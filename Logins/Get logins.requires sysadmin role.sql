-- if your login has sysadmin role
  CREATE TABLE #tempww (
    LoginName nvarchar(max),
    DBname nvarchar(max),
    Username nvarchar(max), 
    AliasName nvarchar(max)
)

INSERT INTO #tempww 
EXEC master..sp_msloginmappings 


SELECT * 
FROM   #tempww 
ORDER BY dbname, username

DROP TABLE #tempww 