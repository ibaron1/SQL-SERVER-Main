select a.DbName,SybOwner,SybTbl,SybRows#,TABLE_SCHEMA,SqlTbl,[SqlRows#],    
(SybRows#-[SqlRows#]) as Diff    
from tempdb..sybase_tbls a 
join tempdb..SqlServer_tbls b
on ltrim(a.DbName)=b.DbName
and SybOwner=TABLE_SCHEMA
and SybTbl=SqlTbl
and SybRows# <> SqlRows#