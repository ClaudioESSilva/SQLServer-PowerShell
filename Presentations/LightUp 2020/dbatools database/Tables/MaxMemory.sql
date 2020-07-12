SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'[dbo].[MaxMemory]')
            AND type IN (N'U')
        )
BEGIN
    CREATE TABLE [dbo].[MaxMemory] (
        [ComputerName] [nvarchar](50) NULL
        , [InstanceName] [nvarchar](255) NULL
        , [SqlInstance] [nvarchar](50) NULL
        , [Total] [int] NULL
        , [MaxValue] [int] NULL
        , [Server] [nvarchar](50) NULL
        , [CollectionTime] [datetime2](7) NOT NULL
        ) ON [PRIMARY]
        WITH (DATA_COMPRESSION = PAGE)
END
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'[dbo].[MaxMemory]')
            AND name = N'CI_MaxMemory_CollectionTime'
        )
    CREATE CLUSTERED INDEX [CI_MaxMemory_CollectionTime] ON [dbo].[MaxMemory] ([CollectionTime] ASC)
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


