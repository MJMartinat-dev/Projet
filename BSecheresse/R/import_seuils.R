# ------------------------------------------------------------------------------
# SCRIPT      : import_seuils.R
# ------------------------------------------------------------------------------
# AUTEUR      : MJMartinat

# DATE        : 01/07/2025
# ------------------------------------------------------------------------------
# DESCRIPTION : Import des fichiers de seuils (débits et nappes), nettoyage
#               des noms de colonnes, conversion des dates et des seuils.
# SORTIE      : objets R `seuils_hydro`, `seuils_piezo`
# ------------------------------------------------------------------------------
# Chargement des bibliothèques nécessaires
# ------------------------------------------------------------------------------
library(dplyr)
library(readr)
library(stringr)
library(lubridate)
library(here)
library(janitor)
library(glue)


# ------------------------------------------------------------------------------
# Conversion d'une date seuil selon le mode de gestion
# ------------------------------------------------------------------------------
parse_seuil_date <- function(Mode_de_gestion, date_vec) {
  if (Mode_de_gestion == "Débits") {
    return(parse_seuil_date_hydro(date_vec))
  } else if (Mode_de_gestion == "Nappes") {
    return(parse_seuil_date_piezo(date_vec))
  } else {
    return(rep(NA, length(date_vec)))
  }
}

# ---- Débits : conversion "jour-mois" (ex : "28-janv.", "2-fevr.") ------------
parse_seuil_date_hydro <- function(date_vec, annee_ref = 2025) {
  mois_fr <- c(
    janv = "01",
    fevr = "02",
    mars = "03",
    avr = "04",
    mai = "05",
    juin = "06",
    juil = "07",
    aout = "08",
    sept = "09",
    oct = "10",
    nov = "11",
    dec = "12"
  )

  date_vec_clean <- date_vec %>%
    tolower() %>%
    gsub("\\.", "", .) %>%
    stringr::str_replace_all(
      c("é" = "e",
        "è" = "e",
        "à" = "a",
        "û" = "u"
      )
    )

  jour <- stringr::str_extract(date_vec_clean, "^\\d{1,2}")

  mois <- stringr::str_extract(date_vec_clean, "[a-z]+")
  mois_num <- mois_fr[mois]

  date_iso <- ifelse(
    is.na(jour) | is.na(mois_num),
    NA_character_,
    glue::glue("{annee_ref}-{mois_num}-{str_pad(jour, 2, pad = '0')}")
  )

  as.Date(date_iso)
}

# ---- Nappes : conversion "mois" (ex : "janvier", "février") ------------------
parse_seuil_date_piezo <- function(date_str, annee_ref = 2025) {

  # Correspondance des mois français (longs et abrégés)
  mois_fr <- c(
    janvier = "01",
    fevrier = "02",
    fevr = "02",
    mars = "03",
    avril = "04",
    mai = "05",
    juin = "06",
    juillet = "07",
    juil = "07",
    aout = "08",
    septembre = "09",
    sept = "09",
    octobre = "10",
    octobre = "10",
    novembre = "11",
    decembre = "12",
    dec = "12",
    oct = "10",
    janv = "01",
    fevr = "02",
    avr = "04",
    juil = "07",
    sept = "09",
    oct = "10",
    nov = "11",
    dec = "12"
  )

  # Nettoyage
  date_str_clean <- date_str %>%
    tolower() %>%
    gsub("\\.", "", .) %>%
    stringr::str_replace_all(
      c("é" = "e",
        "è" = "e",
        "ê" = "e",
        "û" = "u",
        "ï" = "i",
        "â" = "a",
        "ô" = "o",
        "ç" = "c"
      )
    ) %>%
    stringr::str_trim()

  # Extraction du jour et du mois
  jour <- stringr::str_extract(date_str_clean, "^\\d{1,2}")
  mois <- stringr::str_extract(date_str_clean, "(?<=-)[a-z]+|[a-z]+$")
  mois_num <- mois_fr[mois]

  # Si "février", "fevr", etc. (juste mois), alors jour = 01
  jour_final <- ifelse(!is.na(jour), stringr::str_pad(jour, 2, pad = "0"), "01")

  # Si aucun mois reconnu, mais numérique genre "01" ou "1"
  mois_num <- ifelse(
    is.na(mois_num) & stringr::str_detect(date_str_clean, "^\\d{1,2}$"),
    stringr::str_pad(date_str_clean, 2, pad = "0"),
    mois_num
  )

  # Construit la date
  date_iso <- ifelse(
    is.na(mois_num),
    NA_character_,
    glue::glue("{annee_ref}-{mois_num}-{jour_final}")
  )
  as.Date(date_iso)
}

