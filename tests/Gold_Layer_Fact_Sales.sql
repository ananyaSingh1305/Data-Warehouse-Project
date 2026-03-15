SELECT * FROM DataWarehouse.silver_crm_sales_details;

-- This table is a combination of keys, dates and measure. So, a FACT TABLE.

SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM DataWarehouse.silver_crm_sales_details;

-- STEP 1: Bring the dimension table's surrogate key instead of the present foreign keys to connect facts with dimensions.

SELECT 
a.sls_ord_num,
a.sls_prd_key,
b.product_number,
b.product_key,
a.sls_cust_id,
c.customer_id,
c.customer_key,
a.sls_order_dt,
a.sls_ship_dt,
a.sls_due_dt,
a.sls_sales,
a.sls_quantity,
a.sls_price
FROM DataWarehouse.silver_crm_sales_details a
LEFT JOIN DataWarehouse.gold_dim_products b ON a.sls_prd_key = b.product_number
LEFT JOIN DataWarehouse.gold_dim_customers c ON a.sls_cust_id = c.customer_id;

-- Just keep surrogate keys and remove foreign key columns.
-- Also give meaningful names.
-- Sort the columns.

SELECT 
a.sls_ord_num AS order_number,
b.product_key ,
c.customer_key,
a.sls_order_dt AS order_date,
a.sls_ship_dt AS shipping_date,
a.sls_due_dt AS due_date,
a.sls_sales AS sales_amount,
a.sls_quantity AS quantity,
a.sls_price AS price
FROM DataWarehouse.silver_crm_sales_details a
LEFT JOIN DataWarehouse.gold_dim_products b ON a.sls_prd_key = b.product_number
LEFT JOIN DataWarehouse.gold_dim_customers c ON a.sls_cust_id = c.customer_id;

-- Create view

CREATE VIEW gold_fact_sales AS
(SELECT 
a.sls_ord_num AS order_number,
b.product_key ,
c.customer_key,
a.sls_order_dt AS order_date,
a.sls_ship_dt AS shipping_date,
a.sls_due_dt AS due_date,
a.sls_sales AS sales_amount,
a.sls_quantity AS quantity,
a.sls_price AS price
FROM DataWarehouse.silver_crm_sales_details a
LEFT JOIN DataWarehouse.gold_dim_products b ON a.sls_prd_key = b.product_number
LEFT JOIN DataWarehouse.gold_dim_customers c ON a.sls_cust_id = c.customer_id);

-- Quality check of Gold Layer

SELECT * FROM gold_fact_sales a 
LEFT JOIN gold_dim_customers b on a.customer_key = b.customer_key
LEFT JOIN gold_dim_products c on a.product_key = c.product_key
WHERE b.customer_key IS NULL or c.product_key IS NULL;
-- No issues.

SELECT * FROM gold_fact_sales;
