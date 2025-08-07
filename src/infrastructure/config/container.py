"""Dependency injection container."""

from pathlib import Path

from src.application.use_cases.get_address_balance import GetAddressBalanceUseCase
from src.domain.interfaces.cache import CacheInterface
from src.domain.interfaces.database import DatabaseInterface
from src.domain.interfaces.logger import LoggerInterface
from src.domain.interfaces.secrets import SecretsInterface
from src.domain.interfaces.tracing import TracingInterface
from src.domain.services.blockchain_service import BlockchainService
from src.infrastructure.cache.file_cache import FileCache
from src.infrastructure.cache.redis_cache import InMemoryCache, RedisCache
from src.infrastructure.config.settings import Environment, Settings, get_settings
from src.infrastructure.database.dynamodb_repository import DynamoDBRepository
from src.infrastructure.database.file_repository import FileRepository
from src.infrastructure.logging.cloudwatch_logger import (
    CloudWatchLogger,
    ConsoleLogger,
    StructuredLogger,
)
from src.infrastructure.logging.file_logger import FileLogger
from src.infrastructure.mocks.mock_blockchain_repository import MockBlockchainRepository
from src.infrastructure.mocks.mock_cache import MockCache
from src.infrastructure.mocks.mock_database import MockDatabase
from src.infrastructure.mocks.mock_logger import MockLogger
from src.infrastructure.mocks.mock_secrets import MockSecretsManager
from src.infrastructure.mocks.mock_tracer import MockTracer, SilentMockTracer
from src.infrastructure.repositories.filesystem_blockchain_repository import (
    FileSystemBlockchainRepository,
)
from src.infrastructure.repositories.infura_blockchain_repository import (
    InfuraBlockchainRepository,
)
from src.infrastructure.secrets.aws_secrets import (
    AWSSecretsManager,
    EnvironmentSecretsManager,
)
from src.infrastructure.secrets.file_secrets import FileSecretsManager
from src.infrastructure.tracing.file_tracer import FileTracer
from src.infrastructure.tracing.xray_tracer import ConsoleTracer, XRayTracer


