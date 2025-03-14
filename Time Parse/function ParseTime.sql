CREATE OR ALTER FUNCTION [Utilities].[ParseTime] (@timeSec INT)
RETURNS VARCHAR(20)
AS
BEGIN
	RETURN CONCAT(ISNULL(CAST(NULLIF(IIF(@timeSec/3600 > 0, @timeSec/3600, 0), 0) AS VARCHAR(6))+' hr ',''),
					ISNULL(CAST(NULLIF(IIF((@timeSec%3600)/60 > 0, (@timeSec%3600)/60, 0), 0) AS VARCHAR(2))+' min ',''),
					ISNULL(CAST(IIF(@timeSec%3600-((@timeSec%3600)/60)*60 > 0, @timeSec%3600-((@timeSec%3600)/60)*60, 0) AS VARCHAR(2))+' sec',''));
END;
GO