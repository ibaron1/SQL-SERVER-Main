use WideWorldImporters
go
drop view if exists Sales.CustOrders
go
CREATE VIEW Sales.CustOrders
AS
SELECT
  O.CustomerID, 
  DATEADD(month, DATEDIFF(month, 0, O.orderdate), 0) AS ordermonth,
  SUM(OD.Quantity) AS qty
FROM Sales.Orders AS O
  JOIN Sales.OrderLines AS OD
    ON OD.orderid = O.orderid
GROUP BY CustomerID, DATEADD(month, DATEDIFF(month, 0, O.orderdate), 0);
go
select * from Sales.CustOrders