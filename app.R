# Import the required libraries
library(shiny)
library(tidyverse)
library(jsonlite)
library(gapminder)
library(plotly)
library(ggplot2)
library(scales)
library(dplyr)
library(leaflet)
library(sf)
library(htmltools)
library(rsconnect)



# Import Datasets

country_agg_data <- read.csv('Data/Powerplant/gdp_emissions_pop.csv')
powerplant_viz <- read.csv("Data/Powerplant/power_plant_data_locations.csv")
powerplant_emissions <- read.csv("Data/Powerplant/power_plants_locations_emissions.csv")
map_world <- st_read("Data/Shapefile/TM_WORLD_BORDERS-0.3.shp")

# Data Wrangling Tasks

## For Sunbursts charts

# Calculating the sum across each country name, fuel category and primary fuel

check1 <- powerplant_viz %>%
  group_by(country_name,fuel_category,primary_fuel) %>%
  summarize(tot_capacity = sum(round(capacity_mw)))

# Calculating the sum on the total level and appending it into one dataset

grandTotals <- check1 %>%
  group_by(fuel_category,primary_fuel) %>%
  summarize(Name = "All",
            tot_capacity = sum(round(tot_capacity))) %>%
  rename(country_name = Name) %>%
  bind_rows(check1)

## For GDP PPP vs Emissions Data

ylab <- c(0, 2.5, 5.0, 7.5, 10, 12.5)
xlab <- c(0, 2.5, 5.0, 7.5 ,10.0)
legend <- c(2.5,5.0,7.5,10.0)

country_agg_data$country_col <- country_agg_data$country_name

# Extracting the list of all powerplant types

ls <- grandTotals %>% spread(primary_fuel, tot_capacity, fill = 0) %>%
  names(.) %>% .[3:17]

## For Geoplotting Powerplants

## Modifying Shape file to match with the Powerplants Data

map_world <- subset(map_world,is.element(map_world$ISO3,powerplant_emissions$ISO3))
powerplant_emissions <- subset(powerplant_emissions,is.element(powerplant_emissions$ISO3,map_world$ISO3)) %>%
  .[order(match(powerplant_emissions$ISO3,map_world$ISO3)),]

## Creating bins and palettes
bins <- c(0, 3, 9, 12, Inf)
pal <- colorBin(palette = "YlOrRd",
                domain = powerplant_emissions$emissions_total_2014,
                bins = bins * 10^6)
pal2 <- colorFactor(palette = c("firebrick3","darkolivegreen3"), domain = powerplant_viz$fuel_category)


# Define Country List

## Visualization 1 (GDP PPP vs Emissions Data):
country_list_viz1 <- distinct(country_agg_data, country_name)
country_list_viz1 <- as.list(levels(country_list_viz1$country_name))
country_list_viz1 <- c('All',country_list_viz1)

## Visualization 2 (Sunbursts - Left):
country_list_viz2 <- distinct(check1, country_name)
country_list_viz2 <- as.list(levels(country_list_viz2$country_name))
country_list_viz2 <- c('All',country_list_viz2)

## Visualization 3 (Sunbursts - Right):
country_list_viz3 <- country_list_viz2


