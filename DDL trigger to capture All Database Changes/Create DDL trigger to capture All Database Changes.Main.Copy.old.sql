if object_id('[dbo].[ChangeLog]') is not null
  drop table [dbo].[ChangeLog]
go

CREATE TABLE [dbo].[ChangeLog](
	[LogId] [int] IDENTITY(1,1) NOT NULL,
	[InstanceName] [varchar](256) NOT NULL,
	[DatabaseName] [varchar](256) NOT NULL,
	[ObjectType] [varchar](25) NOT NULL,
	[ObjectName] [varchar](256) NOT NULL,
	[Version] [int] NOT NULL default 0,
	[EventType] [varchar](50) NOT NULL,
	[SqlCommand] [varchar](max) NOT NULL,
	[EventDate] [datetime] NOT NULL default getdate(),
	[LoginName] [varchar](256) NOT NULL,
	[HostName] [varchar](256) NULL,
	[IPAddress] [char](32) NULL,
	[ProgramName] [char](256) NULL
)

create clustered index i on dbo.ChangeLog([ObjectName], [Version])
go

if object_id('FALCON_SRF_CrossAsset_EMIR.[dbo].[ChangeLogBackup]') is not null
  drop table FALCON_SRF_CrossAsset_EMIR.[dbo].[ChangeLogBackup]
go
CREATE TABLE FALCON_SRF_CrossAsset_EMIR.[dbo].[ChangeLogBackup](
	[LogId] [int] NOT NULL,
	[InstanceName] [varchar](256) NOT NULL,
	[DatabaseName] [varchar](256) NOT NULL,
	[ObjectType] [varchar](25) NOT NULL,
	[ObjectName] [varchar](256) NOT NULL,
	[Version] [int] NOT NULL default 0,
	[EventType] [varchar](50) NOT NULL,
	[SqlCommand] [varchar](max) NOT NULL,
	[EventDate] [datetime] NOT NULL default getdate(),
	[LoginName] [varchar](256) NOT NULL,
	[HostName] [varchar](256) NULL,
	[IPAddress] [char](32) NULL,
	[ProgramName] [char](256) NULL
)

create clustered index i on FALCON_SRF_CrossAsset_EMIR.dbo.[ChangeLogBackup]([ObjectName], [Version])
go

if object_id('FALCON_SRF_CrossAsset_EMIR.[dbo].[ChangeLogTampering]') is not null
  drop table FALCON_SRF_CrossAsset_EMIR.[dbo].[ChangeLogTampering]
go
CREATE TABLE FALCON_SRF_CrossAsset_EMIR.[dbo].[ChangeLogTampering](
	AttemptToModifyFromLogin varchar(256),
	AttemptToModifyFromHostName varchar(256),
	TypeOfModification varchar(6),
	OriginalOrAttemptedToModify varchar(8),
	[LogId] [int] NOT NULL,
	[InstanceName] [varchar](256) NOT NULL,
	[DatabaseName] [varchar](256) NOT NULL,
	[ObjectType] [varchar](25) NOT NULL,
	[ObjectName] [varchar](256) NOT NULL,
	[Version] [int] NOT NULL default 0,
	[EventType] [varchar](50) NOT NULL,
	[SqlCommand] [varchar](max) NOT NULL,
	[EventDate] [datetime] NOT NULL default getdate(),
	[LoginName] [varchar](256) NOT NULL,
	[HostName] [varchar](256) NULL,
	[IPAddress] [char](32) NULL,
	[ProgramName] [char](256) NULL
)

create clustered index i on FALCON_SRF_CrossAsset_EMIR.dbo.[ChangeLogTampering]([ObjectName], [Version])
GO

-- =============================================================
-- Author: Eli Baron
-- Create date: 2014-10-23
-- Description: To assign next version to new/modified db object
-- =============================================================
create trigger dbo.tI_ChangeLog
on dbo.ChangeLog
with encryption 
after insert
as
declare @ObjectName varchar(256), @maxVersion int, @maxLogId int

select @ObjectName =  [ObjectName] from inserted

select @maxVersion = max([Version]), @maxLogId = max([LogId])
from dbo.ChangeLog
where [ObjectName] = @ObjectName

update dbo.ChangeLog
set [Version] = @maxVersion + 1
where [ObjectName] = @ObjectName
and [LogId] = @maxLogId

