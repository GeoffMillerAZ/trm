"""CloudWatch and console logging implementations."""

import json
import sys
import traceback
from datetime import datetime
from typing import Any

import boto3
from botocore.exceptions import ClientError

from src.domain.interfaces.logger import LoggerInterface, LogLevel


class CloudWatchLogger(LoggerInterface):
    """CloudWatch Logs implementation of logger interface."""

    def __init__(
        self,
        log_group_name: str,
        log_stream_name: str,
        region_name: str = "us-east-1",
        endpoint_url: str | None = None,
    ):
        """Initialize CloudWatch logger.

        Args:
            log_group_name: CloudWatch log group name
            log_stream_name: CloudWatch log stream name
            region_name: AWS region
            endpoint_url: Custom endpoint URL (for testing)
        """
        self.log_group_name = log_group_name
        self.log_stream_name = log_stream_name

        client_config = {"region_name": region_name}
        if endpoint_url:
            client_config["endpoint_url"] = endpoint_url

        self.client = boto3.client("logs", **client_config)
        self.sequence_token: str | None = None

        # Ensure log group and stream exist
        self._ensure_log_group_exists()
        self._ensure_log_stream_exists()

    def _ensure_log_group_exists(self) -> None:
        """Ensure CloudWatch log group exists."""
        try:
            self.client.describe_log_groups(logGroupNamePrefix=self.log_group_name)
        except ClientError:
            try:
                self.client.create_log_group(logGroupName=self.log_group_name)
            except ClientError as e:
                if e.response["Error"]["Code"] != "ResourceAlreadyExistsException":
                    raise

    def _ensure_log_stream_exists(self) -> None:
        """Ensure CloudWatch log stream exists."""
        try:
            response = self.client.describe_log_streams(
                logGroupName=self.log_group_name,
                logStreamNamePrefix=self.log_stream_name,
            )

            streams = response.get("logStreams", [])
            matching_streams = [
                s for s in streams if s["logStreamName"] == self.log_stream_name
            ]

            if matching_streams:
                self.sequence_token = matching_streams[0].get("uploadSequenceToken")
            else:
                self.client.create_log_stream(
                    logGroupName=self.log_group_name, logStreamName=self.log_stream_name
                )

        except ClientError as e:
            if e.response["Error"]["Code"] != "ResourceAlreadyExistsException":
                raise

    async def log(
        self,
        level: LogLevel,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
        exception: Exception | None = None,
    ) -> None:
        """Log a message to CloudWatch Logs."""
        try:
            # Build structured log entry
            log_entry = {
                "timestamp": datetime.utcnow().isoformat(),
                "level": level.value,
                "message": message,
                "service": "trm-blockexplorer",
            }

            if correlation_id:
                log_entry["correlation_id"] = correlation_id

            if metadata:
                log_entry["metadata"] = metadata

            if exception:
                log_entry["exception"] = {
                    "type": type(exception).__name__,
                    "message": str(exception),
                    "traceback": traceback.format_exception(
                        type(exception), exception, exception.__traceback__
                    ),
                }

            # Send to CloudWatch
            log_event = {
                "timestamp": int(datetime.utcnow().timestamp() * 1000),
                "message": json.dumps(log_entry, default=str),
            }

            put_events_kwargs = {
                "logGroupName": self.log_group_name,
                "logStreamName": self.log_stream_name,
                "logEvents": [log_event],
            }

            if self.sequence_token:
                put_events_kwargs["sequenceToken"] = self.sequence_token

            response = self.client.put_log_events(**put_events_kwargs)
            self.sequence_token = response.get("nextSequenceToken")

        except ClientError as e:
            # Fallback to console logging if CloudWatch fails
            print(f"CloudWatch logging failed: {e}", file=sys.stderr)
            console_logger = ConsoleLogger()
            await console_logger.log(
                level, message, correlation_id, metadata, exception
            )


