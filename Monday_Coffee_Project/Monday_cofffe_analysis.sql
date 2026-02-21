 -- Monday Coffee -- Data Analysis

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports and Data Analysis
-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	round((population * 0.25)/1000000,2) AS coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY population DESC;

-- Q.2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
	SUM(total) AS total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date) = 2023 
	AND 
	EXTRACT(QUARTER FROM sale_date) = 4;


SELECT * FROM sales;

SELECT 
	ci.city_name,
	SUM(s.total) AS total_revenue
FROM sales as s
JOIN customers as c
on s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date) = 2023 
	AND 
	EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY 2 DESC;

-- Q.3 Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT p.product_name,
	COUNT(s.sale_id) as total_units_sold
FROM products AS p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;


-- Q.4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city, total_sales, number_of_customer

SELECT 
	ci.city_name,
	SUM(s.total) AS total_revenue,
	COUNT(DISTINCT c.customer_id) as total_cus,
	ROUND((sum(s.total)/COUNT(DISTINCT c.customer_id))::"numeric",2) AS Avg_Sale_per_cus
FROM sales as s
JOIN customers as c
on s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id


GROUP BY ci.city_name
ORDER BY 2 DESC;


-- Q.5 City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total_current_cx, estimated coffee consumers(25%)

WITH city_table AS
(SELECT 
	city_name,
	round((population * 0.25) / 1000000,2) AS coffee_consumers_in_millions
FROM city
),
customers_table 
AS
(SELECT
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_customers
FROM sales as s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
)
SELECT 
	cit.city_name,
	cit.coffee_consumers_in_millions AS estimated_coffee_cunsumers,
	ct.unique_customers
FROM city_table  as cit
JOIN
customers_table as ct
ON ct.city_name = cit.city_name;


-- Q.6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
-- city_name,product_name,sales_volume
SELECT * 
FROM
(
SELECT 
	ci.city_name,
	p.product_name,
	count(s.sale_id) as total_orders,
	DENSE_RANK() OVER(partition by ci.city_name ORDER BY count(s.sale_id) DESC) as rank
FROM sales as s
JOIN 
products as p
ON s.product_id = p.product_id
JOIN customers as c
ON c.customer_id = s.customer_id
 
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1, 2
--ORDER BY 1, 3
) AS  t1

WHERE rank <= 3;

-- Q.7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT * FROM products;

SELECT 
	ci.city_name,
	count(distinct c.customer_id) as unique_cx
FROM sales as s
JOIN customers as c
on s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1;

-- Q.8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH
City_table AS
(
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) AS total_unique_cx,
	ROUND(SUM(s.total)::"numeric"/COUNT(DISTINCT s.customer_id)::"numeric",2) AS Avg_Sale_per_customer
FROM sales as s
JOIN customers as c
on s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2
),

city_rent AS
(
SELECT city_name,estimated_rent
FROM city
)

SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_unique_cx,
	ct.Avg_Sale_per_customer,
	ROUND(cr.estimated_rent::numeric/ct.total_unique_cx::numeric,2)AS Avg_rent_per_cust
	
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC;

SELECT * FROM city;


-- Q.9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
-- by each city

WITH 
month_sales 
AS
(
SELECT 
	ci.city_name,
	EXTRACT(MONTH FROM s.sale_date) as month,
	EXTRACT(YEAR FROM s.sale_date) as year,
	SUM(s.total) as total_sale
FROM sales as s
JOIN customers as c 
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1, 2 ,3
ORDER BY 1, 3, 2 
),
growth_ratio
AS
(
SELECT 
	city_name,
	month,
	year,
	total_sale as current_month_sale,
	LAG(total_sale,1) OVER(partition by city_name order by year,month) as last_month_sale
FROM month_sales
)

SELECT 
	city_name,
	month,
	year,
	current_month_sale,
	last_month_sale,
	ROUND(((current_month_sale-last_month_sale)::numeric/last_month_sale::numeric) * 100,2) AS growth_rate_percent
FROM growth_ratio
WHERE last_month_sale is not null


-- Q.10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH
City_table AS
(
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) AS total_unique_cx,
	ROUND(SUM(s.total)::"numeric"/COUNT(DISTINCT s.customer_id)::"numeric",2) AS Avg_Sale_per_customer
FROM sales as s
JOIN customers as c
on s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2
),

city_rent AS
(
SELECT 
	city_name,
	estimated_rent,
	ROUND((population * 0.25)/1000000::numeric,2) as estimated_coffee_consumer_in_ml
FROM city
)

SELECT 
	cr.city_name,
	total_revenue AS total_sales,
	cr.estimated_rent as total_rent,
	ct.total_unique_cx,
	cr.estimated_coffee_consumer_in_ml,
	ct.Avg_Sale_per_customer,
	ROUND(cr.estimated_rent::numeric/ct.total_unique_cx::numeric,2)AS Avg_rent_per_cust
	
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;

/*
-- Recommendations
City 1: Pune
		1. Avg rent per customer is less than Rs 500 which is Rs 294.23, 
		2. highest total revenue,
		3. avg_sale_per_customer is also high

City 2: Delhi
		1. very high estimated_coffee_consumer_in_mil, which is 7.75 million
		2. total_unique_customers is also very high which is 68, this has the potential for the future
		3. Avg rent per customer is(still less than Rs 500) which is Rs 330.88

City 3: Jaipur
		1. highest numeber of unique customers which is 69.
		2. avg_rent_per_customer is very less which is Rs.156.52
		3. Avg_sale_per_customer_is  at top 4 ahich is 11644.20.

*/


