# Base image https://hub.docker.com/u/rocker/
FROM rocker/shiny:latest

# system libraries of general use
# install debian packages
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \ 
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \

## update system libraries
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean

# copy all files
COPY . . 

# install renv & restore packages
RUN Rscript -e 'install.packages("renv")'
RUN Rscript -e 'renv::restore()'

# remove install files
RUN rm -rf /var/lib/apt/lists/*

# run app on container start
CMD ["R", "-e", "shiny::runApp('/scripts', host = '0.0.0.0', port = as.numeric(Sys.getenv('PORT')))"]