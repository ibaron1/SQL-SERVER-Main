use OSM_4
go

declare @tblList table
(Tbl varchar(128) NOT NULL)

insert @tblList
values
('Entity')
,('Event_Activity')
,('Event_Fill')
,('Entity_Summary')

declare @partition table(PartitionNumber int)

insert @partition
values
(1)
,(2)

delete dbo.DataPurgeCfg

insert dbo.DataPurgeCfg
(PartitionNumber
,Tbl
,RetentionDays
,PurgeBatchSize)
select 
PartitionNumber
,Tbl
,7
,100000
from @tblList cross join @partition

update dbo.DataPurgeCfg
set PurgeBatchSize = 10000
where Tbl = 'Entity_Summary'

select * from dbo.DataPurgeCfg
