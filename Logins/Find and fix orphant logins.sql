The fastest way to copy a database is to detach-copy-attach method, but the production users will not have database access while the prod db is detached. You can do something like this if your production DB is for example a Point of Sale system that nobody uses during the night.

If you cannot detach the production db you should use backup and restore.

You will have to create the logins if they are not in the new instance. I do not recommend you to copy the system databases.

You can use the SQL Server Management Studio to create the scripts that create the logins you need. Right click on the login you need to create and select Script Login As / Create.

This will lists the orphaned users:

EXEC sp_change_users_login 'Report'

If you already have a login id and password for this user, fix it by doing:

EXEC sp_change_users_login 'Auto_Fix', 'user'

If you want to create a new login id and password for this user, fix it by doing:

EXEC sp_change_users_login 'Auto_Fix', 'user', 'login', 'password'
