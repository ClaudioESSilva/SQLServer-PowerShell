USE CollationsPerformance
GO


/***************************
	Show table structure
***************************/
EXEC sp_spaceused '[NonSQLCollation].[batchref_child]'
EXEC sp_spaceused '[SQLCollation].[batchref_child]'

EXEC sp_spaceused '[NonSQLCollation].[batchref_parent]'
EXEC sp_spaceused '[SQLCollation].[batchref_parent]'

EXEC sp_help '[NonSQLCollation].[batchref_child]'
EXEC sp_help '[SQLCollation].[batchref_child]'
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

/*************************************
	Run both and check performance
*************************************/
SELECT c.batchref_parent
	,MAX(p.batchref) AS LatestBatch
FROM [NonSQLCollation].[batchref_child] AS c
	INNER JOIN [NonSQLCollation].[batchref_parent] AS p
	   ON c.batchref_parent = p.batchref_parent
GROUP BY c.batchref_parent


SELECT c.batchref_parent
	,MAX(p.batchref) AS LatestBatch
FROM [SQLCollation].[batchref_child] AS c
	INNER JOIN [SQLCollation].[batchref_parent] AS p
	   ON c.batchref_parent = p.batchref_parent
GROUP BY c.batchref_parent


/*******************************************************
	Force Serial plan to better understand the impact

	Run both and check performance
*******************************************************/
SELECT c.batchref_parent
	,MAX(p.batchref) AS LatestBatch
FROM [NonSQLCollation].[batchref_child] AS c
	INNER JOIN [NonSQLCollation].[batchref_parent] AS p
	   ON c.batchref_parent = p.batchref_parent
GROUP BY c.batchref_parent
OPTION (MAXDOP 1)


SELECT c.batchref_parent
	,MAX(p.batchref) AS LatestBatch
FROM [SQLCollation].[batchref_child] AS c
	INNER JOIN [SQLCollation].[batchref_parent] AS p
	   ON c.batchref_parent = p.batchref_parent
GROUP BY c.batchref_parent
OPTION (MAXDOP 1)


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


/**************************************
	Did it change anything?
	Yes, but just the plane shape

	Run both and check performance
**************************************/

SELECT c.batchref_parent
	,MAX(p.batchref) AS LatestBatch
FROM [NonSQLCollation].[batchref_child] AS c
	INNER JOIN [NonSQLCollation].[batchref_parent] AS p
	   ON c.batchref_parent = p.batchref_parent
GROUP BY c.batchref_parent


SELECT c.batchref_parent
	,MAX(p.batchref) AS LatestBatch
FROM [SQLCollation].[batchref_child] AS c
	INNER JOIN [SQLCollation].[batchref_parent] AS p
	   ON c.batchref_parent = p.batchref_parent
GROUP BY c.batchref_parent
