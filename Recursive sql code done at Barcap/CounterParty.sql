USE [FALCON_SRF_Credit_QA]
GO

/****** Object:  Table [srf_main].[CounterParty]    Script Date: 02/26/2013 17:42:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [srf_main].[CounterParty](
	[id] [int] NOT NULL,
	[parentcpartyid] [varchar](100) NULL,
	[ultimateparent] [varchar](100) NULL,
	[lei] [varchar](100) NULL,
	[avId] [varchar](100) NULL,
	[categoryCode] [varchar](10) NULL,
	[classification] [varchar](100) NULL,
	[percentOwned] [varchar](100) NULL,
	[donotreportflag] [varchar](10) NULL,
	[uspersonflag] [varchar](10) NULL,
	[isdaflag] [varchar](10) NULL,
	[maskingoverrideflag] [varchar](10) NULL,
	[countryofincorporation] [varchar](10) NULL,
	[countryofoperation] [varchar](10) NULL,
	[childCOI] [varchar](10) NULL,
	[childCOO] [varchar](10) NULL,
	[phaseInCategory1] [varchar](255) NULL,
	[phaseInCategory2] [varchar](255) NULL,
	[phaseInCategory3] [varchar](255) NULL,
	[centralGovernment] [varchar](255) NULL,
	[centralBanks] [varchar](255) NULL,
	[interNatFinInst] [varchar](255) NULL
) ON [FALCON_SRF_D02_Group1]

GO

SET ANSI_PADDING ON
GO
create index IDX_ID on srf_main.CounterParty(id)
go


