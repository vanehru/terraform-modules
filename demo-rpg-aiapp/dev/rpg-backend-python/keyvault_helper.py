"""Azure Key Vault helper for retrieving secrets."""
import os
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient


def get_sql_connection_string():
    """
    Retrieve SQL connection string from Azure Key Vault.
    
    Returns:
        str: SQL connection string
        
    Raises:
        ValueError: If KEYVAULT_URL environment variable is not set
        Exception: For Azure Key Vault access errors
    """
    try:
        keyvault_url = os.environ.get("KEYVAULT_URL")
        
        if not keyvault_url:
            raise ValueError("環境変数 'KEYVAULT_URL' が設定されていません。")
        
        # Validate URL format
        if not keyvault_url.startswith('https://'):
            raise ValueError("Key Vault URL must use HTTPS")
        
        credential = DefaultAzureCredential()
        client = SecretClient(vault_url=keyvault_url, credential=credential)
        
        secret = client.get_secret("sqlconnectionString")
        return secret.value
        
    except ValueError:
        raise
    except Exception as e:
        raise Exception(f"Key Vaultへのアクセスに失敗しました: {str(e)}") from e
