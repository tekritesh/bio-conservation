library(ggplot2)
library(ggmap)
library(data.table)
library(leaflet)



dtData<-
  fread(
    "/home/ritesh/Downloads/consolidated_data.csv"
  )




# ==================================Stamen=====================================

qmplot(
  data =
    dtData,
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
    scientificName,
  # 'red',
  size=
    2,
  alpha = 
    0.7
  # zoom = 1
)
  # scale_color_continuous(low = 'blue', high = 'red')

# ====================================Leaflet===================================

# https://rstudio.github.io/leaflet/raster.html
pal <- colorFactor(
  palette = "Dark2",
  domain = dtData$scientificName
)

m <- leaflet(dtData) %>%
  addTiles() %>%
  addCircles(
    lat = ~decimalLatitude,
    lng = ~decimalLongitude,
    radius = 500,
    opacity = 100,fill = T,
    popup = c(dtData$scientificName),
    color = ~pal(scientificName)
      
  ) %>%
  setView(lng = mean(dtData$decimalLongitude), lat = mean(dtData$decimalLatitude), zoom = 12) 

m
  # addLegend(
  #   position = "bottomright",
  #   values = ~scientificName,
  #   title = "Species",
  #   pal = 
  #           # labFormat = labelFormat(prefix = "$"),
  #           # opacity = 1
  # )
m
