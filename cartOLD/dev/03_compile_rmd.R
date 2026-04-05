# ──────────────────────────────────────────────────────────────────────────────
# SCRIPT      : dev/03_compile_rmd.R
# AUTEUR      : Marie-Jeanne MARTINAT
# ORGANISME   : Direction Departementale des Territoires de la Drome (DDT)
# DATE        : 2025
# DESCRIPTION : Compilation des fichiers Rmd en HTML pour l application cartOLD
#               Ce script convertit les pages statiques (Rmd) en HTML et les
#               place dans inst/app/www/html pour integration dans l’interface
#               Shiny.
#               - Installation et chargement des librairies necessaires :
#                 - rmarkdown : pour la compilation des fichiers Rmd en HTML.
#                 - fs : gestion de fichiers et dossiers pour des operations futures.
#                 - rstudioapi : pour automatiser l ouverture du script suivant.
#               - Liste des fichiers à compiler :
#                 - avertissement
#                 - accueil
#                 - aide
#                 - mentions legales
#                 - confidentialite
#               - Creation d un repertoire de sortie pour les fichiers HTML, en
#                 nettoyant le dossier precedent s il existe.
#               - Boucle de compilation pour chaque fichier Rmd, avec gestion
#                 des erreurs pour assurer la robustesse.
#               - Navigation vers le script suivant après compilation.
# ──────────────────────────────────────────────────────────────────────────────
# LIBRAIRIES NECESSAIRES
# ──────────────────────────────────────────────────────────────
# ── Enregistrement des packages dans une variable ─────────────
required_packages <- c(
  "rmarkdown",                                                                  # Generation des  rapports/documentation
  "fs",                                                                         # Gestion des fichiers/dossiers (si besoin futur)
  "rstudioapi"                                                                  # Gestion des fonctionnalités de RStudio
)

# ── Installation et chargement des packages necessaires ───────
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)                                  # Si un des packages est manquant, installation
  }
  library(pkg, character.only = TRUE)                                           # Chargement du package
}

# ──────────────────────────────────────────────────────────────
# LISTE DES FICHIERS A COMPILER EN RMD
# ──────────────────────────────────────────────────────────────
# ── Enregistrement des fichiers dans une variable ─────────────
rmd_list <- c("avertissement",
              "accueil",
              "aide",
              "mentions_legales",
              "confidentialite")                                                # Ajout/retrait des fichiers au besoin

# ──────────────────────────────────────────────────────────────
# PREPARATION DU REPERTOIRE DE SORTIE
# ──────────────────────────────────────────────────────────────
# ── Enregistrement du chemin d'enregistrement dans une
#    variable ──────────────────────────────────────────────────
html_dir <- "inst/app/www/html"                                                 # Repertoire de sortie des fichiers HTML

# ── Vérifie si le dossier existe et le supprime avant de
#    recreer un dossier propre ─────────────────────────────────
if (dir.exists(html_dir)) {
  unlink(html_dir, recursive = TRUE)                                            # Suppression du dossier s il existe deja (nettoyage)
}

dir.create(html_dir, recursive = TRUE, showWarnings = FALSE)                    # Creation du dossier de sortie (vide)

# ──────────────────────────────────────────────────────────────
# BOUCLE POUR LA COMPILATION DES RMD EN HTML
# ──────────────────────────────────────────────────────────────
# ── Boucle sur chaque fichier Rmd de la liste ─────────────────
for (name in rmd_list) {

  rmd_file  <- file.path("dev/rmd", paste0(name, ".Rmd"))                       # Enregistrement dans une variable du chemin d acces au fichier Rmd source
  html_file <- file.path(html_dir, paste0(name, ".html"))                       # Enregistrement dans une variable du chemin d acces au fichier HTML de sortie

  if (file.exists(rmd_file)) {                                                  # Verification de l'existence des fichiers Rmd
    message("Compilation : ", rmd_file)                                         # Affichage d un message de progression
    tryCatch({
      rmarkdown::render(                                                        # Compilation du fichier Rmd en HTML
        input       = rmd_file,                                                 # Chemin du fichier source .Rmd
        output_file = basename(html_file),                                      # Nom du fichier HTML de sortie
        output_dir  = dirname(html_file),                                       # Repertoire de sortie
        quiet       = TRUE                                                      # Mode silencieux (pas de logs détailles)
      )
    }, error = function(e) {                                                    # Gestion d'erreurs pour rendre le processus plus robuste
      message("Erreur lors de la compilation de ", rmd_file)
      message("Message d'erreur : ", e$message)
    })
  } else {
    warning("Fichier Rmd introuvable : ", rmd_file)                             # Alerte si le fichier Rmd est manquant
  }
}

# ──────────────────────────────────────────────────────────────
# ETAPE SUIVANTE
# ──────────────────────────────────────────────────────────────
# ── Ouverture automatiquement du script de transformation des
#    Rmd ───────────────────────────────────────────────────────
rstudioapi::navigateToFile("dev/04_fix_non_ascii.R", line = 1)                  # Ouverture le script de déploiement

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT 03_compile_rmd.R
# ──────────────────────────────────────────────────────────────────────────────
