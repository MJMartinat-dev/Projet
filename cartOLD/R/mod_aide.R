# ──────────────────────────────────────────────────────────────────────────────
# FICHIER     : mod_aide.R
# AUTEUR      : MJ Martinat
# DATE        : 2025
# ORGANISATION: DDT de la Drôme
# DESCRIPTION : Module Aide pour cartOLD
#               Affiche une page HTML statique (aide.html) dans une iframe
#               responsive. Le fichier HTML est généré depuis aide_cartOLD.Rmd
#               et stocké dans inst/app/www/html/
# ──────────────────────────────────────────────────────────────────────────────
# INTERFACE UTILISATEUR DU MODULE AIDE (UI)
# ──────────────────────────────────────────────────────────────────────────────
#' UI du module aide
#'
#' Affiche une page HTML statique (aide.html) dans une iframe responsive.
#' Le fichier HTML est pré-rendu depuis aide_cartOLD.Rmd et stocké dans inst/app/www/html/
#'
#' @param id Identifiant du namespace du module
#'
#' @return Un tagList contenant l'iframe avec la page d'aide
#'
#' @importFrom shiny NS tagList tags
#'
#' @export
mod_aide_ui <- function(id) {                                                   # Debut function UI du module Aide
  ns <- shiny::NS(id)                                                           # Genere un namespace unique pour eviter collisions ID

  shiny::tagList(                                                               # Conteneur global regroupant le contenu du module
    shiny::tags$div(                                                            # Bloc enveloppe avec classe CSS dediee
      class = "bloc-aide-cadre",                                                # Classe CSS assurant hauteur fluide/pleine page

      shiny::tags$iframe(                                                       # Element <iframe> affichant le fichier HTML statique
        src    = "www/html/aide.html",                                          # Chemin vers le fichier pre-rendu (via addResourcePath)
        width  = "100%",                                                        # Largeur responsive = occupe tout l’espace horizontal
        height = "100%",                                                        # Hauteur fluide = depend des styles associes
        style  = "border: none; min-height: 100vh;",                            # Supprime bordure, impose une hauteur minimale plein ecran
        loading = "lazy",                                                       # Active chargement differe → optimisation performance
        title   = "Guide d'utilisation cartOLD"                                 # Attribut accessibilite (lecteurs d ecran)
      )                                                                         # Fin iframe
    )                                                                           # Fin bloc conteneur
  )                                                                             # Fin tagList
}                                                                               # Fin UI module Aide



# ──────────────────────────────────────────────────────────────────────────────
# SERVEUR DU MODULE AIDE
# ──────────────────────────────────────────────────────────────────────────────
#' Serveur du module aide
#'
#' Module serveur associe a l interface Aide.
#' Actuellement vide (page HTML statique sans interactions Shiny)
#'
#' @param id Identifiant du namespace du module
#'
#' @return Aucun objet retourné (execute dans l environnement serveur Shiny)
#'
#' @importFrom shiny moduleServer
#'
#' @export
mod_aide_server <- function(id) {                                                # Debut function serveur du module Aide
  shiny::moduleServer(id, function(input, output, session) {                     # Création du module serveur avec namespace
    # Le namespace session$ns est disponible mais inutile ici                    # (aucun élément dynamique à générer)

     # ─────────────────────────────────────────────────────────────────────────
     # La page affichee est un simple fichier HTML integre via <iframe>.
     # Aucun input, aucun output, aucune logique réactive n'est utilisée.
     # Ce module est donc intentionnellement vide, mais structurellement pret
     # pour accueillir des evolutions (tracking, analytics, messages dynamiques…)
     # ─────────────────────────────────────────────────────────────────────────

  })                                                                              # Fin moduleServer
}                                                                                 # Fin serveur module Aide


# ──────────────────────────────────────────────────────────────────────────────
# FIN DU FICHIER
# ──────────────────────────────────────────────────────────────────────────────
