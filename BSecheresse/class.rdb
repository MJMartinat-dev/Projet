# ------------------------------------------------------------------------------
# SCRIPT      : import_debits.R
# ------------------------------------------------------------------------------
# AUTEUR      : MJMartinat
# Structure   : DDT de la Drôme
# DATE        : 01/06/2025
# ------------------------------------------------------------------------------
# DESCRIPTION : Récupération automatisée des débits moyens journaliers (QmnJ)
#               via l'API Hub'eau (endpoint obs_elab) pour le département de
#               la Drôme (26), l'Isère (38) et stations complémentaires.
#               Fusion des métadonnées stations/sites + conversion L/s → m³/s.
# SORTIE      : donnees/creations/debits.csv (tableau des débits en m³/s)
# API         : https://hubeau.eaufrance.fr/api/v2/hydrometrie/obs_elab
# GRANDEUR    : QmnJ = Débit moyen journalier (observations élaborées)
# ------------------------------------------------------------------------------
# Chargement des bibliothèques
# ------------------------------------------------------------------------------
library(httr)                                                                   # Requêtes HTTP vers l'API Hub'eau
library(jsonlite)                                                               # Parsing des réponses JSON
library(dplyr)                                                                  # Manipulation des données
library(purrr)                                                                  # Programmation fonctionnelle (map)
library(readr)                                                                  # Lecture/écriture CSV
library(janitor)                                                                # Nettoyage des noms de colonnes
library(glue)                                                                   # Interpolation de chaînes
library(stringr)                                                                # Manipulation de chaînes
library(here)                                                                   # Gestion des chemins relatifs
library(tibble)                                                                 # Tibbles pour data.frames modernes


# ------------------------------------------------------------------------------
# Création du dossier de sortie
# ------------------------------------------------------------------------------
dir.create("donnees/bulletin/creations", showWarnings = FALSE)                  # Création du dossier si inexistant


# ------------------------------------------------------------------------------
# Import_debits_26 (Département de la Drôme)
# ------------------------------------------------------------------------------
# ---- Récupération des sites hydrométriques (référentiel) ---------------------
res_sites_debit_26 <- httr::GET(                                                # Requête GET vers l'API Hub'eau
  url = "https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/sites",     # Endpoint référentiel sites
  query = list(code_departement = "26", size = 10000)                           # Filtre département Drôme
)
httr::stop_for_status(res_sites_debit_26)                                       # Arrêt si erreur HTTP

sites_debit_26 <- jsonlite::fromJSON(                                           # Parsing JSON vers data.frame
  httr::content(res_sites_debit_26, as = "text", encoding = "UTF-8")            # Extraction contenu texte UTF-8
)$data %>%
  tibble::as_tibble() %>%                                                       # Conversion en tibble
  janitor::clean_names() %>%                                                    # Nettoyage des noms de colonnes
  dplyr::select(                                                                # Sélection des colonnes utiles
    code_commune_site, libelle_commune,                                         # Commune du site
    code_site, libelle_site,                                                    # Identifiants site
    longitude_site, latitude_site,                                              # Coordonnées WGS84
    coordonnee_x_site, coordonnee_y_site,                                       # Coordonnées Lambert
    code_zone_hydro_site                                                        # Zone hydrographique
  ) %>%
  dplyr::rename(                                                                # Renommage pour harmonisation
    libelle_bassin_versant = code_zone_hydro_site,                              # Code zone hydro → bassin versant
    code_commune = code_commune_site,                                           # Harmonisation nom commune
    coordonnee_x = coordonnee_x_site,                                           # Harmonisation coordonnée X
    coordonnee_y = coordonnee_y_site,                                           # Harmonisation coordonnée Y
    longitude = longitude_site,                                                 # Harmonisation longitude
    latitude = latitude_site                                                    # Harmonisation latitude
  ) %>%
  dplyr::mutate(                                                                # Conversion en caractères
    dplyr::across(-code_site, as.character)                                     # Toutes colonnes sauf code_site
  ) %>%
  dplyr::rename_with(                                                           # Ajout suffixe _sites
    ~ paste0(., "_sites"), -code_site                                           # Pour éviter conflits jointure
  ) %>%
  dplyr::filter(                                                                # Exclusion stations problématiques
    !code_site %in% c("V5220003", "V5220002", "V5214026")                       # Stations à exclure
  )

# ---- Récupération des stations hydrométriques (référentiel) ------------------
res_stations_debit_26 <- httr::GET(                                             # Requête GET vers l'API Hub'eau
  url = "https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/stations",  # Endpoint référentiel stations
  query = list(code_departement = "26", size = 10000)                           # Filtre département Drôme
)
httr::stop_for_status(res_stations_debit_26)                                    # Arrêt si erreur HTTP

