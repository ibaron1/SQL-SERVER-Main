use master
go

if exists (select '1' from sysobjects where name = 'sp_FKs')
  drop proc sp_FKs
go

CREATE PROC sp_FKs
@datatype varchar(20) = 'char',
@operation varchar(10) --ENABLE, DISABLE, DROP, CREATE  
AS

SET NOCOUNT ON

declare @schemaName sysname, @tableName sysname  
	

DECLARE 
 FK_crsr CURSOR LOCAL FORWARD_ONLY FAST_FORWARD FOR 
		select distinct user_name(o.uid) as [schema], o.name as [Table]
		from sys.columns c join sys.types t
		on t.user_type_id = c.user_type_id
		and t.name = @datatype
		join sysobjects o
		on c.object_id = o.id and o.type = 'U'
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

