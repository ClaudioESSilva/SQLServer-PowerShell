USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_add_jobstep_for_non_admins]
	@job_id                UNIQUEIDENTIFIER = NULL,   -- Must provide either this or job_name
	@job_name              sysname          = NULL,   -- Must provide either this or job_id
	@step_id               INT              = NULL,   -- The proc assigns a default
	@step_name             sysname,
	@subsystem             NVARCHAR(40)     = N'TSQL',
	@command               NVARCHAR(max)   = NULL,   
	@additional_parameters NVARCHAR(max)    = NULL,
	@cmdexec_success_code  INT              = 0,
	@on_success_action     TINYINT          = 1,      -- 1 = Quit With Success, 2 = Quit With Failure, 3 = Goto Next Step, 4 = Goto Step
	@on_success_step_id    INT              = 0,
	@on_fail_action        TINYINT          = 2,      -- 1 = Quit With Success, 2 = Quit With Failure, 3 = Goto Next Step, 4 = Goto Step
	@on_fail_step_id       INT              = 0,
	@server                sysname      = NULL,
	@database_name         sysname          = NULL,
	@database_user_name    sysname          = NULL,
	@retry_attempts        INT              = 0,      -- No retries
	@retry_interval        INT              = 0,      -- 0 minute interval
	@os_run_priority       INT              = 0,      -- -15 = Idle, -1 = Below Normal, 0 = Normal, 1 = Above Normal, 15 = Time Critical)
	@output_file_name      NVARCHAR(200)    = NULL,
	@flags                 INT              = 0,       -- 0 = Normal, 
													   -- 1 = Encrypted command (read only), 
													   -- 2 = Append output files (if any), 
													   -- 4 = Write TSQL step output to step history,                                      
													   -- 8 = Write log to table (overwrite existing history), 
													   -- 16 = Write log to table (append to existing history)
													   -- 32 = Write all output to job history
													   -- 64 = Create a Windows event to use as a signal for the Cmd jobstep to abort
	@proxy_id                 INT                = NULL,
	@proxy_name               sysname          = NULL,
	-- mutual exclusive; must specify only one of above 2 parameters to 
	-- identify the proxy. 
	@step_uid UNIQUEIDENTIFIER = NULL OUTPUT

WITH EXECUTE AS OWNER
AS
	BEGIN
		IF EXISTS (SELECT [name]
				     FROM msdb.dbo.sysjobs
					WHERE job_id = @job_id
					 AND [name] LIKE '<customer job prefix name>%'
			) 
			BEGIN 
				EXEC msdb.dbo.sp_add_jobstep
					@job_id
					,@job_name
					,@step_id
					,@step_name
					,@subsystem
					,@command
					,@additional_parameters
					,@cmdexec_success_code
					,@on_success_action
					,@on_success_step_id
					,@on_fail_action
					,@on_fail_step_id
					,@server
					,@database_name
					,@database_user_name
					,@retry_attempts
					,@retry_interval
					,@os_run_priority
					,@output_file_name
					,@flags
					,@proxy_id
					,@proxy_name
					,@step_uid
			END
		ELSE
			BEGIN
				RAISERROR ('The job_id used does not belong to an <customer job prefix name> job.', 16, 1);  
			END  
	END

GO

