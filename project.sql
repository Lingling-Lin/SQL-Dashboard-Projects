SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Project_Portfolio.death
WHERE continent IS NOT NULL
ORDER BY 1,2;

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM Project_Portfolio.death
WHERE location = 'China' AND continent IS NOT NULL
ORDER BY 1,2;

-- shows what percentage of population got Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS CasePercentage
FROM Project_Portfolio.death
WHERE location = 'China' AND continent IS NOT NULL
ORDER BY 1,2;

-- country with highest infection rate compare to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS CasePercentage
FROM Project_Portfolio.death
WHERE continent IS NOT NULL
GROUP BY 1,2
ORDER BY CasePercentage DESC;

-- country with highest death count
SELECT location, MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM Project_Portfolio.death
WHERE continent IS NOT NULL
GROUP BY 1
ORDER BY TotalDeathCount DESC;

SELECT continent, MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM Project_Portfolio.death
WHERE (continent IS NOT NULL) OR (continent NOT LIKE ' ')
GROUP BY 1
ORDER BY TotalDeathCount DESC;

-- showing continnents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM Project_Portfolio.death
WHERE continent IS NOT NULL
GROUP BY 1
ORDER BY TotalDeathCount DESC;

-- Global numbers
SELECT SUM(CAST(new_cases AS SIGNED)) AS total_newcases, SUM(CAST(new_deaths AS SIGNED)), 
		SUM(CAST(new_deaths AS SIGNED))/SUM(CAST(new_cases AS SIGNED))*100 AS DeathPercentage
FROM Project_Portfolio.death
WHERE continent IS NOT NULL;

-- total population vs vaccinations (using CTE) 
WITH popvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
			-- here, order by is important if you want to do cumsum
		SUM(CAST(v.new_vaccinations AS SIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, date) AS RollingPeopleVaccinated
FROM death d
JOIN vaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM popvsVac;


-- total population vs vaccinations (using temp table)
DROP TABLE if exists PercentPopulationVaccinated;
Create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric);

-- the NULLIF function to convert empty strings to NULL, combined with COALESCE to provide a default value if necessary.
INSERT INTO PercentPopulationVaccinated (Continent, location,date, population, new_vaccinations, RollingPeopleVaccinated)
SELECT d.continent, d.location, d.date, d.population, COALESCE(CAST(NULLIF(v.new_vaccinations, '') AS DECIMAL), 0),
		SUM(IFNULL(CAST(NULLIF(v.new_vaccinations, '') AS SIGNED), 0)) OVER (PARTITION BY d.location ORDER BY d.location, date) AS RollingPeopleVaccinated
FROM death d
JOIN vaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT *, (RollingPeopleVaccinated/population)*100 AS new_value
FROM PercentPopulationVaccinated;

-- Creating View to store data for later visualizations(parminent)
Create VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, COALESCE(CAST(NULLIF(v.new_vaccinations, '') AS DECIMAL), 0),
		SUM(IFNULL(CAST(NULLIF(v.new_vaccinations, '') AS SIGNED), 0)) OVER (PARTITION BY d.location ORDER BY d.location, date) AS RollingPeopleVaccinated
FROM death d
JOIN vaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT *
FROM PercentPopulationVaccinated


