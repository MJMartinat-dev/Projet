# ──────────────────────────────────────────────────────────────────────────────
# FICHIER     : mod_accueil.R
# AUTEUR      : MJ Martinat
# DATE        : 2025
# ORGANISATION: DDT de la Drôme
# DESCRIPTION : Module Accueil de l'application cartOLD
#               Affiche une page HTML statique de presentation
#               Version DÉPLOIEMENT DIRECT sur shinyapps.io
# ──────────────────────────────────────────────────────────────────────────────
# INTERFACE DU MODULE ACCUEIL (UI)
# ──────────────────────────────────────────────────────────────────────────────
#' Interface utilisateur du module Accueil
#'
#' Affiche une page d’accueil statique dans une iframe responsive.
#' La page HTML est generee depuis un RMarkdown puis integree dans inst/app/www/html/.
#'
#' @param id Identifiant du module (namespace Shiny)
#'
#' @return Un objet `shiny::tagList` contenant l'integralite du rendu UI
#'
#' @importFrom shiny NS tagList tags
#'
#' @noRd
mod_accueil_ui <- function(id) {                                                # Debut de la fonction UI du module Accueil
  ns <- shiny::NS(id)                                                           # Namespace unique genere pour eviter conflits d'IDs dans Shiny

  shiny::tagList(                                                               # Regroupement des elements UI du module
    shiny::tags$div(                                                            # Conteneur principal du module Accueil
      class = "bloc-accueil-cadre",                                             # Classe CSS pour regler le comportement layout

      shiny::tags$iframe(                                                       # Élement <iframe> affichant la page HTML d'accueil
        src = "www/html/accueil.html",                                          # Chemin du fichier HTML rendu statiquement via golem::add_resource_path
        width = "100%",                                                         # Largeur : occupe toute la largeur du conteneur
        height = "100%",                                                        # Hauteur : adaptative (completee par min-height ci-dessous)
        style = "border: none; min-height: 100vh;",                             # Suppression bordure + hauteur minimale = hauteur ecran
        loading = "lazy",                                                       # Lazy-loading pour optimisation de performance
        title = "Page d'accueil cartOLD"                                        # Titre descriptif pour lecteurs d’ecran
      )
    )
  )
}



# ──────────────────────────────────────────────────────────────────────────────
#                          SERVEUR DU MODULE ACCUEIL
# ──────────────────────────────────────────────────────────────────────────────
#' Serveur du module Accueil
#'
#' Aucun comportement interactif pour le moment : module purement statique.
#' Cette structure permet neanmoins d’ajouter plus tard :
#' - logique de suivi statistique
#' - affichages conditionnels
#' - declencheurs d'evenements
#'
#' @param id Identifiant du module
#'
#' @return Aucune valeur retournee (effets de bord uniquement)
#'
#' @importFrom shiny moduleServer
#'
#' @noRd
mod_accueil_server <- function(id) {                                            # Debut du serveur du module Accueil
  shiny::moduleServer(id, function(input, output, session) {                    # Declaration du serveur encapsule

    # ─────────────────────────────────────────────────────────────────────────
    # MODULE SERVEUR ACTUELLEMENT VIDE
    # La page affichee etant une iframe statique, Shiny n’a aucun evenement
    # reactif à gerer ici.
    #
    # Cette zone est prête à accueillir :
    #   - du tracking utilisateur (analytics interne)
    #   - des affichages modaux conditionnels
    #   - du monitoring de session
    #   - des integrations futures avec d'autres modules
    # ─────────────────────────────────────────────────────────────────────────

  })
}

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU FICHIER
# ──────────────────────────────────────────────────────────────────────────────
