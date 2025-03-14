declare @sqlstr varchar(400)
select @sqlstr='ALTER TABLE [srf_main].[TradeRptJurisdiction] DROP CONSTRAINT '+object_name(constraint_object_id)
from sys.foreign_key_columns
where referenced_object_id=object_id('srf_main.trade')
and parent_object_id=object_id('srf_main.TradeRptJurisdiction')
exec(@sqlstr)