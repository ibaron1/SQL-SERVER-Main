declare @last_DataPurgeEnded date
select @last_DataPurgeEnded = DataPurgeEnded from [core].[ControlPurgeOfExpiredArchivedData]

select DbName, DbSize_GB, Updated_DbSpace_Used_GB, cast(DataPurgeEnded as date) as DataPurgeEnded
into #t
from [core].[ControlPurgeOfExpiredArchivedData]
union
select DbName, DbSize_GB, Updated_DbSpace_Used_GB, cast(DataPurgeEnded as date) as DataPurgeEnded 
from [core].[ControlPurgeOfExpiredArchivedData_History]
where DataPurgeEnded between dateadd(day, -29, @last_DataPurgeEnded) and @last_DataPurgeEnded

select t1.DbName, t1.DbSize_GB as [T day DbSize_GB], t2.DbSize_GB as [T-1 day DbSize_GB], 
t1.Updated_DbSpace_Used_GB as [T day Updated_DbSpace_Used_GB], t2.Updated_DbSpace_Used_GB as [T-1 day Updated_DbSpace_Used_GB],
(t1.Updated_DbSpace_Used_GB - t2.Updated_DbSpace_Used_GB) as [Daily delta Updated_DbSpace_Used_GB],
cast(t1.DataPurgeEnded as date) as [T day DataPurgeEnded], cast(t2.DataPurgeEnded as date)  as [T-1 day DataPurgeEnded]
into #t1
from #t as t1
join #t as t2
on datediff(day, t2.DataPurgeEnded, t1.DataPurgeEnded) = 1

select sum([Daily delta Updated_DbSpace_Used_GB]) as [DbSpace_Used_GB for last month]
from #t1

select * from #t1
order by [T day DataPurgeEnded]

drop table #t, #t1