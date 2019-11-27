/*
	Created by REDGLUEL1\Claudio Silva using dbatools Export-DbaScript for objects on localhost,1433 at 11/26/2019 12:33:10
	See https://dbatools.io/Export-DbaScript for more information
*/
EXEC msdb.dbo.sysmail_configure_sp @parameter_name=N'AccountRetryAttempts', @parameter_value=N'1', @description=N'Number of retry attempts for a mail server'
EXEC msdb.dbo.sysmail_configure_sp @parameter_name=N'AccountRetryDelay', @parameter_value=N'60', @description=N'Delay between each retry attempt to mail server'
EXEC msdb.dbo.sysmail_configure_sp @parameter_name=N'DatabaseMailExeMinimumLifeTime', @parameter_value=N'600', @description=N'Minimum process lifetime in seconds'
EXEC msdb.dbo.sysmail_configure_sp @parameter_name=N'DefaultAttachmentEncoding', @parameter_value=N'MIME', @description=N'Default attachment encoding'
EXEC msdb.dbo.sysmail_configure_sp @parameter_name=N'LoggingLevel', @parameter_value=N'2', @description=N'Database Mail logging level: normal - 1, extended - 2 (default), verbose - 3'
EXEC msdb.dbo.sysmail_configure_sp @parameter_name=N'MaxFileSize', @parameter_value=N'1000000', @description=N'Default maximum file size'
EXEC msdb.dbo.sysmail_configure_sp @parameter_name=N'ProhibitedExtensions', @parameter_value=N'exe,dll,vbs,js', @description=N'Extensions not allowed in outgoing mails'
EXEC msdb.dbo.sysmail_add_account_sp @account_name=N'The DBA Team', 
		@email_address=N'administrator@ad.local', 
		@display_name=N'The DBA Team'
EXEC msdb.dbo.sysmail_add_profile_sp @profile_name=N'The DBA Team'
EXEC msdb.dbo.sysmail_add_profileaccount_sp @profile_name=N'The DBA Team', @account_name=N'The DBA Team', @sequence_number=1
EXEC msdb.dbo.sysmail_add_principalprofile_sp @principal_name=N'guest', @profile_name=N'The DBA Team', @is_default=1
