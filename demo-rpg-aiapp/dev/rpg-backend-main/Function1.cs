using Azure;
using Azure.AI.OpenAI;
using AzureOpenAISample.Security;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using OpenAI.Chat;
using System.Data;
using System.Net;
using System.Text.Encodings.Web;
using System.Text.Json;

namespace AzureOpenAISample
{
    public class Function1
    {
        private readonly ILogger<Function1> _logger;

        public Function1(ILogger<Function1> logger)
        {
            _logger = logger;
        }

        [Function("OpenAI")]
        public async Task<HttpResponseData> OpenAI([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequestData req)
        {
            _logger.LogInformation("OpenAI function processed a request.");

            var endpoint = Environment.GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT");
            var key = Environment.GetEnvironmentVariable("AZURE_OPENAI_KEY");
            
            if (string.IsNullOrEmpty(endpoint))
            {
                var response = req.CreateResponse(HttpStatusCode.BadRequest);
                await response.WriteStringAsync("Please set the AZURE_OPENAI_ENDPOINT environment variable.");
                return response;
            }
            
            if (string.IsNullOrEmpty(key))
            {
                var response = req.CreateResponse(HttpStatusCode.BadRequest);
                await response.WriteStringAsync("Please set the AZURE_OPENAI_KEY environment variable.");
                return response;
            }

            AzureKeyCredential credential = new AzureKeyCredential(key);
            AzureOpenAIClient azureClient = new(new Uri(endpoint), credential);
            ChatClient chatClient = azureClient.GetChatClient("gpt-4o");

            string userMessage = req.Query["message"] ?? "";
            if (string.IsNullOrEmpty(userMessage))
            {
                string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
                dynamic? data = JsonConvert.DeserializeObject(requestBody);
                userMessage = data?.message ?? "";
            }

            var messages = new List<ChatMessage>
            {
                new SystemChatMessage(@"
【目的】
MBTI 風に 4 軸（Charisma/E–I, Intuition/N–S, Logic/T–F, Order/J–P）を **0–100（50基準）**で採点する。
**強い傾向は極端値に寄せる（中間はできるだけ避ける）。**

【スコア方針（大胆化）】

* 高いほど **左側**（E/N/T/P）。低いほど **右側**（I/S/F/J）。
* シグナル強度で目安を固定：

  * **強**：95/5（±45）
  * **中**：80/20（±30）
  * **弱**：65/35（±15）
* **何かしら判定材料があれば 50±5 に収めない**（最低でも 65/35 か 35/65 へ）。
* 複数強シグナルが同方向に重なれば 98/2 まで可（0–100 でクリップ）。
* 矛盾して同程度なら 45–55 に散らす。意味不明は **50 固定**。

【判定ルール（簡潔）】

1. 返答中の語句・行動意図を各軸にマッピング（例）：

   * **Charisma(E–I)**：人に話しかける/リードする/社交的=E、独力/静か/一人で整理=I
   * **Intuition(N–S)**：可能性/概念/将来像=N、事実/手順/具体= S
   * **Logic(T–F)**：根拠/効率/一貫性=T、配慮/関係/感情=F
   * **Order(J–P)**：計画/締切遵守/決める=J、柔軟/即興/様子見=P
2. 強度は言い切り/行動の即時性/具体語の濃さで判定（強・中・弱）。
3. 軸ごとに 50 を起点に強度ぶんだけ ± 加算し、0–100 で丸めて出力。
4. 特殊語「m3h20252q」なら全軸 **10000**。

            【出力形式】

            - 出力は必ず4パラメータとその数値のみをJSON形式で返す  
            - 改行や文字を一切入れず、必ず次の形式を守ること  

            {""Charisma"":,""Intuition"":,""Logic"":,""Order"":}

            - 例（特殊条件「m3h20252q」が含まれる場合）：  
            {""Charisma"":1000,""Intuition"":1000,""Logic"":1000,""Order"":1000}
 
【例（参考・返答→出力）】

* 「今すぐ皆を集めて相談乗る。資料は後で詰める」→ Charisma 95, Intuition 80, Logic 35, Order 70
* 「一人で要件洗い出して計画立てる」→ Charisma 20, Intuition 35, Logic 80, Order 10
            "),
                new UserChatMessage(userMessage)
            };

            var options = new ChatCompletionOptions
            {
                Temperature = 0,
                MaxOutputTokenCount = 6553,
                TopP = 0.95f,
                FrequencyPenalty = 0,
                PresencePenalty = 0
            };

            var jsonOptions = new JsonSerializerOptions
            {
                WriteIndented = true,
                Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
            };

            try
            {
                ChatCompletion completion = await chatClient.CompleteChatAsync(messages, options);
                var okResponse = req.CreateResponse(HttpStatusCode.OK);
                await okResponse.WriteStringAsync(System.Text.Json.JsonSerializer.Serialize(completion, jsonOptions));
                return okResponse;
            }
            catch (Exception ex)
            {
                var errorResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await errorResponse.WriteStringAsync($"An error occurred: {ex.Message}");
                return errorResponse;
            }
        }

        [Function("SELECTPLAYER")]
        public async Task<HttpResponseData> SelectPlayer([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequestData req)
        {
            _logger.LogInformation("プレイヤーデータ取得処理を開始します");

            string userId = req.Query["UserId"] ?? "";
            if (string.IsNullOrEmpty(userId))
            {
                string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
                dynamic? data = JsonConvert.DeserializeObject(requestBody);
                userId = data?.UserId ?? "";
            }

            if (string.IsNullOrEmpty(userId))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync("UserId パラメータが必要です。");
                return badResponse;
            }

            try
            {
                string connectionString = await KeyVault.GetSqlConnectionStringAsync();
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    string sql = @"SELECT UserId, CharId, Exp, Parameter1, Parameter2, Parameter3, Parameter4, CurrentEventId, CurrentSeq
                                   FROM PlayerData WHERE UserId = @UserId";

                    using (SqlCommand command = new SqlCommand(sql, connection))
                    {
                        command.Parameters.AddWithValue("@UserId", userId);
                        connection.Open();
                        using (SqlDataReader reader = command.ExecuteReader())
                        {
                            PlayerDataList resultList = new PlayerDataList();
                            while (reader.Read())
                            {
                                resultList.List.Add(new PlayerDataRow
                                {
                                    UserId = reader.GetString(0),
                                    CharId = reader.GetInt32(1),
                                    Exp = reader.GetInt32(2),
                                    Parameter1 = reader.GetInt32(3),
                                    Parameter2 = reader.GetInt32(4),
                                    Parameter3 = reader.GetInt32(5),
                                    Parameter4 = reader.GetInt32(6),
                                    CurrentEventId = reader.GetInt32(7),
                                    CurrentSeq = reader.GetInt32(8)
                                });
                            }
                            var response = req.CreateResponse(HttpStatusCode.OK);
                            await response.WriteStringAsync(JsonConvert.SerializeObject(resultList));
                            return response;
                        }
                    }
                }
            }
            catch (SqlException e)
            {
                _logger.LogError(e, "PlayerData 取得中にエラーが発生しました。");
                var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
                await errorResponse.WriteStringAsync("PlayerData 取得エラーが発生しました。");
                return errorResponse;
            }
        }

        [Function("SELECTALLPLAYER")]
        public async Task<HttpResponseData> SelectAllPlayer([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequestData req)
        {
            _logger.LogInformation("全プレイヤーデータ取得処理を開始します");

            try
            {
                string connectionString = await KeyVault.GetSqlConnectionStringAsync();
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    string sql = @"SELECT * FROM PlayerData";
                    using (SqlCommand command = new SqlCommand(sql, connection))
                    {
                        connection.Open();
                        using (SqlDataReader reader = command.ExecuteReader())
                        {
                            PlayerDataList resultList = new PlayerDataList();
                            while (reader.Read())
                            {
                                resultList.List.Add(new PlayerDataRow
                                {
                                    UserId = reader.GetString(0),
                                    CharId = reader.GetInt32(1),
                                    Exp = reader.GetInt32(2),
                                    Parameter1 = reader.GetInt32(3),
                                    Parameter2 = reader.GetInt32(4),
                                    Parameter3 = reader.GetInt32(5),
                                    Parameter4 = reader.GetInt32(6),
                                    CurrentEventId = reader.GetInt32(7),
                                    CurrentSeq = reader.GetInt32(8)
                                });
                            }
                            var response = req.CreateResponse(HttpStatusCode.OK);
                            await response.WriteStringAsync(JsonConvert.SerializeObject(resultList));
                            return response;
                        }
                    }
                }
            }
            catch (SqlException e)
            {
                _logger.LogError(e, "PlayerData 取得中にエラーが発生しました。");
                var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
                await errorResponse.WriteStringAsync("PlayerData 取得エラーが発生しました。");
                return errorResponse;
            }
        }

        [Function("SELECTEVENTS")]
        public async Task<HttpResponseData> SelectEvents([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequestData req)
        {
            string eventIdStr = req.Query["eventId"] ?? "";
            if (string.IsNullOrEmpty(eventIdStr))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync("eventId パラメータが必要です。");
                return badResponse;
            }

            int eventId = int.Parse(eventIdStr);

            try
            {
                string connectionString = await KeyVault.GetSqlConnectionStringAsync();
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    string sql = @"SELECT EventId, Seq, Speaker, Text FROM EventTable WHERE EventId = @EventId ORDER BY Seq ASC";
                    using (SqlCommand command = new SqlCommand(sql, connection))
                    {
                        command.Parameters.AddWithValue("@EventId", eventId);
                        connection.Open();
                        using (SqlDataReader reader = command.ExecuteReader())
                        {
                            var resultList = new List<object>();
                            while (reader.Read())
                            {
                                resultList.Add(new
                                {
                                    EventId = reader.GetInt32(reader.GetOrdinal("EventId")),
                                    Seq = reader.GetInt32(reader.GetOrdinal("Seq")),
                                    Speaker = reader.IsDBNull(reader.GetOrdinal("Speaker")) ? "" : reader.GetString(reader.GetOrdinal("Speaker")),
                                    Text = reader.IsDBNull(reader.GetOrdinal("Text")) ? "" : reader.GetString(reader.GetOrdinal("Text"))
                                });
                            }
                            var response = req.CreateResponse(HttpStatusCode.OK);
                            await response.WriteStringAsync(JsonConvert.SerializeObject(new { EventLines = resultList }));
                            return response;
                        }
                    }
                }
            }
            catch (SqlException e)
            {
                _logger.LogError(e, "SQLエラーが発生しました");
                var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
                await errorResponse.WriteStringAsync("SQLエラーが発生しました");
                return errorResponse;
            }
        }

