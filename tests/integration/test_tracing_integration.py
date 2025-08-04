"""Integration tests for tracing implementations."""

import asyncio

import pytest

from src.domain.interfaces.tracing import TraceStatus
from src.infrastructure.mocks.mock_tracer import MockTracer
from src.infrastructure.tracing.xray_tracer import ConsoleTracer


@pytest.mark.asyncio
async def test_console_tracer_basic_operations():
    """Test basic operations on console tracer."""
    tracer = ConsoleTracer(service_name="test-service")

    # Start a trace
    async with await tracer.start_trace(
        "test_operation", metadata={"test": "value"}
    ) as span:
        await span.set_attribute("operation_type", "test")
        await span.add_event("operation_started")

        # Start a child span
        async with await tracer.start_span("child_operation") as child_span:
            await child_span.set_attribute("child_attr", "child_value")
            await child_span.add_event("child_event")

    # Verify context was available during operation
    context = await tracer.get_current_context()
    assert context is not None
    assert len(context.trace_id) == 8  # UUID[:8]


@pytest.mark.asyncio
async def test_console_tracer_error_handling():
    """Test error handling in console tracer."""
    tracer = ConsoleTracer()

    async with await tracer.start_trace("error_operation") as span:
        try:
            # Simulate an error
            raise ValueError("Test error")
        except ValueError as e:
            await span.record_exception(e)
            await span.set_status(TraceStatus.ERROR, "Operation failed")

        # Span should handle the error gracefully
        assert span.status == TraceStatus.ERROR


@pytest.mark.asyncio
async def test_console_tracer_context_injection_extraction():
    """Test context injection and extraction."""
    tracer = ConsoleTracer()

    async with await tracer.start_trace("parent_operation") as span:
        # Test context injection
        headers = {"existing": "header"}
        injected_headers = await tracer.inject_context(headers)

        assert "existing" in injected_headers
        assert "X-Trace-Id" in injected_headers
        assert "X-Span-Id" in injected_headers
        assert injected_headers["X-Trace-Id"] == span.trace_context.trace_id

        # Test context extraction
        extracted_context = await tracer.extract_context(injected_headers)
        assert extracted_context is not None
        assert extracted_context.trace_id == span.trace_context.trace_id
        assert extracted_context.span_id == span.trace_context.span_id


@pytest.mark.asyncio
async def test_mock_tracer_comprehensive_tracking():
    """Test comprehensive tracking in mock tracer."""
    tracer = MockTracer()

    # Start trace and span operations
    async with await tracer.start_trace(
        "main_operation", service_name="test-service", metadata={"version": "1.0"}
    ) as span:
        await span.set_attribute("user_id", "12345")
        await span.add_event("user_authenticated")

        async with await tracer.start_span(
            "database_query", metadata={"table": "users"}
        ) as db_span:
            await db_span.set_attribute("query_type", "SELECT")
            await db_span.add_event("query_executed")

        async with await tracer.start_span("cache_lookup") as cache_span:
            await cache_span.set_attribute("cache_key", "user:12345")
            await cache_span.set_status(TraceStatus.ERROR, "Cache miss")

    # Test context operations
    await tracer.get_current_context()
    headers = await tracer.inject_context({"test": "header"})
    await tracer.extract_context(headers)

    # Verify call tracking
    assert len(tracer.start_trace_calls) == 1
    assert tracer.start_trace_calls[0][0] == "main_operation"
    assert tracer.start_trace_calls[0][1] == "test-service"
    assert tracer.start_trace_calls[0][2]["version"] == "1.0"

    assert len(tracer.start_span_calls) == 2
    assert tracer.start_span_calls[0][0] == "database_query"
    assert tracer.start_span_calls[1][0] == "cache_lookup"

    assert tracer.get_current_context_calls == 1
    assert len(tracer.inject_context_calls) == 1
    assert len(tracer.extract_context_calls) == 1

    # Verify span tracking
    assert len(tracer.spans) == 3  # main + 2 child spans

    # Test helper methods
    assert tracer.has_span_with_operation("main_operation")
    assert tracer.has_span_with_operation("database_query")
    assert tracer.has_span_with_operation("cache_lookup")
    assert not tracer.has_span_with_operation("nonexistent_operation")

    assert tracer.has_error_spans()  # cache_lookup had error status

    db_spans = tracer.get_spans_by_operation("database_query")
    assert len(db_spans) == 1
    assert db_spans[0]["attributes"]["query_type"] == "SELECT"

    error_spans = tracer.get_spans_with_status(TraceStatus.ERROR)
    assert len(error_spans) == 1
    assert error_spans[0]["operation_name"] == "cache_lookup"

    user_spans = tracer.get_spans_with_attribute("user_id", "12345")
    assert len(user_spans) == 1
    assert user_spans[0]["operation_name"] == "main_operation"


