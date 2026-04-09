# ------------------------------------------------------------------------------
# SCRIPT      : import_ondes.R
# ------------------------------------------------------------------------------
# AUTEUR      : MJMartinat
# Structure   : DDT de la Drôme
# DATE        : 01/06/2025
# ------------------------------------------------------------------------------
# DESCRIPTION :
#   ▹ Obtenir pour chaque station ONDE la dernière observation disponible
#     (écoulement visible, faible, assec...)
#   ▹ Lier ces observations aux métadonnées géographiques des stations
#   ▹ Produire une table propre en vue de l’analyse ou de la diffusion
#   ▹ API : https://hubeau.eaufrance.fr/api/v1/ecoulement
# SORTIE : donnees/bulletin/creations/ondes.csv
# ------------------------------------------------------------------------------
# Chargement des bibliothèques nécessaires
# ------------------------------------------------------------------------------
library(httr)
library(jsonlite)
library(dplyr)
library(janitor)
library(readr)
library(purrr)
library(tibble)
library(here)


# ------------------------------------------------------------------------------
# Création du dossier de sortie s’il n’existe pas
# ------------------------------------------------------------------------------
base::dir.create("donnees/bulletin/creations", showWarnings = FALSE)


# ------------------------------------------------------------------------------
# Import_ondes_26
# ------------------------------------------------------------------------------
## Requête API : métadonnées des stations ONDE dans le département 26
res_stations_onde_26 <- httr::GET(
  url = "https://hubeau.eaufrance.fr/api/v1/ecoulement/stations",
  query = list(
    code_departement = "26",
    code_region = "84",
    size = 20000
  )
)
httr::stop_for_status(res_stations_onde_26)

stations_onde_26 <- jsonlite::fromJSON(
  httr::content(res_stations_onde_26, as = "text", encoding = "UTF-8")
)$data %>%
dplyr::as_tibble() %>%
janitor::clean_names() %>%
dplyr::select(
  code_region,
  libelle_region,
  code_departement,
  libelle_departement,
  code_commune,
  libelle_commune,
  code_bassin,
  libelle_bassin,
  code_station,
  libelle_station,
  etat_station,
  code_cours_eau,
  libelle_cours_eau,
  coordonnee_x_station,
  coordonnee_y_station,
  libelle_projection_station,
  longitude,
  latitude
)

# ---- Requête API : observations d’écoulement ONDE en format CSV --------------
res_onde_26 <- httr::GET(
  url = "https://hubeau.eaufrance.fr/api/v1/ecoulement/observations.csv",
  query = list(
    code_departement = "26",
    size = 20000
  )
)
httr::stop_for_status(res_onde_26)

ondes_26 <- readr::read_delim(
  httr::content(res_onde_26, as = "text", encoding = "UTF-8"),
  delim = ";",
  show_col_types = FALSE
) %>%
janitor::clean_names() %>%
dplyr::select(
  code_station,
  date_observation,
  code_ecoulement,
  libelle_ecoulement
)

if (base::nrow(ondes_26) == 0) {
  ondes_26 <- tibble::tibble(
    code_station = base::character(),
    date_observation = base::as.Date(base::character()),
    code_ecoulement = base::character(),
    libelle_ecoulement = base::character()
  )
}

final_onde_26 <- ondes_26 %>%
  dplyr::mutate(date_observation = base::as.Date(date_observation)) %>%
  dplyr::left_join(stations_onde_26, by = "code_station") %>%
  dplyr::filter(!base::is.na(libelle_ecoulement)) %>%
  dplyr::arrange(code_station, dplyr::desc(date_observation)) %>%
  dplyr::group_by(code_station) %>%
  dplyr::slice_head(n = 1) %>%
  dplyr::ungroup() %>%
  dplyr::select(
    code_region,
    libelle_region,
    code_departement,
    libelle_departement,
    code_commune,
    libelle_commune,
    code_bassin,
    libelle_bassin,
    code_cours_eau,
    libelle_cours_eau,
    code_station,
    libelle_station,
    etat_station,
    coordonnee_x_station,
    coordonnee_y_station,
    libelle_projection_station,
    longitude,
    latitude,
    date_observation,
    code_ecoulement,
    libelle_ecoulement
  )

