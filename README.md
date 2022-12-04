[![Not Maintained](https://img.shields.io/badge/Maintenance%20Level-Not%20Maintained-yellow.svg)](https://gist.github.com/cheerfulstoic/d107229326a01ff0f333a1d3476e068d)

# bibliostats

Bibliostats contains some functions I created in R for a bibliometric study of greek university departments. The code can be useful to people doing similar studies, so I decided to upload it in Github.
It contains four functions, three of which collect data from Scopus and one scrapes data from Google Scholar (insitution) profiles.

## function sc_bibliostats_univ

This function collects data from Scopus via the Scopus API using the bibliometrix package. It reads a file containing authors with Scopus IDs and affiliation
data (university name, department name), performs a search in Scopus and returns a dataframe with bibliometric data for a given time period.

## function sc_bibliostats_univ_multiple

This function reads a list of xlsx files, where each file contains authors with scopus_ids (e.g. from the same department or group).
The function performs a search in Scopus similarly to the previous one and returns a dataframe with bibliometric data for a given time period.

The xlsx file names are used to build the table of results, so the file name could be the name of department or group. In the code it is assumed to be the name of the department.

## function sc_bibliostats_thematic

This funciton reads a file containing authors with Scopus IDs and affiliation (university name, department name), filters to find authors in certain subject area (based on department affiliation), and then performs a search in Scopus and returns a dataframe with bibliometric data for a given time period. It uses the bibliometrix package similar to the above.

## function gs_scrape_univ

This function scrapes a Google Scholar institution (here university) page and returns a table with the active authors in a given period, the number of papers and
number of citations.

## License

The code is distributed under MIT license.

## Project status

The repository is not actively maintained. I created these functions for a specific purpose, and I do not systematically work in this area. Feel free to improve it or fork it if you like. You can let me know if you find any errors or need any clarifications.
