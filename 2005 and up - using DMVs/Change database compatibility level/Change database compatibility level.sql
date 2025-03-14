EXEC sp_dbcmptlevel SecurityNew, 90
EXEC sp_dbcmptlevel MarketData, 90
EXEC sp_dbcmptlevel staging1, 90
EXEC sp_dbcmptlevel RiskBook, 90
EXEC sp_dbcmptlevel RISKWORLD, 90
EXEC sp_dbcmptlevel Logger70, 90
EXEC sp_dbcmptlevel RISKWORLD_ARCHIVE, 90
EXEC sp_dbcmptlevel RISKBOOK_ARCHIVE, 90

select name as [databases could not be changed to compatibility level 90]
from sys.databases
where compatibility_level < 90