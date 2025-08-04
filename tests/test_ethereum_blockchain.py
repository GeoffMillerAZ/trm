"""
Tests for the EthereumBlockchain interface implementations
"""

import os
from unittest.mock import Mock, patch

import pytest

from src.infrastructure.adapters.async_infura_ethereum_blockchain import (
    AsyncInfuraEthereumBlockchain,
)
from src.infrastructure.adapters.infura_ethereum_blockchain import (
    InfuraEthereumBlockchain,
)


class TestInfuraEthereumBlockchain:
    """Test the synchronous Infura implementation"""

    def test_init_with_api_key(self):
        """Test initialization with provided API key"""
        blockchain = InfuraEthereumBlockchain(api_key="test_key_123")
        assert blockchain.api_key == "test_key_123"

    def test_init_from_environment(self):
        """Test initialization from environment variable"""
        with patch.dict(os.environ, {"INFURA_API_KEY": "env_key_456"}):
            blockchain = InfuraEthereumBlockchain()
            assert blockchain.api_key == "env_key_456"

    def test_init_missing_api_key(self):
        """Test initialization fails without API key"""
        with patch.dict(os.environ, {}, clear=True):
            with pytest.raises(ValueError, match="INFURA_API_KEY is required"):
                InfuraEthereumBlockchain()

    @patch("requests.post")
    def test_get_balance_success(self, mock_post):
        """Test successful balance retrieval"""
        # Mock successful response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "jsonrpc": "2.0",
            "id": 1,
            "result": "0x1bc16d674ec80000",  # 2 ETH in wei (hex)
        }
        mock_post.return_value = mock_response

        blockchain = InfuraEthereumBlockchain(api_key="test_key")
        balance = blockchain.get_balance("0x742d35Cc6634C0532925a3b844Bc9e7595f89590")

        assert balance == 2.0
        mock_post.assert_called_once()

    @patch("requests.post")
    def test_get_balance_error_response(self, mock_post):
        """Test balance retrieval with error response"""
        # Mock error response
        mock_response = Mock()
        mock_response.status_code = 500
        mock_response.json.return_value = {"error": "Internal server error"}
        mock_post.return_value = mock_response

        blockchain = InfuraEthereumBlockchain(api_key="test_key")
        balance = blockchain.get_balance("0x742d35Cc6634C0532925a3b844Bc9e7595f89590")

        assert balance == 0

    @patch("requests.post")
    def test_get_balance_zero(self, mock_post):
        """Test balance retrieval for zero balance"""
        # Mock response with zero balance
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "jsonrpc": "2.0",
            "id": 1,
            "result": "0x0",  # 0 ETH
        }
        mock_post.return_value = mock_response

        blockchain = InfuraEthereumBlockchain(api_key="test_key")
        balance = blockchain.get_balance("0x0000000000000000000000000000000000000000")

        assert balance == 0.0


class TestAsyncInfuraEthereumBlockchain:
    """Test the asynchronous Infura implementation"""

    def test_init_with_api_key(self):
        """Test initialization with provided API key"""
        blockchain = AsyncInfuraEthereumBlockchain(api_key="test_key_123")
        assert blockchain.api_key == "test_key_123"
        assert blockchain.base_url == "https://mainnet.infura.io/v3/test_key_123"

    def test_get_balance_not_implemented(self):
        """Test that synchronous get_balance raises NotImplementedError"""
        blockchain = AsyncInfuraEthereumBlockchain(api_key="test_key")
        with pytest.raises(
            NotImplementedError, match="This is an async implementation"
        ):
            blockchain.get_balance("0x742d35Cc6634C0532925a3b844Bc9e7595f89590")

    @pytest.mark.asyncio
    async def test_get_balance_async_success(self):
        """Test successful async balance retrieval"""
        with patch("httpx.AsyncClient") as mock_client_class:
            # Mock the async context manager
            mock_client = Mock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            # Mock successful response
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {
                "jsonrpc": "2.0",
                "id": 1,
                "result": "0x29a2241af62c0000",  # 3 ETH in wei (hex)
            }

            # Create async mock for post method
            async def async_post(*args, **kwargs):
                return mock_response

            mock_client.post = async_post

            blockchain = AsyncInfuraEthereumBlockchain(api_key="test_key")
            balance = await blockchain.get_balance_async(
                "0x742d35Cc6634C0532925a3b844Bc9e7595f89590"
            )

            assert balance == 3.0

    @pytest.mark.asyncio
    async def test_get_balance_async_error(self):
        """Test async balance retrieval with error"""
        with patch("httpx.AsyncClient") as mock_client_class:
            # Mock the async context manager
            mock_client = Mock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            # Mock error response
            mock_response = Mock()
            mock_response.status_code = 400

            # Create async mock for post method
            async def async_post(*args, **kwargs):
                return mock_response

            mock_client.post = async_post

            blockchain = AsyncInfuraEthereumBlockchain(api_key="test_key")
            balance = await blockchain.get_balance_async("invalid_address")

            assert balance == 0.0
