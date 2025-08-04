"""Integration tests for blockchain service with infrastructure components."""

from datetime import datetime, timedelta
from decimal import Decimal

import pytest

from src.domain.interfaces.logger import LogLevel
from src.domain.services.blockchain_service import BlockchainService
from src.domain.value_objects.ethereum_address import EthereumAddress
from src.infrastructure.mocks.mock_cache import MockCache
from src.infrastructure.mocks.mock_database import MockDatabase
from src.infrastructure.mocks.mock_logger import MockLogger
from src.infrastructure.mocks.mock_tracer import MockTracer


class MockBlockchainRepository:
    """Mock blockchain repository for testing."""

    def __init__(self, balance_to_return=Decimal("1.5")):
        self.balance_to_return = balance_to_return
        self.get_balance_calls = []

    async def get_balance(self, address: EthereumAddress) -> Decimal:
        self.get_balance_calls.append(address)
        return self.balance_to_return


@pytest.fixture
def blockchain_service_components():
    """Fixture providing all service components."""
    return {
        "blockchain_repo": MockBlockchainRepository(Decimal("2.5")),
        "cache": MockCache(),
        "database": MockDatabase(),
        "logger": MockLogger(),
        "tracer": MockTracer(),
    }


@pytest.mark.asyncio
async def test_blockchain_service_cache_miss_flow():
    """Test complete flow when cache is empty."""
    # Setup mocks
    blockchain_repo = MockBlockchainRepository(Decimal("2.5"))
    cache = MockCache()
    database = MockDatabase()
    logger = MockLogger()
    tracer = MockTracer()

    service = BlockchainService(
        blockchain_repository=blockchain_repo,
        cache=cache,
        database=database,
        logger=logger,
        tracer=tracer,
        cache_ttl_minutes=5,
    )

    # Execute
    result = await service.get_address_balance(
        "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
    )

    # Verify result
    assert result is not None
    assert result.balance_eth == Decimal("2.5")
    assert result.address.value == "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
    assert result.source == "blockchain"

    # Verify blockchain repository was called
    assert len(blockchain_repo.get_balance_calls) == 1
    called_address = blockchain_repo.get_balance_calls[0]
    assert called_address.value == "0xc94770007dda54cF92009BFF0dE90c06F603a09f"

    # Verify cache operations
    assert len(cache.get_calls) == 1
    assert len(cache.set_calls) == 1
    cache_key = "balance:0xc94770007dda54cf92009bff0de90c06f603a09f"
    assert cache.get_calls[0] == cache_key

    # Verify database operations
    assert len(database.save_balance_calls) == 1
    saved_balance = database.save_balance_calls[0]
    assert saved_balance.balance_eth == Decimal("2.5")

    # Verify logging
    assert logger.has_log_with_level(LogLevel.INFO)
    assert logger.has_log_with_message("Retrieving balance for address")
    assert logger.has_log_with_message("Balance retrieved successfully")

    # Verify tracing
    assert len(tracer.traces) > 0
    main_trace = tracer.traces[0]
    assert main_trace["operation_name"] == "get_address_balance"
    assert "address" in main_trace["metadata"]


@pytest.mark.asyncio
async def test_blockchain_service_cache_hit_flow():
    """Test flow when balance is found in cache."""
    blockchain_repo = MockBlockchainRepository()
    cache = MockCache()
    database = MockDatabase()
    logger = MockLogger()
    tracer = MockTracer()

    # Pre-populate cache with fresh data
    cache_data = {
        "address": "0xc94770007dda54cf92009bff0de90c06f603a09f",
        "balance_eth": "3.0",
        "retrieved_at": datetime.utcnow().isoformat(),
    }
    cache_key = "balance:0xc94770007dda54cf92009bff0de90c06f603a09f"
    await cache.set(cache_key, cache_data)

    service = BlockchainService(
        blockchain_repository=blockchain_repo,
        cache=cache,
        database=database,
        logger=logger,
        tracer=tracer,
        cache_ttl_minutes=5,
    )

    # Execute
    result = await service.get_address_balance(
        "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
    )

    # Verify result from cache
    assert result is not None
    assert result.balance_eth == Decimal("3.0")
    assert result.source == "cache"

    # Verify blockchain repository was NOT called
    assert len(blockchain_repo.get_balance_calls) == 0

    # Verify cache was checked but not written to again
    assert len(cache.get_calls) == 1
    assert len(cache.set_calls) == 1  # Only the pre-population

    # Verify database was NOT written to
    assert len(database.save_balance_calls) == 0

    # Verify logging shows cache hit
    assert logger.has_log_with_message("Balance retrieved from cache")

    # Verify tracing recorded cache hit
    assert len(tracer.traces) > 0
    assert len(tracer.spans) > 0
    check_cache_spans = [
        span for span in tracer.spans if span["operation_name"] == "check_cache"
    ]
    assert len(check_cache_spans) > 0


