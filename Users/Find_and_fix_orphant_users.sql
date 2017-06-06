/******** Find and fix orphant users, this might happen after daatabse was copied from another server where SID for user is different ********/
-- find orphant users
exec sp_change_users_login 'Report'

-- fix orphant users - will map to login if one exists and use its password otherwise create login with this password
exec sp_change_users_login 'Auto_Fix', 'DEVtest', null,'pw'