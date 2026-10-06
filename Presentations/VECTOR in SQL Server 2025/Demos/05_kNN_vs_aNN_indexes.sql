/* 
	Being a new data type, can VECTOR columns be indexed, and how/why might that change the results?

	And, how does it impact table design?
*/


/*
	- Before March 2026 (All flavours):
        - Table will become read-only 
            - A special note to ALLOW_STALE_VECTOR_INDEX database scoped-configuration
                - Azure only - Couldn't be used on premises 😅
	

    - After - Since March 18th 2026 - Azure:
        - No longer the case on Azure SQL DB - https://devblogs.microsoft.com/azure-sql/diskann-vector-index-improvements/
            - Full DML support – Tables are no longer read‑only after index creation
            - Iterative filtering – Filters are applied during vector search, not after (no more manual TOP_N hints needed)
            - Smarter optimizer – Automatically chooses between DiskANN and exact KNN
            - Improved quantization – Faster builds and better search quality

    - kNN - Exact search, also known as k-nearest neighbor
        vs 
      DiskANN (approximate nearest neighbor) - a graph-based system for indexing and searching large sets of vector data using limited computational resources.
      (https://www.microsoft.com/en-us/research/publication/diskann-fast-accurate-billion-point-nearest-neighbor-search-on-a-single-node/)        

      More: https://learn.microsoft.com/en-us/sql/sql-server/ai/vectors?view=sql-server-ver17
*/
THROW 81920, 'Hey! Just don''t run everything!', 1
GO


USE [AdventureWorksLT]
GO

/* 
    Let's try to update a table with a VECTOR index 

    Remember I'm using SQL Server on-premesis 
*/
DROP TABLE IF EXISTS [SalesLT].[ProductBigEmbeddingsNotUpdatable]
GO

CREATE TABLE [SalesLT].[ProductBigEmbeddingsNotUpdatable]
(
    [ProductID] [bigint] NOT NULL,
    [Comments] [varchar](50) NULL,
	[ProductEmbedding] [vector](768) NULL,
	CONSTRAINT [PK_ProductBigEmbeddingsNotUpdatable_ProductID] PRIMARY KEY CLUSTERED 
    (
	    [ProductID] ASC
    )
)
GO


INSERT INTO [SalesLT].[ProductBigEmbeddingsNotUpdatable] ([ProductID], [ProductEmbedding])
SELECT p.[ProductID], [ProductEmbedding]
FROM [SalesLT].[ProductBigEmbeddings] AS p
WHERE NOT EXISTS (SELECT 1
					FROM [SalesLT].[ProductBigEmbeddingsNotUpdatable] AS PBE
				   WHERE p.[ProductID] = PBE.[ProductID]
				 )
            
/* 
    Error?!

    Only on premises!

    Fix on table creation and rerun this.
*/
CREATE VECTOR INDEX vec_idx_ProductBigEmbeddingsNotUpdatable ON [SalesLT].[ProductBigEmbeddingsNotUpdatable] 
(
    ProductEmbedding
)
WITH 
(
    METRIC = 'cosine', 
    TYPE = 'DISKANN'
);
GO

/*
    Now our table is read-only!
    Trying to do DML operations will result in an error
*/
UPDATE [SalesLT].[ProductBigEmbeddingsNotUpdatable] 
SET [ProductID] = 1000000
WHERE [ProductID] = 1
GO


/*
    Compare the execution plans
*/

DECLARE @search_text NVARCHAR(MAX) = '650'
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);


SELECT VECTOR_DISTANCE('cosine', @search_vector, [ProductEmbedding]) AS distance,
        PB.*
FROM [SalesLT].[ProductBigEmbeddings] AS PBE
	INNER JOIN [SalesLT].[ProductBig] AS PB
	ON PBE.ProductID = PB.ProductID
WHERE VECTOR_DISTANCE('cosine', @search_vector, [ProductEmbedding]) < 0.32
ORDER BY distance ASC



SELECT TOP (1500) 
		s.distance, 
        PB.*
FROM [SalesLT].[ProductBig] AS PB
INNER JOIN VECTOR_SEARCH(
                TABLE      = [SalesLT].[ProductBigEmbeddings] AS PBE,
                COLUMN     = [ProductEmbedding],
                SIMILAR_TO = @search_vector,
                METRIC     = 'cosine',
				TOP_N	   = 1500
            ) AS s
ON PBE.ProductID = PB.ProductID
WHERE s.distance < 0.32
GO

/*
    A couple of things to notice when we have a VECTOR index
        - DiskANN relies on creating a graph to navigate quickly through all the indexed vectors to find the closest match to a given vector.
*/















/*
    On Azure make sure you use the newer syntax!

    Before (Post-Filtering)	                                            New Version (Iterative Filtering)
    ---------------------------------------------------------------------------------------------------------------------
    The Problem: Filtering happened after retrieving vectors	        The Solution: Filtering happens during the search
    You had to over-fetch and hope enough matched	                    You get exactly the number of results requested
    ----------------------------------------------------------------------------------------------------------------------
    Result: Maybe 10 results, maybe 3, maybe 0                          Result: Exactly 10 Technology articles
    Had to guess how many to fetch (TOP_N = 20? 100?)                   No guessing needed
*/
/*
    OLD
*/
SELECT TOP (1500) 
		s.distance, PB.*
