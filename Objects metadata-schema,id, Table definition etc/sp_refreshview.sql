https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-refreshview-transact-sql?view=sql-server-ver16

Updates the metadata for the specified non-schema-bound view. 

Persistent metadata for a view can become outdated because of changes to the underlying objects upon which the view depends.

sp_refreshview [ @viewname = ] 'viewname'
[ ; ]