
set nocount on

declare @PurgeThisDate char(10) = NULL, -- format: mm/dd/yyyy
@PurgePriorToThisDate char(10) = '12/31/2012', -- format: mm/dd/yyyy
@DeletionThreshold int = 30, -- in days from current date
@DeleteNumberOfRowsBatchSize int = 50000,
@shrinkdatabase char(1) = 'N' 

declare @DeleteOlderThanThisDay char(10), @currDate char(10)

if @PurgePriorToThisDate is null
	select @DeleteOlderThanThisDay = convert(char(10), dateadd(dd,-1*(@DeletionThreshold),getdate()), 101)
	,@currDate = convert(char(10), getdate(), 101)
else
	select @DeleteOlderThanThisDay = @PurgePriorToThisDate

declare @rc int, @rc_total int

declare @tbl table (tbl sysname, ChildTo sysname, IfExists char(1) default 'Y')

declare @tbl1 table (tbl sysname)

declare @TabSpaceFinal table  
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

insert @tbl1
select tbl from @tbl
where ifexists = 'Y'

declare @GoBackFlag int = 1

goto spaceusedtbl

BackToProcessing:

insert @TabSpaceBefore
select * from @TabSpaceFinal 

print 'Database '+cast(db_name() as varchar(128))+' on instance '+cast(@@servername as varchar(200))

if @PurgeThisDate is not null
  begin
    IF isdate(@PurgeThisDate) <> 1
	  begin
		print 'Invalid date '+@PurgeThisDate
		print 'Please enter mm/dd/yyyy' 
		return 
	  end
         
    print 'Deleting data prior to '+@PurgeThisDate
    
    set @DeleteOlderThanThisDay = 0

  end
else
  begin
    print 'Deleting data from '+@DeleteOlderThanThisDay
  end

declare @starttime datetime = getdate()

print ''
print 'START of deleting old data :'+cast(@starttime as varchar(24))
print ''

-- prepare to delete from child tbls
declare @TradeIdOrig table (TradeId int)

declare @TradeId table (TradeId int)

declare @TradeMessagePayload table
(PayloadId	int,TradeMessageId	int)

declare @TradeMessageIdOrig table
(TradeMessageId int) 

declare @TradeMessageId table
(TradeMessageId int) 

declare @PayloadIdOrig table
(PayloadId int)
 
declare @PayloadId table
(PayloadId int)

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
	insert @TradeIdOrig
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
  	insert @TradeIdOrig
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
  
	insert @TradeMessageIdOrig       
	select DISTINCT TradeMessageId 
	from @TradeMessagePayload 
	order by TradeMessageId
	
	insert @PayloadIdOrig
	select DISTINCT PayloadId 
	from @TradeMessagePayload 
	order by PayloadId


declare @tblname varchar(128)

--1

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.GTRException'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

delete @TradeMessageId
insert @TradeMessageId select * from @TradeMessageIdOrig
  
while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.GTRException WITH (READPAST)--GTRExceptionId (PK)
  where  TradeMessageId in (select TradeMessageId from @TradeMessageId)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))
  
  delete a -- minimize search for next iteration - remove ids that were deleted
  from @TradeMessageId as a
  where not exists
  (select '1' from srf_main.GTRException
   where TradeMessageId = a.TradeMessageId)

end

end
else
  print 'Table '+@tblname+' does not exist'

--2

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.TradeMessagePayload'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

delete @PayloadId
insert @PayloadId select * from @PayloadIdOrig

while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.TradeMessagePayload WITH (READPAST) -- needs to be by PayloadId (PK), no idx on TradeMessageId
  where  PayloadId in (select PayloadId from @PayloadId)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))
  
  delete a -- minimize search for next iteration - remove ids that were deleted
  from @PayloadId as a
  where not exists
  (select '1' from srf_main.TradeMessagePayload
   where PayloadId = a.PayloadId) 

end

end
else
  print 'Table '+@tblname+' does not exist'

--3

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.TradeMessage'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

delete @TradeMessageId
insert @TradeMessageId select * from @TradeMessageIdOrig
  
while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.TradeMessage WITH (READPAST)-- TradeMessageId (PK)
  where  TradeMessageId in (select TradeMessageId from @TradeMessageId)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))
  
  delete a -- minimize search for next iteration - remove ids that were deleted
  from @TradeMessageId as a
  where not exists 
  (select '1' from @TradeMessageId
   where TradeMessageId = a.TradeMessageId)
   
end

end
else
  print 'Table '+@tblname+' does not exist'

--4.

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.Trade'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

delete @TradeId
insert @TradeId select * from @TradeIdOrig
 
