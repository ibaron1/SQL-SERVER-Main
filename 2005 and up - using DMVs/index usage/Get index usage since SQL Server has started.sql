SELECT DB_NAME() AS DB, OBJECT_NAME(S.object_id) AS Object_Name
    ,isnull(I.name,'') Index_Name 
    ,CASE WHEN I.type = 0 THEN 'Heap'
	  WHEN I.type = 1 THEN 'Clustered' 
          WHEN I.type = 2 THEN 'Non-Clustered'
          WHEN I.type = 3 THEN 'XML'  
          ELSE 'N/A' END AS Index_Type 
	,S.user_seeks + S.user_scans + S.user_lookups AS accessedTimes#     
    ,S.user_seeks
    ,S.user_scans
    ,S.user_lookups
FROM sys.dm_db_index_usage_stats S JOIN sys.indexes I
  ON S.index_id= I.index_id 
 and S.object_id =  I.object_Id
 and s.database_id = DB_ID()
and S.user_seeks + S.user_scans + S.user_lookups > 0 
--order by accessedTimes# desc
order by OBJECT_NAME(S.object_id), I.name
