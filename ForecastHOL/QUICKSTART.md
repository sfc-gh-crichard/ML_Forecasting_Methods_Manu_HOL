# ThisIsClay Co - HVAC Demand Forecasting Lab

## 🎯 Quick Start Guide

Complete guide to run the lab from start to finish in one place.

---

## 🏔️ About ThisIsClay Co

ThisIsClay Co is an HVAC distribution company specializing in cold weather and high-elevation markets across North America (Rocky Mountains, Pacific Northwest, New England). They distribute heat pumps, furnaces, and air handlers to residential, commercial, and government customers.

**Lab Data**: This lab uses synthetic weekly data (3 years, 156 weeks) with realistic patterns including:
- **Demand & Revenue**: Weekly unit sales and revenue by region/product/segment
- **Seasonal Factors**: Winter peaks (heating demand), summer/fall variations
- **Temperature Data**: Regional average temperatures affecting HVAC demand
- **Economic Indicators**: GDP growth, unemployment rates, consumer confidence index
- **Housing Data**: New housing starts influencing installation demand
- **Market Segments**: B2C (residential), B2B (commercial), B2G (government contracts)

The data mirrors real-world HVAC demand patterns with weather dependencies, economic cycles, and seasonal variations.

---

## Overview

This lab demonstrates **three forecasting methods** in Snowflake using HVAC demand data:

1. **Method 1: Cortex ML** - SQL-based, auto-generated features from historical time series (~30 min)
2. **Method 2: XGBoost** - Custom ML with 25+ engineered features (lags, rolling stats, weather, economic indicators) (~90 min) 
3. **Method 3: Snowpark ML** - Enterprise ML with preprocessing pipelines and Model Registry (~60 min) ⭐ **RECOMMENDED**

**Total Time**: 2-3 hours for complete lab

---

## Prerequisites

- **Snowflake account** with:
  - Ability to create databases, warehouses, roles
  - Container Runtime enabled (for notebooks)
  - ACCOUNTADMIN role (for initial setup)
- **Python 3.8+** installed locally with: pandas, numpy, matplotlib, seaborn

---

## Step 1: Generate Data (2 minutes)

Generate the HVAC demand dataset:

```bash
python generate_hvac_data.py
```

**Output**: `thisisclayco_hvac_demand_data.csv` (~22,000 records, 3 years of weekly data)

---

## Step 2: Setup Snowflake Environment (3 minutes)

1. Open **Snowsight** (Snowflake web UI)
2. Open a **SQL Worksheet**
3. Copy and run the entire `setup.sql` script

**What it creates**:
- Database: `HVAC_FORECAST_DB`
- Warehouse: `HVAC_FORECAST_WH` (MEDIUM size, auto-suspend enabled)
- Schema: `FORECAST_DATA`
- Tables and views for all methods

**Verify**:
```sql
USE ROLE HVAC_FORECAST_ROLE;
USE DATABASE HVAC_FORECAST_DB;
USE SCHEMA FORECAST_DATA;

SHOW TABLES;
-- Should show HVAC_DEMAND_RAW and other tables
```

**Expected Cost**: ~2-3 Snowflake credits for entire lab (MEDIUM warehouse with auto-suspend)

---

## Step 3: Load Data into Snowflake (2 minutes)

**Option A - Using Snowsight UI (Recommended)**:
1. Go to **Data** → **Databases** → **HVAC_FORECAST_DB** → **FORECAST_DATA** → **Tables**
2. Click **HVAC_DEMAND_RAW** table
3. Click **Load Data** button
4. Upload `thisisclayco_hvac_demand_data.csv`
5. Follow wizard and click **Load**

**Option B - Using SQL**:
```sql
-- Create stage and upload file first, then:
COPY INTO HVAC_DEMAND_RAW
FROM @HVAC_DATA_STAGE/thisisclayco_hvac_demand_data.csv
FILE_FORMAT = CSV_FORMAT;
```

**Verify data loaded**:
```sql
SELECT COUNT(*) FROM HVAC_DEMAND_RAW;
-- Should return ~22,000 records

SELECT * FROM HVAC_DEMAND_RAW LIMIT 10;
```

---

## Step 4: Enable ML Packages (5 minutes) ⚠️ **CRITICAL**

**This step is REQUIRED for best results!** Without these packages, notebooks will use basic statistical methods instead of ML.

### 4a. Enable Anaconda (One-Time Setup)

As **ACCOUNTADMIN**, enable Anaconda packages:

