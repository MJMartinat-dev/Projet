# ------------------------------------------------------------------------------
# SCRIPT      : import_nappes.R
# ------------------------------------------------------------------------------
# AUTEUR      : MJMartinat
# Structure   : DDT de la Drôme
# DATE        : 01/06/2025
# ------------------------------------------------------------------------------
# DESCRIPTION : Récupération des chroniques piézométriques via l'API Hub'eau
#               pour le département de la Drôme (26), fusion avec métadonnées.
#               Ne conserve que la dernière mesure disponible par code BSS et
#               élimine les enregistrements sans niveau mesuré.
# SORTIE      : donnees/bulletin/creations/niveaux_nappes.csv (niveaux NGF en mètres)
# CORRECTION  : Harmonisation types code_departement (numeric -> character)
# ------------------------------------------------------------------------------
# Chargement des bibliothèques
# ------------------------------------------------------------------------------
library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(readr)
library(janitor)
library(here)
library(tibble)


# ------------------------------------------------------------------------------
# Création du dossier de sortie
# ------------------------------------------------------------------------------
base::dir.create("donnees/bulletin/creations", showWarnings = FALSE)


# ------------------------------------------------------------------------------
# Import_nappes_26
# ------------------------------------------------------------------------------
# ---- Récupération des stations piézométriques --------------------------------
res_stations_nappes_26 <- httr::GET(
  "https://hubeau.eaufrance.fr/api/v1/niveaux_nappes/stations",
  query = list(code_departement = "26", size = 20000)
)
httr::stop_for_status(res_stations_nappes_26)

stations_nappes_26 <- jsonlite::fromJSON(
  httr::content(res_stations_nappes_26, as = "text", encoding = "UTF-8")
)$data %>%
tibble::as_tibble() %>%
janitor::clean_names() %>%
dplyr::select(
  code_departement,
  nom_departement,
  code_commune_insee,
  nom_commune,
  code_bss,
  urn_bss,
  bss_id,
  codes_masse_eau_edl,
  noms_masse_eau_edl,
  profondeur_investigation,
  altitude_station,
  date_debut_mesure,
  date_fin_mesure,
  libelle_pe,
  x,
  y,
  geometry
)

# ---- Fonction de récupération des chroniques piézométriques ------------------
get_chroniques_26 <- function(code_bss_input) {
  res_nappes_26 <- httr::GET("https://hubeau.eaufrance.fr/api/v1/niveaux_nappes/chroniques",
                             query = list(code_bss = code_bss_input, size = 20000))
  if (httr::http_error(res_nappes_26)) return(NULL)

  data_nappes_26 <- httr::content(res_nappes_26, as = "parsed", simplifyVector = TRUE)$data
  if (is.null(data_nappes_26) || length(data_nappes_26) == 0) return(NULL)

  if (base::is.data.frame(data_nappes_26)) {
    return(
      data_nappes_26 %>%
      tibble::as_tibble() %>%
      dplyr::mutate(code_bss = code_bss_input) %>%
      dplyr::select(code_bss, date_mesure, niveau_nappe_eau) %>%
      dplyr::rename(resultat_niveau_nappe = niveau_nappe_eau)
    )
  }

  tibble::tibble(
    code_bss = base::rep(code_bss_input, length(data_nappes_26)),
    date_mesure = purrr::map_chr(data_nappes_26, ~ .x[["date_mesure"]] %||% NA_character_),
    resultat_niveau_nappe = purrr::map_dbl(data_nappes_26, ~ base::as.numeric(.x[["niveau_nappe_eau"]] %||% NA_real_))
  )
}

# ---- Récupération des chroniques ---------------------------------------------
nappes_26 <- stations_nappes_26$code_bss %>%
  base::unique() %>%
  purrr::map_dfr(get_chroniques_26)

# ---- Sécurité : structure vide -----------------------------------------------
if (base::nrow(nappes_26) == 0) {
  nappes_26 <- tibble::tibble(
    code_bss = character(),
    date_mesure = base::as.Date(character()),
    resultat_niveau_nappe = numeric()
  )
}

