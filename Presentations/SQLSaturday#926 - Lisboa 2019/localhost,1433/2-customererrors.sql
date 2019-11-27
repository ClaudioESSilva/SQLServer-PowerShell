/*
	Created by REDGLUEL1\Claudio Silva using dbatools Export-DbaScript for objects on localhost,1433 at 11/26/2019 12:33:08
	See https://dbatools.io/Export-DbaScript for more information
*/
EXEC master.dbo.sp_addmessage @msgnum=60000, @lang=N'us_english', 
		@severity=16, 
		@msgtext=N'The item named %s already exists in %s.', 
		@with_log=false
