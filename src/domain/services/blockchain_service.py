import uuid
from datetime import datetime, timedelta
from decimal import Decimal

from src.domain.entities.address_balance import AddressBalance
from src.domain.interfaces.cache import CacheInterface
from src.domain.interfaces.database import DatabaseInterface
from src.domain.interfaces.logger import LoggerInterface
from src.domain.interfaces.tracing import TraceStatus, TracingInterface
from src.domain.repositories.blockchain_repository import BlockchainRepository
from src.domain.value_objects.ethereum_address import EthereumAddress


class BlockchainService:
    """
    Domain service for blockchain operations and business logic.
    Orchestrates balance retrieval with caching, persistence, and proper error handling.
    """

    def __init__(
        self,
        blockchain_repository: BlockchainRepository,
        cache: CacheInterface,
        database: DatabaseInterface,
        logger: LoggerInterface,
        tracer: TracingInterface,
        cache_ttl_minutes: int = 5,
    ) -> None:
        self._blockchain_repository = blockchain_repository
        self._cache = cache
        self._database = database
        self._logger = logger
        self._tracer = tracer
        self._cache_ttl = timedelta(minutes=cache_ttl_minutes)

    def _get_cache_key(self, address: str) -> str:
        """Generate cache key for address balance."""
        return f"balance:{address.lower()}"

    async def get_address_balance(self, address: str) -> AddressBalance | None:
        """
        Get balance for an Ethereum address with caching and persistence.

        Flow:
        1. Validate address format
        2. Check cache for recent balance
        3. If cache miss, fetch from blockchain
        4. Store in cache and database
        5. Return balance

        Returns None if address is invalid, matching Flask behavior.
        """
        correlation_id = str(uuid.uuid4())[:8]

        async with await self._tracer.start_trace(
            "get_address_balance",
            metadata={"address": address, "correlation_id": correlation_id},
        ) as span:
            try:
                await span.set_attribute("address", address)
                await span.set_attribute("correlation_id", correlation_id)

                # Validate address format first
                async with await self._tracer.start_span(
                    "validate_address", metadata={"address": address}
                ) as validation_span:
                    try:
                        ethereum_address = EthereumAddress(address)
                        await validation_span.set_attribute("valid", True)
                        await validation_span.add_event("address_validated")
                    except ValueError as e:
                        await validation_span.set_attribute("valid", False)
                        await validation_span.set_attribute("error", str(e))
                        await validation_span.set_status(
                            TraceStatus.ERROR, "Invalid address format"
                        )

                        await self._logger.info(
                            "Invalid address format",
                            correlation_id=correlation_id,
                            metadata={"address": address, "error": str(e)},
                        )
                        return None

                cache_key = self._get_cache_key(address)
                await span.set_attribute("cache_key", cache_key)

                await self._logger.info(
                    "Retrieving balance for address",
                    correlation_id=correlation_id,
                    metadata={"address": address},
                )

                # Try cache first
                async with await self._tracer.start_span(
                    "check_cache", metadata={"cache_key": cache_key}
                ) as cache_span:
                    cached_balance = await self._get_from_cache(
                        cache_key, correlation_id
                    )

                    if cached_balance:
                        await cache_span.set_attribute("cache_hit", True)
                        await cache_span.set_attribute(
                            "balance", float(cached_balance.balance_eth)
                        )
                        await cache_span.add_event(
                            "cache_hit", {"balance": float(cached_balance.balance_eth)}
                        )

                        await span.set_attribute("source", "cache")
                        await span.set_attribute(
                            "balance", float(cached_balance.balance_eth)
                        )

                        # Update source to indicate cache hit
                        cached_balance.source = "cache"

                        await self._logger.debug(
                            "Balance retrieved from cache",
                            correlation_id=correlation_id,
                            metadata={
                                "address": address,
                                "balance": float(cached_balance.balance_eth),
                            },
                        )
                        return cached_balance
                    else:
                        await cache_span.set_attribute("cache_hit", False)
                        await cache_span.add_event("cache_miss")

                # Cache miss - fetch from blockchain
                await self._logger.debug(
                    "Cache miss, fetching from blockchain",
                    correlation_id=correlation_id,
                    metadata={"address": address},
                )

                async with await self._tracer.start_span(
                    "fetch_from_blockchain", metadata={"address": address}
                ) as blockchain_span:
                    await blockchain_span.set_attribute("provider", "infura")

                    balance_eth = await self._blockchain_repository.get_balance(
                        ethereum_address
                    )

                    await blockchain_span.set_attribute("balance", float(balance_eth))
                    await blockchain_span.add_event(
                        "balance_fetched", {"balance": float(balance_eth)}
                    )

                # Create domain entity
                address_balance = AddressBalance(
                    address=ethereum_address,
                    balance_eth=Decimal(str(balance_eth)),
                    retrieved_at=datetime.utcnow(),
                    source="blockchain",
                )

                # Store in cache and database (fire and forget)
                async with await self._tracer.start_span(
                    "store_balance",
                    metadata={"address": address, "balance": float(balance_eth)},
                ) as store_span:
                    await self._store_balance(
                        address_balance, cache_key, correlation_id
                    )
                    await store_span.add_event("balance_stored")

                await span.set_attribute("source", "blockchain")
                await span.set_attribute("balance", float(balance_eth))
                await span.add_event(
                    "balance_retrieved_successfully",
                    {
                        "address": address,
                        "balance": float(balance_eth),
                        "source": "blockchain",
                    },
                )

                await self._logger.info(
                    "Balance retrieved successfully",
                    correlation_id=correlation_id,
                    metadata={
                        "address": address,
                        "balance": float(balance_eth),
                        "source": "blockchain",
                    },
                )

                return address_balance

            except Exception as e:
                # Any other error during balance retrieval
                await span.set_status(TraceStatus.ERROR, str(e))
                await span.set_attribute("error", str(e))
                await span.add_event("error", {"exception": str(e)})

                await self._logger.error(
                    "Balance retrieval failed",
                    correlation_id=correlation_id,
                    metadata={"address": address},
                    exception=e,
                )
                return None

    async def _get_from_cache(
        self, cache_key: str, correlation_id: str
    ) -> AddressBalance | None:
        """Get balance from cache if available and fresh."""
        try:
            cached_data = await self._cache.get(cache_key)
            if not cached_data:
                return None

            # Reconstruct AddressBalance from cached data
            address = EthereumAddress(cached_data["address"])
            balance_eth = Decimal(cached_data["balance_eth"])
            retrieved_at = datetime.fromisoformat(cached_data["retrieved_at"])

            # Check if cache entry is still fresh
            age = datetime.utcnow() - retrieved_at
            if age <= self._cache_ttl:
                return AddressBalance(
                    address=address,
                    balance_eth=balance_eth,
                    retrieved_at=retrieved_at,
                    source="cache",
                )

            # Cache entry is stale, remove it
            await self._cache.delete(cache_key)
            return None

        except Exception as e:
            # Cache errors should not fail the request
            await self._logger.warning(
                "Cache retrieval failed",
                correlation_id=correlation_id,
                metadata={"cache_key": cache_key, "error": str(e)},
            )
            return None

    async def _store_balance(
        self, balance: AddressBalance, cache_key: str, correlation_id: str
    ) -> None:
        """Store balance in cache and database."""
        # Prepare cache data
        cache_data = {
            "address": balance.address.value,
            "balance_eth": str(balance.balance_eth),
            "retrieved_at": balance.retrieved_at.isoformat(),
        }

        # Store in cache (best effort)
        try:
            await self._cache.set(cache_key, cache_data, ttl=self._cache_ttl)
            await self._logger.debug(
                "Balance stored in cache",
                correlation_id=correlation_id,
                metadata={"cache_key": cache_key},
            )
        except Exception as e:
            await self._logger.warning(
                "Cache storage failed",
                correlation_id=correlation_id,
                metadata={"cache_key": cache_key, "error": str(e)},
            )

        # Store in database (best effort)
        try:
            await self._database.save_balance(balance)
            await self._logger.debug(
                "Balance stored in database",
                correlation_id=correlation_id,
                metadata={"address": balance.address.value},
            )
        except Exception as e:
            await self._logger.warning(
                "Database storage failed",
                correlation_id=correlation_id,
                metadata={"address": balance.address.value, "error": str(e)},
            )
