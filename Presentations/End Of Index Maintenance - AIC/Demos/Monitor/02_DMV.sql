/*
	Check the new columns that AIC brings
		- compaction_attempt_count
		- compaction_complete_count
		- compaction_skip_count
		- compaction_ineligible_count
		- compaction_failure_count
		- compaction_row_move_count
		- compaction_page_deallocation_count

*/
SELECT 
		  compaction_attempt_count
		, compaction_complete_count
		, compaction_skip_count
		, compaction_ineligible_count
		, compaction_failure_count
		, compaction_row_move_count
		, compaction_page_deallocation_count
		, * 
  FROM sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('dbo.aic_demo'), -1, 0)

sp_help 'sys.dm_db_index_operational_stats'