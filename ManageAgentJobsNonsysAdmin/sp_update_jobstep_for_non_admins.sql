USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_update_jobstep_for_non_admins]
  @job_id                 UNIQUEIDENTIFIER = NULL, -- Must provide either this or job_name
  @job_name               sysname          = NULL, -- Not updatable (provided for identification purposes only)
  @step_id                INT,                     -- Not updatable (provided for identification purposes only)
  @step_name              sysname          = NULL,
  @subsystem              NVARCHAR(40)     = NULL,
  @command                NVARCHAR(max)    = NULL,
  @additional_parameters  NVARCHAR(max)    = NULL,
  @cmdexec_success_code   INT              = NULL,
  @on_success_action      TINYINT          = NULL,
  @on_success_step_id     INT              = NULL,
  @on_fail_action         TINYINT          = NULL,
  @on_fail_step_id        INT              = NULL,
  @server                 sysname          = NULL,
  @database_name          sysname          = NULL,
  @database_user_name     sysname          = NULL,
  @retry_attempts         INT              = NULL,
  @retry_interval         INT              = NULL,
  @os_run_priority        INT              = NULL,
  @output_file_name       NVARCHAR(200)    = NULL,
  @flags                  INT              = NULL,
  @proxy_id				  int          = NULL,
  @proxy_name			  sysname         = NULL
  -- mutual exclusive; must specify only one of above 2 parameters to 
  -- identify the proxy. 

WITH EXECUTE AS OWNER
AS
	BEGIN
		IF EXISTS (SELECT [name]
				     FROM msdb.dbo.sysjobs
					WHERE job_id = @job_id
					 AND [name] LIKE '<customer job prefix name>%'
			) 
			BEGIN 
                EXEC msdb.dbo.sp_update_jobstep
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
			END
		ELSE
			BEGIN
				RAISERROR ('The job_id used does not belong to an <customer job prefix name> job.', 16, 1);  
			END  
	END

GO
