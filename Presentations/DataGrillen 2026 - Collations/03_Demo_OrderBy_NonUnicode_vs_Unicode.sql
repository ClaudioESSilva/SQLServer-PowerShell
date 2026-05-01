/***********************************************************************************************
	This one isn't performance related but about accurate (based on your expectations) results

	A nice to know/remember when thinking about changing a column collation!
***********************************************************************************************/

USE CollationsPerformance
GO

/***********************************************
	Turn on STATISTICS TIME and IO
	Turn on "Include Actual Execution Plan"

	SET STATISTICS TIME, IO ON
***********************************************/

/************************************************************************
	Create a table with 4 columns. 
	Same data but different collations and data types (non)unicode
************************************************************************/
DROP TABLE IF EXISTS dbo.[LetsOrderBy]
GO
CREATE TABLE dbo.[LetsOrderBy]
(
	NonSQLCollationUnicode	nvarchar(10) COLLATE Latin1_General_CI_AS NOT NULL,
	NonSQLCollation			varchar(10) COLLATE Latin1_General_CI_AS NOT NULL,
	SQLCollationUnicode		nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	SQLCollation			varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
INSERT INTO dbo.[LetsOrderBy](NonSQLCollationUnicode, NonSQLCollation, SQLCollationUnicode, SQLCollation)
SELECT NonSQLCollationUnicode, NonSQLCollation, SQLCollationUnicode, SQLCollation
FROM (
		 VALUES (N'a-c', 'a-c', N'a-c', 'a-c'), 
				(N'b-c', 'b-c', N'b-c', 'b-c'), 
				(N'bc', 'bc', N'bc', 'bc'), 
				(N'ab', 'ab', N'ab', 'ab')
	) t(NonSQLCollationUnicode, NonSQLCollation, SQLCollationUnicode, SQLCollation)
GO


/**************************************
	Run the next four queries
	and check the order of the data
**************************************/
SELECT *
FROM dbo.LetsOrderBy
ORDER BY NonSQLCollationUnicode

SELECT *
FROM dbo.LetsOrderBy
ORDER BY SQLCollationUnicode


SELECT *
FROM dbo.LetsOrderBy
ORDER BY NonSQLCollation

SELECT *
FROM dbo.LetsOrderBy
ORDER BY SQLCollation
GO









/********************************************************************************************************
*********************************************************************************************************
		A SQL collation's rules for sorting non-Unicode data are incompatible with any sort routine 
	that is provided by the Microsoft Windows operating system; 
	however, the sorting of Unicode data is compatible with a particular version of the Windows 
	sorting rules. Because the comparison rules for non-Unicode and Unicode data are different, 
	when you use a SQL collation you might see different results for comparisons of the same 
	characters, depending on the underlying data type. 

		For example, if you are using the SQL collation "SQL_Latin1_General_CP1_CI_AS", the 
	non-Unicode string 'a-c' is less than the string 'ab' because the hyphen ("-") is sorted as 
	a separate character that comes before "b". 
	However, if you convert these strings to Unicode and you perform the same comparison, the 
	Unicode string N'a-c' is considered to be greater than N'ab' because the Unicode sorting 
	rules use a "word sort" that ignores the hyphen.

	Source: Comparing SQL collations to Windows collations (https://mskb.pkisolutions.com/kb/322112)
*********************************************************************************************************
********************************************************************************************************/



/***********************************************************************
	Database collation comes into play when using constant/variables
***********************************************************************/
SELECT col1
FROM (VALUES (N'a-c'), (N'b-c'), (N'ac'), (N'ab')) t(col1)
ORDER BY col1

SELECT col1
FROM (VALUES ('a-c'), ('b-c'), ('ac'), ('ab')) t(col1)
ORDER BY col1
GO


SELECT name, collation_name
FROM sys.databases
WHERE database_id = DB_ID()


SELECT col1
FROM (VALUES (N'a-c'), (N'b-c'), (N'ac'), (N'ab')) t(col1)
ORDER BY col1 COLLATE LATIN1_General_CI_AS

SELECT col1
FROM (VALUES ('a-c'), ('b-c'), ('ac'), ('ab')) t(col1)
ORDER BY col1 COLLATE LATIN1_General_CI_AS
GO