stations_debit_26 <- jsonlite::fromJSON(                                        # Parsing JSON vers data.frame
  httr::content(res_stations_debit_26, as = "text", encoding = "UTF-8")         # Extraction contenu texte UTF-8
)$data %>%
  tibble::as_tibble() %>%                                                       # Conversion en tibble
  janitor::clean_names()                                                        # Nettoyage des noms de colonnes

if (!any(c("code_commune_station", "code_commune") %in%                         # Vérification présence colonne commune
               colnames(stations_debit_26))) {
  stations_debit_26$code_commune <- NA_character_                               # Ajout colonne si absente
}

stations_debit_26 <- stations_debit_26 %>%
  dplyr::select(                                                                # Sélection des colonnes utiles
    code_region, libelle_region,                                                # Région
    code_departement, libelle_departement,                                      # Département
    dplyr::any_of(c("code_commune_station", "code_commune")),                   # Commune (nom variable)
    libelle_commune,                                                            # Libellé commune
    code_cours_eau, libelle_cours_eau,                                          # Cours d'eau
    code_site, libelle_site,                                                    # Site parent
    code_station, libelle_station,                                              # Station
    coordonnee_x_station, coordonnee_y_station,                                 # Coordonnées Lambert
    longitude_station, latitude_station                                         # Coordonnées WGS84
  ) %>%
  dplyr::rename(                                                                # Renommage pour harmonisation
    code_commune = dplyr::any_of(c("code_commune_station", "code_commune")),    # Harmonisation commune
    coordonnee_x = coordonnee_x_station,                                        # Harmonisation coordonnée X
    coordonnee_y = coordonnee_y_station,                                        # Harmonisation coordonnée Y
    longitude = longitude_station,                                              # Harmonisation longitude
    latitude = latitude_station                                                 # Harmonisation latitude
  ) %>%
  dplyr::filter(                                                                # Exclusion stations problématiques
    !code_station %in% c("V522000301", "V522000201", "V521402601")              # Stations à exclure
  )

# ---- Fonction pour récupérer les débits moyens journaliers (QmnJ) ------------
get_obs_debit_26 <- function(code_station_input) {

  date_fin_obs <- format(Sys.Date(), "%Y-%m-%d")                                # Date fin = aujourd'hui
  date_debut_obs <- format(Sys.Date() - 7, "%Y-%m-%d")                          # Date début = J-7 (7 derniers jours)

  res_26 <- httr::GET(                                                          # Requête GET vers l'API Hub'eau
    url = "https://hubeau.eaufrance.fr/api/v2/hydrometrie/obs_elab",            # Endpoint observations élaborées
    query = list(
      code_entite = code_station_input,                                         # Code station ou site
      grandeur_hydro_elab = "QmnJ",                                             # QmnJ = Débit moyen journalier
      size = 20000,                                                             # Taille max page
      sort = "desc",                                                            # Tri descendant (plus récent d'abord)
      date_debut_obs_elab = date_debut_obs,                                     # Filtre date début
      date_fin_obs_elab = date_fin_obs                                          # Filtre date fin
    )
  )

  if (httr::http_error(res_26)) {                                               # Gestion erreur HTTP
    return(NULL)                                                                # Retourne NULL si erreur
  }

  data_26 <- httr::content(res_26, as = "parsed", simplifyVector = TRUE)$data   # Extraction données JSON

  if (is.null(data_26) || length(data_26) == 0) {                               # Vérification données non vides
    return(NULL)                                                                # Retourne NULL si vide
  }

  if (is.data.frame(data_26)) {                                                 # Si réponse est un data.frame
    cols_needed <- c("code_station", "date_obs_elab", "resultat_obs_elab")      # Colonnes requises
    if (!all(cols_needed %in% colnames(data_26))) {                             # Vérification colonnes présentes
      return(NULL)                                                              # Retourne NULL si colonnes manquantes
    }

    return(data_26 %>%
                   tibble::as_tibble() %>%                                      # Conversion en tibble
                   dplyr::mutate(code_site = code_station_input) %>%            # Ajout code_site pour référence
                   dplyr::select(code_site,
                                 code_station,                                  # Sélection colonnes utiles
                                 date_obs_elab,
                                 resultat_obs_elab)
           )                                                                    # Date et résultat observation
  }

  tibble::tibble(                                                               # Construction tibble si liste
    code_site = rep(code_station_input, length(data_26)),                       # Répétition code_site
    code_station = purrr::map_chr(data_26,                                      # Extraction code_station
                                  ~ .x[["code_station"]] %||% NA_character_),
    date_obs_elab = purrr::map_chr(data_26,                                     # Extraction date observation
                                   ~ .x[["date_obs_elab"]] %||% NA_character_),
    resultat_obs_elab = purrr::map_dbl(data_26,                                 # Extraction résultat (L/s)
                                       ~ as.numeric(.x[["resultat_obs_elab"]] %||% NA_real_))
  )
}

