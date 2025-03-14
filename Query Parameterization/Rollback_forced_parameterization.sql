
declare @sqlstr varchar(400)

select name  as db into #db from sys.databases
where is_parameterization_forced = 1 and
name not in ('master','tempdb','model','msdb','dbautils','apputils') and name not like 'FALCON%Cache'

select * into #db_copy from #db

select 'Parameterization before'
select name, is_parameterization_forced 
from sys.databases sd join #db  as d
on sd.name = d.db 

while exists (select 1 from #db)
begin
  set @sqlstr = 'alter database '+(select top(1) db from #db)+' set parameterization simple with no_wait'
  --print @sqlstr
  exec (@sqlstr)
  
  delete top(1) from #db
end

select 'Parameterization after'
select name, is_parameterization_forced 
from sys.databases sd join #db_copy as d
on sd.name = d.db 
  
drop table #db, #db_copy



go