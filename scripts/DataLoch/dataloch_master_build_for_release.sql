/*--------------------------------------------------------------------------------------
-- Project: 
-------------
DataLoch Respiratory Registry (as part of Respiratory Curation Harmonisation project funded by BREATHE, HDR UK)

-------------
-- Purpose: 
-------------
Build curated datasets for respiratory cohorts that is not project-specific and is comparable with work
performed in England and Wales for curation harmonisation project using DataLoch internal data.

-------------
-- Author: 
-------------
Sara Hatam, DataLoch

-------------
-- Notes:
-------------
To be run after dataloch_pull_codelists_for_release.sql

Paths and databases names have been modified or replaced with [REDACTED] as a 
condition for release to public domain.

NB: This script cannot be run without having internal DataLoch access.
----------------------------------------------------------------------------------------*/

USE [REDACTED]

-- Create schemas
IF (SCHEMA_ID('RESP_RAW') IS NULL)
BEGIN
    EXEC ('CREATE SCHEMA RESP_RAW')
END;

IF (SCHEMA_ID('RESP') IS NULL)
BEGIN
    EXEC ('CREATE SCHEMA RESP')
END;

DECLARE @GP_END AS DATE;
SELECT @GP_END = CAST('2023-05-18' AS DATE);

/*-------------------------------------------------------------------------------
-- Get respiratory condition events (GP, SMR, NRS Deaths)
---------------------------------------------------------------------------------*/
-- GP
DROP TABLE IF EXISTS #gp_events
SELECT 
	gp.PPID
	,gp.PPIDType
	,CAST(EventDate AS Date) AS EventDate
	,Code
	,CodeType
	,Description
	,Incident
	,Prevalent
	,Condition
	,ConditionSubcategory1
	,ConditionSubcategory2
	,CodesetVersion
	,'GP' AS Source
INTO #gp_events
FROM [REDACTED].GP_RCE gp
INNER JOIN Codelist.Conditions
ON Code = FullReadCode
LEFT JOIN [REDACTED].DEMOG AS dem
	ON dem.PPID = gp.PPID
WHERE 
	CodesetVersion = '1.0'
AND CodeType = 'Read2'
AND gp.PPIDType = 'CHI'
AND EventDate > CAST('1900-01-01' AS DATE)
AND EventDate <= @GP_END

-- SMR and NRS
DROP TABLE IF EXISTS #smr_nrs_events
SELECT 
	PPID
	,PPIDType
	,CAST(EventDate AS Date) AS EventDate
	,Position
	,smr.Code
	,cond.CodeType
	,Description
	,Incident
	,Prevalent
	,Condition
	,ConditionSubcategory1
	,ConditionSubcategory2
	,CodesetVersion
	,Source
INTO #smr_nrs_events
FROM [REDACTED].SMR_C AS smr
INNER JOIN Codelist.Conditions AS cond
ON cond.Code COLLATE SQL_Latin1_General_CP1_CS_AS = smr.Code COLLATE SQL_Latin1_General_CP1_CS_AS
WHERE 
	CodesetVersion = '1.0'
AND cond.CodeType = 'ICD10'
AND PPIDType = 'CHI'
AND smr.CodeType = 'ICD'
UNION ALL
SELECT 
	PPID
	,PPIDType
	,CAST(EventDate AS Date) AS EventDate
	,Position
	,nrs.Code
	,cond.CodeType
	,Description
	,Incident
	,Prevalent
	,Condition
	,ConditionSubcategory1
	,ConditionSubcategory2
	,CodesetVersion
	,'NRS Death' AS Source
FROM [REDACTED].NRS_DEATH AS nrs
INNER JOIN Codelist.Conditions AS cond
ON cond.Code COLLATE SQL_Latin1_General_CP1_CS_AS = nrs.Code COLLATE SQL_Latin1_General_CP1_CS_AS
WHERE CodesetVersion = '1.0'
AND cond.CodeType = 'ICD10'
AND PPIDType = 'CHI'
AND nrs.CodeType = 'ICD10'

