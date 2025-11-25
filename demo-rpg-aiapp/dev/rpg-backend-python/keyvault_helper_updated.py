"""Azure Key Vault helper for retrieving secrets - Updated for infrastructure."""
import os
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient


def get_secret_from_keyvault(secret_name: str, fallback_env_var: str = None):
    """Generic function to retrieve secrets from Key Vault with environment fallback.
    
    Args:
        secret_name: Name of the secret in Key Vault
        fallback_env_var: Environment variable name to use as fallback
        
    Returns:
        str: Secret value
    """
    # Try environment variable first if provided
    if fallback_env_var:
        env_value = os.environ.get(fallback_env_var)
        if env_value:
            return env_value
    
    # Try Key Vault
    keyvault_url = os.environ.get("KEY_VAULT_URI")
    if keyvault_url:
        try:
            credential = DefaultAzureCredential()
            client = SecretClient(vault_url=keyvault_url, credential=credential)
            secret = client.get_secret(secret_name)
            return secret.value
        except Exception as e:
            if fallback_env_var:
                env_value = os.environ.get(fallback_env_var)
                if env_value:
                    return env_value
            raise Exception(f"Key Vault access failed for secret '{secret_name}': {str(e)}")
    
    # No Key Vault URL configured
    if fallback_env_var:
        env_value = os.environ.get(fallback_env_var)
        if env_value:
            return env_value
    
    raise ValueError(f"Neither KEY_VAULT_URI nor {fallback_env_var} environment variable is configured.")


def get_sql_connection_string():
    """Retrieve SQL connection string from Key Vault or environment."""
    return get_secret_from_keyvault("sql-connection-string", "SQL_CONNECTION_STRING")


def get_openai_endpoint():
    """Retrieve OpenAI endpoint from Key Vault or environment."""
    return get_secret_from_keyvault("openai-endpoint", "AZURE_OPENAI_ENDPOINT")


def get_openai_key():
    """Retrieve OpenAI API key from Key Vault or environment."""
    return get_secret_from_keyvault("openai-key", "AZURE_OPENAI_KEY")


def get_sql_server_fqdn():
    """Retrieve SQL Server FQDN from Key Vault or environment."""
    return get_secret_from_keyvault("sql-server-fqdn", "SQL_SERVER_FQDN")


def get_sql_database_name():
    """Retrieve SQL Database name from Key Vault or environment."""
    return get_secret_from_keyvault("sql-database-name", "SQL_DATABASE_NAME")


def get_sql_username():
    """Retrieve SQL username from Key Vault or environment."""
    return get_secret_from_keyvault("sql-username", "SQL_USERNAME")