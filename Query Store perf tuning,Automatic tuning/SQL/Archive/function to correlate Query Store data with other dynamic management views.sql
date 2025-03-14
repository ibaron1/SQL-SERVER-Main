SELECT qt.query_text_id,
       q.query_id,
       qt.query_sql_text,
       qt.statement_sql_handle,
       q.context_settings_id,
       qs.statement_context_id
FROM sys.query_store_query_text AS qt
     INNER JOIN sys.query_store_query AS q
         ON qt.query_text_id = q.query_text_id
CROSS APPLY sys.fn_stmt_sql_handle_from_sql_stmt(qt.query_sql_text, NULL) AS fn_handle_from_stmt
     INNER JOIN sys.dm_exec_query_stats AS qs
         ON fn_handle_from_stmt.statement_sql_handle = qs.statement_sql_handle;