USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_delete_job_for_non_admins]
    @job_id                   UNIQUEIDENTIFIER = NULL, -- If provided should NOT also provide job_name
    @job_name                 sysname          = NULL, -- If provided should NOT also provide job_id
    @originating_server       sysname          = NULL, -- Reserved (used by SQLAgent)
    @delete_history           BIT              = 1,    -- Reserved (used by SQLAgent)
    @delete_unused_schedule   BIT              = 1     -- For backward compatibility schedules are deleted by default if they are not 
                                                       -- being used by another job. With the introduction of reusable schedules in V9 
                                                       -- callers should set this to 0 so the schedule will be preserved for reuse.

WITH EXECUTE AS OWNER
AS
	BEGIN
		
		IF EXISTS (SELECT [name]
				     FROM msdb.dbo.sysjobs
					WHERE job_id = @job_id
					 AND [name] LIKE '<customer job prefix name>%'
			) 
			BEGIN 
				EXEC msdb.dbo.sp_delete_job
					@job_id                
                    ,@job_name              
                    ,@originating_server    
                    ,@delete_history        
                    ,@delete_unused_schedule
			END
		ELSE
			BEGIN
				RAISERROR ('The job_id used does not belong to an <customer job prefix name> job.', 16, 1);  
			END         
	END
GO


