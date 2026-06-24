
CREATE OR ALTER PROCEDURE silver.load_silver AS 

BEGIN
TRUNCATE TABLE silver.crm_cust_info;

INSERT INTO silver.crm_cust_info(

	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_gndr,
	cst_maternal_status,
	cst_create_date

)

	SELECT
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		ELSE 'n/a'
	END cst_gndr,

	CASE WHEN UPPER(TRIM(cst_maternal_status)) = 'S' THEN 'Single'
		WHEN UPPER(TRIM(cst_maternal_status)) = 'M' THEN 'Married'
		ELSE 'n/a'
	END cst_maternal_status,

	cst_create_date
	FROM(
	SELECT
	*,
	ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
	FROM bronze.crm_cust_info
	)t WHERE flag_last = 1;

TRUNCATE TABLE silver.crm_prd_info;
INSERT INTO silver.crm_prd_info(

prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
)


SELECT
	prd_id,
	REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
	SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
	prd_nm,
	ISNULL(prd_cost,0) AS prd_cost,
	CASE UPPER(TRIM(prd_line)) 
		 WHEN'M' THEN 'Mountain'
		 WHEN'R' THEN 'Road'
		 WHEN'S' THEN 'Other Sales'
		 WHEN'T' THEN 'Touring'
		 ELSE 'n/a'
	END AS prd_line,
	prd_start_dt,
	LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) AS prd_end_dt_test
FROM bronze.crm_prd_info;


TRUNCATE TABLE silver.crm_sales_details;
INSERT INTO silver.crm_sales_details(

	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_price,
	sls_quantity

)

SELECT
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
END sls_order_dt,
CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
END sls_ship_dt,
CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
END sls_due_dt,

CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <= 0
	THEN sls_sales / NULLIF(sls_quantity,0)
	ELSE sls_price
END AS sls_price,
sls_quantity

FROM bronze.crm_sales_details


TRUNCATE TABLE silver.erp_cust_az12
INSERT INTO silver.erp_cust_az12(
erp_cid,
bdate,
gen
)

SELECT
CASE WHEN erp_cid LIKE 'NAS%'
	THEN SUBSTRING(erp_cid,4,LEN(erp_cid))
	ELSE erp_cid
END cid,
CASE WHEN bdate> GETDATE() THEN NULL
	ELSE bdate
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	 WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
	 ELSE 'n/a'
END as gen
FROM bronze.erp_cust_az12;

TRUNCATE TABLE silver.erp_loc_a101
INSERT INTO silver.erp_loc_a101(

erp_cid,
erp_cntry

)

SELECT
REPLACE(erp_cid,'-','') cid,
CASE WHEN TRIM(erp_cntry) = 'DE' THEN 'Germany'
	 WHEN TRIM(erp_cntry) IN  ('US','USA') THEN 'United States'
	 WHEN TRIM(erp_cntry) = '' OR erp_cntry IS NULL THEN 'n/a'
	 ELSE TRIM(erp_cntry)
END AS country	
FROM bronze.erp_loc_a101;


TRUNCATE TABLE silver.erp_px_cat_g1v2;
INSERT INTO silver.erp_px_cat_g1v2
(
erp_id,
erp_cat,
erp_subcat,
erp_maintennance
)

SELECT
erp_id,
erp_cat,
erp_subcat,
erp_maintennance
FROM bronze.erp_px_cat_g1v2

END
