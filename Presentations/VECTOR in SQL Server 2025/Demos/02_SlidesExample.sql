/*
    Example from slides
*/
THROW 81920, 'Hey! Just don''t run everything!', 1
GO

USE tempdb
GO

DROP TABLE IF EXISTS dbo.word_vectors;

CREATE TABLE dbo.word_vectors
(
    id INT PRIMARY KEY
  , word VARCHAR(50)
  , v VECTOR(4)
);

INSERT  INTO dbo.word_vectors (id, word, v)
VALUES                       
      (1, 'dog',        '[0.82, 0.65, 0.10, 0.05]')
    , (2, 'puppy',      '[0.79, 0.68, 0.12, 0.04]')
    , (3, 'airplane',   '[0.05, 0.02, 0.91, 0.88]');



DECLARE @query AS VECTOR(4) = '[0.82, 0.65, 0.10, 0.05]'; -- "dog"

SELECT     word
         , VECTOR_DISTANCE('cosine', @query, v) AS distance
FROM     dbo.word_vectors
ORDER BY distance;
GO




USE AdventureWorksLT
GO
/* 
    With real embeddings
*/
DECLARE @v1 AS VECTOR(768);
DECLARE @v2 AS VECTOR(768);
DECLARE @v3 AS VECTOR(768);
DECLARE @v4 AS VECTOR(768);

SELECT @v1 = AI_GENERATE_EMBEDDINGS('dog' USE MODEL ollama);
SELECT @v2 = AI_GENERATE_EMBEDDINGS('puppy' USE MODEL ollama);
SELECT @v3 = AI_GENERATE_EMBEDDINGS('cat' USE MODEL ollama);
SELECT @v4 = AI_GENERATE_EMBEDDINGS('airplane' USE MODEL ollama);

SELECT VECTOR_DISTANCE('cosine', @v1, @v2) AS dogVSpuppy;
SELECT VECTOR_DISTANCE('cosine', @v1, @v3) AS dogVScat;
SELECT VECTOR_DISTANCE('cosine', @v1, @v4) AS dogVSairplane;
GO

