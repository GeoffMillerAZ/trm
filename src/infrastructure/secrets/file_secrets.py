"""File-based implementation of secrets interface."""

import base64
import json
import os
from datetime import datetime
from pathlib import Path

from src.domain.interfaces.secrets import SecretsInterface, SecretValue


class FileSecretsManager(SecretsInterface):
    """File-based secrets management implementation."""

    def __init__(
        self,
        secrets_dir: str = "workspace/secrets",
        config_dir: str = "workspace/config",
        encrypt_secrets: bool = False,
        encryption_key: bytes | None = None,
    ):
        """Initialize file-based secrets manager.

        Args:
            secrets_dir: Directory to store encrypted secrets
            config_dir: Directory to store plain-text parameters
            encrypt_secrets: Whether to encrypt secret values
            encryption_key: Key for encryption (if None, will generate one)
        """
        self.secrets_dir = Path(secrets_dir).resolve()
        self.config_dir = Path(config_dir).resolve()
        self.encrypt_secrets = encrypt_secrets

        # Ensure directories exist
        self.secrets_dir.mkdir(parents=True, exist_ok=True)
        self.config_dir.mkdir(parents=True, exist_ok=True)

        # Initialize encryption if enabled
        self.cipher = None
        if self.encrypt_secrets:
            self._init_encryption(encryption_key)

    def _init_encryption(self, key: bytes | None = None) -> None:
        """Initialize encryption cipher."""
        try:
            from cryptography.fernet import Fernet

            if key is None:
                # Try to load existing key or generate new one
                key_file = self.secrets_dir / ".encryption_key"

                if key_file.exists():
                    with open(key_file, "rb") as f:
                        key = f.read()
                else:
                    key = Fernet.generate_key()
                    # Save key securely (in real use, this should be managed externally)
                    with open(key_file, "wb") as f:
                        f.write(key)
                    # Restrict permissions
                    os.chmod(key_file, 0o600)

            self.cipher = Fernet(key)

        except ImportError:
            # If cryptography is not available, disable encryption
            self.encrypt_secrets = False
            self.cipher = None

    def _encrypt_value(self, value: str) -> str:
        """Encrypt a value if encryption is enabled."""
        if not self.encrypt_secrets or self.cipher is None:
            return value

        encrypted_bytes = self.cipher.encrypt(value.encode("utf-8"))
        return base64.b64encode(encrypted_bytes).decode("utf-8")

    def _decrypt_value(self, encrypted_value: str) -> str:
        """Decrypt a value if encryption is enabled."""
        if not self.encrypt_secrets or self.cipher is None:
            return encrypted_value

        try:
            encrypted_bytes = base64.b64decode(encrypted_value.encode("utf-8"))
            decrypted_bytes = self.cipher.decrypt(encrypted_bytes)
            return decrypted_bytes.decode("utf-8")
        except Exception:
            # If decryption fails, return as-is (might be plain text)
            return encrypted_value

    def _sanitize_name(self, name: str) -> str:
        """Sanitize secret/parameter name for safe filename usage."""
        import re

        # Replace unsafe characters with underscores
        sanitized = re.sub(r"[^\w\-_.]", "_", name)
        # Limit length
        if len(sanitized) > 200:
            sanitized = sanitized[:200]
        return sanitized

    def _atomic_write_json(self, file_path: Path, data: dict) -> None:
        """Atomically write JSON data to file."""
        temp_file = file_path.with_suffix(".tmp")
        try:
            with open(temp_file, "w") as f:
                json.dump(data, f, indent=2, default=str)

            # Set restrictive permissions
            os.chmod(temp_file, 0o600)

            # Atomic rename
            temp_file.rename(file_path)

        except OSError:
            # Clean up temp file on error
            try:
                temp_file.unlink()
            except OSError:
                pass
            raise

    async def get_secret(self, secret_name: str) -> SecretValue | None:
        """Retrieve a secret by name."""
        safe_name = self._sanitize_name(secret_name)
        secret_file = self.secrets_dir / f"{safe_name}.json"

        if not secret_file.exists():
            return None

        try:
            with open(secret_file) as f:
                data = json.load(f)

            # Decrypt value if needed
            decrypted_value = self._decrypt_value(data["encrypted_value"])

            return SecretValue(
                value=decrypted_value,
                version=data.get("version", "1"),
                created_date=data.get("created_date"),
                last_accessed=datetime.utcnow().isoformat(),
            )

        except (json.JSONDecodeError, OSError, KeyError):
            return None

    async def get_parameter(self, parameter_name: str) -> str | None:
        """Retrieve a parameter by name (for non-sensitive config)."""
        safe_name = self._sanitize_name(parameter_name)
        param_file = self.config_dir / f"{safe_name}.json"

        if not param_file.exists():
            return None

        try:
            with open(param_file) as f:
                data = json.load(f)

            return data.get("value")

        except (json.JSONDecodeError, OSError, KeyError):
            return None

    async def get_secrets_batch(
        self, secret_names: list[str]
    ) -> dict[str, SecretValue | None]:
        """Retrieve multiple secrets in a single call for efficiency."""
        results = {}

        for secret_name in secret_names:
            results[secret_name] = await self.get_secret(secret_name)

        return results

    async def get_parameters_batch(
        self, parameter_names: list[str]
    ) -> dict[str, str | None]:
        """Retrieve multiple parameters in a single call for efficiency."""
        results = {}

        for parameter_name in parameter_names:
            results[parameter_name] = await self.get_parameter(parameter_name)

        return results

    async def set_secret(self, secret_name: str, secret_value: str) -> None:
        """Store a secret (for development/testing purposes)."""
        safe_name = self._sanitize_name(secret_name)
        secret_file = self.secrets_dir / f"{safe_name}.json"

        # Encrypt value
        encrypted_value = self._encrypt_value(secret_value)

        secret_data = {
            "name": secret_name,
            "encrypted_value": encrypted_value,
            "version": "1",
            "created_date": datetime.utcnow().isoformat(),
            "updated_date": datetime.utcnow().isoformat(),
            "encrypted": self.encrypt_secrets,
        }

        # If file exists, preserve some metadata
        if secret_file.exists():
            try:
                with open(secret_file) as f:
                    existing_data = json.load(f)
                secret_data["created_date"] = existing_data.get(
                    "created_date", secret_data["created_date"]
                )
                # Increment version
                try:
                    old_version = int(existing_data.get("version", "0"))
                    secret_data["version"] = str(old_version + 1)
                except (ValueError, TypeError):
                    secret_data["version"] = "1"
            except (json.JSONDecodeError, OSError):
                pass

        self._atomic_write_json(secret_file, secret_data)

    async def set_parameter(self, parameter_name: str, parameter_value: str) -> None:
        """Store a parameter (for development/testing purposes)."""
        safe_name = self._sanitize_name(parameter_name)
        param_file = self.config_dir / f"{safe_name}.json"

        param_data = {
            "name": parameter_name,
            "value": parameter_value,
            "created_date": datetime.utcnow().isoformat(),
            "updated_date": datetime.utcnow().isoformat(),
        }

        # If file exists, preserve created_date
        if param_file.exists():
            try:
                with open(param_file) as f:
                    existing_data = json.load(f)
                param_data["created_date"] = existing_data.get(
                    "created_date", param_data["created_date"]
                )
            except (json.JSONDecodeError, OSError):
                pass

        self._atomic_write_json(param_file, param_data)

    async def delete_secret(self, secret_name: str) -> None:
        """Delete a secret (for cleanup purposes)."""
        safe_name = self._sanitize_name(secret_name)
        secret_file = self.secrets_dir / f"{safe_name}.json"

        try:
            secret_file.unlink()
        except OSError:
            # File doesn't exist, that's fine
            pass

    async def list_secrets(self, prefix: str | None = None) -> list[str]:
        """List available secrets with optional prefix filter."""
        secrets = []

        for secret_file in self.secrets_dir.glob("*.json"):
            if secret_file.name.startswith(
                "."
            ):  # Skip system files like .encryption_key
                continue

            try:
                with open(secret_file) as f:
                    data = json.load(f)

                secret_name = data.get("name", secret_file.stem)

                if prefix is None or secret_name.startswith(prefix):
                    secrets.append(secret_name)

            except (json.JSONDecodeError, OSError, KeyError):
                continue

        return sorted(secrets)

    def list_parameters(self, prefix: str | None = None) -> list[str]:
        """List available parameters with optional prefix filter."""
        parameters = []

        for param_file in self.config_dir.glob("*.json"):
            try:
                with open(param_file) as f:
                    data = json.load(f)

                param_name = data.get("name", param_file.stem)

                if prefix is None or param_name.startswith(prefix):
                    parameters.append(param_name)

            except (json.JSONDecodeError, OSError, KeyError):
                continue

        return sorted(parameters)

    def get_secrets_stats(self) -> dict:
        """Get secrets management statistics for debugging."""
        stats = {
            "total_secrets": 0,
            "total_parameters": 0,
            "encryption_enabled": self.encrypt_secrets,
            "secrets_size_bytes": 0,
            "parameters_size_bytes": 0,
        }

        # Count secrets
        for secret_file in self.secrets_dir.glob("*.json"):
            if not secret_file.name.startswith("."):  # Skip system files
                try:
                    file_stat = secret_file.stat()
                    stats["total_secrets"] += 1
                    stats["secrets_size_bytes"] += file_stat.st_size
                except OSError:
                    pass

        # Count parameters
        for param_file in self.config_dir.glob("*.json"):
            try:
                file_stat = param_file.stat()
                stats["total_parameters"] += 1
                stats["parameters_size_bytes"] += file_stat.st_size
            except OSError:
                pass

        return stats
