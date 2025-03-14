--Create the dbo.ServerLogonHistory Table

CREATE TABLE dbo.ServerLogonHistory

    (

                EventType   VARCHAR(512),

                PostTime    DATETIME,

                SPID        INT,

                ServerName  VARCHAR(512),

                LoginName   VARCHAR(512),

                LoginType   VARCHAR(512),

                SID         VARCHAR(512),

                ClientHost  VARCHAR(512),

                IsPooled    BIT

    )

GO



    --Grant insert rights to public for this table

GRANT INSERT ON dbo.ServerLogonHistory TO PUBLIC



    --Create the Logon Trigger Trigger_ServerLogon

CREATE TRIGGER Trigger_ServerLogon

            ON ALL SERVER FOR LOGON

            AS

    BEGIN

    DECLARE @data XML

        SET @data = EVENTDATA()

    INSERT INTO dbo.ServerLogonHistory

        SELECT @data.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(512)')

                , @data.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime')

                , @data.value('(/EVENT_INSTANCE/SPID)[1]', 'nvarchar(4)')

                , @data.value('(/EVENT_INSTANCE/ServerName)[1]', 'nvarchar(512)')

                , @data.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(512)')

                , @data.value('(/EVENT_INSTANCE/LoginType)[1]', 'nvarchar(512)')

                , @data.value('(/EVENT_INSTANCE/SID)[1]', 'nvarchar(512)')

                , @data.value('(/EVENT_INSTANCE/ClientHost)[1]', 'nvarchar(512)')

                , @data.value('(/EVENT_INSTANCE/IsPooled)[1]', 'nvarchar(1)')

    END

GO
