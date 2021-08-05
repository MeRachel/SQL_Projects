CREATE TABLE covid_cases(
iso_code VARCHAR,continent VARCHAR,location_ VARCHAR,date_ VARCHAR,population VARCHAR,
total_cases VARCHAR,new_cases VARCHAR,new_cases_smoothed VARCHAR,total_deaths VARCHAR,
new_deaths VARCHAR,new_deaths_smoothed VARCHAR,total_cases_per_million VARCHAR,
new_cases_per_million VARCHAR,new_cases_smoothed_per_million VARCHAR,
total_deaths_per_million VARCHAR,new_deaths_per_million VARCHAR,
new_deaths_smoothed_per_million VARCHAR,reproduction_rate VARCHAR,icu_patients VARCHAR,
icu_patients_per_million VARCHAR,hosp_patients VARCHAR,hosp_patients_per_million VARCHAR,
weekly_icu_admissions VARCHAR,weekly_icu_admissions_per_million VARCHAR,
weekly_hosp_admissions VARCHAR,weekly_hosp_admissions_per_million VARCHAR
)

COPY covid_cases
FROM 'G:\pgAdmin 4\v5\Covid_Death.csv'
DELIMITER ','
CSV HEADER

SELECT * FROM covid_cases

SELECT location_,date_,total_cases,new_cases,total_deaths,population
FROM covid_cases

ALTER TABLE covid_cases
ALTER COLUMN population SET DATA TYPE BIGINT USING population::BIGINT,
ALTER COLUMN total_cases SET DATA TYPE FLOAT USING total_cases::FLOAT,
ALTER COLUMN new_cases SET DATA TYPE FLOAT USING new_cases::FLOAT,
ALTER COLUMN total_deaths SET DATA TYPE FLOAT USING total_deaths::FLOAT,
ALTER COLUMN new_deaths SET DATA TYPE FLOAT USING new_deaths::FLOAT,
ALTER COLUMN icu_patients SET DATA TYPE FLOAT USING icu_patients::FLOAT

-- Total Cases v/s Total Deaths
SELECT location_,date_,total_cases,total_deaths,population,(total_deaths/total_cases)*100 AS percent_death
FROM covid_cases
WHERE continent is not null

SELECT location_,date_,total_cases,total_deaths,population,(total_deaths/total_cases)*100 AS percent_death
FROM covid_cases
WHERE location_ LIKE '%India'
WHERE continent is not null

--Total Cases v/s Population
SELECT location_,date_,total_cases,population,(total_cases/population)*100 AS percent_cases
FROM covid_cases
WHERE location_ LIKE '%India'
WHERE continent is not null

--Countries with highest Infection rate v/s population
SELECT location_, MAX(total_cases) as Highest_number,population,MAX((total_cases/population))*100 AS Highest_cases_vs_population
FROM covid_cases
WHERE continent is not null
GROUP BY location_,population
ORDER BY Highest_cases_vs_population DESC

--Countries with Highest Death Count
SELECT location_, MAX(total_deaths) as Highest_deaths
FROM covid_cases
WHERE continent is not null
GROUP BY location_
ORDER BY Highest_deaths desc


--Countries with Highest Death Count per population
SELECT location_, MAX(total_deaths) as Highest_deaths,population,MAX((total_deaths/population))*100 AS Highest_deaths_vs_population
FROM covid_cases
WHERE continent is not null
GROUP BY location_,population
ORDER BY Highest_deaths_vs_population asc

-- Highest Deaths per continent
SELECT location_, MAX(total_deaths) as Highest_deaths
FROM covid_cases
WHERE continent is null
GROUP BY location_
ORDER BY Highest_deaths desc

-- Global Information
-- Percent new deaths per new cases
SELECT date_,SUM(new_cases) as total_new_cases, SUM(new_deaths) as total_new_deaths, (SUM(new_deaths)/SUM(new_cases))*100 as percent_new_deaths
FROM covid_cases
WHERE new_cases !=0
GROUP BY date_

-- Percent new deaths per total cases (date-wise)
SELECT date_,SUM(total_cases) as total_new_cases, SUM(new_deaths) as total_new_deaths, (SUM(new_deaths)/SUM(new_cases))*100 as percentage_new_deaths
FROM covid_cases
WHERE new_deaths !=0
GROUP BY date_

--Percent new deaths per total cases (across the globe)
SELECT SUM(total_cases) as total_new_cases, SUM(new_deaths) as total_new_deaths, (SUM(new_deaths)/SUM(new_cases))*100 as percentage_new_deaths
FROM covid_cases
WHERE new_deaths !=0

SELECT * FROM covid_vaccine

