import re
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class EthereumAddress:
    value: str

    def __post_init__(self) -> None:
        if not self._is_valid_ethereum_address(self.value):
            raise ValueError(f"Invalid Ethereum address: {self.value}")

    @staticmethod
    def _is_valid_ethereum_address(address: str) -> bool:
        """
        Validates Ethereum address format: 0x followed by 40 hexadecimal characters.
        Case-insensitive validation matching the original Flask implementation.
        """
        pattern = r"0x[0-9A-F]{40}$"
        return bool(re.match(pattern, address, flags=re.I))

    def __str__(self) -> str:
        return self.value

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, EthereumAddress):
            return False
        return self.value == other.value

    def __hash__(self) -> int:
        return hash(self.value)
