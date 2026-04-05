# ──────────────────────────────────────────────────────────────────────────────
# Script      : dev/05_deploy.R
# Auteur      : Marie-Jeanne MARTINAT
# Structure   : Direction Départementale des Territoires de la Drome (DDT)
# Date        : 2025
# Description : Deploiement de l'application Shiny {golem} "cartOLD"
#               sur shinyapps.io (compte ministériel)
#               - Chargement des variables d environnement depuis le fichier
#                 .Renviron (identifiants de connexion, config de proxy).
#               - Verification de la configuration du proxy ministeriel pour
#                 assurer la connexion a shinyapps.io.
#               - Installation des packages nécessaires si absents (rsconnect,
#                 devtools, golem).
#               - Verification de la structure du package golem avant déploiement
#                 (fichiers DESCRIPTION, NAMESPACE, etc.).
#               - Verification des identifiants requis pour acceder a
#                 shinyapps.io (SHINYAPPS_NAME, SHINYAPPS_TOKEN, SHINYAPPS_SECRET).
#               - Verification des fichiers critiques essentiels au bon
#                 fonctionnement de l application.
#               - Construction d'une liste explicite de tous les fichiers a
#                 deployer, évitant les fichiers inutiles.
#               - Estimation de la taille totale des fichiers a deployer et
#                 avertissement en cas de dépassement des limites de
#                 shinyapps.io.
#               - Deploiement de l application sur shinyapps.io et mise a
#                 jour de l interface en ligne.
# ──────────────────────────────────────────────────────────────────────────────
# CHARGEMENT ENVIRONNEMENT & VERIFICATIONS PRELIMINAIRES
# ────────────────────────────────────────────────────────────────────────
# ── Chargement des variables d'environnement ────────────────────────────
# Le fichier .Renviron contient les identifiants shinyapps.io et config proxy
# Ces variables sont sensibles et ne doivent JAMAIS être versionnées dans Git
if (!file.exists(".Renviron")) {
  stop("ERREUR : Fichier .Renviron manquant")
}
readRenviron(".Renviron")                                                       # Charge les variables dans l'environnement R

# ── Vérification du proxy (contexte ministériel) ────────────────────────
# Dans les DDT/DREAL, connexion internet obligatoirement via proxy
# Sans proxy configuré, impossible de contacter shinyapps.io
if (nzchar(Sys.getenv("HTTPS_PROXY")) || nzchar(Sys.getenv("HTTP_PROXY"))) {
  message("INFO : Proxy détecté et configuré")
} else {
  warning("ATTENTION : Aucun proxy défini - risque d'échec de connexion à shinyapps.io")
}

# ── Installation des dependances si nécessaire ───────────────────────────
# Enregistrement des packages dans une variable
pkgs <- c("rsconnect",                                                          # Communication avec shinyapps.io
          "desc",                                                               # CrEation et Gestion de Fichiers DESCRIPTION
          "golem",                                                              # Framework de l'application
          "devtools")                                                           # Verification de la structure du package golem

# Enregistrement des packages manquants dans une variable
to_install <- pkgs[!pkgs %in% installed.packages()[, 1]]                        # Identification des packages manquants

# Verification que tous les packages necessaires au deploiement sont installes sinon installation
if (length(to_install) > 0) {
  message("INFO : Installation des packages manquants : ", paste(to_install, collapse = ", "))
  install.packages(to_install)
}

# Activation des packages/librairies
library(rsconnect)                                                              # Deploiement sur shinyapps.io
library(devtools)                                                               # Vreification du package
library(golem)                                                                  # Support framework golem

# ────────────────────────────────────────────────────────────────────────
# VERIFICATION DU PACKAGE
# ────────────────────────────────────────────────────────────────────────
# ── Avant déploiement, vérifie que le package golem est valide
#    Contrôle : DESCRIPTION, NAMESPACE, structure des fichiers R, etc.
#    Bonne pratique recommandée par les DDT pour éviter erreurs
#    en production ───────────────────────────────────────────────────────
message("INFO : Vérification de la structure du package golem...")              # Message d information au demarrage
devtools::check()                                                               # Lance R CMD check
message("SUCCES : Vérification terminée sans erreur\n")                         # Message d information de fin

# ────────────────────────────────────────────────────────────────────────
# VERIFICATION DES IDENTIFIANTS SHINYAPPS.IO
# ────────────────────────────────────────────────────────────────────────
# ── Trois variables obligatoires pour s authentifier sur shinyapps.io ───
# Enregistrement des variables dans une variable
required_vars <- c("SHINYAPPS_NAME",                                            # Nom du compte (ex: "ddt-drome")
                   "SHINYAPPS_TOKEN",                                           # Jeton d authentification
                   "SHINYAPPS_SECRET"                                           # Cle secrete associee
                   )
# Enregistrement des variables manquantes dans une variable
missing <- required_vars[!nzchar(Sys.getenv(required_vars))]                    # Detection des variables vides

