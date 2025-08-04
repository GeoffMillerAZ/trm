"""AWS Secrets Manager and SSM Parameter Store implementation."""

from datetime import datetime

import boto3
from botocore.exceptions import ClientError

from src.domain.interfaces.secrets import SecretsInterface, SecretValue


class AWSSecretsManager(SecretsInterface):
    """AWS Secrets Manager and SSM Parameter Store implementation."""

    def __init__(
        self,
        region_name: str = "us-east-1",
        endpoint_url: str | None = None,
        aws_access_key_id: str | None = None,
        aws_secret_access_key: str | None = None,
        secret_prefix: str = "trm-blockexplorer/",
        parameter_prefix: str = "/trm-blockexplorer/",
    ):
        """Initialize AWS secrets manager.

        Args:
            region_name: AWS region
            endpoint_url: Custom endpoint URL (for local development)
            aws_access_key_id: AWS access key
            aws_secret_access_key: AWS secret key
            secret_prefix: Prefix for secret names
            parameter_prefix: Prefix for parameter names
        """
        self.secret_prefix = secret_prefix
        self.parameter_prefix = parameter_prefix

        # Configure AWS clients
        client_config = {"region_name": region_name}

        if endpoint_url:
            client_config.update(
                {
                    "endpoint_url": endpoint_url,
                    "aws_access_key_id": aws_access_key_id or "local",
                    "aws_secret_access_key": aws_secret_access_key or "local",
                }
            )

        self.secrets_client = boto3.client("secretsmanager", **client_config)
        self.ssm_client = boto3.client("ssm", **client_config)

    def _get_secret_name(self, name: str) -> str:
        """Get full secret name with prefix."""
        if name.startswith(self.secret_prefix):
            return name
        return f"{self.secret_prefix}{name}"

    def _get_parameter_name(self, name: str) -> str:
        """Get full parameter name with prefix."""
        if name.startswith(self.parameter_prefix):
            return name
        return f"{self.parameter_prefix}{name}"

    async def get_secret(self, secret_name: str) -> SecretValue | None:
        """Retrieve a secret from AWS Secrets Manager."""
        try:
            full_name = self._get_secret_name(secret_name)

            response = self.secrets_client.get_secret_value(SecretId=full_name)

            secret_value = SecretValue(
                value=response["SecretString"],
                version=response.get("VersionId"),
                created_date=response.get("CreatedDate", "").isoformat()
                if response.get("CreatedDate")
                else None,
            )

            return secret_value

        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            if error_code in [
                "ResourceNotFoundException",
                "DecryptionFailureException",
                "InternalServiceErrorException",
            ]:
                return None
            raise RuntimeError(
                f"Failed to retrieve secret {secret_name}: {e.response['Error']['Message']}"
            ) from e
        except Exception as e:
            raise RuntimeError(
                f"Unexpected error retrieving secret {secret_name}: {str(e)}"
            ) from e

    async def get_parameter(self, parameter_name: str) -> str | None:
        """Retrieve a parameter from SSM Parameter Store."""
        try:
            full_name = self._get_parameter_name(parameter_name)

            response = self.ssm_client.get_parameter(
                Name=full_name,
                WithDecryption=True,  # Decrypt SecureString parameters
            )

            return response["Parameter"]["Value"]

        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            if error_code == "ParameterNotFound":
                return None
            raise RuntimeError(
                f"Failed to retrieve parameter {parameter_name}: {e.response['Error']['Message']}"
            ) from e
        except Exception as e:
            raise RuntimeError(
                f"Unexpected error retrieving parameter {parameter_name}: {str(e)}"
            ) from e

    async def get_secrets_batch(
        self, secret_names: list[str]
    ) -> dict[str, SecretValue | None]:
        """Retrieve multiple secrets in batch (limited by AWS API)."""
        results = {}

        # AWS Secrets Manager doesn't have native batch get, so we do them individually
        # In production, you might want to implement concurrent requests
        for secret_name in secret_names:
            try:
                results[secret_name] = await self.get_secret(secret_name)
            except Exception:
                results[secret_name] = None

        return results

    async def get_parameters_batch(
        self, parameter_names: list[str]
    ) -> dict[str, str | None]:
        """Retrieve multiple parameters in batch using SSM get_parameters."""
        try:
            full_names = [self._get_parameter_name(name) for name in parameter_names]

            response = self.ssm_client.get_parameters(
                Names=full_names, WithDecryption=True
            )

            # Create mapping of original names to values
            results = {}
            name_mapping = {
                self._get_parameter_name(name): name for name in parameter_names
            }

            # Add found parameters
            for param in response["Parameters"]:
                original_name = name_mapping.get(param["Name"])
                if original_name:
                    results[original_name] = param["Value"]

            # Add missing parameters as None
            for name in parameter_names:
                if name not in results:
                    results[name] = None

            return results

        except ClientError as e:
            raise RuntimeError(
                f"Failed to retrieve parameters batch: {e.response['Error']['Message']}"
            ) from e
        except Exception as e:
            raise RuntimeError(
                f"Unexpected error retrieving parameters batch: {str(e)}"
            ) from e

    async def set_secret(self, secret_name: str, secret_value: str) -> None:
        """Store a secret in AWS Secrets Manager."""
        try:
            full_name = self._get_secret_name(secret_name)

            # Try to update first (if secret exists)
            try:
                self.secrets_client.update_secret(
                    SecretId=full_name, SecretString=secret_value
                )
            except ClientError as e:
                if e.response["Error"]["Code"] == "ResourceNotFoundException":
                    # Secret doesn't exist, create it
                    self.secrets_client.create_secret(
                        Name=full_name,
                        SecretString=secret_value,
                        Description=f"TRM Block Explorer secret: {secret_name}",
                    )
                else:
                    raise

        except ClientError as e:
            raise RuntimeError(
                f"Failed to store secret {secret_name}: {e.response['Error']['Message']}"
            ) from e
        except Exception as e:
            raise RuntimeError(
                f"Unexpected error storing secret {secret_name}: {str(e)}"
            ) from e

    async def set_parameter(self, parameter_name: str, parameter_value: str) -> None:
        """Store a parameter in SSM Parameter Store."""
        try:
            full_name = self._get_parameter_name(parameter_name)

            self.ssm_client.put_parameter(
                Name=full_name,
                Value=parameter_value,
                Type="String",  # Use SecureString for sensitive data
                Overwrite=True,
                Description=f"TRM Block Explorer parameter: {parameter_name}",
            )

        except ClientError as e:
            raise RuntimeError(
                f"Failed to store parameter {parameter_name}: {e.response['Error']['Message']}"
            ) from e
        except Exception as e:
            raise RuntimeError(
                f"Unexpected error storing parameter {parameter_name}: {str(e)}"
            ) from e

    async def delete_secret(self, secret_name: str) -> None:
        """Delete a secret from AWS Secrets Manager."""
        try:
            full_name = self._get_secret_name(secret_name)

            self.secrets_client.delete_secret(
                SecretId=full_name,
                ForceDeleteWithoutRecovery=True,  # For development/testing
            )

        except ClientError as e:
            if e.response["Error"]["Code"] != "ResourceNotFoundException":
                raise RuntimeError(
                    f"Failed to delete secret {secret_name}: {e.response['Error']['Message']}"
                ) from e
        except Exception as e:
            raise RuntimeError(
                f"Unexpected error deleting secret {secret_name}: {str(e)}"
            ) from e

    async def list_secrets(self, prefix: str | None = None) -> list[str]:
        """List available secrets with optional prefix filter."""
        try:
            # Start with our base prefix
            filter_prefix = self.secret_prefix
            if prefix:
                filter_prefix += prefix

            paginator = self.secrets_client.get_paginator("list_secrets")
            secret_names = []

            for page in paginator.paginate():
                for secret in page["SecretList"]:
                    secret_name = secret["Name"]
                    if secret_name.startswith(filter_prefix):
                        # Remove our base prefix to return clean names
                        clean_name = secret_name[len(self.secret_prefix) :]
                        secret_names.append(clean_name)

            return secret_names

        except ClientError as e:
            raise RuntimeError(
                f"Failed to list secrets: {e.response['Error']['Message']}"
            ) from e
        except Exception as e:
            raise RuntimeError(f"Unexpected error listing secrets: {str(e)}") from e


