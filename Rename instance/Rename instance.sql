-- Get the current instance name
SELECT @@servername

-- Remove server from the list of known remote and linked servers on the local instance of SQL Server.
EXEC master.dbo.sp_dropserver 'CMX9001'
 
--Define the name of the local instance of SQL Server.
EXEC master.dbo.sp_addserver 'CMX9003', 'local'

-- restart instance: the new instance name will not take effect until the restart
 
--Get the new name of the SQL Server instance for comparison.
SELECT @@servername

