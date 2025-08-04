"""
Async implementation of Infura Ethereum blockchain interface
"""

import os

import httpx
import structlog

from src.domain.interfaces.ethereum_blockchain import EthereumBlockchain

logger = structlog.get_logger(__name__)


class AsyncInfuraEthereumBlockchain(EthereumBlockchain):
    """
    Async implementation of the EthereumBlockchain interface using Infura.

    This provides the same functionality as InfuraEthereumBlockchain but with
    async/await support for better performance in async applications.
    """

    def __init__(self, api_key: str | None = None):
        """
        Initialize with an API key.

        Args:
            api_key: Infura API key. If not provided, will use INFURA_API_KEY environment variable.
        """
        self.api_key = api_key or os.environ.get("INFURA_API_KEY")
        if not self.api_key:
            raise ValueError(
                "INFURA_API_KEY is required either as parameter or environment variable"
            )
        self.base_url = f"https://mainnet.infura.io/v3/{self.api_key}"

    async def get_balance_async(self, address: str) -> float:
        """
        Async version of get_balance.

        Gets the current balance of an ethereum address from infura.io.
        Takes an eth address as a string and returns balance as a float.

        Note: This is the async implementation. For synchronous code, use get_balance().
        """
        headers = {"Content-Type": "application/json"}

        json_data = {
            "jsonrpc": "2.0",
            "method": "eth_getBalance",
            "params": [
                address,
                "latest",
            ],
            "id": 1,
        }

        async with httpx.AsyncClient() as client:
            try:
                logger.debug("Making async Infura API request", address=address)

                response = await client.post(
                    self.base_url, headers=headers, json=json_data, timeout=30.0
                )

                logger.debug(
                    "Async Infura response received",
                    status_code=response.status_code,
                    address=address,
                )

                if response.status_code != 200:
                    logger.error(
                        "Response code was unsuccessful",
                        status_code=response.status_code,
                        address=address,
                    )
                    return 0.0

                response_data = response.json()
                logger.debug("response content is", response=response_data)

                hex_amount = response_data["result"]
                wei_amount = int(hex_amount, base=16)
                eth_amount = wei_amount / 1_000_000_000_000_000_000

                logger.debug("eth_amount is", eth_amount=eth_amount)
                return eth_amount

            except Exception as e:
                logger.error("Balance retrieval failed", address=address, error=str(e))
                return 0.0

    def get_balance(self, address: str) -> float:
        """
        Synchronous wrapper for compatibility with EthereumBlockchain interface.

        This method is provided for interface compliance but will raise an error
        directing users to use the async version.
        """
        raise NotImplementedError(
            "This is an async implementation. Use get_balance_async() with await, "
            "or use InfuraEthereumBlockchain for synchronous operations."
        )
