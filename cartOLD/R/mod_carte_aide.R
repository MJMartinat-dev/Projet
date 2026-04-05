# ──────────────────────────────────────────────────────────────────────────────
# FICHIER     : mod_carte_aide.R
# AUTEUR      : MJ Martinat
# DATE        : 2025
# ORGANISATION: DDT de la Drôme
# DESCRIPTION : Module tutoriel interactif pour cartOLD
#               Overlay style Géoportail avec bulles d'aide pointant vers
#               les contrôles de la carte (zoom, légende, échelles, fonds)
#               Contrôlé par bouton "Afficher l'aide" dans le sidebar
# ──────────────────────────────────────────────────────────────────────────────
# INTERFACE DU MODULE AIDE CARTE (UI)
# ──────────────────────────────────────────────────────────────────────────────
#' UI du module aide carte
#'
#' Génère l'overlay tutoriel transparent avec bulles d'aide
#' pointant vers les différents contrôles cartographiques.
#' L'overlay est initialement caché (classe CSS "hidden") et affiché
#' via un message custom ou un input Shiny.
#'
#' @param id Identifiant du namespace du module
#'
#' @return Un tagList contenant l'overlay d'aide
#'
#' @importFrom shiny NS tagList tags HTML
#'
#' @export
mod_carte_aide_ui <- function(id) {
  ns <- shiny::NS(id)                                                           # Cree un namespace unique pour tous les ids HTML du module

  shiny::tagList(                                                               # Regroupe l ensemble des elements UI dans une liste de tags
    # ── OVERLAY TUTORIEL GLOBAL ─────────────────────────────────────────
    shiny::tags$div(
      id = ns("aide_overlay"),                                                  # Id HTML de l overlay, namespace pour eviter les collisions
      class = "aide-carte-overlay hidden",                                      # Classe principale + 'hidden' pour le masquer par defaut

      # ── Fond semi-transparent blanc recouvrant la carte (backdrop) ────
      shiny::tags$div(
        class = "aide-backdrop"                                                 # Element de fond (overlay blanc ou semi-transparent)
      ),

      # ── BULLE : ZOOM ──────────────────────────────────────────────────
      shiny::tags$div(
        class = "help-bubble help-bubble-zoom",                                 # Bulle associée à la zone de zoom Leaflet
        shiny::tags$img(
          src = "www/images/aide_fleche_droite.png",                            # Fleche orientee vers les boutons de zoom
          class = "help-arrow arrow-to-zoom",                                   # Classe pour le style et la position de la fleche
          alt = "Flèche vers zoom"                                              # Texte alternatif pour accessibilite
        ),
        shiny::tags$div(
          class = "help-content",                                               # Conteneur du texte de la bulle
          shiny::tags$span(class = "help-strong", "Zoomer"),                    # Titre de la bulle en style "fort"
          shiny::tags$br(),                                                     # Saut de ligne
          "Utilisez les boutons + et - pour ajuster le niveau de zoom (agrandir et rétrécir) de la carte."  # Texte explicatif
        )
      ),

      # ── BULLE : LEGENDE ───────────────────────────────────────────────
      shiny::tags$div(
        class = "help-bubble help-bubble-legende",                              # Bulle positionnee pres du controle de legende
        shiny::tags$img(
          src = "www/images/aide_fleche_gauche.png",                            # Fleche orientee vers la legende
          class = "help-arrow arrow-to-legende",                                # Classe pour style/position de la fleche
          alt = "Flèche vers légende"                                           # Texte alternatif
        ),
        shiny::tags$div(
          class = "help-content",                                               # Contenu textuel de l aide pour la legende
          shiny::tags$span(class = "help-strong", "Légende"),                   # Titre de la bulle
          shiny::tags$br(),                                                     # Saut de ligne
          "Affichez la légende pour identifier les différentes couches visibles sur la carte."  # Texte d'explication
        )
      ),

      # ── BULLE : ECHELLES ──────────────────────────────────────────────
      shiny::tags$div(
        class = "help-bubble help-bubble-echelles",                             # Bulle associee aux echelles cartographiques
        shiny::tags$img(
          src = "www/images/aide_fleche_droite.png",                            # Fleche orientee vers le controle d echelles
          class = "help-arrow arrow-to-echelles",                               # Classe de style / position
          alt = "Flèche vers échelles"                                          # Texte alternatif
        ),
        shiny::tags$div(
          class = "help-content",                                               # Bloc texte pour la bulle echelles
          shiny::tags$span(class = "help-strong", "Échelles"),                  # Titre de la bulle
          shiny::tags$br(),                                                     # Saut de ligne
          "Consultez les échelles numérique et graphique pour évaluer les distances."  # Message explicatif
        )
      ),

      # ── BULLE : FONDS DE CARTE ────────────────────────────────────────
      shiny::tags$div(
        class = "help-bubble help-bubble-fonds",                                # Bulle pour les fonds de carte (OSM / IGN / Ortho)
        shiny::tags$img(
          src = "www/images/aide_fleche_gauche.png",                            # Flèche orientee vers le selecteur de fonds
          class = "help-arrow arrow-to-fonds",                                  # Classe pour style et ancrage
          alt = "Flèche vers fonds"                                             # Texte alternatif
        ),
        shiny::tags$div(
          class = "help-content",                                               # Conteneur du texte de la bulle
          shiny::tags$span(class = "help-strong", "Fonds de carte"),            # Titre de la bulle fonds
          shiny::tags$br(),                                                     # Saut de ligne
          "Changez le fond de carte entre OSM, IGN Plan et IGN Orthophoto."     # Texte explicatif des options de fond
        )
      ),

      # ── LIEN CENTRAL VERS AIDE COMPLETE ─────────────────────────────────
      shiny::tags$div(
        class = "help-center-link",                                             # Bloc central affichant un bouton vers l aide complete
        shiny::tags$a(
          href = "#",                                                           # Lien neutre (action geree en JS / Shiny)
          class = "btn-aide-complete",                                          # Classe bouton d aide complete
          onclick = sprintf("Shiny.setInputValue('%s', Math.random()); return false;", ns("goto_aide")), # Envoie un input goto_aide cote serveur
          shiny::tags$i(class = "fa fa-book"),                                  # Icone livre (Font Awesome)
          " Accéder à l'aide complète"                                          # Libelle du lien
        ),
        shiny::tags$p(
          class = "help-center-subtitle",                                       # Sous-texte sous le bouton
          "Consultez l'onglet Aide pour plus d'informations sur les logos et fonctionnalités." # Texte d'explication
        )
      ),

      # ── BOUTON FERMER ───────────────────────────────────────────────────
      shiny::tags$button(
        class = "btn-fermer-aide",                                              # Classe CSS du bouton de fermeture de l'overlay
        onclick = sprintf("Shiny.setInputValue('%s', Math.random()); return false;", ns("close_aide")), # Envoie un input close_aide cote serveur
        shiny::tags$i(class = "fa fa-times"),                                   # Icone croix (Font Awesome)
        " Fermer"                                                               # Libellé du bouton
      )
    )
  )
}

