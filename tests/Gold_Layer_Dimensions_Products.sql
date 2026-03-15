SELECT * FROM silver_crm_prod_info WHERE prd_cat_id ='CO_PE';

SELECT * FROM silver_erp_px_cat_g1v2 WHERE ID ='CO_PE';

SELECT 
ID,CAT,SUBCAT,MAINTENANCE 
FROM silver_erp_px_cat_g1v2;

SELECT DISTINCT prd_cat_id FROM silver_crm_prod_info;

SELECT DISTINCT ID FROM silver_erp_px_cat_g1v2;

SELECT DISTINCT prd_cat_id FROM silver_crm_prod_info
WHERE prd_cat_id NOT IN (SELECT DISTINCT ID FROM silver_erp_px_cat_g1v2);
-- CO_PE

SELECT DISTINCT ID FROM silver_erp_px_cat_g1v2
WHERE ID NOT IN (SELECT DISTINCT prd_cat_id FROM silver_crm_prod_info);

-- OBSERATION: silver_crm_prod_info or the CRM table is the master table.

SELECT 
a.prd_id,
a.prd_cat_id,
a.prd_sales_id,
a.prd_nm,
a.prd_cost,
a.prd_line,
a.prd_start_dt,
a.prd_end_dt
FROM silver_crm_prod_info a
LEFT JOIN silver_erp_px_cat_g1v2 b
ON a.prd_cat_id = b.ID;

-- REQUIREMENT: Considering only current data, ie, filter out historical data.
-- A record is current data if the prd_end_date in CRM table is NULL.

SELECT 
a.prd_id,
a.prd_cat_id,
a.prd_sales_id,
a.prd_nm,
a.prd_cost,
a.prd_line,
a.prd_start_dt,
b.CAT,
b.SUBCAT,
b.MAINTENANCE
FROM silver_crm_prod_info a
LEFT JOIN silver_erp_px_cat_g1v2 b
ON a.prd_cat_id = b.ID
WHERE a.prd_end_dt IS NULL;

-- Quality Check: Check uniqueness of prd_id
SELECT t.prd_id, count(*) FROM(
SELECT 
a.prd_id,
a.prd_cat_id,
a.prd_sales_id,
a.prd_nm,
a.prd_cost,
a.prd_line,
a.prd_start_dt,
b.CAT,
b.SUBCAT,
b.MAINTENANCE
FROM silver_crm_prod_info a
LEFT JOIN silver_erp_px_cat_g1v2 b
ON a.prd_cat_id = b.ID
WHERE a.prd_end_dt IS NULL) t
GROUP BY t.prd_id
HAVING count(*)>1;
-- Hence all values are unique.

-- NEXT STEP: 
-- Give column friendly/meaningful names.
-- Sort the columns in logical groups to improve readability.

SELECT 
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

-- As this table holds descriptive information about the product, hence it is a DIMENSION TABLE.
-- We always need a Primary Key for Dimension.
-- We can depend on the Primary Key available from the source system. Here, product_id.
-- If you have dimensions that do not have PK that you can count on. There we can create a new primary key, calling it SURROGATE KEY.

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

-- Create VIEW:

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

SELECT * FROM gold_dim_products;
