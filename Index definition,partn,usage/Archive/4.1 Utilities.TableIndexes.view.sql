CREATE VIEW [Utilities].[TableIndexes]
AS
SELECT DB_NAME () AS DatabaseName
	, sc.name AS SchemaName
	, t.name AS TableName
	, si.name AS IndexName
	, CASE WHEN si.type = 5 THEN
		N'CREATE CLUSTERED COLUMNSTORE INDEX ' + QUOTENAME(si.name) + N' ON ' + +QUOTENAME(sc.name) + N'.'
		+ QUOTENAME(t.name) + N' ON [PRIMARY];'
		ELSE
			CASE si.index_id
				WHEN 0 THEN
					N'/* No create statement (Heap) */'
				ELSE
				CASE si.is_primary_key
					WHEN 1 THEN
						N'ALTER TABLE ' + QUOTENAME(sc.name) + N'.' + QUOTENAME(t.name)
						+ N' ADD CONSTRAINT ' + QUOTENAME(si.name) + N' PRIMARY KEY '
						+ CASE WHEN si.index_id > 1 THEN N'NON' ELSE N'' END + N'CLUSTERED '
					ELSE
						N'CREATE ' + CASE WHEN si.is_unique = 1 THEN N'UNIQUE ' ELSE N'' END
						+ CASE WHEN si.index_id > 1 THEN N'NON' ELSE N'' END + N'CLUSTERED ' + N'INDEX '
						+ QUOTENAME(si.name) + N' ON ' + QUOTENAME(sc.name) + N'.' + QUOTENAME(t.name)
						+ N' '
				END +
/* key def */ N'(' + keys.key_definition + N')' +
/* includes */ CASE WHEN includes.include_definition IS NOT NULL THEN
						N' INCLUDE (' + includes.include_definition + N')'
					ELSE
						N''
				END	+
/* filters */ CASE WHEN si.filter_definition IS NOT NULL THEN
					N' WHERE ' + si.filter_definition
					ELSE
						N''
				END +
			/* with clause - compression goes here */
			CASE WHEN row_compression_clause.row_compression_partition_list IS NOT NULL
				OR page_compression_clause.page_compression_partition_list IS NOT NULL THEN
				N' WITH ('
				+ CASE WHEN row_compression_clause.row_compression_partition_list IS NOT NULL THEN
				N'DATA_COMPRESSION = ROW '
				+ CASE WHEN psc.name IS NULL THEN
							N''
						ELSE
							+ N' ON PARTITIONS (' + row_compression_clause.row_compression_partition_list
							+ N')'
				END
			ELSE
				N''
			END + CASE WHEN row_compression_clause.row_compression_partition_list IS NOT NULL
							AND page_compression_clause.page_compression_partition_list IS NOT NULL THEN
							N', '
						ELSE
							N''
				  END 
			+ CASE WHEN page_compression_clause.page_compression_partition_list IS NOT NULL THEN
						N'DATA_COMPRESSION = PAGE '
						+ CASE WHEN psc.name IS NULL THEN
								N''
								ELSE
								+N' ON PARTITIONS (' + page_compression_clause.page_compression_partition_list
								+ N')'
						END
					ELSE
						N''
				END + N')'
			ELSE
				N''
		END +
		/* ON where? filegroup? partition scheme? */
		' ON ' + CASE WHEN psc.name IS NULL THEN
						ISNULL(QUOTENAME(fg.name), N'')
					  ELSE
						psc.name + N' (' + partitioning_column.column_name + N' )'
				 END + N';'
			END
END AS CreateIndexSOL
FROM sys.indexes AS si
JOIN sys.tables AS t ON
	si.object_id = t.object_id
JOIN sys.schemas AS sc ON
	t.schema_id = sc.schema_id
LEFT JOIN sys.dm_db_index_usage_stats AS stat ON
	stat.database_id = DB_ID()
	AND si.object_id = stat.object_id
	AND si.index_id = stat.index_id
LEFT JOIN sys.partition_schemes AS psc ON
	si.data_space_id = psc.data_space_id
LEFT JOIN sys.partition_functions AS pf ON
	psc.function_id = pf.function_id
LEFT JOIN sys.filegroups AS fg ON
	si.data_space_id = fg.data_space_id
/* Key list */
OUTER APPLY
		(SELECT STUFF(

		(SELECT N', ' + QUOTENAME(c.name) + CASE ic.is_descending_key WHEN 1 THEN N' DESC' ELSE N'' END
		FROM sys.index_columns AS ic
		JOIN sys.columns AS c ON
			ic.column_id = c.column_id
			AND ic.object_id = c.object_id
		WHERE ic.object_id = si.object_id
			AND ic.index_id= si.index_id
			AND ic.key_ordinal > 0
		ORDER BY ic.key_ordinal
		FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
		, 1
		, 2
		, '')) AS keys(key_definition)
/* Partitioning Ordinal */
OUTER APPLY
		( SELECT MAX (QUOTENAME (c.name) ) AS column_name
		FROM sys.index_columns AS ic
		JOIN sys.columns AS c ON
			ic.column_id = c.column_id
			AND ic.object_id = c.object_id
		WHERE ic.object_id = si.object_id
		AND ic.index_id = si.index_id
		AND ic.partition_ordinal = 1) AS partitioning_column
/* Include list */
OUTER APPLY
(SELECT STUFF(( SELECT N', ' + QUOTENAME(c.name)
FROM sys.index_columns AS ic
JOIN sys.columns AS c ON
	ic.column_id = c.column_id
	AND ic.object_id = c.object_id
WHERE ic.object_id = si.object_id
	AND ic.index_id= si.index_id
	AND ic.is_included_column = 1
ORDER BY c.name
FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
, 1
, 2
, '')) AS includes(include_definition)
/* Partitions */
OUTER APPLY
	(	SELECT COUNT(*)	AS partition_count
		, CAST(SUM(ps.in_row_reserved_page_count) * 8./ 1024./ 1024.AS NUMERIC(32, 1)) AS reserved_in_row_GB
		, CAST(SUM(ps.lob_reserved_page_count) * 8./ 1024./ 1024.AS NUMERIC(32, 1)) AS reserved_LOB_GB
		, SUM(ps.row_count)	AS row_count
		FROM sys.partitions AS p
		JOIN sys.dm_db_partition_stats AS ps ON
			p.partition_id = ps.partition_id
		WHERE p.object_id = si.object_id
			AND p.index_id = si.index_id) AS partition_sums
/* row compression list by partition */
OUTER APPLY
		(SELECT STUFF((SELECT N', ' + CAST(p.partition_number AS VARCHAR(32))	
		FROM sys.partitions AS p
		WHERE p.object_id = si.object_id
		AND p.index_id = si.index_id
		AND p.data_compression = 1
		ORDER BY p.partition_number
		FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
		, 1
		, 2
		, '')) AS row_compression_clause(row_compression_partition_list)
/* data compression list by partition */
OUTER APPLY
		(SELECT STUFF(( SELECT N', ' + CAST(p.partition_number AS VARCHAR(32))
		FROM sys.partitions AS p
		WHERE p.object_id = si.object_id
		AND p.index_id = si.index_id
		AND p.data_compression = 2
		ORDER BY p.partition_number
		FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
		, 1
		, 2
		, '')) AS page_compression_clause(page_compression_partition_list)
		WHERE si.type IN ( 1, 2, 5 ); /* clustered, nonclustered, clustered columnstore */

GO		

		
		

		
		

		

		

		
