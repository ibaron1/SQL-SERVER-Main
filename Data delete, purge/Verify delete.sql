set nocount on

declare @DeleteDays int = 25

declare @DeleteOlderThanThisDay char(10), @currDate char(10)

select @DeleteOlderThanThisDay = convert(char(10), dateadd(dd,-1*(@DeleteDays),getdate()), 101)
,@currDate = convert(char(10), getdate(), 101)

	    select t.TradeId into #TradeId 
            from srf_main.Trade t
      		where   t.TradeId in (
            		select t.TradeId from
                  	srf_main.Trade t
                  		left outer join srf_main.TradeMessage tm
                        on t.TradeId = tm.TradeId
                  		inner join srf_main.TradeMessagePayload tp
                        on tm.TradeMessageId = tp.TradeMessageId
                  	where tm.ArrivalDateTime < @DeleteOlderThanThisDay)

            select DISTINCT tp.TradeMessageId, tp.PayloadId into #TradeMessageId_PayloadId --39019 rows 
            from #TradeId t
                  left outer join srf_main.TradeMessage tm
                        on t.TradeId = tm.TradeId
                  inner join srf_main.TradeMessagePayload tp
                        on tm.TradeMessageId = tp.TradeMessageId
                  where tm.ArrivalDateTime < @DeleteOlderThanThisDay
                  
            select DISTINCT TradeMessageId into #TradeMessageId --16407 rows 
            from #TradeMessageId_PayloadId 
            order by TradeMessageId
            
            select DISTINCT PayloadId into #PayloadId --39019 rows 
            from #TradeMessageId_PayloadId 
            order by PayloadId

select count(*) as [srf_main.GTRException Rows count]
from srf_main.GTRException --GTRExceptionId (PK)
      where  TradeMessageId in (select TradeMessageId from #TradeMessageId)

select count(*) as [srf_main.TradeMessagePayload Rows count]
from srf_main.TradeMessagePayload -- needs to be by PayloadId (PK), no idx on TradeMessageId
      where  PayloadId in (select PayloadId from #PayloadId)

select count(*) as [srf_main.TradeMessage Rows count]
from srf_main.TradeMessage -- TradeMessageId (PK)
      where   TradeMessageId in (select TradeMessageId from #TradeMessageId)

select count(*) as [srf_main.Trade Rows count]
from srf_main.Trade --TradeId (PK)
      where   TradeId in (select TradeId from #TradeId)

select count(*) as [srf_main.Exception Rows count]
from srf_main.Exception --no idx on ProcessedDate
      where ProcessedDate < @DeleteOlderThanThisDay

select count(*) as [srf_main.EODBusinessexception Rows count]
from srf_main.EODBusinessexception -- no idx
                  where CreateDate < @DeleteOlderThanThisDay

select count(*) as [srf_main.EODTradeStage Rows count]
from srf_main.EODTradeStage -- PK starting on tradeId, cobDate - 17,709,151 row table in prod Rates  
            where cobDate < @DeleteOlderThanThisDay -- is CI scan, i.e. tbl scan

select distinct e1.EODTradeId into #EODTradeStatus 
	    from srf_main.EODTradeStatus es
            join srf_main.EODTrade e1
                  on e1.EODTradeId = es.EODTradeId
            where e1.CreateDate < @DeleteOlderThanThisDay

select count(*) as [srf_main.EODTradeStatus Rows count]
from srf_main.EODTradeStatus --idx starting on tradeId
  where EODTradeId in -- idx starting clmn EODTradeId
  (select EODTradeId from #EODTradeStatus)

select count(*) as [srf_main.EODTrade Rows count]
from srf_main.EODTrade --unique idx on EODTradeId 
  where EODTradeId in (select EODTradeId from #EODTradeStatus)

drop table #TradeId, #TradeMessageId_PayloadId, #TradeMessageId, #PayloadId, #EODTradeStatus