ALTER TABLE covid_vaccine
ALTER COLUMN new_tests SET DATA TYPE FLOAT USING new_tests::FLOAT,
ALTER COLUMN total_tests SET DATA TYPE FLOAT USING total_tests::FLOAT,
ALTER COLUMN total_vaccinations  SET DATA TYPE FLOAT USING total_vaccinations::FLOAT,
ALTER COLUMN people_vaccinated SET DATA TYPE FLOAT USING people_vaccinated::FLOAT,
ALTER COLUMN new_vaccinations SET DATA TYPE FLOAT USING new_vaccinations::FLOAT
SELECT * FROM covid_cases cc JOIN covid_vaccine cv
ON cc.location_=cv.location_ 
AND cc.date_=cv.date_

 -- Total Population v/s new vaccination
SELECT cc.continent, cc.location_,cc.date_,cc.population,cv.new_vaccinations 
FROM covid_cases cc JOIN covid_vaccine cv
ON cc.location_=cv.location_ 
AND cc.date_=cv.date_
ORDER BY 2,3

--Total Population v/s Total new vaccinations per date
SELECT cc.continent, cc.location_,cc.date_,cc.population,cv.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION BY cc.location_ ORDER BY cc.location_,cc.date_) as RollingPeopleVaccinated
FROM covid_cases cc JOIN covid_vaccine cv
ON cc.location_=cv.location_ 
AND cc.date_=cv.date_
ORDER BY 2,3

-- Create Temporary Table
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated(
continent VARCHAR,
location_ VARCHAR,
date_ VARCHAR,
population FLOAT,
new_vaccinations FLOAT,
RollingPeopleVaccinated FLOAT	
);
INSERT INTO PercentPopulationVaccinated(
SELECT cc.continent, cc.location_,cc.date_,cc.population,cv.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION BY cc.location_ ORDER BY cc.location_,cc.date_) as RollingPeopleVaccinated
FROM covid_cases cc JOIN covid_vaccine cv
ON cc.location_=cv.location_ 
AND cc.date_=cv.date_
);
SELECT *,(RollingPeopleVaccinated/population)*100 AS PercentVaccination
FROM PercentPopulationVaccinated

--Percentage People Vaccinated
SELECT cc.continent, cc.location_,cc.date_,cc.population,cv.people_vaccinated,
SUM(people_vaccinated) OVER (PARTITION BY cc.location_ ORDER BY cc.location_,cc.date_) as TotalPeopleVaccinated
FROM covid_cases cc JOIN covid_vaccine cv
ON cc.location_=cv.location_ 
AND cc.date_=cv.date_;


DROP TABLE IF EXISTS TotalPercentPopulationVaccinated;
CREATE TABLE TotalPercentPopulationVaccinated(
location VARCHAR,
date VARCHAR,
population FLOAT,
people_vaccinated FLOAT,
TotalPeopleVaccinated FLOAT	
);
INSERT INTO TotalPercentPopulationVaccinated(
SELECT cc.location_,cc.date_,cc.population,cv.people_vaccinated,
MAX(people_vaccinated) OVER (PARTITION BY cc.location_ ORDER BY cc.location_,cc.date_) as TotalPeopleVaccinated
FROM covid_cases cc JOIN covid_vaccine cv
ON cc.location_=cv.location_ 
AND cc.date_=cv.date_
);
SELECT *,(TotalPeopleVaccinated/population)*100 AS TotalPercentVaccination
FROM TotalPercentPopulationVaccinated
GROUP BY location,date,population,people_vaccinated,TotalPeopleVaccinated




--Create View to store data for Visulaisation
CREATE VIEW HighestDeathperConinent AS
SELECT location_, MAX(total_deaths) as Highest_deaths,population,MAX((total_deaths/population))*100 AS Highest_deaths_vs_population
FROM covid_cases
WHERE continent is not null
GROUP BY location_,population
ORDER BY Highest_deaths_vs_population asc

CREATE VIEW PercentagePopulationVaccinated AS
SELECT cc.continent, cc.location_,cc.date_,cc.population,cv.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION BY cc.location_ ORDER BY cc.location_,cc.date_) as RollingPeopleVaccinated
FROM covid_cases cc JOIN covid_vaccine cv
ON cc.location_=cv.location_ 
AND cc.date_=cv.date_;
SELECT *,(RollingPeopleVaccinated/population)*100 AS PercentVaccination
FROM PercentPopulationVaccinated

CREATE VIEW TotalPecentageVaccinated AS
SELECT cc.location_,cc.date_,cc.population,cv.people_vaccinated,
MAX(people_vaccinated) OVER (PARTITION BY cc.location_ ORDER BY cc.location_,cc.date_) as TotalPeopleVaccinated
FROM covid_cases cc JOIN covid_vaccine cv
ON cc.location_=cv.location_ 
AND cc.date_=cv.date_;
SELECT *,(TotalPeopleVaccinated/population)*100 AS TotalPercentVaccination
FROM TotalPercentPopulationVaccinated
GROUP BY location,date,population,people_vaccinated,TotalPeopleVaccinated





 