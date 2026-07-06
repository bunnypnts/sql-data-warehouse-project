--Change over time analysis

SELECT 
	YEAR(order_date) as order_year,
	MONTH(order_date) as order_month,
	SUM(sales_amount) as total_sales,
	COUNT(DISTINCT customer_key) as total_customers
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY YEAR(order_date), month(order_date)
	ORDER BY YEAR(order_date) ,month(order_date)

--Cumulative Analysis

--Calculate the total sales per month and the running total of sales over time

SELECT 
	order_date,
	total_sales,
	SUM(total_sales) OVER (ORDER BY order_date) as running_total_sales,
	avg_price,
	AVG(avg_price) OVER (ORDER BY order_date) as moving_avg_price
	FROM
		(
		SELECT
			DATETRUNC(year,order_date) AS order_date,
			SUM(sales_amount) AS total_sales,
			AVG(price) AS avg_price
			FROM gold.fact_sales
			WHERE order_date IS NOT NULL
			GROUP BY DATETRUNC(year,order_date)
		) t

--Performance Analysis
--Analyze the yearly performance of products by comparing their sales to both the average sales performance of the product and the previous year's sales

WITH yearly_sales AS (

	SELECT
	YEAR(f.order_date) AS order_year,
	p.product_name,
	SUM(f.sales_amount) AS current_sales
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
	GROUP BY YEAR(f.order_date),p.product_name
)
SELECT
order_year,
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) avg_sales, 
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Average'
 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Average'			
ELSE 'Average' END,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) py_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) diff_py
FROM yearly_sales

--Part to whole analysis


SELECT 
category,
total_sales,
SUM(total_sales) OVER() overall_sales,
ROUND((CAST(total_sales AS FLOAT)/SUM(total_sales) OVER()) * 100,2) AS percentage_total
FROM 
		(SELECT
		category,
		SUM(sales_amount) AS total_sales
		FROM gold.fact_sales f
		LEFT JOIN gold.dim_products p
		ON p.product_key = f.product_key
		GROUP BY category) t
ORDER BY total_sales DESC

--Data Segmentation
--Segment products into cost ranges and count how many products fall into each segment
SELECT
	cost_range,
	COUNT(product_key) AS total_products
FROM
 (SELECT
	 product_key,
	 product_name,
	 cost,
	 CASE 
		 WHEN cost < 100 THEN 'Below 100'
		 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		 WHEN cost BETWEEN 500 AND 100 THEN '500-1000'
		 ELSE 'Above 100'
	END as cost_range
FROM gold.dim_products) t
GROUP BY cost_range

SELECT 
customer_segment,
COUNT(customer_key) AS total_customers
FROM(
	SELECT
	customer_key,
	CASE
		WHEN lifespan >= 12 AND total_spend > 5000 THEN 'VIP'
		WHEN lifespan >= 12 AND total_spend <= 5000 THEN 'Regular'
		ELSE 'New'
	END customer_segment
	FROM
	(
		SELECT
		c.customer_key,
		SUM(f.sales_amount) AS total_spend,
		MIN(f.order_date) AS first_order,
		MAX(f.order_date) AS last_order,
		DATEDIFF(MONTH,MIN(f.order_date) ,MAX(f.order_date)) AS lifespan
		FROM gold.fact_sales f
		LEFT JOIN gold.dim_customers c
		ON f.customer_key = c.customer_key
		GROUP BY c.customer_key) t

	) t
GROUP BY customer_segment
ORDER BY total_customers DESC;

--Customer Report
--Consolidate key customer metrics and behaviors

WITH base_query AS (

--Base query to join data

	SELECT 
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name,' ',c.last_name) AS customer_full_name,
	DATEDIFF(year, c.birthdate,GETDATE()) AS customer_age
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
	ON c.customer_key = f.customer_key
	WHERE order_date IS NOT NULL
),

customer_aggregation AS (
	SELECT 
	customer_key,
	customer_full_name,
	customer_age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month,MIN(order_date), MAX(order_date)) AS lifespan
	FROM base_query
	GROUP BY 
		customer_key,
		customer_key,
		customer_full_name,
		customer_age
	)

SELECT 
customer_key,
customer_key,
customer_full_name,
customer_age,
total_orders,
total_sales,
total_quantity,
total_products,
last_order_date,
CASE
	WHEN customer_age < 20 THEN 'Under 20'
	WHEN customer_age  BETWEEN 20 and 29 then '20-29'
	WHEN customer_age  BETWEEN 30 and 39 then '30-39'
	WHEN customer_age  BETWEEN 40 and 49 then '40-49'
ELSE '50 and above'
END AS age_group,
CASE
	WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	ELSE 'New' 
	END AS customer_segment,
last_order_date,
DATEDIFF(month,last_order_date,GETDATE()) AS recency,

--Compute average order value

CASE WHEN total_orders = 0 then 0
	ELSE total_sales/total_orders
	END AS avg_order_value,

--Compute average monthly spend


CASE WHEN lifespan = 0 then total_sales
	ELSE total_sales/lifespan
	END AS avg_monthly_spend

FROM customer_aggregation