@pytest.mark.asyncio
async def test_mock_tracer_span_lifecycle():
    """Test span lifecycle tracking in mock tracer."""
    tracer = MockTracer()

    async with await tracer.start_trace("lifecycle_test") as span:
        # Verify initial state
        span_info = tracer.spans[0]
        assert span_info["operation_name"] == "lifecycle_test"
        assert span_info["start_time"] is not None
        assert span_info["end_time"] is None
        assert span_info["status"] == TraceStatus.OK

        # Modify span
        await span.set_attribute("test_attr", "test_value")
        await span.add_event("test_event", {"event_data": "value"})
        await span.set_status(TraceStatus.OK, "All good")

        # Verify modifications
        assert span_info["attributes"]["test_attr"] == "test_value"
        assert len(span_info["events"]) == 1
        assert span_info["events"][0]["name"] == "test_event"
        assert span_info["events"][0]["attributes"]["event_data"] == "value"

    # Verify span was finished
    assert span_info["end_time"] is not None
    assert span_info["duration"] is not None
    assert span_info["duration"] > 0


@pytest.mark.asyncio
async def test_mock_tracer_exception_recording():
    """Test exception recording in mock tracer."""
    tracer = MockTracer()

    async with await tracer.start_trace("exception_test") as span:
        test_exception = ValueError("Test exception for tracing")
        await span.record_exception(test_exception)

        span_info = tracer.spans[0]
        assert "exceptions" in span_info
        assert len(span_info["exceptions"]) == 1

        exception_info = span_info["exceptions"][0]
        assert exception_info["type"] == "ValueError"
        assert exception_info["message"] == "Test exception for tracing"
        assert exception_info["timestamp"] is not None


@pytest.mark.asyncio
async def test_mock_tracer_trace_relationships():
    """Test parent-child relationships in traces."""
    tracer = MockTracer()

    async with await tracer.start_trace("parent_trace") as parent_span:
        parent_trace_id = parent_span.trace_context.trace_id

        async with await tracer.start_span("child_span_1") as child1:
            assert child1.trace_context.trace_id == parent_trace_id
            assert (
                child1.trace_context.parent_span_id == parent_span.trace_context.span_id
            )

            async with await tracer.start_span("grandchild_span") as grandchild:
                assert grandchild.trace_context.trace_id == parent_trace_id
                assert (
                    grandchild.trace_context.parent_span_id
                    == child1.trace_context.span_id
                )

    # Verify trace relationships
    trace_spans = tracer.get_spans_by_trace_id(parent_trace_id)
    assert len(trace_spans) == 3

    # Find parent span
    parent_spans = [s for s in trace_spans if s["is_root"]]
    assert len(parent_spans) == 1
    assert parent_spans[0]["operation_name"] == "parent_trace"


@pytest.mark.asyncio
async def test_mock_tracer_concurrent_spans():
    """Test handling of concurrent spans."""
    tracer = MockTracer()

    async def create_span(operation_name: str, delay: float):
        async with await tracer.start_trace(operation_name) as span:
            await span.set_attribute("operation", operation_name)
            await asyncio.sleep(delay)
            await span.add_event("operation_completed")

    # Run concurrent spans
    await asyncio.gather(
        create_span("operation_1", 0.01),
        create_span("operation_2", 0.01),
        create_span("operation_3", 0.01),
    )

    # Verify all spans were tracked
    assert len(tracer.spans) == 3
    operation_names = [span["operation_name"] for span in tracer.spans]
    assert "operation_1" in operation_names
    assert "operation_2" in operation_names
    assert "operation_3" in operation_names

    # Verify all spans completed
    for span in tracer.spans:
        assert span["end_time"] is not None
        assert len(span["events"]) == 1
        assert span["events"][0]["name"] == "operation_completed"


@pytest.mark.asyncio
async def test_mock_tracer_reset_functionality():
    """Test reset functionality of mock tracer."""
    tracer = MockTracer()

    # Generate some trace data
    async with await tracer.start_trace("test_operation") as span:
        await span.set_attribute("test", "value")

    await tracer.get_current_context()
    await tracer.inject_context({"test": "header"})

    # Verify data exists
    assert len(tracer.traces) > 0
    assert len(tracer.spans) > 0
    assert tracer.get_current_context_calls > 0
    assert len(tracer.inject_context_calls) > 0

    # Reset
    tracer.reset()

    # Verify everything is cleared
    assert len(tracer.traces) == 0
    assert len(tracer.spans) == 0
    assert tracer.current_context is None
    assert tracer.get_current_context_calls == 0
    assert len(tracer.inject_context_calls) == 0

    # Verify tracer still works after reset
    async with await tracer.start_trace("after_reset") as span:
        await span.set_attribute("reset_test", "passed")

    assert len(tracer.spans) == 1
    assert tracer.spans[0]["operation_name"] == "after_reset"
