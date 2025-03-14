SELECT  cat.name            AS category_name        ,
evt.name           AS event_name        ,
col.name           AS column_name        ,
sub.subclass_name 
FROM    sys.trace_subclass_values sub
JOIN    sys.trace_columns col           ON  sub.trace_column_id = col.trace_column_id
JOIN    sys.trace_events evt            ON  sub.trace_event_id = evt.trace_event_id
JOIN    sys.trace_categories cat        ON  cat.category_id = evt.category_id
WHERE   sub.subclass_name like '%pool%'