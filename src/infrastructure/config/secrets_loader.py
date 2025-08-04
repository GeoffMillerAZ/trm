"""Secrets loader for application configuration."""

from typing import Any

from src.domain.interfaces.logger import LoggerInterface
from src.domain.interfaces.secrets import SecretsInterface


class SecretsLoader:
    """Load application secrets and parameters from secrets backend."""

    def __init__(self, secrets: SecretsInterface, logger: LoggerInterface):
        """Initialize secrets loader.

        Args:
            secrets: Secrets interface implementation
            logger: Logger interface implementation
        """
        self.secrets = secrets
        self.logger = logger
        self._cached_secrets: dict[str, str] = {}

    async def load_application_secrets(self) -> dict[str, Any]:
        """Load all required application secrets.

        Returns:
            Dictionary containing all loaded secrets
        """
        await self.logger.info("Loading application secrets")

        # Define required secrets
        required_secrets = [
            "infura-api-key",
            "redis-password",
            "database-encryption-key",
        ]

        # Define optional secrets
        optional_secrets = ["aws-access-key", "aws-secret-key", "monitoring-api-key"]

        # Load secrets in batch for efficiency
        try:
            # Load required secrets
            required_results = await self.secrets.get_secrets_batch(required_secrets)

            # Load optional secrets
            optional_results = await self.secrets.get_secrets_batch(optional_secrets)

            # Process results
            loaded_secrets = {}
            missing_required = []

            # Check required secrets
            for secret_name in required_secrets:
                secret_value = required_results.get(secret_name)
                if secret_value and secret_value.value:
                    loaded_secrets[secret_name] = secret_value.value
                    self._cached_secrets[secret_name] = secret_value.value
                    await self.logger.debug(
                        f"Successfully loaded required secret: {secret_name}"
                    )
                else:
                    missing_required.append(secret_name)
                    await self.logger.warning(f"Missing required secret: {secret_name}")

            # Check optional secrets
            for secret_name in optional_secrets:
                secret_value = optional_results.get(secret_name)
                if secret_value and secret_value.value:
                    loaded_secrets[secret_name] = secret_value.value
                    self._cached_secrets[secret_name] = secret_value.value
                    await self.logger.debug(
                        f"Successfully loaded optional secret: {secret_name}"
                    )
                else:
                    await self.logger.debug(f"Optional secret not found: {secret_name}")

            # Handle missing required secrets
            if missing_required:
                error_msg = f"Missing required secrets: {', '.join(missing_required)}"
                await self.logger.error(error_msg)
                raise ValueError(error_msg)

            await self.logger.info(
                f"Successfully loaded {len(loaded_secrets)} secrets",
                metadata={"secrets_count": len(loaded_secrets)},
            )

            return loaded_secrets

        except Exception as e:
            await self.logger.error("Failed to load application secrets", exception=e)
            raise

    async def load_application_parameters(self) -> dict[str, Any]:
        """Load application configuration parameters.

        Returns:
            Dictionary containing all loaded parameters
        """
        await self.logger.info("Loading application parameters")

        # Define configuration parameters
        config_parameters = [
            "cache-ttl-seconds",
            "rate-limit-requests-per-minute",
            "blockchain-network",
            "log-level",
            "enable-tracing",
            "tracing-sample-rate",
        ]

        try:
            # Load parameters in batch
            results = await self.secrets.get_parameters_batch(config_parameters)

            loaded_parameters = {}

            for param_name in config_parameters:
                param_value = results.get(param_name)
                if param_value:
                    loaded_parameters[param_name] = param_value
                    await self.logger.debug(
                        f"Successfully loaded parameter: {param_name}"
                    )
                else:
                    await self.logger.debug(
                        f"Parameter not found (using default): {param_name}"
                    )

            await self.logger.info(
                f"Successfully loaded {len(loaded_parameters)} parameters",
                metadata={"parameters_count": len(loaded_parameters)},
            )

            return loaded_parameters

        except Exception as e:
            await self.logger.error(
                "Failed to load application parameters", exception=e
            )
            # Parameters are optional, so don't fail
            return {}

    async def get_secret(self, secret_name: str, required: bool = True) -> str | None:
        """Get a single secret value.

        Args:
            secret_name: Name of the secret
            required: Whether the secret is required

        Returns:
            Secret value or None if not found and not required

        Raises:
            ValueError: If required secret is not found
        """
        # Check cache first
        if secret_name in self._cached_secrets:
            return self._cached_secrets[secret_name]

        try:
            secret_value = await self.secrets.get_secret(secret_name)

            if secret_value and secret_value.value:
                self._cached_secrets[secret_name] = secret_value.value
                return secret_value.value
            elif required:
                error_msg = f"Required secret not found: {secret_name}"
                await self.logger.error(error_msg)
                raise ValueError(error_msg)
            else:
                await self.logger.debug(f"Optional secret not found: {secret_name}")
                return None

        except Exception as e:
            if required:
                await self.logger.error(
                    f"Failed to retrieve required secret: {secret_name}", exception=e
                )
                raise
            else:
                await self.logger.warning(
                    f"Failed to retrieve optional secret: {secret_name}", exception=e
                )
                return None

    async def refresh_secret(self, secret_name: str) -> str | None:
        """Refresh a cached secret by fetching it again.

        Args:
            secret_name: Name of the secret to refresh

        Returns:
            Updated secret value or None if not found
        """
        await self.logger.debug(f"Refreshing secret: {secret_name}")

        # Remove from cache to force reload
        self._cached_secrets.pop(secret_name, None)

        try:
            secret_value = await self.secrets.get_secret(secret_name)

            if secret_value and secret_value.value:
                self._cached_secrets[secret_name] = secret_value.value
                await self.logger.debug(f"Successfully refreshed secret: {secret_name}")
                return secret_value.value
            else:
                await self.logger.warning(
                    f"Secret not found during refresh: {secret_name}"
                )
                return None

        except Exception as e:
            await self.logger.error(
                f"Failed to refresh secret: {secret_name}", exception=e
            )
            return None

    def get_cached_secrets(self) -> dict[str, str]:
        """Get all cached secrets (for debugging/monitoring).

        Returns:
            Dictionary of cached secret names (values are redacted)
        """
        return dict.fromkeys(self._cached_secrets.keys(), "[REDACTED]")
