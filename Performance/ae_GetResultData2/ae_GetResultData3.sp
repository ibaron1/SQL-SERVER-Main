set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[ae_GetResultData3] (@simID INT,  @startPID INT, @endPID INT, @resultID INT)
AS
BEGIN

 SET NOCOUNT ON

  select  p.positionid,
    s.valueID,
    s.legid,
    plc.currency, --null as currency,
    s.strategyID,
    s.effectiveDate,
    s.valuationDate,
    s.curveID,
    s.maturityPeriod,
    s.ResultValue
  from    
		ufnSimResultBase(@simID)  s,
		ufnGetPositions6(@simID, @startPID, @endPID) p,
		positionlegcurrency plc WITH (NOLOCK)
  where  p.simulationID  = @simID
   and p.positionUID  = s.positionUID
   and  p.positionUID  = plc.positionUID
   and  s.positionUID  = plc.positionUID
   and  s.legid  = plc.legId
   and  s.valueID  = @resultID

END