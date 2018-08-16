use TFM_Archive;

drop table [tfm].[Request];

CREATE TABLE [tfm].[Request]
(
	  [transactionId] BIGINT NOT NULL
	, [workflowId] INT NOT NULL
	, [correlationId] VARCHAR(40) NOT NULL
	, [ExtRefId] VARCHAR(40) NOT NULL
	, [hostAddress] VARCHAR(40) NULL
	, [hostName] VARCHAR(40) NULL
	, [currentSystem] VARCHAR(20) NULL
	, [outcome] VARCHAR(10) NULL
	, [timestamp] DATETIME NULL
	, [duration_ms] INT NOT NULL
	, [loadId] INT NOT NULL
)

CREATE NONCLUSTERED INDEX [idx_correlationId] ON [tfm].[Request] ([correlationId] ASC)

CREATE UNIQUE NONCLUSTERED INDEX [idx_transactionId] ON [tfm].[Request] ([timestamp] ASC, [transactionId] ASC)