# Created by Ioannis Koukoutsidis, 2022
#
# Function that a Google Scholar insitution (here university) page and returns
# a table with the active authors in a given period, the number of papers and
# number of citations
#
# Parameters
# ----------
# gs_univ_url: URL of the university page in Google Scholar
# s_y: start year of the period you would like to search
# e_y: end year of the period you would like to search
# 
# Needs packages tidyverse, tidytext, rvest
#

gs_scrape_univ <- function(gs_univ_url,s_y,e_y){

page <- read_html(gs_univ_url)

author_name <- c()
scholar_id <- c()
citations <- c()

author_name <- c(author_name, page %>% html_nodes(".gs_ai_name")%>%html_text())
scholar_id <- c(scholar_id, page %>% html_nodes(".gs_ai_name > a") %>% html_attr("href") %>% gsub(".*=", "", .))
citations <- c(citations, page %>% html_nodes(".gs_ai_cby")%>%html_text() %>% readr::parse_number())

last_page <- FALSE

while (last_page==FALSE) {
  
  Sys.sleep(runif(1, min = 3, max = 11))
url2 <- page %>%
  html_nodes("button.gs_btnPR") %>%
  html_attr("onclick") %>% 
  gsub("^window.location='|'$", "", .)

if (is.na(url2)) {last_page=TRUE
break}

nexturl <- paste0("https://scholar.google.gr", url2) 
nexturl <- gsub("\\", "=",nexturl,fixed=TRUE)
nexturl <- gsub("x3d", "",nexturl,fixed=TRUE)
nexturl <- gsub("=x26", "&",nexturl,fixed=TRUE)
nexturl <- gsub("x26", "&",nexturl,fixed=TRUE)

page <- read_html(nexturl)
author_name <- c(author_name, page %>% html_nodes(".gs_ai_name")%>%html_text())
scholar_id <- c(scholar_id, page %>% html_nodes(".gs_ai_name > a") %>% html_attr("href") %>% gsub(".*=", "", .))
citations <- c(citations, page %>% html_nodes(".gs_ai_cby")%>%html_text() %>% readr::parse_number())

}

citations <- as.integer(citations)
author_table <- cbind.data.frame(author_name,scholar_id,citations)

#function that retrieves the papers and citations of each author
author_papers <- function(id){
title <- c()
year <- c()
cites <- c()

last_page <- FALSE
index <- 0

while (last_page==FALSE) {
  #construct URL
  url_name <- paste0("https://scholar.google.com/citations?hl=en&user=",id,"&cstart=",100*index,"&pagesize=100")
  wp <- read_html(url_name)
  if (!is_empty(html_text(html_nodes(wp,".gsc_a_e")))) { 
      if (grepl('no articles',html_text(html_nodes(wp,".gsc_a_e")))) {last_page=TRUE
  break}}
  
  title <- c(title, wp %>% html_nodes(".gsc_a_at")%>%html_text())
  year <- c(year, wp %>% html_nodes(".gsc_a_hc")%>%html_text() %>% readr::parse_number())
  cites <- c(cites, wp %>% html_nodes(".gsc_a_ac")%>%html_text() %>% readr::parse_number())
  
  index <- index+1  
}

# Make data frame
df <- data.frame(title = title, year = year, cites=cites, stringsAsFactors = FALSE)
}

# function that gets a publications table and a range in years and 
#returns the number of publications in a given time range
papers_in_years <- function (d_f, start_year, end_year) {
  pubs_in_range <- d_f %>% filter(!is.na(year) & year>=start_year & year<=end_year)
  nrow(pubs_in_range)
}

# function that gets a publications table and a range in years and 
# returns the number of citations to these publications in that range
citations_in_years <- function (d_f, start_year, end_year) {
  pubs_in_range <- d_f %>% filter(!is.na(year) & year>=start_year & year<=end_year)
  sum(pubs_in_range$cites,na.rm = TRUE)
}

author_table <- author_table %>% rowwise() %>%
  mutate(num_of_papers=papers_in_years(author_papers(scholar_id),s_y,e_y),
         cites_of_papers=citations_in_years(author_papers(scholar_id),s_y,e_y))

return(author_table)
}
