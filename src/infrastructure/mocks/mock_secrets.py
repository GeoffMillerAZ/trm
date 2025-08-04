"""Mock secrets implementation for testing."""

from datetime import datetime

from src.domain.interfaces.secrets import SecretsInterface, SecretValue


class MockSecretsManager(SecretsInterface):
    """Mock secrets manager implementation for testing."""

    def __init__(self):
        """Initialize mock secrets manager with in-memory storage."""
        self.secrets: dict[str, SecretValue] = {}
        self.parameters: dict[str, str] = {}

        # Call tracking
        self.get_secret_calls: list[str] = []
        self.get_parameter_calls: list[str] = []
        self.get_secrets_batch_calls: list[list[str]] = []
        self.get_parameters_batch_calls: list[list[str]] = []
        self.set_secret_calls: list[tuple] = []
        self.set_parameter_calls: list[tuple] = []
        self.delete_secret_calls: list[str] = []
        self.list_secrets_calls: list[str | None] = []

    async def get_secret(self, secret_name: str) -> SecretValue | None:
        """Retrieve a secret from mock storage."""
        self.get_secret_calls.append(secret_name)
        return self.secrets.get(secret_name)

    async def get_parameter(self, parameter_name: str) -> str | None:
        """Retrieve a parameter from mock storage."""
        self.get_parameter_calls.append(parameter_name)
        return self.parameters.get(parameter_name)

    async def get_secrets_batch(
        self, secret_names: list[str]
    ) -> dict[str, SecretValue | None]:
        """Retrieve multiple secrets from mock storage."""
        self.get_secrets_batch_calls.append(secret_names)

        results = {}
        for name in secret_names:
            results[name] = self.secrets.get(name)

        return results

    async def get_parameters_batch(
        self, parameter_names: list[str]
    ) -> dict[str, str | None]:
        """Retrieve multiple parameters from mock storage."""
        self.get_parameters_batch_calls.append(parameter_names)

        results = {}
        for name in parameter_names:
            results[name] = self.parameters.get(name)

        return results

    async def set_secret(self, secret_name: str, secret_value: str) -> None:
        """Store a secret in mock storage."""
        self.set_secret_calls.append((secret_name, secret_value))

        self.secrets[secret_name] = SecretValue(
            value=secret_value,
            version="mock-v1",
            created_date=datetime.utcnow().isoformat(),
        )

    async def set_parameter(self, parameter_name: str, parameter_value: str) -> None:
        """Store a parameter in mock storage."""
        self.set_parameter_calls.append((parameter_name, parameter_value))
        self.parameters[parameter_name] = parameter_value

    async def delete_secret(self, secret_name: str) -> None:
        """Delete a secret from mock storage."""
        self.delete_secret_calls.append(secret_name)
        self.secrets.pop(secret_name, None)

    async def list_secrets(self, prefix: str | None = None) -> list[str]:
        """List available secrets with optional prefix filter."""
        self.list_secrets_calls.append(prefix)

        if prefix is None:
            return list(self.secrets.keys())

        return [name for name in self.secrets.keys() if name.startswith(prefix)]

    def reset(self) -> None:
        """Reset mock secrets manager state."""
        self.secrets.clear()
        self.parameters.clear()
        self.get_secret_calls.clear()
        self.get_parameter_calls.clear()
        self.get_secrets_batch_calls.clear()
        self.get_parameters_batch_calls.clear()
        self.set_secret_calls.clear()
        self.set_parameter_calls.clear()
        self.delete_secret_calls.clear()
        self.list_secrets_calls.clear()

    def add_preset_secret(
        self, name: str, value: str, version: str = "mock-v1"
    ) -> None:
        """Add a preset secret for testing."""
        self.secrets[name] = SecretValue(
            value=value, version=version, created_date=datetime.utcnow().isoformat()
        )

    def add_preset_parameter(self, name: str, value: str) -> None:
        """Add a preset parameter for testing."""
        self.parameters[name] = value


