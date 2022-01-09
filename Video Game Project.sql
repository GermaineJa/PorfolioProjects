---Videogame data exploration

Skills used:  CTEs, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

--- Evaluate Dataset( check column formatting, nulls etc.)
select * from vgsales$
--- table countains 16,598 rows
select COUNT(distinct rank) as Disinct
from vgsales$

---Check nulls-The Year column contains 273 rows to be filtered out
	SELECT 
	Rank, Name,Year,genre, publisher, na_sales, eu_sales, jp_sales, other_sales
	FROM vgsales$ 
	WHERE name IS NULL OR year IS NULL OR genre IS NULL OR publisher IS NULL OR na_sales IS NULL OR  eu_sales IS NULL OR jp_sales IS NULL OR  other_sales IS NULL 
	group by Rank, Name,Year,genre, publisher, na_sales, eu_sales, jp_sales, other_sales
	ORDER BY Rank;

SELECT 
	Rank, Name,Year,genre, publisher, na_sales, eu_sales, jp_sales, other_sales
	FROM vgsales$ 
	WHERE name IS NULL OR year IS NULL OR genre IS NULL OR publisher IS NULL OR na_sales IS NULL OR  eu_sales IS NULL OR jp_sales IS NULL OR  other_sales IS NULL;

select COUNT(*)-COUNT(year) AS COUNTOFNULLS
from vgsales$;

--- Dataset will only be evaulated to 2016 as dates after that dont have complete data

Delete from vgsales$ 
 where Year> 2016
select Name, Year 
from vgsales$
where Year > 2016


---There are 33 different platforms, 14 Genres and 580 Publishers being evaluated 
select COUNT(distinct PLATFORM) as PlatformCount, 
Count(distinct Genre) as GenreCount, 
COUNT(distinct Publisher) as PublisherCount
from vgsales$
where Platform is not null or Genre is not null or publisher is not null

--- Reformatted Sales figures to make ready smaller numbers easier and  changed names for some values.
select Rank,Name,
Case 
when Platform ='XB' then 'Xbox'
when Platform ='X360' then 'Xbox360'
when Platform ='PSV' then 'PSVita'
when Platform ='GC' then 'GameCast'
when Platform ='DC' then 'DreamCast'
when Platform ='2600' then 'Atari2600'
else Platform
END as Console
,Year, Genre, Publisher,
Convert(money, Na_Sales)*1000000 as NorthAmerica,
convert(money,Eu_Sales,3)*1000000 as Europe,
coNvert(money,JP_Sales,3)*1000000 as Japan,
convert(money,Other_Sales,3)*1000000 as Other,
convert(money,Global_Sales,3)*1000000 as Global_SalesNew
from vgsales$


-- Put queries in a contained view to operate from
Drop view if exists vgsalesTemp 
go
Create View VGSalesTemp as
(select Rank,Name,
Case 
when Platform ='XB' then 'Xbox'
when Platform ='X360' then 'Xbox360'
when Platform ='PSV' then 'PSVita'
when Platform ='GC' then 'GameCast'
when Platform ='DC' then 'DreamCast'
when Platform ='2600' then 'Atari2600'
else Platform
END as Console
,Year, Genre, Publisher,
Convert(money, Na_Sales)*1000000 as NorthAmerica,
convert(money,Eu_Sales,3)*1000000 as Europe,
coNvert(money,JP_Sales,3)*1000000 as Japan,
convert(money,Other_Sales,3)*1000000 as Other,
convert(money,Global_Sales,3)*1000000 as Global_SalesNew
from vgsales$)

 

--1.what are the number of games released per year?
select distinct Year, 
count(year) as NumberofGamesPerYear
from vgsales$
where Year is not null
Group by year
order by year;

