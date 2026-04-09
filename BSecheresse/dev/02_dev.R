# ------------------------------------------------------------------------------
# SCRIPT 02_dev.R - STRUCTURATION DU PROJET
# ------------------------------------------------------------------------------
# Auteur    : MJMartinat
# Structure : DDT de la Drôme
# Date      : 2025
# ------------------------------------------------------------------------------
# Objectifs :
# - Vérification .Renviron & API
# - Création architecture dossiers
# - Création fichiers R & Rmd/tex/html
# - Vérification données dans /donnees
# - Passage au script 03_install_package.R
# ------------------------------------------------------------------------------

if (!requireNamespace("rstudioapi", quietly = TRUE)) install.packages("rstudioapi") # Installe rstudioapi si nécessaire
library(rstudioapi)                                                             # Charge rstudioapi

message("DEBUT DU SCRIPT 02 : STRUCTURATION DU PROJET")                         # Indique le démarrage du script

# ------------------------------------------------------------------------------
# Vérification .Renviron
# ------------------------------------------------------------------------------
if (!file.exists(".Renviron")) stop(".Renviron est manquant, exécuter d'abord 01_start.R")   # Stoppe si .Renviron absent

# ------------------------------------------------------------------------------
# Vérification des clés API
# ------------------------------------------------------------------------------
api_keys <- c("API_MF_LOGIN", "API_MF_PWD", "API_MF_TOKEN")                     # Liste des clés à contrôler
for (k in api_keys) {                                                           # Boucle sur chaque clé
  if (Sys.getenv(k) == "") message("Clé API manquante : ", k)                   # Avertit si une clé est vide
}

# ------------------------------------------------------------------------------
# Création de l’architecture des dossiers
# ------------------------------------------------------------------------------
dirs <- c(
  "donnees/bulletin/sorties",
  "donnees/bulletin/creations",
  "donnees/bulletin/origines",
  "donnees/graphique/sorties",
  "donnees/graphique/sorties/Chroniques_completes",
  "donnees/graphique/origines/sig",
  "donnees/graphique/origines/stations_ades",
  "donnees/graphique/origines/stations_hydro",
  "R",
  "fichiers/Rmd",
  "fichiers/tex",
  "fichiers/html",
  "fichiers/images",
  "sorties/bulletins/pdf",
  "sorties/bulletins/html",
  "sorties/bulletins/images",
  "sorties/cartes/pdf",
  "sorties/cartes/png",
  "sorties/graphique",
  "sorties/graphique/donnees",
  "sorties/graphique/xlsx",
  "sorties/graphique/pdf"
)                                                                               # Vector des dossiers à créer

for (d in dirs) {                                                               # Boucle sur les dossiers
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)                           # Crée le dossier si absent
}

message("Dossiers de travail créés ou déjà présents")                           # Confirmation création arborescence

# ------------------------------------------------------------------------------
# Création des fichiers R vides
# ------------------------------------------------------------------------------
r_files <- c(
  "creation_carte.R",
  "import_debit_smbvl.R",
  "import_debit.R",
  "import_meteofr.R",
  "import_nappe.R",
  "import_onde.R",
  "import_seuils.R",
  "import.R",
  "utils.R"
)                                                                               # Liste des fichiers R attendus

for (f in r_files) {                                                            # Boucle sur les fichiers
  file_path <- file.path("R", f)                                                # Construit le chemin dans R/
  if (!file.exists(file_path)) file.create(file_path)                           # Crée le fichier s'il n'existe pas
}

message("Fichiers R de structure créés ou déjà présents")                       # Confirmation création des squelettes R

# ------------------------------------------------------------------------------
# Création des headers LaTeX et HTML
# ------------------------------------------------------------------------------
if (!file.exists("fichiers/tex/header.tex")) {                                  # Test existence header.tex
  writeLines("% Header LaTeX du projet", "fichiers/tex/header.tex")             # Crée un header.tex minimal
}

if (!file.exists("fichiers/html/header.html")) {                                # Test existence header.html
  writeLines("<!-- Header HTML du projet -->", "fichiers/html/header.html")     # Crée un header.html minimal
}

message("Headers LaTeX et HTML initialisés")                                    # Confirmation initialisation headers

# ------------------------------------------------------------------------------
# Vérification des données attendues dans donnees/origines
# ------------------------------------------------------------------------------
data_required <- c(
  "seuils_hydro.csv",
  "seuils_piezo_84.csv",
  "seuils_piezo_intdpt.csv",
  "seuils_piezo.csv",
  "bassins_versants.csv",
  "departement_26.shp",
  "CA 84 - Nappes 84 - Evolution Suivi 2006-2025.xlsx",
  "2025_Secteurs_Secheresse_interdep.shp"
)                                                                               # Liste des jeux de données requis

for (d in data_required) {                                                      # Boucle sur chaque fichier attendu
  if (!file.exists(file.path("donnees/origines", d))) {                         # Vérifie la présence dans data/
    message("Donnée manquante dans donnees/ : ", d)                             # Avertit si la donnée est absente
  }
}

# ------------------------------------------------------------------------------
# Passage au script 03_install_package.R
# ------------------------------------------------------------------------------
next_script <- file.path(getwd(), "dev", "03_install_package.R")                # Chemin du script 03

if (file.exists(next_script)) {                                                 # Vérifie si le script existe
  message("Passage au script 03_install_package.R")                             # Indique le changement de script
  rstudioapi::navigateToFile(next_script)                                       # Ouvre le script 03 dans RStudio
} else {
  message("Script 03_install_package.R introuvable dans dev")                   # Avertit si script manquant
}

message("SCRIPT 02 TERMINE")                                                    # Fin du script


# ------------------------------------------------------------------------------
# FIN DU SCRIPT 02_dev.R
# ------------------------------------------------------------------------------
