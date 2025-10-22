# ❄️ Snowflake HVAC Demand Forecasting Lab

Compare three forecasting methods in Snowflake: Cortex ML, XGBoost, and Snowpark ML

## 🏔️ About ThisIsClay Co

ThisIsClay Co is an HVAC distribution company specializing in cold weather and high-elevation markets across North America (Rocky Mountains, Pacific Northwest, New England).

## 🎯 What This Lab Covers

This hands-on lab demonstrates **three forecasting methods** using realistic HVAC demand data (3 years, 22K+ records):

1. **Cortex ML** - SQL-based, auto-generated features (~30 min)
2. **XGBoost** - Custom ML with 25+ features (weather, economic data) (~90 min)
3. **Snowpark ML** - Enterprise ML with Model Registry (~60 min) ⭐ **RECOMMENDED**

<img width="2096" height="776" alt="image" src="https://github.com/user-attachments/assets/08a4b07c-92fc-4043-9d69-9ffd9445ba6c" />


## 📊 Lab Data

Synthetic weekly data with realistic patterns including:
- Demand & Revenue tracking by region/product/segment
- Seasonal factors (winter peaks, summer variations)
- Temperature data affecting HVAC demand
- Economic indicators (GDP, unemployment, consumer confidence)
- Housing starts data
- Market segments (B2C, B2B, B2G)

## 🚀 Quick Start

**Total Time**: 2-3 hours for complete lab

1. **Generate data**: Run `python generate_hvac_data.py`
2. **Setup Snowflake**: Run `setup.sql` in Snowsight
3. **Load CSV**: Upload `thisisclayco_hvac_demand_data.csv`
4. **Run notebooks**: Execute notebooks 1-4 in Snowflake
5. **Deploy dashboard**: Create Streamlit app with `forecast_comparison_dashboard.py`

📖 **Full guide**: See [QUICKSTART.md](QUICKSTART.md)

## 📁 Repository Contents

| File | Purpose |
|------|---------|
| `QUICKSTART.md` | Complete step-by-step guide |
| `generate_hvac_data.py` | Generate synthetic HVAC data |
| `setup.sql` | Snowflake environment setup |
| `1_cortex_ml_forecasting.ipynb` | Method 1: Cortex ML (SQL-based) |
| `2_xgboost_time_series.ipynb` | Method 2: XGBoost (custom ML) |
| `3_snowpark_ml_forecasting.ipynb` | Method 3: Snowpark ML |
| `4_comparison_all_methods.ipynb` | Compare all methods |
| `forecast_comparison_dashboard.py` | Interactive Streamlit dashboard |
| `thisisclayco_hvac_demand_data.csv` | Sample data (generated) |

## 🎓 When to Use Each Method

- **Cortex ML**: Quick insights, SQL-only teams, standard patterns
- **XGBoost**: Maximum accuracy, complex features, experienced data scientists
- **Snowpark ML**: Production ML, governance, enterprise scale 

## 💰 Cost

~2-3 Snowflake credits for entire lab (MEDIUM warehouse, auto-suspend enabled)

## 🔗 Resources

- [Snowflake Cortex ML](https://docs.snowflake.com/en/user-guide/ml-functions)
- [Snowpark ML](https://docs.snowflake.com/en/developer-guide/snowpark-ml/index)
- [Snowflake Notebooks](https://docs.snowflake.com/en/user-guide/ui-snowsight-notebooks)
