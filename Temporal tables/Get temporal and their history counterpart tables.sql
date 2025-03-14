select schema_name(t.schema_id) as temporal_table_schema,
     t.name as temporal_table_name,
    schema_name(h.schema_id) as history_table_schema,
     h.name as history_table_name,
    case when t.history_retention_period = -1 
        then 'INFINITE' 
        else cast(t.history_retention_period as varchar) + ' ' + 
            t.history_retention_period_unit_desc + 'S'
    end as retention_period
from sys.tables t
    left outer join sys.tables h
        on t.history_table_id = h.object_id
where t.temporal_type = 2
order by temporal_table_schema, temporal_table_name