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

#country_agg_data <- read.csv('Data/DataViz_memo_hs957.csv')
country_agg_data <- read.csv('Data/Powerplant/gdp_emissions_pop.csv')
ylab <- c(0, 2.5, 5.0, 7.5, 10, 12.5)
xlab <- c(0, 2.5, 5.0, 7.5 ,10.0)
legend <- c(2.5,5.0,7.5,10.0)
country_agg_data$country_col <- country_agg_data$country_name
#country_agg_data <- country_agg_data[c("country_name","emissions_capita_2014","gdp_2018","pop_2018")]

#country_agg_data_omit <- na.omit(country_agg_data)
#country_agg_data_omit <- droplevels(country_agg_data_omit)

# Define Country List
country_list <- distinct(country_agg_data, country_name)
#country_list <- droplevels(country_list)
country_list <- as.list(levels(country_list$country_name))
country_list <- c('All',country_list)

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
                  choices = country_list # List of options
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
  hr()
  )
  

# Define the server actions
server <- function(input, output){
  
  output$plot <- renderPlotly({
    
    if(input$countries!="All"){
      
      levels(country_agg_data$country_col)[levels(country_agg_data$country_col)!=input$countries] <- "Other countries"
      
      #country_subset <- country_agg_data %>% filter(country_name == input$countries)
      
      g <- ggplot(country_agg_data,
                  aes(Emissions,gdp_ppp)) +
        geom_point(alpha = 0.4,aes(size = pop_size, frame = years,
                                   color = country_col, ids = country_name)) +
        #scale_colour_gradient(low="skyblue",high="red4",labels = paste0(legend, " Million"),
                              #breaks = 10^6 * legend) +
        scale_y_continuous(labels = dollar, breaks = 10^4 * ylab) + 
        scale_x_continuous(labels = comma, breaks = 10^6 * xlab) +
        xlab("Total Carbon emissions") + 
        ylab("GDP per Capita, PPP") +
        ggtitle("GDP per Capita, PPP vs. Emissions per capita") +
        theme_light()
      
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
        xlab("Total Carbon emissions") + 
        ylab("GDP per Capita, PPP") +
        ggtitle("GDP per Capita, PPP vs. Emissions per capita") +
        theme_light()
      
      g
      
    }

    
})
}

# Run the app
shinyApp(ui = ui, server = server)