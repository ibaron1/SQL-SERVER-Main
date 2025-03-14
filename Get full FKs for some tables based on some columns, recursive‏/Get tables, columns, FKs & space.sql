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

declare @FK table
( 
 ParentTblSchema varchar(20), ParentTbl varchar(200),
 ReferencedTblSchema varchar(20), ReferencedTbl varchar(200),  
 ParentColumnName varchar(200),
 ReferencedColumnName varchar(200),
 FKConstraintName varchar(100))
 
declare @tblObjId table(tbl_object_id int)

insert @tblObjId
select distinct OBJECT_ID([schema]+'.'+[Table])
from @Tables
 
;WITH FK_CTE AS 
(select constraint_object_id,
referenced_object_id, referenced_column_id,
parent_object_id,parent_column_id
from sys.foreign_key_columns a join @tblObjId b
on a.parent_object_id = b.tbl_object_id or a.referenced_object_id = b.tbl_object_id
union all
select e.constraint_object_id,
e.referenced_object_id, e.referenced_column_id,
e.parent_object_id,e.parent_column_id
from FK_CTE join sys.foreign_key_columns e  
on e.referenced_object_id = FK_CTE.parent_object_id
)
insert @FK
select  distinct
(select SCHEMA_NAME(SCHEMA_ID) from sys.objects where object_id = a.parent_object_id) as ParentTblSchema,
object_name(parent_object_id) as ParentTbl,
(select SCHEMA_NAME(SCHEMA_ID) from sys.objects where object_id = a.referenced_object_id) as ReferencedTblSchema,
object_name(referenced_object_id) as ReferencedTbl,
col_name(parent_object_id,parent_column_id) AS ParentColumnName,
col_name(referenced_object_id,referenced_column_id) AS ReferencedColumnName,
object_name(constraint_object_id) AS FKConstraintName
from FK_CTE a OPTION (MAXRECURSION 0)

declare @AllTables table([schema] varchar(20), [Table] varchar(200))

insert @AllTables
select ParentTblSchema,ParentTbl 
from @FK
union 
select ReferencedTblSchema,ReferencedTbl 
from @FK

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
         FROM @AllTables

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


select * from @Tables

select distinct isnull((c.[schema]+'.'+c.[Table]),f.ReferencedTblSchema+'.'+f.ReferencedTbl) as [Table], 
isnull(f.ParentTblSchema+'.'+f.ParentTbl,'') as [FK Table],  
[Rows], cast(round(ReservedMB,0) as int) as SpaceUsed_MB,
isnull(ParentColumnName,'') as ParentColumnName, 
isnull(ReferencedColumnName,'') as ReferencedColumnName,
isnull(FKConstraintName,'') as FKConstraintName
from @TabSpace a join  @AllTables b
on a.[Schema] = b.[schema]
and a.TabName = b.[Table]
join @FK f
on b.[schema] = f.ReferencedTblSchema and b.[Table] = f.ReferencedTbl
full join @Tables c
on f.ReferencedTblSchema = c.[schema] and f.ReferencedTbl = c.[Table]



drop table #TabSpaceTxt                