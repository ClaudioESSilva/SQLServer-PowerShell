/*
    PREVIEW_FEATURES !?
    What it will unlock? (Note: Not only VECTOR-related features)

    - ✅Half-precision (2-byte) vectors
    - ✅CREATE VECTOR INDEX
    - ✅VECTOR_SEARCH (Disk-aNN algorithm with VECTOR index - Old version of the index)

    ! Only for SQL Server on premises !

    Source: https://learn.microsoft.com/en-us/sql/sql-server/preview-features-faq?view=sql-server-ver17
*/
USE AdventureWorksLT
GO

DROP TABLE IF EXISTS [SalesLT].[ProductEmbeddings_HalfPercision]
GO

/*
    TRY to create a table with half-percision (2-byte) vector
*/
CREATE TABLE [SalesLT].[ProductEmbeddings_HalfPercision]
(
    ProductID INT PRIMARY KEY
  , embeddings VECTOR(768, float16)
  , chunk NVARCHAR(2000)
);
GO

/*
    Check the current running configuration
*/
SELECT * 
  FROM sys.database_scoped_configurations
 WHERE name = 'PREVIEW_FEATURES'

/*
    Turn it on
*/
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;

/*
    Create a table with half-percision (2-byte) vector
*/
CREATE TABLE [SalesLT].[ProductEmbeddings_HalfPercision]
(
    ProductID INT PRIMARY KEY
  , embeddings VECTOR(768, float16)
  , chunk NVARCHAR(2000)
);

INSERT INTO [SalesLT].[ProductEmbeddings_HalfPercision] (ProductID, chunk, embeddings)
SELECT   p.ProductID
       , p.Name + ' ' + ISNULL(p.Color, 'No Color') + ' ' + c.Name + ' ' + m.Name + ' ' + ISNULL(d.Description, '') AS chunk
       , AI_GENERATE_EMBEDDINGS(p.Name + ' ' + ISNULL(p.Color, 'No Color') + ' ' + c.Name + ' ' + m.Name + ' ' + ISNULL(d.Description, '') USE MODEL ollama) AS embeddings
FROM [SalesLT].[Product] AS p
    INNER JOIN [SalesLT].[ProductCategory] AS c
       ON p.ProductCategoryID = c.ProductCategoryID
    INNER JOIN [SalesLT].[ProductModel] AS m
       ON p.ProductModelID = m.ProductModelID
     LEFT OUTER JOIN [SalesLT].[vProductAndDescription] AS d
       ON p.ProductID = d.ProductID
      AND d.Culture = 'en';

-- Review the created embeddings
SELECT TOP 10
      pe.*
    , p.Name
  FROM [SalesLT].[ProductEmbeddings_HalfPercision] AS pe
    INNER JOIN [SalesLT].[Product] AS p
       ON pe.ProductID = p.ProductID;
GO

sp_help '[SalesLT].[ProductEmbeddings_HalfPercision]'
GO

/*
    Why is the "Length" = 1544?
*/
SELECT 768 /* Dimensions */
        * 
        2  /* Number of bytes - float(16) */
        + 
        8  /* Bytes of the header */
GO

sp_spaceused '[SalesLT].[ProductEmbeddings_HalfPercision]'
GO



/*
    Comparing table space between two vector float size.

    Double the space of the embedding
*/
sp_spaceused '[SalesLT].[ProductEmbeddings]'
GO
sp_spaceused '[SalesLT].[ProductEmbeddings_HalfPercision]'
GO


/*
        Half of the space. The percision of the vectors is different but in most 
    cases the results are similar. 
        It's a balance - test accordingly and compare results.
*/