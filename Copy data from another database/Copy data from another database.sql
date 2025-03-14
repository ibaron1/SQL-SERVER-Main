set quoted_identifier off
go
set nocount on
go
select 'insert '+name+' select * from cfe_calltrack..'+name+char(10)+'GO'+char(10)+"print 'Copied data from table "+name+"'"+char(10)+'GO'
from sysobjects
where type='U' and name not like 'rs[_]%'