        [Function("UPDATE")]
        public async Task<HttpResponseData> Update([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequestData req)
        {
            _logger.LogInformation("PlayerData 更新処理を開始します");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic? data = JsonConvert.DeserializeObject(requestBody);

            string userId = req.Query["UserId"] ?? data?.UserId ?? "";
            string charId = req.Query["CharId"] ?? data?.CharId ?? "";
            string exp = req.Query["Exp"] ?? data?.Exp ?? "";
            string parameter1 = req.Query["Parameter1"] ?? data?.Parameter1 ?? "";
            string parameter2 = req.Query["Parameter2"] ?? data?.Parameter2 ?? "";
            string parameter3 = req.Query["Parameter3"] ?? data?.Parameter3 ?? "";
            string parameter4 = req.Query["Parameter4"] ?? data?.Parameter4 ?? "";
            string currentEventId = req.Query["CurrentEventId"] ?? data?.CurrentEventId ?? "";
            string currentSeq = req.Query["CurrentSeq"] ?? data?.CurrentSeq ?? "";

            if (string.IsNullOrWhiteSpace(userId))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync("UserId が設定されていません。");
                return badResponse;
            }

            try
            {
                string connectionString = await KeyVault.GetSqlConnectionStringAsync();
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    string sql = @"
                        UPDATE PlayerData
                        SET 
                          CharId = ISNULL(@CharId, CharId),
                          Exp = ISNULL(@Exp, Exp),
                          Parameter1 = ISNULL(@Parameter1, Parameter1),
                          Parameter2 = ISNULL(@Parameter2, Parameter2),
                          Parameter3 = ISNULL(@Parameter3, Parameter3),
                          Parameter4 = ISNULL(@Parameter4, Parameter4),
                          CurrentEventId = ISNULL(@CurrentEventId, CurrentEventId),
                          CurrentSeq = ISNULL(@CurrentSeq, CurrentSeq)
                        WHERE UserId = @UserId";

                    using (SqlCommand command = new SqlCommand(sql, connection))
                    {
                        command.Parameters.AddWithValue("@UserId", userId);
                        command.Parameters.AddWithValue("@CharId", string.IsNullOrWhiteSpace(charId) ? (object)DBNull.Value : int.Parse(charId));
                        command.Parameters.AddWithValue("@Exp", string.IsNullOrWhiteSpace(exp) ? (object)DBNull.Value : int.Parse(exp));
                        command.Parameters.AddWithValue("@Parameter1", string.IsNullOrWhiteSpace(parameter1) ? (object)DBNull.Value : int.Parse(parameter1));
                        command.Parameters.AddWithValue("@Parameter2", string.IsNullOrWhiteSpace(parameter2) ? (object)DBNull.Value : int.Parse(parameter2));
                        command.Parameters.AddWithValue("@Parameter3", string.IsNullOrWhiteSpace(parameter3) ? (object)DBNull.Value : int.Parse(parameter3));
                        command.Parameters.AddWithValue("@Parameter4", string.IsNullOrWhiteSpace(parameter4) ? (object)DBNull.Value : int.Parse(parameter4));
                        command.Parameters.AddWithValue("@CurrentEventId", string.IsNullOrWhiteSpace(currentEventId) ? (object)DBNull.Value : int.Parse(currentEventId));
                        command.Parameters.AddWithValue("@CurrentSeq", string.IsNullOrWhiteSpace(currentSeq) ? (object)DBNull.Value : int.Parse(currentSeq));

                        connection.Open();
                        int result = command.ExecuteNonQuery();

                        JObject jsonObj = new JObject { ["result"] = $"{result}件のプレイヤーデータを更新しました。" };
                        var response = req.CreateResponse(HttpStatusCode.OK);
                        await response.WriteStringAsync(JsonConvert.SerializeObject(jsonObj, Formatting.None));
                        return response;
                    }
                }
            }
            catch (SqlException e)
            {
                _logger.LogError(e, "PlayerData 更新中にエラーが発生しました。");
                var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
                await errorResponse.WriteStringAsync("PlayerData 更新エラーが発生しました。");
                return errorResponse;
            }
        }

