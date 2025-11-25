-- Create PlayerData table
CREATE TABLE PlayerData(
	UserId nvarchar(50) NOT NULL,
	CharId int NOT NULL DEFAULT 0,
	Exp int NOT NULL DEFAULT 0,
	Parameter1 int NOT NULL DEFAULT 0,
	Parameter2 int NOT NULL DEFAULT 0,
	Parameter3 int NOT NULL DEFAULT 0,
	Parameter4 int NOT NULL DEFAULT 0,
	CurrentEventId int NOT NULL DEFAULT 1,
	CurrentSeq int NOT NULL DEFAULT 0,
	PRIMARY KEY (UserId)
);

-- Create EventTable
CREATE TABLE EventTable(
	EventId int NOT NULL,
	Seq int NOT NULL,
	Speaker nvarchar(100) NULL,
	Text nvarchar(max) NOT NULL,
	PRIMARY KEY (EventId, Seq)
);

-- Insert sample events
INSERT INTO EventTable VALUES 
(1, 1, 'System', 'Welcome to the RPG world!'),
(1, 2, 'Guide', 'Your first adventure begins...'),
(2, 1, 'Monster', 'A wild monster appears!');