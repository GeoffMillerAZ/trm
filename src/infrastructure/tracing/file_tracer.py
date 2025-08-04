"""File-based implementation of tracing interface."""

import json
import time
import uuid
from contextlib import asynccontextmanager
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

from src.domain.interfaces.tracing import TraceSpan, TraceStatus, TracingInterface


@dataclass
class FileTraceSpan:
    """File-based implementation of TraceSpan."""

    trace_id: str
    span_id: str
    parent_span_id: str | None
    operation_name: str
    start_time: float
    end_time: float | None = None
    status: TraceStatus = TraceStatus.OK
    status_message: str | None = None
    attributes: dict[str, Any] = None
    events: list[dict[str, Any]] = None

    def __post_init__(self):
        if self.attributes is None:
            self.attributes = {}
        if self.events is None:
            self.events = []

    async def set_attribute(self, key: str, value: Any) -> None:
        """Set span attribute."""
        self.attributes[key] = value

    async def set_status(self, status: TraceStatus, message: str | None = None) -> None:
        """Set span status."""
        self.status = status
        self.status_message = message

    async def add_event(
        self, name: str, attributes: dict[str, Any] | None = None
    ) -> None:
        """Add event to span."""
        event = {"name": name, "timestamp": time.time(), "attributes": attributes or {}}
        self.events.append(event)

    async def end(self) -> None:
        """End the span."""
        self.end_time = time.time()


