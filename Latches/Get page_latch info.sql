-- All tables/indexes from databases on instance

SELECT DB_NAME(database_id) as DB, object_name(object_id, database_id) as ObjName,
index_id,
page_io_latch_wait_in_ms,page_latch_wait_count,
row_lock_wait_count, row_lock_wait_in_ms, 
page_lock_wait_count, page_lock_wait_in_ms 
FROM sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL)
WHERE page_io_latch_wait_in_ms > 0
and object_name(object_id, database_id) not like 'sys%'
and DB_NAME(database_id) not in ('master','model','msdb','tempdb','sysdb','ssmatesterdb_syb')
order by page_latch_wait_count desc

-- All tables/indexes from databases on instance

;with cte as
(SELECT database_id, object_id,
 index_id,
page_io_latch_wait_in_ms,page_latch_wait_count,
row_lock_wait_count, row_lock_wait_in_ms, 
page_lock_wait_count, page_lock_wait_in_ms 
FROM sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL) 
WHERE page_io_latch_wait_in_ms > 0
and object_name(object_id, database_id) not like 'sys%'
and DB_NAME(database_id) not in ('master','model','msdb','tempdb','sysdb','ssmatesterdb_syb')
) 
select DB_NAME(cte.database_id) as DB, object_name(cte.object_id, cte.database_id) as ObjName,
isnull(i.name, 'heap (table)') as Index_name, cte.index_id, page_io_latch_wait_in_ms,page_latch_wait_count,row_lock_wait_count,row_lock_wait_in_ms,page_lock_wait_count,page_lock_wait_in_ms 
from cte join sys.indexes i
on cte.object_id = i.object_id and cte.index_id = i.index_id
and cte.database_id = DB_ID()
--and cte.object_id = object_id('srf_main.BCPValAgg')
order by ObjName, page_latch_wait_count desc




