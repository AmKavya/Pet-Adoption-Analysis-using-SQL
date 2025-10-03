-- Phase 1 Data Explortion [Goal: Understand the basic distribution of animals, adopters, and shelters.]

-- Count of animals by type and gender	
 SELECT animal_type, gender, COUNT(*) AS total
 FROM Animals GROUP BY animal_type, gender;	
--  Dogs vs Cats distribution and gender ratios in shelters

-- Number of animals by status	
 SELECT status, COUNT(*) AS total FROM Animals 
 GROUP BY status 
 ORDER BY FIELD(status,'Available','Adopted','Fostered','Returned','Deceased');	
--  How many animals are available, adopted, fostered, or returned

-- Number of adopters by age group and gender	
 SELECT
 CASE WHEN age < 18 THEN 'Under 18'
 WHEN age BETWEEN 18 AND 25 THEN '18-25'
 WHEN age BETWEEN 26 AND 35 THEN '26-35' 
 WHEN age BETWEEN 36 AND 50 THEN '36-50'
 ELSE '50+' END AS age_group, gender, 
 COUNT(*) AS total FROM Adopters
 GROUP BY age_group, gender;
--  Understand adopter demographics

-- Distribution of animals by source	
 SELECT source, COUNT(*) AS total FROM Animals
 GROUP BY source
 ORDER BY FIELD(source,'Street','Owner Surrender','Pedigree');	
--  How animals enter shelters (majority street vs surrendered vs pedigree)


-- Phase 2 Shelter Capacity & Occupancy [Goal: Identify overcrowded shelters and resource strain.]

-- Shelter occupancy vs capacity	
 SELECT s.shelter_name, c.city_name, s.capacity, 
 COUNT(a.animal_id) AS current_occupancy, 
 ROUND((COUNT(a.animal_id)/s.capacity)*100, 2) AS occupancy_percent 
 FROM Shelters s 
 JOIN City c ON s.city_id = c.city_id 
 LEFT JOIN Animals a ON a.shelter_id = s.shelter_id
 AND a.status IN ('Available','Returned','Fostered')
 GROUP BY s.shelter_id 
 ORDER BY occupancy_percent DESC;
--  Identify shelters near or over capacity

-- Average remaining capacity per city	
 SELECT c.city_name, 
 ROUND(AVG((occ.current_occupancy/s.capacity)*100),2) AS avg_occupancy_percent, 
 ROUND(AVG(((s.capacity-occ.current_occupancy)/s.capacity)*100),2) AS avg_remaining_percent 
 FROM Shelters s 
 JOIN City c ON s.city_id=c.city_id 
 LEFT JOIN (SELECT shelter_id, COUNT(animal_id) AS current_occupancy 
 FROM Animals WHERE status IN ('Available','Returned')
 GROUP BY shelter_id) occ ON s.shelter_id=occ.shelter_id
 GROUP BY c.city_name
 ORDER BY avg_occupancy_percent DESC;	
--  Cities with highest average occupancy → may need extra shelters or resources

-- Shelters likely to face overcrowding soon	
 SELECT c.city_name, s.shelter_name, s.capacity, 
 COUNT(a.animal_id) AS current_animals, 
 ROUND((COUNT(a.animal_id)/s.capacity)*100,2) AS occupancy_percent 
 FROM Shelters s 
 LEFT JOIN Animals a ON s.shelter_id=a.shelter_id AND a.status IN ('Available','Returned') 
 JOIN City c ON s.city_id=c.city_id
 GROUP BY c.city_name, s.shelter_name, s.capacity 
 HAVING occupancy_percent>70
 ORDER BY occupancy_percent DESC;	
--  Prioritize shelters for intervention



-- Phase 3 – Adoption Outcomes [ Goal: Identify patterns in adoption success and speed.]

-- Adoption counts per city and shelter	
 SELECT c.city_name, s.shelter_name, 
 COUNT(a.adoption_id) AS adoption_count FROM Adoptions a 
 JOIN Animals an ON a.animal_id=an.animal_id
 JOIN Shelters s ON an.shelter_id=s.shelter_id
 JOIN City c ON s.city_id=c.city_id 
 GROUP BY c.city_name, s.shelter_name 
 ORDER BY  adoption_count DESC;	
--  Which shelters/cities are most active in adoptions
 
