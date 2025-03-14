
if object_id(N'dbo.sp_purgeOldData') is not null
  drop proc dbo.sp_purgeOldData
go

create procedure dbo.sp_purgeOldData
@PurgeThisDate char(10) = NULL, -- format: mm/dd/yyyy
@PurgePriorToThisDate char(10) = NULL, -- format: mm/dd/yyyy
@DeletionThreshold int = 30, -- in days from current date
@DeleteNumberOfRowsBatchSize int = 10000,
@shrinkdatabase char(1) = 'N' 
as

/***********************************************
Author.
Eli Baron

Purpose.
To purge old data.
Reports tables space before and after the purge,
number of rows deleted and saved space.

Created.
02/20/2013
***********************************************/

/*********************************************************************************************************
exec dbo.sp_purgeOldData @DeletionThreshold int = 30 -- to delete data prior to 30 days from current date
exec dbo.sp_purgeOldData @PurgePriorToThisDate = '12/31/2012' -- to delete data for a specific day
exec dbo.sp_purgeOldData @PurgeThisDate = '01/18/2013' -- to delete data prior to a specific day
*********************************************************************************************************/

set nocount on

declare @DeleteOlderThanThisDay char(10), @currDate char(10)

if @PurgePriorToThisDate is null
	select @DeleteOlderThanThisDay = convert(char(10), dateadd(dd,-1*(@DeletionThreshold),getdate()), 101)
	,@currDate = convert(char(10), getdate(), 101)
else
	select @DeleteOlderThanThisDay = @PurgePriorToThisDate

declare @rc int, @rc_total int

declare @tbl table (tbl sysname, ChildTo sysname, IfExists char(1) default 'Y')

create table #tbl(tbl sysname)

create table #TabSpaceFinal 
([Schema] sysname
,TabName sysname
,[Rows] bigint
,ReservedMB numeric(18,3)
,DataMB numeric(18,3)
,Index_SizeMB numeric(18,3)
,UnusedMB numeric(18,3)
)

declare @TabSpaceBefore table  
([Schema] sysname
,TabName sysname
,[Rows] bigint
,ReservedMB numeric(18,3)
,DataMB numeric(18,3)
,Index_SizeMB numeric(18,3)
,UnusedMB numeric(18,3)
)

declare @TabSpaceAfter table  
([Schema] sysname
,TabName sysname
,[Rows] bigint
,ReservedMB numeric(18,3)
,DataMB numeric(18,3)
,Index_SizeMB numeric(18,3)
,UnusedMB numeric(18,3)
)

insert @tbl(tbl,ChildTo)
values('srf_main.GTRException','srf_main.TradeMessage')
,('srf_main.TradeMessagePayload','srf_main.TradeMessage')
,('srf_main.TradeMessage','srf_main.Trade')
,('srf_main.Trade','')
,('srf_main.Exception','')
,('srf_main.EODBusinessexception','')
,('srf_main.EODTradeStage','')
,('srf_main.EODTradeStatus','srf_main.EODTrade')
,('srf_main.BCPGTRResponseData','srf_main.EODTrade')
,('srf_main.EODTrade','')

update @tbl
set ifexists = 'N'
where object_id(tbl) is null

insert #tbl
select tbl from @tbl
where ifexists = 'Y'

exec sp_spaceusedtbl

insert @TabSpaceBefore
select * from #TabSpaceFinal

print 'Database '+cast(db_name() as varchar(128))+' on instance '+cast(@@servername as varchar(200))

if @PurgeThisDate is not null
  begin
    IF isdate(@PurgeThisDate) <> 1
	  begin
		print 'Invalid date '+@PurgeThisDate
		print 'Please enter mm/dd/yyyy' 
		return 
	  end
         
    print 'Deleting data for '+@PurgeThisDate
    
    set @DeleteOlderThanThisDay = 0

  end
else
  begin
    print 'Deleting data prior to '+@DeleteOlderThanThisDay
  end

declare @starttime datetime = getdate()

print ''
print 'START of deleting old data :'+cast(@starttime as varchar(24))
print ''

-- prepare to delete from child tbls

declare @TradeId table (TradeId int)

declare @TradeMessagePayload table
(PayloadId	int,TradeMessageId	int)

if exists 
(select 1 from @tbl where tbl in ('srf_main.TradeMessage','srf_main.TradeMessagePayload','srf_main.Trade')
 and IfExists = 'N')
begin
  select 'This tables do not exist', tbl 
  from @tbl 
  where tbl in ('srf_main.TradeMessage','srf_main.TradeMessagePayload','srf_main.Trade')
  and IfExists = 'N'
end

