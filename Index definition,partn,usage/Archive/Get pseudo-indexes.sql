SELECT schema_name(schema_id)+'.'+o.name as tblName, i.name as indexName, indid, reserved*8/1024.0 as reserved_MB, 
used*8/1024.0 as used_MB
FROM sysindexes i join sys.objects o
on i.id = o.object_id and type = 'U'
WHERE indid >=1
order by 1