SELECT
      CONCAT(QUOTENAME(OBJECT_SCHEMA_NAME(p.object_id)), N'.', QUOTENAME(OBJECT_NAME(p.object_id))) AS ObjectName 
    , i.name AS IndexName
    , p.index_id AS IndexID 
    , ds.name AS PartitionScheme 
    , p.partition_number AS PartitionNumber 
    , fg.name AS FileGroupName 
    , prv_left.value AS LowerBoundaryValue 
    , prv_right.value AS UpperBoundaryValue 
    , CASE pf.boundary_value_on_right WHEN 1 THEN 'RIGHT' ELSE 'LEFT' END AS PartitionFunctionRange 
    , p.rows AS Rows
	, pst.used_page_count AS UsedPages
	, pst.used_page_count * 8 AS UsedSpaceKB
	, pst.reserved_page_count as ReservedPages
	, pst.reserved_page_count * 8 as ReservedSpaceKB
FROM
    sys.partitions AS p 
    INNER JOIN sys.dm_db_partition_stats AS pst ON p.partition_id = pst.partition_id
    INNER JOIN sys.indexes AS i ON i.[object_id] = p.[object_id] AND i.index_id = p.index_id
    INNER JOIN sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id
    INNER JOIN sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id
    INNER JOIN sys.partition_functions AS pf ON pf.function_id = ps.function_id
    INNER JOIN sys.destination_data_spaces AS dds2 ON dds2.partition_scheme_id = ps.data_space_id AND dds2.destination_id = p.partition_number
    INNER JOIN sys.filegroups AS fg ON fg.data_space_id = dds2.data_space_id
    LEFT OUTER JOIN sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id AND prv_left.boundary_id = p.partition_number - 1
    LEFT OUTER JOIN sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id AND prv_right.boundary_id = p.partition_number
ORDER BY
      ObjectName
    , IndexID
    , p.partition_number;

--or if the above is slow running, from Jim Crouse of ServiceMAC on 9/25/2024

SELECT      *
FROM
            (   SELECT          TOP (2147483647)
                                CONCAT(QUOTENAME(OBJECT_SCHEMA_NAME(p.object_id)), N'.', QUOTENAME(OBJECT_NAME(p.object_id))) AS ObjectName
                              , i.name                                                                                        AS IndexName
                              , p.index_id                                                                                    AS IndexID
                              , ds.name                                                                                       AS PartitionScheme
                              , p.partition_number                                                                            AS PartitionNumber
                              , fg.data_space_id
                              , fg.name                                                                                       AS FileGroupName
                              , prv_left.value                                                                                AS LowerBoundaryValue
                              , prv_right.value                                                                               AS UpperBoundaryValue
                              , CASE pf.boundary_value_on_right WHEN 1 THEN 'RIGHT' ELSE 'LEFT' END                           AS PartitionFunctionRange
                              , p.rows                                                                                        AS Rows
                              , pst.used_page_count                                                                           AS UsedPages
                              , pst.used_page_count * 8                                                                       AS UsedSpaceKB
                              , pst.reserved_page_count                                                                       AS ReservedPages
                              , pst.reserved_page_count * 8                                                                   AS ReservedSpaceKB
                FROM            sys.partitions              AS p
                INNER JOIN      sys.dm_db_partition_stats   AS pst ON
                                p.partition_id            = pst.partition_id
                INNER JOIN      sys.indexes                 AS i ON
                                i.[object_id]             = p.[object_id]
                                AND i.index_id            = p.index_id
                INNER JOIN      sys.data_spaces             AS ds ON
                                ds.data_space_id          = i.data_space_id
                INNER JOIN      sys.partition_schemes       AS ps ON
                                ps.data_space_id          = ds.data_space_id
                INNER JOIN      sys.partition_functions     AS pf ON
                                pf.function_id            = ps.function_id
                LEFT OUTER JOIN sys.destination_data_spaces AS dds2 ON
                                dds2.partition_scheme_id  = ps.data_space_id
                                AND dds2.destination_id   = p.partition_number
                LEFT OUTER JOIN sys.filegroups              AS fg ON
                                fg.data_space_id          = dds2.data_space_id
                LEFT OUTER JOIN sys.partition_range_values  AS prv_left ON
                                ps.function_id            = prv_left.function_id
                                AND prv_left.boundary_id  = p.partition_number - 1
                LEFT OUTER JOIN sys.partition_range_values  AS prv_right ON
                                ps.function_id            = prv_right.function_id
                                AND prv_right.boundary_id = p.partition_number) AS SysData
WHERE       SysData.data_space_id IS NOT NULL 
--AND ObjectName = '[Results].[RuleResults]'
ORDER BY    SysData.ObjectName
          , SysData.IndexID
          , SysData.PartitionNumber;




---==========================================

SELECT SCHEMA_NAME(so.schema_id) AS schema_name ,
   OBJECT_NAME(p.object_id) AS object_name ,
   p.partition_number ,
   p.data_compression_desc ,
   dbps.row_count ,
   dbps.reserved_page_count * 8 / 1024. AS reserved_mb ,
   si.index_id ,
   CASE WHEN si.index_id = 0 THEN '(heap!)'
      ELSE si.name
   END AS index_name ,
   si.is_unique ,
   si.data_space_id ,
   mappedto.name AS mapped_to_name ,
   mappedto.type_desc AS mapped_to_type_desc ,
   partitionds.name AS partition_filegroup ,
   pf.name AS pf_name ,
   pf.type_desc AS pf_type_desc ,
   pf.fanout AS pf_fanout ,
   pf.boundary_value_on_right ,
   ps.name AS partition_scheme_name ,
   rv.value AS range_value
FROM  sys.partitions p
JOIN  sys.objects so
   ON p.object_id = so.object_id
    AND so.is_ms_shipped = 0
LEFT JOIN sys.dm_db_partition_stats AS dbps
   ON p.object_id = dbps.object_id
    AND p.partition_id = dbps.partition_id
JOIN  sys.indexes si
   ON p.object_id = si.object_id
    AND p.index_id = si.index_id
LEFT JOIN sys.data_spaces mappedto
   ON si.data_space_id = mappedto.data_space_id
LEFT JOIN sys.destination_data_spaces dds
   ON si.data_space_id = dds.partition_scheme_id
    AND p.partition_number = dds.destination_id
LEFT JOIN sys.data_spaces partitionds
   ON dds.data_space_id = partitionds.data_space_id
LEFT JOIN sys.partition_schemes AS ps
   ON dds.partition_scheme_id = ps.data_space_id
LEFT JOIN sys.partition_functions AS pf
   ON ps.function_id = pf.function_id
LEFT JOIN sys.partition_range_values AS rv
   ON pf.function_id = rv.function_id
    AND dds.destination_id = CASE pf.boundary_value_on_right
              WHEN 0 THEN rv.boundary_id
              ELSE rv.boundary_id + 1 end