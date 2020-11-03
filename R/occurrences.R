#https://www.idigbio.org/wiki/images/5/50/2_Chamberlain_1280-720.pdf

pacman::p_load(tidyverse, rvest, xml2, rgbif, ggmap, maptools, maps)

dat <- occ_search(taxonKey=9592496, limit=10000, hasCoordinate=TRUE) 

datasets <- dat$data %>%
  select(datasetKey) %>%
  distinct()

sites <- dat$data %>%
  select(datasetKey, decimalLatitude, decimalLongitude, locality, relativeOrganismQuantity) %>%
  mutate(decimalLatitude = round(decimalLatitude, 2),
         decimalLongitude = round(decimalLongitude, 2)) %>%
  group_by(datasetKey, decimalLatitude, decimalLongitude, locality) %>%
  summarise(relativeOrganismQuantity = max(relativeOrganismQuantity, na.rm = T))

metadata <- dat$data %>%
  select(datasetKey, decimalLatitude, decimalLongitude, eventRemarks, materialSampleID, references) %>%
  distinct() %>%
  mutate(decimalLatitude = round(decimalLatitude, 2),
         decimalLongitude = round(decimalLongitude, 2),
         reference = if_else(is.na(materialSampleID), references, materialSampleID)) %>%
  group_by(datasetKey, decimalLatitude, decimalLongitude) %>%
  summarise(info = list(eventRemarks),
            reference = list(reference))


get_title <- function(key){
  url <- paste0("https://www.gbif.org/dataset/", key)
  url %>%
    read_html() %>%
    html_node("h1") %>%
    html_text() %>%
    str_squish()
}



get_descriptions <- function(key){
  url <- paste0("https://www.gbif.org/dataset/", key)
  text <- url %>%
    read_html() %>%
    html_nodes("div")
  
  text[16] %>% 
    str_squish() %>%
    str_extract("(?<=><h2>Description</h2> )(.*)(?= </section><section><h2>Sampling Description</h2>)")
}

titles <- list()
descriptions <- list()
for(i in 1:length(datasets$datasetKey)){
  titles <- append(titles, get_title(datasets$datasetKey[i]))
  descriptions <- append(descriptions, get_descriptions(datasets$datasetKey[i]))
}

data <- datasets %>%
  bind_cols(title = unlist(titles), description = unlist(descriptions)) %>%
  full_join(sites) %>%
  left_join(metadata)

#write_csv(data, "occurrences.csv")
annotated_data <- read_csv("../data/occurrences.csv")
#map
mp <- NULL
mapWorld <- borders("world", colour="gray50", fill="gray50") # create a layer of borders
mp <- ggplot() +   mapWorld

occurrences <- ggplot() +  
  mapWorld +
  geom_point(aes(annotated_data$decimalLongitude, annotated_data$decimalLatitude, color=annotated_data$environment, shape = annotated_data$sequence_type, label = paste0("type: ", annotated_data$sample_type, " note: ",annotated_data$note)), size=2) + 
  geom_point(aes(x = -103.75, y = 44.35), color = "red", size = 4)

plotly::ggplotly(occurrences)
