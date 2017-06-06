use riskbook
go
select g.name, object_name(major_id) as 'Object',
permission_name
from sys.database_permissions p
join sys.database_principals g
on p.grantee_principal_id = g.principal_id
and g.name = 'public' -- role or user
order by 1,2 
go

select * from sys.database_principals 
select * from sys.server_principals