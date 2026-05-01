/*
====================================================================================
DDL Script: Create Gold Views
====================================================================================
Script Purpose:
    This script creates views for the 'gold' layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver Layer
    to produce a clean, enriched and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
====================================================================================
*/


-- =================================================================================
-- Create Dimension: golf.dim_customers
-- =================================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
 	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
		CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birth_date,
	ci.cst_create_date AS create_date
FROM silver.crm_cst_info ci
LEFT JOIN silver.erp_cust_az1 ca
	ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la 
	ON ci.cst_key =la.cid;
GO
  
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO

-- =================================================================================
-- Create Dimension: golf.dim_products
-- =================================================================================
CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER (ORDER BY pi.prd_start_dt, pi.prd_key) AS product_key,
	pi.prd_id AS product_id,
	pi.prd_key AS product_number,
	pi.prd_nm AS product_name,
	pi.cat_id AS category_id,
	pc.cat AS product_category,
	pc.subcat AS product_sub_category,
	pc.maintenance,
	pi.prd_line AS product_line,
	pi.prd_cost AS product_cost,
	pi.prd_start_dt AS product_start_date
FROM silver.crm_prd_info pi
LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pi.cat_id = pc.id 
WHERE pi.prd_end_dt IS NULL -- Filter out historical data
;
GO
  
-- =================================================================================
-- Create Fact Table: golf.fact_sales
-- =================================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO
  
CREATE VIEW gold.fact_sales AS
SELECT 
	sd.sls_ord_num AS order_number,
	dp.product_key,
	dc.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_price AS price,
	sd.sls_quantity AS quantity,
	sd.sls_sales AS sales
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products dp
	ON sd.sls_prd_key = dp.product_number
LEFT JOIN gold.dim_customers dc
	ON sd.sls_cust_id = dc.customer_id 
;
GO
