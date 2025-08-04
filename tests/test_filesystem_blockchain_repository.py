"""Tests for the FileSystemBlockchainRepository implementation."""

from decimal import Decimal

import pytest

from src.domain.value_objects.ethereum_address import EthereumAddress
from src.infrastructure.repositories.filesystem_blockchain_repository import (
    FileSystemBlockchainRepository,
)


class TestFileSystemBlockchainRepository:
    """Test the filesystem blockchain repository implementation."""

    @pytest.fixture
    def temp_data_dir(self, tmp_path):
        """Create a temporary directory for test data."""
        data_dir = tmp_path / "test_blockchain"
        data_dir.mkdir()
        yield data_dir
        # Cleanup handled by pytest tmp_path

    @pytest.fixture
    def repository(self, temp_data_dir):
        """Create a filesystem repository instance."""
        return FileSystemBlockchainRepository(
            data_dir=str(temp_data_dir), auto_populate=True
        )

    @pytest.mark.asyncio
    async def test_initialization_creates_directories(self, temp_data_dir):
        """Test that initialization creates required directories."""
        FileSystemBlockchainRepository(data_dir=str(temp_data_dir), auto_populate=False)

        assert (temp_data_dir / "addresses").exists()
        assert (temp_data_dir / "addresses").is_dir()

    @pytest.mark.asyncio
    async def test_auto_populate_creates_test_data(self, repository, temp_data_dir):
        """Test that auto_populate creates 100 test addresses."""
        # Check metadata file
        metadata_file = temp_data_dir / "metadata.json"
        assert metadata_file.exists()

        # Check address files
        address_files = list((temp_data_dir / "addresses").glob("*.json"))
        assert len(address_files) == 100

    @pytest.mark.asyncio
    async def test_well_known_addresses_have_correct_balances(self, repository):
        """Test that well-known addresses return expected balances."""
        # Test Vitalik's address
        vitalik = EthereumAddress("0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")
        balance = await repository.get_balance(vitalik)
        assert balance == Decimal("325159.5")

        # Test Beacon Deposit Contract
        beacon = EthereumAddress("0x00000000219ab540356cBB839Cbe05303d7705Fa")
        balance = await repository.get_balance(beacon)
        assert balance == Decimal("50000000")

        # Test zero address
        zero = EthereumAddress("0x0000000000000000000000000000000000000000")
        balance = await repository.get_balance(zero)
        assert balance == Decimal("0")

    @pytest.mark.asyncio
    async def test_get_balance_unknown_address_generates_deterministic(
        self, repository
    ):
        """Test that unknown addresses get deterministic balances."""
        # Test address not in pre-populated list
        address = EthereumAddress("0x1234567890123456789012345678901234567890")

        # Get balance twice - should be the same
        balance1 = await repository.get_balance(address)
        balance2 = await repository.get_balance(address)

        assert balance1 == balance2
        assert balance1 > 0  # Should have some balance

    @pytest.mark.asyncio
    async def test_add_test_address(self, repository):
        """Test adding a custom test address."""
        test_address = "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"
        test_balance = Decimal("12345.6789")

        repository.add_test_address(test_address, test_balance)

        # Verify balance
        address = EthereumAddress(test_address)
        balance = await repository.get_balance(address)
        assert balance == test_balance

    def test_add_test_address_invalid_format(self, repository):
        """Test that adding invalid address raises error."""
        with pytest.raises(ValueError):
            repository.add_test_address("invalid_address", Decimal("100"))

    @pytest.mark.asyncio
    async def test_balance_persistence(self, repository, temp_data_dir):
        """Test that balances persist across repository instances."""
        # Add a test address
        test_address = "0xfeedfeedfeedfeedfeedfeedfeedfeedfeedfeed"
        test_balance = Decimal("9876.54321")
        repository.add_test_address(test_address, test_balance)

        # Create new repository instance
        new_repo = FileSystemBlockchainRepository(
            data_dir=str(temp_data_dir), auto_populate=False
        )

        # Check balance persists
        address = EthereumAddress(test_address)
        balance = await new_repo.get_balance(address)
        assert balance == test_balance

    def test_reset_test_data(self, repository, temp_data_dir):
        """Test resetting test data."""
        # Add custom address
        repository.add_test_address(
            "0xcafecafecafecafecafecafecafecafecafecafe", Decimal("1000")
        )

        # Count files before reset
        files_before = len(list((temp_data_dir / "addresses").glob("*.json")))
        assert files_before > 100  # Should have 101 files

        # Reset
        repository.reset_test_data()

        # Should be back to exactly 100 files
        files_after = len(list((temp_data_dir / "addresses").glob("*.json")))
        assert files_after == 100

    def test_get_all_test_addresses(self, repository):
        """Test getting all test addresses."""
        addresses = repository.get_all_test_addresses()

        assert len(addresses) == 100

        # Check format
        for address, balance in addresses:
            assert address.startswith("0x")
            assert len(address) == 42
            assert isinstance(balance, Decimal)
            assert balance >= 0

    @pytest.mark.asyncio
    async def test_deterministic_balance_generation(self, repository):
        """Test that balance generation is deterministic based on address."""
        # Test several generated addresses (40 hex chars after 0x)
        test_addresses = [
            "0x" + "a" * 40,  # All 'a's
            "0x" + "b" * 40,  # All 'b's
            "0x" + "12" * 20,  # Repeating pattern
            "0x" + "00" * 20,  # All zeros (different from zero address)
            "0x" + "ff" * 20,  # All f's
        ]

        for addr_hex in test_addresses:
            balance1 = repository._generate_deterministic_balance(addr_hex)
            balance2 = repository._generate_deterministic_balance(addr_hex)

            assert balance1 == balance2, f"Balance not deterministic for {addr_hex}"
            assert balance1 >= 0
            assert balance1 < 100000  # Max possible balance

    @pytest.mark.asyncio
    async def test_case_insensitive_addresses(self, repository):
        """Test that addresses are case-insensitive."""
        # Test with mixed case
        upper_address = EthereumAddress("0xD8DA6BF26964AF9D7EED9E03E53415D37AA96045")
        lower_address = EthereumAddress("0xd8da6bf26964af9d7eed9e03e53415d37aa96045")

        balance_upper = await repository.get_balance(upper_address)
        balance_lower = await repository.get_balance(lower_address)

        assert balance_upper == balance_lower

    def test_generate_test_address(self, repository):
        """Test test address generation."""
        # Generate several addresses
        addresses = [repository._generate_test_address(i) for i in range(10)]

        # Check all are valid format
        for addr in addresses:
            assert addr.startswith("0x")
            assert len(addr) == 42

        # Check all are unique
        assert len(set(addresses)) == len(addresses)
