
select object_name(id) as tbl, [name] as Idx, 
STATS_DATE (id , indid) StatsUpdateDate
from sysindexes
where object_name(id) not like 'sys%'
--order by object_name(id)
order by StatsUpdateDate