# ---- Récupération des données de débit pour toutes les stations --------------
debits_26 <- stations_debit_26$code_station %>%                                 # Liste codes stations
  unique() %>%                                                                  # Dédoublonnage
  purrr::map_dfr(get_obs_debit_26)                                              # Appel fonction pour chaque station

if (nrow(debits_26) == 0) {                                                     # Si aucune donnée récupérée
  debits_26 <- tibble::tibble(                                                  # Création tibble vide structuré
    code_site = character(),                                                    # Code site vide
    code_station = character(),                                                 # Code station vide
    date_obs_elab = as.Date(character()),                                       # Date vide
    resultat_obs_elab = numeric()                                               # Résultat vide
  )
}

# ---- Fusion et enrichissement des données ------------------------------------
debits_26 <- debits_26 %>%
  dplyr::rename(code_site_orig = code_site)                                     # Renommage pour éviter conflit

stations_debit_26 <- stations_debit_26 %>%
  dplyr::rename(code_site_station = code_site)                                  # Renommage pour éviter conflit

final_debit_26 <- debits_26 %>%
  dplyr::mutate(
    date_obs = as.Date(date_obs_elab),                                          # Conversion date
    code_site = code_site_orig,                                                 # Restauration code_site
    jointure_station = dplyr::coalesce(code_station, code_site_orig)            # Clé jointure avec fallback
  ) %>%
  dplyr::left_join(stations_debit_26,                                           # Jointure métadonnées stations
                   by = c("jointure_station" = "code_station")) %>%
  dplyr::left_join(sites_debit_26, by = "code_site") %>%                        # Jointure métadonnées sites
  dplyr::mutate(
    code_commune = dplyr::coalesce(as.character(code_commune),                  # Fusion commune (station prioritaire)
                                   code_commune_sites),
    libelle_commune = dplyr::coalesce(as.character(libelle_commune),            # Fusion libellé commune
                                      libelle_commune_sites),
    libelle_site = dplyr::coalesce(as.character(libelle_site),                  # Fusion libellé site
                                   libelle_site_sites),
    coordonnee_x = dplyr::coalesce(as.character(coordonnee_x),                  # Fusion coordonnée X
                                   coordonnee_x_sites),
    coordonnee_y = dplyr::coalesce(as.character(coordonnee_y),                  # Fusion coordonnée Y
                                   coordonnee_y_sites),
    longitude = dplyr::coalesce(as.character(longitude),                        # Fusion longitude
                                longitude_sites),
    latitude = dplyr::coalesce(as.character(latitude),                          # Fusion latitude
                               latitude_sites),
    libelle_bassin_versant = libelle_bassin_versant_sites,                      # Bassin versant depuis sites
    debit_m3s = resultat_obs_elab / 1000                                        # Conversion L/s → m³/s
  ) %>%
  dplyr::filter(!is.na(debit_m3s), !is.na(code_station))                        # Filtrage valeurs manquantes

# ---- Vérification des colonnes attendues -------------------------------------
expected_cols_26 <- c(                                                          # Liste colonnes attendues
  "code_region", "libelle_region",                                              # Région
  "libelle_bassin_versant",                                                     # Bassin versant
  "code_departement", "libelle_departement",                                    # Département
  "code_commune", "libelle_commune",                                            # Commune
  "code_cours_eau", "libelle_cours_eau",                                        # Cours d'eau
  "code_site", "libelle_site",                                                  # Site
  "code_station", "libelle_station",                                            # Station
  "coordonnee_x", "coordonnee_y",                                               # Coordonnées Lambert
  "longitude", "latitude",                                                      # Coordonnées WGS84
  "date_obs", "debit_m3s"                                                       # Date et débit
)

missing_cols_26 <- setdiff(expected_cols_26,                                    # Colonnes manquantes
                                 colnames(final_debit_26)
                           )
if (length(missing_cols_26) > 0) {                                              # Si colonnes manquantes
  stop("Colonnes manquantes après jointure : ",                                 # Erreur avec liste colonnes
             paste(missing_cols_26, collapse = ","))
}

# ---- Sélection et tri final --------------------------------------------------
final_debit_26 <- final_debit_26 %>%
  dplyr::select(dplyr::all_of(expected_cols_26)) %>%                            # Sélection colonnes attendues
  dplyr::arrange(code_station, dplyr::desc(date_obs))                           # Tri par station puis date desc

# ---- Conservation des 3 dernières valeurs par station (3 jours de QmnJ) ------

final_debit_26 <- final_debit_26 %>%
  dplyr::group_by(code_station) %>%                                             # Groupement par station
  dplyr::slice_head(n = 3) %>%                                                  # 3 dernières valeurs QmnJ
  dplyr::ungroup()                                                              # Dégroupement

