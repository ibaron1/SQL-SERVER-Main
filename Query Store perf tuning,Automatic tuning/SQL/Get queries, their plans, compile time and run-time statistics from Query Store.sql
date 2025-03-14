SELECT Txt.query_text_id, Txt.query_sql_text, Pln.plan_id, Qry.*, RtSt.*
FROM sys.query_store_plan AS Pln
INNER JOIN sys.query_store_query AS Qry
    ON Pln.query_id = Qry.query_id
INNER JOIN sys.query_store_query_text AS Txt
    ON Qry.query_text_id = Txt.query_text_id
INNER JOIN sys.query_store_runtime_stats RtSt
ON Pln.plan_id = RtSt.plan_id;