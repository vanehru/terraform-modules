/****** Object:  Table [dbo].[EventTable]    Script Date: 2025/09/25 18:17:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EventTable](
	[EventId] [int] NOT NULL,
	[Seq] [int] NOT NULL,
	[Speaker] [nvarchar](100) NULL,
	[Text] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_Event] PRIMARY KEY CLUSTERED 
(
	[EventId] ASC,
	[Seq] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[KakeiboTable]    Script Date: 2025/09/25 18:17:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[KakeiboTable](
	[Date] [date] NULL,
	[Inout] [nvarchar](10) NULL,
	[Category] [nvarchar](20) NULL,
	[Amount] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PlayerData]    Script Date: 2025/09/25 18:17:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SampleTable]    Script Date: 2025/09/25 18:17:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SampleTable](
	[ID] [int] NOT NULL,
	[Name] [nvarchar](50) NULL,
 CONSTRAINT [PK_SampleTable] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SampleTable2]    Script Date: 2025/09/25 18:17:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SampleTable2](
	[ID] [int] NOT NULL,
	[Name] [nvarchar](50) NULL,
 CONSTRAINT [PK_SampleTable2] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[sessions]    Script Date: 2025/09/25 18:17:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[sessions](
	[session_id] [varchar](128) NOT NULL,
	[user_id] [int] NOT NULL,
	[user_name] [nvarchar](256) NOT NULL,
	[ip_address] [varchar](45) NULL,
	[user_agent] [varchar](512) NULL,
	[created_at] [datetime] NOT NULL,
	[updated_at] [datetime] NULL,
	[expires_at] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[session_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 2025/09/25 18:17:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[UserId] [nvarchar](50) NOT NULL,
	[PasswordHash] [varbinary](256) NOT NULL,
	[UserName] [nvarchar](100) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PlayerData] ADD  DEFAULT ((0)) FOR [CharId]
GO
ALTER TABLE [dbo].[PlayerData] ADD  DEFAULT ((0)) FOR [Exp]
GO
ALTER TABLE [dbo].[PlayerData] ADD  DEFAULT ((0)) FOR [Parameter1]
GO
ALTER TABLE [dbo].[PlayerData] ADD  DEFAULT ((0)) FOR [Parameter2]
GO
ALTER TABLE [dbo].[PlayerData] ADD  DEFAULT ((0)) FOR [Parameter3]
GO
ALTER TABLE [dbo].[PlayerData] ADD  DEFAULT ((0)) FOR [Parameter4]
GO
ALTER TABLE [dbo].[PlayerData] ADD  DEFAULT ((1)) FOR [CurrentEventId]
GO
ALTER TABLE [dbo].[PlayerData] ADD  DEFAULT ((0)) FOR [CurrentSeq]
GO
