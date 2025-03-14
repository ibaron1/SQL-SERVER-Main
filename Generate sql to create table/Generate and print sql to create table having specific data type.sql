
declare @tbl varchar(200) = 'dbo.##SFreportResultSet'--null -- schema.table

declare @sql varchar(max)

select @sql = 'create table [' + schema_name(so.schema_id) + '].'+'[' + so.name + ']'+CHAR(10)+'(' + STUFF(o.list,1,2,'') + ')' + CASE WHEN tc.Constraint_Name IS NULL THEN '' ELSE 'ALTER TABLE ' + so.Name + ' ADD CONSTRAINT ' + tc.Constraint_Name  + ' PRIMARY KEY ' + ' (' + STUFF(j.List, 1,1,'') + ')' END
from    sys.objects so
cross apply
    (SELECT 
        CHAR(10)+', ['+column_name+'] ' + 
        data_type + case data_type
            when 'sql_variant' then ''
            when 'text' then ''
            when 'ntext' then ''
            when 'xml' then ''
            when 'decimal' then '(' + cast(numeric_precision as varchar) + ', ' + cast(numeric_scale as varchar) + ')'
            else coalesce('('+case when character_maximum_length = -1 then 'MAX' else cast(character_maximum_length as varchar) end +')','') end + ' ' +
        case when exists ( 
        select object_id from sys.columns
        where object_id=so.object_id
        and name=column_name
        and columnproperty(object_id,name,'IsIdentity') = 1 
        ) then
        'IDENTITY(' + 
        cast(ident_seed(so.name) as varchar) + ',' + 
        cast(ident_incr(so.name) as varchar) + ')'
        else ''
        end + ' ' +
         (case when IS_NULLABLE = 'No' then 'NOT ' else '' end ) + 'NULL ' + 
          case when information_schema.columns.COLUMN_DEFAULT IS NOT NULL THEN 'DEFAULT '+ information_schema.columns.COLUMN_DEFAULT ELSE '' END 

     from information_schema.columns where TABLE_NAME = so.name and TABLE_SCHEMA = schema_name(so.schema_id)
     order by ordinal_position
    FOR XML PATH('')) o (list)
left join
    information_schema.table_constraints tc
on  tc.Table_name       = so.Name
AND tc.Constraint_Type  = 'PRIMARY KEY'
cross apply
    (select ',[' + Column_Name + ']'
     FROM   information_schema.key_column_usage kcu
     WHERE  kcu.Constraint_Name = tc.Constraint_Name
     ORDER BY
        ORDINAL_POSITION
     FOR XML PATH('')) j (list)
where so.object_id = coalesce(object_id(@tbl), object_id(schema_name(so.schema_id)+'.'+so.name)) and 
type = 'U'
AND name    NOT IN ('dtproperties')

print @sql