from src.application.use_cases.get_block_by_hash import GetBlockByHashUseCase
from src.infrastructure.config.container import (
    get_blockchain_service as container_get_blockchain_service,
)
from src.infrastructure.repositories.infura_blockchain_repository import InfuraBlockchainRepository


async def get_block_by_hash_use_case() -> GetBlockByHashUseCase:
    """FastAPI dependency for get block by hash use case."""
    # Get the blockchain service from container
    from src.infrastructure.config.container import get_container
    from src.infrastructure.config.settings import get_settings
    from src.infrastructure.secrets.aws_secrets import EnvironmentSecretsManager
    
    container = get_container()
    settings = get_settings()
    
    # Create the blockchain repository directly (same logic as in container)
    if settings.use_mock_blockchain or settings.is_file_based:
        from src.infrastructure.mocks.mock_blockchain_repository import MockBlockchainRepository
        blockchain_repository = MockBlockchainRepository()
    else:
        # Get API key from environment or secrets
        secrets = await container.get_secrets()
        api_key_secret = await secrets.get_secret("infura-api-key")
        api_key = (
            api_key_secret.value
            if api_key_secret
            else settings.infura_api_key
        )
        blockchain_repository = InfuraBlockchainRepository(api_key=api_key)
    
    return GetBlockByHashUseCase(blockchain_repository)
