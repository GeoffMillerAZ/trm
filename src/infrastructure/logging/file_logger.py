"""File-based implementation of logger interface."""

import json
import os
import traceback
from datetime import datetime
from pathlib import Path
from typing import Any

from src.domain.interfaces.logger import LoggerInterface, LogLevel


class FileLogger(LoggerInterface):
    """File-based logger implementation with JSON structured logging and rotation."""

    def __init__(
        self,
        log_dir: str = "workspace/logging",
        log_file_prefix: str = "app",
        max_log_files: int = 7,
        human_readable: bool = True,
        enable_console: bool = True,
    ):
        """Initialize file-based logger.

        Args:
            log_dir: Directory to store log files
            log_file_prefix: Prefix for log files (will be app-2025-07-31.jsonl)
            max_log_files: Maximum number of log files to keep
            human_readable: Whether to format JSON for human readability
            enable_console: Whether to also log to console
        """
        self.log_dir = Path(log_dir).resolve()
        self.log_file_prefix = log_file_prefix
        self.max_log_files = max_log_files
        self.human_readable = human_readable
        self.enable_console = enable_console

        # Ensure log directory exists
        self.log_dir.mkdir(parents=True, exist_ok=True)

        # Initialize console logger if needed
        if self.enable_console:
            import logging

            self.console_logger = logging.getLogger("file_logger")
            if not self.console_logger.handlers:
                handler = logging.StreamHandler()
                formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
                handler.setFormatter(formatter)
                self.console_logger.addHandler(handler)
                self.console_logger.setLevel(logging.DEBUG)

    def _get_log_file_path(self, date: datetime | None = None) -> Path:
        """Get log file path for given date."""
        if date is None:
            date = datetime.utcnow()

        date_str = date.strftime("%Y-%m-%d")
        return self.log_dir / f"{self.log_file_prefix}-{date_str}.jsonl"

    def _cleanup_old_logs(self) -> None:
        """Remove old log files exceeding max_log_files."""
        log_files = list(self.log_dir.glob(f"{self.log_file_prefix}-*.jsonl"))

        if len(log_files) <= self.max_log_files:
            return

        # Sort by modification time, oldest first
        log_files.sort(key=lambda f: f.stat().st_mtime)

        # Remove oldest files
        for log_file in log_files[: len(log_files) - self.max_log_files]:
            try:
                log_file.unlink()
            except OSError:
                pass

    def _format_log_entry(
        self,
        level: LogLevel,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
        exception: Exception | None = None,
    ) -> dict:
        """Format log entry as structured dictionary."""
        entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": level.value,
            "message": message,
        }

        if correlation_id:
            entry["correlation_id"] = correlation_id

        if metadata:
            entry["metadata"] = metadata

        if exception:
            entry["exception"] = {
                "type": type(exception).__name__,
                "message": str(exception),
                "traceback": traceback.format_exception(
                    type(exception), exception, exception.__traceback__
                ),
            }

        # Add process info
        entry["process"] = {
            "pid": os.getpid(),
        }

        return entry

    def _write_log_entry(self, entry: dict) -> None:
        """Write log entry to file."""
        log_file = self._get_log_file_path()

        try:
            # Append to daily log file
            with open(log_file, "a") as f:
                if self.human_readable:
                    json.dump(entry, f, indent=2, default=str)
                    f.write("\n")
                else:
                    json.dump(entry, f, default=str)
                    f.write("\n")

            # Cleanup old logs periodically
            if hash(entry.get("message", "")) % 100 == 0:  # Cleanup every ~100 messages
                self._cleanup_old_logs()

        except OSError as e:
            # If we can't write to file, at least try console
            if self.enable_console:
                self.console_logger.error(f"Failed to write to log file: {e}")

    def _log_to_console(
        self, level: LogLevel, message: str, correlation_id: str | None = None
    ) -> None:
        """Log to console if enabled."""
        if not self.enable_console:
            return

        log_message = message
        if correlation_id:
            log_message = f"[{correlation_id}] {message}"

        level_mapping = {
            LogLevel.DEBUG: self.console_logger.debug,
            LogLevel.INFO: self.console_logger.info,
            LogLevel.WARNING: self.console_logger.warning,
            LogLevel.ERROR: self.console_logger.error,
            LogLevel.CRITICAL: self.console_logger.critical,
        }

        log_func = level_mapping.get(level, self.console_logger.info)
        log_func(log_message)

    async def log(
        self,
        level: LogLevel,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
        exception: Exception | None = None,
    ) -> None:
        """Log a message with structured data."""
        # Format log entry
        entry = self._format_log_entry(
            level, message, correlation_id, metadata, exception
        )

        # Write to file
        self._write_log_entry(entry)

        # Also log to console
        self._log_to_console(level, message, correlation_id)

    def get_log_stats(self) -> dict:
        """Get logging statistics for debugging."""
        log_files = list(self.log_dir.glob(f"{self.log_file_prefix}-*.jsonl"))

        stats = {
            "total_log_files": len(log_files),
            "total_size_bytes": 0,
            "oldest_log": None,
            "newest_log": None,
            "log_levels_count": {level.value: 0 for level in LogLevel},
        }

        file_times = []

        for log_file in log_files:
            try:
                file_stat = log_file.stat()
                stats["total_size_bytes"] += file_stat.st_size
                file_times.append(file_stat.st_mtime)

                # Count log levels in this file (sample first 100 lines)
                with open(log_file) as f:
                    for i, line in enumerate(f):
                        if i >= 100:  # Sample only first 100 lines for performance
                            break
                        try:
                            entry = json.loads(line.strip())
                            level = entry.get("level", "INFO")
                            if level in stats["log_levels_count"]:
                                stats["log_levels_count"][level] += 1
                        except (json.JSONDecodeError, KeyError):
                            continue

            except (OSError, json.JSONDecodeError):
                pass

        if file_times:
            stats["oldest_log"] = datetime.fromtimestamp(min(file_times)).isoformat()
            stats["newest_log"] = datetime.fromtimestamp(max(file_times)).isoformat()

        return stats

    def search_logs(
        self,
        query: str,
        level: LogLevel | None = None,
        correlation_id: str | None = None,
        start_date: datetime | None = None,
        end_date: datetime | None = None,
        limit: int = 100,
    ) -> list[dict]:
        """Search log entries with filters."""
        results = []

        # Determine which log files to search
        log_files = list(self.log_dir.glob(f"{self.log_file_prefix}-*.jsonl"))

        if start_date or end_date:
            # Filter log files by date range
            filtered_files = []
            for log_file in log_files:
                try:
                    # Extract date from filename
                    date_str = log_file.stem.split("-", 1)[1]  # Remove prefix
                    file_date = datetime.strptime(date_str, "%Y-%m-%d")

                    if start_date and file_date < start_date:
                        continue
                    if end_date and file_date > end_date:
                        continue

                    filtered_files.append(log_file)
                except (ValueError, IndexError):
                    continue
            log_files = filtered_files

        # Sort by modification time, newest first
        log_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)

        for log_file in log_files:
            if len(results) >= limit:
                break

            try:
                with open(log_file) as f:
                    for line in f:
                        if len(results) >= limit:
                            break

                        try:
                            entry = json.loads(line.strip())

                            # Apply filters
                            if level and entry.get("level") != level.value:
                                continue

                            if (
                                correlation_id
                                and entry.get("correlation_id") != correlation_id
                            ):
                                continue

                            if (
                                query
                                and query.lower()
                                not in entry.get("message", "").lower()
                            ):
                                continue

                            results.append(entry)

                        except (json.JSONDecodeError, KeyError):
                            continue

            except OSError:
                continue

        return results
