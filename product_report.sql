CREATE VIEW gold_report_products AS
WITH product_query AS (
    SELECT 
        f.order_date,
        f.order_number,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.product_number,
        p.category,
        p.subcategory,
        p.cost,
        p.start_date
    FROM gold_dim_products AS p
    RIGHT JOIN gold_fact_sales AS f
        ON p.product_key = f.product_key
),
Agg_Query AS (
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        SUM(sales_amount) AS total_sales,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
        MAX(order_date) AS last_ordered,
        SUM(quantity) AS total_quantity,
        ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
    FROM product_query
    GROUP BY product_key, product_name, category, subcategory, cost
)
SELECT 
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_ordered,
    TIMESTAMPDIFF(MONTH, last_ordered, CURDATE()) AS recency_in_months,

    -- Product segmentation
    CASE 
        WHEN total_sales > 50000 THEN 'High Performer'
        WHEN total_sales >= 10000 THEN 'Mid Range'
        ELSE 'Low Performer'
    END AS product_segment,

    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,

    -- Average Order Revenue
    CASE 
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,

    -- Average Monthly Revenue
    CASE 
        WHEN lifespan = 0 THEN 0
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue

FROM Agg_Query;
