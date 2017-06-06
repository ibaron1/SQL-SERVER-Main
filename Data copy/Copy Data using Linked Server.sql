declare @sql varchar(400)
set @sql='select * from cmxdb.dbo.ero_line'
SET @sql = N'select * from OPENQUERY(LINK_cmx7992, ''' + REPLACE(@sql, '''', '''''') + ''')'
--PRINT @sql
insert into ero_line
EXEC (@sql)
