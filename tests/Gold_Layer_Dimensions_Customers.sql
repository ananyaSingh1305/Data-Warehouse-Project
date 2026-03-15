SELECT * FROM silver_crm_cust_info;

SELECT * FROM silver_erp_cust_az12;

SELECT * FROM silver_erp_loc_a101;

-- silver_crm_cust_info is the master table

SELECT a.cst_id, a.cst_key, a.cst_firstname, a.cst_lastname, a.cst_marital_status, a.cst_gndr, a.cst_create_date,
b.CID, b.BDATE, b.GEN,
c.CID, c.CNTRY
FROM silver_crm_cust_info AS a
LEFT JOIN silver_erp_cust_az12 b ON a.cst_key = b.CID 
LEFT JOIN silver_erp_loc_a101 c ON a.cst_key = c.CID;

-- QUALITY CHECK: Check if any duplicates were introduced by the join logic.

SELECT t.cst_id, count(*) FROM(
SELECT a.cst_id, a.cst_key, a.cst_firstname, a.cst_lastname, a.cst_marital_status, a.cst_gndr, a.cst_create_date,
b.BDATE, b.GEN, c.CNTRY
FROM silver_crm_cust_info AS a
LEFT JOIN silver_erp_cust_az12 b ON a.cst_key = b.CID 
LEFT JOIN silver_erp_loc_a101 c ON a.cst_key = c.CID) t
GROUP BY t.cst_id
HAVING count(*)>1;
-- No issue.

-- Integration Issue: There are 2 sources for gender column, and there is a mismatch.

SELECT a.cst_id, a.cst_key, a.cst_gndr,b.GEN
FROM silver_crm_cust_info AS a
LEFT JOIN silver_erp_cust_az12 b ON a.cst_key = b.CID 
LEFT JOIN silver_erp_loc_a101 c ON a.cst_key = c.CID
WHERE a.cst_gndr!=b.GEN;

SELECT DISTINCT a.cst_gndr,b.GEN
FROM silver_crm_cust_info AS a
LEFT JOIN silver_erp_cust_az12 b ON a.cst_key = b.CID 
LEFT JOIN silver_erp_loc_a101 c ON a.cst_key = c.CID
WHERE a.cst_gndr!=b.GEN; -- Showing all possible mismatch combinations.

/*
We need to confirm from the experts about it. Is source silver_erp_cust_az12 or silver_erp_cust_az12 the master table for gender values?
So as to prioritize gender from what table.
ASSUMPTION:
1. Master source of customer data is CRM.
2. If data is CRM is not available, choose from ERP.
3. If both are N/A, then N/A.
*/

SELECT a.cst_id, a.cst_key, a.cst_gndr,b.GEN,
CASE 
WHEN a.cst_gndr!='N/A' THEN a.cst_gndr
WHEN a.cst_gndr='N/A' THEN b.GEN
ELSE 'N/A'
END AS new_gen
FROM silver_crm_cust_info AS a
LEFT JOIN silver_erp_cust_az12 b ON a.cst_key = b.CID 
LEFT JOIN silver_erp_loc_a101 c ON a.cst_key = c.CID
WHERE a.cst_gndr!=b.GEN;

-- So, final query

SELECT a.cst_id, a.cst_key, a.cst_firstname, a.cst_lastname, a.cst_marital_status, 
CASE 
WHEN a.cst_gndr!='N/A' THEN a.cst_gndr
WHEN a.cst_gndr='N/A' THEN b.GEN
ELSE 'N/A'
END AS new_gen,
a.cst_create_date,
b.CID, b.BDATE,
c.CID, c.CNTRY
FROM silver_crm_cust_info AS a
LEFT JOIN silver_erp_cust_az12 b ON a.cst_key = b.CID 
LEFT JOIN silver_erp_loc_a101 c ON a.cst_key = c.CID;

-- NEXT STEP: 
-- Give column friendly/meaningful names.
-- Sort the columns in logical groups to improve readability.

SELECT 
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
LEFT JOIN silver_erp_loc_a101 c ON a.cst_key = c.CID;

-- As this table holds descriptive information about the customer, hence it is a DIMENSION TABLE.
-- We always need a Primary Key for Dimension.
-- We can depend on the Primary Key available from the source system. Here, customer_id.
-- If you have dimensions that do not have PK that you can count on. There we can create a new primary key, calling it SURROGATE KEY.

SELECT
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
LEFT JOIN silver_erp_loc_a101 c ON a.cst_key = c.CID;

-- ALL DONE!!
-- Now create object: In Gold Layer, we create VIEW.

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

-- CHECK QUALITY OF VIEW: gold_dim_customers

SELECT * FROM gold_dim_customers;
SELECT DISTINCT gender FROM gold_dim_customers;
SELECT DISTINCT country FROM gold_dim_customers;
SELECT DISTINCT marital_status FROM gold_dim_customers;
