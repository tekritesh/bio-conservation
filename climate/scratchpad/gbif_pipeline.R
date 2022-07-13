# ==============================LIBS============================================
library(data.table)
library(logger)
library(rgbif)
library(bigQueryR)



# ==============================================================================



countries_to_fetch = c("GB","BZ")
years = 2020:2022
# end_year = 2022
# months = 1:12 

dir.create(
  path = '/mnt/Work/PersonalData/Raw/GBIF/Logs',showWarnings = F,recursive = T
)
dir.create(
  path = '/mnt/Work/PersonalData/Raw/GBIF/Trace',showWarnings = F,recursive = T
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

if( file.exists('/mnt/Work/PersonalData/Raw/GBIF/Trace/LastRun.csv')){
  dtTrace<- fread('/mnt/Work/PersonalData/Raw/GBIF/Trace/LastRun.csv')
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
  
  write.csv(dtTrace,'/mnt/Work/PersonalData/Raw/GBIF/Trace/LastRun.csv',row.names = F)
  
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
        # iPartition = 2
        
        tryCatch(
          {
            dtTrace<- fread('/mnt/Work/PersonalData/Raw/GBIF/Trace/LastRun.csv')
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
            
            
            start_of_query_time = Sys.time()
            if ( nrow(
              dtTrace[year == iYear &
                      start_month == istart_month &
                      end_month == iend_month ]) == 0 ){
              
              
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
              dtTrace<-fread('/mnt/Work/PersonalData/Raw/GBIF/Trace/LastRun.csv')
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
              
              write.csv(dtTrace,'/mnt/Work/PersonalData/Raw/GBIF/Trace/LastRun.csv',row.names = F)
              
              Sys.sleep(2*60)
              log_info(
                paste0(
                  "Query ID:",
                  igbif_query_id
                )
              )
              
              
            }else{
              
              log_info(
                paste0(
                  "Query already run for Bulk Download from ",
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
              
              
              dtResults<- dtResults[,
                        list(
                          gbifID = as.numeric(gbifID),
                          datasetKey = as.character(datasetKey),
                          occurrenceID = as.character(occurrenceID),
                          kingdom = as.character(kingdom),
                          phylum=as.character(phylum),
                          class=as.character(class),
                          order=as.character(order),
                          family=as.character(family),
                          genus=as.character(genus),
                          species=as.character(species),
                          infraspecificEpithet=as.character(infraspecificEpithet),
                          taxonRank=as.character(taxonRank),
                          scientificName=as.character(scientificName),
                          verbatimScientificName=as.character(verbatimScientificName),
                          verbatimScientificNameAuthorship = as.character(verbatimScientificNameAuthorship),
                          countryCode=as.character(countryCode),
                          locality=as.character(locality),
                          stateProvince=as.character(stateProvince),
                          occurrenceStatus=as.character(occurrenceStatus),
                          individualCount=as.character(individualCount),
                          publishingOrgKey=as.character(publishingOrgKey),
                          decimalLatitude=as.numeric(decimalLatitude),
                          decimalLongitude=as.numeric(decimalLongitude),
                          coordinateUncertaintyInMeters=as.numeric(coordinateUncertaintyInMeters),
                          coordinatePrecision=as.numeric(coordinatePrecision),
                          elevation=as.numeric(elevation),
                          elevationAccuracy=as.numeric(elevationAccuracy),
                          depth=as.numeric(depth),
                          depthAccuracy=as.numeric(depthAccuracy),
                          eventDate=as.POSIXct(eventDate),
                          day=as.numeric(day),
                          month=as.numeric(month),
                          year=as.numeric(year),
                          taxonKey=as.numeric(taxonKey),
                          speciesKey=as.numeric(speciesKey),
                          basisOfRecord=as.character(basisOfRecord),
                          institutionCode=as.character(institutionCode),
                          collectionCode=as.character(collectionCode),
                          catalogNumber=as.numeric(catalogNumber),
                          recordNumber=as.numeric(recordNumber),
                          identifiedBy=as.character(identifiedBy),
                          dateIdentified=as.POSIXct(dateIdentified),
                          license = as.character(license),
                          rightsHolder=as.character(rightsHolder),
                          recordedBy=as.character(recordedBy),
                          typeStatus=as.character(typeStatus),
                          establishmentMeans=as.character(establishmentMeans),
                          lastInterpreted=as.POSIXct(lastInterpreted),
                          mediaType=as.character(mediaType),
                          issue=as.character(issue)                         
                          
                        )
                        
                        
                        
                        ]
              
              
              if ( nrow(dtResults) > 0 ){
                
                
                log_info(
                  paste0("Received Data Rows:", nrow(dtResults))
                )
                # Upload to BQ
                
                
                if( dtTrace[ gbif_query_id == igbif_query_id , upload] == F  ){
                  
                  log_info(
                    paste0("Initiating BQ Upload Sequence")
                  )
                  
                  tryCatch(
                    {
                      bqr_auth(json_file = "molten-kit-354506-12dcdc7ea89a.json")    
                      dtTrace[gbif_query_id ==  igbif_query_id, upload := T] 
                      write.csv(dtTrace,'/mnt/Work/PersonalData/Raw/GBIF/Trace/LastRun.csv',row.names = F)
                      
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
                      message(cond)
                      # log_info(cond)
                      log_info(
                        paste0("Upload Successful!")
                      )
                      # log_info("Error Error Error Level 1!! Dont want to Exit")
                      return(0)
                    } 
                  )
                  
                  
                }else{
                  log_info(
                    paste0("Data has been uploaded to BQ")
                  )
                  
                }
                
                
              }
            }
            
            
          },
          error=function(cond) {
            # log_info(cond)
            log_info("Error Error Error!! Exiting..............")
            
            message(cond)
            
            return(0)
          }
        )
      }
    )
  }
)





