# ------------------------------------------------------------------------------
# SCRIPT 04_repare_erreur_preambule.R : CORRECTION "Ne peut être utilisé que
# dans le préambule"
# ------------------------------------------------------------------------------
# Auteur       : MJMartinat
# Structure    : DDT de la Drôme
# Date         : 2025-12-29
# ------------------------------------------------------------------------------
# DESCRIPTION  : Corrige l’erreur LaTeX "Can be used only in preamble"
#                - Analyse le YAML du Rmd
#                - Détecte before_body: ../tex/main.tex
#                - Déplace main.tex vers in_header (préambule LaTeX)
#                - Sauvegarde le Rmd modifié
# VERSION      : 1.0
# DÉPENDANCES  : here, base R
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Bandeau console
# ------------------------------------------------------------------------------
cat("\n")                                                                       # Saut de ligne console
cat("═══════════════════════════════════════════════════════════════\n")        # Ligne décorative
cat("  CORRECTION : Can be used only in preamble\n")                            # Titre console
cat("═══════════════════════════════════════════════════════════════\n\n")      # Ligne décorative


# ------------------------------------------------------------------------------
# Chargement des dépendances
# ------------------------------------------------------------------------------
library(here)                                                                   # Chemins relatifs au projet


# ------------------------------------------------------------------------------
# Paramètres d’entrée
# ------------------------------------------------------------------------------
rmd_file <- here::here("fichiers", "Rmd", "bulletin_secheresse.Rmd")            # Chemin du Rmd cible

if (!file.exists(rmd_file)) {                                                   # Vérifie présence du fichier
  cat("Fichier Rmd introuvable:", rmd_file, "\n")                               # Log erreur
  stop("Fichier non trouvé", call. = FALSE)                                     # Stop propre
}

cat("Fichier à modifier:", rmd_file, "\n\n")                                    # Log fichier ciblé


# ------------------------------------------------------------------------------
# Lecture du contenu Rmd
# ------------------------------------------------------------------------------
content <- readLines(rmd_file, warn = FALSE)                                    # Lecture brute du Rmd (lignes)

cat("Recherche du problème...\n\n")                                             # Log début analyse


# ------------------------------------------------------------------------------
# Analyse du YAML : section pdf_document
# ------------------------------------------------------------------------------
in_pdf_section <- FALSE                                                         # Flag : actuellement dans pdf_document
pdf_start <- 0                                                                  # Index début section pdf_document
modified <- FALSE                                                               # Flag : modification effectuée

