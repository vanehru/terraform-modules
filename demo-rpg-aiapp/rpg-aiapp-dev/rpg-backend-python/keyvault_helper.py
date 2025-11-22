"""Azure Key Vault helper for retrieving secrets."""
import os
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient


async def get_sql_connection_string():
    """
    Retrieve SQL connection string from Azure Key Vault.
    
    Returns:
        str: SQL connection string
        
    Raises:
        ValueError: If KEYVAULT_URL environment variable is not set
    """
    keyvault_url = os.environ.get("KEYVAULT_URL")
    
    if not keyvault_url:
        raise ValueError("環境変数 'KEYVAULT_URL' が設定されていません。")
    
    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=keyvault_url, credential=credential)
    
    secret = client.get_secret("sqlconnectionString")
    return secret.value
