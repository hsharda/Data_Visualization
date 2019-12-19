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


# Import Dataset

country_agg_data <- read.csv('Data/Powerplant/gdp_emissions_pop.csv')
powerplant_viz <- read.csv("Data/Powerplant/power_plant_data_locations.csv")


#powerplant_viz <- read.csv("Data/Powerplant/power_plant_data_locations.csv")
powerplant_emissions <- read.csv("Data/Powerplant/power_plants_locations_emissions.csv")
map_world <- st_read("Data/Shapefile/TM_WORLD_BORDERS-0.3.shp")

#country_data <- read.csv("Data/DataViz memo_hs957.csv")

# Data Wrangling Tasks

## For Sunbursts charts

check1 <- powerplant_viz %>%
  group_by(country_name,fuel_category,primary_fuel) %>%
  summarize(tot_capacity = sum(round(capacity_mw)))

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

ls <- grandTotals %>% spread(primary_fuel, tot_capacity, fill = 0) %>%
  names(.) %>% .[3:17]

## For Geoplotting Powerplants

## Modifying Shape file to match with the Power Plants Data

map_world <- subset(map_world,is.element(map_world$ISO3,powerplant_emissions$ISO3))
powerplant_emissions <- subset(powerplant_emissions,is.element(powerplant_emissions$ISO3,map_world$ISO3)) %>%
  .[order(match(powerplant_emissions$ISO3,map_world$ISO3)),]

## Creating bins and palettes
bins <- c(0, 2, 4, 6, 8, 10, 12, Inf)
pal <- colorBin(palette = "YlOrRd",
                domain = powerplant_emissions$emissions_total_2014,
                bins = bins * 10^6)
pal2 <- colorFactor(palette = c("firebrick3","darkolivegreen3"), domain = powerplant_viz$fuel_category)

### Adding labels to the Emissions polygons
label <- paste("<p>","Country Name: ",powerplant_emissions$country_name,"</p>",
               "<p>","Emissions: ",powerplant_emissions$emissions_total_2014,"</p>",
               sep = "")

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
country_list_viz3 <- c('All',country_list_viz2)


