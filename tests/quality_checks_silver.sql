/*
===================================================================================================
Quality Checks
===================================================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, and standardization
    across the 'silver' schemas. It includes checks for:
    - Null or duplicate primary keys
    - Unwanted spaces in string fields
    - Data standardization and consistency
    - Invalid date ranges and orders
    - Data consistency between related fields

Usage Notes:
    - Run these checks after data loading 'silver' layer
    - Investigate and resolve any discrepancies found during the checks.
===================================================================================================
*/

-- =====================================================================================
-- Checking 'silver.crm_cst_info'
-- =====================================================================================
-- Checking For Nulls or Duplicate in Primary Key
-- Expectation: No Result
 SELECT
	cst_id,
	COUNT(*)
FROM silver.crm_cst_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Checking for Unwanted Spaces
-- Expectation: No Result
SELECT cst_firstname
FROM silver.crm_cst_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_cst_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT cst_marital_status
FROM silver.crm_cst_info
WHERE cst_marital_status != TRIM(cst_marital_status);

SELECT cst_gndr
FROM silver.crm_cst_info
WHERE cst_gndr != TRIM(cst_gndr);

-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cst_info;

SELECT DISTINCT cst_marital_status
FROM silver.crm_cst_info; 
 

-- =====================================================================================
-- Checking 'silver.crm_prd_info'
-- =====================================================================================
-- Checking For Nulls or Duplicate in Primary Key
-- Expectation: No Result
SELECT
	prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Security Checks for the crm_cust_sales_details Table
-- Checking for Unwanted Spaces
-- Expectation: No Result
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Checking for NULLS or Negative Numbers
-- Expectation: No Results
SELECT prd_cost 
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Check for Invalid Date Orders
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- =====================================================================================
-- Checking 'silver.crm_cust_sales_details'
-- =====================================================================================
-- Checking for Unwanted Spaces
-- Expectation: No Result
SELECT sls_ord_num
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

SELECT sls_prd_key
FROM silver.crm_sales_details
WHERE sls_prd_key != TRIM(sls_prd_key);

-- Checking the integrity of sls_prd_key
-- Expectation: No Result
SELECT *
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (
	SELECT prd_key
	FROM silver.crm_prd_info
);

-- Checking the integrity of sls_cust_id
-- Expectation: No Result
SELECT *
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (
	SELECT cst_id 
	FROM silver.crm_cst_info
);

-- Checking for Invalid Dates
SELECT 
	sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt <= 0
	OR LEN(sls_order_dt) != 8
	OR sls_order_dt > 20260430
	OR sls_order_dt < 19000101;

SELECT 
	sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt <= 0
	OR LEN(sls_ship_dt) != 8
	OR sls_ship_dt > 20260430
	OR sls_ship_dt < 19000101;

SELECT 
	sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt <= 0
	OR LEN(sls_due_dt) != 8
	OR sls_due_dt > 20260430
	OR sls_due_dt < 19000101;

SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
	OR sls_order_dt > sls_due_dt
	OR sls_ship_dt > sls_due_dt;

-- Checking Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero or negative
SELECT DISTINCT
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_price * sls_quantity
	OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
	OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- =====================================================================================
-- Checking 'silver.erp_cust_az1'
-- =====================================================================================
-- Checking the integrity of cid
-- Expectation: No Result
SELECT 
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		 ELSE cid
	END AS cid
FROM silver.erp_cust_az1
WHERE 	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		 ELSE cid
	END NOT IN (
	SELECT DISTINCT
		cst_key
	FROM silver.crm_cst_info
);

-- Identifying Dates that are Out-of-Range
SELECT DISTINCT
	bdate 
FROM silver.erp_cust_az1
WHERE bdate < '1924-01-01' OR bdate > GETDATE();

-- Data Standardization & Consistency
SELECT DISTINCT
	gen
FROM silver.erp_cust_az1;

-- =====================================================================================
-- Checking 'silver.erp_loc_a101'
-- =====================================================================================
--Checking for integrity of cid
--Expectation: No Result
SELECT cid
FROM silver.erp_loc_a101
WHERE cid NOT IN (
	SELECT cst_key 
	FROM silver.crm_cst_info
);

-- Data Standardization & Consistency
SELECT DISTINCT
	cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

-- =====================================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- =====================================================================================
-- Data Standardization & Consistency
SELECT DISTINCT maintenance 
FROM silver.erp_px_cat_g1v2;
