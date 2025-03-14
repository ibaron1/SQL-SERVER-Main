UPDATE [FALCON_SRF_Cache].[srf_cache].[D_SDSRefData]
   SET 
       [id] = CASE [id]  WHEN 'NULL' THEN NULL ELSE  [id] END
      ,[type] = CASE [type]  WHEN 'NULL' THEN NULL ELSE  [type] END
      ,[premierClient] = CASE [premierClient]  WHEN 'NULL' THEN NULL ELSE  [premierClient] END
      ,[Name] = CASE [Name]  WHEN 'NULL' THEN NULL ELSE  [Name] END
      ,[shortName] = CASE [shortName]  WHEN 'NULL' THEN NULL ELSE  [shortName] END
      ,[groupId] = CASE [groupId]  WHEN 'NULL' THEN NULL ELSE  [groupId] END
      ,[parentCpartyId] = CASE [parentCpartyId]  WHEN 'NULL' THEN NULL ELSE  [parentCpartyId] END
      ,[ultimateParent] = CASE [ultimateParent]  WHEN 'NULL' THEN NULL ELSE  [ultimateParent] END
      ,[locationOfOperation] = CASE [locationOfOperation]  WHEN 'NULL' THEN NULL ELSE  [locationOfOperation] END
      ,[countryOfOperation] = CASE [countryOfOperation]  WHEN 'NULL' THEN NULL ELSE  [countryOfOperation] END
      ,[locationOfIncorporation] = CASE [locationOfIncorporation]  WHEN 'NULL' THEN NULL ELSE  [locationOfIncorporation] END
      ,[countryOfIncorporation] = CASE [countryOfIncorporation]  WHEN 'NULL' THEN NULL ELSE  [countryOfIncorporation] END
      ,[lastUpdateDate] = CASE [lastUpdateDate]  WHEN 'NULL' THEN NULL ELSE  [lastUpdateDate] END
      ,[deleted] = CASE [deleted]  WHEN 'NULL' THEN NULL ELSE  [deleted] END
      ,[lei] = CASE [lei]  WHEN 'NULL' THEN NULL ELSE  [lei] END
      ,[swiftBic] = CASE [swiftBic]  WHEN 'NULL' THEN NULL ELSE  [swiftBic] END
      ,[avId] = CASE [avId]  WHEN 'NULL' THEN NULL ELSE  [avId] END
      ,[categoryCode] = CASE [categoryCode]  WHEN 'NULL' THEN NULL ELSE  [categoryCode] END
      ,[classification] = CASE [classification]  WHEN 'NULL' THEN NULL ELSE  [classification] END
      ,[percentOwned] = CASE [percentOwned]  WHEN 'NULL' THEN NULL ELSE  [percentOwned] END
      ,[principal] = CASE [principal]  WHEN 'NULL' THEN NULL ELSE  [principal] END
      ,[agent] = CASE [agent]  WHEN 'NULL' THEN NULL ELSE  [agent] END
      ,[DoNotReportFlag] = CASE [DoNotReportFlag]  WHEN 'NULL' THEN NULL ELSE  [DoNotReportFlag] END
      ,[USPersonFlag] = CASE [USPersonFlag]  WHEN 'NULL' THEN NULL ELSE  [USPersonFlag] END
      ,[ISDAFlag] = CASE [ISDAFlag]  WHEN 'NULL' THEN NULL ELSE  [ISDAFlag] END
      ,[MaskingOverrideFlag] = CASE [MaskingOverrideFlag]  WHEN 'NULL' THEN NULL ELSE  [MaskingOverrideFlag] END
      ,[giveUpFlag] = CASE [giveUpFlag]  WHEN 'NULL' THEN NULL ELSE  [giveUpFlag] END
      ,[extId$] = CASE [extId$]  WHEN 'NULL' THEN NULL ELSE  [extId$] END
      ,[phaseInCategory1] = CASE [phaseInCategory1]  WHEN 'NULL' THEN NULL ELSE  [phaseInCategory1] END
      ,[phaseInCategory2] = CASE [phaseInCategory2]  WHEN 'NULL' THEN NULL ELSE  [phaseInCategory2] END
      ,[phaseInCategory3] = CASE [phaseInCategory3]  WHEN 'NULL' THEN NULL ELSE  [phaseInCategory3] END
      ,[centralGovernment] = CASE [centralGovernment]  WHEN 'NULL' THEN NULL ELSE  [centralGovernment] END
      ,[centralBanks] = CASE [centralBanks]  WHEN 'NULL' THEN NULL ELSE  [centralBanks] END
      ,[interNatFinInst] = CASE [interNatFinInst]  WHEN 'NULL' THEN NULL ELSE  [interNatFinInst] END
      ,[pseudoLegal] = CASE [pseudoLegal]  WHEN 'NULL' THEN NULL ELSE  [pseudoLegal] END
      ,[trSdsId] = CASE [trSdsId]  WHEN 'NULL' THEN NULL ELSE  [trSdsId] END
      ,[isUndisclosedPrincipalFlag] = CASE [isUndisclosedPrincipalFlag]  WHEN 'NULL' THEN NULL ELSE  [isUndisclosedPrincipalFlag] END

GO

/*
select * into [srf_cache].[D_SDSRefData_backup]
from [srf_cache].[D_SDSRefData]
*/