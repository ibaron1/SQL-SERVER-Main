
USE [FALCON_SRF_Credit]
GO
/****** object:	StoredProcedure [srf_main].[EodSnapshotGetAllDiff] Script Date:
09/15/2015 13:09:15 ******/
SET ANSI_NULLS ON GO
SET QUOTED_IDENTIFIER ON GO
-- Author: Eli Baron -- Create date: 2015-04-02
-- Description: Get Diff in Fields fr all trades from EOD snapshot Files Summary Report ; JIRA TTRR-1979
create proc [srf_main].[EodsnapshotGetAllDiff] with execute as owner as
set transaction isolation level read uncommitted set implicit_transactions off set nocount on
declare @cobDate date,
@publisher varchar(100),
@reportingjurisdiction varchar(100),
@tradePartylTransactionld varchar(100),
@tradeParty2Transactionld varchar(100),
@mismatchedFields varchar(max),
@sqlstr varchar(max)
create table #MismatchBW (cobDate date,
publisher varchar(100) null, reportingjurisdiction varchar(100), tradePartylTransactionld varchar(100), tradeParty2Transactionld varchar(100), mismatchedFieldName varchar(100), mismatchedFieldvalue varchar(100) null)
create table #MismatchFAEOD (cobDate date,
publisher varchar(100) null, reportingjurisdiction varchar(100), tradePartylTransactionld varchar(100), tradeParty2Transactionld varchar(100), mismatchedFieldName varchar(100), mismatchedFieldvalue varchar(100) null)
truncate table srf_main.EODSnapshotCompareMismatch
declare abc_cursor cursor fast_forward for select
cobDate,publisher,reportingjurisdiction,tradePartylTransactionld,tradeParty2Transactionld,mismatchedFields
from srf_main.EODSnapshotCompareResult
where linkFlag = 'Both'

open abc_cursor

while 1=1 
begin

fetch abc_cursor into
@cobDate,@pub!isher.@reportingjurisdiction,@tradePartylTransactionld,@tradeParty2Tra nsactionld,@mismatchedFields

if @@FETCH_STATUS <> 0 
	break

select @mismatchedFields = mismatchedFields 
from srf_main.EODSnapshotCompareResult 
where cobDate = @cobDate 
and publisher = @publisher
and reportingjurisdiction = @reportingJurisdiction 
and tradePartylTransactionid = @tradePartylTransactionld 
and tradeParty2Transactionld = @tradeParty2Transactionld

if OBJECT_ID('tempdb.dbo.##EODSnapshotBWtmp') is not null 
	drop table ##EODSnapshotBWtmp

set @sqlstr = 'select '+@mismatchedFields+' into ##EODSnapshotBWtmp from 
srf_main.EODSnapshotBW where ' +
'cobDate = '''+cast(@cobDate as char(10))+
''' and publisher = '''+@publisher+
''' and reportingjurisdiction = '''+@reportingjurisdiction+
'''and tradePartylTransactionld = '''+@tradePartylTransactionld+
'''and tradeParty2Transactionld = '''+@tradeParty2Transactionld+''''

exec (@sqlstr) 

select @sqlstr =
'select '+
''''+cast(@cobDate as CHAR(10))+''','+
''''+@publisher+''',' +
''''+@reportingjurisdiction+''','+
''''+@tradePartylTransactionld+''','+
''''+@tradeParty2Transactionld+''','+
'unpvt.clmn, 
unpvt.value
from ##EODSnapshotBWtmp 
unpivot (
value for clmn in ('+stuff(
				select ','+ c.name from tempdb.sys.columns c join tempdb.sys.objects o
							on c.Object_id = o.Object_id 
							where o.name = '##EODSnapshotBWtmp'
				for xml path(' ')
				)
				,1,1,'') + ')
) unpvt'
from tempdb.sys.columns c join tempdb.sys.objects o
on c.object_id = o.Object_id
where o.name = '##EODSnapshotBWtmp' 

truncate table #MismatchBW

insert #MismatchBW 
exec (@sqlstr)
