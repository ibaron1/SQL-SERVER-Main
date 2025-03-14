======================== dependent compiled sql for the object =====================
set nocount on

declare @ObjName varchar(30)
select  @ObjName = 'imssp_holdings_measurisk'

select distinct object_name(d.id) 'Calling', object_name(d.depid) 'Called'
--into #dependObj
from sysdepends d, sysobjects o
where object_name(d.id) = @ObjName
and d.depid = o.id and o.type = 'P'

======================== All dependencies in a database =========================
set nocount on

select name as tbl 
into #tbls
from sysobjects
where type='U'

select distinct object_name(d.id) ObjName, 
case o.type when 'P' then 'Proc' when 'TR' then 'Trigger' when 'V' then 'View' end as type,
object_name(depid) DepObjName
from sysdepends d, sysobjects o, #tbls t 
where d.id = o.id
and object_name(depid) = t.tbl 
order by object_name(depid)
compute count(object_name(depid))
by object_name(depid)

drop table #tbls

======================== All dependencies resolution in a database =========================
-- create table top(name varchar(30))
-- select * from  tempdb..top

set nocount on 

select name as tbl 
into #tbls
from sysobjects
where type='U'

select object_name(d.id) Obj, 
case o.type when 'P' then 'Proc' when 'TR' then 'Trigger' when 'V' then 'View' end as ObjType,
object_name(depid) DepObj,
case o.type when 'P' then 'Proc' when 'TR' then 'Trigger' when 'V' then 'View' end as DepObjType,
t.tbl as Ref_Tbl_ForObj 
into #AllRefs
from #tbls t, sysdepends d, sysobjects o, sysobjects o1 
where d.id = o.id
and object_name(d.depid) = t.tbl 
and d.depid = o1.id
order by Obj



-- select * from #AllRefs

drop table #tbls
--drop table #AllRefs 








