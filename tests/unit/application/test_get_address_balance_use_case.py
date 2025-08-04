from datetime import datetime
from decimal import Decimal
from unittest.mock import AsyncMock

import pytest

from src.application.dtos.blockchain_dtos import BalanceRequest, BalanceResponse
from src.application.use_cases.get_address_balance import GetAddressBalanceUseCase
from src.domain.entities.address_balance import AddressBalance
from src.domain.value_objects.ethereum_address import EthereumAddress
from src.infrastructure.mocks.mock_logger import MockLogger
from src.infrastructure.mocks.mock_tracer import MockTracer


class TestGetAddressBalanceUseCase:
    """Unit tests for GetAddressBalanceUseCase."""

    @pytest.fixture
    def mock_blockchain_service(self):
        """Mock blockchain service."""
        service = AsyncMock()

        # Default return value
        address = EthereumAddress("0xc94770007dda54cf92009bff0de90c06f603a09f")
        balance = AddressBalance(
            address=address,
            balance_eth=Decimal("2.5"),
            retrieved_at=datetime.utcnow(),
            source="blockchain",
        )
        service.get_address_balance.return_value = balance

        return service

    @pytest.fixture
    def mock_logger(self):
        """Mock logger interface."""
        return MockLogger()

    @pytest.fixture
    def mock_tracer(self):
        """Mock tracer interface."""
        return MockTracer()

    @pytest.fixture
    def use_case(self, mock_blockchain_service, mock_logger, mock_tracer):
        """Create GetAddressBalanceUseCase instance with mocked dependencies."""
        return GetAddressBalanceUseCase(
            blockchain_service=mock_blockchain_service,
            logger=mock_logger,
            tracer=mock_tracer,
        )

    def test_use_case_initialization(
        self, mock_blockchain_service, mock_logger, mock_tracer
    ):
        """Test use case initialization with dependencies."""
        use_case = GetAddressBalanceUseCase(
            blockchain_service=mock_blockchain_service,
            logger=mock_logger,
            tracer=mock_tracer,
        )

        assert use_case._blockchain_service == mock_blockchain_service
        assert use_case._logger == mock_logger
        assert use_case._tracer == mock_tracer

    @pytest.mark.asyncio
    async def test_execute_successful_balance_retrieval(
        self, use_case, mock_blockchain_service
    ):
        """Test successful balance retrieval."""
        request = BalanceRequest(address="0xc94770007dda54cF92009BFF0dE90c06F603a09f")

        result = await use_case.execute(request)

        assert result is not None
        assert isinstance(result, BalanceResponse)
        assert result.address == "0xc94770007dda54cf92009bff0de90c06f603a09f"
        assert result.balance_eth == Decimal("2.5")
        assert result.source == "blockchain"

        # Verify service was called with correct address (lowercase due to BalanceRequest validation)
        mock_blockchain_service.get_address_balance.assert_called_once_with(
            "0xc94770007dda54cf92009bff0de90c06f603a09f"
        )

    @pytest.mark.asyncio
    async def test_execute_service_returns_none(
        self, use_case, mock_blockchain_service
    ):
        """Test when blockchain service returns None."""
        mock_blockchain_service.get_address_balance.return_value = None

        request = BalanceRequest(address="0xc94770007dda54cF92009BFF0dE90c06F603a09f")

        result = await use_case.execute(request)

        assert result is None
        mock_blockchain_service.get_address_balance.assert_called_once_with(
            "0xc94770007dda54cf92009bff0de90c06f603a09f"
        )

    @pytest.mark.asyncio
    async def test_execute_service_raises_exception(
        self, use_case, mock_blockchain_service
    ):
        """Test when blockchain service raises an exception."""
        mock_blockchain_service.get_address_balance.side_effect = Exception(
            "Network error"
        )

        request = BalanceRequest(address="0xc94770007dda54cF92009BFF0dE90c06F603a09f")

        result = await use_case.execute(request)

        assert result is None

    @pytest.mark.asyncio
    async def test_execute_with_cache_source(self, use_case, mock_blockchain_service):
        """Test execution when balance comes from cache."""
        address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
        balance = AddressBalance(
            address=address,
            balance_eth=Decimal("1.5"),
            retrieved_at=datetime.utcnow(),
            source="cache",
        )
        mock_blockchain_service.get_address_balance.return_value = balance

        request = BalanceRequest(address="0xc94770007dda54cF92009BFF0dE90c06F603a09f")

        result = await use_case.execute(request)

        assert result is not None
        assert result.balance_eth == Decimal("1.5")
        assert result.source == "cache"

    @pytest.mark.asyncio
    async def test_execute_with_zero_balance(self, use_case, mock_blockchain_service):
        """Test execution with zero balance."""
        address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
        balance = AddressBalance(
            address=address,
            balance_eth=Decimal("0"),
            retrieved_at=datetime.utcnow(),
            source="blockchain",
        )
        mock_blockchain_service.get_address_balance.return_value = balance

        request = BalanceRequest(address="0xc94770007dda54cF92009BFF0dE90c06F603a09f")

        result = await use_case.execute(request)

        assert result is not None
        assert result.balance_eth == Decimal("0")
        assert result.source == "blockchain"

    @pytest.mark.asyncio
    async def test_execute_with_large_balance(self, use_case, mock_blockchain_service):
        """Test execution with large balance."""
        address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
        balance = AddressBalance(
            address=address,
            balance_eth=Decimal("1000000.123456789"),
            retrieved_at=datetime.utcnow(),
            source="blockchain",
        )
        mock_blockchain_service.get_address_balance.return_value = balance

        request = BalanceRequest(address="0xc94770007dda54cF92009BFF0dE90c06F603a09f")

        result = await use_case.execute(request)

        assert result is not None
        assert result.balance_eth == Decimal("1000000.123456789")
        assert result.source == "blockchain"

    @pytest.mark.asyncio
    async def test_execute_response_formatting(self, use_case, mock_blockchain_service):
        """Test that response is properly formatted from AddressBalance."""
        retrieved_at = datetime.utcnow()
        address = EthereumAddress("0xc94770007dda54cf92009bff0de90c06f603a09f")
        balance = AddressBalance(
            address=address,
            balance_eth=Decimal("3.14159"),
            retrieved_at=retrieved_at,
            source="blockchain",
        )
        mock_blockchain_service.get_address_balance.return_value = balance

        request = BalanceRequest(address="0xc94770007dda54cF92009BFF0dE90c06F603a09f")

        result = await use_case.execute(request)

        assert result is not None
        assert result.address == "0xc94770007dda54cf92009bff0de90c06f603a09f"
        assert result.balance_eth == Decimal("3.14159")
        assert result.retrieved_at == retrieved_at
        assert result.source == "blockchain"
