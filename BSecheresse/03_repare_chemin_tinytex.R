# ------------------------------------------------------------------------------
# SCRIPT diagnose_latex_error.R : DIAGNOSTIC AUTOMATIQUE DES ERREURS LaTeX
# ------------------------------------------------------------------------------
# Auteur       : MJMartinat
# Structure    : DDT de la Drôme
# Date         : 2025-12-29
# ------------------------------------------------------------------------------
# DESCRIPTION  : Diagnostic des erreurs de compilation LaTeX (PDF)
#                - Recherche du .log le plus récent
#                - Extraction des erreurs clés ("!" + patterns fréquents)
#                - Propositions de remédiation (polices, packages, images, encodage)
#                - Génération optionnelle d’un script correctif (font Marianne)
# VERSION      : 1.0
# DÉPENDANCES  : here, jsonlite (optionnel si extensions), base R
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Configuration locale et chargement des packages
# ------------------------------------------------------------------------------
cat("\n")                                                                        # Saut de ligne console

cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau console
cat("  DIAGNOSTIC DES ERREURS LATEX\n")                                         # Titre console
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

library(here)                                                                   # Gestion des chemins relatifs au projet

# ------------------------------------------------------------------------------
# Trouver le fichier .log le plus récent
# ------------------------------------------------------------------------------
log_dir <- here::here("sorties", "bulletins", "pdf")                            # Répertoire des PDF/.log

if (!dir.exists(log_dir)) {                                                     # Vérifie existence dossier
  cat("Le dossier PDF n'existe pas:", log_dir, "\n")                            # Log erreur utilisateur
  stop("Impossible de trouver le dossier de sortie PDF", call. = FALSE)         # Stop propre (sans trace)
}

log_files <- list.files(                                                        # Liste des fichiers .log
  log_dir,                                                                      # Dossier de recherche
  pattern = "\\.log$",                                                          # Filtre extension .log
  full.names = TRUE                                                             # Chemins complets
)

if (length(log_files) == 0) {                                                   # Si aucun .log trouvé
  cat("Aucun fichier .log trouvé dans:", log_dir, "\n")                         # Log absence
  cat("   Le bulletin n'a probablement jamais été tenté.\n")                    # Hypothèse
  cat("   Essayez d'abord: source('dev/05_create_bulletin.R')\n")               # Suggestion
  stop("Aucun fichier log trouvé", call. = FALSE)                               # Stop propre
}

log_file <- log_files[which.max(file.info(log_files)$mtime)]                    # Sélection du .log le plus récent

cat("Fichier log analysé:", basename(log_file), "\n")                           # Affiche nom du log
cat("   Date:", format(file.info(log_file)$mtime, "%Y-%m-%d %H:%M:%S"), "\n\n") # Affiche date modif

# ------------------------------------------------------------------------------
# Lire et analyser le fichier log
# ------------------------------------------------------------------------------
cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau section
cat("  ANALYSE DU FICHIER LOG\n")                                               # Titre section
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

log_content <- readLines(log_file, warn = FALSE)                                # Lecture lignes log (sans warning)

# ------------------------------------------------------------------------------
# Rechercher les erreurs courantes
# ------------------------------------------------------------------------------
problemes_detectes <- list()                                                    # Conteneur problèmes détectés

if (any(grepl("Font.*Marianne.*not found", log_content, ignore.case = TRUE)) || # Pattern police Marianne manquante
    any(grepl("cannot find font",          log_content, ignore.case = TRUE)) || # Pattern police introuvable
    any(grepl("fontspec error",            log_content, ignore.case = TRUE))) { # Pattern fontspec
  problemes_detectes$font <- TRUE                                               # Flag font
  cat("PROBLÈME DÉTECTÉ: Police Marianne introuvable\n\n")                      # Log diagnostic
}

package_errors <- grep(                                                         # Extraction erreurs .sty manquants
  "! LaTeX Error.*\\.sty not found",                                            # Pattern LaTeX Error package
  log_content,                                                                  # Source log
  value = TRUE                                                                  # Retourne les lignes
)

if (length(package_errors) > 0) {                                               # Si packages manquants
  problemes_detectes$package <- package_errors                                  # Stocke détails
  cat("PROBLÈME DÉTECTÉ: Package(s) LaTeX manquant(s)\n")                       # Log diagnostic
  for (err in package_errors) cat("   ", err, "\n")                             # Liste les erreurs
  cat("\n")                                                                     # Saut de ligne
}

if (any(grepl("File.*not found", log_content)) ||                               # Pattern fichier manquant
    any(grepl("Missing.*figure", log_content, ignore.case = TRUE))) {           # Pattern figure manquante
  problemes_detectes$image <- TRUE                                              # Flag images
  cat("PROBLÈME DÉTECTÉ: Fichier image manquant\n\n")                           # Log diagnostic
}

