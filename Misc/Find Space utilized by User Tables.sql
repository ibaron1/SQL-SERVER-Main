
---- for the report ----

SELECT [Table Name], (SELECT rows FROM sysindexes S WHERE S.Indid < 2 AND S.ID = OBJECT_ID(a.[Table Name])) AS [Total rows], [Total Space Used in MB] FROM  
(SELECT QUOTENAME(USER_NAME(so.uid)) + '.' + QUOTENAME(OBJECT_NAME(si.id)) AS [Table Name],
CONVERT(numeric(15,2),(((CONVERT(numeric(15,2),SUM(si.Reserved)) * (SELECT low FROM master.dbo.spt_values (NOLOCK) WHERE number = 1 AND type = 'E')) / 1024.)/1024.)) AS [Total Space Used in MB]
FROM sysindexes si (NOLOCK) INNER JOIN sysobjects so (NOLOCK) 
ON    si.id = so.id AND so.type IN ('U')
WHERE indid IN (0, 1, 255)
GROUP BY QUOTENAME(USER_NAME(so.uid)) + '.' + QUOTENAME(OBJECT_NAME(si.id))
) as a
ORDER BY [Total Space Used in MB] DESC



---- to join w other tables ----

SELECT tbl, (SELECT rows FROM sysindexes S WHERE S.Indid < 2 AND S.ID = OBJECT_ID(a.tbl)) AS tbl_rows, tbl_total_space_used_MB FROM  
(SELECT OBJECT_NAME(si.id) AS tbl,
CONVERT(numeric(15,2),(((CONVERT(numeric(15,2),SUM(si.Reserved)) * (SELECT low FROM master.dbo.spt_values (NOLOCK) WHERE number = 1 AND type = 'E')) / 1024.)/1024.)) AS tbl_total_space_used_MB
FROM sysindexes si (NOLOCK) INNER JOIN sysobjects so (NOLOCK) 
ON    si.id = so.id AND so.type IN ('U')
WHERE indid IN (0, 1, 255)
GROUP BY OBJECT_NAME(si.id)
) as a
ORDER BY tbl_total_space_used_MB DESC