USE CollationsPerformance
GO

/***********************************************
	Turn on STATISTICS TIME and IO
	Turn on "Include Actual Execution Plan"

	SET STATISTICS TIME, IO ON
***********************************************/

/*******************
	DROP INDEXES
*******************/
DROP INDEX [batchref_parent_idx_1] ON [NonSQLCollation].[batchref_child]
GO
DROP INDEX [batchref_parent_idx_1] ON [SQLCollation].[batchref_child]
GO


/*********************************************************
	Count the number of records based on a LIKE pattern
*********************************************************/
SELECT COUNT(1) AS RecordsFound
FROM [NonSQLCollation].[batchref_child] AS c
WHERE batchref_parent LIKE '%ABCD%'


SELECT COUNT(1) AS RecordsFound
FROM [SQLCollation].[batchref_child] AS c
WHERE batchref_parent LIKE '%ABCD%'
GO


/*******************************************************
	Add an index on the child table

	This shows that the problem isn't getting the data 
*******************************************************/
CREATE NONCLUSTERED INDEX [batchref_parent_idx_1] ON [NonSQLCollation].[batchref_child]
(
	[batchref_parent] ASC
)
GO

CREATE NONCLUSTERED INDEX [batchref_parent_idx_1] ON [SQLCollation].[batchref_child]
(
	[batchref_parent] ASC
)
GO


/*******************************
	Is it faster?
	Does it return any data?
*******************************/
SELECT COUNT(1) AS RecordsFound
FROM [NonSQLCollation].[batchref_child] AS c
WHERE batchref_parent LIKE '%ABCD%'


SELECT COUNT(1) AS RecordsFound
FROM [SQLCollation].[batchref_child] AS c
WHERE batchref_parent LIKE '%ABCD%'
GO



/************************************************************
	1. Run the next query and pick an existing partial string
	2. Replace on the next four queries

	Replace below and run. Check that, the first two are 
	quick but last two still show a huge difference.
	
	The fact we have the index and we are doing search 
	without the leading wild card, 	can make you think 
	that performace will be the same.
************************************************************/
SELECT TOP 10 *
FROM [NonSQLCollation].[batchref_child]



SELECT COUNT(1) AS RecordsFound
FROM [NonSQLCollation].[batchref_child] AS c
WHERE batchref_parent LIKE 'FFCA%'


SELECT COUNT(1) AS RecordsFound
FROM [SQLCollation].[batchref_child] AS c
WHERE batchref_parent LIKE 'FFCA%'
GO


SELECT COUNT(1) AS RecordsFound
FROM [NonSQLCollation].[batchref_child] AS c
WHERE batchref_parent LIKE '%FFCA%'


SELECT COUNT(1) AS RecordsFound
FROM [SQLCollation].[batchref_child] AS c
WHERE batchref_parent LIKE '%FFCA%'
GO