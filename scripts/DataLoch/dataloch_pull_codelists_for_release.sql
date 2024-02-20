/*--------------------------------------------------------------------------------------
-- Project: 
-------------
DataLoch Respiratory Registry (as part of Respiratory Curation Harmonisation project funded by BREATHE, HDR UK)

-------------
-- Purpose: 
-------------
To pull all respiratory curation-related codelists (see below) together into internal DataLoch database.

Conditions - ILD, COPD, Asthma (Read and ICD-10)
Medications - COPD medications (dm+d and BNF)
Other - ethnicity 

-------------
-- Author: 
-------------
Sara Hatam, DataLoch

-------------
-- Notes:
-------------
To be run before dataloch_master_build_for_release.sql

Paths and databases names have been modified or replaced with [REDACTED] as a 
condition for release to public domain.

NB: This script cannot be run without having internal DataLoch access.
----------------------------------------------------------------------------------------*/

-- Database
USE [REDACTED]

-- Create schema
IF (SCHEMA_ID('Codelist') IS NULL)  
BEGIN 
   	EXEC ('CREATE SCHEMA Codelist')
END; 

-- make sure we have find all the possible ICD-10 codes in the database
-- as some may be missing from PHS that are in NRS deaths
DROP TABLE IF EXISTS #temp_all_icd10_nrs_smr
;SELECT 
	Code
	,CodeType 
	,UPPER([CodeDesc]) AS TargetLevel1
INTO #temp_all_icd10_nrs_smr
FROM 
	[REDACTED].[NRS_DEATH]
WHERE CodeType = 'ICD10'
UNION
SELECT 
	ICD10_CODE AS Code
	,'ICD10' AS CodeType
	,UPPER(ICD10_DESCRIPTION) AS TargetLevel1
FROM 
	[REDACTED].[INTERNAL_ICD10_REF]
ORDER BY Code


/*-------------------------
COPD Read codes
---------------------------*/
DROP TABLE IF EXISTS #copd_read
CREATE TABLE #copd_read
(
medcodeid varchar(100) NULL,
medcode varchar(100) NULL,
snomedctconceptid varchar(100) NULL,
snomedctdescriptionid varchar(100) NULL,
readcode char(7) COLLATE SQL_Latin1_General_CP1_CS_AS NULL,
term varchar(100),
incident bit,
prevalent bit
);

BULK INSERT #copd_read
FROM '[REDACTED]\codelists\definite_copd_incidence_prevalence-aurum_gold_snomed_read.txt'
WITH ( FIRSTROW = 2);

ALTER TABLE #copd_read
DROP COLUMN medcode, medcodeid, snomedctconceptid, snomedctdescriptionid
DELETE FROM #copd_read WHERE readcode =  'NA' OR readcode IS NULL
GO

/*-------------------------
COPD ICD-10 codes
---------------------------*/
DROP TABLE IF EXISTS #copd_icd10
CREATE TABLE #copd_icd10
(
[code] varchar(5),
[description] varchar(76),
[coding_system] varchar(11),
[concept_id] varchar(5),
[concept_version] int,
[concept_name] varchar(85)
);

BULK INSERT #copd_icd10
FROM '[REDACTED]\codelists\PH798-COPD_secondary_care_BREATHE_recommended-C2484_ver_6368_codelist_20230106T095902.csv'
WITH ( FORMAT = 'CSV', FIRSTROW = 2);


/*-------------------------
ILD Read codes
---------------------------*/
DROP TABLE IF EXISTS #ild_read
CREATE TABLE #ild_read
(
medcodeid bigint,
snomedctconceptid bigint,
snomedctdescriptionid bigint,
readcode char(7) COLLATE SQL_Latin1_General_CP1_CS_AS NULL,
term varchar(100),
incident bit,
prevalent bit,
broad_ipf bit,
narrow_ipf bit,
treatment_ild bit,
exposure_ild bit,
autoimmune_ild bit,
other bit
);

BULK INSERT #ild_read
FROM '[REDACTED]\codelists\definite_ild_incidence_prevalence_classification-aurum_snomed_read.txt'
WITH (FIRSTROW = 2);

ALTER TABLE #ild_read
DROP COLUMN medcodeid, snomedctconceptid, snomedctdescriptionid
DELETE FROM #ild_read WHERE readcode =  'NA' OR readcode IS NULL
GO

