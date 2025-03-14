sp_configure 'Ad Hoc Distributed Queries', 1;
GO
RECONFIGURE;
GO

create table XLImport4
(BookCode varchar(200),	Region varchar(200),	BusinessArea varchar(200))
go

SELECT * INTO XLImport4 FROM OPENROWSET('Microsoft.Jet.OLEDB.4.0',
'Excel 8.0;Database=\\nykdwm1009181\tst\Book_Mapping_to_Region_Business.xlsx', [Book List$])
--or 
SELECT * INTO XLImport4 FROM OPENDATASOURCE('Microsoft.Jet.OLEDB.4.0',
'Data Source=\\nykdwm1009181\tst\Book_Mapping_to_Region_Business.xlsx;Extended Properties=Excel 8.0')...[Customers$]

go