"""Cache interface for domain layer."""

from abc import ABC, abstractmethod
from datetime import timedelta
from typing import Any


class CacheInterface(ABC):
    """Abstract cache interface for domain layer."""

    @abstractmethod
    async def get(self, key: str) -> Any | None:
        """Retrieve value from cache."""
        pass

    @abstractmethod
    async def set(self, key: str, value: Any, ttl: timedelta | None = None) -> None:
        """Store value in cache with optional TTL."""
        pass

    @abstractmethod
    async def delete(self, key: str) -> None:
        """Remove value from cache."""
        pass

    @abstractmethod
    async def exists(self, key: str) -> bool:
        """Check if key exists in cache."""
        pass

    @abstractmethod
    async def clear(self) -> None:
        """Clear all cache entries."""
        pass
