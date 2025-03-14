create table dbo.abc (a int)

insert abc
values(2)
go 100 --executes 100 times

declare @tblName varchar(200) = 'abc'
exec ('truncate table '+@tblName)

https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-executesql-transact-sql?view=sql-server-ver16

DECLARE @sqlCommand nvarchar(1000)
DECLARE @columnList varchar(75)
DECLARE @city varchar(75)
SET @columnList = 'CustomerID, ContactName, City'
SET @city = 'London'
SET @sqlCommand = 'SELECT ' + @columnList + ' FROM customers WHERE City = @city'
EXECUTE sp_executesql @sqlCommand, N'@city nvarchar(75)', @city = @city


Dynamic SQL is useful for several purposes, including the following ones:

Automating administrative tasks For example, querying metadata and constructing and executing a BACKUP DATABASE statement for each database in the instance Improving performance of certain tasks For example, constructing parameterized ad-hoc queries that can reuse previously cached execution plans (more on this later) Constructing elements of the code based on querying the actual data For example, constructing a PIVOT query dynamically when you don’t know ahead of time which elements should appear in the IN clause of the PIVOT operator

DECLARE @sql AS NVARCHAR(100);

SET @sql = N'SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderid = @orderid;';

EXEC sp_executesql
@stmt = @sql,
  @params = N'@orderid AS INT',
  @orderid = 10248; This code generates the following output: 

orderid     custid      empid       orderdate
----------- ----------- ----------- -----------
10248       85          5           2020-07-04


Using PIVOT with Dynamic SQL

DECLARE @sql AS NVARCHAR(1000) = N'SELECT *
FROM (SELECT shipperid, YEAR(orderdate) AS orderyear, freight
      FROM Sales.Orders) AS D
  PIVOT(SUM(freight) FOR orderyear IN('
+ (SELECT STRING_AGG(QUOTENAME(orderyear), N',') WITHIN GROUP(ORDER BY orderyear)
     FROM (SELECT DISTINCT(YEAR(orderdate)) AS orderyear FROM Sales.Orders) AS D)

  + N')) AS P;';

EXEC sys.sp_executesql @stmt = @sql;

Ben-Gan, Itzik. T-SQL Fundamentals (Developer Reference) (p. 513). Pearson Education. Kindle Edition. 


