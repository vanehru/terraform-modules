-- Create Users table (matching C# Function1.cs schema)
CREATE TABLE Users (
    UserId NVARCHAR(50) PRIMARY KEY,
    PasswordHash VARBINARY(256) NOT NULL,
    UserName NVARCHAR(100)
);

-- Create Players table 
CREATE TABLE Players (
    UserId NVARCHAR(50) NOT NULL,
    CharId INT NOT NULL,
    Exp INT DEFAULT 0,
    Parameter1 INT DEFAULT 50,
    Parameter2 INT DEFAULT 50,
    Parameter3 INT DEFAULT 50,
    Parameter4 INT DEFAULT 50,
    CurrentEventId INT DEFAULT 1,
    CurrentSeq INT DEFAULT 1,
    PRIMARY KEY (UserId, CharId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

-- Create Events table
CREATE TABLE Events (
    EventId INT NOT NULL,
    Seq INT NOT NULL,
    EventType NVARCHAR(50),
    EventText NVARCHAR(1000),
    PRIMARY KEY (EventId, Seq)
);

-- Insert sample events
INSERT INTO Events (EventId, Seq, EventType, EventText) VALUES 
(1, 1, 'welcome', 'Welcome to the RPG world!'),
(1, 2, 'quest', 'Your first adventure begins...'),
(2, 1, 'battle', 'A wild monster appears!');