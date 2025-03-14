 insert core.ArchivingDataProcessing(DbName,Tbl,AppDataType,workflowId,ifArchiveOnboarded)
	 select DbName,Tbl,AppDataType,workflowId,case when RetentionDays is not null then 'Y' else 'N' end
	 from core.DataArchivingAndPurgingConfig
	 where DbName = 'TFM' and AppDataType = 'tfm'
	 and isnull(workflowId ,'') not in (select isnull(workflowId ,'') from core.ArchivingDataProcessing)