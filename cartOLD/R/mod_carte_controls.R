# ──────────────────────────────────────────────────────────────────────────────
# FICHIER     : mod_carte_controls.R
# AUTEUR      : MJ Martinat
# DATE        : 2025
# ORGANISATION: DDT de la Drôme
# DESCRIPTION : Module UI des contrôles cartographiques flottants (cartOLD)
#               Composants affichés par-dessus la carte Leaflet :
#               - Échelle numérique
#               - Échelle graphique
#               - Rose des vents
#               - Bouton Légende + panneau dynamique
#               Version compatible shinyapps.io
# ──────────────────────────────────────────────────────────────────────────────
# INTERFACE DU MODULE CONTROLES DE LA CARTE (UI)
# ──────────────────────────────────────────────────────────────────────────────
#' UI - Controles cartographiques flottants
#'
#' Genere tous les elements d interface superposes a la carte :
#' - Échelle numérique (1:xxxxx)
#' - Échelle graphique
#' - Indicateur Nord
#' - Panneau de legende dynamique
#'
#' @param id Identifiant du module (namespace interne via NS)
#'
#' @return Un objet `tagList()` contenant tous les contrôles UI
#'
#' @importFrom shiny NS tagList tags actionButton uiOutput icon textInput
#' @importFrom magrittr %>%
#'
#' @noRd
mod_carte_controls_ui <- function(id) {                                         # Debut de la fonction UI
  ns <- shiny::NS(id)                                                           # Création du namespace pour isoler tous les IDs

  shiny::tagList(                                                               # Conteneur global qui regroupe tous les controles superposes

    # ─── OUTILS DE MESURE DE DISTANCE ─────────────────────────────
    shiny::tags$div(                                                            # Conteneur des boutons mesure
      id    = ns("bloc_mesure"),                                                # ID unique
      class = "ctrl-mesure-distance",                                           # Classe CSS pour positionnement

      # Bouton activer/désactiver mesure
      shiny::tags$button(                                                       # Bouton mesure principal
        id       = ns("btn_mesure"),                                            # ID du bouton
        class    = "btn-mesure leaflet-bar",                                    # Classes CSS
        title
        = "Mesurer une distance (clic pour activer)",
        type     = "button",                                                    # Type bouton
        shiny::tags$i(class = "fa fa-ruler")                                    # Icône règle FontAwesome
      ),

      # Bouton effacer les mesures
      shiny::tags$button(                                                       # Bouton effacer
        id       = ns("btn_mesure_clear"),                                      # ID du bouton
        class    = "btn-mesure-clear leaflet-bar",                              # Classes CSS
        title    = "Effacer toutes les mesures",                                # Tooltip
        type     = "button",                                                    # Type bouton
        shiny::tags$i(class = "fa fa-trash")                                    # Icône poubelle
      )
    ),

    # ─── ECHELLE NUMERIQUE ──────────────────────────────────────
    shiny::tags$div(                                                            # Bloc contenant l echelle numerique
      id    = ns("bloc_echelle_num"),                                           # ID unique du bloc
      class = "ctrl-echelle-num",                                               # Classe CSS positionnant l element sur la carte

      shiny::tags$form(                                                         # Utilisation d un <form> pour une structuration propre
        class = "form-echelle-numerique",                                       # Classe CSS du formulaire
        shiny::tags$span("Échelle "),                                           # Label avant la valeur
        shiny::HTML("1:"),                                                      # Prefixe fixe "1:"
        shiny::tags$input(                                                      # Champ texte affichant la valeur numerique
          id       = ns("echelle_num_valeur"),                                  # ID (namespace)
          type     = "text",                                                    # Type input HTML
          value    = "50000",                                                   # Valeur affichee par defaut
          readonly = "readonly",                                                # Verrouille l edition (valeur maj via JS)
          title    = "Échelle numérique de la carte"                            # Texte descriptif
        )                                                                       # Fin <input>
      )                                                                         # Fin <form>
    ),                                                                          # Fin conteneur echelle numerique

    # ─── ECHELLE GRAPHIQUE ──────────────────────────────────────
    shiny::tags$div(                                                            # Bloc general de l echelle graphique
      id    = ns("bloc_echelle_graph"),                                         # ID unique
      class = "ctrl-echelle-graph",                                             # Classe CSS de positionnement

      shiny::tags$div(                                                          # Conteneur de la barre graphique segmentee
        class = "barre-echelle-graph",                                          # Classe CSS personnalisee
        shiny::tags$div(class = "segment-black"),                               # Segment noir de la barre
        shiny::tags$div(class = "segment-white")                                # Segment blanc de la barre
      ),

      shiny::tags$div(                                                          # Bloc contenant les labels de longueur
        class = "labels-echelle-graph",                                         # Classe CSS
        shiny::tags$span("0"),                                                  # Origine de l echelle
        shiny::tags$span(                                                       # Valeur dynamique actualisee par JS
          id = ns("echelle_graph_valeur"),                                      # ID unique
          "1000 m"                                                              # Valeur initiale affichee
        )
      )
    ),                                                                          # Fin echelle graphique

    # ─── ROSE DES VENTS (INDICATEUR NORD) ───────────────────────
    shiny::tags$div(                                                            # Conteneur indicateur du Nord
      id    = ns("rose_vents"),                                                 # ID (namespace)
      class = "indicateur-nord",                                                # Classe CSS pour position flottante
      title = "Indicateur du Nord géographique",                                # Texte descriptif

      shiny::tags$div(class = "north-label", "N"),                              # Lettre « N » affichee
      shiny::tags$div(class = "north-arrow")                                    # Petite fleche indiquant le Nord
    ),                                                                          # Fin rose des vents

    # ─── BOUTON LEGENDE + PANNEAU DYNAMIQUE ─────────────────────
    shiny::tags$div(                                                            # Conteneur general du systeme de legende
      id    = ns("bloc_legende"),                                               # ID unique (namespace)
      class = "ctrl-legende",                                                   # Positionnement CSS

      shiny::actionButton(                                                      # Bouton bascule legende
        inputId = ns("bouton_legende"),                                         # ID du bouton
        label   = "Légende",                                                    # Texte affiche
        icon    = shiny::icon("list"),                                          # Icone FontAwesome
        class   = "btn-legende",                                                # Classe CSS
        title   = "Afficher/masquer la legende"                                 # Tooltip
      ),

      shiny::tags$div(                                                           # Panneau deroulant masque par défaut
        id    = ns("panneau_legende"),                                           # ID unique
        class = "panneau-legende",                                               # Classe CSS
        style = "display: none;",                                                # Masque au chargement

        shiny::textInput(                                                        # Input invisible utilise comme trigger reactif
          inputId = ns("update_legende_toggle"),                                 # ID
          label   = NULL,                                                        # Pas de label
          value   = "",                                                          # Valeur vide
          width   = "0px"                                                        # Largeur nulle
        ) %>%
          shiny::tagAppendAttributes(style = "display: none;"),              # Rend l input totalement invisible

        shiny::uiOutput(                                                         # Contenu dynamique genere cote serveur
          outputId = ns("contenu_legende")                                       # ID de sortie UI
        )
      )                                                                           # Fin panneau
    )                                                                             # Fin bloc legende
  )                                                                               # Fin tagList global
}                                                                                 # Fin fonction UI