--2.Which region has performed the best in terms of sales?
Select SUM(NorthAmerica) as TotalNASales,
SUM(Europe) as TotalEUSales,
SUM(Japan) AS TotalJPSales,
sum(Other) as OtherSales,
SUM(Global_SalesNew)+sum(Europe)+sum(Japan)+sum(Other) as TotalSales
from VGSalesTemp;

--3.What are the top 10 games currently making the most sales globally?

Select top 10 Name,Year, Global_SalesNew
from VGSalesTemp
order by Global_SalesNew desc

--4.Which are the platforms which made the highest sales for each genre in each region and how much?

With CTE_Consoles as
(select Console,Genre, NorthAmerica, 
row_number() over (partition by Genre order by NorthAmerica desc) as YY,
SUM(NorthAmerica)over (partition by Genre) as TotalSales_NA
from VGSalesTemp
where year is not null)
select Genre, Console, TotalSales_NA from CTE_Consoles
where YY=1
Order by TotalSales_NA desc;

With CTE_Consoles as
(select Console,Genre, Europe, 
row_number() over (partition by Genre order by Europe desc) as YY,
SUM(Europe)over (partition by Genre) as TotalSales_EU
from VGSalesTemp
where year is not null)
select Genre, Console, TotalSales_EU from CTE_Consoles
where YY=1
Order by TotalSales_EU desc;

With CTE_Consoles as
(select Console,Genre, Japan, 
row_number() over (partition by Genre order by Japan desc) as YY,
SUM(Europe)over (partition by Genre) as TotalSales_JP
from VGSalesTemp
where year is not null)
select Genre, Console, TotalSales_JP from CTE_Consoles
where YY=1
Order by TotalSales_JP desc;

With CTE_Consoles as
(select Console,Genre, Other, 
row_number() over (partition by Genre order by Other desc) as YY,
SUM(Other)over (partition by Genre) as TotalSales_Other
from VGSalesTemp
where year is not null)
select Genre, Console, TotalSales_Other from CTE_Consoles
where YY=1
Order by TotalSales_Other desc;

--5.What are the top games for different regions?

select top 5 Name, format(NorthAmerica, 'C') as NA
from VGSalesTemp
order by NorthAmerica desc

select top 5 Name, format(Europe, 'C') as EUR
from VGSalesTemp
order by Europe desc

select top 5 Name, format(Japan, 'C') as JP
from VGSalesTemp
order by Japan desc

select top 5 Name, format(Other, 'C') as Other_
from VGSalesTemp
order by Other desc

--6.What are the top gaming genres that are making high sales?
Select Genre, 
sum(Global_SalesNew) as TotalSales
from VGSalesTemp
where Global_SalesNew is not null
Group by Genre 
order by TotalSales desc

---7.Percentage of sales per console

select Console,(sum(Global_SalesNew)/(select Sum(Global_SalesNew)from VGSalesTemp))*100 as TotalPercentage
from VGSalesTemp
Group by Console 
order by TotalPercentage desc


---8.Evaluate yearly trend for top perfoming game, console, publisher

With CTE_Games as (select Year, name,Console, Publisher,Global_SalesNew,
row_number()over (partition by year order by Global_SalesNew desc) as YY
from VGSalesTemp
where year is not null)
select Year,Name,Global_SalesNew from CTE_Games
where YY = 1
order by Year;


With CTE_Consoles as
(select Year, Console,Global_SalesNew, 
row_number() over (partition by year order by Global_SalesNew desc) as YY,
SUM(Global_SalesNew)over (partition by Year) as TotalSales
from VGSalesTemp
where year is not null)
select Year,Console,TotalSales from CTE_Consoles
where YY=1
Order by Year;

With CTE_Publishers as
(select Year, Publisher,Global_SalesNew, 
row_number() over (partition by year order by Global_SalesNew desc) as YY,
SUM(Global_SalesNew)over (partition by Year) as TotalSales
from VGSalesTemp
where year is not null)
select Year,Publisher,TotalSales from CTE_Publishers
where YY=1
Order by Year;
