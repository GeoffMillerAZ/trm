"""Pydantic models for blockchain API requests and responses."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator
from pydantic.functional_serializers import field_serializer


class BalanceRequest(BaseModel):
    """Request model for address balance lookup."""

    address: str = Field(
        ...,
        description="Ethereum address to check balance for",
        min_length=42,
        max_length=42,
        json_schema_extra={"example": "0xc94770007dda54cF92009BFF0dE90c06F603a09f"},
    )

    @field_validator("address")
    @classmethod
    def validate_ethereum_address(cls, v: str) -> str:
        """Validate Ethereum address format (case-insensitive)."""
        import re

        # Case-insensitive validation to match original Flask behavior
        pattern = r"^0x[0-9A-Fa-f]{40}$"
        if not re.match(pattern, v, re.IGNORECASE):
            raise ValueError("Invalid Ethereum address format")
        return v.lower()


class BalanceResponse(BaseModel):
    """Response model for address balance."""

    address: str = Field(
        ...,
        description="The Ethereum address that was queried",
        json_schema_extra={"example": "0xc94770007dda54cf92009bff0de90c06f603a09f"},
    )
    balance_eth: Decimal = Field(
        ..., description="Balance in ETH", ge=0, json_schema_extra={"example": 1.5}
    )
    retrieved_at: datetime = Field(
        ...,
        description="Timestamp when the balance was retrieved",
        json_schema_extra={"example": "2024-01-15T10:30:00Z"},
    )
    source: str = Field(
        ...,
        description="Source of the balance data",
        json_schema_extra={"example": "blockchain", "enum": ["cache", "blockchain"]},
    )

    @classmethod
    def from_address_balance(
        cls, address_balance, source: str = "blockchain"
    ) -> "BalanceResponse":
        """Create response from AddressBalance entity."""
        return cls(
            address=address_balance.address.value,
            balance_eth=address_balance.balance_eth,
            retrieved_at=address_balance.retrieved_at,
            source=source,
        )

    model_config = ConfigDict()

    @field_serializer("balance_eth")
    def serialize_decimal(self, v: Decimal) -> float:
        """Serialize Decimal to float for JSON."""
        return float(v)


class ErrorDetail(BaseModel):
    """Detailed error information."""

    field: str | None = Field(
        None, description="Field name that caused the error (for validation errors)"
    )
    message: str = Field(..., description="Human-readable error message")
    code: str = Field(..., description="Machine-readable error code")


class ErrorResponse(BaseModel):
    """Standardized error response model."""

    error: str = Field(
        ...,
        description="High-level error description",
        json_schema_extra={"example": "Validation failed"},
    )
    error_code: str = Field(
        ...,
        description="Machine-readable error code",
        json_schema_extra={"example": "VALIDATION_ERROR"},
    )
    details: list[ErrorDetail] | None = Field(
        None, description="Detailed error information"
    )
    request_id: str | None = Field(
        None, description="Request correlation ID for tracing"
    )

    @classmethod
    def validation_error(cls, message: str = "Invalid request data") -> "ErrorResponse":
        """Create validation error response."""
        return cls(error=message, error_code="VALIDATION_ERROR")

    @classmethod
    def invalid_address(cls, address: str) -> "ErrorResponse":
        """Create invalid address error response."""
        return cls(
            error="Invalid Ethereum address format",
            error_code="INVALID_ADDRESS",
            details=[
                ErrorDetail(
                    field="address",
                    message=f"Address '{address}' is not a valid Ethereum address",
                    code="INVALID_FORMAT",
                )
            ],
        )

    @classmethod
    def service_unavailable(
        cls, message: str = "Service temporarily unavailable"
    ) -> "ErrorResponse":
        """Create service unavailable error response."""
        return cls(error=message, error_code="SERVICE_UNAVAILABLE")


class HealthResponse(BaseModel):
    """Health check response model."""

    status: str = Field(
        ...,
        description="Service health status",
        json_schema_extra={
            "example": "healthy",
            "enum": ["healthy", "unhealthy", "degraded"],
        },
    )
    message: str = Field(
        ...,
        description="Health status message",
        json_schema_extra={"example": "All systems operational"},
    )
    timestamp: datetime = Field(
        ...,
        description="Health check timestamp",
        json_schema_extra={"example": "2024-01-15T10:30:00Z"},
    )
    version: str = Field(
        ..., description="API version", json_schema_extra={"example": "2.0.0"}
    )
    dependencies: dict | None = Field(
        None, description="Status of external dependencies"
    )