@pytest.mark.asyncio
async def test_blockchain_service_stale_cache_handling():
    """Test that stale cache entries are removed and fresh data fetched."""
    blockchain_repo = MockBlockchainRepository(Decimal("4.0"))
    cache = MockCache()
    database = MockDatabase()
    logger = MockLogger()
    tracer = MockTracer()

    # Pre-populate cache with stale data (10 minutes old)
    stale_time = datetime.utcnow() - timedelta(minutes=10)
    cache_data = {
        "address": "0xc94770007dda54cf92009bff0de90c06f603a09f",
        "balance_eth": "3.0",
        "retrieved_at": stale_time.isoformat(),
    }
    cache_key = "balance:0xc94770007dda54cf92009bff0de90c06f603a09f"
    await cache.set(cache_key, cache_data)

    service = BlockchainService(
        blockchain_repository=blockchain_repo,
        cache=cache,
        database=database,
        logger=logger,
        tracer=tracer,
        cache_ttl_minutes=5,  # 5 minute TTL, so 10 minute old data is stale
    )

    # Execute
    result = await service.get_address_balance(
        "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
    )

    # Verify fresh result was returned
    assert result is not None
    assert result.balance_eth == Decimal("4.0")  # Fresh from blockchain
    assert result.source == "blockchain"

    # Verify blockchain repository was called (cache miss due to staleness)
    assert len(blockchain_repo.get_balance_calls) == 1

    # Verify stale cache entry was deleted and new one was set
    assert len(cache.delete_calls) == 1
    assert cache.delete_calls[0] == cache_key

    # Verify database was updated with fresh data
    assert len(database.save_balance_calls) == 1

    # Verify logging shows cache miss due to staleness
    assert logger.has_log_with_message("Cache miss, fetching from blockchain")


@pytest.mark.asyncio
async def test_blockchain_service_invalid_address():
    """Test handling of invalid Ethereum addresses."""
    blockchain_repo = MockBlockchainRepository()
    cache = MockCache()
    database = MockDatabase()
    logger = MockLogger()
    tracer = MockTracer()

    service = BlockchainService(
        blockchain_repository=blockchain_repo,
        cache=cache,
        database=database,
        logger=logger,
        tracer=tracer,
    )

    # Test invalid address
    result = await service.get_address_balance("invalid_address")

    # Verify null result
    assert result is None

    # Verify no external calls were made
    assert len(blockchain_repo.get_balance_calls) == 0
    assert len(cache.get_calls) == 0
    assert len(database.save_balance_calls) == 0

    # Verify error was logged
    assert logger.has_log_with_message("Invalid address format")

    # Verify tracing recorded the validation failure
    assert len(tracer.traces) > 0
    assert len(tracer.spans) > 0
    validation_spans = [
        span for span in tracer.spans if span["operation_name"] == "validate_address"
    ]
    assert len(validation_spans) > 0


@pytest.mark.asyncio
async def test_blockchain_service_cache_error_handling():
    """Test that cache errors don't break the service."""
    from src.infrastructure.mocks.mock_cache import FailingMockCache

    blockchain_repo = MockBlockchainRepository(Decimal("5.0"))
    cache = FailingMockCache()  # Always fails
    database = MockDatabase()
    logger = MockLogger()
    tracer = MockTracer()

    service = BlockchainService(
        blockchain_repository=blockchain_repo,
        cache=cache,
        database=database,
        logger=logger,
        tracer=tracer,
    )

    # Execute - should work despite cache failures
    result = await service.get_address_balance(
        "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
    )

    # Verify result is still returned
    assert result is not None
    assert result.balance_eth == Decimal("5.0")
    assert result.source == "blockchain"

    # Verify blockchain was called (cache failed)
    assert len(blockchain_repo.get_balance_calls) == 1

    # Verify database was still called
    assert len(database.save_balance_calls) == 1

    # Verify cache errors were logged as warnings
    warning_logs = [log for log in logger.log_calls if log["level"] == LogLevel.WARNING]
    assert len(warning_logs) >= 1
    assert any("Cache" in log["message"] for log in warning_logs)


@pytest.mark.asyncio
async def test_blockchain_service_database_error_handling():
    """Test that database errors don't break the service."""
    from src.infrastructure.mocks.mock_database import FailingMockDatabase

    blockchain_repo = MockBlockchainRepository(Decimal("6.0"))
    cache = MockCache()
    database = FailingMockDatabase()  # Always fails
    logger = MockLogger()
    tracer = MockTracer()

    service = BlockchainService(
        blockchain_repository=blockchain_repo,
        cache=cache,
        database=database,
        logger=logger,
        tracer=tracer,
    )

    # Execute - should work despite database failures
    result = await service.get_address_balance(
        "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
    )

    # Verify result is still returned
    assert result is not None
    assert result.balance_eth == Decimal("6.0")
    assert result.source == "blockchain"

    # Verify blockchain was called
    assert len(blockchain_repo.get_balance_calls) == 1

    # Verify cache was used
    assert len(cache.set_calls) == 1

    # Verify database errors were logged as warnings
    warning_logs = [log for log in logger.log_calls if log["level"] == LogLevel.WARNING]
    assert len(warning_logs) >= 1
    assert any("Database" in log["message"] for log in warning_logs)