# ---- Fusion, nettoyage et filtrage -------------------------------------------
final_nappes_26 <- nappes_26 %>%
  dplyr::mutate(date_mesure = base::as.Date(date_mesure)) %>%
  dplyr::left_join(stations_nappes_26, by = "code_bss") %>%
  dplyr::filter(!base::is.na(resultat_niveau_nappe)) %>%
  dplyr::select(
    code_departement,
    nom_departement,
    code_commune_insee,
    nom_commune,
    code_bss,
    urn_bss,
    bss_id,
    altitude_station,
    date_debut_mesure,
    date_fin_mesure,
    libelle_pe,
    x,
    y,
    date_mesure,
    resultat_niveau_nappe
  ) %>%
  dplyr::arrange(
    code_bss,
    dplyr::desc(date_mesure)
  ) %>%
  dplyr::group_by(code_bss) %>%
  dplyr::slice_head(n = 1) %>%
  dplyr::ungroup()

# ---- Format mois -------------------------------------------------------------
final_nappes_26 <- final_nappes_26 %>%
  dplyr::mutate(date_mesure = base::format(date_mesure, "%m"))

# ---- Export final ------------------------------------------------------------
readr::write_csv(
  final_nappes_26,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "niveaux_nappes_26.csv"
  )
)

message("Fichier 'donnees/bulletin/creations/niveaux_nappes_26.csv' généré avec succès (mois de mesure en format 'mm').")


# ------------------------------------------------------------------------------
# Import_nappes_38
# ------------------------------------------------------------------------------
# ---- Récupération des métadonnées de la station ciblée -----------------------
code_bss_cible_38 <- "07953X0104/P"

res_stations_nappes_38 <- httr::GET(
  url = "https://hubeau.eaufrance.fr/api/v1/niveaux_nappes/stations",
  query = list(code_departement = "38", code_bss = code_bss_cible_38)
)
httr::stop_for_status(res_stations_nappes_38)

stations_nappes_38 <- jsonlite::fromJSON(
  httr::content(res_stations_nappes_38, as = "text", encoding = "UTF-8")
)$data %>%
tibble::as_tibble() %>%
janitor::clean_names()

# ---- Fonction de récupération des chroniques piézométriques ------------------
get_chroniques_38 <- function(code_bss_input) {
  res_nappes_38 <- httr::GET("https://hubeau.eaufrance.fr/api/v1/niveaux_nappes/chroniques",
                             query = list(code_bss = code_bss_input, size = 20000))
  if (httr::http_error(res_nappes_38)) return(NULL)

  data_nappes_38 <- httr::content(res_nappes_38, as = "parsed", simplifyVector = TRUE)$data
  if (is.null(data_nappes_38) || length(data_nappes_38) == 0) return(NULL)

  if (base::is.data.frame(data_nappes_38)) {
    return(
      data_nappes_38 %>%
      tibble::as_tibble() %>%
      dplyr::mutate(code_bss = code_bss_input) %>%
      dplyr::select(
        code_bss,
        date_mesure,
        niveau_nappe_eau
      ) %>%
      dplyr::rename(resultat_niveau_nappe = niveau_nappe_eau)
    )
  }

  tibble::tibble(
    code_bss = base::rep(code_bss_input, length(data_nappes_38)),
    date_mesure = purrr::map_chr(data_nappes_38, ~ .x[["date_mesure"]] %||% NA_character_),
    resultat_niveau_nappe = purrr::map_dbl(data_nappes_38, ~ base::as.numeric(.x[["niveau_nappe_eau"]] %||% NA_real_))
  )
}

# ---- Récupération de la chronique pour cette station uniquement --------------
nappes_38 <- get_chroniques_38(code_bss_cible_38)

if (base::nrow(nappes_38) == 0) {
  nappes_38 <- tibble::tibble(
    code_bss = character(),
    date_mesure = base::as.Date(character()),
    resultat_niveau_nappe = numeric()
  )
}