class FailingMockSecretsManager(SecretsInterface):
    """Mock secrets manager that always fails - useful for testing error handling."""

    async def get_secret(self, secret_name: str) -> SecretValue | None:
        """Always fail when getting secret."""
        raise RuntimeError(f"Mock secrets manager get_secret failure for {secret_name}")

    async def get_parameter(self, parameter_name: str) -> str | None:
        """Always fail when getting parameter."""
        raise RuntimeError(
            f"Mock secrets manager get_parameter failure for {parameter_name}"
        )

    async def get_secrets_batch(
        self, secret_names: list[str]
    ) -> dict[str, SecretValue | None]:
        """Always fail when getting secrets batch."""
        raise RuntimeError("Mock secrets manager get_secrets_batch failure")

    async def get_parameters_batch(
        self, parameter_names: list[str]
    ) -> dict[str, str | None]:
        """Always fail when getting parameters batch."""
        raise RuntimeError("Mock secrets manager get_parameters_batch failure")

    async def set_secret(self, secret_name: str, secret_value: str) -> None:
        """Always fail when setting secret."""
        raise RuntimeError(f"Mock secrets manager set_secret failure for {secret_name}")

    async def set_parameter(self, parameter_name: str, parameter_value: str) -> None:
        """Always fail when setting parameter."""
        raise RuntimeError(
            f"Mock secrets manager set_parameter failure for {parameter_name}"
        )

    async def delete_secret(self, secret_name: str) -> None:
        """Always fail when deleting secret."""
        raise RuntimeError(
            f"Mock secrets manager delete_secret failure for {secret_name}"
        )

    async def list_secrets(self, prefix: str | None = None) -> list[str]:
        """Always fail when listing secrets."""
        raise RuntimeError("Mock secrets manager list_secrets failure")


class SlowMockSecretsManager(SecretsInterface):
    """Mock secrets manager with artificial delays for testing timeouts."""

    def __init__(self, delay_seconds: float = 1.0):
        """Initialize slow mock secrets manager.

        Args:
            delay_seconds: Artificial delay to introduce
        """
        self.delay_seconds = delay_seconds
        self.storage = MockSecretsManager()

    async def _delay(self) -> None:
        """Introduce artificial delay."""
        import asyncio

        await asyncio.sleep(self.delay_seconds)

    async def get_secret(self, secret_name: str) -> SecretValue | None:
        """Retrieve secret with delay."""
        await self._delay()
        return await self.storage.get_secret(secret_name)

    async def get_parameter(self, parameter_name: str) -> str | None:
        """Retrieve parameter with delay."""
        await self._delay()
        return await self.storage.get_parameter(parameter_name)

    async def get_secrets_batch(
        self, secret_names: list[str]
    ) -> dict[str, SecretValue | None]:
        """Retrieve secrets batch with delay."""
        await self._delay()
        return await self.storage.get_secrets_batch(secret_names)

    async def get_parameters_batch(
        self, parameter_names: list[str]
    ) -> dict[str, str | None]:
        """Retrieve parameters batch with delay."""
        await self._delay()
        return await self.storage.get_parameters_batch(parameter_names)

    async def set_secret(self, secret_name: str, secret_value: str) -> None:
        """Store secret with delay."""
        await self._delay()
        await self.storage.set_secret(secret_name, secret_value)

    async def set_parameter(self, parameter_name: str, parameter_value: str) -> None:
        """Store parameter with delay."""
        await self._delay()
        await self.storage.set_parameter(parameter_name, parameter_value)

    async def delete_secret(self, secret_name: str) -> None:
        """Delete secret with delay."""
        await self._delay()
        await self.storage.delete_secret(secret_name)

    async def list_secrets(self, prefix: str | None = None) -> list[str]:
        """List secrets with delay."""
        await self._delay()
        return await self.storage.list_secrets(prefix)
