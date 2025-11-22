using System;
using System.Security.Cryptography;
using System.Linq;

namespace AzureOpenAISample.Security
{
    // PBKDF2を使ったパスワードのハッシュ化と検証を行うクラス
    public static class PBKDF2Hash
    {
        // ソルト（salt）のサイズ。ハッシュ化の強度に影響します。
        private const int SaltSize = 16;

        // ハッシュ化されたパスワードのキー（出力）のサイズ。
        private const int KeySize = 32;

        // パスワードハッシュを生成する際の反復回数。回数が多いほどセキュアになりますが、処理に時間がかかります。（ブルートフォース攻撃対策）
        private const int Iterations = 100000;

        // パスワードをPBKDF2アルゴリズムでハッシュ化するメソッド
        public static string HashPassword(string password)
        {
            // セキュアランダムなソルトを生成
            using var rng = RandomNumberGenerator.Create();
            byte[] salt = new byte[SaltSize];
            rng.GetBytes(salt); // ランダムにソルトを生成

            // PBKDF2アルゴリズムを使用してパスワードからハッシュ化されたキーを生成
            using var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations, HashAlgorithmName.SHA256);
            byte[] key = pbkdf2.GetBytes(KeySize); // 生成したハッシュ値をキーサイズに合わせて取得

            // ソルトとハッシュ化されたパスワードをBase64エンコードして ":" で連結
            // この連結形式（ソルト:キー）は後で検証時に利用します
            return $"{Convert.ToBase64String(salt)}:{Convert.ToBase64String(key)}";
        }

        // パスワードと保存されたハッシュを比較して、正しいパスワードか検証するメソッド
        public static bool VerifyPassword(string password, byte[] storedBytes)
        {
            // salt と key を分離（先頭16バイトがsalt、残りがkey）
            byte[] salt = storedBytes.Take(SaltSize).ToArray();
            byte[] storedKey = storedBytes.Skip(SaltSize).ToArray();

            // 入力されたパスワードと保存されたソルトを使って新たにキーを生成
            using var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations, HashAlgorithmName.SHA256);
            byte[] key = pbkdf2.GetBytes(KeySize);

            // セキュアにキーが一致するかを比較
            return CryptographicOperations.FixedTimeEquals(key, storedKey);
        }

        // パスワードをPBKDF2でハッシュ化し、ソルトとキーを連結したbyte[]として返すメソッド
        public static byte[] HashPasswordAsBytes(string password)
        {
            using var rng = RandomNumberGenerator.Create();
            byte[] salt = new byte[SaltSize];
            rng.GetBytes(salt);

            using var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations, HashAlgorithmName.SHA256);
            byte[] key = pbkdf2.GetBytes(KeySize);

            return salt.Concat(key).ToArray();
        }
    }
}