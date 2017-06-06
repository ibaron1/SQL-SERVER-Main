set nocount on

declare  @SourceDB varchar(128) = db_name()
declare @instance varchar(200) = @@servername
declare @sql nvarchar(4000) 

declare @Tables table(Instance varchar(200), DbName varchar(100), [schema] varchar(20), [Table] varchar(200), ColumnName varchar(200))

insert @Tables
select @instance as Instance, @SourceDB as DbName, schema_name(o.schema_id) as [schema], o.name as [Table], c.name as ColumnName
from sys.objects o
join sys.columns c
on c.object_id = o.object_id and o.type = 'U'
where lower(c.name) like '%maturi%' 
union all
select @instance as Instance, @SourceDB as DbName, schema_name(o.schema_id) as [schema], o.name as [Table], c.name as ColumnName
from sys.objects o
join sys.columns c
on c.object_id = o.object_id and o.type = 'U'
where lower(c.name) like '%terminat%' 
union all
select @instance as Instance, @SourceDB as DbName, schema_name(o.schema_id) as [schema], o.name as [Table], c.name as ColumnName
from sys.objects o
join sys.columns c
on c.object_id = o.object_id and o.type = 'U'
where lower(c.name) like '%event%' 

---------------------------------------------------------------
-- #TabSpaceTxt Holds the results of sp_spaceused. 
-- It Doesn't have Schema Info!
create table #TabSpaceTxt (
                         TabName sysname
	                   , [Rows] varchar (11)
	                   , Reserved varchar (18)
					   , Data varchar (18)
	                   , Index_Size varchar ( 18 )
	                   , Unused varchar ( 18 )
                       )
					
---------------------------------------------------------------
-- The result table, with numeric results and Schema name.
declare @TabSpace table ( [Schema] sysname
                       , TabName sysname
	                   , [Rows] bigint
	                   , ReservedMB numeric(18,3)
					   , DataMB numeric(18,3)
	                   , Index_SizeMB numeric(18,3)
	                   , UnusedMB numeric(18,3)
                       )
                       
DECLARE @Tab sysname -- table name
      , @Sch sysname -- owner,schema

DECLARE TableCursor CURSOR FOR
    SELECT [schema], [Table] 
         FROM @Tables

OPEN TableCursor;
FETCH TableCursor into @Sch, @Tab;

WHILE @@FETCH_STATUS = 0 BEGIN

	SELECT @sql = 'exec [' + @SourceDB 
	   + ']..sp_executesql N''insert #TabSpaceTxt exec sp_spaceused '
	   + '''''[' + @Sch + '].[' + @Tab + ']' + '''''''';

	Delete from #TabSpaceTxt; -- Stores 1 result at a time
	EXEC (@sql);

    INSERT INTO @TabSpace
	SELECT @Sch
	     , [TabName]
         , convert(bigint, rows)
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(reserved, len(reserved)-3)) / 1024.0) 
                ReservedMB
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(data, len(data)-3)) / 1024.0) DataMB
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(index_size, len(index_size)-3)) / 1024.0) 
                 Index_SizeMB
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(unused, len([Unused])-3)) / 1024.0) 
                [UnusedMB]
        FROM #TabSpaceTxt;

	FETCH TableCursor into @Sch, @Tab;
END;

CLOSE TableCursor;
DEALLOCATE TableCursor;

declare @FK table
(FKConstraintName varchar(100), 
 ParentTblSchema varchar(20), ParentTblName varchar(200), ParentColumnName varchar(200),
 ReferencedTblSchema varchar(20), ReferencedTbl varchar(200), ReferencedColumnName varchar(200))
 
insert @FK
select
object_name(constraint_object_id) AS FKConstraintName, 
(select SCHEMA_NAME(SCHEMA_ID) from sys.objects where object_id = a.parent_object_id) as ParentTblSchema,
object_name(parent_object_id) as ParentTblName,
col_name(parent_object_id,parent_column_id) AS ParentColumnName,
(select SCHEMA_NAME(SCHEMA_ID) from sys.objects where object_id = a.referenced_object_id) as ReferencedTblSchema,
object_name(referenced_object_id) as ReferencedTbl,
col_name(referenced_object_id,referenced_column_id) AS ReferencedColumnName
from sys.foreign_key_columns a


select * from @Tables

select distinct b.[schema]+'.'+TabName as [Table], [Rows], cast(round(ReservedMB,0) as int) as ReservedMB,
isnull(FKConstraintName,'') as FKConstraintName, isnull((ReferencedTblSchema+'.'+ReferencedTbl),'') as [Child table], isnull(ParentColumnName,'') as ParentColumnName, 
isnull(ReferencedColumnName,'') as ReferencedColumnName
from @TabSpace a join  @Tables b
on a.[Schema] = b.[schema]
and a.TabName = b.[Table]
left join @FK f
on b.[schema] = f.ParentTblSchema and b.[Table] = f.ParentTblName


drop table #TabSpaceTxt                