"""Legacy health check endpoints matching Flask healthz blueprint."""

from fastapi import APIRouter
from fastapi.responses import PlainTextResponse

router = APIRouter(tags=["health"])


@router.get("/healthz/live", response_class=PlainTextResponse)
async def liveness():
    """
    Liveness probe endpoint.
    Returns simple text response for Kubernetes liveness checks.
    """
    return "OK"


@router.get("/healthz/ready", response_class=PlainTextResponse)
async def readiness():
    """
    Readiness probe endpoint.
    Returns simple text response for Kubernetes readiness checks.
    """
    return "OK"
