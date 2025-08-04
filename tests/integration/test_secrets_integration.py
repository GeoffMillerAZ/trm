"""Integration tests for secrets implementations."""

import pytest

from src.infrastructure.mocks.mock_secrets import MockSecretsManager
from src.infrastructure.secrets.aws_secrets import EnvironmentSecretsManager


@pytest.mark.asyncio
async def test_environment_secrets_manager_basic_operations():
    """Test basic operations on environment secrets manager."""
    secrets = EnvironmentSecretsManager(env_prefix="TEST_")

    # Set some secrets
    await secrets.set_secret("api-key", "test-api-key-123")
    await secrets.set_parameter("cache-ttl", "300")

    # Test get_secret
    secret = await secrets.get_secret("api-key")
    assert secret is not None
    assert secret.value == "test-api-key-123"
    assert secret.version == "env"

    # Test get_parameter
    param = await secrets.get_parameter("cache-ttl")
    assert param == "300"

    # Test nonexistent
    nonexistent = await secrets.get_secret("nonexistent-key")
    assert nonexistent is None

    # Cleanup
    await secrets.delete_secret("api-key")
    await secrets.delete_secret("cache-ttl")


@pytest.mark.asyncio
async def test_environment_secrets_manager_batch_operations():
    """Test batch operations on environment secrets manager."""
    secrets = EnvironmentSecretsManager(env_prefix="BATCH_")

    # Set up test data
    await secrets.set_secret("key1", "value1")
    await secrets.set_secret("key2", "value2")
    await secrets.set_parameter("param1", "paramvalue1")
    await secrets.set_parameter("param2", "paramvalue2")

    # Test batch get secrets
    secret_results = await secrets.get_secrets_batch(["key1", "key2", "nonexistent"])
    assert len(secret_results) == 3
    assert secret_results["key1"].value == "value1"
    assert secret_results["key2"].value == "value2"
    assert secret_results["nonexistent"] is None

    # Test batch get parameters
    param_results = await secrets.get_parameters_batch(
        ["param1", "param2", "nonexistent"]
    )
    assert len(param_results) == 3
    assert param_results["param1"] == "paramvalue1"
    assert param_results["param2"] == "paramvalue2"
    assert param_results["nonexistent"] is None

    # Cleanup
    for key in ["key1", "key2", "param1", "param2"]:
        await secrets.delete_secret(key)


@pytest.mark.asyncio
async def test_environment_secrets_manager_list_secrets():
    """Test listing secrets with prefix filtering."""
    secrets = EnvironmentSecretsManager(env_prefix="LIST_")

    # Set up test data
    await secrets.set_secret("app-api-key", "value1")
    await secrets.set_secret("app-db-password", "value2")
    await secrets.set_secret("monitoring-key", "value3")

    # Test list all
    all_secrets = await secrets.list_secrets()
    app_secrets = [s for s in all_secrets if s.startswith("app-")]
    assert len(app_secrets) >= 2
    assert "app-api-key" in app_secrets
    assert "app-db-password" in app_secrets

    # Test list with prefix
    app_only = await secrets.list_secrets(prefix="app-")
    assert "app-api-key" in app_only
    assert "app-db-password" in app_only
    assert "monitoring-key" not in app_only

    # Cleanup
    for key in ["app-api-key", "app-db-password", "monitoring-key"]:
        await secrets.delete_secret(key)


