# ──────────────────────────────────────────────────────────────────────────────
# FICHIER       : app_config.R
# AUTEUR        : Marie-Jeanne MARTINAT
# ORGANISATION  : DDT de la Drôme
# DATE          : 2025
# DESCRIPTION   : Configuration centrale de l'application cartOLD
#                 Version hybride (développement + déploiement direct)
# ──────────────────────────────────────────────────────────────────────────────
# ACCÈS PORTABLE AUX RESSOURCES DU PACKAGE
# ───────────────────────────────────────────────
#' Accès universel aux ressources internes du package
#'
#' Retourne un chemin absolu pointant vers un fichier contenu dans `inst/`,
#' que l’application soit exécutée :
#'   - en développement local
#'   - en tant que package installé
#'   - en environnement de production (shinyapps.io, Posit Connect)
#'
#' @param ... Composants du chemin (sous-dossiers, fichiers).
#'
#' @return Une chaîne de caractères représentant un chemin absolu.
#'
#'
#' @noRd
app_sys <- function(...) {
  system.file(..., package = "cartOLD")                                         # system.file() détecte automatiquement le contexte (dev ou installé)
}


# ───────────────────────────────────────────────
# LECTURE CENTRALISÉE DE LA CONFIGURATION GOLEM
# ───────────────────────────────────────────────
#' Lecture d’un paramètre dans `golem-config.yml`
#'
#' Chargement intelligent d’un paramètre de configuration selon
#' l’environnement actif. Ordre de priorité :
#'   1. GOLEM_CONFIG_ACTIVE
#'   2. R_CONFIG_ACTIVE
#'   3. "default"
#'
#' @param value   Nom du paramètre à extraire.
#' @param config  Profil actif (détecté automatiquement si non fourni).
#' @param use_parent Recherche du fichier dans les dossiers parents.
#' @param file    Chemin complet vers `golem-config.yml`.
#'
#' @return La valeur extraite du fichier YAML.
#'
#' @importFrom config get
#'
#' @noRd
get_golem_config <- function(
    value,                                                                      # Clé YAML recherchée
    config = Sys.getenv(
      "GOLEM_CONFIG_ACTIVE",                                                    # Niveau 1 : variable golem
      Sys.getenv(
        "R_CONFIG_ACTIVE",                                                      # Niveau 2 : variable config standard
        "default"                                                               # Niveau 3 : fallback automatique
      )
    ),
    use_parent = TRUE,                                                          # Recherche ascendante activée
    file = app_sys("golem-config.yml")                                          # Localisation du fichier YAML
) {
  # Chargement propre via le package {config}
  # Le fichier YAML peut contenir plusieurs blocs : default/dev/production
  config::get(
    value = value,                                                              # Paramètre demandé
    config = config,                                                            # Section YAML active
    file = file,                                                                # Chemin exact du YAML
    use_parent = use_parent                                                     # Recherche dans parents
  )
}



# ──────────────────────────────────────────────────────────────────────────────
# FIN DU FICHIER
# ──────────────────────────────────────────────────────────────────────────────
