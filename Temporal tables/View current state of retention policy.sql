SELECT DB.is_temporal_history_retention_enabled,
    SCHEMA_NAME(T1.schema_id) AS TemporalTableSchema,
    T1.name AS TemporalTableName,
    SCHEMA_NAME(T2.schema_id) AS HistoryTableSchema,
    T2.name AS HistoryTableName,
    T1.history_retention_period,
    T1.history_retention_period_unit_desc
FROM sys.tables T1
OUTER APPLY (
    SELECT is_temporal_history_retention_enabled
    FROM sys.databases
    WHERE name = DB_NAME()
    ) AS DB
LEFT JOIN sys.tables T2
    ON T1.history_table_id = T2.object_id
WHERE T1.temporal_type = 2;