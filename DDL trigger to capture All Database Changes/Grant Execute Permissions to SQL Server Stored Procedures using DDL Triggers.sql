/*
To get a list of all available events: 
select * from sys.trigger_event_types 

This proc will grant execute permissions for any new procedure that is created.

Change the Rolename in this script for your environment.
*/
 
IF EXISTS (SELECT * FROM sys.triggers WHERE parent_class_desc = 'DATABASE' AND name = N'DDLTRG_StoredProcedureCreate')
 DROP TRIGGER [DDLTRG_StoredProcedureCreate] ON DATABASE
GO 
CREATE TRIGGER DDLTRG_StoredProcedureCreate
ON DATABASE
FOR Create_Procedure
/***************************************************************
Purpose: Grant execute permissions to DevUserRole for all new stored procedures created
***************************************************************/
AS
DECLARE @data XML
DECLARE @objectname VARCHAR(255)
DECLARE @DatabaseName VARCHAR(255)
DECLARE @SchemaName VARCHAR(255)
DECLARE @strsql VARCHAR(500)
 
SET @data = EVENTDATA() 
SET @objectname = @data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'varchar(256)')
SET @DatabaseName = @data.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'varchar(256)')
SET @SchemaName = @data.value('(/EVENT_INSTANCE/SchemaName)[1]', 'varchar(256)')
 
IF @SchemaName = 'DBO' --Grant execute permissions for stored procedures owned by dbo schema.
BEGIN

 SET @strsql = 'grant execute on '+@DatabaseName+'.'+@SchemaName +'.'+@objectname+' to DevUserRole'

 EXECUTE (@strsql)
 
END
 
GO