# Verification que toutes les variables necessaires au deploiement sont presentes sinon avertissement
if (length(missing) > 0) {
  stop("ERREUR : Variables d'environnement manquantes dans .Renviron : ",
       paste(missing, collapse = ", "))                                         # Message d information d erreur
}
message("SUCCES : Identifiants shinyapps.io détectés et valides\n")             # Message d information de reussite

# ────────────────────────────────────────────────────────────────────────
# VERIFICATION DES FICHIERS CRITIQUES
# ────────────────────────────────────────────────────────────────────────
# ── Verifie la presence des fichiers indispensables au fonctionnement de l app
# Sans ces fichiers, le deploiement echouera ou l app ne s affichera pas ─
# Enregistrement des fichiers dans une variable
fichiers_critiques <- c(
  "app.R",                                                                      # Point d entree Shiny
  "DESCRIPTION",                                                                # Metadonnees du package (dependances)
  "NAMESPACE",                                                                  # Exports de fonctions
  "inst/golem-config.yml",                                                      # Configuration golem (environnements)
  "inst/app/www/css/style.css",                                                 # Feuille de styles CSS
  "inst/app/www/js/script.js"                                                   # Scripts JavaScript
)

# Enregistrement des fichiers manquants dans une variable
manquants <- c()
for (f in fichiers_critiques) {
  if (!file.exists(f)) {
    manquants <- c(manquants, f)
    cat("[MANQUANT]", f, "\n")                                                  # Fichier critique absent
  } else {
    cat("[OK]      ", f, "\n")                                                  # Fichier trouvé
  }
}

# Verification que tous les fichiers necessaires au deploiement sont presents sinon avertissement
if (length(manquants) > 0) {
  stop("\nERREUR : Fichiers critiques manquants. Déploiement impossible.")      # Message d information d erreur
}
cat("\n")

# ────────────────────────────────────────────────────────────────────────
# LISTE COMPLETE DES FICHIERS A DEPLOYER
# ────────────────────────────────────────────────────────────────────────
# ── Construction de la liste de tous les fichiers a envoyer sur shinyapps.io
#    Stratégie : spécifier manuellement pour eviter d envoyer des fichiers
#    inutiles (fichiers temporaires, .git, .Rproj.user, etc.) ────────────
message("INFO : Préparation de la liste des fichiers à déployer...\n")           # Message d information au demarrage

# ── Fichiers de base ────────────────────────────────────────────────────
# Fichiers racine indispensables pour que shinyapps.io reconnaisse l'app
fichiers <- c(
  "app.R",                                                                      # Point d entree de l application
  "DESCRIPTION",                                                                # Liste des dependances R
  "NAMESPACE"                                                                   # Definition des exports
)


# ── Code R (tout le dossier) ────────────────────────────────────────────
# Tous les fichiers .R contenant les modules, fonctions utilitaires, etc.
fichiers <- c(
  fichiers,                                                                     # Conservation des fichiers deja listes
  list.files("R",                                                               # Scan du dossier R/
             full.names = TRUE,                                                 # Chemin complet necessaire
             recursive = TRUE)                                                  # Inclusion des sous-dossiers
)

# ── Configuration golem ──────────────────────────────────────────────────
# Fichier YAML définissant les paramètres selon l'environnement (dev/prod)
fichiers <- c(
  fichiers,                                                                     # Conservation des fichiers deja listes
  "inst/golem-config.yml"                                                       # Configuration golem
)

# ── Donnees GeoParquet (fichiers uniques) ────────────────────────────────
# Fichiers geographiques charges au demarrage de l application
fichiers <- c(fichiers,
              "inst/app/extdata/departement.parquet",                           # donnees departementales au format parquet
              "inst/app/extdata/communes.parquet",                              # donnees communales au format parquet
              "inst/app/extdata/old200.parquet",                                # donnees des massifs forestiers + les 200m (zones a risques)
              "inst/app/extdata/communes_old200.parquet")                       # donnees communales touchees par les zones a risques

# ── Donnees par commune (tous les .parquet) ───────────────────────────────
# Fichiers GeoParquet decoupes par commune pour chargement progressif
# Evite de charger 640K parcelles et 200K batiments d un coup (gain memoire)
# - parcelles : données cadastrales
# - batis     : bâtiments
# - old50m    : OLD dans un rayon de 50m
# - zu        : zones urbaines
for (couche in c("parcelles", "batis", "old50m", "zu")) {
  dir_couche <- file.path("inst/app/extdata", couche)                           # Construction du chemin vers chaque sous-dossier

  if (dir.exists(dir_couche)) {                                                 # Verification que le dossier existe (evite les erreurs)
    fichiers_couche <- list.files(dir_couche,
                                  pattern = "\\.parquet$",                      # Seulement les .parquet (exclut .txt, etc.)
                                  full.names = TRUE)                            # Chemin complet necessaire pour deployApp()
    fichiers <- c(fichiers, fichiers_couche)                                    # Ajout a la liste globale de deploiement
    cat(sprintf("  - %s : %d fichier(s)\n",
                couche,
                length(fichiers_couche)))                                       # Affichage du comptage pour suivi
  }
}

