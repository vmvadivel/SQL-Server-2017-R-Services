EXECUTE sp_configure 'external scripts enabled', 1;
GO
RECONFIGURE;
GO

--After this Restart SQL Server Services to take effect
