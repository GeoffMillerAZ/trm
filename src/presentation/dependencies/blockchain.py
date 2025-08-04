from src.application.use_cases.get_address_balance import GetAddressBalanceUseCase
from src.domain.services.blockchain_service import BlockchainService
from src.infrastructure.config.container import (
    get_balance_use_case as container_get_balance_use_case,
)
from src.infrastructure.config.container import (
    get_blockchain_service as container_get_blockchain_service,
)


async def get_blockchain_service() -> BlockchainService:
    """FastAPI dependency for blockchain service."""
    return await container_get_blockchain_service()


async def get_balance_use_case() -> GetAddressBalanceUseCase:
    """FastAPI dependency for balance use case."""
    return await container_get_balance_use_case()
