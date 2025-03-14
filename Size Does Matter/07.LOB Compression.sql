/****************************************************************************/
/*    Size Does Matter: 10 Ways to Reduce DB Size and Improve Performance   */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                          LOB Compression                                 */
/****************************************************************************/
use [SQLServerInternals]
go

if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where v.name = 'vDataWithXML' and s.name = 'dbo') drop view dbo.vDataWithXML;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'DataWithXML' and s.name = 'dbo') drop table dbo.DataWithXML;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'DataWithCompressedXML' and s.name = 'dbo') drop table dbo.DataWithCompressedXML;
if object_id(N'dbo.fnGetCompressedObjectId') is not null drop function [dbo].fnGetCompressedObjectId;

create table dbo.DataWithXML
(
	ID int not null,
	Data xml not null,

	constraint PK_DataWithXML
	primary key clustered(ID)
	on [Entities]
)
go

declare
	@X xml

;with n1(c) as (select 0 union all select 0) -- 2 rows
,n2(c) as (select 0 from n1 as t1 cross join n1 as t2) -- 4 rows
select @X = 
	(
		select *
		from master.sys.objects --cross join n2
		for xml raw, root('Data')
	)

--select datalength(@X)

;with n1(c) as (select 0 union all select 0) -- 2 rows
,n2(c) as (select 0 from n1 as t1 cross join n1 as t2) -- 4 rows
,n3(c) as (select 0 from n2 as t1 cross join n2 as t2) -- 16 rows
,n4(c) as (select 0 from n3 as t1 cross join n3 as t2) -- 256 rows
,n5(c) as (select 0 from n4 as t1 cross join n3 as t2) -- 4,096 rows
,ids(id) as (select row_number() over (order by (select null)) from n5)
insert into dbo.DataWithXML(ID,Data)
	select id, @X
	from Ids
go

update dbo.DataWithXML
set Data.modify('replace value of (/Data/row/@object_id)[1]
with sql:column("ID")')
go


select 
    index_id, partition_number, alloc_unit_type_desc
    ,index_level
	,page_count
	,page_count * 8 / 1024 as [Size MB]
from 
    sys.dm_db_index_physical_stats
    (
        db_id() /*Database */
        ,object_id(N'dbo.DataWithXML') /* Table (Object_ID) */
        ,1 /* Index ID */
        ,null /* Partition ID – NULL – all partitions */
        ,'detailed' /* Mode */
    )
go

select avg(datalength(Data)) as [Avg XML Size] 
from dbo.DataWithXML
go

create table dbo.DataWithCompressedXML
(
	ID int not null,
	Data varbinary(max) not null,

	constraint PK_DataWithCompressedXML
	primary key clustered(ID)
	on [Entities]
)
go

insert into dbo.DataWithCompressedXML(ID,Data)
	select ID, compress(convert(varbinary(max),Data))
	from dbo.DataWithXML
go

select avg(datalength(Data)) as [Uncompressed] 
from dbo.DataWithXML

select avg(datalength(Data)) as [Compressed] 
from dbo.DataWithCompressedXML
go

select 
    index_id, partition_number, alloc_unit_type_desc
    ,index_level
	,page_count
	,page_count * 8 / 1024 as [Size MB] , '' ,''
from 
    sys.dm_db_index_physical_stats
    (
        db_id() /*Database */
        ,object_id(N'dbo.DataWithCompressedXML') /* Table (Object_ID) */
        ,1 /* Index ID */
        ,null /* Partition ID – NULL – all partitions */
        ,'detailed' /* Mode */
    )
go

create view dbo.vDataWithXML(ID, Data)
as
	select ID, convert(xml,Decompress(Data))
	from dbo.DataWithCompressedXML
go

select top 1 * from dbo.vDataWithXML
go

set statistics time on
select count(*) 
from dbo.DataWithXML 
where Data.value('(/Data/row/@object_id)[1]','int') = 3;

select count(*) 
from dbo.vDataWithXML 
where Data.value('(/Data/row/@object_id)[1]','int') = 3;
set statistics time off
go

create function dbo.fnGetCompressedObjectId(@Compressed varbinary(max))
returns int
with schemabinding
as
begin
	return (convert(xml,Decompress(@Compressed)).value('(/Data/row/@object_id)[1]','int'))
end
go	 

alter table dbo.DataWithCompressedXML
add
	ObjId as dbo.fnGetCompressedObjectId(Data)
	persisted
go

--alter index PK_DataWithCompressedXML on dbo.DataWithCompressedXML rebuild
go

alter view dbo.vDataWithXML(ID, Data, ObjId)
as
	select ID, convert(xml,Decompress(Data)), ObjId
	from dbo.DataWithCompressedXML
go


set statistics time on
select count(*) from dbo.DataWithXML where Data.value('(/Data/row/@object_id)[1]','int') = 3
select count(*) from dbo.vDataWithXML where ObjId = 3
set statistics time off
go

select top 1 * from DataWithCompressedXML
go

