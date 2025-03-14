select distinct t.name
from sys.partitions p
inner join sys.tables t
on p.object_id = t.object_id
where p.partition_number <> 1