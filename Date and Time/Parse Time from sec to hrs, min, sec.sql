

DECLARE @a INT = 6515

SELECT 
CONCAT(CONVERT(varchar(6), IIF(@a/3600 > 0, @a/3600, 0)),' hr ',
	   CONVERT(varchar(2), IIF((@a%3600)/60 > 0, (@a%3600)/60,  0)),' min ',
	   CONVERT(varchar(2), IIF(@a%3600-((@a%3600)/60)*60 > 0, @a%3600-((@a%3600)/60)*60, 0)),' sec')

SELECT 
CONCAT(CONVERT(varchar(6), case when @a/3600 > 0 then @a/3600 else 0 end)+' hr ',
CONVERT(varchar(2), case when (@a%3600)/60 > 0 then (@a%3600)/60 else 0 end)+' min ',
CONVERT(varchar(2), case when @a%3600-((@a%3600)/60)*60 > 0 then @a%3600-((@a%3600)/60)*60 else 0 end)+' sec')