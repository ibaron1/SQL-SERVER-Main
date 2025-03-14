DISABLE TRIGGER dbo.tI_ChangeLog on dbo.ChangeLog

ENABLE TRIGGER dbo.tI_ChangeLog on dbo.ChangeLog


DISABLE TRIGGER dbo.tD_ChangeLog on dbo.ChangeLog

ENABLE TRIGGER dbo.tD_ChangeLog on dbo.ChangeLog


DISABLE TRIGGER backup_objects ON DATABASE;
DISABLE TRIGGER tD_ChangeLog ON dbo.ChangeLog;

ENABLE TRIGGER tD_ChangeLog ON dbo.ChangeLog;
ENABLE TRIGGER backup_objects ON DATABASE;