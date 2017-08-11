
if object_id('tfmarchive.DataArchivingCfg') is not null
  drop table tfmarchive.DataArchivingCfg
go
create table tfmarchive.DataArchivingCfg
(DbName varchar(128) not null,
 AppDataType varchar(20),
 workflowId int not null constraint FK_workflowId foreign key references dbo.Workflow(workflowId),    -- replace by tfm.Workflow(workflowId ; on 8/4/17 there was just 1 row in that table
 Tbl varchar(128) not null,
 Retention_days int null,
 Archive_retention_days int null,
 ArchiveBatchSize int not null);

create unique clustered index idx_DataArchivingCfg on tfmarchive.DataArchivingCfg(workflowId,Tbl)
go

if object_id('tfmarchive.DataArchivingLog') is not null
  drop table tfmarchive.DataArchivingLog;

create table tfmarchive.DataArchivingLog
(DbName varchar(128) not null,
 AppDataType varchar(20) null,
 workflowId int not null,
 Tbl varchar(128) not null,
 ifArchiveOnboarded char(1) null,
 hasLOBcolumn char(1) null default ('N'),
 ArchiveAndPurgeArchivedOlderThan date null,
 RowsToArchive int null,
 ArchiveStartDate datetime null,
 ArchivedRows int null,
 LastArchiveDate datetime null,
 ArchiveEndDate datetime null,
 ArchivingError varchar(4000) null,
 ArchivedRowsToPurge int null,
 PurgeArchivedStartDate datetime null,
 PurgedArchivedRows int null,
 PurgeArchivedLastDate datetime null,
 PurgeArchivedEndDate datetime null,
 PurgeArchivedError varchar(4000) null);

 create unique clustered index idx_DataArchivingLog on tfmarchive.DataArchivingLog(AppDataType,workflowId,Tbl);

 if object_id('tfmarchive.DataArchivingLog_History') is not null
  drop table tfmarchive.DataArchivingLog_History;

create table tfmarchive.DataArchivingLog_History
(DbName varchar(128) not null,
 AppDataType varchar(20) null,
 workflowId int not null,
 Tbl varchar(128) not null,
 ifArchiveOnboarded char(1) null,
 hasLOBcolumn char(1) null default ('N'),
 ArchiveAndPurgeArchivedOlderThan date null,
 RowsToArchive int null,
 ArchiveStartDate datetime null,
 ArchivedRows int null,
 LastArchiveDate datetime null,
 ArchiveEndDate datetime null,
 ArchivingError varchar(4000) null,
 ArchivedRowsToPurge int null,
 PurgeArchivedStartDate datetime null,
 PurgedArchivedRows int null,
 PurgeArchivedLastDate datetime null,
 PurgeArchivedEndDate datetime null,
 PurgeArchivedError varchar(4000) null);

create clustered index idx_DataArchivingLog on tfmarchive.DataArchivingLog_History(AppDataType,workflowId,Tbl,LastArchiveDate);

if object_id('tfmarchive.DbSpaceAfterArchiving') is not null
  drop table tfmarchive.DbSpaceAfterArchiving;

create table tfmarchive.DbSpaceAfterArchiving
(DbName varchar(128) not null,
 DbSize_MB int null,
 Orig_DbSpace_Used_MB int null,
 Orig_DbAvailable_Space_MB int null,
 Orig_Percent_Used varchar(4) null,
 Updated_DbSpace_Used_MB int null,
 Updated_DbAvailable_Space_MB int null,
 Updated_Percent_Used varchar(4) null,
 AppDataType varchar(20) null,
 DataArchivingStarted datetime null,
 CurrentRunStarted datetime null,
 CurentRunEnded datetime null,
 DataArchivingEnded datetime null);

 if object_id('tfmarchive.DbSpaceAfterArchiving_History') is not null
  drop table tfmarchive.DbSpaceAfterArchiving_History;

create table tfmarchive.DbSpaceAfterArchiving_History
(DbName varchar(128) not null,
 DbSize_MB int null,
 Orig_DbSpace_Used_MB int null,
 Orig_DbAvailable_Space_MB int null,
 Orig_Percent_Used varchar(4) null,
 Updated_DbSpace_Used_MB int null,
 Updated_DbAvailable_Space_MB int null,
 Updated_Percent_Used varchar(4) null,
 AppDataType varchar(20) null,
 DataArchivingStarted datetime null,
 CurrentRunStarted datetime null,
 CurentRunEnded datetime null,
 DataArchivingEnded datetime null);
