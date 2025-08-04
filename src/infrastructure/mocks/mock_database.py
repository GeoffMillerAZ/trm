"""Mock database implementation for testing."""

from typing import Any

from src.domain.entities.address_balance import AddressBalance
from src.domain.interfaces.database import DatabaseInterface
from src.domain.value_objects.ethereum_address import EthereumAddress


class MockDatabase(DatabaseInterface):
    """Mock database implementation for testing."""

    def __init__(self):
        """Initialize mock database with in-memory storage."""
        self.balances: list[AddressBalance] = []
        self.metadata: dict[str, dict[str, Any]] = {}
        self.save_balance_calls: list[AddressBalance] = []
        self.get_balance_history_calls: list[tuple] = []
        self.get_latest_balance_calls: list[EthereumAddress] = []
        self.save_metadata_calls: list[tuple] = []
        self.get_metadata_calls: list[str] = []

    async def save_balance(self, balance: AddressBalance) -> None:
        """Save address balance to mock storage."""
        self.save_balance_calls.append(balance)
        self.balances.append(balance)

    async def get_balance_history(
        self, address: EthereumAddress, limit: int = 100
    ) -> list[AddressBalance]:
        """Get balance history for an address from mock storage."""
        self.get_balance_history_calls.append((address, limit))

        # Filter balances for the specific address
        address_balances = [
            balance
            for balance in self.balances
            if balance.address.value == address.value
        ]

        # Sort by retrieved_at descending (most recent first)
        address_balances.sort(key=lambda b: b.retrieved_at, reverse=True)

        # Apply limit
        return address_balances[:limit]

    async def get_latest_balance(
        self, address: EthereumAddress
    ) -> AddressBalance | None:
        """Get the most recent balance for an address from mock storage."""
        self.get_latest_balance_calls.append(address)

        history = await self.get_balance_history(address, limit=1)
        return history[0] if history else None

    async def save_metadata(self, key: str, value: dict[str, Any]) -> None:
        """Save metadata to mock storage."""
        self.save_metadata_calls.append((key, value))
        self.metadata[key] = value

    async def get_metadata(self, key: str) -> dict[str, Any] | None:
        """Get metadata from mock storage."""
        self.get_metadata_calls.append(key)
        return self.metadata.get(key)

    def reset(self) -> None:
        """Reset mock database state."""
        self.balances.clear()
        self.metadata.clear()
        self.save_balance_calls.clear()
        self.get_balance_history_calls.clear()
        self.get_latest_balance_calls.clear()
        self.save_metadata_calls.clear()
        self.get_metadata_calls.clear()


class FailingMockDatabase(DatabaseInterface):
    """Mock database that always fails - useful for testing error handling."""

    async def save_balance(self, balance: AddressBalance) -> None:
        """Always fail when saving balance."""
        raise RuntimeError("Mock database save_balance failure")

    async def get_balance_history(
        self, address: EthereumAddress, limit: int = 100
    ) -> list[AddressBalance]:
        """Always fail when getting balance history."""
        raise RuntimeError("Mock database get_balance_history failure")

    async def get_latest_balance(
        self, address: EthereumAddress
    ) -> AddressBalance | None:
        """Always fail when getting latest balance."""
        raise RuntimeError("Mock database get_latest_balance failure")

    async def save_metadata(self, key: str, value: dict[str, Any]) -> None:
        """Always fail when saving metadata."""
        raise RuntimeError("Mock database save_metadata failure")

    async def get_metadata(self, key: str) -> dict[str, Any] | None:
        """Always fail when getting metadata."""
        raise RuntimeError("Mock database get_metadata failure")
