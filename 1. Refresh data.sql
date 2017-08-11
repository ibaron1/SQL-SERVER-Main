
drop table tfmarchive.RequestKeyAttributes
drop table tfmarchive.Payload
drop table tfmarchive.Activity
drop table tfmarchive.Step
drop table tfmarchive.Request

truncate table TFM_Archive.tfmarchive.RequestKeyAttributes
truncate table TFM_Archive.tfmarchive.Payload
truncate table TFM_Archive.tfmarchive.Activity
truncate table TFM_Archive.tfmarchive.Step
truncate table TFM_Archive.tfmarchive.Request

select * into tfmarchive.Request
from dbo.Request

select * into tfmarchive.Step
from dbo.Step

select * into tfmarchive.Activity
from dbo.Activity

select * into tfmarchive.Payload
from dbo.Payload

select * into tfmarchive.RequestKeyAttributes
from dbo.RequestKeyAttributes