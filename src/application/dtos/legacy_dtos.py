"""Legacy DTOs for backward compatibility with original Flask API."""

from pydantic import BaseModel, Field


class LegacyBalanceResponse(BaseModel):
    """Legacy balance response matching original Flask API format."""

    balance: float = Field(
        ...,
        description="ETH balance as a float",
        json_schema_extra={"example": 1.5},
    )


class LegacyErrorResponse(BaseModel):
    """Legacy error response matching original Flask API format."""

    error: str = Field(
        ...,
        description="Error message",
        json_schema_extra={"example": "invalid address syntax"},
    )
