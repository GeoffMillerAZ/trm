"""Mock tracing implementation for testing."""

import time
import uuid
from typing import Any

from src.domain.interfaces.tracing import (
    TraceContext,
    TraceSpan,
    TraceStatus,
    TracingInterface,
)


class MockTracer(TracingInterface):
    """Mock tracer implementation for testing."""

    def __init__(self):
        """Initialize mock tracer with in-memory storage."""
        self.traces: list[dict[str, Any]] = []
        self.spans: list[dict[str, Any]] = []
        self.current_context: TraceContext | None = None

        # Call tracking
        self.start_trace_calls: list[tuple] = []
        self.start_span_calls: list[tuple] = []
        self.get_current_context_calls: int = 0
        self.inject_context_calls: list[dict[str, str]] = []
        self.extract_context_calls: list[dict[str, str]] = []

    async def start_trace(
        self,
        operation_name: str,
        service_name: str = "trm-blockexplorer",
        metadata: dict[str, Any] | None = None,
    ) -> "MockSpan":
        """Start a new trace."""
        self.start_trace_calls.append((operation_name, service_name, metadata))

        trace_id = str(uuid.uuid4())[:8]
        span_id = str(uuid.uuid4())[:8]

        trace_context = TraceContext(
            trace_id=trace_id, span_id=span_id, is_sampled=True
        )

        self.current_context = trace_context

        trace_info = {
            "trace_id": trace_id,
            "operation_name": operation_name,
            "service_name": service_name,
            "metadata": metadata or {},
            "start_time": time.time(),
        }
        self.traces.append(trace_info)

        return MockSpan(
            operation_name=operation_name,
            trace_context=trace_context,
            tracer=self,
            metadata=metadata,
            is_root=True,
        )

    async def start_span(
        self,
        operation_name: str,
        parent_context: TraceContext | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> "MockSpan":
        """Start a new span within existing trace context."""
        self.start_span_calls.append((operation_name, parent_context, metadata))

        parent = parent_context or self.current_context

        if not parent:
            return await self.start_trace(operation_name, metadata=metadata)

        span_id = str(uuid.uuid4())[:8]

        trace_context = TraceContext(
            trace_id=parent.trace_id,
            span_id=span_id,
            parent_span_id=parent.span_id,
            is_sampled=parent.is_sampled,
        )

        # Update current context to the new span
        self.current_context = trace_context

        return MockSpan(
            operation_name=operation_name,
            trace_context=trace_context,
            tracer=self,
            metadata=metadata,
            is_root=False,
        )

    async def get_current_context(self) -> TraceContext | None:
        """Get current trace context."""
        self.get_current_context_calls += 1
        return self.current_context

    async def inject_context(self, headers: dict[str, str]) -> dict[str, str]:
        """Inject trace context into HTTP headers."""
        self.inject_context_calls.append(headers.copy())

        if not self.current_context:
            return headers

        headers_copy = headers.copy()
        headers_copy["X-Mock-Trace-Id"] = self.current_context.trace_id
        headers_copy["X-Mock-Span-Id"] = self.current_context.span_id

        return headers_copy

    async def extract_context(self, headers: dict[str, str]) -> TraceContext | None:
        """Extract trace context from HTTP headers."""
        self.extract_context_calls.append(headers.copy())

        trace_id = headers.get("X-Mock-Trace-Id")
        span_id = headers.get("X-Mock-Span-Id")

        if not trace_id or not span_id:
            return None

        return TraceContext(trace_id=trace_id, span_id=span_id, is_sampled=True)

    def get_spans_by_operation(self, operation_name: str) -> list[dict[str, Any]]:
        """Get all spans for a specific operation."""
        return [span for span in self.spans if span["operation_name"] == operation_name]

    def get_spans_by_trace_id(self, trace_id: str) -> list[dict[str, Any]]:
        """Get all spans for a specific trace."""
        return [
            span for span in self.spans if span["trace_context"]["trace_id"] == trace_id
        ]

    def get_spans_with_status(self, status: TraceStatus) -> list[dict[str, Any]]:
        """Get all spans with a specific status."""
        return [span for span in self.spans if span["status"] == status]

    def get_spans_with_attribute(self, key: str, value: Any) -> list[dict[str, Any]]:
        """Get all spans with a specific attribute."""
        return [span for span in self.spans if span["attributes"].get(key) == value]

    def has_span_with_operation(self, operation_name: str) -> bool:
        """Check if any span exists with the given operation name."""
        return any(span["operation_name"] == operation_name for span in self.spans)

    def has_error_spans(self) -> bool:
        """Check if any spans have error status."""
        return any(span["status"] == TraceStatus.ERROR for span in self.spans)

    def reset(self) -> None:
        """Reset mock tracer state."""
        self.traces.clear()
        self.spans.clear()
        self.current_context = None
        self.start_trace_calls.clear()
        self.start_span_calls.clear()
        self.get_current_context_calls = 0
        self.inject_context_calls.clear()
        self.extract_context_calls.clear()


class MockSpan(TraceSpan):
    """Mock span implementation for testing."""

    def __init__(
        self,
        operation_name: str,
        trace_context: TraceContext,
        tracer: MockTracer,
        metadata: dict[str, Any] | None = None,
        is_root: bool = False,
    ):
        super().__init__(operation_name, trace_context)
        self.tracer = tracer
        self.is_root = is_root

        if metadata:
            self.attributes.update(metadata)

        # Track in tracer
        self.span_info = {
            "operation_name": operation_name,
            "trace_context": {
                "trace_id": trace_context.trace_id,
                "span_id": trace_context.span_id,
                "parent_span_id": trace_context.parent_span_id,
                "is_sampled": trace_context.is_sampled,
            },
            "start_time": self.start_time,
            "end_time": None,
            "status": self.status,
            "attributes": self.attributes.copy(),
            "events": [],
            "is_root": is_root,
        }
        self.tracer.spans.append(self.span_info)

    async def set_attribute(self, key: str, value: Any) -> None:
        """Set a span attribute."""
        self.attributes[key] = value
        self.span_info["attributes"][key] = value

    async def set_attributes(self, attributes: dict[str, Any]) -> None:
        """Set multiple span attributes."""
        for key, value in attributes.items():
            await self.set_attribute(key, value)

    async def add_event(
        self, name: str, attributes: dict[str, Any] | None = None
    ) -> None:
        """Add an event to the span."""
        event = {"name": name, "timestamp": time.time(), "attributes": attributes or {}}
        self.events.append(event)
        self.span_info["events"].append(event)

    async def set_status(
        self, status: TraceStatus, description: str | None = None
    ) -> None:
        """Set span status."""
        self.status = status
        self.span_info["status"] = status

        if description:
            self.span_info["status_description"] = description

    async def record_exception(self, exception: Exception) -> None:
        """Record an exception in the span."""
        exception_info = {
            "type": type(exception).__name__,
            "message": str(exception),
            "timestamp": time.time(),
        }

        if "exceptions" not in self.span_info:
            self.span_info["exceptions"] = []

        self.span_info["exceptions"].append(exception_info)

    async def finish(self) -> None:
        """Finish the span."""
        self.end_time = time.time()
        self.span_info["end_time"] = self.end_time
        self.span_info["duration"] = self.end_time - self.start_time


class SilentMockTracer(TracingInterface):
    """Silent mock tracer that doesn't store anything - useful for performance tests."""

    async def start_trace(
        self,
        operation_name: str,
        service_name: str = "trm-blockexplorer",
        metadata: dict[str, Any] | None = None,
    ) -> "SilentMockSpan":
        """Start a silent trace."""
        trace_context = TraceContext(
            trace_id="silent", span_id="silent", is_sampled=False
        )

        return SilentMockSpan(operation_name, trace_context)

    async def start_span(
        self,
        operation_name: str,
        parent_context: TraceContext | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> "SilentMockSpan":
        """Start a silent span."""
        trace_context = TraceContext(
            trace_id="silent", span_id="silent", is_sampled=False
        )

        return SilentMockSpan(operation_name, trace_context)

    async def get_current_context(self) -> TraceContext | None:
        """Get current context."""
        return None

    async def inject_context(self, headers: dict[str, str]) -> dict[str, str]:
        """Return headers unchanged."""
        return headers

    async def extract_context(self, headers: dict[str, str]) -> TraceContext | None:
        """Return no context."""
        return None


class SilentMockSpan(TraceSpan):
    """Silent mock span that does nothing."""

    def __init__(self, operation_name: str, trace_context: TraceContext):
        super().__init__(operation_name, trace_context)

    async def set_attribute(self, key: str, value: Any) -> None:
        """Silently ignore attribute."""
        pass

    async def set_attributes(self, attributes: dict[str, Any]) -> None:
        """Silently ignore attributes."""
        pass

    async def add_event(
        self, name: str, attributes: dict[str, Any] | None = None
    ) -> None:
        """Silently ignore event."""
        pass

    async def set_status(
        self, status: TraceStatus, description: str | None = None
    ) -> None:
        """Silently ignore status."""
        pass

    async def record_exception(self, exception: Exception) -> None:
        """Silently ignore exception."""
        pass

    async def finish(self) -> None:
        """Silently finish."""
        pass


class FailingMockTracer(TracingInterface):
    """Mock tracer that always fails - useful for testing error handling."""

    async def start_trace(
        self,
        operation_name: str,
        service_name: str = "trm-blockexplorer",
        metadata: dict[str, Any] | None = None,
    ) -> TraceSpan:
        """Always fail when starting trace."""
        raise RuntimeError("Mock tracer start_trace failure")

    async def start_span(
        self,
        operation_name: str,
        parent_context: TraceContext | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> TraceSpan:
        """Always fail when starting span."""
        raise RuntimeError("Mock tracer start_span failure")

    async def get_current_context(self) -> TraceContext | None:
        """Always fail when getting context."""
        raise RuntimeError("Mock tracer get_current_context failure")

    async def inject_context(self, headers: dict[str, str]) -> dict[str, str]:
        """Always fail when injecting context."""
        raise RuntimeError("Mock tracer inject_context failure")

    async def extract_context(self, headers: dict[str, str]) -> TraceContext | None:
        """Always fail when extracting context."""
        raise RuntimeError("Mock tracer extract_context failure")
