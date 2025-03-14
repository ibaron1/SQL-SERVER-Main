Let’s go through our demo to understand practically how to implement the SQL Server Partitioned View and its benefits. We will start with creating four new tables under SQLShackDemo database with identical schema and each table keeps the shipments information for a specific quarter of the year. The partitioning column is the Ship_Quarter column in which the constraint that specifies the four quarters is defined. The Ship_Quarter column is also included in the Primary Key constraint. The T-SQL script to create the four quarters tables will be like:

 
USE SQLShackDemo 
GO
CREATE TABLE Shipments_Q1 (
Ship_Num INT NOT NULL,
Ship_CountryCode CHAR(3) NOT NULL,
Ship_Date DATETIME NULL,
Ship_Quarter SMALLINT NOT NULL CONSTRAINT CK_Ship_Q1 CHECK (Ship_Quarter = 1),
CONSTRAINT PK_Shipments_Q1 PRIMARY KEY (Ship_Num, Ship_Quarter)
);
 
GO
CREATE TABLE Shipments_Q2 (
Ship_Num INT NOT NULL,
Ship_CountryCode CHAR(3) NOT NULL,
Ship_Date DATETIME NULL,
Ship_Quarter SMALLINT NOT NULL CONSTRAINT CK_Ship_Q2 CHECK (Ship_Quarter = 2),
CONSTRAINT PK_Shipments_Q2 PRIMARY KEY (Ship_Num, Ship_Quarter)
);

GO
CREATE TABLE Shipments_Q3 (
Ship_Num INT NOT NULL,
Ship_CountryCode CHAR(3) NOT NULL,
Ship_Date DATETIME NULL,
Ship_Quarter SMALLINT NOT NULL CONSTRAINT CK_Ship_Q3 CHECK (Ship_Quarter = 3),
CONSTRAINT PK_Shipments_Q3 PRIMARY KEY (Ship_Num, Ship_Quarter)
);
 
GO
CREATE TABLE Shipments_Q4 (
Ship_Num INT NOT NULL,
Ship_CountryCode CHAR(3) NOT NULL,
Ship_Date DATETIME NULL,
Ship_Quarter SMALLINT NOT NULL CONSTRAINT CK_Ship_Q4 CHECK (Ship_Quarter = 4),
CONSTRAINT PK_Shipments_Q4 PRIMARY KEY (Ship_Num, Ship_Quarter)
);
 
Once the tables created successfully, we will create the Partitioned View that combines four the SELECT statement, one per each participating table, using the UNION ALL T-SQL statement as in the below CREATE VIEW statement:

 
USE SQLShackDemo 
GO
CREATE VIEW DBO.Shipments_Info
WITH SCHEMABINDING
AS
SELECT [Ship_Num],[Ship_CountryCode],[Ship_Date],[Ship_Quarter] FROM DBO.Shipments_Q1
UNION ALL
SELECT [Ship_Num],[Ship_CountryCode],[Ship_Date],[Ship_Quarter] FROM DBO.Shipments_Q2
UNION ALL
SELECT [Ship_Num],[Ship_CountryCode],[Ship_Date],[Ship_Quarter] FROM DBO.Shipments_Q3
UNION ALL
SELECT [Ship_Num],[Ship_CountryCode],[Ship_Date],[Ship_Quarter] FROM DBO.Shipments_Q4
 

That’s it! Now the Partitioned View solution is ready to use. If we try to insert four values to the view directly, which is updatable in our case here as the view contains SELECT statement per each participant table, the tables combined by UNION ALL operator and the partitioning column is involved in the Primary Key constraint as described previously. The INSERT INTO T-SQL statement to the view will handle spreading the data through the participating tables depending on the CHECK constraint. If we run the below INSERT INTO statements:

 
INSERT INTO DBO.Shipments_Info VALUES(1117,'JOR',GETDATE(),1)
INSERT INTO DBO.Shipments_Info VALUES(1118,'JFK',GETDATE(),2)
INSERT INTO DBO.Shipments_Info VALUES(1119,'CAS',GETDATE(),3)
INSERT INTO DBO.Shipments_Info VALUES(1120,'BEY',GETDATE(),4)
 
And try to retrieve the data from the four participating tables:

 
SELECT * FROM DBO.Shipments_Q1
GO
SELECT * FROM DBO.Shipments_Q2
GO
SELECT * FROM DBO.Shipments_Q3
GO
SELECT * FROM DBO.Shipments_Q4
GO

If we plan to retrieve the third quarter data using a filter on the Ship_Num column:

 
  SELECT * FROM DBO.Shipments_Info WHERE [Ship_Num] = 1119
 
The SQL Server Query Optimizer will seek all participating tables for this value, which is part of the Primary Key on all tables, in order to retrieve the requested data as in the execution plan below generated using the APEXSQL PLAN application:

But if we search for the same data by filtering the Ship_Quarter partitioning column:

 
set statistics profile, time, io on
go
 SELECT * FROM DBO.Shipments_Info WHERE [Ship_Num] = 1119 and [Ship_Quarter] = 3
 
The SQL Server Query Optimizer will identify directly in which table it can find that data without the need to touch all participating tables as shown in the below execution plan generated using the APEXSQL PLAN application:




