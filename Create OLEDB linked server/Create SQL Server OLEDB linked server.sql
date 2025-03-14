EXEC master.dbo.sp_addlinkedserver @server = N'LINK_CFEDB', @srvproduct=N'SQLServer', @provider=N'SQLNCLI10', @datasrc=N'PAERSCBBLD0367\ANNACCTPROD'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'LINK_CFEDB',@useself=N'False',@locallogin=NULL,@rmtuser=N'sa',@rmtpassword='########'
