/*
https://learn.microsoft.com/en-us/sql/relational-databases/tables/temporal-tables?view=sql-server-ver16#how-do-i-query-temporal-data

Temporal queries*
FOR SYSTEM_TIME
ALL, AS OF, BETWEEN..AND, FROM ..TO, CONTAINED IN

Expression					Qualifying rows	
----------                              	---------------
AS OF date_time					ValidFrom <= date_time AND ValidTo > date_time

FROM start_date_time TO end_date_time		ValidFrom < end_date_time AND ValidTo > start_date_time

BETWEEN start_date_time AND end_date_time	ValidFrom <= end_date_time AND ValidTo > start_date_time

CONTAINED IN (start_date_time, end_date_time)	ValidFrom >= start_date_time AND ValidTo <= end_date_time

ALL						All rows  
						Returns the union of rows that belong to the current and the history table.

Note.
You can choose to hide the period columns.

To return a hidden column, you must explicitly refer to the hidden column in the query. Similarly INSERT and BULK INSERT statements continue as if these new period columns weren't present (and the column values are auto-populated).

--============================== Examples ================================--
https://learn.microsoft.com/en-us/sql/relational-databases/tables/querying-data-in-a-system-versioned-temporal-table?view=sql-server-ver16
*/

SELECT * FROM Employee
    FOR SYSTEM_TIME
        BETWEEN '2021-01-01 00:00:00.0000000' AND '2022-01-01 00:00:00.0000000'
            WHERE EmployeeID = 1000 ORDER BY ValidFrom;

-- State of entire table AS OF specific date in the past
SELECT [DeptID],
    [DeptName],
    [ValidFrom],
    [ValidTo]
FROM [dbo].[Department]
FOR SYSTEM_TIME AS OF '2021-09-01 T10:00:00.7230011';

DECLARE @ADayAgo DATETIME2;
SET @ADayAgo = DATEADD(DAY, -1, SYSUTCDATETIME());

-- Comparison between two points in time for subset of rows
SELECT D_1_Ago.[DeptID],
    D.[DeptID],
    D_1_Ago.[DeptName],
    D.[DeptName],
    D_1_Ago.[ValidFrom],
    D.[ValidFrom],
    D_1_Ago.[ValidTo],
    D.[ValidTo]
FROM HumanResources.[Department]
FOR SYSTEM_TIME AS OF @ADayAgo AS D_1_Ago
INNER JOIN HumanResources.[Department] AS D
    ON D_1_Ago.[DeptID] = [D].[DeptID]
        AND D_1_Ago.[DeptID] BETWEEN 1 AND 5;

Use views with AS OF subclause in temporal queries
---------------------------------------------------
Using views is useful in scenarios when complex point-in time analysis is required. 
A common example is generating a business report today with the values for previous month.

Query for changes to specific rows over time
--------------------------------------------
/* Query using BETWEEN...AND sub-clause*/
SELECT [DeptID],
    [DeptName],
    [ValidFrom],
    [ValidTo],
    IIF(YEAR(ValidTo) = 9999, 1, 0) AS IsActual
FROM [dbo].[Department]
FOR SYSTEM_TIME BETWEEN '2021-01-01' AND '2021-12-31'
WHERE DeptId = 1
ORDER BY ValidFrom DESC;

/* Query using CONTAINED IN sub-clause */
SELECT [DeptID],
    [DeptName],
    [ValidFrom],
    [ValidTo]
FROM [dbo].[Department]
FOR SYSTEM_TIME CONTAINED IN ('2021-04-01', '2021-09-25')
WHERE DeptId = 1
ORDER BY ValidFrom DESC;

/* Query using ALL sub-clause */
SELECT [DeptID],
    [DeptName],
    [ValidFrom],
    [ValidTo],
    IIF(YEAR(ValidTo) = 9999, 1, 0) AS IsActual
FROM [dbo].[Department]
FOR SYSTEM_TIME ALL
ORDER BY [DeptID],
    [ValidFrom] DESC;