1. In Snowsight, go to **Admin** → **Billing & Terms** → **Anaconda**
2. **Accept the Anaconda terms** (one-time per account)

**OR** run this SQL:
```sql
USE ROLE ACCOUNTADMIN;
SELECT SYSTEM$ENABLE_ANACONDA_PACKAGES();
```

### 4b. Add Packages to Notebooks

When you create/upload each notebook in Snowflake, add the required packages:

#### For Notebook 1: `1_cortex_ml_forecasting.ipynb`
**No packages needed!** ✅ Just upload and run.

#### For Notebook 2: `2_xgboost_time_series.ipynb`
**Required packages**:
1. Click **"Packages"** dropdown (top of notebook)
2. Search and add: `xgboost` (version 1.7.3+)
3. Search and add: `scikit-learn` (version 1.2.2+)
4. Click **"Start"** or restart notebook

#### For Notebook 3: `3_snowpark_ml_forecasting.ipynb` ⭐
**Required packages** (3 total):
1. Click **"Packages"** dropdown
2. Search and add: `snowflake-ml-python` (version 1.0.12+) - **CRITICAL**
3. Search and add: `xgboost` (version 1.7.3+)
4. Search and add: `scikit-learn` (version 1.2.2+)
5. Click **"Start"** or restart notebook

#### For Notebook 4: `4_comparison_all_methods.ipynb`
**No packages needed!** ✅ Just compares results.

### Package Summary Table

| Notebook | Packages Required | Why |
|----------|------------------|-----|
| 1 - Cortex ML | None | Uses SQL-based Cortex ML |
| 2 - XGBoost | `xgboost`, `scikit-learn` | ML training & evaluation |
| 3 - Snowpark ML | `snowflake-ml-python`, `xgboost`, `scikit-learn` | Full Snowpark ML stack |
| 4 - Comparison | None | Just queries results |

### How to Add Packages in Snowsight

1. Open your notebook in Snowsight
2. Look for **"Packages"** button/dropdown (usually top toolbar)
3. Click **"+ Add packages"**
4. Search for package name (exact spelling)
5. Click **"+"** to add
6. Repeat for each package
7. Click **"Apply"** and restart notebook

### Verification

After adding packages and running the first cell:

**Notebook 2 should show**:
```
✅ XGBoost/sklearn available - will use ML model
```

**Notebook 3 should NOT show**:
```
ℹ️ Snowpark ML not available - will use statistical baseline instead
```

If you see the warning messages, packages weren't added correctly. Go back and add them.

### ⚠️ Important Notes

- **Without packages**, notebooks will fall back to basic statistical methods (not recommended for production)
- **With packages**, you get full ML capabilities and much better accuracy
- **Anaconda packages are free** for most Snowflake users
- **Takes 2 minutes** to set up, but makes a huge difference in results!

---

## Step 5: Run the Forecasting Methods

Upload and run the notebooks in Snowflake:

### 5.1 Upload Notebooks to Snowflake

1. In Snowsight, go to **Projects** → **Notebooks**
2. Click **+ Notebook**
3. Click **Import .ipynb file**
4. Upload each notebook file:
   - `1_cortex_ml_forecasting.ipynb`
   - `2_xgboost_time_series.ipynb`
   - `3_snowpark_ml_forecasting.ipynb`
   - `4_comparison_all_methods.ipynb`
5. **IMPORTANT**: Add required packages (see Step 4) before running!
6. Select warehouse: `HVAC_FORECAST_WH`
7. Click **Create**

### 5.2 Run Notebook 1: Cortex ML (~30 min)

**File**: `1_cortex_ml_forecasting.ipynb`

**What it does**:
- SQL-based forecasting with Cortex ML
- Prepares data in required format (DS, Y columns)
- Trains model and generates 52-week forecasts
- Creates validation views

**Output**: `CORTEX_ML_FORECASTS` table

**Run all cells sequentially**. At the end you should see:
```
✅ VALIDATION CHECKS
  WEEKS_CHECK: ✅ PASS
  POSITIVE_CHECK: ✅ PASS
```

### 5.3 Run Notebook 2: XGBoost (~90 min) 🔥

**File**: `2_xgboost_time_series.ipynb`

**Prerequisites**: Must have added `xgboost` and `scikit-learn` packages!

**What it does**:
- Engineers advanced features (lags, rolling stats, interactions)
- Trains custom XGBoost model
- Evaluates with MAE, RMSE, R² metrics
- Shows feature importance
- Generates 52-week forecasts

