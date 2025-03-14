use OSM_4
go

if object_id('dbo.usp_PurgeExpiredData_new') is not null
  drop proc dbo.usp_PurgeExpiredData_new
go
/*****************************************************
Author. Eli Baron
Date created. 6-18-2018
Description. Purge expired data after 7 calendar days
based on TMS_ENTY_UPD 
Jira WMTRADOSM-834

Modified by Eli Baron
Date modified. 07-25-18
Description. Change to column TMS_LIFTM to identify expired data
Jira WMTRADOSM-953

Modified by Eli Baron
Date modified. 8-6-18
Description. Change data purging to be parent and partition based 
Jira WMTRADOSM-1086 
*****************************************************/
create proc dbo.usp_PurgeExpiredData_new
@PartitionNumber int,
@ExpirationDays int = 7,
@PurgeBatchSize int = 100000,
@RunTime_min int = 120
as
set nocount on

set nocount on
set transaction isolation level read uncommitted
set dateformat mdy

declare 
@PurgeExpiredDataOlderThan datetime,
@StartOfCurrentRun datetime = getdate(),
@tbl varchar(128),
@rc int

declare @EndOfCurrentRun char(1)  = 'N'

declare @Error varchar(4000)

delete dbo.PurgeCycle
where PartitionNumber = @PartitionNumber

delete dbo.PurgeSession
where PartitionNumber = @PartitionNumber

;with spaceStats
as
(select sum(cast(round(size/128.0, 0)/1024 as dec(10,2))) as size_in_GB,
			sum(cast(round(fileproperty(name, 'SpaceUsed')/128.0,0)/1024 as dec(10,2))) as Space_used_in_GB,
			sum(cast(round(size/128.0/1024 - (fileproperty(name, 'SpaceUsed')/128.0)/1024,0) as dec(10,2))) as Available_Space_in_GB
from sys.database_files
			where type_desc = 'rows'
			group by type_desc)
insert dbo.PurgeCycle
(DbName,
PartitionNumber,
DbSize_GB,
Orig_DbSpace_Used_GB,
Orig_DbAvailable_Space_GB,
Orig_Percent_Used,
DataPurgeStarted,
CurrentRunStarted)
select 
db_name(),
@PartitionNumber,
size_in_GB,
Space_used_in_GB,
Available_Space_in_GB,
cast(cast(round(Space_used_in_GB/size_in_GB*100,0) as int) as varchar(10))+'%' as Percent_Used,
getdate() as DataPurgeStarted,
getdate() as CurrentRunStarted
from spaceStats

;with LOB
 as
(select top 100 percent o.name as tbl,
case when t.name is not null then 'Y' end as LOBcolumn
 from sys.objects o 
	 join sys.syscolumns c
		on o.object_id = c.id and o.type = 'U'
	 left join systypes t
		 on c.xtype = t.xtype and (t.name in ('image','text','xml') or (c.length = -1 and t.name <> 'sysname'))
where o.name in ('Entity_Summary','Entity','Event_Activity','Event_Fill')
order by tbl, LOBcolumn desc
)
,PrepareForPurge
as
(select distinct 
tbl,
hasLOBcolumn = (select top 1 LOBcolumn from LOB where tbl = l.tbl and LOBcolumn is not null)
from LOB as l)
insert dbo.PurgeSession
(Tbl, PartitionNumber, hasLOBcolumn)
select tbl,
@PartitionNumber,
case when hasLOBcolumn is null then 'N' else hasLOBcolumn end
from PrepareForPurge

set @PurgeExpiredDataOlderThan = dateadd(dd, -1*@ExpirationDays, getutcdate())

select IDN_ENTY,NUM_ENTY_PART
into #purgeKeys
from dbo.Entity_Summary
where TMS_LIFTM < @PurgeExpiredDataOlderThan
and NUM_ENTY_PART = @PartitionNumber

create unique clustered index i on #purgeKeys(IDN_ENTY,NUM_ENTY_PART)

--1. 
set @tbl = 'Entity'

