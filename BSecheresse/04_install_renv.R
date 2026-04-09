# ------------------------------------------------------------------------------
# SCRIPT 03_install_packages - INSTALLATION DES PACKAGES ET CONFIGURATION LATEX
# ------------------------------------------------------------------------------
# Auteur    : MJMartinat
# Structure : DDT de la Drôme
# Date      : 2025
# ------------------------------------------------------------------------------
# Objectifs :
# - Installation des packages nécessaires
# - Réinstallation complète de TinyTeX
# - Suivie du rendu automatique du bulletin sécheresse.
# ------------------------------------------------------------------------------

message("DEBUT DU SCRIPT 03 : INSTALLATION DES DEPENDANCES ET CONFIGURATION LATEX")    # Indique le début du script


# ------------------------------------------------------------------------------
# Vérification .Renviron et proxy
# ------------------------------------------------------------------------------
if (!file.exists(".Renviron"))
  stop(".Renviron est manquant, exécuter d'abord 01_start.R")                   # Stoppe si .Renviron absent

HTTP_PROXY <- Sys.getenv("http_proxy")                                          # Lit la variable PROXY
if (HTTP_PROXY != "") {                                                         # Vérifie si un proxy est défini
  message("Proxy détecté : ", HTTP_PROXY)                                       # Affiche le proxy
} else {
  message("Aucun proxy défini dans .Renviron")                                  # Informe qu'aucun proxy n'est défini
}

HTTPS_PROXY <- Sys.getenv("https_proxy")                                        # Lit la variable PROXY
if (HTTPS_PROXY != "") {                                                        # Vérifie si un proxy est défini
  message("Proxy détecté : ", HTTPS_PROXY)                                      # Affiche le proxy
} else {
  message("Aucun proxy défini dans .Renviron")                                  # Informe qu'aucun proxy n'est défini
}

FTP_PROXY <- Sys.getenv("ftp_proxy")                                            # Lit la variable PROXY
if (FTP_PROXY != "") {                                                          # Vérifie si un proxy est défini
  message("Proxy détecté : ", FTP_PROXY)                                        # Affiche le proxy
} else {
  message("Aucun proxy défini dans .Renviron")                                  # Informe qu'aucun proxy n'est défini
}


