import re
from dataclasses import dataclass


@dataclass(frozen=True)
class BlockHash:
    """Represents a validated Ethereum block hash."""

    value: str

    def __post_init__(self) -> None:
        if not re.match(r"^0x[a-fA-F0-9]{64}$", self.value):
            raise ValueError("Block hash must be a 66-character hex string (including 0x prefix)")
