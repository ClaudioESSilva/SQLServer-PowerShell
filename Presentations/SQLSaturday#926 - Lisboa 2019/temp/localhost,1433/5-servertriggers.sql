/*
	Created by REDGLUEL1\Claudio Silva using dbatools Export-DbaScript for objects on localhost,1433 at 11/26/2019 12:33:10
	See https://dbatools.io/Export-DbaScript for more information
*/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [tr_MScdc_db_ddl_event] on all server for ALTER_DATABASE, DROP_DATABASE
		             as 
					set ANSI_NULLS ON
					set ANSI_PADDING ON
					set ANSI_WARNINGS ON
					set ARITHABORT ON
					set CONCAT_NULL_YIELDS_NULL ON
					set NUMERIC_ROUNDABORT OFF
					set QUOTED_IDENTIFIER ON

					declare @EventData xml, @retcode int
					set @EventData=EventData()  
					if object_id('sys.sp_MScdc_db_ddl_event' ) is not null
					begin 
						exec @retcode = sys.sp_MScdc_db_ddl_event @EventData
						if @@error <> 0 or @retcode <> 0 
						begin
							rollback tran
						end
					end		 

GO
ENABLE TRIGGER [tr_MScdc_db_ddl_event] ON ALL SERVER

