use master
go

if exists (select '1' from sysobjects where name = 'sp_allFKs')
  drop proc sp_allFKs
go

CREATE PROC sp_allFKs
@operation varchar(10) --ENABLE, DISABLE, DROP, CREATE  
AS

SET NOCOUNT ON

declare @schemaName sysname, @tableName sysname  
	

DECLARE 
 FK_crsr CURSOR LOCAL FORWARD_ONLY FAST_FORWARD FOR 
		select user_name(o.uid) as [schema], o.name as [Table]
		from sysobjects o
		where o.type = 'U'

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

exec sys.sp_MS_marksystemobject sp_allFKs
go
grant execute on sp_allFKs to public
go

