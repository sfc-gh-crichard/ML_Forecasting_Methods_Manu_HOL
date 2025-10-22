/*
 * ThisIsClay Co - HVAC Forecasting Lab Setup
 * 
 * This script sets up the Snowflake environment for comparing three forecasting methods:
 * 1. Snowflake Cortex ML Forecasting (SQL-based)
 * 2. Scalable Time Series with XGBoost (Snowpark Python)
 * 3. Snowpark ML APIs (Python ML Framework)
 * 
 * Run this script as ACCOUNTADMIN or a user with sufficient privileges
 */

-- ============================================================================
-- STEP 1: CREATE ROLE AND GRANT PERMISSIONS
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Capture current username
SET USERNAME = (SELECT CURRENT_USER());
SELECT $USERNAME;

-- Create a dedicated role for this lab
CREATE OR REPLACE ROLE HVAC_FORECAST_ROLE;
GRANT ROLE HVAC_FORECAST_ROLE TO USER IDENTIFIER($USERNAME);

-- Grant necessary account-level privileges
GRANT CREATE DATABASE ON ACCOUNT TO ROLE HVAC_FORECAST_ROLE;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE HVAC_FORECAST_ROLE;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE HVAC_FORECAST_ROLE;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE HVAC_FORECAST_ROLE;
GRANT IMPORT SHARE ON ACCOUNT TO ROLE HVAC_FORECAST_ROLE;

-- Switch to the new role
USE ROLE HVAC_FORECAST_ROLE;

-- ============================================================================
-- STEP 2: CREATE WAREHOUSE (LARGER SIZE FOR FASTER PROCESSING)
-- ============================================================================

-- Create a MEDIUM warehouse for better performance with 3 years of weekly data
-- Cost: ~4 credits/hour. AUTO_SUSPEND after 5 min saves costs.
-- Expected total lab cost: 2-3 credits
CREATE OR REPLACE WAREHOUSE HVAC_FORECAST_WH 
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 300  -- Suspend after 5 minutes of inactivity
    AUTO_RESUME = TRUE   -- Auto-resume when queries run
    INITIALLY_SUSPENDED = TRUE  -- Start suspended (no immediate cost)
    COMMENT = 'Warehouse for HVAC forecasting lab - medium size for faster processing';

USE WAREHOUSE HVAC_FORECAST_WH;

-- ============================================================================
-- STEP 3: CREATE DATABASE AND SCHEMA
-- ============================================================================

CREATE OR REPLACE DATABASE HVAC_FORECAST_DB
    COMMENT = 'Database for ThisIsClay Co HVAC demand forecasting analysis';

CREATE OR REPLACE SCHEMA HVAC_FORECAST_DB.FORECAST_DATA
    COMMENT = 'Schema containing HVAC demand data and forecasting models';

USE SCHEMA HVAC_FORECAST_DB.FORECAST_DATA;

-- ============================================================================
-- STEP 4: CREATE STAGES
-- ============================================================================

-- Stage for raw data files
CREATE OR REPLACE STAGE HVAC_DATA_STAGE
    COMMENT = 'Stage for HVAC demand data CSV files';

-- Stage for model artifacts
CREATE OR REPLACE STAGE HVAC_MODEL_STAGE
    COMMENT = 'Stage for storing model artifacts and outputs';

-- Stage for notebook files
CREATE OR REPLACE STAGE HVAC_NOTEBOOK_STAGE
    COMMENT = 'Stage for Jupyter notebook files';

-- ============================================================================
-- STEP 5: CREATE FILE FORMAT
-- ============================================================================

CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    ESCAPE = 'NONE'
    ESCAPE_UNENCLOSED_FIELD = '\134'
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO'
    NULL_IF = ('NULL', 'null', '')
    COMMENT = 'CSV format for HVAC demand data';

-- ============================================================================
-- STEP 6: CREATE EXTERNAL ACCESS INTEGRATION FOR NOTEBOOKS
-- ============================================================================

-- Network rule to allow external access from notebooks
CREATE OR REPLACE NETWORK RULE hvac_allow_all_rule
    TYPE = 'HOST_PORT'
    MODE = 'EGRESS'
    VALUE_LIST = ('0.0.0.0:443', '0.0.0.0:80');

-- External access integration
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION hvac_external_access
    ALLOWED_NETWORK_RULES = (hvac_allow_all_rule)
    ENABLED = TRUE
    COMMENT = 'External access for HVAC forecast notebooks';

GRANT USAGE ON INTEGRATION hvac_external_access TO ROLE HVAC_FORECAST_ROLE;

-- ============================================================================
-- STEP 7: CREATE BASE TABLE FOR HVAC DEMAND DATA
-- ============================================================================

