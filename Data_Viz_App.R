# Import the required libraries
library(shiny)
library(tidyverse)
library(jsonlite)
library(gapminder)
library(plotly)
library(ggplot2)
library(scales)
library(ggrepel)

# Import Dataset

country_agg_data <- read.csv('Data/DataViz memo_hs957.csv')
ylab <- c(0, 2.5, 5.0, 7.5, 10, 12.5)
gap_data <- gapminder::gapminder
gap_data$country_name = gap_data$country
gap_data$country_col = gap_data$country

# Define Country List
country_list <- distinct(country_agg_data, Country.Name_x)
country_list <- as.list(levels(country_list$Country.Name_x))
country_list <- c('All',country_list)

# Create the UI
ui <- fluidPage(
  
  # Set Page Title
  titlePanel("Global GHG Emissions and Power Plant Database (Under Construction)"),
  
  # Use the sidebar layout for app
  sidebarLayout(
    
    # Define text for side panel
    sidebarPanel(
      h3('Select a country'),
      p("Select a country from the drop down below to highlight it in the graph to the right"),
      selectInput(inputId = 'countries',                 
                  label = "Select a Country:",            
                  choices = country_list # List of options
      )
    ),
    
    # Define text for main panel
    mainPanel(
      h1("Overview"),
      p("The world is rapidly changing. It is important to understand how different countries' development trajectories have changed over time.
        This dashboard is intended to make it easier to see trends for individual countries as well as groups of countries.
        Press the play button below to see how countries have progressed over time.
        Select a country from the dropdown list to highlight its progress.")
      
      )
    )
  )
  

# Define the server actions
server <- function(input, output){
  
  output$plot <- renderPlotly({
    
    g <- ggplot(country_agg_data,aes(emissions_capita_2014,gdp_2018)) +
      geom_point(alpha = 0.4,  aes(size = pop_2018, color = emissions_capita_2014)) +
      scale_colour_gradient(low="skyblue",high="red4") +
      geom_text_repel(aes(label = Country.Name_x), data =
                        final_data[final_data$emissions_capita_2014>15,],size = 2, nudge_x = 2) +
      scale_y_continuous(labels = dollar, breaks = 10^4 * ylab) +
      xlab("Carbon emissions per Capita (in tons, as of 2014)") + 
      ylab("GDP per Capita, PPP (2018)") +
      ggtitle("GDP per Capita, PPP vs. Emissions per capita") +
      theme_light()
    
    g
    
  })
}

# Run the app
shinyApp(ui = ui, server = server)