/*-------------------------
ILD ICD-10 codes
---------------------------*/
DROP TABLE IF EXISTS #ild_icd10
CREATE TABLE #ild_icd10
(
[code] varchar(5),
[codetype] varchar(11),
[description] varchar(200),
broad_ipf bit,
narrow_ipf bit,
treatment_ild bit,
exposure_ild bit,
autoimmune_ild bit,
other bit
);

BULK INSERT #ild_icd10
FROM '[REDACTED]\codelists\ild_classifications-icd10.txt'
WITH (FIRSTROW = 2);


/*-------------------------
Asthma Read codes
---------------------------*/
DROP TABLE IF EXISTS #asthma_read
CREATE TABLE #asthma_read
(
medcodeid bigint,
snomedctconceptid bigint,
snomedctdescriptionid bigint,
readcode char(7) COLLATE SQL_Latin1_General_CP1_CS_AS NULL,
term varchar(100),
incident bit,
prevalent bit,
);

BULK INSERT #asthma_read
FROM '[REDACTED]\codelists\definite_asthma_incidence_prevalence-aurum_snomed_read.txt'
WITH (FIRSTROW = 2);

ALTER TABLE #asthma_read
DROP COLUMN medcodeid, snomedctconceptid, snomedctdescriptionid
DELETE FROM #asthma_read WHERE readcode =  'NA' OR readcode IS NULL
GO

/*-------------------------
Asthma ICD-10 codes
---------------------------*/
DROP TABLE IF EXISTS #asthma_icd10
CREATE TABLE #asthma_icd10
(
[code] varchar(7),
[description] varchar(76),
[coding_system] varchar(11),
[concept_id] varchar(5),
[concept_version] int,
[concept_name] varchar(85)
);

BULK INSERT #asthma_icd10
FROM '[REDACTED]\codelists\PH783-asthma_secondary_care_BREATHE_recommended-C2426_ver_6252_codelist_20230406T141138.csv'
WITH ( FORMAT = 'CSV', FIRSTROW = 2);


/*------------------------------------------
Bring condition codelists into one table
-------------------------------------------*/
-- Now make the table
DROP TABLE IF EXISTS Codelist.Conditions
-- COPD read
SELECT 
	cl.readcode AS Code
	,'Read2' AS CodeType
	,Description
	,Incident
	,Prevalent
	,'COPD' AS Condition
	,NULL AS ConditionSubcategory1
	,NULL AS ConditionSubcategory2
	,'1.0' AS CodesetVersion
INTO Codelist.Conditions
FROM #copd_read AS cl
INNER JOIN [REDACTED].[ReadCodeRef] AS ref
ON ref.FullReadCode COLLATE SQL_Latin1_General_CP1_CS_AS = cl.readcode COLLATE SQL_Latin1_General_CP1_CS_AS
UNION ALL
-- ILD read
SELECT 
	cl.readcode AS Code
	,'Read2' AS CodeType
	,Description
	,Incident
	,Prevalent
	,'ILD' AS Condition
	,CASE 
		WHEN broad_ipf = 1 THEN 'Idiopathic pulmonary fibrosis'
		WHEN treatment_ild = 1 THEN 'Treatment-related' 
		WHEN exposure_ild = 1 THEN 'Exposure-related' 
		WHEN autoimmune_ild = 1 THEN 'Autoimmune-related' 
		WHEN other = 1 THEN 'Other' 
	END AS ConditionSubcategory1
	,CASE WHEN narrow_ipf = 1 THEN 'Narrow IPF'
	ELSE NULL END AS ConditionSubcategory2
	,'1.0' AS CodesetVersion
FROM #ild_read AS cl
INNER JOIN [REDACTED].[ReadCodeRef] AS ref
ON ref.FullReadCode COLLATE SQL_Latin1_General_CP1_CS_AS = cl.readcode COLLATE SQL_Latin1_General_CP1_CS_AS
UNION ALL
-- asthma read
SELECT 
	cl.readcode AS Code
	,'Read2' AS CodeType
	,Description
	,Incident
	,Prevalent
	,'Asthma' AS Condition
	,NULL AS ConditionSubcategory1
	,NULL AS ConditionSubcategory2
	,'1.0' AS CodesetVersion
FROM #asthma_read AS cl
INNER JOIN [REDACTED].[ReadCodeRef] AS ref
ON ref.FullReadCode COLLATE SQL_Latin1_General_CP1_CS_AS = cl.readcode COLLATE SQL_Latin1_General_CP1_CS_AS
UNION ALL
-- COPD icd10
SELECT 
	ref.Code COLLATE SQL_Latin1_General_CP1_CS_AS AS Code
	,'ICD10' AS CodeType
	,TargetLevel1 AS Description
	,1 AS Incident
	,1 AS Prevalent
	,'COPD' AS Condition
	,NULL AS ConditionSubcategory1
	,NULL AS ConditionSubcategory2
	,'1.0' AS CodesetVersion
