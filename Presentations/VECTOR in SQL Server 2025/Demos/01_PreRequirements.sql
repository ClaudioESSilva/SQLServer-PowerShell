/*
    PRE-REQUIREMENTS to be able to work with Embeddings (VECTOR data type)
        - On Azure:
            - We need a Database Master key (DMK)
            - We need a credential 


        - On-premises:
            - We need to enable "EXEC sp_configure 'external rest endpoint enabled', 1;"

        - Both on-premises and azure
            - We need an EXTERNAL MODEL

    BEFORE RUN:
        Replace:
            - "<API_KEY>" by the Key you can find withing the Azure AI studio
            - "<azureaiservices>" by your URL

*/
THROW 81920, 'Hey! Just don''t run everything!', 1
GO


USE AdventureWorksLT
GO

/*
EXECUTE sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO


-- Create a database master key!

CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<password>';
GO
*/

IF EXISTS (SELECT *
           FROM   sys.[database_scoped_credentials]
           WHERE  name = 'https://<azureaiservices>.cognitiveservices.azure.com')
    BEGIN
        DROP DATABASE SCOPED CREDENTIAL [https://<azureaiservices>.cognitiveservices.azure.com];
    END
GO

CREATE DATABASE SCOPED CREDENTIAL [https://<azureaiservices>.cognitiveservices.azure.com]
    WITH IDENTITY = 'HTTPEndpointHeaders', SECRET = '{"Authorization":"bearer <API_KEY>"}';
GO


/*
    How to create an EXTERNAL MODEL
*/
IF EXISTS (SELECT *
           FROM   sys.external_models
           WHERE  [name] = 'TestEmbeddings')
    BEGIN
        DROP EXTERNAL MODEL [TestEmbeddings];
    END
GO

CREATE EXTERNAL MODEL TestEmbeddings
WITH 
(
    LOCATION = 'https://<azureaiservices>.cognitiveservices.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=2023-05-15',
    API_FORMAT = 'Azure OpenAI',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'text-embedding-3-small',
    CREDENTIAL = [https://<azureaiservices>.cognitiveservices.azure.com]
    --,
    --PARAMETERS = '{"dimensions":725}'
); 









USE AdventureWorksLT
GO

/*
    How to create an EXTERNAL MODEL
*/
IF EXISTS (SELECT *
           FROM   sys.external_models
           WHERE  [name] = 'ollama')
    BEGIN
        DROP EXTERNAL MODEL [ollama];
    END
GO


CREATE EXTERNAL MODEL ollama
WITH 
(
    LOCATION = 'https://model-web:443/api/embed',
    API_FORMAT = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'nomic-embed-text'
);
GO

/*
    Testing a call with AI_GENERATE_EMBEDDINGS
*/
PRINT 'Testing the external model by calling AI_GENERATE_EMBEDDINGS function...';
GO
BEGIN
    DECLARE @result AS NVARCHAR(MAX);
    SET @result = (SELECT CONVERT (NVARCHAR(MAX), AI_GENERATE_EMBEDDINGS(N'test text' USE MODEL ollama)));
    SELECT AI_GENERATE_EMBEDDINGS(N'test text' USE MODEL ollama) AS GeneratedEmbedding;
    IF @result IS NOT NULL
        PRINT 'Model test successful. Result: ' + @result;
    ELSE
        PRINT 'Model test failed. No result returned.';
END
GO

/*
    Using sp_invoke_external_rest_endpoint

    This will become more useful later
*/
EXECUTE sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE;
GO


DECLARE @ReturnCode AS INT;
DECLARE @Response AS NVARCHAR(MAX);
DECLARE @Payload AS NVARCHAR(MAX) = N'{"model":"nomic-embed-text","input":"test text"}';

EXECUTE @ReturnCode = sys.sp_invoke_external_rest_endpoint 
    @method = 'POST', 
    @url = 'https://model-web:443/api/embed', 
    @payload = @Payload, 
    @headers = N'{"Content-Type":"application/json"}', 
    @response = @Response OUTPUT;

SELECT   @ReturnCode AS ReturnCode
       , @Response AS Response;
GO