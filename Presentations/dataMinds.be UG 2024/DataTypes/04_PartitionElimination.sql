/*
	WHAT ABOUT PARTITIONED TABLES?

	NOTE: Partitioning is NOT a PERFORMANCE feature!
		  However, if you can leverage on it to make queries faster/do less IO....why not? :-) 
*/

USE DataTypes;
GO

/*
	TURN *OFF* ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO OFF
*/

/*
  ~3 sec to create
*/
IF OBJECT_ID('TabPartitionElimination') IS NOT NULL
  DROP TABLE TabPartitionElimination
GO
IF EXISTS(SELECT * FROM sys.partition_schemes WHERE name = 'myRangePS')
  DROP PARTITION SCHEME myRangePS
GO

IF EXISTS(SELECT * FROM sys.partition_functions WHERE name = 'myRangePF')
  DROP PARTITION FUNCTION myRangePF
GO

CREATE PARTITION FUNCTION myRangePF (INT)
AS RANGE LEFT FOR VALUES
(   100,
    500,
    1000,
    1500
);

CREATE PARTITION SCHEME myRangePS AS PARTITION myRangePF ALL TO ([PRIMARY]);
GO

CREATE TABLE TabPartitionElimination
(
    Col1 INT,
    Col2 INT,
    Col3 CHAR(1000) DEFAULT NEWID()
) ON myRangePS (Col1);
GO

IF OBJECT_ID('TabNonPartitioned') IS NOT NULL
  DROP TABLE TabNonPartitioned

CREATE TABLE TabNonPartitioned
(
    Col1 INT,
    Col2 INT,
    Col3 CHAR(1000) DEFAULT NEWID()
) ON [PRIMARY];
GO

SET NOCOUNT ON;
BEGIN TRANSACTION
GO
INSERT INTO TabPartitionElimination (Col1, Col2)
SELECT TOP(20000) ABS(CheckSUM(NEWID()) / 10000000), ABS(CheckSUM(NEWID()) / 10000000)
  FROM sys.columns AS a, sys.columns AS b, sys.columns AS c, sys.columns AS d
GO

INSERT INTO TabPartitionElimination (Col1, Col2)
SELECT TOP(1000) 1001, ABS(CheckSUM(NEWID()) / 10000000)
  FROM sys.columns AS a, sys.columns AS b, sys.columns AS c, sys.columns AS d
GO

INSERT INTO TabPartitionElimination (Col1, Col2)
SELECT TOP(1000) 1501, ABS(CheckSUM(NEWID()) / 10000000)
  FROM sys.columns AS a, sys.columns AS b, sys.columns AS c, sys.columns AS d
GO
COMMIT
GO

/*
  Creating a CLUSTERED INDEX
*/
CREATE CLUSTERED INDEX CI_TabPartitionElimination ON [dbo].TabPartitionElimination (COL1)
GO

/*
  Copy all data from partitioned table to the non-partitioned
*/
INSERT INTO TabNonPartitioned
SELECT * FROM TabPartitionElimination
GO




/*
  Check the number of the partitions
*/
SELECT $partition.myRangePF(Col1) [Partition Number], * 
  FROM TabPartitionElimination
GO













/*
	TURN ON ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO ON
*/

/*
  Read only data from partition 5
*/
SELECT * 
  FROM TabPartitionElimination
 WHERE Col1 > 1500 /* Static partition elimination */
   AND 1 = 1 /* Get rid of the auto-parameterization - https://www.sql.kiwi/2012/09/why-doesn-t-partition-elimination-work.html */


/*
  Read only data from partition 4 & 5
*/
DECLARE @i INT = 1500
SELECT * 
  FROM TabPartitionElimination
 WHERE Col1 >= @i /* Dynamic partition elimination */
GO

/*
  What about non-partitioned table?
*/
DECLARE @i INT = 1500
SELECT * 
  FROM TabNonPartitioned
 WHERE Col1 >= @i
GO


/*
  Read only data from partition 4 & 5?
*/
DECLARE @i BIGINT = 1500
SELECT * 
  FROM TabPartitionElimination
 WHERE Col1 >= @i
/*
  How many partitions were read?!
*/






























/*
	TURN *OFF* ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO OFF
*/
/*
	WHAT ABOUT DATES?

	NOTE: Partitioning is NOT a PERFORMANCE feature!
		  However, if you can leverage on it to make queries faster....why not? :-) 
*/

IF OBJECT_ID('TabPartitionEliminationDates') IS NOT NULL
  DROP TABLE TabPartitionEliminationDates