FROM #copd_icd10 AS cl
INNER JOIN #temp_all_icd10_nrs_smr AS ref
ON ref.Code = REPLACE(cl.Code, '.', '')
UNION ALL
SELECT 
	ref.Code COLLATE SQL_Latin1_General_CP1_CS_AS AS Code
	,'ICD10' AS CodeType
	,TargetLevel1 AS Description
	,1 AS Incident
	,1 AS Prevalent
	,'COPD' AS Condition
	,NULL AS ConditionSubcategory1
	,NULL AS ConditionSubcategory2
	,'1.0' AS CodesetVersion
FROM #copd_icd10 AS cl
INNER JOIN #temp_all_icd10_nrs_smr AS ref
ON ref.Code = CONCAT(REPLACE(cl.Code, '.', ''), 'X')
UNION ALL
-- ILD icd10
SELECT 
	ref.Code COLLATE SQL_Latin1_General_CP1_CS_AS AS Code
	,'ICD10' AS CodeType
	,TargetLevel1 AS Description
	,1 AS Incident
	,1 AS Prevalent
	,'ILD' AS Condition
	,CASE 
		WHEN broad_ipf = 1 THEN 'Idiopathic pulmonary fibrosis'
		WHEN treatment_ild = 1 THEN 'Treatment-related' 
		WHEN exposure_ild = 1 THEN 'Exposure-related' 
		WHEN autoimmune_ild = 1 THEN 'Autoimmune-related' 
		WHEN other = 1 THEN 'Other' 
	END AS ConditionSubcategory1
	,NULL AS ConditionSubcategory2
	,'1.0' AS CodesetVersion
FROM #ild_icd10 AS cl
INNER JOIN #temp_all_icd10_nrs_smr AS ref
ON ref.Code = REPLACE(cl.Code, '.', '')
UNION ALL
SELECT 
	ref.Code COLLATE SQL_Latin1_General_CP1_CS_AS AS Code
	,'ICD10' AS CodeType
	,TargetLevel1 AS Description
	,1 AS Incident
	,1 AS Prevalent
	,'ILD' AS Condition
	,CASE 
		WHEN broad_ipf = 1 THEN 'Idiopathic pulmonary fibrosis'
		WHEN treatment_ild = 1 THEN 'Treatment-related' 
		WHEN exposure_ild = 1 THEN 'Exposure-related' 
		WHEN autoimmune_ild = 1 THEN 'Autoimmune-related' 
		WHEN other = 1 THEN 'Other' 
	END AS ConditionSubcategory1
	,NULL AS ConditionSubcategory2
	,'1.0' AS CodesetVersion
FROM #ild_icd10 AS cl
INNER JOIN #temp_all_icd10_nrs_smr AS ref
ON ref.Code = CONCAT(REPLACE(cl.Code, '.', ''), 'X')
UNION ALL
-- asthma icd10
SELECT 
	ref.Code COLLATE SQL_Latin1_General_CP1_CS_AS AS Code
	,'ICD10' AS CodeType
	,TargetLevel1 AS Description
	,1 AS Incident
	,1 AS Prevalent
	,'Asthma' AS Condition
	,NULL AS ConditionSubcategory1
	,NULL AS ConditionSubcategory2
	,'1.0' AS CodesetVersion
FROM #asthma_icd10 AS cl
INNER JOIN #temp_all_icd10_nrs_smr AS ref
ON ref.Code = REPLACE(cl.Code, '.', '')
UNION ALL
SELECT 
	ref.Code COLLATE SQL_Latin1_General_CP1_CS_AS AS Code
	,'ICD10' AS CodeType
	,TargetLevel1 AS Description
	,1 AS Incident
	,1 AS Prevalent
	,'Asthma' AS Condition
	,NULL AS ConditionSubcategory1
	,NULL AS ConditionSubcategory2
	,'1.0' AS CodesetVersion
FROM #asthma_icd10 AS cl
INNER JOIN #temp_all_icd10_nrs_smr AS ref
ON ref.Code = CONCAT(REPLACE(cl.Code, '.', ''), 'X')
ORDER BY Condition, ConditionSubcategory1, ConditionSubcategory2