# Fusion, nettoyage et filtrage
final_nappes_38 <- nappes_38 %>%
  dplyr::mutate(date_mesure = base::as.Date(date_mesure)) %>%
  dplyr::left_join(stations_nappes_38, by = "code_bss") %>%
  dplyr::filter(!base::is.na(resultat_niveau_nappe)) %>%
  dplyr::select(
    code_departement,
    nom_departement,
    code_commune_insee,
    nom_commune,
    code_bss,
    urn_bss,
    bss_id,
    altitude_station,
    date_debut_mesure,
    date_fin_mesure,
    libelle_pe,
    x,
    y,
    date_mesure,
    resultat_niveau_nappe
  ) %>%
  dplyr::arrange(
    code_bss,
    dplyr::desc(date_mesure)
  ) %>%
  dplyr::group_by(code_bss) %>%
  dplyr::slice_head(n = 1) %>%
  dplyr::ungroup()

# ---- Format mois -------------------------------------------------------------
final_nappes_38 <- final_nappes_38 %>%
  dplyr::mutate(date_mesure = base::format(date_mesure, "%d-%B"))

# ---- Export final ------------------------------------------------------------
readr::write_csv(
  final_nappes_38,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "niveaux_nappes_38.csv"
  )
)

message("Fichier 'donnees/bulletin/creations/niveaux_nappes_38.csv' généré avec succès (mois de mesure en format 'mm').")


# ------------------------------------------------------------------------------
# Import_nappes_84
# ------------------------------------------------------------------------------
# ---- Chemin du fichier source Excel ------------------------------------------
fichier_excel <- here::here(
  "donnees",
  "bulletin",
  "origines",
  "CA 84 - Nappes 84 - Evolution Suivi 2006-2025.xlsx"
)

# ---- Lecture brute (en-têtes croisés) des lignes 2 à 6, colonnes 6 à 13
#      (F à M) -----------------------------------------------------------------
nappes_84_lignes <- readxl::read_excel(
  fichier_excel,
  sheet = 1,
  range = "F2:M6",
  col_names = FALSE
)

# ---- Reconstruction par paires : on ne garde que les colonnes impaires
#      (6, 8, 10, 12) ----------------------------------------------------------
nappes_84_donnees <- nappes_84_lignes[, c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE, FALSE)]
nappes_84_info <- as.data.frame(t(nappes_84_donnees), stringsAsFactors = FALSE)
names(nappes_84_info) <- c(
  "num_demandeur",
  "nom",
  "representant",
  "origine",
  "commune"
)
nappes_84_info$commune <- stringr::str_to_upper(
  stringr::str_trim(nappes_84_info$commune)
)

# ---- Initialisation des colonnes pour ajout des résultats dans nappes_84_info
nappes_84_info <- nappes_84_info %>%
  dplyr::mutate(
    date = NA_character_,
    hauteur = NA_real_,
    niveau_nappe = NA_real_,
    niveau_total = NA_real_
  )

# ---- Lecture des données de valeur à partir de la ligne 7 (colonnes F à M)----
valeurs <- readxl::read_excel(
  fichier_excel,
  sheet = 1,
  range = readxl::cell_limits(c(7, 6), c(NA, 13))
)