**Output**: `XGBOOST_FORECASTS` table, `XGBOOST_FEATURES` table

**Run all cells sequentially**. You should see:
```
✅ XGBoost/sklearn available - will use ML model
Training XGBoost model...
MAE: ~45-50 units
RMSE: ~60-70 units
R²: ~0.85-0.92
```

### 5.4 Run Notebook 3: Snowpark ML (~60 min) ⭐

**File**: `3_snowpark_ml_forecasting.ipynb`

**Prerequisites**: Must have added `snowflake-ml-python`, `xgboost`, and `scikit-learn` packages!

**What it does**:
- Uses Snowpark ML preprocessing pipelines
- Trains with Snowpark ML APIs
- Registers model in Model Registry
- Generates 52-week forecasts
- Provides governance and versioning

**Output**: `SNOWPARK_ML_FORECASTS` table, model in registry

**Run all cells sequentially**. Should proceed directly to training (no "not available" message).

**This is the RECOMMENDED method for production!**

### 5.5 Run Notebook 4: Comparison (~30 min)

**File**: `4_comparison_all_methods.ipynb`

**Prerequisites**: Must have run notebooks 1, 2, and 3 first!

**What it does**:
- Compares all three methods side-by-side
- Analyzes regional and product-level differences
- Provides decision framework
- Creates unified comparison views

**Output**: `FORECAST_METHOD_COMPARISON` table

**Run all cells sequentially**. You'll see comprehensive comparisons and recommendations.

---

## Step 6: Deploy Interactive Comparison Dashboard ⭐ (Recommended)

**This is the BEST way to visualize and compare all three forecasting methods!**

### 6.1 Create Streamlit App in Snowflake

1. In Snowsight, go to **Projects** → **Streamlit**
2. Click **+ Streamlit App**
3. Enter app details:
   - **Name**: `HVAC Forecast Comparison Dashboard`
   - **Database**: `HVAC_FORECAST_DB`
   - **Schema**: `FORECAST_DATA`
   - **Warehouse**: `HVAC_FORECAST_WH`
4. Click **Create**

### 6.2 Add Required Package

**IMPORTANT**: Before uploading the code, add the required package:

1. In the Streamlit app editor, click **Packages** (top toolbar)
2. Search for and add: `plotly` (for interactive charts)
3. Click **Apply**

### 6.3 Upload Dashboard Code

1. Delete the default code in the editor
2. Open `forecast_comparison_dashboard.py` from this project
3. Copy ALL the code
4. Paste into the Streamlit editor
5. Click **Run** (top right)

### 6.4 What the Dashboard Shows

The interactive dashboard provides:

**📈 6 Interactive Tabs:**
1. **Forecast Trends** - 52-week trends with all 3 methods overlaid
2. **Regional Comparison** - Compare forecasts by region
3. **Product Breakdown** - Compare by product type
4. **Seasonal Patterns** - Seasonal demand analysis
5. **Accuracy Metrics** - MAE, RMSE, R² comparison with holdout test
6. **Historical vs Predicted** - Visual validation of forecast quality

**🎛️ Interactive Filters:**
- Region selector (multi-select)
- Product selector (multi-select)
- Customer segment selector
- Method toggle (compare 1, 2, or all 3 methods)

**📊 Clear Method Labeling:**
- **Cortex ML**: Labeled as "Cortex ML Function" (SQL-based)
- **XGBoost**: Labeled as "XGBoost Model" (Python trained)
- **Snowpark ML**: Labeled as "Snowpark ML Model + Registry" (Enterprise)

**📝 Copy-Paste SQL Queries:**
- Each tab includes SQL queries you can copy and run in SQL Worksheets
- Queries for all visualization views included

### 6.5 Using the Dashboard

**To explore:**
1. Use sidebar filters to select regions/products
2. Toggle between tabs to see different views
3. Click on method expandable sections for pros/cons
4. Copy SQL queries from each tab for further analysis

**To share:**
- Click **Share** (top right) to give access to colleagues
- Share link works for anyone with Snowflake access

**Cost**: The warehouse runs while the dashboard is open, then auto-suspends after 15 minutes of inactivity.

---

## Step 7: Quick SQL Queries (Alternative to Dashboard)

If you prefer SQL worksheets, here are quick queries for each method:

### Cortex ML Forecasts
```sql
-- View all Cortex ML forecasts
SELECT * FROM CORTEX_ML_FORECASTS;

-- Time series visualization
SELECT * FROM CORTEX_ML_VIZ_TIMESERIES;

-- Regional comparison
SELECT * FROM CORTEX_ML_VIZ_REGIONAL;
```

