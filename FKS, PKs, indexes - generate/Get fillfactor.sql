select object_name(object_id) as [table],
name as [index],
type_desc,
is_unique,
fill_factor
from sys.indexes
where object_name(object_id) in ('order_summary', 'order_activity','exec_activity')