import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_endpoint(client: AsyncClient) -> None:
    response = await client.get("/api/v1/health")

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["message"] == "All systems operational"


@pytest.mark.asyncio
async def test_balance_endpoint_valid_address(client: AsyncClient) -> None:
    """Test balance endpoint with valid Ethereum address."""
    # Use an address that exists in the MockBlockchainRepository test data
    # The address 0x742d35cc6634c0532925a3b844bc9e7595ed6ff5 has 1.5 ETH
    response = await client.get(
        "/api/v1/address/0x742d35cc6634c0532925a3b844bc9e7595ed6ff5/balance"
    )

    assert response.status_code == 200
    data = response.json()
    assert "balance_eth" in data
    assert data["balance_eth"] == 1.5  # This address has 1.5 ETH in mock data
    assert data["source"] in ["cache", "blockchain"]


@pytest.mark.asyncio
async def test_balance_endpoint_invalid_address(client: AsyncClient) -> None:
    """Test balance endpoint with invalid Ethereum address."""
    response = await client.get("/api/v1/address/invalid_address/balance")

    assert response.status_code == 422  # FastAPI validation error for path parameter
    data = response.json()
    assert "detail" in data


@pytest.mark.asyncio
async def test_balance_endpoint_infura_error(client: AsyncClient) -> None:
    """Test balance endpoint when address has no balance."""
    # Use an address that has 0 balance in the mock data
    response = await client.get(
        "/api/v1/address/0x0000000000000000000000000000000000000000/balance"
    )

    assert response.status_code == 200
    data = response.json()
    assert data["balance_eth"] == 0.0
    assert data["source"] == "blockchain"
