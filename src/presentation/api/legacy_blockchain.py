"""Legacy Flask-compatible blockchain API endpoints."""

import structlog
from fastapi import APIRouter, Depends, Path
from fastapi.responses import JSONResponse

from src.application.dtos.blockchain_dtos import BalanceRequest
from src.application.dtos.legacy_dtos import LegacyBalanceResponse, LegacyErrorResponse
from src.application.use_cases.get_address_balance import GetAddressBalanceUseCase
from src.presentation.dependencies.blockchain import get_balance_use_case

logger = structlog.get_logger(__name__)
router = APIRouter(tags=["blockchain"])


@router.get("/")
async def root_handler(
    use_case: GetAddressBalanceUseCase = Depends(get_balance_use_case),
) -> JSONResponse:
    """Root endpoint returns error for no address."""
    return JSONResponse(
        content={"error": "no address provided"},
        status_code=200,
    )


@router.get("/address/balance/{eth_address}")
async def process_address(
    eth_address: str = Path(
        ...,
        description="Ethereum address to check balance for",
    ),
    use_case: GetAddressBalanceUseCase = Depends(get_balance_use_case),
) -> JSONResponse:
    """
    Legacy endpoint matching original Flask API.

    Checks for the balance of a given eth address.
    Returns simple JSON with just balance or error.
    Always returns 200 OK status to match Flask behavior.
    """

    # Validate address format
    try:
        # Use same validation as original - case insensitive hex check
        import re

        pattern = r"^0x[0-9A-F]{40}$"
        if not bool(re.match(pattern, eth_address, flags=re.I)):
            raise ValueError("Invalid format")

    except (ValueError, AttributeError):
        logger.info("address has invalid syntax, address: %s submitted", eth_address)
        response = LegacyErrorResponse(error="invalid address syntax")
        return JSONResponse(content=response.model_dump(), status_code=200)

    try:
        # Create request object for use case
        request = BalanceRequest(address=eth_address)

        # Execute use case
        result = await use_case.execute(request)

        if result is None:
            # Return 0 balance on any error (matching original behavior)
            logger.debug("returning value for address %s", eth_address)
            response = LegacyBalanceResponse(balance=0)
            return JSONResponse(content=response.model_dump(), status_code=200)

        # Return balance in legacy format
        logger.debug("returning value for address %s", eth_address)
        response = LegacyBalanceResponse(balance=float(result.balance_eth))
        return JSONResponse(content=response.model_dump(), status_code=200)

    except Exception as e:
        logger.error("Error processing address", address=eth_address, error=str(e))
        # Return 0 balance on any error (matching original behavior)
        response = LegacyBalanceResponse(balance=0)
        return JSONResponse(content=response.model_dump(), status_code=200)
