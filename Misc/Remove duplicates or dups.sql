use monitordb
go

set nocount on

set rowcount 0

select 'Duplicates before they are removed'

select SPID, KPID, BatchID , ContextID , LineNumber , DBID, count(*) as Cnt
into #monProcess  
from monProcess
group by SPID, KPID, BatchID , ContextID , LineNumber , DBID
having count(*) > 1

select * from #monProcess

select isnull(sum(Cnt - 1), 0) as [Total number of duplicates] from #monProcess

declare @SPID smallint, @KPID int, @BatchID int, @ContextID int, @LineNumber int, @DBID int, @Cnt int

set rowcount 1

while exists
(select * from monProcess
group by SPID, KPID, BatchID , ContextID , LineNumber , DBID
having count(*) > 1)
begin

select @SPID = SPID, @KPID = KPID, @BatchID = BatchID, @ContextID = ContextID, @LineNumber = LineNumber, @DBID = DBID, @Cnt = count(*)
from monProcess
group by SPID, KPID, BatchID , ContextID , LineNumber , DBID
having count(*) > 1

set @Cnt = @Cnt - 1

set rowcount @Cnt

delete monProcess
where SPID = @SPID and KPID = @KPID and BatchID = @BatchID and ContextID = @ContextID and LineNumber = @LineNumber and DBID = @DBID

set rowcount 1

end

set rowcount 0

select 'After duplicates were removed'

select t1.SPID, t1.KPID, t1.BatchID , t1.ContextID , t1.LineNumber , t1.DBID, count(*) as Cnt  
from monProcess t1, #monProcess t2
where t1.SPID = t2.SPID and t1.KPID = t2.KPID and t1.BatchID = t2.BatchID 
and t1.ContextID = t2.ContextID and t1.LineNumber = t2.LineNumber and t1.DBID = t2.DBID
group by t1.SPID, t1.KPID, t1.BatchID, t1.ContextID, t1.LineNumber, t1.DBID

drop table #monProcess

go


