use TFM
go

set identity_insert tfm.workflow on

insert [tfm].[Workflow]
([workflowId]
      ,[product]
      ,[channel]
      ,[touchpoint]
      ,[operation]
      ,[mode]
      ,[version])
SELECT [workflowId]
      ,[product]
      ,[channel]
      ,[touchpoint]
      ,[operation]
      ,[mode]
      ,[version]
  FROM dbo.[Workflow]

set identity_insert tfm.workflow off

go

set identity_insert tfm.FileLoad on

insert [tfm].FileLoad
([loadId]
      ,[Name]
      ,[URL]
      ,[lastModified]
      ,[replay]
      ,[loadStatus]
      ,[loadStarted]
      ,[loadEnded]
      ,[processedRecordCount]
      ,[targetRecordCount])
SELECT [loadId]
      ,[Name]
      ,[URL]
      ,[lastModified]
      ,[replay]
      ,[loadStatus]
      ,[loadStarted]
      ,[loadEnded]
      ,[processedRecordCount]
      ,[targetRecordCount]
  FROM dbo.FileLoad1 as f

set identity_insert tfm.FileLoad off

go

set identity_insert tfm.Request on

insert [tfm].Request
([transactionId]
      ,[workflowId]
      ,[correlationId]
      ,[ExtRefId]
      ,[hostAddress]
      ,[hostName]
      ,[currentSystem]
      ,[outcome]
      ,[timestamp]
      ,[duration_ms]
      ,[loadId])
SELECT [transactionId]
      ,[workflowId]
      ,[correlationId]
      ,[ExtRefId]
      ,[hostAddress]
      ,[hostName]
      ,[currentSystem]
      ,[outcome]
      ,[timestamp]
      ,[duration_ms]
      ,[loadId]
  FROM dbo.Request

set identity_insert tfm.Request off

go

insert [tfm].[RequestKeyAttributes]
([keyName]
      ,[keyValue]
      ,[transactionId]
)
select [keyName]
      ,[keyValue]
      ,[transactionId]
	from dbo.[RequestKeyAttributes]
go

set identity_insert tfm.[Step] on

insert [tfm].[Step]
([tranStepId]
      ,[transactionId]
      ,[stepId]
      ,[timestamp]
      ,[duration_ms])
SELECT [tranStepId]
      ,[transactionId]
      ,[stepId]
      ,[timestamp]
      ,[duration_ms]
  FROM dbo.[Step]

set identity_insert tfm.[Step] off

go

set identity_insert tfm.[Activity] on

select * into #Activity
from Activity where 1=2

while exists (select '1' from dbo.Activity)
begin
	delete top (100000) from dbo.Activity
	output deleted.* into #Activity

	insert [tfm].[Activity]
	([activityId]
		  ,[tranStepId]
		  ,[activityName]
		  ,[outcome]
		  ,[tfmSourceApp]
		  ,[tfmDestinationApp]
		  ,[timestamp]
		  ,[duration_ms])
	SELECT [activityId]
		  ,[tranStepId]
		  ,[activityName]
		  ,[outcome]
		  ,[tfmSourceApp]
		  ,[tfmDestinationApp]
		  ,[timestamp]
		  ,[duration_ms]
	  FROM #Activity

	truncate table #Activity
end

set identity_insert tfm.[Activity] off

go

select * into #Payload
from Payload where 1=2

while exists (select '1' from dbo.Payload)
begin
	delete top (100000) from dbo.[Payload]
	output deleted.* into #Payload

	insert [tfm].[Payload]
	([activityId]
			,[payload]
			,[formatType]
			,[eventType])
	SELECT [activityId]
			,[payload]
			,[formatType]
			,[eventType]
	FROM #Payload

	truncate table #Payload
end
