/*
	Created by REDGLUEL1\Claudio Silva using dbatools Export-DbaLogin for objects on localhost,1433 at 2019-11-26 22:21:37.736
	See https://dbatools.io/Export-DbaLogin for more information
*/
USE master

GO
IF NOT EXISTS (SELECT loginname FROM master.dbo.syslogins WHERE name = 'storageuser') CREATE LOGIN [storageuser] WITH PASSWORD = 0x01003A2F024897F4A96E4AC4167E6431FBB0E26A9A987644D720 HASHED, SID = 0xEA947BDFB542FC4B816012ADE47D1651, DEFAULT_DATABASE = [master], CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF, DEFAULT_LANGUAGE = [us_english]
GO

USE master

GO
Grant CONNECT SQL TO [storageuser]  AS [sa]
GO
Deny SHUTDOWN TO [storageuser]  AS [sa]
GO
Grant VIEW ANY DATABASE TO [storageuser]  AS [sa]
GO

USE [Northwind]

GO
CREATE USER [storageuser] FOR LOGIN [storageuser] WITH DEFAULT_SCHEMA=[dbo]
GO
Grant CONNECT TO [storageuser]  AS [dbo]
GO
Grant SHOWPLAN TO [storageuser]  AS [dbo]
GO
