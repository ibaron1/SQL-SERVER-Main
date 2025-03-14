-- Indexes only
SELECT @@servername as Instance, schema_name(schema_id)+'.'+o.name as tblName, i.name as indexName, indid, reserved*8/1024.0 as reserved_MB, 
used*8/1024.0 as used_MB
FROM sysindexes i join sys.objects o
on i.id = o.object_id and type = 'U'
WHERE indid >=1
order by reserved_MB desc

-- Tables only
SELECT @@servername as Instance, schema_name(schema_id)+'.'+o.name as tblName, isnull(i.name,'heap - table') as indexName, indid, reserved*8/1024.0 as reserved_MB, 
used*8/1024.0 as used_MB
FROM sysindexes i join sys.objects o
on i.id = o.object_id and type = 'U'
WHERE indid  = 0
order by reserved_MB desc

-- Tables and their indexes



-- Space used for some tables and their indexes
SELECT @@servername as Instance, schema_name(schema_id)+'.'+o.name as tblName, sum(reserved*8/1024.0) as reserved_MB, 
sum(used*8/1024.0) as used_MB
FROM sysindexes i join sys.objects o
on i.id = o.object_id and type = 'U'
--WHERE indid in (0,1)
where schema_name(schema_id)+'.'+o.name in ('srf_main.BCPValAgg','srf_main.EODBusinessException')
group by schema_name(schema_id)+'.'+o.name
order by reserved_MB desc