readr::write_csv(final_debit_26,                                                # Export CSV complet
                 here::here(
                   "donnees",
                   "bulletin",
                   "creations",
                   "debits_26_complet.csv"
                  )
                )

# ---- Calcul moyenne + dernière date ------------------------------------------
cols_meta <- c(
  "code_region",
  "libelle_region",
  "libelle_bassin_versant",
  "code_departement",
  "libelle_departement",
  "code_commune",
  "libelle_commune",
  "code_cours_eau",
  "libelle_cours_eau",
  "code_site",
  "libelle_site",
  "libelle_station",
  "coordonnee_x",
  "coordonnee_y",
  "longitude",
  "latitude"
)

final_debits_26 <- final_debit_26 %>%
  dplyr::group_by(code_station) %>%
  dplyr::summarise(
    dplyr::across(
      dplyr::any_of(cols_meta),
      ~ dplyr::first(.x)
    ),
    debit_m3s = round(mean(debit_m3s, na.rm = TRUE), 2),
    date_obs  = format(max(date_obs, na.rm = TRUE), "%m-%d"),
    .groups = "drop"
  )


# ---- Export final département 26 --------------------------------------------
readr::write_csv(final_debits_26,                                               # Export CSV agrégé
                 here::here(
                   "donnees",
                   "bulletin",
                   "creations",
                   "debits_26.csv"
                  )
                )

message("Fichiers générés : debits_26_complet.csv (3 QmnJ) + debits_26.csv (moyenne)")


# ------------------------------------------------------------------------------
# Import_debits_38 (Département de l'Isère - Station spécifique)
# ------------------------------------------------------------------------------
# ---- Code site ciblé (Isère) -------------------------------------------------
code_site_cible_38 <- "W3315010"                                                # Code site Isère ciblé

# ---- Récupération des sites hydrométriques (référentiel) ---------------------
res_sites_debit_38 <- httr::GET(                                                # Requête GET vers l'API Hub'eau
  url = "https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/sites",     # Endpoint référentiel sites
  query = list(code_departement = "38",                                         # Filtre département Isère
               code_site = code_site_cible_38,                                  # Filtre site spécifique
               size = 10000
              )
)
httr::stop_for_status(res_sites_debit_38)                                       # Arrêt si erreur HTTP

sites_debit_38 <- jsonlite::fromJSON(                                           # Parsing JSON vers data.frame
  httr::content(res_sites_debit_38, as = "text", encoding = "UTF-8")
)$data %>%
tibble::as_tibble() %>%                                                         # Conversion en tibble
janitor::clean_names() %>%                                                      # Nettoyage des noms de colonnes
dplyr::select(                                                                  # Sélection des colonnes utiles
  code_commune_site,
  libelle_commune,
  code_site,
  libelle_site,
  longitude_site,
  latitude_site,
  coordonnee_x_site,
  coordonnee_y_site,
  code_zone_hydro_site
) %>%
dplyr::rename(                                                                  # Renommage pour harmonisation
  libelle_bassin_versant = code_zone_hydro_site,
  code_commune = code_commune_site,
  coordonnee_x = coordonnee_x_site,
  coordonnee_y = coordonnee_y_site,
  longitude = longitude_site,
  latitude = latitude_site
) %>%
dplyr::mutate(
  dplyr::across(-code_site, as.character)
) %>%                                                                           # Conversion en caractères
dplyr::rename_with(~ paste0(., "_sites"), -code_site)                           # Ajout suffixe _sites

# ---- Code station ciblé (Isère) ----------------------------------------------
code_station_cible_38 <- "W331501001"                                           # Code station Isère ciblée

# ---- Récupération des stations hydrométriques (référentiel) ------------------
res_stations_debit_38 <- httr::GET(                                             # Requête GET vers l'API Hub'eau
  url = "https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/stations",  # Endpoint référentiel stations
  query = list(code_departement = "38",                                         # Filtre département Isère
               code_station = code_station_cible_38,                            # Filtre station spécifique
               size = 10000
              )
)
httr::stop_for_status(res_stations_debit_38)                                    # Arrêt si erreur HTTP

stations_debit_38 <- jsonlite::fromJSON(                                        # Parsing JSON vers data.frame
  httr::content(res_stations_debit_38, as = "text", encoding = "UTF-8")
)$data %>%
tibble::as_tibble() %>%                                                         # Conversion en tibble
janitor::clean_names()                                                          # Nettoyage des noms de colonnes

if (!any(c("code_commune_station", "code_commune") %in%                         # Vérification présence colonne commune
               colnames(stations_debit_38))) {
  stations_debit_38$code_commune <- NA_character_                               # Ajout colonne si absente
}