if (any(grepl("! Undefined control sequence", log_content))) {                  # Pattern commande LaTeX inconnue
  problemes_detectes$syntax <- TRUE                                             # Flag syntaxe
  cat("PROBLÈME DÉTECTÉ: Erreur de syntaxe LaTeX\n\n")                          # Log diagnostic
}

if (any(grepl("Unicode char.*not set up", log_content))) {                      # Pattern unicode non géré
  problemes_detectes$encoding <- TRUE                                           # Flag encodage
  cat("PROBLÈME DÉTECTÉ: Erreur d'encodage Unicode\n\n")                        # Log diagnostic
}

# ------------------------------------------------------------------------------
# Extraire les lignes d'erreur importantes
# ------------------------------------------------------------------------------
cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau section
cat("  ERREURS TROUVÉES DANS LE LOG\n")                                          # Titre section
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

error_lines <- grep("^!", log_content, value = TRUE)                            # Lignes d’erreur LaTeX (préfixe "!")

if (length(error_lines) > 0) {                                                  # Si erreurs trouvées
  cat("Erreurs principales:\n")                                                 # Intro
  for (i in seq_along(error_lines)) {                                           # Boucle lignes erreur
    if (i <= 10) cat(sprintf("[%d] %s\n", i, error_lines[i]))                   # Affiche max 10 erreurs
  }
  if (length(error_lines) > 10) {                                               # Si plus de 10
    cat(sprintf("... et %d autres erreurs\n", length(error_lines) - 10))        # Indique surplus
  }
  cat("\n")                                                                     # Saut de ligne
} else {                                                                        # Si aucune erreur explicite
  cat("Aucune ligne d'erreur explicite trouvée avec '!'\n")                     # Log avertissement
  cat("Recherche d'autres indices...\n\n")                                      # Log suite
}

# ------------------------------------------------------------------------------
# Proposer des solutions
# ------------------------------------------------------------------------------
cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau section
cat("  SOLUTIONS PROPOSÉES\n")                                                  # Titre section
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

if (length(problemes_detectes) == 0) {                                          # Si aucun pattern reconnu
  cat("Erreur non identifiée automatiquement\n\n")                              # Log
  cat("ÉTAPES DE DIAGNOSTIC MANUEL:\n\n")                                       # Guide
  cat("1. Ouvrez le fichier log complet:\n")                                    # Étape 1
  cat("   ", log_file, "\n\n")                                                  # Chemin log
  cat("2. Cherchez les lignes commençant par '!'\n\n")                          # Étape 2
  cat("3. OU essayez la version HTML qui fonctionne:\n")                        # Étape 3
  cat("   source('dev/05_create_bulletin_html_only.R')\n\n")                    # Commande
}

if (!is.null(problemes_detectes$font)) {                                        # Si problème de police
  cat("┌─────────────────────────────────────────────────────────────┐\n")      # Cadre solution
  cat("│ SOLUTION #1 : Police Marianne manquante                    │\n")       # Titre solution
  cat("└─────────────────────────────────────────────────────────────┘\n\n")    # Fin cadre

  cat("La police 'Marianne' n'est pas installée sur Windows.\n\n")             # Explication

  cat("OPTION A : Utiliser une police système (RAPIDE)\n")                      # Option A
  cat("───────────────────────────────────────────────────────────────\n")      # Séparateur
  cat("Modifiez le fichier Rmd ligne 19:\n\n")                                  # Consigne
  cat("AVANT:\n")                                                               # Avant
  cat('mainfont: "Marianne"\n\n')                                               # Exemple avant
  cat("APRÈS (choisissez une):\n")                                              # Après
  cat('mainfont: "Arial"\n')                                                    # Exemple
  cat('mainfont: "Calibri"\n')                                                  # Exemple
  cat('mainfont: "Times New Roman"\n\n')                                        # Exemple

  cat("OPTION B : Installer la police Marianne\n")                              # Option B
  cat("───────────────────────────────────────────────────────────────\n")      # Séparateur
  cat("1. Téléchargez la police Marianne\n")                                    # Étape 1
  cat("2. Clic droit → 'Installer pour tous les utilisateurs'\n")               # Étape 2
  cat("3. Relancez la génération\n\n")                                          # Étape 3

  cat("OPTION C : Version HTML (contourne le problème)\n")                      # Option C
  cat("───────────────────────────────────────────────────────────────\n")      # Séparateur
  cat("source('dev/05_create_bulletin_html_only.R')\n\n")                       # Commande
}

