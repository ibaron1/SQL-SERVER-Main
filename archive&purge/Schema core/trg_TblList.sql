USE TFM_Archive
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if object_id('tfm.trg_TblList') is not null
  drop trigger tfm.trg_TblList
GO
/**********************************************
Author. Eli Baron
Date created. 3-16-18
Description. data audit
**********************************************/
create trigger tfm.trg_TblList
on  tfm.TblList 
instead of update,delete
as
 
set nocount on


GO
