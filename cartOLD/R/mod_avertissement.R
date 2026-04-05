# ──────────────────────────────────────────────────────────────────────────────
# FICHIER     : mod_avertissement.R
# AUTEUR      : MJ Martinat
# ORGANISATION: DDT de la Drôme
# DATE        : 2025
# DESCRIPTION : Module Avertissement de l'application cartOLD
#               - Interface et serveur du module "Avertissement"
#               - Affiche un contenu HTML statique encapsule dans un IFRAME
#               - Module purement informatif, sans logique interactive
# ──────────────────────────────────────────────────────────────────────────────
# INTERFACE UTILISATEUR DU MODULE AVERTISSEMENT
# ──────────────────────────────────────────────────────────────────────────────
#' UI du module Avertissement
#'
#' Construit le conteneur affichant :
#' - un titre principal formel
#' - un sous-titre
#' - une page HTML statique integree via <iframe>
#'
#' @param id Identifiant du module (namespace Shiny)
#'
#' @return Un objet `shiny.tagList` representant l'UI complete du module
#'
#' @importFrom shiny NS tagList tags
#'
#' @noRd
mod_avertissement_ui <- function(id) {                                          # Fonction UI du module Avertissement
  ns <- shiny::NS(id)                                                           # Creation du namespace pour les IDs internes

  shiny::tagList(                                                               # Regroupe l’ensemble des elements UI du module
    shiny::tags$div(                                                            # Conteneur general du bloc Avertissement
      class = "bloc-avertissement-cadre",                                       # Classe CSS principale pour le style

      # ───────────────────────────────────────────────────────────────────────
      # TITRE PRINCIPAL DU MODULE
      # ───────────────────────────────────────────────────────────────────────
      shiny::tags$h2(                                                           # Titre H2 affiche dans le cadre
        "CARTOGRAPHIE INDICATIVE DES OBLIGATIONS LÉGALES DE DÉBROUSSAILLEMENT", # Texte principal
        class = "titre-avertissement-principal"                                 # Classe CSS du titre principal
      ),

      # ───────────────────────────────────────────────────────────────────────
      # SOUS-TITRE DU MODULE
      # ───────────────────────────────────────────────────────────────────────
      shiny::tags$h3(                                                           # Sous-titre H3
        "Avertissements et informations préalables",                            # Contenu textuel
        class = "titre-avertissement-sous"                                      # Style CSS specifique
      ),

      # ───────────────────────────────────────────────────────────────────────
      # CONTENU STATIQUE HTML INTÉGRÉ EN IFRAME
      # ───────────────────────────────────────────────────────────────────────
      shiny::tags$iframe(                                                       # Iframe integree dans l UI
        src   = "www/html/avertissement.html",                                  # Fichier HTML statique à afficher
        width = "100%",                                                         # Largeur : pleine largeur du conteneur
        height = "100%",                                                        # Hauteur fill mais min-height definie ci-dessous
        class = "bloc-avertissement-iframe",                                    # Classe CSS personnalisee
        style  = "border: none; min-height: 75vh; background-color: cornsilk",  # Style inline pour garantir affichage (pas de bordures,hauteur minimum, couleur de fond)
        loading = "lazy",                                                       # Chargement differe pour optimisation performance
        title = "Avertissements liés à l'outil cartOLD"                         # Titre descriptif
      )
    )
  )
}



# ──────────────────────────────────────────────────────────────────────────────
# SERVEUR DU MODULE AVERTISSEMENT
# ──────────────────────────────────────────────────────────────────────────────
#' Serveur du module Avertissement
#'
#' Module serveur associe à l'UI.
#' Le module ne contient **aucune logique reactive**, car le contenu
#' est entièrement statique (HTML externalise).
#'
#' @param id Identifiant du module
#'
#' @return Aucun retour attendu (effets de bord uniquement)
#'
#' @importFrom shiny moduleServer
#'
#' @noRd
mod_avertissement_server <- function(id) {                                      # Fonction serveur du module Avertissement
  shiny::moduleServer(id, function(input, output, session) {                    # Declaration du module serveur
    # ─────────────────────────────────────────────────────────────────────────
    # MODULE STATIQUE :
    # Pas d'observeEvent, pas de reactive, pas de renderUI.
    # L'iframe charge le contenu HTML sans interaction côte serveur.
    # ─────────────────────────────────────────────────────────────────────────
  })
}

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU FICHIER
# ──────────────────────────────────────────────────────────────────────────────