@pytest.mark.asyncio
async def test_blockchain_service_correlation_id_tracking():
    """Test that correlation IDs are used consistently in logs and tracing."""
    blockchain_repo = MockBlockchainRepository(Decimal("1.0"))
    cache = MockCache()
    database = MockDatabase()
    logger = MockLogger()
    tracer = MockTracer()

    service = BlockchainService(
        blockchain_repository=blockchain_repo,
        cache=cache,
        database=database,
        logger=logger,
        tracer=tracer,
    )

    # Execute
    await service.get_address_balance("0xc94770007dda54cF92009BFF0dE90c06F603a09f")

    # Verify all log entries have correlation IDs
    assert len(logger.log_calls) > 0
    for log_entry in logger.log_calls:
        assert log_entry["correlation_id"] is not None
        assert len(log_entry["correlation_id"]) == 8  # UUID[:8]

    # Verify the same correlation ID is used throughout the request
    correlation_ids = [
        log["correlation_id"] for log in logger.log_calls if log["correlation_id"]
    ]
    assert len(set(correlation_ids)) == 1  # All should be the same

    # Verify tracing also uses correlation ID
    assert len(tracer.traces) > 0
    main_trace = tracer.traces[0]
    assert "correlation_id" in main_trace["metadata"]
    assert main_trace["metadata"]["correlation_id"] == correlation_ids[0]


@pytest.mark.asyncio
async def test_blockchain_service_end_to_end_integration():
    """Test complete end-to-end integration with realistic data flow."""
    blockchain_repo = MockBlockchainRepository(Decimal("10.5"))
    cache = MockCache()
    database = MockDatabase()
    logger = MockLogger()
    tracer = MockTracer()

    service = BlockchainService(
        blockchain_repository=blockchain_repo,
        cache=cache,
        database=database,
        logger=logger,
        tracer=tracer,
        cache_ttl_minutes=10,
    )

    address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"

    # First call - should miss cache and hit blockchain
    result1 = await service.get_address_balance(address)

    assert result1 is not None
    assert result1.balance_eth == Decimal("10.5")
    assert result1.source == "blockchain"
    assert len(blockchain_repo.get_balance_calls) == 1
    assert len(cache.set_calls) == 1
    assert len(database.save_balance_calls) == 1

    # Reset call tracking
    cache.get_calls.clear()
    cache.set_calls.clear()

    # Second call - should hit cache
    result2 = await service.get_address_balance(address)

    assert result2 is not None
    assert result2.balance_eth == Decimal("10.5")
    assert result2.source == "cache"
    assert len(blockchain_repo.get_balance_calls) == 1  # No additional calls
    assert len(cache.get_calls) == 1  # Cache was checked
    assert len(cache.set_calls) == 0  # No additional cache writes
    assert len(database.save_balance_calls) == 1  # No additional database writes

    # Verify consistent logging across both calls
    info_logs = [log for log in logger.log_calls if log["level"] == LogLevel.INFO]
    assert (
        len(info_logs) >= 3
    )  # First call: 2 INFO logs, second call: 1 INFO log (cache hit logs at DEBUG)

    # Verify tracing captured both requests
    assert len(tracer.traces) == 2
    assert all(
        trace["operation_name"] == "get_address_balance" for trace in tracer.traces
    )


@pytest.mark.asyncio
async def test_blockchain_service_multiple_addresses():
    """Test handling multiple different addresses in sequence."""
    blockchain_repo = MockBlockchainRepository(Decimal("7.5"))
    cache = MockCache()
    database = MockDatabase()
    logger = MockLogger()
    tracer = MockTracer()

    service = BlockchainService(
        blockchain_repository=blockchain_repo,
        cache=cache,
        database=database,
        logger=logger,
        tracer=tracer,
        cache_ttl_minutes=5,
    )

    addresses = [
        "0xc94770007dda54cF92009BFF0dE90c06F603a09f",
        "0x742D35Cc6634C0532925a3b8D400A4c0D81e31b3",
        "0x8ba1f109551bd432803012645db22e9e8c2e7985",
    ]

    results = []
    for address in addresses:
        result = await service.get_address_balance(address)
        results.append(result)

    # Verify all results
    assert len(results) == 3
    for i, result in enumerate(results):
        assert result is not None
        assert result.balance_eth == Decimal("7.5")
        assert result.address.value.lower() == addresses[i].lower()
        assert result.source == "blockchain"

    # Verify separate cache entries
    assert len(cache.set_calls) == 3
    cache_keys = [call[0] for call in cache.set_calls]
    assert len(set(cache_keys)) == 3  # All different cache keys

    # Verify separate database entries
    assert len(database.save_balance_calls) == 3

    # Verify separate traces
    assert len(tracer.traces) == 3

    # Verify blockchain repository called for each address
    assert len(blockchain_repo.get_balance_calls) == 3
    called_addresses = [
        addr.value.lower() for addr in blockchain_repo.get_balance_calls
    ]
    expected_addresses = [addr.lower() for addr in addresses]
    assert called_addresses == expected_addresses
