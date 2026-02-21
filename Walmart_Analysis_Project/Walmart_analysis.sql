SELECT * FROM walmart;

--
SELECT COUNT(*) FROM walmart;

-- how many distinct payment type we have
SELECT DISTINCT payment_method FROM walmart;

-- how many transaction we have in this distict payment_method?
SELECT 
	payment_method,
	COUNT(*) AS total_transactions
FROM walmart
GROUP BY payment_method;

-- how many total stores we have?

SELECT 
	COUNT(DISTINCT Branch) 
FROM walmart;


-- max quantity
SELECT MAX(quantity) FROM walmart;

-- Business Problems
-- Q.1 What are the different payment methods, and how many transactions and items were sold with each method?
SELECT 
	payment_method,
	COUNT(*) AS total_transactions,
	SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Q.2 Identify the highest-rated category in each branch, displaying the branch, category and AVG rating
SELECT * FROM walmart;

SELECT * FROM
(
SELECT 
	 branch,
	 category,
	 AVG(rating) as Avg_rating,
	 RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank
FROM walmart
GROUP BY 1, 2
)
WHERE rank = 1
;

-- Q.3 Identify the busiest day for each branch based on the number of transactions
SELECT * FROM walmart;

SELECT 
	date,
	TO_CHAR(TO_DATE(date, 'DD/MM/YY'),'Day') as day_name,
	TO_CHAR(TO_DATE(date, 'DD/MM/YY'),'MONTH') as month_name
FROM walmart;

SELECT * 
FROM
(
SELECT
	branch,
	TO_CHAR(TO_DATE(date, 'DD/MM/YY'),'Day') as day_name,
	count(*) AS no_of_transactions,
	RANK() OVER (PARTITION BY branch ORDER BY count(*) DESC) as rank
FROM walmart
GROUP BY 1,2
)
WHERE rank = 1;

-- Q.4 - Calculate Total Quantity Sold by per Payment Method.

SELECT 
	payment_method,
	SUM(quantity) AS total_quantity_sold
FROM walmart
GROUP BY payment_method;

-- Q.5 
-- Determine the average, minimum, and maximum rating of category for each city.
-- List the city, average_rating, min_rating, and max_rating.

SELECT 
	city,
	category,
	AVG(rating) as average_rating,
	MIN(rating) as min_rating,
	MAX(rating) as max_rating
FROM walmart
GROUP BY 1,2;

-- Q. 6
-- Calculate the total profit for  each category by considering total_profit as 
-- (unit_price * quantity * profit_margin). List category and total_profit, ordered from highest to lowest profit.

SELECT * FROM walmart;

SELECT
	category,
	SUM(total) AS total_revenue,
	SUM(total * profit_margin) AS total_profit
FROM walmart
GROUP BY 1
ORDER BY total_profit DESC;


SELECT DISTINCT category FROM walmart;

-- Q.7 
-- Determine the most common payment method for each BRANCH.
-- Display Branch and the preferred_payment_method.

WITH temp_table 
AS 
(SELECT 
	branch,
	payment_method,
	COUNT(*) as total_trans,
	RANK() over(partition by branch ORDER BY COUNT(*)  DESC) as rank
FROM walmart
GROUP BY 1,2
)
SELECT * 
FROM temp_table
WHERE rank = 1;


-- Q.8
-- Categorize sales into 3 group MORNING, AFTERNOON, EVENING 
-- Find out each of the shift and number of invoices

SELECT
	branch,
	CASE 
		WHEN EXTRACT (HOUR FROM (time::time)) < 12 THEN 'Morning'
		WHEN EXTRACT (HOUR FROM (time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
	END AS day_time,
	COUNT(*) AS total_trans
FROM walmart
GROUP BY 1,2
ORDER BY 1, 3 DESC;

-- Q.9
-- Identify 5 branch with highest decrese ratio in 
-- revevenue compare to last year(current year 2023 and last year 2022)

-- rdr == last_rev-cr_rev/ls_rev*100

SELECT *,
	EXTRACT(YEAR FROM TO_DATE(date,'DD/MM/YY')) as Year
FROM walmart;


-- 2022 sales
WITH 

revenue_2022
AS
(
SELECT 
	branch,
	SUM(total) as revenue
FROM walmart
WHERE EXTRACT(YEAR FROM TO_DATE(date,'DD/MM/YY')) = 2022
GROUP BY 1),
revenue_2023
AS
(
SELECT 
	branch,
	SUM(total) as revenue
FROM walmart
WHERE EXTRACT(YEAR FROM TO_DATE(date,'DD/MM/YY')) = 2023
GROUP BY 1
)
SELECT 
	ls.branch,
	ls.revenue as last_year_revenue,
	cs.revenue as current_year_revenue,
	ROUND((ls.revenue - cs.revenue)::numeric*100/ls.revenue::numeric,2)  as rev_dec_ratio
FROM revenue_2022 as ls
JOIN
revenue_2023 as cs
on ls.branch = cs.branch
WHERE ls.revenue > cs.revenue
ORDER BY 4 DESC
LIMIT 5
;