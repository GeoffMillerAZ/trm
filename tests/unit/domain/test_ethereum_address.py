import pytest

from src.domain.value_objects.ethereum_address import EthereumAddress


class TestEthereumAddress:
    """Test cases for EthereumAddress value object."""

    def test_valid_ethereum_address(self):
        """Test valid Ethereum address creation."""
        valid_address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        address = EthereumAddress(valid_address)
        assert address.value == valid_address

    def test_valid_ethereum_address_lowercase(self):
        """Test valid Ethereum address with lowercase characters."""
        valid_address = "0xc94770007dda54cf92009bff0de90c06f603a09f"
        address = EthereumAddress(valid_address)
        assert address.value == valid_address

    def test_valid_ethereum_address_uppercase(self):
        """Test valid Ethereum address with uppercase characters."""
        valid_address = "0xC94770007DDA54CF92009BFF0DE90C06F603A09F"
        address = EthereumAddress(valid_address)
        assert address.value == valid_address

    def test_invalid_ethereum_address_no_prefix(self):
        """Test invalid Ethereum address without 0x prefix."""
        invalid_address = "c94770007dda54cF92009BFF0dE90c06F603a09f"
        with pytest.raises(ValueError, match="Invalid Ethereum address"):
            EthereumAddress(invalid_address)

    def test_invalid_ethereum_address_wrong_length_short(self):
        """Test invalid Ethereum address with incorrect length (too short)."""
        invalid_address = "0xc94770007dda54cF92009BFF0dE90c06F603a09"
        with pytest.raises(ValueError, match="Invalid Ethereum address"):
            EthereumAddress(invalid_address)

    def test_invalid_ethereum_address_wrong_length_long(self):
        """Test invalid Ethereum address with incorrect length (too long)."""
        invalid_address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f1"
        with pytest.raises(ValueError, match="Invalid Ethereum address"):
            EthereumAddress(invalid_address)

    def test_invalid_ethereum_address_invalid_characters(self):
        """Test invalid Ethereum address with non-hex characters."""
        invalid_address = "0xg94770007dda54cF92009BFF0dE90c06F603a09f"
        with pytest.raises(ValueError, match="Invalid Ethereum address"):
            EthereumAddress(invalid_address)

    def test_invalid_ethereum_address_empty(self):
        """Test invalid empty Ethereum address."""
        with pytest.raises(ValueError, match="Invalid Ethereum address"):
            EthereumAddress("")

    def test_ethereum_address_equality(self):
        """Test Ethereum address equality comparison."""
        address1 = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
        address2 = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
        address3 = EthereumAddress("0x1234567890abcdef1234567890abcdef12345678")

        assert address1 == address2
        assert address1 != address3
        assert address1 != "not an address object"

    def test_ethereum_address_hash(self):
        """Test Ethereum address hashing for use in sets/dicts."""
        address1 = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
        address2 = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")

        assert hash(address1) == hash(address2)

        # Test that addresses can be used as dictionary keys
        address_dict = {address1: "test"}
        assert address_dict[address2] == "test"

    def test_ethereum_address_string_representation(self):
        """Test string representation of Ethereum address."""
        address_value = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        address = EthereumAddress(address_value)
        assert str(address) == address_value

    def test_ethereum_address_immutable(self):
        """Test that EthereumAddress is immutable (frozen dataclass)."""
        address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
        with pytest.raises(AttributeError):  # Should be frozen
            address.value = "0x1234567890abcdef1234567890abcdef12345678"