begin try
 begin

	update dbo.PurgeSession
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from dbo.Entity as e
	    where exists
		(select '1' from #purgeKeys
		 where IDN_ENTY = e.IDN_ENTY and NUM_ENTY_PART = e.NUM_ENTY_PART))
	   ,StartDate = getdate()
	where Tbl = @tbl and PartitionNumber = @PartitionNumber
    option (maxdop 1)

	set @rc = @PurgeBatchSize

	while @rc = @PurgeBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@PurgeBatchSize) e
		from dbo.Entity as e
		join #purgeKeys as pk
		on e.IDN_ENTY = pk.IDN_ENTY and e.NUM_ENTY_PART = pk.NUM_ENTY_PART
		option (maxdop 1)

		set @rc = @@rowcount

		update dbo.PurgeSession
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where Tbl = @tbl and PartitionNumber = @PartitionNumber
	end
	
	update dbo.PurgeSession
	set EndDate = getdate()
	where Tbl = @tbl and PartitionNumber = @PartitionNumber
end
end try
begin catch
	set @Error = 
		'ErrorNumber: '+cast(ERROR_NUMBER() as varchar(100))+' '+
		'ErrorSeverity: '+cast(ERROR_SEVERITY() as varchar(100))+' '+
		'ErrorState: '+cast(ERROR_STATE() as varchar(100))+' '+
		'ErrorLine: '+cast(ERROR_LINE() as varchar(100))+' '+
		'ErrorMessage: '+ERROR_MESSAGE()

	update dbo.PurgeSession
	set Error = @Error
    where Tbl = @tbl and PartitionNumber = @PartitionNumber

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--2. 
set @tbl = 'Event_Activity'

begin try
 begin

	update dbo.PurgeSession
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from dbo.Event_Activity as e
	    where exists
		(select '1' from #purgeKeys
		 where IDN_ENTY = e.IDN_ENTY and NUM_ENTY_PART = e.NUM_ENTY_PART))
	   ,StartDate = getdate()
	where Tbl = @tbl and PartitionNumber = @PartitionNumber
    option (maxdop 1)

	set @rc = @PurgeBatchSize

	while @rc = @PurgeBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@PurgeBatchSize) e
		from dbo.Event_Activity as e
		join #purgeKeys as pk
		on e.IDN_ENTY = pk.IDN_ENTY and e.NUM_ENTY_PART = pk.NUM_ENTY_PART
		option (maxdop 1)

		set @rc = @@rowcount

		update dbo.PurgeSession
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where Tbl = @tbl and PartitionNumber = @PartitionNumber
	end
	
	update dbo.PurgeSession
	set EndDate = getdate()
	where Tbl = @tbl and PartitionNumber = @PartitionNumber
end
end try
begin catch
	set @Error = 
		'ErrorNumber: '+cast(ERROR_NUMBER() as varchar(100))+' '+
		'ErrorSeverity: '+cast(ERROR_SEVERITY() as varchar(100))+' '+
		'ErrorState: '+cast(ERROR_STATE() as varchar(100))+' '+
		'ErrorLine: '+cast(ERROR_LINE() as varchar(100))+' '+
		'ErrorMessage: '+ERROR_MESSAGE()

	update dbo.PurgeSession
	set Error = @Error
    where Tbl = @tbl and PartitionNumber = @PartitionNumber

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--3. 
set @tbl = 'Event_Fill'

begin try
 begin

	update dbo.PurgeSession
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from dbo.Event_Fill as e
	    where exists
		(select '1' from #purgeKeys
		 where IDN_ENTY = e.IDN_ENTY and NUM_ENTY_PART = e.NUM_ENTY_PART))
	   ,StartDate = getdate()
	where Tbl = @tbl and PartitionNumber = @PartitionNumber
    option (maxdop 1)

	set @rc = @PurgeBatchSize

	while @rc = @PurgeBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@PurgeBatchSize) e
		from dbo.Event_Fill as e
		join #purgeKeys as pk
		on e.IDN_ENTY = pk.IDN_ENTY and e.NUM_ENTY_PART = pk.NUM_ENTY_PART
		option (maxdop 1)

		set @rc = @@rowcount

		update dbo.PurgeSession
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where Tbl = @tbl and PartitionNumber = @PartitionNumber
	end
	
	update dbo.PurgeSession
	set EndDate = getdate()
	where Tbl = @tbl and PartitionNumber = @PartitionNumber
