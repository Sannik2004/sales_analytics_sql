/*
------------------------------------------------------------
 Project: Gold Sales Analytics - SQL Reporting Suite
 Author : Sannik
 Date   : 29-08-2025
 DBMS   : MySQL 8.x
------------------------------------------------------------
 Description:
 This SQL script provides advanced analytics and reporting 
 for sales, products, and customers in the Gold dataset. 
 It includes:
   1. Monthly Sales & Running Totals
   2. Product Yearly Performance vs Average
   3. Category-Wise Sales Contribution
   4. Product Segmentation by Cost Ranges
   5. Customer Segmentation by Spending & Lifespan
   6. Customer Analytics Report (View Creation)
------------------------------------------------------------
*/

/* ==========================================================
   1. Monthly Sales Trends with Totals, Customers & Quantity
   ========================================================== */
SELECT
    DATE_FORMAT(order_date, '%Y-%b') AS order_month,
    SUM(sales_amount) AS Total_Sales, 
    COUNT(DISTINCT customer_key) AS Total_Customers, 
    SUM(quantity) AS Total_Quantity
FROM gold_fact_sales
WHERE order_date <> 0
GROUP BY order_month
ORDER BY order_month;


/* ==========================================================
   1B. Monthly Cumulative Sales & Running Average
   ========================================================== */
SELECT 
    order_month,
    Total_Sales,
    SUM(Total_Sales) OVER (
        ORDER BY order_year, order_num_month
    ) AS Cumulative_Total_Sales,
    AVG(AVG_SALES) OVER (
        ORDER BY order_year, order_num_month
    ) AS Running_Average_Sales
FROM (
    SELECT
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_num_month,
        DATE_FORMAT(order_date, '%Y-%b') AS order_month,
        SUM(sales_amount) AS Total_Sales,
        AVG(sales_amount) AS AVG_SALES
    FROM gold_fact_sales
    WHERE order_date <> 0
    GROUP BY order_year, order_num_month, order_month
) AS monthly_sales
ORDER BY order_year, order_num_month;


/* ==========================================================
   2. Yearly Product Performance vs. Average & Prior Year
   ========================================================== */
WITH yearly_product_performance AS (
    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold_fact_sales AS f
    LEFT JOIN gold_dim_products AS p
        ON f.product_key = p.product_key
    WHERE YEAR(f.order_date) <> 0
    GROUP BY YEAR(f.order_date), p.product_name
)
SELECT *,
       AVG(current_sales) OVER (PARTITION BY product_name) AS AVG_SALES,
       current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS difference_avg,
       CASE 
           WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 
                THEN 'Above Average'
           WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 
                THEN 'Below Average'
           ELSE 'AVG'
       END AS average_change,
       LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS py_sales,
       current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS df_py_sales,
       CASE 
           WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 
                THEN 'Increases'
           WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 
                THEN 'Decreases'
           ELSE 'Equal'
       END AS py_change
FROM yearly_product_performance
ORDER BY product_name, order_year;


/* ==========================================================
   3. Category Sales Contribution (Share of Overall Sales)
   ========================================================== */
WITH CTE AS (
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold_fact_sales AS f
    LEFT JOIN gold_dim_products AS p
        ON f.product_key = p.product_key
    GROUP BY p.category
)
SELECT *,
       SUM(total_sales) OVER() AS Overall_Total_Sales,
       CONCAT(ROUND(total_sales / SUM(total_sales) OVER() * 100, 2), '%') AS Percentage_Contributed
FROM CTE
ORDER BY total_sales DESC;


/* ==========================================================
   4. Product Segmentation by Cost Ranges
   ========================================================== */
WITH product_segment AS (
    SELECT product_key, product_name, cost,
           CASE 
               WHEN cost < 100 THEN 'Below 100'
               WHEN cost BETWEEN 100 AND 500 THEN '100-500'
               WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
               ELSE 'Above 1000'
           END AS cost_range
    FROM gold_dim_products
)
SELECT 
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segment
GROUP BY cost_range
ORDER BY total_products DESC;


/* ==========================================================
   5. Customer Segmentation by Spending & Lifespan
   ========================================================== */
WITH CTE AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS Total_Spending_Amount,
        TIMESTAMPDIFF(MONTH, MIN(f.order_date), MAX(f.order_date)) AS lifespan
    FROM gold_dim_customers AS c
    LEFT JOIN gold_fact_sales AS f
        ON c.customer_key = f.customer_key
    GROUP BY c.customer_key 
)
SELECT
    COUNT(customer_key) AS total_customers,
    customer_category
FROM (
    SELECT customer_key,
           Total_Spending_Amount, 
           lifespan,
           CASE 
               WHEN lifespan >= 12 AND Total_Spending_Amount > 5000 THEN 'VIP'
               WHEN lifespan >= 12 AND Total_Spending_Amount <= 5000 THEN 'REGULAR'
               ELSE 'NEW'
           END AS customer_category
    FROM CTE
) t
GROUP BY customer_category
ORDER BY total_customers;


/* ==========================================================
   6. Customer Analytics Report (View Creation)
   ========================================================== */
CREATE OR REPLACE VIEW gold_report_customers AS
WITH base_query AS (
    SELECT 
        f.order_number,
        f.product_key,
        f.order_date,
        f.quantity,
        f.sales_amount,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name,' ', c.last_name) AS full_name,
        TIMESTAMPDIFF(YEAR, c.birthdate, CURDATE()) AS present_age
    FROM gold_fact_sales AS f
    LEFT JOIN gold_dim_customers AS c
        ON f.customer_key = c.customer_key
),
customer_agg AS (
    SELECT 
        customer_key,
        customer_number,
        full_name,
        present_age,
        SUM(Sales_amount) AS Total_amount,
        COUNT(DISTINCT order_number) AS Total_orders,
        SUM(quantity) AS Total_quantity,
        COUNT(DISTINCT product_key) AS Total_products,
        MAX(order_date) AS last_order_date,
        TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY customer_key, customer_number, present_age, full_name
)
SELECT
    customer_key,
    customer_number,
    full_name,
    Total_amount,
    Total_products,
    Total_orders,
    CASE 
        WHEN lifespan >= 12 AND Total_amount > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND Total_amount <= 5000 THEN 'REGULAR'
        ELSE 'NEW'
    END AS customer_category,
    CASE
        WHEN present_age < 20 THEN '0-20'
        WHEN present_age BETWEEN 20 AND 30 THEN '20-30'
        WHEN present_age BETWEEN 30 AND 40 THEN '30-40'
        WHEN present_age BETWEEN 40 AND 50 THEN '40-50'
        ELSE 'Above 50'
    END AS Age_category,
    last_order_date,
    lifespan,
    TIMESTAMPDIFF(MONTH, last_order_date, CURDATE()) AS recency,
    -- Average Order Value
    CASE WHEN Total_amount = 0 THEN 0
         ELSE Total_amount / Total_orders 
    END AS Average_Order_Value,
    -- Average Monthly Sales
    CASE WHEN lifespan = 0 THEN 0
         ELSE Total_amount / lifespan
    END AS Average_Monthly_Sales
FROM customer_agg;


/*
------------------------------------------------------------
 End of Script
 Extend with:
   - RFM Analysis
   - Cohort Analysis
   - CLV (Customer Lifetime Value) Models
------------------------------------------------------------
*/
