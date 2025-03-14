/****************************************************************************/
/*    Size Does Matter: 10 Ways to Reduce DB Size and Improve Performance   */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                          Unused indexes                                  */
/****************************************************************************/


-- Check TableInfo.SQL instead

use [SQLServerInternals]
go

select 
    s.Name + N'.' + t.name as [Table]
    ,i.name as [Index] 
    ,i.is_unique as [IsUnique]
    ,ius.user_seeks as [Seeks], ius.user_scans as [Scans]
    ,ius.user_lookups as [Lookups]
    ,ius.user_seeks + ius.user_scans + ius.user_lookups as [Reads]
    ,ius.user_updates as [Updates], ius.last_user_seek as [Last Seek]
    ,ius.last_user_scan as [Last Scan], ius.last_user_lookup as [Last Lookup]
    ,ius.last_user_update as [Last Update]
from 
    sys.tables t with (nolock) join sys.indexes i with (nolock) on
        t.object_id = i.object_id
    join sys.schemas s with (nolock) on 
        t.schema_id = s.schema_id
    left outer join sys.dm_db_index_usage_stats ius on
        ius.database_id = db_id() and
        ius.object_id = i.object_id and 
        ius.index_id = i.index_id
order by
    s.name, t.name, i.index_id
option (recompile)
go

select 
    s.Name + N'.' + t.name as [Table]
    ,i.name as [Index] 
    ,i.is_unique as [IsUnique]
	,ios.*
from 
    sys.tables t with (nolock) join sys.indexes i with (nolock) on
        t.object_id = i.object_id
    join sys.schemas s with (nolock) on 
        t.schema_id = s.schema_id
    outer apply sys.dm_db_index_operational_stats
		(
			db_id()
			,t.object_id
			,i.index_id
			,null
		) ios
order by
    s.name, t.name, i.index_id
option (recompile)
go

alter index PK_DataWithXML on dbo.DataWithXML rebuild
go

