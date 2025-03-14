The REPLICATE function replicates a string a requested number of times. Syntax REPLICATE(string, n)

Syntax REPLICATE(string, n)

SELECT supplierid,
  RIGHT(REPLICATE('0', 9) + CAST(supplierid AS VARCHAR(10)), 10) AS strsupplierid
FROM Production.Suppliers;

supplierid  strsupplierid
----------- -------------
29          0000000029
28          0000000028
4           0000000004
21          0000000021
2           0000000002

