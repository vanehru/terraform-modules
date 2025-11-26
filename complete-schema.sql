-- Complete schema for RPG Gaming Backend - Simple version
-- Execute these statements one by one in Azure Data Studio

-- Step 1: Create Users table (for authentication)
CREATE TABLE [dbo].[Users](
    [UserId] [nvarchar](50) NOT NULL PRIMARY KEY,
    [PasswordHash] [varbinary](max) NOT NULL,
    [UserName] [nvarchar](100) NOT NULL,
    [CreatedAt] [datetime2] DEFAULT GETDATE()
);

-- Step 2: Create PlayerData table
CREATE TABLE [dbo].[PlayerData](
    [UserId] [nvarchar](50) NOT NULL PRIMARY KEY,
    [CharId] [int] NOT NULL DEFAULT 1,
    [Exp] [int] NOT NULL DEFAULT 0,
    [Parameter1] [int] NOT NULL DEFAULT 50,
    [Parameter2] [int] NOT NULL DEFAULT 50,
    [Parameter3] [int] NOT NULL DEFAULT 50,
    [Parameter4] [int] NOT NULL DEFAULT 50,
    [CurrentEventId] [int] NOT NULL DEFAULT 1,
    [CurrentSeq] [int] NOT NULL DEFAULT 1,
    FOREIGN KEY ([UserId]) REFERENCES [Users]([UserId])
);

-- Step 3: Create EventTable
CREATE TABLE [dbo].[EventTable](
    [EventId] [int] NOT NULL,
    [Seq] [int] NOT NULL,
    [Speaker] [nvarchar](100) NULL,
    [Text] [nvarchar](max) NOT NULL,
    CONSTRAINT [PK_Event] PRIMARY KEY CLUSTERED 
    (
        [EventId] ASC,
        [Seq] ASC
    )
);

-- Step 4: Insert sample events
INSERT INTO EventTable VALUES 
(1, 1, 'System', 'Welcome to the RPG world!'),
(1, 2, 'Guide', 'Your first adventure begins...'),
(2, 1, 'Monster', 'A wild monster appears!');
