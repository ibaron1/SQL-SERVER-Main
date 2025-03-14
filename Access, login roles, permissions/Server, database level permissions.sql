--Server Level permissions

--For server role permissions 
SELECT * FROM sys.fn_builtin_permissions('SERVER') ORDER BY permission_name;

--exec sp_srvrolepermission; --But those permissions don't really map to what the previous query returns.

--For Logins permissions

select  ge.name as Grantee,
        gr.name as Grantor,
        o.name as ObjectName,
        p.permission_name,
        P.state_desc 
from sys.server_permissions as p
        left join sys.server_principals as Ge on p.grantee_principal_id = ge.principal_id
        left join sys.server_principals as Gr on p.grantor_principal_id = gr.principal_id
        left join sys.objects as o on p.major_id = o.object_id;

--Database Level Permissions

select  ge.name as Grantee,
        gr.name as Grantor,
        o.name as ObjectName,
        p.permission_name,
        state_desc
from sys.database_permissions as p
        left join sys.database_principals as Ge on p.grantee_principal_id = ge.principal_id
        left join sys.database_principals as Gr on p.grantor_principal_id = gr.principal_id
        left join sys.objects as o on p.major_id = o.object_id;
go
