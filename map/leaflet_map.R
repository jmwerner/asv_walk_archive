library(leaflet)
library(jsonlite)
library(htmlwidgets)

# Miles completed can come in as command line arg
args = commandArgs(trailingOnly = TRUE)

# Total trip milage (along path - from google)
milesTotal = 2930

if(is.na(args[1])){
    milesCompleted = 0
}else{
    milesCompleted = as.numeric(args[1])
}

print(paste("Generating map for", milesCompleted, "completed miles"))

# GIS libraries all suck, so I'm writing my own more accurate distance functions
calculatePointwiseDistances = function(lat, lon) {
    latDiff = diff(lat)
    lonDiff = diff(lon)
    distances = c(0, sqrt(latDiff^2 + lonDiff^2))
    distances
}

# Finding the vector index where the percentages overtake the total percent complete
findCumulativeDistanceIndex = function(distancePercentages, milesCompleted, milestotal) {
    index = 1
    if(milesCompleted >= milesTotal){
        index = length(distancePercentages)
    }else{
        while(distancePercentages[index] <= milesCompleted / milesTotal) {
        index = index + 1
        }    
    }
    index
}

# Using fromJSON instead of graphics libs because they are all unnecessarily hard to use
directions = read.csv('../generate_coords/route_points.csv', header = FALSE)
names(directions) = c('lat', 'lon')

lattitude = directions[,1]
longitude = directions[,2]
pointwiseDistances = calculatePointwiseDistances(lattitude, longitude)
cumulativeDistancePercentage = cumsum(pointwiseDistances) / sum(pointwiseDistances)

pointsOfInterest = data.frame(longitude = c(-122.17677, -80.5976773),
                              lattitude = c(37.47977, 28.2129335),
                              popup = c("ASV",  "Ed Johnson"))

# New lat/lon pointwise distance method
distanceIndex = findCumulativeDistanceIndex(cumulativeDistancePercentage, 
                                            milesCompleted, 
                                            milesTotal)

# Make sure it's between 1 and length(lattitude), reassign if not
if(distanceIndex < 1) {
    distanceIndex = 1
}

if(distanceIndex > length(lattitude)) {
    distanceIndex = length(lattitude)
}

johnson_icon <- makeIcon(
  iconUrl = "johnson_icon.png",
  iconWidth = 70, iconHeight = 70
)

gh_icon <- makeIcon(
  iconUrl = "gh_icon.png",
  iconWidth = 50, iconHeight = 50
)

walking_icon <- makeIcon(
  iconUrl = "walking_icon.png",
  iconWidth = 50, iconHeight = 50
)

walkAcrossUSA = leaflet() %>% 
           addProviderTiles(providers$Esri.NatGeoWorldMap) %>% 
           # addProviderTiles("CartoDB.Positron") %>%
           # addProviderTiles("Stamen.Toner") %>%
           # addTiles(group = "OSM (default)") %>%
           #     addProviderTiles("MtbMap") %>%
           #     addProviderTiles("Stamen.TonerLines",
           #         options = providerTileOptions(opacity = 0.8)
           #     ) %>%
           # # addProviderTiles("Stamen.TonerLabels") %>%
           addPolylines(lat = lattitude, lng= longitude, color = "white", weight = 8) %>%
           addPolylines(lat = lattitude, lng= longitude, color = "blue", weight = 6) %>%
           addPolylines(lat = lattitude[1:distanceIndex], lng= longitude[1:distanceIndex], color = "red", weight = 9) %>%
           addMarkers(lat = pointsOfInterest$lattitude[1], lng = pointsOfInterest$longitude[1], popup = pointsOfInterest$popup[1], icon = gh_icon) %>%
           addMarkers(lat = pointsOfInterest$lattitude[2], lng = pointsOfInterest$longitude[2], popup = pointsOfInterest$popup[2], icon = johnson_icon) %>%
           addMarkers(lat = lattitude[distanceIndex], lng = longitude[distanceIndex], popup = paste("Completed about", milesCompleted, "miles as of", format(Sys.time(), "%a %b %d")), icon = walking_icon)


saveWidget(walkAcrossUSA, file = "index.html")

