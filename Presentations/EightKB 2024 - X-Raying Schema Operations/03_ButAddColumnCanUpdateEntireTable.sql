/********************************************************************************
	DEMO: Adding a null/not null column can update the entire table... even on
	      Enterprise Edition

	My brain: SAY WHAT?! ??
********************************************************************************/

/* Just don't run everything */
THROW 81920, 'Hey! Just don''t run everything. ??', 1
GO

USE XRaying
GO

DROP TABLE IF EXISTS dbo.Client
GO

CREATE TABLE dbo.Client 
(
	Id			int			NOT NULL IDENTITY(1,1) PRIMARY KEY,
	FirstName	varchar(30) NULL,
	DoB			date		NULL,
	JobTitle	varchar(30) NULL,
	Bio			char(7992)	NULL
);
GO

/* Insert some data */
INSERT INTO dbo.Client (FirstName, DoB, JobTitle, Bio) 
VALUES 
		(REPLICATE('A', 15), '1990-01-01', REPLICATE('A', 15), 'Hello, I''m Alex'),
		(REPLICATE('B', 15), '1990-01-01', REPLICATE('B', 15), 'Hello, I''m Brad'),
		(REPLICATE('C', 15), '1990-01-01', REPLICATE('C', 15), 'Hello, I''m Christina'),
		(REPLICATE('G', 30), '1990-01-01', REPLICATE('G', 30), 'Hello, I''m Gabriel'),
		(REPLICATE('H', 30), '1990-01-01', REPLICATE('H', 30), 'Hello, I''m Helena'),
		(REPLICATE('I', 30), '1990-01-01', REPLICATE('I', 30), 'Hello, I''m Irina')
GO

DBCC IND ('XRaying', 'dbo.Client', 1);
GO

DBCC TRACEON (3604);
GO
DBCC PAGE (N'XRaying', 1, 1025843, 3);
GO

/* Add a new column */
ALTER TABLE dbo.Client 
  ADD AnotherInt int NOT NULL DEFAULT(0);
GO












/*
	But why?
	Let's take a look at one of the last 3 records
*/
DBCC PAGE (N'XRaying', 1, 1025844, 3);
GO


/* Remove records that occupy the 8060 bytes */
DELETE
  FROM dbo.Client
 WHERE Id >= 4
GO


/* Try to add the new column again */
ALTER TABLE dbo.Client 
  ADD AnotherInt int NOT NULL DEFAULT(0);
GO

/* Check the contents */
DBCC TRACEON (3604);
GO
DBCC PAGE (N'XRaying', 1, 1025842, 3);
GO



/*
	Bottom line: 
		When the engine detects that by adding a column, a record can exceed the 8060 bytes,
		it will update every record to make sure that doesn't happen.
	
		If it really happens, it's aborted and rollback.
*/


/* 
	Insert a new record that will exceed the 8060 to show the error message 
*/
INSERT INTO dbo.Client (FirstName, DoB, JobTitle, Bio) 
VALUES (REPLICATE('I', 30), '1990-01-01', REPLICATE('I', 30), 'Hello, I''m Irina')
GO

















/*
	It can take time to fail, tho
*/
DROP TABLE IF EXISTS dbo.ClientFailSlow
GO

CREATE TABLE dbo.ClientFailSlow
(
	Id			int			NOT NULL IDENTITY(1,1) PRIMARY KEY,
	FirstName	varchar(30)	NULL,
	DoB			date		NULL,
	JobTitle	varchar(30)	NULL,
	Bio			char(7992)	NULL
);
GO

/* Insert some data */
;WITH
    L0 AS ( SELECT 1 AS c 
            FROM (VALUES(1),(1),(1),(1),(1),(1),(1),(1),
                        (1),(1),(1),(1),(1),(1),(1),(1)) AS D(c) ),
    L1 AS ( SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B ),
    L2 AS ( SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B ),
    L3 AS ( SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B ),
    Nums AS ( SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum
              FROM L3 
			)
	INSERT INTO dbo.ClientFailSlow (FirstName, DoB, JobTitle, Bio)
	SELECT TOP (500000) REPLICATE('C', 15), '1990-01-01', REPLICATE('F', 15), 'Hello, I''m Christina'
	  FROM Nums
GO