insert FALCON_SRF_CrossAsset_EMIR.[dbo].[ChangeLogBackup]
select * from dbo.ChangeLog
where [ObjectName] = @ObjectName
and [LogId] = @maxLogId

GO
/*
-- =========================================================================
-- Author: Eli Baron
-- Create date: 2014-10-23
-- Description: To audit tampering insert attempt of data in ChangeLog table
-- =========================================================================
create trigger dbo.tI1_ChangeLog
on dbo.ChangeLog
with encryption 
instead of insert
as
-- what was attempted to be updated
insert FALCON_SRF_CrossAsset_EMIR.[dbo].[ChangeLogTampering]
select suser_name(), host_name(), 'Insert', 'New', * 
from inserted

go
*/

-- =========================================================================
-- Author: Eli Baron
-- Create date: 2014-10-23
-- Description: To audit tampering update attempt of data in ChangeLog table
-- =========================================================================
create trigger dbo.tU_ChangeLog
on dbo.ChangeLog
with encryption 
instead of update
as
-- what was attempted to be updated
insert FALCON_SRF_CrossAsset_EMIR.[dbo].[ChangeLogTampering]
select suser_name(), host_name(), 'Update', 'Original', * 
from deleted

insert FALCON_SRF_CrossAsset_EMIR.[dbo].[ChangeLogTampering]
select suser_name(), host_name(), 'Update', 'Modify', * 
from inserted
go

-- =========================================================================
-- Author: Eli Baron
-- Create date: 2014-10-23
-- Description: To audit tampering delete attempt of data in ChangeLog table
-- =========================================================================
create trigger dbo.tD_ChangeLog
on dbo.ChangeLog
with encryption 
instead of delete
as
-- what was attempted to be updated
insert FALCON_SRF_CrossAsset_EMIR.[dbo].[ChangeLogTampering]
select suser_name(), host_name(), 'Delete', 'Original', * 
from deleted

go


--drop trigger backup_objects on database
go

-- ======================================================================
-- Author: Eli Baron
-- Create date: 2014-10-23
-- Description: To store new/modified db object with relevant information
-- ======================================================================
create trigger backup_objects
on database
with encryption 
for create_procedure, alter_procedure, drop_procedure,
create_table, alter_table, drop_table,
create_function, alter_function, drop_function
,CREATE_VIEW,ALTER_VIEW,DROP_VIEW,CREATE_TRIGGER,ALTER_TRIGGER,DROP_TRIGGER
,CREATE_INDEX,ALTER_INDEX,DROP_INDEX,CREATE_SYNONYM,DROP_SYNONYM
,CREATE_TYPE,DROP_TYPE,CREATE_SCHEMA,ALTER_SCHEMA,DROP_SCHEMA
,BIND_DEFAULT,BIND_RULE,CREATE_DEFAULT,DROP_DEFAULT,CREATE_RULE,DROP_RULE
as

set nocount on

declare @data xml = EVENTDATA()
declare @SchemaName NVARCHAR(255) 
    = @data.value('(/EVENT_INSTANCE/SchemaName)[1]',  'NVARCHAR(255)'),
@ObjectName NVARCHAR(255) 
    = @data.value('(/EVENT_INSTANCE/ObjectName)[1]',  'NVARCHAR(255)');
    
DECLARE 
    @ip VARCHAR(32) =
    (
        SELECT client_net_address
            FROM sys.dm_exec_connections
            WHERE session_id = @@SPID
    );

insert into ChangeLog([InstanceName],[DatabaseName],[ObjectType],[ObjectName],[EventType],[SqlCommand],[LoginName],[HostName], IPAddress, ProgramName)
values(
@data.value('(/EVENT_INSTANCE/ServerName)[1]', 'varchar(256)'),
@data.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'varchar(256)'),
@data.value('(/EVENT_INSTANCE/ObjectType)[1]', 'varchar(25)'),
@SchemaName+'.'+@ObjectName, 
@data.value('(/EVENT_INSTANCE/EventType)[1]', 'varchar(50)'), 
@data.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'varchar(max)'), 
@data.value('(/EVENT_INSTANCE/LoginName)[1]', 'varchar(256)'), 
HOST_NAME(),
@ip,
PROGRAM_NAME())

GO