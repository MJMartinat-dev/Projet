# ------------------------------------------------------------------------------
# SCRIPT 04_install_renv.R - INITIALISATION ET CONFIGURATION renv
# ------------------------------------------------------------------------------
# Auteur    : MJMartinat
# Structure : DDT de la Drôme
# Date      : 2025
# ------------------------------------------------------------------------------
# Objectifs :
# - Initialiser renv si absent
# - Restaurer l’environnement s’il existe
# - Forcer un snapshot cohérent après installation des dépendances
# - Garantir la reproductibilité complète du projet (DDT Drôme)
# ------------------------------------------------------------------------------

message("DEBUT DU SCRIPT 04 : CONFIGURATION ET SYNCHRONISATION renv")           # Démarre le script renv


# ------------------------------------------------------------------------------
# Vérification .Renviron et proxy
# ------------------------------------------------------------------------------
if (!file.exists(".Renviron"))                                                  # Vérifie présence .Renviron
  stop(".Renviron est manquant, exécuter d'abord 01_start.R")                   # Stoppe si absent

HTTP_PROXY  <- Sys.getenv("http_proxy")                                         # Lit proxy HTTP
HTTPS_PROXY <- Sys.getenv("https_proxy")                                        # Lit proxy HTTPS
FTP_PROXY   <- Sys.getenv("ftp_proxy")                                          # Lit proxy FTP

if (HTTP_PROXY != "")  message("Proxy HTTP détecté : ", HTTP_PROXY)             # Affiche proxy HTTP si défini
if (HTTPS_PROXY != "") message("Proxy HTTPS détecté : ", HTTPS_PROXY)           # Affiche proxy HTTPS si défini
if (FTP_PROXY != "")   message("Proxy FTP détecté : ", FTP_PROXY)               # Affiche proxy FTP si défini


# ------------------------------------------------------------------------------
# Chargement du package renv
# ------------------------------------------------------------------------------
if (!"renv" %in% installed.packages()[, "Package"]) {                           # Vérifie si renv est installé
  install.packages("renv")                                                      # Installe renv si absent
  message("renv installé (installation automatique)")                           # Confirmation installation
}

library(renv)                                                                   # Charge renv


# ------------------------------------------------------------------------------
# Initialisation renv SI ABSENT, sinon restauration
# ------------------------------------------------------------------------------
if (!file.exists("renv.lock")) {                                                # Vérifie existence renv.lock
  message("Aucun renv.lock détecté → initialisation d’un nouvel environnement") # Message init
  renv::init(bare = FALSE)                                                      # Initialise renv avec état courant
  message("Initialisation renv terminée")                                       # Confirmation init
} else {
  message("renv.lock détecté → restauration de l’environnement")                # Message restauration
  renv::restore(prompt = FALSE)                                                 # Restaure sans demander
  message("Restauration renv terminée")                                         # Confirmation restauration
}


# ------------------------------------------------------------------------------
# Synchronisation complète des dépendances projet
# ------------------------------------------------------------------------------
message("Snapshot des dépendances → mise à jour renv.lock")                     # Contexte snapshot

tryCatch({
  renv::snapshot(prompt = FALSE)                                                # Snapshot silencieux
  message("Snapshot terminé : renv.lock mis à jour")                            # Confirmation snapshot
}, error = function(e) {
  message("Erreur snapshot renv : ", e$message)                                 # Gestion erreur
})


# ------------------------------------------------------------------------------
# Diagnostic final renv
# ------------------------------------------------------------------------------
message("Diagnostic rapide renv :")                                             # Indique diagnostic
try(renv::status(), silent = TRUE)                                              # Affiche l’état renv


# ------------------------------------------------------------------------------
# Passage automatique au script suivant si existant
# ------------------------------------------------------------------------------
next_script <- file.path(getwd(), "dev", "05_create_bulletin.R")                # Prochain script éventuel

if (file.exists(next_script)) {                                                 # Vérifie script suivant
  message("Passage au script 05_create_bulletin.R")                             # Indique la transition
  try(rstudioapi::navigateToFile(next_script), silent = TRUE)                   # Ouvre dans RStudio si dispo
} else {
  message("Aucun script suivant trouvé (fin de la chaîne renv)")                # Aucun script trouvé
}

message("SCRIPT 04 TERMINE")                                                    # Fin du script


# ------------------------------------------------------------------------------
# FIN DU SCRIPT 04_INSTALL_RENV.R
# ------------------------------------------------------------------------------