# ──────────────────────────────────────────────────────────────
# SERVEUR DU MODULE AIDE CARTE
# ──────────────────────────────────────────────────────────────
#' Serveur du module aide carte
#'
#' Gere l affichage/masquage de l overlay tutoriel
#' et la navigation vers l onglet aide via reactiveValues.
#'
#' @param id Identifiant du namespace du module
#' @param r reactiveValues partage pour communication avec app_server
#'
#' @importFrom shiny moduleServer observeEvent
#'
#' @export
mod_carte_aide_server <- function(id, r = NULL) {
  shiny::moduleServer(id, function(input, output, session) {                    # Declare le module serveur avec l id fourni
    ns <- session$ns                                                            # Récupère la fonction de namespacing associee a la session

    # ── Fermeture de l'overlay ─────────────────────────────────────────────
    shiny::observeEvent(input$close_aide, {                                     # Observe les clics / evenements sur l input close_aide
      session$sendCustomMessage(                                                # Envoie un message custom cote client (JS)
        "toggleAideCarte",                                                      # Nom du handler JS (doit etre défini cote front)
        list(id = ns("aide_overlay"), show = FALSE)                             # Donnees envoyees : id de l overlay + flag show = FALSE (cacher)
      )
    }, ignoreInit = TRUE)                                                       # ignoreInit=TRUE : ne pas declencher a l initialisation

    # ── Navigation vers onglet Aide via reactiveValues ─────────────────────
    shiny::observeEvent(input$goto_aide, {                                      # Observe les clics / evenements sur le lien "aide complete"
      # ── Fermer l overlay avant la navigation ─────────────────────────────
      session$sendCustomMessage(
        "toggleAideCarte",                                                      # Meme handler JS que precedemment
        list(id = ns("aide_overlay"), show = FALSE)                             # Demande au front de masquer l overlay
      )

      # ── Signaler a app_server de changer d onglet ────────────────────────
      if (!is.null(r)) {                                                        # Verifie que l objet reactiveValues partage est disponible
        r$navigate_to_aide <- Sys.time()                                        # Stocke la date/heure actuelle pour declencher un observeEvent cote app_server
      }
    }, ignoreInit = TRUE)                                                       # Évite tout declenchement a la creation de la session
  })
}

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU FICHIER
# ──────────────────────────────────────────────────────────────────────────────
