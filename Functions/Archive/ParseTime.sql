DROP FUNCTION IF EXISTS Utilities.ParseTime
GO
CREATE FUNCTION Utilities.ParseTime (@timeSec VARCHAR(20))
RETURNS VARCHAR(20)
AS
BEGIN
	RETURN CONCAT(CONVERT(VARCHAR(6), IIF(@timeSec/3600 > 0, @timeSec/3600, 0)),' hr ',
						 CONVERT(VARCHAR(2), IIF((@timeSec%3600)/60 > 0, (@timeSec%3600)/60,  0)),' min ',
						 CONVERT(varchar(2), IIF(@timeSec%3600-((@timeSec%3600)/60)*60 > 0, @timeSec%3600-((@timeSec%3600)/60)*60, 0)),' sec')
END

GO

SELECT Utilities.ParseTime(10000)