GO
IF EXISTS(SELECT * FROM sys.partition_schemes WHERE name = 'myDateRangePS')
  DROP PARTITION SCHEME myDateRangePS
GO

IF EXISTS(SELECT * FROM sys.partition_functions WHERE name = 'myDateRangePF')
  DROP PARTITION FUNCTION myDateRangePF
GO

CREATE PARTITION FUNCTION myDateRangePF (DATETIME2(0))
AS RANGE LEFT FOR VALUES
(   
	'2014-01-01',
	'2015-01-01',
	'2016-01-01',
	'2017-01-01',
	'2018-01-01',
	'2019-01-01',
	'2020-01-01',
	'2021-01-01',
    '2022-01-01',
    '2023-01-01',
    '2024-01-01'
);

CREATE PARTITION SCHEME myDateRangePS AS PARTITION myDateRangePF ALL TO ([PRIMARY]);
GO

CREATE TABLE TabPartitionEliminationDates
(
    EventDT DATETIME2(0),
    EventEndDT DATETIME2(7),
    Col3 CHAR(1000) DEFAULT NEWID()
) ON myDateRangePS (EventDT);
GO

/*
  Creating a CLUSTERED INDEX -- Less impact
  or leave as a HEAP -- We'll see a bigger impact
*/
--CREATE CLUSTERED INDEX CI_TabPartitionEliminationDates ON [dbo].TabPartitionEliminationDates (EventDT) ON myDateRangePS (EventDT);
--GO


SET NOCOUNT ON;
BEGIN TRANSACTION
GO
INSERT INTO TabPartitionEliminationDates (EventDT, EventEndDT)
SELECT TOP(100000) DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+360, '2016-01-01'), DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+360, '2016-01-01')
  FROM sys.columns AS a, sys.columns AS b, sys.columns AS c, sys.columns AS d
GO

INSERT INTO TabPartitionEliminationDates (EventDT, EventEndDT)
SELECT TOP(100000) DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+30, '2017-01-01'), DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+360, '2017-01-01')
  FROM sys.columns AS a, sys.columns AS b, sys.columns AS c, sys.columns AS d
GO

INSERT INTO TabPartitionEliminationDates (EventDT, EventEndDT)
SELECT TOP(100000) DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+30, '2018-01-01'), DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+360, '2018-01-01')
  FROM sys.columns AS a, sys.columns AS b, sys.columns AS c, sys.columns AS d
GO

INSERT INTO TabPartitionEliminationDates (EventDT, EventEndDT)
SELECT TOP(500000) DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+30, '2019-01-01'), DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+360, '2019-01-01')
  FROM sys.columns AS a, sys.columns AS b, sys.columns AS c, sys.columns AS d
GO

INSERT INTO TabPartitionEliminationDates (EventDT, EventEndDT)
SELECT TOP(500000) DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+30, '2022-01-01'), DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+360, '2022-09-01')
  FROM sys.columns AS a, sys.columns AS b, sys.columns AS c, sys.columns AS d
GO

INSERT INTO TabPartitionEliminationDates (EventDT, EventEndDT)
SELECT TOP(150000) '2023-01-02', DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+30, '2023-01-02')
  FROM sys.columns AS a, sys.columns AS b, sys.columns AS c, sys.columns AS d
GO

INSERT INTO TabPartitionEliminationDates (EventDT, EventEndDT)
SELECT TOP(150000) '2024-01-02', DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+30, '2024-01-02')
  FROM sys.columns AS a, sys.columns AS b, sys.columns AS c, sys.columns AS d
GO
COMMIT
GO


SELECT $partition.myDateRangePF(EventDT) [Partition Number], * 
  FROM TabPartitionEliminationDates
GO

/*
	TURN ON ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO ON
*/

/*
  How many partitions were read?
*/
DECLARE @DT DATETIME = '2022-01-02'
SELECT COUNT(1) 
  FROM TabPartitionEliminationDates
 WHERE EventDT > @DT
GO


DECLARE @DT DATE = '2022-01-02'
SELECT COUNT(1)
  FROM TabPartitionEliminationDates
 WHERE EventDT > @DT
GO




DECLARE @DT2 DATETIME = '2023-01-02'
SELECT EventDT
  FROM TabPartitionEliminationDates
 WHERE EventDT >= @DT2
GO

DECLARE @DT2 DATETIME2(0) = '2023-01-02'
SELECT EventDT
  FROM TabPartitionEliminationDates
 WHERE EventDT >= @DT2
GO


/*
	Bottom line:
		- Avoid implicit conversions.
		- Make sure you use variables of the same data types as our table columns
		  That will also help getting partition elimination when possible
*/

