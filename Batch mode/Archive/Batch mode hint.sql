SELECT 
    ProductID, 
    SUM(SalesAmount) AS TotalSales
FROM 
    Sales
GROUP BY 
    ProductID
OPTION (USE HINT ('ENABLE_BATCH_MODE'));