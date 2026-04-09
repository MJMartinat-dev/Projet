# ------------------------------------------------------------------------------
# SCRIPT 03_repare_chemin_tinytex.R : CONFIGURATION TEMPORAIRE DU PATH TinyTeX
# ------------------------------------------------------------------------------
# Auteur       : MJMartinat
# Structure    : DDT de la Drôme
# Date         : 2025-12-29
# ------------------------------------------------------------------------------
# DESCRIPTION  : Configure temporairement le PATH pour rendre TinyTeX visible
#                dans la session R courante (résolution "xelatex introuvable")
#                - Détecte TinyTeX via le package {tinytex}
#                - Construit le chemin binaire selon l’OS
#                - Vérifie la présence de xelatex avant/après
#                - Ajoute le dossier bin TinyTeX au PATH (session uniquement)
# VERSION      : 1.0
# DÉPENDANCES  : here (optionnel), tinytex, base R
# ------------------------------------------------------------------------------

cat("\n")                                                                       # Saut de ligne console
cat("----------------------------------------------------------------------\n") # Ligne décorative
cat("  CONFIGURATION DU PATH TINYTEX\n")                                        # Titre console
cat("--------------------------------------------------------------------\n\n") # Ligne décorative


# ------------------------------------------------------------------------------
# Vérification de tinytex
# ------------------------------------------------------------------------------
cat("Recherche de TinyTeX...\n")                                                # Log étape 1

tinytex_found <- FALSE                                                          # Flag TinyTeX détecté
tinytex_bin_path <- NULL                                                        # Chemin binaire TinyTeX (bin/*)

# Méthode 1: Via le package tinytex
if (requireNamespace("tinytex", quietly = TRUE)) {                              # Test présence {tinytex}
  cat("Package tinytex installé\n")                                             # Log OK

  if (tinytex:::is_tinytex()) {                                                 # Test TinyTeX réellement installé
    cat("TinyTeX est installé\n")                                               # Log OK

    tryCatch({                                                                  # Capture erreurs détection root/bin
      root <- tinytex::tinytex_root()                                           # Récupère racine TinyTeX
      cat("TinyTeX root:", root, "\n")                                          # Log root

      # Construire le chemin vers bin
      if (.Platform$OS.type == "windows") {                                     # Cas Windows
        tinytex_bin_path <- file.path(root, "bin", "windows")                   # Bin Windows
      } else if (Sys.info()["sysname"] == "Darwin") {                           # Cas macOS
        tinytex_bin_path <- file.path(root, "bin", "universal-darwin")          # Bin macOS
      } else {                                                                  # Cas Linux
        tinytex_bin_path <- file.path(root, "bin", "x86_64-linux")              # Bin Linux
      }

      if (dir.exists(tinytex_bin_path)) {                                       # Vérifie existence dossier bin
        cat("Chemin bin trouvé:", tinytex_bin_path, "\n")                       # Log OK
        tinytex_found <- TRUE                                                   # Flag TinyTeX trouvé
      } else {                                                                  # Sinon
        cat("Chemin bin introuvable:", tinytex_bin_path, "\n")                  # Log KO
      }

    }, error = function(e) {                                                    # Gestion erreur
      cat("Erreur lors de la détection de TinyTeX:", e$message, "\n")           # Log erreur
    })
  } else {                                                                      # Si TinyTeX non installé
    cat("TinyTeX n'est pas installé\n")                                         # Log KO
  }
} else {                                                                        # Si package {tinytex} absent
  cat("Package tinytex non installé\n")                                         # Log KO
  cat("Installez-le avec: install.packages('tinytex')\n")                       # Suggestion
}

cat("\n")                                                                       # Respiration console


# ------------------------------------------------------------------------------
# Vérification actuelle de xelatex
# ------------------------------------------------------------------------------
cat("Vérification actuelle de xelatex...\n")                                    # Log étape 2

xelatex_before <- Sys.which("xelatex")                                          # Recherche xelatex via PATH
if (xelatex_before != "") {                                                     # Si déjà accessible
  cat("xelatex déjà accessible:", xelatex_before, "\n")                         # Log OK
  cat("Aucune modification nécessaire\n\n")                                     # Info
  cat("---------------------------------------------------------------\n\n")    # Footer
  stop("xelatex est déjà accessible. Aucune action nécessaire.", call. = FALSE) # Stop volontaire
} else {                                                                        # Si non trouvé
  cat("xelatex non trouvé dans le PATH\n\n")                                    # Log KO
}


