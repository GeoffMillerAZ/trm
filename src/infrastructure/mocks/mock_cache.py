"""Mock cache implementation for testing."""

from datetime import timedelta
from typing import Any

from src.domain.interfaces.cache import CacheInterface


class MockCache(CacheInterface):
    """Mock cache implementation for testing."""

    def __init__(self):
        """Initialize mock cache with in-memory storage."""
        self.storage: dict[str, Any] = {}
        self.get_calls: list[str] = []
        self.set_calls: list[tuple] = []
        self.delete_calls: list[str] = []
        self.exists_calls: list[str] = []
        self.clear_calls: int = 0

    async def get(self, key: str) -> Any | None:
        """Retrieve value from mock cache."""
        self.get_calls.append(key)
        return self.storage.get(key)

    async def set(self, key: str, value: Any, ttl: timedelta | None = None) -> None:
        """Store value in mock cache."""
        self.set_calls.append((key, value, ttl))
        self.storage[key] = value

    async def delete(self, key: str) -> None:
        """Remove value from mock cache."""
        self.delete_calls.append(key)
        self.storage.pop(key, None)

    async def exists(self, key: str) -> bool:
        """Check if key exists in mock cache."""
        self.exists_calls.append(key)
        return key in self.storage

    async def clear(self) -> None:
        """Clear all cache entries."""
        self.clear_calls += 1
        self.storage.clear()

    def reset(self) -> None:
        """Reset mock cache state."""
        self.storage.clear()
        self.get_calls.clear()
        self.set_calls.clear()
        self.delete_calls.clear()
        self.exists_calls.clear()
        self.clear_calls = 0


class FailingMockCache(CacheInterface):
    """Mock cache that always fails - useful for testing error handling."""

    async def get(self, key: str) -> Any | None:
        """Always fail when getting from cache."""
        raise RuntimeError("Mock cache get failure")

    async def set(self, key: str, value: Any, ttl: timedelta | None = None) -> None:
        """Always fail when setting cache."""
        raise RuntimeError("Mock cache set failure")

    async def delete(self, key: str) -> None:
        """Always fail when deleting from cache."""
        raise RuntimeError("Mock cache delete failure")

    async def exists(self, key: str) -> bool:
        """Always fail when checking cache existence."""
        raise RuntimeError("Mock cache exists failure")

    async def clear(self) -> None:
        """Always fail when clearing cache."""
        raise RuntimeError("Mock cache clear failure")


class SlowMockCache(CacheInterface):
    """Mock cache with artificial delays for testing timeouts."""

    def __init__(self, delay_seconds: float = 1.0):
        """Initialize slow mock cache.

        Args:
            delay_seconds: Artificial delay to introduce
        """
        self.delay_seconds = delay_seconds
        self.storage: dict[str, Any] = {}

    async def _delay(self) -> None:
        """Introduce artificial delay."""
        import asyncio

        await asyncio.sleep(self.delay_seconds)

    async def get(self, key: str) -> Any | None:
        """Retrieve value with delay."""
        await self._delay()
        return self.storage.get(key)

    async def set(self, key: str, value: Any, ttl: timedelta | None = None) -> None:
        """Store value with delay."""
        await self._delay()
        self.storage[key] = value

    async def delete(self, key: str) -> None:
        """Remove value with delay."""
        await self._delay()
        self.storage.pop(key, None)

    async def exists(self, key: str) -> bool:
        """Check existence with delay."""
        await self._delay()
        return key in self.storage

    async def clear(self) -> None:
        """Clear cache with delay."""
        await self._delay()
        self.storage.clear()
