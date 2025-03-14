USE [ControlTower]
GO

/****** Object:  View [Metadata].[ColumnstoreRowGroups]    Script Date: 10/11/2024 9:36:42 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW [Metadata].[ColumnstoreRowGroups]
AS
SELECT  OBJECT_SCHEMA_NAME(CSRG.object_id) AS TableSchema
      , OBJECT_NAME(CSRG.object_id)        AS TableName
      , CSRG.object_id AS ObjectId
      , CSRG.index_id AS IndexId
      , CSRG.partition_number AS PartitionNumber
      , CSRG.row_group_id AS RowGroupId
      , CSRG.delta_store_hobt_id AS DeltaStoreHobtId
      , CSRG.state AS [State]
      , CSRG.state_description AS [StateDescription]
      , CSRG.total_rows AS [TotalRows]
      , CSRG.deleted_rows AS [DeletedRows]
      , CSRG.size_in_bytes AS [SizeInBytes]
FROM    sys.column_store_row_groups AS CSRG WITH (NOLOCK);
GO


