USE [ServiceMac]
GO

/****** Object:  UserDefinedFunction [Utilities].[SuperTrim]    Script Date: 11/11/2024 10:30:00 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [Utilities].[SuperTrim] (@InputString VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
	RETURN TRIM(CHAR(10) + CHAR(13) + CHAR(9) + ' ' + '_' FROM @InputString) 
END

GO