if @PurgeThisDate is null
  begin 
	insert @TradeId
	    select t.TradeId 
            from srf_main.Trade t
      		where   t.TradeId in (
            		select t.TradeId from
                  	srf_main.Trade t
                  		left outer join srf_main.TradeMessage tm
                        on t.TradeId = tm.TradeId
                  		inner join srf_main.TradeMessagePayload tp
                        on tm.TradeMessageId = tp.TradeMessageId
                  	where tm.ArrivalDateTime < @DeleteOlderThanThisDay)

	insert @TradeMessagePayload
            select DISTINCT tp.TradeMessageId, tp.PayloadId 
            from @TradeId t
                  left outer join srf_main.TradeMessage tm
                        on t.TradeId = tm.TradeId
                  inner join srf_main.TradeMessagePayload tp
                        on tm.TradeMessageId = tp.TradeMessageId
                  where tm.ArrivalDateTime < @DeleteOlderThanThisDay

  end
else
  begin
  	insert @TradeId
	    select t.TradeId 
            from srf_main.Trade t
      		where   t.TradeId in (
            		select t.TradeId from
                  	srf_main.Trade t
                  		left outer join srf_main.TradeMessage tm
                        on t.TradeId = tm.TradeId
                  		inner join srf_main.TradeMessagePayload tp
                        on tm.TradeMessageId = tp.TradeMessageId
                  	where convert(char(10), tm.ArrivalDateTime, 101) = @PurgeThisDate)

	insert @TradeMessagePayload
            select DISTINCT tp.TradeMessageId, tp.PayloadId 
            from @TradeId t
                  left outer join srf_main.TradeMessage tm
                        on t.TradeId = tm.TradeId
                  inner join srf_main.TradeMessagePayload tp
                        on tm.TradeMessageId = tp.TradeMessageId
                  where convert(char(10), tm.ArrivalDateTime, 101) = @PurgeThisDate

  end
                  
            select DISTINCT TradeMessageId into #TradeMessageId 
            from @TradeMessagePayload 
            order by TradeMessageId
            
            select DISTINCT PayloadId into #PayloadId 
            from @TradeMessagePayload 
            order by PayloadId


declare @tblname varchar(128)

--1

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.GTRException'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.GTRException --GTRExceptionId (PK)
      where  TradeMessageId in (select TradeMessageId from #TradeMessageId)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))

end

end
else
  print 'Table '+@tblname+' does not exist'

--2

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.TradeMessagePayload'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.TradeMessagePayload -- needs to be by PayloadId (PK), no idx on TradeMessageId
      where  PayloadId in (select PayloadId from #PayloadId)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))

end

end
else
  print 'Table '+@tblname+' does not exist'

--3

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.TradeMessage'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.TradeMessage -- TradeMessageId (PK)
      where   TradeMessageId in (select TradeMessageId from #TradeMessageId)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))

end

end
else
  print 'Table '+@tblname+' does not exist'

--4.

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.Trade'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin
 
while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.Trade --TradeId (PK)
      where   TradeId in (select TradeId from @TradeId)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))

end

end
else
  print 'Table '+@tblname+' does not exist'

--5.

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.Exception'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin
 
while @rc = @DeleteNumberOfRowsBatchSize
begin

  if @PurgeThisDate is null
    delete top (@rc) from srf_main.Exception --no idx on ProcessedDate
      where ProcessedDate < @DeleteOlderThanThisDay
  else
    delete top (@rc) from srf_main.Exception --no idx on ProcessedDate
      where convert(char(10), ProcessedDate, 101) = @PurgeThisDate  

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))

end

end
else
  print 'Table '+@tblname+' does not exist'

--6.

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.EODBusinessexception'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

while @rc = @DeleteNumberOfRowsBatchSize
begin

  if @PurgeThisDate is null
    delete top (@rc) from srf_main.EODBusinessexception -- no idx
                  where CreateDate < @DeleteOlderThanThisDay
  else
     delete top (@rc) from srf_main.EODBusinessexception -- no idx
                  where convert(char(10), CreateDate, 101) = @PurgeThisDate

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))

end

end
else
  print 'Table '+@tblname+' does not exist'

--7.

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.EODTradeStage'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

while @rc = @DeleteNumberOfRowsBatchSize
begin

  if @PurgeThisDate is null
    delete top (@rc) from srf_main.EODTradeStage -- PK starting on tradeId, cobDate - 17,709,151 row table in prod Rates  
            where cobDate < @DeleteOlderThanThisDay -- is CI scan, i.e. tbl scan
  else
    delete top (@rc) from srf_main.EODTradeStage 
            where convert(char(10), cobDate, 101) = @PurgeThisDate
            
  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))

end

end
else
  print 'Table '+@tblname+' does not exist'

--8.
declare @EODTradeStatus table(EODTradeId int)

if @PurgeThisDate is null
   insert @EODTradeStatus
   select distinct e1.EODTradeId 
	    from srf_main.EODTradeStatus es
            join srf_main.EODTrade e1
                  on e1.EODTradeId = es.EODTradeId
            where e1.CreateDate < @DeleteOlderThanThisDay
