/*
	Created by REDGLUEL1\Claudio Silva using dbatools Export-DbaScript for objects on localhost,1433 at 11/26/2019 12:33:08
	See https://dbatools.io/Export-DbaScript for more information
*/
CREATE SERVER ROLE [bulkadmin]
CREATE SERVER ROLE [dbcreator]
CREATE SERVER ROLE [diskadmin]
CREATE SERVER ROLE [Endpoint-Admins]
ALTER SERVER ROLE [dbcreator] ADD MEMBER [Endpoint-Admins]
CREATE SERVER ROLE [processadmin]
CREATE SERVER ROLE [public]
CREATE SERVER ROLE [securityadmin]
CREATE SERVER ROLE [serveradmin]
CREATE SERVER ROLE [setupadmin]
CREATE SERVER ROLE [sysadmin]
