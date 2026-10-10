/*
    Automatic Index Compaction (AIC) Demo - Step 2: Degrade
    =======================================================
    Scatter-delete 50% of rows using CHECKSUM modulo.
    Every page loses roughly half its rows, but no page goes empty.
    Result: ~47% page density, same page count — worst case for scans.

    Why CHECKSUM(id) % 2?
    - Distributes deletes uniformly across all pages (not contiguous).
    - Contiguous deletes would deallocate entire pages (no density problem).
    - Scatter-delete leaves every page half-full — maximum wasted I/O.

    Note: In Hyperscale (ADR), the DELETE stamps a 14-byte version pointer
    on each ghost record. Pages at 99.8% density may split from this overhead,
    which is why page count can increase slightly after the delete.
*/

/*
    Check some index properties and copy the result to the below table for comparison:

index_name	    used_page_count	    reserved_page_count	    index_total_size_mb	    fill_factor	    density_pct	    leaf_page_count	    record_count	frag_pct	pvs_kb


*/

SELECT i.name AS index_name,
       ps.used_page_count,
       ps.reserved_page_count,
       CAST(ps.reserved_page_count / 128.0 AS decimal(7,2)) AS index_total_size_mb,
       i.fill_factor,
       CAST(ips.avg_page_space_used_in_percent AS decimal(5,2)) AS density_pct,
       ips.page_count AS leaf_page_count,
       ips.record_count,
       CAST(ips.avg_fragmentation_in_percent AS decimal(5,2)) AS frag_pct,
       pvs.persistent_version_store_size_kb AS pvs_kb
FROM sys.dm_db_partition_stats AS ps
    INNER JOIN sys.indexes AS i
       ON ps.object_id = i.object_id AND ps.index_id = i.index_id
    INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.aic_demo'), 1, 1, 'DETAILED') AS ips
       ON i.object_id = ips.object_id
      AND i.index_id = ips.index_id
    CROSS JOIN sys.dm_tran_persistent_version_store_stats AS pvs
WHERE ps.object_id = OBJECT_ID(N'dbo.aic_demo')
  AND ips.index_level = 0
  AND pvs.database_id = DB_ID();
GO


/* Scatter-delete: remove rows where CHECKSUM(id) is even */
DELETE dbo.aic_demo WHERE CHECKSUM(id) % 2 = 0;
GO

/*
    Check some index properties
*/
SELECT i.name AS index_name,
       ps.used_page_count,
       ps.reserved_page_count,
       CAST(ps.reserved_page_count / 128.0 AS decimal(7,2)) AS index_total_size_mb,
       i.fill_factor,
       CAST(ips.avg_page_space_used_in_percent AS decimal(5,2)) AS density_pct,
       ips.page_count AS leaf_page_count,
       ips.record_count,
       CAST(ips.avg_fragmentation_in_percent AS decimal(5,2)) AS frag_pct,
       pvs.persistent_version_store_size_kb AS pvs_kb
FROM sys.dm_db_partition_stats AS ps
    INNER JOIN sys.indexes AS i
       ON ps.object_id = i.object_id AND ps.index_id = i.index_id
    INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.aic_demo'), 1, 1, 'DETAILED') AS ips
       ON i.object_id = ips.object_id
      AND i.index_id = ips.index_id
    CROSS JOIN sys.dm_tran_persistent_version_store_stats AS pvs
WHERE ps.object_id = OBJECT_ID(N'dbo.aic_demo')
  AND ips.index_level = 0
  AND pvs.database_id = DB_ID();

WAITFOR DELAY '00:00:03'
GO 10