stations_debit_38 <- stations_debit_38 %>%
  dplyr::select(                                                                # Sélection des colonnes utiles
    code_region,
    libelle_region,
    code_departement,
    libelle_departement,
    dplyr::any_of(c("code_commune_station", "code_commune")),
    libelle_commune,
    code_cours_eau,
    libelle_cours_eau,
    code_site,
    libelle_site,
    code_station,
    libelle_station,
    coordonnee_x_station,
    coordonnee_y_station,
    longitude_station,
    latitude_station
  ) %>%
  dplyr::rename(                                                                # Renommage pour harmonisation
    code_commune = dplyr::any_of(c("code_commune_station", "code_commune")),
    coordonnee_x = coordonnee_x_station,
    coordonnee_y = coordonnee_y_station,
    longitude = longitude_station,
    latitude = latitude_station
  )

# ---- Fonction pour récupérer les débits moyens journaliers (QmnJ) - Isère ----
get_obs_debit_38 <- function(code_station_input) {

  date_fin_obs <- format(Sys.Date(), "%Y-%m-%d")                                # Date fin = aujourd'hui
  date_debut_obs <- format(Sys.Date() - 7, "%Y-%m-%d")                          # Date début = J-7

  res_38 <- httr::GET(                                                          # Requête GET vers l'API Hub'eau
    url = "https://hubeau.eaufrance.fr/api/v2/hydrometrie/obs_elab",            # Endpoint observations élaborées
    query = list(
      code_entite = code_station_input,                                         # Code station ou site
      grandeur_hydro_elab = "QmnJ",                                             # QmnJ = Débit moyen journalier
      size = 20000,
      sort = "desc",
      date_debut_obs_elab = date_debut_obs,
      date_fin_obs_elab = date_fin_obs
    )
  )

  if (httr::http_error(res_38)) {                                               # Gestion erreur HTTP
    return(NULL)
  }

  data_38 <- httr::content(res_38, as = "parsed", simplifyVector = TRUE)$data

  if (is.null(data_38) || length(data_38) == 0) {
    return(NULL)
  }

  if (is.data.frame(data_38)) {
    cols_needed <- c("code_station", "date_obs_elab", "resultat_obs_elab")
    if (!all(cols_needed %in% colnames(data_38))) {
      return(NULL)
    }

    return(data_38 %>%
                   tibble::as_tibble() %>%
                   dplyr::mutate(code_site = code_station_input) %>%
                   dplyr::select(code_site, code_station,
                                 date_obs_elab, resultat_obs_elab))
  }

  tibble::tibble(
    code_site = rep(code_station_input, length(data_38)),
    code_station = purrr::map_chr(data_38, ~ .x[["code_station"]] %||% NA_character_),
    date_obs_elab = purrr::map_chr(data_38, ~ .x[["date_obs_elab"]] %||% NA_character_),
    resultat_obs_elab = purrr::map_dbl(data_38, ~ as.numeric(.x[["resultat_obs_elab"]] %||% NA_real_))
  )
}

# ---- Récupération des données de débit ---------------------------------------
debits_38 <- stations_debit_38$code_station %>%                                 # Liste codes stations
  unique() %>%
  purrr::map_dfr(get_obs_debit_38)

if (nrow(debits_38) == 0) {                                                     # Si aucune donnée récupérée
  debits_38 <- tibble::tibble(
    code_site = character(),
    code_station = character(),
    date_obs_elab = as.Date(character()),
    resultat_obs_elab = numeric()
  )
}

# ---- Fusion et enrichissement ------------------------------------------------
debits_38 <- debits_38 %>%
  dplyr::rename(code_site_orig = code_site)

stations_debit_38 <- stations_debit_38 %>%
  dplyr::rename(code_site_station = code_site)

final_debit_38 <- debits_38 %>%
  dplyr::mutate(
    date_obs = as.Date(date_obs_elab),                                          # Conversion date (QmnJ = date simple)
    code_site = code_site_orig,
    jointure_station = dplyr::coalesce(code_station, code_site_orig)
  ) %>%
  dplyr::left_join(stations_debit_38, by = c("jointure_station" = "code_station")) %>%
  dplyr::left_join(sites_debit_38, by = "code_site") %>%
  dplyr::mutate(
    code_commune = dplyr::coalesce(as.character(code_commune), code_commune_sites),
    libelle_commune = dplyr::coalesce(as.character(libelle_commune), libelle_commune_sites),
    libelle_site = dplyr::coalesce(as.character(libelle_site), libelle_site_sites),
    coordonnee_x = dplyr::coalesce(as.character(coordonnee_x), coordonnee_x_sites),
    coordonnee_y = dplyr::coalesce(as.character(coordonnee_y), coordonnee_y_sites),
    longitude = dplyr::coalesce(as.character(longitude), longitude_sites),
    latitude = dplyr::coalesce(as.character(latitude), latitude_sites),
    libelle_bassin_versant = libelle_bassin_versant_sites,
    debit_m3s = resultat_obs_elab / 1000                                        # Conversion L/s → m³/s
  ) %>%
  dplyr::filter(!is.na(debit_m3s), !is.na(code_station))

