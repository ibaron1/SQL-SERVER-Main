set quoted_identifier on
go
-- LOCK FOR TEST
select concat('select login: ',name,char(10),'; exec sp_locklogin ',name, ' lock')
from master..syslogins
where name not in ('sa','testuser', 'p489920', 'e492862', 'adm_monitor_srv','GPS_DEV') and name not like 'adm%'
and name not like 'dba%'

-- LOCK ALL
select concat('select login: ',name,char(10),'; exec sp_locklogin ',name, ' lock')
from master..syslogins
where name not in ('sa','p489920', 'adm_monitor_srv') and name not like 'adm%'
and name not like 'dba%'

-- UNLOCK
select concat('select login: ',name,char(10),'; exec sp_locklogin ',name, ' unlock')
from master..syslogins

