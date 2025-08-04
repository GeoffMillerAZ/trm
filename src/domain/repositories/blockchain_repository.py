from abc import ABC, abstractmethod
from decimal import Decimal

from src.domain.value_objects.ethereum_address import EthereumAddress


class BlockchainRepository(ABC):
    """
    Abstract repository interface for blockchain operations.
    Following the repository pattern to abstract external blockchain API dependencies.
    """

    @abstractmethod
    async def get_balance(self, address: EthereumAddress) -> Decimal:
        """
        Get the balance for an Ethereum address.

        Args:
            address: Validated EthereumAddress value object

        Returns:
            Balance in ETH as Decimal

        Raises:
            Exception: If balance retrieval fails
        """
        pass