# ------------------------------------------------------------------------------
# Liste des packages nécessaires au projet
# ------------------------------------------------------------------------------
pkgs <- c(
  "chromote",                                                                   # Pilotage Chrome headless via le protocole DevTools :
                                                                                # - capture/rendu de HTML (screenshots, PDF), tests visuels,
                                                                                # - automatisation (ex: générer des exports "pixel perfect").
                                                                                # Pré-requis: un binaire Chrome/Chromium accessible sur la machine.
  "dplyr",                                                                      # Wrangling data "tidy" : filter/mutate/summarise/join.
                                                                                # À privilégier pour la lisibilité des pipelines (avec pipes).
  "glue",                                                                       # Templating de chaînes robuste :
                                                                                # - interpolation {var} + construction de messages/paths/SQL.
                                                                                # Utile pour logs, noms de fichiers, textes de rapports.
  "grid",                                                                       # Système graphique bas niveau :
                                                                                # - assemblage de grobs, annotations, mise en page avancée.
                                                                                # Souvent utilisé indirectement via ggplot2/tables/plots.
  "here",                                                                       # Gestion de chemins "projet-aware" :
                                                                                # - évite setwd() et les chemins relatifs fragiles.
                                                                                # Stabilise l’exécution sur différentes machines/CI.
  "httr",                                                                       # Client HTTP (REST) :
                                                                                # - GET/POST, headers, auth, retry, timeouts.
                                                                                # Alternative moderne : httr2 (si tu envisages une montée de version).
  "janitor",                                                                    # Nettoyage de dataframes :
                                                                                # - clean_names(), tabyl(), remove_empty().
                                                                                # Très utile en ingestion (Excel/CSV hétérogènes).
  "jsonlite",                                                                   # JSON performant :
                                                                                # - fromJSON/toJSON, streaming possible, gestion des types.
                                                                                # Recommandé pour APIs + sérialisation de config/artefacts.
  "kableExtra",                                                                 # Mise en forme avancée des tableaux knitr :
                                                                                # - styles HTML/PDF/LaTeX, colonnes, group headers.
                                                                                # À manier prudemment si multi-formats (HTML vs PDF).
  "knitr",                                                                      # Moteur R Markdown (chunks, options, hooks) :
                                                                                # - cœur du rendu reproductible (cache, figures, tables).
  "leaflet",                                                                    # Cartographie interactive (htmlwidgets) :
                                                                                # - couches, popups, tuiles, intégration Shiny.
                                                                                # Attention aux volumes de géométrie (simplification souvent requise).
  "lubridate",                                                                  # Manipulation des dates :
                                                                                # - parse, floor_date, intervals, time zones.
                                                                                # À cadrer : timezone explicite si reporting réglementaire.
  "magrittr",                                                                   # Pipes et helpers (%>%, %<>%, extractors) :
                                                                                # - utile si tu veux certaines variantes hors base pipe |>.
                                                                                # Note : R >= 4.1 propose |>, mais magrittr reste courant.
  "markdown",                                                                   # Rendu markdown bas niveau :
                                                                                # - conversion md -> html (souvent complémentaire à rmarkdown).
  "plyr",                                                                       # Package legacy (pré-tidyverse) :
                                                                                # - risque de conflits avec dplyr (ex: summarise, arrange).
                                                                                # À conserver uniquement si tu as du code historique dépendant.
  "png",                                                                        # Lecture/écriture PNG :
                                                                                # - import d’icônes, logos, overlays pour rapports/cartes.
  "progress",                                                                   # Barres de progression :
                                                                                # - ergonomie UX pour scripts longs / boucles (ETL, batch).
  "purrr",                                                                      # Programmation fonctionnelle :
                                                                                # - map(), safely(), possibly(), walk().
                                                                                # Excellent pour pipelines robustes (gestion d’erreurs contrôlée).
  "Rcpp",                                                                       # Interface C++ :
                                                                                # - accélération/perf, dépendance indirecte de nombreux packages.
                                                                                # À noter si compilation native/CI (toolchain requis).
  "readr",                                                                      # I/O fichiers plats performant :
                                                                                # - read_csv(), write_csv(), col_types, locale.
                                                                                # Préférable à utils::read.csv pour perf + types.
  "readxl",                                                                     # Lecture Excel sans Java :
                                                                                # - read_excel(), gestion des sheets.
                                                                                # Alternative recommandée à xlsx quand possible.
  "rjson",                                                                      # JSON legacy :
                                                                                # - souvent remplacé par jsonlite.
                                                                                # À garder seulement si compat rétro ou objets spécifiques.
  "rmarkdown",                                                                  # Orchestration du rendu (HTML/PDF/Word) :
                                                                                # - render(), params, formats.
                                                                                # Dépendances LaTeX/Pandoc selon la cible.
  "sf",                                                                         # Spatial vectoriel (Simple Features) :
                                                                                # - opérations géo, reprojection, jointures spatiales.
                                                                                # Dépendances système : GDAL/GEOS/PROJ (sensibles en déploiement).
  "stars",                                                                      # Spatial raster/grilles :
                                                                                # - manipulation de rasters/arrays spatio-temporels.
                                                                                # Attention mémoire (chunking / proxy si gros volumes).
  "stringi",                                                                    # Moteur Unicode bas niveau (ICU) :
                                                                                # - robustesse sur accents, normalisation, encodages.
                                                                                # Souvent dépendance indirecte de stringr.
  "stringr",                                                                    # API "user-friendly" sur stringi :
                                                                                # - str_detect/replace/extract, regex cohérentes.
                                                                                # Recommandé pour pipelines texte.
  "tibble",                                                                     # Dataframes modernes :
                                                                                # - impression, colonnes-list, compat tidyverse.
  "tidyverse",                                                                  # Meta-package (dplyr, ggplot2, tidyr, readr, purrr, tibble, stringr...) :
                                                                                # - charge un écosystème complet.
                                                                                # Utile en dev, mais en prod tu peux préférer charger finement.
  "tmap",                                                                       # Cartographie (statique + interactive) :
                                                                                # - tmap_mode("plot"/"view"), mise en page carto.
                                                                                # Alternative/complément à ggplot2 + sf selon besoins.
  "utils",                                                                      # Base R utilitaires :
                                                                                # - read.csv, unzip, sessionInfo, etc.
                                                                                # Souvent déjà disponible (base), mais OK en liste pour clarté.
  "xlsx",                                                                       # Excel via Java (souvent) :
                                                                                # - write/read .xlsx avec styles.
                                                                                # Attention : dépendances Java + fragilité en serveur/CI.
                                                                                # Si l’objectif est l’export, openxlsx est souvent plus “déployable”.
  "yaml",                                                                       # Lecture config YAML :
                                                                                # - paramètres de pipeline, config environnement.
                                                                                # Très utile pour séparer code et configuration.
  "zoo"                                                                         # Séries temporelles :
                                                                                # - rollapply, interpolation, index time.
                                                                                # Pertinent pour hydro/météo (moyennes glissantes, trous de mesure).
)

# ---- Installation conditionnelle des packages manquants --
to_install <- pkgs[!pkgs %in% installed.packages()[, "Package"]]                # Identifie les packages non installés dans l'environnement

if (length(to_install) > 0) {                                                   # Vérifie s'il existe au moins un package manquant
  install.packages(to_install)                                                  # Installe uniquement les dépendances absentes
  message("Packages installés : ", paste(to_install, collapse = ", "))          # Retour console listant les packages installés
} else {
  message("Tous les packages nécessaires sont déjà installés.")                 # Message si aucune installation n'est requise
}



# ---- Chargement des packages critiques ------------------
library(here)                                                                   # Charge here


