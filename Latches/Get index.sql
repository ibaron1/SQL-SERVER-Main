select OBJECT_NAME(object_id) as [Table], name as [Index], index_id 
from sys.indexes
where OBJECT_NAME(object_id) = 'MoneyMarketFixedCFT'