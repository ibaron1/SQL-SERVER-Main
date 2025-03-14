SELECT KCU.table_name,
KCU.column_name field_name,
TC.constraint_type,
CASE TC.is_deferrable WHEN 'NO' THEN 0 ELSE 1 END 'is_deferrable',
CASE TC.initially_deferred WHEN 'NO' THEN 0 ELSE 1 END 'is_deferred',
rc.match_option 'match_type',
rc.update_rule 'on_update',
rc.delete_rule 'on_delete',
ccu.table_name 'references_table',
ccu.column_name 'references_field',
KCU.ordinal_position 'field_position'
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU
LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC
ON KCU.table_name =TC.table_name
AND KCU.table_schema =TC.table_schema
AND KCU.table_catalog =TC.table_catalog
AND KCU.constraint_catalog =TC.constraint_catalog
AND KCU.constraint_name =TC.constraint_name
LEFT JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
ON rc.constraint_schema =TC.constraint_schema
AND rc.constraint_catalog =TC.constraint_catalog
AND rc.constraint_name =TC.constraint_name
LEFT JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu
ON rc.unique_constraint_schema = ccu.constraint_schema
AND rc.unique_constraint_catalog = ccu.constraint_catalog
AND rc.unique_constraint_name = ccu.constraint_name
WHERE KCU.constraint_catalog = DB_NAME()
ORDER BY KCU.constraint_name,
KCU.ordinal_position;
