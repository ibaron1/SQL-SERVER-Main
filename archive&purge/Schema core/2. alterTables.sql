use TFM_Archive
go

alter table core.DataArchivingAndPurgingConfig
alter column workflowId int null

alter table core.ArchivingDataProcessing
alter column workflowId int null

alter table core.ArchivingDataProcessing_History
alter column workflowId int null

alter table core.ExpiredArchivedDataProcessing
alter column workflowId int null

alter table core.ExpiredArchivedDataProcessing_History
alter column workflowId int null

go