USE TFM_Archive
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if object_id('core.trg_DataArchivingAndPurgingConfig') is not null
  drop trigger core.trg_DataArchivingAndPurgingConfig
GO
/**********************************************
Author. Eli Baron
Date created. 2-6-18
Description. data audit
**********************************************/
create trigger core.trg_DataArchivingAndPurgingConfig
on  core.DataArchivingAndPurgingConfig 
after insert,update,delete
as
 
set nocount on

declare @action char(1) = 'I'

if exists (select 1 from deleted)
  set @action = case 
					when exists (select 1 from inserted) then 'U'
					else 'D' 
				end

if @action = 'I'
	insert tfm.TblList
	select *,@action, suser_name(), getdate() 
	from inserted
else
	insert tfm.TblList
	select *,@action, suser_name(), getdate() 
	from deleted


GO