# ------------------------------------------------------------------------------
# Ajout du chemin
# ------------------------------------------------------------------------------
if (!tinytex_found) {                                                           # Si TinyTeX non détecté
  cat("IMPOSSIBLE DE CONFIGURER LE PATH\n")                                     # Log erreur
  cat("TinyTeX n'a pas été trouvé sur votre système.\n\n")                      # Détail

  cat("SOLUTIONS:\n")                                                           # Pistes
  cat("   Installez TinyTeX:\n")                                                # Solution 1
  cat("      install.packages('tinytex')\n")                                    # Commande
  cat("      tinytex::install_tinytex()\n\n")                                   # Commande

  cat("   Ou utilisez la version HTML uniquement:\n")                           # Solution 2
  cat("      source('dev/05_create_bulletin_html_only.R')\n\n")                 # Commande

  cat("---------------------------------------------------------------\n\n")    # Footer
  stop("TinyTeX introuvable", call. = FALSE)                                    # Stop propre
}

cat("Configuration du PATH...\n")                                               # Log étape 3

current_path <- Sys.getenv("PATH")                                              # Récupère PATH courant

if (.Platform$OS.type == "windows") {                                           # Cas Windows
  new_path <- paste(current_path, tinytex_bin_path, sep = ";")                  # Concat PATH (séparateur ;)
} else {                                                                        # Cas Unix
  new_path <- paste(current_path, tinytex_bin_path, sep = ":")                  # Concat PATH (séparateur :)
}

Sys.setenv(PATH = new_path)                                                     # Applique le PATH modifié (session R)

cat("Chemin TinyTeX ajouté au PATH\n\n")                                        # Log OK


# ------------------------------------------------------------------------------
# Vérification
# ------------------------------------------------------------------------------
cat("Vérification...\n")                                                        # Log étape 4

xelatex_after <- Sys.which("xelatex")                                           # Test xelatex après ajout PATH
if (xelatex_after != "") {                                                      # Si accessible
  cat("xelatex maintenant accessible:", xelatex_after, "\n\n")                  # Log OK

  cat("---------------------------------------------------------------\n")      # Bandeau succès
  cat("  SUCCÈS !\n")                                                           # Titre succès
  cat("---------------------------------------------------------------\n\n")    # Fin bandeau
  cat("XeLaTeX est maintenant accessible dans cette session R\n\n")             # Résumé
  cat("Vous pouvez maintenant générer le bulletin PDF:\n")                      # Next step
  cat("   source('dev/05_create_bulletin.R')\n\n")                              # Commande
  cat("IMPORTANT: Cette configuration est temporaire\n")                        # Avertissement
  cat("   Elle s'applique uniquement à cette session R.\n")                     # Portée
  cat("   Pour une solution permanente, consultez:\n")                          # Référence doc
  cat("   SOLUTION_TINYTEX.md (Solution 3: Configuration du PATH)\n\n")         # Piste
  cat("---------------------------------------------------------------\n\n")    # Footer

} else {                                                                        # Si toujours non accessible
  cat("xelatex toujours introuvable\n\n")                                       # Log KO

  cat("---------------------------------------------------------------\n")      # Bandeau échec
  cat("  ÉCHEC\n")                                                              # Titre échec
  cat("---------------------------------------------------------------\n\n")    # Fin bandeau
  cat("La configuration automatique a échoué\n\n")                              # Résumé

  cat("SOLUTIONS:\n")                                                           # Pistes
  cat("- Fermez et relancez RStudio EN TANT QU'ADMINISTRATEUR\n")               # Solution 1
  cat("- Redémarrez Windows\n")                                                 # Solution 2
  cat("- Consultez SOLUTION_TINYTEX.md pour d'autres solutions\n")              # Solution 3
  cat("- En attendant, utilisez la version HTML uniquement:\n")                 # Contournement
  cat("   source('dev/05_create_bulletin_html_only.R')\n\n")                    # Commande
  cat("---------------------------------------------------------------\n\n")    # Footer
}

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT 03_repare_chemin_tinytex.R
# ──────────────────────────────────────────────────────────────────────────────
