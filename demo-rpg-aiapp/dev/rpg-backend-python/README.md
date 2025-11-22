# RPG Gaming App - Python Backend

Python Azure Functions backend migrated from C#. This backend provides 8 API endpoints for the RPG gaming application.

## Features

- **OpenAI Integration**: MBTI personality scoring using Azure OpenAI GPT-4
- **Player Management**: CRUD operations for player data
- **Event System**: Game event data management
- **User Authentication**: Secure user registration and login with PBKDF2 password hashing
- **Azure Key Vault**: Secure storage and retrieval of SQL connection strings

## API Endpoints

### 1. OpenAI - MBTI Personality Scoring
- **Route**: `/api/OpenAI`
- **Methods**: GET, POST
- **Parameters**: `message` (user input text)
- **Returns**: JSON with Charisma, Intuition, Logic, Order scores (0-100)

### 2. SELECTPLAYER - Get Player Data
- **Route**: `/api/SELECTPLAYER`
- **Methods**: GET, POST
- **Parameters**: `UserId`
- **Returns**: Player data including exp, parameters, current event

### 3. SELECTALLPLAYER - Get All Players
- **Route**: `/api/SELECTALLPLAYER`
- **Methods**: GET, POST
- **Returns**: List of all player data

### 4. SELECTEVENTS - Get Event Data
- **Route**: `/api/SELECTEVENTS`
- **Methods**: GET, POST
- **Returns**: List of all game events

### 5. UPDATE - Update Player Data
- **Route**: `/api/UPDATE`
- **Methods**: POST
- **Body**: JSON with UserId, CharId, Exp, Parameters, CurrentEventId, CurrentSeq
- **Returns**: Number of updated records

### 6. INSERTUSER - Register New User
- **Route**: `/api/INSERTUSER`
- **Methods**: POST
- **Body**: JSON with UserId, Password
- **Returns**: Success message
- **Security**: Password is hashed using PBKDF2-SHA256

### 7. INSERTPLAYER - Initialize Player Data
- **Route**: `/api/INSERTPLAYER`
- **Methods**: POST
- **Body**: JSON with UserId, CharId (optional)
- **Returns**: Success message
- **Defaults**: Exp=0, All Parameters=50, CurrentEventId=1, CurrentSeq=1

### 8. LOGIN - User Authentication
- **Route**: `/api/LOGIN`
- **Methods**: POST
- **Body**: JSON with UserId, Password
- **Returns**: JSON with result and UserId on success
- **Security**: Password verification using PBKDF2-SHA256

## Environment Variables

All secrets must be configured via environment variables (local development) or GitHub Secrets (deployment):

```bash
AZURE_OPENAI_ENDPOINT=https://your-openai-resource.openai.azure.com/
AZURE_OPENAI_KEY=your-api-key
AZURE_OPENAI_DEPLOYMENT=gpt-4o
KEYVAULT_URL=https://your-keyvault.vault.azure.net/
```

## Local Development

1. **Install Python 3.9+**:
   ```bash
   python --version  # Should be 3.9 or higher
   ```

2. **Create virtual environment**:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Install Azure Functions Core Tools**:
   ```bash
   # macOS
   brew tap azure/functions
   brew install azure-functions-core-tools@4

   # Windows
   npm install -g azure-functions-core-tools@4
   ```

5. **Configure local settings**:
   Copy `local.settings.json.example` to `local.settings.json` and fill in your values:
   ```bash
   cp local.settings.json.example local.settings.json
   # Edit local.settings.json with your actual values
   ```

6. **Run locally**:
   ```bash
   func start
   ```

   The API will be available at `http://localhost:7071/api/`

## Testing Endpoints

### Test OpenAI Endpoint
```bash
curl "http://localhost:7071/api/OpenAI?message=今すぐ皆を集めて相談乗る"
```

### Test Player Selection
```bash
curl "http://localhost:7071/api/SELECTPLAYER?UserId=testuser123"
```

### Test User Registration
```bash
curl -X POST http://localhost:7071/api/INSERTUSER \
  -H "Content-Type: application/json" \
  -d '{"UserId":"newuser","Password":"securepass123"}'
```

### Test Login
```bash
curl -X POST http://localhost:7071/api/LOGIN \
  -H "Content-Type: application/json" \
  -d '{"UserId":"newuser","Password":"securepass123"}'
```