class FileTracer(TracingInterface):
    """File-based tracing implementation storing traces as JSON files."""

    def __init__(
        self,
        trace_dir: str = "workspace/tracing",
        service_name: str = "trm-blockexplorer",
        max_traces: int = 1000,
        auto_flush_interval: int = 60,  # seconds
    ):
        """Initialize file-based tracer.

        Args:
            trace_dir: Directory to store trace files
            service_name: Name of the service
            max_traces: Maximum number of trace directories to keep
            auto_flush_interval: Seconds between automatic flushes
        """
        self.trace_dir = Path(trace_dir).resolve()
        self.service_name = service_name
        self.max_traces = max_traces
        self.auto_flush_interval = auto_flush_interval

        # Ensure trace directory exists
        self.trace_dir.mkdir(parents=True, exist_ok=True)

        # Track active spans
        self._active_spans: dict[str, FileTraceSpan] = {}
        self._last_flush = time.time()

    def _generate_trace_id(self) -> str:
        """Generate unique trace ID."""
        return str(uuid.uuid4())

    def _generate_span_id(self) -> str:
        """Generate unique span ID."""
        return str(uuid.uuid4())[:16]  # Shorter span IDs

    def _get_trace_dir(self, trace_id: str) -> Path:
        """Get directory for a specific trace."""
        trace_dir = self.trace_dir / trace_id
        trace_dir.mkdir(parents=True, exist_ok=True)
        return trace_dir

    def _cleanup_old_traces(self) -> None:
        """Remove old trace directories if exceeding max_traces."""
        trace_dirs = [d for d in self.trace_dir.iterdir() if d.is_dir()]

        if len(trace_dirs) <= self.max_traces:
            return

        # Sort by modification time, oldest first
        trace_dirs.sort(key=lambda d: d.stat().st_mtime)

        # Remove oldest traces
        for trace_dir in trace_dirs[: len(trace_dirs) - self.max_traces]:
            try:
                import shutil

                shutil.rmtree(trace_dir)
            except OSError:
                pass

    def _flush_span(self, span: FileTraceSpan) -> None:
        """Write span to file."""
        trace_dir = self._get_trace_dir(span.trace_id)
        span_file = trace_dir / f"{span.span_id}.json"

        # Convert span to dictionary
        span_data = {
            "trace_id": span.trace_id,
            "span_id": span.span_id,
            "parent_span_id": span.parent_span_id,
            "operation_name": span.operation_name,
            "service_name": self.service_name,
            "start_time": span.start_time,
            "end_time": span.end_time,
            "duration_ms": (span.end_time - span.start_time) * 1000
            if span.end_time
            else None,
            "status": span.status.value,
            "status_message": span.status_message,
            "attributes": span.attributes,
            "events": span.events,
            "created_at": datetime.fromtimestamp(span.start_time).isoformat(),
        }

        try:
            with open(span_file, "w") as f:
                json.dump(span_data, f, indent=2, default=str)
        except OSError:
            # If we can't write the span, just continue
            pass

    def _auto_flush(self) -> None:
        """Automatically flush completed spans periodically."""
        current_time = time.time()

        if current_time - self._last_flush < self.auto_flush_interval:
            return

        self._last_flush = current_time

        # Flush completed spans
        completed_spans = []
        for span_id, span in self._active_spans.items():
            if span.end_time is not None:
                completed_spans.append(span_id)

        for span_id in completed_spans:
            span = self._active_spans.pop(span_id)
            self._flush_span(span)

        # Cleanup old traces
        self._cleanup_old_traces()

    async def start_trace(
        self, operation_name: str, metadata: dict[str, Any] | None = None
    ) -> TraceSpan:
        """Start a new trace."""
        trace_id = self._generate_trace_id()
        span_id = self._generate_span_id()

        span = FileTraceSpan(
            trace_id=trace_id,
            span_id=span_id,
            parent_span_id=None,
            operation_name=operation_name,
            start_time=time.time(),
        )

        # Add metadata as attributes
        if metadata:
            span.attributes.update(metadata)

        # Add service information
        span.attributes["service.name"] = self.service_name

        self._active_spans[span_id] = span
        self._auto_flush()

        return span

    async def start_span(
        self,
        operation_name: str,
        parent_span: TraceSpan | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> TraceSpan:
        """Start a new span within existing trace."""
        if parent_span:
            trace_id = parent_span.trace_id
            parent_span_id = parent_span.span_id
        else:
            trace_id = self._generate_trace_id()
            parent_span_id = None

        span_id = self._generate_span_id()

        span = FileTraceSpan(
            trace_id=trace_id,
            span_id=span_id,
            parent_span_id=parent_span_id,
            operation_name=operation_name,
            start_time=time.time(),
        )

        # Add metadata as attributes
        if metadata:
            span.attributes.update(metadata)

        # Add service information
        span.attributes["service.name"] = self.service_name

        self._active_spans[span_id] = span
        self._auto_flush()

        return span

    @asynccontextmanager
    async def trace_context(
        self, operation_name: str, metadata: dict[str, Any] | None = None
    ):
        """Context manager for tracing operations."""
        span = await self.start_trace(operation_name, metadata)
        try:
            yield span
        except Exception as e:
            await span.set_status(TraceStatus.ERROR, str(e))
            await span.set_attribute("error", True)
            await span.set_attribute("error.message", str(e))
            await span.set_attribute("error.type", type(e).__name__)
            raise
        finally:
            await span.end()
            # Flush immediately for completed spans
            if span.span_id in self._active_spans:
                completed_span = self._active_spans.pop(span.span_id)
                self._flush_span(completed_span)

    async def inject_context(self, headers: dict[str, str]) -> dict[str, str]:
        """Inject trace context into headers (simple implementation)."""
        # For file-based tracing, we could inject a simple trace header
        # In a real implementation, this would follow W3C Trace Context standard
        return headers.copy()  # No-op for file-based implementation

    async def extract_context(self, headers: dict[str, str]) -> str | None:
        """Extract trace context from headers (simple implementation)."""
        # For file-based tracing, context extraction is not really applicable
        return None

    def get_trace_stats(self) -> dict:
        """Get tracing statistics for debugging."""
        trace_dirs = [d for d in self.trace_dir.iterdir() if d.is_dir()]

        stats = {
            "total_traces": len(trace_dirs),
            "active_spans": len(self._active_spans),
            "total_spans": 0,
            "total_size_bytes": 0,
            "oldest_trace": None,
            "newest_trace": None,
        }

        trace_times = []

        for trace_dir in trace_dirs:
            try:
                dir_stat = trace_dir.stat()
                trace_times.append(dir_stat.st_mtime)

                # Count spans in this trace
                span_files = list(trace_dir.glob("*.json"))
                stats["total_spans"] += len(span_files)

                # Calculate size
                for span_file in span_files:
                    try:
                        file_stat = span_file.stat()
                        stats["total_size_bytes"] += file_stat.st_size
                    except OSError:
                        pass

            except OSError:
                pass

        if trace_times:
            stats["oldest_trace"] = datetime.fromtimestamp(min(trace_times)).isoformat()
            stats["newest_trace"] = datetime.fromtimestamp(max(trace_times)).isoformat()

        return stats

    def search_traces(
        self,
        operation_name: str | None = None,
        service_name: str | None = None,
        status: TraceStatus | None = None,
        start_time: datetime | None = None,
        end_time: datetime | None = None,
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        """Search traces with filters."""
        results = []
        trace_dirs = [d for d in self.trace_dir.iterdir() if d.is_dir()]

        # Sort by modification time, newest first
        trace_dirs.sort(key=lambda d: d.stat().st_mtime, reverse=True)

        for trace_dir in trace_dirs[
            : limit * 10
        ]:  # Search more than limit for filtering
            if len(results) >= limit:
                break

            try:
                # Get all spans for this trace
                span_files = list(trace_dir.glob("*.json"))
                trace_spans = []

                for span_file in span_files:
                    try:
                        with open(span_file) as f:
                            span_data = json.load(f)

                        # Apply filters
                        if (
                            operation_name
                            and span_data.get("operation_name") != operation_name
                        ):
                            continue

                        if (
                            service_name
                            and span_data.get("service_name") != service_name
                        ):
                            continue

                        if status and span_data.get("status") != status.value:
                            continue

                        if start_time:
                            span_start = datetime.fromtimestamp(
                                span_data.get("start_time", 0)
                            )
                            if span_start < start_time:
                                continue

                        if end_time:
                            span_start = datetime.fromtimestamp(
                                span_data.get("start_time", 0)
                            )
                            if span_start > end_time:
                                continue

                        trace_spans.append(span_data)

                    except (json.JSONDecodeError, OSError, KeyError):
                        continue

                if trace_spans:
                    # Build trace summary
                    root_span = min(
                        trace_spans, key=lambda s: s.get("start_time", float("inf"))
                    )
                    trace_summary = {
                        "trace_id": trace_dir.name,
                        "root_operation": root_span.get("operation_name"),
                        "service_name": root_span.get("service_name"),
                        "start_time": root_span.get("start_time"),
                        "created_at": root_span.get("created_at"),
                        "total_spans": len(trace_spans),
                        "spans": trace_spans,
                    }
                    results.append(trace_summary)

            except OSError:
                continue

        return results

    def export_trace(
        self, trace_id: str, format: str = "json"
    ) -> dict[str, Any] | None:
        """Export a specific trace in the requested format."""
        trace_dir = self.trace_dir / trace_id

        if not trace_dir.exists():
            return None

        try:
            spans = []
            for span_file in trace_dir.glob("*.json"):
                with open(span_file) as f:
                    span_data = json.load(f)
                spans.append(span_data)

            # Sort spans by start time
            spans.sort(key=lambda s: s.get("start_time", 0))

            if format == "json":
                return {
                    "trace_id": trace_id,
                    "spans": spans,
                    "exported_at": datetime.utcnow().isoformat(),
                }

            # Could add other formats like Jaeger, Zipkin, etc.
            return None

        except (json.JSONDecodeError, OSError):
            return None
