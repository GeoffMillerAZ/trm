"""FastAPI blockchain API endpoints with proper HTTP semantics."""

import structlog
from fastapi import APIRouter, Depends, HTTPException, Path, status
from pydantic import ValidationError

from src.application.dtos.blockchain_dtos import (
    BalanceRequest,
    BalanceResponse,
    ErrorResponse,
)
from src.application.dtos.block_dtos import GetBlockByHashRequest, GetBlockByHashResponse
from src.application.use_cases.get_address_balance import GetAddressBalanceUseCase
from src.application.use_cases.get_block_by_hash import GetBlockByHashUseCase
from src.presentation.dependencies.block import get_block_by_hash_use_case
from src.presentation.dependencies.blockchain import get_balance_use_case

logger = structlog.get_logger(__name__)
router = APIRouter(
    tags=["blockchain"],
    responses={
        400: {"model": ErrorResponse, "description": "Validation error"},
        404: {"model": ErrorResponse, "description": "Address not found"},
        503: {"model": ErrorResponse, "description": "Service unavailable"},
    },
)


@router.get(
    "/block/{block_hash}",
    response_model=GetBlockByHashResponse,
    status_code=status.HTTP_200_OK,
    summary="Get block by hash",
    description="Retrieve a block by its hash",
)
async def get_block_by_hash(
    block_hash: str = Path(
        ...,
        description="Block hash to retrieve",
        min_length=66,
        max_length=66,
        pattern=r"^0x[a-fA-F0-9]{64}$",
    ),
    use_case: GetBlockByHashUseCase = Depends(get_block_by_hash_use_case),
) -> GetBlockByHashResponse:
    """
    Get a block by its hash.
    """
    try:
        request = GetBlockByHashRequest(block_hash=block_hash)
        response = await use_case.execute(request)
        if not response.block:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Block not found")
        return response
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get(
    "/address/{eth_address}/balance",
    response_model=BalanceResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Ethereum address balance",
    description="Retrieve the current ETH balance for a given Ethereum address",
    responses={
        200: {
            "description": "Successfully retrieved balance",
            "content": {
                "application/json": {
                    "example": {
                        "address": "0xc94770007dda54cf92009bff0de90c06f603a09f",
                        "balance_eth": 1.5,
                        "retrieved_at": "2024-01-15T10:30:00Z",
                        "source": "blockchain",
                    }
                }
            },
        }
    },
)
async def get_address_balance(
    eth_address: str = Path(
        ...,
        description="Ethereum address to check balance for",
        min_length=42,
        max_length=42,
        pattern=r"^0x[0-9A-Fa-f]{40}$",
        examples=["0xc94770007dda54cF92009BFF0dE90c06F603a09f"],
    ),
    use_case: GetAddressBalanceUseCase = Depends(get_balance_use_case),
) -> BalanceResponse:
    """
    Get Ethereum address balance.

    Returns the current ETH balance for the specified Ethereum address.
    The balance is retrieved from the blockchain via Infura and may be cached
    for performance optimization.

    Args:
        eth_address: Valid Ethereum address (42 characters, hex format)

    Returns:
        BalanceResponse: Address balance information with metadata

    Raises:
        HTTPException: 400 for invalid address format
        HTTPException: 503 for service unavailable
    """
    logger.info("Balance request received", address=eth_address)

    try:
        # Validate address format using Pydantic
        request = BalanceRequest(address=eth_address)
    except ValidationError as e:
        logger.warning("Invalid address format", address=eth_address, error=str(e))
        error_response = ErrorResponse.invalid_address(eth_address)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=error_response.dict()
        ) from e

    try:
        response = await use_case.execute(request)

        if response is None:
            # This shouldn't happen with proper validation, but handle gracefully
            logger.error(
                "Use case returned None for valid address", address=eth_address
            )
            error_response = ErrorResponse.service_unavailable(
                "Unable to retrieve balance at this time"
            )
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=error_response.dict(),
            )

        logger.info(
            "Balance response prepared",
            address=eth_address,
            balance=float(response.balance_eth),
            source=response.source,
        )

        return response

    except Exception as e:
        logger.error(
            "Unexpected error retrieving balance", address=eth_address, error=str(e)
        )
        error_response = ErrorResponse.service_unavailable(
            "Internal server error occurred"
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=error_response.dict(),
        ) from e
