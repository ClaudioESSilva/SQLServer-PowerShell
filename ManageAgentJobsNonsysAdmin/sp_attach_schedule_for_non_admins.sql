USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[sp_attach_schedule_for_non_admins]
  @job_id               UNIQUEIDENTIFIER    = NULL,     -- Must provide either this or job_name
  @job_name             sysname             = NULL,     -- Must provide either this or job_id
  @schedule_id          INT                 = NULL,     -- Must provide either this or schedule_name
  @schedule_name        sysname             = NULL,     -- Must provide either this or schedule_id
  @automatic_post       BIT                 = 1         -- If 1 will post notifications to all tsx servers to that run this job

WITH EXECUTE AS OWNER
AS
	BEGIN
		IF EXISTS (SELECT [name]
				     FROM msdb.dbo.sysjobs
					WHERE job_id = @job_id
					 AND [name] LIKE '<customer job prefix name>%'
			) 
			BEGIN 
				EXEC msdb.dbo.sp_attach_schedule
					@job_id
					,@job_name
					,@schedule_id
					,@schedule_name 
					,@automatic_post
			END
		ELSE
			BEGIN
				RAISERROR ('The job_id used does not belong to an <customer job prefix name> job.', 16, 1);  
			END  
	END

GO

