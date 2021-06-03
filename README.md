# wheregotcovid
wheregotcovid is an interactive RShiny web app displaying maps and data of public places visited by COVID19 cases in Singapore in the past 14 days. Click [here](https://wheregotcovid.herokuapp.com) to access the app. The app is updated once daily.

There are other great COVID19-related tools and apps out there; this app aims to complement those existing resources.

This github page contains the codes used to create the app.

## Code
Key elements of the code:
- *scripts/extract_pdf_data.ipynb* - a Jupyter notebook containing Python script to extract visit data from MOH Press Releases.
- *scripts/preprocessing.R* – an R script that cleans the extracted data and geocodes addresses to obtain coordinates used to map the locations in the app. 
- *scripts/map.R* – an R script that creates leaflet maps of the places visited by COVID19 cases.
- *scripts/app.R* - an R script used to render the Shiny app.
- *data* - a folder containing data used in the app.

## Author
Nicole Neo, [nicolenwd](https://github.com/nicolenwd)

## License
wheregotcovid is released under the MIT License - see the [LICENSE](LICENSE) file for details.