        [Function("INSERTUSER")]
        public async Task<HttpResponseData> InsertUser([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequestData req)
        {
            _logger.LogInformation("ユーザー登録処理を開始します");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic? data = JsonConvert.DeserializeObject(requestBody);

            string id = data?.ID ?? "";
            string password = data?.Password ?? "";
            string name = data?.Name ?? "";

            if (string.IsNullOrWhiteSpace(id) || string.IsNullOrWhiteSpace(password) || string.IsNullOrWhiteSpace(name))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync("ID、パスワード、または表示名が設定されていません。");
                return badResponse;
            }

            try
            {
                byte[] hashedPassword = PBKDF2Hash.HashPasswordAsBytes(password);
                string connectionString = await KeyVault.GetSqlConnectionStringAsync();

                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    string sql = "INSERT INTO Users (UserId, PasswordHash, UserName) VALUES (@UserId, @PasswordHash, @UserName)";
                    using (SqlCommand command = new SqlCommand(sql, connection))
                    {
                        command.Parameters.AddWithValue("@UserId", id);
                        command.Parameters.Add("@PasswordHash", SqlDbType.VarBinary, 256).Value = hashedPassword;
                        command.Parameters.AddWithValue("@UserName", name);

                        connection.Open();
                        int result = command.ExecuteNonQuery();
                        
                        var response = req.CreateResponse(HttpStatusCode.OK);
                        await response.WriteStringAsync($"登録結果:{result}件のユーザー情報を登録しました。");
                        return response;
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ユーザー登録中にエラーが発生しました。");
                var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
                await errorResponse.WriteStringAsync("内部エラーが発生しました。");
                return errorResponse;
            }
        }

        [Function("INSERTPLAYER")]
        public async Task<HttpResponseData> InsertPlayer([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequestData req)
        {
            _logger.LogInformation("プレイヤーデータ登録処理を開始します");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic? data = JsonConvert.DeserializeObject(requestBody);

            string userId = data?.UserId ?? "";

            if (string.IsNullOrWhiteSpace(userId))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync("UserId が設定されていません。");
                return badResponse;
            }

            try
            {
                string connectionString = await KeyVault.GetSqlConnectionStringAsync();
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    string sql = @"INSERT INTO PlayerData (UserId) VALUES (@UserId)";

                    using (SqlCommand command = new SqlCommand(sql, connection))
                    {
                        command.Parameters.AddWithValue("@UserId", userId);
                        connection.Open();
                        int result = command.ExecuteNonQuery();

                        JObject jsonObj = new JObject { ["result"] = $"{result}件のプレイヤーデータを登録しました。" };
                        var response = req.CreateResponse(HttpStatusCode.OK);
                        await response.WriteStringAsync(JsonConvert.SerializeObject(jsonObj, Formatting.None));
                        return response;
                    }
                }
            }
            catch (SqlException e)
            {
                _logger.LogError(e, "PlayerData 登録中にエラーが発生しました。");
                var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
                await errorResponse.WriteStringAsync("PlayerData 登録エラーが発生しました。");
                return errorResponse;
            }
        }

