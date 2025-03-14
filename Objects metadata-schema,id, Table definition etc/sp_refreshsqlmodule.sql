https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-refreshsqlmodule-transact-sql?view=sql-server-ver16

sp_refreshsqlmodule should be run when changes are made to the objects underlying the module that affect its definition. 

Otherwise, the module might produce unexpected results when queried or invoked. 

To refresh a view, you can use either sp_refreshsqlmodule or sp_refreshview with the same results.