class ConsoleLogger(LoggerInterface):
    """Console logging implementation for local development."""

    def __init__(self, enable_colors: bool = True):
        """Initialize console logger.

        Args:
            enable_colors: Whether to enable colored output
        """
        self.enable_colors = enable_colors
        self.colors = {
            LogLevel.DEBUG: "\033[36m",  # Cyan
            LogLevel.INFO: "\033[32m",  # Green
            LogLevel.WARNING: "\033[33m",  # Yellow
            LogLevel.ERROR: "\033[31m",  # Red
            LogLevel.CRITICAL: "\033[35m",  # Magenta
        }
        self.reset_color = "\033[0m"

    def _colorize(self, level: LogLevel, text: str) -> str:
        """Apply color to text based on log level."""
        if not self.enable_colors:
            return text

        color = self.colors.get(level, "")
        return f"{color}{text}{self.reset_color}"

    async def log(
        self,
        level: LogLevel,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
        exception: Exception | None = None,
    ) -> None:
        """Log a message to console."""
        timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")

        # Build log message
        log_parts = [f"[{timestamp}]", f"[{level.value}]", "[trm-blockexplorer]"]

        if correlation_id:
            log_parts.append(f"[{correlation_id}]")

        log_parts.append(message)

        log_message = " ".join(log_parts)
        colored_message = self._colorize(level, log_message)

        # Choose output stream based on level
        output_stream = (
            sys.stderr if level in [LogLevel.ERROR, LogLevel.CRITICAL] else sys.stdout
        )
        print(colored_message, file=output_stream)

        # Print metadata if present
        if metadata:
            metadata_str = json.dumps(metadata, indent=2, default=str)
            colored_metadata = self._colorize(level, f"Metadata: {metadata_str}")
            print(colored_metadata, file=output_stream)

        # Print exception if present
        if exception:
            exception_str = f"Exception: {type(exception).__name__}: {exception}"
            colored_exception = self._colorize(level, exception_str)
            print(colored_exception, file=output_stream)

            # Print traceback for errors and critical messages
            if level in [LogLevel.ERROR, LogLevel.CRITICAL]:
                tb_str = "".join(
                    traceback.format_exception(
                        type(exception), exception, exception.__traceback__
                    )
                )
                colored_traceback = self._colorize(level, tb_str)
                print(colored_traceback, file=output_stream)


class StructuredLogger(LoggerInterface):
    """Structured logger that combines console and CloudWatch logging."""

    def __init__(
        self,
        console_logger: ConsoleLogger,
        cloudwatch_logger: CloudWatchLogger | None = None,
        min_cloudwatch_level: LogLevel = LogLevel.INFO,
    ):
        """Initialize structured logger.

        Args:
            console_logger: Console logger for local output
            cloudwatch_logger: Optional CloudWatch logger for production
            min_cloudwatch_level: Minimum level to send to CloudWatch
        """
        self.console_logger = console_logger
        self.cloudwatch_logger = cloudwatch_logger
        self.min_cloudwatch_level = min_cloudwatch_level

    def _should_send_to_cloudwatch(self, level: LogLevel) -> bool:
        """Determine if log should be sent to CloudWatch."""
        if not self.cloudwatch_logger:
            return False

        level_priorities = {
            LogLevel.DEBUG: 10,
            LogLevel.INFO: 20,
            LogLevel.WARNING: 30,
            LogLevel.ERROR: 40,
            LogLevel.CRITICAL: 50,
        }

        return level_priorities[level] >= level_priorities[self.min_cloudwatch_level]

    async def log(
        self,
        level: LogLevel,
        message: str,
        correlation_id: str | None = None,
        metadata: dict[str, Any] | None = None,
        exception: Exception | None = None,
    ) -> None:
        """Log a message to both console and CloudWatch."""
        # Always log to console
        await self.console_logger.log(
            level, message, correlation_id, metadata, exception
        )

        # Conditionally log to CloudWatch
        if self._should_send_to_cloudwatch(level):
            await self.cloudwatch_logger.log(
                level, message, correlation_id, metadata, exception
            )
