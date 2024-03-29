# wheregotcovid
**Update**: The app is no longer updated as of 30 June 2021, as the Ministry of Health has stopped releasing data on public places visited by COVID19 cases.

wheregotcovid is an interactive RShiny web app displaying maps and data of public places visited by COVID19 cases in Singapore in the past 14 days. Click [here](https://nicolenwd.shinyapps.io/wheregotcovid) to access the app.

There are other great COVID19-related tools and apps that have been created; this app aims to complement those existing resources.

This github page contains the codes used in the app.

## Code
Key elements of the code:
- *app/scripts/extract_pdf_data.ipynb* - a Python script that extracts visit data from MOH Press Releases
- *app/scripts/preprocessing.R* – an R script that cleans the extracted data and geocodes the addresses to to map the locations in the app
- *app/map.R* – an R script that creates leaflet maps of the places visited by COVID19 cases
- *app/app.R* - an R script used to render the Shiny app
- *data* - a folder containing data used in the app

## Author
Nicole Neo, [nicolenwd](https://github.com/nicolenwd)

## License
wheregotcovid is released under the MIT License - see the [LICENSE](LICENSE) file for details.

