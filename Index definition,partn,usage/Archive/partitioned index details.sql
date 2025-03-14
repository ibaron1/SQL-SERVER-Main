

select 
    object_schema_name(i.object_id) as [schema],
    object_name(i.object_id) as [object_name],
    t.name as [table_name],
    i.name as [index_name],
    s.name as [partition_scheme]
from sys.indexes i
    join sys.partition_schemes s on i.data_space_id = s.data_space_id
    join sys.tables t on i.object_id = t.object_id    

-- List partitioned tables (excluding system tables)

SELECT DISTINCT so.name
FROM sys.partitions sp
       JOIN sys.objects so ON so.object_id = sp.object_id
       where name NOT LIKE 'sys%' and name NOT LIKE 'sqla%' and name NOT LIKE 'plan%' 
       and name NOT LIKE 'persistent%' and name NOT LIKE 'queue_messages%'
       and name NOT LIKE 'ifts%' and name NOT LIKE 'fulltext%'
       ORDER BY name


-- List partitioned tables and partition information (excluding system tables)

SELECT so.name
      ,[partition_id]
      ,sp.[object_id]
      ,[index_id]
      ,[partition_number]
      ,[hobt_id]
      ,[rows]
      ,[filestream_filegroup_id]
      ,[data_compression]
      ,[data_compression_desc]
  FROM sys.partitions sp
       JOIN sys.objects so ON so.object_id = sp.object_id
       where name NOT LIKE 'sys%' and name NOT LIKE 'sqla%' and name NOT LIKE 'plan%' 
       and name NOT LIKE 'persistent%' and name NOT LIKE 'queue_messages%'
       and name NOT LIKE 'ifts%' and name NOT LIKE 'fulltext%'
       ORDER BY name