# ------------------------------------------------------------------------------
# SCRIPT 01_start.R - INITIALISATION DU PROJET SÉCHERESSE
# ------------------------------------------------------------------------------
# Auteur : MJMartinat
# Structure : DDT de la Drôme
# Date : 2025
# ------------------------------------------------------------------------------
# Objectifs :
# - Création .Renviron
# - Vérification proxy
# - Installation packages du développement
# - Création projet R, DESCRIPTION
# - Passage automatique au script 02_dev.R
# ------------------------------------------------------------------------------

if (!requireNamespace("rstudioapi", quietly = TRUE)) install.packages("rstudioapi")   # Installe rstudioapi si absent
library(rstudioapi)                                                                   # Charge rstudioapi

message("DEMARRAGE DU SCRIPT 01 - PARAMETRAGE INITIAL")                               # Message d'état

# ------------------------------------------------------------------------------
# Création du fichier .Renviron si absent
# ------------------------------------------------------------------------------
# renv_path <- file.path(getwd(), ".Renviron")                                  # Chemin vers .Renviron
#
# if (!file.exists(renv_path)) {                                                # Vérifie si .Renviron existe
#   writeLines(c(
#     "HTTP_PROXY=adress_proxy_a_modifier",                                     # Définit le http proxy
#     "HTTPS_PROXY=adress_proxy_a_modifier",                                    # Définit le htpps proxy
#     "FTP_PROXY=adress_proxy_a_modifier",                                      # Définit le ftp proxy
#     "API_MF_LOGIN"="identifiant_meteofrance_a_modifier",                      # Identifiant utilisateur
#     "API_MF_PWD"="mdp_meteofrance_a_modifier",                                # Mot de passe utilisateur
#     "API_MF_TOKEN"="mdp_meteofrance_a_modifier",                              # Clé API météo
#   ), renv_path)                                                               # Écrit le fichier
#
#   message(".Renviron créé")                                                   # Confirmation création
# } else {
#   message(".Renviron déjà présent")                                           # Fichier existant
# }


# ------------------------------------------------------------------------------
# Vérification d’un proxy
# ------------------------------------------------------------------------------
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
# Installation des packages utiles au développement
# ------------------------------------------------------------------------------
dev_pkgs <- c("usethis", "devtools", "lintr", "roxygen2", "desc", "rstudioapi") # Liste packages dev

to_install <- dev_pkgs[!dev_pkgs %in% installed.packages()[, "Package"]]        # Packages manquants

if (length(to_install) > 0) {                                                   # Vérifie si des packages manquent
  install.packages(to_install)                                                  # Installe les packages
  message("Packages développeur installés : ", paste(to_install, collapse = ", "))  # Confirme installation
} else {
  message("Tous les packages développeur sont déjà installés")                  # Rien à installer
}


# ------------------------------------------------------------------------------
# Création du projet R (DESCRIPTION)
# ------------------------------------------------------------------------------
if (!file.exists("DESCRIPTION")) {                                              # Vérifie présence DESCRIPTION
  usethis::create_package(getwd(), fields = list(
    Title = "BSecheresse",                                                      # Titre du package
    Description = "Outil de génération de bulletins sécheresse au format pdf et html.",  # Description
    Author = "MJ MARTINAT",                                                     # Auteur
    Maintainer = "Aurélie WILD <aurelie.wild@drome.gouv.fr>",                   # Mainteneur
    Version = "0.0.1"                                                           # Version initiale
  ))
  message("DESCRIPTION créé")                                                   # Confirmation création
} else {
  message("DESCRIPTION déjà présent")                                           # DESCRIPTION existant
}


# ------------------------------------------------------------------------------
# Passage automatique à 02_dev.R
# ------------------------------------------------------------------------------
path_next <- file.path(getwd(), "dev", "02_dev.R")                              # Chemin script 02

if (file.exists(path_next)) {                                                   # Vérifie si script présent
  message("Passage au script 02_dev.R")                                         # Message
  rstudioapi::navigateToFile(path_next)                                         # Ouvre script suivant
} else {
  message("Script 02_dev.R introuvable : vérifier le dossier dev")              # Avertissement absence fichier
}

message("SCRIPT 01 TERMINE")                                                    # Fin du script


# ------------------------------------------------------------------------------
# FIN DU SCRIPT 01_start.R
# ------------------------------------------------------------------------------
