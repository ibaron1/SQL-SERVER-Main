select sys.schemas.name 'Schema', sys.objects.name Object, sys.database_principals.name username, sys.database_permissions.type permissions_type,
     sys.database_permissions.permission_name, 
     sys.database_permissions.state permission_state,
     sys.database_permissions.state_desc,
     state_desc + ' ' + permission_name + ' on ['+ sys.schemas.name + '].[' + sys.objects.name + '] to [' + sys.database_principals.name + ']' COLLATE LATIN1_General_CI_AS as statement
into #permission
 from sys.database_permissions
 join sys.objects on sys.database_permissions.major_id = 
     sys.objects.object_id
 join sys.schemas on sys.objects.schema_id = sys.schemas.schema_id
 join sys.database_principals on sys.database_permissions.grantee_principal_id = 
     sys.database_principals.principal_id
 order by 1, 2, 3, 5

select name, type
from sysobjects o
where not exists
(select '1' from #permission
 where Object = o.name)
order by type, name 
