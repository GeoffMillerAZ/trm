"""Integration tests for database implementations."""

from datetime import datetime
from decimal import Decimal

import pytest

from src.domain.entities.address_balance import AddressBalance
from src.domain.value_objects.ethereum_address import EthereumAddress
from src.infrastructure.mocks.mock_database import MockDatabase


@pytest.mark.asyncio
async def test_mock_database_balance_operations():
    """Test balance operations on mock database."""
    db = MockDatabase()

    # Create test balance
    address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
    balance = AddressBalance(
        address=address,
        balance_eth=Decimal("1.5"),
        retrieved_at=datetime(2023, 12, 1, 10, 0, 0),
        source="blockchain",
    )

    # Test save
    await db.save_balance(balance)
    assert len(db.save_balance_calls) == 1
    assert db.save_balance_calls[0] == balance

    # Test get latest balance
    latest = await db.get_latest_balance(address)
    assert latest is not None
    assert latest.address.value == address.value
    assert latest.balance_eth == Decimal("1.5")
    assert len(db.get_latest_balance_calls) == 1

    # Test get balance history
    history = await db.get_balance_history(address, limit=10)
    assert len(history) == 1
    assert history[0].address.value == address.value
    assert (
        len(db.get_balance_history_calls) == 2
    )  # One from get_latest_balance, one from direct call
    assert db.get_balance_history_calls[1] == (
        address,
        10,
    )  # Check the direct call parameters


@pytest.mark.asyncio
async def test_mock_database_balance_history_ordering():
    """Test that balance history is returned in correct order."""
    db = MockDatabase()
    address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")

    # Create multiple balances with different timestamps
    balance1 = AddressBalance(
        address=address,
        balance_eth=Decimal("1.0"),
        retrieved_at=datetime(2023, 12, 1, 10, 0, 0),
    )
    balance2 = AddressBalance(
        address=address,
        balance_eth=Decimal("2.0"),
        retrieved_at=datetime(2023, 12, 1, 11, 0, 0),
    )
    balance3 = AddressBalance(
        address=address,
        balance_eth=Decimal("3.0"),
        retrieved_at=datetime(2023, 12, 1, 12, 0, 0),
    )

    # Save in random order
    await db.save_balance(balance2)
    await db.save_balance(balance1)
    await db.save_balance(balance3)

    # Get history - should be ordered by retrieved_at descending
    history = await db.get_balance_history(address, limit=10)
    assert len(history) == 3
    assert history[0].balance_eth == Decimal("3.0")  # Most recent first
    assert history[1].balance_eth == Decimal("2.0")
    assert history[2].balance_eth == Decimal("1.0")

    # Get latest should return most recent
    latest = await db.get_latest_balance(address)
    assert latest.balance_eth == Decimal("3.0")


@pytest.mark.asyncio
async def test_mock_database_multiple_addresses():
    """Test handling multiple addresses."""
    db = MockDatabase()

    address1 = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
    address2 = EthereumAddress("0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")

    balance1 = AddressBalance(
        address=address1,
        balance_eth=Decimal("1.0"),
        retrieved_at=datetime(2023, 12, 1, 10, 0, 0),
    )
    balance2 = AddressBalance(
        address=address2,
        balance_eth=Decimal("2.0"),
        retrieved_at=datetime(2023, 12, 1, 10, 0, 0),
    )

    await db.save_balance(balance1)
    await db.save_balance(balance2)

    # Get history for each address separately
    history1 = await db.get_balance_history(address1)
    history2 = await db.get_balance_history(address2)

    assert len(history1) == 1
    assert len(history2) == 1
    assert history1[0].address.value == address1.value
    assert history2[0].address.value == address2.value


@pytest.mark.asyncio
async def test_mock_database_metadata_operations():
    """Test metadata operations on mock database."""
    db = MockDatabase()

    # Test save and get metadata
    metadata = {
        "last_sync": "2023-12-01T10:00:00Z",
        "version": "2.0.0",
        "config": {"cache_ttl": 300},
    }

    await db.save_metadata("app_config", metadata)
    assert len(db.save_metadata_calls) == 1
    assert db.save_metadata_calls[0] == ("app_config", metadata)

    result = await db.get_metadata("app_config")
    assert result == metadata
    assert len(db.get_metadata_calls) == 1
    assert db.get_metadata_calls[0] == "app_config"

    # Test nonexistent metadata
    result = await db.get_metadata("nonexistent")
    assert result is None


@pytest.mark.asyncio
async def test_mock_database_limit_parameter():
    """Test that limit parameter is respected."""
    db = MockDatabase()
    address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")

    # Create 5 balance entries
    for i in range(5):
        balance = AddressBalance(
            address=address,
            balance_eth=Decimal(str(i + 1)),
            retrieved_at=datetime(2023, 12, 1, 10, i, 0),
        )
        await db.save_balance(balance)

    # Get with limit
    history = await db.get_balance_history(address, limit=3)
    assert len(history) == 3

    # Should get most recent 3 (5, 4, 3)
    assert history[0].balance_eth == Decimal("5")
    assert history[1].balance_eth == Decimal("4")
    assert history[2].balance_eth == Decimal("3")


@pytest.mark.asyncio
async def test_mock_database_reset():
    """Test that reset clears all data and call tracking."""
    db = MockDatabase()

    # Add some data
    address = EthereumAddress("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
    balance = AddressBalance(
        address=address, balance_eth=Decimal("1.0"), retrieved_at=datetime.utcnow()
    )

    await db.save_balance(balance)
    await db.save_metadata("test", {"key": "value"})
    await db.get_balance_history(address)

    # Verify data exists
    assert len(db.balances) == 1
    assert len(db.metadata) == 1
    assert len(db.save_balance_calls) == 1

    # Reset
    db.reset()

    # Verify everything is cleared
    assert len(db.balances) == 0
    assert len(db.metadata) == 0
    assert len(db.save_balance_calls) == 0
    assert len(db.get_balance_history_calls) == 0
