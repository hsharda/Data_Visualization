#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Sep 28 00:44:55 2019

@author: harshsharda
"""
# Global Data Lab: https://globaldatalab.org/areadata/hhsize/?interpolation=1&extrapolation=1&extrapolation_years=3&nearest_real=0
# WRI: http://datasets.wri.org/dataset/globalpowerplantdatabase
# WB: Access to Electricity; https://data.worldbank.org/indicator/EG.ELC.ACCS.RU.ZS
# WB: World Development Indicators
# WB: GDP per capita, PPP https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.CD
 
import pandas as pd
import numpy as np
import geopandas as gdp
import descartes
from shapely.geometry import Point,Polygon
import seaborn as sns
import matplotlib.pyplot as plt
from pandas.plotting import scatter_matrix

#Importing the dataset
power_plant_data = pd.read_csv("Data/Powerplant/global_power_plant_database.csv")
gdp_ppp_data = pd.read_csv("Data/WB_Data/API_NY.GDP.PCAP.PP.CD_DS2_en_csv_v2_199565.csv", skiprows = 4)
total_population = pd.read_csv("Data/WB_Data/API_19_DS2_en_csv_v2_200848.csv", skiprows = 4)
co2_emissions_capita = pd.read_csv("Data/WB_Data/API_EN.ATM.CO2E.PC_DS2_en_csv_v2_240835.csv", skiprows = 4)
co2_emissions_total = pd.read_csv("Data/WB_Data/API_EN.ATM.CO2E.KT_DS2_en_csv_v2_248027.csv", skiprows = 4)

# Data Wrangling

#Renaming the merging variable
power_plant_data = power_plant_data.rename(columns = {'country':'country_code','country_long':'country_name'})

list(power_plant_data.columns.values)

power_plant_data = power_plant_data[['country_code','country_name','name','capacity_mw',
                                     'latitude','longitude','primary_fuel']]

#Population Data
total_population = total_population[total_population['Indicator Name'] == 'Population, total'][['Country Name','Country Code','2017','2018']].rename(columns = {'2017':'pop_2017','2018':'pop_2018'})

#CO2 emissions 
co2_emissions_capita = co2_emissions_capita[['Country Name','Country Code','2014']].rename(columns = {'2014': 'emissions_capita_2014'})
co2_emissions_total = co2_emissions_total[['Country Name','Country Code','2014']].rename(columns = {'2014': 'emissions_total_2014'})

#GDP Data
gdp_ppp_data = gdp_ppp_data[['Country Name','Country Code','2016','2017','2018']].rename(columns = {'2016': 'gdp_2016','2017':'gdp_2017','2018':'gdp_2018'})

#Data Cleaning & performing EDA to check if they should be dropped

#Checking the null and na values
power_plant_data.isna().sum()

#Dropping columns with missing values
power_plant_data = power_plant_data.drop(['commissioning_year','owner','source','url','gppd_idnr',
                                          'geolocation_source','wepp_id','year_of_capacity_data',
                                          'generation_gwh_2013','generation_gwh_2014','generation_gwh_2015',
                                          'generation_gwh_2016','generation_gwh_2017','estimated_generation_gwh'],axis = 1)

# Creating new variables

pp_dummies = pd.get_dummies(power_plant_data['primary_fuel'], prefix = 'primary_fuel')
power_plant_data = pd.concat([power_plant_data, pp_dummies], axis=1)

#To get a list of variables

list(power_plant_data.columns.values)

# Grouping by the data at country level
pp_data_group = pd.DataFrame(power_plant_data.groupby(['Country Code','Country Name'])['capacity_mw',
                             'primary_fuel_Biomass','primary_fuel_Coal','primary_fuel_Cogeneration',
                             'primary_fuel_Gas','primary_fuel_Geothermal','primary_fuel_Hydro',
                             'primary_fuel_Nuclear','primary_fuel_Oil','primary_fuel_Other',
                             'primary_fuel_Petcoke','primary_fuel_Solar','primary_fuel_Storage',
                             'primary_fuel_Waste','primary_fuel_Wave and Tidal','primary_fuel_Wind'].agg('sum').reset_index())

# Calculating the total count
pp_data_group['Total_power_plants'] = pp_data_group.loc[:,['primary_fuel_Biomass','primary_fuel_Coal','primary_fuel_Cogeneration',
                             'primary_fuel_Gas','primary_fuel_Geothermal','primary_fuel_Hydro',
                             'primary_fuel_Nuclear','primary_fuel_Oil','primary_fuel_Other',
                             'primary_fuel_Petcoke','primary_fuel_Solar','primary_fuel_Storage',
                             'primary_fuel_Waste','primary_fuel_Wave and Tidal','primary_fuel_Wind']].sum(axis=1)


merged_data = pd.merge(pp_data_group, total_population, on = ['Country Code'], how = 'left')
merged_data = pd.merge(merged_data, household_size, on = ['Country Code'], how = 'left')
merged_data = pd.merge(merged_data, percent_electricity, on = ['Country Code'], how = 'left')
merged_data = pd.merge(merged_data, gdp_ppp_data, on = ['Country Code'], how = 'left')
merged_data = pd.merge(merged_data, co2_emissions_capita, on = ['Country Code'], how = 'left')
merged_data = pd.merge(merged_data, co2_emissions_total, on = ['Country Code'], how = 'left')

difference = power_plant_data.groupby(['Country Code','primary_fuel'])['capacity_mw'].agg(['sum','count']).reset_index()
#difference = power_plant_data.groupby(['Country Code','primary_fuel']).agg({'capacity_mw':'sum','primary_fuel':'count'}).reset_index()
difference_pivot = difference.pivot(index = 'Country Code', columns = 'primary_fuel', values = ['sum','count']).reset_index()


merged_data = pd.merge(merged_data, difference_pivot, on = ['Country Code'], how = 'left')
merged_data = merged_data.drop(['Country Name_y'], axis = 1)

#Checking variables
list(merged_data.columns.values)

#Data description for outlier treatment

#Checking the null and na values
merged_data.isna().sum()

merged_data.shape[0]
# 164 columns

description = pd.DataFrame(merged_data.describe())

power_plant_data.isna().sum()
len(power_plant_data.primary_fuel.unique())
power_plants = pd.DataFrame(power_plant_data.describe())
power_plants.to_csv(r'power_plants.csv')

gdp_ppp_ds = pd.DataFrame(gdp_ppp_data.describe())
gdp_ppp_data.isna().sum()
gdp_ppp_ds.to_csv(r'gdp_ppp_ds.csv')

#Imputing missing GDP values

def modify(x):
    if pd.isna(x['gdp_2018']):
        return (x['gdp_2017']/x['gdp_2016'])*x['gdp_2017']
    else :
        return x['gdp_2018']

merged_data['gdp_2018'] = merged_data.apply(modify, axis = 1)
merged_data.isna().sum()

#Dropping NA values in the GDP 2018 column
merged_data_clean = merged_data.dropna(subset = ['gdp_2018'])
merged_data_clean.isna().sum()

merged_data_clean.to_csv(r'final_data.csv')
merged_data.to_csv(r'../Data/final_data_complete.csv',index = False)

#Plotting

final_data = pd.read_csv("../Data/DataViz memo_hs957.csv")

## Scatterplot in R

plot_data = merged_data[['gdp_2016','gdp_2017','gdp_2018']]
sns.boxplot(x="variable", y="value", data=pd.melt(plot_data))
plt.title("Box Plot with GDP Variables")
plt.xlabel("GDP Variables")
plt.ylabel("GDP Numbers")
plt.show()

merged_data.plot(title = "Operating Capacity (MW)",kind ='hist',y = 'gdp_2018',bins = 30)



# Making it into timeseries data

gdp_ppp_tut = pd.read_csv("../Data/API_NY.GDP.PCAP.PP.CD_DS2_en_csv_v2_199565.csv", skiprows = 4)
gdp_ppp_tut_sub = gdp_ppp_tut[['Country Name','2011','2012','2013','2014','2015','2016','2017','2018']]
gdp_ppp_final = gdp_ppp_tut_sub.loc[(gdp_ppp_tut_sub['Country Name'] == "India")
                                    |(gdp_ppp_tut_sub['Country Name'] == "United States")|(gdp_ppp_tut_sub['Country Name'] == "China")].reset_index(drop = True)

gdp_pivot = gdp_ppp_final.set_index('Country Name').T.rename_axis('Year').rename_axis(None, 1).reset_index()
gdp_pivot.Year = pd.to_datetime(gdp_pivot.Year, format='%Y')
gdp_pivot.to_csv(r'../Data/gdp_pivot.csv', index = False)


# GDP RATE

gdp_ppp_rate = pd.read_csv("../Data/API_NY.GDP.PCAP.KD.ZG_DS2_en_csv_v2_422038.csv", skiprows = 4)
gdp_ppp_rate_sub = gdp_ppp_rate[['Country Name','2011','2012','2013','2014','2015','2016','2017','2018']]
gdp_final_rate = gdp_ppp_rate_sub.loc[(gdp_ppp_rate_sub['Country Name'] == "India")
                                    |(gdp_ppp_rate_sub['Country Name'] == "United States")|(gdp_ppp_rate_sub['Country Name'] == "China")].reset_index(drop = True)

gdp_pivot_rate = gdp_final_rate.set_index('Country Name').T.rename_axis('Year').rename_axis(None, 1).reset_index()
gdp_pivot_rate.Year = pd.to_datetime(gdp_pivot_rate.Year, format='%Y')
gdp_pivot_rate.to_csv(r'../Data/gdp_pivot_rate.csv', index = False)
                           


         
# Extra stuff


world_map.plot()
crs = {'init': 'epsg:4326'}
geometry = [Point(xy) for xy in zip(power_plant_data["latitude"],power_plant_data["longitude"])]
geo_df = gdp.GeoDataFrame(power_plant_data,
                          crs = crs,
                          geometry = geometry)

fig,ax = plt.subplots(figsize = (5,5))
world_map.plot(ax = ax, alpha = 0.4, color = 'grey')
geo_df.plot(ax = ax, markersize = 20, color = 'blue', marker = 'o', label = 'Neg')
#plt.legend()
plt.show()


print(scatter_matrix(power_plant_data))

import plotly.express as px
iris = px.data.iris()
fig = px.scatter_matrix(iris)
fig.show()


plt.hist(merged_data['gdp_2018'], 30, facecolor='blue', alpha=0.5)


import plotly.graph_objects as go
fig = go.Figure(data=go.Splom(
                dimensions=[dict(label='sepal length',
                                 values=power_plant_data['sepal length']),
                            dict(label='sepal width',
                                 values=power_plant_data['sepal width']),
                            dict(label='petal length',
                                 values=power_plant_data['petal length']),
                            dict(label='petal width',
                                 values=power_plant_data['petal width'])],
                diagonal_visible=False, # remove plots on diagonal
                text=df['class'],
                marker=dict(color=index_vals,
                            showscale=False, # colors encode categorical variables
                            line_color='white', line_width=0.5)
                ))
                
                
import pandas as pd
print(pd.__version__)