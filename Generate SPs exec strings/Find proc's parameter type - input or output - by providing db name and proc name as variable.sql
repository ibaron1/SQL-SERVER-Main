use master
go

create proc sp_GetParamType
@pname varchar(100)
as
set nocount on

declare @db varchar(100)

set @db = db_name()

select name as param_name, 
case isoutparam 
when 0 then 'input'
when 1 then 'output' 
end as param_type
from syscolumns
where id=object_id(@db+'..'+@pname)
go


/**

from truviewConfig db:

riskbook..sp_GetParamType 'smsp_GetTemplateCurveID'

returns:


param_name	param_type
@curveID	input
@templCurveID	output

**/