# ---- Vérification des colonnes attendues -------------------------------------
expected_cols_38 <- c(
  "code_region",
  "libelle_region",
  "libelle_bassin_versant",
  "code_departement",
  "libelle_departement",
  "code_commune",
  "libelle_commune",
  "code_cours_eau",
  "libelle_cours_eau",
  "code_site",
  "libelle_site",
  "code_station",
  "libelle_station",
  "coordonnee_x",
  "coordonnee_y",
  "longitude",
  "latitude",
  "date_obs",
  "debit_m3s"
)

missing_cols_38 <- setdiff(
  expected_cols_38,
  colnames(final_debit_38)
)
if (length(missing_cols_38) > 0) {
  stop("Colonnes manquantes après jointure : ", paste(missing_cols_38, collapse = ","))
}

# ---- Sélection et tri final --------------------------------------------------
final_debit_38 <- final_debit_38 %>%
  dplyr::select(dplyr::all_of(expected_cols_38)) %>%
  dplyr::arrange(code_station, dplyr::desc(date_obs))

# ---- Conservation des 3 dernières valeurs par station (3 jours de QmnJ) ------
final_debit_38 <- final_debit_38 %>%
  dplyr::group_by(code_station) %>%
  dplyr::slice_head(n = 3) %>%                                                  # 3 dernières valeurs QmnJ
  dplyr::ungroup()

readr::write_csv(
  final_debit_38,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "debits_38_complet.csv"
  )
)

# ---- Moyenne + dernière date -------------------------------------------------
cols_meta <- c(
  "code_region",
  "libelle_region",
  "libelle_bassin_versant",
  "code_departement",
  "libelle_departement",
  "code_commune",
  "libelle_commune",
  "code_cours_eau",
  "libelle_cours_eau",
  "code_site",
  "libelle_site",
  "libelle_station",
  "coordonnee_x",
  "coordonnee_y",
  "longitude",
  "latitude"
)

final_debits_38 <- final_debit_38 %>%
  dplyr::group_by(code_station) %>%
  dplyr::summarise(
    dplyr::across(dplyr::any_of(cols_meta), ~ dplyr::first(.x)),
    debit_m3s = round(mean(debit_m3s, na.rm = TRUE), 2),
    date_obs  = format(max(date_obs, na.rm = TRUE), "%m-%d"),
    .groups = "drop"
  )


# ---- Export final département 38 ---------------------------------------------
readr::write_csv(
  final_debits_38,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "debits_38.csv"
  )
)

message("Fichiers générés : debits_38_complet.csv (3 QmnJ) + debits_38.csv (moyenne)")


