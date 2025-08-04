"""Filesystem-based implementation of blockchain repository for testing."""

import hashlib
import json
from datetime import datetime
from decimal import Decimal
from pathlib import Path

import structlog

from src.domain.repositories.blockchain_repository import BlockchainRepository
from src.domain.value_objects.ethereum_address import EthereumAddress

logger = structlog.get_logger(__name__)


class FileSystemBlockchainRepository(BlockchainRepository):
    """
    Filesystem implementation of the BlockchainRepository.

    Stores and retrieves balance data from JSON files for testing purposes.
    Pre-populates with well-known addresses and generates deterministic balances.
    """

    # Well-known addresses with specific balances for testing
    WELL_KNOWN_ADDRESSES = {
        # Major contracts and addresses
        "0x00000000219ab540356cbb839cbe05303d7705fa": Decimal(
            "50000000"
        ),  # Beacon Deposit Contract
        "0xd8da6bf26964af9d7eed9e03e53415d37aa96045": Decimal("325159.5"),  # Vitalik
        "0xde0b295669a9fd93d5f28d9ec85e40f4cb697bae": Decimal("683943.2"),  # EF Wallet
        "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2": Decimal(
            "2947652.8"
        ),  # WETH Contract
        "0xbe0eb53f46cd790cd13851d5eff43d12404d33e8": Decimal("1996008.5"),  # Binance 7
        "0xda9dfa130df4de4673b89022ee50ff26f6ea73cf": Decimal("2100000.0"),  # Kraken 13
        "0x0716a17fbaee714f1e6ab0f9d59edbc5f09815c0": Decimal(
            "1847291.3"
        ),  # Arbitrum One
        "0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be": Decimal("1652341.7"),  # Binance
        "0x61edcdf5bb737adffe5043706e7c5bb1f1a56eea": Decimal("1500000.0"),  # Gemini 5
        "0x742d35cc6634c0532925a3b844bc9e7595f89590": Decimal("1234567.89"),  # BitGo
        # Test addresses with specific patterns
        "0x0000000000000000000000000000000000000000": Decimal("0"),  # Zero address
        "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef": Decimal("0"),  # Dead address
        "0x1111111111111111111111111111111111111111": Decimal(
            "1.111111111"
        ),  # Repeating 1s
        "0x2222222222222222222222222222222222222222": Decimal(
            "2.222222222"
        ),  # Repeating 2s
        "0x9999999999999999999999999999999999999999": Decimal(
            "999999.999999999"
        ),  # Near million
        "0x0123456789abcdef0123456789abcdef01234567": Decimal(
            "123.456789"
        ),  # Sequential
        "0xffffffffffffffffffffffffffffffffffffffff": Decimal(
            "10000000"
        ),  # Max address = 10M
        # Exchange addresses
        "0x2910543af39aba0cd09dbb2d50200b3e800a63d2": Decimal("982341.5"),  # Kraken 4
        "0x0a869d79a7052c7f1b55a8ebabbea3420f0d1e13": Decimal("876543.21"),  # Kraken 6
        "0xe853c56864a2ebe4576a807d26fdc4a0ada51919": Decimal("765432.1"),  # Kraken 3
    }

    def __init__(
        self, data_dir: str = "workspace/blockchain", auto_populate: bool = True
    ):
        """
        Initialize filesystem blockchain repository.

        Args:
            data_dir: Directory to store blockchain data
            auto_populate: Whether to auto-populate with test addresses on init
        """
        self.data_dir = Path(data_dir).resolve()
        self.addresses_dir = self.data_dir / "addresses"

        # Ensure directories exist
        self.addresses_dir.mkdir(parents=True, exist_ok=True)

        if auto_populate:
            self._populate_test_data()

    def _populate_test_data(self) -> None:
        """Populate filesystem with test addresses and balances."""
        logger.info("Populating filesystem with test blockchain data")

        # Write metadata
        metadata_file = self.data_dir / "metadata.json"
        metadata = {
            "generated_at": datetime.utcnow().isoformat(),
            "total_addresses": 100,
            "version": "1.0.0",
            "description": "Test blockchain data for FileSystemBlockchainRepository",
        }

        with open(metadata_file, "w") as f:
            json.dump(metadata, f, indent=2)

        # Generate 100 addresses total
        addresses_to_generate = []

        # Add well-known addresses
        for address, balance in self.WELL_KNOWN_ADDRESSES.items():
            addresses_to_generate.append((address, balance))

        # Generate remaining addresses with deterministic balances
        remaining_count = 100 - len(self.WELL_KNOWN_ADDRESSES)
        for i in range(remaining_count):
            # Generate address based on index
            address = self._generate_test_address(i)
            balance = self._generate_deterministic_balance(address)
            addresses_to_generate.append((address, balance))

        # Write all address files
        for address, balance in addresses_to_generate:
            self._write_address_balance(address, balance)

        logger.info(
            "Populated test blockchain data",
            total_addresses=len(addresses_to_generate),
            data_dir=str(self.data_dir),
        )

    def _generate_test_address(self, index: int) -> str:
        """Generate a test Ethereum address based on index."""
        # Create a deterministic address using index
        data = f"test_address_{index:04d}".encode()
        hash_bytes = hashlib.sha256(data).digest()[:20]  # Take first 20 bytes
        return "0x" + hash_bytes.hex()

    def _generate_deterministic_balance(self, address: str) -> Decimal:
        """
        Generate a deterministic balance based on address.

        Uses address hash to create predictable but varied balances.
        """
        # Remove 0x prefix and convert to bytes
        address_bytes = bytes.fromhex(address[2:])

        # Use first 8 bytes as seed for balance
        seed = int.from_bytes(address_bytes[:8], byteorder="big")

        # Generate balance between 0 and 100,000 ETH
        # with some having very small amounts, some medium, some large
        balance_categories = [
            (0.7, 0, 10),  # 70% have 0-10 ETH
            (0.2, 10, 1000),  # 20% have 10-1000 ETH
            (0.08, 1000, 10000),  # 8% have 1000-10000 ETH
            (0.02, 10000, 100000),  # 2% have 10000-100000 ETH (whales)
        ]

        # Determine category based on address hash
        category_seed = seed % 100 / 100.0
        cumulative = 0.0

        for probability, min_balance, max_balance in balance_categories:
            cumulative += probability
            if category_seed <= cumulative:
                # Generate balance within this range
                range_size = max_balance - min_balance
                balance_value = min_balance + (seed % range_size)

                # Add some decimals
                decimal_part = (seed % 1000000) / 1000000.0

                return Decimal(str(balance_value + decimal_part))

        # Default fallback
        return Decimal("1.0")

    def _write_address_balance(self, address: str, balance: Decimal) -> None:
        """Write balance data for an address."""
        address_file = self.addresses_dir / f"{address.lower()}.json"

        data = {
            "address": address.lower(),
            "balance_wei": str(int(balance * 10**18)),  # Convert to wei
            "balance_eth": str(balance),
            "last_updated": datetime.utcnow().isoformat(),
            "block_number": 19000000,  # Fixed block number for testing
        }

        with open(address_file, "w") as f:
            json.dump(data, f, indent=2)

    def _read_address_balance(self, address: str) -> Decimal | None:
        """Read balance data for an address."""
        address_file = self.addresses_dir / f"{address.lower()}.json"

        if not address_file.exists():
            return None

        try:
            with open(address_file) as f:
                data = json.load(f)

            return Decimal(data["balance_eth"])

        except (json.JSONDecodeError, KeyError, ValueError) as e:
            logger.error(
                "Failed to read address balance", address=address, error=str(e)
            )
            return None

    async def get_balance(self, address: EthereumAddress) -> Decimal:
        """
        Get the balance for an Ethereum address.

        Returns balance from filesystem or generates deterministic balance
        if address not found.
        """
        logger.debug("Getting balance from filesystem", address=address.value)

        # Try to read from filesystem first
        balance = self._read_address_balance(address.value)

        if balance is not None:
            logger.debug(
                "Balance found in filesystem",
                address=address.value,
                balance=float(balance),
            )
            return balance

        # Generate deterministic balance for unknown addresses
        balance = self._generate_deterministic_balance(address.value)

        # Optionally write to filesystem for future lookups
        self._write_address_balance(address.value, balance)

        logger.debug(
            "Generated deterministic balance",
            address=address.value,
            balance=float(balance),
        )

        return balance

    def add_test_address(self, address: str, balance: Decimal) -> None:
        """
        Add a custom test address with specific balance.

        Useful for setting up specific test scenarios.
        """
        # Validate address format
        try:
            eth_address = EthereumAddress(address)
        except ValueError as e:
            logger.error("Invalid address format", address=address, error=str(e))
            raise

        self._write_address_balance(eth_address.value, balance)
        logger.info(
            "Added test address", address=eth_address.value, balance=float(balance)
        )

    def reset_test_data(self) -> None:
        """Reset all test data to initial state."""
        logger.info("Resetting test blockchain data")

        # Remove all address files
        for address_file in self.addresses_dir.glob("*.json"):
            address_file.unlink()

        # Re-populate with initial data
        self._populate_test_data()

    def get_all_test_addresses(self) -> list[tuple[str, Decimal]]:
        """Get all test addresses and their balances."""
        addresses = []

        for address_file in sorted(self.addresses_dir.glob("*.json")):
            try:
                with open(address_file) as f:
                    data = json.load(f)

                addresses.append((data["address"], Decimal(data["balance_eth"])))

            except (json.JSONDecodeError, KeyError, ValueError):
                continue

        return addresses
