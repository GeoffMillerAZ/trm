from abc import ABC, abstractmethod


class EthereumBlockchain(ABC):
    """
    Interface for Ethereum blockchain operations.

    This interface defines the contract for interacting with Ethereum blockchain,
    matching the original infura.py module's functionality.
    """

    @abstractmethod
    def get_balance(self, address: str) -> float:
        """
        Get the current balance of an ethereum address.

        Args:
            address: Ethereum address as a string (e.g., "0x742d35Cc6634C0532925a3b844Bc9e7595f89590")

        Returns:
            Balance in ETH as a float. Returns 0.0 on error.

        Note:
            This method signature matches the original infura.py implementation
            for compatibility. The implementation should handle validation and
            error cases by returning 0.0 on failure.
        """
        pass
