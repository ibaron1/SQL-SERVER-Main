

Select  distinct OBJECT_NAME(d.id) ParentObj,OBJECT_NAME(depid) , o.type as DepObjType
from sysdepends d join sysobjects o
on d.depid = o.id
WHERE d.id = OBJECT_ID('s_ac_payment')


/***** get rows # ***/


select 'exec sp_spaceused '+DepObj
from
(Select  distinct OBJECT_NAME(d.id) ParentObj,OBJECT_NAME(depid) DepObj, o.type as DepObjType
from sysdepends d join sysobjects o
on d.depid = o.id
WHERE d.id = OBJECT_ID('s_ac_payment'))  as t
where DepObjType='U'

select 'set nocount on'
select 'select count(*) as '+DepObj+' from '+DepObj
from
(Select  distinct OBJECT_NAME(d.id) ParentObj,OBJECT_NAME(depid) DepObj, o.type as DepObjType
from sysdepends d join sysobjects o
on d.depid = o.id
WHERE d.id = OBJECT_ID('s_ac_payment'))  as t
where DepObjType='U'


/************ to generate as source for data compare tool **********/

