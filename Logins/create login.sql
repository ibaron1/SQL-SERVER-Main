USE [FALCON_SRF_Rates]
GO

CREATE LOGIN [sysWINMIS] WITH PASSWORD='DF77d@qe', DEFAULT_DATABASE=[FALCON_SRF_Rates], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

ALTER LOGIN [sysWINMIS] DISABLE
GO


CREATE USER [sysWINMIS] FOR LOGIN [sysWINMIS] WITH DEFAULT_SCHEMA=[srf_main]
GO
