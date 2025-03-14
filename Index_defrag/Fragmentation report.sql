
  select ObjectName, IndexName, 
    CASE WHEN I.type = 1 THEN 'Clustered' 
          WHEN I.type = 2 THEN 'Non-Clustered' 
          ELSE 'Unknown' END Index_Type,
CountPages, ScanDensity as [ScanDensity in % (no fragmentation when 100)] 
  from fraglist f join sys.indexes i
on f.IndexName = i.name
  where ScanDensity <= 99
order by ObjectName,type 
--order by CountPages desc,ScanDensity 