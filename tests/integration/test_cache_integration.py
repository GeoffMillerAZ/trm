"""Integration tests for cache implementations."""

from datetime import timedelta

import pytest

from src.infrastructure.cache.redis_cache import InMemoryCache
from src.infrastructure.mocks.mock_cache import MockCache


@pytest.mark.asyncio
async def test_in_memory_cache_basic_operations():
    """Test basic cache operations on in-memory cache."""
    cache = InMemoryCache()

    # Test set and get
    await cache.set("test_key", "test_value")
    result = await cache.get("test_key")
    assert result == "test_value"

    # Test exists
    assert await cache.exists("test_key") is True
    assert await cache.exists("nonexistent_key") is False

    # Test delete
    await cache.delete("test_key")
    result = await cache.get("test_key")
    assert result is None

    # Test clear
    await cache.set("key1", "value1")
    await cache.set("key2", "value2")
    await cache.clear()
    assert await cache.get("key1") is None
    assert await cache.get("key2") is None


@pytest.mark.asyncio
async def test_in_memory_cache_ttl():
    """Test TTL functionality on in-memory cache."""
    cache = InMemoryCache()

    # Set with TTL
    await cache.set("ttl_key", "ttl_value", ttl=timedelta(milliseconds=100))

    # Should exist immediately
    assert await cache.exists("ttl_key") is True
    result = await cache.get("ttl_key")
    assert result == "ttl_value"

    # Wait for expiration
    import asyncio

    await asyncio.sleep(0.2)

    # Should be expired
    assert await cache.exists("ttl_key") is False
    result = await cache.get("ttl_key")
    assert result is None


@pytest.mark.asyncio
async def test_in_memory_cache_complex_data():
    """Test caching complex data structures."""
    cache = InMemoryCache()

    # Test dictionary
    test_dict = {
        "address": "0xc94770007dda54cF92009BFF0dE90c06F603a09f",
        "balance_eth": "1.5",
        "retrieved_at": "2023-12-01T10:00:00",
    }

    await cache.set("balance_data", test_dict)
    result = await cache.get("balance_data")
    assert result == test_dict

    # Test list
    test_list = ["item1", "item2", "item3"]
    await cache.set("list_data", test_list)
    result = await cache.get("list_data")
    assert result == test_list


@pytest.mark.asyncio
async def test_mock_cache_tracking():
    """Test that mock cache tracks method calls."""
    cache = MockCache()

    # Perform operations
    await cache.set("key1", "value1")
    await cache.set("key2", "value2", ttl=timedelta(minutes=5))
    await cache.get("key1")
    await cache.get("nonexistent")
    await cache.exists("key1")
    await cache.delete("key2")
    await cache.clear()

    # Check call tracking
    assert len(cache.set_calls) == 2
    assert cache.set_calls[0] == ("key1", "value1", None)
    assert cache.set_calls[1] == ("key2", "value2", timedelta(minutes=5))

    assert len(cache.get_calls) == 2
    assert "key1" in cache.get_calls
    assert "nonexistent" in cache.get_calls

    assert len(cache.exists_calls) == 1
    assert cache.exists_calls[0] == "key1"

    assert len(cache.delete_calls) == 1
    assert cache.delete_calls[0] == "key2"

    assert cache.clear_calls == 1

    # Test reset
    cache.reset()
    assert len(cache.set_calls) == 0
    assert len(cache.get_calls) == 0
    assert cache.clear_calls == 0
