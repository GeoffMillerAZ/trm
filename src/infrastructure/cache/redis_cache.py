"""Redis implementation of cache interface."""

import json
import pickle
from datetime import timedelta
from typing import Any

import redis.asyncio as redis

from src.domain.interfaces.cache import CacheInterface


class RedisCache(CacheInterface):
    """Redis implementation of cache interface."""

    def __init__(
        self,
        host: str = "localhost",
        port: int = 6379,
        db: int = 0,
        password: str | None = None,
        decode_responses: bool = True,
        prefix: str = "trm:blockexplorer:",
    ):
        """Initialize Redis cache.

        Args:
            host: Redis host
            port: Redis port
            db: Redis database number
            password: Redis password
            decode_responses: Whether to decode responses
            prefix: Key prefix for namespace isolation
        """
        self.prefix = prefix
        self.redis = redis.Redis(
            host=host,
            port=port,
            db=db,
            password=password,
            decode_responses=decode_responses,
        )

    def _make_key(self, key: str) -> str:
        """Create prefixed key for namespace isolation."""
        return f"{self.prefix}{key}"

    async def get(self, key: str) -> Any | None:
        """Retrieve value from cache."""
        try:
            value = await self.redis.get(self._make_key(key))
            if value is None:
                return None

            # Try to deserialize as JSON first, fallback to pickle
            try:
                return json.loads(value)
            except (json.JSONDecodeError, TypeError):
                # Handle binary data stored with pickle
                if isinstance(value, bytes):
                    return pickle.loads(value)
                return value

        except redis.RedisError as e:
            # Log error but don't fail - cache misses are acceptable
            print(f"Cache get error for key {key}: {e}")
            return None

    async def set(self, key: str, value: Any, ttl: timedelta | None = None) -> None:
        """Store value in cache with optional TTL."""
        try:
            # Serialize value
            if isinstance(value, dict | list | tuple):
                serialized_value = json.dumps(value, default=str)
            elif isinstance(value, str | int | float | bool):
                serialized_value = value
            else:
                # Use pickle for complex objects
                serialized_value = pickle.dumps(value)

            # Set with optional TTL
            if ttl:
                await self.redis.setex(
                    self._make_key(key), int(ttl.total_seconds()), serialized_value
                )
            else:
                await self.redis.set(self._make_key(key), serialized_value)

        except redis.RedisError as e:
            # Log error but don't fail - cache writes are best effort
            print(f"Cache set error for key {key}: {e}")

    async def delete(self, key: str) -> None:
        """Remove value from cache."""
        try:
            await self.redis.delete(self._make_key(key))
        except redis.RedisError as e:
            print(f"Cache delete error for key {key}: {e}")

    async def exists(self, key: str) -> bool:
        """Check if key exists in cache."""
        try:
            result = await self.redis.exists(self._make_key(key))
            return bool(result)
        except redis.RedisError as e:
            print(f"Cache exists error for key {key}: {e}")
            return False

    async def clear(self) -> None:
        """Clear all cache entries with our prefix."""
        try:
            # Get all keys with our prefix
            keys = await self.redis.keys(f"{self.prefix}*")
            if keys:
                await self.redis.delete(*keys)
        except redis.RedisError as e:
            print(f"Cache clear error: {e}")

    async def close(self) -> None:
        """Close Redis connection."""
        await self.redis.close()


class InMemoryCache(CacheInterface):
    """In-memory cache implementation for testing/local development."""

    def __init__(self):
        """Initialize in-memory cache."""
        self._cache: dict = {}
        self._ttl: dict = {}

    def _is_expired(self, key: str) -> bool:
        """Check if cached item has expired."""
        if key not in self._ttl:
            return False

        import time

        return time.time() > self._ttl[key]

    async def get(self, key: str) -> Any | None:
        """Retrieve value from cache."""
        if key not in self._cache:
            return None

        if self._is_expired(key):
            await self.delete(key)
            return None

        return self._cache[key]

    async def set(self, key: str, value: Any, ttl: timedelta | None = None) -> None:
        """Store value in cache with optional TTL."""
        self._cache[key] = value

        if ttl:
            import time

            self._ttl[key] = time.time() + ttl.total_seconds()
        elif key in self._ttl:
            del self._ttl[key]

    async def delete(self, key: str) -> None:
        """Remove value from cache."""
        self._cache.pop(key, None)
        self._ttl.pop(key, None)

    async def exists(self, key: str) -> bool:
        """Check if key exists in cache."""
        if key not in self._cache:
            return False

        if self._is_expired(key):
            await self.delete(key)
            return False

        return True

    async def clear(self) -> None:
        """Clear all cache entries."""
        self._cache.clear()
        self._ttl.clear()
