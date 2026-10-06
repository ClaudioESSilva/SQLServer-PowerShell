/* 
	How does it impact table design?
*/
USE AdventureWorksLT
GO

/*
    Create a new table to hold the embeddings.
    Keep the PK of the main table so you can JOIN and link back.
*/
CREATE TABLE [SalesLT].[ProductEmbeddings]
(
    ProductID INT PRIMARY KEY
  , embeddings VECTOR(768)
  , chunk NVARCHAR(2000)
);

INSERT INTO [SalesLT].[ProductEmbeddings] (ProductID, chunk, embeddings)
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
  FROM [SalesLT].[ProductEmbeddings] AS pe
    INNER JOIN [SalesLT].[Product] AS p
       ON pe.ProductID = p.ProductID;
GO










/*
    How does it look like?
*/
sp_help '[SalesLT].[ProductEmbeddings]'
GO

























/*
    Why is the "Length" = 3080?
*/
SELECT 768 /* Dimensions */
        * 
        4  /* Number of bytes - float(32) */
        + 
        8  /* Bytes of the header */
GO

sp_spaceused '[SalesLT].[ProductEmbeddings]'
GO








/*
	Check the content of a page
*/
SELECT * 
  FROM sys.dm_db_database_page_allocations(DB_ID('AdventureWorksLT'), OBJECT_ID(N'SalesLT.ProductEmbeddings'), NULL, NULL, N'Limited')

-- OR 
DBCC IND ('AdventureWorksLT', 'SalesLT.ProductEmbeddings', -1);
GO

/*
    Pick a allocated_page_page_id value to see the contents of the page
*/
DBCC TRACEON (3604);
GO
DBCC PAGE (N'AdventureWorksLT', 1, 1242, 3);
GO






/*
    Create a new table to hold the embeddings.
    Keep the PK of the main table so you can JOIN and link back.

    ~25 seconds
*/
USE [AdventureWorksLT]
GO

DROP TABLE IF EXISTS [SalesLT].[ProductWithEmbedding]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SalesLT].[ProductWithEmbedding]') AND type in (N'U'))
BEGIN
    CREATE TABLE [SalesLT].[ProductWithEmbedding](
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
	    [ModifiedDate] [datetime] NOT NULL,
        [embeddings] [vector](768)
    CONSTRAINT [PK_ProductWithEmbedding_ProductID] PRIMARY KEY CLUSTERED 
    (
	    [ProductID] ASC
    )
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO

SET IDENTITY_INSERT [SalesLT].[ProductWithEmbedding] ON

INSERT INTO [SalesLT].[ProductWithEmbedding]([ProductID], [Name], [ProductNumber], [Color], [StandardCost], [ListPrice], [Size], [Weight], [ProductCategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [ThumbNailPhoto], [ThumbnailPhotoFileName], [rowguid], [ModifiedDate])
SELECT [ProductID], [Name], [ProductNumber], [Color], [StandardCost], [ListPrice], [Size], [Weight], [ProductCategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [ThumbNailPhoto], [ThumbnailPhotoFileName], [rowguid], [ModifiedDate]
  FROM [SalesLT].[Product]

SET IDENTITY_INSERT [SalesLT].[ProductWithEmbedding] OFF
GO


/*
    Generate the embeddings
*/
UPDATE [SalesLT].[ProductWithEmbedding]
   SET [embeddings] = AI_GENERATE_EMBEDDINGS(p.Name + ' ' + ISNULL(p.Color, 'No Color') + ' ' + c.Name + ' ' + m.Name + ' ' + ISNULL(d.Description, '') USE MODEL ollama)
FROM [SalesLT].[ProductWithEmbedding] AS p
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
  FROM [SalesLT].[ProductWithEmbedding] AS pe
GO

/*
    How does it look like?
*/
sp_help '[SalesLT].[ProductWithEmbedding]'
GO

sp_help '[SalesLT].[Product]'
GO


sp_spaceused '[SalesLT].[ProductWithEmbedding]'
GO

sp_spaceused '[SalesLT].[Product]'
GO


/*
    SET STATISTICS TIME, IO ON
    <Turn on Actual Execution Plan>
*/
SELECT ProductId
FROM [SalesLT].[Product]
WHERE Color = N'Red'

SELECT ProductId
FROM [SalesLT].[ProductWithEmbedding]
WHERE Color = N'Red'

/*
    sp_tableoption doesn't work for VECTOR data type
    NOTE:
        - This option, on tables with LOB_DATA, can be highly beneficial for DWH/reporting scenarios 
        where you perform frequent index scans on the non-LOB columns.
        - Why? Because more rows will fit in a single 8KB page.
*/
EXECUTE sp_tableoption '[SalesLT].[ProductWithEmbedding]', 'large value types out of row', 1;



/*
    Observations:
        - We can't offload the VECTOR data the same way we can with LOB (using: sp_tableoption)
        - Offloading the embeddings to another table will make possible not touching all the data when reading original's table CI
        - On premesis creating a VECTOR index will still make your table read-only. ( We are at the beginning of October 2026)
*/