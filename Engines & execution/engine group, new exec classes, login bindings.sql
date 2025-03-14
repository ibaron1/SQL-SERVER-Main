/* on GLSR2D
sp_showexeclass

use master
exec sp_showcontrolinfo

exec sp_tempdb 'show'
*/
select engine, status from master..sysengines

exec sp_addengine 8, EC3
exec sp_addengine 9, EC3

-- exec sp_dropengine 7, EC3 --> engine group is dropped when the last ingine in the group is dropped

exec sp_addexeclass "ADHOC", "LOW", 0, "EC3"

exec sp_bindexeclass 'GLSQryTlR', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlR3', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlR4', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlR5', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlR7', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlRD', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlW', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlW3', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlW4', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlW5', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlW7', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlWD', 'lg', NULL, 'ADHOC'

/********************  Change exec class *************************/

exec sp_unbindexeclass 'GLSQryTlR', 'lg', NULL
exec sp_unbindexeclass 'GLSQryTlR3', 'lg', NULL
exec sp_unbindexeclass 'GLSQryTlR4', 'lg', NULL
exec sp_unbindexeclass 'GLSQryTlR5', 'lg', NULL
exec sp_unbindexeclass 'GLSQryTlR7', 'lg', NULL
exec sp_unbindexeclass 'GLSQryTlRD', 'lg', NULL
exec sp_unbindexeclass 'GLSQryTlW', 'lg', NULL
exec sp_unbindexeclass 'GLSQryTlW3', 'lg', NULL
exec sp_unbindexeclass 'GLSQryTlW4', 'lg', NULL
exec sp_unbindexeclass 'GLSQryTlW5', 'lg', NULL
exec sp_unbindexeclass 'GLSQryTlW7', 'lg', NULL
exec sp_unbindexeclass 'GLSQryTlWD', 'lg', NULL

sp_dropexeclass 'ADHOC'

exec sp_addexeclass "ADHOC", "MEDIUM", 0, "EC3"

exec sp_bindexeclass 'GLSQryTlR', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlR3', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlR4', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlR5', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlR7', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlRD', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlW', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlW3', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlW4', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlW5', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlW7', 'lg', NULL, 'ADHOC'
exec sp_bindexeclass 'GLSQryTlWD', 'lg', NULL, 'ADHOC'