# Conversion d'une date d'observation ISO selon le mode de gestion
parse_obs_date <- function(Mode_de_gestion, date_str) {
  d <- suppressWarnings(ymd(date_str))
  if (is.na(d)) return(NA)

  if (Mode_de_gestion == "Débits") {
    return(floor_date(d, unit = "day"))
  } else if (Mode_de_gestion == "Nappes") {
    return(floor_date(d, unit = "month"))
  } else {
    return(NA)
  }
}

# Conversion sécurisée des colonnes seuils en valeurs numériques
convertir_seuils_numeriques <- function(df) {
  df %>%
    dplyr::mutate(
      dplyr::across(
        c(vigilance, alerte, alerte_renforcee, crise),
        ~ .x %>%
          as.character() %>%
          stringr::str_replace_all(",", ".") %>%
          readr::parse_number(
            locale = locale(decimal_mark = "."),
            na = c("", "NA", "ND", "--", "non", "n/a", "Non défini")
          )
      )
    )
}


# ------------------------------------------------------------------------------
# Import des seuils pour les débits
# ------------------------------------------------------------------------------
seuils_hydro <- readr::read_delim(
  here::here(
    "donnees",
    "bulletin",
    "origines",
    "seuils_hydro.csv"
  ),
  delim = ";",
  show_col_types = FALSE,
  trim_ws = TRUE,
  locale = locale(decimal_mark = ".", encoding = "Windows-1252")
) %>%
janitor::clean_names() %>%
dplyr::mutate(date = parse_seuil_date("Débits", date)) %>%
convertir_seuils_numeriques()


# ------------------------------------------------------------------------------
# Import des seuils pour les nappes
# ------------------------------------------------------------------------------
seuils_piezo_intdpt <- readr::read_delim(
  here::here(
    "donnees",
    "bulletin",
    "origines",
    "seuils_piezo_intdpt.csv"
  ),
  delim = ";",
  show_col_types = FALSE,
  trim_ws = TRUE,
  locale = locale(decimal_mark = ".", encoding = "Windows-1252")
) %>%
janitor::clean_names() %>%
dplyr::mutate(date = parse_seuil_date("Nappes", date)) %>%
convertir_seuils_numeriques()

seuils_piezo_84 <- readr::read_delim(
  here::here(
    "donnees",
    "bulletin",
    "origines",
    "seuils_piezo_84.csv"
  ),
  delim = ";",
  show_col_types = FALSE,
  trim_ws = TRUE,
  locale = locale(decimal_mark = ".", encoding = "Windows-1252")
) %>%
janitor::clean_names() %>%
dplyr::mutate(date = parse_seuil_date("Nappes", date)) %>%
convertir_seuils_numeriques()

seuils_piezo_total <- dplyr::bind_rows(seuils_piezo_intdpt, seuils_piezo_84)

readr::write_csv(
  seuils_piezo_total,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "seuils_piezo.csv"
  )
)

seuils_piezo <- read.csv2(
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "seuils_piezo.csv"
  ),
  sep = ",",
  dec = ".",
  stringsAsFactors = FALSE
)
