CREATE DATABASE PROJECT

USE PROJECT

select * from encounters

select * from patients

select * from payers

select * from procedures

select * from organizations

SELECT ENCOUNTERCLASS, COUNT(*) AS COUNTS
FROM encounters
GROUP BY ENCOUNTERCLASS
ORDER BY COUNTS DESC;

-- GETTING MAJORITY ENCOUNTERS FROM AMBULATORY CLASS

SELECT * FROM ENCOUNTERS
WHERE BASE_ENCOUNTER_COST IS NULL;

SELECT * FROM ENCOUNTERS
WHERE TOTAL_CLAIM_COST IS NULL;

SELECT * FROM ENCOUNTERS
WHERE PAYER_COVERAGE IS NULL;

ALTER TABLE ENCOUNTERS
ALTER COLUMN BASE_ENCOUNTER_COST float;

ALTER TABLE ENCOUNTERS
ALTER COLUMN total_claim_cost FLOAT;

ALTER TABLE ENCOUNTERS
ALTER COLUMN payer_coverage FLOAT;


SELECT id, SUM(BASE_ENCOUNTER_COST) AS total_cost
FROM encounters
GROUP BY id
ORDER BY total_cost DESC;


-- Objective 1
SELECT 
    e.ReasonCode, REASONDESCRIPTION,
    COUNT(e.Id) AS total_encounters,
    SUM(e.Total_Claim_Cost) AS total_claim_cost,
    SUM(e.Payer_Coverage) AS total_payer_coverage,
    SUM(e.Total_Claim_Cost - e.Payer_Coverage) AS uncovered_cost,
    AVG(DATEDIFF(YEAR, pat.BirthDate, GETDATE())) AS average_patient_age,  -- Average age of patients
    SUM(CASE WHEN pat.Gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN pat.Gender = 'F' THEN 1 ELSE 0 END) AS female_count 
FROM 
    encounters e
JOIN 
    patients pat ON e.Patient = pat.Id  -- Linking encounters to patients
GROUP BY 
    e.ReasonCode, REASONDESCRIPTION
ORDER BY 
    uncovered_cost DESC;


-- THERE ARE BLANK RECORDS IN REASON CODE AND REASON DESCRIPTION JUST FILLING WITH 'UNKNOWN'

UPDATE encounters
SET 
    ReasonCode = 'UNKNOWN',
    ReasonDescription = 'UNKNOWN'
WHERE 
    LTRIM(RTRIM(ReasonCode)) = '' OR LTRIM(RTRIM(ReasonDescription)) = '';


SELECT * FROM encounters

SELECT 
    ReasonCode,
    REASONDESCRIPTION,
    COUNT(Id) AS total_encounters,
    SUM(CASE WHEN ENCOUNTERCLASS = 'AMBULATORY' THEN 1 ELSE 0 END) AS AMBULATORY_COUNT,
    SUM(CASE WHEN ENCOUNTERCLASS = 'OUTPATIENT' THEN 1 ELSE 0 END) AS OUTPATIENT_COUNT,
    SUM(CASE WHEN ENCOUNTERCLASS = 'URGENTCARE' THEN 1 ELSE 0 END) AS URGENTCARE_COUNT,
    SUM(CASE WHEN ENCOUNTERCLASS = 'EMERGENCY' THEN 1 ELSE 0 END) AS EMERGENCY_COUNT,
    SUM(CASE WHEN ENCOUNTERCLASS = 'WELLNESS' THEN 1 ELSE 0 END) AS WELLNESS_COUNT,
    SUM(CASE WHEN ENCOUNTERCLASS = 'INPATIENT' THEN 1 ELSE 0 END) AS INPATIENT_COUNT
FROM 
    encounters 
GROUP BY 
    ReasonCode, 
    REASONDESCRIPTION
ORDER BY 
	total_encounters DESC;


-- OBJECTIVE 2

