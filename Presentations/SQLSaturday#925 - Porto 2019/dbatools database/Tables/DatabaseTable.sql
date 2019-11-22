SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'[dbo].[DatabaseTable]')
            AND type IN (N'U')
        )
BEGIN
    CREATE TABLE [dbo].[DatabaseTable] (
        [ComputerName] [nvarchar](50) NULL
        , [InstanceName] [nvarchar](255) NULL
        , [SqlInstance] [nvarchar](50) NULL
        , [Database] [nvarchar](50) NULL
        , [Schema] [nvarchar](255) NULL
        , [Name] [nvarchar](255) NULL
        , [IndexSpaceUsed] [float] NULL
        , [DataSpaceUsed] [float] NULL
        , [RowCount] [bigint] NULL
        , [HasClusteredIndex] [bit] NULL
        , [IsFileTable] [bit] NULL
        , [IsMemoryOptimized] [bit] NULL
        , [IsPartitioned] [bit] NULL
        , [FullTextIndex] [nvarchar](255) NULL
        , [ChangeTrackingEnabled] [bit] NULL
        , [CollectionTime] [datetime2](7) NULL
        ) ON [PRIMARY]
        WITH (DATA_COMPRESSION = PAGE)
END
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'[dbo].[DatabaseTable]')
            AND name = N'CI_DatabaseTable_CollectionTime'
        )
    CREATE CLUSTERED INDEX [CI_DatabaseTable_CollectionTime] ON [dbo].[DatabaseTable] ([CollectionTime] ASC)
        WITH (
                PAD_INDEX = OFF
                , STATISTICS_NORECOMPUTE = OFF
                , SORT_IN_TEMPDB = OFF
                , DROP_EXISTING = OFF
                , ONLINE = OFF
                , ALLOW_ROW_LOCKS = ON
                , ALLOW_PAGE_LOCKS = ON
                , DATA_COMPRESSION = PAGE
                ) ON [PRIMARY]
GO