for (i in seq_along(content)) {                                                 # Parcourt toutes les lignes
  line <- content[i]                                                            # Ligne courante

  if (grepl("^\\s*pdf_document:", line)) {                                      # Détecte début bloc pdf_document
    in_pdf_section <- TRUE                                                      # Active le flag de section
    pdf_start <- i                                                              # Mémorise la ligne de départ
    next                                                                        # Passe à la ligne suivante
  }

  if (in_pdf_section) {                                                         # Si on est dans pdf_document

    if (grepl("^[a-z]", line) && !grepl("^\\s", line)) {                        # Détecte fin de bloc (nouvelle clé YAML top-level)
      in_pdf_section <- FALSE                                                   # Désactive le flag
    }

    if (grepl("before_body:.*main\\.tex", line)) {                              # Détecte main.tex injecté en before_body
      cat("Problème trouvé à la ligne", i, "\n")                                # Log ligne problème
      cat("   ", trimws(line), "\n\n")                                          # Log contenu ligne

      for (j in (i - 1):pdf_start) {                                            # Remonte vers le haut du bloc pdf_document
        if (grepl("in_header:", content[j])) {                                  # Cherche la directive in_header

          if (grepl("^\\s*in_header:\\s*$", content[j])) {                      # Cas 1 : in_header déjà au format liste YAML
            indent <- gsub("^(\\s*).*", "\\1", content[j + 1])                  # Récupère indentation d’un item existant
            content <- append(                                                  # Ajoute main.tex juste après le premier item
              content,
              paste0(indent, "  - ../tex/main.tex"),
              after = j + 1
            )
            content <- content[-(i + 1)]                                        # Supprime la ligne before_body (décalée après insertion)
            modified <- TRUE                                                    # Marque modification
          } else {                                                              # Cas 2 : in_header est sur une seule ligne (valeur inline)
            old_header <- gsub(".*in_header:\\s*(.*)\\s*", "\\1", content[j])   # Extrait la valeur existante (ex: ../tex/header.tex)
            indent <- gsub("^(\\s*).*", "\\1", content[j])                      # Récupère indentation de la clé
            content[j] <- paste0(indent, "in_header:")                          # Convertit in_header en liste
            content <- append(                                                  # Insère les deux items (ancien + main.tex)
              content,
              c(
                paste0(indent, "  - ", old_header),
                paste0(indent, "  - ../tex/main.tex")
              ),
              after = j
            )
            content <- content[-(i + 2)]                                        # Supprime before_body (décalée après 2 insertions)
            modified <- TRUE                                                    # Marque modification
          }

          break                                                                 # Sort de la recherche in_header
        }
      }

      if (modified) {                                                           # Si correction effectuée
        cat("Correction appliquée:\n")                                          # Log succès
        cat("   main.tex déplacé de 'before_body' vers 'in_header'\n\n")        # Log détail
      }

      break                                                                      # Sort de la boucle principale (une correction suffit)
    }
  }
}


# ------------------------------------------------------------------------------
# Contrôle : aucune modification = rien à faire
# ------------------------------------------------------------------------------
if (!modified) {                                                                # Si aucun changement
  cat("Attention : Problème non trouvé ou déjà corrigé\n")                      # Log
  cat("   Le fichier main.tex n'est pas dans 'before_body'\n\n")                # Détail
  stop("Aucune modification nécessaire", call. = FALSE)                         # Stop propre
}


# ------------------------------------------------------------------------------
# Écriture du fichier corrigé
# ------------------------------------------------------------------------------
writeLines(content, rmd_file)                                                   # Écrit le Rmd modifié (overwrite)


# ------------------------------------------------------------------------------
# Bandeau succès + explications
# ------------------------------------------------------------------------------
cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau succès
cat(" CORRECTION RÉUSSIE\n")                                                    # Titre succès
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

cat("EXPLICATION DU PROBLÈME:\n\n")                                             # Titre explication
cat("Le fichier main.tex contient:\n")                                          # Intro
cat("  \\usepackage[table]{xcolor}     ← Commande de PRÉAMBULE\n")              # Exemple 1
cat("  \\definecolor{...}               ← Commande de PRÉAMBULE\n\n")           # Exemple 2
cat("Ces commandes doivent être AVANT \\begin{document}\n\n")                   # Rappel règle LaTeX
cat("AVANT la correction:\n")                                                   # Intro avant
cat("  before_body: ../tex/main.tex   ← APRÈS \\begin{document} \n\n")          # Avant
cat("APRÈS la correction:\n")                                                   # Intro après
cat("  in_header:                     ← AVANT \\begin{document} \n")            # Après
cat("    - ../tex/header.tex\n")                                                # Item header
cat("    - ../tex/main.tex\n\n")                                                # Item main

cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau next
cat(" PROCHAINE ÉTAPE\n")                                                       # Titre next
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

cat("Générez maintenant le bulletin:\n\n")                                      # Instruction
cat("  source('dev/05_create_bulletin.R')\n\n")                                 # Commande

cat("Si vous avez toujours une erreur de police:\n\n")                          # Suggestion police
cat("  source('fix_font_arial.R')\n")                                           # Fix font
cat("  source('dev/05_create_bulletin.R')\n\n")                                 # Rebuild

cat("═══════════════════════════════════════════════════════════════\n\n")      # Footer


# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT 04_repare_erreur_preambule.R
# ──────────────────────────────────────────────────────────────────────────────
