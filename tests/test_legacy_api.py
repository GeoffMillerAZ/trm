"""Tests for legacy Flask-compatible API endpoints."""

from datetime import datetime
from decimal import Decimal
from unittest.mock import AsyncMock

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.application.dtos.blockchain_dtos import BalanceResponse
from src.application.use_cases.get_address_balance import GetAddressBalanceUseCase
from src.main import app
from src.presentation.api.legacy_blockchain import router as legacy_router


class TestLegacyAPI:
    """Test legacy API endpoints for backward compatibility."""

    @pytest.fixture
    def client(self):
        """Create test client."""
        return TestClient(app)

    def test_root_path(self, client):
        """Test root path returns error for no address."""
        response = client.get("/")
        assert response.status_code == 200
        assert response.json() == {"error": "no address provided"}

    def test_valid_address_balance(self):
        """Test valid address returns balance in legacy format."""
        # Create a test app with mocked dependency
        test_app = FastAPI()

        # Mock the use case
        mock_use_case = AsyncMock(spec=GetAddressBalanceUseCase)
        mock_balance = BalanceResponse(
            address="0x742d35cc6634c0532925a3b844bc9e7595f89590",
            balance_eth=Decimal("2.5"),
            retrieved_at=datetime.utcnow(),
            source="blockchain",
        )
        mock_use_case.execute.return_value = mock_balance

        # Override dependency - need to override the actual dependency function
        from src.presentation.dependencies.blockchain import get_balance_use_case

        test_app.dependency_overrides[get_balance_use_case] = lambda: mock_use_case
        test_app.include_router(legacy_router)

        client = TestClient(test_app)
        response = client.get(
            "/address/balance/0x742d35Cc6634C0532925a3b844Bc9e7595f89590"
        )
        assert response.status_code == 200
        assert response.json() == {"balance": 2.5}

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

    def test_use_case_returns_none(self, client, monkeypatch):
        """Test use case returning None results in balance 0."""
        # Mock the use case to return None
        mock_use_case = AsyncMock()
        mock_use_case.execute.return_value = None

        def mock_get_balance_use_case():
            return mock_use_case

        monkeypatch.setattr(
            "src.presentation.api.legacy_blockchain.get_balance_use_case",
            mock_get_balance_use_case,
        )

        response = client.get(
            "/address/balance/0x742d35Cc6634C0532925a3b844Bc9e7595f89590"
        )
        assert response.status_code == 200
        assert response.json() == {"balance": 0}

    def test_use_case_exception(self, client, monkeypatch):
        """Test use case exception results in balance 0."""
        # Mock the use case to raise exception
        mock_use_case = AsyncMock()
        mock_use_case.execute.side_effect = Exception("Test error")

        def mock_get_balance_use_case():
            return mock_use_case

        monkeypatch.setattr(
            "src.presentation.api.legacy_blockchain.get_balance_use_case",
            mock_get_balance_use_case,
        )

        response = client.get(
            "/address/balance/0x742d35Cc6634C0532925a3b844Bc9e7595f89590"
        )
        assert response.status_code == 200
        assert response.json() == {"balance": 0}

    def test_case_insensitive_address(self):
        """Test that address validation is case insensitive."""
        # Create a test app with mocked dependency
        test_app = FastAPI()

        # Mock the use case
        mock_use_case = AsyncMock(spec=GetAddressBalanceUseCase)
        mock_balance = BalanceResponse(
            address="0x742d35cc6634c0532925a3b844bc9e7595f89590",
            balance_eth=Decimal("1.0"),
            retrieved_at=datetime.utcnow(),
            source="cache",
        )
        mock_use_case.execute.return_value = mock_balance

        # Override dependency
        from src.presentation.dependencies.blockchain import get_balance_use_case

        test_app.dependency_overrides[get_balance_use_case] = lambda: mock_use_case
        test_app.include_router(legacy_router)

        client = TestClient(test_app)

        # Test with uppercase
        response = client.get(
            "/address/balance/0X742D35CC6634C0532925A3B844BC9E7595F89590"
        )
        assert response.status_code == 200
        assert response.json() == {"balance": 1.0}

        # Test with mixed case
        response = client.get(
            "/address/balance/0x742d35Cc6634C0532925a3b844Bc9e7595f89590"
        )
        assert response.status_code == 200
        assert response.json() == {"balance": 1.0}
