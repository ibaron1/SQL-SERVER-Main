SELECT
plan_id,
query_id,
s.compatibility_level ,
s.last_execution_time,
s.last_compile_duration,
CAST(query_plan AS XML) AS 'Execution Plan'
FROM sys.query_store_plan s

