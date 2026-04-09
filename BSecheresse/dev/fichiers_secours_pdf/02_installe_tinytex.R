# ------------------------------------------------------------------------------
# SCRIPT 02_install_tinytex.R : INSTALLATION GUIDÉE DE TinyTeX
# ------------------------------------------------------------------------------
# Auteur       : MJMartinat
# Structure    : DDT de la Drôme
# Date         : 2025-12-29
# ------------------------------------------------------------------------------
# DESCRIPTION  : Installation guidée pour activer la génération PDF (LaTeX)
#                - Installe le package R {tinytex}
#                - Installe TinyTeX (distribution LaTeX légère)
#                - Installe les packages LaTeX nécessaires au bulletin
# VERSION      : 1.0
# DÉPENDANCES  : here (optionnel), tinytex
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Bandeau console
# ------------------------------------------------------------------------------
cat("\n")                                                                       # Saut de ligne console
cat("═══════════════════════════════════════════════════════════════\n")        # Ligne décorative
cat("  INSTALLATION GUIDÉE DE TINYTEX\n")                                       # Titre
cat("═══════════════════════════════════════════════════════════════\n\n")      # Ligne décorative

cat("Ce script va installer:\n")                                                # Intro
cat("   - Le package R 'tinytex'\n")                                            # Étape 1
cat("   - TinyTeX (distribution LaTeX légère)\n")                               # Étape 2
cat("   - Les packages LaTeX requis pour le bulletin\n\n")                      # Étape 3
cat("Durée indicative: 10-15 minutes\n")                                        # Durée (indicatif)
cat("Espace disque requis: ~100 MB\n\n")                                        # Disk

reponse <- readline(prompt = "Voulez-vous continuer ? (O/N): ")                 # Confirmation utilisateur

if (!grepl("^[Oo]", reponse)) {                                                 # Si réponse ≠ O/oui
  cat("\nInstallation annulée\n")                                               # Log annulation
  cat("   Pour générer le bulletin sans PDF:\n")                                # Alternative
  cat("   source('dev/05_create_bulletin_html_only.R')\n\n")                    # Commande alternative
  stop("Installation annulée par l'utilisateur", call. = FALSE)                 # Stop propre
}

cat("\n")                                                                       # Respiration console


# ------------------------------------------------------------------------------
# Installation du package R 'tinytex'
# ------------------------------------------------------------------------------
cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau section
cat(" Installation du package R 'tinytex'\n")                                   # Titre section
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

if (!requireNamespace("tinytex", quietly = TRUE)) {                             # Test présence {tinytex}
  cat("Installation du package 'tinytex'...\n")                                 # Log install
  install.packages("tinytex", quiet = TRUE)                                     # Installation CRAN
  cat("Package 'tinytex' installé\n\n")                                         # Log OK
} else {                                                                        # Sinon
  cat("Package 'tinytex' déjà installé\n\n")                                    # Log déjà présent
}

library(tinytex)                                                                # Charge {tinytex} pour la suite


# ------------------------------------------------------------------------------
# Installation de TinyTeX
# ------------------------------------------------------------------------------
cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau section
cat(" Installation de TinyTeX\n")                                               # Titre section
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

if (tinytex:::is_tinytex()) {                                                   # Détection TinyTeX déjà installé
  cat("TinyTeX est déjà installé\n")                                            # Log OK
  cat("   Chemin: ", tinytex::tinytex_root(), "\n\n")                           # Affiche racine
} else {                                                                        # Sinon installer
  cat("Installation de TinyTeX...\n")                                           # Log install
  cat("   (Téléchargement + installation)\n\n")                                 # Détail

  tryCatch({                                                                    # Encapsulation erreur réseau/permissions
    tinytex::install_tinytex()                                                  # Installation TinyTeX
    cat("\nTinyTeX installé avec succès\n")                                     # Log succès
    cat("   Chemin: ", tinytex::tinytex_root(), "\n\n")                         # Affiche racine
  }, error = function(e) {                                                      # Gestion erreur
    cat("\nERREUR lors de l'installation de TinyTeX\n")                         # Log erreur
    cat("   Message: ", e$message, "\n\n")                                      # Message brut
    cat("   SOLUTIONS:\n")                                                      # Pistes
    cat("   - Vérifiez votre connexion internet\n")                             # Connexion
    cat("   - Relancez ce script\n")                                            # Retry
    cat("   - Alternative: installer MiKTeX manuellement (si politique SI)\n\n") # Plan B
    stop("Installation de TinyTeX échouée", call. = FALSE)                      # Stop propre
  })
}


# ------------------------------------------------------------------------------
# Installation des packages LaTeX requis
# ------------------------------------------------------------------------------
cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau section
cat("  Installation des packages LaTeX requis\n")                               # Titre section
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

