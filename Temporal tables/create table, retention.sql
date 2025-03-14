CREATE TABLE dbo.WebsiteUserInfo
(
    UserID INT NOT NULL PRIMARY KEY CLUSTERED,
    UserName NVARCHAR(100) NOT NULL,
    PagesVisited int NOT NULL,
    ValidFrom DATETIME2(0) GENERATED ALWAYS AS ROW START,
    ValidTo DATETIME2(0) GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON
    (
        HISTORY_TABLE = dbo.WebsiteUserInfoHistory,
        HISTORY_RETENTION_PERIOD = 6 MONTHS
    )
);

PK is a must for temporal tables

Retention can be spicified as
DAYS
WEEKS
MONTHS
YEARS
INFINITE (DEFAULT, -1)

In some scenarios, you might want to configure retention after table creation, or to change the previously configured value. In that case, use the ALTER TABLE statement:

ALTER TABLE dbo.WebsiteUserInfo
SET (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 9 MONTHS));