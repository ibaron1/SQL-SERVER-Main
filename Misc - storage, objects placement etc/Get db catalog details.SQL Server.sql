
select 
(select @@servername) as [SQL Server],
(select db_name()) as DbName,
(select count(*) from systypes where usertype > 99) as [User Datatypes],
(select count(*) from sysobjects where type = 'R') as [Rules],
(select count(*)  from sysconstraints where status&5 = 5) as [Defaults],
(select count(*) from sysobjects where type = 'U') as [Tables],
(select count(*) from sys.computed_columns where is_computed&1 = 1) as [ComputedColumns],
(select count(*) from sys.computed_columns where is_persisted&1 = 1) as [PersistedComputedColumns],
(select count(*)  from sysconstraints where status&4 = 4)  as [CheckConstraints],
(select count(*) from sys.indexes where is_primary_key = 1) as [PKconstraints],
(select count(*)  from sysconstraints where status&3 = 3)  as [FKconstraints],
(select count(*) from sys.indexes where type=1) as  [ClusteredIndexes],
(select count(*) from sys.indexes where type=2) as  [NonclusteredIndexes],
(select count(*) from sysobjects where type = 'P') as [Procedures],
(select count(*) from sysobjects where type = 'V') as [Views],
(select count(*) from sysobjects where type = 'TR') as [Triggers],
(select count(*) from sys.objects where type = 'FN') as [ScalarFunctions],
(select count(*) from sysobjects where type = 'IF') as [InlineTableValuedFunction]