class EnvironmentSecretsManager(SecretsInterface):
    """Environment variables-based secrets manager for local development."""

    def __init__(self, env_prefix: str = "TRM_"):
        """Initialize environment secrets manager.

        Args:
            env_prefix: Prefix for environment variables
        """
        self.env_prefix = env_prefix
        import os

        self.env_vars = dict(os.environ)

    def _get_env_name(self, name: str) -> str:
        """Get environment variable name with prefix."""
        clean_name = name.upper().replace("-", "_").replace("/", "_")
        if clean_name.startswith(self.env_prefix):
            return clean_name
        return f"{self.env_prefix}{clean_name}"

    async def get_secret(self, secret_name: str) -> SecretValue | None:
        """Retrieve secret from environment variables."""
        env_name = self._get_env_name(secret_name)
        value = self.env_vars.get(env_name)

        if value is None:
            return None

        return SecretValue(
            value=value, version="env", created_date=datetime.utcnow().isoformat()
        )

    async def get_parameter(self, parameter_name: str) -> str | None:
        """Retrieve parameter from environment variables."""
        env_name = self._get_env_name(parameter_name)
        return self.env_vars.get(env_name)

    async def get_secrets_batch(
        self, secret_names: list[str]
    ) -> dict[str, SecretValue | None]:
        """Retrieve multiple secrets from environment."""
        results = {}
        for name in secret_names:
            results[name] = await self.get_secret(name)
        return results

    async def get_parameters_batch(
        self, parameter_names: list[str]
    ) -> dict[str, str | None]:
        """Retrieve multiple parameters from environment."""
        results = {}
        for name in parameter_names:
            results[name] = await self.get_parameter(name)
        return results

    async def set_secret(self, secret_name: str, secret_value: str) -> None:
        """Set environment variable (for testing)."""
        env_name = self._get_env_name(secret_name)
        import os

        os.environ[env_name] = secret_value
        self.env_vars[env_name] = secret_value

    async def set_parameter(self, parameter_name: str, parameter_value: str) -> None:
        """Set environment variable (for testing)."""
        await self.set_secret(parameter_name, parameter_value)

    async def delete_secret(self, secret_name: str) -> None:
        """Delete environment variable."""
        env_name = self._get_env_name(secret_name)
        import os

        if env_name in os.environ:
            del os.environ[env_name]
        self.env_vars.pop(env_name, None)

    async def list_secrets(self, prefix: str | None = None) -> list[str]:
        """List environment variables matching pattern."""
        filter_prefix = self.env_prefix
        if prefix:
            filter_prefix += prefix.upper().replace("-", "_").replace("/", "_")

        matching_vars = []
        for env_name in self.env_vars.keys():
            if env_name.startswith(filter_prefix):
                # Remove prefix and convert back to clean name
                clean_name = env_name[len(self.env_prefix) :].lower().replace("_", "-")
                matching_vars.append(clean_name)

        return sorted(matching_vars)
