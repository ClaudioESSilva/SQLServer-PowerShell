SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'[dbo].[DiskSpace]')
            AND type IN (N'U')
        )
BEGIN
    CREATE TABLE [dbo].[DiskSpace] (
        [ComputerName] [nvarchar](50) NULL
        , [Name] [nvarchar](50) NULL
        , [Label] [nvarchar](50) NULL
        , [Capacity] [bigint] NULL
        , [Free] [bigint] NULL
        , [PercentFree] [float] NULL
        , [BlockSize] [int] NULL
        , [FileSystem] [nvarchar](50) NULL
        , [Type] [nvarchar](50) NULL
        , [IsSqlDisk] [nvarchar](50) NULL
        , [Server] [nvarchar](50) NULL
        , [DriveType] [nvarchar](50) NULL
        , [SizeInBytes] [float] NULL
        , [FreeInBytes] [float] NULL
        , [SizeInKB] [float] NULL
        , [FreeInKB] [float] NULL
        , [SizeInMB] [float] NULL
        , [FreeInMB] [float] NULL
        , [SizeInGB] [float] NULL
        , [FreeInGB] [float] NULL
        , [SizeInTB] [float] NULL
        , [FreeInTB] [float] NULL
        , [SizeInPB] [float] NULL
        , [FreeInPB] [float] NULL
        , [CollectionTime] [datetime2](7) NULL
        ) ON [PRIMARY]
        WITH (DATA_COMPRESSION = PAGE)
END

IF NOT EXISTS (
        SELECT *
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'[dbo].[DiskSpace]')
            AND name = N'CI_DiskSpace_CollectionTime'
        )
    CREATE CLUSTERED INDEX [CI_DiskSpace_CollectionTime] ON [dbo].[DiskSpace] ([CollectionTime] ASC)
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


