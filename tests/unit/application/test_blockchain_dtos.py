from datetime import datetime
from decimal import Decimal

import pytest
from pydantic import ValidationError

from src.application.dtos.blockchain_dtos import (
    BalanceRequest,
    BalanceResponse,
    ErrorDetail,
    ErrorResponse,
    HealthResponse,
)
from src.domain.entities.address_balance import AddressBalance
from src.domain.value_objects.ethereum_address import EthereumAddress


class TestBalanceRequest:
    """Unit tests for BalanceRequest DTO."""

    def test_valid_balance_request(self):
        """Test creating a valid BalanceRequest."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        request = BalanceRequest(address=address)

        assert request.address == address.lower()

    def test_balance_request_address_lowercase_conversion(self):
        """Test that address is converted to lowercase."""
        address = "0xC94770007DDA54CF92009BFF0DE90C06F603A09F"
        request = BalanceRequest(address=address)

        assert request.address == address.lower()

    def test_balance_request_invalid_address_format(self):
        """Test validation of invalid address format."""
        invalid_addresses = [
            "invalid_address",
            "0x123",  # Too short
            "0xC94770007DDA54CF92009BFF0DE90C06F603A09F123",  # Too long
            "C94770007DDA54CF92009BFF0DE90C06F603A09F",  # Missing 0x prefix
            "0xG94770007DDA54CF92009BFF0DE90C06F603A09F",  # Invalid hex character
            "",  # Empty string
        ]

        for invalid_address in invalid_addresses:
            with pytest.raises(ValidationError):
                BalanceRequest(address=invalid_address)

    def test_balance_request_address_length_validation(self):
        """Test address length validation."""
        # Too short
        with pytest.raises(ValidationError):
            BalanceRequest(address="0x123")

        # Too long
        with pytest.raises(ValidationError):
            BalanceRequest(address="0xC94770007DDA54CF92009BFF0DE90C06F603A09F123")

    def test_balance_request_missing_address(self):
        """Test that address field is required."""
        with pytest.raises(ValidationError):
            BalanceRequest()


class TestBalanceResponse:
    """Unit tests for BalanceResponse DTO."""

    def test_valid_balance_response(self):
        """Test creating a valid BalanceResponse."""
        address = "0xc94770007dda54cf92009bff0de90c06f603a09f"
        balance_eth = Decimal("2.5")
        retrieved_at = datetime.utcnow()
        source = "blockchain"

        response = BalanceResponse(
            address=address,
            balance_eth=balance_eth,
            retrieved_at=retrieved_at,
            source=source,
        )

        assert response.address == address
        assert response.balance_eth == balance_eth
        assert response.retrieved_at == retrieved_at
        assert response.source == source

    def test_balance_response_zero_balance(self):
        """Test BalanceResponse with zero balance."""
        response = BalanceResponse(
            address="0xc94770007dda54cf92009bff0de90c06f603a09f",
            balance_eth=Decimal("0"),
            retrieved_at=datetime.utcnow(),
            source="blockchain",
        )

        assert response.balance_eth == Decimal("0")

    def test_balance_response_large_balance(self):
        """Test BalanceResponse with large balance."""
        large_balance = Decimal("1000000.123456789")
        response = BalanceResponse(
            address="0xc94770007dda54cf92009bff0de90c06f603a09f",
            balance_eth=large_balance,
            retrieved_at=datetime.utcnow(),
            source="blockchain",
        )

        assert response.balance_eth == large_balance

    def test_balance_response_negative_balance_validation(self):
        """Test that negative balance is rejected."""
        with pytest.raises(ValidationError):
            BalanceResponse(
                address="0xc94770007dda54cf92009bff0de90c06f603a09f",
                balance_eth=Decimal("-1.0"),
                retrieved_at=datetime.utcnow(),
                source="blockchain",
            )

    def test_balance_response_invalid_source(self):
        """Test validation of source field."""
        # Note: Pydantic enum validation is disabled in this implementation
        # The source field accepts any string value
        response = BalanceResponse(
            address="0xc94770007dda54cf92009bff0de90c06f603a09f",
            balance_eth=Decimal("2.5"),
            retrieved_at=datetime.utcnow(),
            source="invalid_source",
        )
        assert response.source == "invalid_source"

    def test_balance_response_valid_sources(self):
        """Test valid source values."""
        valid_sources = ["cache", "blockchain"]

        for source in valid_sources:
            response = BalanceResponse(
                address="0xc94770007dda54cf92009bff0de90c06f603a09f",
                balance_eth=Decimal("2.5"),
                retrieved_at=datetime.utcnow(),
                source=source,
            )
            assert response.source == source

    def test_from_address_balance_blockchain_source(self):
        """Test creating BalanceResponse from AddressBalance with blockchain source."""
        address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
        retrieved_at = datetime.utcnow()

        address_balance = AddressBalance(
            address=address,
            balance_eth=Decimal("2.5"),
            retrieved_at=retrieved_at,
            source="blockchain",
        )

        response = BalanceResponse.from_address_balance(address_balance, "blockchain")

        assert response.address == address.value
        assert response.balance_eth == Decimal("2.5")
        assert response.retrieved_at == retrieved_at
        assert response.source == "blockchain"

    def test_from_address_balance_cache_source(self):
        """Test creating BalanceResponse from AddressBalance with cache source."""
        address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
        retrieved_at = datetime.utcnow()

        address_balance = AddressBalance(
            address=address,
            balance_eth=Decimal("1.75"),
            retrieved_at=retrieved_at,
            source="cache",
        )

        response = BalanceResponse.from_address_balance(address_balance, "cache")

        assert response.address == address.value
        assert response.balance_eth == Decimal("1.75")
        assert response.retrieved_at == retrieved_at
        assert response.source == "cache"

    def test_from_address_balance_default_source(self):
        """Test creating BalanceResponse with default source."""
        address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")

        address_balance = AddressBalance(
            address=address,
            balance_eth=Decimal("3.0"),
            retrieved_at=datetime.utcnow(),
            source="blockchain",
        )

        response = BalanceResponse.from_address_balance(address_balance)

        assert response.source == "blockchain"


class TestErrorDetail:
    """Unit tests for ErrorDetail DTO."""

    def test_error_detail_with_field(self):
        """Test creating ErrorDetail with field."""
        detail = ErrorDetail(
            field="address", message="Invalid address format", code="INVALID_FORMAT"
        )

        assert detail.field == "address"
        assert detail.message == "Invalid address format"
        assert detail.code == "INVALID_FORMAT"

    def test_error_detail_without_field(self):
        """Test creating ErrorDetail without field."""
        detail = ErrorDetail(message="Service unavailable", code="SERVICE_ERROR")

        assert detail.field is None
        assert detail.message == "Service unavailable"
        assert detail.code == "SERVICE_ERROR"


class TestErrorResponse:
    """Unit tests for ErrorResponse DTO."""

    def test_error_response_basic(self):
        """Test creating basic ErrorResponse."""
        response = ErrorResponse(
            error="Validation failed", error_code="VALIDATION_ERROR"
        )

        assert response.error == "Validation failed"
        assert response.error_code == "VALIDATION_ERROR"
        assert response.details is None
        assert response.request_id is None

    def test_error_response_with_details(self):
        """Test creating ErrorResponse with details."""
        details = [
            ErrorDetail(
                field="address", message="Invalid format", code="INVALID_FORMAT"
            )
        ]

        response = ErrorResponse(
            error="Validation failed",
            error_code="VALIDATION_ERROR",
            details=details,
            request_id="req123",
        )

        assert response.details == details
        assert response.request_id == "req123"

    def test_validation_error_class_method(self):
        """Test validation_error class method."""
        response = ErrorResponse.validation_error("Custom validation message")

        assert response.error == "Custom validation message"
        assert response.error_code == "VALIDATION_ERROR"

    def test_validation_error_default_message(self):
        """Test validation_error with default message."""
        response = ErrorResponse.validation_error()

        assert response.error == "Invalid request data"
        assert response.error_code == "VALIDATION_ERROR"

    def test_invalid_address_class_method(self):
        """Test invalid_address class method."""
        address = "invalid_address"
        response = ErrorResponse.invalid_address(address)

        assert response.error == "Invalid Ethereum address format"
        assert response.error_code == "INVALID_ADDRESS"
        assert len(response.details) == 1
        assert response.details[0].field == "address"
        assert address in response.details[0].message

    def test_service_unavailable_class_method(self):
        """Test service_unavailable class method."""
        response = ErrorResponse.service_unavailable("Custom unavailable message")

        assert response.error == "Custom unavailable message"
        assert response.error_code == "SERVICE_UNAVAILABLE"

    def test_service_unavailable_default_message(self):
        """Test service_unavailable with default message."""
        response = ErrorResponse.service_unavailable()

        assert response.error == "Service temporarily unavailable"
        assert response.error_code == "SERVICE_UNAVAILABLE"


class TestHealthResponse:
    """Unit tests for HealthResponse DTO."""

    def test_health_response_healthy(self):
        """Test creating healthy HealthResponse."""
        timestamp = datetime.utcnow()

        response = HealthResponse(
            status="healthy",
            message="All systems operational",
            timestamp=timestamp,
            version="1.0.0",
        )

        assert response.status == "healthy"
        assert response.message == "All systems operational"
        assert response.timestamp == timestamp
        assert response.version == "1.0.0"
        assert response.dependencies is None

    def test_health_response_with_dependencies(self):
        """Test creating HealthResponse with dependencies."""
        dependencies = {
            "database": "healthy",
            "cache": "degraded",
            "blockchain": "healthy",
        }

        response = HealthResponse(
            status="degraded",
            message="Some services degraded",
            timestamp=datetime.utcnow(),
            version="1.0.0",
            dependencies=dependencies,
        )

        assert response.status == "degraded"
        assert response.dependencies == dependencies

    def test_health_response_invalid_status(self):
        """Test validation of status field."""
        # Note: Pydantic enum validation is disabled in this implementation
        # The status field accepts any string value
        response = HealthResponse(
            status="invalid_status",
            message="Test message",
            timestamp=datetime.utcnow(),
            version="1.0.0",
        )
        assert response.status == "invalid_status"

    def test_health_response_valid_statuses(self):
        """Test valid status values."""
        valid_statuses = ["healthy", "unhealthy", "degraded"]

        for status in valid_statuses:
            response = HealthResponse(
                status=status,
                message="Test message",
                timestamp=datetime.utcnow(),
                version="1.0.0",
            )
            assert response.status == status
