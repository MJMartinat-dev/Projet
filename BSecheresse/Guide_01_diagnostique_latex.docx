# ------------------------------------------------------------------------------
# SCRIPT 05_repare_police_arial.R : REMPLACEMENT POLICE MARIANNE → ARIAL
# ------------------------------------------------------------------------------
# Auteur       : MJMartinat
# Structure    : DDT de la Drôme
# Date         : 2025-12-29
# ------------------------------------------------------------------------------
# DESCRIPTION  : Remplace la police "Marianne" par "Arial" dans le Rmd
#                - Recherche la directive YAML mainfont
#                - Substitue Marianne par Arial
#                - Sauvegarde le fichier modifié
#                - Affiche un log détaillé des changements
# VERSION      : 1.0
# DÉPENDANCES  : here, base R
# ------------------------------------------------------------------------------

cat("\n")                                                                       # Saut de ligne console
cat("---------------------------------------------------------------\n")        # Ligne décorative
cat("  CORRECTION RAPIDE : POLICE MARIANNE → ARIAL\n")                          # Titre console
cat("---------------------------------------------------------------\n\n")      # Ligne décorative


# ------------------------------------------------------------------------------
# Chargement dépendances
# ------------------------------------------------------------------------------
library(here)                                                                   # Gestion chemins relatifs projet


# ------------------------------------------------------------------------------
# Paramétrage fichier cible
# ------------------------------------------------------------------------------
rmd_file <- here::here("fichiers", "Rmd", "bulletin_secheresse.Rmd")            # Chemin du Rmd à corriger

if (!file.exists(rmd_file)) {                                                   # Vérification existence fichier
  cat("Fichier Rmd introuvable:", rmd_file, "\n")                               # Log erreur
  stop("Fichier non trouvé", call. = FALSE)                                     # Stop propre
}

cat("Fichier à modifier:", rmd_file, "\n\n")                                    # Log chemin fichier


# ------------------------------------------------------------------------------
# Lecture du contenu
# ------------------------------------------------------------------------------
content <- readLines(rmd_file, warn = FALSE)                                    # Lecture ligne par ligne du Rmd


# ------------------------------------------------------------------------------
# Recherche et remplacement de la directive mainfont
# ------------------------------------------------------------------------------
modified <- FALSE                                                               # Flag modification effectuée

for (i in seq_along(content)) {                                                 # Parcours de toutes les lignes
  if (grepl('mainfont.*["\']Marianne["\']', content[i])) {                      # Détection mainfont Marianne
    old_line <- content[i]                                                      # Sauvegarde ligne originale
    content[i] <- 'mainfont: "Arial"'                                           # Remplacement par Arial
    cat("Ligne", i, "modifiée:\n")                                              # Log numéro ligne
    cat("   AVANT:", old_line, "\n")                                            # Log ancien contenu
    cat("   APRÈS:", content[i], "\n\n")                                        # Log nouveau contenu
    modified <- TRUE                                                            # Marque modification
    break                                                                       # Une seule modification attendue
  }
}

# ------------------------------------------------------------------------------
# Gestion cas où aucune modification effectuée
# ------------------------------------------------------------------------------
if (!modified) {                                                                # Si Marianne non trouvée
  cat("Ligne 'mainfont: Marianne' non trouvée\n")                               # Log avertissement
  cat("La police est peut-être déjà changée ou la ligne est différente\n\n")    # Détail

  font_lines <- grep("font", content, ignore.case = TRUE)                       # Recherche lignes contenant 'font'

  if (length(font_lines) > 0) {                                                 # Si lignes détectées
    cat("Lignes contenant 'font' trouvées:\n")                                  # Log info
    for (i in font_lines[1:min(5, length(font_lines))]) {                       # Limite affichage à 5 lignes
      cat(sprintf("[%d] %s\n", i, content[i]))                                  # Affichage lignes concernées
    }
    cat("\n")                                                                   # Saut de ligne
  }

  stop("Modification non effectuée", call. = FALSE)                             # Stop propre
}


# ------------------------------------------------------------------------------
# Sauvegarde du fichier modifié
# ------------------------------------------------------------------------------
writeLines(content, rmd_file)                                                   # Écriture fichier (overwrite)


# ------------------------------------------------------------------------------
# Bandeau succès
# ------------------------------------------------------------------------------
cat("---------------------------------------------------------------\n")        # Bandeau succès
cat("    MODIFICATION RÉUSSIE\n")                                               # Titre succès
cat("---------------------------------------------------------------\n\n")      # Fin bandeau

cat("La police Marianne a été remplacée par Arial.\n")                          # Résumé action
cat("Arial est une police standard Windows toujours disponible.\n\n")           # Justification technique

cat("PROCHAINE ÉTAPE:\n")                                                       # Instruction suivante
cat("Générez maintenant le bulletin:\n\n")                                      # Action
cat("  source('dev/05_create_bulletin.R')\n\n")                                 # Commande relance

cat("---------------------------------------------------------------\n\n")      # Footer final


# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT 05_repare_police_arial.R
# ──────────────────────────────────────────────────────────────────────────────
