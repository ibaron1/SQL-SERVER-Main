select * from sys.sql_logins 

select * from sys.server_principals 
where type_desc in ('SQL_LOGIN','WINDOWS_LOGIN','WINDOWS_GROUP')
order by type_desc