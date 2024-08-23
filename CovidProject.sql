Select *
from CovidProject..CovidDeaths$
Where location like '%states%'
order by 3,4

--Select *
--from CovidProject..CovidVax$
--order by 3,4

-- Selecting the Data I will be using 

Select Location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths$
order by 1,2

--Total Cases vs Total Deaths
Select iso_code, Location, date, total_cases, total_deaths,
Case --can't divide by 0
	when total_cases <> 0 then (total_deaths/total_cases) * 100
	Else 0
end as DeathPercentage
from CovidDeaths$
where iso_code like '%USA%'
order by 2,3

--Total cases vs Population 
--Shows % of pop got covid
Select iso_code, Location, date, total_cases, Population, (total_cases/population) * 100 as InfectedPopPercent 
from CovidDeaths$
--where iso_code like '%USA%'
order by 2,3

--Infection Rates 
--Which country had the highest infection rate compared to population
Select location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population)) * 100 as InfectedPopPercent
from CovidDeaths$
Group by location, population
order by InfectedPopPercent desc

--Countries with highest death count
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
Group by location
order by TotalDeathCount desc

Select location, continent, MAX(total_deaths) as TotalDeathCount
from CovidDeaths$
where continent is NOT NULL
Group by location, continent
order by TotalDeathCount desc

--Highest death count each continent saw
Select continent, MAX(total_deaths) as TotalDeathCount
from CovidDeaths$
where continent is NOT NULL
Group by continent
order by TotalDeathCount desc

--Total death count for entire continent 
Select continent, SUM(new_deaths) as TotalDeathCount
from CovidDeaths$
Where continent is NOT NULL
Group by continent
Order by TotalDeathCount desc

Select location, MAX(total_deaths) as TotalDeathCount 
from CovidDeaths$
where continent is NULL
group by location
order by TotalDeathCount desc

--AlexTheAnalyst's Query (Using for sake of following along)
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is NOT NULL
Group by continent
order by TotalDeathCount desc

--Global Numbers
Select date, SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, 
CASE
	when SUM(new_cases) <> 0 then SUM(new_deaths)/SUM(new_cases) * 100
END as DeathPercentage
from CovidDeaths$
where continent is not null
group by date
order by 1,2

Select SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, 
CASE
	when SUM(new_cases) <> 0 then SUM(new_deaths)/SUM(new_cases) * 100
END as DeathPercentage
from CovidDeaths$
where continent is not null
order by 1,2


--Total population vs Vaccinations 
Select dea.continent, dea.date, dea.location, dea.population, vax.new_vaccinations, SUM(cast(vax.new_vaccinations as bigint)) OVER (Partition by dea.location) as TotalVaxCount--want the count to start over when it reaches a new location 
from CovidDeaths$ dea
join CovidVax$ vax
	ON dea.location = vax.location 
	and dea.date = vax.date
	where dea.continent is not null
order by 2,3

Select dea.continent, dea.date, dea.location, dea.population, vax.new_vaccinations, SUM(Convert(bigint, vax.new_vaccinations)) OVER (Partition by dea.location Order by dea.date) as TotalVaxCount --want the count to start over when it reaches a new location 
from CovidDeaths$ dea
join CovidVax$ vax
	ON dea.location = vax.location 
	and dea.date = vax.date
	where dea.continent is not null
order by 2,3

--Using CTE to find percentage of population vaccinated 
With PopvsVAX (Continent, Location, Date, Population, new_vaccinations, TotalVaxCount)
as
(Select dea.continent, dea.date, dea.location, dea.population, vax.new_vaccinations, SUM(Convert(bigint, vax.new_vaccinations)) OVER (Partition by dea.location Order by dea.date) as TotalVaxCount --want the count to start over when it reaches a new location 
from CovidDeaths$ dea
join CovidVax$ vax
	ON dea.location = vax.location 
	and dea.date = vax.date
	where dea.continent is not null
)
Select *, (TotalVaxCount/Population) * 100
from PopvsVAX

--Using a temp table 
Drop Table if exists #PercentPopVaxed
Create Table #PercentPopVaxed
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
TotalVaxCount numeric
)

Insert into #PercentPopVaxed
Select dea.continent, Convert(date, dea.date) as Date, dea.location, dea.population, vax.new_vaccinations, SUM(Convert(bigint, vax.new_vaccinations)) OVER (Partition by dea.location Order by Convert(date, dea.date)) as TotalVaxCount --want the count to start over when it reaches a new location 
from CovidDeaths$ dea
join CovidVax$ vax
	ON dea.location = vax.location 
	and Convert(date, dea.date) = Convert(date, vax.date)
	where dea.continent is not null

Select *, (TotalVaxCount/Population) * 100
from #PercentPopVaxed

--Creating view to store data for later visualization
Create View PercentPopVaxed as
Select dea.continent, dea.date, dea.location, dea.population, vax.new_vaccinations, SUM(Convert(bigint, vax.new_vaccinations)) OVER (Partition by dea.location Order by dea.date) as TotalVaxCount --want the count to start over when it reaches a new location 
from CovidDeaths$ dea
join CovidVax$ vax
	ON dea.location = vax.location 
	and dea.date = vax.date
where dea.continent is not null

Select *
from PercentPopVaxed