# ---- Extraction des dernières valeurs disponibles pour chaque bloc (4 blocs)
resultats <- lapply(0:3, function(i) {
  col_date <- valeurs[[2 * i + 1]]
  col_haut <- valeurs[[2 * i + 2]]

  commune      <- nappes_84_info$commune[i + 1]
  nom          <- nappes_84_info$nom[i + 1]
  numero       <- nappes_84_info$num_demandeur[i + 1]
  origine      <- nappes_84_info$origine[i + 1]
  representant <- nappes_84_info$representant[i + 1]

  # Nettoyage des dates
  dates <- suppressWarnings(lubridate::dmy(col_date))
  if (all(is.na(dates))) {
    dates <- suppressWarnings(as.Date(as.numeric(col_date), origin = "1899-12-30"))
  }

  valides <- which(!is.na(dates) & !is.na(col_haut))
  if (length(valides) == 0) return(NULL)
  dernier <- valides[which.max(dates[valides])]

  # Valeur de fond de nappe selon commune
  niveau_ref <- dplyr::case_when(
    commune == "SAINTE-CECILE-LES-VIGNES" ~ 114.00,
    commune == "VISAN"                    ~ 113.00,
    commune == "VALREAS"                  ~ 230.10,
    commune == "VILLEDIEU"                ~ 186.00,
    TRUE                                   ~ NA_real_
  )

  nappes_84_info$date[i + 1]         <<- format(dates[dernier], "%d/%m/%Y")
  nappes_84_info$hauteur[i + 1]      <<- as.numeric(col_haut[dernier])
  nappes_84_info$niveau_nappe[i + 1] <<- niveau_ref
  nappes_84_info$niveau_total[i + 1] <<- round(as.numeric(col_haut[dernier]) + niveau_ref, 2)

  dplyr::tibble(
    numero         = numero,
    nom            = nom,
    representant   = representant,
    origine        = origine,
    commune        = commune,
    date           = format(dates[dernier], "%d-%B"),
    hauteur        = as.numeric(col_haut[dernier]),
    niveau_nappe   = niveau_ref,
    niveau_total   = round(as.numeric(col_haut[dernier]) + niveau_ref, 2)
  )
}) %>% bind_rows()

# ---- Export CSV compatible Windows (Windows-1252 ; séparateur ;) -------------
utils::write.table(
  x            = resultats,
  file         = here::here("donnees", "bulletin", "creations", "niveaux_nappes_84.csv"),
  sep          = ",",
  row.names    = FALSE,
  fileEncoding = "UTF-8",
  quote        = FALSE
)


# ------------------------------------------------------------------------------
# Import_nappes - FUSION
# ------------------------------------------------------------------------------
# ---- Chargement des deux fichiers --------------------------------------------
nappes_84 <- readr::read_csv(
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "niveaux_nappes_84.csv"
  ),
  show_col_types = FALSE
)
nappes_38 <- readr::read_csv(
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "niveaux_nappes_38.csv"
  ),
  show_col_types = FALSE
)
nappes_26 <- readr::read_csv(
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "niveaux_nappes_26.csv"
  ),
  show_col_types = FALSE
)

# ---- Transformation stricte du tableau 84 en format national -----------------
nappes_84_fmt <- nappes_84 %>%
  dplyr::transmute(
    code_departement = "84",
    nom_departement = "Vaucluse",
    code_commune_insee = NA_character_,
    nom_commune = commune,
    code_bss = numero,
    urn_bss = NA_character_,
    bss_id = NA_character_,
    altitude_station = NA_real_,
    date_debut_mesure = NA,
    date_fin_mesure = NA,
    libelle_pe = origine,
    x = NA_real_,
    y = NA_real_,
    date_mesure = date,
    resultat_niveau_nappe = niveau_total
  )

# ---- Vérification structure identique ----------------------------------------
stopifnot(identical(names(nappes_38), names(nappes_26)))
stopifnot(identical(names(nappes_38), names(nappes_84_fmt)))

# ------------------------------------------------------------------------------
# Harmonisation des types AVANT fusion
# ------------------------------------------------------------------------------
# ---- Conversion de code_departement en character partout ---------------------
nappes_26$code_departement       <- as.character(nappes_26$code_departement)
nappes_26$code_commune_insee     <- as.character(nappes_26$code_commune_insee)

nappes_38$code_departement       <- as.character(nappes_38$code_departement)
nappes_38$code_commune_insee     <- as.character(nappes_38$code_commune_insee)

nappes_84_fmt$code_commune_insee <- as.character(nappes_84_fmt$code_commune_insee)
nappes_84_fmt$date_mesure        <- as.character(nappes_84_fmt$date_mesure)

# ---- Fusion des 3 jeux de données --------------------------------------------
nappes_total <- dplyr::bind_rows(nappes_38, nappes_26, nappes_84_fmt)
readr::write_csv(nappes_total,
                 here::here(
                   "donnees",
                   "bulletin",
                   "creations",
                   "niveaux_nappes.csv"
                 )
                )

message("fichier fusionné : donnees/bulletin/creations/niveaux_nappes.csv")
