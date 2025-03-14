USE [FALCON_SRF_Cache]
GO

/****** Object:  Schema [srf_cache]    Script Date: 05/08/2013 16:32:30 ******/
CREATE SCHEMA [srf_cache] AUTHORIZATION [dbo]
GO

CREATE USER [srfcache] FOR LOGIN [srfcache] WITH DEFAULT_SCHEMA=[srf_cache]
GO


-- if user exists
alter USER [srfcache] WITH DEFAULT_SCHEMA=[srf_cache]
GO

