


# ===================================Libs/Funcs=================================
source(
  paste(
    getwd(),
    'gbif_functions.R',
    sep = '/'
  )
)

#Inputs

vSpeciesNames = c("Rhinoceros unicornis","Bubo bengalensis")
top_left_lat_deg = 8.5
top_left_lon_deg = 72
bottom_right_lat_deg = 31.5
bottom_right_lon_deg = 91
year= '2022'


# ====================================Querys====================================


if(T){
  
    dtRawSpecies<-
      fGetSpecies(
        vSpeciesNames = vSpeciesNames,
        top_left_lat_deg = top_left_lat_deg,
        top_left_lon_deg = top_left_lon_deg,
        bottom_right_lat_deg = bottom_right_lat_deg,
        bottom_right_lon_deg = bottom_right_lon_deg,
        cNumberofDataPoints = 100000
      )
    
  dtStations<-
    fGetClimateStations(
      country_name = "Brazil",
      # centre_lat_deg = median(dtRawSpecies$decimalLatitude),
      # centre_lon_deg = median(dtRawSpecies$decimalLongitude),
      # no_of_stations = 50,
      use_country = T
      )
  
  
  dtRawClimate<- 
    fGetHourlyWeatherData(
      vListofStationIDs = dtStations$wmo_id ,
      vListofStationNames = dtStations$station_names,
      vListofStationLat_Deg = dtStations$lat,
      vListofStationLon_Deg = dtStations$lon,
      year = year
      )

  
}


if(F){
  library(ggplot2)
  library(ggmap)
  # Test Plot
  qmplot(
    data =
      dtRawSpecies,
    y = 
      decimalLatitude,
    x = 
      decimalLongitude,
    maptype = 
      "terrain",
    # "toner",
    geom = 
      "point",
    col =
    species,
    # 'red',
    size=
      2,
    alpha = 
      0.7
    # zoom = 1
  )
  
}

# ===========================Stitching is WIP===================================

if(T){
  # Cleaning/subsetting the datasets, standardizing some names
  
  # dtRawSpecies<-dtRawSpecies[complete.cases(dtRawSpecies)]
  # dtRawSpecies<-fread("/home/ritesh/Desktop/BZ.csv")
  # dtRawClimate<-fread("/home/ritesh/Desktop/BZ_Climate.csv")
  # 
  dtSpecies<- 
    dtRawSpecies[,
                 list(
                   species,
                   speciesKey,
                   scientificName,
                   
                   decimalLatitude,
                   decimalLongitude,
                   coordinateUncertaintyInMeters,
                   # stateProvince,
                   countryCode,
                   
                   year,
                   month,
                   day,
                   eventDate,
                   
                   # publishingCountry,
                   stateProvince,
                   basisOfRecord,
                   recordedBy
                 )
    ]
  
  # Questions to Answer: ?
  # What is our strategy to merge by geo coordiantes
  # 1 deg is roughly = 100kms, so 2nd decimal place is around 1km. Is that good enough for climate data?
  # Data that we have has upto 4 decimal places. Shall we go more granular?
  
  # 
  
  dtRawClimate<-dtRawClimate[complete.cases(dtRawClimate)]
  dtClimate<- 
    dtRawClimate[,
                 list(
                   altitude = mean(alt,na.rm = T),
                   mean_air_temp_C = mean(t2m,na.rm = T),
                   mean_dew_point = mean(dpt2m,na.rm = T),
                   wind_speed_mps = mean(ws,na.rm = T),
                   wind_direction_deg = mean(wd,na.rm = T),
                   sea_level_pressure_hPa = mean(slp,na.rm = T),
                   visibility_m = mean(visibility,na.rm = T)
                 ),
                 list(
                   station_name,
                   decimalLatitude = round(lat,2),
                   decimalLongitude = round(lon,2),
                   year,
                   month,
                   day
                 )
    ]
  
  
  
  dtResult<-
    rbindlist(
      lapply(
        1:nrow(dtSpecies),
        function(iRow){
          # iRow = 7
          
          dtUniqueStations<- dtClimate[, .N, list( station_name, decimalLatitude, decimalLongitude)]
          dtTemp<-dtSpecies[iRow]
          # unique_names <- unique(colnames(dtTemp))
          # dtTemp <- dtTemp[unique_names]
          
          iLat_deg = dtTemp[,decimalLatitude]
          iLon_deg = dtTemp[,decimalLongitude]
          
          dtUniqueStations[,
                           distance_m := 
                             dtHaversine(
                               lat_from = iLat_deg,
                               lon_from = iLon_deg,
                               lat_to = decimalLatitude,
                               lon_to = decimalLongitude
                             )                 
          ]
          
          # setorder(dtUniqueStations, distance_m)
          
          distanceFromClosestStation_m<- dtUniqueStations[,min(distance_m,na.rm = T)]
          
          dtNearestStation<-
            dtClimate[
              station_name == 
                dtUniqueStations[distance_m == distanceFromClosestStation_m, station_name]
              ]
          
          
          
          dtNearestStation[,
                           delta_days:=
                             abs(as.numeric(
                               as.Date(paste(year,month,day,sep = "-")) - 
                                 as.Date(dtTemp$eventDate)
                               ))
                           ]
          
          setorder(dtNearestStation, delta_days)
          
          dtNearestStation<-dtNearestStation[1]
            
          
          # iTemp<- 
            # dtNearestStation[ delta_days == min(delta_days,na.rm = T), mean_air_temp_C ]
          
          dtTemp[,closest_station:= dtNearestStation$station_name ]
          
          # setnames(dtNearestStation,"station_name","closest_station")
          
          dtTemp<-
            merge(
              dtTemp,
              dtNearestStation[,
                               list(
                                 closest_station = station_name,
                                 station_lat_deg =decimalLatitude,
                                 station_lon_deg =decimalLongitude,
                                 
                                 altitude,
                                 mean_air_temp_C,
                                 mean_dew_point,
                                 wind_speed_mps,
                                 wind_direction_deg,
                                 sea_level_pressure_hPa,
                                 visibility_m,
                                 last_temp_recorded_days = delta_days
                               )
                               ],
              by = 
                'closest_station',
              all = T
            )
          
          # if(length(iTemp)> 1){
            cat(
              "Row:",iRow,
              # " Temp:",iTemp,
              # " meanTemp:", mean(iTemp),
              # "days:",dtNearestStation[ delta_days == min(delta_days,na.rm = T),(delta_days) ],
              "\n"
            )  
          
          return(dtTemp)
          
        }
      ),
      use.names = T,
      fill = T
    )
  
  
}

# ============================Data Upload=======================================
library(bigQueryR)
library(googleAuthR)
library(googleCloudStorageR)

bqr_auth(json_file = "molten-kit-354506-12dcdc7ea89a.json")

dtResult[, stateProvince:= ifelse(stateProvince == "",NA,stateProvince)]

bqr_upload_data(
  projectId = 'molten-kit-354506',
  datasetId =  "sample_gbif_climate",
  tableId = 'consolidated_UK_2O22',
  upload_data = as.data.table(dtResult),
  create = 'CREATE_IF_NEEDED',
  wait = T,
  autodetect = T)




# ==============================================================================




