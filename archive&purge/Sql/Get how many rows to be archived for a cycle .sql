USE TFM
GO
/****** Object:  StoredProcedure [core].[DataArchivingForWorkflow]    Script Date: 8/10/2018 10:37:10 AM ******/

set nocount on
set transaction isolation level read uncommitted
set dateformat mdy

declare @DataArchivingStartDay date = '2018-08-11' 
--declare @DataArchivingStartDay date = getdate()


declare @ArchiveOlderThan datetime,
@AppDataType varchar(20) = 'tfm'

select @ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@DataArchivingStartDay),101)
from TFM_Archive.core.DataArchivingAndPurgingConfig as cfg
cross join TFM_Archive.core.ControlOfDataArchiving as ctrl
where cfg.AppDataType = @AppDataType and Tbl = 'FileLoad'

if object_id('tempdb.dbo.#loadIdsForDataArchiving') is not null
  drop table #loadIdsForDataArchiving

select loadId into #loadIdsForDataArchiving
from TFM.tfm.FileLoad
where loadEnded < @ArchiveOlderThan

if object_id('tempdb.dbo.#transactionIdArchiving') is not null
  drop table #transactionIdArchiving

select transactionId into #transactionIdArchiving
from TFM.tfm.Request
where loadId in (select loadId from #loadIdsForDataArchiving)

if object_id('tempdb.dbo.#activityIdArchiving') is not null
  drop table #activityIdArchiving

select activityId into #activityIdArchiving
from TFM.tfm.Activity
where transactionId in (select transactionId from #transactionIdArchiving)

select '' as [Volume to archive for cycle starting], cast(@DataArchivingStartDay as date) as [on], @ArchiveOlderThan as [to archive older than],db_name() as [from database], @@servername as [on SQL Server instance]

-- Workflow based tables
select ' ' as [Workflow based tables],
(select count(1) from TFM.tfm.RequestKeyAttributes
	where transactionId in (select transactionId from  #transactionIdArchiving)) as [Row# to archive from RequestKeyAttributes]  
,
(select count(1) from TFM.tfm.Payload
	where activityId in (select activityId from #activityIdArchiving)) as [Row# to archive from Payload] 
,
(select count(1) from TFM.tfm.Activity
	where activityId in (select activityId from #activityIdArchiving)) as [Row# to archive from Activity]
, 
(select count(1) from TFM.tfm.Request 
	where transactionId in (select transactionId from  #transactionIdArchiving)) as [Row# to archive from Request]

if object_id('tempdb.dbo.#TransformationId') is not null
  drop table #TransformationId

select TransformationId into #TransformationId
from TFM.tfm.FileTransformation
where TransformationEnded < @ArchiveOlderThan

-- Cross workflow tables
select ' ' as [Cross workflow tables],
(select count(1) from TFM.tfm.LoadError 
	    where loadId in (select loadId from #loadIdsForDataArchiving)) as [Row# to archive from LoadError]  
,
(select count(1) from TFM.tfm.LoadErrorHistory 
	    where loadId in (select loadId from #loadIdsForDataArchiving)) as [Row# to archive from LoadErrorHistory] 
,
(select count(1) from TFM.tfm.LoggerError 
	    where loadId in (select loadId from #loadIdsForDataArchiving)) as [Row# to archive from LoggerError]
, 
(select count(1) from TFM.tfm.LoggerErrorHistory 
	    where loadId in (select loadId from #loadIdsForDataArchiving)) as [Row# to archive from LoggerErrorHistory]
,
(select count(1) from TFM.tfm.FileLoad 
	    where loadId in (select loadId from #loadIdsForDataArchiving)) as [Row# to archive from FileLoad]
,
(select count(1) from TFM.tfm.FileLoadHistory 
	    where loadId in (select loadId from  #loadIdsForDataArchiving)) as [Row# to archive from FileLoadHistory]

select ' ' as [Cross workflow tables]
,
(select count(1) from TFM.tfm.FileTransformation
where TransformationEnded < @ArchiveOlderThan) as [Row# to archive from FileTransformation]
,
(select count(1) from #TransformationId) as [Row# to archive from TransformationError]
,
(select count(1) from TFM.tfm.TransformationErrorHistory 
where TransformationId in (select TransformationId from #TransformationId)) as [Row# to archive from TransformationErrorHistory]
,
(select count(1) from TFM.tfm.FileTransformation 
where TransformationId in (select TransformationId from #TransformationId)) as [Row# to archive from FileTransformation]
,
(select count(1) from TFM.tfm.FileTransformationHistory 
where TransformationId in (select TransformationId from #TransformationId)) as [Row# to archive from FileTransformationHistory]

