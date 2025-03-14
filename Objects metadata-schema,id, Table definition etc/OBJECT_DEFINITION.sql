https://learn.microsoft.com/en-us/sql/t-sql/functions/object-definition-transact-sql?view=sql-server-ver16

OBJECT_DEFINITION ( object_id ) 

Return Types
nvarchar(max)

Returns NULL on error or if a caller does not have permission to view the object.

USE AdventureWorks2022;  
GO  
SELECT OBJECT_DEFINITION (OBJECT_ID(N'Person.uAddress')) AS [Trigger Definition];   
GO  

The following example returns the definition of the system stored procedure sys.sp_columns

USE AdventureWorks2022;  
GO  
SELECT OBJECT_DEFINITION (OBJECT_ID(N'sys.sp_columns')) AS [Object Definition];  
GO