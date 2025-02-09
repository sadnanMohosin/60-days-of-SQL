select * from data_mart.weekly_sales;--17,117

/*
				Part-1. Data Cleansing Steps
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

1. Convert the week_date to a DATE format
2. Add a week_number as the second column for each week_date value, for example any value from the 1st of January to
	7th of January will be 1, 8th to 14th will be 2 etc
3. Add a month_number with the calendar month for each week_date value as the 3rd column
4. Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
5. Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

		segment		age_band
		1			Young Adults
		2			Middle Aged
		3 or 4		Retirees

6. Add a new demographic column using the following mapping for the first letter in the segment values:

		segment		demographic
		C			Couples
		F			Families
		
7. Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
8. Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record


				Part-2. Data Exploration
1. What day of the week is used for each week_date value?
2. What range of week numbers are missing from the dataset?
3. How many total transactions were there for each year in the dataset?
4. What is the total sales for each region for each month?
5. What is the total count of transactions for each platform
6. What is the percentage of sales for Retail vs Shopify for each month?
7. What is the percentage of sales by demographic for each year in the dataset?
8. Which age_band and demographic values contribute the most to Retail sales?
9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
	If not - how would you calculate it instead?
	
			Part-3. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:

1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
2. What about the entire 12 weeks before and after?
3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?


			Part-4. Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

	1. region
	2. platform
	3. age_band
	4. demographic
	5. customer_type
Do you have any further recommendations for Danny�s team at Data Mart or any interesting insights based off this analysis?
*/


/*
				Part-1. Data Cleansing Steps
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

1. Convert the week_date to a DATE format
2. Add a week_number as the second column for each week_date value, for example any value from the 1st of January to
	7th of January will be 1, 8th to 14th will be 2 etc
3. Add a month_number with the calendar month for each week_date value as the 3rd column
4. Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
5. Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

		segment		age_band
		1			Young Adults
		2			Middle Aged
		3 or 4		Retirees

6. Add a new demographic column using the following mapping for the first letter in the segment values:

		segment		demographic
		C			Couples
		F			Families
		
7. Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
8. Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

*/

select * from data_mart.weekly_sales;


create table data_mart.clean_weekly_sales as 
select 
	week_date,
	date_part('week',week_date) as week_number,
	date_part('month',week_date) as month_number,
	date_part('year',week_date) as calender_year, 
	region,
	platform,
	segment,
	case 
		when segment ilike '%1' then 'Yound Adults' 
		when segment ilike '%2' then 'Middle Aged'
		when segment ilike '%3' or segment ilike '%4' then 'Retirees'
		else 'unknown'
	end as age_band,
	case 
		when segment ilike 'c%' then 'Couples' 
		when segment ilike 'f%' then 'Families'
		else 'unknown'
	end as demographic,
	customer_type,
	transactions,
	sales,
	round(sales/transactions::numeric,2) as  avg_transaction
from 
	(
	select 
		('20'||split_part(week_date,'/',3)||'-'||split_part(week_date,'/',2)||'-'||split_part(week_date,'/',1))::date as week_date,
		region,
		platform,
		case when segment='null' then 'unknown' else segment end as segment,
		customer_type,
		transactions,
		sales
	from data_mart.weekly_sales
	) tbl1
;

select * from data_mart.clean_weekly_sales;



--				Part-2. Data Exploration
--1. What day of the week is used for each week_date value?

select 
	day_of_week,
	count(1) as occurrence
from
(
select 
	week_date,
	to_char(week_date,'Day') as day_of_week
from data_mart.clean_weekly_sales
) tbl1
group by 1;



--2. What range of week numbers are missing from the dataset?
select * from data_mart.clean_weekly_sales;


select 
	distinct week_number
from data_mart.clean_weekly_sales
group by 1
order by 1;

--Answer: Looks like week number 1-12 and 37-52 are missing

--3. How many total transactions were there for each year in the dataset?
select * from data_mart.clean_weekly_sales;

select 
	date_part('year', week_date)::varchar as "Year",
	sum(transactions)/100000 as "Total Transaction (Million)"
from data_mart.clean_weekly_sales
group by 1
order by 1;

--4. What is the total sales for each region for each month?

