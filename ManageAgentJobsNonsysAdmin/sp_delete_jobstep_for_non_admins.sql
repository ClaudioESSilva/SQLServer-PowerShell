USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_delete_jobstep_for_non_admins]
	@job_id   UNIQUEIDENTIFIER = NULL, -- Must provide either this or job_name
	@job_name sysname          = NULL, -- Must provide either this or job_id
	@step_id  INT

WITH EXECUTE AS OWNER
AS
	BEGIN
		IF EXISTS (SELECT [name]
				     FROM msdb.dbo.sysjobs
					WHERE job_id = @job_id
					 AND [name] LIKE '<customer job prefix name>%'
			) 
			BEGIN 
				EXEC msdb.dbo.sp_delete_jobstep
					@job_id
					,@job_name
					,@step_id
			END
		ELSE
			BEGIN
				RAISERROR ('The job_id used does not belong to an <customer job prefix name> job.', 16, 1);  
			END  
	END

GO

