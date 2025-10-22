"""
Generate synthesized HVAC demand data for ThisIsClay Co
3 years of weekly data with seasonal patterns, regional variations, and customer segments
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# Set random seed for reproducibility
np.random.seed(42)

# Configuration
START_DATE = datetime(2022, 1, 3)  # Monday, Jan 3, 2022
WEEKS = 156  # 3 years of weekly data
FORECAST_WEEKS = 52  # 1 year forecast horizon

# Regions - ThisIsClay Co operates in extreme cold/high-altitude markets
REGIONS = [
    'CO_Rocky_Mountains',
    'UT_High_Elevation', 
    'WY_Mountain',
    'MT_Northern',
    'ID_Mountain',
    'CA_NV_Tahoe',
    'OR_WA_Pacific_NW',
    'VT_ME_NH_New_England'
]

# Products - specialized HVAC systems
PRODUCTS = [
    'Cold_Climate_Heat_Pump',
    'Variable_Gas_Furnace',
    'Standard_Air_Handler',
    'High_Altitude_Air_Handler',
    'Replacement_Parts',
    'Maintenance_Contract'
]

# Customer Segments
SEGMENTS = ['B2B', 'B2G', 'B2C']

# Product base prices (in dollars)
PRODUCT_PRICES = {
    'Cold_Climate_Heat_Pump': 8500,
    'Variable_Gas_Furnace': 4500,
    'Standard_Air_Handler': 2800,
    'High_Altitude_Air_Handler': 3500,
    'Replacement_Parts': 350,
    'Maintenance_Contract': 1200
}

# Regional population/market size factors (relative demand multipliers)
REGION_FACTORS = {
    'CO_Rocky_Mountains': 1.5,  # Largest market - HQ location
    'UT_High_Elevation': 1.2,
    'WY_Mountain': 0.6,
    'MT_Northern': 0.7,
    'ID_Mountain': 0.8,
    'CA_NV_Tahoe': 1.3,
    'OR_WA_Pacific_NW': 1.4,
    'VT_ME_NH_New_England': 1.1
}

# Customer segment mix by product (probabilities)
SEGMENT_MIX = {
    'Cold_Climate_Heat_Pump': {'B2B': 0.25, 'B2G': 0.15, 'B2C': 0.60},
    'Variable_Gas_Furnace': {'B2B': 0.30, 'B2G': 0.20, 'B2C': 0.50},
    'Standard_Air_Handler': {'B2B': 0.35, 'B2G': 0.25, 'B2C': 0.40},
    'High_Altitude_Air_Handler': {'B2B': 0.40, 'B2G': 0.30, 'B2C': 0.30},
    'Replacement_Parts': {'B2B': 0.30, 'B2G': 0.20, 'B2C': 0.50},
    'Maintenance_Contract': {'B2B': 0.45, 'B2G': 0.30, 'B2C': 0.25}
}

def generate_temperature_data(week_num, region):
    """Generate realistic temperature data for each region"""
    # Base temperature varies by region and season
    season_factor = np.sin((week_num / 52) * 2 * np.pi - np.pi/2)  # -1 to 1, coldest at winter
    
    region_base_temps = {
        'CO_Rocky_Mountains': 35,
        'UT_High_Elevation': 38,
        'WY_Mountain': 30,
        'MT_Northern': 28,
        'ID_Mountain': 32,
        'CA_NV_Tahoe': 36,
        'OR_WA_Pacific_NW': 42,
        'VT_ME_NH_New_England': 34
    }
    
    base_temp = region_base_temps[region]
    seasonal_swing = 35  # Temperature varies by 35 degrees from summer to winter
    avg_temp = base_temp + season_factor * seasonal_swing
    
    # Add some random variation
    return avg_temp + np.random.normal(0, 5)

def generate_economic_indicator(week_num):
    """Generate economic confidence index (0-100)"""
    # Trend upward with some volatility
    trend = 70 + (week_num / WEEKS) * 15  # 70 to 85 over 3 years
    noise = np.random.normal(0, 5)
    return max(50, min(100, trend + noise))

def generate_housing_starts(week_num, region):
    """Generate housing starts index for the region"""
    # Seasonal pattern (higher in spring/summer)
    season_factor = np.sin((week_num / 52) * 2 * np.pi) * 0.3 + 1.0  # 0.7 to 1.3
    
    # Regional base levels
    regional_base = {
        'CO_Rocky_Mountains': 150,
        'UT_High_Elevation': 120,
        'WY_Mountain': 40,
        'MT_Northern': 50,
        'ID_Mountain': 60,
        'CA_NV_Tahoe': 100,
        'OR_WA_Pacific_NW': 140,
        'VT_ME_NH_New_England': 80
    }
    
    base = regional_base[region]
    return int(base * season_factor + np.random.normal(0, 10))

def calculate_seasonality_factor(week_num, product):
    """Calculate seasonal demand multiplier based on product type"""
    # Week of year (0-51)
    week_of_year = week_num % 52
    
    # Different products have different seasonal patterns
    if product in ['Cold_Climate_Heat_Pump', 'Variable_Gas_Furnace']:
        # Heating systems: Peak demand in fall (weeks 35-45) and early winter (weeks 45-10)
        # Lowest in summer (weeks 20-35)
        if 35 <= week_of_year <= 45:  # Fall - highest demand
            return 1.8
        elif (week_of_year >= 45) or (week_of_year <= 10):  # Winter - high demand
            return 1.5
        elif 10 < week_of_year <= 20:  # Spring - moderate
            return 1.1
        else:  # Summer - lowest
            return 0.6
            
    elif 'Air_Handler' in product:
        # Air handlers: More consistent, slight peak in spring/fall
        if week_of_year in range(15, 25) or week_of_year in range(35, 45):
            return 1.3
        return 1.0
        
    elif product == 'Replacement_Parts':
        # Parts: Spike in winter when systems fail, consistent otherwise
        if (week_of_year >= 48) or (week_of_year <= 8):  # Deep winter
            return 1.7
        return 1.0
        
    elif product == 'Maintenance_Contract':
        # Maintenance: Peak in spring/fall shoulder seasons
        if week_of_year in range(12, 22) or week_of_year in range(38, 48):
            return 1.4
        return 0.9
        
    return 1.0

def generate_base_demand(product):
    """Generate base weekly demand for a product"""
    base_demands = {
        'Cold_Climate_Heat_Pump': 45,
        'Variable_Gas_Furnace': 55,
        'Standard_Air_Handler': 35,
        'High_Altitude_Air_Handler': 28,
        'Replacement_Parts': 180,
        'Maintenance_Contract': 25
    }
    return base_demands[product]

def generate_hvac_data():
    """Generate the complete HVAC demand dataset"""
    
    records = []
    
    for week_num in range(WEEKS):
        week_date = START_DATE + timedelta(weeks=week_num)
        
        for region in REGIONS:
            # Generate external factors for this week/region
            avg_temp = generate_temperature_data(week_num, region)
            economic_index = generate_economic_indicator(week_num)
            housing_starts = generate_housing_starts(week_num, region)
            
            for product in PRODUCTS:
                # Base demand for product
                base_demand = generate_base_demand(product)
                
                # Apply multipliers
                region_factor = REGION_FACTORS[region]
                seasonality = calculate_seasonality_factor(week_num, product)
                
                # Temperature impact (colder = more heating equipment demand)
                if product in ['Cold_Climate_Heat_Pump', 'Variable_Gas_Furnace']:
                    temp_factor = 1.0 + (50 - avg_temp) / 100  # Colder = higher demand
                else:
                    temp_factor = 1.0
                
                # Housing starts impact (more construction = more equipment)
                if product not in ['Replacement_Parts', 'Maintenance_Contract']:
                    housing_factor = 1.0 + (housing_starts / 1000)
                else:
                    housing_factor = 1.0
                
                # Economic impact
                economic_factor = 0.7 + (economic_index / 100) * 0.6  # 0.7 to 1.3
                
                # Growth trend (company growing 15% per year)
                growth_factor = 1.0 + (week_num / WEEKS) * 0.45  # 1.0 to 1.45 over 3 years
                
                # Calculate total demand
                total_demand = (base_demand * region_factor * seasonality * 
                              temp_factor * housing_factor * economic_factor * growth_factor)
                
                # Add random noise
                noise = np.random.normal(1.0, 0.15)
                total_demand = max(0, int(total_demand * noise))
                
                # Split by customer segment
                for segment in SEGMENTS:
                    segment_pct = SEGMENT_MIX[product][segment]
                    segment_demand = int(total_demand * segment_pct)
                    
                    if segment_demand > 0 or np.random.random() > 0.7:  # Keep some zero values
                        revenue = segment_demand * PRODUCT_PRICES[product]
                        
                        # B2G often has bulk discounts
                        if segment == 'B2G' and segment_demand > 0:
                            revenue *= 0.92
                        
                        # B2B can have volume discounts
                        elif segment == 'B2B' and segment_demand > 0:
                            revenue *= 0.95
                        
                        record = {
                            'WEEK_START_DATE': week_date.strftime('%Y-%m-%d'),
                            'YEAR': week_date.year,
                            'QUARTER': f'Q{(week_date.month-1)//3 + 1}',
                            'MONTH': week_date.month,
                            'WEEK_OF_YEAR': week_date.isocalendar()[1],
                            'REGION': region,
                            'PRODUCT': product,
                            'CUSTOMER_SEGMENT': segment,
                            'DEMAND_UNITS': segment_demand,
                            'REVENUE': round(revenue, 2),
                            'AVG_TEMPERATURE_F': round(avg_temp, 1),
                            'ECONOMIC_INDEX': round(economic_index, 1),
                            'HOUSING_STARTS': housing_starts,
                            'IS_HOLIDAY_WEEK': 1 if week_date.month == 12 and week_date.day >= 20 else 0,
                            'IS_WINTER': 1 if week_date.month in [12, 1, 2] else 0,
                            'IS_SPRING': 1 if week_date.month in [3, 4, 5] else 0,
                            'IS_SUMMER': 1 if week_date.month in [6, 7, 8] else 0,
                            'IS_FALL': 1 if week_date.month in [9, 10, 11] else 0
                        }
                        
                        records.append(record)
    
    df = pd.DataFrame(records)
    return df

def main():
    print("Generating ThisIsClay Co HVAC demand data...")
    print(f"Time period: {WEEKS} weeks (3 years)")
    print(f"Regions: {len(REGIONS)}")
    print(f"Products: {len(PRODUCTS)}")
    print(f"Customer Segments: {len(SEGMENTS)}")
    
    df = generate_hvac_data()
    
    print(f"\nGenerated {len(df)} records")
    print(f"Date range: {df['WEEK_START_DATE'].min()} to {df['WEEK_START_DATE'].max()}")
    print(f"Total demand units: {df['DEMAND_UNITS'].sum():,.0f}")
    print(f"Total revenue: ${df['REVENUE'].sum():,.2f}")
    
    # Save to CSV
    output_file = 'thisisclayco_hvac_demand_data.csv'
    df.to_csv(output_file, index=False)
    print(f"\nData saved to: {output_file}")
    
    # Print summary statistics
    print("\n=== Summary Statistics ===")
    print("\nDemand by Region:")
    print(df.groupby('REGION')['DEMAND_UNITS'].sum().sort_values(ascending=False))
    
    print("\nDemand by Product:")
    print(df.groupby('PRODUCT')['DEMAND_UNITS'].sum().sort_values(ascending=False))
    
    print("\nDemand by Customer Segment:")
    print(df.groupby('CUSTOMER_SEGMENT')['DEMAND_UNITS'].sum().sort_values(ascending=False))
    
    print("\nRevenue by Customer Segment:")
    print(df.groupby('CUSTOMER_SEGMENT')['REVENUE'].sum().sort_values(ascending=False))

if __name__ == "__main__":
    main()

