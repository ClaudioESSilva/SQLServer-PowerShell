/* 
	What capabilities does it bring that were difficult or inefficient before?

	Text search VS FTS VS Semantic Search
*/
THROW 81920, 'Hey! Just don''t run everything!', 1
GO

USE [AdventureWorksLT]
GO

DROP TABLE IF EXISTS [SalesLT].[ProductBig]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SalesLT].[ProductBig]') AND type in (N'U'))
BEGIN
    CREATE TABLE [SalesLT].[ProductBig](
	    [ProductID] [int] IDENTITY(1,1) NOT NULL,
	    [Name] [dbo].[Name] NOT NULL,
	    [ProductNumber] [nvarchar](25) NOT NULL,
	    [Color] [nvarchar](15) NULL,
	    [StandardCost] [money] NOT NULL,
	    [ListPrice] [money] NOT NULL,
	    [Size] [nvarchar](5) NULL,
	    [Weight] [decimal](8, 2) NULL,
	    [ProductCategoryID] [int] NULL,
	    [ProductModelID] [int] NULL,
	    [SellStartDate] [datetime] NOT NULL,
	    [SellEndDate] [datetime] NULL,
	    [DiscontinuedDate] [datetime] NULL,
	    [ThumbNailPhoto] [varbinary](max) NULL,
	    [ThumbnailPhotoFileName] [nvarchar](50) NULL,
	    [rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	    [ModifiedDate] [datetime] NOT NULL
    CONSTRAINT [PK_ProductBig_ProductID] PRIMARY KEY CLUSTERED 
    (
	    [ProductID] ASC
    )
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO

SET IDENTITY_INSERT [SalesLT].[ProductBig] ON

INSERT INTO [SalesLT].[ProductBig]([ProductID], [Name], [ProductNumber], [Color], [StandardCost], [ListPrice], [Size], [Weight], [ProductCategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [ThumbNailPhoto], [ThumbnailPhotoFileName], [rowguid], [ModifiedDate])
SELECT [ProductID], [Name], [ProductNumber], [Color], [StandardCost], [ListPrice], [Size], [Weight], [ProductCategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [ThumbNailPhoto], [ThumbnailPhotoFileName], [rowguid], [ModifiedDate]
  FROM [SalesLT].[Product]

SET IDENTITY_INSERT [SalesLT].[ProductBig] OFF
GO


INSERT INTO [SalesLT].[ProductBig]([Name], [ProductNumber], [Color], [StandardCost], [ListPrice], [Size], [Weight], [ProductCategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [ThumbNailPhoto], [ThumbnailPhotoFileName], [rowguid], [ModifiedDate])
SELECT [Name], [ProductNumber], [Color], [StandardCost], [ListPrice], [Size], [Weight], [ProductCategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [ThumbNailPhoto], [ThumbnailPhotoFileName], [rowguid], [ModifiedDate]
  FROM [SalesLT].[Product]
GO 100


/*
	Check if you have FullText installed
*/
SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled')
GO


CREATE FULLTEXT CATALOG ft AS DEFAULT;
GO

CREATE FULLTEXT INDEX ON [SalesLT].[ProductBig]
(
	[Name]
)
KEY INDEX PK_ProductBig_ProductID
GO



/*
	Find Products that contain "650" in their name
*/
SELECT * 
  FROM [SalesLT].[ProductBig]
 WHERE Name LIKE '%650%'
GO

/*
	Use Full-text search to find Products that contain "650" in their name
*/
SELECT * 
  FROM [SalesLT].[ProductBig]
 WHERE CONTAINS(Name, '*650*')
GO



/*
-- 
--	Done upfront because it takes some time
-- 

CREATE TABLE [SalesLT].[ProductBigEmbeddings]
(
    [ProductID] [int] NOT NULL ,
	[ProductEmbedding] [vector](768) NULL,
	CONSTRAINT [PK_ProductBigEmbeddings_ProductID] PRIMARY KEY CLUSTERED 
    (
	    [ProductID] ASC
    )
)
GO

INSERT INTO [SalesLT].[ProductBigEmbeddings] ([ProductID], [ProductEmbedding])
SELECT p.[ProductID], AI_GENERATE_EMBEDDINGS(p.[Name] USE MODEL ollama)
FROM [SalesLT].[ProductBig] AS p
WHERE NOT EXISTS (SELECT 1
					FROM [SalesLT].[ProductBigEmbeddings] AS PBE
				   WHERE p.[ProductID] = PBE.[ProductID]
				 )
*/
-- sp_help '[SalesLT].[ProductBigEmbeddings]'
-- sp_spaceused '[SalesLT].[ProductBigEmbeddings]'



/*
	Do a search using semantic search

	NOTE: This will need to scan the entire table
*/
DECLARE @search_text NVARCHAR(MAX) = '650'
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);

SELECT PB.*,
		VECTOR_DISTANCE('cosine', @search_vector, [ProductEmbedding]) AS distance
FROM [SalesLT].[ProductBigEmbeddings] AS PBE
	INNER JOIN [SalesLT].[ProductBig] AS PB
	ON PBE.ProductID = PB.ProductID
WHERE VECTOR_DISTANCE('cosine', @search_vector, [ProductEmbedding]) < 0.32
ORDER BY distance ASC
GO





/*
	Comparing the results of the 3 queries
*/

/*
	Regular like search
*/
SELECT * 
  FROM [SalesLT].[ProductBig]
 WHERE Name LIKE '%Sleeve%'
GO

/*
	Use Full-text search to find Products that contain "650" in their name
*/
SELECT * 
  FROM [SalesLT].[ProductBig]
 WHERE CONTAINS (Name, '*Sleeve*')
GO


/*
	What about semantic search?
*/
DECLARE @search_text NVARCHAR(MAX) = 'Sleeve'
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);

SELECT PB.*,
		VECTOR_DISTANCE('cosine', @search_vector, [ProductEmbedding]) AS distance
  FROM [SalesLT].[ProductBigEmbeddings] AS PBE
	INNER JOIN [SalesLT].[ProductBig] AS PB
	   ON PBE.ProductID = PB.ProductID
-- WHERE VECTOR_DISTANCE('cosine', @search_vector, [ProductEmbedding]) < 0.41 /* Uncomment so we get the same number of results as previous queries */
ORDER BY distance ASC
GO

/*
	The whole table because we aren't filtering by the calculated distance
*/





/*
	Remember the main question?
		- What capabilities does it bring that were difficult or inefficient before?

	If we have semantic search why try to get the exact words?!
*/
DECLARE @search_text NVARCHAR(MAX) = 'Male clothes'
DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);

SELECT PB.*,
		VECTOR_DISTANCE('cosine', @search_vector, [ProductEmbedding]) AS distance
FROM [SalesLT].[ProductBigEmbeddings] AS PBE
	INNER JOIN [SalesLT].[ProductBig] AS PB
	ON PBE.ProductID = PB.ProductID
-- WHERE VECTOR_DISTANCE('cosine', @search_vector, [ProductEmbedding]) < 0.4 /* Uncomment so we get the closer results */
ORDER BY distance ASC
GO