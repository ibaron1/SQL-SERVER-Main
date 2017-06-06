SELECT ghost_record_count , version_ghost_record_count, * FROM sys.dm_db_index_physical_stats
(DB_ID('FALCON_SRF_Credit'), OBJECT_ID('srf_main.EODTradeStage'), NULL, NULL , 'DETAILED'); 