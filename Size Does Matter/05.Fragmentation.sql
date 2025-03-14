/****************************************************************************/
/*    Size Does Matter: 10 Ways to Reduce DB Size and Improve Performance   */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                        Internal Fragmentation                            */
/****************************************************************************/
use [SQLServerInternals]
go

select 
    index_id, partition_number, alloc_unit_type_desc
    ,index_level, page_count, page_count * 8 / 1024 as [Size MB]
	, avg_page_space_used_in_percent
from 
    sys.dm_db_index_physical_stats
    (
        db_id() /*Database */
        ,object_id(N'dbo.Customers') /* Table (Object_ID) */
        ,1 /* Index ID */
        ,null /* Partition ID – NULL – all partitions */
        ,'detailed' /* Mode */
    )
go


-- Size of the Clustered Index:
-- Number of Pages:
-- Logical Reads: 
-- Time:
dbcc dropcleanbuffers
set statistics io, time on
select max(CreditLimit) from dbo.Customers option (maxdop 1)
set statistics io, time off
go

;with Buffers(allocation_unit_id,pages,free_space)
as
(
	select
		allocation_unit_id
		,count(*) as pages
		,sum(convert(bigint,free_space_in_bytes)) as free_space
	from sys.dm_os_buffer_descriptors
	where database_id = DB_ID ('SQLServerInternals')
	group by allocation_unit_id
)
select
    p.object_id
	,p.index_id
	,object_name(p.object_id) as [Table]
	,i.Name as [Index]
	,i.type_desc as [Type]
	,b.Pages
	,b.Pages * 8. / 1024 as [Size MB]
	,b.free_space / 1024. / 1024 as [Free Space]
from
	Buffers b join sys.allocation_units au on 
		au.allocation_unit_id = b.allocation_unit_id
	join sys.partitions p on
		au.container_id = p.partition_id
	join sys.indexes i on
		i.index_id = p.index_id and
		p.object_id = i.object_id
where
	p.object_id > 100
order by 
	[Size MB] desc
go

alter index IDX_Customers_CustomerID on dbo.Customers rebuild with (fillfactor=100)
go

if object_id('tempdb..#TempUID') is not null drop table #TempUID
create table #TempUID(ID uniqueidentifier default NEWID(), Num int)
go

declare
	@I int = 200
	,@X xml

select @X = 
	(select * from master.sys.objects for xml raw, root('Data')) 

truncate table #TempUID
	 
;with n1(c) as (select 0 union all select 0) -- 2 rows
,n2(c) as (select 0 from n1 as t1 cross join n1 as t2) -- 4 rows
,n3(c) as (select 0 from n2 as t1 cross join n2 as t2) -- 16 rows
,n4(c) as (select 0 from n3 as t1 cross join n3 as t2) -- 256 rows
,n5(c) as (select 0 from n4 as t1 cross join n4 as t2) -- 65,536 rows
,ids(id) as (select row_number() over (order by (select null)) from n5)
	insert into #TempUID(Num) 
		select ID from Ids

insert into dbo.Customers(CustomerId, CustomerNumber, CustomerName, CreditLimit, Attributes)
	select ID 
		,convert(nvarchar(16),@I * 65536 + 1 + Num)
		,N'Customer ' + convert(nvarchar(48),ID)
		,Abs(CheckSum(ID))
		,iif(Num % 100 = 0, @X, NULL)
	from #TempUID
go

select 
    index_id, partition_number, alloc_unit_type_desc
    ,index_level, page_count, page_count * 8 / 1024 as [Size MB]
	, avg_page_space_used_in_percent
from 
    sys.dm_db_index_physical_stats
    (
        db_id() /*Database */
        ,object_id(N'dbo.Customers') /* Table (Object_ID) */
        ,1 /* Index ID */
        ,null /* Partition ID – NULL – all partitions */
        ,'detailed' /* Mode */
    )
go


alter index IDX_Customers_CustomerID on dbo.Customers rebuild with (fillfactor=100)
go