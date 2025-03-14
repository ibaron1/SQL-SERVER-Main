select DB_NAME(database_id) as DbName, object_name(object_id) as ObjectName, 
index_id , partition_number 
page_compression_attempt_count, page_compression_success_count
from sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL) s
where DB_NAME(database_id) not in 
('master','tempdb','msdb', 'model','ReportServer','ReportServerTempDB')
and object_name(object_id) not like 'sys%'
