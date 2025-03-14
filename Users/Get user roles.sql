/**************************************************
 This code will tell you what roles in each database a user has.  
**************************************************/
declare @RoleName varchar(50)
declare @UserName varchar(50)
declare @CMD varchar(1000)

set @UserName = 'username'

create Table #UserRoles
(DatabaseName varchar(50), 
Role varchar(50))

create table #RoleMember
(DBRole varchar(100),
MemberName varchar(100),
MemberSid varbinary(2048))


set @CMD = 'use ?

truncate table #RoleMember

insert into #RoleMember
exec sp_helprolemember 

insert into #UserRoles
(DatabaseName, Role)
select db_name(), dbRole
from #RoleMember
where MemberName = ''' + @UserName + ''''

exec sp_MSForEachDB @CMD

select * from #UserRoles

drop table #UserRoles
drop table #RoleMember



/**************************************************
 A full audit of all the login role assigments on your server 
**************************************************/
declare @RoleName varchar(50)
declare @CMD varchar(1000)

create Table #UserRoles
(DatabaseName varchar(50), 
Role varchar(50))

create table #RoleMember
(DBRole varchar(100),
MemberName varchar(100),
MemberSid varbinary(2048))


set @CMD = 'use ?

truncate table #RoleMember

insert into #RoleMember
exec sp_helprolemember 

insert into #UserRoles
(DatabaseName, Role)
select db_name(), dbRole
from #RoleMember'

exec sp_MSForEachDB @CMD

select * from #UserRoles

drop table #UserRoles
drop table #RoleMember
