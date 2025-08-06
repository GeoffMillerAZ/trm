from dataclasses import dataclass


@dataclass(frozen=True)
class Transaction:
    """Represents a simplified Ethereum transaction for this context."""

    hash: str
