/**** query systabstats ****/

select top 7 object_name(t.id),i.name as indname,t.*
from systabstats t join sysindexes i 
on t.id = i.id and t.indid = i.indid and
t.indid in (0,1) and forwrowcnt <> 0


/**** Dump query plans into sysqueryplans  ****/

set plan dump off  -- on makes query plans being dumped into sysqueryplans
select top 7 object_name(t.id),i.name as indname,t.*
from systabstats t join sysindexes i 
on t.id = i.id and t.indid = i.indid

select * from sysqueryplans


