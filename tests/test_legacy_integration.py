"""Integration tests for legacy API endpoints."""

import pytest
from fastapi.testclient import TestClient

from src.main import app


class TestLegacyIntegration:
    """Test legacy API endpoints integration."""

    @pytest.fixture
    def client(self):
        """Create test client."""
        return TestClient(app)

    def test_root_path(self, client):
        """Test root path returns error for no address."""
        response = client.get("/")
        assert response.status_code == 200
        assert response.json() == {"error": "no address provided"}

    def test_invalid_address_format(self, client):
        """Test invalid address returns error in legacy format."""
        response = client.get("/address/balance/invalid_address")
        assert response.status_code == 200  # Always 200 for legacy
        assert response.json() == {"error": "invalid address syntax"}

    def test_short_address(self, client):
        """Test short address returns error."""
        response = client.get("/address/balance/0x123")
        assert response.status_code == 200
        assert response.json() == {"error": "invalid address syntax"}

    def test_address_without_0x_prefix(self, client):
        """Test address without 0x prefix returns error."""
        response = client.get(
            "/address/balance/742d35Cc6634C0532925a3b844Bc9e7595f89590"
        )
        assert response.status_code == 200
        assert response.json() == {"error": "invalid address syntax"}

    def test_healthz_endpoints(self, client):
        """Test health check endpoints."""
        # Test liveness
        response = client.get("/healthz/live")
        assert response.status_code == 200
        assert response.text == "OK"

        # Test readiness
        response = client.get("/healthz/ready")
        assert response.status_code == 200
        assert response.text == "OK"

    def test_valid_address_returns_balance_format(self, client):
        """Test valid address returns correct response format."""
        # This will return 0 because no real Infura key, but format should be correct
        response = client.get(
            "/address/balance/0x742d35Cc6634C0532925a3b844Bc9e7595f89590"
        )
        assert response.status_code == 200
        data = response.json()
        assert "balance" in data
        assert isinstance(data["balance"], int | float)
