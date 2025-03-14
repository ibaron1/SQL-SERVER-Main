use TFM_Archive
go

delete from core.DataArchivingAndPurgingConfig
where Tbl in ('LoadError','LoadErrorHistory','LoggerError','LoggerErrorHistory','FileLoad','FileLoadHistory',
'FileTransformation','FileTransformationHistory','TransformationError','TransformationErrorHistory')

INSERT INTO [core].[DataArchivingAndPurgingConfig]
           ([DbName]
           ,[DbArchivingName]
           ,[AppDataType]
           ,[workflowId]
           ,[Tbl]
           ,[RetentionDays]
           ,[RetentionDaysForArchiving]
           ,[ArchivingBatchSize])
VALUES
('TFM','TFM_Archive','tfm',null,'LoadError',7,28,100000)
,('TFM','TFM_Archive','tfm',null,'LoadErrorHistory',7,28,100000)
,('TFM','TFM_Archive','tfm',null,'LoggerError',7,28,100000)
,('TFM','TFM_Archive','tfm',null,'LoggerErrorHistory',7,28,100000)
,('TFM','TFM_Archive','tfm',null,'FileLoad',7,28,100000)
,('TFM','TFM_Archive','tfm',null,'FileLoadHistory',7,28,100000)
,('TFM','TFM_Archive','tfm',null,'FileTransformation',7,28,100000)
,('TFM','TFM_Archive','tfm',null,'FileTransformationHistory',7,28,100000)
,('TFM','TFM_Archive','tfm',null,'TransformationError',7,28,100000)
,('TFM','TFM_Archive','tfm',null,'TransformationErrorHistory',7,28,100000)
go