-- Shelter adoption success rates	
 SELECT s.shelter_name, COUNT(a.animal_id) AS total_animals, 
 SUM(CASE WHEN a.status='Adopted' THEN 1 ELSE 0 END) AS adopted_count, 
 ROUND(SUM(CASE WHEN a.status='Adopted' THEN 1 ELSE 0 END)
/COUNT(a.animal_id)*100,2) AS success_percent 
 FROM Animals a 
 JOIN Shelters s ON a.shelter_id=s.shelter_id 
 JOIN City c ON s.city_id=c.city_id 
 GROUP BY s.shelter_id 
 ORDER BY success_percent DESC;	
-- Identify high-performing shelters

-- Average adoption time by animal type	
 SELECT animal_type,
 ROUND(AVG(DATEDIFF(a.adoption_date, an.intake_date)),2) AS avg_adoption_days
 FROM Adoptions a 
 JOIN Animals an ON a.animal_id=an.animal_id 
 GROUP BY animal_type
 ORDER BY avg_adoption_days;	
--  Dogs vs cats adoption speed
 
-- Top adopted breeds	
 SELECT an.animal_type, an.breed,
 COUNT(*) AS adoption_count FROM Adoptions a 
 JOIN Animals an ON a.animal_id=an.animal_id 
 GROUP BY an.animal_type, an.breed
 ORDER BY an.animal_type, adoption_count DESC;	
 
 -- for better view 

SELECT
    -- Dog columns
    MAX(CASE WHEN animal_type = 'Dog' THEN breed END) AS dog_breed,
    MAX(CASE WHEN animal_type = 'Dog' THEN adoption_count END) AS dog_count,
    
    -- Cat columns
    MAX(CASE WHEN animal_type = 'Cat' THEN breed END) AS cat_breed,
    MAX(CASE WHEN animal_type = 'Cat' THEN adoption_count END) AS cat_count
FROM (
    SELECT 
        an.animal_type,
        an.breed,
        COUNT(*) AS adoption_count,
        ROW_NUMBER() OVER (PARTITION BY an.animal_type ORDER BY COUNT(*) DESC) AS rn
    FROM Adoptions a
    JOIN Animals an ON a.animal_id = an.animal_id
    GROUP BY an.animal_type, an.breed
) t
GROUP BY t.rn
ORDER BY t.rn;
--  Breeds most likely to get adopted



-- Phase 4 – Challenges & Returns [Goal: Investigate adoption failures and reasons for returns.]
-- Animals returned with adopter details	
SELECT an.animal_id, an.animal_type, an.breed, an.age, ad.adopter_id, ad.name AS adopter_name,
 s.shelter_name, c.city_name, a.adoption_date, a.returned, a.reason AS return_reason 
 FROM Adoptions a JOIN Animals an ON a.animal_id=an.animal_id 
 JOIN Adopters ad ON a.adopter_id=ad.adopter_id
 JOIN Shelters s ON an.shelter_id=s.shelter_id 
 JOIN City c ON s.city_id=c.city_id 
 WHERE a.returned='TRUE'
 ORDER BY a.adoption_date DESC;
--  Identify returned animals, shelters, and adopters

-- Return rates by breed, age, adopter demographics	
-- by age
SELECT 
    an.animal_type,
    CASE 
        WHEN an.age < 1 THEN 'Puppy/Kitten (<1 yr)'
        WHEN an.age BETWEEN 1 AND 3 THEN 'Young (1-3 yrs)'
        WHEN an.age BETWEEN 4 AND 7 THEN 'Adult (4-7 yrs)'
        ELSE 'Senior (>7 yrs)'
    END AS age_group,
    COUNT(*) AS total_returns,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM Adoptions WHERE returned='TRUE') * 100, 2) AS return_percent
FROM Adoptions a
JOIN Animals an ON a.animal_id = an.animal_id
WHERE a.returned='TRUE'
GROUP BY an.animal_type, age_group
ORDER BY total_returns DESC;

-- by breed
SELECT 
    an.animal_type,
    an.breed,
    COUNT(*) AS total_returns,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM Adoptions WHERE returned='TRUE') * 100, 2) AS return_percent
FROM Adoptions a
JOIN Animals an ON a.animal_id = an.animal_id
WHERE a.returned='TRUE'
GROUP BY an.animal_type, an.breed
ORDER BY total_returns DESC;

-- by reason
SELECT 
    a.reason,
    COUNT(*) AS total_returns,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM Adoptions 
    WHERE returned='TRUE') * 100, 2) AS return_percent
