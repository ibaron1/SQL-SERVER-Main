use TFM_Archive
go

if object_id('core.vw_TblsNotOnBoardedOrArchived') is not null
  drop view core.vw_TblsNotOnBoardedOrArchived
go

/*********************************************************
Author. Eli Baron
Date created. 08-07-2017
Purpose. select tables not archived
Date modified. 8-29-17
 Moved to core schema 
Modified by Eli Baron on 2-20-18
cross workflow changes
*********************************************************/

create view core.vw_TblsNotOnBoardedOrArchived
as
with tbls
as (select distinct Tbl from core.DataArchivingAndPurgingConfig where workflowId is not null)
,wfId
as (select distinct workflowId from core.DataArchivingAndPurgingConfig where workflowId is not null)
select w.workflowId as [Workflow not onboarded  for archiving], ' ' as [Table not onboarded for archiving], ' ' as [Table not archived (no retention)] 
from TFM.tfm.Workflow as w
where workflowId is not null and workflowId not in (select workflowId from wfId)
union all
select t.workflowId, tbls.Tbl, ' '  
from core.DataArchivingAndPurgingConfig as t
right join tbls
on t.Tbl <> tbls.Tbl and t.workflowId is not null
where exists
(select '1' from core.DataArchivingAndPurgingConfig 
 where workflowId = t.workflowId and workflowId is not null
 group by workflowId
 having count(1) < (select count(1) from tbls))
union all 
select workflowId, ' ', Tbl
from core.DataArchivingAndPurgingConfig 
where RetentionDays is null
and workflowId is not null