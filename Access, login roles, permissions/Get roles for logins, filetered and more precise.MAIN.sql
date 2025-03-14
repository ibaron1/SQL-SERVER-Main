select @@servername as sql_server;

select name, type_desc 
from sys.objects 
where type in ('U' , 'P') 
order by type desc; 

;WITH CTE_Roles 
AS 
(SELECT 
FROM sys.database_role_members 
--WHERE member_principal_id in ('','') 
UNION ALL 
--select db_name() as [database] 
SELECT drm.member_principal_id,drm.role_principal_id 
FROM sys.database_role_members drm 
INNER JOIN CTE_Roles CR 
ON drm.member_principal_id = CR.member_principal_id
) 
SELECT USER UserName,USER RoleName 
FROM CTE Roles 
where USER like and member_principal_id < > USER ID() 
ORDER BY 


;WITH CTE_R01es (member_principal_id, 
SELECT member_principal_id, role_principal_id 
FROM sys 
- -WHERE in ( 
UNION ALL 
SELECT role_principal_id 
FROM sys drm 
INNER JOIN CTE Roles CR 
ON drm.member_principal_id 
= CR.role_principal_id 
SELECT @@servername as sql_server, db_name() as [database], 
USER UserName,USER RoleName, 
FROM CTE Roles 
where USER = 'MSAD\eIib' 
ORDER BY 
getdate() [as of] 