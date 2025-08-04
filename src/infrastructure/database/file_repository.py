"""File-based implementation of database interface."""

import json
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any

from src.domain.entities.address_balance import AddressBalance
from src.domain.interfaces.database import DatabaseInterface
from src.domain.value_objects.ethereum_address import EthereumAddress


class FileRepository(DatabaseInterface):
    """File-based database implementation storing records as JSON files."""

    def __init__(
        self, db_dir: str = "workspace/db", max_history_per_address: int = 100
    ):
        """Initialize file-based database.

        Args:
            db_dir: Directory to store database files
            max_history_per_address: Maximum balance history entries per address
        """
        self.db_dir = Path(db_dir).resolve()
        self.max_history_per_address = max_history_per_address

        # Ensure database directories exist
        self.balances_dir = self.db_dir / "balances"
        self.metadata_dir = self.db_dir / "metadata"
        self.indexes_dir = self.db_dir / "indexes"

        for directory in [self.balances_dir, self.metadata_dir, self.indexes_dir]:
            directory.mkdir(parents=True, exist_ok=True)

    def _get_address_dir(self, address: str) -> Path:
        """Get directory for address balance files."""
        # Create subdirectories based on address prefix for better organization
        prefix = address.lower()[:6]  # First 6 chars after 0x
        address_dir = self.balances_dir / prefix / address.lower()
        address_dir.mkdir(parents=True, exist_ok=True)
        return address_dir

    def _balance_to_dict(self, balance: AddressBalance) -> dict:
        """Convert AddressBalance to dictionary for JSON storage."""
        return {
            "address": balance.address.value,
            "balance_eth": str(
                balance.balance_eth
            ),  # Store as string to preserve precision
            "retrieved_at": balance.retrieved_at.isoformat(),
            "source": balance.source,
            "id": str(uuid.uuid4()),  # Unique identifier for this record
        }

    def _dict_to_balance(self, data: dict) -> AddressBalance:
        """Convert dictionary to AddressBalance entity."""
        from decimal import Decimal

        return AddressBalance(
            address=EthereumAddress(data["address"]),
            balance_eth=Decimal(data["balance_eth"]),
            retrieved_at=datetime.fromisoformat(data["retrieved_at"]),
            source=data.get("source", "blockchain"),
        )

    def _atomic_write_json(self, file_path: Path, data: Any) -> None:
        """Atomically write JSON data to file."""
        temp_file = file_path.with_suffix(".tmp")
        try:
            with open(temp_file, "w") as f:
                json.dump(data, f, indent=2, default=str)

            # Atomic rename
            temp_file.rename(file_path)

        except OSError:
            # Clean up temp file on error
            try:
                temp_file.unlink()
            except OSError:
                pass
            raise

    def _update_address_index(self, address: str) -> None:
        """Update index with address information."""
        index_file = self.indexes_dir / "addresses.json"

        # Load existing index
        addresses = set()
        if index_file.exists():
            try:
                with open(index_file) as f:
                    addresses = set(json.load(f))
            except (json.JSONDecodeError, OSError):
                addresses = set()

        # Add new address
        addresses.add(address.lower())

        # Save updated index
        self._atomic_write_json(index_file, sorted(addresses))

    def _cleanup_old_balances(self, address_dir: Path) -> None:
        """Remove old balance files if exceeding max history."""
        balance_files = list(address_dir.glob("*.json"))

        if len(balance_files) <= self.max_history_per_address:
            return

        # Sort by modification time, oldest first
        balance_files.sort(key=lambda f: f.stat().st_mtime)

        # Remove oldest files
        for balance_file in balance_files[
            : len(balance_files) - self.max_history_per_address
        ]:
            try:
                balance_file.unlink()
            except OSError:
                pass

    async def save_balance(self, balance: AddressBalance) -> None:
        """Save address balance to database."""
        address_dir = self._get_address_dir(balance.address.value)

        # Create filename with timestamp for ordering
        timestamp = balance.retrieved_at.strftime("%Y%m%d_%H%M%S_%f")
        balance_file = address_dir / f"{timestamp}.json"

        # Convert to dictionary and save
        balance_data = self._balance_to_dict(balance)
        self._atomic_write_json(balance_file, balance_data)

        # Update latest balance symlink/file
        latest_file = address_dir / "latest.json"
        self._atomic_write_json(latest_file, balance_data)

        # Update address index
        self._update_address_index(balance.address.value)

        # Cleanup old balances
        self._cleanup_old_balances(address_dir)

    async def get_balance_history(
        self, address: EthereumAddress, limit: int = 100
    ) -> list[AddressBalance]:
        """Get balance history for an address."""
        address_dir = self._get_address_dir(address.value)

        if not address_dir.exists():
            return []

        # Get all balance files, excluding latest.json
        balance_files = [
            f for f in address_dir.glob("*.json") if f.name != "latest.json"
        ]

        # Sort by modification time, newest first
        balance_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)

        # Limit results
        balance_files = balance_files[:limit]

        balances = []
        for balance_file in balance_files:
            try:
                with open(balance_file) as f:
                    data = json.load(f)

                balance = self._dict_to_balance(data)
                balances.append(balance)

            except (json.JSONDecodeError, OSError, KeyError, ValueError):
                # Skip corrupted files
                continue

        return balances

    async def get_latest_balance(
        self, address: EthereumAddress
    ) -> AddressBalance | None:
        """Get the most recent balance for an address."""
        address_dir = self._get_address_dir(address.value)
        latest_file = address_dir / "latest.json"

        if not latest_file.exists():
            return None

        try:
            with open(latest_file) as f:
                data = json.load(f)

            return self._dict_to_balance(data)

        except (json.JSONDecodeError, OSError, KeyError, ValueError):
            # Try to recover from balance history
            history = await self.get_balance_history(address, limit=1)
            return history[0] if history else None

    async def save_metadata(self, key: str, value: dict[str, Any]) -> None:
        """Save metadata to database."""
        metadata_file = self.metadata_dir / f"{key}.json"

        metadata = {
            "key": key,
            "value": value,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }

        # If file exists, preserve created_at
        if metadata_file.exists():
            try:
                with open(metadata_file) as f:
                    existing_data = json.load(f)
                metadata["created_at"] = existing_data.get(
                    "created_at", metadata["created_at"]
                )
            except (json.JSONDecodeError, OSError):
                pass

        self._atomic_write_json(metadata_file, metadata)

    async def get_metadata(self, key: str) -> dict[str, Any] | None:
        """Get metadata from database."""
        metadata_file = self.metadata_dir / f"{key}.json"

        if not metadata_file.exists():
            return None

        try:
            with open(metadata_file) as f:
                data = json.load(f)

            return data.get("value")

        except (json.JSONDecodeError, OSError, KeyError):
            return None

    def get_database_stats(self) -> dict:
        """Get database statistics for debugging."""
        stats = {
            "total_addresses": 0,
            "total_balance_records": 0,
            "total_metadata_records": 0,
            "total_size_bytes": 0,
            "oldest_balance": None,
            "newest_balance": None,
        }

        # Count addresses from index
        index_file = self.indexes_dir / "addresses.json"
        if index_file.exists():
            try:
                with open(index_file) as f:
                    addresses = json.load(f)
                stats["total_addresses"] = len(addresses)
            except (json.JSONDecodeError, OSError):
                pass

        # Count balance records and calculate size
        balance_times = []
        for balance_file in self.balances_dir.rglob("*.json"):
            if balance_file.name != "latest.json":
                try:
                    file_stat = balance_file.stat()
                    stats["total_balance_records"] += 1
                    stats["total_size_bytes"] += file_stat.st_size
                    balance_times.append(file_stat.st_mtime)
                except OSError:
                    pass

        # Count metadata records
        for metadata_file in self.metadata_dir.glob("*.json"):
            try:
                file_stat = metadata_file.stat()
                stats["total_metadata_records"] += 1
                stats["total_size_bytes"] += file_stat.st_size
            except OSError:
                pass

        if balance_times:
            stats["oldest_balance"] = datetime.fromtimestamp(
                min(balance_times)
            ).isoformat()
            stats["newest_balance"] = datetime.fromtimestamp(
                max(balance_times)
            ).isoformat()

        return stats

    async def create_table_if_not_exists(self) -> None:
        """Create database structure if it doesn't exist (compatibility method)."""
        # File-based implementation doesn't need table creation
        # But we ensure directories exist
        for directory in [self.balances_dir, self.metadata_dir, self.indexes_dir]:
            directory.mkdir(parents=True, exist_ok=True)
