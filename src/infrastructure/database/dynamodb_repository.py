"""DynamoDB implementation of database interface."""

import json
from datetime import datetime
from decimal import Decimal
from typing import Any

import boto3
from botocore.exceptions import ClientError

from src.domain.entities.address_balance import AddressBalance
from src.domain.interfaces.database import DatabaseInterface
from src.domain.value_objects.ethereum_address import EthereumAddress


class DynamoDBRepository(DatabaseInterface):
    """DynamoDB implementation of database interface."""

    def __init__(
        self,
        table_name: str = "trm-blockexplorer",
        region_name: str = "us-east-1",
        endpoint_url: str | None = None,
        aws_access_key_id: str | None = None,
        aws_secret_access_key: str | None = None,
    ):
        """Initialize DynamoDB repository.

        Args:
            table_name: DynamoDB table name
            region_name: AWS region
            endpoint_url: Custom endpoint URL (for local development)
            aws_access_key_id: AWS access key (for local development)
            aws_secret_access_key: AWS secret key (for local development)
        """
        self.table_name = table_name

        # Configure DynamoDB client for local or production
        client_config = {"region_name": region_name}

        if endpoint_url:
            # Local development configuration
            client_config.update(
                {
                    "endpoint_url": endpoint_url,
                    "aws_access_key_id": aws_access_key_id or "local",
                    "aws_secret_access_key": aws_secret_access_key or "local",
                }
            )

        self.dynamodb = boto3.resource("dynamodb", **client_config)
        self.table = self.dynamodb.Table(table_name)

    async def save_balance(self, balance: AddressBalance) -> None:
        """Save address balance to DynamoDB."""
        try:
            item = {
                "PK": f"ADDRESS#{balance.address.value}",
                "SK": f"BALANCE#{balance.retrieved_at.isoformat()}",
                "address": balance.address.value,
                "balance_eth": str(balance.balance_eth),
                "retrieved_at": balance.retrieved_at.isoformat(),
                "ttl": int(
                    balance.retrieved_at.timestamp() + 86400 * 30
                ),  # 30 days TTL
            }

            self.table.put_item(Item=item)

        except ClientError as e:
            raise RuntimeError(
                f"Failed to save balance: {e.response['Error']['Message']}"
            ) from e

    async def get_balance_history(
        self, address: EthereumAddress, limit: int = 100
    ) -> list[AddressBalance]:
        """Get balance history for an address."""
        try:
            response = self.table.query(
                KeyConditionExpression="PK = :pk AND begins_with(SK, :sk_prefix)",
                ExpressionAttributeValues={
                    ":pk": f"ADDRESS#{address.value}",
                    ":sk_prefix": "BALANCE#",
                },
                ScanIndexForward=False,  # Most recent first
                Limit=limit,
            )

            balances = []
            for item in response.get("Items", []):
                balance = AddressBalance(
                    address=EthereumAddress(item["address"]),
                    balance_eth=Decimal(item["balance_eth"]),
                    retrieved_at=datetime.fromisoformat(item["retrieved_at"]),
                )
                balances.append(balance)

            return balances

        except ClientError as e:
            raise RuntimeError(
                f"Failed to get balance history: {e.response['Error']['Message']}"
            ) from e

    async def get_latest_balance(
        self, address: EthereumAddress
    ) -> AddressBalance | None:
        """Get the most recent balance for an address."""
        history = await self.get_balance_history(address, limit=1)
        return history[0] if history else None

    async def save_metadata(self, key: str, value: dict[str, Any]) -> None:
        """Save metadata to DynamoDB."""
        try:
            item = {
                "PK": f"METADATA#{key}",
                "SK": "CURRENT",
                "metadata": json.dumps(value, default=str),
                "updated_at": datetime.utcnow().isoformat(),
            }

            self.table.put_item(Item=item)

        except ClientError as e:
            raise RuntimeError(
                f"Failed to save metadata: {e.response['Error']['Message']}"
            ) from e

    async def get_metadata(self, key: str) -> dict[str, Any] | None:
        """Get metadata from DynamoDB."""
        try:
            response = self.table.get_item(
                Key={"PK": f"METADATA#{key}", "SK": "CURRENT"}
            )

            item = response.get("Item")
            if not item:
                return None

            return json.loads(item["metadata"])

        except ClientError as e:
            raise RuntimeError(
                f"Failed to get metadata: {e.response['Error']['Message']}"
            ) from e

    async def create_table_if_not_exists(self) -> None:
        """Create DynamoDB table if it doesn't exist (for local development)."""
        import time

        max_retries = 5
        retry_delay = 2

        for attempt in range(max_retries):
            try:
                self.table.load()
                # Table exists, we're done
                return
            except ClientError as e:
                if e.response["Error"]["Code"] == "ResourceNotFoundException":
                    # Table doesn't exist, try to create it
                    try:
                        table = self.dynamodb.create_table(
                            TableName=self.table_name,
                            KeySchema=[
                                {"AttributeName": "PK", "KeyType": "HASH"},
                                {"AttributeName": "SK", "KeyType": "RANGE"},
                            ],
                            AttributeDefinitions=[
                                {"AttributeName": "PK", "AttributeType": "S"},
                                {"AttributeName": "SK", "AttributeType": "S"},
                            ],
                            BillingMode="PAY_PER_REQUEST",
                        )
                        # Wait for table to be created
                        table.wait_until_exists()
                        return
                    except ClientError as create_error:
                        if (
                            create_error.response["Error"]["Code"]
                            == "ResourceInUseException"
                        ):
                            # Table already exists (race condition), that's OK
                            return
                        elif attempt < max_retries - 1:
                            # Connection issue, retry
                            time.sleep(retry_delay)
                            continue
                        else:
                            raise
                else:
                    # Other error, retry if we have attempts left
                    if attempt < max_retries - 1:
                        time.sleep(retry_delay)
                        continue
                    else:
                        raise
