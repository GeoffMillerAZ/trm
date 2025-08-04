from datetime import datetime, timedelta
from decimal import Decimal
from unittest.mock import AsyncMock

import pytest

from src.domain.entities.address_balance import AddressBalance
from src.domain.services.blockchain_service import BlockchainService
from src.domain.value_objects.ethereum_address import EthereumAddress
from src.infrastructure.mocks.mock_cache import MockCache
from src.infrastructure.mocks.mock_database import MockDatabase
from src.infrastructure.mocks.mock_logger import MockLogger
from src.infrastructure.mocks.mock_tracer import MockTracer


class TestBlockchainService:
    """Unit tests for BlockchainService domain service."""

    @pytest.fixture
    def mock_blockchain_repository(self):
        """Mock blockchain repository."""
        repo = AsyncMock()
        repo.get_balance.return_value = Decimal("2.5")
        return repo

    @pytest.fixture
    def mock_cache(self):
        """Mock cache interface."""
        return MockCache()

    @pytest.fixture
    def mock_database(self):
        """Mock database interface."""
        return MockDatabase()

    @pytest.fixture
    def mock_logger(self):
        """Mock logger interface."""
        return MockLogger()

    @pytest.fixture
    def mock_tracer(self):
        """Mock tracer interface."""
        return MockTracer()

    @pytest.fixture
    def blockchain_service(
        self,
        mock_blockchain_repository,
        mock_cache,
        mock_database,
        mock_logger,
        mock_tracer,
    ):
        """Create BlockchainService instance with mocked dependencies."""
        return BlockchainService(
            blockchain_repository=mock_blockchain_repository,
            cache=mock_cache,
            database=mock_database,
            logger=mock_logger,
            tracer=mock_tracer,
            cache_ttl_minutes=5,
        )

    def test_get_cache_key(self, blockchain_service):
        """Test cache key generation."""
        address = "0xC94770007DDA54CF92009BFF0DE90C06F603A09F"
        expected_key = "balance:0xc94770007dda54cf92009bff0de90c06f603a09f"

        cache_key = blockchain_service._get_cache_key(address)

        assert cache_key == expected_key

    def test_get_cache_key_lowercase(self, blockchain_service):
        """Test cache key generation converts to lowercase."""
        address = "0xC94770007DDA54CF92009BFF0DE90C06F603A09F"
        cache_key = blockchain_service._get_cache_key(address)

        assert cache_key.islower()
        assert cache_key.startswith("balance:")

    @pytest.mark.asyncio
    async def test_get_address_balance_invalid_address(self, blockchain_service):
        """Test handling of invalid Ethereum addresses."""
        invalid_address = "invalid_address"

        result = await blockchain_service.get_address_balance(invalid_address)

        assert result is None

    @pytest.mark.asyncio
    async def test_get_address_balance_empty_address(self, blockchain_service):
        """Test handling of empty address."""
        empty_address = ""

        result = await blockchain_service.get_address_balance(empty_address)

        assert result is None

    @pytest.mark.asyncio
    async def test_get_address_balance_none_address(self, blockchain_service):
        """Test handling of None address."""
        # The service should handle None gracefully and return None
        result = await blockchain_service.get_address_balance(None)
        assert result is None

    @pytest.mark.asyncio
    async def test_get_from_cache_no_data(self, blockchain_service, mock_cache):
        """Test _get_from_cache when cache is empty."""
        cache_key = "balance:0xc94770007dda54cf92009bff0de90c06f603a09f"
        correlation_id = "test123"

        result = await blockchain_service._get_from_cache(cache_key, correlation_id)

        assert result is None

    @pytest.mark.asyncio
    async def test_get_from_cache_fresh_data(self, blockchain_service, mock_cache):
        """Test _get_from_cache with fresh cached data."""
        cache_key = "balance:0xc94770007dda54cf92009bff0de90c06f603a09f"
        correlation_id = "test123"

        # Pre-populate cache with fresh data
        cache_data = {
            "address": "0xc94770007dda54cf92009bff0de90c06f603a09f",
            "balance_eth": "2.5",
            "retrieved_at": datetime.utcnow().isoformat(),
        }
        await mock_cache.set(cache_key, cache_data)

        result = await blockchain_service._get_from_cache(cache_key, correlation_id)

        assert result is not None
        assert result.address.value == "0xc94770007dda54cf92009bff0de90c06f603a09f"
        assert result.balance_eth == Decimal("2.5")
        assert result.source == "cache"

    @pytest.mark.asyncio
    async def test_get_from_cache_stale_data(self, blockchain_service, mock_cache):
        """Test _get_from_cache with stale cached data."""
        cache_key = "balance:0xc94770007dda54cf92009bff0de90c06f603a09f"
        correlation_id = "test123"

        # Pre-populate cache with stale data (10 minutes old)
        stale_time = datetime.utcnow() - timedelta(minutes=10)
        cache_data = {
            "address": "0xc94770007dda54cf92009bff0de90c06f603a09f",
            "balance_eth": "2.5",
            "retrieved_at": stale_time.isoformat(),
        }
        await mock_cache.set(cache_key, cache_data)

        result = await blockchain_service._get_from_cache(cache_key, correlation_id)

        # Should return None for stale data and delete from cache
        assert result is None
        cached_after_staleness_check = await mock_cache.get(cache_key)
        assert cached_after_staleness_check is None

    @pytest.mark.asyncio
    async def test_get_from_cache_invalid_cache_data(
        self, blockchain_service, mock_cache
    ):
        """Test _get_from_cache with invalid cached data structure."""
        cache_key = "balance:0xc94770007dda54cf92009bff0de90c06f603a09f"
        correlation_id = "test123"

        # Pre-populate cache with invalid data
        invalid_cache_data = {"invalid": "data"}
        await mock_cache.set(cache_key, invalid_cache_data)

        result = await blockchain_service._get_from_cache(cache_key, correlation_id)

        # Should return None when cache data is invalid
        assert result is None

    @pytest.mark.asyncio
    async def test_store_balance(self, blockchain_service, mock_cache, mock_database):
        """Test _store_balance method."""
        address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
        balance = AddressBalance(
            address=address,
            balance_eth=Decimal("2.5"),
            retrieved_at=datetime.utcnow(),
            source="blockchain",
        )
        cache_key = "balance:0xc94770007dda54cf92009bff0de90c06f603a09f"
        correlation_id = "test123"

        await blockchain_service._store_balance(balance, cache_key, correlation_id)

        # Verify cache was updated
        cached_data = await mock_cache.get(cache_key)
        assert cached_data is not None
        assert cached_data["address"] == address.value
        assert cached_data["balance_eth"] == "2.5"

        # Verify database was updated
        saved_balances = mock_database.balances
        assert len(saved_balances) == 1
        assert saved_balances[0].address.value == address.value

    @pytest.mark.asyncio
    async def test_store_balance_cache_failure(self, blockchain_service, mock_database):
        """Test _store_balance when cache operations fail."""
        from src.infrastructure.mocks.mock_cache import FailingMockCache

        # Use a cache that always fails
        failing_cache = FailingMockCache()
        service = BlockchainService(
            blockchain_repository=AsyncMock(),
            cache=failing_cache,
            database=mock_database,
            logger=MockLogger(),
            tracer=MockTracer(),
            cache_ttl_minutes=5,
        )

        address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
        balance = AddressBalance(
            address=address,
            balance_eth=Decimal("2.5"),
            retrieved_at=datetime.utcnow(),
            source="blockchain",
        )
        cache_key = "balance:0xc94770007dda54cf92009bff0de90c06f603a09f"
        correlation_id = "test123"

        # Should not raise exception even when cache fails
        await service._store_balance(balance, cache_key, correlation_id)

        # Database should still be updated
        saved_balances = mock_database.balances
        assert len(saved_balances) == 1

    @pytest.mark.asyncio
    async def test_store_balance_database_failure(self, blockchain_service, mock_cache):
        """Test _store_balance when database operations fail."""
        from src.infrastructure.mocks.mock_database import FailingMockDatabase

        # Use a database that always fails
        failing_database = FailingMockDatabase()
        service = BlockchainService(
            blockchain_repository=AsyncMock(),
            cache=mock_cache,
            database=failing_database,
            logger=MockLogger(),
            tracer=MockTracer(),
            cache_ttl_minutes=5,
        )

        address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
        balance = AddressBalance(
            address=address,
            balance_eth=Decimal("2.5"),
            retrieved_at=datetime.utcnow(),
            source="blockchain",
        )
        cache_key = "balance:0xc94770007dda54cf92009bff0de90c06f603a09f"
        correlation_id = "test123"

        # Should not raise exception even when database fails
        await service._store_balance(balance, cache_key, correlation_id)

        # Cache should still be updated
        cached_data = await mock_cache.get(cache_key)
        assert cached_data is not None
