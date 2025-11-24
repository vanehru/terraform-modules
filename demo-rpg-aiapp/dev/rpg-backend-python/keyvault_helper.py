"""Azure Key Vault helper for retrieving secrets."""
import os
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient


def get_sql_connection_string():
    """Retrieve SQL connection string, preferring Key Vault with env fallback.

    Returns:
        str: SQL connection string

    Order of resolution:
    1) Azure Key Vault secret `sqlconnectionString` when `KEYVAULT_URL` is configured and reachable
    2) Environment variable `SQL_CONNECTION_STRING`
    """
    # Fallback to environment if explicitly provided
    env_conn = os.environ.get("SQL_CONNECTION_STRING")

    keyvault_url = os.environ.get("KEYVAULT_URL")
    if keyvault_url:
        try:
            if not keyvault_url.startswith('https://'):
                raise ValueError("Key Vault URL must use HTTPS")

            credential = DefaultAzureCredential()
            client = SecretClient(vault_url=keyvault_url, credential=credential)
            secret = client.get_secret("sqlconnectionString")
            return secret.value
        except Exception:
            # Fall through to env var if KV is not accessible
            if env_conn:
                return env_conn
            # Re-raise a generic message to avoid leaking details
            raise Exception("Key Vaultへのアクセスに失敗しました。SQL_CONNECTION_STRING の環境変数も未設定です。")

    # No Key Vault URL configured; use env var if present
    if env_conn:
        return env_conn

    raise ValueError("'KEYVAULT_URL' または 'SQL_CONNECTION_STRING' のいずれかを設定してください。")