@pytest.mark.asyncio
async def test_mock_secrets_manager_call_tracking():
    """Test that mock secrets manager tracks method calls correctly."""
    secrets = MockSecretsManager()

    # Add some preset data
    secrets.add_preset_secret("test-secret", "test-value")
    secrets.add_preset_parameter("test-param", "param-value")

    # Perform operations
    await secrets.get_secret("test-secret")
    await secrets.get_secret("nonexistent")
    await secrets.get_parameter("test-param")
    await secrets.get_secrets_batch(["test-secret", "other"])
    await secrets.get_parameters_batch(["test-param", "other"])
    await secrets.set_secret("new-secret", "new-value")
    await secrets.set_parameter("new-param", "new-param-value")
    await secrets.delete_secret("old-secret")
    await secrets.list_secrets()
    await secrets.list_secrets("prefix-")

    # Verify call tracking
    assert len(secrets.get_secret_calls) == 2
    assert "test-secret" in secrets.get_secret_calls
    assert "nonexistent" in secrets.get_secret_calls

    assert len(secrets.get_parameter_calls) == 1
    assert "test-param" in secrets.get_parameter_calls

    assert len(secrets.get_secrets_batch_calls) == 1
    assert secrets.get_secrets_batch_calls[0] == ["test-secret", "other"]

    assert len(secrets.get_parameters_batch_calls) == 1
    assert secrets.get_parameters_batch_calls[0] == ["test-param", "other"]

    assert len(secrets.set_secret_calls) == 1
    assert secrets.set_secret_calls[0] == ("new-secret", "new-value")

    assert len(secrets.set_parameter_calls) == 1
    assert secrets.set_parameter_calls[0] == ("new-param", "new-param-value")

    assert len(secrets.delete_secret_calls) == 1
    assert secrets.delete_secret_calls[0] == "old-secret"

    assert len(secrets.list_secrets_calls) == 2
    assert None in secrets.list_secrets_calls
    assert "prefix-" in secrets.list_secrets_calls


@pytest.mark.asyncio
async def test_mock_secrets_manager_preset_functionality():
    """Test preset functionality of mock secrets manager."""
    secrets = MockSecretsManager()

    # Add preset secrets
    secrets.add_preset_secret("preset-secret", "preset-value", "v1.0")
    secrets.add_preset_parameter("preset-param", "preset-param-value")

    # Test retrieval
    secret = await secrets.get_secret("preset-secret")
    assert secret is not None
    assert secret.value == "preset-value"
    assert secret.version == "v1.0"

    param = await secrets.get_parameter("preset-param")
    assert param == "preset-param-value"

    # Test batch retrieval
    batch_secrets = await secrets.get_secrets_batch(["preset-secret", "nonexistent"])
    assert batch_secrets["preset-secret"].value == "preset-value"
    assert batch_secrets["nonexistent"] is None

    batch_params = await secrets.get_parameters_batch(["preset-param", "nonexistent"])
    assert batch_params["preset-param"] == "preset-param-value"
    assert batch_params["nonexistent"] is None

    # Test list
    secret_list = await secrets.list_secrets()
    assert "preset-secret" in secret_list


@pytest.mark.asyncio
async def test_mock_secrets_manager_crud_operations():
    """Test CRUD operations on mock secrets manager."""
    secrets = MockSecretsManager()

    # Create
    await secrets.set_secret("crud-secret", "initial-value")
    await secrets.set_parameter("crud-param", "initial-param")

    # Read
    secret = await secrets.get_secret("crud-secret")
    assert secret.value == "initial-value"

    param = await secrets.get_parameter("crud-param")
    assert param == "initial-param"

    # Update (set again)
    await secrets.set_secret("crud-secret", "updated-value")
    await secrets.set_parameter("crud-param", "updated-param")

    # Verify update
    updated_secret = await secrets.get_secret("crud-secret")
    assert updated_secret.value == "updated-value"

    updated_param = await secrets.get_parameter("crud-param")
    assert updated_param == "updated-param"

    # Delete
    await secrets.delete_secret("crud-secret")

    # Verify deletion
    deleted_secret = await secrets.get_secret("crud-secret")
    assert deleted_secret is None


@pytest.mark.asyncio
async def test_mock_secrets_manager_reset():
    """Test reset functionality of mock secrets manager."""
    secrets = MockSecretsManager()

    # Add data and perform operations
    await secrets.set_secret("test-secret", "test-value")
    await secrets.set_parameter("test-param", "test-value")
    await secrets.get_secret("test-secret")
    await secrets.list_secrets()

    # Verify data exists
    assert len(secrets.secrets) == 1
    assert len(secrets.parameters) == 1
    assert len(secrets.get_secret_calls) == 1
    assert len(secrets.list_secrets_calls) == 1

    # Reset
    secrets.reset()

    # Verify everything is cleared
    assert len(secrets.secrets) == 0
    assert len(secrets.parameters) == 0
    assert len(secrets.get_secret_calls) == 0
    assert len(secrets.list_secrets_calls) == 0

    # Verify operations still work after reset
    await secrets.set_secret("after-reset", "value")
    secret = await secrets.get_secret("after-reset")
    assert secret.value == "value"
