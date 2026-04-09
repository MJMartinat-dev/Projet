# ------------------------------------------------------------------------------
# SCRIPT      : import.R
# ------------------------------------------------------------------------------
# AUTEUR      : MJMartinat
# Structure   : DDT de la Drôme
# DATE        : 01/07/2025
# ------------------------------------------------------------------------------
# DESCRIPTION : Chargement conditionnel des données (débits, nappes, ONDE),
#               fusion avec bassins versants, enrichissement des jeux et
#               export du tableau de synthèse final (fusion_secheresse.csv).
# SORTIE      : donnees/bulletin/sorties/fusion_secheresse.csv (tableau homogène tous modules)
# CORRECTIONS : - Renommage sécurisé avec safe_rename()
#               - Harmonisation types avec force_character()
#               - Gestion robuste des colonnes manquantes
# ------------------------------------------------------------------------------
# Chargement des bibliothèques nécessaires
# ------------------------------------------------------------------------------
library(dplyr)
library(readr)
library(stringr)
library(here)


# ------------------------------------------------------------------------------
# Chargement initial des imports spécifiques
# (appelés automatiquement par d'autres scripts si besoin)
# ------------------------------------------------------------------------------
source(here::here("R", "import_debit.R"), encoding = "UTF-8", local = knitr::knit_global())
source(here::here("R", "import_nappe.R"), encoding = "UTF-8", local = knitr::knit_global())
source(here::here("R", "import_onde.R"), encoding = "UTF-8", local = knitr::knit_global())
source(here::here("R", "import_seuils.R"), encoding = "UTF-8", local = knitr::knit_global())
#source(here::here("R", "import_debit_smbvl.R"), encoding = "UTF-8", local = knitr::knit_global())


# ------------------------------------------------------------------------------
# Lancement conditionnel des scripts si fichiers absents
# ------------------------------------------------------------------------------
required <- c(
  debits = "debits.csv",
  ondes  = "ondes.csv",
  nappes = "niveaux_nappes.csv"
)
scripts <- c(
  debits = "import_debit.R",
  ondes  = "import_onde.R",
  nappes = "import_nappe.R"
)

for (key in names(required)) {
  path <- here::here("donnees", "bulletin", "creations", required[[key]])
  if (!file.exists(path)) {
    message("Génération du fichier manquant : ", required[[key]])
    source(here::here("R", scripts[[key]]), encoding = "UTF-8", local = knitr::knit_global())
  }
}

# ------------------------------------------------------------------------------
# Chargement des seuils
# ------------------------------------------------------------------------------
# ---- Vérification de la présence des fichiers de seuils ----------------------
seuil_files <- c("seuils_hydro.csv", "seuils_piezo.csv")
for (f in seuil_files) {
  chemin <- here::here("donnees", "bulletin", "origines", f)
  if (!file.exists(chemin)) {
    stop(paste0("Le fichier '", f, "' est manquant. Veuillez le placer dans 'donnees/bulletin/origines'."))
  }
}


# ---- Chargement des seuils via le script dédié -------------------------------
source(
  here::here(
    "R",
    "import_seuils.R"
  ),
encoding = "UTF-8")


# ------------------------------------------------------------------------------
# Chargement des données CSV sources
# ------------------------------------------------------------------------------
bv <- readr::read_delim(
  here::here(
    "donnees",
    "bulletin",
    "origines",
    "bassins_versants.csv"
  ),
  delim = ";",
  locale = locale(encoding = "Windows-1252"),
  show_col_types = FALSE
)


# ------------------------------------------------------------------------------
# Fonction de chargement CSV (codage Windows-1252)
# ------------------------------------------------------------------------------
load_csv_cp1252 <- function(path) read_csv(path, locale = locale(encoding = "Windows-1252"), show_col_types = FALSE)

# ---- Débits (formulaire) -----------------------------------------------------
debits_form <- readr::read_csv(
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "debits.csv"
  ),
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE) %>%
  dplyr::mutate(
    code_station = stringr::str_trim(code_station)
  ) %>%
  dplyr::mutate(
    dplyr::across(
      c(latitude, longitude, date_obs, debit_m3s),
      as.character)
  )

# ---- Ondes (formulaire) ------------------------------------------------------
des_form  <- load_csv_cp1252(
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "ondes.csv"
  )
) %>%
dplyr::mutate(
  code_station = stringr::str_trim(code_station)
) %>%
dplyr::mutate(
  dplyr::across(
    c(latitude, longitude, date_observation, libelle_ecoulement),
    as.character
  )
)

# ---- Nappes (formulaire) -----------------------------------------------------
nappes_form <- load_csv_cp1252(
  here::here(
    "donnees",
    "bulletin",
    "creations",
    "niveaux_nappes.csv"
  )
) %>%
dplyr::mutate(
  code_bss = stringr::str_trim(code_bss)
) %>%
dplyr::mutate(
  dplyr::across(
    c(date_mesure, resultat_niveau_nappe),
    as.character
  )
)

