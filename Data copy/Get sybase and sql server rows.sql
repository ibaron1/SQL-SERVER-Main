select a.DbName,SybOwner,SybTbl,SybRows#,TABLE_SCHEMA,SqlTbl,[SqlRows#],    
case when (SybRows#-[SqlRows#]) < 0 then 0 else (SybRows#-[SqlRows#]) end as Diff    
from tempdb..sybase_tbls a 
left join tempdb..SqlServer_tbls b
on ltrim(a.DbName)=b.DbName
and SybOwner=TABLE_SCHEMA
and SybTbl=SqlTbl
where SybTbl not like 'rs[_]%'
order by SybRows# desc