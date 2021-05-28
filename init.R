# R script to install packages if not already installed

my_packages = c("dplyr", "readr", "data.table",
                "httr",
                "sp", "sf", "rgdal",
                "leaflet", "leaflet.extras",
                "htmltools", "htmlwidgets", "rvest",
                "shiny", "shinythemes", "DT")

install_if_missing = function(p) {
  if (p %in% rownames(installed.packages()) == FALSE) {
    install.packages(p)
  }
}

invisible(sapply(my_packages, install_if_missing))
