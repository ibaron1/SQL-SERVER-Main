https://learn.microsoft.com/en-us/sql/t-sql/functions/object-schema-name-transact-sql?view=sql-server-ver16

OBJECT_SCHEMA_NAME ( object_id [, database_id ] )  

Return Types
sysname

Exceptions
Returns NULL on error or if a caller does not have permission to view the object.

SELECT DISTINCT OBJECT_SCHEMA_NAME(object_id)  
FROM master.sys.objects;  

The following example returns the database, schema, and object name for all objects in the current database context.

SELECT QUOTENAME(DB_NAME(db_id()))   
    + N'.'   
    + QUOTENAME(OBJECT_SCHEMA_NAME(object_id, db_id()))   
    + N'.'   
    + QUOTENAME(OBJECT_NAME(object_id, db_id()))  
    , *   
FROM sys.objects;
GO



The following example returns the object schema name, object name, and SQL text for all cached query plans that are not ad hoc or prepared statements.

SELECT DISTINCT OBJECT_SCHEMA_NAME(object_id, 1) AS schema_name  
FROM master.sys.objects; 

SELECT DB_NAME(st.dbid) AS database_name,   
    OBJECT_SCHEMA_NAME(st.objectid, st.dbid) AS schema_name,  
    OBJECT_NAME(st.objectid, st.dbid) AS object_name,   
    st.text AS query_statement  
FROM sys.dm_exec_query_stats AS qs  
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st  
WHERE st.objectid IS NOT NULL;  
GO  