# ------------------------------------------------------------------------------
# Réinstallation propre TinyTeX + mise à jour + rendu bulletin
# ------------------------------------------------------------------------------
message("REINSTALLATION PROPRE TINYTEX ET GENERATION DU BULLETIN")              # Message de contexte

# ---- Packages nécessaires déjà installés ci-dessus ------                     # Commentaire de cohérence

# ---- Désinstallation TinyTeX ----------------------------
message("Desinstallation de TinyTeX existant")                                  # Information phase de désinstallation
try({
  tinytex::uninstall_tinytex()                                                  # Tente de désinstaller TinyTeX
}, silent = TRUE)                                                               # Ignore les erreurs si non installé

# ---- Suppression des dossiers TinyTeX résiduels ---------
paths_to_clean <- c(
  file.path(Sys.getenv("APPDATA"), "TinyTeX"),                                  # Dossier TinyTeX dans APPDATA
  file.path(Sys.getenv("LOCALAPPDATA"), "TinyTeX"),                             # Dossier TinyTeX dans LOCALAPPDATA
  "C:/TinyTeX"                                                                  # Installation racine éventuelle
)                                                                               # Fin du vecteur de chemins

message("Suppression des dossiers TinyTeX residuels")                           # Information nettoyage

for (p in paths_to_clean) {                                                     # Parcourt chaque chemin
  if (dir.exists(p)) {                                                          # Vérifie l'existence du dossier
    message("Suppression du dossier : ", p)                                     # Indique le dossier supprimé
    unlink(p, recursive = TRUE, force = TRUE)                                   # Supprime le dossier de façon récursive
  }
}

# ---- Vérification de la présence de tlmgr --------------
if (Sys.which("tlmgr") != "") {                                                 # Vérifie si tlmgr est encore accessible
  message("tlmgr encore present : ", Sys.which("tlmgr"))                        # Informe de sa présence résiduelle
  message("Supprimer manuellement ce dossier si necessaire")                    # Invite à un nettoyage manuel
} else {
  message("Aucun moteur TeX residuel détecté")                                  # Confirme l'absence de tlmgr
}

# ---- Réinstallation TinyTeX complète (TinyTeX-2) -------
message("Installation de TinyTeX-2 (version complete)")                         # Information phase installation

tinytex::install_tinytex(bundle = "TinyTeX-2", force = TRUE)                    # Installe TinyTeX-2 proprement

message("TinyTeX installe avec succes")                                         # Confirmation installation

# ---- Mise à jour complète de TeXLive ------------------
message("Mise a jour complete de tlmgr")                                        # Indique la mise à jour

tinytex::tlmgr_update("--self", "--all")                                        # Met à jour tlmgr et tous les paquets

message("Mise a jour TeXLive terminée")                                         # Confirmation des mises à jour

# ---- Diagnostic post-installation --------------------
message("Verification du moteur TeX installe")                                  # Diagnostic LaTeX

tryCatch({
  system2("xelatex", "--version")                                               # Vérifie la disponibilité de xelatex
}, error = function(e) {
  message("xelatex introuvable, verifier la configuration ou relancer RStudio") # Message en cas de problème
})

message("Verification du module expl3")                                         # Information vérification expl3

try({
  tinytex::tlmgr_info("l3kernel")                                               # Vérifie le package l3kernel
  tinytex::tlmgr_info("l3packages")                                             # Vérifie le package l3packages
}, silent = TRUE)                                                               # Ignore les warnings

message("Systeme LaTeX considere comme coherent")                               # Conclusion sur LaTeX


# ------------------------------------------------------------------------------
# Génération automatique du bulletin
# ------------------------------------------------------------------------------
message("Lancement de la generation automatique du bulletin")                   # Indique le début du rendu

bulletin_script <- here::here("R", "render_bulletin.R")                         # Localise le script de rendu

if (!file.exists(bulletin_script)) {                                            # Vérifie la présence du script
  stop("Le fichier R/render_bulletin.R est introuvable")                        # Stoppe si le script n'existe pas
}

source(bulletin_script, encoding = "UTF-8")                                     # Charge le script render_bulletin

render_bulletin()                                                               # Appelle la fonction de rendu

message("Bulletin genere avec succes")                                          # Confirme la génération du bulletin
message("Chemin de sortie : ", here::here("sorties", "bulletins", "pdf"))       # Indique le dossier de sortie


# ------------------------------------------------------------------------------
# Passage au script 04_create_bulletin.R
# ------------------------------------------------------------------------------
next_script <- file.path(getwd(), "dev", "04_install_renv.R")                   # Chemin du script 04

if (file.exists(next_script)) {                                                 # Vérifie si le script existe
  message("Passage au script 04_install_renv.R")                                # Indique le changement de script
  rstudioapi::navigateToFile(next_script)                                       # Ouvre le script 04 dans RStudio
} else {
  message("Script 04_install_renv.R introuvable dans dev")                      # Avertit si script manquant
}

message("SCRIPT 04 TERMINE")                                                    # Fin du script


# ------------------------------------------------------------------------------
# FIN DU SCRIPT 03_install_packages.R
# ------------------------------------------------------------------------------

