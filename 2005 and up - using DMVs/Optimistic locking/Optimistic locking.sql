use riskbook
go

CREATE TABLE _LastID_copy(
	name varchar(50) NOT NULL,
	lastID int NOT NULL,
	pad1 varchar(255) NULL,
	pad2 varchar(255) NULL,
	pad3 varchar(255) NULL,
	pad4 varchar(255) NULL,
	rowid rowversion not null,
 CONSTRAINT XPK_LastID1 PRIMARY KEY CLUSTERED 
(
	name ASC
)) ON [PRIMARY]

go

insert _LastID_copy
(

)




