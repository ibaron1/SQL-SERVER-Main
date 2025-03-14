select
index_id, partition_number, alloc_unit_type_desc ,page_count, record_count, 
min_record_size_in_bytes ,max_record_size_in_bytes, avg_record_size_in_bytes 
from sys.dm_db_index_physical_stats ( db_id() ,object_id(N'dbo.DataRows') 
,0  /* IndexId = 0 -> Table Heap */ ,
NULL /* All Partitions */ 
,'DETAILED' )

index_id	partition_number	alloc_unit_type_desc	page_count	record_count	min_record_size_in_bytes	max_record_size_in_bytes	avg_record_size_in_bytes
0		1			IN_ROW_DATA		1		1		5111				5111				5111
0		1			ROW_OVERFLOW_DATA	1		1		5014				5014				5014
0		1			LOB_DATA		4		4		7894				8054				8014