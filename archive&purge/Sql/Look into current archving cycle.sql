use TFM_Archive
go
/*
select * from [core].[ControlOfDataArchiving_History]

select * from [core].[ControlOfDataArchiving_History]
order by DataArchivingStarted desc
*/
select count(distinct workflowId) as [workflowId count]
from [core].[ArchivingDataProcessing]

select * , datediff(mi, StartDate, LastDate) as [Run Time in  min]
from [core].[ArchivingDataProcessing]
--where LastDate is not null
order by StartDate desc