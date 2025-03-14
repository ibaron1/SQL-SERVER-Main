Recommended by MS -

Initially

--1.
DBCC CLEANTABLE (FALCON_SRF_Rates,"srf_main.EODTradeStage", 0)
WITH NO_INFOMSGS;

--2.
dbcc shrinkdatabase ('FALCON_SRF_Rates', notruncate)



--1.
ALTER INDEX PK__EODTrade__EC020E91092CB0BA ON srf_main.EODTradeStage REORGANIZE WITH (LOB_COMPACTION = ON) ;


--2.
dbcc shrinkdatabase ('FALCON_SRF_Rates', notruncate)

