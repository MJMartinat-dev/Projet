# ──────────────────────────────────────────────────────────────────────────────
# SCRIPT      : dev/04_fix_non_ascii.R
# AUTEUR      : Marie-Jeanne MARTINAT
# ORGANISME   : Direction Départementale des Territoires de la Drôme (DDT)
# DATE        : 2025
# OBJET       : Audit ASCII strict des fichiers .R
#               → Méthode officielle R via iconv() et tools::showNonASCII()
#               - Vérification de la conformité des fichiers .R en termes
#                 de caractères ASCII.
#               - Utilisation de la fonction iconv() pour tester la
#                 conversion des lignes, identifiant les caractères non-ASCII.
#               - Enregistrement des erreurs rencontrées dans un fichier
#                 log pour un suivi ultérieur.
#               - Gestion des lignes de documentation Roxygen pour éviter
#                 les faux positifs.
#               - Boucle principale parcourant tous les fichiers .R d'un
#                 dossier spécifié et ses sous-dossiers.
# ──────────────────────────────────────────────────────────────────────────────
# LIBRAIRIES NECESSAIRES
# ──────────────────────────────────────────────────────────────
# ── Enregistrement des packages dans une variable ─────────────
required_packages <- c(
  "rstudioapi",                                                                 # Navigation vers un autre fichier
  "tools"                                                                       # Outils pour le developpement, l'administration et la documentation
)

# ── Installation et chargement des packages nécessaires ───────
for (pkg in required_packages) {                                                # Boucle installation/chargement
  if (!requireNamespace(pkg, quietly = TRUE)) {                                 # Observation de l installation ou non des package
    install.packages(pkg, dependencies = TRUE)                                  # Si un des packages est manquant, installation
  }
  library(pkg, character.only = TRUE)                                           # Chargement du package
}


# ──────────────────────────────────────────────────────────────
# FONCTION : contrôle ASCII strict (méthode officielle R)
# ──────────────────────────────────────────────────────────────
check_non_ascii <- function(path = "R") {                                       # Dossier à analyser
  # ── Enregistrement des fichiers dans une variable ───────────
  files <- list.files(                                                          # Liste des fichiers .R
    path, "\\.R$", full.names = TRUE, recursive = TRUE
  )

  # ── Fichier de log pour enregistrer les erreurs ─────────────
  log_file <- "inst/dev/logs/non_ascii_errors.txt"
  if (file.exists(log_file)) file.remove(log_file)                              # Suppression du log precedent s il existe

  for (file in files) {                                                         # Boucle sur les fichiers

    lines <- readLines(                                                         # lecture UTF-8
      file, warn = FALSE, encoding = "UTF-8"
    )

    for (i in seq_along(lines)) {                                               # Boucle sur les lignes des fichiers
      line <- lines[i]                                                          # ligne courante

      if (grepl("^#'", line)) next                                              # Ignore la documentation roxygen

      # ── Test avant conversion pour s'assurer que le fichier est
      #    bien en UTF-8 ─────────────────────────────────────────
      if (!any(grepl("[^\x00-\x7F]", line))) next                               # Si aucune caractère non-ASCII, ne le prend pas en compte

      ascii_test <- iconv(                                                      # Conversion officielle ASCII
        line, from = "UTF-8", to = "ASCII", sub = NA
      )

      if (is.na(ascii_test)) {                                                  # NA = présence de non ASCII

        message("⚠ ", file, " : ligne ", i)                                     # Emplacement des caractères spéciaux
        message("   > ", line)                                                  # ligne fautive

        message("   ↳ Caractères non-ASCII détectés via iconv()")               # Message d informations officielles
        tools::showNonASCII(line)                                               # Affichage de la ligne R

        # ── Enregistrer dans un fichier de log ───────────────
        log_msg <- paste0(Sys.time(), " - ", file, " : ligne ", i, "\n", line, "\n\n") # Enregistrement des messages d erreurs (log) dans une variable
        write(log_msg, file = log_file, append = TRUE)                          # Ecriture du log (tous les messages d erreurs)
      }
    }
  }

  message("Analyse ASCII strict terminée (méthode officielle iconv/tools).")    # Message dinformation de fin d analyse
}

# ──────────────────────────────────────────────────────────────
# EXÉCUTION
# ──────────────────────────────────────────────────────────────
# ── Verification des fichiers du dossier "R" ──────────────────
check_non_ascii("R")                                                            # Audit du dossier R

# ──────────────────────────────────────────────────────────────
# ÉTAPE SUIVANTE
# ──────────────────────────────────────────────────────────────
# ── Ouverture automatiquement du script de transformation des
#    Rmd ───────────────────────────────────────────────────────
rstudioapi::navigateToFile("dev/05_deploy.R", line = 1)                         # Suite du workflow

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT 04_fix_non_ascii.R
# ──────────────────────────────────────────────────────────────────────────────
