DISABLE TRIGGER backup_objects ON DATABASE;
DISABLE TRIGGER tD_ChangeLog ON dbo.ChangeLog;


SELECT LoginName,* FROM [dbo].[ChangeLog]
WHERE CAST(EventDate AS DATE) = CAST(GETDATE() AS DATE)
AND LoginName LIKE 'eli%'

DELETE FROM [dbo].[ChangeLog]
WHERE CAST(EventDate AS DATE) = CAST(GETDATE() AS DATE)
AND LoginName LIKE 'eli%'

DELETE FROM [dbo].ChangeLogBackup
WHERE CAST(EventDate AS DATE) = CAST(GETDATE() AS DATE)
AND LoginName LIKE 'eli%'

SELECT * FROM  [dbo].[ChangeLogTampering]
--TRUNCATE TABLE [dbo].[ChangeLogTampering]




ENABLE TRIGGER tD_ChangeLog ON dbo.ChangeLog;
ENABLE TRIGGER backup_objects ON DATABASE;