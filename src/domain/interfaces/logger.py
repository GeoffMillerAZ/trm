"""Logger interface for domain layer."""

from abc import ABC, abstractmethod
from enum import Enum
from typing import Any


class LogLevel(Enum):
    """Log levels."""

    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"


class LoggerInterface(ABC):
    """Abstract logger interface for domain layer."""

    @abstractmethod
    async def log(
        self,
        level: LogLevel,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
        exception: Exception | None = None,
    ) -> None:
        """Log a message with structured data."""
        pass

    async def debug(
        self,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> None:
        """Log debug message."""
        await self.log(LogLevel.DEBUG, message, correlation_id, metadata)

    async def info(
        self,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> None:
        """Log info message."""
        await self.log(LogLevel.INFO, message, correlation_id, metadata)

    async def warning(
        self,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> None:
        """Log warning message."""
        await self.log(LogLevel.WARNING, message, correlation_id, metadata)

    async def error(
        self,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
        exception: Exception | None = None,
    ) -> None:
        """Log error message."""
        await self.log(LogLevel.ERROR, message, correlation_id, metadata, exception)

    async def critical(
        self,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
        exception: Exception | None = None,
    ) -> None:
        """Log critical message."""
        await self.log(LogLevel.CRITICAL, message, correlation_id, metadata, exception)
