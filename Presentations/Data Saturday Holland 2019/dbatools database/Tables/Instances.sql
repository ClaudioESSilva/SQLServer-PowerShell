SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'[dbo].[Instances]')
            AND type IN (N'U')
        )
BEGIN
    CREATE TABLE [dbo].[Instances] (
        [HOSTNAME] [nvarchar](50) NULL
        , [PORT] [float] NULL
        , [ENVIRONMENT] [nvarchar](50) NULL
        , [DOMAIN] [nvarchar](255) NULL
        , [INSTANCE] [nvarchar](50) NULL
        ) ON [PRIMARY]
END
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'[dbo].[DF_Instances_INSTANCE]')
            AND type = 'D'
        )
BEGIN
    ALTER TABLE [dbo].[Instances] ADD CONSTRAINT [DF_Instances_INSTANCE] DEFAULT(N'MSSQLSERVER')
    FOR [INSTANCE]
END
GO


