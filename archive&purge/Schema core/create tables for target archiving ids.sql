use TFM_Archive
go

create table core.transactionIdArchiving(transactionId int constraint PK_transactionId primary key)
create table core.activityIdArchiving(activityId int constraint PK_activityId primary key)

go