create table dbo.ChangeLog(
	[LogId] [int] IDENTITY(1,1) NOT NULL,
	[InstanceName] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DatabaseName] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ObjectType] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ObjectName] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Version] int NOT NULL DEFAULT (0),
	[EventType] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SqlCommand] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EventDate] [datetime] NOT NULL CONSTRAINT [DF_EventsLog_EventDate]  DEFAULT (getdate()),
	[LoginName] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]

GO

create clustered index i on dbo.ChangeLog([ObjectName], [Version])

create trigger dbo.tI_ChangeLog
on dbo.ChangeLog
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

GO



create trigger backup_objects
on database
for create_procedure, alter_procedure, drop_procedure,
create_table, alter_table, drop_table,
create_function, alter_function, drop_function
,CREATE_VIEW,ALTER_VIEW,DROP_VIEW,CREATE_TRIGGER,ALTER_TRIGGER,DROP_TRIGGER
,CREATE_INDEX,ALTER_INDEX,DROP_INDEX,CREATE_SYNONYM,DROP_SYNONYM
,CREATE_TYPE,DROP_TYPE,CREATE_SCHEMA,ALTER_SCHEMA,DROP_SCHEMA
,BIND_DEFAULT,BIND_RULE,CREATE_DEFAULT,DROP_DEFAULT,CREATE_RULE,DROP_RULE
as

set nocount on

declare @data xml
set @data = EVENTDATA()

insert into ChangeLog([InstanceName],[DatabaseName],[ObjectType],[ObjectName],[EventType],[SqlCommand],[LoginName])

values(
@data.value('(/EVENT_INSTANCE/ServerName)[1]', 'varchar(256)'),
@data.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'varchar(256)'),
@data.value('(/EVENT_INSTANCE/ObjectType)[1]', 'varchar(25)'),
@data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'varchar(256)'), 
@data.value('(/EVENT_INSTANCE/EventType)[1]', 'varchar(50)'), 
@data.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'varchar(max)'), 
@data.value('(/EVENT_INSTANCE/LoginName)[1]', 'varchar(256)')
)

GO

