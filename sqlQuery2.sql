SELECT * 
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT * 
--FROM PortfolioProject..CovidVaccination
--ORDER BY 3,4

-- SELECT DATA THAT WE ARE GOING TO BE USING
SELECT	location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Total deaths
SELECT location, SUM(CAST(new_deaths as bigint)) as TotaldeathCount
from PortfolioProject..CovidDeaths
where continent is NULL
and location not in ('World', 'European Union', 'International','High income','Upper middle income','Lower middle income','Low income')
group by location
order by TotaldeathCount desc

--TOTAL CASE5S VS TOTAL DEATHS
SELECT	location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 death_per
FROM PortfolioProject..CovidDeaths
where location like 'India'
ORDER BY 1,2

-- TOTAL DEATHS VS POPULATION
SELECT	location, date, total_cases, population,(total_cases/population)*100 cases_per
FROM PortfolioProject..CovidDeaths
where location like 'India'
ORDER BY 1,2

-- Looking at highest infection rates compared to popultion
SELECT	location,population, max(total_cases) max_cases,max((total_cases/population))*100 highest_case_rate
FROM PortfolioProject..CovidDeaths
--where location like 'India'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY highest_case_rate DESC

SELECT	location,population,date, max(total_cases) max_cases,max((total_cases/population))*100 highest_case_rate
FROM PortfolioProject..CovidDeaths
--where location like 'India'
GROUP BY location, population,date
ORDER BY highest_case_rate DESC

-- LOOKING AT HIGHEST DEATH COMPARED TO POPULATION

SELECT	CONTINENT, max(CAST(total_deaths AS INT)) max_death
FROM PortfolioProject..CovidDeaths
--where location like 'India'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY max_death DESC


-- GLOBAL NUMBERS

SELECT  sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,(sum(cast(new_deaths as int))/sum(new_cases))*100 death_per
FROM PortfolioProject..CovidDeaths
where continent IS NOT NULL
ORDER BY 1,2

-- LOOKING AT TOTAL POPULATION VS VACCINATION

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as sum_vac_per_location
  , sum_vac_per_location                  --GIVES ERROR BCZ IT HAS TO ASSOCIATE WITH ONE OF THE TABLE, TO SOLVE THIS WE USE WITH CLAUSE BY SETTING PARAMETERS OF OUR
                                           -- OWN WHICH CAN BE USED MUTIPLE TIMES IN THE QUERY 
FROM PortfolioProject..CovidDeaths death
join PortfolioProject..CovidVaccination vac
on death.location = vac.location
and death.date = vac.date
where death.continent is not null
ORDER BY 2,3

-- WITH CLAUSE
WITH PopulVSVacc (continent, location, date, population, new_vaccinations, sum_vac_per_location)
as
(SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as sum_vac_per_location
FROM PortfolioProject..CovidDeaths death
join PortfolioProject..CovidVaccination vac
on death.location = vac.location
and death.date = vac.date
where death.continent is not null
)
SELECT *, round((sum_vac_per_location/population)*100,5) as percent_vacc
FROM PopulVSVacc

-- TEMPORARY TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
	( Continent nvarchar(255),
	  Location nvarchar(255),
	  Date datetime,
	  Population numeric,
	  new_vaccinations numeric,
	  sum_vac_per_location numeric
)
INSERT INTO #PercentPopulationVaccinated

     SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	        SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as sum_vac_per_location
	FROM PortfolioProject..CovidDeaths death
	join PortfolioProject..CovidVaccination vac
	on death.location = vac.location
	and death.date = vac.date
	where death.continent is not null
	ORDER BY 2,3

	SELECT *, round((sum_vac_per_location/population)*100,5) as percent_vacc
	FROM #PercentPopulationVaccinated

-- CREATING VIEW TO STORE DATA FOR LATER
CREATE VIEW PercentPopulationVaccinated AS
	    SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
				SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as sum_vac_per_location
		FROM PortfolioProject..CovidDeaths death
		join PortfolioProject..CovidVaccination vac
		on death.location = vac.location
		and death.date = vac.date
		where death.continent is not null

		SELECT *
		FROM PercentPopulationVaccinated
	