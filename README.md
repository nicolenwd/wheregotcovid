# wheregotcovid
wheregotcovid is an interactive RShiny web app displaying maps and data of public places in Singapore visited by COVID19 cases in the past 14 days. Click [here](https://wheregotcovid.herokuapp.com) to access the app. The app is updated daily.

This github page contains the code for the app.

## Code
Key elements of the code:
- *preprocessing.R* – an R script that cleans the extracted data and geocodes addresses to obtain coordinates used to map the locations in the app. The output files are saved in the *input_data* folder.
- *map.R* – an R script that creates leaflet maps of the places visited by COVID19 cases.
- *app.R* - an R script used to render the Shiny app.
- *input_data* - a folder containing data on public places visited by COVID19 cases.

## Author
Nicole Neo, [nicolenwd](https://github.com/nicolenwd)