select 
	date_part('year', week_date)::varchar as "Year",
	sum(sales)/100000000 as "Total Transaction (Billion)"
from data_mart.clean_weekly_sales
group by 1
order by 1;

--5. What is the total count of transactions for each platform
select 
	platform as "Platform",
	count(1) as "Total Transaction Count"
from data_mart.clean_weekly_sales
group by 1
;

--6. What is the percentage of sales for Retail vs Shopify for each month?

select 
	month_name as "Month",
	round(retail_sale/total_sales::numeric*100 ,2) as "Retail Sale (%)",
	round(shopify_sale/total_sales::numeric*100 ,2) as "Shopify Sale (%)"
from 
	(
	select 
		date_trunc('month', week_date)::date as months,
		to_char(date_trunc('month', week_date),'Mon-yyyy') as month_name,
		sum(case when platform='Retail' then sales end) as retail_sale,
		sum(case when platform='Shopify' then sales end) as shopify_sale,
		sum(sales) as total_sales
	from data_mart.clean_weekly_sales
	group by 1,2
	order by 1
	) tbl1
;

--7. What is the percentage of sales by demographic for each year in the dataset?
select 
	"Year",
	round(sale_couples/total_sales::numeric*100 ,2) as "Couples Sale (%)",
	round(sale_families/total_sales::numeric*100 ,2) as "Families Sale (%)",
	round(sale_unknown/total_sales::numeric*100 ,2) as "Unknown Sale (%)"
from 
(
select 
	date_part('year', week_date)::varchar as "Year",
	sum(case when demographic='Couples' then sales end) as sale_couples,
	sum(case when demographic='Families' then sales end) as sale_families,
	sum(case when demographic='unknown' then sales end) as sale_unknown,
	sum(sales) as total_sales
from data_mart.clean_weekly_sales
group by 1
order by 1
) tbl1
;

--8. Which age_band and demographic values contribute the most to Retail sales?
select 
	age_band,
	sum(sales) as total_sales
from data_mart.clean_weekly_sales
where 1=1
and platform='Retail'
and age_band !='unknown'
group by 1
order by 2 desc
;

select 
	demographic,
	sum(sales) as total_sales
from data_mart.clean_weekly_sales
where 1=1
and platform='Retail'
and demographic !='unknown'
group by 1
order by 2 desc
;

--Answer: Retirees contribute most From age_band . Families contribute most From demographic 

--9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
--	If not - how would you calculate it instead?

--Answer: No

select 
	date_part('year', week_date)::varchar as "Year",
	round(sum(case when platform='Retail' then  sales end)/sum(case when platform='Retail' then  transactions end)::numeric,2) as "Avg. transaction size for Retail",
	round(sum(case when platform='Shopify' then  sales end)/sum(case when platform='Shopify' then  transactions end)::numeric,2) as "Avg. transaction size for Shopify"
from data_mart.clean_weekly_sales
group by 1
order by 1
;


/*	
			Part-3. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and 
after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes 
came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and 
the previous week_date values would be before

Using this analysis approach - answer the following questions:

1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual 
values and percentage of sales?
2. What about the entire 12 weeks before and after?
3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
*/

--1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual 
--values and percentage of sales?

select 
	before_change as "Sale before change",
	after_change as "Sale after change",
	before_change-after_change as "Reduction",
	round((before_change-after_change)/before_change::numeric*100,2)||'%' as "Reduction Rate"
from 
(
select 
	sum(case when week_date>='2020-06-15'::date-interval '4 week' and week_date<'2020-06-15' then sales end) as before_change,
	sum(case when week_date>='2020-06-15' and week_date<'2020-06-15'::date+interval '4 week' then sales end) as after_change
from data_mart.clean_weekly_sales
where 1=1
and ((week_date>='2020-06-15'::date-interval '4 week' and week_date<'2020-06-15')
	or  (week_date>='2020-06-15' and week_date<'2020-06-15'::date+interval '4 week'))
) tbl1
;

--2. What about the entire 12 weeks before and after?
select 
	before_change as "Sale before change",
	after_change as "Sale after change",
	before_change-after_change as "Reduction",
	round((before_change-after_change)/before_change::numeric*100,2)||'%' as "Reduction Rate"