readr::write_csv(
  final_onde_26,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "ondes_26.csv"
  )
)

message("Fichier 'donnees/bulletin/creations/ondes_26.csv' généré avec succès.")

# ------------------------------------------------------------------------------
# Import_ondes_84
# ------------------------------------------------------------------------------
codes_cibles_84 <- c("V5354011", "V5214022", "V5214024", "V5214023", "V5220001")

res_stations_onde_84 <- httr::GET(
  url = "https://hubeau.eaufrance.fr/api/v1/ecoulement/stations",
  query = list(
    code_departement = "84",
    code_region = "93",
    code_station = base::paste(codes_cibles_84, collapse = ","),
    size = 20000
  )
)
httr::stop_for_status(res_stations_onde_84)

stations_onde_84 <- jsonlite::fromJSON(
  httr::content(res_stations_onde_84, as = "text", encoding = "UTF-8")
)$data %>%
dplyr::as_tibble() %>%
janitor::clean_names() %>%
dplyr::select(
  code_region,
  libelle_region,
  code_departement,
  libelle_departement,
  code_commune,
  libelle_commune,
  code_bassin,
  libelle_bassin,
  code_station,
  libelle_station,
  etat_station,
  code_cours_eau,
  libelle_cours_eau,
  coordonnee_x_station,
  coordonnee_y_station,
  libelle_projection_station,
  longitude,
  latitude
)

res_onde_84 <- httr::GET(
  url = "https://hubeau.eaufrance.fr/api/v1/ecoulement/observations.csv",
  query = list(
    code_departement = "84",
    code_station = base::paste(codes_cibles_84, collapse = ","),
    size = 20000
  )
)
httr::stop_for_status(res_onde_84)

ondes_84 <- readr::read_delim(
  httr::content(res_onde_84, as = "text", encoding = "UTF-8"),
  delim = ";",
  show_col_types = FALSE
) %>%
janitor::clean_names() %>%
dplyr::select(
  code_station,
  date_observation,
  code_ecoulement,
  libelle_ecoulement
)

if (base::nrow(ondes_84) == 0) {
  ondes_84 <- tibble::tibble(
    code_station = base::character(),
    date_observation = base::as.Date(base::character()),
    code_ecoulement = base::character(),
    libelle_ecoulement = base::character()
  )
}

final_onde_84 <- ondes_84 %>%
  dplyr::mutate(date_observation = base::as.Date(date_observation)) %>%
  dplyr::left_join(stations_onde_84, by = "code_station") %>%
  dplyr::filter(!base::is.na(libelle_ecoulement)) %>%
  dplyr::arrange(code_station, dplyr::desc(date_observation)) %>%
  dplyr::group_by(code_station) %>%
  dplyr::slice_head(n = 1) %>%
  dplyr::ungroup() %>%
  dplyr::select(
    code_region,
    libelle_region,
    code_departement,
    libelle_departement,
    code_commune,
    libelle_commune,
    code_bassin,
    libelle_bassin,
    code_cours_eau,
    libelle_cours_eau,
    code_station,
    libelle_station,
    etat_station,
    coordonnee_x_station,
    coordonnee_y_station,
    libelle_projection_station,
    longitude,
    latitude,
    date_observation,
    code_ecoulement,
    libelle_ecoulement
  )

readr::write_csv(
  final_onde_84,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "ondes_84.csv"
  )
)

message("Fichier 'donnees/bulletin/creations/ondes_84.csv' généré avec succès.")


# ------------------------------------------------------------------------------
# Import_ondes_05
# ------------------------------------------------------------------------------
codes_cibles_05 <- c("X1050001", "V5304011")

res_stations_onde_05 <- httr::GET(
  url = "https://hubeau.eaufrance.fr/api/v1/ecoulement/stations",
  query = list(
    code_departement = "05",
    code_region = "93",
    code_station = base::paste(codes_cibles_05, collapse = ","),
    size = 20000
  )
)
httr::stop_for_status(res_stations_onde_05)

