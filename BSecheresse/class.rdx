# ------------------------------------------------------------------------------
# SCRIPT      : import_debits_smbvl.R
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
library(chromote)
library(jsonlite)
library(dplyr)
library(readr)
library(lubridate)
library(here)
library(purrr)
library(stringr)


# ------------------------------------------------------------------------------
# Référentiel des 4 stations ciblées
# ------------------------------------------------------------------------------
stations_smbvl <- tibble(
  libelle_station = c(
    "L'Hérin à Bouchet",
    "Le Lez à Suze-la-Rousse",
    "Le Lez à Bollène",
    "Le Lez à Grignan [Pont D 541]"
  ),
  code_station = c(
    "V522000201",
    "V522000301",
    "V523401001",
    "V521402601"
  ),
  code_region = c(
    84,
    84,
    93,
    84
  ),
  libelle_region = c(
    "AUVERGNE-RHONE-ALPES",
    "AUVERGNE-RHONE-ALPES",
    "PROVENCE-ALPES-CÔTE-D-AZUR",
    "AUVERGNE-RHONE-ALPES"
  ),
  libelle_bassin_versant = rep("Lez provençal – Lauzon", 4),
  code_departement = c(
    26,
    26,
    84,
    26
  ),
  libelle_departement = c(
    "DROME",
    "DROME",
    "VAUCLUSE",
    "DROME"
  ),
  code_commune = c(
    26054,
    26345,
    84500,
    26146
  ),
  libelle_commune = c(
    "BOUCHET",
    "SUZE-LA-ROUSSE",
    "BOLLENE",
    "GRIGNAN"
  ),
  code_cours_eau = c(
    "V5220540",
    "V52-0400",
    "V5230400",
    "V52-0400"
  ),
  libelle_cours_eau = c(
    "l’Hérin",
    "Le Lez",
    "Le Lez",
    "Le Lez"
  ),
  code_site = c(
    "V5220002",
    "V5220003",
    "V5234010",
    "V5214026"
  ),
  libelle_site = c(
    "L'Hérin à Bouchet",
    "Le Lez à Suze-la-Rousse",
    "Le Lez à Bollène",
    "Le Lez à Grignan [Pont D 541]"
  ),
  coordonnee_x = c(
    849465.0,
    846674.0,
    839708.6,
    852631.0
  ),
  coordonnee_y = c(
    6357110,
    6356433,
    6355253,
    6369569
  ),
  longitude = c(
    4.873447,
    4.838279,
    4.750682,
    4.916906
  ),
  latitude = c(
    44.29705,
    44.29155,
    44.28236,
    44.40849
  )
)


# ------------------------------------------------------------------------------
# Récupération des données SMBVL (via Chromote)
# ------------------------------------------------------------------------------
b <- ChromoteSession$new()
b$Network$enable()
b$Network$setCookie(name = ".ASPXAUTH", value = "…", domain = "smbvl.follow.solutions", path = "/")
b$Network$setCookie(name = "ASP.NET_SessionId", value = "…", domain = "smbvl.follow.solutions", path = "/")
b$Page$navigate("https://smbvl.follow.solutions/tableau")
b$Page$loadEventFired(); Sys.sleep(5)
b$Runtime$evaluate('
  fetch("/tableau/GetTableauAjax", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "X-Requested-With": "XMLHttpRequest"
    },
    body: "idVue=5&supervision=HYDRO&idTypeStation=0&idTypeCanalCollecte=0&idTypeMediaCollecte=0&checkboxAlarme=false"
  }).then(res => res.json()).then(data => window._smbvlData = data)
')
message("Attente du chargement de _smbvlData...")
try_count <- 0
repeat {
  Sys.sleep(2)
  res <- b$Runtime$evaluate("typeof window._smbvlData !== 'undefined'")
  if (res$result$value == TRUE) break
  try_count <- try_count + 1
  if (try_count > 10) { b$close(); stop("Données toujours non disponibles après 20 sec.") }
}

res_debits_smbvl <- b$Runtime$evaluate("JSON.stringify(window._smbvlData)")
donnees_smbvl <- jsonlite::fromJSON(res_debits_smbvl$result$value, flatten = TRUE)


# ------------------------------------------------------------------------------
# Préparation des mesures, fusion des valeurs seulement
# ------------------------------------------------------------------------------
noms_cibles <- stations_smbvl$libelle_station
mapping_json_to_libelle <- c(
  "Bouchet - Hérein"     = "L'Hérin à Bouchet",
  "Suze la Rousse - Lez" = "Le Lez à Suze-la-Rousse",
  "Bollène - Lez"        = "Le Lez à Bollène",
  "Grignan - Lez"        = "Le Lez à Grignan [Pont D 541]"
)


debits_mesures <- donnees_smbvl %>%
  filter(nom %in% names(mapping_json_to_libelle)) %>%
  transmute(
    libelle_station = recode(nom, !!!mapping_json_to_libelle),
    # ---- Extraction du jour/mois et conversion -------------------------------
    date_obs = str_extract(dateDerniereMesure, "^[0-9]{2}/[0-9]{2}"),
    date_obs = dmy(paste0(date_obs, "/", year(Sys.Date()))),
    # Format français "jour-mois_abbr."
    date_obs = format(date_obs, "%m-%d")
    ,
    debit_m3s = as.numeric(str_replace(`mesureParTypeRub.DEBIT_CC.valeur`, ",", "."))
  )


# ------------------------------------------------------------------------------
# Jointure stricte pour n'avoir QUE 4 lignes
# ------------------------------------------------------------------------------
debits_smbvl_final <- stations_smbvl %>%
  left_join(debits_mesures, by = "libelle_station")


# ------------------------------------------------------------------------------
# Colonnes dans l'ordre voulu
# ------------------------------------------------------------------------------
colonnes_finales <- c(
  "code_station",
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
  "latitude",
  "debit_m3s",
  "date_obs"
)

debits_smbvl_final <- debits_smbvl_final %>%
  select(all_of(colonnes_finales))


# ------------------------------------------------------------------------------
# Export CSV
# ------------------------------------------------------------------------------
readr::write_csv(
  debits_smbvl_final,
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "debits_smbvl.csv"
  )
)

message("Export avec 4 lignes, toutes métadonnées, date et débit mesuré à jour.")


# ------------------------------------------------------------------------------
# Fermeture propre Chromote
# ------------------------------------------------------------------------------
b$close()
