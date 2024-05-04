/**********************************************************************
							F L O A T S

From documentation:
	Approximate-number data types for use with floating point numeric data. 
	Floating point data is approximate; therefore, not all values in the 
  data type range can be represented exactly.

	Source: https://learn.microsoft.com/en-us/sql/t-sql/data-types/float-and-real-transact-sql
**********************************************************************/
DECLARE @float1 float = 0.1
DECLARE @float2 float = 0.2

SELECT
		-- Addition of both values
		@float1 + @float2 AS AdditionBoth,

		-- some floats with values 0.1 and 0.2. Is it = 0.3?
		CASE 
			WHEN @float1 + @float2 = 0.3 THEN 'True'
			ELSE 'False'
		 END AS CaseTest
GO
























/*
	An SSMS problem!
		- SSMS hides the full story (result of the addition)

	Let's see SQLCMD (use "02_FLOAT_sqlcmd")
	What about ADS (Azure Data Studio)?
*/





































/*
	How can this create problems?!
*/

/*
	Equality
*/
USE DataTypes
GO

DROP TABLE IF EXISTS testFloat
GO

/*
	Still from documentation:
		If n is specified, it must be a value between 1 and 53. The default value of n is 53.

		SQL Server treats n as one of two possible values. 
		If 1<=n<=24, n is treated as 24. 
		If 25<=n<=53, n is treated as 53.
*/
CREATE TABLE testFloat
(
 col10 float(10),
 col24 float(24),
 col25 float(25),
 col30 float(30),
 colF  float,
 colR  real,
)
GO

-- Insert a record with a sum of two floats
INSERT INTO testFloat (colF) 
VALUES (CAST(.1 as float) + CAST(.2 as float))

-- Check the record
SELECT * 
  FROM testFloat
GO

-- Can we filter by the value?
SELECT * 
  FROM testFloat 
 WHERE colF = .3
GO

-- You missed the "0" before the ".3"
SELECT * 
  FROM testFloat 
 WHERE colF = 0.3
GO

-- Using the percision of the column datatype
DECLARE @f float = 0.3
SELECT * 
  FROM testFloat 
 WHERE colF = @f
GO

-- Try with different percision (hopeless)
DECLARE @f float(3) = 0.3
SELECT * 
  FROM testFloat 
 WHERE colF = @f
GO

-- What if we compare with stored value - "0.30000000000000004"
SELECT * 
  FROM testFloat 
 WHERE colF = 0.30000000000000004
GO














































/*
	INEQUALITY
*/
SET NOCOUNT ON;
DECLARE @float float(1) = 4.7

-- Exit when variable equal to 5.0 or above 5.2
WHILE (@float <> 5 AND @float < 5.2)
	BEGIN
		PRINT @float
		SELECT @float, SUM(@float)
		PRINT ''
		PRINT ''
		SET @float += 0.1;
	END 

SELECT  @float,
		SUM(@float) AS SumResult, 
		SUM(CAST(@float AS float(1))) AS SumCastResult, 
		CAST(@float AS float(52)) AS Cast52,
		CAST(SUM(@float) AS float(1)),
		CAST(SUM(@float) AS float)

SELECT DATALENGTH(CAST(@float AS float(24))) AS DataLength24InBytes, 
		DATALENGTH(CAST(@float AS float(25))) AS DataLength25InBytes
GO




















/*
	ROUNDING / CEILING

	Client using CEILING function
		CEILING returns the smallest integer greater than, or equal to, the specificed numeric expression 
*/
DECLARE @float1 float(1) = 0.1
DECLARE @float2 float(1) = 0.2

SELECT CEILING(0.7) AS [Ceiling0.7],
		CEILING(1.001) AS [Ceiling1.001]

SELECT @float1 AS [Float],
		CAST(@float1 AS float) FloatWithBiggerPercision,
		@float2 AS [Float2],
		CAST(@float2 AS float) Float2WithBiggerPercision

SELECT SUM(CAST(@float1 AS float) + CAST(@float2 AS float) + 0.7) AS [SumBut0.7IsDecimal],
		SUM(CAST(@float1 AS float) + CAST(@float2 AS float) + CAST(0.7 AS float)) AS SumAllWithBiggerPercision,
		SUM(CAST(@float1 AS float) + CAST(@float2 AS float) + CAST(0.7 AS float(24))) AS [SumBut0.7HasSmallerPercision]

SELECT CEILING(SUM(CAST(@float1 AS float) + CAST(@float2 AS float) + 0.7)) AS [CeilingSumBut0.7IsDecimal],
		CEILING(SUM(CAST(@float1 AS float) + CAST(@float2 AS float) + CAST(0.7 AS float))) AS CeilingSumAllWithBiggerPercision,
		CEILING(SUM(CAST(@float1 AS float) + CAST(@float2 AS float) + CAST(0.7 AS float(24)))) AS [CeilingSumBut0.7HasSmallerPercision]
GO












































/*
	FORMAT

	Use STR() - From documentation:
		Returns character data converted from numeric data. 
		The character data is right-justified, with a specified length and decimal precision.
	Source: https://learn.microsoft.com/en-us/sql/t-sql/functions/str-transact-sql
*/
declare @f1 float;
declare @f2 float;
set @f1 = 1555.49;
set @f2 = 1555.4899999999998;
select @f1, @f2;
select STR(@f1,30,15), STR(@f2,30,15);































/*****************************************
	TAKEAWAYS:

	It's ok to use FLOAT:
		- for thing you measure and don't need lots of precision (engineering and scientific application)
	
	Avoid using FLOAT:
		- when accuracy is important 
			- Working with money, financial apps
		- equality checks (=)
		- inequality checks (<>)
		- rounding number
		- for things you count

	What to use? 
		- Use DECIMAL instead. Gives you precision up to 38.

	Check FLOAT converter:
		https://www.h-schmidt.net/FloatConverter/IEEE754.html

	To better understand floats:
		- Floating Point Math (30000000000000004.com) - https://0.30000000000000004.com/
		- The Floating-Point Guide - What Every Programmer Should Know About Floating-Point Arithmetic - https://floating-point-gui.de/
*****************************************/

