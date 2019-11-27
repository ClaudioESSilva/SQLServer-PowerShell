/*
	Created by REDGLUEL1\Claudio Silva using dbatools Export-DbaLogin for objects on localhost,1433 at 2019-11-26 22:21:37.736
	See https://dbatools.io/Export-DbaLogin for more information
*/
USE master

GO
IF NOT EXISTS (SELECT loginname FROM master.dbo.syslogins WHERE name = 'storageuserColleague') CREATE LOGIN [storageuserColleague] WITH PASSWORD = 0x01003A2F024897F4A96E4AC4167E6431FBB0E26A9A987644D720 HASHED , DEFAULT_DATABASE = [master], CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF, DEFAULT_LANGUAGE = [us_english]
GO

USE master

GO
Grant CONNECT SQL TO [storageuserColleague]  AS [sa]
GO
Deny SHUTDOWN TO [storageuserColleague]  AS [sa]
GO
Grant VIEW ANY DATABASE TO [storageuserColleague]  AS [sa]
GO

USE [Northwind]

GO
CREATE USER [storageuserColleague] FOR LOGIN [storageuserColleague] WITH DEFAULT_SCHEMA=[dbo]
GO
Grant CONNECT TO [storageuserColleague]  AS [dbo]
GO
Grant SHOWPLAN TO [storageuserColleague]  AS [dbo]
GO

USE [Northwind]
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'storageuserColleague')
CREATE USER [storageuserColleague] FOR LOGIN [storageuserColleague] WITH DEFAULT_SCHEMA=[dbo]
GO
GRANT CONNECT TO [storageuserColleague]  AS [dbo];
GO
GRANT SHOWPLAN TO [storageuserColleague]  AS [dbo];
GO
DENY SELECT ON OBJECT::[dbo].[Employees] TO [storageuserColleague]  AS [dbo];
GO
GRANT INSERT ON OBJECT::[dbo].[Categories] TO [storageuserColleague]  AS [dbo];
GO
GRANT SELECT ON OBJECT::[dbo].[Categories] TO [storageuserColleague]  AS [dbo];
GO
GRANT SELECT ON OBJECT::[dbo].[Customers] TO [storageuserColleague]  AS [dbo];
GO

