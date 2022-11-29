# Created by Ioannis Koukoutsidis, 2022
#
# Function that reads a file containing authors with Scopus IDs and affiliation
# (university name, department name), filters to find authors in certain subject
# area (based on department affiliation), and then performs a search in Scopus 
# and returns a dataframe with bibliometric data for a given time period
#
# File must contain at least the following columns:
# univ_acronym (acronym or other identifier of university),
# school_or_department (name of school or department in university), 
# scopus_id (author Scopus ID, where available)
#
# 
# api_key: your Scopus API key
# file_path: file to an excel file containing the data
# search_term: string containing a search term related to the thematic area 
# (subject area) one would like to search (e.g. "physics")
# exclude_term: string the user would like to exclude from the search (optional)
#
# Needs packages tidyverse, bibliometrix
#

sc_bibliostats_thematic <- function(api_key, file_path, search_term, exclude_term=NULL, period=NULL){

data <- readxl::read_excel(file_path)

#filter based on search term
if(missing(exclude_term)){
related_data <- data %>% filter(grepl(search_term,school_or_department,ignore.case = TRUE))
}
else {
  related_data <- data %>% filter(grepl(search_term,school_or_department,ignore.case = TRUE) & !agrepl(exclude_term,school_or_department,ignore.case = TRUE, max.distance = 0.1))
}
  

#extract university and dept names
dept_names <- unique(related_data[,c('univ_acronym', 'school_or_department')])

#extract list of scopus IDs
id_list <- list()
for (i in 1:nrow(dept_names)) {
  id_list[[i]] <- related_data %>% filter(univ_acronym==as.character(dept_names[i,1])) %>% 
    filter(school_or_department==as.character(dept_names[i,2]))  %>% select(scopus_id)
}

#extract faculty list for each department
faculty_list <- list()
for (i in 1:length(dept_names)) {
  faculty_list[[i]] <- data_uni %>% filter(school_or_department==dept_names[i])
}

#find authors not indexed in Scopus
faculty_no_scopus_list <- lapply(faculty_list, function(x) x%>% subset(is.na(scopus_id)))

## create the bibliographic collections of each dept in a list
#
res_list <- lapply(id_list,retrievalByAuthorID,api_key,remove.duplicated = TRUE,country = FALSE)
#
BIB_DF <- list()
for (i in 1:length(res_list)) {
  BIB_DF[[i]] <- as.data.frame(res_list[[i]][["M"]])
}

#filter documents in period (if given)
if(!missing(period)){
  BIB_DF <- lapply(BIB_DF, function(M) M %>% filter(PY %in% (period)))
}

#calculate number of articles and citations
faculty_count_list <- lapply(faculty_list, nrow)
faculty_count_no_scopus_list <- lapply(faculty_no_scopus_list,nrow)
articles_count_list <- lapply (BIB_DF,nrow)
citation_count_list <- lapply (BIB_DF,function(y) sum(y$TC))

faculty_count <- unlist(faculty_count_list)
faculty_count_no_scopus <- unlist(faculty_count_no_scopus_list)
articles_count <- unlist(articles_count_list)
citation_count <- unlist(citation_count_list)

articles_per_faculty_member <- articles_count/faculty_count
citations_per_faculty_member <- citation_count/faculty_count
citations_per_article <- citation_count/articles_count

#summary_data_frame
summary_depts <- tibble("University"=dept_names[,1],"School or Department"=dept_names[,2],"Number of faculty members"=faculty_count,
                        "Number of faculty members without a Scopus profile"=faculty_count_no_scopus,
                        "Articles in period"=articles_count,
                        "Citations"=citation_count,"Articles per faculty_member"=articles_per_faculty_member,
                        "Citations per faculty_member"=citations_per_faculty_member,
                        "Citations_per_article"=citations_per_article) %>% arrange(desc(`Citations per faculty_member`))

return(summary_depts)
}
