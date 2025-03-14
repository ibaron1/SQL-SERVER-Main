use RiskBook
go

if not exists (select '1' from sys.columns where object_name(object_id) = '_LastID' and name = 'rowid')
alter table _LastID
add rowid rowversion not null

go