class DIContainer:
    """Dependency injection container."""

    def __init__(self, settings: Settings):
        """Initialize container with settings."""
        self.settings = settings
        self._cache: CacheInterface | None = None
        self._database: DatabaseInterface | None = None
        self._logger: LoggerInterface | None = None
        self._secrets: SecretsInterface | None = None
        self._tracer: TracingInterface | None = None
        self._blockchain_service: BlockchainService | None = None
        self._get_balance_use_case: GetAddressBalanceUseCase | None = None

    async def get_cache(self) -> CacheInterface:
        """Get cache implementation based on environment."""
        if self._cache is None:
            if self.settings.environment == Environment.TESTING:
                self._cache = MockCache()
            elif self.settings.is_file_based:
                # Use file-based cache
                cache_dir = f"{self.settings.workspace_base_path}/cache"
                self._cache = FileCache(
                    cache_dir=cache_dir,
                    max_entries=self.settings.file_cache_max_entries,
                )
            elif not self.settings.cache_enabled:
                # Use mock cache when caching is disabled
                self._cache = MockCache()
            elif self.settings.use_mock_blockchain and not self.settings.redis_url:
                # Mock mode - use mock cache when no Redis URL is configured
                self._cache = MockCache()
            elif self.settings.is_local and not self.settings.redis_url.startswith(
                "redis://"
            ):
                # Use in-memory cache for local development without Redis
                self._cache = InMemoryCache()
            else:
                # Use Redis cache
                redis_config = self.settings.redis_config
                self._cache = RedisCache(**redis_config)

        return self._cache

    async def get_database(self) -> DatabaseInterface:
        """Get database implementation based on environment."""
        if self._database is None:
            if self.settings.environment == Environment.TESTING:
                self._database = MockDatabase()
            elif self.settings.is_file_based:
                # Use file-based database
                db_dir = f"{self.settings.workspace_base_path}/db"
                self._database = FileRepository(
                    db_dir=db_dir,
                    max_history_per_address=self.settings.file_db_max_history_per_address,
                )
                # Ensure database structure exists
                await self._database.create_table_if_not_exists()
            elif self.settings.use_mock_blockchain and not self.settings.dynamodb_endpoint:
                # Mock mode - use mock database when no DynamoDB endpoint is configured
                self._database = MockDatabase()
            else:
                # Use DynamoDB
                dynamodb_config = self.settings.dynamodb_config
                self._database = DynamoDBRepository(**dynamodb_config)

                # Create table if in local environment
                if self.settings.is_local:
                    await self._database.create_table_if_not_exists()

        return self._database

    async def get_logger(self) -> LoggerInterface:
        """Get logger implementation based on environment."""
        if self._logger is None:
            if self.settings.environment == Environment.TESTING:
                self._logger = MockLogger()
            elif self.settings.is_file_based:
                # Use file-based logger
                log_dir = f"{self.settings.workspace_base_path}/logging"
                self._logger = FileLogger(
                    log_dir=log_dir,
                    log_file_prefix="app",
                    max_log_files=self.settings.log_rotation_days,
                )
            elif self.settings.is_local:
                # Use console logger for local development
                self._logger = ConsoleLogger(enable_colors=True)
            else:
                # Use structured logger with CloudWatch for production
                console_logger = ConsoleLogger(enable_colors=False)

                if self.settings.enable_cloudwatch_logging:
                    cloudwatch_logger = CloudWatchLogger(
                        log_group_name=self.settings.cloudwatch_log_group,
                        log_stream_name=self.settings.cloudwatch_log_stream,
                        region_name=self.settings.aws_region,
                    )
                    self._logger = StructuredLogger(
                        console_logger=console_logger,
                        cloudwatch_logger=cloudwatch_logger,
                    )
                else:
                    self._logger = console_logger

        return self._logger

    async def get_secrets(self) -> SecretsInterface:
        """Get secrets implementation based on environment."""
        if self._secrets is None:
            if self.settings.environment == Environment.TESTING:
                self._secrets = MockSecretsManager()
            elif self.settings.is_file_based:
                # Use file-based secrets manager
                secrets_dir = f"{self.settings.workspace_base_path}/secrets"
                config_dir = f"{self.settings.workspace_base_path}/config"
                self._secrets = FileSecretsManager(
                    secrets_dir=secrets_dir,
                    config_dir=config_dir,
                    encrypt_secrets=self.settings.file_secrets_encrypt,
                )
            elif self.settings.secrets_backend == "aws":
                # Use AWS Secrets Manager
                self._secrets = AWSSecretsManager(
                    region_name=self.settings.aws_region,
                    endpoint_url=None,  # Use real AWS service
                    secret_prefix=self.settings.secrets_prefix,
                    parameter_prefix=self.settings.parameters_prefix,
                )
            elif self.settings.secrets_backend == "file":
                # Use file-based secrets manager
                secrets_file = (
                    self.settings.secrets_file_path
                    or f"{self.settings.workspace_base_path}/secrets/local.json"
                )
                config_dir = f"{self.settings.workspace_base_path}/config"
                self._secrets = FileSecretsManager(
                    secrets_dir=str(Path(secrets_file).parent),
                    config_dir=config_dir,
                    encrypt_secrets=bool(self.settings.secrets_encryption_key),
                )
            else:
                # Use environment variables
                self._secrets = EnvironmentSecretsManager()

        return self._secrets

    async def get_tracer(self) -> TracingInterface:
        """Get tracer implementation based on environment."""
        if self._tracer is None:
            if self.settings.environment == Environment.TESTING:
                self._tracer = MockTracer()
            elif (
                self.settings.is_file_based and self.settings.tracing_backend == "file"
            ):
                # Use file-based tracer only when explicitly requested
                trace_dir = f"{self.settings.workspace_base_path}/tracing"
                self._tracer = FileTracer(
                    trace_dir=trace_dir,
                    service_name=self.settings.tracing_service_name,
                    max_traces=self.settings.max_trace_files,
                )
            elif self.settings.tracing_backend == "xray":
                # Use AWS X-Ray
                self._tracer = XRayTracer(
                    service_name=self.settings.tracing_service_name,
                    sampling_rate=self.settings.tracing_sampling_rate,
                    use_local_mode=self.settings.enable_xray_local_mode,
                )
            elif self.settings.tracing_backend == "console":
                # Use console tracer for local development
                self._tracer = ConsoleTracer(
                    service_name=self.settings.tracing_service_name
                )
            else:
                # Silent tracer for performance testing
                self._tracer = SilentMockTracer()

        return self._tracer

    async def get_blockchain_service(self) -> BlockchainService:
        """Get blockchain service with dependencies."""
        if self._blockchain_service is None:
            # Use mock repository for testing or when configured
            if (
                self.settings.environment == Environment.TESTING
                or self.settings.use_mock_blockchain
            ):
                blockchain_repo = MockBlockchainRepository()
            elif (
                self.settings.is_file_based
                and self.settings.blockchain_backend == "filesystem"
            ):
                # Use filesystem repository for testing with real data
                blockchain_dir = f"{self.settings.workspace_base_path}/blockchain"
                blockchain_repo = FileSystemBlockchainRepository(
                    data_dir=blockchain_dir, auto_populate=True
                )
            else:
                # Get secrets to retrieve API key
                secrets = await self.get_secrets()
                api_key_secret = await secrets.get_secret("infura-api-key")
                api_key = (
                    api_key_secret.value
                    if api_key_secret
                    else self.settings.infura_api_key
                )

                blockchain_repo = InfuraBlockchainRepository(api_key=api_key)

            cache = await self.get_cache()
            database = await self.get_database()
            logger = await self.get_logger()
            tracer = await self.get_tracer()

            self._blockchain_service = BlockchainService(
                blockchain_repository=blockchain_repo,
                cache=cache,
                database=database,
                logger=logger,
                tracer=tracer,
            )

        return self._blockchain_service

    async def get_balance_use_case(self) -> GetAddressBalanceUseCase:
        """Get balance use case with dependencies."""
        if self._get_balance_use_case is None:
            blockchain_service = await self.get_blockchain_service()
            logger = await self.get_logger()
            tracer = await self.get_tracer()

            self._get_balance_use_case = GetAddressBalanceUseCase(
                blockchain_service=blockchain_service, logger=logger, tracer=tracer
            )

        return self._get_balance_use_case

    async def close(self) -> None:
        """Clean up resources."""
        if self._cache and hasattr(self._cache, "close"):
            await self._cache.close()


# Global container instance
_container: DIContainer | None = None


def get_container() -> DIContainer:
    """Get global container instance."""
    global _container
    if _container is None:
        settings = get_settings()
        _container = DIContainer(settings)
    return _container


async def get_cache() -> CacheInterface:
    """FastAPI dependency for cache."""
    container = get_container()
    return await container.get_cache()


async def get_database() -> DatabaseInterface:
    """FastAPI dependency for database."""
    container = get_container()
    return await container.get_database()


async def get_logger() -> LoggerInterface:
    """FastAPI dependency for logger."""
    container = get_container()
    return await container.get_logger()


async def get_blockchain_service() -> BlockchainService:
    """FastAPI dependency for blockchain service."""
    container = get_container()
    return await container.get_blockchain_service()


async def get_secrets() -> SecretsInterface:
    """FastAPI dependency for secrets."""
    container = get_container()
    return await container.get_secrets()


async def get_tracer() -> TracingInterface:
    """FastAPI dependency for tracer."""
    container = get_container()
    return await container.get_tracer()


async def get_balance_use_case() -> GetAddressBalanceUseCase:
    """FastAPI dependency for balance use case."""
    container = get_container()
    return await container.get_balance_use_case()