from 
(
select 
	sum(case when week_date>='2020-06-15'::date-interval '12 week' and week_date<'2020-06-15' then sales end) as before_change,
	sum(case when week_date>='2020-06-15' and week_date<'2020-06-15'::date+interval '12 week' then sales end) as after_change
from data_mart.clean_weekly_sales
where 1=1
and ((week_date>='2020-06-15'::date-interval '12 week' and week_date<'2020-06-15')
	or  (week_date>='2020-06-15' and week_date<'2020-06-15'::date+interval '12 week'))
) tbl1
;



--select 
--	distinct week_date
--from data_mart.clean_weekly_sales
--where 1=1
--and (	(week_date>='2020-06-15' and week_date<'2020-06-15'::date+interval '12 week')
--			or (week_date>'2019-09-02'::date- interval '12 week' and week_date<='2019-09-02')
--			or (week_date>'2018-09-03'::date- interval '12 week' and week_date<='2018-09-03')
--		)
--;
--
--select 
--	distinct week_date
--from data_mart.clean_weekly_sales
--where date_part('year', week_date)=2019
--;

--3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

-- comparison of before change period of 2020 with similar period of 2018 and 2019
select 
	before_change_2020 as "Sale 2020 (before change)",
	similar_weeks_2019 as "Sale 2019 (similar week)",
	before_change_2020-similar_weeks_2019 as "Increase in 2020",
	round((before_change_2020-similar_weeks_2019)/similar_weeks_2019::numeric*100,2)||'%' as "Increase Rate",
	similar_weeks_2018 as "Sale 2018 (similar week)",
	before_change_2020-similar_weeks_2018 as "Increase in 2020",
	round((before_change_2020-similar_weeks_2018)/similar_weeks_2018::numeric*100,2)||'%' as "Increase Rate"
from 
	(
	select 
		sum(case when week_date>='2020-06-15'::date-interval '12 week' and week_date<'2020-06-15' then sales end) as before_change_2020,
		sum(case when week_date>='2019-03-25' and week_date<'2019-03-25'::date+interval '12 week' then sales end) as similar_weeks_2019,
		sum(case when week_date>='2018-03-26' and week_date<'2018-03-26'::date+interval '12 week' then sales end) as similar_weeks_2018
	from data_mart.clean_weekly_sales
	where 1=1
	and (	(week_date>='2020-06-15'::date-interval '12 week' and week_date<'2020-06-15')
			or (week_date>='2019-03-25' and week_date<'2019-03-25'::date+interval '12 week')
			or (week_date>='2018-03-26' and week_date<'2018-03-26'::date+interval '12 week')
		)
	) tbl1
;

-- comparison of after change period of 2020 with similar period of 2018 and 2019
select 
	after_change_2020 as "Sale 2020 (after change)",
	similar_weeks_2019 as "Sale 2019 (similar week)",
	after_change_2020-similar_weeks_2019 as "Increase in 2020",
	round((after_change_2020-similar_weeks_2019)/similar_weeks_2019::numeric*100,2)||'%' as "Increase Rate",
	similar_weeks_2018 as "Sale 2018 (similar week)",
	after_change_2020-similar_weeks_2018 as "Increase in 2020",
	round((after_change_2020-similar_weeks_2018)/similar_weeks_2018::numeric*100,2)||'%' as "Increase Rate"
from 
	(
	select 
		sum(case when week_date>='2020-06-15' and week_date<'2020-06-15'::date+interval '12 week' then sales end) as after_change_2020,
		sum(case when week_date>'2019-09-02'::date- interval '12 week' and week_date<='2019-09-02' then sales end) as similar_weeks_2019,
		sum(case when week_date>'2018-09-03'::date- interval '12 week' and week_date<='2018-09-03' then sales end) as similar_weeks_2018
	from data_mart.clean_weekly_sales
	where 1=1
	and (	(week_date>='2020-06-15' and week_date<'2020-06-15'::date+interval '12 week')
			or (week_date>'2019-09-02'::date- interval '12 week' and week_date<='2019-09-02')
			or (week_date>'2018-09-03'::date- interval '12 week' and week_date<='2018-09-03')
		)
	) tbl1
;

