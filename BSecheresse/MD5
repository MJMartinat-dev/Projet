# ------------------------------------------------------------------------------
# R/import_stations_geo.R
# ------------------------------------------------------------------------------
# AUTEUR      : MJMartinat
# Structure   : DDT de la Drôme
# DATE        : 01/06/2025
# ------------------------------------------------------------------------------
# DESCRIPTION : Import des stations (Drôme) avec coordonnées → sf
# ------------------------------------------------------------------------------
# Chargement des bibliothèques
# ------------------------------------------------------------------------------
library(jsonlite)
library(dplyr)
library(sf)


# ------------------------------------------------------------------------------
# API de stations hydrométriques en Drôme
# ------------------------------------------------------------------------------
url <- "https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/stations?code_departement=26&format=json"


# ------------------------------------------------------------------------------
# Import JSON
# ------------------------------------------------------------------------------
stations_data <- fromJSON(url, flatten = TRUE)$data


# ------------------------------------------------------------------------------
# Transformation en objet sf (points géographiques)
# ------------------------------------------------------------------------------
stations_sf <- st_as_sf(
  stations_data,
  coords = c("longitude_station", "latitude_station"),
  crs = 4326
)


# ------------------------------------------------------------------------------
# Sauvegarde locale (optionnelle)
# ------------------------------------------------------------------------------
sf::st_write(
  stations_sf,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "stations_drome.geojson"
  ),
  delete_dsn = TRUE
)