CREATE OR REPLACE TABLE HVAC_DEMAND_RAW (
    WEEK_START_DATE DATE NOT NULL,
    YEAR INTEGER,
    QUARTER VARCHAR(2),
    MONTH INTEGER,
    WEEK_OF_YEAR INTEGER,
    REGION VARCHAR(50),
    PRODUCT VARCHAR(50),
    CUSTOMER_SEGMENT VARCHAR(10),
    DEMAND_UNITS INTEGER,
    REVENUE DECIMAL(12,2),
    AVG_TEMPERATURE_F DECIMAL(5,1),
    ECONOMIC_INDEX DECIMAL(5,1),
    HOUSING_STARTS INTEGER,
    IS_HOLIDAY_WEEK INTEGER,
    IS_WINTER INTEGER,
    IS_SPRING INTEGER,
    IS_SUMMER INTEGER,
    IS_FALL INTEGER
) COMMENT = 'Raw HVAC demand data for ThisIsClay Co - 3 years weekly data';

-- ============================================================================
-- STEP 8: INSTRUCTIONS FOR LOADING DATA
-- ============================================================================

/*
 * TO LOAD THE DATA:
 * 
 * Option 1 - Load from local file using SnowSQL or Snowsight:
 * 
 * PUT file:///path/to/thisisclayco_hvac_demand_data.csv @HVAC_DATA_STAGE AUTO_COMPRESS=TRUE;
 * 
 * COPY INTO HVAC_DEMAND_RAW
 * FROM @HVAC_DATA_STAGE/thisisclayco_hvac_demand_data.csv.gz
 * FILE_FORMAT = CSV_FORMAT
 * ON_ERROR = 'CONTINUE';
 * 
 * 
 * Option 2 - Load directly in Snowsight:
 * 
 * 1. Navigate to Data > Databases > HVAC_FORECAST_DB > FORECAST_DATA > Tables > HVAC_DEMAND_RAW
 * 2. Click "Load Data" button
 * 3. Select the thisisclayco_hvac_demand_data.csv file
 * 4. Follow the wizard to complete the load
 */

-- Verify data after loading
-- SELECT COUNT(*) AS TOTAL_RECORDS FROM HVAC_DEMAND_RAW;
-- SELECT MIN(WEEK_START_DATE) AS START_DATE, MAX(WEEK_START_DATE) AS END_DATE FROM HVAC_DEMAND_RAW;

-- ============================================================================
-- STEP 9: CREATE VIEWS FOR DIFFERENT FORECASTING METHODS
-- ============================================================================

-- Aggregated view for Cortex ML (by Region and Product, across all segments)
CREATE OR REPLACE VIEW HVAC_DEMAND_BY_REGION_PRODUCT AS
SELECT 
    WEEK_START_DATE,
    REGION,
    PRODUCT,
    SUM(DEMAND_UNITS) AS TOTAL_DEMAND_UNITS,
    SUM(REVENUE) AS TOTAL_REVENUE,
    AVG(AVG_TEMPERATURE_F) AS AVG_TEMPERATURE_F,
    AVG(ECONOMIC_INDEX) AS ECONOMIC_INDEX,
    AVG(HOUSING_STARTS) AS HOUSING_STARTS,
    MAX(IS_HOLIDAY_WEEK) AS IS_HOLIDAY_WEEK,
    MAX(IS_WINTER) AS IS_WINTER,
    MAX(IS_SPRING) AS IS_SPRING,
    MAX(IS_SUMMER) AS IS_SUMMER,
    MAX(IS_FALL) AS IS_FALL
FROM HVAC_DEMAND_RAW
GROUP BY WEEK_START_DATE, REGION, PRODUCT
ORDER BY WEEK_START_DATE, REGION, PRODUCT;

-- View by Region, Product, and Customer Segment for detailed analysis
CREATE OR REPLACE VIEW HVAC_DEMAND_DETAILED AS
SELECT * FROM HVAC_DEMAND_RAW
ORDER BY WEEK_START_DATE, REGION, PRODUCT, CUSTOMER_SEGMENT;

-- Time series view optimized for Cortex ML Forecasting
-- Cortex requires: timestamp column, series identifier columns, target column
CREATE OR REPLACE VIEW HVAC_DEMAND_TS_FORMAT AS
SELECT 
    WEEK_START_DATE AS DS,  -- Date/timestamp column
    REGION,
    PRODUCT,
    CUSTOMER_SEGMENT,
    DEMAND_UNITS AS Y,  -- Target variable
    AVG_TEMPERATURE_F,
    ECONOMIC_INDEX,
    HOUSING_STARTS,
    IS_WINTER,
    IS_SPRING,
    IS_SUMMER,
    IS_FALL
FROM HVAC_DEMAND_RAW
ORDER BY DS, REGION, PRODUCT, CUSTOMER_SEGMENT;

-- ============================================================================
-- STEP 10: CREATE TABLES TO STORE FORECAST RESULTS
-- ============================================================================

-- Table for Cortex ML forecasting results
CREATE OR REPLACE TABLE CORTEX_ML_FORECASTS (
    FORECAST_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    WEEK_START_DATE DATE,
    REGION VARCHAR(50),
    PRODUCT VARCHAR(50),
    CUSTOMER_SEGMENT VARCHAR(10),
    FORECAST_DEMAND DECIMAL(12,2),
    LOWER_BOUND DECIMAL(12,2),
    UPPER_BOUND DECIMAL(12,2),
    METHOD VARCHAR(50) DEFAULT 'CORTEX_ML'
) COMMENT = 'Forecast results from Snowflake Cortex ML';

