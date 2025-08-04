"""Mock logger implementation for testing."""

from typing import Any

from src.domain.interfaces.logger import LoggerInterface, LogLevel


class MockLogger(LoggerInterface):
    """Mock logger implementation for testing."""

    def __init__(self):
        """Initialize mock logger with in-memory storage."""
        self.log_calls: list[dict[str, Any]] = []

    async def log(
        self,
        level: LogLevel,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
        exception: Exception | None = None,
    ) -> None:
        """Log a message to mock storage."""
        log_entry = {
            "level": level,
            "message": message,
            "correlation_id": correlation_id,
            "metadata": metadata,
            "exception": exception,
        }
        self.log_calls.append(log_entry)

    def get_logs_by_level(self, level: LogLevel) -> list[dict[str, Any]]:
        """Get all log entries for a specific level."""
        return [log for log in self.log_calls if log["level"] == level]

    def get_logs_by_message(self, message: str) -> list[dict[str, Any]]:
        """Get all log entries containing a specific message."""
        return [log for log in self.log_calls if message in log["message"]]

    def get_logs_by_correlation_id(self, correlation_id: str) -> list[dict[str, Any]]:
        """Get all log entries for a specific correlation ID."""
        return [
            log for log in self.log_calls if log["correlation_id"] == correlation_id
        ]

    def has_log_with_level(self, level: LogLevel) -> bool:
        """Check if any log entry exists with the given level."""
        return any(log["level"] == level for log in self.log_calls)

    def has_log_with_message(self, message: str) -> bool:
        """Check if any log entry contains the given message."""
        return any(message in log["message"] for log in self.log_calls)

    def has_error_log(self) -> bool:
        """Check if any error or critical log entries exist."""
        return any(
            log["level"] in [LogLevel.ERROR, LogLevel.CRITICAL]
            for log in self.log_calls
        )

    def reset(self) -> None:
        """Reset mock logger state."""
        self.log_calls.clear()


class SilentMockLogger(LoggerInterface):
    """Silent mock logger that doesn't store anything - useful for performance tests."""

    async def log(
        self,
        level: LogLevel,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
        exception: Exception | None = None,
    ) -> None:
        """Silently ignore all log messages."""
        pass


class FailingMockLogger(LoggerInterface):
    """Mock logger that always fails - useful for testing error handling."""

    async def log(
        self,
        level: LogLevel,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
        exception: Exception | None = None,
    ) -> None:
        """Always fail when logging."""
        raise RuntimeError("Mock logger failure")
