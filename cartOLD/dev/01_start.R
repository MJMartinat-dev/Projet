# ──────────────────────────────────────────────────────────────────────────────
# SCRIPT      : 01_start.R
# AUTEUR      : Marie-Jeanne MARTINAT
# STRUCTURE   : DDT de la Drôme
# DATE        : 2025
# DESCRIPTION : Initialisation du projet Shiny {golem} "cartOLD"
#               - Préparation .Renviron (proxy / secrets)
#               - Génération DESCRIPTION + fichiers standards
#               - Configuration golem
#               - Initialisation Git + remote GitLab Forge
# NOTE        : À exécuter une seule fois après création du projet golem
# ──────────────────────────────────────────────────────────────────────────────
# VARIABLES D ENVIRONNEMENTS (PROXY, TOKENS...)
# ────────────────────────────────────────────────────────────────────────
if (!file.exists(".Renviron")) file.create(".Renviron")                         # Creation de  .Renviron si absent
usethis::edit_r_environ()                                                       # Ouverture de .Renviron pour definir proxy et variables sensibles

message("Pensez à ajouter vos variables d'environnement sensibles
         dans .Renviron, telles que le proxy ou les tokens.")                   # Message d information

# ────────────────────────────────────────────────────────────────────────
# INSTALLATION ET CHARGEMENT DES DEPENDANCES
# ────────────────────────────────────────────────────────────────────────
# ── Installation des packages ───────────────────────────────────────────
pkgs <- c("golem",                                                              # Outil pour construire des applications Shiny pour la production
          "usethis",                                                            # Outil pour automatiser de nombreuses tâches communes de configuration de paquets et d'analyses
          "rstudioapi",                                                         # Outil pour interagir avec des documents dans RStudio
          "devtools",                                                           # Outils developpement R
          "attachment")                                                         # Outil pour gerer les dependances DESCRIPTION

to_install <- pkgs[!pkgs %in% installed.packages()[,"Package"]]                 # Identification des packages manquants
if (length(to_install) > 0) install.packages(to_install)                        # Installation uniquement des packages manquants

# ── Chargement des packages ─────────────────────────────────────────────
library(golem)                                                                  # Mise en fonction  de l outil de construction d applications Shiny
library(usethis)                                                                # Mise en fonction  de l outil de configuration et d analyses
library(rstudioapi)                                                             # Mise en fonction  de l outil de navigation dans RStudio IDE
library(devtools)                                                               # Mise en fonction  de l outil de developpement R
library(attachment)                                                             # Mise en fonction  de l outil de scan automatique dépendances


# ────────────────────────────────────────────────────────────────────────
# CONFIGURATION DU FICHIER DESCRIPTION
# ────────────────────────────────────────────────────────────────────────
# ── Remplissage des metadonnees du package selon standards CRAN ─────────
golem::fill_desc(
  pkg_name = "cartOLD",                                                         # Nom du package
  pkg_title = "Cartographie interactive des OLD",                               # Titre court
  pkg_description = "Application Shiny modulaire pour la visualisation cartographique interactive des Obligations Légales de Débroussaillement dans la Drôme.",
  authors = person(
    given = "Marie-Jeanne",                                                     # Prénom du développeur
    family = "MARTINAT",                                                        # Nom du développeur
    email  = "marie-jeanne.martinat@i-carre.net",                               # email du développeur
    role   = c("aut", "cre")                                                    # aut=auteur, cre=mainteneur
  ),
  repo_url = NULL                                                               # URL GitLab Forge (optionnel)
)

# ────────────────────────────────────────────────────────────────────────
# AJOUT/MISE À JOUR DE LA VERSION
# ────────────────────────────────────────────────────────────────────────
# ──  Modification direct du fichier DESCRIPTION pour gerer la version ───
description_file <- "DESCRIPTION"                                               # Variable pour le fichier DESCRIPTION
desc_content <- readLines(description_file)                                     # Lecture du contenu actuel

# ──  Recherche la ligne Version et l'ajoute/modifie ─────────────────────
if (!any(grepl("^Version:", desc_content))) {
  desc_content <- c(desc_content, "Version: 0.0.1")                             # Ajout si absente
} else {
  desc_content <- gsub("Version: .*", "Version: 0.0.1", desc_content)           # Mise à jour si présente
}

writeLines(desc_content, description_file)                                      # Ecriture des modifications

# ────────────────────────────────────────────────────────────────────────
# INSTALLATION DES DÉPENDANCES DE DÉVELOPPEMENT
# ────────────────────────────────────────────────────────────────────────
# ── Installation des  packages nécessaires pour tester, documenter et
#    controler qualite ──────────────────────────────────────────────────
golem::install_dev_deps()                                                       # testthat, roxygen2, rcmdcheck, etc.

# ────────────────────────────────────────────────────────────────────────
# CONFIGURATION GOLEM
# ────────────────────────────────────────────────────────────────────────
# ── Creation "inst/golem-config.yml" avec parametres par défaut
golem::set_golem_options()                                                      # Activation structure golem (config, etc.)

# ────────────────────────────────────────────────────────────────────────
# FICHIERS STANDARDS DU PROJET
# ────────────────────────────────────────────────────────────────────────
usethis::use_gpl3_license()                                                     # Licence GPL-3 (open source)
usethis::use_readme_rmd(open = FALSE)                                           # Creation README.Rmd
devtools::build_readme()                                                        # Compilation README.Rmd → README.md
usethis::use_code_of_conduct(contact = "Marie-Jeanne MARTINAT")                 # Code conduite contributeurs
usethis::use_news_md(open = FALSE)                                              # Fichier NEWS.md (changelog)

# ────────────────────────────────────────────────────────────────────────
# TESTS (FACULTATIF)
# ────────────────────────────────────────────────────────────────────────
# ── Activation du framework testthat si tests unitaires souhaites
#    (optionnel) ─────────────────────────────────────────────────────────
# golem::use_recommended_tests()                                                # Creation des tests dans le dossier "testthat/"

# ────────────────────────────────────────────────────────────────────────
# RESSOURCES VISUELLES
# ────────────────────────────────────────────────────────────────────────
# ── Creation d un favicon par defaut dans "inst/app/www/" ───────────────
golem::use_favicon()                                                            # Creation du favicon.ico generique

# ────────────────────────────────────────────────────────────────────────
# ORGANISATION DU DOSSIER WWW (BONNES PRATIQUES DDT)
# ────────────────────────────────────────────────────────────────────────
# ── Creation d une arborescence propre pour les ressources statiques ────
if (!dir.exists("inst/app/www/icones")) {
  dir.create("inst/app/www/icones",                                             # Dossier dedie aux icones
             recursive = TRUE,                                                  # Creation des parents si necessaire
             showWarnings = FALSE)                                              # Pas d alerte si existe deja
}

# ── Deplacement du favicon dans le sous-dossier "icones/" ───────────────
if (file.exists("inst/app/www/favicon.ico")) {
    file.rename("inst/app/www/favicon.ico",                                     # Source
                "inst/app/www/icones/cartOLD.ico")                              # Destination finale
} else {
  message("INFO : Le fichier favicon.ico n'a pas été trouvé dans inst/app/www/") # Message d information
}

# ────────────────────────────────────────────────────────────────────────
# INITIALISATION GIT & CONNEXION GITLAB FORGE
# ────────────────────────────────────────────────────────────────────────
# ── Initialisation du depot Git local ───────────────────────────────────
usethis::use_git(message = "Initialisation projet cartOLD")                     # Premier commit automatique

# Configure le depot distant (GitLab Forge ministeriel)
usethis::use_git_remote(
  name = "origin",                                                              # Nom conventionnel du remote
  url  = "https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/cartold.git"
)                                                                               # URL du dépôt Forge

# ────────────────────────────────────────────────────────────────────────
# ETAPE SUIVANTE
# ────────────────────────────────────────────────────────────────────────
# ── Ouverture automatiquement du script de developpement ────────────────
rstudioapi::navigateToFile("dev/02_dev.R", line = 1)                            # Passe a l etape suivante

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT 01_START.R
# ──────────────────────────────────────────────────────────────────────────────
