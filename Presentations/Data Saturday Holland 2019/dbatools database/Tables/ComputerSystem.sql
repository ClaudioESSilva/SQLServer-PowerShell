SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'[dbo].[ComputerSystem]')
            AND type IN (N'U')
        )
BEGIN
    CREATE TABLE [dbo].[ComputerSystem] (
        [ComputerName] [nvarchar](50) NULL
        , [Domain] [nvarchar](50) NULL
        , [DomainRole] [nvarchar](50) NULL
        , [Manufacturer] [nvarchar](100) NULL
        , [Model] [nvarchar](100) NULL
        , [SystemFamily] [nvarchar](100) NULL
        , [SystemSkuNumber] [nvarchar](100) NULL
        , [SystemType] [nvarchar](100) NULL
        , [ProcessorName] [nvarchar](1000) NULL
        , [ProcessorCaption] [nvarchar](1000) NULL
        , [ProcessorMaxClockSpeed] [nvarchar](500) NULL
        , [NumberLogicalProcessors] [bigint] NULL
        , [NumberProcessors] [bigint] NULL
        , [IsHyperThreading] [bit] NULL
        , [TotalPhysicalMemory] [bigint] NULL
        , [IsDaylightSavingsTime] [bit] NULL
        , [DaylightInEffect] [bit] NULL
        , [DnsHostName] [nvarchar](50) NULL
        , [IsSystemManagedPageFile] [bit] NULL
        , [AdminPasswordStatus] [nvarchar](50) NULL
        , [CollectionTime] [datetime2](7) NULL
        ) ON [PRIMARY]
        WITH (DATA_COMPRESSION = PAGE)
END
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'[dbo].[ComputerSystem]')
            AND name = N'CI_ComputerSystem_CollectionTime'
        )
    CREATE CLUSTERED INDEX [CI_ComputerSystem_CollectionTime] ON [dbo].[ComputerSystem] ([CollectionTime] ASC)
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