/*
	SHOWCONTIG: 
		Displays fragmentation information for the data and indexes of the specified table or view.

	Check maximum record size
*/
DBCC SHOWCONTIG('dbo.ClientFailSlow') WITH TABLERESULTS
GO

/*
	Insert one record that will make the adition of the column fail.
	This record will be at the end of the table
*/
INSERT INTO dbo.ClientFailSlow (FirstName, DoB, JobTitle, Bio) 
VALUES (REPLICATE('I', 30), '1990-01-01', REPLICATE('I', 30), 'Hello, I''m Irina')
GO

/*
	Check maximum record size, again...
*/
DBCC SHOWCONTIG('dbo.ClientFailSlow') WITH TABLERESULTS
GO

/* 
	Try to add a new column
	Check the tlog writes going up on sp_WhoIsActive
*/
ALTER TABLE dbo.ClientFailSlow
  ADD AnotherInt int NULL;
GO

/*
	Takes some time (just for 500000 records) until it fails.
	A rollback happens and the column wasn't added.
*/


















/*
	How to solve this?
	You need to make sure you record cannot surpass the 8060 bytes on the page
*/
DROP TABLE IF EXISTS dbo.ClientSmallerBio
GO

CREATE TABLE dbo.ClientSmallerBio 
(
	Id			int			NOT NULL IDENTITY(1,1) PRIMARY KEY,
	FirstName	varchar(30) NULL,
	DoB			date		NULL,
	JobTitle	varchar(30) NULL,
	Bio			char(7988)	NULL
);
GO

/*
	50000 records
*/
;WITH
    L0 AS ( SELECT 1 AS c 
            FROM (VALUES(1),(1),(1),(1),(1),(1),(1),(1),
                        (1),(1),(1),(1),(1),(1),(1),(1)) AS D(c) ),
    L1 AS ( SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B ),
    L2 AS ( SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B ),
    L3 AS ( SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B ),
    Nums AS ( SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum
              FROM L3 
			)
	INSERT INTO dbo.ClientSmallerBio (FirstName, DoB, JobTitle, Bio)
	SELECT TOP (50000) REPLICATE('I', 30), '1990-01-01', REPLICATE('I', 30), 'Hello, I''m Irina'
	  FROM Nums
GO

/*
	Check maximum record size
*/
DBCC SHOWCONTIG('dbo.ClientSmallerBio') WITH TABLERESULTS
GO

/*
	Try to add an int (4 bytes) and it is quick (Developer/Enterprise)
*/
ALTER TABLE dbo.ClientSmallerBio 
  ADD AnotherInt int NOT NULL DEFAULT(0);
GO

/*
	Check maximum record size again
*/
DBCC SHOWCONTIG('dbo.ClientSmallerBio') WITH TABLERESULTS
GO


/*
	Show the column on the data page
*/
DBCC IND ('XRaying', 'dbo.ClientSmallerBio', 1);
GO

DBCC TRACEON (3604);
GO
DBCC PAGE (N'XRaying', 1, 1031256, 3);
GO


/*
	Just few metadata for now
*/
SELECT 
	p.index_id, 
	p.partition_number, 
	pc.leaf_null_bit,
	coalesce(cx.name, c.name) as column_name,
	pc.partition_column_id,
	pc.modified_count,
	pc.is_nullable,
	pc.max_length,
	pc.has_default,
	pc.default_value
  FROM sys.system_internals_partitions p
	JOIN sys.system_internals_partition_columns pc
	  ON p.partition_id = pc.partition_id
	LEFT JOIN sys.index_columns ic
	  ON p.object_id = ic.object_id
	 AND ic.index_id = p.index_id
	 AND ic.index_column_id = pc.partition_column_id
	LEFT JOIN sys.columns c
	  ON p.object_id = c.object_id
	 AND ic.column_id = c.column_id	
	LEFT JOIN sys.columns cx
	  ON p.object_id = cx.object_id	
	 AND p.index_id in (0,1)
	 AND pc.partition_column_id = cx.column_id
 WHERE p.object_id = object_id('dbo.ClientSmallerBio')
ORDER BY index_id, partition_number;
GO




/*
	But the sum of the max length doesn't match the 8060?!

	Let's do some math!
*/
SELECT 4 + 30 + 3 + 30 + 7988 + 4
/* 8059 */







