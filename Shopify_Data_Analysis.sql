/* 
Shopify Sales Data Exploration

Used on personal business data to determine the following:
	- Best selling product by revenue
	- Year with the highest revenue
	- Shipping cost to sales ratio
	- Customer with highest spend
	- Order count by country
	- Amount of days to fulfill order
	- RFM Analysis (Recency, Frequency, Monetarty) - Index best customers
*/
--- Inspecting Data
select * from [dbo].[shopify_sales];

--- ANALYSIS ---

--- GROUP SALES BY PRODUCT - Find best selling product by revenue
select Lineitem_name, sum(Subtotal) Revenue
from [dbo].[shopify_sales]
group by Lineitem_name
order by Revenue desc;

--- GROUP SALES BY YEAR - Find the year with the highest revenue
select LEFT(Created_at, 4), sum(Subtotal) Revenue
from [dbo].[shopify_sales]
group by LEFT(Created_at, 4)
order by Revenue desc;

--- SHIPPING COST TO SALES RATIO - Measures how much spent to get products to customers relative to revenue
select (sum(Shipping) / sum(Total))Shipping_cost_to_sales_ratio
from [dbo].[shopify_sales]

--- CUSTOMER WITH HIGHEST SPEND - Find which customer spent the most along with total number of orders
select Billing_Name, Count(Name) Number_of_orders, Sum(Total)Revenue
from [dbo].[shopify_sales]
where Billing_Name IS NOT NULL
group by Billing_Name
order by Revenue desc;

--- ORDER COUNT BY COUNTRY - Find which country has the most orders
select DISTINCT Shipping_Country, Count(Name) Number_of_orders
from [dbo].[shopify_sales]
where Shipping_Country IS NOT NULL
Group by Shipping_Country
order by Number_of_orders desc;

--- AMOUNT OF DAYS TO FULFILL ORDER - Find out which orders took the longest to fulfill by amount of days
select Name as Order_number, convert(date,left(Created_at,10), 120) as Order_date, convert(date,left(Fulfilled_at,10), 120) as Fulfillment_date,
DATEDIFF(DD, convert(date,left(Created_at,10), 120), convert(date,left(Fulfilled_at,10), 120)) as Days_to_fulfill
from [dbo].[shopify_sales]
where Created_at IS NOT NULL AND Fulfilled_at IS NOT NULL
order by Days_to_fulfill desc;

--- RFM ANALYSIS - INDEX BEST CUSTOMERS (RECENCY, FREQUENCY, MONETARY)
--- Categorize customers by analyzing recency, frequency and monetary values to index best customers. Can be used to send customers targeted marketing campaigns.
DROP TABLE IF EXISTS #rfm
;with rfm as
(
	select 
		Billing_Name,
		sum(Total) MonetaryValue,
		avg(Total) AvgMonetaryValue,
		count(Name) Frequency,
		max(convert(date,left(Created_at,10), 120)) last_order_date,
		(select max(convert(date,left(Created_at,10), 120)) from [dbo].[shopify_sales]) max_order_date,
		DATEDIFF(DD, max(convert(date,left(Created_at,10), 120)), (select max(convert(date,left(Created_at,10), 120)) from [dbo].[shopify_sales])) Recency
	from [dbo].[shopify_sales]
	where Billing_Name IS NOT NULL
	group by Billing_Name
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
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_cell_string
into #rfm
from rfm_calc c

select Billing_Name, rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112, 113 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost customers' ---Customer's that haven't purchased recently, don't buy frequently and have low spend
		when rfm_cell_string in (133, 134, 143, 242, 243, 244, 334, 343, 344, 144) then 'slipping away' ---Customer's who have high spend but hasn't purchased recently
		when rfm_cell_string in (311, 411, 331) then 'new customers' ---Recent Customers with low spend
		when rfm_cell_string in (221, 222, 223, 233, 322) then 'potential churners' --- Customer's that have potential to be an active customer
		when rfm_cell_string in (323, 324, 333, 321, 422, 332, 431, 432, 433, 434, 443, 444) then 'active' ---Customers who are active and loyal
	end rfm_segment
from #rfm
order by rfm_segment asc