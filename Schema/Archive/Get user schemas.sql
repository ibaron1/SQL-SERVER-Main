SELECT 
    s.name AS schema_name, 
    u.name AS schema_owner
FROM 
    sys.schemas s
INNER JOIN sys.sysusers u ON u.uid = s.principal_id
where s.schema_id > 4 and schema_id < 16384 -- system schemas
ORDER BY 
    s.name;


	select * FROM 
    sys.schemas
	where schema_id > 4 and schema_id < 16384 -- system schemas