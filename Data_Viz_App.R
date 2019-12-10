# Import the required libraries
library(shiny)
library(tidyverse)
library(jsonlite)
library(gapminder)
library(plotly)
library(ggplot2)

# Import Dataset
gap_data <- gapminder::gapminder
gap_data$country_name = gap_data$country
gap_data$country_col = gap_data$country

# Define Country List
country_list <- distinct(gap_data, country)
country_list <- as.list(levels(country_list$country))
country_list <- c('All',country_list)

# Create the UI
ui <- fluidPage(
  
  # Set Page Title
  titlePanel("Global Development Report (Under Construction)"),
  
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
server <- function(input, output){}

# Run the app
shinyApp(ui = ui, server = server)