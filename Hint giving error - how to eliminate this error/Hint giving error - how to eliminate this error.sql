select distinct sd.id, sd.Name as Party1Name
into #Party1Name 
from srf_main.Trade as t with (forceseek)
join srf_main.TradeMessage as tm with (forceseek)
on t.TradeId = tm.TradeId
join FALCON_SRF_Cache.srf_cache.D_SDSRefData sd
on sd.id = t.LegalEntitySdsId
where tm.ArrivalDateTime between @startdate and @enddate
and tm.TradeMessageId in 
(select MAX(tm30.TradeMessageId) from srf_main.TradeMessage tm30 with (forceseek) 
 where tm30.TradeId = tm.TradeId and
 tm30.MsgType = tm.MsgType 						
 and tm30.GTRMsgStatus='Submit')

OPTION (RECOMPILE)