# Create the UI
ui <- fluidPage(
  
  # Set Page Title
  titlePanel("Global GHG Emissions and Power Plant Database (Under Construction)"),
  
  hr(),
  
  # Use the sidebar layout for app
  sidebarLayout(
    
    # Define text for side panel
    sidebarPanel(
      h3('Select a country'),
      p("Select a country from the drop down below to highlight it in the graph to the right"),
      selectInput(inputId = 'countries',                 
                  label = "Select a Country:",            
                  choices = country_list_viz1 # List of options
      )
    ),
    
    # Define text for main panel
    mainPanel(
      h4("Overview"),
      p("The world is rapidly changing. It is important to understand how different countries' development trajectories have changed over time.
        This dashboard is intended to make it easier to see trends for individual countries as well as groups of countries.
        Press the play button below to see how countries have progressed over time.
        Select a country from the dropdown list to highlight its progress."),
      plotlyOutput("plot")
      )
    
    ),
  hr(),
  
  fluidRow(
    column(width = 12, align = "center",
    h4("Spread of Powerplants throughout the world")),
    column(width = 12,
    p("The world is rapidly changing. It is important to understand how different countries' development trajectories have changed over time.
      This dashboard is intended to make it easier to see trends for individual countries as well as groups of countries.
      Press the play button below to see how countries have progressed over time.
      Select a country from the dropdown list to highlight its progress."),
    leafletOutput("geo_plot"))
    ),
  
  hr(),
  
  sidebarPanel(
    position = "left",
    h3('Select a country'),
    p("Select a country from the drop down below to highlight it in the graph at the bottom"),
    selectInput(inputId = 'countries_viz2',                 
                label = "Select a Country:",            
                choices = country_list_viz2 # List of options
    ), width = 6 , plotlyOutput("plot_sunburst")
  ),
  
  sidebarPanel(
    position = "right",
    h3('Select a country'),
    p("Select a country from the drop down below to highlight it in the graph at the bottom"),
    selectInput(inputId = 'countries_viz3',                 
                label = "Select a Country:",            
                choices = country_list_viz3 # List of options
    ), width = 6 , plotlyOutput("plot_sunburst2")
    
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
        xlab("Total Carbon Emissions") + 
        ylab("GDP per Capita, PPP") +
        ggtitle("GDP per Capita, PPP vs. Emissions per capita") +
        theme_light() + 
        scale_color_manual(values = c("skyblue","red4"))
        
      
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
        xlab("Total Carbon Emissions") + 
        ylab("GDP per Capita, PPP") +
        ggtitle("GDP per Capita, PPP vs. Emissions per capita") +
        theme_light()
      
      g
      
    }
  })
  
  
  output$geo_plot <- renderLeaflet({
    
    m <- leaflet(powerplant_viz) %>%  addTiles() %>%
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
                       popup = ~c(name),
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
    
    sum_non_renew <- grandTotals %>% filter(fuel_category == "Non-renewable" & country_name == input$countries_viz2) %>% summarise(sum = sum(tot_capacity))
    sum_renew <- grandTotals %>% filter(fuel_category == "Renewable" & country_name == input$countries_viz2) %>% summarise(sum = sum(tot_capacity))
    
    sum_total <- grandTotals %>% filter(country_name == input$countries_viz2) %>%
      group_by(country_name) %>% summarise(sum = sum(tot_capacity))
    
    values <-c(sum_total$sum,sum_non_renew$sum,sum_renew$sum)
    
    for(val in ls){
      a <- grandTotals %>% filter(primary_fuel == val & country_name == input$countries_viz2) %>%
        summarise(sum = sum(tot_capacity))
      values = append(round(values), round(a$sum))
    }
    
    labels <- c("All","Non-renewable", "Renewable", ls)
    parents <- c("","All","All","Renewable",
                 "Non-renewable","Non-renewable","Non-renewable","Renewable",
                 "Renewable","Renewable","Non-renewable","Non-renewable",
                 "Non-renewable","Renewable","Renewable","Non-renewable",
                 "Renewable","Renewable")
    
    index_nums <- which(values %in% 0)
    values <- values[-index_nums]
    labels <- labels[-index_nums]
    parents <- parents[-index_nums]
    
    
    p <- plot_ly(
      labels = labels,
      parents = parents,
      values = values,
      type = 'sunburst',
      branchvalues = "total"
    ) %>%
      layout(title = 'Fuel Category')
    p
  })

    
    output$plot_sunburst2 <- renderPlotly({
      
    # Visualization 3 codes:
    
    sum_non_renew <- grandTotals %>% filter(fuel_category == "Non-renewable" & country_name == input$countries_viz3) %>% summarise(sum = sum(tot_capacity))
    sum_renew <- grandTotals %>% filter(fuel_category == "Renewable" & country_name == input$countries_viz3) %>% summarise(sum = sum(tot_capacity))
    
    sum_total <- grandTotals %>% filter(country_name == input$countries_viz3) %>%
      group_by(country_name) %>% summarise(sum = sum(tot_capacity))
    
    values <-c(sum_total$sum,sum_non_renew$sum,sum_renew$sum)
    
    for(val in ls){
      a <- grandTotals %>% filter(primary_fuel == val & country_name == input$countries_viz3) %>%
        summarise(sum = sum(tot_capacity))
      values = append(round(values), round(a$sum))
    }
    
    labels <- c("All","Non-renewable", "Renewable", ls)
    parents <- c("","All","All","Renewable",
                 "Non-renewable","Non-renewable","Non-renewable","Renewable",
                 "Renewable","Renewable","Non-renewable","Non-renewable",
                 "Non-renewable","Renewable","Renewable","Non-renewable",
                 "Renewable","Renewable")
    
    index_nums <- which(values %in% 0)
    values <- values[-index_nums]
    labels <- labels[-index_nums]
    parents <- parents[-index_nums]
    
    
    p <- plot_ly(
      labels = labels,
      parents = parents,
      values = values,
      type = 'sunburst',
      branchvalues = "total"
    ) %>%
      layout(title = 'Fuel Category')
    p
  })

}

# Run the app
shinyApp(ui = ui, server = server)