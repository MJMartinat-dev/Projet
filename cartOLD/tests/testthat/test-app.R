# ==============================================================================
# FICHIER     : test_app.R
# AUTEUR      : MJ Martinat
# DATE        : 2025
# ORGANISATION: DDT de la Drôme - Ministère de la Transition Écologique
# DESCRIPTION : Tests unitaires de l'application cartOLD
# ==============================================================================

# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION DES TESTS
# ══════════════════════════════════════════════════════════════════════════════
library(testthat)                                                               # Framework de tests
library(shiny)                                                                  # Pour tester l'application Shiny

# ══════════════════════════════════════════════════════════════════════════════
# TEST 1 : CHARGEMENT DE L'APPLICATION
# ══════════════════════════════════════════════════════════════════════════════
test_that("L'application se charge sans erreur", {                             # Test de chargement
  expect_true(file.exists("app.R"), "Le fichier app.R doit exister")           # Vérif fichier
  expect_true(file.exists("R/app_ui.R"), "Le fichier app_ui.R doit exister")   # Vérif UI
  expect_true(file.exists("R/app_server.R"), "Le fichier app_server.R doit exister")  # Vérif serveur
})                                                                              # Fin test

# ══════════════════════════════════════════════════════════════════════════════
# TEST 2 : STRUCTURE DES DONNÉES
# ══════════════════════════════════════════════════════════════════════════════
test_that("Les fichiers RDS de données existent", {                            # Test présence données
  fichiers_rds <- c(                                                            # Liste fichiers attendus
    "inst/app/extdata/departement.rds",                                         # Département
    "inst/app/extdata/communes.rds",                                            # Communes
    "inst/app/extdata/communes_old200.rds",                                     # Communes OLD
    "inst/app/extdata/old200.rds",                                              # OLD 200m
    "inst/app/extdata/old50m.rds",                                              # OLD 50m
    "inst/app/extdata/parcelles.rds",                                           # Parcelles
    "inst/app/extdata/batis.rds",                                               # Bâtiments
    "inst/app/extdata/zu.rds"                                                   # Zonage urbain
  )                                                                             # Fin liste

  for (fichier in fichiers_rds) {                                               # Pour chaque fichier
    expect_true(                                                                # Vérification existence
      file.exists(fichier),                                                     # Test fichier
      info = paste("Le fichier", fichier, "doit exister")                       # Message erreur
    )                                                                           # Fin expect
  }                                                                             # Fin boucle
})                                                                              # Fin test

# ══════════════════════════════════════════════════════════════════════════════
# TEST 3 : FICHIERS CSS ET JS
# ══════════════════════════════════════════════════════════════════════════════
test_that("Les assets web sont présents", {                                    # Test assets
  expect_true(                                                                  # Vérif CSS
    file.exists("inst/app/www/css/style.css"),                                  # Fichier CSS
    "Le fichier CSS doit exister"                                               # Message
  )                                                                             # Fin expect

  expect_true(                                                                  # Vérif JS
    file.exists("inst/app/www/js/script.js"),                                   # Fichier JS
    "Le fichier JavaScript doit exister"                                        # Message
  )                                                                             # Fin expect

  expect_true(                                                                  # Vérif HTML accueil
    file.exists("inst/app/www/html/accueil.html"),                              # Page accueil
    "La page d'accueil HTML doit exister"                                       # Message
  )                                                                             # Fin expect

  expect_true(                                                                  # Vérif avertissement
    file.exists("inst/app/www/html/avertissement.html"),                        # Modale avertissement
    "Le fichier avertissement.html doit exister"                                # Message
  )                                                                             # Fin expect
})                                                                              # Fin test

# ══════════════════════════════════════════════════════════════════════════════
# TEST 4 : FONCTIONS PRINCIPALES
# ══════════════════════════════════════════════════════════════════════════════
test_that("Les fonctions principales existent", {                              # Test fonctions
  source("R/app_config.R")                                                      # Chargement config
  source("R/import_data.R")                                                     # Chargement import

  expect_true(exists("app_sys"), "La fonction app_sys doit exister")            # Test app_sys
  expect_true(exists("import_data"), "La fonction import_data doit exister")    # Test import_data
  expect_true(exists("import_data_cached"), "La fonction import_data_cached doit exister")  # Test cached
})                                                                              # Fin test

# ══════════════════════════════════════════════════════════════════════════════
# TEST 5 : CHARGEMENT DES DONNÉES
# ══════════════════════════════════════════════════════════════════════════════
test_that("Les données se chargent correctement", {                            # Test chargement données
  skip_on_cran()                                                                # Skip sur CRAN (trop long)

  source("R/app_config.R")                                                      # Chargement config
  source("R/import_data.R")                                                     # Chargement import

  expect_silent({                                                               # Test sans erreur
    data <- import_data()                                                       # Chargement données
  })                                                                            # Fin expect_silent

  expect_type(data, "list", "import_data doit retourner une liste")            # Vérif type
  expect_true("departement" %in% names(data), "Données département manquantes")  # Vérif département
  expect_true("communes" %in% names(data), "Données communes manquantes")      # Vérif communes
  expect_true("old200" %in% names(data), "Données OLD200 manquantes")          # Vérif OLD200
  expect_true("old50m_all" %in% names(data), "Données OLD50m manquantes")      # Vérif OLD50m
})                                                                              # Fin test

# ══════════════════════════════════════════════════════════════════════════════
# TEST 6 : MODULES SHINY
# ══════════════════════════════════════════════════════════════════════════════
test_that("Les modules Shiny sont définis", {                                  # Test modules
  source("R/mod_accueil.R")                                                     # Chargement module accueil
  source("R/mod_carte.R")                                                       # Chargement module carte
  source("R/mod_carte_controls.R")                                              # Chargement module contrôles

  expect_true(exists("mod_accueil_ui"), "Module accueil UI manquant")           # Test UI accueil
  expect_true(exists("mod_accueil_server"), "Module accueil serveur manquant")  # Test serveur accueil
  expect_true(exists("mod_carte_ui"), "Module carte UI manquant")               # Test UI carte
  expect_true(exists("mod_carte_server"), "Module carte serveur manquant")      # Test serveur carte
  expect_true(exists("mod_carte_controls_ui"), "Module contrôles UI manquant")  # Test UI contrôles
  expect_true(exists("mod_carte_controls_server"), "Module contrôles serveur manquant")  # Test serveur contrôles
})                                                                              # Fin test

# ══════════════════════════════════════════════════════════════════════════════
# TEST 7 : DESCRIPTION ET NAMESPACE
# ══════════════════════════════════════════════════════════════════════════════
test_that("Les fichiers DESCRIPTION et NAMESPACE existent", {                  # Test métadonnées
  expect_true(file.exists("DESCRIPTION"), "DESCRIPTION doit exister")           # Vérif DESCRIPTION
  expect_true(file.exists("NAMESPACE"), "NAMESPACE doit exister")               # Vérif NAMESPACE
})                                                                              # Fin test

# ══════════════════════════════════════════════════════════════════════════════
# FIN DES TESTS
# ══════════════════════════════════════════════════════════════════════════════
