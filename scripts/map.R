### Script that plots leaflet maps of places in SG visited by covid cases

## A. Set up
# Loading packages
library(sp)
library(sf)
library(rgdal)
library(leaflet)
library(leaflet.extras)
library(htmltools)
library(htmlwidgets)
library(rvest)
library(tidyverse)
library(here)

# Loading datasets
visit_data <- read.csv(here("data", "visit_data_clean.csv"), stringsAsFactors = F, encoding = "UTF-8")
visit_data_coords <- read.csv(here("data", "visit_data_coords.csv"), stringsAsFactors = F, encoding = "UTF-8")

# Loading shpfiles for SG Planning Area polygons
PA <- readOGR(here("data", "planning-area-2019.kml"))
base::names(PA) <- c("kml", "description")
PA <- spTransform(PA, CRS("+init=epsg:4326")) 


## B. Creating map of individual public locations visited by COVID19 cases
# Getting visit count and details for each location
visit_data_count <- visit_data %>%
  count(Location, Address) %>%
  rename(n_cases = n) %>%
  arrange(desc(n_cases))

visit_data_details <- visit_data %>% 
  mutate(details = paste0("<li>", Date, " ", Time, " ", Store, "</li>")) %>%
  group_by(Location, Address) %>%
  summarise(details_all = paste(details, collapse = "")) %>%
  mutate(details_all = paste0("<ul>", details_all, "</ul>")) 

marker_data <- visit_data_coords %>%
  left_join(visit_data_count, by = c("Location", "Address")) %>%
  left_join(visit_data_details, by = c("Location", "Address"))

# Creating labels for each location marker
marker_data$label <- unlist(lapply(seq(nrow(marker_data)), function(i) {
  paste0("<strong>", marker_data[i,"Location"], "</strong>",
         "<br>", marker_data[i, "Address"],
         "<br>", "# of visits by COVID cases: ", 
         marker_data[i, "n_cases"],
         marker_data[i, "details_all"])
}))
marker_data <- marker_data %>% 
  select(Location, Address, lon, lat, n_cases, label) %>%
  distinct(Location, .keep_all = T) %>%
  arrange(desc(n_cases))

# Leaflet map of individual locations
map_locations <- leaflet(options = leafletOptions(minZoom = 11, maxZoom = 18)) %>%
  addProviderTiles("OneMapSG.Default", group = "OneMapSG") %>%
  addCircleMarkers(data = marker_data,
                   lng = ~lon, lat = ~lat,
                   radius = ~(n_cases*2.5),
                   fillOpacity = 0.6, fillColor = "Red", 
                   weight = 2, color = "Black",
                   label = ~lapply(label, HTML), 
                   labelOptions = labelOptions(textsize = "12px"),
                   group = "Locations") %>%
 setView(lat = 1.332555, lng = 103.847393, zoom = 11) %>% #Singapore coordinates
  addResetMapButton()
map_locations


## C. Creating heatmap of location visits across Planning Areas
# Adding Planning Area (PA) names to polygon data
PA_names <- c("BUKIT MERAH", "BUKIT PANJANG", "BUKIT TIMAH",
              "CENTRAL WATER CATCHMENT", "CHANGI", "CHOA CHU KANG",
              "CLEMENTI", "HOUGANG", "JURONG EAST",
              "JURONG WEST", "KALLANG", "LIM CHU KANG",
              "MANDAI", "NORTH-EASTERN ISLANDS", "NOVENA",
              "PASIR RIS", "PIONEER", "PUNGGOL",
              "ANG MO KIO", "BEDOK", "BISHAN",
              "BOON LAY", "BUKIT BATOK", "QUEENSTOWN",
              "SELETAR", "SEMBAWANG", "SENGKANG",
              "SERANGOON", "SIMPANG", "SOUTHERN ISLANDS",
              "SUNGEI KADUT", "TAMPINES", "TANGLIN",
              "TENGAH", "TOA PAYOH", "TUAS",
              "DOWNTOWN CORE", "MARINA EAST", "MARINA SOUTH",
              "MUSEUM", "NEWTON", "ORCHARD",
              "OUTRAM", "RIVER VALLEY", "ROCHOR",
              "SINGAPORE RIVER", "STRAITS VIEW", "CHANGI BAY",
              "MARINE PARADE", "GEYLANG", "PAYA LEBAR",
              "WESTERN ISLANDS", "WESTERN WATER CATCHMENT", "WOODLANDS", "YISHUN")
PA$Name <- PA_names

# Creating a SpatialPointsDataFrame for individual locations
coordinates(visit_data_coords)= ~lon+lat
proj4string(visit_data_coords)= PA@proj4string

# Intersecting location points with PA polygons and creating joint dataframe
joint <- spatialEco::point.in.poly(visit_data_coords, PA) 

# Aggregating number of visits per PA polygon and merging with PA polygons data
visit_prop_per_PA <- as.data.frame(joint) %>%
  group_by(Name) %>%
  summarise(n = n()) %>%
  mutate(visit_prop = n/sum(n)*100) %>% 
  arrange(desc(visit_prop))

merged <- sp::merge(PA, visit_prop_per_PA, by = "Name")

# Creating labels for each PA polygon
merged$label <- unlist(lapply(seq(nrow(merged)), function(x) {
  data <- as.data.frame(merged)
  paste0("<strong>", data[x,"Name"], "</strong>", "<br>",
         "# of visits by COVID19 cases: ", data[x, "n"],
         "<br>", "% of all visits by COVID19 cases: ",
         as.character(round(data[x, "visit_prop"], 1)), "%")
}))

# Color palette for heatmap
prop_pal <- colorNumeric(palette = c("#ffffb2", "#fecc5c", "#fd8d3c", "#e34a33", "#b30000"),
                         na.color = "#d9d9d9",
                         domain = merged$n)

# Leaflet heatmap of distribution of location visits by COVID19 cases across PAs
map_heatmap <- leaflet(data = merged,
                       options = leafletOptions(minZoom = 10, maxZoom = 18)) %>%
  addProviderTiles("OneMapSG.Default", group = "OneMapSG") %>%
  addProviderTiles("CartoDB.Positron", group = "CartoDB") %>%
  addPolygons(weight = 1, color = "Grey", opacity = 0.8, 
              fillColor = ~prop_pal(n), fillOpacity = 0.7, 
              label = ~lapply(label, HTML), 
              labelOptions = labelOptions(textsize = "14px"),
              highlight = highlightOptions(weight = 4, color = "Black",
                                           bringToFront = T),
              group = "Heatmap") %>%
  addLegend(title = "# of visits", pal = prop_pal, 
            values = range(merged$n, na.rm = T), 
            bins = seq(0, 20, 4), 
            position = "bottomright") %>%
  addLayersControl(baseGroups = c("CartoDB", "OneMapSG"),
                   options = layersControlOptions(collapsed = FALSE),
                   position = "topright") %>%
  setView(lat = 1.337896, lng = 103.839627, zoom = 11) %>% #Singapore coordinates
  addResetMapButton()
map_heatmap