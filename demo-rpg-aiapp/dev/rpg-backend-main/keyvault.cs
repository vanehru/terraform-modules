using System;
using System.Threading.Tasks;
using Azure.Identity;　// Azure AD認証用ライブラリ
using Azure.Security.KeyVault.Secrets; // Key Vaultシークレット取得用ライブラリ

namespace AzureOpenAISample
{
    // Key Vaultの共通処理をまとめたクラス
    public static class KeyVault
    {
        // Key Vaultから接続文字列を取得する関数
        public static async Task<string> GetSqlConnectionStringAsync()
        {
            // 環境変数「KEYVAULT_URL」からKey VaultのURLを取得
            string keyVaultUrl = Environment.GetEnvironmentVariable("KEYVAULT_URL");

            // URLが設定されていない場合はエラー
            if (string.IsNullOrEmpty(keyVaultUrl))
            {
                throw new InvalidOperationException("環境変数 'KEYVAULT_URL' が設定されていません。");
            }

            // Key Vaultのシークレットクライアントを初期化
            var client = new SecretClient(new Uri(keyVaultUrl), new DefaultAzureCredential());

            // シークレット名「sqlconnectionString」の値を取得
            KeyVaultSecret secret = await client.GetSecretAsync("sqlconnectionString");

            // 接続文字列を返却
            return secret.Value;
        }
    }
}