USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_update_job_for_non_admins]
	@job_id                       UNIQUEIDENTIFIER = NULL, -- Must provide this or current_name
	@job_name                     sysname          = NULL, -- Must provide this or job_id
	@new_name                     sysname          = NULL,
	@enabled                      TINYINT          = NULL,
	@description                  NVARCHAR(512)    = NULL,
	@start_step_id                INT              = NULL,
	@category_name                sysname          = NULL,
	@owner_login_name             sysname          = NULL,
	@notify_level_eventlog        INT              = NULL,
	@notify_level_email           INT              = NULL,
	@notify_level_netsend         INT              = NULL,
	@notify_level_page            INT              = NULL,
	@notify_email_operator_name   sysname          = NULL,
	@notify_netsend_operator_name sysname          = NULL,
	@notify_page_operator_name    sysname          = NULL,
	@delete_level                 INT              = NULL,
	@automatic_post               BIT              = 1     -- Flag for SEM use only

WITH EXECUTE AS OWNER
AS
	BEGIN
		
		IF EXISTS (SELECT [name]
				     FROM msdb.dbo.sysjobs
					WHERE job_id = @job_id
					 AND [name] LIKE '<customer job prefix name>%'
			) 
			BEGIN 
				EXEC msdb.dbo.sp_update_job
					@job_id                      
					,@job_name                    
					,@new_name                    
					,@enabled                     
					,@description                 
					,@start_step_id               
					,@category_name               
					,@owner_login_name            
					,@notify_level_eventlog       
					,@notify_level_email          
					,@notify_level_netsend        
					,@notify_level_page           
					,@notify_email_operator_name  
					,@notify_netsend_operator_name
					,@notify_page_operator_name   
					,@delete_level                
					,@automatic_post
			END
		ELSE
			BEGIN
				RAISERROR ('The job_id used does not belong to an <customer job prefix name> job.', 16, 1);  
			END         
	END
GO


