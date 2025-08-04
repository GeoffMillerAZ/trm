"""
A module to handle calls to Infura - Direct implementation matching original infura.py
"""

import logging
import os

import requests

from src.domain.interfaces.ethereum_blockchain import EthereumBlockchain


def setup_logger(name: str) -> logging.Logger:
    """
    A function to setup a logger.
    Takes a module name as input and outputs a logger object.

    Note: This is a simplified version matching the original utils.setup_logger
    """
    logger = logging.getLogger(name)
    if os.getenv("DEBUG"):
        logger.setLevel(level=logging.DEBUG)
    else:
        logger.setLevel(level=logging.INFO)
    formatter = logging.Formatter("%(asctime)s:%(levelname)s:%(module)s:%(message)s")
    streamhandler = logging.StreamHandler()
    streamhandler.setFormatter(formatter)
    logger.addHandler(streamhandler)
    logger.propagate = False
    return logger


log = setup_logger("infura")


class InfuraEthereumBlockchain(EthereumBlockchain):
    """
    Infura implementation of the EthereumBlockchain interface.

    This implementation exactly matches the behavior of the original infura.py module,
    including the same error handling, logging, and calculation methods.
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

    def get_balance(self, address: str) -> float:
        """
        A function that gets the current balance of an ethereum address from infura.io
        Takes an eth address as a string and returns balance as a float.

        This implementation exactly matches the original infura.py behavior.
        """
        url = f"https://mainnet.infura.io/v3/{self.api_key}"
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

        response = requests.post(url, headers=headers, json=json_data)

        log.debug("response status code %s", response.status_code)
        log.debug("response content is %s", response.json())

        if response.status_code != 200:
            log.error("Response code was unsuccessful")
            return 0

        hex_amount = response.json()["result"]
        wei_amount = int(hex_amount, base=16)
        eth_amount = wei_amount / 1_000_000_000_000_000_000
        log.debug("eth_amount is %s", eth_amount)
        return eth_amount
