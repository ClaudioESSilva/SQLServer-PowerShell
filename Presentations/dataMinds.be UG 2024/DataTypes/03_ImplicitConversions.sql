USE DataTypes
GO

DROP TABLE IF EXISTS ImplicitConversions
GO

SELECT TOP 1000000 IDENTITY(int, 1,1) AS ID, 
       SUBSTRING(CONVERT(varchar(250),NEWID()),1,8) AS [Name], 
       CONVERT(varchar(250), NEWID()) AS UUID,
	   CONVERT(varchar(10), ABS(CHECKSUM(NEWID()) / 1000000)) AS Code
  INTO ImplicitConversions
  FROM sys.columns AS a, sys.columns AS b, sys.columns AS c, sys.columns AS d
GO
ALTER TABLE ImplicitConversions ADD CONSTRAINT PK_ImplicitConversions PRIMARY KEY(ID)
GO


/*
  DROP INDEX NCI_Name ON ImplicitConversions
*/
CREATE INDEX NCI_Name ON ImplicitConversions([Name])
GO

SELECT TOP 10 *
FROM ImplicitConversions
GO










/*
	TURN ON ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO ON
*/

DECLARE @Name nvarchar(200)
SET @Name = N'E01DE6D5'

/*
  What gonna happen? Seek or scan?
*/
SELECT * 
  FROM ImplicitConversions
 WHERE Name = @Name
GO



DECLARE @Name varchar(200)
SET @Name = 'E01DE6D5'

/*
  What gonna happen? Seek or scan?
*/
SELECT * 
  FROM ImplicitConversions
 WHERE Name = @Name
GO




/*
	Show on SQLQueryStress
*/











/*
	What about numbers?
*/
SELECT *
  FROM ImplicitConversions
 WHERE Code = 661

SELECT *
  FROM ImplicitConversions
 WHERE Code = '661'

/*
	Let's create an index to help the query
*/
CREATE INDEX NCI_Code ON ImplicitConversions(Code)
GO


/*
	Now with a supportive index
*/
SELECT ID
  FROM ImplicitConversions
 WHERE Code = 661

SELECT ID
  FROM ImplicitConversions
 WHERE Code = '661'


/*
	NOTE: Check data types precedence:
		https://learn.microsoft.com/en-us/sql/t-sql/data-types/data-type-precedence-transact-sql
*/













/*
	INEQUALITY
*/
SELECT COUNT(1)
  FROM ImplicitConversions
 WHERE Code > '661'

SELECT COUNT(1)
  FROM ImplicitConversions
 WHERE Code > 661

/*
	Let's check what happens when we try to ORDER the data
*/
SELECT TOP 1000 *
  FROM ImplicitConversions
 WHERE Code > 1
ORDER BY Code


SELECT TOP 1000 *
  FROM ImplicitConversions
 WHERE Code > 1
ORDER BY CAST(Code AS int)




/*****************************************
	TAKEAWAY:

	- Don't do assumptions regarding data types. 
	Avoid try to infer them by the name. Confirm them!
*****************************************/