stations_onde_05 <- jsonlite::fromJSON(
  httr::content(res_stations_onde_05, as = "text", encoding = "UTF-8")
)$data %>%
dplyr::as_tibble() %>%
janitor::clean_names() %>%
dplyr::select(
  code_region,
  libelle_region,
  code_departement,
  libelle_departement,
  code_commune,
  libelle_commune,
  code_bassin,
  libelle_bassin,
  code_station,
  libelle_station,
  etat_station,
  code_cours_eau,
  libelle_cours_eau,
  coordonnee_x_station,
  coordonnee_y_station,
  libelle_projection_station,
  longitude,
  latitude
)

res_onde_05 <- httr::GET(
  url = "https://hubeau.eaufrance.fr/api/v1/ecoulement/observations.csv",
  query = list(
    code_departement = "05",
    code_station = base::paste(codes_cibles_05, collapse = ","),
    size = 20000
  )
)
httr::stop_for_status(res_onde_05)

ondes_05 <- readr::read_delim(
  httr::content(res_onde_05, as = "text", encoding = "UTF-8"),
  delim = ";",
  show_col_types = FALSE
) %>%
janitor::clean_names() %>%
dplyr::select(
  code_station,
  date_observation,
  code_ecoulement,
  libelle_ecoulement
)

if (base::nrow(ondes_05) == 0) {
  ondes_05 <- tibble::tibble(
    code_station = base::character(),
    date_observation = base::as.Date(base::character()),
    code_ecoulement = base::character(),
    libelle_ecoulement = base::character()
  )
}

final_onde_05 <- ondes_05 %>%
  dplyr::mutate(date_observation = base::as.Date(date_observation)) %>%
  dplyr::left_join(stations_onde_05, by = "code_station") %>%
  dplyr::filter(!base::is.na(libelle_ecoulement)) %>%
  dplyr::arrange(code_station, dplyr::desc(date_observation)) %>%
  dplyr::group_by(code_station) %>%
  dplyr::slice_head(n = 1) %>%
  dplyr::ungroup() %>%
  dplyr::select(
    code_region,
    libelle_region,
    code_departement,
    libelle_departement,
    code_commune,
    libelle_commune,
    code_bassin,
    libelle_bassin,
    code_cours_eau,
    libelle_cours_eau,
    code_station,
    libelle_station,
    etat_station,
    coordonnee_x_station,
    coordonnee_y_station,
    libelle_projection_station,
    longitude,
    latitude,
    date_observation,
    code_ecoulement,
    libelle_ecoulement
  )

readr::write_csv(
  final_onde_05,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "ondes_05.csv"
  )
)

message("Fichier 'donnees/bulletin/creations/ondes_05.csv' généré avec succès.")


# ------------------------------------------------------------------------------
# Import_ondes_38
# ------------------------------------------------------------------------------
codes_cibles_38 <- c("V3600002")

res_stations_onde_38 <- httr::GET(
  url = "https://hubeau.eaufrance.fr/api/v1/ecoulement/stations",
  query = list(
    code_departement = "38",
    code_region = "84",
    code_station = base::paste(codes_cibles_38, collapse = ","),
    size = 20000
  )
)
httr::stop_for_status(res_stations_onde_38)

stations_onde_38 <- jsonlite::fromJSON(
  httr::content(res_stations_onde_38, as = "text", encoding = "UTF-8")
)$data %>%
dplyr::as_tibble() %>%
janitor::clean_names() %>%
dplyr::select(
  code_region,
  libelle_region,
  code_departement,
  libelle_departement,
  code_commune,
  libelle_commune,
  code_bassin,
  libelle_bassin,
  code_station,
  libelle_station,
  etat_station,
  code_cours_eau,
  libelle_cours_eau,
  coordonnee_x_station,
  coordonnee_y_station,
  libelle_projection_station,
  longitude,
  latitude
)

