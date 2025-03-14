SELECT  [ObjectName],
        COUNT(*) AS [SP Count]
FROM    [dbo].[Identify_query_counts]
WHERE   [Duration] > 100
        AND [ObjectName] IS NOT NULL
GROUP BY [ObjectName]
ORDER BY [SP Count] DESC
