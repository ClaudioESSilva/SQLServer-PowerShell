/*
    Make sure you are connected to a SQL Server instance that allow
    turning on the AUTOMATIC_INDEX_COMPACTION
*/
THROW 811920, 'Hey! Just don''t run everything!', 1
GO

/* 
    Make sure automatic index compaction is OFF
    for the "before AIC" demo
*/
ALTER DATABASE CURRENT SET AUTOMATIC_INDEX_COMPACTION = OFF;
GO

/* 
    Confirm it's enabled 
*/
SELECT name AS database_name,
       IIF(is_automatic_index_compaction_on = 1, 'ON', 'OFF') AS aic_status
FROM sys.databases
WHERE database_id = DB_ID();