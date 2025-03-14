-- by file and its type
SELECT db_name(b.database_id) as DbName,
   b.type_desc,
   a.filename AS [File Name],
   CAST(a.size/128.0 AS DECIMAL(10,2)) AS [Size in MB],
   CAST(FILEPROPERTY(a.name, 'SpaceUsed')/128.0 AS DECIMAL(10,2)) AS [Space Used],
   CAST(a.size/128.0-(FILEPROPERTY(a.name, 'SpaceUsed')/128.0) AS DECIMAL(10,2)) AS [Available Space],
   CAST((CAST(FILEPROPERTY(a.name, 'SpaceUsed')/128.0 AS DECIMAL(10,2))/CAST(a.size/128.0 AS DECIMAL(10,2)))*100 AS DECIMAL(10,2)) AS [Percent Used]
FROM sysfiles a join master.sys.master_files b
on a.fileid = b.file_id
where db_name(b.database_id) = db_name()
order by b.type_desc desc

-- summary for db by data and log portion
SELECT db_name(b.database_id) as DbName,
   b.type_desc,
   sum(CAST(a.size/128.0 AS DECIMAL(10,2))) AS [Size in MB],
   sum(CAST(FILEPROPERTY(a.name, 'SpaceUsed')/128.0 AS DECIMAL(10,2))) AS [Space Used],
   sum(CAST(a.size/128.0-(FILEPROPERTY(a.name, 'SpaceUsed')/128.0) AS DECIMAL(10,2))) AS [Available Space],
   CAST(sum(CAST(FILEPROPERTY(a.name, 'SpaceUsed')/128.0 AS DECIMAL(10,2)))/sum(CAST(a.size/128.0 AS DECIMAL(10,2)))*100 AS DECIMAL(10,2)) AS [Percent Used]
FROM sysfiles a join master.sys.master_files b
on a.fileid = b.file_id
where db_name(b.database_id) = db_name()
group by b.database_id, b.type_desc 

/*
filename is visible to dbcreator, sysadmin, the database owner with CREATE ANY DATABASE permissions, or grantees that have any one of the following permissions: ALTER ANY DATABASE, CREATE ANY DATABASE, VIEW ANY DEFINITION”  (SQL Server Online Help
*/

	