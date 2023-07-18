/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Use [Portfolio Project]
--select * from CovidDeaths ORDER BY 3,4
--select * from [dbo].[CovidVaccination] ORDER BY 3,4

Select location,date,total_cases,new_cases,total_deaths,population
from [dbo].[CovidDeaths] 
order by location,date

select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='CovidDeaths'

-- Total Cases vs Total Deaths
--Shows the likelihood of dying if you get Covid in India
Select location,date,total_cases,new_cases,total_deaths,((total_deaths/total_cases)* 100)as Death_Percentage 
from [dbo].[CovidDeaths] 
where location like '%India%'
order by location,date

Alter table [dbo].[CovidDeaths]
alter column total_cases decimal(20,10)

--Total Cases per population 
-- Shows what percentage of population infected with Covid
Select location,date, total_cases,population, ((total_cases/Population)*100) as Chance_of_getting_Covid
from CovidDeaths
where location like '%states%'
order by location,date

Select location,date, population, total_cases,((total_cases/Population)*100) as Chance_of_getting_Covid
from CovidDeaths
--where location like '%India%'
order by Chance_of_getting_Covid desc

--Looking at countries with high infection rate compared to Population 
Select location, Population, MAX(total_cases) as Highest_Infection_Count,(((MAX(total_cases))/Population)*100) as Percent_Population_Infected
from CovidDeaths
group by location,population
order by 4

--Looking at countries with high infection rate compared to Population 
--Select location, MAX(CAST(Population as bigint)), MAX(total_cases) as Highest_Infection_Count,(((MAX(total_cases))/Population)*100) as Percent_Population_Infected
--from CovidDeaths
--group by location
--order by 4

--Countries with High Death Count per population 
Select location, Max(Population), MAX(total_deaths) as Highest_Death_Count,(((MAX(total_deaths))/Max(Population))*100) as Percent_Population_Died
from CovidDeaths
group by location
order by 4 desc

-- BREAKING THINGS DOWN BY CONTINENT
--Continents with High Death Count 
Select continent ,MAX(total_deaths) as Total_Death_Count
from CovidDeaths
where continent is not NULL
group by continent
order by Total_Death_Count desc


Select * from [dbo].[CovidDeaths] where location='World' 
select distinct new_cases,new_deaths from CovidDeaths

--Global numbers
select SUM(new_cases) as Total_Cases, SUM(new_deaths) as Total_Deaths,
SUM(cast(new_deaths as decimal))/sum(cast(new_cases as decimal))*100 as Death_Percentage 
from [dbo].[CovidDeaths]
where continent is not Null 
--group by date
order by 1,2


select * from CovidVaccination

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
	
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over ( Partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
from CovidDeaths dea
join CovidVaccination vac
on dea.location= vac.location
and dea.date= vac.date
where dea.continent is not null
order by 2,3

select date, location, new_cases, SUM(new_cases) over ( Partition by location order by location,date) as Rolling_cases from CovidDeaths 
select * from CovidDeaths

--Creating a Comman Table Expression (CTE) to perform Calculation on Partition By in previous query
With PopVsVac (Continent, location,date,population,new_vaccination, Rolling_People_Vaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over ( Partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
from CovidDeaths dea
join CovidVaccination vac
on dea.location= vac.location
and dea.date= vac.date
where dea.continent is not null
--order by 2,3
)
select *, (convert(decimal,Rolling_People_Vaccinated)/Convert(decimal,Population))*100 as Percentage_Vaccinated 
from PopVsVac

--Creating a Temp Table to perform Calculation on Partition By in previous query
use [Portfolio Project]
DROP Table if exists #Population_Vaccinated 
Create table #Population_Vaccinated 
(continent Varchar(50), location Varchar(50),date date, 
Population NUMERIC,
new_vaccination NUMERIC,
Rolling_People_Vaccinated NUMERIC
)
Insert into #Population_Vaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over ( Partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
from CovidDeaths dea
join CovidVaccination vac
on dea.location= vac.location
and dea.date= vac.date
--where dea.continent is not null
--order by 2,3
select * from #Population_Vaccinated


Select *, (Rolling_People_Vaccinated/Population)*100
From #Population_Vaccinated

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Cretaing view to store data for later visualization 

Drop view if exists PercentPopulationVaccinated
create view PercentPopulationVaccinated as

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(numeric,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

select * from  PercentPopulationVaccinated
