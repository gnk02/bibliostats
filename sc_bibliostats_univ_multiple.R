# Created by Ioannis Koukoutsidis, 2022
#
# Function that reads a list of xlsx files, where each file contains authors 
# with scopus_ids (e.g. from the same department or group)
# The function performs a search in Scopus and returns a dataframe with 
# bibliometric data for a given time period
#
# The xlsx file names are used to build the table of results, so the file name
# could be the name of department or group. In the code it is assumed to be
# the name of the department
#
# Each file must contain at least a column called
# scopus_id (author scopus_id, where available)
#
# 
# api_key: your Scopus API key
# file_path: file to a directory containing the files
# period: the time period, e.g. 2017:2021 (optional, but recommended for long lists)
#
# Needs packages tidyverse, bibliometrix
#
#
sc_bibliostats_univ_multiple <- function(api_key, file_path, period=NULL){
  
# select xlsx files to compare
file_list <- list.files(path=file_path,pattern=".xlsx",full.names = TRUE)

faculty_list <- lapply(file_list, readxl::read_excel)

#find authors not indexed in Scopus
faculty_no_scopus_list <- lapply(faculty_list, function(x) x%>% subset(is.na(`scopus_id`)))

#get department names in a list
dept_names_list <- lapply(lapply(file_list, tools::file_path_sans_ext),basename)

#get scopus_ids in a list
id_list <- lapply(faculty_list, function(x) x%>% select(`scopus_id`))

## create the bibliographic collections of each dept in a list
#
res_list <- lapply(id_list,retrievalByAuthorID,api_key,remove.duplicated = TRUE,country = FALSE)
#
BIB_DF <- list()
for (i in 1:length(res_list)) {
  BIB_DF[[i]] <- as.data.frame(res_list[[i]][["M"]])
}

#filter documents in period, if given
if(!missing(period)){
BIB_DF <- lapply(BIB_DF, function(M) M %>% filter(PY %in% (period)))
}

#calculate number of articles and citations
faculty_count_list <- lapply(faculty_list, nrow)
faculty_count_no_scopus_list <- lapply(faculty_no_scopus_list,nrow)
articles_count_list <- lapply (BIB_DF,nrow)
citation_count_list <- lapply (BIB_DF,function(y) sum(y$TC))

dept_names <- unlist(dept_names_list)
faculty_count <- unlist(faculty_count_list)
faculty_count_no_scopus <- unlist(faculty_count_no_scopus_list)
articles_count <- unlist(articles_count_list)
citation_count <- unlist(citation_count_list)

articles_per_faculty_member <- articles_count/faculty_count
citations_per_faculty_member <- citation_count/faculty_count
citations_per_article <- citation_count/articles_count

#summary_data_frame
summary_depts <- tibble("Department"=dept_names,"Number of faculty members"=faculty_count,
                        "Number of faculty members without a Scopus profile"=faculty_count_no_scopus,
                        "Articles in period"=articles_count,
                        "Citations"=citation_count,"Articles per faculty_member"=articles_per_faculty_member,
                        "Citations per faculty_member"=citations_per_faculty_member,
                        "Citations_per_article"=citations_per_article) %>% arrange(desc(`Citations per faculty_member`))

return(summary_depts)
}
