"""Azure Functions app for RPG Gaming Backend."""
import os
import json
import logging
from typing import Dict, List, Any, Optional
import azure.functions as func
from openai import AzureOpenAI
import pyodbc
from keyvault_helper import get_sql_connection_string
from password_helper import hash_password, verify_password

# Constants
DEFAULT_CHAR_ID = 1
DEFAULT_EXP = 0
DEFAULT_PARAMETER_VALUE = 50
DEFAULT_EVENT_ID = 1
DEFAULT_EVENT_SEQ = 1
MIN_PARAMETER_VALUE = 0
MAX_PARAMETER_VALUE = 100

app = func.FunctionApp()


def row_to_player_dict(row) -> Dict[str, Any]:
    """Convert database row to player dictionary."""
    return {
        "UserId": row[0],
        "CharId": row[1],
        "Exp": row[2],
        "Parameter1": row[3],
        "Parameter2": row[4],
        "Parameter3": row[5],
        "Parameter4": row[6],
        "CurrentEventId": row[7],
        "CurrentSeq": row[8]
    }


def row_to_event_dict(row) -> Dict[str, Any]:
    """Convert database row to event dictionary."""
    return {
        "EventId": row[0],
        "Seq": row[1],
        "EventType": row[2],
        "EventText": row[3]
    }


def validate_parameter_value(value: Any, param_name: str) -> Optional[str]:
    """Validate parameter value is within acceptable range."""
    if value is None:
        return None
    try:
        int_value = int(value)
        if int_value < MIN_PARAMETER_VALUE or int_value > MAX_PARAMETER_VALUE:
            return f"{param_name} must be between {MIN_PARAMETER_VALUE} and {MAX_PARAMETER_VALUE}"
    except (ValueError, TypeError):
        return f"{param_name} must be a valid number"
    return None


@app.route(route="OpenAI", methods=["GET", "POST"], auth_level=func.AuthLevel.ANONYMOUS)
def openai_function(req: func.HttpRequest) -> func.HttpResponse:
    """MBTI personality scoring using Azure OpenAI GPT-4."""
    logging.info("OpenAI function processed a request.")
    
    endpoint = os.environ.get("AZURE_OPENAI_ENDPOINT")
    api_key = os.environ.get("AZURE_OPENAI_KEY")
    deployment = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4o")
    
    if not endpoint:
        return func.HttpResponse(
            "Please set the AZURE_OPENAI_ENDPOINT environment variable.",
            status_code=400
        )
    
    if not api_key:
        return func.HttpResponse(
            "Please set the AZURE_OPENAI_KEY environment variable.",
            status_code=400
        )
    
    # Get user message from query or body
    user_message = req.params.get("message")
    if not user_message:
        try:
            req_body = req.get_json()
            user_message = req_body.get("message", "")
        except ValueError:
            user_message = ""
    
    if not user_message:
        return func.HttpResponse(
            "Please provide a 'message' parameter.",
            status_code=400
        )
    
    system_prompt = """
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

{"Charisma":,"Intuition":,"Logic":,"Order":}

- 例（特殊条件「m3h20252q」が含まれる場合）：  
{"Charisma":1000,"Intuition":1000,"Logic":1000,"Order":1000}

【例（参考・返答→出力）】

* 「今すぐ皆を集めて相談乗る。資料は後で詰める」→ Charisma 95, Intuition 80, Logic 35, Order 70
* 「一人で要件洗い出して計画立てる」→ Charisma 20, Intuition 35, Logic 80, Order 10
"""
    
    try:
        client = AzureOpenAI(
            azure_endpoint=endpoint,
            api_key=api_key,
            api_version="2024-02-01"
        )
        
        response = client.chat.completions.create(
            model=deployment,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message}
            ],
            temperature=0,
            max_tokens=6553,
            top_p=0.95,
            frequency_penalty=0,
            presence_penalty=0
        )
        
        return func.HttpResponse(
            json.dumps(response.model_dump(), indent=2, ensure_ascii=False),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"Error in OpenAI function: {str(e)}")
        return func.HttpResponse(
            "An error occurred while processing your request.",
            status_code=500
        )


@app.route(route="SELECTPLAYER", methods=["GET", "POST"], auth_level=func.AuthLevel.ANONYMOUS)
def select_player(req: func.HttpRequest) -> func.HttpResponse:
    """Get player data by UserId."""
    logging.info("プレイヤーデータ取得処理を開始します")
    
    user_id = req.params.get("UserId")
    if not user_id:
        try:
            req_body = req.get_json()
            user_id = req_body.get("UserId", "")
        except ValueError:
            user_id = ""
    
    if not user_id:
        return func.HttpResponse(
            "UserId パラメータが必要です。",
            status_code=400
        )
    
    conn = None
    try:
        connection_string = get_sql_connection_string()
        conn = pyodbc.connect(connection_string)
        
        with conn.cursor() as cursor:
            sql = """
                SELECT UserId, CharId, Exp, Parameter1, Parameter2, Parameter3, Parameter4, 
                       CurrentEventId, CurrentSeq
                FROM PlayerData 
                WHERE UserId = ?
            """
            
            cursor.execute(sql, user_id)
            rows = cursor.fetchall()
            
            result_list = [row_to_player_dict(row) for row in rows]
        
        return func.HttpResponse(
            json.dumps({"List": result_list}, ensure_ascii=False),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"PlayerData 取得中にエラーが発生しました: {str(e)}")
        return func.HttpResponse(
            "PlayerData 取得エラーが発生しました。",
            status_code=500
        )
    finally:
        if conn:
            conn.close()


