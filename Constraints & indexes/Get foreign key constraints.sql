declare @Tables table(	TABLE_SCHEMA sysname
                      , TabName sysname )

insert @Tables
select TABLE_SCHEMA, TABLE_NAME
from INFORMATION_SCHEMA.TABLES
where TABLE_TYPE = 'BASE TABLE'


SELECT f.name AS ForeignKey,
(select TABLE_SCHEMA from @Tables where TabName = object_name(f.parent_object_id)) as TableSchema,
OBJECT_NAME(f.parent_object_id) AS TableName,
COL_NAME(fc.parent_object_id,
fc.parent_column_id) AS ColumnName,
(select TABLE_SCHEMA from @Tables where TabName = object_name(f.referenced_object_id)) as ReferenceTableSchema,
OBJECT_NAME (f.referenced_object_id) AS ReferenceTableName,
COL_NAME(fc.referenced_object_id,
fc.referenced_column_id) AS ReferenceColumnName
FROM sys.foreign_keys AS f
INNER JOIN sys.foreign_key_columns AS fc
ON f.OBJECT_ID = fc.constraint_object_id