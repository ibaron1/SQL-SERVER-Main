USE FALCON_SRF_CacheQA
GO


if object_id('srf_main.FinalSP_Populate_BatchSize') is not null
  drop proc srf_main.FinalSP_Populate_BatchSize
go

-- EXEC FinalSP_Populate_BatchSize 2000,4

CREATE PROC srf_main.FinalSP_Populate_BatchSize 
@BatchSize int,
@maxLevelOfRecursion int = 10
AS

set nocount on
	
	truncate table FALCON_SRF_Credit_QA.srf_main.CounterParty

	declare @cnt bigint, @i int, @rowcount int

	create table #AllIDs(rownumber bigint, id varchar(255))
	 
   	;with GetIds(id) as
   	(select distinct id from srf_cache.D_SDSRefData)
   	insert #AllIDs
   	select ROW_NUMBER() over (order by id) as rownumber,id
   	from GetIds

	create unique clustered index i on #AllIDs(rownumber)

	create table #ProcessTheseIds (id varchar(255), principal varchar(255))

	select @cnt= max(rownumber)+1 from #AllIDs

	set @i = 1

	while @i <= @cnt 
	begin
		truncate table #ProcessTheseIds

		insert #ProcessTheseIds
		select id, 
		(select top (1) principal from srf_cache.D_SDSRefData where id = a.id)
		from #AllIDs a
		where a.rownumber between @i and @i + @BatchSize
		
		set @rowcount += @@rowcount

		exec srf_main.UpdateUSPersonFlag_CounterpartyTable @maxLevelOfRecursion
		
		if 	@rowcount%10000 = 0			
		  print 'Processed rows: '+cast(@rowcount as varchar(20))

		set @i +=@BatchSize

	END
	 
drop table #AllIDs

go
