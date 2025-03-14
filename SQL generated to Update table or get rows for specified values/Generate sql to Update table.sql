-- generate update statement
set nocount on

declare 
@schema varchar(20) = 'srfcache', 
@tbl varchar(128) = 'D_SDSRefData'

declare @a table (clmn varchar(200))

;WITH ClmnNum(rowNumber,ColumnName) as
(
select ROW_NUMBER() over (order by c.column_id ) as rowNumber,
c.name as ColumnName
from sys.columns c join sys.types t
on t.user_type_id = c.user_type_id
and t.name = 'varchar'
join sys.objects o
on c.object_id = o.object_id 
where user_name(o.schema_id) = @schema and o.name = @tbl
) 
insert @a
select case rowNumber when 1 then '' else ',' end+
+ColumnName+'='+'CASE '+ColumnName+' WHEN ''NULL'' THEN NULL ELSE '+ColumnName+' END'
from ClmnNum
order by rowNumber


select ' UPDATE '+@schema+'.'+@tbl+' SET'
union all
select * from @a