# ---- Normalisation des codes station dans BV ---------------------------------
bv <- bv %>%
  dplyr::mutate(
    code_station = stringr::str_trim(code_station)
  )


# ------------------------------------------------------------------------------
# Fonctions utilitaires
# ------------------------------------------------------------------------------
# ---- Fonction de renommage sécurisé (ne plante pas si colonne absente) -------
safe_rename <- function(df, ...) {
  renames <- list(...)
  for (new_name in names(renames)) {
    old_name <- renames[[new_name]]
    if (old_name %in% names(df)) {
      names(df)[names(df) == old_name] <- new_name
    }
  }
  df
}

# ---- Fonction de conversion brutale en character (garantie 100%) -------------
force_character <- function(df) {
  for (col in names(df)) {
    df[[col]] <- as.character(df[[col]])
  }
  df
}

# ---- Fonction utilitaire pour ajouter les colonnes manquantes si besoin ------
ajoute_colonnes_manquantes <- function(df, colonnes_finales) {
  for (col in setdiff(colonnes_finales, names(df))) {
    df[[col]] <- NA_character_
  }
  df <- df[, colonnes_finales]
  return(df)
}


# ------------------------------------------------------------------------------
# Enrichissement des données
# ------------------------------------------------------------------------------
# ---- Débits enrichis avec données BV -----------------------------------------
debits_bc <- debits_form %>%
  dplyr::select(
    -code_departement,
    -libelle_departement,
    -code_commune,
    -libelle_commune,
    -code_cours_eau,
    -libelle_cours_eau,
    -code_site,
    -libelle_site,
    -libelle_station
  ) %>%
  dplyr::inner_join(
    bv,
    by = "code_station"
  ) %>%
  dplyr::mutate(
    code_region = "84",
    libelle_region = "AUVERGNE-RHONE-ALPES"
  ) %>%
  dplyr::select(
    code_region,
    libelle_region,
    bassins_versants,
    code_departement,
    libelle_departement,
    code_commune,
    libelle_commune,
    code_cours_eau,
    libelle_cours_eau,
    type_d_eau,
    libelle_bassin_versant,
    libelle_site,
    code_station,
    libelle_station,
    coordonnee_x,
    coordonnee_y,
    longitude,
    latitude,
    code_site,
    date_obs,
    debit_m3s
  )