# ------------------------------------------------------------------------------
# Import_debits_84 (Département du Vaucluse - COMMENTÉ)
# ------------------------------------------------------------------------------
# # Code site ciblé
# code_cible_84 <- "V523401001"
#
# # Requête API pour récupérer les sites hydrométriques
# res_sites_debit_84 <- httr::GET(
#   url = "https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/sites",
#   query = list(code_departement = "84", code_entite = code_cible_84, size = 10000)
# )
# httr::stop_for_status(res_sites_debit_84)
#
# sites_debit_84 <- jsonlite::fromJSON(httr::content(res_sites_debit_84, as = "text", encoding = "UTF-8"))$data %>%
#   tibble::as_tibble() %>%
#   janitor::clean_names() %>%
#   dplyr::select(
#     code_commune_site, libelle_commune,
#     code_site, libelle_site,
#     longitude_site, latitude_site,
#     coordonnee_x_site, coordonnee_y_site,
#     code_zone_hydro_site
#   ) %>%
#   dplyr::rename(
#     libelle_bassin_versant = code_zone_hydro_site,
#     code_commune = code_commune_site,
#     coordonnee_x = coordonnee_x_site,
#     coordonnee_y = coordonnee_y_site,
#     longitude = longitude_site,
#     latitude = latitude_site
#   ) %>%
#   dplyr::mutate(dplyr::across(-code_site, as.character)) %>%
#   dplyr::rename_with(~ paste0(., "_sites"), -code_site)
#
# # Requête API pour les stations hydrométriques
# res_stations_debit_84 <- httr::GET(
#   url = "https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/stations",
#   query = list(code_departement = "84", size = 10000)
# )
# httr::stop_for_status(res_stations_debit_84)
#
# stations_debit_84 <- jsonlite::fromJSON(httr::content(res_stations_debit_84, as = "text", encoding = "UTF-8"))$data %>%
#   tibble::as_tibble() %>%
#   janitor::clean_names()
#
# if (!any(c("code_commune_station", "code_commune") %in% colnames(stations_debit_84))) {
#   stations_debit_84$code_commune <- NA_character_
# }
#
# stations_debit_84 <- stations_debit_84 %>%
#   dplyr::select(
#     code_region, libelle_region,
#     code_departement, libelle_departement,
#     dplyr::any_of(c("code_commune_station", "code_commune")),
#     libelle_commune,
#     code_cours_eau, libelle_cours_eau,
#     code_site, libelle_site,
#     code_station, libelle_station,
#     coordonnee_x_station, coordonnee_y_station,
#     longitude_station, latitude_station
#   ) %>%
#   dplyr::rename(
#     code_commune = dplyr::any_of(c("code_commune_station", "code_commune")),
#     coordonnee_x = coordonnee_x_station,
#     coordonnee_y = coordonnee_y_station,
#     longitude = longitude_station,
#     latitude = latitude_station
#   )
#
# # Fonction pour récupérer les débits moyens journaliers QmnJ
# get_obs_debit_84 <- function(code_station_input) {
#
#   date_fin_obs <- format(Sys.Date(), "%Y-%m-%d")
#   date_debut_obs <- format(Sys.Date() - 7, "%Y-%m-%d")
#
#   res_84 <- httr::GET(
#     url = "https://hubeau.eaufrance.fr/api/v2/hydrometrie/obs_elab",
#     query = list(
#       code_entite = code_station_input,
#       grandeur_hydro_elab = "QmnJ",
#       size = 20000,
#       sort = "desc",
#       date_debut_obs_elab = date_debut_obs,
#       date_fin_obs_elab = date_fin_obs
#     )
#   )
#   if (httr::http_error(res_84)) return(NULL)
#
#   data_84 <- httr::content(res_84, as = "parsed", simplifyVector = TRUE)$data
#   if (is.null(data_84) || length(data_84) == 0) return(NULL)
#
#   if (is.data.frame(data_84)) {
#     cols_needed <- c("code_station", "date_obs_elab", "resultat_obs_elab")
#     if (!all(cols_needed %in% colnames(data_84))) return(NULL)
#
#     return(data_84 %>%
#                    tibble::as_tibble() %>%
#                    dplyr::mutate(code_site = code_station_input) %>%
#                    dplyr::select(code_site, code_station, date_obs_elab, resultat_obs_elab))
#   }
#
#   tibble::tibble(
#     code_site = rep(code_station_input, length(data_84)),
#     code_station = purrr::map_chr(data_84, ~ .x[["code_station"]] %||% NA_character_),
#     date_obs_elab = purrr::map_chr(data_84, ~ .x[["date_obs_elab"]] %||% NA_character_),
#     resultat_obs_elab = purrr::map_dbl(data_84, ~ as.numeric(.x[["resultat_obs_elab"]] %||% NA_real_))
#   )
# }
#
# # Récupération des données de débit
# debits_84 <- tibble::tibble()
#
# if (!is.null(code_cible_84)) {
#   debits_84 <- get_obs_debit_84(code_cible_84)
# }
#
# if (nrow(debits_84) == 0) {
#   debits_84 <- tibble::tibble(
#     code_site = character(),
#     code_station = character(),
#     date_obs_elab = as.Date(character()),
#     resultat_obs_elab = numeric()
#   )
# }
#
# # Fusion et enrichissement
# debits_84 <- debits_84 %>%
#   dplyr::rename(code_site_orig = code_site)
#
# stations_debit_84 <- stations_debit_84 %>%
#   dplyr::rename(code_site_station = code_site)
#
# final_debit_84 <- debits_84 %>%
#   dplyr::mutate(
#     date_obs = as.Date(date_obs_elab),
#     code_site = code_site_orig,
#     jointure_station = dplyr::coalesce(code_station, code_site_orig)
#   ) %>%
#   dplyr::left_join(stations_debit_84, by = c("jointure_station" = "code_station")) %>%
#   dplyr::left_join(sites_debit_84, by = "code_site") %>%
#   dplyr::mutate(
#     code_commune = dplyr::coalesce(as.character(code_commune), code_commune_sites),
#     libelle_commune = dplyr::coalesce(as.character(libelle_commune), libelle_commune_sites),
#     libelle_site = dplyr::coalesce(as.character(libelle_site), libelle_site_sites),
#     coordonnee_x = dplyr::coalesce(as.character(coordonnee_x), coordonnee_x_sites),
#     coordonnee_y = dplyr::coalesce(as.character(coordonnee_y), coordonnee_y_sites),
#     longitude = dplyr::coalesce(as.character(longitude), longitude_sites),
#     latitude = dplyr::coalesce(as.character(latitude), latitude_sites),
#     libelle_bassin_versant = libelle_bassin_versant_sites,
#     debit_m3s = resultat_obs_elab / 1000
#   ) %>%
#   dplyr::filter(!is.na(debit_m3s), !is.na(code_station))
#
# # Vérification des colonnes attendues
# expected_cols_84 <- c(
#   "code_region", "libelle_region",
#   "libelle_bassin_versant",
#   "code_departement", "libelle_departement",
#   "code_commune", "libelle_commune",
#   "code_cours_eau", "libelle_cours_eau",
#   "code_site", "libelle_site",
#   "code_station", "libelle_station",
#   "coordonnee_x", "coordonnee_y",
#   "longitude", "latitude",
#   "date_obs", "debit_m3s"
# )
#
# missing_cols_84 <- setdiff(expected_cols_84, colnames(final_debit_84))
# if (length(missing_cols_84) > 0) {
#   stop("Colonnes manquantes après jointure : ", paste(missing_cols_84, collapse = ", "))
# }
#
# # Sélection et tri final
# final_debit_84 <- final_debit_84 %>%
#   dplyr::select(dplyr::all_of(expected_cols_84)) %>%
#   dplyr::arrange(code_station, dplyr::desc(date_obs))
#
# # Dernières valeurs par station (3 QmnJ)
# final_debit_84 <- final_debit_84 %>%
#   dplyr::group_by(code_station) %>%
#   dplyr::slice_head(n = 3) %>%
#   dplyr::ungroup()
#
# readr::write_csv(final_debit_84, here::here("data", "debits_84_complet.csv"))
#
# # Moyenne + dernière date
# final_debits_84 <- final_debit_84 %>%
#   dplyr::group_by(code_station) %>%
#   dplyr::summarise(
#     dplyr::across(
#       c(code_region, libelle_region, libelle_bassin_versant, code_departement,
#               libelle_departement, code_commune, libelle_commune, code_cours_eau,
#               libelle_cours_eau, code_site, libelle_site, libelle_station,
#               coordonnee_x, coordonnee_y, longitude, latitude),
#       ~ dplyr::first(.)
#     ),
#     debit_m3s = round(mean(debit_m3s, na.rm = TRUE), 2),
#     date_obs = format(max(date_obs, na.rm = TRUE), "%m-%d"),
#     .groups = "drop"
#   )
#
# # Export final
# readr::write_csv(final_debits_84, here::here("donnees", "bulletin", "creations", "debits_84.csv"))
# message("Fichiers générés : debits_84_complet.csv (3 QmnJ) + debits_84.csv (moyenne)")


