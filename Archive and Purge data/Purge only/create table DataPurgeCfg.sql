use OSM_4
go
if object_id('dbo.DataPurgeCfg') is not null
  drop table dbo.DataPurgeCfg
go
CREATE TABLE dbo.DataPurgeCfg(
	PartitionNumber int NOT NULL,
	Tbl varchar(128) NOT NULL,
	RetentionDays int NOT NULL,
	PurgeBatchSize int NOT NULL
) ON [PRIMARY]
GO