## Deployment

### Deploy to Azure

1. **Using Azure Functions Core Tools**:
   ```bash
   func azure functionapp publish <your-function-app-name>
   ```

2. **Using GitHub Actions**:
   - Push to `main` or `dev` branch
   - GitHub Actions workflow will automatically deploy
   - Ensure GitHub Secrets are configured (see `../../GITHUB-SECRETS.md`)

### Configure Azure Function App Settings

After deployment, set environment variables in Azure:

```bash
az functionapp config appsettings set \
  --name <your-function-app-name> \
  --resource-group <your-resource-group> \
  --settings \
    AZURE_OPENAI_ENDPOINT=<your-endpoint> \
    AZURE_OPENAI_KEY=<your-key> \
    AZURE_OPENAI_DEPLOYMENT=gpt-4o \
    KEYVAULT_URL=<your-keyvault-url>
```

## Database Schema

### UserData Table
```sql
CREATE TABLE UserData (
    UserId NVARCHAR(100) PRIMARY KEY,
    Password NVARCHAR(255) NOT NULL  -- PBKDF2-SHA256 hashed
);
```

### PlayerData Table
```sql
CREATE TABLE PlayerData (
    UserId NVARCHAR(100),
    CharId INT,
    Exp INT,
    Parameter1 INT,  -- Charisma
    Parameter2 INT,  -- Intuition
    Parameter3 INT,  -- Logic
    Parameter4 INT,  -- Order
    CurrentEventId INT,
    CurrentSeq INT,
    PRIMARY KEY (UserId, CharId),
    FOREIGN KEY (UserId) REFERENCES UserData(UserId)
);
```

### EventData Table
```sql
CREATE TABLE EventData (
    EventId INT,
    Seq INT,
    EventType NVARCHAR(50),
    EventText NVARCHAR(MAX),
    PRIMARY KEY (EventId, Seq)
);
```

## Dependencies

- **azure-functions**: Azure Functions SDK for Python
- **azure-identity**: Azure Active Directory authentication
- **azure-keyvault-secrets**: Azure Key Vault secrets management
- **openai**: Azure OpenAI SDK
- **pyodbc**: SQL Server database connectivity
- **passlib**: Password hashing with PBKDF2

## Security Features

1. **Password Hashing**: PBKDF2-SHA256 with salt
2. **Key Vault Integration**: SQL connection strings stored securely
3. **Managed Identity**: No credentials in code
4. **Environment Variables**: All secrets via configuration
5. **GitHub Secrets**: Secure CI/CD deployment

## Differences from C# Version

### Advantages of Python Version:
- ✅ **Simpler syntax**: More readable and maintainable
- ✅ **Async support**: Native async/await for better performance
- ✅ **Smaller footprint**: Faster cold starts (~$0/month vs $200/month)
- ✅ **Popular AI libraries**: Better integration with ML/AI ecosystem
- ✅ **Cost effective**: Flex Consumption Plan significantly cheaper

### Key Changes:
- **Async functions**: All database operations are async
- **pyodbc**: Uses parameterized queries with `?` instead of `@param`
- **Logging**: Uses Python logging module
- **JSON handling**: Native Python `json` module
- **Error handling**: Pythonic try/except patterns

## Troubleshooting

### Import Errors (Development)
The lint errors about missing imports are expected during development. Run:
```bash
pip install -r requirements.txt
```

### Database Connection Issues
1. Check KEYVAULT_URL is set correctly
2. Verify Managed Identity has Key Vault access
3. Ensure SQL connection string in Key Vault is valid

### Azure OpenAI Errors
1. Verify AZURE_OPENAI_ENDPOINT format: `https://xxx.openai.azure.com/`
2. Check AZURE_OPENAI_KEY is valid
3. Ensure deployment name matches: `gpt-4o`

### Password Hashing Issues
- Passwords are hashed with PBKDF2-SHA256
- Do NOT try to migrate existing C# hashed passwords directly
- Users will need to re-register or implement password migration strategy

## License

MIT License - See parent directory for details

## Support

For issues and questions:
- GitHub Issues: https://github.com/vanehru/terraform-modules/issues
- Documentation: See `../../GITHUB-SECRETS.md` for deployment guide
