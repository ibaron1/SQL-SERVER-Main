WITH CTE_year 
AS
(
    SELECT YEAR(orderdate) AS orderyear, CustomerID
    FROM Sales.Orders
)
--  get unique count
SELECT orderyear, COUNT(DISTINCT CustomerID) AS cust_count, count(CustomerID) as cust_across_orders_count
FROM CTE_year
GROUP BY orderyear;