res_onde_38 <- httr::GET(
  url = "https://hubeau.eaufrance.fr/api/v1/ecoulement/observations.csv",
  query = list(
    code_departement = "38",
    code_station = base::paste(codes_cibles_38, collapse = ","),
    size = 20000
  )
)
httr::stop_for_status(res_onde_38)

ondes_38 <- readr::read_delim(
  httr::content(res_onde_38, as = "text", encoding = "UTF-8"),
  delim = ";",
  show_col_types = FALSE
) %>%
janitor::clean_names() %>%
dplyr::select(
  code_station,
  date_observation,
  code_ecoulement,
  libelle_ecoulement
)

if (base::nrow(ondes_38) == 0) {
  ondes_38 <- tibble::tibble(
    code_station = base::character(),
    date_observation = base::as.Date(base::character()),
    code_ecoulement = base::character(),
    libelle_ecoulement = base::character()
  )
}

final_onde_38 <- ondes_38 %>%
  dplyr::mutate(date_observation = base::as.Date(date_observation)) %>%
  dplyr::left_join(stations_onde_38, by = "code_station") %>%
  dplyr::filter(!base::is.na(libelle_ecoulement)) %>%
  dplyr::arrange(code_station, dplyr::desc(date_observation)) %>%
  dplyr::group_by(code_station) %>%
  dplyr::slice_head(n = 1) %>%
  dplyr::ungroup() %>%
  dplyr::select(
    code_region,
    libelle_region,
    code_departement,
    libelle_departement,
    code_commune,
    libelle_commune,
    code_bassin,
    libelle_bassin,
    code_cours_eau,
    libelle_cours_eau,
    code_station,
    libelle_station,
    etat_station,
    coordonnee_x_station,
    coordonnee_y_station,
    libelle_projection_station,
    longitude,
    latitude,
    date_observation,
    code_ecoulement,
    libelle_ecoulement
  )

readr::write_csv(
  final_onde_38,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "ondes_38.csv"
  )
)

message("Fichier 'donnees/bulletin/creations/ondes_38.csv' généré avec succès.")


# ------------------------------------------------------------------------------
# Import_ondes
# ------------------------------------------------------------------------------
# ---- Fonction de coercition sûre ---------------------------------------------
coerce_col_to_char <- function(df, colname) {
  if (colname %in% names(df)) {
    df[[colname]] <- as.character(df[[colname]])
  }
  return(df)
}

# ---- Chargement des fichiers -------------------------------------------------
ondes_26 <- readr::read_csv(
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "ondes_26.csv"
  ),
  show_col_types = FALSE
) %>%
coerce_col_to_char("code_departement") %>%
coerce_col_to_char("code_commune") %>%
coerce_col_to_char("code_ecoulement")

ondes_38 <- readr::read_csv(
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "ondes_38.csv"
  ),
  show_col_types = FALSE
) %>%
coerce_col_to_char("code_departement") %>%
coerce_col_to_char("code_commune") %>%
coerce_col_to_char("code_ecoulement")

ondes_84 <- readr::read_csv(
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "ondes_84.csv"
  ),
  show_col_types = FALSE
) %>%
coerce_col_to_char("code_departement") %>%
coerce_col_to_char("code_commune") %>%
coerce_col_to_char("code_ecoulement")

ondes_05 <- readr::read_csv(
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "ondes_05.csv"
  ),
  show_col_types = FALSE
) %>%
coerce_col_to_char("code_departement") %>%
coerce_col_to_char("code_commune") %>%
coerce_col_to_char("code_ecoulement")

# ---- Vérification structure --------------------------------------------------
stopifnot(identical(names(ondes_26), names(ondes_38)))
stopifnot(identical(names(ondes_26), names(ondes_84)))
stopifnot(identical(names(ondes_26), names(ondes_05)))

# ---- Fusion ------------------------------------------------------------------
ondes_total <- dplyr::bind_rows(ondes_26, ondes_38, ondes_84, ondes_05)

# ---- Export ------------------------------------------------------------------
readr::write_csv(
  ondes_total,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "ondes.csv"
  )
)

message("Fichier fusionné : donnees/bulletin/creations/ondes.csv")
