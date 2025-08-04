from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal

from src.domain.events.blockchain_events import BalanceRetrievedEvent
from src.domain.value_objects.ethereum_address import EthereumAddress


@dataclass
class AddressBalance:
    address: EthereumAddress
    balance_eth: Decimal
    retrieved_at: datetime = field(default_factory=datetime.utcnow)
    source: str = "blockchain"  # "cache" or "blockchain"
    _events: list[object] = field(default_factory=list, init=False, repr=False)

    def __post_init__(self) -> None:
        if self.balance_eth < 0:
            raise ValueError("Balance cannot be negative")

    @classmethod
    def create(cls, address: str, balance_eth: Decimal) -> "AddressBalance":
        """
        Create an AddressBalance entity with proper validation and domain events.
        """
        ethereum_address = EthereumAddress(address)
        address_balance = cls(address=ethereum_address, balance_eth=balance_eth)

        # Emit domain event for balance retrieval
        address_balance._add_event(
            BalanceRetrievedEvent(
                address=address,
                balance_eth=float(balance_eth),
                retrieved_at=address_balance.retrieved_at,
            )
        )

        return address_balance

    def _add_event(self, event: object) -> None:
        """Add domain event to the entity."""
        self._events.append(event)

    def get_events(self) -> list[object]:
        """Get copy of all domain events."""
        return self._events[:]

    def clear_events(self) -> None:
        """Clear all domain events."""
        self._events.clear()
