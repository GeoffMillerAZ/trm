"""Tracing interface for domain layer."""

import time
from abc import ABC, abstractmethod
from contextlib import AbstractAsyncContextManager
from dataclasses import dataclass
from enum import Enum
from typing import Any


class TraceStatus(Enum):
    """Trace status enumeration."""

    OK = "OK"
    ERROR = "ERROR"
    TIMEOUT = "TIMEOUT"
    CANCELLED = "CANCELLED"


@dataclass
class TraceContext:
    """Represents tracing context information."""

    trace_id: str
    span_id: str
    parent_span_id: str | None = None
    is_sampled: bool = True


@dataclass
class SpanAttribute:
    """Represents a span attribute with type safety."""

    key: str
    value: Any

    def __post_init__(self):
        """Validate attribute value types."""
        if not isinstance(self.value, str | int | float | bool):
            # Convert complex types to string
            self.value = str(self.value)


class TracingInterface(ABC):
    """Abstract tracing interface for domain layer."""

    @abstractmethod
    async def start_trace(
        self,
        operation_name: str,
        service_name: str = "trm-blockexplorer",
        metadata: dict[str, Any] | None = None,
    ) -> "TraceSpan":
        """Start a new trace."""
        pass

    @abstractmethod
    async def start_span(
        self,
        operation_name: str,
        parent_context: TraceContext | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> "TraceSpan":
        """Start a new span within existing trace context."""
        pass

    @abstractmethod
    async def get_current_context(self) -> TraceContext | None:
        """Get current trace context."""
        pass

    @abstractmethod
    async def inject_context(self, headers: dict[str, str]) -> dict[str, str]:
        """Inject trace context into HTTP headers for distributed tracing."""
        pass

    @abstractmethod
    async def extract_context(self, headers: dict[str, str]) -> TraceContext | None:
        """Extract trace context from HTTP headers."""
        pass


class TraceSpan(ABC):
    """Abstract trace span for instrumentation."""

    def __init__(
        self,
        operation_name: str,
        trace_context: TraceContext,
        start_time: float | None = None,
    ):
        self.operation_name = operation_name
        self.trace_context = trace_context
        self.start_time = start_time or time.time()
        self.end_time: float | None = None
        self.status = TraceStatus.OK
        self.attributes: dict[str, Any] = {}
        self.events: list[dict[str, Any]] = []

    @abstractmethod
    async def set_attribute(self, key: str, value: Any) -> None:
        """Set a span attribute."""
        pass

    @abstractmethod
    async def set_attributes(self, attributes: dict[str, Any]) -> None:
        """Set multiple span attributes."""
        pass

    @abstractmethod
    async def add_event(
        self, name: str, attributes: dict[str, Any] | None = None
    ) -> None:
        """Add an event to the span."""
        pass

    @abstractmethod
    async def set_status(
        self, status: TraceStatus, description: str | None = None
    ) -> None:
        """Set span status."""
        pass

    @abstractmethod
    async def record_exception(self, exception: Exception) -> None:
        """Record an exception in the span."""
        pass

    @abstractmethod
    async def finish(self) -> None:
        """Finish the span."""
        pass

    async def __aenter__(self) -> "TraceSpan":
        """Context manager entry."""
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        if exc_type is not None:
            await self.record_exception(exc_val)
            await self.set_status(TraceStatus.ERROR, str(exc_val))
        await self.finish()


class TracingContextManager(AbstractAsyncContextManager):
    """Context manager for tracing operations."""

    def __init__(self, span: TraceSpan):
        self.span = span

    async def __aenter__(self) -> TraceSpan:
        return self.span

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            await self.span.record_exception(exc_val)
            await self.span.set_status(TraceStatus.ERROR, str(exc_val))
        await self.span.finish()
