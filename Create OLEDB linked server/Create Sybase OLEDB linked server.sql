EXEC master.dbo.sp_addlinkedserver @server = N'TESTME', @srvproduct=N'Sybase', @provider=N'ASEOLEDB', @datasrc=N'BASELINE11', @provstr=N'BASELINE11'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'TESTME',@useself=N'False',@locallogin=NULL,@rmtuser=N'x171524',@rmtpassword='########'

GO