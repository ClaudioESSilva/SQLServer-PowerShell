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
    CREATE TABLE [dbo].[InstanceProperty] (
        [ComputerName] [nvarchar](50) NULL
        , [BuildNumber] [nvarchar](50) NULL
        , [Edition] [nvarchar](50) NULL
        , [HasNullSaPassword] [nvarchar](50) NULL
        , [HostPlatform] [nvarchar](50) NULL
        , [IsCaseSensitive] [nvarchar](50) NULL
        , [IsFullTextInstalled] [nvarchar](50) NULL
        , [IsXTPSupported] [nvarchar](50) NULL
        , [Language] [nvarchar](50) NULL
        , [MaxPrecision] [nvarchar](50) NULL
        , [NetName] [nvarchar](50) NULL
        , [OSVersion] [nvarchar](50) NULL
        , [PathSeparator] [nvarchar](50) NULL
        , [PhysicalMemory] [nvarchar](50) NULL
        , [Platform] [nvarchar](50) NULL
        , [Processors] [nvarchar](50) NULL
        , [Product] [nvarchar](50) NULL
        , [VersionMajor] [nvarchar](50) NULL
        , [VersionMinor] [nvarchar](50) NULL
        , [VersionString] [nvarchar](50) NULL
        , [Collation] [nvarchar](50) NULL
        , [EngineEdition] [nvarchar](50) NULL
        , [IsClustered] [nvarchar](50) NULL
        , [IsSingleUser] [nvarchar](50) NULL
        , [ProductLevel] [nvarchar](50) NULL
        , [BuildClrVersionString] [nvarchar](50) NULL
        , [CollationID] [nvarchar](50) NULL
        , [ComparisonStyle] [nvarchar](50) NULL
        , [ComputerNamePhysicalNetBIOS] [nvarchar](50) NULL
        , [ResourceLastUpdateDateTime] [nvarchar](50) NULL
        , [ResourceVersionString] [nvarchar](50) NULL
        , [SqlCharSet] [nvarchar](50) NULL
        , [SqlCharSetName] [nvarchar](50) NULL
        , [SqlSortOrder] [nvarchar](50) NULL
        , [SqlSortOrderName] [nvarchar](50) NULL
        , [FullyQualifiedNetName] [nvarchar](50) NULL
        , [IsHadrEnabled] [nvarchar](50) NULL
        , [AbortOnArithmeticErrors] [nvarchar](50) NULL
        , [AbortTransactionOnError] [nvarchar](50) NULL
        , [AnsiNullDefaultOff] [nvarchar](50) NULL
        , [AnsiNullDefaultOn] [nvarchar](50) NULL
        , [AnsiNulls] [nvarchar](50) NULL
        , [AnsiPadding] [nvarchar](50) NULL
        , [AnsiWarnings] [nvarchar](50) NULL
        , [ConcatenateNullYieldsNull] [nvarchar](50) NULL
        , [CursorCloseOnCommit] [nvarchar](50) NULL
        , [DisableDefaultConstraintCheck] [nvarchar](50) NULL
        , [IgnoreArithmeticErrors] [nvarchar](50) NULL
        , [ImplicitTransactions] [nvarchar](50) NULL
        , [NoCount] [nvarchar](50) NULL
        , [NumericRoundAbort] [nvarchar](50) NULL
        , [QuotedIdentifier] [nvarchar](50) NULL
        , [AuditLevel] [nvarchar](50) NULL
        , [LoginMode] [nvarchar](50) NULL
        , [MailProfile] [nvarchar](50) NULL
        , [NumberOfLogFiles] [nvarchar](50) NULL
        , [PerfMonMode] [nvarchar](50) NULL
        , [TapeLoadWaitTime] [nvarchar](50) NULL
        , [ErrorLogSizeKb] [nvarchar](50) NULL
        , [CollectionTime] [datetime2](7) NULL
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


