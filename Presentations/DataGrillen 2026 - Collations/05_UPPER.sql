/*
	Turn on STATISTICS TIME and IO
	Turn on "Include Actual Execution Plan"

	SET STATISTICS TIME, IO ON
*/

-- Clean index if exists
DROP INDEX [batchref_parent_idx_1] ON [NonSQLCollation].[batchref_child]
GO
DROP INDEX [batchref_parent_idx_1] ON [SQLCollation].[batchref_child]
GO

SELECT TOP 20 * FROM [NonSQLCollation].[batchref_child]

SELECT COUNT(1) AS RecordsFound
FROM [NonSQLCollation].[batchref_child] AS c
WHERE LOWER(batchref_parent) = LOWER('0x522A7FE6A3296322E273A65B0FFCDBF5301BE6050EBA3BF7A01FD9AA4D455CEE')


SELECT COUNT(1) AS RecordsFound
FROM [SQLCollation].[batchref_child] AS c
WHERE LOWER(batchref_parent) = LOWER('0x522A7FE6A3296322E273A65B0FFCDBF5301BE6050EBA3BF7A01FD9AA4D455CEE')
