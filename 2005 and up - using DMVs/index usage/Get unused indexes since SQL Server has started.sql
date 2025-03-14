USE riskbook
go
SELECT DB_NAME() AS DB, OBJECT_NAME(I.object_id) AS Object_Name
    ,isnull(I.name,'N/A') AS Index_Name 
    ,CASE WHEN I.type = 1 THEN 'Clustered' 
          WHEN I.type = 2 THEN 'Non-Clustered' 
          ELSE 'N/A' END AS Index_Type
	,'No' AS [If index was in metadata cache]
	,'N/A' AS accessedTimes#     
FROM  sys.indexes I
WHERE I.type in (1,2)
AND NOT EXISTS 
(SELECT '1' FROM sys.dm_db_index_usage_stats
 WHERE object_id =  I.object_Id
 AND index_id= I.index_id
 AND database_id = DB_ID())
UNION
SELECT DB_NAME() AS DB, OBJECT_NAME(I.object_id) AS Object_Name
    ,isnull(I.name,'N/A') AS Index_Name 
    ,CASE WHEN I.type = 1 THEN 'Clustered' 
          WHEN I.type = 2 THEN 'Non-Clustered' 
          ELSE 'N/A' END AS Index_Type
	,'Yes' AS [If index was in metadata cache]
	,convert(varchar(20), S.user_seeks + S.user_scans + S.user_lookups) AS accessedTimes#      
FROM sys.dm_db_index_usage_stats S RIGHT JOIN sys.indexes I
  ON S.index_id= I.index_id 
 and S.object_id =  I.object_Id
 and s.database_id = DB_ID()
WHERE S.user_seeks + S.user_scans + S.user_lookups = 0
and I.type in (1,2)
order by 
[If index was in metadata cache] desc,
OBJECT_NAME(I.object_id)