# ── Ressources www/ (CSS, JS, images, fonts...) ───────────────────────────
# Tous les fichiers statiques necessaires a l interface utilisateur
# CRITIQUE : sans ces fichiers, l app s affiche mal (erreurs MIME type
# sur shinyapps.io)
www_dirs <- c(
  "css",                                                                        # dossier pour les fichiers de styles css personnalises
  "js",                                                                         # dossier pour les fichiers js personnalises
  "html",                                                                       # dossier pour les fichiers html (pages statiques)
  "icones",                                                                     # dossier pour les icones au format .ico
  "images",                                                                     # dossier pour les images et logos (png, jpg,...)
  "fonts"                                                                       # dossier pour les polices
)

for (d in www_dirs) {
  dir_path <- file.path("inst/app/www", d)                                      # Construction du chemin vers chaque sous-dossier

  if (dir.exists(dir_path)) {                                                   # Verification de l existence (certains dossiers optionnels)
    fichiers_www <- list.files(dir_path,
                               full.names = TRUE,                               # Chemin complet obligatoire pour deployApp()
                               recursive = TRUE)                                # Inclusion des sous-dossiers (ex: fonts/woff2/)
    fichiers <- c(fichiers, fichiers_www)                                       # Ajout à la liste globale de déploiement
    cat(sprintf("  - www/%s : %d fichier(s)\n",
                d,
                length(fichiers_www)))                                          # Affichage du comptage pour suivi
  }
}

cat(sprintf("\nSUCCES : %d fichier(s) prêts pour le déploiement\n\n",
            length(fichiers)))                                                  # Message d information avec l affiche du comptage final

# ────────────────────────────────────────────────────────────────────────
# ESTIMATION DE LA TAILLE
# ────────────────────────────────────────────────────────────────────────
# ── Calcul de la taille totale des fichiers a deployer ──────────────────
# Limite shinyapps.io : 1 GB pour compte gratuit, 5 GB pour compte payant
taille_totale <- sum(sapply(fichiers, function(f) {
  if (file.exists(f) && !file.info(f)$isdir) {                                  # Ignore les dossiers
    file.size(f)                                                                # Taille en octets
  } else {
    0
  }
})) / 1024^2                                                                    # Conversion en MB

cat(sprintf("INFO : Taille totale du déploiement : %.2f MB\n\n", taille_totale)) # Message d information sur la taille totale

# ── Avertissement si la taille depasse la limite du compte gratuit ─────
if (taille_totale > 1000) {
  warning("ATTENTION : Taille > 1 GB (limite compte gratuit shinyapps.io)")     # Message d avertissement sur la taille totale

  warning("Vérifier que le compte ministériel dispose d'un abonnement payant")  # Message d avertissement sur l abonnement à shinyapps.io

  reponse <- readline("Continuer quand même ? (o/n) : ")                        # Enregistrement de la question dans une variable

  if (tolower(reponse) != "o") {
    stop("Déploiement annulé par l'utilisateur")                                # Message d annulation par l utilisateur
  }
}

# ────────────────────────────────────────────────────────────────────────
# DÉPLOIEMENT SUR SHINYAPPS.IO
# ────────────────────────────────────────────────────────────────────────
# ── Lancement du déploiement via rsconnect ──────────────────────────────
# Le processus inclut : upload des fichiers, installation des dépendances R,
# compilation de l'app, mise en ligne
message("INFO : Démarrage du déploiement sur shinyapps.io...")                  # Message d information au demarrage
message("       (Cela peut prendre plusieurs minutes selon la taille)")         # Message d information au demarrage
message("       (Ne pas interrompre le processus)\n")                           # Message d information au demarrage

rsconnect::deployApp(
  appDir = ".",                                                                 # Repertoire racine du projet
  appFiles = fichiers,                                                          # Liste explicite (evite fichiers inutiles)
  appName = "cartOLD",                                                          # Nom de l app sur shinyapps.io
  forceUpdate = TRUE,                                                           # Force mise a jour si app existe deja
  launch.browser = TRUE                                                         # Ouvre navigateur automatiquement apres deploiement
)

cat("\n")
cat(" ──────────────────────────────────────────────────────────────────── \n") # Message d information a la fin du deploiement
cat("                      DÉPLOIEMENT TERMINÉ                             \n") # Message d information a la fin du deploiement
cat(" ──────────────────────────────────────────────────────────────────── \n") # Message d information a la fin du deploiement
cat("\n")
cat("L'application cartOLD est maintenant accessible en ligne.\n")              # Message d information a la fin du deploiement
cat("URL : https://ssm-ecologie.shinyapps.io/cartOLD\n")                        # Message d information a la fin du deploiement
cat("\n")

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT
# ──────────────────────────────────────────────────────────────────────────────