-- Table for XGBoost forecasting results
CREATE OR REPLACE TABLE XGBOOST_FORECASTS (
    FORECAST_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    WEEK_START_DATE DATE,
    REGION VARCHAR(50),
    PRODUCT VARCHAR(50),
    CUSTOMER_SEGMENT VARCHAR(10),
    FORECAST_DEMAND DECIMAL(12,2),
    MODEL_VERSION VARCHAR(50),
    METHOD VARCHAR(50) DEFAULT 'XGBOOST'
) COMMENT = 'Forecast results from XGBoost model';

-- Table for Snowpark ML forecasting results
CREATE OR REPLACE TABLE SNOWPARK_ML_FORECASTS (
    FORECAST_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    WEEK_START_DATE DATE,
    REGION VARCHAR(50),
    PRODUCT VARCHAR(50),
    CUSTOMER_SEGMENT VARCHAR(10),
    FORECAST_DEMAND DECIMAL(12,2),
    MODEL_VERSION VARCHAR(50),
    METHOD VARCHAR(50) DEFAULT 'SNOWPARK_ML'
) COMMENT = 'Forecast results from Snowpark ML';

-- Unified comparison view
CREATE OR REPLACE VIEW FORECAST_COMPARISON AS
SELECT 
    'CORTEX_ML' AS METHOD,
    WEEK_START_DATE,
    REGION,
    PRODUCT,
    CUSTOMER_SEGMENT,
    FORECAST_DEMAND
FROM CORTEX_ML_FORECASTS
UNION ALL
SELECT 
    'XGBOOST' AS METHOD,
    WEEK_START_DATE,
    REGION,
    PRODUCT,
    CUSTOMER_SEGMENT,
    FORECAST_DEMAND
FROM XGBOOST_FORECASTS
UNION ALL
SELECT 
    'SNOWPARK_ML' AS METHOD,
    WEEK_START_DATE,
    REGION,
    PRODUCT,
    CUSTOMER_SEGMENT,
    FORECAST_DEMAND
FROM SNOWPARK_ML_FORECASTS
ORDER BY WEEK_START_DATE, REGION, PRODUCT, CUSTOMER_SEGMENT, METHOD;

-- ============================================================================
-- STEP 11: CREATE SAMPLE QUERIES FOR DATA EXPLORATION
-- ============================================================================

-- Total demand by year
-- SELECT YEAR, SUM(DEMAND_UNITS) AS TOTAL_DEMAND, SUM(REVENUE) AS TOTAL_REVENUE
-- FROM HVAC_DEMAND_RAW
-- GROUP BY YEAR
-- ORDER BY YEAR;

-- Demand trend by customer segment
-- SELECT CUSTOMER_SEGMENT, SUM(DEMAND_UNITS) AS TOTAL_DEMAND
-- FROM HVAC_DEMAND_RAW
-- GROUP BY CUSTOMER_SEGMENT
-- ORDER BY TOTAL_DEMAND DESC;

-- Top products by revenue
-- SELECT PRODUCT, SUM(REVENUE) AS TOTAL_REVENUE
-- FROM HVAC_DEMAND_RAW
-- GROUP BY PRODUCT
-- ORDER BY TOTAL_REVENUE DESC;

-- Regional performance
-- SELECT REGION, SUM(DEMAND_UNITS) AS TOTAL_DEMAND, SUM(REVENUE) AS TOTAL_REVENUE
-- FROM HVAC_DEMAND_RAW
-- GROUP BY REGION
-- ORDER BY TOTAL_REVENUE DESC;

-- Seasonal patterns
-- SELECT 
--     CASE 
--         WHEN IS_WINTER = 1 THEN 'Winter'
--         WHEN IS_SPRING = 1 THEN 'Spring'
--         WHEN IS_SUMMER = 1 THEN 'Summer'
--         WHEN IS_FALL = 1 THEN 'Fall'
--     END AS SEASON,
--     AVG(DEMAND_UNITS) AS AVG_DEMAND
-- FROM HVAC_DEMAND_RAW
-- GROUP BY SEASON
-- ORDER BY AVG_DEMAND DESC;

-- ============================================================================
-- SETUP COMPLETE!
-- ============================================================================

SELECT 'Setup complete! Ready to load data and begin forecasting.' AS STATUS;

/*
 * NEXT STEPS:
 * 1. Load the CSV data into HVAC_DEMAND_RAW table (see instructions in STEP 8)
 * 2. Verify the data loaded correctly
 * 3. Open Method 1: Cortex ML Forecasting notebook
 * 4. Open Method 2: XGBoost Time Series notebook
 * 5. Open Method 3: Snowpark ML notebook
 * 6. Compare results using the unified comparison notebook
 */

