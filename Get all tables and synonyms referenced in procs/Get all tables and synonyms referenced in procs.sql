Select  distinct OBJECT_NAME(d.id) procname,OBJECT_NAME(depid) as DepObjName, 
case o.type when 'U' then 'table' 
when 'SN' then 'synonym' 
when 'V' then 'view'
else '' end as DepObjType
from sysdepends d join sysobjects o
on d.depid = o.id
join CapaxMigrationToolkit.dbo.Procs_cmxdb_ActivityLog c
on d.id = OBJECT_ID(c.procname)


/*********** Get unique list of tables, views  and synonyms **********/

Select  distinct OBJECT_NAME(depid) as procname, 
case o.type when 'U' then 'table' 
when 'SN' then 'synonym' 
when 'V' then 'view'
else '' end as DepObjType
from sysdepends d join sysobjects o
on d.depid = o.id
join CapaxMigrationToolkit.dbo.Procs_cmxdb_ActivityLog c
on d.id = OBJECT_ID(c.procname)


/**** Get tables referenced in views by views ****/

Select  distinct OBJECT_NAME(d.id) procname,OBJECT_NAME(depid) as DepObjName, 
case o.type when 'U' then 'table' 
when 'SN' then 'synonym' 
when 'V' then 'view'
else '' end as DepObjType
from sysdepends d join sysobjects o
on d.depid = o.id
join CapaxMigrationToolkit.dbo.Procs_cmxdb_ActivityLog c
on d.id = OBJECT_ID(c.procname)
where o.type <> 'P'
order by DepObjType


/**** Get unique tables referenced in procs and views  ****/

Select  OBJECT_NAME(depid) as [Table or synonym], 
case o.type when 'U' then 'table' 
when 'SN' then 'synonym' end as [Type] 
from sysdepends d join sysobjects o
on d.depid = o.id
join CapaxMigrationToolkit.dbo.Procs_cmxdb_ActivityLog c
on d.id = OBJECT_ID(c.procname)
where o.type in ('U','SN')
union
Select  OBJECT_NAME(depid) as DepObjName, 
case o.type when 'U' then 'table' 
when 'SN' then 'synonym' end as DepObjType 
from sysdepends d join sysobjects o
on d.depid = o.id
WHERE object_name(d.id) in ('CustomerView','OrderDetailOIT')
order by [Type]