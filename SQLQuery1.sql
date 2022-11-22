-- Intro, getting to know our data

SELECT *
FROM PortfolioProject..CovidDeaths
Where continent is not null
Order by 3,4

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
Order by 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in Chile (at 15.11.2022 the chance was 0.431%)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Germany%'
Order by 1,2


-- Looking at Total Cases vs Population 
-- Shows what porcentage of population got covid in Germany (at 15.11.2022 43.32% of the population already got Covid)

SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Germany%'
Order by 1,2


-- Showing Countries with Highest Death Count per Population

SELECT location,  Max (cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Germany%'
Where continent is not null
Group by location
Order by TotalDeathCount desc


-- Lets Break Things Down by Continent

SELECT continent,  Max (cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Germany%'
Where continent is not null
Group by continent
Order by TotalDeathCount desc


-- Join Tables
-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by 
	dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by 2,3

-- Use CTE
With PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by 
	dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3
)
SELECT*, (RollingPeopleVaccinated/population)*100 as 
fROM PopvsVac



-- Temp Table
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)


Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by 
	dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--Where dea.continent is not null
--Order by 2,3


SELECT*, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Creatin View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by 
	dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3

Select*
FROM PercentPopulationVaccinated


-- Global Numbers (	Queries for Tableu)

-- 1. 
SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DetahPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Germany%'
Where continent is not null
--Group by date
Order by 1,2

-- 2.
-- Total deaths by continent

SELECT location,  SUM (cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
Where continent is null
and location not in ('world', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
Group by location
Order by TotalDeathCount desc

-- 3.

-- Looking at Countries with Higest Infection Rate compared to Popupation

SELECT location, population, Max (total_cases) as HighestInfectionCount,	Max((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Germany%'
Group by location, population
Order by PercentPopulationInfected desc

-- 4.

SELECT location, population, date, Max (total_cases) as HighestInfectionCount,	Max((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Germany%'
Group by location, population, date
Order by PercentPopulationInfected desc
