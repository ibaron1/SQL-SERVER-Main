-- for all db's table columns
select (schema_name(o.schema_id)+'.'+o.name) as [Table], c.name as [Column],
t.name as [Large datatype], c.[length]
from sys.objects o join sys.syscolumns c 
on o.object_id = c.id and o.type = 'U'
join systypes t 
on c.xtype = t.xtype
and t.name in ('image','text','xml')
union
select (schema_name(o.schema_id)+'.'+o.name) as [Table], c.name as [Column],
t.name as [Large datatype], c.[length]
from sys.objects o join sys.syscolumns c 
on o.object_id = c.id and o.type = 'U'
join systypes t 
on c.xtype = t.xtype
where c.[length] = -1
and t.name <> 'sysname'

-- for columns of specific tables

declare @table table (tbl varchar(400)) 
declare @dbid int, @object_id int

insert @table
values ('srf_main.EODBusinessexception')
,('srf_main.EODTradeStage')
,('srf_main.EODTradeStatus')
,('srf_main.BCPGTRResponseData')
,('srf_main.EODTrade')

;with a_cte 
as
(select (schema_name(o.schema_id)+'.'+o.name) as [Table], c.name as [Column],
t.name as [Large datatype], c.length
from sys.objects o join sys.syscolumns c 
on o.object_id = c.id and o.type = 'U'
join systypes t 
on c.xtype = t.xtype
and t.name in ('image','text','xml')
union
select (schema_name(o.schema_id)+'.'+o.name) as [Table], c.name as [Column],
t.name as [Large datatype], c.length
from sys.objects o join sys.syscolumns c 
on o.object_id = c.id and o.type = 'U'
join systypes t 
on c.xtype = t.xtype
where c.length = -1 -- columns with max length and data types (n)varchar, (n)varbinary
and t.name <> 'sysname')
select a.* from  a_cte a
join @table b
on a.[Table] = b.tbl








