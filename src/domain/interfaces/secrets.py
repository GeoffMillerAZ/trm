"""Secrets management interface for domain layer."""

from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass
class SecretValue:
    """Represents a secret value with metadata."""

    value: str
    version: str | None = None
    created_date: str | None = None
    last_accessed: str | None = None


class SecretsInterface(ABC):
    """Abstract secrets management interface for domain layer."""

    @abstractmethod
    async def get_secret(self, secret_name: str) -> SecretValue | None:
        """Retrieve a secret by name."""
        pass

    @abstractmethod
    async def get_parameter(self, parameter_name: str) -> str | None:
        """Retrieve a parameter by name (for non-sensitive config)."""
        pass

    @abstractmethod
    async def get_secrets_batch(
        self, secret_names: list[str]
    ) -> dict[str, SecretValue | None]:
        """Retrieve multiple secrets in a single call for efficiency."""
        pass

    @abstractmethod
    async def get_parameters_batch(
        self, parameter_names: list[str]
    ) -> dict[str, str | None]:
        """Retrieve multiple parameters in a single call for efficiency."""
        pass

    @abstractmethod
    async def set_secret(self, secret_name: str, secret_value: str) -> None:
        """Store a secret (for development/testing purposes)."""
        pass

    @abstractmethod
    async def set_parameter(self, parameter_name: str, parameter_value: str) -> None:
        """Store a parameter (for development/testing purposes)."""
        pass

    @abstractmethod
    async def delete_secret(self, secret_name: str) -> None:
        """Delete a secret (for cleanup purposes)."""
        pass

    @abstractmethod
    async def list_secrets(self, prefix: str | None = None) -> list[str]:
        """List available secrets with optional prefix filter."""
        pass