FROM [SalesLT].[ProductBig] AS PB
INNER JOIN VECTOR_SEARCH(
                TABLE      = [SalesLT].[ProductBigEmbeddings] AS PBE,
                COLUMN     = [ProductEmbedding],
                SIMILAR_TO = @search_vector,
                METRIC     = 'cosine',
				TOP_N	   = 1500 -- Over-fetch!
            ) AS s
ON PBE.ProductID = PB.ProductID
WHERE s.distance < 0.32
GO


/*
    vs NEWER
*/
SELECT TOP (1500) WITH APPROXIMATE
		s.distance, PB.*
FROM [SalesLT].[ProductBig] AS PB
INNER JOIN VECTOR_SEARCH(
                TABLE      = [SalesLT].[ProductBigEmbeddings] AS PBE,
                COLUMN     = [ProductEmbedding],
                SIMILAR_TO = @search_vector,
                METRIC     = 'cosine'
                /* No more TOP_N here */
            ) AS s
ON PBE.ProductID = PB.ProductID
WHERE s.distance < 0.32


















/*
    This means we may have different versions of VECTOR indexes!
    If I'm not sure, how do I check that?
*/


USE AdventureWorksLT
GO

/*
    Which version of the VECTOR index do we have?
    Source: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-vector-index-transact-sql?view=sql-server-ver17#migrating-from-earlier-vector-index-versions

    On premises it will show NULL. But, we don't have yet the new goodies!
*/
SELECT
    i.name AS index_name,
    t.name AS table_name,
    v.build_parameters,
    JSON_VALUE(v.build_parameters, '$.Version') AS index_version,
    CASE
        WHEN JSON_VALUE(v.build_parameters, '$.Version') >= '3'
            THEN 'Uses latest version (no migration required)'
        WHEN JSON_VALUE(v.build_parameters, '$.Version') < '3'
            THEN 'Created using an earlier version (migration recommended)'
        ELSE 'Unknown format'
    END AS migration_status
FROM sys.vector_indexes AS v
    INNER JOIN sys.indexes AS i
        ON v.object_id = i.object_id
        AND v.index_id = i.index_id
    INNER JOIN sys.tables AS t
        ON v.object_id = t.object_id
ORDER BY t.name, i.name;

/*
How to interpret the results

    Uses latest version
        - Already supports iterative filtering, full DML support, optimizer-driven execution and improved quantization
        - No migration required

    Created using an earlier version
        - Uses legacy post-filter behavior
        - Doesn't support the latest vector search capabilities
        - Migration is strongly recommended to ensure future compatibility
*/







/*

    For people already using VECTOR data types with INDEXES

    Important:

        Service impact: Dropping a vector index immediately disables approximate vector search on the 
    affected table until the index is recreated. 
        Plan migrations during maintenance windows for production systems.

     Source: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-vector-index-transact-sql?view=sql-server-ver17#step-2-drop-and-recreate-the-vector-index
*/

/*
    Basically queries using VECTOR_SEARCH() function will stop working.
    
    Example:
        Drop the VECTOR index and try to run a query using VECTOR_SEARCH()

    This is important to notice because with other in-row indexes the query will rebuild the plan and "default" to a different index/heap.
    Not here (and that makes sense)
*/

DECLARE @search_text NVARCHAR(MAX) = '650'
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);

SELECT TOP (1500) 
		s.distance, PB.*
FROM [SalesLT].[ProductBig] AS PB
INNER JOIN VECTOR_SEARCH(
                TABLE      = [SalesLT].[ProductBigEmbeddingsNotUpdatable] AS PBE,
                COLUMN     = [ProductEmbedding],
                SIMILAR_TO = @search_vector,
                METRIC     = 'cosine',
				TOP_N	   = 1500
            ) AS s
ON PBE.ProductID = PB.ProductID
GO


/*
    Let's drop the index and test again
*/
DROP INDEX vec_idx_ProductBigEmbeddingsNotUpdatable ON [SalesLT].[ProductBigEmbeddingsNotUpdatable] 
GO

DECLARE @search_text NVARCHAR(MAX) = '650'
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);

SELECT TOP (1500) 
		s.distance, PB.*
FROM [SalesLT].[ProductBig] AS PB
INNER JOIN VECTOR_SEARCH(
                TABLE      = [SalesLT].[ProductBigEmbeddingsNotUpdatable] AS PBE,
                COLUMN     = [ProductEmbedding],
                SIMILAR_TO = @search_vector,
                METRIC     = 'cosine',
				TOP_N	   = 1500
            ) AS s
ON PBE.ProductID = PB.ProductID
GO

/*
    Contrary to the in-row indexing, if a VECTOR index doesn't exist, VECTOR_SEARCH can't default anything else
*/











/*
    Newer version of the VECTOR index should use newer syntax
	Only works with the newer VECTOR index versions!
*/
SELECT TOP (1500) WITH APPROXIMATE
		s.distance, PB.*
FROM [SalesLT].[ProductBig] AS PB
INNER JOIN VECTOR_SEARCH(
                TABLE      = [SalesLT].[ProductBigEmbeddings] AS PBE,
                COLUMN     = [ProductEmbedding],
                SIMILAR_TO = @search_vector,
                METRIC     = 'cosine'
            ) AS s
ON PBE.ProductID = PB.ProductID
WHERE s.distance < 0.32