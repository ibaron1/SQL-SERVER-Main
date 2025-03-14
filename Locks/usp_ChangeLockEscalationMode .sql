/*In order to control the lock escalation I have created a stored procedure that gets the desired lock escalation mode, the schema name and the table name or partial table name for changing the lock escalation mode on multiple tables with a similar pattern.
So for example if we pass in the value 'order', any table that has order in the name will be changed. As a safeguard, I also added a pattern length parameter. The default is five characters, but this can be overridden if there is a need to search for larger or smaller pattern matches like 'ord'. Lastly, it will only update user tables and not system tables by using the is_ms_shipped column.
Here is the stored procedure T-SQL code. This will print out the ALTER TABLE statements, but if you want to execute them you can uncomment the EXEC (@tsql) line. The @mode value should be AUTO or DISABLE.
*/
CREATE PROCEDURE dbo.usp_ChangeLockEscalationMode 
   (@mode varchar(10),
   @schema varchar(30),
   @tableNamepattern varchar(30),
   @patternLen int = 5)
AS
BEGIN
   DECLARE @tsql varchar(200)
   DECLARE @tablename varchar(60)
 
   DECLARE cur CURSOR FOR
    ( SELECT object_name (t.object_id) as table_name
      FROM sys.tables t , sys.schemas s
      WHERE charindex ( @tableNamepattern , object_name (t.object_id) ,1) > 0 
       and s.schema_id = t.schema_id 
       and s.name = @schema
       and t.is_ms_shipped = 0
       and len(@tableNamepattern) >= @patternLen )
   
   OPEN cur
   FETCH NEXT FROM cur INTO @tablename
 
   WHILE @@FETCH_STATUS = 0
   BEGIN
      SET @tsql = 'ALTER TABLE ' + @schema + '.[' + @tableName + ']'+ ' SET ' + 
      '( LOCK_ESCALATION = ' + @mode + ' )'

      PRINT @tsql 
      --EXEC (@tsql)

      FETCH NEXT FROM cur INTO @tablename
   END

   CLOSE cur
   DEALLOCATE cur
END
GO 
--An example for using the procedure
--In the Northwind database, DISABLE lock escalation for both the Orders and [Order Details] tables
USE Northwind
GO

EXEC dbo.usp_ChangeLockEscalationMode @mode = 'DISABLE', @schema = 'dbo', @tableNamepattern = 'Order'
GO
--Now check the lock escalation mode:
SELECT s.name as schemaname,object_name (t.object_id) as table_name,t.lock_escalation_desc
FROM sys.tables t, sys.schemas s
WHERE object_name (t.object_id) like '%order%' 
and s.name = 'dbo' 
and s.schema_id = t.schema_id 
