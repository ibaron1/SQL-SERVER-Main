To find the schema name using an object_id in SQL Server, you can use the OBJECT_SCHEMA_NAME function:

Syntax: OBJECT_SCHEMA_NAME(object_id [, database_id ] )

Example: SELECT DISTINCT OBJECT_SCHEMA_NAME(object_id) FROM master.sys.objects 

The OBJECT_ID function returns the database object identification number for a schema-scoped object. Objects that aren't schema-scoped, like DDL triggers, can't be queried using OBJECT_ID. 

OBJECT_SCHEMA_NAME (Transact-SQL) - SQL Server
Sep 3, 2024 — * OBJECT_SCHEMA_NAME ( object_id [, database_id ] ) * SELECT DISTINCT OBJECT_SCHEMA_NAME(object_id) FROM master. sys.

Microsoft Learn
OBJECT_ID (Transact-SQL) - SQL Server - Microsoft Learn
Sep 3, 2024 — Returns the database object identification number of a schema-scoped object. Objects that aren't schema-scoped, such as DDL triggers

Microsoft Learn
