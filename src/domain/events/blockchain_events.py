from dataclasses import dataclass
from datetime import datetime


@dataclass
class BalanceRetrievedEvent:
    """Domain event emitted when an address balance is successfully retrieved."""

    address: str
    balance_eth: float
    retrieved_at: datetime
    correlation_id: str | None = None


@dataclass
class BalanceRetrievalFailedEvent:
    """Domain event emitted when balance retrieval fails."""

    address: str
    error_message: str
    failed_at: datetime
    correlation_id: str | None = None