/*
	Source: https://learn.microsoft.com/en-us/sql/relational-databases/databases/estimate-the-size-of-a-clustered-index?view=sql-server-ver16
	
	1. Specify the number of rows that will be present in the table:

		Num_Rows = number of rows in the table

	2. Specify the number of fixed-length and variable-length columns and calculate the space that is required for their storage:

		Calculate the space that each of these groups of columns occupies within the data row. The size of a column depends on the data type and length specification.
			Num_Cols = total number of columns (fixed-length and variable-length)
			Fixed_Data_Size = total byte size of all fixed-length columns
			Num_Variable_Cols = number of variable-length columns
			Max_Var_Size = maximum byte size of all variable-length columns

	3. If the clustered index is non-unique (NOT OUR CASE HERE), account for the uniqueifier column:

		The uniqueifier is a nullable, variable-length column. It will be non-null and 4 bytes in size in rows that have non-unique key values. 
		This value is part of the index key and is required to make sure that every row has a unique key value.

		Num_Cols = Num_Cols + 1
		Num_Variable_Cols = Num_Variable_Cols + 1
		Max_Var_Size = Max_Var_Size + 4
		These modifications assume that all values will be non-unique.

	4. Part of the row, known as the null bitmap, is reserved to manage column nullability. Calculate its size:
		Null_Bitmap = 2 + ((Num_Cols + 7) / 8)

		Null_Bitmap = 2 + ((5 + 7) / 8)
		Null_Bitmap = 3 (discard any remainder)

	5. Calculate the variable-length data size:
		Variable_Data_Size = 2 + (Num_Variable_Cols x 2) + Max_Var_Size
		
		Variable_Data_Size = 2 + (2 x 2) + 60
		Variable_Data_Size = 66

		NOTE: The bytes added to Max_Var_Size are for tracking each variable-length column. 
		This formula assumes that all variable-length columns are 100 percent full. 
		If you anticipate that a smaller percentage of the variable-length column storage 
		space will be used, you can adjust the Max_Var_Size value by that percentage to yield 
		a more accurate estimate of the overall table size.

	6. Calculate the total row size:
		Row_Size = Fixed_Data_Size + Variable_Data_Size + Null_Bitmap + 4
		
		NOTE: The value 4 in the formula is the row header overhead of the data row.

		Fixed_Data_Size = 4 (int) + 3 (date) + 7988 (char) + 4 (int)

		Row_Size = 7999 + 66 + 3 + 4
		Row_Size = 8072 ???

		When it exceeds the 8060 the variable length ones occupy a fixed 24 bytes (pointer to ROW_OVERFLOW):
			24 bytes * 2 columns = 48
			48 + 6 = 54

		Row_Size = 7999 + 54 + 3 + 4
		Row_Size = 8060
		
	7. Calculate the number of rows per page (8096 free bytes per page):
		Rows_Per_Page = 8096 / (Row_Size + 2)

		Rows_Per_Page = 8096 / (8060 + 2)
		Rows_Per_Page = 1.004

		Because rows do not span pages, the number of rows per page should be rounded down to the nearest whole row. 
		The value 2 in the formula is for the row's entry in the slot array of the page.


	Important! This does not consider:
		- Partitioning
		- Allocation pages
		- Large object (LOB) values
		- Compression
		- Sparse columns
*/


/*
	Show the ROW_OVERFLOW_DATA allocations
	Because it's quicker (with 'Limited') to return all results	
*/
SELECT *
  FROM sys.dm_db_database_page_allocations(DB_ID('XRaying'), OBJECT_ID(N'dbo.ClientSmallerBio'), NULL, NULL, N'Limited')
GO

/*
	Show the pointer to the ROW_OVERFLOW_DATA
*/
DBCC TRACEON (3604);
GO
DBCC PAGE (N'XRaying', 1, 1031256, 3);
GO


SELECT *
  FROM sys.dm_db_database_page_allocations(DB_ID('XRaying'), OBJECT_ID(N'dbo.ClientSmallerBio'), NULL, NULL, N'Limited')
 WHERE allocated_page_page_id = 1059529
GO

/*
	The "blob Id:" is the link
*/
DBCC PAGE (N'XRaying', 1, 1059529, 3);
GO