### XGBoost Forecasts
```sql
-- View all XGBoost forecasts
SELECT * FROM XGBOOST_FORECASTS;

-- Time series visualization
SELECT * FROM XGBOOST_VIZ_TIMESERIES;

-- Regional comparison
SELECT * FROM XGBOOST_VIZ_REGIONAL;

-- Feature importance
SELECT * FROM XGBOOST_FEATURES LIMIT 100;
```

### Snowpark ML Forecasts
```sql
-- View all Snowpark ML forecasts
SELECT * FROM SNOWPARK_ML_FORECASTS;

-- Time series visualization
SELECT * FROM SNOWPARK_ML_VIZ_TIMESERIES;

-- Regional comparison
SELECT * FROM SNOWPARK_ML_VIZ_REGIONAL;

-- Check model in registry
SHOW MODELS IN SCHEMA FORECAST_DATA;
```

### Compare All Methods
```sql
-- Combined view of all methods
SELECT * FROM ALL_METHODS_COMBINED;

-- Weekly totals by method
SELECT 
    WEEK_START_DATE,
    METHOD,
    SUM(FORECAST_DEMAND) AS TOTAL_FORECAST
FROM ALL_METHODS_COMBINED
GROUP BY WEEK_START_DATE, METHOD
ORDER BY WEEK_START_DATE, METHOD;

-- Regional comparison across methods
SELECT 
    REGION,
    SUM(CASE WHEN METHOD = 'Cortex_ML' THEN FORECAST_DEMAND END) AS CORTEX_ML,
    SUM(CASE WHEN METHOD = 'XGBoost' THEN FORECAST_DEMAND END) AS XGBOOST,
    SUM(CASE WHEN METHOD = 'Snowpark_ML' THEN FORECAST_DEMAND END) AS SNOWPARK_ML
FROM ALL_METHODS_COMBINED
GROUP BY REGION
ORDER BY CORTEX_ML DESC;
```

---

## 📊 What You Get

### Dataset
- **22,464 records** of HVAC demand
- **3 years** (156 weeks) from 2022-2024
- **8 regions** (Rocky Mountains, Pacific NW, New England, etc.)
- **6 products** (Heat Pumps, Furnaces, Air Handlers, Parts, Maintenance)
- **3 segments** (B2C, B2B, B2G)

### Forecasts
- **52-week forecasts** for each method
- **By region, product, and customer segment**
- **Validation checks** built into each notebook
- **Visualization views** ready to chart

### Comparison
- **Side-by-side comparison** of all three methods
- **Decision framework** for method selection
- **Performance metrics** and insights

---

## 🎓 When to Use Each Method

### Use Cortex ML When:
- ✅ Need quick insights for executives
- ✅ Team primarily uses SQL
- ✅ Standard time series patterns
- ✅ Limited ML expertise
- ✅ Rapid prototyping

### Use XGBoost When:
- ✅ Complex demand patterns
- ✅ Need maximum customization
- ✅ Feature engineering is critical
- ✅ Model explainability required
- ✅ Have experienced data scientists

### Use Snowpark ML When: ⭐
- ✅ Building production ML platforms
- ✅ Need model governance/versioning
- ✅ Standardizing on Snowflake ML
- ✅ Require scalable workflows
- ✅ ML Ops capabilities needed

**Recommended**: Use all three for different purposes (hybrid approach)!

---

## 🐛 Troubleshooting

### Issue: "Anaconda packages not available"
**Solution**: 
- Contact your Snowflake admin
- Need ACCOUNTADMIN to enable in Admin → Billing & Terms → Anaconda

### Issue: "Package not found" when searching
**Solution**:
- Make sure Anaconda is enabled first (see above)
- Search exact names: `xgboost` (lowercase), `scikit-learn` (with hyphen), `snowflake-ml-python`
- Check you're in Snowflake Notebooks (not regular SQL worksheet)

### Issue: Still seeing "not available" messages after adding packages
**Solution**:
- Restart the notebook after adding packages
- Verify packages are listed in the Packages panel
- Check you added ALL required packages (e.g., Notebook 3 needs 3 packages)

### Issue: "Cortex ML functions not available"
**Solution**:
- Cortex ML may not be enabled in your Snowflake account
- The notebook includes statistical baseline fallback (still works)
- Contact Snowflake support to enable Cortex ML

### Issue: "Warehouse suspended" error
**Solution**:
```sql
ALTER WAREHOUSE HVAC_FORECAST_WH RESUME;
```

