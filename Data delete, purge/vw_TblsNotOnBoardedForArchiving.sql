USE [TFM]
GO

if object_id('tfmarchive.vw_TblsNotOnBoardedOrArchived') is not null
  drop view tfmarchive.vw_TblsNotOnBoardedOrArchived
go

/************************************
Author. Eli Baron
Date created. 08-07-2017
Purpose. Get not yet archived tables 
************************************/

create view tfmarchive.vw_TblsNotOnBoardedOrArchived
as
with tbls
as (select distinct Tbl from tfmarchive.DataArchivingCfg)
,wfId
as (select distinct workflowId from tfmarchive.DataArchivingCfg)
select w.workflowId as [Workflow not onboarded  for archiving], ' ' as [Table not onboarded for archiving], ' ' as [Table not archived (no retention)] 
from Workflow as w
where workflowId not in (select workflowId from wfId)
union all
select t.workflowId, tbls.Tbl, ' '  
from tfmarchive.DataArchivingCfg as t
right join tbls
on t.Tbl <> tbls.Tbl
where exists
(select '1' from tfmarchive.DataArchivingCfg 
 where workflowId = t.workflowId
 group by workflowId
 having count(1) < (select count(1) from tbls))
union all 
select workflowId, ' ', Tbl
from tfmarchive.DataArchivingCfg 
where Retention_days is null