from dataclasses import dataclass, field
from datetime import datetime

from src.domain.value_objects.block_hash import BlockHash
from src.domain.value_objects.transaction import Transaction


@dataclass
class Block:
    """Represents a block in the Ethereum blockchain."""

    hash: BlockHash
    parent_hash: BlockHash
    number: int
    timestamp: datetime
    transactions: list[Transaction] = field(default_factory=list)
