# ------------------------------------------------------------------------------
# SCRIPT      : import_meteofr.R
# ------------------------------------------------------------------------------
# AUTEUR      : MJMartinat
# Structure   : DDT de la Drôme
# DATE        : 01/06/2025
# ------------------------------------------------------------------------------
# DESCRIPTION :
# SORTIE      :
# ------------------------------------------------------------------------------
# Chargement des bibliothèques
# ------------------------------------------------------------------------------
library(httr)
library(stars)
library(glue)


# ------------------------------------------------------------------------------
# Paramètres d’auth (environnement .Renviron conseillé)
# ------------------------------------------------------------------------------
login <- Sys.getenv("API_MF_LOGIN")
mdp   <- Sys.getenv("API_MF_PWD")
jeton <- Sys.getenv("API_MF_TOKEN")

coverageid  <- "PRECIP__surface"
date_debut  <- Sys.Date()
date_fin    <- Sys.Date() + 6
lat_min <- 44.36; lat_max <- 45.26
lon_min <- 4.89; lon_max <- 5.37

wcs_url <- "http://public-api.meteofrance.fr:8280/public/arpege/1.0/wcs/MF-NWP-GLOBAL-ARPEGE-01-EUROPE-WCS/GetCoverage"
query <- list(
  service = "WCS",
  version = "2.0.1",
  coverageid = coverageid,
  format = "application/wmo-grib"
)
url_full <- httr::modify_url(wcs_url, query = query)
url_full <- paste0(
  url_full,
  "&subset=", glue("lat({lat_min},{lat_max})"),
  "&subset=", glue("lon({lon_min},{lon_max})"),
  "&subset=", glue('time("{date_debut}T00:00:00Z","{date_fin}T23:00:00Z")')
)

grib_file <- tempfile(fileext = ".grib2")
res <- httr::GET(
  url_full,
  httr::authenticate(login, mdp),
  httr::add_headers(Authorization = paste("Bearer", jeton)),
  httr::write_disk(grib_file, overwrite = TRUE),
  httr::timeout(60)
)
print(res$status_code)