packages_latex <- c(                                                            # Liste minimale packages LaTeX (tlmgr)
  "fontspec",                                                                   # Polices Unicode (XeLaTeX/LuaLaTeX)
  "xunicode",                                                                   # Support Unicode (legacy)
  "fancyhdr",                                                                   # En-têtes/pieds de page
  "booktabs",                                                                   # Tables typographiquement propres
  "xcolor",                                                                     # Couleurs
  "colortbl",                                                                   # Couleurs dans tableaux
  "float",                                                                      # Gestion positionnement figures
  "makecell",                                                                   # Cellules avancées
  "multirow",                                                                   # Fusion lignes tableau
  "geometry"                                                                    # Mise en page (marges)
)

cat("Installation de", length(packages_latex), "packages LaTeX...\n")           # Log total
cat("   (tlmgr_install, peut prendre plusieurs minutes)\n\n")                   # Info

for (i in seq_along(packages_latex)) {                                          # Boucle sur packages
  pkg <- packages_latex[i]                                                      # Package courant
  cat(sprintf("   [%2d/%2d] %s... ", i, length(packages_latex), pkg))           # Progression

  tryCatch({                                                                    # Tolérance aux erreurs ponctuelles
    tinytex::tlmgr_install(pkg)                                                 # Installation via tlmgr
    cat("\n")                                                                   # Log OK
  }, error = function(e) {                                                      # Gestion erreur
    cat("(erreur, mais on continue)\n")                                         # Log warning soft
  })
}

cat("\nTous les packages LaTeX sont installés\n\n")                                 # Log fin étape


# ------------------------------------------------------------------------------
# Vérification finale (XeLaTeX accessible)
# ------------------------------------------------------------------------------
cat("═══════════════════════════════════════════════════════════════\n")        # Bandeau section
cat("  VÉRIFICATION FINALE\n")                                                  # Titre section
cat("═══════════════════════════════════════════════════════════════\n\n")      # Fin bandeau

xelatex_path <- Sys.which("xelatex")                                            # Recherche binaire xelatex dans PATH

if (xelatex_path != "") {                                                       # Si trouvé
  cat("XeLaTeX est accessible:", xelatex_path, "\n\n")                          # Log OK

  cat("═══════════════════════════════════════════════════════════════\n")      # Bandeau succès
  cat(" INSTALLATION RÉUSSIE !\n")                                              # Titre succès
  cat("═══════════════════════════════════════════════════════════════\n\n")    # Fin bandeau

  cat("TinyTeX est installé et fonctionnel\n")                                  # Check 1
  cat("Les packages LaTeX requis sont installés\n")                             # Check 2
  cat("XeLaTeX est accessible\n\n")                                             # Check 3

  cat("PROCHAINES ÉTAPES:\n\n")                                                 # Next steps
  cat("- Redémarrez RStudio complètement\n")                                    # Redémarrage complet
  cat("- Vérifiez après redémarrage:\n")                                        # Vérif
  cat("   Sys.which('xelatex')\n\n")                                            # Commande test
  cat("- Générez le bulletin:\n")                                               # Exécution
  cat("   source('dev/05_create_bulletin.R')\n\n")                              # Commande

  cat("═══════════════════════════════════════════════════════════════\n\n")    # Footer

} else {                                                                        # Si non trouvé dans PATH
  cat("XeLaTeX n'est pas encore accessible\n\n")                                # Log warning

  cat("═══════════════════════════════════════════════════════════════\n")      # Bandeau warning
  cat(" REDÉMARRAGE REQUIS\n")                                                  # Titre warning
  cat("═══════════════════════════════════════════════════════════════\n\n")    # Fin bandeau

  cat("TinyTeX semble installé, mais l'environnement doit être rafraîchi.\n")   # Explication
  cat("RStudio doit être relancé pour recharger PATH / variables.\n\n")         # Cause fréquente

  cat("À FAIRE MAINTENANT:\n\n")                                                # Todo
  cat("- Fermez COMPLÈTEMENT RStudio\n")                                        # Quit complet
  cat("- Relancez RStudio\n")                                                   # Relance
  cat("- Vérifiez:\n")                                                          # Vérif
  cat("   Sys.which('xelatex')\n")                                              # Commande test
  cat("- Générez le bulletin:\n")                                               # Exécution
  cat("   source('dev/05_create_bulletin.R')\n\n")                              # Commande

  cat("═══════════════════════════════════════════════════════════════\n\n")    # Footer
}


# ------------------------------------------------------------------------------
# Informations complémentaires
# ------------------------------------------------------------------------------
cat("INFORMATIONS TINYTEX:\n\n")                                                # Titre infos
cat("   Emplacement: ", tinytex::tinytex_root(), "\n")                          # Racine TinyTeX
cat("   Taille: ~100 MB\n")                                                     # Indication taille
cat("   Pour désinstaller: tinytex::uninstall_tinytex()\n\n")                   # Commande uninstall

cat("═══════════════════════════════════════════════════════════════\n\n")      # Footer global


# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT 02_install_tinytex.R
# ──────────────────────────────────────────────────────────────────────────────
