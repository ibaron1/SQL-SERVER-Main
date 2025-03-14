	SELECT      SCHEMA_NAME(o.schema_id) as [schema], o.name as ObjName, 
		o.type as ObjType, smsp.Definition as ObjDef
	FROM
		sys.all_objects AS o
		INNER JOIN sys.sql_modules AS smsp 
		ON smsp.object_id = o.object_id
	WHERE
		SCHEMA_NAME(o.schema_id) <> N'sys'
		and smsp.definition IS NOT NULL	
		and o.type in ('P','TR','V')
	and smsp.definition like '%SRFCodes%'
		ORDER BY o.type