while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.Trade WITH (READPAST)--TradeId (PK)
  where TradeId in (select TradeId from @TradeId)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))
  
  delete a -- don't search for ids being deleted 
  from @TradeId as a
  where not exists 
  (select '1' from srf_main.Trade
   where TradeId = a.TradeId)

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
    delete top (@rc) from srf_main.Exception WITH (READPAST)--no idx on ProcessedDate
      where ProcessedDate < @DeleteOlderThanThisDay
  else
    delete top (@rc) from srf_main.Exception  WITH (READPAST) --no idx on ProcessedDate
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
    delete top (@rc) from srf_main.EODBusinessexception  WITH (READPAST) -- no idx
                  where CreateDate < @DeleteOlderThanThisDay
  else
     delete top (@rc) from srf_main.EODBusinessexception  WITH (READPAST) -- no idx
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
    delete top (@rc) from srf_main.EODTradeStage  WITH (READPAST) -- PK starting on tradeId, cobDate - 17,709,151 row table in prod Rates  
            where cobDate < @DeleteOlderThanThisDay -- is CI scan, i.e. tbl scan
  else
    delete top (@rc) from srf_main.EODTradeStage WITH (READPAST) 
            where convert(char(10), cobDate, 101) = @PurgeThisDate
            
  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))

end

end
else
  print 'Table '+@tblname+' does not exist'

--8.
declare @EODTradeStatusOrig table(EODTradeId int)

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

delete @EODTradeStatus
insert @EODTradeStatus select * from @EODTradeStatusOrig

while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.EODTradeStatus  WITH (READPAST) --idx starting on tradeId
  where EODTradeId in (select EODTradeId from @EODTradeStatus) -- idx starting clmn EODTradeId

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))
  
  delete a
  from @EODTradeStatus a
  where not exists
  (select '1' from srf_main.EODTradeStatus
   where EODTradeId = a.EODTradeId)

end

end
else
  print 'Table '+@tblname+' does not exist'

--9.
select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.BCPGTRResponseData' --FK to EODTrade 

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

delete @EODTradeStatus
insert @EODTradeStatus select * from @EODTradeStatusOrig

while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.BCPGTRResponseData  WITH (READPAST) --unique idx on EODTradeId 
  where EODTradeId in (select EODTradeId from @EODTradeStatus)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))
  
  delete a
  from @EODTradeStatus a
  where not exists
  (select '1' from srf_main.BCPGTRResponseData
   where EODTradeId = a.EODTradeId)

end

end
else
  print 'Table '+@tblname+' does not exist'

--10.

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.EODTrade'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

delete @EODTradeStatus
insert @EODTradeStatus select * from @EODTradeStatusOrig

while @rc = @DeleteNumberOfRowsBatchSize
begin

  delete top (@rc) from srf_main.EODTrade  WITH (READPAST) --unique idx on EODTradeId 
  where EODTradeId in (select EODTradeId from @EODTradeStatus)

  set @rc = @@rowcount
  set @rc_total = @rc_total + @rc
  print 'Table '+@tblname+' , rows deleted = '+cast(@rc_total as varchar(40))
  
  delete a
  from @EODTradeStatus a
  where not exists
  (select '1' from srf_main.EODTrade
   where EODTradeId = a.EODTradeId)

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

spaceusedtbl:

delete @TabSpaceFinal 

declare @Tables table ([schema] sysname,TabName sysname)
		
insert @Tables ([schema], TabName) 
select TABLE_SCHEMA, TABLE_NAME 
from INFORMATION_SCHEMA.TABLES a
join @tbl1 b
on a.TABLE_SCHEMA+'.'+TABLE_NAME = b.tbl
where a.TABLE_TYPE = 'BASE TABLE'
  
declare @TabSpace table  
(TabName sysname
,[Rows] bigint
,Reserved varchar(38)
,Data varchar(38)
,Index_Size varchar(38)
,Unused varchar(38)
)

declare @sqlcmd varchar(200)
  
declare @schema sysname, @TabName sysname

declare TableCursor cursor for
select [schema],TabName from @Tables

open TableCursor

while 1=1
begin
  fetch TableCursor into @schema,@TabName 
  if @@fetch_status  <> 0
    break
    
  set @sqlcmd = 'sp_spaceused '+''''+@schema+'.'+@TabName+''''

  insert @TabSpace  
  exec (@sqlcmd)

  insert @TabSpaceFinal 
  select @schema, TabName
        , convert(bigint, Rows)
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(Reserved, len(Reserved)-3)) / 1024.0) 
                ReservedMB
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(Data, len(Data)-3)) / 1024.0) DataMB
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(Index_Size, len(Index_Size)-3)) / 1024.0) 
                 Index_SizeMB
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(Unused, len([Unused])-3)) / 1024.0) 
                [UnusedMB]
  from @TabSpace
  
  delete @TabSpace
  
end

close TableCursor;
deallocate TableCursor;

if @GoBackFlag = 1
  begin
    set @GoBackFlag = 0
    goto BackToProcessing
  end

insert @TabSpaceAfter
select * from @TabSpaceFinal 

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
