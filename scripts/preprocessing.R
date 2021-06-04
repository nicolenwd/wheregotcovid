###Script that preprocesses data of public places visited by COVID19 cases

## A. Set up
# Loading packages 
library(httr)
library(dplyr)
library(data.table)
library(readr)
library(here)

# Loading dataset
visit_data_raw <- fread(here("data", "visit_data_raw.csv"), header = T, encoding = "UTF-8") %>% select(-V1)


## B. Data pre-processing
# Cleaning misspelled locations/stores
visit_data_clean <- visit_data_raw %>%
  mutate(Location = gsub("^Giant$", "Giant Supermarket", Location)) %>%
  mutate(Location = gsub("^Funan$", "Funan Mall", Location)) %>%
  mutate(Location = gsub("^Seletar Mall$", "The Seletar Mall", Location)) %>%
  mutate(Location = gsub(".*Atat.*", "Atatcutz", Location)) %>%
  mutate(Store = gsub(visit_data_raw[19, "Store"], "Toys'R'Us", Store, fixed = T))

# # Replacing values in wrong column
# which((visit_data_clean$Location == "McDonald's"), arr.ind = T)
# visit_data_clean[103, "Location"] <- "Bedok Mall"
# visit_data_clean[82, "Store"] <- "McDonald's"

# Sanity check of visit_data_clean to see whether duplicated Address values are due to multiple Locations per Address, or due to unclean data
length(unique(visit_data_clean$Address))
duplicated <- visit_data_clean %>%
  count(Location, Address) %>%
  count(Address) %>%
  filter(n>1)
check <- visit_data_clean %>%
  filter(Address %in% duplicated$Address)

# Exporting cleaned dataset
write_csv(visit_data_clean, here("data", "visit_data_clean.csv"), col_names = T) 


## C. Geocoding
# Calling OneMapSG API to get lon/lat values for all addresses in the data
url <- "https://developers.onemap.sg/commonapi/search"
address <- unique(visit_data_clean$Address)
output <- matrix(nrow = length(address), ncol = 3)

for (i in 1:length(address)){
  address_input <- address[i]
  query_params <- list(searchVal = address_input, returnGeom = 'Y', getAddrDetails= 'Y', pageNum= '1')
  result <- GET(url, query = query_params)
  lon <- content(result)$results[1][[1]]$LONGITUDE
  lat <- content(result)$results[1][[1]]$LATITUDE
  output[i, 1] <- address_input
  output[i, 2] <- ifelse(length(lon) == 0, NA, lon)
  output[i, 3] <- ifelse(length(lat) == 0, NA, lat)
}

# Creating dataframe for the output
output_df <- as.data.frame(output) %>%
  rename(address = V1,
         lon = V2,
         lat = V3)

# Checking and replacing missing coordinate values (if any)
which(is.na(output_df), arr.ind = T)

# Adding coords to visit_data_clean
visit_data_coords <- base::merge(visit_data_clean, output_df, by.x = "Address", by.y = "address", sort = FALSE)
any(is.na(visit_data_coords))
visit_data_coords <- visit_data_coords %>%
  select(Date, Time, Location, Store, Address, lon, lat)

# Exporting dataframe of visit_data with address coords
write_csv(visit_data_coords, here("data", "visit_data_coords.csv"), col_names = T)
