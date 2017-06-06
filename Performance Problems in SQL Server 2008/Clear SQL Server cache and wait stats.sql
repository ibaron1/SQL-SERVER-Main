
CHECKPOINT
GO
/*
to test queries with a cold buffer cache without shutting down and restarting the server. DBCC DROPCLEANBUFFERS serves to empty the data cache. Any data loaded into the buffer cache due to the prior execution of a query is removed.
*/
DBCC DROPCLEANBUFFERS
GO
--clear the procedure cache
DBCC FREEPROCCACHE
GO

-- Clear Wait Stats
DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);