# ──────────────────────────────────────────────────────────────
# SERVEUR DU MODULE CONTROLES DE LA CARTE
# ──────────────────────────────────────────────────────────────
#' Serveur - Contrôles cartographiques flottants
#'
#' Gère les interactions avec les contrôles superposés :
#' - Ouverture/fermeture du panneau legende (via shinyjs::toggle)
#' - Rendu DYNAMIQUE du contenu de la legende basé sur les couches affichées
#'
#' @param id Identifiant namespace du module
#' @param input_couches Reactive() retournant les couches sélectionnées
#' @param old50m_data Reactive() retournant les données OLD50m (pour gradient)
#'
#' @return Aucun objet retourné (effets secondaires sur le DOM)
#'
#' @family modules cartOLD
#'
#' @importFrom shiny moduleServer observeEvent observe renderUI tags tagList updateTextInput req
#' @importFrom shinyjs toggle
#'
#' @noRd
mod_carte_controls_server <- function(id, r) {                                  # Début fonction serveur du module
  shiny::moduleServer(id, function(input, output, session) {                    # Déclaration moduleServer
    ns <- session$ns                                                            # Raccourci namespace


    # ── GESTION BOUTON LEGENDE ──────────────────────────────────────────
    shiny::observeEvent(input$bouton_legende, {                                 # Observe clic bouton legende
      shinyjs::toggle(                                                          # Appelle shinyjs pour basculer affichage
        id       = "panneau_legende",                                           # ID du panneau a afficher/masquer
        anim     = TRUE,                                                        # Animation activee
        animType = "slide",                                                     # Animation type slide
        time     = 0.3                                                          # Durée 0.3 sec
      )
    }, ignoreInit = TRUE)                                                       # Ignore premier declenchement

    # ── DECLENCHEUR DE RAFRAICHISSEMENT ─────────────────────────────────
    shiny::observe({                                                            # Observe reactivite : declenche update legende
      r$couches_select                                                          # Dépendance réactive (ne rien écrire ici)
      shiny::updateTextInput(                                                   # Force actualisation valeur toggle
        session = session,                                                      # Session en cours
        inputId = "update_legende_toggle",                                      # ID de l input cache
        value   = as.character(Sys.time())                                      # Nouvelle valeur = timestamp pour declench.
      )
    })

    # ── CONTENU DYNAMIQUE DE LA LEGENDE ─────────────────────────────────
    output$contenu_legende <- shiny::renderUI({                                 # Rendu UI dynamique de la legende
      shiny::req(input$update_legende_toggle)                                   # Exige la mise à jour du toggle

      couches <- r$couches_select %||% character(0)                             # Recupere couches selectionnees ou vecteur vide

      legende <- list()                                                         # Initialise la liste d’elements legende

      # ── Département ─────────────────────────────────
      if ("dept_lim" %in% couches) {                                            # Si limite departement activee
        legende <- c(legende, list(                                             # Ajoute item legende
          shiny::tags$div(                                                      # Bloc item legende
            class = "legende-item",                                             # Classe CSS de la legende
            shiny::tags$span(                                                   # Symbole graphique de la legende
              class = "legende-symbole",                                        # Classe css du symbole
              style = "border: 2.8px solid red;
                       background: transparent;"
            ),
            "Limites d\u00e9partementales"                                      # Libelle de la legende
          )
        ))
      }

      # ── Communes ───────────────────────────────────
      if ("communes_lim" %in% couches) {                                        # Si limite communes activee
        legende <- c(legende, list(                                             # Ajoute item legende
          shiny::tags$div(                                                      # Bloc item legende
            class = "legende-item",                                             # Classe css de la legende
            shiny::tags$span(                                                   # Symbole graphique de la legende
              class = "legende-symbole",                                        # Classe css du symbole des communes
              style = "border: 2px solid black;
                       background: transparent;"
            ),
            "Limites communales"                                                # Libelle de la legende
          )
        ))
      }

      # ── OLD 200M : zones a risques delimitees par la limite des 200m autour des massifs forestiers de plus de 0.5ha
      if ("old200" %in% couches) {                                              # Si couche OLD 200m activee
        legende <- c(legende, list(                                             # Ajoute item legende
          shiny::tags$div(                                                      # Bloc item legende
            class = "legende-item",                                             # Classe css de la legende
            shiny::tags$span(                                                   # Symbole graphique legende
              class = "legende-symbole",                                        # Classe du symbole OLD 200m
              style = "border: 2px dashed blue;
                       background: rgba(0, 0, 225, 0.25);"
            ),
            "Zones à risques (OLD 200m)"                                        # Libelle de la legende
          )
        ))
      }

      # ── OLD50M : Zones à débroussailler (résultats) ─
      if ("old50m" %in% couches) {                                              # Affiche gradient si OLD 50m visible
        gradient_id <- "gradient-old50m"                                        # ID gradient SVG
        legende <- c(legende, list(                                             # Ajoute item legende
          shiny::tags$div(                                                      # Item legende
            class = "legende-item",                                             # Classe css de la legende
            shiny::tags$svg(
              width   = 27,
              height  = 16,
              viewBox = "0 0 27 16",
              style   = "margin-right: 8px;",

              # --- GRAND DISQUE BLEU (droite) ---
              shiny::tags$circle(
                cx = 20, cy = 10, r = 10,
                fill = "#6D7EC3",
                stroke = "black",
                `stroke-width` = 1.8
              ),

              # --- DISQUE CENTRAL BEIGE ---
              shiny::tags$circle(
                cx = 11, cy = 12, r = 7,
                fill = "#E8DFB5",
                stroke = "black",
                `stroke-width` = 1.8
              ),

              # --- QUART DE DISQUE ROUGE EN HAUT GAUCHE ---
              shiny::tags$path(
                d = "M0,0 L14,0 A14,14 0 0,1 0,14 Z",
                fill = "#E78080",
                stroke = "black",
                `stroke-width` = 1.8
              ),

              # --- CONTOUR EXTERNE ---
              shiny::tags$rect(
                x = 0, y = 0, width = 27, height = 16,
                fill = "none",
                stroke = "black",
                `stroke-width` = 2
              )
            ),
            shiny::tags$span("Zones \u00e0 d\u00e9broussailler (OLD50m)")       # Libelle de la legende
          )
        ))
      }

      # ── Limites parcellaires ────────────────────────
      if ("parcelle_lim" %in% couches) {                                        # Si parcelles selectionnees
        legende <- c(legende, list(                                             # Ajoute item legende
          shiny::tags$div(                                                      # Item legende
            class = "legende-item",                                             # Classe css de la legende
            shiny::tags$span(                                                   # Symbole graphique legende
              class = "legende-symbole",                                        # Classe css du symbole parcelles
              style = "border: 2px solid #ff6a00;
                       background: transparent;"
            ),
            "Limites parcellaires"                                              # Libelle de la legende
          )
        ))
      }

      # ── Bâtiments de la BD Topo ─────────────────────
      if ("batis" %in% couches) {                                               # Si batiments affiches
        legende <- c(legende, list(                                             # Ajoute item legende
          shiny::tags$div(                                                      # Item legende
            class = "legende-item",                                             # Classe css de la legende
            shiny::tags$span(                                                   # Symbole graphique de la legende
              class = "legende-symbole",                                        # Classe css du symbole bâtiment
              style = "border: 1px solid #ffa400;
                       background: #ffa400;"
            ),
            "B\u00e2timents"                                                    # Libelle de la legende
          )
        ))
      }

      # ── Zonage urbain (PLU) ────────────────────────
      if ("ZU" %in% couches) {                                                  # Si zonage urbain visible
        legende <- c(legende, list(                                             # Ajoute item legende
          shiny::tags$div(                                                      # Item legende
            class = "legende-item",                                             # Classe css de la legende
            shiny::tags$span(                                                   # Symbole graphique de la legende
              class = "legende-symbole",                                        # Classe css du symbole PLU
              style = "border: 2.8px dashed black;
                       background: transparent;"
            ),
            "Zonage urbain (PLU)"                                               # Libelle de la legende
          )
        ))
      }

      if (length(legende) == 0) {                                               # Si aucune couche sélectionnée
        return(                                                                 # Retourne
          shiny::tags$div(                                                      # Item legende vide
            class = "legende-vide",                                             # Classe de la legende vide
            style = "color: #666;
                     font-style: italic;
                     text-align: center;
                     padding: 20px;",
            "Aucune couche s\u00e9lectionn\u00e9e"                              # Message utilisateur
          )
        )
      }

      shiny::tags$div(                                                          # Conteneur final legende
        class = "legende-container",                                            # Classe CSS
        shiny::tags$h4(class = "legende-titre", "Légende des couches"),         # Titre legende
        shiny::tags$div(                                                        # Conteneur des items
          class = "legende-items",                                              # Classe css de la legende
          style = "font-size: 0.95em;
                   line-height: 1.6;",                                          # Style interne
          legende                                                               # Injection liste items
        )
      )
    })
  })
}                                                                               # Fin module serveur

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU FICHIER
# ──────────────────────────────────────────────────────────────────────────────