# ------------------------------------------------------------------------------
# Import_debits - Fusion finale de tous les départements
# ------------------------------------------------------------------------------
# ---- Chargement des fichiers -------------------------------------------------
debits_26 <- readr::read_csv(                                                   # Lecture CSV département 26
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "debits_26.csv"
  ),
  show_col_types = FALSE
)
debits_38 <- readr::read_csv(                                                   # Lecture CSV département 38
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "debits_38.csv"
  ),
  show_col_types = FALSE
)
# debits_84 <- readr::read_csv(                                                 # Lecture CSV département 84 (commenté)
#   here::here(
#     "donnees",
#     "bulletin",
#     "creations",
#     "debits_84.csv"
#   ),
#   show_col_types = FALSE
# )
debits_smbvl <- readr::read_delim(                                              # Lecture CSV SMBVL (délimiteur ;)
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "debits_smbvl.csv"
  ),
  delim = ",",
  show_col_types = FALSE
)

# ---- Vérification structure identique ----------------------------------------
stopifnot(identical(names(debits_26), names(debits_38)))                        # Vérification colonnes 26/38
# stopifnot(identical(names(debits_26), names(debits_84)))                      # Vérification colonnes 26/84 (commenté)
stopifnot(identical(names(debits_26), names(debits_smbvl)))                     # Vérification colonnes 26/SMBVL

debits_26$code_commune <- as.character(debits_26$code_commune)                  # Uniformisation type commune 26
debits_38$code_commune <- as.character(debits_38$code_commune)                  # Uniformisation type commune 38
debits_smbvl$code_commune <- as.character(debits_smbvl$code_commune)            # Uniformisation type commune SMBVL

# ---- Fusion de tous les départements -----------------------------------------
debits_total <- dplyr::bind_rows(debits_26, debits_38, debits_smbvl)            # Fusion verticale des tibbles
# Note : Ajouter ", debits_84" si la station fonctionne dans le 84

# ---- Export final ------------------------------------------------------------
readr::write_csv(
  debits_total,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "debits.csv"
  )
)
# Export CSV fusionné
message("Fichier fusionné : donnees/bulletin/creations/debits.csv")             # Message confirmation

# ------------------------------------------------------------------------------
# Fin du script
# ------------------------------------------------------------------------------
