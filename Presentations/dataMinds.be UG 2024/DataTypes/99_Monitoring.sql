EXEC sp_whoisactive
	@get_plans = 1
	--, @get_memory_info = 1




SELECT * 
  FROM sys.dm_exec_query_memory_grants
-- WHERE grant_time IS NOT NULL

-- sp_configure 'max server memory (MB)'

--SELECT * 
--FROM sys.dm_exec_requests
--WHERE session_id >= 50


SELECT TOP(5) [type] AS [ClerkType],
SUM(pages_kb) / 1024 AS [SizeMb]
FROM sys.dm_os_memory_clerks WITH (NOLOCK)
GROUP BY [type]
ORDER BY SUM(pages_kb) DESC


SELECT session_id, requested_memory_kb / 1024 as RequestedMemMb, 
granted_memory_kb / 1024 as GrantedMemMb, text
FROM sys.dm_exec_query_memory_grants qmg
CROSS APPLY sys.dm_exec_sql_text(sql_handle)



SELECT * FROM sys.dm_exec_query_resource_semaphores

EXEC sp_PressureDetector
	@what_to_check = 'memory'

SELECT * FROM sys.dm_exec_query_resource_semaphores











/*
	Check Memory Per Object
*/
USE DataTypes
GO

-- Object level
;WITH src AS
(
	SELECT
		[Object] = o.name,
		[Type] = o.type_desc,
		[Index] = COALESCE(i.name, ''),
		[Index_Type] = i.type_desc,
		p.[object_id],
		p.index_id,
		au.allocation_unit_id
	FROM sys.partitions AS p
		INNER JOIN sys.allocation_units AS au
		ON p.hobt_id = au.container_id
		INNER JOIN sys.objects AS o
		ON p.[object_id] = o.[object_id]
		INNER JOIN sys.indexes AS i
		ON o.[object_id] = i.[object_id]
		AND p.index_id = i.index_id
	WHERE au.[type] IN (1,2,3)
	  AND o.is_ms_shipped = 0
)
SELECT
	src.[Object],
	src.[Type],
	src.[Index],
	src.Index_Type,
	buffer_pages = COUNT_BIG(b.page_id),
	buffer_mb = COUNT_BIG(b.page_id) / 128
  FROM src
	INNER JOIN sys.dm_os_buffer_descriptors AS b
	ON src.allocation_unit_id = b.allocation_unit_id
 WHERE b.database_id = DB_ID()
GROUP BY
	src.[Object],
	src.[Type],
	src.[Index],
	src.Index_Type
ORDER BY buffer_pages DESC
