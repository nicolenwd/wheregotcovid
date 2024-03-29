### RShiny App of public places in Singapore visited by COVID19 cases (past 14 days)

## A. Set up
# Loading packages
# library(shiny)
library(sp)
library(sf)
library(rgdal)
library(leaflet)
library(leaflet.extras)
library(htmltools)
library(htmlwidgets)
library(httr)
library(shinythemes)
library(DT)
library(tidyverse)
library(here)

# Loading leaflet maps
source(here("scripts", "map.R"))


## B. Shiny UI
ui <- navbarPage(title = "wheregotcovid",
                 theme = shinytheme("cosmo"),
                 tabPanel("Maps",
                    tags$div(tags$b("This page is no longer updated as of 30 June 2021, as the Ministry of Health has stopped releasing data on public places visited by COVID19 cases."), 
                             style = "font-size:18px",
                             tags$br()),
                    tags$h1(tags$strong("Maps")), 
                    tags$div("Locations: Individual public places with details of visits",
                             tags$br(),
                             "Heatmap: Map of Singapore coloured by number of visits per area",
                             style = "font-size:18px"),
                    tags$div("(Note: Hover over/tap on the map for details. Data includes visits in past 14 days; excludes workplaces, healthcare facilities and public transport)",
                             style = "font_size:12px; font-style:italic"),
                    tags$p(''),
                    textInput("search", "Search Location", placeholder = "e.g. 018971 or Marina Bay Sands"),
                    tabsetPanel(
                      tabPanel("Locations", uiOutput("locations_ui")),
                      tabPanel("Heatmap", uiOutput("heatmap_ui"))
                    )),
                 tabPanel("Data", 
                    # tags$div("Last Updated: 16 Jun 2021", style = "text-align:right"),
                    tags$h1(tags$strong("Data")),
                    tags$p("Details of public places in Singapore visited by COVID19 cases (past 14 days)",
                           style = "font-size:18px"),
                    tags$p("Data from", tags$a(href = "https://www.moh.gov.sg/news-highlights", "MOH Press Releases - Annexes")),
                    DTOutput("data")),
                 tabPanel("About", includeMarkdown(here("scripts", "app_about.md"))),
                 tags$head(shiny::includeHTML(here("scripts", "analytics.html")))
)


## C. Shiny Server
server <- function(input, output, session){
  output$locations_ui <- renderUI({
    leafletOutput("locations", height = 550)
  })
  output$locations <- renderLeaflet({
    map_locations
  })

  output$heatmap_ui <- renderUI({
    leafletOutput("heatmap", height = 550)
  })
  output$heatmap <- renderLeaflet({
    map_heatmap
  })

  output$data <- renderDT(
    visit_data,
    filter = "top",
    options = list(pageLength = 20, dom = "ltipr")
    )
  
  # Reactive functions that allow map to pan to user-searched location
  searchInput <- reactive({
    url <- "https://developers.onemap.sg/commonapi/search"
    query_params <- list(searchVal = as.character(input$search), returnGeom = 'Y', 
                         getAddrDetails= 'Y', pageNum= '1')
    result <- GET(url, query = query_params)
    lon <- content(result)$results[1][[1]]$LONGITUDE
    lat <- content(result)$results[1][[1]]$LATITUDE
    lon_lat <- data.frame(lon, lat)
  })
  
  observe({
    search_data <- searchInput()
    leafletProxy("locations") %>% 
      setView(lng = search_data$lon, lat = search_data$lat, zoom = 15) 
  })
  
  observe({
    search_data <- searchInput()
    leafletProxy("heatmap") %>% 
      setView(lng = search_data$lon, lat = search_data$lat, zoom = 13) 
  })
}
  

shinyApp(ui, server)