
set nocount on

declare @PurgeThisDate char(10) = NULL, -- format: mm/dd/yyyy
@PurgePriorToThisDate char(10) = '2/1/2013', -- format: mm/dd/yyyy
@DeletionThreshold int = 30, -- in days from current date
@DeleteNumberOfRowsBatchSize int = 50000,
@shrinkdatabase char(1) = 'N' 

declare @RunTime_min int = 420 -- run for 2hrs 30 min

declare @DeleteOlderThanThisDay char(10), @currDate char(10) 

declare @startTime datetime = getdate()

if @PurgePriorToThisDate is null
	select @DeleteOlderThanThisDay = convert(char(10), dateadd(dd,-1*(@DeletionThreshold),getdate()), 101)
	,@currDate = convert(char(10), getdate(), 101)
else
	select @DeleteOlderThanThisDay = @PurgePriorToThisDate

declare @rc int, @rc_total int

declare @tbl table (tbl sysname, ChildTo sysname, IfExists char(1) default 'Y', hasLOBcolumn char(1) default 'N')

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
values ('srf_main.EODBusinessexception','')
,('srf_main.EODTradeStage','')
,('srf_main.EODTradeStatus','srf_main.EODTrade')
,('srf_main.BCPGTRResponseData','srf_main.EODTrade')
,('srf_main.EODTrade','')

update @tbl
set ifexists = 'N'
where object_id(tbl) is null

;with a_cte 
as
(select (schema_name(o.schema_id)+'.'+o.name) as [Table], c.name as [Column],
t.name as [Large datatype], c.length
from sys.objects o join sys.syscolumns c 
on o.object_id = c.id and o.type = 'U'
join systypes t 
on c.xtype = t.xtype
and t.name in ('image','text','xml')
union
select (schema_name(o.schema_id)+'.'+o.name) as [Table], c.name as [Column],
t.name as [Large datatype], c.length
from sys.objects o join sys.syscolumns c 
on o.object_id = c.id and o.type = 'U'
join systypes t 
on c.xtype = t.xtype
where c.length = -1 -- columns with max length and data types (n)varchar, (n)varbinary
and t.name <> 'sysname')
update a
set hasLOBcolumn = 'Y'
from @tbl a join a_cte b
on a.tbl = b.[Table]

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
         
    print 'Deleting data for '+@PurgeThisDate
    
    set @DeleteOlderThanThisDay = 0

  end
else
  begin
    print 'Deleting data prior to '+@DeleteOlderThanThisDay
  end

print ''
print 'START of deleting old data :'+cast(@starttime as varchar(24))
print ''

declare @tblname varchar(128)

--1.

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, 
@tblname = 'srf_main.EODBusinessexception'


if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin


while @rc = @DeleteNumberOfRowsBatchSize 
begin

  if datediff(mi, @startTime, getdate()) > @RunTime_min
    begin   
      print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
      print 'Start time '+cast(@startTime as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
      goto spaceusedtbl   
    end

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

--2.

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.EODTradeStage'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

while @rc = @DeleteNumberOfRowsBatchSize
begin

  if datediff(mi, @startTime, getdate()) > @RunTime_min
    begin   
      print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
      print 'Start time '+cast(@startTime as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
      goto spaceusedtbl   
    end

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

--3.
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

  if datediff(mi, @startTime, getdate()) > @RunTime_min
    begin   
      print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
      print 'Start time '+cast(@startTime as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
      goto spaceusedtbl   
    end

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

--4.
select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.BCPGTRResponseData' --FK to EODTrade 

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

delete @EODTradeStatus
insert @EODTradeStatus select * from @EODTradeStatusOrig

while @rc = @DeleteNumberOfRowsBatchSize
begin

  if datediff(mi, @startTime, getdate()) > @RunTime_min
    begin   
      print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
      print 'Start time '+cast(@startTime as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
      goto spaceusedtbl   
    end

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

--5.

select @rc = @DeleteNumberOfRowsBatchSize, @rc_total = 0, @tblname = 'srf_main.EODTrade'

if (select IfExists from @tbl where tbl = @tblname) = 'Y'
begin

delete @EODTradeStatus
insert @EODTradeStatus select * from @EODTradeStatusOrig

while @rc = @DeleteNumberOfRowsBatchSize
begin

	if datediff(mi, @startTime, getdate()) > @RunTime_min
	begin   
	  print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
	  print 'Start time '+cast(@startTime as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
	  goto spaceusedtbl   
	end

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
join @tbl b
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

select c.tbl as [Table],c.ChildTo,c.IfExists, c.hasLOBcolumn
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
select '','','','','','','','','','','','','','','', ''
  union all
select 'TOTAL','','','',
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