else
   insert @EODTradeStatus
   select distinct e1.EODTradeId 
	    from srf_main.EODTradeStatus es
            join srf_main.EODTrade e1
                  on e1.EODTradeId = es.EODTradeId
            where convert(char(10), e1.CreateDate, 101) = @PurgeThisDate

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.EODTradeStatus'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.EODTradeStatus --idx starting on tradeId
  where EODTradeId in -- idx starting clmn EODTradeId
  (select EODTradeId from @EODTradeStatus)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))

end

end
else
  print 'Table '+@tblname+' does not exist'

--9.
select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.BCPGTRResponseData' --FK to EODTrade 

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.BCPGTRResponseData --unique idx on EODTradeId 
  where EODTradeId in (select EODTradeId from @EODTradeStatus)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))

end

end
else
  print 'Table '+@tblname+' does not exist'

--10.

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.EODTrade'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.EODTrade --unique idx on EODTradeId 
  where EODTradeId in (select EODTradeId from @EODTradeStatus)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))

end

end
else
  print 'Table '+@tblname+' does not exist'

print ''
print 'END of deleting old data :'+cast(getdate() as varchar(24))
declare @run_time int = datediff(ss, @starttime, getdate())
print 'RUN TIME to delete data : '+cast((case when @run_time/3600 > 0 then @run_time/3600 else 0 end) as varchar(2))+' hr '+
cast((case when (@run_time%3600)/60 > 0 then (@run_time%3600)/60 else 0 end) as varchar(2))+' min '+
cast((case when @run_time%3600-((@run_time%3600)/60)*60 > 0 then @run_time%3600-((@run_time%3600)/60)*60 else 0 end) as varchar(2))+' sec '

truncate table #TabSpaceFinal

exec sp_spaceusedtbl

insert @TabSpaceAfter
select * from #TabSpaceFinal

select c.tbl as [Table],c.ChildTo,c.IfExists
, cast((b.[Rows]- a.[Rows]) as varchar(100)) as [RowsDeleted]
, cast((b.ReservedMB - a.ReservedMB) as varchar(100)) as [SpaceSavedMB]
, cast(b.[Rows] as varchar(100)) as [Rows # before]
, cast(a.[Rows] as varchar(100)) as [Rows # after]
, cast(b.ReservedMB as varchar(100)) as [ReservedMB before] 
, cast(a.ReservedMB as varchar(100)) as [ReservedMB after] 
, cast(b.DataMB as varchar(100)) as [DataMB before] 
, cast(a.DataMB as varchar(100)) as [DataMB after] 
, cast(b.Index_SizeMB as varchar(100)) as [Index_SizeMB before] 
, cast(a.Index_SizeMB as varchar(100)) as [Index_SizeMB after]
, cast(b.UnusedMB as varchar(100)) as [UnusedMB before] 
, cast(a.UnusedMB as varchar(100)) as [UnusedMB after]
from @TabSpaceBefore b join @TabSpaceAfter a
on a.[Schema] = b.[Schema] and a.TabName = b.TabName
right join @tbl c
on b.[Schema]+'.'+b.TabName = c.tbl
  union all
select '','','','','','','','','','','','','','',''
  union all
select 'TOTAL','','',
cast(sum(b.[Rows] - a.[Rows]) as varchar(100)),
cast(sum(b.ReservedMB - a.ReservedMB) as varchar(100)),
'','','','','','','','','',''
from @TabSpaceBefore b join @TabSpaceAfter a
on a.[Schema] = b.[Schema] and a.TabName = b.TabName




drop table #TradeMessageId, #PayloadId, #tbl, #TabSpaceFinal

if @shrinkdatabase = 'Y'
begin

	declare @sqlCommand nvarchar(600), @dbname nvarchar(400) = db_name()
	set @starttime = getdate()
	print ''
	print 'Now compacting data in data files; their physical size do not change : '+cast(@starttime as varchar(24))
	set @sqlCommand = 'dbcc shrinkdatabase ('+@dbname+', notruncate)'
	exec (@sqlCommand)
	print 'End of compacting data : '+cast(getdate() as varchar(24))
	set @run_time = datediff(ss, @starttime, getdate())
	print 'Run time to compact data : '+cast((case when @run_time/3600 > 0 then @run_time/3600 else 0 end) as varchar(2))+' hr '+
	cast((case when (@run_time%3600)/60 > 0 then (@run_time%3600)/60 else 0 end) as varchar(2))+' min '+
	cast((case when @run_time%3600-((@run_time%3600)/60)*60 > 0 then @run_time%3600-((@run_time%3600)/60)*60 else 0 end) as varchar(2))+' sec '

end

go

grant exec on dbo.sp_purgeOldData to srfmain

go
