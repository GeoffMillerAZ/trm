"""Health check API endpoints."""

from datetime import datetime

from fastapi import APIRouter

from src.application.dtos.blockchain_dtos import HealthResponse

router = APIRouter(tags=["health"])


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Health check",
    description="Check if the API service is healthy and operational",
)
async def health_check() -> HealthResponse:
    """
    Health check endpoint.

    Returns the current health status of the API service.

    Returns:
        HealthResponse: Service health information
    """
    return HealthResponse(
        status="healthy",
        message="All systems operational",
        timestamp=datetime.utcnow(),
        version="2.0.0",
    )