/* -------------------------
COPD Medications
----------------------------*/
DROP TABLE IF EXISTS #copd_meds
CREATE TABLE #copd_meds
(
prodcodeid varchar(100),
dmdid varchar(100) NULL,
bnfcode	varchar(100) NULL,
termfromemis varchar(200),	
dmdproductdescription varchar(200) NULL,
bnfname	varchar(200) NULL,
productname	varchar(200) NULL,
dmdlevel varchar(100) NULL,
vpid varchar(100) NULL,
atc	char(7) NULL,
formulation	varchar(100) NULL,
routeofadministration varchar(100) NULL,
drugsubstancename varchar(100) NULL,
substancestrength varchar(100) NULL,	
category varchar(100),
);

BULK INSERT #copd_meds
FROM '[REDACTED]\codelists\copd_medications-aurum_dmd_bnf_atc.txt'
WITH (FIRSTROW = 2);

ALTER TABLE #copd_meds
DROP COLUMN prodcodeid, termfromemis, productname

DELETE FROM #copd_meds WHERE (bnfcode =  'NA' OR bnfcode IS NULL) AND (dmdid =  'NA' OR dmdid IS NULL) 
GO

-- Updating the categories to be more meaningful
UPDATE #copd_meds
SET category = UPPER(category)

UPDATE #copd_meds
SET category = 'Antibiotics' WHERE category = 'abx'

UPDATE #copd_meds
SET category = 'Triple therapy' WHERE category = 'triple'

UPDATE #copd_meds
SET category = 'Theophylline' WHERE category = 'theophylline'

-- We are splitting the codelist into codetypes dm+d and bnf so easy to get either 
DROP TABLE IF EXISTS Codelist.Medications
SELECT 
	dmdid AS Code
	,'dm+d' AS CodeType
	,dmdproductdescription AS Description
	,ATC
	,DrugSubstanceName
	,substancestrength AS DrugSubstanceStrength
	,formulation AS DrugFormulation
	,RouteOfAdministration
	,'COPD' AS DrugGroup
	,category AS DrugSubGroup
	,'1.0' AS CodesetVersion
INTO Codelist.Medications
FROM #copd_meds
WHERE dmdid != 'NA' AND dmdid IS NOT NULL
UNION ALL
SELECT 
	bnfcode AS Code
	,'BNF' AS CodeType
	,bnfname AS Description
	,ATC
	,DrugSubstanceName
	,substancestrength AS DrugSubstanceStrength
	,formulation AS DrugFormulation
	,RouteOfAdministration
	,'COPD' AS DrugGroup
	,category AS DrugSubGroup
	,'1.0' AS CodesetVersion
FROM #copd_meds WHERE bnfcode != 'NA' AND bnfcode IS NOT NULL


/* -------------------------
Ethnicity
----------------------------*/
DROP TABLE IF EXISTS #breathe_ethnicity
CREATE TABLE #breathe_ethnicity
(
medcodeid bigint,
snomedctconceptid bigint,
snomedctdescriptionid bigint,
readcode varchar(20) NULL,
emiscodecategoryid int,
term varchar(200),
hes_ethnicity varchar(20),
Ethnicity6 varchar(20),
EthnicityEngWales2011 varchar(200),
EthnicityEngWales2021 varchar(200),
EthnicityScot2011 varchar(200),
EthnicityNI2011 varchar(200),
EthnicityUK2011 varchar(200)
);

BULK INSERT #breathe_ethnicity
FROM '[REDACTED]\codelists\ethnicity-aurum_snomed_read_hes-breathe.txt'
WITH (FIRSTROW = 2);

DELETE FROM #breathe_ethnicity WHERE readcode = 'NA' OR LEN(readcode) > 7 OR readcode LIKE 'ESC%'

DROP TABLE IF EXISTS Codelist.Ethnicity
SELECT 
EthnicityEngWales2011
,EthnicityScot2011
,EthnicityNI2011
,EthnicityUK2011
,Ethnicity6
INTO Codelist.Ethnicity
FROM #breathe_ethnicity b
INNER JOIN [REDACTED].ReadCodeRef r
ON fullreadcode COLLATE SQL_Latin1_General_CP1_CS_AS = b.readcode COLLATE SQL_Latin1_General_CP1_CS_AS
GROUP BY
EthnicityEngWales2011
,EthnicityScot2011
,EthnicityNI2011
,EthnicityUK2011
,Ethnicity6
ORDER BY Ethnicity6, EthnicityScot2011