SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'[dbo].[InstanceProperty]')
            AND type IN (N'U')
        )
BEGIN
    CREATE TABLE [dbo].[InstanceProperty](
            [ComputerName] [NVARCHAR](50) NULL,
            [BuildNumber] [NVARCHAR](50) NULL,
            [Edition] [NVARCHAR](50) NULL,
            [ErrorLogPath] [NVARCHAR](100) NULL,
            [HasNullSaPassword] [NVARCHAR](50) NULL,
            [HostPlatform] [NVARCHAR](50) NULL,
            [IsCaseSensitive] [NVARCHAR](50) NULL,
            [IsFullTextInstalled] [NVARCHAR](50) NULL,
            [IsXTPSupported] [NVARCHAR](50) NULL,
            [Language] [NVARCHAR](50) NULL,
            [MasterDBLogPath] [NVARCHAR](100) NULL,
            [MasterDBPath] [NVARCHAR](100) NULL,
            [MaxPrecision] [NVARCHAR](50) NULL,
            [NetName] [NVARCHAR](50) NULL,
            [OSVersion] [NVARCHAR](50) NULL,
            [PathSeparator] [NVARCHAR](50) NULL,
            [PhysicalMemory] [NVARCHAR](50) NULL,
            [Platform] [NVARCHAR](50) NULL,
            [Processors] [NVARCHAR](50) NULL,
            [Product] [NVARCHAR](50) NULL,
            [RootDirectory] [NVARCHAR](100) NULL,
            [VersionMajor] [NVARCHAR](50) NULL,
            [VersionMinor] [NVARCHAR](50) NULL,
            [VersionString] [NVARCHAR](50) NULL,
            [Collation] [NVARCHAR](50) NULL,
            [EngineEdition] [NVARCHAR](50) NULL,
            [IsClustered] [NVARCHAR](50) NULL,
            [IsSingleUser] [NVARCHAR](50) NULL,
            [ProductLevel] [NVARCHAR](50) NULL,
            [BuildClrVersionString] [NVARCHAR](50) NULL,
            [CollationID] [NVARCHAR](50) NULL,
            [ComparisonStyle] [NVARCHAR](50) NULL,
            [ComputerNamePhysicalNetBIOS] [NVARCHAR](50) NULL,
            [ResourceLastUpdateDateTime] [NVARCHAR](50) NULL,
            [ResourceVersionString] [NVARCHAR](50) NULL,
            [SqlCharSet] [NVARCHAR](50) NULL,
            [SqlCharSetName] [NVARCHAR](50) NULL,
            [SqlSortOrder] [NVARCHAR](50) NULL,
            [SqlSortOrderName] [NVARCHAR](50) NULL,
            [FullyQualifiedNetName] [NVARCHAR](50) NULL,
            [IsHadrEnabled] [NVARCHAR](50) NULL,
            [IsPolyBaseInstalled] [NVARCHAR](50) NULL,
            [AbortOnArithmeticErrors] [NVARCHAR](50) NULL,
            [AbortTransactionOnError] [NVARCHAR](50) NULL,
            [AnsiNullDefaultOff] [NVARCHAR](50) NULL,
            [AnsiNullDefaultOn] [NVARCHAR](50) NULL,
            [AnsiNulls] [NVARCHAR](50) NULL,
            [AnsiPadding] [NVARCHAR](50) NULL,
            [AnsiWarnings] [NVARCHAR](50) NULL,
            [ConcatenateNullYieldsNull] [NVARCHAR](50) NULL,
            [CursorCloseOnCommit] [NVARCHAR](50) NULL,
            [DisableDefaultConstraintCheck] [NVARCHAR](50) NULL,
            [IgnoreArithmeticErrors] [NVARCHAR](50) NULL,
            [ImplicitTransactions] [NVARCHAR](50) NULL,
            [NoCount] [NVARCHAR](50) NULL,
            [NumericRoundAbort] [NVARCHAR](50) NULL,
            [QuotedIdentifier] [NVARCHAR](50) NULL,
            [AuditLevel] [NVARCHAR](50) NULL,
            [BackupDirectory] [NVARCHAR](100) NULL,
            [DefaultFile] [NVARCHAR](100) NULL,
            [DefaultLog] [NVARCHAR](100) NULL,
            [LoginMode] [NVARCHAR](50) NULL,
            [MailProfile] [NVARCHAR](50) NULL,
            [NumberOfLogFiles] [NVARCHAR](50) NULL,
            [PerfMonMode] [NVARCHAR](50) NULL,
            [TapeLoadWaitTime] [NVARCHAR](50) NULL,
            [ErrorLogSizeKb] [NVARCHAR](50) NULL,
            [CollectionTime] [datetime2](7) NULL
        ) ON [PRIMARY]
        WITH (DATA_COMPRESSION = PAGE)
END
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'[dbo].[InstanceProperty]')
            AND name = N'CI_InstanceProperty_CollectionTime'
        )
    CREATE CLUSTERED INDEX [CI_InstanceProperty_CollectionTime] ON [dbo].[InstanceProperty] ([CollectionTime] ASC)
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