SELECT 
    Patient, 
    COUNT(Id) AS Num_Encounters, 
    SUM(Total_Claim_Cost) AS Total_Cost,
    SUM(CASE WHEN ENCOUNTERCLASS = 'AMBULATORY' THEN 1 ELSE 0 END) AS AMBULATORY_COUNT,
    SUM(CASE WHEN ENCOUNTERCLASS = 'OUTPATIENT' THEN 1 ELSE 0 END) AS OUTPATIENT_COUNT,
    SUM(CASE WHEN ENCOUNTERCLASS = 'URGENTCARE' THEN 1 ELSE 0 END) AS URGENTCARE_COUNT,
    SUM(CASE WHEN ENCOUNTERCLASS = 'EMERGENCY' THEN 1 ELSE 0 END) AS EMERGENCY_COUNT,
    SUM(CASE WHEN ENCOUNTERCLASS = 'WELLNESS' THEN 1 ELSE 0 END) AS WELLNESS_COUNT,
    SUM(CASE WHEN ENCOUNTERCLASS = 'INPATIENT' THEN 1 ELSE 0 END) AS INPATIENT_COUNT
FROM 
    ENCOUNTERS
WHERE 
    Total_Claim_Cost > 10000 
GROUP BY 
    Patient, YEAR(Start)
HAVING 
    COUNT(Id) > 3


-- OBJECTIVE 3

SELECT e.ReasonCode, e.REASONDESCRIPTION, p.Gender, p.Race, p.Ethnicity, COUNT(e.Id) AS Num_Encounters, AVG(e.Total_Claim_Cost) AS Avg_Claim_Cost
FROM encounters e

JOIN patients p ON e.Patient = p.Id
WHERE e.ReasonCode IN (
        SELECT TOP 3 e2.ReasonCode 
        FROM encounters e2
        
		WHERE e2.ReasonCode IS NOT NULL
        
		GROUP BY e2.ReasonCode
        ORDER BY COUNT(e2.Id) DESC)

GROUP BY 
    e.ReasonCode, e.REASONDESCRIPTION, p.Gender, p.Race, p.Ethnicity;


-- OBJECTIVE 4
SELECT p.Name AS Payer_Name, pr.Code AS Procedure_Code, e.Base_Encounter_Cost, 
e.Total_Claim_Cost, e.Payer_Coverage, (e.Total_Claim_Cost - e.Payer_Coverage) AS Uncovered_Cost
FROM 
encounters e,
procedures pr,
payers p
WHERE 
e.Id = pr.Encounter
AND e.Payer = p.Id 
AND e.Total_Claim_Cost > e.Payer_Coverage;

-- Average of uncovered costs
SELECT AVG(TOTAL_CLAIM_COST - PAYER_COVERAGE) AS AVG_UNCOVERED_COST 
FROM ENCOUNTERS E,
procedures PR,
PAYERS P
WHERE E.ID = PR.ENCOUNTER AND E.PAYER = P.ID AND E.TOTAL_CLAIM_COST > E.PAYER_COVERAGE;

SELECT * FROM procedures

-- OBJECTIVE 5TH

UPDATE procedures
SET 
    ReasonCode = 'UNKNOWN',
    ReasonDescription = 'UNKNOWN'
WHERE 
    LTRIM(RTRIM(ReasonCode)) = '' OR LTRIM(RTRIM(ReasonDescription)) = ''; 

SELECT pr.Patient, pr.ReasonCode, pr.REASONDESCRIPTION, COUNT(DISTINCT pr.Encounter) AS Num_Encounters
FROM procedures pr
WHERE pr.ReasonCode IS NOT NULL 
GROUP BY pr.Patient, pr.ReasonCode, pr.REASONDESCRIPTION
HAVING COUNT(DISTINCT pr.Encounter) > 1
order by Num_Encounters desc; 


-- OBJECTIVE 6 
SELECT o.Name AS Organization_Name, e.EncounterClass, AVG(DATEDIFF(MINUTE, e.Start, e.Stop)) AS Average_Duration_Minutes,
COUNT(CASE WHEN DATEDIFF(MINUTE, e.Start, e.Stop) > 1440 THEN 1 END) AS Exceeding_24_Hours
FROM encounters e

JOIN organizations o ON e.Organization = o.Id  

GROUP BY o.Name, e.EncounterClass
ORDER BY o.Name, e.EncounterClass; 


