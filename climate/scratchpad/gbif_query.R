
# ==============================LIBS============================================
library(data.table)
library(logger)
library(curl)
library(rgbif)
library(ggplot2)
library(ggmap)

theme_set(theme_bw())


cFilePath  = "/mnt/Work/PersonalData/Raw/GBIF/"

dir.create(
  path = paste0(cFilePath,"Maps/"),
  showWarnings = F,
  recursive = T
)

dir.create(
  path = paste0(cFilePath,"Data/"),
  showWarnings = F,
  recursive = T
)

dir.create(
  path = gsub(pattern = "Raw",replacement = "Processed",x = cFilePath) ,
  showWarnings = F,
  recursive = T
)




# ==============================GBIF QUERY======================================

vSpeciesToQuery<- c("Rhinoceros unicornis","Bubo bengalensis")

# -------------
# Species : Rhinoceros unicornis
#Ahmedabad: 23.0225° N, 72.5714° E
#Tripura: 23.9408° N, 91.9882° E
# 
#Amritsar: 31.6340° N, 74.8723° E
#Trivandrum: 8.5241° N, 76.9366° E
# -------------




# note that coordinate ranges must be specified this way: "smaller, larger" (e.g. "-5, -2")
vLongitudeLimits<- "72,91"
vLatitudeLimits<- "8.5,31.5"


# Species + Coordinates
gbif_raw <- 
  occ_data(
    scientificName = vSpeciesToQuery,
    hasCoordinate = TRUE,
    limit = 20000,
    decimalLongitude = vLongitudeLimits,
    decimalLatitude = vLatitudeLimits
    )  




# - Contents of Query Results
lapply(
  gbif_raw,
  function(iElement){
    print(iElement)  
    
  }
)



# - If we need
vCitations<- 
  gbif_citation(gbif_raw)


#Filteting List Object 


dtData<-
  rbindlist(
    lapply(
      names(gbif_raw),
      function(iElement){
        
        
        dtTemp<- data.table(
          get(
            "data",
            get(
              iElement,
              gbif_raw)
          )
          
        )
        
        return(dtTemp)
      }
      ),
    use.names = T,
    fill = T
  )





# dtData<-
#   data.table(
#     gbif_raw$data
#     )

if(F){
  
  cFileName<- 
    paste(
      paste0(cFilePath,"Data"),
      paste(sapply(unique(dtData$scientificName), paste, collapse="_"), collapse="_"),
      sep = "/"
    )
  
  save(
    list = 
      "dtData",
    file = 
      paste0(
        cFileName,
        ".RData"
        )
    )
  
}






# ===============================GBIF PLOTS=====================================

if(F){
  height <- dtData[, diff(range(decimalLatitude))]
  width <- dtData[, diff(range(decimalLongitude))]
  sac_borders <- c(bottom  = min(dtData$decimalLatitude)  - 0.1 * height, 
                   top     = max(dtData$decimalLatitude)  + 0.1 * height,
                   left    = min(dtData$decimalLongitude) - 0.1 * width,
                   right   = max(dtData$decimalLongitude) + 0.1 * width)
  map <- get_stamenmap(sac_borders, zoom = 10, maptype = "toner-lite")
  
  cFileName<- 
    paste(
      round(sac_borders[1]),
      round(sac_borders[2]),
      round(sac_borders[3]),
      round(sac_borders[4]),
      sep = "_"
    )
  
  save(
    list = "map",
    file = 
      paste0(
        cFilePath,
        "Maps/",
        cFileName,
        ".Rdata"
        )
  )
  
}


qmplot(
  data =
    dtData,
  x = 
    decimalLongitude,
  y = 
    decimalLatitude,
  maptype = 
    "terrain",
    # "toner",
  geom = 
    "point",
  col = 
    scientificName,
    # 'red',
  size=
    2,
  alpha = 
    0.7
  )

# ggmap(map)+
# # ggplot()+
#   geom_point(
#     data = 
#       dtData,
#     aes(
#       x = 
#         decimalLatitude,
#       y =
#         decimalLongitude
#     ),
#     alpha = 
#       0.7
#   )

# ===============================GBIF PHOTOS====================================

res<- 
  occ_search(
    scientificName = 
      "Aves",
      # vSpeciesToQuery[1],
    mediaType = 'StillImage',
    limit=10
    )

gbif_photos(
  res
  # which='map'
  
  
)

# ================================================================================
# 
# Species lists and bounding boxes:
#   
#   years = [2021, 2022]
# 
# brazil_species = ['Chrysocyon brachyurus', 'Callithrix jacchus',
#                   'Euphractus sexcinctus', 'Nasua nasua',
#                   'Hydrochoerus hydrochaeris']
# uk_species = ['Erinaceus roumanicus', 'Vulpes vulpes',
#               'Phoca vitulina', 'Lutra lutra',
#               'Branta canadensis']
# Longitude:
#   country	                                       min	    max
# 0	Brazil	                      -72.87397	   -34.808346
# 1	United Kingdom            -7.42667	      1.747407
# 
# Latitude:
#   country	                        min	                  max
# 0	Brazil	             -30.340799	-1.292262
# 1	United Kingdom    50.025300	 60.789810



# Reference:https://search.r-project.org/CRAN/refmans/rgbif/html/occ_download.html
# https://data-blog.gbif.org/post/downloading-long-species-lists-on-gbif/
  
  
uk_species = c('Erinaceus roumanicus', 'Vulpes vulpes','Phoca vitulina', 'Lutra lutra','Branta canadensis')
gbif_taxon_keys <- uk_species %>% # use fewer names if you want to just test 
  name_backbone_checklist()  %>% # match to backbone
  filter(!matchType == "NONE") %>% # get matched names
  pull(usagekey)

brazil_species = c('Chrysocyon brachyurus', 'Callithrix jacchus','Euphractus sexcinctus', 'Nasua nasua','Hydrochoerus hydrochaeris')
gbif_taxon_keys <- brazil_species %>% # use fewer names if you want to just test 
  name_backbone_checklist() 
  # filter(!matchType == "NONE") %>% # get matched names
  # pull(usagekey)


# gbif_taxon_keys<-gbif_taxon_keys

x = occ_download(
  user='riteshtekriwal',
  pwd = '1235qwet',
  email = 'tekritesh@gmail.com',
  format = "SIMPLE_CSV",
  pred_in("taxonKey", gbif_taxon_keys$usageKey),
  # pred_in("hasCoordinate", TRUE),
  pred_in("country", c("BR")),
  pred_in("year", 2022)
)


x
occ_download_wait(x[1])

d <- occ_download_get(x[1]) %>%
  occ_download_import()
dtResults<- data.table(d)
