# ──────────────────────────────────────────────────────────────────────────────
# FICHIER     : app.R
# AUTEUR      : MJ Martinat
# DATE        : 2025
# ORGANISATION: Direction Départementale des Territoires de la Drôme (DDT)
# DESCRIPTION : Point d'entrée pour déploiement direct sur shinyapps.io
#                - Charge tous les fichiers R nécessaires pour l'application.
#                - Configure les bibliothèques utilisées pour le traitement des données,
#                 la création de graphiques et l'affichage interactif.
#                - Lancement de l'application Shiny "cartOLD" en mode développement.
# ──────────────────────────────────────────────────────────────────────────────
# ── CHARGEMENT DES PACKAGES ─────────────────────────────────
library(base64enc)                                                              # Encodage Base64 pour convertir des donnees en format Base64.
library(config)                                                                 # Gestion des configurations du projet.
library(dplyr)                                                                  # Manipulation et transformation de donnees.
library(golem)                                                                  # Utilitaires pour structurer l application Shiny (add_resource_path, etc.).
library(htmlwidgets)                                                            # Creation de widgets HTML interactifs.
library(leaflet)                                                                # Affichage de cartes interactives.
library(magrittr)                                                               # Opérateur %>% pour chainer les operations de maniere fluide.
library(memoise)                                                                # Mise en cache des fonctions pour ameliorer les performances.
library(r2d3)                                                                   # Integration de visualisations D3 dans R.
library(rmarkdown)                                                              # Génération de documents PDF et autres formats a partir de Markdown.
library(RColorBrewer)                                                           # Palettes de couleurs predefinies pour les visualisations.
library(sf)                                                                     # Manipulation de donnees geospatiales.
library(sfarrow)                                                                # Extensions pour les donnees spatiales avec Arrow.
library(shiny)                                                                  # Framework pour creer des applications web interactives.
library(shinyjs)                                                                # Manipulation du DOM JavaScript depuis R.
library(stats)                                                                  # Fonctions statistiques de base.
library(utils)                                                                  # Fonctions utilitaires diverses.
library(grDevices)                                                              # Fonctions graphiques pour la gestion des appareils graphiques.

# ── CHARGEMENT DU PACKAGE EN MODE DEV (LOCAL) ───────────────
pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)

# ── LANCEMENT DE L'APPLICATION ──────────────────────────────
cartOLD::run_app()                                                              # Demarre l'application "cartOLD".
