/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Inspecting Data
select * 
from [dbo].[CovidDeaths]
where continent IS NOT NULL
order by 3,4

select Location, date, total_cases, new_cases, total_deaths, population 
from [dbo].[CovidDeaths]
where continent IS NOT NULL
order by 1,2

-- Total Cases versus Total Deaths 
-- Likelihood of dying if you contract covid in Canada
select Location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as DeathPercentage
from [dbo].[CovidDeaths]
where location = 'Canada' and continent IS NOT NULL
order by 1,2

-- Total Cases versus Population 
-- Percentage of Population that contracted covid in Canada
select Location, date, population, total_cases, (total_cases / population)*100 as ContractedPercentage
from [dbo].[CovidDeaths]
where location = 'Canada' and continent IS NOT NULL
order by 1,2

-- Countries with Highest Infection Rate compared to Population
select Location, population, max(total_cases) as HighestInfectionCount, max((total_cases / population))*100 as ContractedPercentage
from [dbo].[CovidDeaths]
where continent IS NOT NULL
group by Location, population
order by ContractedPercentage desc

--Countries with the Highest Death Count
select Location, max(total_deaths*100) as TotalDeathCount
from [dbo].[CovidDeaths]
where continent != 'World'
group by Location
order by TotalDeathCount desc

-- CONTINENTAL NUMBERS --

-- Continents with the Highest Death Count
select continent, max(total_deaths*100) as TotalDeathCount
from [dbo].[CovidDeaths]
where continent IS  NOT NULL
group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS --

-- Total Cases, Deaths and Death Percentage by date
select date, sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(new_deaths as int))/sum(new_cases) * 100 as DeathPercentage
from [dbo].[CovidDeaths]
where continent IS NOT NULL
group by date
order by 1, 2

-- Total Cases, Deaths and Death Percentage 
select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(new_deaths as int))/sum(new_cases) * 100 as DeathPercentage
from [dbo].[CovidDeaths]
where continent IS NOT NULL
order by 1, 2

-- Inspecting Covid Vaccinations
select * 
from [dbo].[CovidVaccinations]
order by 3,4

-- Total Population versus Vaccinations
-- Percentage of Population that has been Vaccinated

-- Using CTE to perform Calculation on Partition in previous query

With PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinationCount)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location, dea.Date) as RollingVaccinationCount
from [dbo].[CovidDeaths] dea
join [dbo].[CovidVaccinations] vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent IS NOT NULL
)
select *, (RollingVaccinationCount / population) * 100 from PopvsVac

-- Using Temp Table to perform Calculation on Partition in previous query
DROP Table if exists #PercentPopulationVaccinated;
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
RollingVaccinationCount numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location, dea.Date) as RollingVaccinationCount
from [dbo].[CovidDeaths] dea
join [dbo].[CovidVaccinations] vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent IS NOT NULL

select *, (RollingVaccinationCount / population) * 100 
from #PercentPopulationVaccinated

-- Creating view for later visulizations

Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location, dea.Date) as RollingVaccinationCount
from [dbo].[CovidDeaths] dea
join [dbo].[CovidVaccinations] vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent IS NOT NULL
