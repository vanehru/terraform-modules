project_name = "rpgai"
environment  = "staging"
location     = "Japan East"
instance     = "001"

sql_server_name = "sql-rpgai-staging-001"
sql_database_name = "rpgaidb"
sql_database_sku_name = "S0"

key_vault_name = "kv-rpgai-staging-001"
function_app_name = "func-rpgai-staging-001"
static_web_app_name = "swa-rpgai-staging-001"
storage_account_name = "strpgaistaging001"
openai_account_name = "oai-rpgai-staging-001"

tags = {
  Environment = "staging"
  Project     = "rpg-ai-app"
}