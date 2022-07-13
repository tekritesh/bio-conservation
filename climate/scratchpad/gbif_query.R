
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
  # pred_in("taxonKey", gbif_taxon_keys$usageKey),
  # pred_in("hasCoordinate", TRUE),
  pred_in("country", c("GB")),
  # pred_and(pred_gte("year", 2020), pred_lte("year", 2022))
  # pred_and(pred_gte("year", 2020), pred_lte("year", 2022))
  pred_in("year", 2022),
  pred_in("month", 3)
)


x
occ_download_wait(x[1])

d <- occ_download_get(x[1]) %>%
  occ_download_import()
dtResults<- data.table(d)


# ==============================================================================



countries_to_fetch = c("GB","BZ")
years = 2020:2022
# end_year = 2022
# months = 1:12 

dir.create(
  path = '/mnt/Work/PersonalData/Raw/GBIF/Logs',showWarnings = F,recursive = T
)
log_file_name = paste0('/mnt/Work/PersonalData/Raw/GBIF/Logs/',Sys.time(),".txt")
log_appender(
  appender_file(
    file =log_file_name,
    append = TRUE,
    max_lines = Inf,
    max_bytes = Inf,
    max_files = 1L
  )
)

if( file.exists('/mnt/Work/PersonalData/Raw/GBIF/Logs/LastRun.csv')){
  dtTrace<- fread('/mnt/Work/PersonalData/Raw/GBIF/Logs/LastRun.csv')
}else{
  dtTrace<-
    data.table(
      gbif_query_id = "",
      year = 0,
      start_month =0,
      end_month = 0,
      country = "",
      success = F
    )
  
  write.csv(dtTrace,'/mnt/Work/PersonalData/Raw/GBIF/Logs/LastRun.csv',row.names = F)
  
}



lapply(
  years,
  function(iYear){
    # iYear = 2020
    # iMonths<- 12
    iNumberofMonthsToQuery<- 2
    
    lapply(
      1:(12/iNumberofMonthsToQuery), 
           function(iPartition){
             # iPartition = 1
            
             tryCatch(
               {
                 
                 istart_month = ((iPartition - 1)*iNumberofMonthsToQuery) + 1
                 iend_month = (iPartition )*iNumberofMonthsToQuery 
                 
                 log_info(
                   paste0(
                     "Running GBIF Bulk Download from ",
                     iYear,
                     "-",
                     istart_month,
                     " to ",
                     iYear,
                     "-",
                     iend_month,
                     " for ",
                     paste(countries_to_fetch,collapse = ',')
                   )
                 )
                 
                 if ( nrow(
                   dtTrace[year == iYear &
                           start_month == istart_month &
                           end_month == iend_month ]) == 0 ){
                   start_of_query_time = Sys.time()
                   
                   iQuery = occ_download(
                     user='riteshtekriwal',
                     pwd = '1235qwet',
                     email = 'tekritesh@gmail.com',
                     format = "SIMPLE_CSV",
                     pred_in("country", countries_to_fetch),
                     pred_in("year", iYear),
                     pred_and(pred_gte("month", istart_month), pred_lte("month", iend_month))
                   )
                   igbif_query_id = iQuery[1]
                   dtTrace<-fread('/mnt/Work/PersonalData/Raw/GBIF/Logs/LastRun.csv')
                   dtTrace<- 
                     rbind(
                       dtTrace,
                       data.table(
                         gbif_query_id = igbif_query_id,
                         year = iYear,
                         start_month = istart_month,
                         end_month = iend_month,
                         country = paste(countries_to_fetch,collapse = ','),
                         query = T,
                         upload = F
                       )
                       
                     )
                   
                   write.csv(dtTrace,'/mnt/Work/PersonalData/Raw/GBIF/Logs/LastRun.csv',row.names = F)
                   
                   Sys.sleep(2*60)
                   log_info(
                     paste0(
                       "Query ID:",
                       gbif_query_id
                     )
                   )
                   
                   
                 }else{
                   igbif_query_id <-
                     dtTrace[year == iYear &
                               start_month == istart_month &
                               end_month == iend_month,
                             gbif_query_id
                             ]
                     
                   
                 }
                 
                 # gbif_query_id = "0384128-210914110416597"
                 iQueryStatus<- occ_download_wait(igbif_query_id)
                 
                 if(iQueryStatus$status == 'SUCCEEDED'){
                   
                   
                   log_info(
                     paste0(
                       "Time taken to finish the query:",
                       round(Sys.time()-start_of_query_time,2),
                       ' secs'
                     )
                   )
                   
                   start_of_query_time = Sys.time()
                   
                   iRawData <- occ_download_get(igbif_query_id) %>% occ_download_import()
                   
                   log_info(
                     paste0(
                       "Time taken to fetch the data:",
                       round(Sys.time()-start_of_query_time,2),
                       ' secs'
                     )
                   )
                   
                   dtResults<- data.table(iRawData)
                   
                   dtResults[,gbifID:=as.numeric(gbifID)]
                   
                   
                   if ( nrow(dtResults) > 0 ){
                     
                     
                     log_info(
                       paste0("Received Data Rows:", nrow(dtResults))
                     )
                     # Upload to BQ
                     
                     
                     if( dtTrace[ gbif_query_id == igbif_query_id & upload == F ]  ){
                       
                       log_info(
                         paste0("Initiating BQ Upload Sequence")
                       )
                       
                       tryCatch(
                         {
                           bqr_auth(json_file = "molten-kit-354506-12dcdc7ea89a.json")     
                           bqr_upload_data(
                             projectId = 'molten-kit-354506',
                             datasetId =  "gbif",
                             tableId = 'occurence_data',
                             upload_data = dtResults,
                             create = c("CREATE_IF_NEEDED"),
                             writeDisposition = "WRITE_APPEND",
                             wait = F
                             # create = 'CREATE_IF_NEEDED'
                           )
                           
                           log_info(
                             paste0("Upload Successful!")
                           )
                         },
                         error =function(cond){
                           # message(cond)
                           log_info("Error Error Error Level 1!! Dont want to Exit")
                           return(0)
                         }
                         
                         
                       )
                       
                       
                       
                       
                       dtTrace[gbif_id ==  igbif_query_id, success = T] 
                       write.csv(dtTrace,'/mnt/Work/PersonalData/Raw/GBIF/Logs/LastRun.csv',row.names = F)
                       
                     }
                     
                     
                   }
                 }
                 
                 
               },
               error=function(cond) {
                 log_info("Error Error Error!! Exiting..............")
                 message(cond)
                 
                 
                 next()
                 # stop()
                 
               }
               
               
             )
             
           }
      )
    }
  )





