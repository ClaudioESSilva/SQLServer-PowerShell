USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_add_job_for_non_admins]
	@job_name                     sysname,
	@enabled                      TINYINT          = 1,        -- 0 = Disabled, 1 = Enabled
	@description                  NVARCHAR(512)    = NULL,
	@start_step_id                INT              = 1,
	@category_name                sysname          = NULL,
	@category_id                  INT              = NULL,     -- A language-independent way to specify which category to use
	@owner_login_name             sysname          = NULL,     -- The procedure assigns a default
	@notify_level_eventlog        INT              = 2,        -- 0 = Never, 1 = On Success, 2 = On Failure, 3 = Always
	@notify_level_email           INT              = 0,        -- 0 = Never, 1 = On Success, 2 = On Failure, 3 = Always
	@notify_level_netsend         INT              = 0,        -- 0 = Never, 1 = On Success, 2 = On Failure, 3 = Always
	@notify_level_page            INT              = 0,        -- 0 = Never, 1 = On Success, 2 = On Failure, 3 = Always
	@notify_email_operator_name   sysname          = NULL,
	@notify_netsend_operator_name sysname          = NULL,
	@notify_page_operator_name    sysname          = NULL,
	@delete_level                 INT              = 0,        -- 0 = Never, 1 = On Success, 2 = On Failure, 3 = Always
	@job_id                       UNIQUEIDENTIFIER = NULL OUTPUT,
	@originating_server           sysname           = NULL      -- For SQLAgent use only

WITH EXECUTE AS OWNER
AS
	BEGIN
			IF EXISTS (SELECT [name]
				     FROM msdb.dbo.sysjobs
					WHERE job_id = @job_id
					 AND [name] LIKE '<customer job prefix name>%'
			) 
			BEGIN 
				EXEC msdb.dbo.sp_add_job
					@job_name                     
					,@enabled                      
					,@description                  
					,@start_step_id                
					,@category_name                
					,@category_id                  
					,@owner_login_name             
					,@notify_level_eventlog        
					,@notify_level_email           
					,@notify_level_netsend         
					,@notify_level_page            
					,@notify_email_operator_name   
					,@notify_netsend_operator_name 
					,@notify_page_operator_name    
					,@delete_level                 
					,@job_id                       
					,@originating_server           
			END
		ELSE
			BEGIN
				RAISERROR ('The job_id used does not belong to an <customer job prefix name> job.', 16, 1);  
			END  
	END

GO

