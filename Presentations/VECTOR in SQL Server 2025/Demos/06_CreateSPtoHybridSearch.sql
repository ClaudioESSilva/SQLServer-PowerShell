/*
    sp_help '[SalesLT].[ProductEmbeddings]'
*/

/*
    Create a FTS index based on chunk column on the same table as the embeddings
*/
CREATE FULLTEXT INDEX ON [SalesLT].[ProductEmbeddings]
(
	[chunk]
)
KEY INDEX PK__ProductE__B40CC6EDA6760C58
GO


CREATE OR ALTER PROCEDURE HybridSearchProducts
/*
    Example: https://devblogs.microsoft.com/azure-sql/enhancing-search-capabilities-in-sql-server-and-azure-sql-with-hybrid-search-and-rrf-re-ranking/

    Hybrid Search: Full-Text + Vector with Reciprocal Rank Fusion
    Requires: SQL Server 2025 / Azure SQL Database
      - Full-Text index on the target column (e.g. [ProductEmbedding])
      - Vector index on the embedding column (e.g. [embedding])
*/

    @search_text  NVARCHAR(4000) = N'Male clothes',
    @topN         INT           = 20,   -- final result depth
    @productsN    INT           = 50,   -- results per retriever
    @k            FLOAT         = 60.0  -- RRF constant (standard default)
AS
  
    DECLARE @search_vector VECTOR(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);

	IF @search_vector IS NULL
		BEGIN
			THROW 50000, 'Could not generate VECTOR. Try again in a couple of seconds', 1;
		END;

    /*
        1. Full-Text products (lexical)
            FREETEXTTABLE.RANK is a relevance score 0–1000, NOT a position.
            Convert to positional rank with ROW_NUMBER.
    */
    WITH fts AS (
        SELECT
            ft.[KEY]                                           AS id,
            ROW_NUMBER() OVER (ORDER BY ft.[RANK] DESC)        AS fts_rank
        FROM FREETEXTTABLE([SalesLT].[ProductEmbeddings], chunk, @search_text, @productsN) AS ft
    ),

    /* 
        2. Vector products (semantic ANN or KNN) 
    */
    vec AS (
        --SELECT
        --    t.id,
        --    ROW_NUMBER() OVER (ORDER BY s.distance ASC)        AS vec_rank
        --FROM VECTOR_SEARCH(
        --         TABLE  = [SalesLT].[ProductEmbeddings] AS t,
        --         COLUMN = [embeddings],
        --         SIMILAR_TO = @search_vector,
        --         METRIC = 'cosine',
        --         TOP_N  = @productsN
        --     ) AS s

        SELECT TOP (@productsN)
            ProductID AS id,
            ROW_NUMBER() OVER (ORDER BY VECTOR_DISTANCE('cosine', @search_vector, [embeddings]) ASC) AS vec_rank,
            VECTOR_DISTANCE('cosine', @search_vector, [embeddings]) AS distance
        FROM [SalesLT].[ProductEmbeddings]
        ORDER BY VECTOR_DISTANCE('cosine', @search_vector, [embeddings])
    ),

    /*
        3. Reciprocal Rank Fusion
            Documents missing from a list contribute 0 for that list's term.
            COALESCE maps NULL rank (absent from list) to (@productsN + 1),
            giving a minimal but non-zero contribution 
                - set to 0 if you prefer hard cutoffs.
    */
    fused AS (
        SELECT
            COALESCE(fts.id, vec.id)                           AS id,
            1.0 / (@k + COALESCE(CAST(fts.fts_rank AS FLOAT), @productsN + 1))
          + 1.0 / (@k + COALESCE(CAST(vec.vec_rank AS FLOAT), @productsN + 1))
                                                               AS rrf_score
            ,fts.fts_rank
            ,vec.vec_rank
            ,vec.distance
        FROM fts
        FULL OUTER JOIN vec ON fts.id = vec.id
    )

    /*
        4. Final result
    */
    SELECT TOP (@topN)
        PE.ProductID,
        PE.chunk,
        f.distance,
        PE.[embeddings],
        f.rrf_score,
        f.fts_rank,
        f.vec_rank
    FROM fused AS f
        INNER JOIN [SalesLT].[ProductEmbeddings] AS PE
        ON PE.ProductID = f.id
    ORDER BY f.rrf_score DESC;
GO


/*
    Existing words
    and
    Semantic search (Context)
*/
EXEC HybridSearchProducts 'long sleeve'
EXEC HybridSearchProducts 'Female clothes'















/*
    What about when one of the words exists? ("shorts" in this case)
*/
EXEC HybridSearchProducts 'Confortable female shorts with grip'

EXEC HybridSearchProducts 'Women dark clothes'