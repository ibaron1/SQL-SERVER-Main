use riskworld
go
select 'ALTER INDEX '+IndexName+' ON '+ObjectName+' REBUILD WITH (SORT_IN_TEMPDB = ON)'
from fraglist f join sys.indexes i
on f.IndexName = i.name
where ScanDensity <= 95
order by ObjectName,type -- 1 - Clustered, 2 - Non-Clustered