end
end try
begin catch
	set @Error = 
		'ErrorNumber: '+cast(ERROR_NUMBER() as varchar(100))+' '+
		'ErrorSeverity: '+cast(ERROR_SEVERITY() as varchar(100))+' '+
		'ErrorState: '+cast(ERROR_STATE() as varchar(100))+' '+
		'ErrorLine: '+cast(ERROR_LINE() as varchar(100))+' '+
		'ErrorMessage: '+ERROR_MESSAGE()

	update dbo.PurgeSession
	set Error = @Error
    where Tbl = @tbl and PartitionNumber = @PartitionNumber

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--4. 
set @tbl = 'Entity_Summary'

begin try
 begin

	update dbo.PurgeSession
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from dbo.Entity_Summary as e
	    where exists
		(select '1' from #purgeKeys
		 where IDN_ENTY = e.IDN_ENTY and NUM_ENTY_PART = e.NUM_ENTY_PART))
	   ,StartDate = getdate()
	where Tbl = @tbl and PartitionNumber = @PartitionNumber
    option (maxdop 1)

	set @rc = @PurgeBatchSize

	while @rc = @PurgeBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@PurgeBatchSize) e
		from dbo.Entity_Summary as e
		join #purgeKeys as pk
		on e.IDN_ENTY = pk.IDN_ENTY and e.NUM_ENTY_PART = pk.NUM_ENTY_PART
		option (maxdop 1)

		set @rc = @@rowcount

		update dbo.PurgeSession
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where Tbl = @tbl and PartitionNumber = @PartitionNumber
	end
	
	update dbo.PurgeSession
	set EndDate = getdate()
	where Tbl = @tbl and PartitionNumber = @PartitionNumber
end
end try
begin catch
	set @Error = 
		'ErrorNumber: '+cast(ERROR_NUMBER() as varchar(100))+' '+
		'ErrorSeverity: '+cast(ERROR_SEVERITY() as varchar(100))+' '+
		'ErrorState: '+cast(ERROR_STATE() as varchar(100))+' '+
		'ErrorLine: '+cast(ERROR_LINE() as varchar(100))+' '+
		'ErrorMessage: '+ERROR_MESSAGE()

	update dbo.PurgeSession
	set Error = @Error
    where Tbl = @tbl and PartitionNumber = @PartitionNumber

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

EndOfCurrentRun:

with spaceStats
as
(select sum(cast(round(size/128.0, 0)/1024 as dec(10,2))) as size_in_GB,
			sum(cast(round(fileproperty(name, 'SpaceUsed')/128.0,0)/1024 as dec(10,2))) as Space_used_in_GB,
			sum(cast(round(size/128.0/1024 - (fileproperty(name, 'SpaceUsed')/128.0)/1024,0) as dec(10,2))) as Available_Space_in_GB
from sys.database_files
			where type_desc = 'rows'
			group by type_desc)
update dbo.PurgeCycle
set Updated_DbSpace_Used_GB = Space_used_in_GB
,Updated_DbAvailable_Space_GB = Available_Space_in_GB
,Updated_Percent_Used = cast(cast(round(Space_used_in_GB/size_in_GB*100,0) as int) as varchar(10))+'%'
,CurentRunEnded = getdate()
,DataPurgeEnded = case when @EndOfCurrentRun = 'N' then getdate() end
from spaceStats
where PartitionNumber = @PartitionNumber

select * from dbo.PurgeCycle
where PartitionNumber = @PartitionNumber

select * from dbo.PurgeSession
where PartitionNumber = @PartitionNumber

if exists 
(select 1 from dbo.PurgeSession 
 where Error is not null and PartitionNumber = @PartitionNumber)
    throw 51000, @Error, 1;

go