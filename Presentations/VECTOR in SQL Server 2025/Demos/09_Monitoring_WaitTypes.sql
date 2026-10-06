/*
	Monitoring for External AI calls

	It will count towards some *HTTP* waits
		- HTTP_EXTERNAL_CONNECTION
		- PREEMPTIVE_HTTP_EVENT_WAIT
*/
SELECT *
  FROM sys.dm_exec_session_wait_stats 
 WHERE session_id = 55
ORDER BY wait_time_ms DESC





/*
	Transactions should be as small and fast as possible.
	Be mindful of blocking.
	
	If you decide to use it from SQL Server and you want to do some bulk actions, 
	remember you will have as many HTTP requests as rows being processed.
	RBAR (Row-by-agonizing-row)

		TIP: You can use temporary tables to minimize the impact on concurrency.
*/