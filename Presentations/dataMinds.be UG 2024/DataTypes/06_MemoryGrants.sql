/*
	Memory grants

	Max of 25% of the 75% of the Max Memory configuration
	Example:
		With 4 GB of RAM as Max Memory * 75% = 3GB
		3GB * 25% = 0.75 GB or ~750MB
*/
USE DataTypes
GO

/*
	Check memory grant size of each query

	Turn ON "Discard results"
*/ 
SELECT UUID, DoB
  FROM ExcessiveDataTypesAndSizes
 WHERE ID <= 2000000
ORDER BY UUID
OPTION(RECOMPILE)


SELECT UUID, DoB
  FROM LessExcessiveDataTypesAndSizes
 WHERE ID <= 2000000
ORDER BY UUID
OPTION(RECOMPILE)


SELECT UUID, DoB
  FROM BetterDataTypesAndSizes
 WHERE ID <= 2000000
ORDER BY UUID
OPTION(RECOMPILE)














/*
	Go back and check execution times too!
*/









/*
	Show on SQLQueryStress
	- Monitor using sp_WhoIsActive
	- Show the WAIT TYPE
*/
















/*
	Parallelism also request more memory
*/
SELECT UUID, DoB
  FROM BetterDataTypesAndSizes
 WHERE ID <= 2000000
ORDER BY UUID
OPTION(RECOMPILE)

SELECT UUID, DoB
  FROM BetterDataTypesAndSizes
 WHERE ID <= 2000000
ORDER BY UUID
OPTION(RECOMPILE, MAXDOP 1)



/*
	One way to check how Memory Grant is impacted by data types

	Turn OFF "Discard results"
*/
DROP TABLE IF EXISTS MemoryGrant
GO
CREATE TABLE MemoryGrant
(
	id				int IDENTITY(1,1) PRIMARY KEY,
	number			int,
	description500	varchar(500),
	description4000	varchar(4000),
	descriptionMAX	varchar(MAX)
)

INSERT INTO  MemoryGrant (number, description4000, description500, descriptionMAX)
SELECT TOP(3000) a.column_id, a.name, a.name, NULL
FROM sys.columns AS a
GO

SELECT id, description500
FROM MemoryGrant
ORDER BY number

SELECT id, description4000
FROM MemoryGrant
ORDER BY number

SELECT id, descriptionMAX
FROM MemoryGrant
ORDER BY number

SELECT *
FROM MemoryGrant
ORDER BY number










