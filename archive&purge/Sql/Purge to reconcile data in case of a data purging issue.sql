use TFM_Archive
go
declare @PurgeExpiredDataOlderThan datetime = '02/16/2018'

declare @loadId table (loadId int)
declare @transactionId table (transactionId int)
declare @tranStepId table (tranStepId int) 
declare @activityId table (activityId int)

insert @loadId
select loadId
from tfm.FileLoad
where loadEnded < @PurgeExpiredDataOlderThan

insert @transactionId
select transactionId -- for RequestKeyAttributes, Step
from tfm.Request
where timestamp < @PurgeExpiredDataOlderThan

insert @tranStepId
select tranStepId -- for Activity
from tfm.Step
where transactionId in (select transactionId from @transactionId)

insert @activityId
select activityId -- for Payload and RequestLoad
from tfm.Activity
where tranStepId in (select tranStepId from @tranStepId)

delete from tfm.RequestKeyAttributes
where transactionId in (select transactionId from @transactionId)
option (maxdop 0)

print 'purged count from RequestKeyAttributes : '+cast(@@rowcount as varchar(4))

delete from tfm.Payload
where activityId in (select activityId from @activityId)
option (maxdop 0)

print 'purged count from Payload : '+cast(@@rowcount as varchar(4))

delete from tfm.Activity
where activityId in (select activityId from @activityId)
option (maxdop 0)

print 'purged count from Activity : '+cast(@@rowcount as varchar(4))

delete from tfm.Step
where tranStepId in (select tranStepId from @tranStepId)
option (maxdop 0)

print 'purged count from Step : '+cast(@@rowcount as varchar(4))
 
delete from tfm.Request
where transactionId in (select transactionId from @transactionId)
option (maxdop 0)

print 'purged count from Request : '+cast(@@rowcount as varchar(4))
 