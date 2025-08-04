from datetime import datetime

from src.domain.events.blockchain_events import (
    BalanceRetrievalFailedEvent,
    BalanceRetrievedEvent,
)


class TestBalanceRetrievedEvent:
    """Unit tests for BalanceRetrievedEvent domain event."""

    def test_create_balance_retrieved_event(self):
        """Test creating a BalanceRetrievedEvent with all fields."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        balance_eth = 2.5
        retrieved_at = datetime.utcnow()
        correlation_id = "abc123"

        event = BalanceRetrievedEvent(
            address=address,
            balance_eth=balance_eth,
            retrieved_at=retrieved_at,
            correlation_id=correlation_id,
        )

        assert event.address == address
        assert event.balance_eth == balance_eth
        assert event.retrieved_at == retrieved_at
        assert event.correlation_id == correlation_id

    def test_create_balance_retrieved_event_without_correlation_id(self):
        """Test creating a BalanceRetrievedEvent without correlation_id."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        balance_eth = 1.0
        retrieved_at = datetime.utcnow()

        event = BalanceRetrievedEvent(
            address=address, balance_eth=balance_eth, retrieved_at=retrieved_at
        )

        assert event.address == address
        assert event.balance_eth == balance_eth
        assert event.retrieved_at == retrieved_at
        assert event.correlation_id is None

    def test_balance_retrieved_event_equality(self):
        """Test BalanceRetrievedEvent equality comparison."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        balance_eth = 2.5
        retrieved_at = datetime.utcnow()
        correlation_id = "abc123"

        event1 = BalanceRetrievedEvent(
            address=address,
            balance_eth=balance_eth,
            retrieved_at=retrieved_at,
            correlation_id=correlation_id,
        )

        event2 = BalanceRetrievedEvent(
            address=address,
            balance_eth=balance_eth,
            retrieved_at=retrieved_at,
            correlation_id=correlation_id,
        )

        assert event1 == event2

    def test_balance_retrieved_event_inequality(self):
        """Test BalanceRetrievedEvent inequality comparison."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        balance_eth = 2.5
        retrieved_at = datetime.utcnow()

        event1 = BalanceRetrievedEvent(
            address=address,
            balance_eth=balance_eth,
            retrieved_at=retrieved_at,
            correlation_id="abc123",
        )

        event2 = BalanceRetrievedEvent(
            address=address,
            balance_eth=balance_eth,
            retrieved_at=retrieved_at,
            correlation_id="def456",
        )

        assert event1 != event2


class TestBalanceRetrievalFailedEvent:
    """Unit tests for BalanceRetrievalFailedEvent domain event."""

    def test_create_balance_retrieval_failed_event(self):
        """Test creating a BalanceRetrievalFailedEvent with all fields."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        error_message = "Network timeout"
        failed_at = datetime.utcnow()
        correlation_id = "abc123"

        event = BalanceRetrievalFailedEvent(
            address=address,
            error_message=error_message,
            failed_at=failed_at,
            correlation_id=correlation_id,
        )

        assert event.address == address
        assert event.error_message == error_message
        assert event.failed_at == failed_at
        assert event.correlation_id == correlation_id

    def test_create_balance_retrieval_failed_event_without_correlation_id(self):
        """Test creating a BalanceRetrievalFailedEvent without correlation_id."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        error_message = "Invalid address format"
        failed_at = datetime.utcnow()

        event = BalanceRetrievalFailedEvent(
            address=address, error_message=error_message, failed_at=failed_at
        )

        assert event.address == address
        assert event.error_message == error_message
        assert event.failed_at == failed_at
        assert event.correlation_id is None

    def test_balance_retrieval_failed_event_equality(self):
        """Test BalanceRetrievalFailedEvent equality comparison."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        error_message = "Network timeout"
        failed_at = datetime.utcnow()
        correlation_id = "abc123"

        event1 = BalanceRetrievalFailedEvent(
            address=address,
            error_message=error_message,
            failed_at=failed_at,
            correlation_id=correlation_id,
        )

        event2 = BalanceRetrievalFailedEvent(
            address=address,
            error_message=error_message,
            failed_at=failed_at,
            correlation_id=correlation_id,
        )

        assert event1 == event2

    def test_balance_retrieval_failed_event_inequality(self):
        """Test BalanceRetrievalFailedEvent inequality comparison."""
        address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
        error_message = "Network timeout"
        failed_at = datetime.utcnow()

        event1 = BalanceRetrievalFailedEvent(
            address=address,
            error_message=error_message,
            failed_at=failed_at,
            correlation_id="abc123",
        )

        event2 = BalanceRetrievalFailedEvent(
            address=address,
            error_message="Different error",
            failed_at=failed_at,
            correlation_id="abc123",
        )

        assert event1 != event2