### Issue: Data load fails
**Solution**:
- Use absolute file paths
- Verify CSV file exists in the location
- Check role has INSERT privileges

### Issue: Import errors in notebooks
**Solution**:
- Ensure Container Runtime is enabled for your account
- Verify you're using Snowflake Notebooks (not external Python)
- Restart the notebook

### Issue: SQL function errors (WEEK_OF_YEAR, etc.)
**Solution**:
- Already fixed in current notebooks
- If you see this, re-upload the latest notebook files

---

## 💡 Pro Tips

### Performance
- **MEDIUM warehouse** is recommended for this dataset (3 years weekly data)
- Warehouse auto-suspends after 5 minutes to save costs
- Total lab cost: ~2-3 Snowflake credits

### Data Generation
- Modify `generate_hvac_data.py` to change:
  - Number of weeks (`num_weeks` variable)
  - Regions, products, or segments (update lists)
  - Seasonal patterns (adjust multipliers)

### Running Notebooks
- **Run cells in order** (don't skip or run out of sequence)
- **Wait for each cell to complete** before running next
- **Check for ✅ PASS** in validation sections

### Package Management
- You can add/remove packages anytime via Packages panel
- Restart notebook after package changes
- Packages persist for that notebook (don't need to re-add)

---

## 🎯 Success Checklist

- [ ] Data generated (`thisisclayco_hvac_demand_data.csv` exists)
- [ ] Snowflake environment setup complete (`setup.sql` run)
- [ ] Data loaded (~22K records in `HVAC_DEMAND_RAW`)
- [ ] Anaconda enabled in Snowflake
- [ ] Packages added to Notebook 2 (`xgboost`, `scikit-learn`)
- [ ] Packages added to Notebook 3 (`snowflake-ml-python`, `xgboost`, `scikit-learn`)
- [ ] Notebook 1 complete (✅ PASS in validation)
- [ ] Notebook 2 complete (✅ PASS in validation)
- [ ] Notebook 3 complete (✅ PASS in validation)
- [ ] Notebook 4 complete (comparison results shown)
- [ ] **Dashboard deployed** (Streamlit app running with `plotly` package) ⭐
- [ ] Understand when to use each method

---

## 📚 Quick Reference

### Key SQL Commands

```sql
-- Check data
SELECT COUNT(*) FROM HVAC_DEMAND_RAW;

-- View forecasts
SELECT * FROM CORTEX_ML_FORECASTS LIMIT 10;
SELECT * FROM XGBOOST_FORECASTS LIMIT 10;
SELECT * FROM SNOWPARK_ML_FORECASTS LIMIT 10;

-- Compare methods
SELECT METHOD, COUNT(*), AVG(FORECAST_DEMAND)
FROM FORECAST_METHOD_COMPARISON
GROUP BY METHOD;

-- Resume warehouse
ALTER WAREHOUSE HVAC_FORECAST_WH RESUME;

-- Suspend warehouse manually (auto-suspends after 5 min anyway)
ALTER WAREHOUSE HVAC_FORECAST_WH SUSPEND;
```

### File Summary

| File | Purpose |
|------|---------|
| `generate_hvac_data.py` | Generate synthetic HVAC demand data |
| `setup.sql` | Create Snowflake environment |
| `1_cortex_ml_forecasting.ipynb` | Method 1: SQL-based Cortex ML |
| `2_xgboost_time_series.ipynb` | Method 2: Custom XGBoost ML |
| `3_snowpark_ml_forecasting.ipynb` | Method 3: Snowpark ML workflow |
| `4_comparison_all_methods.ipynb` | Compare all methods |
| `forecast_comparison_dashboard.py` | Interactive Streamlit dashboard ⭐ |

---

## 🚀 Ready to Start!

```bash
# Step 1: Generate data
python generate_hvac_data.py

# Step 2-3: Open Snowsight
# → Run setup.sql
# → Load CSV file

# Step 4: Enable Anaconda and add packages to notebooks

# Step 5: Run notebooks (1, 2, 3, 4)

# Step 6: Deploy Streamlit dashboard ⭐ (Recommended!)
# → Projects → Streamlit → Create app
# → Add plotly package
# → Paste forecast_comparison_dashboard.py code
# → Run and explore!

# Step 7: Or use SQL queries for quick analysis
```

**Total Time**: 2-3 hours for complete lab (+ 10 min for dashboard)

**Have questions?** See Troubleshooting section above!

---

**Let's forecast! 📈**
