/*
	Performance when generating embeddings
*/
USE AdventureWorksLT
GO

DROP TABLE IF EXISTS #messages;

SELECT TOP (100)   
      id           = row_number() OVER (ORDER BY (SELECT NULL))
    , text         = CONVERT (NVARCHAR(MAX), text)
    , VectorSingle = CONVERT (VECTOR(768), NULL)
    , VectorBatch  = CONVERT (VECTOR(768), NULL)
INTO   #messages
FROM   sys.messages AS s;

SELECT *
FROM   #messages;

-- updating using row by row
DECLARE @Start AS DATETIME;

SET @Start = getdate();

UPDATE #Messages
SET    VectorSingle = AI_GENERATE_EMBEDDINGS(text USE MODEL ollama);

SELECT ElapsedAiGenerated = datediff(ms, @Start, getdate());
GO


/*
	Paste the result here: 4204 ms
    
    Run the next block and come here paste the result: 3680 ms

*/
DECLARE @body AS NVARCHAR(MAX), @result AS NVARCHAR(MAX), @Start AS DATETIME;

SELECT @body = (SELECT   input      = JSON_QUERY(JSON_ARRAYAGG(text))
                       , model      = 'nomic-embed-text'
                       , dimensions = 768
                FOR    JSON PATH, WITHOUT_ARRAY_WRAPPER)
FROM   #messages;

SET @Start = getdate();

EXECUTE sp_invoke_external_rest_endpoint 
    'https://model-web:443/api/embed', 
    @payload = @body, 
    @response = @result OUTPUT;

SELECT @result

DROP TABLE IF EXISTS #embresult;

SELECT   r.[key]
       , embeddings = JSON_QUERY(r.value, '$')
INTO   #embresult
FROM   OPENJSON (@result, '$.result.embeddings') AS r;

UPDATE m
SET    VectorBatch = embeddings
FROM   #embresult AS o
       INNER JOIN
       #Messages AS m
       ON m.id = o.[key] + 1;

SELECT ElapsedBatched = datediff(ms, @Start, getdate());

SELECT   *
       , CONVERT (DECIMAL(30, 29), VECTOR_DISTANCE('cosine', VectorSingle, VectorBatch))
FROM   #Messages;


SELECT CAST(@body AS JSON) AS body, CAST(@result AS JSON) AS response