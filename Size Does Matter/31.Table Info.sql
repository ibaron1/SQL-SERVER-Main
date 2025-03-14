/****************************************************************************/
/*                         SQL Server Internals v3                          */
/*                           Training Materials                             */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Diagnostics Scripts                              */
/*					     Table/Index information                            */
/****************************************************************************/

use [SQLServerInternals]
go

/****************************************************************************
This script scans content of entire buffer pool, which takes significant amount of time
on the servers with large amount of RAM.

When you do the analysis across multiple databases on the same server, consider to
persist results of BufferInfo(db_id, allocation_unit_id, BuffSize) in temp table to
speed up the process
****************************************************************************/
;with BufferInfo(allocation_unit_id, BuffSize)
as
(
	select allocation_unit_id, convert(decimal(11,3),count(*) / 128.0) as BuffSize
	from sys.dm_os_buffer_descriptors with (nolock)
	where database_id = db_id()
	group by allocation_unit_id
)
,TableInfo
as
(
	select 
		t.object_id as [ObjectId], i.index_id as [IndexId],
		sch.name + '.' + t.name AS [TableName], i.name as [Index Name]
		,sum(p.[rows]) as [Rows]
		,i.is_unique as [Index Unique], i.fill_factor,
		i.is_disabled,
		i.has_filter as [Filtered],
		t.lock_escalation_desc as [Lock Escalation],
		max(p.data_compression) as [Max Compression Level],
		sum(a.total_pages) as TotalPages, 
		sum(a.used_pages) as UsedPages, 
		sum(a.data_pages) as DataPages,
		(sum(a.total_pages) * 8) / 1024 as TotalSpaceMB, 
		(sum(a.used_pages) * 8) / 1024 as UsedSpaceMB, 
		(sum(a.data_pages) * 8) / 1024 as DataSpaceMB,
		sum(bi.BuffSize) as BufferPoolSizeMb
	from 
		sys.tables t with (nolock) join sys.indexes i with (nolock) on
			t.object_id = i.object_id
		join sys.partitions p with (nolock) on 
			i.object_id = p.object_id AND i.index_id = p.index_id
		join sys.allocation_units a with (nolock) on 
			p.partition_id = a.container_id
		left join BufferInfo bi on
			a.allocation_unit_id = bi.allocation_unit_id 
		join sys.schemas sch on
			t.schema_id = sch.schema_id
	where
		t.name NOT LIKE 'dt%' and
		i.object_id > 255 --and 	
		--i.index_id <= 1
		--and i.is_disabled = 0
	group by
		sch.name, t.name, i.object_id, i.index_id, i.name, 
		i.is_unique, i.fill_factor, t.lock_escalation_desc,
		t.object_id, i.index_id, i.has_filter, i.is_disabled
)
select 
	@@SERVERNAME as [Server]
	,DB_NAME() as [Database]
	,getDate() as [OnTime]
	,ic.GuidThere
	,case ti.[Max Compression Level]
		when 0 then 'NONE'
		when 1 then 'ROW'
		when 2 then 'PAGE'
		when 3 then 'COLUMNSTORE'
		when 4 then 'COLUMNSTORE_ARCHIVE'
	end as [Max Compression Across All Partitions]
	,ti.* 
	,stats_date(ti.ObjectId, ti.IndexId) as [Statistics Date]
	,ius.*
	,ios.*
from 
	TableInfo ti cross apply
	(
		select
			case
				when exists(
					select * 
					from 
						sys.index_columns ic with (nolock) join sys.columns c with (nolock) on	
							ic.object_id = c.object_id and
							ic.column_id = c.column_id  
					where 
						ic.object_id = ti.ObjectId and 
						ic.index_id = ti.IndexId and 
						c.system_type_id = 36 --uniqueidentifier
				)
				then 'Yes'
				else 'No'
			end as [GuidThere]

	) ic  
	outer apply
	(
		select 
			ius.user_seeks as [Seeks], ius.user_scans as [Scans]
			,ius.user_lookups as [Lookups]
			,ius.user_seeks + ius.user_scans + ius.user_lookups as [Reads]
			,ius.user_updates as [Updates], ius.last_user_seek as [Last Seek]
			,ius.last_user_scan as [Last Scan], ius.last_user_lookup as [Last Lookup]
			,ius.last_user_update as [Last Update]
		from 
			sys.dm_db_index_usage_stats ius 
		where
			ius.database_id = db_id() and
			ius.object_id = ti.ObjectId and 
			ius.index_id = ti.IndexId
	) ius
	outer apply
	(
		select 
			sum(range_scan_count) as range_scan_count
			,sum(singleton_lookup_count) as singleton_lookup_count
			,sum(row_lock_wait_count) as row_lock_wait_count
			,sum(row_lock_wait_in_ms) as row_lock_wait_in_ms
			,sum(page_lock_wait_count) as page_lock_wait_count
			,sum(page_lock_wait_in_ms) as page_lock_wait_in_ms
			,sum(page_latch_wait_count) as page_latch_wait_count
			,sum(page_latch_wait_in_ms) as page_latch_wait_in_ms
			,sum(page_io_latch_wait_count) as page_io_latch_wait_count
			,sum(page_io_latch_wait_in_ms) as page_io_latch_wait_in_ms
		from sys.dm_db_index_operational_stats(db_id(),ti.ObjectId,ti.IndexId,0)
	) ios
order by 
	ti.Rows desc
option (recompile, maxdop 1);
go

