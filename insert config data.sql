USE [TFM]
GO

delete tfmarchive.DataArchivingCfg

declare @tbl table(Tbl varchar(128))

insert @tbl
values
('tfmarchive.Payload')
,('tfmarchive.Activity')
,('tfmarchive.Step')
,('tfmarchive.RequestKeyAttributes')
,('tfmarchive.Request')	

insert tfmarchive.DataArchivingCfg
(DbName
,AppDataType
,workflowId
,Tbl
,Retention_days
,Archive_retention_days
,ArchiveBatchSize)
select 
 db_name()
,'TFM'
,w.workflowId
,Tbl
,90
,30
,100000
from @tbl as t cross join dbo.Workflow as w
where not exists
(select '1' from tfmarchive.DataArchivingCfg
 where  workflowId = w.workflowId and Tbl = t.Tbl)

 select * from tfmarchive.DataArchivingCfg

