#!/usr/bin/env python3
import pyodbc
import sys

# Connection string
conn_str = "Server=tcp:rpg-sql-l0svei.database.windows.net,1433;Initial Catalog=rpg-gaming-db;Persist Security Info=False;User ID=sqladmin;Password=(eViaICwzce-__+T;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

try:
    # Connect to database
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    # Create Users table
    cursor.execute("""
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
    CREATE TABLE Users (
        UserId NVARCHAR(50) PRIMARY KEY,
        Password NVARCHAR(255) NOT NULL,
        CreatedAt DATETIME2 DEFAULT GETDATE()
    )
    """)
    
    # Create Players table
    cursor.execute("""
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Players' AND xtype='U')
    CREATE TABLE Players (
        PlayerId INT IDENTITY(1,1) PRIMARY KEY,
        UserId NVARCHAR(50) NOT NULL,
        CharId INT DEFAULT 1,
        Level INT DEFAULT 1,
        Experience INT DEFAULT 0,
        CreatedAt DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (UserId) REFERENCES Users(UserId)
    )
    """)
    
    # Create Events table
    cursor.execute("""
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Events' AND xtype='U')
    CREATE TABLE Events (
        EventId INT IDENTITY(1,1) PRIMARY KEY,
        EventName NVARCHAR(100),
        Description NVARCHAR(500),
        CreatedAt DATETIME2 DEFAULT GETDATE()
    )
    """)
    
    # Insert sample events
    cursor.execute("""
    IF NOT EXISTS (SELECT * FROM Events WHERE EventId = 1)
    INSERT INTO Events (EventName, Description) VALUES 
    ('Welcome Event', 'Welcome to the RPG world!'),
    ('First Quest', 'Complete your first adventure'),
    ('Level Up', 'Congratulations on leveling up!')
    """)
    
    conn.commit()
    print("✅ Database tables created successfully!")
    
except Exception as e:
    print(f"❌ Error: {e}")
finally:
    if 'conn' in locals():
        conn.close()