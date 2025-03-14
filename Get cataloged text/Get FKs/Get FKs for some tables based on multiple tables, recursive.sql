--EMIR UAT
set nocount on

declare  @SourceDB varchar(128) = db_name()
declare @instance varchar(200) = @@servername
declare @sql nvarchar(4000) 

declare @Tables table([schemaTable] varchar(200))

insert @Tables
values
('srf_main.AlternateTrade'),
('srf_main.BCPValAgg'),
('srf_main.FeedFileFragment'),
('srf_main.FeedActivity'),
('srf_main.FeedExpectedControlMsg'),
('srf_main.EODBusinessexception'),
('srf_main.BCPGTRResponseData'),
('srf_main.EODTrade'),
('srf_main.EODTradeJurisdiction'),
('srf_main.EODTradeRptJurisdiction'),
('srf_main.EODTradeStage'),
('srf_main.EODTradeStatus'),
('srf_main.EODValuationFeedData'),
('srf_main.ErrorWorkFlow'),
('srf_main.Exception'),
('srf_main.GTRException'),
('srf_main.InterEntitySuppressedTrades'),
('srf_main.GTRResponseStage'),
('srf_main.SRFException'),
('srf_main.TempEODLog'),
('srf_main.Trade'),
('srf_main.TradeMessage'),
('srf_main.MsgJurisdiction'),
('srf_main.TradeMessagePayload'),
('srf_main.TradeMessagePayloadTrident'),
('srf_main.TradeMessageRptJurisdiction'),
('srf_main.TradeMessageTrident'),
('srf_main.TradeRptJurisdiction'),
('srf_main.Valuation'),
('srf_main.GTRResponseFileFragmentId')

 declare @FK table
(constraint_object_id int,parent_object_id int,parent_column_id int,
 referenced_object_id int, referenced_column_id int)

declare @tblObjId table(tbl_object_id int)

insert @tblObjId
select distinct OBJECT_ID([schemaTable])
from @Tables
 
;WITH FK_CTE AS 
(select constraint_object_id,parent_object_id,parent_column_id,
referenced_object_id, referenced_column_id
from sys.foreign_key_columns a join @tblObjId b
on a.parent_object_id = b.tbl_object_id or a.referenced_object_id = b.tbl_object_id
union all
select e.constraint_object_id,e.parent_object_id,e.parent_column_id,
e.referenced_object_id, e.referenced_column_id
from FK_CTE join sys.foreign_key_columns e  
on e.referenced_object_id = FK_CTE.parent_object_id
)
insert @FK
select * from FK_CTE OPTION (MAXRECURSION 0)

select  distinct
(select SCHEMA_NAME(SCHEMA_ID) from sys.objects where object_id = a.parent_object_id) +'.'+
object_name(parent_object_id) as [Child table],
(select SCHEMA_NAME(SCHEMA_ID) from sys.objects where object_id = a.referenced_object_id) +'.'+
object_name(referenced_object_id) as [Parent table],
col_name(parent_object_id,parent_column_id) AS [Child key],
col_name(referenced_object_id,referenced_column_id) AS [Parent key],
object_name(constraint_object_id) AS FKConstraintName
from @FK a
order by [Parent table]

select  distinct
(select SCHEMA_NAME(SCHEMA_ID) from sys.objects where object_id = a.parent_object_id) as ReferencingTblSchema,
object_name(parent_object_id) as ReferencingTbl,
(select SCHEMA_NAME(SCHEMA_ID) from sys.objects where object_id = a.referenced_object_id) as ReferencedTblSchema,
object_name(referenced_object_id) as ReferencedTbl,
col_name(parent_object_id,parent_column_id) AS ReferencingColumnName,
col_name(referenced_object_id,referenced_column_id) AS ReferencedColumnName,
object_name(constraint_object_id) AS FKConstraintName
from @FK a
order by ReferencingTbl
