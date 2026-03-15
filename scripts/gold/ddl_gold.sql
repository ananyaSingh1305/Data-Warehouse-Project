/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold_dim_customers
-- =============================================================================

CREATE VIEW gold_dim_customers AS
(SELECT
ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,
a.cst_id AS customer_id, 
a.cst_key AS customer_number, 
a.cst_firstname AS first_name, 
a.cst_lastname AS last_name, 
c.CNTRY AS country,
a.cst_marital_status AS marital_status, 
CASE 
WHEN a.cst_gndr!='N/A' THEN a.cst_gndr
WHEN a.cst_gndr='N/A' THEN b.GEN
ELSE 'N/A'
END AS gender,
b.BDATE AS birthdate, 
a.cst_create_date AS create_date
FROM silver_crm_cust_info AS a
LEFT JOIN silver_erp_cust_az12 b ON a.cst_key = b.CID 
LEFT JOIN silver_erp_loc_a101 c ON a.cst_key = c.CID
);

-- =============================================================================
-- Create Dimension: gold_dim_products
-- =============================================================================

CREATE VIEW gold_dim_products AS
SELECT 
ROW_NUMBER() OVER(ORDER BY a.prd_start_dt, a.prd_id) AS product_key,
a.prd_id AS product_id,
a.prd_sales_id AS product_number,
a.prd_nm AS product_name,
a.prd_cat_id AS category_id,
b.CAT AS category,
b.SUBCAT AS sub_category,
b.MAINTENANCE AS maintenance,
a.prd_cost AS cost,
a.prd_line AS product_line,
a.prd_start_dt AS product_start_date
FROM silver_crm_prod_info a
LEFT JOIN silver_erp_px_cat_g1v2 b
ON a.prd_cat_id = b.ID
WHERE a.prd_end_dt IS NULL;

-- =============================================================================
-- Create Dimension: gold_fact_sales
-- =============================================================================

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



