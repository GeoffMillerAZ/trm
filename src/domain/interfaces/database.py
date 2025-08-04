"""Database interface for domain layer."""

from abc import ABC, abstractmethod
from typing import Any

from src.domain.entities.address_balance import AddressBalance
from src.domain.value_objects.ethereum_address import EthereumAddress


class DatabaseInterface(ABC):
    """Abstract database interface for domain layer."""

    @abstractmethod
    async def save_balance(self, balance: AddressBalance) -> None:
        """Save address balance to database."""
        pass

    @abstractmethod
    async def get_balance_history(
        self, address: EthereumAddress, limit: int = 100
    ) -> list[AddressBalance]:
        """Get balance history for an address."""
        pass

    @abstractmethod
    async def get_latest_balance(
        self, address: EthereumAddress
    ) -> AddressBalance | None:
        """Get the most recent balance for an address."""
        pass

    @abstractmethod
    async def save_metadata(self, key: str, value: dict[str, Any]) -> None:
        """Save metadata to database."""
        pass

    @abstractmethod
    async def get_metadata(self, key: str) -> dict[str, Any] | None:
        """Get metadata from database."""
        pass