/*-------------------------------------------------------------------------------
-- Get approximate GP observability
---------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS #followup
;WITH registrations AS (
SELECT 
	PPID
	,PPIDType
	,RegistrationStartDate
	,RegistrationEndDate
	,CurrentPopulation
	,PastPopulation
	,Postcode
FROM [REDACTED].GP_REG
WHERE CurrentPopulation = 1 OR PastPopulation = 1
AND PPIDType = 'CHI'
AND IsValidCHI = 1
GROUP BY 
	PPID
	,PPIDType
	,RegistrationStartDate
	,RegistrationEndDate
	,CurrentPopulation
	,PastPopulation
	,Postcode
),reg_end AS (
SELECT PPID
		,PPIDType
		,RegistrationEndDate
		,Postcode
		,ROW_NUMBER() 
		OVER (PARTITION BY [PPID]
		ORDER BY RegistrationStartDate DESC) AS row_num_end
FROM registrations
), reg_start AS (
SELECT PPID
		,PPIDType
		,MIN(RegistrationStartDate) AS RegistrationStartDate
FROM registrations
WHERE RegistrationStartDate IS NOT NULL
GROUP BY
	PPID
	,PPIDType
)
SELECT
	s.PPID
	,s.PPIDType
	,DateOfBirth
	,DateOfDeath
	,CASE WHEN RegistrationStartDate < DateOfBirth OR RegistrationStartDate > @GP_END THEN NULL ELSE RegistrationStartDate END AS MinRegStartDate
	,CASE WHEN RegistrationEndDate > @GP_END THEN NULL ELSE RegistrationEndDate END AS MaxRegEndDate
	,Sex
	,Ethnicity6
	,Ethnicity
	,Postcode AS PostcodeAtLatestRegistration
INTO #followup
FROM reg_start AS s
LEFT JOIN reg_end AS e
ON s.PPID = e.PPID AND s.PPIDType = e.PPIDType
INNER JOIN [REDACTED].DEMOG d
ON s.PPID = d.PPID AND s.PPIDType = d.PPIDType
WHERE row_num_end = 1
AND DoBMatchesCHI = 1
AND SexMatchesCHI = 1
AND ( RegistrationStartDate < RegistrationEndDate OR RegistrationStartDate IS NULL OR RegistrationEndDate IS NULL )
AND (RegistrationStartDate < DateOfDeath OR RegistrationStartDate IS NULL OR DateOfDeath IS NULL)
AND (DateOfDeath IS NULL OR HealthActivityAfterDateOfDeath = 0)


/*----------------------------------------------------------------------------------------
-- Make conditions table
-- Ensure that we only keep people with valid, unique CHIs alive and observable from 2004
------------------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS RESP_RAW.ConditionEvents
;WITH unioned_conditions AS
(
SELECT 
	PPID
	,PPIDType
	,EventDate
	,Position
	,Code COLLATE SQL_Latin1_General_CP1_CS_AS AS Code
	,CodeType
	,Description
	,Incident
	,Prevalent
	,Condition
	,ConditionSubcategory1
	,ConditionSubcategory2
	,CodesetVersion
	,Source
FROM #smr_nrs_events
UNION ALL
SELECT 
	PPID
	,PPIDType
	,EventDate
	,NULL AS Position
	,Code
	,CodeType
	,Description
	,Incident
	,Prevalent
	,Condition
	,ConditionSubcategory1
	,ConditionSubcategory2
	,CodesetVersion
	,Source
FROM #gp_events
)
SELECT
	cond.PPID
	,cond.PPIDType
	,EventDate
	,Position
	,Code
	,CodeType
	,Description
	,Incident
	,Prevalent
	,Condition
	,ConditionSubcategory1
	,ConditionSubcategory2
	,CodesetVersion
	,Source
	,CASE WHEN Source = 'GP' THEN 'GP' WHEN Source LIKE 'SMR%' THEN 'Secondary Care' WHEN Source = 'NRS Death' THEN 'Death' END AS Pathway
INTO RESP_RAW.ConditionEvents
FROM unioned_conditions AS cond
INNER JOIN #followup f
	ON f.PPID = cond.PPID AND f.PPIDType = cond.PPIDType
WHERE 
	EventDate >= DateOfBirth
AND ( 
	DateOfDeath IS NULL 
	OR 
	(DateOfDeath >= CAST('2004-01-01' AS DATE) AND EventDate <= DateOfDeath)
	)
AND EventDate <= GETDATE()
AND EventDate > CAST('1900-01-01' AS DATE)
AND f.PPIDType = 'CHI'
AND cond.PPIDType = 'CHI'
AND ( MaxRegEndDate IS NULL OR MaxRegEndDate >= CAST('2004-01-01' AS DATE) )
AND ( ([REDACTED].AgeInYears(DateOfBirth, EventDate) >= 35 AND Condition = 'COPD') 
	OR ([REDACTED].AgeInYears(DateOfBirth, EventDate) >= 40 AND Condition = 'ILD') 
	OR Condition = 'Asthma')
GROUP BY
	cond.PPID
	,cond.PPIDType
	,EventDate
	,Position
	,Code
	,CodeType
	,Description
	,Incident
	,Prevalent
	,Condition
	,ConditionSubcategory1
	,ConditionSubcategory2
	,CodesetVersion
	,Source
	,CASE WHEN Source = 'GP' THEN 'GP' WHEN Source LIKE 'SMR%' THEN 'Secondary Care' WHEN Source = 'NRS Death' THEN 'NRS' END
ORDER BY 
	cond.PPID
	,EventDate

/*----------------------------------------------------------------------------------------
-- Make diagnoses table
------------------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS RESP_RAW.Diagnoses
;WITH max_inc AS (
SELECT 
	PPID 
	,PPIDType
	,EventDate
	,Condition
	,Source
	,MAX(Incident) AS MaxIncident
FROM RESP_RAW.ConditionEvents
GROUP BY
	PPID 
	,PPIDType
	,EventDate
	,Condition
	,Source
),
em_any AS (
SELECT 
	PPID 
	,PPIDType
	,Condition
	,MIN(EventDate) AS EarliestMention
FROM RESP_RAW.ConditionEvents
WHERE 
	Condition IN ('COPD', 'ILD', 'Asthma')
GROUP BY
	PPID 
	,PPIDType
	,Condition
),
em_incidence AS (
SELECT
	PPID 
	,PPIDType
	,Condition
	,MIN(EventDate) AS EarliestIncidence
FROM max_inc
WHERE Condition IN ('COPD', 'ILD', 'Asthma')
AND MaxIncident = 1
GROUP BY
	PPID 
	,PPIDType
	,Condition
),
em_pri_any AS (
SELECT
	PPID 
	,PPIDType
	,Condition
	,MIN(EventDate) AS EarliestMentionInPrimaryCare
FROM RESP_RAW.ConditionEvents
WHERE Condition IN ('COPD', 'ILD', 'Asthma')
AND Source = 'GP'
GROUP BY
	PPID 
	,PPIDType
	,Condition
),
em_pri_inc AS (
SELECT
	PPID 
	,PPIDType
	,Condition
	,MIN(EventDate) AS EarliestIncidenceInPrimaryCare
FROM max_inc
WHERE Condition IN ('COPD', 'ILD', 'Asthma')
AND Source = 'GP'
AND MaxIncident = 1
GROUP BY
	PPID 
	,PPIDType
	,Condition
),
em_reg AS (
SELECT
	em_any.PPID 
	,em_any.PPIDType
	,em_any.Condition
	,CAST(EarliestIncidence AS DATE) AS EarliestIncidence
	,CAST(EarliestMention AS DATE) AS EarliestMention
	,CAST(EarliestIncidenceInPrimaryCare AS DATE) AS EarliestIncidenceInPrimaryCare
	,CAST(EarliestMentionInPrimaryCare AS DATE) AS EarliestMentionInPrimaryCare
	,MinRegStartDate
FROM em_any
LEFT JOIN em_incidence AS inc
ON em_any.PPID = inc.PPID AND em_any.Condition = inc.Condition AND em_any.PPIDType = inc.PPIDType
LEFT JOIN em_pri_any AS pri
ON em_any.PPID = pri.PPID AND em_any.Condition = pri.Condition AND em_any.PPIDType = pri.PPIDType
LEFT JOIN em_pri_inc AS pri_inc
ON em_any.PPID = pri_inc.PPID AND em_any.Condition = pri_inc.Condition AND em_any.PPIDType = pri_inc.PPIDType
LEFT JOIN #followup AS f
ON em_any.PPID = f.PPID AND em_any.PPIDType = f.PPIDType
), 
inc_pathway AS (
SELECT 
	em_reg.PPID
	,em_reg.PPIDType 
	,em_reg.Condition
	,EarliestIncidence
	,1 AS non_gp
FROM em_reg
INNER JOIN RESP_RAW.ConditionEvents c
ON em_reg.PPID = c.PPID 
AND em_reg.PPIDType = c.PPIDType 
AND EarliestIncidence = EventDate 
AND em_reg.Condition = c.Condition
WHERE Pathway != 'GP'
GROUP BY 
	em_reg.PPID
	,em_reg.PPIDType 
	,em_reg.Condition
	,EarliestIncidence
)
SELECT
	em_reg.PPID 
	,em_reg.PPIDType
	,em_reg.Condition
	,CASE WHEN em_reg.EarliestIncidence > EarliestMention
		OR (DATEDIFF(Day, MinRegStartDate, em_reg.EarliestIncidence) BETWEEN 0 AND 365 AND MinRegStartDate IS NOT NULL AND non_gp IS NULL)
		THEN NULL ELSE em_reg.EarliestIncidence END AS EarliestIncidence
	,EarliestMention
	,CASE WHEN EarliestIncidenceInPrimaryCare > EarliestMentionInPrimaryCare 
		OR (DATEDIFF(Day, MinRegStartDate, EarliestIncidenceInPrimaryCare) BETWEEN 0 AND 365 AND MinRegStartDate IS NOT NULL)
		THEN NULL ELSE EarliestIncidenceInPrimaryCare END AS EarliestIncidenceInPrimaryCare
	,EarliestMentionInPrimaryCare
INTO RESP_RAW.Diagnoses
FROM em_reg 
LEFT JOIN inc_pathway p
ON em_reg.PPID = p.PPID AND em_reg.PPIDType = p.PPIDType AND p.EarliestIncidence = em_reg.EarliestIncidence AND em_reg.Condition = p.Condition
ORDER BY em_reg.PPID


/*----------------------------------------------------------------------------------------
-- Make demographics table
------------------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS RESP_RAW.Demographics
SELECT 
	PPID
	,PPIDType
	,DateOfBirth
	,MONTH(DateOfBirth) AS MonthOfBirth
	,YEAR(DateOfBirth) AS YearOfBirth
	,DateOfDeath
	,CASE WHEN CAST(MinRegStartDate AS DATE) < DateOfBirth THEN NULL ELSE CAST(MinRegStartDate AS DATE) END AS MinRegStartDate
	,CAST(MaxRegEndDate AS DATE) AS MaxRegEndDate
	,Sex
	,Ethnicity AS EthnicityScot2011
	,EthnicityUK2011
	,f.Ethnicity6
	,simd2020v2_sc_quintile
INTO RESP_RAW.Demographics
FROM #followup AS f
LEFT JOIN [REDACTED].SIMD
	ON REPLACE(PostcodeAtLatestRegistration, ' ', '') = REPLACE(Postcode, ' ', '')
LEFT JOIN Codelist.Ethnicity 
	ON Ethnicity = EthnicityScot2011
WHERE (MaxRegEndDate IS NULL OR MaxRegEndDate >= CAST('2004-01-01' AS DATE))
AND (DateOfDeath IS NULL OR DateOfDeath >= CAST('2004-01-01' AS DATE))
GROUP BY 
	PPID
	,PPIDType
	,DateOfBirth
	,DateOfDeath
	,Sex
	,Ethnicity
	,EthnicityUK2011
	,f.Ethnicity6 
	,CASE WHEN CAST(MinRegStartDate AS DATE) < DateOfBirth THEN NULL ELSE CAST(MinRegStartDate AS DATE) END
	,MaxRegEndDate
	,simd2020v2_sc_quintile
ORDER BY
PPID

ALTER TABLE RESP_RAW.Demographics
ADD GPFollowupEnd Date
GO

DECLARE @GP_END AS DATE;
SELECT @GP_END = CAST('2023-05-18' AS DATE);

UPDATE RESP_RAW.Demographics
SET GPFollowupEnd = (SELECT MIN(MinDate)
        FROM (VALUES (CASE WHEN DateOfDeath IS NULL THEN @GP_END ELSE DateOfDeath END),(CASE WHEN MaxRegEndDate IS NULL THEN @GP_END ELSE MaxRegEndDate END),(@GP_END)) AS UpdateScore(MinDate)) 

DROP TABLE IF EXISTS RESP_RAW.Medications
SELECT 
	pis.PPID
	,pis.PPIDType
	,[PD Prescribed Date] AS PrescribedDate
	,[Paid Date] AS PaidDate
	,[Paid Quantity] AS PaidQuantity
	,Code
	,CodeType
	,[PI BNF Item Description] AS Description
	,ATC
	,DrugSubstanceName
	,DrugSubstanceStrength
	,DrugFormulation
	,RouteOfAdministration
	,DrugGroup
	,DrugSubGroup
	,CodesetVersion
	,'PIS' AS Source
	,'GP' AS Pathway
INTO RESP_RAW.Medications
FROM [REDACTED].PIS AS pis
INNER JOIN Codelist.Medications
ON Code = [PI BNF Item Code]
INNER JOIN RESP_RAW.Diagnoses AS diag
ON pis.PPID = diag.PPID
WHERE 
	CodeType = 'BNF' 
	AND CodesetVersion = '1.0'
	AND [Presc Location Type] = 'GPPRA'
GROUP BY 
	pis.PPID
	,pis.PPIDType
	,[PD Prescribed Date]
	,[Paid Date]
	,[Paid Quantity]
	,Code
	,CodeType
	,[PI BNF Item Description]
	,ATC
	,DrugSubstanceName
	,DrugSubstanceStrength
	,DrugFormulation
	,RouteOfAdministration
	,DrugGroup
	,DrugSubGroup
	,CodesetVersion

DROP TABLE IF EXISTS RESP_RAW.Measurements
CREATE TABLE RESP_RAW.Measurements (
	[PPID] VARCHAR(30) NOT NULL
	,[PPIDType] VARCHAR(10) NOT NULL
	,MeasurementDate Date NOT NULL
	,MeasurementCode VARCHAR(50) NOT NULL
	,MeasurementDescription VARCHAR(200) NOT NULL
	,Pathway VARCHAR(20) NOT NULL
	,Source VARCHAR(100) NOT NULL
	,TextValue VARCHAR(100) NULL
	,NumericValue Float NULL
	,NumericUnit VARCHAR(20) NULL
)

-- First BMI and Height
DROP TABLE IF EXISTS #bmi_height
SELECT 
	obs.[PPID]
	,obs.[PPIDType]
	,CAST([Datetime] AS Date) AS MeasurementDate
	,CASE WHEN ObservationDescription = 'BMI value' THEN 'BMI' 
		WHEN ObservationDescription = 'Body height' THEN 'BodyHeight' END AS MeasurementCode
	,ObservationDescription AS MeasurementDescription
	,Pathway
	,Source
	,CASE WHEN [REDACTED].AgeInYears(DateOfBirth, datetime) < 18 THEN 'Child at measurement' ELSE NULL END AS TextValue
	,CASE WHEN ObservationDescription = 'BMI value' THEN ROUND(Value, 1) 
		WHEN ObservationDescription = 'Body height' THEN ROUND(ValueAsFloat/100.0, 2) END AS NumericValue
	,[REDACTED].AgeInYears(DateOfBirth, Datetime) AS AgeAtMeasurement
INTO #bmi_height
FROM [REDACTED].OBSERVATIONS AS obs
INNER JOIN [RESP_RAW].[Diagnoses] AS diag
ON diag.PPID = obs.PPID AND diag.PPIDType = obs.PPIDType
LEFT JOIN [RESP_RAW].[Demographics] AS dem
ON dem.PPID = obs.PPID AND diag.PPIDType = dem.PPIDType
WHERE 
	( ObservationDescription = 'BMI value' OR ObservationDescription = 'Body height' )
AND Datetime >= DateOfBirth
AND Datetime < GETDATE()
AND Datetime > CAST('1900-01-01' AS DATE)
AND (DateOfDeath IS NULL OR Datetime <= DateOfDeath) 
GROUP BY 
	obs.[PPID]
	,obs.[PPIDType]
	,CAST([Datetime] AS Date)
	,CASE WHEN ObservationDescription = 'BMI value' THEN 'BMI' 
		WHEN ObservationDescription = 'Body height' THEN 'BodyHeight' END
	,ObservationDescription
	,Source
	,Pathway
	,CASE WHEN [REDACTED].AgeInYears(DateOfBirth, Datetime) < 18 THEN 'Child at measurement' ELSE NULL END
	,CASE WHEN ObservationDescription = 'BMI value' THEN ROUND(Value, 1) 
		WHEN ObservationDescription = 'Body height' THEN ROUND(ValueAsFloat/100.0, 2) END
	,[REDACTED].AgeInYears(DateOfBirth, Datetime)

DELETE FROM #bmi_height WHERE NumericValue NOT BETWEEN 10 AND 100 AND MeasurementCode = 'BMI'
DELETE FROM #bmi_height WHERE NumericValue NOT BETWEEN 0.1 AND 2.5 AND MeasurementCode = 'BodyHeight'
DELETE FROM #bmi_height WHERE AgeAtMeasurement <= 3 AND NumericValue > 1.35 AND MeasurementCode = 'BodyHeight'
DELETE FROM #bmi_height WHERE AgeAtMeasurement BETWEEN 4 AND 11 AND NumericValue NOT BETWEEN 0.5 AND 2 AND MeasurementCode = 'BodyHeight'
DELETE FROM #bmi_height WHERE AgeAtMeasurement BETWEEN 12 AND 17 AND NumericValue NOT BETWEEN 0.5 AND 2.5 AND MeasurementCode = 'BodyHeight'
DELETE FROM #bmi_height WHERE AgeAtMeasurement >= 18 AND NumericValue NOT BETWEEN 1.21 AND 2.5 AND MeasurementCode = 'BodyHeight'

-- Quite a lot of same-day duplicates, get median
ALTER TABLE #bmi_height
ADD MedianValue Float NULL
GO

ALTER TABLE #bmi_height
ADD DiffFromMed Float NULL
GO

;WITH median AS
(SELECT PPID, PPIDType, MeasurementDate, MeasurementCode, NumericValue, Source, Pathway, PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY NumericValue)
        OVER (PARTITION BY PPID, MeasurementDate, MeasurementCode, Source, Pathway) AS MedianVal
FROM #bmi_height
)
UPDATE #bmi_height
SET MedianValue = MedianVal, DiffFromMed = CASE WHEN (meas.MeasurementCode = 'BMI' AND ABS(meas.NumericValue - MedianVal) > 1) OR 
(meas.MeasurementCode = 'BodyHeight' AND ABS(meas.NumericValue - MedianVal) >= 0.03)  THEN 1 ELSE 0 END
FROM #bmi_height meas
INNER JOIN median med
ON med.PPID = meas.PPID AND med.PPIDType = meas.PPIDType AND med.MeasurementDate = meas.MeasurementDate AND med.Source = meas.Source
AND med.Pathway = meas.Pathway AND med.MeasurementCode = meas.MeasurementCode


ALTER TABLE #bmi_height
ADD CountNumDiffFromMed Int NULL
GO

;WITH num_diff AS
(
SELECT PPID, PPIDType, MeasurementDate, MeasurementCode, NumericValue, Source, Pathway, MedianValue,
SUM(DiffFromMed) OVER (PARTITION BY [PPID], MeasurementDate, MeasurementCode, Source, Pathway) 
AS sum_diff
FROM #bmi_height
GROUP BY PPID, PPIDType, MeasurementDate, MeasurementCode, NumericValue, Source, Pathway, MedianValue, DiffFromMed
)
UPDATE #bmi_height
SET CountNumDiffFromMed = sum_diff
FROM #bmi_height meas
INNER JOIN num_diff AS diff
ON diff.PPID = meas.PPID AND diff.PPIDType = meas.PPIDType AND diff.MeasurementDate = meas.MeasurementDate AND diff.Source = meas.Source
AND diff.Pathway = meas.Pathway AND diff.MeasurementCode = meas.MeasurementCode

DELETE FROM #bmi_height WHERE CountNumDiffFromMed > 1 OR ( CountNumDiffFromMed = 1 AND DiffFromMed = 1 )

UPDATE #bmi_height
SET NumericValue = ROUND(MedianValue,1) WHERE NumericValue != ROUND(MedianValue,1) AND MeasurementCode = 'BMI'


UPDATE #bmi_height
SET NumericValue = ROUND(MedianValue,2) WHERE NumericValue != ROUND(MedianValue,2) AND MeasurementCode = 'BodyHeight'


DELETE FROM RESP_RAW.Measurements WHERE MeasurementCode IN ('BMI', 'BodyHeight')
INSERT INTO RESP_RAW.Measurements 
SELECT 
	[PPID]
	,[PPIDType]
	,MeasurementDate
	,MeasurementCode
	,MeasurementDescription
	,Pathway
	,Source
	,CASE WHEN TextValue = 'Child at measurement' THEN 'Child at measurement'
	WHEN MeasurementCode = 'BMI' AND ROUND(NumericValue, 1) < 18.5 THEN 'Underweight'
	WHEN MeasurementCode = 'BMI' AND ROUND(NumericValue, 1) < 25 THEN 'Normal'
	WHEN MeasurementCode = 'BMI' AND ROUND(NumericValue, 1) < 30 THEN 'Overweight'
	WHEN MeasurementCode = 'BMI' AND ROUND(NumericValue, 1) >= 30 THEN 'Obese' 
	ELSE NULL END AS TextValue
	,NumericValue
	,CASE WHEN MeasurementCode = 'BMI' THEN 'kg/m2'
	WHEN MeasurementCode = 'BodyHeight' THEN 'm' END AS NumericUnit
FROM #bmi_height
GROUP BY
	PPID
	,PPIDType
	,MeasurementDate
	,MeasurementCode
	,MeasurementDescription
	,Pathway
	,Source
	,CASE WHEN TextValue = 'Child at measurement' THEN 'Child at measurement'
	WHEN MeasurementCode = 'BMI' AND ROUND(NumericValue, 1) < 18.5 THEN 'Underweight'
	WHEN MeasurementCode = 'BMI' AND ROUND(NumericValue, 1) < 25 THEN 'Normal'
	WHEN MeasurementCode = 'BMI' AND ROUND(NumericValue, 1) < 30 THEN 'Overweight'
	WHEN MeasurementCode = 'BMI' AND ROUND(NumericValue, 1) >= 30 THEN 'Obese' 
	ELSE NULL END
,NumericValue 
,CASE WHEN MeasurementCode = 'BMI' THEN 'kg/m2'
	WHEN MeasurementCode = 'BodyHeight' THEN 'm' END

-- Smoking - no cleaning required
DELETE FROM RESP_RAW.Measurements WHERE MeasurementCode = 'SmokingStatus'
INSERT INTO RESP_RAW.Measurements
SELECT 
	obs.[PPID]
	,obs.[PPIDType]
	,CAST([Datetime] AS Date) AS MeasurementDate
	,'SmokingStatus' AS MeasurementCode
	,ObservationDescription AS MeasurementDescription
	,Pathway
	,Source
	,Value AS TextValue
	,NULL AS NumericValue
	,NULL AS NumericUnit
FROM [REDACTED].OBSERVATIONS AS obs
INNER JOIN [RESP_RAW].[Diagnoses] AS diag
ON diag.PPID = obs.PPID AND diag.PPIDType = obs.PPIDType
LEFT JOIN [RESP_RAW].[Demographics] AS dem
ON dem.PPID = obs.PPID AND dem.PPIDType = obs.PPIDType
WHERE 
	ObservationDescription = 'Smoking status'
AND Datetime >= DateOfBirth
AND Datetime < GETDATE()
AND Datetime > CAST('1900-01-01' AS DATE)
AND (DateOfDeath IS NULL OR Datetime <= DateOfDeath) 
GROUP BY 
	obs.[PPID]
	,obs.[PPIDType]
	,CAST([Datetime] AS Date)
	,ObservationCode
	,ObservationDescription
	,Source
	,Pathway
	,Value


-- Next is Actual FEV1
DELETE FROM RESP_RAW.Measurements WHERE MeasurementCode IN ('FEV1', 'FEV1PostBronchodil')
INSERT INTO RESP_RAW.Measurements 
SELECT 
	obs.[PPID]
	,obs.[PPIDType]
	,CAST([Datetime] AS Date) AS MeasurementDate
	,CASE WHEN ObservationDescription = 'Forced expired volume in 1 second' 
		THEN 'FEV1'
	WHEN ObservationDescription = 'Forced expired volume in 1 second after bronchodilation' 
		THEN 'FEV1PostBronchodil' 
	END AS MeasurementCode
	,ObservationDescription AS MeasurementDescription
	,Pathway
	,Source
	,NULL AS TextValue
	,MAX(ValueAsFloat) AS NumericValue -- get the best of all values on a single day
	,'L' AS NumericUnit
FROM [REDACTED].OBSERVATIONS AS obs
INNER JOIN [RESP_RAW].[Diagnoses] AS diag
ON diag.PPID = obs.PPID AND diag.PPIDType = obs.PPIDType
LEFT JOIN [RESP_RAW].[Demographics] AS dem
ON dem.PPID = obs.PPID AND dem.PPIDType = obs.PPIDType
WHERE 
	ObservationDescription IN ('Forced expired volume in 1 second', 'Forced expired volume in 1 second after bronchodilation')
AND Datetime >= DateOfBirth
AND Datetime < GETDATE()
AND Datetime > CAST('1900-01-01' AS DATE)
AND ValueAsFloat BETWEEN 0.1 AND 7
GROUP BY 
	obs.[PPID]
	,obs.[PPIDType]
	,CAST([Datetime] AS Date)
	,ObservationCode
	,ObservationDescription
	,Source
	,Pathway

-- Now ExpectedFEV1
DROP TABLE IF EXISTS #expectedfev1
SELECT 
	obs.[PPID]
	,obs.[PPIDType]
	,CAST([Datetime] AS Date) AS MeasurementDate
	,'ExpectedFEV1' AS MeasurementCode
	,ObservationDescription AS MeasurementDescription
	,Pathway
	,Source
	,NULL AS TextValue
	,ROUND(ValueAsFloat, 2) AS NumericValue
INTO #expectedfev1
FROM [REDACTED].OBSERVATIONS AS obs
INNER JOIN [RESP_RAW].[Diagnoses] AS diag
ON diag.PPID = obs.PPID AND diag.PPIDType = obs.PPIDType
LEFT JOIN [RESP_RAW].[Demographics] AS dem
ON dem.PPID = obs.PPID AND dem.PPIDType = obs.PPIDType
WHERE 
	ObservationDescription = 'Expected forced expired volume in 1 second'
AND Datetime >= DateOfBirth
AND Datetime < GETDATE()
AND Datetime > CAST('1900-01-01' AS DATE)
AND (DateOfDeath IS NULL OR Datetime <= DateOfDeath) 
AND ValueAsFloat BETWEEN 0.1 AND 7
GROUP BY 
	obs.[PPID]
	,obs.[PPIDType]
	,CAST([Datetime] AS Date)
	,ObservationCode
	,ObservationDescription
	,Source
	,Pathway
	,ROUND(ValueAsFloat,2)

-- drop duplicates completely as we will derive new ones
DROP TABLE IF EXISTS #drop_expectedfev1
SELECT PPID, MeasurementDate, Pathway
INTO #drop_expectedfev1
FROM #expectedfev1 GROUP BY PPID, MeasurementDate, Pathway HAVING COUNT(*) > 1

-- always use alias to stop from accidentally dropping whole table
DELETE _exp
FROM #expectedfev1 AS _exp
INNER JOIN #drop_expectedfev1 AS _drop
ON _exp.PPID = _drop.PPID AND _exp.MeasurementDate = _drop.MeasurementDate AND _exp.Pathway = _drop.Pathway


DELETE FROM RESP_RAW.Measurements WHERE MeasurementCode = 'ExpectedFEV1' AND Pathway != 'Derived'
INSERT INTO RESP_RAW.Measurements 
SELECT 
	[PPID]
	,[PPIDType]
	,MeasurementDate
	,'ExpectedFEV1' AS MeasurementCode
	,MeasurementDescription
	,Pathway
	,Source
	,NULL AS TextValue
	,NumericValue
	,'L' AS NumericUnit
FROM #expectedfev1

-- next is FEV1 percent predicted
DELETE FROM RESP_RAW.Measurements WHERE MeasurementCode IN ('FEV1PercentPredicted', 'FEV1PercentPredictedPostBronchodil') AND Source NOT LIKE 'Derived%'
INSERT INTO RESP_RAW.Measurements 
SELECT 
	obs.[PPID]
	,obs.[PPIDType]
	,CAST([Datetime] AS Date) AS MeasurementDate
	,CASE WHEN ObservationDescription = 'Percent predicted forced expired volume in one second'
		THEN 'FEV1PercentPredicted' 
	WHEN ObservationDescription = 'Percentage predicted forced expiratory volume in 1 second after bronchodilation'
		THEN 'FEV1PercentPredictedPostBronchodil' 
	END AS MeasurementCode
	,ObservationDescription AS MeasurementDescription
	,Pathway
	,Source
	,CASE 
	WHEN obs.PPID NOT IN (SELECT DISTINCT PPID FROM RESP_RAW.Diagnoses WHERE Condition = 'COPD') 
		THEN 'No known COPD diagnosis' 
	WHEN ROUND(MAX(ValueAsFloat),0) >= 80 THEN 'GOLD Stage 1 (Mild)'
	WHEN ROUND(MAX(ValueAsFloat),0) < 80 AND ROUND(MAX(ValueAsFloat),0) >= 50 THEN 'GOLD Stage 2 (Moderate)'
	WHEN ROUND(MAX(ValueAsFloat),0) < 50 AND ROUND(MAX(ValueAsFloat),0) >= 30 THEN 'GOLD Stage 3 (Severe)'
	WHEN ROUND(MAX(ValueAsFloat),0) < 30 THEN 'GOLD Stage 4 (Very severe)' 
		END AS TextValue
	,ROUND(MAX(ValueAsFloat),0) AS NumericValue -- get best of same-day values
	,'%' AS NumericUnit
FROM [REDACTED].OBSERVATIONS AS obs
INNER JOIN [RESP_RAW].[Diagnoses] AS diag
ON diag.PPID = obs.PPID AND diag.PPIDType = obs.PPIDType
LEFT JOIN [RESP_RAW].[Demographics] AS dem
ON dem.PPID = obs.PPID AND dem.PPIDType = obs.PPIDType
WHERE 
	ObservationDescription IN ('Percent predicted forced expired volume in one second', 
	'Percentage predicted forced expiratory volume in 1 second after bronchodilation')
AND Datetime >= DateOfBirth
AND Datetime < GETDATE()
AND Datetime > CAST('1900-01-01' AS DATE)
AND ValueAsFloat BETWEEN 5 AND 200
GROUP BY 
	obs.[PPID]
	,obs.[PPIDType]
	,CAST([Datetime] AS Date)
	,ObservationCode
	,ObservationDescription
	,Source
	,Pathway


-- we need to make FEV1 percent predicted where there is FEV1 and ExpectedFEV1
DROP TABLE IF EXISTS #all_fev1
;WITH exp_gp AS (
SELECT
	PPID
	,PPIDType
	,MeasurementDate
	,NumericValue AS ExpectedFEV1
	,Pathway
FROM RESP_RAW.Measurements
WHERE MeasurementCode = 'ExpectedFEV1'
AND Pathway = 'GP'
),
exp_sc AS (
SELECT
	PPID
	,PPIDType
	,MeasurementDate
	,NumericValue AS ExpectedFEV1
	,Pathway
FROM RESP_RAW.Measurements
WHERE MeasurementCode = 'ExpectedFEV1'
AND Pathway = 'Secondary care'
),
perc_gp AS (
SELECT
	PPID
	,PPIDType
	,MeasurementDate
	,NumericValue AS FEV1PercPred
	,Pathway
FROM RESP_RAW.Measurements
WHERE MeasurementCode = 'FEV1PercentPredicted'
AND Pathway = 'GP'
),
perc_sc AS (
SELECT
	PPID
	,PPIDType
	,MeasurementDate
	,NumericValue AS FEV1PercPred
	,Pathway
FROM RESP_RAW.Measurements
WHERE MeasurementCode = 'FEV1PercentPredicted'
AND Pathway = 'Secondary care'
),
perc_sc_bronch AS (
SELECT
	PPID
	,PPIDType
	,MeasurementDate
	,NumericValue AS FEV1PercPred
	,Pathway
FROM RESP_RAW.Measurements
WHERE MeasurementCode = 'FEV1PercentPredictedPostBronchodil'
AND Pathway = 'Secondary care'
)
SELECT 
	fev1.PPID
	,fev1.PPIDType
	,fev1.MeasurementDate
	,fev1.MeasurementCode
	,fev1.NumericValue AS FEV1 
	,fev1.Pathway AS FEV1Pathway
	,exp_gp.ExpectedFEV1 AS ExpectedFEV1_GP
	,exp_sc.ExpectedFEV1 AS ExpectedFEV1_SC
	,perc_gp.FEV1PercPred AS FEV1PercPred_GP
	,perc_sc.FEV1PercPred AS FEV1PercPred_SC
	,perc_sc_bronch.FEV1PercPred AS FEV1PercPred_SC_bronch
INTO #all_fev1
FROM RESP_RAW.Measurements AS fev1
LEFT JOIN exp_gp
ON fev1.PPID = exp_gp.PPID AND fev1.PPIDType = exp_gp.PPIDType AND fev1.MeasurementDate = exp_gp.MeasurementDate
LEFT JOIN exp_sc
ON fev1.PPID = exp_sc.PPID AND fev1.PPIDType = exp_sc.PPIDType AND fev1.MeasurementDate = exp_sc.MeasurementDate
LEFT JOIN perc_gp
ON fev1.PPID = perc_gp.PPID AND fev1.PPIDType = perc_gp.PPIDType AND fev1.MeasurementDate = perc_gp.MeasurementDate
LEFT JOIN perc_sc
ON fev1.PPID = perc_sc.PPID AND fev1.PPIDType = perc_sc.PPIDType AND fev1.MeasurementDate = perc_sc.MeasurementDate
LEFT JOIN perc_sc_bronch
ON fev1.PPID = perc_sc_bronch.PPID AND fev1.PPIDType = perc_sc_bronch.PPIDType AND fev1.MeasurementDate = perc_sc_bronch.MeasurementDate
WHERE MeasurementCode IN ('FEV1', 'FEV1PostBronchodil')
GROUP BY 
	fev1.PPID
	,fev1.PPIDType
	,fev1.MeasurementDate
	,fev1.MeasurementCode
	,fev1.NumericValue
	,fev1.Pathway
	,exp_gp.ExpectedFEV1
	,exp_sc.ExpectedFEV1
	,perc_gp.FEV1PercPred
	,perc_sc.FEV1PercPred
	,perc_sc_bronch.FEV1PercPred
ORDER BY 
	fev1.PPID
	,fev1.MeasurementDate


ALTER TABLE #all_fev1
ADD FEV1PercPred Int NULL
GO

ALTER TABLE #all_fev1
ADD FEV1PPSource VARCHAR(100) NULL
GO


UPDATE #all_fev1
SET FEV1PercPred = FEV1PercPred_GP, FEV1PPSource = 'GP-entered' 
WHERE FEV1Pathway = 'GP' AND FEV1PercPred_GP IS NOT NULL
AND MeasurementCode = 'FEV1'

UPDATE #all_fev1
SET FEV1PercPred = FEV1PercPred_SC, FEV1PPSource = 'RespNet-entered' WHERE 
FEV1PercPred_SC IS NOT NULL AND ((FEV1Pathway = 'GP' AND FEV1PercPred_GP IS NULL) OR FEV1Pathway = 'Secondary Care')
AND MeasurementCode = 'FEV1'

UPDATE #all_fev1
SET FEV1PercPred = FEV1PercPred_SC_bronch, FEV1PPSource = 'RespNet-entered' WHERE 
FEV1PercPred_SC_bronch IS NOT NULL
AND MeasurementCode = 'FEV1PostBronchodil'


UPDATE #all_fev1
SET FEV1PercPred = FEV1 / ExpectedFEV1_GP * 100.0, FEV1PPSource = 'Derived from GP-entered expected FEV1'
WHERE FEV1PercPred IS NULL AND ExpectedFEV1_GP IS NOT NULL AND  
(FEV1Pathway = 'GP' 
	OR (FEV1Pathway = 'Secondary Care' AND ExpectedFEV1_SC IS NULL))
AND FEV1 / ExpectedFEV1_GP * 100.0 BETWEEN 5 AND 200


UPDATE #all_fev1
SET FEV1PercPred = FEV1 / ExpectedFEV1_SC * 100.0, 
FEV1PPSource = 'Derived from RespNet-entered expected FEV1' WHERE FEV1PercPred IS NULL AND ExpectedFEV1_SC IS NOT NULL 
AND FEV1 / ExpectedFEV1_SC * 100.0 BETWEEN 5 AND 200

-- finish working out closest height
DROP TABLE IF EXISTS #fev1_pp
;WITH all_height AS (
SELECT 
	fev1.PPID
	,fev1.PPIDType
	,fev1.MeasurementDate
	,height.MeasurementDate AS DateAtHeight
	,NumericValue
	,TextValue
	,ABS(DATEDIFF(Day, fev1.MeasurementDate, height.MeasurementDate)) AS DayDiff
	,ROW_NUMBER() 
		OVER (PARTITION BY fev1.[PPID],fev1.MeasurementDate  
		ORDER BY ABS(DATEDIFF(Day, fev1.MeasurementDate, height.MeasurementDate)) ASC, height.MeasurementDate) AS row_num
	,LEAD(ABS(DATEDIFF(Day, fev1.MeasurementDate, height.MeasurementDate)))
		OVER (PARTITION BY fev1.[PPID],fev1.MeasurementDate 
		ORDER BY ABS(DATEDIFF(Day, fev1.MeasurementDate, height.MeasurementDate)) ASC, height.MeasurementDate) AS laggedDayDiff
	,LEAD(NumericValue)
		OVER (PARTITION BY fev1.[PPID],fev1.MeasurementDate 
		ORDER BY ABS(DATEDIFF(Day, fev1.MeasurementDate, height.MeasurementDate)) ASC, height.MeasurementDate) AS laggedHeight
FROM #all_fev1 fev1
LEFT JOIN RESP_RAW.Measurements AS height
ON fev1.PPID = height.PPID
WHERE 
height.MeasurementCode = 'BodyHeight'
),
closest_height AS (
SELECT
	PPID
	,PPIDType
	,MeasurementDate
	,CASE WHEN laggedDayDiff = DayDiff AND ABS(laggedHeight - NumericValue) <= 0.05 THEN ROUND((NumericValue+laggedHeight)/2.0, 2)
		ELSE NumericValue END AS ClosestHeight
	FROM all_height
	WHERE 
	row_num = 1
	AND
	(TextValue IS NULL OR (TextValue = 'Child at measurement' AND DayDiff <= 30))
	)
SELECT 
	fev1.PPID
	,fev1.PPIDType
	,fev1.MeasurementDate
	,MeasurementCode
	,FEV1
	,FEV1Pathway
	,ExpectedFEV1_GP
	,ExpectedFEV1_SC
	,CASE WHEN Sex = 'M' THEN ROUND(4.3 * ClosestHeight - 0.029 * [REDACTED].AgeInYears(DateOfBirth, fev1.MeasurementDate) - 2.49, 2)
		WHEN Sex = 'F' THEN ROUND(3.95 * ClosestHeight - 0.025 * [REDACTED].AgeInYears(DateOfBirth, fev1.MeasurementDate) - 2.6, 2)
		END AS ExpectedFEV1_derived 
	,FEV1PercPred_GP
	,FEV1PercPred_SC
	,FEV1PercPred
	,FEV1PPSource
	,[REDACTED].AgeInYears(DateOfBirth, fev1.MeasurementDate) AS AgeAtMeasurement
	,Sex
	,ClosestHeight
INTO #fev1_pp
FROM #all_fev1 fev1
INNER JOIN [RESP_RAW].[Diagnoses] AS diag
ON diag.PPID = fev1.PPID AND diag.PPIDType = fev1.PPIDType
LEFT JOIN [RESP_RAW].[Demographics] AS dem
ON dem.PPID = fev1.PPID AND dem.PPIDType = fev1.PPIDType
LEFT JOIN closest_height AS h
ON fev1.PPID = h.PPID AND fev1.PPIDType = h.PPIDType AND fev1.MeasurementDate = h.MeasurementDate
GROUP BY
	fev1.PPID
	,fev1.PPIDType
	,fev1.MeasurementDate
	,MeasurementCode
	,FEV1
	,FEV1Pathway
	,ExpectedFEV1_GP
	,ExpectedFEV1_SC
	,CASE WHEN Sex = 'M' THEN ROUND(4.3 * ClosestHeight - 0.029 * [REDACTED].AgeInYears(DateOfBirth, fev1.MeasurementDate) - 2.49, 2)
		WHEN Sex = 'F' THEN ROUND(3.95 * ClosestHeight - 0.025 * [REDACTED].AgeInYears(DateOfBirth, fev1.MeasurementDate) - 2.6, 2)
		END
	,FEV1PercPred_GP
	,FEV1PercPred_SC
	,FEV1PercPred
	,FEV1PPSource
	,[REDACTED].AgeInYears(DateOfBirth, fev1.MeasurementDate)
	,Sex
	,ClosestHeight


UPDATE #fev1_pp
SET FEV1PercPred = FEV1/ExpectedFEV1_derived * 100.0, FEV1PPSource = 'Derived from expected FEV1 using ERS ''93 formulae'
WHERE FEV1PercPred IS NULL AND ExpectedFEV1_derived IS NOT NULL AND FEV1/ExpectedFEV1_derived * 100.0 BETWEEN 5 AND 200


DELETE FROM RESP_RAW.Measurements WHERE MeasurementCode = 'ExpectedFEV1' AND Source LIKE 'Derived%'
INSERT INTO RESP_RAW.Measurements 
SELECT
	PPID
	,PPIDType
	,MeasurementDate
	,'ExpectedFEV1' AS MeasurementCode
	,'Expected forced expired volume in 1 second' AS MeasurementDescription
	,FEV1Pathway AS Pathway
	,FEV1PPSource AS Source
	,NULL AS TextValue
	,ExpectedFEV1_derived AS NumericValue
	,'L' AS NumericUnit
FROM #fev1_pp
WHERE ExpectedFEV1_derived IS NOT NULL AND FEV1PPSource = 'Derived from expected FEV1 using ERS ''93 formulae'
GROUP BY
	PPID
	,PPIDType
	,MeasurementDate
	,ExpectedFEV1_derived
	,FEV1Pathway
	,FEV1PPSource

DELETE FROM RESP_RAW.Measurements WHERE MeasurementCode IN ('FEV1PercentPredicted', 'FEV1PercentPredictedPostBronchodil') AND Source LIKE 'Derived%'
INSERT INTO RESP_RAW.Measurements
SELECT
	PPID
	,PPIDType
	,MeasurementDate
	,CASE WHEN MeasurementCode = 'FEV1' THEN 'FEV1PercentPredicted' 
		WHEN MeasurementCode = 'FEV1PostBronchodil' THEN 'FEV1PercentPredictedPostBronchodil' END AS MeasurementCode
	,CASE WHEN MeasurementCode = 'FEV1' THEN 'Percent predicted forced expired volume in one second'
		WHEN MeasurementCode = 'FEV1PostBronchodil' THEN 'Percentage predicted forced expiratory volume in 1 second after bronchodilation' 
		END AS MeasurementDescription
	,FEV1Pathway AS Pathway
	,FEV1PPSource AS Source
	,CASE
	WHEN PPID NOT IN (SELECT DISTINCT PPID FROM RESP_RAW.Diagnoses WHERE Condition = 'COPD') 
	THEN 'No known COPD diagnosis'
	WHEN FEV1PercPred >= 80 THEN 'GOLD Stage 1 (Mild)'
	WHEN FEV1PercPred < 80 AND FEV1PercPred >= 50 THEN 'GOLD Stage 2 (Moderate)'
	WHEN FEV1PercPred < 50 AND FEV1PercPred >= 30 THEN 'GOLD Stage 3 (Severe)'
	WHEN FEV1PercPred < 30 THEN 'GOLD Stage 4 (Very severe)'
	END AS TextValue
	,FEV1PercPred AS NumericValue
	,'%' AS NumericUnit
FROM #fev1_pp
WHERE FEV1PercPred IS NOT NULL AND FEV1PPSource NOT IN ('GP-entered', 'RespNet-entered')
GROUP BY
	PPID
	,PPIDType
	,MeasurementDate
	,MeasurementCode
	,FEV1PercPred
	,FEV1Pathway
	,FEV1PPSource

SELECT MeasurementCode, TextValue, COUNT(DISTINCT(PPID)) FROM RESP_RAW.Measurements 
WHERE MeasurementCode IN ('FEV1PercentPredicted', 'FEV1PercentPredictedPostBronchodil') GROUP BY MeasurementCode, TextValue

SELECT MeasurementCode, Pathway, COUNT(*) FROM RESP_RAW.Measurements 
WHERE MeasurementCode IN ('FEV1PercentPredicted', 'FEV1PercentPredictedPostBronchodil') GROUP BY MeasurementCode, Pathway

----- Creating views
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DROP VIEW IF EXISTS [RESP].[Demographics]
GO

CREATE VIEW [RESP].[Demographics]
AS
SELECT 
	PPID
	,PPIDType
	,MonthOfBirth
	,YearOfBirth
	,[DateOfDeath]
	,[MinRegStartDate]
	,[MaxRegEndDate]
	,[GPFollowUpEnd]
	,[Sex]
	,Ethnicity6
	,simd2020v2_sc_quintile
FROM [RESP_RAW].[Demographics]
GO

DROP VIEW IF EXISTS [RESP].[Diagnoses]
GO

CREATE VIEW [RESP].[Diagnoses]
AS
SELECT 
	PPID
	,PPIDType
	,[Condition]
	,[EarliestMention]
	,[EarliestIncidence]
	,[EarliestMentionInPrimaryCare]
	,[EarliestIncidenceInPrimaryCare]
FROM [RESP_RAW].[Diagnoses]
GO

DROP VIEW IF EXISTS [RESP].ConditionEvents
GO

CREATE VIEW [RESP].ConditionEvents
AS
SELECT 
	PPID
	,PPIDType
	,[EventDate]
	,Position
	,[Code]
	,[CodeType]
	,[Description]
	,[Incident]
	,[Prevalent]
	,[Condition]
	,[ConditionSubcategory1]
	,[ConditionSubcategory2]
	,[CodesetVersion]
	,CASE WHEN [Source] LIKE 'SMR%' THEN 'SMR' ELSE [Source] END AS [Source]
	,[Pathway]
FROM [RESP_RAW].ConditionEvents
GO

DROP VIEW IF EXISTS [RESP].[Measurements]
GO

CREATE VIEW [RESP].[Measurements]
AS
SELECT 
	PPID
	,PPIDType
	,[MeasurementDate]
	,[MeasurementCode]
	,[MeasurementDescription]
	,TextValue
	,NumericValue
	,NumericUnit
	,Source
	,Pathway
FROM [RESP_RAW].[Measurements]
GO

DROP VIEW IF EXISTS [RESP].[Medications]
GO

CREATE VIEW [RESP].[Medications]
AS
SELECT 
	PPID
	,PPIDType
	,[PrescribedDate]
	,[PaidDate]
	,[PaidQuantity]
	,[Code]
	,[CodeType]
	,[Description]
	,[ATC]
	,[DrugSubstanceName]
	,[DrugSubstanceStrength]
	,[DrugFormulation]
	,[RouteOfAdministration]
	,[DrugGroup]
	,[DrugSubGroup]
	,[CodesetVersion]
	,Source
	,Pathway
FROM [RESP_RAW].[Medications]
GO

