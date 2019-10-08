USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_update_schedule_for_non_admins]
    @schedule_id              INT             = NULL,   -- Must provide either this or schedule_name
    @name                     sysname         = NULL,   -- Must provide either this or schedule_id
    @new_name                 sysname         = NULL,
    @enabled                  TINYINT         = NULL,
    @freq_type                INT             = NULL,
    @freq_interval            INT             = NULL,
    @freq_subday_type         INT             = NULL,
    @freq_subday_interval     INT             = NULL,
    @freq_relative_interval   INT             = NULL,
    @freq_recurrence_factor   INT             = NULL,
    @active_start_date        INT             = NULL, 
    @active_end_date          INT             = NULL,
    @active_start_time        INT             = NULL,
    @active_end_time          INT             = NULL,
    @owner_login_name         sysname         = NULL,
    @automatic_post           BIT             = 1       -- If 1 will post notifications to all tsx servers to 
                                                        -- update all jobs that use this schedule
WITH EXECUTE AS OWNER
AS
	BEGIN

		IF EXISTS (SELECT [name]
				     FROM msdb.dbo.sysjobs
					WHERE job_id = @job_id
					 AND [name] LIKE '<customer job prefix name>%'
			) 
			BEGIN 
                EXEC msdb.dbo.sp_update_schedule
                    @schedule_id
                    ,@name
                    ,@new_name
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
                    ,@automatic_post
			END
		ELSE
			BEGIN
				RAISERROR ('The job_id used does not belong to an <customer job prefix name> job.', 16, 1);  
			END     
	END
GO
