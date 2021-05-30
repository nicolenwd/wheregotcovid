### 2. Script that plots leaflet maps of places in SG visited by covid cases

## A. Set up
# Loading packages
library(tidyverse)
library(sp)
library(sf)
library(rgdal)
library(leaflet)
library(leaflet.extras)
library(htmltools)
library(htmlwidgets)
library(rvest)

# Loading datasets
visit_data <- read.csv("data/visit_data_clean.csv", stringsAsFactors = F, encoding = "UTF-8")
visit_data_coords <- read.csv("data/visit_data_coords.csv", stringsAsFactors = F, encoding = "UTF-8")

# Loading shpfiles for SG Planning Area polygons
PA <- readOGR("data/planning-area-2019.kml")
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
marker_data <- marker_data %>% select(-details_all)

# Leaflet map of individual locations
map_locations <- marker_data %>%
  leaflet(options = leafletOptions(minZoom = 11, maxZoom = 18)) %>%
  addProviderTiles("OneMapSG.Default", group = "OneMapSG") %>%
  addCircleMarkers(lng = ~lon, lat = ~lat,
                   radius = ~(n_cases*2.5),
                   fillOpacity = 0.6, fillColor = "Red", 
                   weight = 2, color = "Black",
                   label = ~lapply(label, HTML), 
                   labelOptions = labelOptions(textsize = "13px"),
                   group = "Locations") %>%
  setView(lat = 1.337896, lng = 103.839627, zoom = 11) #Singapore coordinates
map_locations
# saveWidget(map_locations, "data/map_locations.html")


## C. Creating heatmap of location visits across Planning Areas
# Extracting Planning Area (PA) polygon data from kml file
attributes <- lapply(X = 1:nrow(PA@data), 
                     FUN = function(x) {
                       PA@data %>% 
                       slice(x) %>%
                       pull(Description) %>%
                       read_html() %>%
                       html_node("table") %>%
                       html_table(header = T, trim = T, dec = ".", fill = T) %>%
                       as_tibble(.name_repair = ~ make.names(c("Attribute", "Value"))) %>% 
                       pivot_wider(names_from = Attribute, values_from = Value)
                     })

PA@data <- PA@data %>%
  bind_cols(bind_rows(attributes)) %>%
  select(-Description, -Name) %>%
  rename(Name = PLN_AREA_N)

# Creating a SpatialPointsDataFrame for individual locations
coordinates(visit_data_coords)= ~lon+lat
proj4string(visit_data_coords)= PA@proj4string

# Intersecting location points with PA polygons and creating joint dataframe
joint <- spatialEco::point.in.poly(visit_data_coords, PA) 
head(joint@data)

# Aggregating number of visits per PA polygon and merging with PA polygons data
visit_prop_per_PA <- joint@data %>%
  group_by(Name) %>%
  summarise(n = n()) %>%
  mutate(visit_prop = n/sum(n)*100) %>% 
  arrange(desc(visit_prop))

merged <- merge(PA, visit_prop_per_PA, by = "Name")
head(merged@data)

# Creating labels for each PA polygon
merged@data$label <- unlist(lapply(seq(nrow(merged@data)), function(i) {
  paste0("<strong>", merged@data[i,"Name"], "</strong>", "<br>",
         "# of visits by COVID19 cases: ", merged@data[i, "n"],
         "<br>", "% of all visits by COVID19 cases: ",
         as.character(round(merged@data[i, "visit_prop"], 1)), "%")
}))

# Color palette for heatmap
prop_pal <- colorNumeric(palette = c("#ffffb2", "#fecc5c", "#fd8d3c", "#e34a33", "#b30000"),
                         na.color = "#d9d9d9",
                         domain = merged@data$n)

# Leaflet heatmap of distribution of location visits by COVID19 cases across PAs
map_heatmap <- merged %>%
  leaflet(options = leafletOptions(minZoom = 11, maxZoom = 18)) %>%
  addProviderTiles("OneMapSG.Default", group = "OneMapSG") %>%
  addProviderTiles("CartoDB.Positron", group = "CartoDB") %>%
  addPolygons(weight = 1, color = "Grey", opacity = 0.8, 
              fillColor = ~prop_pal(n), fillOpacity = 0.7, 
              label = ~lapply(label, HTML), 
              labelOptions = labelOptions(textsize = "14px"),
              highlight = highlightOptions(weight = 4, color = "Black",
                                           bringToFront = T),
              group = "Heatmap") %>%
  addLegend(title = "# of visits by COVID19 cases (past 14 days)", pal = prop_pal, 
            values = range(merged@data$n, na.rm=T), bins = 5,
            position = "bottomright") %>%
  addLayersControl(baseGroups = c("CartoDB", "OneMapSG"),
                   options = layersControlOptions(collapsed = FALSE),
                   position = "topright") %>%
  setView(lat = 1.337896, lng = 103.839627, zoom = 11) #Singapore coordinates
map_heatmap
# saveWidget(map_heatmap, "data/map_heatmap.html")