@app.route(route="SELECTALLPLAYER", methods=["GET", "POST"], auth_level=func.AuthLevel.ANONYMOUS)
def select_all_player(req: func.HttpRequest) -> func.HttpResponse:
    """Get all player data."""
    logging.info("全プレイヤーデータ取得処理を開始します")
    
    conn = None
    try:
        connection_string = get_sql_connection_string()
        conn = pyodbc.connect(connection_string)
        
        with conn.cursor() as cursor:
            sql = """
                SELECT UserId, CharId, Exp, Parameter1, Parameter2, Parameter3, Parameter4,
                       CurrentEventId, CurrentSeq
                FROM PlayerData
            """
            
            cursor.execute(sql)
            rows = cursor.fetchall()
            
            result_list = [row_to_player_dict(row) for row in rows]
        
        return func.HttpResponse(
            json.dumps({"List": result_list}, ensure_ascii=False),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"全プレイヤーデータ取得中にエラーが発生しました: {str(e)}")
        return func.HttpResponse(
            "全プレイヤーデータ取得エラーが発生しました。",
            status_code=500
        )
    finally:
        if conn:
            conn.close()


@app.route(route="SELECTEVENTS", methods=["GET", "POST"], auth_level=func.AuthLevel.ANONYMOUS)
def select_events(req: func.HttpRequest) -> func.HttpResponse:
    """Get event data."""
    logging.info("イベントデータ取得処理を開始します")
    
    conn = None
    try:
        connection_string = get_sql_connection_string()
        conn = pyodbc.connect(connection_string)
        
        with conn.cursor() as cursor:
            sql = "SELECT EventId, Seq, EventType, EventText FROM EventData"
            
            cursor.execute(sql)
            rows = cursor.fetchall()
            
            result_list = [row_to_event_dict(row) for row in rows]
        
        return func.HttpResponse(
            json.dumps({"List": result_list}, ensure_ascii=False),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"イベントデータ取得中にエラーが発生しました: {str(e)}")
        return func.HttpResponse(
            "イベントデータ取得エラーが発生しました。",
            status_code=500
        )
    finally:
        if conn:
            conn.close()


