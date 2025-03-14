create TABLE myTable(FileName nvarchar(60), 
  FileType nvarchar(60), Document varchar(max));
GO

INSERT INTO myTable(FileName, FileType, Document) 
   SELECT 'Text1.txt' AS FileName, 
      '.txt' AS FileType, 
      * FROM OPENROWSET(BULK N'\\nykdwm1009181\tst\Text1.txt', SINGLE_CLOB) AS Document;
GO

select * from myTable
