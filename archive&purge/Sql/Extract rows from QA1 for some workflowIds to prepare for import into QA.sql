select * into workflow from tfm.workflow
where workflowid in (5,6)

select distinct f.* into dbo.fileload --588030 rows
from tfm.fileload as f
join tfm.request as r
on f.loadId = r.loadId
where workflowid in (5,6) and loadEnded < '2018-03-02'

select r.* into dbo.request
from tfm.request as r
where workflowid in (5,6)
and loadid in (select loadid from dbo.fileload)

create index i on request(transactionId)

select rka.* into dbo.RequestKeyAttributes --433165
from tfm.RequestKeyAttributes as rka
join dbo.request as r
on rka.transactionId = r.transactionId

select s.* into dbo.step --1,719,877 rows
from tfm.step as s
join dbo.request as r
on r.transactionId = s.transactionId

select a.* into dbo.activity --13,045,250 rows
from dbo.request as r
join dbo.step as s
on r.transactionId = s.transactionId
join tfm.activity as a
on s.transtepid = a.transtepid

create index i on activity(activityid)

-- drop table payload

select * into dbo.payload
from tfm.payload where 1=2

declare @i int, @max int
select @i = min(activityId), @max = max(activityId)
from dbo.activity

while @i <= @max
begin
	insert into dbo.payload
	select p.* 
	from tfm.payload as p with (forceseek)
	inner hash join dbo.activity as a --with (forceseek)
	on p.activityid = a.activityid
	where a.activityid >= @i and a.activityid < @i +100000
	option (maxdop 0)

	set @i += 100000
end

