# ------------------------------------------------------------------------------
# SCRIPT 06_repare_chemin_images.R : CORRECTION CHEMIN DES IMAGES LaTeX
# ------------------------------------------------------------------------------
# Auteur       : MJMartinat
# Structure    : DDT de la Drôme
# Date         : 2025-12-29
# ------------------------------------------------------------------------------
# DESCRIPTION  : Corrige l'erreur LaTeX "Unable to load picture marianne.png"
#                en recalant la directive \\graphicspath dans header.tex
#                - Ouvre fichiers/tex/header.tex
#                - Localise la ligne \\graphicspath
#                - Remplace par un chemin relatif compatible avec le répertoire
#                  de compilation (sorties/bulletins/pdf)
#                - Sauvegarde le fichier modifié + logs AVANT/APRÈS
# VERSION      : 1.0
# DÉPENDANCES  : here, base R
# ------------------------------------------------------------------------------

cat("\n")                                                                       # Saut de ligne console
cat("-----------------------------------------------------------------\n")      # Ligne décorative
cat("  CORRECTION : Chemin des images LaTeX\n")                                 # Titre console
cat("-----------------------------------------------------------------\n\n")    # Ligne décorative


# ------------------------------------------------------------------------------
# Chargement dépendances
# ------------------------------------------------------------------------------
library(here)                                                                   # Gestion chemins projet (portable)


# ------------------------------------------------------------------------------
# Initialisation
# ------------------------------------------------------------------------------
header_file <- here::here("fichiers", "tex", "header.tex")                      # Chemin du header LaTeX


# ------------------------------------------------------------------------------
# Vérification des prérequis
# ------------------------------------------------------------------------------
if (!file.exists(header_file)) {                                                # Vérifie existence fichier
  cat("Fichier header.tex introuvable:", header_file, "\n")                     # Log erreur
  stop("Fichier non trouvé", call. = FALSE)                                     # Stop propre
}

cat("Fichier à modifier:", header_file, "\n\n")                                 # Log cible


# ------------------------------------------------------------------------------
# Lecture du fichier et diagnostic
# ------------------------------------------------------------------------------
content <- readLines(header_file, warn = FALSE)                                 # Lecture contenu header.tex

cat("Recherche du problème...\n\n")                                             # Log diagnostic

modified <- FALSE                                                               # Flag modification effectuée


# ------------------------------------------------------------------------------
# Application de la correction
# ------------------------------------------------------------------------------
for (i in seq_along(content)) {                                                 # Parcourt toutes les lignes
  if (grepl("\\\\graphicspath", content[i])) {                                  # Détecte la directive \\graphicspath
    old_line <- content[i]                                                      # Sauvegarde de la ligne originale

    if (grepl("\\.\\./\\.\\./\\.\\.\\./fichiers", content[i])) {                # Test : chemin déjà au bon format ../../../fichiers
      cat("Le chemin est déjà correct\n")                                       # Log : pas d'action
      cat("   ", trimws(content[i]), "\n\n")                                    # Affiche la ligne existante
      stop("Aucune modification nécessaire", call. = FALSE)                     # Stop volontaire
    }

    content[i] <- "\\graphicspath{{../../../fichiers/tex/logo/}{../../../fichiers/images/}}" # Correction chemin relatif

    cat("Problème trouvé et corrigé à la ligne", i, "\n\n")                     # Log ligne modifiée
    cat("AVANT:\n")                                                             # Bloc avant
    cat("  ", trimws(old_line), "\n\n")                                         # Ligne avant
    cat("APRÈS:\n")                                                             # Bloc après
    cat("  ", trimws(content[i]), "\n\n")                                       # Ligne après

    modified <- TRUE                                                            # Marque modification
    break                                                                       # Sort de la boucle (une seule occurrence attendue)
  }
}

if (!modified) {                                                                # Si \\graphicspath introuvable
  cat("Ligne \\graphicspath non trouvée\n")                                 # Log avertissement
  stop("Impossible de trouver la ligne à modifier", call. = FALSE)              # Stop propre
}


# ------------------------------------------------------------------------------
# Sauvegarde
# ------------------------------------------------------------------------------
writeLines(content, header_file)                                                # Sauvegarde header.tex modifié


# ------------------------------------------------------------------------------
# Messages de fin
# ------------------------------------------------------------------------------
cat("-----------------------------------------------------------------\n")      # Bandeau succès
cat("     CORRECTION RÉUSSIE\n")                                                # Titre succès
cat("-----------------------------------------------------------------\n\n")    # Fin bandeau

cat("EXPLICATION:\n\n")                                                      # Titre explication
cat("Le PDF est généré dans: sorties/bulletins/pdf/\n")                         # Répertoire compilation
cat("Les images sont dans:   fichiers/tex/logo/\n\n")                           # Répertoire images
cat("Pour aller de sorties/bulletins/pdf/ vers fichiers/tex/logo/:\n")          # Explication chemin relatif
cat("  ../../../ (remonter 3 niveaux) puis fichiers/tex/logo/\n\n")             # Détail ../../../
cat("Le LaTeX peut maintenant trouver marianne.png\n\n")                        # Résultat attendu

cat("-----------------------------------------------------------------\n")      # Bandeau next step
cat("     PROCHAINE ÉTAPE\n")                                                   # Titre next step
cat("-----------------------------------------------------------------\n\n")    # Fin bandeau

cat("Générez maintenant le bulletin:\n\n")                                      # Instruction
cat("  source('dev/05_create_bulletin.R')\n\n")                                 # Commande

cat("Si vous avez toujours une erreur de police Marianne:\n\n")                 # Suggestion fallback
cat("  source('fix_font_arial.R')\n")                                           # Script police
cat("  source('dev/05_create_bulletin.R')\n\n")                                 # Rebuild

cat("-----------------------------------------------------------------\n\n")    # Footer final


# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT 06_repare_chemin_images.R
# ──────────────────────────────────────────────────────────────────────────────
