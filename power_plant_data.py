#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Sep 28 00:44:55 2019

@author: harshsharda
"""
# Global Data Lab: https://globaldatalab.org/areadata/hhsize/?interpolation=1&extrapolation=1&extrapolation_years=3&nearest_real=0
# WRI: http://datasets.wri.org/dataset/globalpowerplantdatabase
# WB: GDP per capita, PPP https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.CD
# WB: Carbon Emissions World Bank: Carbon Emissions; https://data.worldbank.org/indicator/EN.ATM.CO2E.PC
 
import pandas as pd
from functools import reduce

#Importing the dataset
power_plant_data = pd.read_csv("Data/Powerplant/global_power_plant_database.csv")
gdp_ppp_data = pd.read_csv("Data/WB_Data/API_NY.GDP.PCAP.PP.CD_DS2_en_csv_v2_199565.csv", skiprows = 4)
total_population = pd.read_csv("Data/WB_Data/API_19_DS2_en_csv_v2_200848.csv", skiprows = 4)
co2_emissions_capita = pd.read_csv("Data/WB_Data/API_EN.ATM.CO2E.PC_DS2_en_csv_v2_240835.csv", skiprows = 4)
co2_emissions_total = pd.read_csv("Data/WB_Data/API_EN.ATM.CO2E.KT_DS2_en_csv_v2_248027.csv", skiprows = 4)

# Data Wrangling

#Renaming the merging variable
power_plant_data = power_plant_data.rename(columns = {'country':'ISO3','country_long':'country_name'})

list(power_plant_data.columns.values)

# Selecting relevant variables
power_plant_data = power_plant_data[['ISO3','country_name','name','capacity_mw',
                                     'latitude','longitude','primary_fuel']]

power_plant_data.primary_fuel.unique()

# Defining fuel category for the type of powerplant
def category(x):
    if x == "Hydro":
        return "Renewable"
    elif x == "Wind":
        return "Renewable"
    elif x == "Nuclear":
        return "Renewable"
    elif x == "Solar":
        return "Renewable"
    elif x == "Wave and Tidal":
        return "Renewable"
    elif x == "Geothermal":
        return "Renewable"
    elif x == "Storage":
        return "Renewable"
    elif x == "Biomass":
        return "Renewable"
    else:
        return "Non-renewable"
    

power_plant_data["fuel_category"] = power_plant_data["primary_fuel"].apply(category)
power_plant_data['name'] = power_plant_data['name'].str.title()
power_plant_data['name_type'] = power_plant_data['name']+ ", " +power_plant_data['primary_fuel'] + " Powerplant"

# Creating dummies and concatinating them into the main dataset
pp_dummies = pd.get_dummies(power_plant_data['primary_fuel'], prefix = 'primary_fuel')
pp_dummies_category = pd.get_dummies(power_plant_data['fuel_category'], prefix = 'fuel_category')
power_plant_data = pd.concat([power_plant_data, pp_dummies,pp_dummies_category], axis=1)

# Exporting file
power_plant_data.to_csv(r'Data/Powerplant/power_plant_data_locations.csv', index = False)

list(power_plant_data.columns.values)

# Calculating the total capacity of the powerplants in the world
pp_data_group = pd.DataFrame(power_plant_data.groupby(['ISO3','country_name'])['capacity_mw',
                             'primary_fuel_Biomass','primary_fuel_Coal','primary_fuel_Cogeneration',
                             'primary_fuel_Gas','primary_fuel_Geothermal','primary_fuel_Hydro',
                             'primary_fuel_Nuclear','primary_fuel_Oil','primary_fuel_Other',
                             'primary_fuel_Petcoke','primary_fuel_Solar','primary_fuel_Storage',
                             'primary_fuel_Waste','primary_fuel_Wave and Tidal','primary_fuel_Wind',
                             'fuel_category_Non-renewable','fuel_category_Renewable'].agg('sum').reset_index())

# Calculating the total count
pp_data_group['Total_power_plants'] = pp_data_group.loc[:,['fuel_category_Non-renewable','fuel_category_Renewable']].sum(axis=1)


#CO2 emissions 

co2_emissions_viz = co2_emissions_total[['Country Name','Country Code','2014']].rename(columns = {'2014': 'emissions_total_2014',
                                       'Country Code': 'ISO3','Country Name':'country_name'})


## Merging both the datasets    
merged_viz1 = pd.merge(pp_data_group, co2_emissions_viz, on = ['ISO3'], how = 'left')
merged_viz1 = merged_viz1.drop(["country_name_y"], axis = 1).rename(columns = {"country_name_x":"country_name"})


# Exporting file
merged_viz1.to_csv(r'Data/Powerplant/power_plants_locations_emissions.csv', index = False)

#### For creating the plotly animated GRAPHs

## Melting CO2 emissions data

co2_emissions_viz = co2_emissions_total.rename(columns = {'Country Code': 'ISO3','Country Name':'country_name'}).drop(["Indicator Code"], axis = 1)

years_list_em = list(co2_emissions_viz.columns.values)
years_chosen_em = years_list_em[years_list_em.index('2000'):years_list_em.index('2014')+1]

co2_emissions_viz1 = co2_emissions_viz.dropna(subset = years_chosen_em)


co2_emissions_melt = pd.melt(co2_emissions_viz1, id_vars = ["ISO3","country_name"],
                             value_vars = years_chosen_em).sort_values(["country_name","variable"]).rename(columns = {"variable": "years",
                            "value":"Emissions"}).reset_index(drop = True)

## Melting GDP PPP Data
    
gdp_viz = gdp_ppp_data.rename(columns = {'Country Code': 'ISO3','Country Name':'country_name'}).drop(["Indicator Code"], axis = 1)

years_list_gdp = list(gdp_viz.columns.values)
years_chosen_gdp = years_list_gdp[years_list_gdp.index('2000'):years_list_gdp.index('2014')+1]

gdp_viz1 = gdp_viz.dropna(subset = years_chosen_gdp)

gdp_melt = pd.melt(gdp_viz1, id_vars = ["ISO3","country_name"],
                             value_vars = years_chosen_gdp).sort_values(["country_name","variable"]).rename(columns = {"variable": "years",
                            "value":"gdp_ppp"}).reset_index(drop = True)

    
## Melting Population Data
    
pop_viz = total_population[total_population['Indicator Name'] == 'Population, total'].rename(columns = {'Country Code': 'ISO3','Country Name':'country_name'}).drop(["Indicator Code"], axis = 1)

pop_list = list(pop_viz.columns.values)
pop_chosen = pop_list[pop_list.index('2000'):pop_list.index('2014')+1]

pop_viz1 = pop_viz.dropna(subset = pop_chosen)

pop_melt = pd.melt(pop_viz1, id_vars = ["ISO3","country_name"],
                             value_vars = years_chosen_gdp).sort_values(["country_name","variable"]).rename(columns = {"variable": "years",
                            "value":"pop_size"}).reset_index(drop = True)
     
    
## Merging all the datasets

data_frames = [gdp_melt, co2_emissions_melt, pop_melt]

merged_viz = reduce(lambda  left,right: pd.merge(left,right,on=["ISO3","years"],
                                            how='left'), data_frames).drop(["country_name_y","country_name_x"], axis = 1)

pp_data_group_subset = pp_data_group["ISO3"]

merged_viz1 = pd.merge(pp_data_group_subset,merged_viz, on = ["ISO3"], how = 'inner')

# Exporting datasets
merged_viz1.to_csv(r'Data/Powerplant/gdp_emissions_pop.csv', index = False)