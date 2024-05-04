/*
	Mixing UNICODE with NON-UNICODE

	Note: The output of your concatenations is what, primarily, matters. 
		  Only after the data type of your variable, if you are using one
*/

SELECT '---- WITH NON-UNICODE ''VARCHAR(MAX)'' -----'



DECLARE @var VARCHAR(MAX)

-- Let's get 8010 as result, right?
SET @var = REPLICATE('A', 7500) + REPLICATE('B', 510)

SELECT LEN(@var) AS 'Not more than 8K'
GO

/*
	Why?
		Because REPLICATE results is the same datatype as the input, 
	in this case VARCHAR which without MAX will be 8000
*/










DECLARE @var VARCHAR(MAX)

-- What if is a UNICODE
SET @var = REPLICATE(N'A', 7500) + REPLICATE('B', 510)

SELECT LEN(@var) AS 'Not more than 4K'
GO

/*
	Why?
		Because REPLICATE results is the same datatype as the input,
	in this case NVARCHAR which without MAX will be 4000
*/










DECLARE @var VARCHAR(MAX)

-- What if I say that my input is a UNICODE MAX
SET @var = REPLICATE(CAST(N'A' AS NVARCHAR(MAX)), 7500) + REPLICATE('B', 510)

SELECT LEN(@var) AS 'AH! Now I have 8010'
GO

/*
	Why?
		Because REPLICATE results is the same datatype as the input,
	in this case NVARCHAR(MAX)
*/










DECLARE @var VARCHAR(MAX)

-- Then...everything is COOL right?! Not really, let's chek if we concatenate UNICODE with NONUNICODE (with more than max 8000)
SET @var = REPLICATE(CAST(N'A' AS NVARCHAR(MAX)), 7500) + REPLICATE('B', 8010)

SELECT LEN(@var) AS 'Damm! I was expecting 15510! (7500 + 8010)'
GO

/*
	Why?
		Because even that REPLICATE results is the same datatype as the input,
	in this case NVARCHAR(MAX) the 2nd part is NONUNICODE and when converted
	to UNICODE it will default to 4000
*/










DECLARE @var VARCHAR(MAX)

-- Ok then if I cast the 'B' to a VARCHAR(MAX) it will work!
SET @var = REPLICATE(CAST(N'A' AS NVARCHAR(MAX)), 7500) + REPLICATE(CAST('B' AS VARCHAR(MAX)), 8010)
/*
	Yes. But what is the outcome a UNICODE or NONUNICODE one? 
	Well depends on the definition of the variable. In this case is a NONUNICODE
*/
SELECT LEN(@var) AS 'Now I have 15510! (7500 + 8010)', 
		DATALENGTH(@var) AS 'You defined me as NONUNICODE that is what I am - 1char = 1byte'
GO










SELECT '---- NOW WITH UNICODE ''NVARCHAR(MAX)'' -----'

DECLARE @var NVARCHAR(MAX)

-- Let's get 8010 as result, right?
SET @var = REPLICATE('A', 7500) + REPLICATE('B', 510)

SELECT LEN(@var) AS 'Not more than 8K'
GO

/*
	Why?
		Because REPLICATE results is the same datatype as the input,
	in this case VARCHAR which without MAX will be 8000
*/










DECLARE @var NVARCHAR(MAX)

-- What if is a UNICODE
SET @var = REPLICATE(N'A', 7500) + REPLICATE('B', 510)

SELECT LEN(@var) AS 'Not more than 4K'
GO

/*
	Why?
		Because REPLICATE results is the same datatype as the input,
	in this case NVARCHAR which without MAX will be 4000
*/










DECLARE @var NVARCHAR(MAX)

-- What if I say that my input is a UNICODE MAX
SET @var = REPLICATE(CAST(N'A' AS NVARCHAR(MAX)), 7500) + REPLICATE('B', 510)

SELECT LEN(@var) AS 'AH! Now I have 8010'
GO

/*
	Why?
		Because REPLICATE results is the same datatype as the input,
	in this case NVARCHAR(MAX)
*/










DECLARE @var NVARCHAR(MAX)

-- Then...everything is COOL right?! Not really, let's chek if we concatenate UNICODE with NONUNICODE (with more than max 8000)
SET @var = REPLICATE(CAST(N'A' AS NVARCHAR(MAX)), 7500) + REPLICATE('B', 8010)

SELECT LEN(@var) AS 'Damm! I was expecting 15510! (7500 + 8010)'
GO

/*
	Why?
		Because REPLICATE of NON-UNICODE ('B') can't be any bigger than 8000 
		(is the same datatype as the input,	in this case VARCHAR)
*/










DECLARE @var NVARCHAR(MAX)

-- Ok then if I cast the 'B' to a VARCHAR(MAX) it will work!
SET @var = REPLICATE(CAST(N'A' AS NVARCHAR(MAX)), 7500) + REPLICATE(CAST('B' AS VARCHAR(MAX)), 8010)
/*
	Yes. But what is the outcome a UNICODE or NONUNICODE one? 
	Well depends on the definition of the variable. In this case is a UNICODE
*/
SELECT LEN(@var) AS 'Now I have 15510! (7500 + 8010)', 
		DATALENGTH(@var) AS 'You defined me as UNICODE that is what I am - 1char = 2bytes'
GO




/*****************************************
	TAKEAWAY:

	- Be aware of truncations!
	- Make sure you use always the same datatype (unicode or non-unicode)
*****************************************/