# ---- Ondes enrichies avec données BV -----------------------------------------
ondes_bc <- des_form %>%
  dplyr::select(
    -any_of(
      c("code_region",
        "libelle_region",
        "code_departement",
        "libelle_departement",
        "code_commune",
        "libelle_commune",
        "code_cours_eau",
        "libelle_cours_eau",
        "code_site",
        "libelle_site",
        "libelle_station"
      )
    )
  ) %>%
  dplyr::inner_join(
    bv,
    by = "code_station"
  ) %>%
  dplyr::mutate(
    code_region = "84",
    libelle_region = "AUVERGNE-RHONE-ALPES"
  ) %>%
  dplyr::select(
    code_region,
    libelle_region,
    bassins_versants,
    code_departement,
    libelle_departement,
    code_commune,
    libelle_commune,
    code_bassin,
    libelle_bassin,
    code_cours_eau,
    libelle_cours_eau,
    type_d_eau,
    code_site,
    libelle_site,
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

# ---- Nappes enrichies avec données BV ----------------------------------------
nappes_bc <- nappes_form %>%
  # Renommage sécurisé avec fonction helper
  safe_rename(
    libelle_departement = "nom_departement",
    code_commune = "code_commune_insee",
    libelle_commune = "nom_commune",
    code_station = "code_bss"
  ) %>%
  dplyr::select(
    -any_of(
      c("code_departement",
        "nom_departement",
        "code_commune_insee",
        "nom_commune",
        "code_bss"
      )
    )
  ) %>%
  dplyr::inner_join(
    bv,
    by = "code_station"
  ) %>%
  dplyr::mutate(
    code_region = "84",
    libelle_region = "AUVERGNE-RHONE-ALPES"
  ) %>%
  dplyr::select(
    any_of(
      c("code_region",
        "libelle_region",
        "bassins_versants",
        "code_departement",
        "libelle_departement",
        "code_commune",
        "libelle_commune",
        "type_d_eau",
        "urn_bss",
        "code_station",
        "bss_id",
        "altitude_station",
        "date_debut_mesure",
        "date_fin_mesure",
        "libelle_pe",
        "x",
        "y",
        "date_mesure",
        "resultat_niveau_nappe"
      )
    )
  )

# ---- Export des fichiers intermédiaires enrichis -----------------------------
readr::write_csv(
  debits_bc,
  here::here(
    "donnees",
    "bulletin",
    "sorties",
    "debits_bc.csv"
  )
)
readr::write_csv(
  ondes_bc,
  here::here(
    "donnees",
    "bulletin",
    "sorties",
    "ondes_bc.csv"
  )
)
readr::write_csv(
  nappes_bc,
  here::here(
    "donnees",
    "bulletin",
    "sorties",
    "nappes_bc.csv"
    )
)

cat("Données normalisées exportées.\n")


# ------------------------------------------------------------------------------
# Préparation des tableaux de données pour fusion
# ------------------------------------------------------------------------------
# ---- Colonnes à garder -------------------------------------------------------
colonnes_finales <- c(
  "code_region",
  "libelle_region",
  "bassins_versants",
  "code_departement",
  "libelle_departement",
  "code_commune",
  "libelle_commune",
  "type_d_eau",
  "Mode_de_gestion",
  "libelle_site",
  "code_site",
  "code_station",
  "Stations",
  "Date_obs",
  "Mesures"
)

# ---- Débits ------------------------------------------------------------------
debits_df <- debits_bc %>%
  safe_rename(
    Stations = "libelle_station",
    Mesures = "debit_m3s",
    Date_obs = "date_obs"
  ) %>%
  dplyr::mutate(
    Mode_de_gestion = "Débits"
  ) %>%
  ajoute_colonnes_manquantes(colonnes_finales)

# ---- Ondes -------------------------------------------------------------------
ondes_df <- ondes_bc %>%
  safe_rename(
    Stations = "libelle_station",
    Mesures = "libelle_ecoulement",
    Date_obs = "date_observation"
  ) %>%
  dplyr::mutate(
    Mode_de_gestion = "Réseau ONDE"
  ) %>%
  ajoute_colonnes_manquantes(colonnes_finales)

# ---- Nappes ------------------------------------------------------------------
nappes_df <- nappes_bc %>%
  safe_rename(
    Stations = "libelle_pe",
    Mesures = "resultat_niveau_nappe",
    Date_obs = "date_mesure"
  ) %>%
  mutate(
    Mode_de_gestion = "Nappes"
  ) %>%
  ajoute_colonnes_manquantes(colonnes_finales)


# ------------------------------------------------------------------------------
# Conversion brutale en caractère (GARANTIE 100%)
# ------------------------------------------------------------------------------
debits_df <- force_character(debits_df)
ondes_df <- force_character(ondes_df)
nappes_df <- force_character(nappes_df)


# ------------------------------------------------------------------------------
# Fusion finale
# ------------------------------------------------------------------------------
fusion_df <- bind_rows(debits_df, ondes_df, nappes_df)

# ---- Tri et export -----------------------------------------------------------
fusion_df <- fusion_df %>%
  dplyr::arrange(bassins_versants, Mode_de_gestion, Stations)

readr::write_delim(
  fusion_df,
  here::here(
    "donnees",
    "bulletin",
    "sorties",
    "fusion_secheresse.csv"
  ),
  delim = ";"
)

cat("Fichier fusionné fusion_secheresse.csv exporté avec succès.\n")


# ------------------------------------------------------------------------------
# Lecture finale pour contrôle
# ------------------------------------------------------------------------------
f_secheresse <- readr::read_delim(
  here::here(
    "donnees",
    "bulletin",
    "sorties",
    "fusion_secheresse.csv"
  ),
  delim = ";",
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

# ---- Ordre attendu des bassins versants --------------------------------------
ordre_bv <- c(
  "Bièvre Liers Valloire",
  "Galaure – Drôme des Collines",
  "Plaine de Valence",
  "Royan – Vercors",
  "Bassin de la Drôme",
  "Roubion – Jabron",
  "Berre",
  "Lez provençal – Lauzon",
  "AEygues",
  "Ouvèze Provencale",
  "La Méouge"
)

# ---- Normalisation + tri -----------------------------------------------------
donnees <- f_secheresse %>%
  dplyr::mutate(
    bv_norm = stringr::str_to_lower(
      stringr::str_trim(bassins_versants)
    )
  ) %>%
  dplyr::mutate(
    ordre_temp = match(bv_norm, str_to_lower(ordre_bv))
  ) %>%
  dplyr::filter(!is.na(ordre_temp)) %>%
  dplyr::arrange(ordre_temp) %>%
  dplyr::select(-bv_norm, -ordre_temp)


# ------------------------------------------------------------------------------
# Message finaux
# ------------------------------------------------------------------------------
message("Import terminé avec succès.")
message("  - Débits : ", nrow(debits_df), " lignes")
message("  - ONDE : ", nrow(ondes_df), " lignes")
message("  - Nappes : ", nrow(nappes_df), " lignes")
message("  - Total fusionné : ", nrow(fusion_df), " lignes")
message("  - Fichier final : donnees/bulletin/sorties/fusion_secheresse.csv")
