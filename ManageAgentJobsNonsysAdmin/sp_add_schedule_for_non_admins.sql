USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_add_schedule_for_non_admins]
	@schedule_name			sysname,
	@enabled				TINYINT         = 1,            -- Name does not have to be unique
	@freq_type				INT             = 0,
	@freq_interval			INT             = 0,
	@freq_subday_type       INT             = 0,
	@freq_subday_interval   INT             = 0,
	@freq_relative_interval INT             = 0,
	@freq_recurrence_factor INT             = 0,
	@active_start_date		INT             = NULL,         -- sp_verify_schedule assigns a default
	@active_end_date        INT             = 99991231,     -- December 31st 9999
	@active_start_time		INT             = 000000,       -- 12:00:00 am
	@active_end_time        INT             = 235959,       -- 11:59:59 pm
	@owner_login_name       sysname         = NULL,
	@schedule_uid           UNIQUEIDENTIFIER= NULL  OUTPUT, -- Used by a TSX machine when inserting a schedule
	@schedule_id            INT             = NULL  OUTPUT,
	@originating_server     sysname        = NULL

WITH EXECUTE AS OWNER
AS
	BEGIN
		IF EXISTS (SELECT [name]
				     FROM msdb.dbo.sysjobs
					WHERE job_id = @job_id
					 AND [name] LIKE '<customer job prefix name>%'
			) 
			BEGIN 
				EXEC msdb.dbo.sp_add_schedule
					@schedule_name			
					,@enabled				
					,@freq_type				
					,@freq_interval			
					,@freq_subday_type       
					,@freq_subday_interval   
					,@freq_relative_interval 
					,@freq_recurrence_factor 
					,@active_start_date		
					,@active_end_date        
					,@active_start_time		
					,@active_end_time        
					,@owner_login_name       
					,@schedule_uid           
					,@schedule_id            
					,@originating_server  
			END
		ELSE
			BEGIN
				RAISERROR ('The job_id used does not belong to an <customer job prefix name> job.', 16, 1);  
			END  
	END

GO

