"""File-based implementation of cache interface."""

import json
import re
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from src.domain.interfaces.cache import CacheInterface


class FileCache(CacheInterface):
    """File-based cache implementation storing entries as JSON files."""

    def __init__(
        self,
        cache_dir: str = "workspace/cache",
        max_entries: int = 1000,
        cleanup_interval: int = 300,  # 5 minutes
    ):
        """Initialize file-based cache.

        Args:
            cache_dir: Directory to store cache files
            max_entries: Maximum number of cache entries
            cleanup_interval: Seconds between TTL cleanup runs
        """
        self.cache_dir = Path(cache_dir).resolve()
        self.max_entries = max_entries
        self.cleanup_interval = cleanup_interval
        self._last_cleanup = time.time()

        # Ensure cache directory exists
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    def _sanitize_key(self, key: str) -> str:
        """Sanitize cache key for safe filename usage."""
        # Replace unsafe characters with underscores
        sanitized = re.sub(r"[^\w\-_.]", "_", key)
        # Limit length to avoid filesystem issues
        if len(sanitized) > 200:
            sanitized = sanitized[:200]
        return sanitized

    def _get_cache_file(self, key: str) -> Path:
        """Get cache file path for given key."""
        safe_key = self._sanitize_key(key)
        return self.cache_dir / f"{safe_key}.json"

    def _cleanup_expired(self) -> None:
        """Remove expired cache entries."""
        current_time = time.time()

        # Only run cleanup periodically
        if current_time - self._last_cleanup < self.cleanup_interval:
            return

        self._last_cleanup = current_time

        for cache_file in self.cache_dir.glob("*.json"):
            try:
                with open(cache_file) as f:
                    data = json.load(f)

                # Check if entry has expired
                if "expires_at" in data and data["expires_at"] < current_time:
                    cache_file.unlink()

            except (json.JSONDecodeError, OSError, KeyError):
                # Remove corrupted files
                try:
                    cache_file.unlink()
                except OSError:
                    pass

    def _enforce_max_entries(self) -> None:
        """Remove oldest entries if max_entries exceeded."""
        cache_files = list(self.cache_dir.glob("*.json"))

        if len(cache_files) <= self.max_entries:
            return

        # Sort by modification time, oldest first
        cache_files.sort(key=lambda f: f.stat().st_mtime)

        # Remove oldest entries
        for cache_file in cache_files[: len(cache_files) - self.max_entries]:
            try:
                cache_file.unlink()
            except OSError:
                pass

    async def get(self, key: str) -> Any | None:
        """Retrieve value from cache."""
        self._cleanup_expired()

        cache_file = self._get_cache_file(key)

        if not cache_file.exists():
            return None

        try:
            with open(cache_file) as f:
                data = json.load(f)

            # Check if expired
            current_time = time.time()
            if "expires_at" in data and data["expires_at"] < current_time:
                cache_file.unlink()
                return None

            # Update access time
            data["last_accessed"] = current_time
            with open(cache_file, "w") as f:
                json.dump(data, f, indent=2)

            return data["value"]

        except (json.JSONDecodeError, OSError, KeyError):
            # Remove corrupted file
            try:
                cache_file.unlink()
            except OSError:
                pass
            return None

    async def set(self, key: str, value: Any, ttl: timedelta | None = None) -> None:
        """Store value in cache with optional TTL."""
        self._cleanup_expired()
        self._enforce_max_entries()

        cache_file = self._get_cache_file(key)
        current_time = time.time()

        # Prepare cache entry
        cache_entry = {
            "key": key,
            "value": value,
            "created_at": current_time,
            "last_accessed": current_time,
        }

        if ttl:
            cache_entry["expires_at"] = current_time + ttl.total_seconds()

        # Atomic write using temporary file
        temp_file = cache_file.with_suffix(".tmp")
        try:
            with open(temp_file, "w") as f:
                json.dump(cache_entry, f, indent=2, default=str)

            # Atomic rename
            temp_file.rename(cache_file)

        except OSError:
            # Clean up temp file on error
            try:
                temp_file.unlink()
            except OSError:
                pass
            raise

    async def delete(self, key: str) -> None:
        """Remove value from cache."""
        cache_file = self._get_cache_file(key)
        try:
            cache_file.unlink()
        except OSError:
            # File doesn't exist, that's fine
            pass

    async def exists(self, key: str) -> bool:
        """Check if key exists in cache."""
        cache_file = self._get_cache_file(key)

        if not cache_file.exists():
            return False

        try:
            with open(cache_file) as f:
                data = json.load(f)

            # Check if expired
            current_time = time.time()
            if "expires_at" in data and data["expires_at"] < current_time:
                cache_file.unlink()
                return False

            return True

        except (json.JSONDecodeError, OSError, KeyError):
            # Remove corrupted file
            try:
                cache_file.unlink()
            except OSError:
                pass
            return False

    async def clear(self) -> None:
        """Clear all cache entries."""
        for cache_file in self.cache_dir.glob("*.json"):
            try:
                cache_file.unlink()
            except OSError:
                pass

    def get_cache_stats(self) -> dict:
        """Get cache statistics for debugging."""
        cache_files = list(self.cache_dir.glob("*.json"))
        current_time = time.time()

        stats = {
            "total_entries": len(cache_files),
            "expired_entries": 0,
            "total_size_bytes": 0,
            "oldest_entry": None,
            "newest_entry": None,
        }

        entry_times = []

        for cache_file in cache_files:
            try:
                file_stat = cache_file.stat()
                stats["total_size_bytes"] += file_stat.st_size
                entry_times.append(file_stat.st_mtime)

                # Check if expired
                with open(cache_file) as f:
                    data = json.load(f)

                if "expires_at" in data and data["expires_at"] < current_time:
                    stats["expired_entries"] += 1

            except (json.JSONDecodeError, OSError):
                pass

        if entry_times:
            stats["oldest_entry"] = datetime.fromtimestamp(min(entry_times)).isoformat()
            stats["newest_entry"] = datetime.fromtimestamp(max(entry_times)).isoformat()

        return stats
