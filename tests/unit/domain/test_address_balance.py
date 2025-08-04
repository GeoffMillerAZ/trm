from datetime import datetime
from decimal import Decimal

import pytest

from src.domain.entities.address_balance import AddressBalance
from src.domain.events.blockchain_events import BalanceRetrievedEvent
from src.domain.value_objects.ethereum_address import EthereumAddress


class TestAddressBalance:
    """Test cases for AddressBalance entity."""

    def test_create_address_balance(self):
        """Test creating AddressBalance entity."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        balance = Decimal("1000.5")

        address_balance = AddressBalance.create(address, balance)

        assert isinstance(address_balance.address, EthereumAddress)
        assert address_balance.address.value == address
        assert address_balance.balance_eth == balance
        assert isinstance(address_balance.retrieved_at, datetime)

    def test_create_address_balance_zero_balance(self):
        """Test creating AddressBalance with zero balance."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        balance = Decimal("0")

        address_balance = AddressBalance.create(address, balance)

        assert address_balance.balance_eth == balance

    def test_create_address_balance_with_invalid_address(self):
        """Test creating AddressBalance with invalid address."""
        invalid_address = "invalid_address"
        balance = Decimal("1000.5")

        with pytest.raises(ValueError, match="Invalid Ethereum address"):
            AddressBalance.create(invalid_address, balance)

    def test_create_address_balance_with_negative_balance(self):
        """Test creating AddressBalance with negative balance."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        balance = Decimal("-100")

        with pytest.raises(ValueError, match="Balance cannot be negative"):
            AddressBalance(address=EthereumAddress(address), balance_eth=balance)

    def test_address_balance_domain_events(self):
        """Test that AddressBalance emits proper domain events."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        balance = Decimal("1000.5")

        address_balance = AddressBalance.create(address, balance)
        events = address_balance.get_events()

        assert len(events) == 1
        assert isinstance(events[0], BalanceRetrievedEvent)

        event = events[0]
        assert event.address == address
        assert event.balance_eth == float(balance)
        assert isinstance(event.retrieved_at, datetime)

    def test_address_balance_clear_events(self):
        """Test clearing domain events."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        balance = Decimal("1000.5")

        address_balance = AddressBalance.create(address, balance)
        assert len(address_balance.get_events()) == 1

        address_balance.clear_events()
        assert len(address_balance.get_events()) == 0

    def test_address_balance_data_access(self):
        """Test accessing AddressBalance data fields."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        balance = Decimal("1000.5")

        address_balance = AddressBalance.create(address, balance)

        assert (
            address_balance.address.value
            == "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        )
        assert address_balance.balance_eth == Decimal("1000.5")
        assert address_balance.source == "blockchain"
        assert isinstance(address_balance.retrieved_at, datetime)

    def test_address_balance_zero_balance_access(self):
        """Test AddressBalance with zero balance."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        balance = Decimal("0")

        address_balance = AddressBalance.create(address, balance)

        assert address_balance.balance_eth == Decimal("0")

    def test_address_balance_decimal_precision_access(self):
        """Test AddressBalance handles decimal precision correctly."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        balance = Decimal("123.456789123456789")

        address_balance = AddressBalance.create(address, balance)

        assert address_balance.balance_eth == Decimal("123.456789123456789")
