USE [master]
GO

/****** Object:  Database [cfe_dc]    Script Date: 04/20/2012 17:25:40 ******/
CREATE DATABASE [cfe_dc] ON  PRIMARY 
( NAME = N'cfe_dc', FILENAME = N'K:\databases\MSSQL10_50.DCREPEXTPROD\MSSQL\DATA\cfe_dc.mdf' , SIZE = 10GB , MAXSIZE = UNLIMITED, FILEGROWTH = 10240KB )
 LOG ON 
( NAME = N'cfe_dc_log', FILENAME = N'J:\databases\MSSQL10_50.DCREPEXTPROD\MSSQL\DATA\cfe_dc_log.ldf' , SIZE = 20MB , MAXSIZE = 2048GB , FILEGROWTH = 10240KB )
GO

ALTER DATABASE [cfe_dc] SET COMPATIBILITY_LEVEL = 100
GO

ALTER DATABASE [cfe_dc] SET RECOVERY SIMPLE 
GO