use OSM_4
go
if object_id('dbo.PurgeCycle') is not null
  drop table dbo.PurgeCycle
go
create table dbo.PurgeCycle
(DbName varchar(128) not null,
 PartitionNumber int NOT NULL,
 DbSize_GB dec(10,2) null,
 Orig_DbSpace_Used_GB dec(10,2) null,
 Orig_DbAvailable_Space_GB dec(10,2) null,
 Orig_Percent_Used varchar(4) null,
 Updated_DbSpace_Used_GB dec(10,2) null,
 Updated_DbAvailable_Space_GB dec(10,2) null,
 Updated_Percent_Used varchar(4) null,
 DataPurgeStarted datetime null,
 CurrentRunStarted datetime null,
 CurentRunEnded datetime null,
 DataPurgeEnded datetime null);
go
if object_id('dbo.PurgeSession') is not null
  drop table dbo.PurgeSession
go
create table dbo.PurgeSession
(Tbl varchar(128) not null,
 PartitionNumber int NOT NULL,
 hasLOBcolumn char(1) null default ('N'),
 PurgeExpiredDataOlderThan datetime null,
 RowsToPurge int null,
 StartDate datetime null,
 RowsPurged int null,
 LastDate datetime null,
 EndDate datetime null,
 Error varchar(4000) null);
go