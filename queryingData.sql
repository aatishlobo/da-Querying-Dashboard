--- Inspecting Data
select * from [dbo].[sales_data_sample]

--- Checking Unique Values
select distinct status from [dbo].[sales_data_sample]		--- good to plot
select distinct YEAR_ID from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample]	--- good to plot
select distinct	COUNTRY from [dbo].[sales_data_sample]		--- good to plot
select distinct DEALSIZE from [dbo].[sales_data_sample]		--- good to plot
select distinct TERRITORY from [dbo].[sales_data_sample]	--- good to plot

select distinct MONTH_ID from [dbo].[sales_data_sample]		--- checking how many months of operation in 2005
where YEAR_ID = 2005



--- ANALYSIS

--- Grouping sales by product line
select PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc


--- Grouping sales by year
select YEAR_ID, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc


--- Grouping sales by dealsize
select DEALSIZE, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by DEALSIZE
order by 2 desc


--- What was the best month for sales and how much was made in that year?
select MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from [dbo].[sales_data_sample]
where  YEAR_ID = 2004
group by MONTH_ID
order by 2 desc


--- November seems to be the best month : what product do they sell in November?
select MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from [dbo].[sales_data_sample]
where  YEAR_ID = 2004 AND MONTH_ID = 11
group by MONTH_ID, PRODUCTLINE
order by 3 desc



--- Who is our best customer? (RFM Analysis)
;with rfm as
(
	select
		CUSTOMERNAME,
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
		datediff(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
	from [dbo].[sales_data_sample]
	group by CUSTOMERNAME
)
select r.*,
	NTILE(4) OVER (order by Recency) rfm_recency,
	NTILE(4) OVER (order by Frequency) rfm_frequency,
	NTILE(4) OVER (order by AvgMonetaryValue) rrm_monetary
from rfm r
order by 4 desc




--- Using rfm calc as another cte

DROP TABLE IF EXISTS #rfm
;with rfm as
(
	select
		CUSTOMERNAME,
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
		datediff(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
	from [dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as
(
	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select
	*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_cell_string
into #rfm
from rfm_calc


select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  -- lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- big spenders who haven’t purchased lately
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active'								   -- customers who buy often & recently, but at low price points
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm



--- What products are often sold together?
select * from [dbo].[sales_data_sample] where ORDERNUMBER='10265'

select distinct ORDERNUMBER, stuff(
	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] p
	where ORDERNUMBER in
		(
			select ORDERNUMBER
			from(
				select ORDERNUMBER, count(*) rn
				from [dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
	)
	and p.ORDERNUMBER = s.ORDERNUMBER
	for xml path (''))
	, 1, 1, '')

from [dbo].[sales_data_sample] s
order by 2 desc

