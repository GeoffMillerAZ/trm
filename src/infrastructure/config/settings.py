"""Application settings and configuration."""

import os
import sys
from enum import Enum
from pathlib import Path
from typing import Any

from pydantic import ConfigDict, Field, field_validator
from pydantic_settings import BaseSettings


class Environment(str, Enum):
    """Environment types."""

    LOCAL = "local"
    DEVELOPMENT = "development"
    DEV = "dev"  # Alias for development
    STAGING = "staging"
    PRODUCTION = "production"
    TESTING = "testing"
    FILE_BASED = "file_based"  # New environment for file-based infrastructure


class ConfigurationError(Exception):
    """Configuration validation error."""

    pass


class Settings(BaseSettings):
    """Application settings with validation."""

    # Environment
    environment: Environment = Environment.LOCAL
    debug: bool = False
    config_file: str | None = Field(None, description="Path to YAML configuration file")

    # API Settings
    api_title: str = "TRM Block Explorer API"
    api_version: str = "2.0.0"
    api_description: str = "Ethereum address analysis and compliance tracking API"

    # Infura Configuration
    infura_api_key: str = Field(
        "your_infura_key_here", description="Infura API key for Ethereum access"
    )
    infura_network: str = Field(
        "mainnet", description="Ethereum network (mainnet, goerli, sepolia)"
    )
    infura_project_secret: str | None = Field(
        None, description="Infura project secret (optional)"
    )

    # Cache Configuration (Redis)
    redis_url: str = Field("redis://localhost:6379", description="Redis connection URL")
    redis_password: str | None = Field(None, description="Redis password")
    cache_ttl_seconds: int = Field(
        300, ge=1, le=86400, description="Cache TTL in seconds (1-86400)"
    )
    cache_enabled: bool = Field(True, description="Enable caching")

    # Database Configuration (DynamoDB)
    dynamodb_table_name: str = Field(
        "trm-blockexplorer", description="DynamoDB table name"
    )
    dynamodb_endpoint: str | None = Field(
        None, description="DynamoDB endpoint URL (for local development)"
    )
    aws_region: str = Field("us-west-2", description="AWS region")
    aws_access_key_id: str | None = Field(None, description="AWS access key ID")
    aws_secret_access_key: str | None = Field(None, description="AWS secret access key")
    aws_session_token: str | None = Field(
        None, description="AWS session token (for STS)"
    )

    # DynamoDB Table Names
    address_watchlist_table: str = Field(
        "address-watchlist", description="Address watchlist table name"
    )
    suspicious_transactions_table: str = Field(
        "suspicious-transactions", description="Suspicious transactions table name"
    )
    investigation_notes_table: str = Field(
        "investigation-notes", description="Investigation notes table name"
    )

    # Logging Configuration
    log_level: str = Field(
        "INFO", description="Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)"
    )
    log_format: str = Field("json", description="Log format (json, text)")
    cloudwatch_log_group: str = Field(
        "trm-blockexplorer", description="CloudWatch log group name"
    )
    cloudwatch_log_stream: str = Field("api", description="CloudWatch log stream name")
    enable_cloudwatch_logging: bool = Field(
        False, description="Enable CloudWatch logging"
    )
    log_file_path: str | None = Field(
        None, description="Log file path for file-based logging"
    )
    log_rotation_size: str = Field("10MB", description="Log file rotation size")
    log_rotation_count: int = Field(5, description="Number of log files to keep")

    # Secrets Configuration
    secrets_backend: str = Field(
        "environment", description="Secrets backend (aws, environment, file)"
    )
    secrets_prefix: str = Field(
        "trm-blockexplorer/", description="Secrets prefix for AWS Secrets Manager"
    )
    parameters_prefix: str = Field(
        "/trm-blockexplorer/", description="Parameter prefix for AWS SSM"
    )
    secrets_file_path: str | None = Field(
        None, description="Path to secrets file (for file backend)"
    )
    secrets_encryption_key: str | None = Field(
        None, description="Encryption key for secrets file"
    )

    # Tracing Configuration
    tracing_backend: str = Field(
        "console", description="Tracing backend (xray, console, silent)"
    )
    tracing_service_name: str = Field(
        "trm-blockexplorer", description="Service name for tracing"
    )
    tracing_sampling_rate: float = Field(
        1.0, ge=0.0, le=1.0, description="Tracing sampling rate (0.0-1.0)"
    )
    enable_xray_local_mode: bool = Field(False, description="Enable X-Ray local mode")
    tracing_enabled: bool = Field(True, description="Enable distributed tracing")

    # Development Settings
    enable_cors: bool = True
    cors_origins: list[str] = ["*"]

    # File-based Infrastructure Settings
    use_file_based_infrastructure: bool = False
    workspace_base_path: str = "workspace"
    file_cache_max_entries: int = 1000
    file_db_max_history_per_address: int = 100
    log_rotation_days: int = 7
    file_secrets_encrypt: bool = False
    max_trace_files: int = 1000

    # Blockchain Configuration
    blockchain_backend: str = Field(
        "infura", description="Blockchain backend (infura, filesystem, mock)"
    )

    # Mock Settings
    use_mock_blockchain: bool = Field(
        False, description="Use mock blockchain repository instead of Infura"
    )

    # Health Check Configuration
    health_check_timeout: int = Field(
        30, ge=1, le=300, description="Health check timeout in seconds"
    )
    health_check_interval: int = Field(
        30, ge=1, le=3600, description="Health check interval in seconds"
    )

    # Rate Limiting Configuration
    rate_limit_enabled: bool = Field(True, description="Enable rate limiting")
    rate_limit_requests_per_minute: int = Field(
        60, ge=1, description="Requests per minute per IP"
    )
    rate_limit_burst: int = Field(10, ge=1, description="Burst limit for rate limiting")

    # API Configuration
    api_cors_origins: list[str] = Field(["*"], description="CORS allowed origins")
    api_cors_methods: list[str] = Field(
        ["GET", "POST", "PUT", "DELETE"], description="CORS allowed methods"
    )
    api_max_request_size: int = Field(
        1024 * 1024, description="Maximum request size in bytes"
    )
    api_timeout: int = Field(
        30, ge=1, le=300, description="API request timeout in seconds"
    )

    # Monitoring Configuration
    metrics_enabled: bool = Field(True, description="Enable metrics collection")
    metrics_port: int = Field(
        9090, ge=1024, le=65535, description="Metrics server port"
    )
    prometheus_enabled: bool = Field(False, description="Enable Prometheus metrics")

    @field_validator("log_level")
    @classmethod
    def validate_log_level(cls, v):
        valid_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
        if v.upper() not in valid_levels:
            raise ValueError(f"log_level must be one of {valid_levels}")
        return v.upper()

    @field_validator("tracing_backend")
    @classmethod
    def validate_tracing_backend(cls, v):
        valid_backends = ["xray", "console", "silent"]
        if v not in valid_backends:
            raise ValueError(f"tracing_backend must be one of {valid_backends}")
        return v

    @field_validator("secrets_backend")
    @classmethod
    def validate_secrets_backend(cls, v):
        valid_backends = ["aws", "environment", "file"]
        if v not in valid_backends:
            raise ValueError(f"secrets_backend must be one of {valid_backends}")
        return v

    @field_validator("log_format")
    @classmethod
    def validate_log_format(cls, v):
        valid_formats = ["json", "text"]
        if v not in valid_formats:
            raise ValueError(f"log_format must be one of {valid_formats}")
        return v

    model_config = ConfigDict(
        env_file=".env",
        case_sensitive=False,
        validate_assignment=True,
        extra="forbid",  # Prevent unknown configuration keys
    )

    @property
    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.environment == Environment.PRODUCTION

    @property
    def is_local(self) -> bool:
        """Check if running in local environment."""
        return self.environment == Environment.LOCAL

    @property
    def is_testing(self) -> bool:
        """Check if running in testing environment."""
        return self.environment == Environment.TESTING

    @property
    def is_file_based(self) -> bool:
        """Check if running in file-based environment."""
        return (
            self.environment == Environment.FILE_BASED
            or self.use_file_based_infrastructure
        )

    @property
    def is_development(self) -> bool:
        """Check if running in development environment."""
        return self.environment in (Environment.DEVELOPMENT, Environment.DEV)

    @property
    def is_staging(self) -> bool:
        """Check if running in staging environment."""
        return self.environment == Environment.STAGING

    @property
    def redis_config(self) -> dict:
        """Get Redis configuration."""
        if self.redis_url.startswith("redis://"):
            # Parse Redis URL
            import urllib.parse

            parsed = urllib.parse.urlparse(self.redis_url)
            return {
                "host": parsed.hostname or "localhost",
                "port": parsed.port or 6379,
                "password": parsed.password or self.redis_password,
                "db": int(parsed.path.lstrip("/")) if parsed.path else 0,
            }
        else:
            return {
                "host": self.redis_url,
                "port": 6379,
                "password": self.redis_password,
                "db": 0,
            }

    @property
    def dynamodb_config(self) -> dict:
        """Get DynamoDB configuration."""
        config = {
            "table_name": self.dynamodb_table_name,
            "region_name": self.aws_region,
        }

        if self.dynamodb_endpoint:
            config.update(
                {
                    "endpoint_url": self.dynamodb_endpoint,
                    "aws_access_key_id": self.aws_access_key_id or "local",
                    "aws_secret_access_key": self.aws_secret_access_key or "local",
                }
            )

        return config

    def validate_configuration(self) -> list[str]:
        """Validate configuration and return list of errors."""
        errors = []

        # Validate required configurations based on environment
        if not self.is_local and not self.is_testing:
            if self.infura_api_key == "your_infura_key_here":
                errors.append("infura_api_key is required for non-local environments")

        # Validate AWS configuration for production
        if self.is_production:
            if not self.aws_region:
                errors.append("aws_region is required for production")
            if self.secrets_backend == "aws" and not all(
                [self.aws_access_key_id, self.aws_secret_access_key]
            ):
                errors.append(
                    "AWS credentials are required when using AWS secrets backend"
                )

        # Validate cache configuration
        if self.cache_enabled and not self.redis_url:
            errors.append("redis_url is required when caching is enabled")

        # Validate secrets configuration
        if self.secrets_backend == "file" and not self.secrets_file_path:
            errors.append(
                "secrets_file_path is required when using file secrets backend"
            )

        # Validate logging configuration
        if self.enable_cloudwatch_logging and not self.cloudwatch_log_group:
            errors.append(
                "cloudwatch_log_group is required when CloudWatch logging is enabled"
            )

        # Validate file-based configuration
        if self.is_file_based:
            workspace_path = Path(self.workspace_base_path)
            if not workspace_path.exists():
                errors.append(
                    f"workspace_base_path '{self.workspace_base_path}' does not exist"
                )

        return errors

    def load_from_yaml(self, yaml_path: str) -> None:
        """Load configuration from YAML file."""
        try:
            import yaml

            with open(yaml_path) as f:
                yaml_config = yaml.safe_load(f)

            # Update settings with YAML values
            for key, value in yaml_config.items():
                if hasattr(self, key):
                    setattr(self, key, value)
        except Exception as e:
            raise ConfigurationError(
                f"Failed to load YAML configuration from {yaml_path}: {e}"
            ) from e

    def get_environment_info(self) -> dict[str, Any]:
        """Get environment information for debugging."""
        return {
            "environment": self.environment,
            "debug": self.debug,
            "is_production": self.is_production,
            "is_local": self.is_local,
            "is_testing": self.is_testing,
            "is_file_based": self.is_file_based,
            "cache_enabled": self.cache_enabled,
            "tracing_enabled": self.tracing_enabled,
            "metrics_enabled": self.metrics_enabled,
            "secrets_backend": self.secrets_backend,
            "tracing_backend": self.tracing_backend,
            "log_level": self.log_level,
        }


def create_settings(config_file: str | None = None, validate: bool = True) -> Settings:
    """Create and validate settings instance."""
    settings = Settings()

    # Load from YAML file if provided
    if config_file:
        settings.config_file = config_file
        settings.load_from_yaml(config_file)

    # Validate configuration
    if validate:
        errors = settings.validate_configuration()
        if errors:
            error_msg = "Configuration validation failed:\n" + "\n".join(
                f"  - {error}" for error in errors
            )
            print(f"ERROR: {error_msg}", file=sys.stderr)
            raise ConfigurationError(error_msg)

    return settings


# Global settings instance - will be initialized on first import
_settings: Settings | None = None


def get_settings() -> Settings:
    """Get the global settings instance."""
    global _settings
    if _settings is None:
        config_file = os.getenv("CONFIG_FILE")
        _settings = create_settings(config_file=config_file)
    return _settings


# Backward compatibility
settings = get_settings()
