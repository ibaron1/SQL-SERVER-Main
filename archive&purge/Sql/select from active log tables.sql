--select * from [core].[DataArchivingAndPurgingConfig]

-- data archiving
select * from [core].[ControlOfDataArchiving]
select * from [core].[ControlOfDataArchiving_History]

select * from [core].[ArchivingDataProcessing]
select * from [core].[ArchivingDataProcessing_History]

--data purging
select * from [core].[ControlPurgeOfExpiredArchivedData]
select * from [core].[ControlPurgeOfExpiredArchivedData_History]

select * from [core].[ExpiredArchivedDataProcessing]
select * from [core].[ExpiredArchivedDataProcessing_History]