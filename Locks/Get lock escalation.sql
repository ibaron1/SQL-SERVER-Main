SELECT s.name as schemaname, object_name (t.object_id) as table_name, t.lock_escalation_desc
FROM sys.tables t, sys.schemas s
WHERE object_name(t.object_id) = 'Product' 
and s.name = 'Production' 
and s.schema_id = t.schema_id 