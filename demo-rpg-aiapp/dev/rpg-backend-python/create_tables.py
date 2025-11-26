"""Create database tables if they don't exist."""
import pymssql
import logging
from keyvault_helper import get_sql_connection_string

def get_db_connection():
    """Get database connection using pymssql."""
    connection_string = get_sql_connection_string()
    params = {'port': 1433, 'tds_version': '7.4'}
    for part in connection_string.split(';'):
        if '=' in part:
            key, value = part.split('=', 1)
            key = key.strip()
            if key == 'Server':
                server_part = value.replace('tcp:', '').strip()
                if ',' in server_part:
                    server, port = server_part.split(',')
                    params['server'] = server
                    params['port'] = int(port)
                else:
                    params['server'] = server_part
            elif key == 'Database':
                params['database'] = value
            elif key == 'Uid':
                params['user'] = value
            elif key == 'Pwd':
                params['password'] = value
    return pymssql.connect(**params)

def create_tables():
    """Create required database tables."""
    try:
        conn = get_db_connection()
        
        with conn.cursor() as cursor:
            # Create UserData table
            cursor.execute("""
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='UserData' AND xtype='U')
            CREATE TABLE UserData (
                UserId NVARCHAR(50) PRIMARY KEY,
                Password NVARCHAR(255) NOT NULL,
                CreatedAt DATETIME2 DEFAULT GETDATE()
            )
            """)
            
            # Create PlayerData table
            cursor.execute("""
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='PlayerData' AND xtype='U')
            CREATE TABLE PlayerData (
                UserId NVARCHAR(50) NOT NULL,
                CharId INT NOT NULL,
                Exp INT DEFAULT 0,
                Parameter1 INT DEFAULT 50,
                Parameter2 INT DEFAULT 50,
                Parameter3 INT DEFAULT 50,
                Parameter4 INT DEFAULT 50,
                CurrentEventId INT DEFAULT 1,
                CurrentSeq INT DEFAULT 1,
                CreatedAt DATETIME2 DEFAULT GETDATE(),
                PRIMARY KEY (UserId, CharId),
                FOREIGN KEY (UserId) REFERENCES UserData(UserId)
            )
            """)
            
            # Create EventData table
            cursor.execute("""
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='EventData' AND xtype='U')
            CREATE TABLE EventData (
                EventId INT NOT NULL,
                Seq INT NOT NULL,
                EventType NVARCHAR(50),
                EventText NVARCHAR(1000),
                PRIMARY KEY (EventId, Seq)
            )
            """)
            
            # Insert sample event data
            cursor.execute("""
            IF NOT EXISTS (SELECT * FROM EventData WHERE EventId = 1 AND Seq = 1)
            INSERT INTO EventData (EventId, Seq, EventType, EventText) VALUES 
            (1, 1, 'welcome', 'Welcome to the RPG world!'),
            (1, 2, 'quest', 'Your first adventure begins...'),
            (2, 1, 'battle', 'A wild monster appears!')
            """)
            
            conn.commit()
            logging.info("Database tables created successfully")
            return True
            
    except Exception as e:
        logging.error(f"Error creating tables: {str(e)}")
        return False
    finally:
        if 'conn' in locals():
            conn.close()