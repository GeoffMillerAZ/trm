import os
from collections.abc import AsyncGenerator

import pytest
from httpx import ASGITransport, AsyncClient

from src.main import create_app


@pytest.fixture
async def app():
    # Set test environment variables
    os.environ["INFURA_API_KEY"] = "test-api-key"
    os.environ["ENVIRONMENT"] = "testing"
    # Clear AWS profile to prevent profile issues
    os.environ.pop("AWS_PROFILE", None)
    os.environ.pop("AWS_DEFAULT_PROFILE", None)
    # Set fake AWS credentials for testing
    os.environ["AWS_ACCESS_KEY_ID"] = "test-key"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "test-secret"
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"

    # Reset global settings and container to pick up test environment
    from src.infrastructure.config import container
    from src.infrastructure.config.settings import Settings

    # Create new settings instance with test environment
    new_settings = Settings()
    # Replace global settings
    import src.infrastructure.config.settings

    src.infrastructure.config.settings.settings = new_settings
    # Clear global container so it gets recreated
    container._container = None

    return create_app()


@pytest.fixture
async def client(app) -> AsyncGenerator[AsyncClient, None]:
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as ac:
        yield ac
