/*
    Make sure you are on the correct database
*/
/*
Create and start an event session collecting the auto_index_compaction_stats event
into a ring_buffer target
*/
IF NOT EXISTS (SELECT 1
               FROM sys.dm_xe_database_sessions
               WHERE name = N'auto_index_compaction_stats')
  BEGIN
        CREATE EVENT SESSION [auto_index_compaction_stats] ON DATABASE 
        ADD EVENT sqlserver.auto_index_compaction_stats
            (
            ACTION (sqlserver.database_name
                  , sqlserver.sql_text
                  , sqlserver.username)
            ) 
        ADD TARGET package0.ring_buffer
            (
            SET max_memory = (10240)
            )
        WITH 
        (
                STARTUP_STATE = ON
        );

      ALTER EVENT SESSION [auto_index_compaction_stats] ON DATABASE STATE = START;
  END
GO

/*
    Use the following query since the data in the XE is cumulative
*/ 

/* Get event data from the ring_buffer target */
DECLARE @EventData AS XML = (SELECT TOP 1 CAST (xst.target_data AS XML) AS TargetData
                             FROM sys.dm_xe_database_session_targets AS xst
                                  INNER JOIN sys.dm_xe_database_sessions AS xs
                                      ON xst.event_session_address = xs.address
                             WHERE xs.name = N'auto_index_compaction_stats');

/* Return statistics for each 10-minute interval */
WITH compaction_stats_event AS (
    SELECT d.value('@timestamp', 'datetimeoffset') AS timestamp,
           d.value('(data[@name = "database_id"]/value/text())[1]', 'smallint') AS database_id,
           d.value('(data[@name = "compact_attempts"]/value/text())[1]', 'bigint') AS compact_attempts,
           d.value('(data[@name = "compact_completed"]/value/text())[1]', 'bigint') AS compact_completed,
           d.value('(data[@name = "pages_deallocated_compaction"]/value/text())[1]', 'bigint') AS pages_deallocated_compaction,
           d.value('(data[@name = "rows_moved"]/value/text())[1]', 'bigint') AS rows_moved
    FROM @EventData.nodes('/RingBufferTarget/event') AS e(d)
    WHERE e.d.value('@name', 'sysname') = 'auto_index_compaction_stats'
),
timestamp_map AS (
    SELECT database_id,
           timestamp,
           LAG(timestamp) OVER (PARTITION BY database_id ORDER BY timestamp) AS previous_timestamp
    FROM compaction_stats_event
)
SELECT c.timestamp,
       c.database_id,
       c.compact_attempts - ISNULL(p.compact_attempts, 0) AS compact_attempts,
       c.compact_completed - ISNULL(p.compact_completed, 0) AS compact_completed,
       c.pages_deallocated_compaction - ISNULL(p.pages_deallocated_compaction, 0) AS pages_deallocated_compaction,
       c.rows_moved - ISNULL(p.rows_moved, 0) AS rows_moved
FROM compaction_stats_event AS c
     LEFT JOIN timestamp_map AS tm
         ON c.timestamp = tm.timestamp
        AND c.database_id = tm.database_id
     LEFT JOIN compaction_stats_event AS p
         ON tm.previous_timestamp = p.timestamp
        AND tm.database_id = p.database_id
ORDER BY timestamp DESC;