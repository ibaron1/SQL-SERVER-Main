use TFM_Archive
go

if object_id('core.loadIdsForDataArchiving') is not null
  drop table core.loadIdsForDataArchiving
go
create table core.loadIdsForDataArchiving(loadId int)
go
if object_id('core.loadIdsForDataPurging') is not null
  drop table core.loadIdsForDataPurging
go
create table core.loadIdsForDataPurging(loadId int)
go