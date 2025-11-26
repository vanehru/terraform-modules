-- Create PlayerData table (C# schema)
CREATE TABLE PlayerData (
    UserId NVARCHAR(50) NOT NULL,
    CharId INT DEFAULT 1,
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

-- Create EventTable (C# schema)
CREATE TABLE EventTable (
    EventId INT NOT NULL,
    Seq INT NOT NULL,
    Speaker NVARCHAR(50),
    Text NVARCHAR(1000),
    PRIMARY KEY (EventId, Seq)
);

-- Insert sample events
INSERT INTO EventTable VALUES 
(1, 1, 'System', 'Welcome to the RPG world!'),
(1, 2, 'Guide', 'Your first adventure begins...'),
(2, 1, 'Monster', 'A wild monster appears!');