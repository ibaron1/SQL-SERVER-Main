

declare @table varchar(400) 
declare @dbid int, @object_id int

set @table = 'KdbLocalTablesT'
select @object_id = object_id(@table), @dbid = db_id()


select db_name(database_id) dbname, object_id, index_id, index_type_desc, 
alloc_unit_type_desc,			--Description of the allocation unit type: IN_ROW_DATA, LOB_DATA, ROW_OVERFLOW_DATA
index_depth,					--Number of index levels 
index_level,					--Current level of the index: 0 for index leaf levels, heaps, and LOB_DATA or 								--ROW_OVERFLOW_DATA allocation units.
								--Greater than 0 for nonleaf index levels. index_level will be  								--the highest at the root level of an index.
avg_fragmentation_in_percent,	--Logical fragmentation for indexes, or extent fragmentation for heaps 								--in the IN_ROW_DATA allocation unit. 
								--The value is measured as a percentage and takes into account								-- multiple files.
								-- 0 for LOB_DATA and ROW_OVERFLOW_DATA allocation units.
								-- NULL for heaps when mode = SAMPLED.
fragment_count,					--Number of fragments in the leaf level of an IN_ROW_DATA allocation unit. 
								--NULL for nonleaf levels of an index, and LOB_DATA or 								--ROW_OVERFLOW_DATA allocation units. 
avg_fragment_size_in_pages,		--Average number of pages in one fragment in the leaf level of 								--an IN_ROW_DATA allocation unit.
								--NULL for nonleaf levels of an index, and LOB_DATA or 
								--ROW_OVERFLOW_DATA allocation units.
								--NULL for heaps when mode = SAMPLED.
page_count,						--Total number of index or data pages.
								--For an index, the total number of index pages in the current level 
								--of the b-tree in the IN_ROW_DATA allocation unit.
								--For a heap, the total number of data pages in the IN_ROW_DATA 
								--allocation unit.
								--For LOB_DATA or ROW_OVERFLOW_DATA allocation units, total number 
								--of pages in the allocation unit.
avg_page_space_used_in_percent,	--Average percentage of available data storage space used in all pages.
								--For an index, average applies to the current level of the b-tree 
								--in the IN_ROW_DATA allocation unit.
								--For a heap, the average of all data pages in 								--the IN_ROW_DATA allocation unit.
								--For LOB_DATA or ROW_OVERFLOW DATA allocation units, the average of 
								--all pages in the allocation unit.
								--NULL when mode = LIMITED. 
record_count,					--Total number of records
								--For an index, total number of records applies to the current level 
								--of the b-tree in the IN_ROW_DATA allocation unit.
								--For a heap, the total number of records in 								--the IN_ROW_DATA allocation unit.
forwarded_record_count			--Number of records in a heap that have forward pointers to another data location. 								--(This state occurs during an update, when there is not enough room 
								--to store the new row in the original location.)
								--NULL for any allocation unit other than the IN_ROW_DATA allocation 
								--units for a heap or for heaps when mode = LIMITED.			
into #indexstats
from sys.dm_db_index_physical_stats(@dbid, @object_id, NULL, NULL, 'DETAILED')
 
select dbname as [Database], object_name(i.object_id) AS TableName,
i.name AS IndexName,
index_type_desc, alloc_unit_type_desc, index_depth, index_level, avg_fragmentation_in_percent, fragment_count, avg_fragment_size_in_pages, page_count,
avg_page_space_used_in_percent, record_count, forwarded_record_count
from #indexstats indexstats left join sys.indexes i 
on i.object_id = indexstats.OBJECT_ID
and i.index_id = indexstats.index_id

/* SQL TO DEFRAG  */
select distinct 'ALTER INDEX '+i.name+' ON '+object_name(indexstats.object_id)+' REBUILD WITH (SORT_IN_TEMPDB = ON, MAXDOP = 1)' as [Sql to defragment indexes]
from #indexstats indexstats join sys.indexes i 
on i.object_id = indexstats.OBJECT_ID
and i.index_id = indexstats.index_id
and avg_fragmentation_in_percent >= 5 and 
(index_level in (0,1) or (index_level >= 2 and page_count >= 100))
and i.name is not null

select distinct 'exec sp_recompile '+object_name(indexstats.object_id)
from #indexstats indexstats join sys.indexes i 
on i.object_id = indexstats.OBJECT_ID
and i.index_id = indexstats.index_id
and avg_fragmentation_in_percent >= 5 and index_level in (0,1)
and i.name is not null

drop table #indexstats
go