        [Function("LOGIN")]
        public async Task<HttpResponseData> Login([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequestData req)
        {
            _logger.LogInformation("ログイン認証処理を開始します");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic? data = JsonConvert.DeserializeObject(requestBody);

            string id = data?.ID ?? "";
            string password = data?.Password ?? "";

            if (string.IsNullOrWhiteSpace(id) || string.IsNullOrWhiteSpace(password))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync("IDまたはパスワードが未入力です。");
                return badResponse;
            }

            try
            {
                string connectionString = await KeyVault.GetSqlConnectionStringAsync();

                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    string sqlUser = "SELECT PasswordHash, UserName FROM Users WHERE UserId = @UserId";
                    using (SqlCommand command = new SqlCommand(sqlUser, connection))
                    {
                        command.Parameters.AddWithValue("@UserId", id);
                        connection.Open();
                        using (SqlDataReader reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                byte[]? storedHash = reader.IsDBNull(0) ? null : reader.GetSqlBinary(0).Value;
                                string userName = reader.IsDBNull(1) ? "Unknown" : reader.GetString(1);

                                if (storedHash != null && PBKDF2Hash.VerifyPassword(password, storedHash))
                                {
                                    reader.Close();

                                    string sqlPlayer = @"SELECT CharId, Exp, Parameter1, Parameter2, Parameter3, Parameter4, CurrentEventId, CurrentSeq 
                                                         FROM PlayerData WHERE UserId = @UserId";
                                    using (SqlCommand cmdPlayer = new SqlCommand(sqlPlayer, connection))
                                    {
                                        cmdPlayer.Parameters.AddWithValue("@UserId", id);
                                        using (SqlDataReader pr = cmdPlayer.ExecuteReader())
                                        {
                                            var response = req.CreateResponse(HttpStatusCode.OK);
                                            if (pr.Read())
                                            {
                                                await response.WriteAsJsonAsync(new
                                                {
                                                    Result = "Succeeded",
                                                    Message = "認証に成功しました",
                                                    UserId = id,
                                                    UserName = userName,
                                                    CharId = pr.GetInt32(0),
                                                    Exp = pr.GetInt32(1),
                                                    Parameter1 = pr.GetInt32(2),
                                                    Parameter2 = pr.GetInt32(3),
                                                    Parameter3 = pr.GetInt32(4),
                                                    Parameter4 = pr.GetInt32(5),
                                                    CurrentEventId = pr.GetInt32(6),
                                                    CurrentSeq = pr.GetInt32(7)
                                                });
                                            }
                                            else
                                            {
                                                await response.WriteAsJsonAsync(new
                                                {
                                                    Result = "Succeeded",
                                                    Message = "認証に成功しました（プレイヤーデータ未登録）",
                                                    UserId = id,
                                                    UserName = userName
                                                });
                                            }
                                            return response;
                                        }
                                    }
                                }
                                else
                                {
                                    var unauthorizedResponse = req.CreateResponse(HttpStatusCode.Unauthorized);
                                    await unauthorizedResponse.WriteAsJsonAsync(new
                                    {
                                        Result = "Failed",
                                        Message = "認証失敗（IDまたはパスワードが一致しません）"
                                    });
                                    return unauthorizedResponse;
                                }
                            }
                            else
                            {
                                var unauthorizedResponse = req.CreateResponse(HttpStatusCode.Unauthorized);
                                await unauthorizedResponse.WriteStringAsync("認証失敗（ユーザーIDが存在しません）");
                                return unauthorizedResponse;
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ログイン認証中にエラーが発生しました。");
                var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
                await errorResponse.WriteStringAsync("LOGIN内部エラーが発生しました。");
                return errorResponse;
            }
        }
    }
}
