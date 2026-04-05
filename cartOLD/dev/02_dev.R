# ──────────────────────────────────────────────────────────────────────────────
# SCRIPT      : 02_dev.R
# AUTEUR      : Marie-Jeanne MARTINAT
# ORGANISME   : Direction Départementale des Territoires de la Drôme (DDT)
# DATE        : 2025
# DESCRIPTION :
#   - Développement de l'application Shiny "cartOLD" utilisant le framework {golem}.
#   - Modules pour gestion d'interface utilisateur (UI) et logique serveur :
#     - Accueil : Présentation générale de l'application et du domaine d'application.
#     - Aide : Informations et guides sur l'utilisation des fonctionnalités.
#     - Avertissement : Notifications importantes pour l'utilisateur.
#     - Outils cartographiques : Commandes et fonctionnalités associées aux cartes.
#     - Cartes interactives : Affichage dynamique de données géographiques via Leaflet.
#   - Gestion des dépendances pour l'application via le champ Imports dans DESCRIPTION.
#   - Création de ressources front-end (JavaScript/CSS) pour personnaliser l'interface.
#   - Préparation des données internes et script de chargement.
#   - Intégration de tests pour assurer la qualité du code.
#   - Documentation et création de vignettes pour la présentation de l'application.
#   - Configuration pour l'intégration continue sur GitLab CI.
# ──────────────────────────────────────────────────────────────────────────────
# DECLARATION DES DEPENDANCES
# ──────────────────────────────────────────────────────────────
if (!requireNamespace("attachment", quietly = TRUE)) install.packages("attachment")
attachment::att_amend_desc()                                                    # Met à jour DESCRIPTION

# Ajoute les packages dans le champ Imports du fichier DESCRIPTION
# Necessaire pour que shinyapps.io installe automatiquement ces dependances
usethis::use_package("base64enc")                                               # Encodage Base64 pour images/donnees
usethis::use_package("config")                                                  # Gestion configuration golem (dev/prod)
usethis::use_package("dplyr")                                                   # Manipulation de donnees (filter, mutate, etc.)
usethis::use_package("golem")                                                   # Framework Shiny production
usethis::use_package("grDevices")                                               # Palettes de couleurs (système R)
usethis::use_package("htmlwidgets")                                             # Widgets HTML interactifs (Leaflet)
usethis::use_package("leaflet")                                                 # Cartes interactives OpenStreetMap/IGN
usethis::use_package("magrittr")                                                # Operateur pipe %>%
usethis::use_package("RColorBrewer")                                            # Palettes de couleurs CartoDB/Brewer
usethis::use_package("rmarkdown")                                               # Generation rapports/documentation
usethis::use_package("sf")                                                      # Objets geographiques (simple features)
usethis::use_package("sfarrow")                                                 # Import / export GeoParquet optimisé
usethis::use_package("shiny")                                                   # Framework applications web interactives
usethis::use_package("shinyjs")                                                 # Manipulation JavaScript cote serveur
usethis::use_package("stats")                                                   # Fonctions statistiques de base R
usethis::use_package("utils")                                                   # Utilitaires système R (read.csv, etc.)

# ──────────────────────────────────────────────────────────────
# MODULES UI ET MODULES SERVEUR
# (creation structurelle : ecrans et logique associee)
# ──────────────────────────────────────────────────────────────
golem::add_module("accueil")                                                    # Module ui/serveur Accueil
golem::add_module("aide")                                                       # Module ui/serveur de l'onglet d'aide complète pour la carte
golem::add_module("avertissement")                                              # Module ui/serveur de l'onglet d'avertissement
golem::add_module("carte")                                                      # Module ui/serveur de carte interactive Leaflet
golem::add_module("carte_aide")                                                 # Module ui/serveur de l'onglet d'aide pour la carte
golem::add_module("carte_export")                                               # Module ui/serveur d'outils pour exporter la carte en jpeg et pdf
golem::add_module("carte_controls")                                             # Module ui/serveur d'outils cartographiques

# ──────────────────────────────────────────────────────────────
# Fonctions utilitaires
# (helpers frontend + backend pour eviter la duplication)
# ──────────────────────────────────────────────────────────────
golem::use_r("golem_utils", with_test = FALSE)                                  # Fonctions utilitaires
golem::use_r("import_data", with_test = FALSE)                                  # Fonctions import de donnees

# ──────────────────────────────────────────────────────────────
# RESSOURCES FRONT-END (JS/CSS)
# ──────────────────────────────────────────────────────────────
# ── Creation des fonctionnalites js et css dans le dossier www
golem::add_js_file("script")                                                    # Fonctions js personnalisees du projet
golem::add_css_file("style")                                                    # Fonctions css personnalisees du projet

# ── Organisation dossiers www (optionnel mais propre DDT) ─────
dir.create("inst/app/www/js",  recursive = TRUE, showWarnings = FALSE)          # Dossier JS
dir.create("inst/app/www/css", recursive = TRUE, showWarnings = FALSE)          # Dossier CSS

# ── Deplacement des fichiers js et css dans un nouveau
#    sous-dossier ──────────────────────────────────────────────
file.rename("inst/app/www/script.js", "inst/app/www/js/script.js")              # Deplacement du  script JS
file.rename("inst/app/www/style.css", "inst/app/www/css/style.css")             # Deplacement du  CSS global

# ──────────────────────────────────────────────────────────────
# DONNEES INTERNES
# ──────────────────────────────────────────────────────────────
# ── Fichier d acquisition de donnees ──────────────────────────
usethis::use_data_raw("pre_data", open = FALSE)                                 # Preparation du script de chargement de donnees

# ──────────────────────────────────────────────────────────────
# TESTS
# ──────────────────────────────────────────────────────────────
# ── Test unique de l application ──────────────────────────────
usethis::use_test("app")                                                        # Création du test global de l application

# ──────────────────────────────────────────────────────────────
# DOCUMENTATION
# ──────────────────────────────────────────────────────────────
# usethis::use_vignette("cartOLD")                                              # Creation des vignettes
# devtools::build_vignettes()                                                   # Compilation de la documentation

# ──────────────────────────────────────────────────────────────
# INTEGRATION EN CONTINUE (GitLab CI)
# ──────────────────────────────────────────────────────────────
usethis::use_gitlab_ci()                                                        #   Itilisation du pipeline Forge

# ──────────────────────────────────────────────────────────────
# ETAPE SUIVANTE
# ──────────────────────────────────────────────────────────────
# ── Ouverture automatiquement du script de transformation des
#    Rmd ───────────────────────────────────────────────────────
rstudioapi::navigateToFile("dev/03_compile_rmd.R", line = 1)                    # Ouvre script suivant

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT
# ──────────────────────────────────────────────────────────────────────────────
