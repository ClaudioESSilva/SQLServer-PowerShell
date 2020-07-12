SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (
        SELECT *
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'[dbo].[Dates]')
            AND type IN (N'U')
        )
BEGIN
    CREATE TABLE [dbo].[Dates] (
        [DWDateKey] [date] NOT NULL
        , [DayDate] [int] NULL
        , [DayOfWeekName] [nvarchar](30) NULL
        , [WeekNumber] [int] NULL
        , [MonthNumber] [int] NULL
        , [MonthName] [nvarchar](30) NULL
        , [MonthShortName] [nvarchar](4) NULL
        , [Year] [int] NULL
        , [QuarterNumber] [nvarchar](30) NULL
        , [QuarterName] [nvarchar](30) NULL
        ) ON [PRIMARY]
END
GO

ALTER TABLE dbo.Dates
  ADD CONSTRAINT PK_Dates PRIMARY KEY CLUSTERED
	(
	    DWDateKey
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, DATA_COMPRESSION = PAGE) ON [PRIMARY]

GO

;WITH CTE_DatesTable
AS
(
  SELECT CAST('20190101' as date) AS [date]
  UNION ALL
  SELECT  DATEADD(dd, 1, [date])
  FROM CTE_DatesTable
  WHERE DATEADD(dd, 1, [date]) <= '21001231'
)
INSERT INTO [dbo].[Dates] ([DWDateKey], [DayDate], [DayOfWeekName], [WeekNumber], [MonthNumber], [MonthName], [MonthShortName], [Year], [QuarterNumber], [QuarterName])
SELECT [DWDateKey]=[date]
    ,[DayDate]=datepart(dd,[date])
    ,[DayOfWeekName]=datename(dw,[date])
    ,[WeekNumber]=DATEPART( WEEK , [date])
    ,[MonthNumber]=DATEPART( MONTH , [date])
    ,[MonthName]=DATENAME( MONTH , [date])
    ,[MonthShortName]=substring(LTRIM( DATENAME(MONTH,[date])),0, 4)
    ,[Year]=DATEPART(YY,[date])
    ,[QuarterNumber]=DATENAME(quarter, [date])
    ,[QuarterName]=DATENAME(quarter, [date])
FROM CTE_DatesTable

OPTION (MAXRECURSION 0);


