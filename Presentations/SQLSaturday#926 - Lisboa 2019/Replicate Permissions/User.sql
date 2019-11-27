USE [Northwind]
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'storageuser')
CREATE USER [storageuser] FOR LOGIN [storageuser] WITH DEFAULT_SCHEMA=[dbo]
GO
GRANT CONNECT TO [storageuser]  AS [dbo];
GO
GRANT SHOWPLAN TO [storageuser]  AS [dbo];
GO
DENY SELECT ON OBJECT::[dbo].[Employees] TO [storageuser]  AS [dbo];
GO
GRANT INSERT ON OBJECT::[dbo].[Categories] TO [storageuser]  AS [dbo];
GO
GRANT SELECT ON OBJECT::[dbo].[Categories] TO [storageuser]  AS [dbo];
GO
GRANT SELECT ON OBJECT::[dbo].[Customers] TO [storageuser]  AS [dbo];
GO
