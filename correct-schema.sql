-- Create PlayerData table (exact schema from data.sql)
CREATE TABLE [dbo].[PlayerData](
	[UserId] [nvarchar](50) NOT NULL,
	[CharId] [int] NOT NULL,
	[Exp] [int] NOT NULL,
	[Parameter1] [int] NOT NULL,
	[Parameter2] [int] NOT NULL,
	[Parameter3] [int] NOT NULL,
	[Parameter4] [int] NOT NULL,
	[CurrentEventId] [int] NOT NULL,
	[CurrentSeq] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)
);

-- Add default values
ALTER TABLE [dbo].[PlayerData] ADD DEFAULT ((0)) FOR [CharId];
ALTER TABLE [dbo].[PlayerData] ADD DEFAULT ((0)) FOR [Exp];
ALTER TABLE [dbo].[PlayerData] ADD DEFAULT ((0)) FOR [Parameter1];
ALTER TABLE [dbo].[PlayerData] ADD DEFAULT ((0)) FOR [Parameter2];
ALTER TABLE [dbo].[PlayerData] ADD DEFAULT ((0)) FOR [Parameter3];
ALTER TABLE [dbo].[PlayerData] ADD DEFAULT ((0)) FOR [Parameter4];
ALTER TABLE [dbo].[PlayerData] ADD DEFAULT ((1)) FOR [CurrentEventId];
ALTER TABLE [dbo].[PlayerData] ADD DEFAULT ((0)) FOR [CurrentSeq];

-- Create EventTable (exact schema from data.sql)
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

-- Insert sample events
INSERT INTO EventTable VALUES 
(1, 1, 'System', 'Welcome to the RPG world!'),
(1, 2, 'Guide', 'Your first adventure begins...'),
(2, 1, 'Monster', 'A wild monster appears!');