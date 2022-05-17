SELECT *
FROM SqlCovid..CovidDeaths
WHERE Continent is not null
ORDER BY 3

--Select data that we are going to use
SELECT location, date, total_cases, new_cases, total_deaths,population
FROM SqlCovid..CovidDeaths
WHERE Continent is not null
ORDER BY 1,2


--Total Cases vs Total Deaths , Shows the likelihood of dying if you contract covid in your country 
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM SqlCovid..CovidDeaths
WHERE location like 'India' and Continent is not null
ORDER BY 1,2

-- Total Cases vs Population, Shows what percentage of population got Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentagePopulationInfected
FROM SqlCovid..CovidDeaths
WHERE Continent is not null
ORDER BY 1,2


--Looking at Countries with Highest Infection Rate compared to Population'
SELECT Location, max(total_cases) as HighestInfectionCount, Population, MAX((total_cases/Population))*100 as PercentagePopulationInfected
FROM SqlCovid..CovidDeaths
--WHERE location like 'India'
GROUP BY Location, Population
ORDER BY PercentagePopulationInfected desc

--Showing Countries with Highest Death Count per Population
SELECT Location, max(cast(Total_deaths as INT)) as TotalDeathCount, MAX((total_deaths/Population))*100 as PercentagePopulationDeath
FROM SqlCovid..CovidDeaths
WHERE Continent is not null
GROUP BY Location
ORDER BY TotalDeathCount desc


-- NOW SHOWING CONTENT BY CONTINENTS

--Continents with highest death count per population
SELECT Continent, max(cast(Total_deaths as INT)) as TotalDeathCount
FROM SqlCovid..CovidDeaths
WHERE Continent is not null    
GROUP BY Continent
ORDER BY TotalDeathCount desc

--GLOBAL NUMBERS

--Number of cases and deaths globally per day
SELECT Date, SUM(new_cases) as Total_cases, SUM(cast(new_deaths as int)) as Total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM SqlCovid..CovidDeaths
WHERE Continent is not null
GROUP BY Date
ORDER BY 1,2

--Total Number of cases and deaths Globally
SELECT SUM(new_cases) as Total_cases, SUM(cast(new_deaths as int)) as Total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM SqlCovid..CovidDeaths
WHERE Continent is not null
ORDER BY 1,2


--JOINING VACCINATION TABLE WITH DEATHS TABLE USING JOIN
--Looking at Total Population vs Vaccination
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_vaccinations,
	SUM(CONVERT(bigint, vac.New_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.Location , dea.Date) as VaccinationCount
FROM SqlCovid..CovidDeaths dea
JOIN SqlCovid..CovidVaccination vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.Continent is not null
ORDER BY 2,3


--USE CTE to show the Population vs Vaccination

with PopvsVac(Continent, Location, Date, Population, New_vaccination, VaccinationCount)  -- No. of Columns in CTE should be same as the original query
as
(
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_vaccinations,
	SUM(CONVERT(bigint, vac.New_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.Location , dea.Date) as VaccinationCount
FROM SqlCovid..CovidDeaths dea
JOIN SqlCovid..CovidVaccination vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.Continent is not null
) 

SELECT *, (VaccinationCount / Population) *100  as VaccinationVsPopulation
FROM PopvsVac


-- We Can do the same by creating a Temporary Table

DROP Table If exists #PercentagePopulationVaccinated     -- This helps in making changes to the same table later
CREATE TABLE #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
VaccinationCount numeric
)

INSERT INTO #PercentagePopulationVaccinated
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_vaccinations,
	SUM(CONVERT(bigint, vac.New_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.Location , dea.Date) as VaccinationCount
FROM SqlCovid..CovidDeaths dea
JOIN SqlCovid..CovidVaccination vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.Continent is not null

SELECT *, (VaccinationCount / Population) *100  as VaccinationVsPopulation
FROM #PercentagePopulationVaccinated


--Creating view to store data for later visualizaitons

CREATE View PercentPopulationVaccinated as
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_vaccinations,
	SUM(CONVERT(bigint, vac.New_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.Location , dea.Date) as VaccinationCount
FROM SqlCovid..CovidDeaths dea
JOIN SqlCovid..CovidVaccination vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.Continent is not null