if (!is.null(problemes_detectes$package)) {                                     # Si packages manquants
  cat("┌─────────────────────────────────────────────────────────────┐\n")      # Cadre solution
  cat("│ SOLUTION #2 : Packages LaTeX manquants                      │\n")      # Titre solution
  cat("└─────────────────────────────────────────────────────────────┘\n\n")    # Fin cadre

  package_names <- gsub(".*?([a-z0-9]+)\\.sty.*", "\\1", problemes_detectes$package) # Extraction noms packages

  cat("Installez les packages manquants:\n\n")                                  # Intro
  cat("tinytex::tlmgr_install(c(\n")                                            # Commande tlmgr
  cat(paste0('  "', package_names, '"', collapse = ",\n"))                      # Liste packages
  cat("\n))\n\n")                                                               # Fermeture commande
}

if (!is.null(problemes_detectes$image)) {                                       # Si images manquantes
  cat("┌─────────────────────────────────────────────────────────────┐\n")      # Cadre solution
  cat("│ SOLUTION #3 : Images manquantes                             │\n")      # Titre solution
  cat("└─────────────────────────────────────────────────────────────┘\n\n")    # Fin cadre

  cat("Vérifiez que les images existent:\n\n")                                  # Consigne
  cat("list.files('fichiers/images', recursive = TRUE)\n")                      # Liste images
  cat("list.files('fichiers/tex/logo', recursive = TRUE)\n\n")                  # Liste logos
}

# ------------------------------------------------------------------------------
# Créer un script de correction automatique
# ------------------------------------------------------------------------------
cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau section
cat("  SCRIPT DE CORRECTION AUTOMATIQUE\n")                                     # Titre section
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

if (!is.null(problemes_detectes$font)) {                                        # Si police manquante détectée
  cat("Script créé: fix_font_problem.R\n\n")                                    # Log création

  fix_script <- here::here("fix_font_problem.R")                                # Chemin script correctif

  cat('# Script de correction automatique de la police
# Remplace "Marianne" par "Arial" dans le Rmd

library(here)

rmd_file <- here::here("fichiers", "Rmd", "bulletin_secheresse.Rmd")
content <- readLines(rmd_file, warn = FALSE)

# Trouver et remplacer la ligne mainfont
for (i in seq_along(content)) {
  if (grepl("mainfont.*Marianne", content[i])) {
    content[i] <- \'mainfont: "Arial"\'
    cat("✅ Ligne", i, "modifiée: Marianne → Arial\\n")
    break
  }
}

writeLines(content, rmd_file)

cat("\\n✅ Police changée pour Arial\\n")
cat("   Relancez maintenant: source(\'dev/05_create_bulletin.R\')\\n\\n")
', file = fix_script)                                                           # Écrit le contenu du script correctif

  cat("Pour l'exécuter: source('fix_font_problem.R')\n\n")                      # Instruction exécution
}

# ------------------------------------------------------------------------------
# Afficher le chemin complet du log
# ------------------------------------------------------------------------------
cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau section
cat("  FICHIER LOG COMPLET\n")                                                  # Titre section
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

cat("Pour voir toutes les erreurs en détail:\n")                                # Consigne
cat(log_file, "\n\n")                                                           # Affiche chemin log

cat("Ou dans R:\n")                                                             # Alternative
cat("cat(readLines('", log_file, "'), sep = '\\n')\n\n")                        # Commande lecture log

# ------------------------------------------------------------------------------
# Résumé final
# ------------------------------------------------------------------------------
cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau section
cat("  RÉSUMÉ\n")                                                                # Titre section
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

if (length(problemes_detectes) > 0) {                                           # Si au moins un problème détecté
  cat("Problème(s) identifié(s):", length(problemes_detectes), "\n")            # Nombre de problèmes
  cat("Solution(s) proposée(s) ci-dessus\n")                                    # Indication
  cat("Script de correction créé si applicable\n\n")                            # Indication

  cat("PROCHAINE ÉTAPE:\n")                                                     # Plan d’action
  cat("Appliquez la solution recommandée\n")                                 # Étape 1
  cat("Relancez: source('dev/05_create_bulletin.R')\n\n")                    # Étape 2
} else {                                                                        # Si aucun problème catégorisé
  cat("Erreur LaTeX non identifiée automatiquement\n")                          # Avertissement
  cat("Consultez le fichier log complet pour plus de détails\n\n")              # Suggestion

  cat("EN ATTENDANT:\n")                                                        # Contournement
  cat("→ Utilisez la version HTML: source('dev/05_create_bulletin_html_only.R')\n\n") # Commande
}

cat("═══════════════════════════════════════════════════════════════\n\n")      # Footer console

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT diagnostique_erreur_latex.R
# ──────────────────────────────────────────────────────────────────────────────
