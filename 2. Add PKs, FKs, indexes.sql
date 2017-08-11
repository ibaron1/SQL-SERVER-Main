
ALTER TABLE tfmarchive.Activity ADD PRIMARY KEY CLUSTERED (activityId asc) with (MAXDOP=0, SORT_IN_TEMPDB=ON) ON [PRIMARY];
GO
ALTER TABLE tfmarchive.Request ADD PRIMARY KEY CLUSTERED (transactionId asc) with (MAXDOP=0, SORT_IN_TEMPDB=ON) ON [PRIMARY];
GO
ALTER TABLE tfmarchive.RequestKeyAttributes ADD PRIMARY KEY CLUSTERED (keyName asc,keyValue asc,transactionId asc) with (MAXDOP=0, SORT_IN_TEMPDB=ON) ON [PRIMARY];
GO
ALTER TABLE tfmarchive.Step ADD PRIMARY KEY CLUSTERED (tranStepId asc) with (MAXDOP=0, SORT_IN_TEMPDB=ON) ON [PRIMARY];
GO


ALTER TABLE [tfmarchive].[Activity]  WITH  CHECK  ADD CONSTRAINT [FK_tranStepId2] FOREIGN KEY ([tranStepId]) REFERENCES [tfmarchive].[Step] ([tranStepId]) ON UPDATE  NO ACTION  ON DELETE  NO ACTION 
ALTER TABLE [tfmarchive].[RequestKeyAttributes]  WITH  CHECK  ADD CONSTRAINT [FK_transactionId_KeyAttr2] FOREIGN KEY ([transactionId]) REFERENCES [tfmarchive].[Request] ([transactionId]) ON UPDATE  NO ACTION  ON DELETE  NO ACTION 
ALTER TABLE [tfmarchive].[Step]  WITH  CHECK  ADD CONSTRAINT [FK_transactionId2] FOREIGN KEY ([transactionId]) REFERENCES [tfmarchive].[Request] ([transactionId]) ON UPDATE  NO ACTION  ON DELETE  NO ACTION 
ALTER TABLE [tfmarchive].[Payload]  WITH  CHECK  ADD CONSTRAINT [FK_Request_transactionId2] FOREIGN KEY ([transactionId]) REFERENCES [tfmarchive].[Request] ([transactionId]) ON UPDATE  NO ACTION  ON DELETE  NO ACTION 
ALTER TABLE [tfmarchive].[Payload]  WITH  CHECK  ADD CONSTRAINT [FK_Activity_activityId2] FOREIGN KEY ([activityId]) REFERENCES [tfmarchive].[Activity] ([activityId]) ON UPDATE  NO ACTION  ON DELETE  NO ACTION 

go


CREATE NONCLUSTERED INDEX [idx_Activity_tranStepId] ON [tfmarchive].[Activity](tranStepId ASC, timestamp ASC) INCLUDE (activityId)WITH (PAD_INDEX = OFF, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, SORT_IN_TEMPDB = OFF) ON [PRIMARY];
 
CREATE NONCLUSTERED INDEX [IX_Activity_timestamp] ON [tfmarchive].[Activity](timestamp ASC) INCLUDE (tranStepId)WITH (PAD_INDEX = OFF, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, SORT_IN_TEMPDB = OFF) ON [PRIMARY];
 
CREATE NONCLUSTERED INDEX [idx_correlationId] ON [tfmarchive].[Request](correlationId ASC) WITH (PAD_INDEX = OFF, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, SORT_IN_TEMPDB = OFF) ON [PRIMARY];
 
CREATE UNIQUE NONCLUSTERED INDEX [idx_transactionId] ON [tfmarchive].[Request](timestamp ASC, transactionId ASC) WITH (PAD_INDEX = OFF, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, SORT_IN_TEMPDB = OFF) ON [PRIMARY];
 
CREATE NONCLUSTERED INDEX [i_transactionId_RequestKeyAttributes] ON [tfmarchive].[RequestKeyAttributes](transactionId ASC) WITH (PAD_INDEX = OFF, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, SORT_IN_TEMPDB = OFF) ON [PRIMARY];
 
CREATE NONCLUSTERED INDEX [IX_Step_transactionId] ON [tfmarchive].[Step](transactionId ASC) INCLUDE (tranStepId)WITH (PAD_INDEX = OFF, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, SORT_IN_TEMPDB = OFF) ON [PRIMARY];
 
go