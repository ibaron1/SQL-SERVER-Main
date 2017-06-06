declare @schema varchar(128), @table varchar(128), @index varchar(128)

select @schema = '[schema]', @table = '[table_name]'

select @index = quotename(i.name)
from sys.indexes i inner join sys.objects o
on i.object_id = o.object_id
and o.type = 'U'
and i.name = 'cstore'
and quotename(schema_name(o.schema_id)) = @schema
and quotename(o.name) = @table

if @index is not null
  select @schema, @table, @index
-- this is a columnstore index; disable it, load data and rebuild it 