FROM Adoptions a
JOIN Animals an ON a.animal_id = an.animal_id
WHERE a.returned='TRUE'
GROUP BY  a.reason
ORDER BY total_returns DESC;
--  Pinpoint patterns in returns (age, breed)



-- Phase 5 – Special Focus: Street vs Pedigree [Goal: Understand adoption trends for strays (major India problem).]
-- Street vs not street adoption per city	
 SELECT c.city_name, 
 SUM(CASE WHEN a2.source='Street' THEN 1 ELSE 0 END) AS stray_adoptions, 
 SUM(CASE WHEN a2.source='Pedigree' 
or a2.source='Owner Surrender' THEN 1 ELSE 0 END) AS NonStray_adoptions 
 FROM Adoptions a 
 JOIN Animals a2 ON a.animal_id=a2.animal_id 
 JOIN Shelters s ON a2.shelter_id=s.shelter_id 
 JOIN City c ON s.city_id=c.city_id 
 GROUP BY c.city_name 
 ORDER BY stray_adoptions DESC;	
--  Cities adopting more strays vs pedigrees

-- total count of it 
SELECT 
    CASE 
        WHEN an.source = 'Street' THEN 'Stray' 
        ELSE 'Not Stray' 
    END AS animal_status,
    COUNT(*) AS adoption_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM Adoptions) * 100, 2) AS adoption_percent
FROM Adoptions a
JOIN Animals an ON a.animal_id = an.animal_id
GROUP BY animal_status;

-- adoption rate by source type 
SELECT 
    an.animal_type,
    an.source AS source_type,   -- 'Street' or 'Pedigree'
    COUNT(*) AS adoption_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM Adoptions) * 100, 2) AS adoption_percent
FROM Adoptions a
JOIN Animals an ON a.animal_id = an.animal_id
GROUP BY an.animal_type, an.source
ORDER BY an.animal_type, adoption_count DESC;




-- Phase 6 – Advanced Insights & Predictions [Goal: Predict trends and guide strategy.]
-- Predict animals likely to be adopted fast	
 SELECT animal_type, breed, 
 CASE WHEN age<1 THEN 'Puppy/Kitten (<1 yr)' 
 WHEN age BETWEEN 1 AND 3 THEN 'Young (1-3 yrs)'
 WHEN age BETWEEN 4 AND 7 THEN 'Adult (4-7 yrs)' 
 ELSE 'Senior (>7 yrs)' END AS age_group, 
 health_status,  a.vaccinated,a.neutered,
 ROUND(AVG(DATEDIFF(adopt.adoption_date, a.intake_date)),2) AS avg_adoption_days
 FROM Adoptions adopt 
 JOIN Animals a ON adopt.animal_id=a.animal_id
 GROUP BY animal_type, breed, age_group, health_status , a.vaccinated, a.neutered
 ORDER BY avg_adoption_days ASC;	
--  Identify animals most likely to be adopted quickly


-- Predict shelters needing additional staff	
 SELECT s.shelter_name, s.capacity, s.staff_count,
 COUNT(a.animal_id) AS current_animals, 
 ROUND(COUNT(a.animal_id)/s.staff_count,2) AS animals_per_staff
 FROM Shelters s 
 LEFT JOIN Animals a ON s.shelter_id=a.shelter_id 
 AND a.status IN ('Available','Returned') 
 LEFT JOIN Adoptions adopt ON a.animal_id=adopt.animal_id 
 GROUP BY s.shelter_name, s.capacity, s.staff_count
 HAVING animals_per_staff>10 
 ORDER BY animals_per_staff DESC;	
--  Prioritize shelters for staffing/training interventions

-- Compare adoption success: fostered vs direct	
SELECT 
    CASE 
        WHEN a.from_foster = 'TRUE' THEN 'Fostered before Adoption'
        ELSE 'Direct Adoption'
    END AS adoption_path,
    COUNT(*) AS total_adoptions,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM Adoptions) * 100, 2) AS adoption_percent
FROM Adoptions a
GROUP BY adoption_path;
--  Effectiveness of foster programs

-- 3.	Rank adopters by number of adoptions.
SELECT 
    ad.adopter_id,
    ad.name,
    COUNT(adopt.adoption_id) AS total_adoptions,
    dense_rank() OVER (ORDER BY COUNT(adopt.adoption_id) DESC) AS adopter_rank
FROM Adoptions adopt
JOIN Adopters ad ON adopt.adopter_id = ad.adopter_id
GROUP BY ad.adopter_id, ad.name
ORDER BY total_adoptions DESC;



