use master
go

if exists (select '1' from sysobjects where name = 'sp_FKs')
  drop proc sp_FKs
go

CREATE PROC sp_FKs
@datatype varchar(20),
@operation varchar(10) --ENABLE, DISABLE, DROP, CREATE  
AS

SET NOCOUNT ON

declare @schemaName sysname, @tableName sysname  
	

DECLARE 
 FK_crsr CURSOR LOCAL FORWARD_ONLY FAST_FORWARD FOR 
		select distinct SCHEMA_NAME(o.schema_id), o.name as [Table]
		from sys.objects o join sys.indexes i
		on o.object_id = i.object_id and o.type = 'U'
		order by 2,1

OPEN FK_crsr

WHILE 1 = 1
BEGIN

  		 FETCH FK_crsr INTO @schemaName, @tableName
 
  		 IF @@FETCH_STATUS <> 0
			BREAK

		 EXEC sp_FKoperation @operation, @tableName, @schemaName  


END

CLOSE FK_crsr
DEALLOCATE FK_crsr

GO

exec sys.sp_MS_marksystemobject sp_FKs
go
grant execute on sp_FKs to public
go

