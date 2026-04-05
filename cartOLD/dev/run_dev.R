# ──────────────────────────────────────────────────────────────────────────────
# SCRIPT      : run_dev.R
# AUTEUR      : Marie-Jeanne MARTINAT
# Structure   : Direction Departementale des Territoires de la Drome (DDT)
# DATE        : 2025
# OBJET       : Lancement de l application "cartOLD" en mode developpement
#               - Configuration des options de developpement pour l application :
#                 - mode de production desactive (golem.app.prod = FALSE)
#                 - utilisation d'un port aleatoire pour eviter les conflits
#                   avec d'autres applications.
#               - Nettoyage de l environnement de travail :
#                 - dechargement de tous les packages attaches pour eviter
#                   les interferences.
#                 - suppression de toutes les variables pour un environnement propre.
#               - Generation de la documentation et rechargement du package
#                 en memoire pour refleter les dernieres modifications.
#               - Lancement de l application Shiny en mode developpement pour
#                 permettre le testing et le debogage.
# ──────────────────────────────────────────────────────────────────────────────
# OPTIONS DE DEVELOPPEMENT
# ──────────────────────────────────────────────────────────────
options(golem.app.prod = FALSE)                                                 # FALSE = mode developpement, TRUE = production
options(shiny.port = httpuv::randomPort())                                      # Port aleatoire (evite domination d un port fixe)

# ──────────────────────────────────────────────────────────────
# NETTOYAGE DE L ENVIRONNEMENT
# ──────────────────────────────────────────────────────────────
golem::detach_all_attached()                                                    # Retrait de tous les packages attaches
rm(list = ls(all.names = TRUE))                                                 # Optionnel : purge totale de l environnement

# ──────────────────────────────────────────────────────────────
# DOCUMENTATION ET RECHARGEMENT DU PACKAGE
# ──────────────────────────────────────────────────────────────
golem::document_and_reload()                                                    # Genere la documentation + recharge des librairies en memoire

# ──────────────────────────────────────────────────────────────
# LANCEMENT DE L APPLICATION
# ──────────────────────────────────────────────────────────────
run_app()                                                                       # Demarrage de l application Shiny en mode dev

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT run_dev.R
# ──────────────────────────────────────────────────────────────────────────────
