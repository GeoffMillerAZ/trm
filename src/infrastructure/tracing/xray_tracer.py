"""AWS X-Ray tracing implementation."""

import time
import uuid
from typing import Any

from src.domain.interfaces.tracing import (
    TraceContext,
    TraceSpan,
    TraceStatus,
    TracingInterface,
)


class XRayTracer(TracingInterface):
    """AWS X-Ray tracing implementation."""

    def __init__(
        self,
        service_name: str = "trm-blockexplorer",
        sampling_rate: float = 1.0,
        use_local_mode: bool = False,
    ):
        """Initialize X-Ray tracer.

        Args:
            service_name: Name of the service
            sampling_rate: Sampling rate (0.0 to 1.0)
            use_local_mode: Whether to use local X-Ray daemon
        """
        self.service_name = service_name
        self.sampling_rate = sampling_rate
        self.use_local_mode = use_local_mode
        self._current_context: TraceContext | None = None

        # Initialize X-Ray SDK if available
        try:
            from aws_xray_sdk.core import xray_recorder

            self.xray_recorder = xray_recorder

            if use_local_mode:
                # Configure for local X-Ray daemon
                xray_recorder.configure(
                    service=service_name,
                    context_missing="LOG_ERROR",
                    plugins=("EC2Plugin",),
                    daemon_address="127.0.0.1:2000",
                )
            else:
                # Configure for AWS X-Ray service
                xray_recorder.configure(
                    service=service_name, context_missing="LOG_ERROR"
                )

            self.xray_available = True
        except ImportError:
            self.xray_recorder = None
            self.xray_available = False

    async def start_trace(
        self,
        operation_name: str,
        service_name: str | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> "XRaySpan":
        """Start a new trace."""
        trace_id = self._generate_trace_id()
        span_id = self._generate_span_id()

        trace_context = TraceContext(
            trace_id=trace_id, span_id=span_id, is_sampled=self._should_sample()
        )

        self._current_context = trace_context

        return XRaySpan(
            operation_name=operation_name,
            trace_context=trace_context,
            xray_recorder=self.xray_recorder,
            service_name=service_name or self.service_name,
            metadata=metadata,
            is_root=True,
        )

    async def start_span(
        self,
        operation_name: str,
        parent_context: TraceContext | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> "XRaySpan":
        """Start a new span within existing trace context."""
        parent = parent_context or self._current_context

        if not parent:
            # No parent context, start a new trace
            return await self.start_trace(operation_name, metadata=metadata)

        span_id = self._generate_span_id()

        trace_context = TraceContext(
            trace_id=parent.trace_id,
            span_id=span_id,
            parent_span_id=parent.span_id,
            is_sampled=parent.is_sampled,
        )

        return XRaySpan(
            operation_name=operation_name,
            trace_context=trace_context,
            xray_recorder=self.xray_recorder,
            service_name=self.service_name,
            metadata=metadata,
            is_root=False,
        )

    async def get_current_context(self) -> TraceContext | None:
        """Get current trace context."""
        return self._current_context

    async def inject_context(self, headers: dict[str, str]) -> dict[str, str]:
        """Inject trace context into HTTP headers."""
        if not self._current_context:
            return headers

        # X-Ray tracing header format
        trace_header = f"Root={self._current_context.trace_id};Parent={self._current_context.span_id};Sampled={'1' if self._current_context.is_sampled else '0'}"

        headers_copy = headers.copy()
        headers_copy["X-Amzn-Trace-Id"] = trace_header

        return headers_copy

    async def extract_context(self, headers: dict[str, str]) -> TraceContext | None:
        """Extract trace context from HTTP headers."""
        trace_header = headers.get("X-Amzn-Trace-Id")
        if not trace_header:
            return None

        try:
            # Parse X-Ray trace header
            parts = trace_header.split(";")
            trace_info = {}

            for part in parts:
                key, value = part.split("=", 1)
                trace_info[key] = value

            return TraceContext(
                trace_id=trace_info.get("Root", ""),
                span_id=trace_info.get("Parent", ""),
                is_sampled=trace_info.get("Sampled") == "1",
            )
        except (ValueError, KeyError):
            return None

    def _generate_trace_id(self) -> str:
        """Generate X-Ray compatible trace ID."""
        # X-Ray trace ID format: 1-{8-digit-hex-time}-{24-digit-hex-random}
        timestamp = hex(int(time.time()))[2:]
        random_part = hex(uuid.uuid4().int)[2:26]  # Take first 24 chars
        return f"1-{timestamp}-{random_part}"

    def _generate_span_id(self) -> str:
        """Generate X-Ray compatible span ID."""
        # X-Ray span ID is 16-digit hex
        return hex(uuid.uuid4().int)[2:18]

    def _should_sample(self) -> bool:
        """Determine if trace should be sampled."""
        import random

        return random.random() < self.sampling_rate


class XRaySpan(TraceSpan):
    """X-Ray span implementation."""

    def __init__(
        self,
        operation_name: str,
        trace_context: TraceContext,
        xray_recorder: Any | None = None,
        service_name: str = "trm-blockexplorer",
        metadata: dict[str, Any] | None = None,
        is_root: bool = False,
    ):
        super().__init__(operation_name, trace_context)
        self.xray_recorder = xray_recorder
        self.service_name = service_name
        self.is_root = is_root
        self.xray_segment = None
        self.xray_subsegment = None

        if metadata:
            self.attributes.update(metadata)

        self._start_xray_span()

    def _start_xray_span(self):
        """Start X-Ray segment or subsegment."""
        if not self.xray_recorder:
            return

        try:
            if self.is_root:
                # Start root segment
                self.xray_segment = self.xray_recorder.begin_segment(
                    name=self.service_name,
                    traceid=self.trace_context.trace_id,
                    parent_id=self.trace_context.parent_span_id,
                )
                if self.xray_segment:
                    self.xray_segment.put_annotation("operation", self.operation_name)
            else:
                # Start subsegment
                self.xray_subsegment = self.xray_recorder.begin_subsegment(
                    name=self.operation_name
                )
        except Exception:
            # Don't fail if X-Ray is not available
            pass

    async def set_attribute(self, key: str, value: Any) -> None:
        """Set a span attribute."""
        self.attributes[key] = value

        if self.xray_recorder:
            try:
                if self.xray_segment:
                    self.xray_segment.put_metadata(key, value)
                elif self.xray_subsegment:
                    self.xray_subsegment.put_metadata(key, value)
            except Exception:
                pass

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

        # X-Ray doesn't have events, so we add as metadata
        if self.xray_recorder:
            try:
                event_data = {
                    "event": name,
                    "timestamp": event["timestamp"],
                    **(attributes or {}),
                }

                if self.xray_segment:
                    self.xray_segment.put_metadata(
                        f"event_{len(self.events)}", event_data
                    )
                elif self.xray_subsegment:
                    self.xray_subsegment.put_metadata(
                        f"event_{len(self.events)}", event_data
                    )
            except Exception:
                pass

    async def set_status(
        self, status: TraceStatus, description: str | None = None
    ) -> None:
        """Set span status."""
        self.status = status

        if self.xray_recorder:
            try:
                if status == TraceStatus.ERROR:
                    if self.xray_segment:
                        self.xray_segment.add_exception(
                            Exception(description or "Error")
                        )
                    elif self.xray_subsegment:
                        self.xray_subsegment.add_exception(
                            Exception(description or "Error")
                        )

                # Add status as annotation
                if self.xray_segment:
                    self.xray_segment.put_annotation("status", status.value)
                elif self.xray_subsegment:
                    self.xray_subsegment.put_annotation("status", status.value)

            except Exception:
                pass

    async def record_exception(self, exception: Exception) -> None:
        """Record an exception in the span."""
        if self.xray_recorder:
            try:
                if self.xray_segment:
                    self.xray_segment.add_exception(exception)
                elif self.xray_subsegment:
                    self.xray_subsegment.add_exception(exception)
            except Exception:
                pass

    async def finish(self) -> None:
        """Finish the span."""
        self.end_time = time.time()

        if self.xray_recorder:
            try:
                if self.xray_segment:
                    self.xray_recorder.end_segment()
                elif self.xray_subsegment:
                    self.xray_recorder.end_subsegment()
            except Exception:
                pass


class ConsoleTracer(TracingInterface):
    """Console-based tracer for local development."""

    def __init__(self, service_name: str = "trm-blockexplorer"):
        self.service_name = service_name
        self._current_context: TraceContext | None = None
        self._indent_level = 0

    async def start_trace(
        self,
        operation_name: str,
        service_name: str | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> "ConsoleSpan":
        """Start a new trace."""
        trace_id = str(uuid.uuid4())[:8]
        span_id = str(uuid.uuid4())[:8]

        trace_context = TraceContext(
            trace_id=trace_id, span_id=span_id, is_sampled=True
        )

        self._current_context = trace_context

        return ConsoleSpan(
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
    ) -> "ConsoleSpan":
        """Start a new span."""
        parent = parent_context or self._current_context

        if not parent:
            return await self.start_trace(operation_name, metadata=metadata)

        span_id = str(uuid.uuid4())[:8]

        trace_context = TraceContext(
            trace_id=parent.trace_id,
            span_id=span_id,
            parent_span_id=parent.span_id,
            is_sampled=parent.is_sampled,
        )

        return ConsoleSpan(
            operation_name=operation_name,
            trace_context=trace_context,
            tracer=self,
            metadata=metadata,
            is_root=False,
        )

    async def get_current_context(self) -> TraceContext | None:
        """Get current trace context."""
        return self._current_context

    async def inject_context(self, headers: dict[str, str]) -> dict[str, str]:
        """Inject trace context into headers."""
        if not self._current_context:
            return headers

        headers_copy = headers.copy()
        headers_copy["X-Trace-Id"] = self._current_context.trace_id
        headers_copy["X-Span-Id"] = self._current_context.span_id

        return headers_copy

    async def extract_context(self, headers: dict[str, str]) -> TraceContext | None:
        """Extract trace context from headers."""
        trace_id = headers.get("X-Trace-Id")
        span_id = headers.get("X-Span-Id")

        if not trace_id or not span_id:
            return None

        return TraceContext(trace_id=trace_id, span_id=span_id, is_sampled=True)


class ConsoleSpan(TraceSpan):
    """Console span implementation for local development."""

    def __init__(
        self,
        operation_name: str,
        trace_context: TraceContext,
        tracer: ConsoleTracer,
        metadata: dict[str, Any] | None = None,
        is_root: bool = False,
    ):
        super().__init__(operation_name, trace_context)
        self.tracer = tracer
        self.is_root = is_root

        if metadata:
            self.attributes.update(metadata)

        self._print_start()

    def _get_indent(self) -> str:
        """Get indentation for nested spans."""
        return "  " * self.tracer._indent_level

    def _print_start(self):
        """Print span start."""
        indent = self._get_indent()
        print(
            f"{indent}🔍 [{self.trace_context.trace_id}:{self.trace_context.span_id}] START {self.operation_name}"
        )

        if self.attributes:
            for key, value in self.attributes.items():
                print(f"{indent}   📋 {key}: {value}")

        self.tracer._indent_level += 1

    async def set_attribute(self, key: str, value: Any) -> None:
        """Set a span attribute."""
        self.attributes[key] = value
        indent = self._get_indent()
        print(f"{indent}📋 {key}: {value}")

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

        indent = self._get_indent()
        print(f"{indent}📝 EVENT: {name}")

        if attributes:
            for key, value in attributes.items():
                print(f"{indent}     {key}: {value}")

    async def set_status(
        self, status: TraceStatus, description: str | None = None
    ) -> None:
        """Set span status."""
        self.status = status
        indent = self._get_indent()

        status_emoji = {
            TraceStatus.OK: "✅",
            TraceStatus.ERROR: "❌",
            TraceStatus.TIMEOUT: "⏰",
            TraceStatus.CANCELLED: "🚫",
        }

        emoji = status_emoji.get(status, "❓")
        print(f"{indent}{emoji} STATUS: {status.value}")

        if description:
            print(f"{indent}     {description}")

    async def record_exception(self, exception: Exception) -> None:
        """Record an exception in the span."""
        indent = self._get_indent()
        print(f"{indent}💥 EXCEPTION: {type(exception).__name__}: {exception}")

    async def finish(self) -> None:
        """Finish the span."""
        self.end_time = time.time()
        duration = self.end_time - self.start_time

        self.tracer._indent_level -= 1
        indent = self._get_indent()

        status_emoji = {
            TraceStatus.OK: "✅",
            TraceStatus.ERROR: "❌",
            TraceStatus.TIMEOUT: "⏰",
            TraceStatus.CANCELLED: "🚫",
        }

        emoji = status_emoji.get(self.status, "✅")
        print(
            f"{indent}{emoji} [{self.trace_context.trace_id}:{self.trace_context.span_id}] END {self.operation_name} ({duration:.3f}s)"
        )

        if self.events:
            print(f"{indent}   📊 Events: {len(self.events)}")

        if self.attributes:
            print(f"{indent}   📋 Attributes: {len(self.attributes)}")
