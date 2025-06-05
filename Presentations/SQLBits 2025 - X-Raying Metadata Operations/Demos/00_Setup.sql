/*
	Create an empty database with SIMPLE recovery model
*/

USE [master]
GO

DROP DATABASE IF EXISTS XRaying
GO

CREATE DATABASE XRaying
GO

ALTER DATABASE [XRaying] SET RECOVERY SIMPLE WITH NO_WAIT
GO