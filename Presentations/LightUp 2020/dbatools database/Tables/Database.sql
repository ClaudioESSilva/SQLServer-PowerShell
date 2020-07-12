SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'[dbo].[Database]')
            AND type IN (N'U')
        )
BEGIN
    CREATE TABLE [dbo].[Database] (
        [ComputerName] [nvarchar](50) NULL
        , [InstanceName] [nvarchar](50) NULL
        , [SqlInstance] [nvarchar](50) NULL
        , [SizeMB] [float] NULL
        , [Compatibility] [nvarchar](50) NULL
        , [LastFullBackup] [datetime2](7) NULL
        , [LastDiffBackup] [datetime2](7) NULL
        , [LastLogBackup] [datetime2](7) NULL
        , [Parent] [nvarchar](50) NULL
        , [ActiveConnections] [int] NULL
        , [Collation] [nvarchar](50) NULL
        , [CompatibilityLevel] [nvarchar](50) NULL
        , [CreateDate] [datetime2](7) NULL
        , [DataSpaceUsage] [float] NULL
        , [DefaultFileGroup] [nvarchar](50) NULL
        , [DelayedDurability] [nvarchar](50) NULL
        , [EncryptionEnabled] [bit] NULL
        , [HasMemoryOptimizedObjects] [nvarchar](50) NULL
        , [ID] [int] NULL
        , [IndexSpaceUsage] [float] NULL
        , [IsAccessible] [bit] NULL
        , [IsDatabaseSnapshot] [bit] NULL
        , [PageVerify] [nvarchar](50) NULL
        , [RecoveryModel] [nvarchar](50) NULL
        , [SpaceAvailable] [float] NULL
        , [Status] [nvarchar](50) NULL
        , [TargetRecoveryTime] [int] NULL
        , [Trustworthy] [bit] NULL
        , [UserAccess] [nvarchar](50) NULL
        , [Version] [int] NULL
        , [DatabaseEngineType] [nvarchar](50) NULL
        , [DatabaseEngineEdition] [nvarchar](50) NULL
        , [Name] [nvarchar](50) NULL
        , [CollectionTime] [datetime2](7) NULL
        ) ON [PRIMARY]
        WITH (DATA_COMPRESSION = PAGE)
END
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'[dbo].[Database]')
            AND name = N'CI_Database_CollectionTime'
        )
    CREATE CLUSTERED INDEX [CI_Database_CollectionTime] ON [dbo].[Database] ([CollectionTime] ASC)
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


