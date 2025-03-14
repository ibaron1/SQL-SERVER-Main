CREATE UNIQUE CLUSTERED INDEX [idx_activityId] ON [tfm].[Activity](activityId ASC) ;
 
CREATE NONCLUSTERED INDEX [idx_Activity_tfm] ON [tfm].[Activity](tranStepId ASC) ;
 
CREATE CLUSTERED INDEX [idx_FileLoad_lastModified] ON [tfm].[FileLoad](lastModified ASC) ;
 
CREATE CLUSTERED INDEX [idx_FileLoad_lastModified] ON [tfm].[FileLoadHistory](lastModified ASC) ;
 
CREATE NONCLUSTERED INDEX [PK_FileLoad] ON [tfm].[FileLoadHistory](loadId ASC) ;
 
CREATE UNIQUE CLUSTERED INDEX [PK_FileTransformation] ON [tfm].[FileTransformation](TransformationId ASC) ;
 
CREATE NONCLUSTERED INDEX [idx_FileTransformation_lastModified] ON [tfm].[FileTransformation](lastModified ASC) ;
 
CREATE NONCLUSTERED INDEX [idx_FileTransformationHistory] ON [tfm].[FileTransformationHistory](TransformationId ASC, replay ASC) ;
 
CREATE NONCLUSTERED INDEX [idx_LoadError] ON [tfm].[LoadError](loadId ASC) ;
 
CREATE NONCLUSTERED INDEX [idx_LoadErrorHistory] ON [tfm].[LoadErrorHistory](loadId ASC) ;
 
CREATE NONCLUSTERED INDEX [idx_LoggerError] ON [tfm].[LoggerError](loadId ASC) ;
 
CREATE NONCLUSTERED INDEX [idx_LoggerErrorHistory] ON [tfm].[LoggerErrorHistory](loadId ASC) ;
 
CREATE UNIQUE NONCLUSTERED INDEX [idx_Payload_Activity_tfm] ON [tfm].[Payload](activityId ASC) ;
 
CREATE UNIQUE CLUSTERED INDEX [PK_transactionId] ON [tfm].[Request](transactionId ASC) ;
 
CREATE NONCLUSTERED INDEX [idx_workflowId] ON [tfm].[Request](workflowId ASC, correlationId ASC) ;
 
CREATE UNIQUE CLUSTERED INDEX [PK_transactionId_KeyAttr] ON [tfm].[RequestKeyAttributes](keyName ASC, keyValue ASC, transactionId ASC) ;
 
CREATE NONCLUSTERED INDEX [idx_RequestKeyAttributes_tfm] ON [tfm].[RequestKeyAttributes](transactionId ASC) ;
 
CREATE UNIQUE CLUSTERED INDEX [PK_tranStepId] ON [tfm].[Step](tranStepId ASC) ;
 
CREATE NONCLUSTERED INDEX [IX_Step_transactionId] ON [tfm].[Step1](transactionId ASC) INCLUDE (tranStepId);
 
CREATE NONCLUSTERED INDEX [idx_TransformationError] ON [tfm].[TransformationError](TransformationId ASC) ;
 
CREATE NONCLUSTERED INDEX [idx_TransformationError] ON [tfm].[TransformationErrorHistory](TransformationId ASC) ;
 