@app.route(route="UPDATE", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
def update_player(req: func.HttpRequest) -> func.HttpResponse:
    """Update player data."""
    logging.info("プレイヤーデータ更新処理を開始します")
    
    try:
        req_body = req.get_json()
    except ValueError:
        return func.HttpResponse(
            "Invalid JSON in request body.",
            status_code=400
        )
    
    user_id = req_body.get("UserId")
    char_id = req_body.get("CharId")
    exp = req_body.get("Exp")
    param1 = req_body.get("Parameter1")
    param2 = req_body.get("Parameter2")
    param3 = req_body.get("Parameter3")
    param4 = req_body.get("Parameter4")
    current_event_id = req_body.get("CurrentEventId")
    current_seq = req_body.get("CurrentSeq")
    
    if not user_id or char_id is None:
        return func.HttpResponse(
            "UserId と CharId は必須です。",
            status_code=400
        )
    
    # Validate parameter values
    for value, name in [(param1, "Parameter1"), (param2, "Parameter2"), 
                         (param3, "Parameter3"), (param4, "Parameter4")]:
        error = validate_parameter_value(value, name)
        if error:
            return func.HttpResponse(error, status_code=400)
    
    conn = None
    try:
        connection_string = get_sql_connection_string()
        conn = pyodbc.connect(connection_string)
        
        with conn.cursor() as cursor:
            sql = """
                UPDATE PlayerData 
                SET Exp = ?, Parameter1 = ?, Parameter2 = ?, Parameter3 = ?, Parameter4 = ?,
                    CurrentEventId = ?, CurrentSeq = ?
                WHERE UserId = ? AND CharId = ?
            """
            
            cursor.execute(sql, exp, param1, param2, param3, param4, 
                          current_event_id, current_seq, user_id, char_id)
            conn.commit()
            
            affected_rows = cursor.rowcount
        
        return func.HttpResponse(
            f"更新されたレコード数: {affected_rows}",
            status_code=200
        )
    except Exception as e:
        logging.error(f"プレイヤーデータ更新中にエラーが発生しました: {str(e)}")
        return func.HttpResponse(
            "プレイヤーデータ更新エラーが発生しました。",
            status_code=500
        )
    finally:
        if conn:
            conn.close()


@app.route(route="INSERTUSER", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
def insert_user(req: func.HttpRequest) -> func.HttpResponse:
    """Register a new user with hashed password."""
    logging.info("ユーザー登録処理を開始します")
    
    try:
        req_body = req.get_json()
    except ValueError:
        return func.HttpResponse(
            "Invalid JSON in request body.",
            status_code=400
        )
    
    user_id = req_body.get("UserId")
    password = req_body.get("Password")
    
    if not user_id or not password:
        return func.HttpResponse(
            "UserId と Password は必須です。",
            status_code=400
        )
    
    # Validate password length
    if len(password) < 8:
        return func.HttpResponse(
            "Password は8文字以上である必要があります。",
            status_code=400
        )
    
    conn = None
    try:
        # Hash password using PBKDF2
        hashed_password = hash_password(password)
        
        connection_string = get_sql_connection_string()
        conn = pyodbc.connect(connection_string)
        
        with conn.cursor() as cursor:
            sql = "INSERT INTO UserData (UserId, Password) VALUES (?, ?)"
            
            cursor.execute(sql, user_id, hashed_password)
            conn.commit()
        
        return func.HttpResponse(
            "ユーザー登録が完了しました。",
            status_code=200
        )
    except pyodbc.IntegrityError:
        return func.HttpResponse(
            "このUserIdは既に登録されています。",
            status_code=409
        )
    except Exception as e:
        logging.error(f"ユーザー登録中にエラーが発生しました: {str(e)}")
        return func.HttpResponse(
            "ユーザー登録エラーが発生しました。",
            status_code=500
        )
    finally:
        if conn:
            conn.close()


@app.route(route="INSERTPLAYER", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
def insert_player(req: func.HttpRequest) -> func.HttpResponse:
    """Initialize player data."""
    logging.info("プレイヤーデータ初期化処理を開始します")
    
    try:
        req_body = req.get_json()
    except ValueError:
        return func.HttpResponse(
            "Invalid JSON in request body.",
            status_code=400
        )
    
    user_id = req_body.get("UserId")
    char_id = req_body.get("CharId", DEFAULT_CHAR_ID)
    
    if not user_id:
        return func.HttpResponse(
            "UserId は必須です。",
            status_code=400
        )
    
    conn = None
    try:
        connection_string = get_sql_connection_string()
        conn = pyodbc.connect(connection_string)
        
        with conn.cursor() as cursor:
            sql = """
                INSERT INTO PlayerData 
                (UserId, CharId, Exp, Parameter1, Parameter2, Parameter3, Parameter4, 
                 CurrentEventId, CurrentSeq)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            cursor.execute(sql, user_id, char_id, DEFAULT_EXP, 
                          DEFAULT_PARAMETER_VALUE, DEFAULT_PARAMETER_VALUE,
                          DEFAULT_PARAMETER_VALUE, DEFAULT_PARAMETER_VALUE,
                          DEFAULT_EVENT_ID, DEFAULT_EVENT_SEQ)
            conn.commit()
        
        return func.HttpResponse(
            "プレイヤーデータの初期化が完了しました。",
            status_code=200
        )
    except Exception as e:
        logging.error(f"プレイヤーデータ初期化中にエラーが発生しました: {str(e)}")
        return func.HttpResponse(
            "プレイヤーデータ初期化エラーが発生しました。",
            status_code=500
        )
    finally:
        if conn:
            conn.close()


@app.route(route="LOGIN", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
def login(req: func.HttpRequest) -> func.HttpResponse:
    """Authenticate user with password verification."""
    logging.info("ログイン処理を開始します")
    
    try:
        req_body = req.get_json()
    except ValueError:
        return func.HttpResponse(
            "Invalid JSON in request body.",
            status_code=400
        )
    
    user_id = req_body.get("UserId")
    password = req_body.get("Password")
    
    if not user_id or not password:
        return func.HttpResponse(
            "UserId と Password は必須です。",
            status_code=400
        )
    
    conn = None
    try:
        connection_string = get_sql_connection_string()
        conn = pyodbc.connect(connection_string)
        
        with conn.cursor() as cursor:
            sql = "SELECT Password FROM UserData WHERE UserId = ?"
            
            cursor.execute(sql, user_id)
            row = cursor.fetchone()
        
        if not row:
            return func.HttpResponse(
                "ユーザーIDまたはパスワードが正しくありません。",
                status_code=401
            )
        
        stored_hash = row[0]
        
        # Verify password using PBKDF2
        if verify_password(password, stored_hash):
            return func.HttpResponse(
                json.dumps({"result": "success", "UserId": user_id}),
                mimetype="application/json",
                status_code=200
            )
        else:
            return func.HttpResponse(
                "ユーザーIDまたはパスワードが正しくありません。",
                status_code=401
            )
    except Exception as e:
        logging.error(f"ログイン処理中にエラーが発生しました: {str(e)}")
        return func.HttpResponse(
            "ログイン処理エラーが発生しました。",
            status_code=500
        )
    finally:
        if conn:
            conn.close()
