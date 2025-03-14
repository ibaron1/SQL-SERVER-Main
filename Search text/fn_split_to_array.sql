USE [capax]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_split_to_array]    Script Date: 09/20/2011 15:39:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER      FUNCTION [dbo].[fn_split_to_array]
(@input AS varchar(max), @delimiter varchar(10))
RETURNS @split_string table
( line int,outstr varchar(max) NULL)
AS
BEGIN
  DECLARE @n_of_delimiters int, @i int,@lineno int
  SET @n_of_delimiters=DATALENGTH(REPLACE(@input,@delimiter,@delimiter+'_')) - DATALENGTH(@input)
  Select @i = 0,@lineno=0
  WHILE @i < @n_of_delimiters
  BEGIN
    SElect @i = @i + 1,@lineno=@lineno+1
    INSERT INTO @split_string
      SELECT @lineno,LEFT(@input,CHARINDEX(@delimiter,@input)-1)
    SET @input=SUBSTRING(@input,CHARINDEX(@delimiter,@input)+1,20088000)
  END
  INSERT INTO @split_string VALUES(@lineno+1,@input)
  RETURN
END