# Create the UI
ui <- fluidPage(
  
  # Set Page Title
  fluidPage(column(12,offset = 3, titlePanel("Global GHG emissions & Powerplant Database"))
    ),
  
  
  fluidRow(
    column(width = 12, align = "left",
           h4("Executive Summary")),
    column(width = 12,
           p(),
           p("With the continuous increase in the greenhouse gas (GHG) emissions (Levin, K. (2018)),
             the effects of climate change are more prominent than ever. Scientists have confirmed that warming at this rate will
             not only increase the spread of Ebola virus, reduce emperor penguin populations by up to 80% by 2100,
             and cause hurricanes and other extreme weather to stick around longer (Levin, K., & Tirpak, D. (2019)), but will also
             affect aspects of equity and climate justice."),
           p("The leading cause of climate change is.... humans -- more specifically the GHG emissions generated by us. Greenhouse gases 
            play an important role in keeping the planet warm enough to sustain life. However, in recent
             decades because of intense human activity, such as burning of fossil fuels like coal, oil and gas to feed an ever-growing
             population of the world needs for energy, the concentration of GHG has risen up to unprecedented levels"),
           p("There is a growing need to spread awareness about climate change and how human activity is leading to
             severe damage to the environment. Despite the popular idea of reducing emissions by half in 10 years, it doesn't include
             tipping points or additional warming caused because of stored carbon in the frozen icecaps in the world. Needless to say, effects of
             climate change are now visible. One popular example is loss of Iceland's once famous glacier Okjokull to which
             one of the country's leading glaciologists has confirmed that the ice is too thin for it to even qualify
             as a glacier"),
           p("To reduce the carbon footprint on earth, it is necessary to invest into technologies such
             as renewable sources of energy like solar, wind, geothermal etc. This dashboard aims to supplement
             this information by providing evidence on how growing development and economic activity has led to 
             increased GHG emissions over time. It also provides with a spatial view of different kinds of powerplants
             throughout the world with a provision to compare both of renewable and non-renewable powerplants at country specific level.")
           )
    ),
  
  hr(),
  
  fluidRow(
    column(width = 12, align = "left",
           h4("Economic development of Countries against GHG Emissions")),
    column(width = 12,
           p(),
           p("Historically, emissions have aligned with the ebb and flow of the economy. Periods of
              great economic activity and growth has been driven by higher demand of energy and industrial
              activity. For example, United States observed greater annual gains in GHG emissions in 2010, 
              when the economy rebounded from the Great Recession (Kormann, C. (2019))"),
           p("With newer technologies and growing demand, the world around, as we see it is rapidly changing. 
              It is important to understand how different countries' development trajectories have changed over 
              time and how it has affected GHG emissions. The dynamic plot below intends to make it easier to see 
              such trends for individual countries as well as groups of countries. Press the play button below 
              to see how countries have progressed over time. Select a country from the dropdown list to highlight its progress.")
    )
  ),
  
  # Use the sidebar layout for app
  sidebarLayout(
    
    # Define text for side panel
    sidebarPanel(
      h4('Select a country'),
      p("Select a country from the drop down below to highlight it in the graph to the right"),
      selectInput(inputId = 'countries',                 
                  label = "Select a Country:",            
                  choices = country_list_viz1 # List of options
      ),
      h6("* Several countries are missing because of missing either emissions data
        or GDP per capita data for that year from the World Bank"),
      h6("* Emissions per capita as an indicator wasn't chosen. Countries with higher GDP per capita
        that cause high carbon emissions per capita are mostly Gulf countries (oil rich) such as Qatar, Kuwait,
        Bahrain etc. These countires have smaller populations (ranging from 400k to 10 million) hence a higher -- per-capita figure.
        Thus, this isn't a realistic comparison")
    ),
    
    # Define text for main panel
    mainPanel(
      plotlyOutput("plot")
      )
    ),

  fluidRow(
    column(width = 12,
           h5("Observations:"),
           p("1. Gulf countries as mentioned before, have very high GDP per capita, PPP($)
             but the annual emissions of these countries is very low compared to 
             other (observable) countries"),
           p("2. As mentioned before, annual emissions of US increased in the year 2010, perceivably because
              the economy was rebounding back from the Great Recession"),
           p("3. Three countries namely, China, United States and India (ranked) 
             are one of the biggest polluters in the world where China and India 
             have relatively low GDP per capita compared to the United States."),
           p("4. China emitted over 12 gigatonnes (Gt) of GHG emissions in the year 2014, accounting
              for 30% of the world total (McGrath, Matt (2014)) mainly stemming
             from coal electricity generation and mining")

    )
    ),
  
  hr(),
  
  fluidRow(
    column(width = 12, align = "left",
    h4("Powerplants spread throughout the World")),
    p(),
    column(width = 12,
    p("The selection of the site of a power plant depends on several factors such as geographical location,
      cost of transmission of energy, cost of fuel, cost of land etc etc. Below is an interactive map
      which illustrates different kinds of power plants with their installed capacities (as of 2015) layered with
      annual GHG emissions of a country (2014)"),
    leafletOutput("geo_plot"),p(),
    h6("Instructions of use:",p(),p("1. The map has a zoom-in, zoom-out feature to view the location of the powerplant"),
       p("2. The map provides a smart functionality to choose how much layer of information does the
         viewer wishes to see; GHG emissions & powerplant locations"))
       )
    ),
  
  hr(),
  
  fluidRow(
    column(width = 12, align = "left",
           h4("Powerplant type by country"),
           p(),
           p("GHG emissions of a country depends on a number of factors. One of the major
              factors include the type of powerplants and their respective capacities installed
              in a country. The powerplant sectors predominantly (for non-renewable) consists of facilities produce
             electricity by combusting fossil fuels. The different types of powerplants (within both renewable and non-renewable)
             shows how diverse the energy portfolio of a country is. To better visualize this aspect, the below
             sunburst graphs help provide the following info:"),
           p("1. Compare the installed capacities between two countries across different types of powerplants"),
           p("2. To what extent has the country diversified its energy landscape")
           )
    ),
  
  sidebarPanel(
    position = "left",
    h4('Select a country'),
    p("Select a country from the drop down below to highlight it in the graph at the bottom"),
    selectInput(inputId = 'countries_viz2',                 
                label = "Select a Country:",            
                choices = country_list_viz2 # List of options
    ), width = 6 , plotlyOutput("plot_sunburst")
  ),
  
  sidebarPanel(
    position = "right",
    h4('Select a country'),
    p("Select a country from the drop down below to highlight it in the graph at the bottom"),
    selectInput(inputId = 'countries_viz3',                 
                label = "Select a Country:",            
                choices = country_list_viz3 # List of options
    ), width = 6 , plotlyOutput("plot_sunburst2")
    
  ),
  
  fluidRow(
    column(width = 12, align = "left",
           h6("Instructions of use:",
           p(),
           p("1. Select the country of choice from the drop-down menu"),
           p("2. Click on either Renewable and Non-renewable tags to further explore 
             types of powerplants within each category"))
    )
  ),
  hr(),
  
  fluidRow(
    column(width = 12, align = "left",
           h4("Next Steps:"),
              p(),
              p("1. The graphs above provide a comprehensive outlook on how economic development
                has perceivably lead to higher GHG emissions. Having said that, there needs to be a shift 
                in the objective of recent governments towards sustained development by adopting newer and
                more innovative technologies"),
              p("2. This dashboard further helps in understand how diversified the energy lanscape of a country
                country compares to the rest of the world. It providers policy makers with the opportunity to explore and 
                make policies focussing more on how to make renewable energies as profitable as non-renewable ones without adverse effects
                to the associated job market. Such policies can help push the world to a future where clean air and water is as accessible as it once was 
                for the generations before."),
           p("3. Lastly, more work is being done on the health implications of increased ambient air pollution which would soon be
             added to the dashboard.")
           
    )
  ),
  hr(),
  
  
  fluidRow(
    column(width = 12, align = "left",
           h5("Bibliography:"),
    p("• McGrath, Matt (2014-09-21). 'China overtakes EU on 'per head' CO2'. Retrieved
      2019-09-26.Probable reason of rapid increase in GHG emissions in China
      from the year 2000 to 2014 is because of rapid industrialization.
      Major industries include mining and ore processing"),
    p("• Levin, K. (2018). New Global CO2 Emissions Numbers Are In. 
      They’re Not Good.New Global CO2 Emissions Numbers Are In. They’re Not Good. Retrieved from
      https://www.wri.org/blog/2018/12/new-global-co2-emissions-numbers-are-they-re-not-good"),
    p("• Kormann, C. (2019, February 4). The New Yorker. The New Yorker. 
      Retrieved from https://www.newyorker.com/news/news-desk/the-false-choice-between-economic-growth-and-combatting-climate-change")
    )
  ),
  
  hr(),
  
  fluidRow(
    column(width = 12, align = "left",
           h5("Sources of Data:"),
           p("•	World Resource Institute: Global Power Plant Database; http://datasets.wri.org/dataset/globalpowerplantdatabase"),
           p("•	World Bank: GDP per capita, PPP; https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.CD"),
           p("•	World Bank: Carbon Emissions; https://data.worldbank.org/indicator/EN.ATM.CO2E.PC")
           )
  ),
  
  hr(),
  
  fluidRow(
    column(width = 12, align = "left",
           h5("Licenses:"),
           p("•	Global Power Plant (WRI): Creative Commons Attribution 4.0 International License. Full license text available at Creative Commons Attribution 4.0"),
           p("•	GDP per capita, PPP (WB): Creative Commons Attribution 4.0 (CC-BY 4.0)"),
           p("•	Carbon Emission (WB): Creative Commons Attribution 4.0 (CC-BY 4.0)")
    )
  )
  
  )
  

# Define the server actions
server <- function(input, output){
  
  output$plot <- renderPlotly({
    
    if(input$countries!="All"){
      
      levels(country_agg_data$country_col)[levels(country_agg_data$country_col)!=input$countries] <- "Other countries"
      
      
      g <- ggplot(country_agg_data,
                  aes(Emissions,gdp_ppp)) +
        geom_point(alpha = 0.4,aes(size = pop_size, frame = years,
                                   color = country_col, ids = country_name), show.legend = F) +
        scale_y_continuous(labels = dollar, breaks = 10^4 * ylab) + 
        scale_x_continuous(labels = comma, breaks = 10^6 * xlab) +
        xlab("Annual Carbon Emissions (Kilo Ton)") + 
        ylab("GDP per Capita, PPP($)") +
        ggtitle("GDP per Capita, PPP vs. Annual emissions") +
        theme_light() + 
        scale_color_manual(values = c("grey","red4"))
        
      
      g
    }
    
    else{
      
      g <- ggplot(country_agg_data,
                  aes(Emissions,gdp_ppp)) +
        geom_point(alpha = 0.4,aes(size = pop_size, frame = years,
                                   color = Emissions, ids = country_name)) +
        scale_colour_gradient(low="skyblue",high="red4",labels = paste0(legend, " Million"),
                              breaks = 10^6 * legend) +
        scale_y_continuous(labels = dollar, breaks = 10^4 * ylab) + 
        scale_x_continuous(labels = comma, breaks = 10^6 * xlab) +
        xlab("Annual Carbon Emissions (Kilo Ton)") + 
        ylab("GDP per Capita, PPP($)") +
        ggtitle("GDP per Capita, PPP vs. Annual emissions") +
        theme_light()
      
      g
      
    }
  })
  
  ### Adding labels to the Emissions polygons
  label <- paste("<p>","Country Name: ",powerplant_emissions$country_name,"</p>",
                 "<p>","Emissions: ",powerplant_emissions$emissions_total_2014,"</p>",
                 sep = "")
  
  output$geo_plot <- renderLeaflet({
    
    m <- leaflet(powerplant_viz) %>%  addTiles() %>%
      setView(0,0, zoom = 0.9) %>%
      addPolygons(data = map_world, weight = 1, smoothFactor = 0.5, color = "white",
                  fillOpacity = 0.8, fillColor = ~pal(powerplant_emissions$emissions_total_2014),
                  label = lapply(label, HTML),
                  group = "GHG Emissions") %>%
      addLegend(pal = pal,
                values = powerplant_emissions$emissions_total_2014,
                opacity = 0.7,
                position = "topright",
                title = "GHG Emissions") %>%
      addLegend(pal = pal2,
                values = powerplant_viz$fuel_category,
                opacity = 0.7,
                position = "bottomright",
                title = "Fuel Category") %>%
      addCircleMarkers(lat = ~latitude, lng = ~longitude,
                       popup = ~name_type,
                       radius = ~0.0000001,
                       color = ~pal2(powerplant_viz$fuel_category),
                       fillOpacity = 0.8,
                       group = "Power Plants") %>%
      addLayersControl(overlayGroups = c("GHG Emissions", "Power Plants"),
                       options = layersControlOptions(collapsed = FALSE),
                       position = "bottomleft")
    m
    
  })
  

  output$plot_sunburst <- renderPlotly({
    
    # Visualization 2 codes:
    
    # The below code generates the Total capacity, total renewable and non-renewable capacity
    
    sum_non_renew <- grandTotals %>% filter(fuel_category == "Non-renewable" & country_name == input$countries_viz2) %>% summarise(sum = sum(tot_capacity))
    sum_renew <- grandTotals %>% filter(fuel_category == "Renewable" & country_name == input$countries_viz2) %>% summarise(sum = sum(tot_capacity))
    
    sum_total <- grandTotals %>% filter(country_name == input$countries_viz2) %>%
      group_by(country_name) %>% summarise(sum = sum(tot_capacity))
    
    # Concatinating values of total, total renewable and total non-renewable
    
    values <-c(sum_total$sum,sum_non_renew$sum,sum_renew$sum)
    
    # Running a function to calulate capacities across each type of powerplant and then
    # append it to the main dataset
    
    for(val in ls){
      a <- grandTotals %>% filter(primary_fuel == val & country_name == input$countries_viz2) %>%
        summarise(sum = sum(tot_capacity))
      values = append(round(values), round(a$sum))
    }
    
    labels <- c("All","Non-renewable", "Renewable", ls)
    
    # Assigning Parents to the labels
    parents <- c("","All","All","Renewable",
                 "Non-renewable","Non-renewable","Non-renewable","Renewable",
                 "Renewable","Renewable","Non-renewable","Non-renewable",
                 "Non-renewable","Renewable","Renewable","Non-renewable",
                 "Renewable","Renewable")
    
    # Calculating the indices in the values which are ZERO. Every ZERO value suggests that
    # there is no such powerplant type in that chosen particular country
    
    index_nums <- which(values %in% 0)
    
    # Running a loop. When the user chooses all the loop wouldn't run
    
    if(length(index_nums)!=0){
      values <- values[-index_nums]
      labels <- labels[-index_nums]
      parents <- parents[-index_nums]
    }
    
    # Creating Sunburt chart
    
    p <- plot_ly(
      labels = labels,
      parents = parents,
      values = values,
      type = 'sunburst',
      branchvalues = "total"
    ) %>%
      layout(title = 'Powerplant capacity by Fuel Category')
    p
  })

    
    output$plot_sunburst2 <- renderPlotly({
      
    # Visualization 3 codes:
    
    # The below code generates the Total capacity, total renewable and non-renewable capacity
    sum_non_renew <- grandTotals %>% filter(fuel_category == "Non-renewable" & country_name == input$countries_viz3) %>% summarise(sum = sum(tot_capacity))
    sum_renew <- grandTotals %>% filter(fuel_category == "Renewable" & country_name == input$countries_viz3) %>% summarise(sum = sum(tot_capacity))
    
    sum_total <- grandTotals %>% filter(country_name == input$countries_viz3) %>%
      group_by(country_name) %>% summarise(sum = sum(tot_capacity))
    
    # Concatinating values of total, total renewable and total non-renewable
    
    values <-c(sum_total$sum,sum_non_renew$sum,sum_renew$sum)
    
    # Running a function to calulate capacities across each type of powerplant and then
    # append it to the main dataset
    
    for(val in ls){
      a <- grandTotals %>% filter(primary_fuel == val & country_name == input$countries_viz3) %>%
        summarise(sum = sum(tot_capacity))
      values = append(round(values), round(a$sum))
    }
    
    # Creating labels for the chart
    labels <- c("All","Non-renewable", "Renewable", ls)
    
    # Assigning Parents to the labels
    parents <- c("","All","All","Renewable",
                 "Non-renewable","Non-renewable","Non-renewable","Renewable",
                 "Renewable","Renewable","Non-renewable","Non-renewable",
                 "Non-renewable","Renewable","Renewable","Non-renewable",
                 "Renewable","Renewable")
    
    
    # Calculating the indices in the values which are ZERO. Every ZERO value suggests that
    # there is no such powerplant type in that chosen particular country
    
    index_nums <- which(values %in% 0)
    
    # Running a loop. When the user chooses all the loop wouldn't run
    if(length(index_nums)!=0){
      values <- values[-index_nums]
      labels <- labels[-index_nums]
      parents <- parents[-index_nums]
    }
    
    
    q <- plot_ly(
      labels = labels,
      parents = parents,
      values = values,
      type = 'sunburst',
      branchvalues = "total"
    ) %>%
      layout(title = 'Powerplant capacity by Fuel Category')
    q
  })

}

# Run the app
shinyApp(ui = ui, server = server)