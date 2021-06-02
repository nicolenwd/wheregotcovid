### RShiny App of public places in Singapore visited by COVID19 cases (past 14 days)

## A. Set up
here::i_am("scripts/app.R")

# Loading packages
library(sp)
library(sf)
library(rgdal)
library(leaflet)
library(leaflet.extras)
library(htmltools)
library(htmlwidgets)
library(rvest)
library(shiny)
library(shinythemes)
library(DT)
library(tidyverse)
library(here)

# Loading leaflet maps
source(here("scripts", "map.R"))

## B. Shiny UI
ui <- navbarPage(title = "wheregotcovid",
                 theme = shinytheme("cosmo"),
                 tags$head(shiny::includeHTML(("google_analytics.html"))),
                 tabPanel("Maps",
                    tags$div("Last Updated: ", Sys.Date(), style = "text-align:right"),
                    tags$h1(tags$strong("Maps")), 
                    tags$p("Locations: Individual locations with details of visits (past 14 days)",
                           tags$br(),
                           "Heatmap: Map of Singapore coloured by number of visits per area (past 14 days)",
                           style = "font-size:18px"),
                    tags$p(tags$em("Hover over/tap on the map for details")),
                    tabsetPanel(
                      tabPanel("Locations", leafletOutput("locations", height = 500)),
                      tabPanel("Heatmap", leafletOutput("heatmap", height = 500))
                    )),
                 tabPanel("Data", 
                    tags$div("Last Updated: ", Sys.Date(), style = "text-align:right"),
                    tags$h1(tags$strong("Data")),
                    tags$p("Details of public places in Singapore visited by COVID19 cases (past 14 days)",
                           style = "font-size:18px"),
                    tags$p("Data from", tags$a(href = "https://www.moh.gov.sg/news-highlights", "MOH Press Releases - Annexes")),
                    DTOutput("data")),
                 tabPanel("About", includeMarkdown(here("scripts", "app_about.md")))
)


## C. Shiny Server
server <- function(input, output, session){
  output$locations <- renderLeaflet({
    map_locations
  })

  output$heatmap <- renderLeaflet({
    map_heatmap
  })

  output$data <- renderDT(
    visit_data,
    filter = "top",
    options = list(pageLength = 20, dom = "ltipr")
    )
}
  

shinyApp(ui, server)