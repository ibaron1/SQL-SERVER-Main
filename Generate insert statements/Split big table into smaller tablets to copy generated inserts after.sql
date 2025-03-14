

CREATE TABLE dbo.EnrichedUTI 
([PublisherTradeId] VARCHAR(100), [TradeIdType] VARCHAR(30), 
[UTI] VARCHAR(100), [UTIPrefix] VARCHAR(100))

  
select distinct * into dbo.Enriched_SRF_UTI from dbo.EnrichedUTI --378014

  
alter table dbo.Enriched_SRF_UTI
ADD RowNumber int IDENTITY 
 
-- split table into smaller tables

declare @maxRows int

select @maxRows = MAX(RowNumber) from dbo.Enriched_SRF_UTI --378014

declare @rowNumInTablets int = 40000

declare @i int = 0, @n int = 1
declare @j int = @rowNumInTablets

declare @sqlstr varchar(2000)

while @i <= (select MAX(RowNumber) from dbo.Enriched_SRF_UTI)
begin 

	select @sqlstr =  
	 'select TradeIdType, PublisherTradeID, UTIPrefix, UTI into dbo.Enriched_SRF_UTI_'+cast(@n as varchar(4))+' from dbo.Enriched_SRF_UTI where RowNumber > '+ cast(@i as varchar(10))+' and RowNumber <= '+cast(@j as varchar(10))
	  
	print @sqlstr
	exec (@sqlstr)
 
	set @i += @rowNumInTablets
	
	set @j += @rowNumInTablets
	 
	set @n = @n+1
 
end
 

/*
select 'drop table dbo.'+name
from sysobjects
where name like 'Enriched_SRF_UTI[_]%'
*/