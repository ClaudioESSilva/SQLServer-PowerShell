-- Login permissions
USE [master]
GO
GRANT VIEW ANY DATABASE TO [storageuser]
GO
DENY SHUTDOWN TO [storageuser]
GO

-- User level
USE [Northwind]
GO
CREATE USER [storageuser] FOR LOGIN [storageuser] WITH DEFAULT_SCHEMA=[dbo]
GO
use [Northwind]
GO
GRANT SHOWPLAN TO [storageuser]
GO
use [Northwind]
GO
GRANT INSERT ON [dbo].[Categories] TO [storageuser]
GO
use [Northwind]
GO
GRANT SELECT ON [dbo].[Categories] TO [storageuser]
GO
use [Northwind]
GO
DENY SELECT ON [dbo].[Employees] TO [storageuser]
GO
use [Northwind]
GO
GRANT SELECT ON [dbo].[Customers] TO [storageuser]
GO
