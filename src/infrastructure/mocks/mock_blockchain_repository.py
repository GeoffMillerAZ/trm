"""Mock blockchain repository for testing."""

import asyncio
from decimal import Decimal

from src.domain.entities.block import Block
from src.domain.repositories.blockchain_repository import BlockchainRepository
from src.domain.value_objects.block_hash import BlockHash
from src.domain.value_objects.ethereum_address import EthereumAddress
from src.infrastructure.test_data.blocks import get_test_block


class MockBlockchainRepository(BlockchainRepository):
    """Mock implementation of blockchain repository for testing."""

    def __init__(self, test_data: dict[str, Decimal] | None = None):
        """Initialize with optional test data.

        Args:
            test_data: Dictionary mapping addresses to balances in Wei
        """
        self._test_data = test_data or self._get_default_test_data()
        self._call_count = 0
        self._last_called_address = None
        self._delay_ms = 0  # Configurable delay for testing

    def _get_default_test_data(self) -> dict[str, Decimal]:
        """Get default test data with various scenarios (balances in ETH)."""
        return {
            # ETH2 deposit contract (large balance)
            "0x00000000219ab540356cbb839cbe05303d7705fa": Decimal(
                "36668162.325"
            ),  # 36.6M ETH
            # Vitalik's address (medium balance)
            "0xd8da6bf26964af9d7eed9e03e53415d37aa96045": Decimal(
                "5234.567890123456789012"
            ),  # 5234.5 ETH
            # Regular user (small balance)
            "0x742d35cc6634c0532925a3b844bc9e7595ed6ff5": Decimal("1.5"),  # 1.5 ETH
            # Empty address
            "0x0000000000000000000000000000000000000000": Decimal("0"),
            # Address with dust amount
            "0x1234567890123456789012345678901234567890": Decimal(
                "0.000000000123456789"
            ),  # Very small amount
            # Test addresses for different scenarios
            "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef": Decimal(
                "999999.999999999999999999"
            ),  # ~1M ETH
            "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa": Decimal("0.1"),  # 0.1 ETH
            "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb": Decimal("2.0"),  # 2 ETH
            "0xcccccccccccccccccccccccccccccccccccccccc": Decimal("50.0"),  # 50 ETH
            # Edge case: very large balance
            "0xffffffffffffffffffffffffffffffffffffffff": Decimal(
                "115792089237316195423570985008687907853.269984665640564039457"
            ),
        }

    async def get_balance(self, address: EthereumAddress) -> Decimal:
        """Get balance for an address from test data.

        Args:
            address: Ethereum address to get balance for

        Returns:
            Balance in ETH as Decimal
        """
        self._call_count += 1
        self._last_called_address = str(address).lower()

        # Simulate network delay if configured
        if self._delay_ms > 0:
            await asyncio.sleep(self._delay_ms / 1000.0)

        # Return balance from test data or 0 if not found
        balance = self._test_data.get(self._last_called_address, Decimal("0"))

        return balance

    def set_balance(self, address: str, balance_eth: Decimal) -> None:
        """Set balance for an address in test data.

        Args:
            address: Ethereum address (will be normalized to lowercase)
            balance_eth: Balance in ETH
        """
        self._test_data[address.lower()] = balance_eth

    def set_delay(self, delay_ms: int) -> None:
        """Set artificial delay for testing.

        Args:
            delay_ms: Delay in milliseconds
        """
        self._delay_ms = max(0, delay_ms)

    def get_call_count(self) -> int:
        """Get number of times get_balance was called."""
        return self._call_count

    def get_last_called_address(self) -> str | None:
        """Get the last address that was queried."""
        return self._last_called_address

    def reset_metrics(self) -> None:
        """Reset call metrics for testing."""
        self._call_count = 0
        self._last_called_address = None

    def clear_test_data(self) -> None:
        """Clear all test data."""
        self._test_data.clear()

    def load_test_scenario(self, scenario: str) -> None:
        """Load a predefined test scenario.

        Args:
            scenario: Name of the scenario to load
        """
        scenarios = {
            "default": self._get_default_test_data(),
            "all_empty": {addr: Decimal("0") for addr in self._get_default_test_data()},
            "all_rich": {
                addr: Decimal("1000.0") for addr in self._get_default_test_data()
            },  # 1000 ETH each
            "error_scenario": {},  # Empty data to simulate not found
        }

        if scenario in scenarios:
            self._test_data = scenarios[scenario]
        else:
            raise ValueError(f"Unknown scenario: {scenario}")

    async def get_block_by_hash(self, block_hash: BlockHash) -> Block | None:
        """Get a block by its hash from test data.

        Args:
            block_hash: Block hash to retrieve

        Returns:
            Block if found, None otherwise
        """
        # Simulate network delay if configured
        if self._delay_ms > 0:
            await asyncio.sleep(self._delay_ms / 1000.0)

        # Get block from test data
        return get_test_block(block_hash.value)
