/****************************************************************************/
/*    Size Does Matter: 10 Ways to Reduce DB Size and Improve Performance   */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                            Compression                                   */
/****************************************************************************/
use SQLServerInternals
go



if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Data_None' and s.name = 'dbo') drop table dbo.Data_None;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Data_Row' and s.name = 'dbo') drop table dbo.Data_Row;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Data_Page' and s.name = 'dbo') drop table dbo.Data_Page;
go


select 
	c.*, m.*, replicate(convert(varchar(max),'A'),8100) as LOB
into Data_None
from
	(
		select top 50 CustomerId -- use 50 with LOB
		from dbo.Customers 
	) c 
	cross apply
	(
		select *
		from master.sys.objects
	) m

select * 
into dbo.Data_Row
from dbo.Data_None;

select * 
into dbo.Data_Page
from dbo.Data_None;
go

alter table dbo.Data_Row rebuild
with (data_compression=row);

alter table dbo.Data_Page rebuild
with (data_compression=page);

select 
	s.name + '.' + t.name as [Table]
	,i.alloc_unit_type_desc
	,sum(i.page_count) as [Pages]
	,sum(i.page_count * 8 / 1024) as [Size MB]
from 
	sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	cross apply 
		sys.dm_db_index_physical_stats
		(
			db_id() /*Compressionbase */
			,t.object_id
			,0 /* Index ID */
			,null /* Partition ID ? NULL ? all partitions */
			,'detailed' /* Mode */
		) i
where
	s.name = 'dbo' and t.name in ('Data_None','Data_Row','Data_Page')
group by 
	s.name, t.name, i.alloc_unit_type_desc
go

set statistics time on
select count(*) from dbo.Data_None option (maxdop 1)
select count(*) from dbo.Data_Row option (maxdop 1)
select count(*) from dbo.Data_Page option (maxdop 1)
set statistics time off
go

set statistics time on
update top (100000) dbo.Data_None set object_id += 1 option (maxdop 1)
update top (100000) dbo.Data_Row set object_id += 1 option (maxdop 1)
update top (100000) dbo.Data_Page set object_id += 1 option (maxdop 1)
set statistics time off
go

set statistics time on
alter table dbo.Data_None rebuild
with (data_compression=none, maxdop=1);

alter table dbo.Data_Row rebuild
with (data_compression=row, maxdop=1);

alter table dbo.Data_Page rebuild
with (data_compression=page, maxdop=1);
set statistics time off
go


