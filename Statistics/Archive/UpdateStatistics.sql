set nocount on

declare @SqlString varchar(200)

declare
UpdStat_crsr cursor local fast_forward for
select distinct 'UPDATE STATISTICS '+object_name(id)+' WITH FULLSCAN'
from sysindexes
where object_name(id) not like 'sys%'
and datediff(DAY, STATS_DATE (id , indid), GETDATE()) > 2

open UpdStat_crsr


while 1 = 1
begin

  fetch UpdStat_crsr into @SqlString

  if @@fetch_status <> 0
            break 
            
  print  @SqlString
  exec(@SqlString)  
            

end

close UpdStat_crsr
deallocate UpdStat_crsr

select distinct 'UPDATE STATISTICS '+object_name(id)+' WITH FULLSCAN'
from sysindexes
where object_name(id) not like 'sys%'
and datediff(DAY, STATS_DATE (id , indid), GETDATE()) > 2

/**** verify ****/

select object_name(id) as tbl, [name] as Idx, 
STATS_DATE (id , indid) StatsUpdateDate,
datediff(DAY, STATS_DATE (id , indid), GETDATE()) as UpdDate
from sysindexes
where object_name(id) not like 'sys%'
and datediff(DAY, STATS_DATE (id , indid), GETDATE()) > 2
and datediff(DAY, STATS_DATE (id , indid), GETDATE()) is not null
order by object_name(id)

go