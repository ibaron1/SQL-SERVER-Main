select
object_name(constraint_object_id) AS FKConstraintName, 
(select SCHEMA_NAME(SCHEMA_ID) from sys.objects where object_id = a.parent_object_id) as ParentTblSchema,
object_name(parent_object_id) as ParentTblName,
col_name(parent_object_id,parent_column_id) AS ParentColumnName,
(select SCHEMA_NAME(SCHEMA_ID) from sys.objects where object_id = a.referenced_object_id) as ReferencedTblSchema,
object_name(referenced_object_id) as ReferencedTbl,
col_name(referenced_object_id,referenced_column_id) AS ReferencedColumnName
from sys.foreign_key_columns a