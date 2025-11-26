-- Create Users table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
CREATE TABLE Users (
    UserId NVARCHAR(50) PRIMARY KEY,
    Password NVARCHAR(255) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- Create Players table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Players' AND xtype='U')
CREATE TABLE Players (
    PlayerId INT IDENTITY(1,1) PRIMARY KEY,
    UserId NVARCHAR(50) NOT NULL,
    CharId INT DEFAULT 1,
    Level INT DEFAULT 1,
    Experience INT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

-- Create Events table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Events' AND xtype='U')
CREATE TABLE Events (
    EventId INT IDENTITY(1,1) PRIMARY KEY,
    EventName NVARCHAR(100),
    Description NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- Insert sample event data
IF NOT EXISTS (SELECT * FROM Events WHERE EventId = 1)
INSERT INTO Events (EventName, Description) VALUES 
('Welcome Event', 'Welcome to the RPG world!'),
('First Quest', 'Complete your first adventure'),
('Level Up', 'Congratulations on leveling up!');