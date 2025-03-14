select AppDataType,Tbl, count(1) as [count across workflows]
from core.DataArchivingAndPurgingConfig
group by AppDataType,Tbl
order by AppDataType,Tbl