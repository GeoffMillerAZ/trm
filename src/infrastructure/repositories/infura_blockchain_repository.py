import os
from decimal import Decimal

import httpx
import structlog

from src.domain.repositories.blockchain_repository import BlockchainRepository
from src.domain.value_objects.ethereum_address import EthereumAddress

logger = structlog.get_logger(__name__)


class InfuraBlockchainRepository(BlockchainRepository):
    """
    Infura implementation of the BlockchainRepository.
    Handles HTTP calls to Infura API for balance retrieval, preserving
    the original Flask application's behavior and error handling.
    """

    def __init__(self, api_key: str) -> None:
        self.api_key = api_key
        self.base_url = f"https://mainnet.infura.io/v3/{api_key}"

    @classmethod
    def from_environment(cls) -> "InfuraBlockchainRepository":
        """Create repository instance using INFURA_API_KEY environment variable."""
        api_key = os.environ.get("INFURA_API_KEY")
        if not api_key:
            raise ValueError("INFURA_API_KEY environment variable is required")
        return cls(api_key)

    async def get_balance(self, address: EthereumAddress) -> Decimal:
        """
        Get balance for Ethereum address via Infura API.

        Preserves the exact behavior of the original Flask implementation:
        - Returns 0 on HTTP errors (matches original error handling)
        - Converts hex wei to ETH with proper decimal precision
        - Maintains same logging patterns
        """
        headers = {"Content-Type": "application/json"}

        json_data = {
            "jsonrpc": "2.0",
            "method": "eth_getBalance",
            "params": [address.value, "latest"],
            "id": 1,
        }

        async with httpx.AsyncClient() as client:
            try:
                logger.debug("Making Infura API request", address=address.value)

                response = await client.post(
                    self.base_url, headers=headers, json=json_data, timeout=30.0
                )

                logger.debug(
                    "Infura response received",
                    status_code=response.status_code,
                    address=address.value,
                )

                if response.status_code != 200:
                    logger.error(
                        "Infura API request failed",
                        status_code=response.status_code,
                        address=address.value,
                    )
                    return Decimal("0")

                response_data = response.json()
                logger.debug(
                    "Infura response content",
                    response=response_data,
                    address=address.value,
                )

                # Extract hex amount and convert to ETH
                hex_amount = response_data["result"]
                wei_amount = int(hex_amount, 16)
                eth_amount = Decimal(wei_amount) / Decimal("1000000000000000000")

                logger.debug(
                    "Balance conversion completed",
                    address=address.value,
                    wei_amount=wei_amount,
                    eth_amount=float(eth_amount),
                )

                return eth_amount

            except Exception as e:
                logger.error(
                    "Balance retrieval failed", address=address.value, error=str(e)
                )
                # Return 0 on any error, matching original Flask behavior
                return Decimal("0")
