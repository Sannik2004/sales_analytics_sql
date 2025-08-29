# 📊 Sales Analytics SQL Project

## 📖 Overview
This project focuses on analyzing sales transactions using SQL.  
The goal is to derive **actionable business insights** such as product performance, customer base growth, and revenue trends.  

The key deliverable is a SQL **view** called `gold_report_products`, which aggregates important KPIs like:
- Total sales
- Customer count
- Product lifespan
- Recency of last order
- Product segmentation (High Performer, Mid Range, Low Performer)
- Average order revenue
- Average monthly revenue

---

## 📂 Dataset
The project uses a **star schema** design with the following tables:

- **`gold_fact_sales`** – transactional sales data  
- **`gold_dim_products`** – product catalog with categories and costs  
- **`gold_dim_customers`** – customer demographic details  

*(If you don’t want to share real datasets, add sample/synthetic data in a `data/` folder for reproducibility.)*

---

## ⚡ SQL Features Used
- Joins: `RIGHT JOIN` to combine fact & dimension data  
- Aggregations: `SUM`, `COUNT(DISTINCT)`, `AVG`, `MAX`, `MIN`  
- Date functions: `TIMESTAMPDIFF`, `CURDATE`  
- Conditional logic: `CASE WHEN` for segmentation  
- Derived KPIs: Recency, Avg Order Revenue, Avg Monthly Revenue  

---

## 📊 Outputs
The main output is the **SQL view** `gold_report_products`.

Example KPIs produced:
- **High Performer Products**: total sales > 50,000  
- **Mid Range Products**: total sales between 10,000 – 50,000  
- **Low Performer Products**: total sales < 10,000  
- Recency of last order in months  
- Average selling price per unit  
- Average monthly revenue across product lifespan  

---

## ▶️ How to Run
1. Clone the repository  
2. Create the schema and load data into the following tables:  
   - `gold_fact_sales`  
   - `gold_dim_products`  
   - `gold_dim_customers`  
3. Run the SQL scripts in the `sql/` folder  
4. Create the view:
   ```sql

#Query the view
SELECT * FROM gold_report_products;

   CREATE VIEW gold_report_products AS
   -- (view definition from sql/view_gold_report_products.sql)
