# ──────────────────────────────────────────────────────────────────────────────
# FICHIER     : mod_carte.R
# AUTEUR      : MJ Martinat
# DATE        : 2025
# ORGANISATION: DDT de la Drôme
# DESCRIPTION : Module carte interactive Leaflet (cartOLD)
#               - Carte Leaflet plein écran
#               - Sidebar : commune, adresse, couches, export
#               - Intégration contrôles custom via mod_carte_controls
#               - CDN Leaflet + EasyButton
#               Version DÉPLOIEMENT DIRECT sur shinyapps.io
# ──────────────────────────────────────────────────────────────────────────────
# INTERFACE UTILISATEUR DU MODULE CARTE
# ──────────────────────────────────────────────────────────────────────────────
#' UI du module Carte
#'
#' Genere l interface utilisateur de la carte :
#' - Conteneur principal (sidebar + zone carte)
#' - Carte Leaflet plein écran
#' - Intégration du module de contrôles custom
#' - Modale d export
#'
#' @param id Identifiant du module (namespace)
#'
#' @return Un objet `shiny.tag.list`
#'
#' @importFrom shiny tagList div HTML selectInput actionButton textInput numericInput
#' @importFrom shiny checkboxGroupInput uiOutput icon br tags NS tableOutput
#' @importFrom shinyjs useShinyjs hidden
#' @importFrom leaflet leafletOutput
#'
#' @export
mod_carte_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    shiny::div(
      id = "content-app",

      # ═══════════════════════════════════════════════════════════════
      # BARRE DE NAVIGATION VERTICALE (STYLE LIZMAP)
      # ═══════════════════════════════════════════════════════════════
      shiny::div(
        id = "mapmenu",
        class = "mapmenu",

        # Bouton hamburger toggle
        shiny::tags$div(
          id = "menuToggle",
          class = "menu-toggle-btn",
          title = "Afficher/masquer le panneau",
          shiny::tags$span(),
          shiny::tags$span(),
          shiny::tags$span()
        ),

        # Liste des boutons de navigation
        shiny::tags$ul(
          class = "nav-list",

          # Bouton Aide (i)
          shiny::tags$li(
            class = "nav-item",
            shiny::actionButton(
              inputId = ns("btn_nav_aide"),
              label = NULL,
              icon = shiny::icon("circle-info"),
              class = "nav-btn",
              title = "Aide"
            )
          ),

          # Bouton Localisation
          shiny::tags$li(
            class = "nav-item",
            shiny::actionButton(
              inputId = ns("btn_nav_loc"),
              label = NULL,
              icon = shiny::icon("location-dot"),
              class = "nav-btn",
              title = "Localisation"
            )
          ),

          # Bouton Couches
          shiny::tags$li(
            class = "nav-item",
            shiny::actionButton(
              inputId = ns("btn_nav_layer"),
              label = NULL,
              icon = shiny::icon("layer-group"),
              class = "nav-btn",
              title = "Couches"
            )
          ),

          # Bouton Outils
          shiny::tags$li(
            class = "nav-item",
            shiny::actionButton(
              inputId = ns("btn_nav_outils"),
              label = NULL,
              icon = shiny::icon("ruler-combined"),
              class = "nav-btn",
              title = "Outils de mesure"
            )
          ),

          # Bouton Export
          shiny::tags$li(
            class = "nav-item",
            shiny::actionButton(
              inputId = ns("btn_nav_export"),
              label = NULL,
              icon = shiny::icon("file-export"),
              class = "nav-btn",
              title = "Exporter"
            )
          )
        )
      ),

      # ═══════════════════════════════════════════════════════════════
      # PANNEAU DOCK (CONTENU DES ONGLETS)
      # ═══════════════════════════════════════════════════════════════
      shiny::div(
        id = ns("dock"),
        class = "dock",

        # Bouton fermer le dock
        shiny::tags$button(
          id = ns("dock_close"),
          class = "dock-close-btn",
          type = "button",
          shiny::icon("times")
        ),

        # ── PANNEAU AIDE ─────────────────────────────────────────────
        shiny::div(
          id = ns("panel_aide"),
          class = "dock-panel",
          `data-panel` = "aide",

          shiny::tags$h4(
            shiny::icon("circle-info"),
            " Aide",
            class = "panel-title"
          ),

          shiny::tags$div(
            class = "panel-content",
            shiny::tags$p("Bienvenue dans l'application cartOLD."),
            shiny::tags$p("Cliquez sur le bouton ci-dessous pour afficher l'aide interactive sur la carte."),
            shiny::br(),
            shiny::actionButton(
              inputId = ns("show_Aide"),
              label = "Afficher l'aide sur la carte",
              icon = shiny::icon("question-circle"),
              class = "btn-primary btn-block"
            )
          )
        ),

        # ── PANNEAU LOCALISATION ─────────────────────────────────────
        shiny::div(
          id = ns("panel_localisation"),
          class = "dock-panel",
          `data-panel` = "localisation",

          shiny::tags$h4(
            shiny::icon("location-dot"),
            " Localisation",
            class = "panel-title"
          ),

          shiny::tags$div(
            class = "panel-content",

            shiny::selectInput(
              inputId = ns("commune_select"),
              label = "Choix de la commune :",
              choices = NULL
            ),

            shiny::div(
              class = "btn-group-actions",
              shiny::actionButton(ns("commune_search"), "Valider", class = "btn-primary"),
              shiny::actionButton(ns("commune_reset"), NULL,
                                  icon = shiny::icon("rotate-left"),
                                  class = "btn-secondary",
                                  title = "Réinitialiser")
            ),

            shiny::br(),

            shiny::textInput(
              inputId = ns("adresse_input"),
              label = "Recherche d'adresse :",
              placeholder = "Tapez les 3 premières lettres"
            ),

            shiny::div(
              class = "btn-group-actions",
              shiny::actionButton(ns("adresse_search"), "Valider", class = "btn-primary"),
              shiny::actionButton(ns("adresse_reset"), NULL,
                                  icon = shiny::icon("rotate-left"),
                                  class = "btn-secondary",
                                  title = "Réinitialiser")
            ),

            shinyjs::hidden(
              shiny::textInput(ns("adresse_sel_label"), "", ""),
              shiny::numericInput(ns("adresse_sel_lon"), "", value = NULL),
              shiny::numericInput(ns("adresse_sel_lat"), "", value = NULL)
            )
          )
        ),

        # ── PANNEAU COUCHES ──────────────────────────────────────────
        shiny::div(
          id = ns("panel_couches"),
          class = "dock-panel",
          `data-panel` = "couches",

          shiny::tags$h4(
            shiny::icon("layer-group"),
            " Couches",
            class = "panel-title"
          ),

          shiny::tags$div(
            class = "panel-content",

            shiny::checkboxGroupInput(
              inputId = ns("couches_select"),
              label = "Choix des données :",
              choices = list(
                "Département"                 = "dept_lim",
                "Communes"                    = "communes_lim",
                "Zones forestières sensibles" = "old200",
                "Zone à débroussailler"       = "old50m",
                "Limites parcellaires"        = "parcelle_lim",
                "Bâtiments"                   = "batis",
                "Zone urbaine (PLU)"          = "ZU"
              ),
              selected = "dept_lim"
            )
          )
        ),

        # ── PANNEAU OUTILS ───────────────────────────────────────────
        shiny::div(
          id = ns("panel_outils"),
          class = "dock-panel",
          `data-panel` = "outils",

          shiny::tags$h4(
            shiny::icon("ruler-combined"),
            " Outils de mesure",
            class = "panel-title"
          ),

          shiny::tags$div(
            class = "panel-content",

            shiny::tags$p(
              class = "outils-instructions",
              shiny::icon("info-circle"),
              " Utilisez les boutons sur la carte pour mesurer des distances."
            ),

            shiny::tags$div(
              class = "outils-legende",
              shiny::tags$p(shiny::tags$strong(shiny::tags$i(class = "fa fa-ruler"), ":"), " Cliquez sur la carte pour ajouter des points."),
              shiny::tags$p(shiny::tags$strong("Double-clic :"), " Terminer la mesure en cours."),
              shiny::tags$p(shiny::tags$strong(shiny::tags$i(class = "fa fa-trash"), ":"), " Annuler la mesure en cours.")
            ),

            shiny::br(),

            shiny::tags$div(
              id = ns("mesure_resultat"),
              class = "mesure-resultat-box",
              shiny::tags$h5("Résultat de mesure"),
              shiny::tags$div(
                id = ns("mesure_valeur"),
                class = "mesure-valeur",
                "Aucune mesure en cours"
              )
            )
          )
        ),

        # ── PANNEAU EXPORT ───────────────────────────────────────────
        shiny::div(
          id = ns("panel_export"),
          class = "dock-panel",
          `data-panel` = "export",

          shiny::tags$h4(
            shiny::icon("file-export"),
            " Export",
            class = "panel-title"
          ),

          shiny::tags$div(
            class = "panel-content",
            mod_carte_export_ui(ns("export"))
          )
        )
      ),

      # ═══════════════════════════════════════════════════════════════
      # ZONE CARTE
      # ═══════════════════════════════════════════════════════════════
      shiny::div(
        id = "carte_zone",
        class = "conteneur-carte",

        leaflet::leafletOutput(ns("carte"), "100%", "100%"),
        mod_carte_controls_ui(ns("controls")),
        mod_carte_aide_ui(ns("aide_ui")),
        shiny::uiOutput(ns("modal_preview"))
      )
    )
  )
}

# ==============================================================================
# MODULE SERVEUR - CARTE
# ==============================================================================
#' Serveur du module Carte (cartOLD)
#'
#' @param id Identifiant du namespace du module
#' @param r  reactiveValues partagé entre modules (état global)
#'
#' @return Aucun objet (module à effets de bord uniquement)
#'
#' Imports nécessaires pour l'ensemble des opérations Shiny, Leaflet, sf, dplyr,
#' et génération d'exports (PNG/PDF).
#'
#' @importFrom shiny moduleServer reactive reactiveVal reactiveValues req observe
#' @importFrom shiny renderUI updateSelectInput updateTextInput showNotification
#' @importFrom shiny modalDialog downloadHandler observeEvent withProgress
#' @importFrom leaflet renderLeaflet leaflet leafletOptions addTiles tileOptions
#' @importFrom leaflet addLayersControl layersControlOptions leafletProxy clearGroup
#' @importFrom leaflet showGroup hideGroup fitBounds flyTo addMarkers colorFactor
#' @importFrom leaflet addPolygons
#' @importFrom htmlwidgets onRender
#' @importFrom shinyjs delay toggle click
#' @importFrom sf st_transform st_geometry_type st_bbox st_make_valid st_buffer
#' @importFrom sf st_is_empty st_geometry st_union st_centroid st_coordinates
#' @importFrom sf sf_use_s2
#' @importFrom dplyr filter arrange mutate distinct group_by summarise
#' @importFrom stats setNames
#' @importFrom RColorBrewer brewer.pal
#' @importFrom grDevices colorRampPalette
#' @importFrom magrittr %>%
#' @importFrom base64enc base64decode
#' @importFrom rmarkdown render pdf_document
#'
#' @noRd
mod_carte_server <- function(id, r) {

  shiny::moduleServer(id, function(input, output, session) {

    ns <- session$ns                                                            # Namespace local → garantit unicité des IDs dans le module

    # ══════════════════════════════════════════════════════════════════
    # NAVIGATION PANNEAUX (STYLE LIZMAP)
    # ══════════════════════════════════════════════════════════════════

    # Panneau actuellement actif (NULL = fermé)
    active_panel <- shiny::reactiveVal(NULL)

    # Fonction pour ouvrir un panneau
    open_panel <- function(panel_name) {
      session$sendCustomMessage("closeDockPanels", list())
      session$sendCustomMessage("openDockPanel", list(
        panel = panel_name,
        dockId = ns("dock")
      ))
      active_panel(panel_name)
    }

    # Fonction pour fermer le dock
    close_dock <- function() {
      session$sendCustomMessage("closeDock", list(dockId = ns("dock")))
      active_panel(NULL)
    }

    # Bouton fermer le dock
    observeEvent(input$dock_close, {
      close_dock()
    })

    # ── NAVIGATION PAR BOUTONS ─────────────────────────────────────────
    observeEvent(input$btn_nav_aide, {
      if (identical(active_panel(), "aide")) {
        close_dock()
      } else {
        open_panel("aide")
      }
    })

    observeEvent(input$btn_nav_loc, {
      if (identical(active_panel(), "localisation")) {
        close_dock()
      } else {
        open_panel("localisation")
      }
    })

    observeEvent(input$btn_nav_layer, {
      if (identical(active_panel(), "couches")) {
        close_dock()
      } else {
        open_panel("couches")
      }
    })

    observeEvent(input$btn_nav_outils, {
      if (identical(active_panel(), "outils")) {
        close_dock()
      } else {
        open_panel("outils")
      }
    })

    observeEvent(input$btn_nav_export, {
      if (identical(active_panel(), "export")) {
        close_dock()
      } else {
        open_panel("export")
      }
    })

    # ══════════════════════════════════════════════════════════════════
    # INTEGRATION SOUS-MODULES
    # ══════════════════════════════════════════════════════════════════
    mod_carte_controls_server("controls", r = r)
    mod_carte_aide_server("aide_ui", r = r)

    # ── Ouverture overlay aide (bulles avec flèches) ──────────────────
    shiny::observeEvent(input$show_Aide, {
      session$sendCustomMessage("toggleAideCarte", list(
        id = ns("aide_ui-aide_overlay"),
        show = TRUE
      ))
    })

    # ──────────────────────────────────────────────────────────────
    # CONFIG DEBUG
    # ──────────────────────────────────────────────────────────────
    DEBUG_MODE <- FALSE  # Flag de debug global
    log_debug <- function(...) {                                                # Fonction interne de log contrôlé
      if (DEBUG_MODE) message("[cartOLD] ", ...)
    }

    # ──────────────────────────────────────────────────────────────
    # CHARGEMENT DONNEES DE BASE
    # ──────────────────────────────────────────────────────────────
    layers <- import_data_cached()                                              # Import unique via cache performant

    departement     <- layers$departement                                       # Limite DDT – couche fixe
    communes        <- layers$communes                                          # Communes IGN
    communes_old200 <- layers$communes_old200                                   # Communes OLD200 (zone sensible)
    old200          <- layers$old200                                            # Polygones OLD200 globaux

    # Harmonisation CRS + géometries valides pour toutes les couches fixes
    prepare_base_layer <- function(x) {
      if (is.null(x) || nrow(x) == 0) return(NULL)                              # Données absentes → aucune action

      x <- sf::st_make_valid(x)                                                 # Correction géométrique
      crs_epsg <- tryCatch(sf::st_crs(x)$epsg, error = function(e) NA_integer_)

      if (is.na(crs_epsg)) {
        sf::st_crs(x) <- 4326                                                   # Normalisation CRS par défaut
      } else if (crs_epsg != 4326) {
        x <- sf::st_transform(x, 4326)                                          # Harmonisation vers WGS84
      }

      x <- x[!sf::st_is_empty(x), , drop = FALSE]                               # Filtrage entités invalides
      x
    }

    # Extraction uniquement des géométries polygonales
    filter_polygons <- function(sfobj) {
      if (is.null(sfobj)) return(NULL)
      keep <- sf::st_geometry_type(sfobj) %in% c("POLYGON", "MULTIPOLYGON")
      sfobj[keep, , drop = FALSE]
    }

    # Application aux couches de base
    departement_wgs <- prepare_base_layer(departement)
    communes_wgs    <- prepare_base_layer(communes)
    old200_wgs      <- prepare_base_layer(old200)

    # Filtrage des géométries polygonales
    departement_poly <- filter_polygons(departement_wgs)
    communes_poly    <- filter_polygons(communes_wgs)
    old200_poly      <- filter_polygons(old200_wgs)

    # ──────────────────────────────────────────────────────────────
    # REACTIFS STRUCTURANTS (réacteur logique du module)
    # ──────────────────────────────────────────────────────────────
    r_communes            <- shiny::reactiveVal(communes_old200)                # Communes filtrées OLD200
    r_old200              <- shiny::reactiveVal(old200)                         # OLD200 global
    r_commune_courante    <- shiny::reactiveVal(NULL)                           # Commune sélectionnée
    auto_selection_en_cours <- shiny::reactiveVal(FALSE)                        # Flag anti-boucle sélection
    idu_precedent         <- shiny::reactiveVal(NULL)                           # [AJOUT] IDU précédent pour détection changement commune

    # IDU (identifiant commune) dérivé de la sélection courante
    idu_react <- shiny::reactive({
      commune_name <- r_commune_courante()
      shiny::req(commune_name)                                                  # Pas de commune → stop
      sel <- dplyr::filter(r_communes(), tex2 == commune_name)                  # Lookup commune dans table
      if (nrow(sel) > 0) as.character(sel$idu[1]) else NULL                     # Retourne IDU unique
    })

    # Suivi de l'état d'ajout des couches dynamiques Leaflet → évite double-add
    rv_layers <- shiny::reactiveValues(
      added = stats::setNames(
        as.list(rep(FALSE, 7)),
        c("dept_lim", "communes_lim", "old200", "old50m",
          "parcelle_lim", "batis", "ZU")
      )
    )

    # ──────────────────────────────────────────────────────────────
    # COMMUNES OLD200 → JS (contrainte BAN)
    # ──────────────────────────────────────────────────────────────
    # Envoie au front la liste complète des communes OLD200.
    shiny::observe({
      communes_codes <- r_communes() %>%
        dplyr::mutate(code_insee_complet = paste0("26", sprintf("%03d", as.numeric(idu)))) %>%
        dplyr::pull(code_insee_complet)

      session$sendCustomMessage(
        "setCommunesOld200",
        list(communes = communes_codes)
      )
    }) %>%
      shiny::bindEvent(r_communes(), once = TRUE)

    # ──────────────────────────────────────────────────────────────
    # SELECTION COMMUNE (combo)
    # ──────────────────────────────────────────────────────────────
    shiny::observeEvent(input$commune_select, {

      if (isTRUE(auto_selection_en_cours())) return()                           # Empêche boucles auto-BAN

      if (!is.null(input$commune_select) && input$commune_select != "") {
        r_commune_courante(input$commune_select)                                # Mise à jour commune active
      }
    }, ignoreInit = TRUE)

    # ──────────────────────────────────────────────────────────────
    # CHARGEMENT COUCHES COMMUNALES (dynamique par IDU)
    # ──────────────────────────────────────────────────────────────
    # Fonction générique de chargement d'une couche communale
    load_commune_layer <- function(layer_name, idu) {

      data <- charger_couche_commune_cached(layer_name, idu)                    # Charge depuis le cache la couche locale associée à une commune (IDU)
      if (is.null(data) || nrow(data) == 0) return(NULL)                        # Si aucune donnée ou table vide → sortie immédiate

      tryCatch({

        crs_epsg <- tryCatch(sf::st_crs(data)$epsg,                             # Récupération EPSG déclaré dans le SF
                             error = function(e) NA_integer_)                   # Si erreur CRS → NA

        if (is.na(crs_epsg)) {                                                  # Cas 1 : CRS inconnu
          sf::st_crs(data) <- 4326                                              # On force WGS84
        } else if (crs_epsg != 4326) {                                          # Cas 2 : CRS valide mais incorrect
          data <- sf::st_transform(data, 4326)                                  # Reprojection vers WGS84
        }

        data <- sf::st_make_valid(data)                                         # Correction géométrique (évite erreurs topologiques)
        data <- data[!sf::st_is_empty(data), , drop = FALSE]                    # Filtrage d'entités invalides/vides

        filter_polygons(data)                                                   # On conserve uniquement les POLYGON / MULTIPOLYGON

      }, error = function(e) {

        data <- sf::st_make_valid(data)                                         # En cas d'erreur CRS, on valide au minimum la géométrie
        filter_polygons(data)                                                   # On retourne quand même des polygones propres
      })
    }

    # ============================================================================
    # REACTIFS DES COUCHES DYNAMIQUES (chargement par commune)
    # ============================================================================

    parcelles <- shiny::reactive({
      idu <- idu_react()                                                        # Appelle l'IDU courant sélectionné
      shiny::req(idu)                                                           # Stop si IDU non disponible
      load_commune_layer("parcelles", idu)                                      # Charge couche parcellaire de la commune
    })

    batis <- shiny::reactive({
      idu <- idu_react()                                                        # Identifiant commune
      shiny::req(idu)
      load_commune_layer("batis", idu)                                          # Charge la couche bâtiments
    })

    old50m <- shiny::reactive({
      idu <- idu_react()
      shiny::req(idu)
      load_commune_layer("old50m", idu)                                         # Charge zones OLD50m produites pour cette commune
    })

    zu <- shiny::reactive({
      idu <- idu_react()
      shiny::req(idu)

      # Tentative de chargement de la couche ZU
      data <- tryCatch(
        load_commune_layer("zu", idu),
        error = function(e) {
          # Cas NORMAL : certaines communes n'ont pas de ZU
          message(
            sprintf(
              "[cartOLD][ZU] Aucune ZU pour la commune %s (ignoré)",
              idu
            )
          )
          return(NULL)
        }
      )

      # Aucune ZU → comportement normal, on sort proprement
      if (is.null(data) || nrow(data) == 0) {
        return(NULL)
      }

      # Sécurité structure
      if (!("typezone" %in% names(data)) || !("geom" %in% names(data))) {
        return(data)
      }

      # Agrégation par typezone (robuste)
      tryCatch({
        s2_state <- sf::sf_use_s2()
        sf::sf_use_s2(FALSE)

        res_agg <- data %>%
          dplyr::group_by(typezone) %>%
          dplyr::summarise(
            geom = sf::st_union(geom),
            .groups = "drop"
          )

        sf::sf_use_s2(s2_state)
        sf::st_geometry(res_agg) <- "geom"

        res_agg
      }, error = function(e) {
        sf::sf_use_s2(TRUE)
        data
      })
    })



    # Palette dynamique OLD50m (couleurs VIVES et distinctes pour chaque compte communal)
    palette_old50m <- shiny::reactive({
      dat <- old50m()
      if (is.null(dat) || nrow(dat) == 0 || is.null(dat$comptecommunal)) {
        return(function(x) "#FF6B35")                                           # Orange vif fallback
      }
      vals <- unique(as.character(dat$comptecommunal))

      # Palette de couleurs VIVES et saturées
      vives <- c(
        "#FF6B35",  # Orange vif
                 "#E63946",  # Rouge corail
                 "#2A9D8F",  # Vert turquoise
                 "#E9C46A",  # Jaune doré
                 "#A855F7",  # Violet
                 "#06B6D4",  # Cyan
                 "#84CC16",  # Vert lime
                 "#F97316",  # Orange brûlé
                 "#EC4899",  # Rose fuchsia
                 "#10B981",  # Vert émeraude
                 "#8B5CF6",  # Violet clair
                 "#F59E0B"   # Ambre
      )

      colors <- grDevices::colorRampPalette(vives)(length(vals))
      leaflet::colorFactor(colors, vals)
    })

    # ──────────────────────────────────────────────────────────────
    # INFOS OLD50m SURVOLÉ — intersection → table attributaire
    # ──────────────────────────────────────────────────────────────
    old50m_hover <- shiny::reactiveVal(NULL)                                    # Contient table d'intersection

    observeEvent(input$old50m_hover_info, {

      info <- input$old50m_hover_info                                           # Payload reçu depuis JS (polygon ID / compte)

      if (is.null(info)) {                                                      # Sortie du survol
        old50m_hover(NULL)
        return()
      }

      dat_old50m  <- old50m()                                                   # Couches dynamiques
      dat_parcels <- parcelles()
      req(dat_old50m, dat_parcels)

      sel <- dat_old50m                                                         # Cible = polygone OLD50m survolé

      if (!is.null(info$idu) && "idu" %in% names(sel)) {
        sel <- sel[sel$idu == info$idu, , drop = FALSE]
      }

      if (!is.null(info$comptecommunal) && "comptecommunal" %in% names(sel)) {
        sel <- sel[sel$comptecommunal == info$comptecommunal, , drop = FALSE]
      }

      if (nrow(sel) == 0) {
        old50m_hover(NULL)
        return()
      }

      # Intersection géométrique (S2 désactivé = robustesse)
      s2_state <- sf::sf_use_s2()
      sf::sf_use_s2(FALSE)
      inter <- try(sf::st_intersection(dat_parcels, sel), silent = TRUE)
      sf::sf_use_s2(s2_state)

      if (inherits(inter, "try-error") || is.null(inter) || nrow(inter) == 0) {
        old50m_hover(NULL)
        return()
      }

      # Préparation table : extraction attributaire utile
      cols_parcelles <- intersect(c("geo_parcelle", "geo_section"), names(inter))
      cols_old50m    <- intersect(c("comptecommunal", "idu"), names(inter))

      df <- as.data.frame(inter)[, c(cols_old50m, cols_parcelles), drop = FALSE]
      df <- unique(df)                   # Suppression doublons

      # Regroupement par compte communal → liste de parcelles / sections
      df_group <- df %>%
        dplyr::group_by(comptecommunal) %>%
        dplyr::summarise(
          parcelles = paste0(unique(geo_parcelle), collapse = ", "),
          sections  = paste0(unique(geo_section), collapse = ", "),
          .groups = "drop"
        )

      old50m_hover(df_group)                                                    # Injection dans tableOutput
    })

    output$old50m_hover_table <- renderTable({
      old50m_hover()
    }, bordered = TRUE, striped = TRUE, hover = TRUE)

    # ──────────────────────────────────────────────────────────────
    # RENDU INITIAL DE LA CARTE (fond + couches fixes)
    # ──────────────────────────────────────────────────────────────
    output$carte <- leaflet::renderLeaflet({

      leaflet::leaflet(options = leaflet::leafletOptions(
        minZoom = 1,
        maxZoom = 18,
        preferCanvas = FALSE                                                    # Rendu vectoriel prioritaire
      )) %>%

        # Fond OSM
        leaflet::addTiles(
          group = "OSM",
          options = leaflet::tileOptions(maxNativeZoom = 19, maxZoom = 22)
        ) %>%

        # Fond IGN Plan
        leaflet::addTiles(
          urlTemplate = "https://data.geopf.fr/wmts?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2&TILEMATRIXSET=PM&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}&STYLE=normal&FORMAT=image/png",
          attribution = "© IGN",
          options = leaflet::tileOptions(crossOrigin = "anonymous", maxNativeZoom = 18, maxZoom = 18),
          group = "IGN Plan"
        ) %>%

        # Fond IGN Ortho
        leaflet::addTiles(
          urlTemplate = "https://data.geopf.fr/wmts?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=ORTHOIMAGERY.ORTHOPHOTOS&TILEMATRIXSET=PM&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}&STYLE=normal&FORMAT=image/jpeg",
          attribution = "© IGN",
          options = leaflet::tileOptions(crossOrigin = "anonymous", maxNativeZoom = 18, maxZoom = 18),
          group = "IGN Ortho"
        ) %>%

        # Fond IGN - Parcellaire cadastral (NOUVEAU SERVICE PCI EXPRESS)
        leaflet::addTiles(
          urlTemplate = paste0(
            "https://data.geopf.fr/wmts?",
            "SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0",
            "&LAYER=CADASTRALPARCELS.PARCELLAIRE_EXPRESS",
            "&STYLE=PCI vecteur",
            "&TILEMATRIXSET=PM",
            "&TILEMATRIX={z}",
            "&TILEROW={y}",
            "&TILECOL={x}",
            "&FORMAT=image/png"
          ),
          attribution = "\u00a9 IGN - Parcellaire Express (PCI)",
          options = leaflet::tileOptions(
            maxNativeZoom = 19,
            maxZoom = 21,
            crossOrigin = "anonymous"
          ),
          group = "IGN Parcellaire"
        ) %>%

        # Ajout couche département si présente
        {
          if (!is.null(departement_poly) && nrow(departement_poly) > 0)
            leaflet::addPolygons(
              .,
              data  = departement_poly,
              group = "dept_lim",
              fill  = FALSE,
              color = "red",
              weight = 2,
              opacity = 1
            )
          else .
        } %>%

        leaflet::addLayersControl(
          baseGroups = c("OSM", "IGN Plan", "IGN Ortho", "IGN Parcellaire"),
          options = leaflet::layersControlOptions(
            collapsed = TRUE,
            position = "bottomleft"
          )
        ) %>%

        leaflet::setView(lng = 4.85, lat = 44.75, zoom = 9) %>%

        # Nettoyage automatique des fonds IGN après rendu
        htmlwidgets::onRender("
          function(el, x) {
            var map = this;
            setTimeout(function() {
              map.setView([44.75, 4.85], 9);
              map.eachLayer(function(layer) {
                if (layer.options && layer.options.group) {
                  if (layer.options.group === 'IGN Plan' || layer.options.group === 'IGN Ortho'|| layer.options.group === 'IGN Parcellaire') {
                    map.removeLayer(layer);
                  }
                }
              });
            }, 100);
          }
        ")
    })

    # ──────────────────────────────────────────────────────────────
    # MISE A JOUR LISTE DES COMMUNES
    # ──────────────────────────────────────────────────────────────
    shiny::observe({                                                            # Observer réactif → met à jour la liste dès que r_communes change
      choix_communes <- r_communes() %>%                                        # Extraction du tableau SF des communes OLD200
        dplyr::arrange(tex2) %>%                                                # Tri alphabétique sur le nom affiché
        dplyr::mutate(label = tex2, value = tex2) %>%                           # label = affichage / value = valeur envoyée input
        dplyr::distinct(label, value)                                           # Nettoyage doublons éventuels

      shiny::updateSelectInput(                                                 # Mise à jour dynamique du selectInput côté UI
        session,
        inputId = "commune_select",                                             # ID de l'input à mettre à jour
        choices = c("Sélectionner une commune" = "",                            # Première entrée vide par défaut
                    choix_communes$label),                                      # Liste réelle des communes
        selected = ""                                                           # Sélection par défaut vide
      )
    })

    # ──────────────────────────────────────────────────────────────
    # OBSERVER COUCHES FIXES (dept / communes / old200)
    # ──────────────────────────────────────────────────────────────
    observe({                                                                   # Observer les changements des couches fixes
      proxy   <- leaflet::leafletProxy("carte", session = session)              # Récupère un proxy Leaflet pour manipuler la carte déjà rendue
      couches <- input$couches_select                                           # Couches cochées par l'utilisateur
      if (is.null(couches)) couches <- character(0)                             # Si rien → vecteur vide

      # --- Département : déjà ajouté dans renderLeaflet() ---
      if ("dept_lim" %in% couches) {                                            # Si la couche est cochée
        proxy %>%
          leaflet::showGroup("dept_lim")                                # → on rend visible
      } else {
        proxy %>%
          leaflet::hideGroup("dept_lim")                                # Sinon → on masque
      }

      # --- Fonction interne pour communes & old200 ---
      add_fixed_layer <- function(group, data, args_list) {                     # Fonction factorisant l'ajout unique des couches
        if (group %in% couches) {                                               # Si la couche est cochée

          if (!isTRUE(rv_layers$added[[group]])) {                              # Si non encore ajoutée → ajout unique
            proxy <<- do.call(                                                  # Ajout dynamique via do.call
              leaflet::addPolygons,                                             # Type de couche
              c(
                list(
                  map  = proxy,                                                 # Proxy de la carte
                  data = data,                                                  # Données SF à afficher
                  group = group                                                 # Nom du groupe Leaflet
                ),
                args_list                                                       # Styles spécifiques envoyés via liste
              )
            )
            rv_layers$added[[group]] <<- TRUE                                   # Marquage "cette couche est déjà ajoutée"
          }
          proxy <<- proxy %>%
            leaflet::showGroup(group)                                           # Affichage du groupe

        } else {                                                                # Si la couche n'est pas cochée
          if (isTRUE(rv_layers$added[[group]])) {                               # Et si elle avait déjà été ajoutée
            proxy <<- proxy %>%
              leaflet::hideGroup(group)                                         # Masque la couche
          }
        }
      }

      # --- Communes ---
      if (!is.null(communes_poly) && nrow(communes_poly) > 0) {                 # Vérification existence couche
        add_fixed_layer(
          "communes_lim",                                                       # Nom du groupe Leaflet
          communes_poly,                                                        # Données polygones communes
          list(
            fill  = FALSE,                                                      # Pas de remplissage
            color = "black",                                                    # Contour noir
            weight = 1.8,                                                       # Épaisseur trait
            opacity = 1,                                                        # Opacité totale
            label = ~tex2                                                       # Label affiché au survol dans Leaflet
          )
        )
      }

      # --- OLD200 ---
      if (!is.null(old200_poly) && nrow(old200_poly) > 0) {                     # Vérification existence couche
        add_fixed_layer(
          "old200",                                                             # Nom du groupe Leaflet
          old200_poly,                                                          # Données SF
          list(
            fillOpacity = 0.3,                                                  # Légère coloration interne
            color       = "blue",                                               # Contour bleu
            weight      = 2.3,                                                  # Ligne plus épaisse
            dashArray   = "5,5"                                                 # Style en tirets
          )
        )
      }

      r$couches_select <- couches                                               # Propagation état sélection à d'autres modules
    })


    # ──────────────────────────────────────────────────────────────
    # OBSERVER COUCHES DYNAMIQUES (old50m, parcelles, batis, ZU)
    # ──────────────────────────────────────────────────────────────
    shiny::observeEvent(
      list(input$couches_select, idu_react()),                                  # Déclenchement : changement commune + changement couches
      ignoreNULL = FALSE,
      ignoreInit = FALSE,
      {
        proxy <- tryCatch(
          leaflet::leafletProxy("carte", session = session),                    # Proxy Leaflet sécurisé
          error = function(e) NULL
        )
        shiny::req(!is.null(proxy))                                             # Si proxy échec → stop observer

        couches <- input$couches_select                                         # Récupère couches sélectionnées
        if (is.null(couches)) couches <- character(0)                           # Défaut = vide
        r$couches_select <- couches                                             # Stockage global

        idu <- idu_react()                                                      # Commune courante

        # ══════════════════════════════════════════════════════════════
        # [AJOUT] DETECTION CHANGEMENT DE COMMUNE → NETTOYAGE COUCHES
        # ══════════════════════════════════════════════════════════════
        idu_prec <- idu_precedent()                                             # Récupère IDU précédent stocké
        commune_changee <- !is.null(idu) &&                                     # IDU actuel non NULL
          !is.null(idu_prec) &&                                                 # IDU précédent non NULL
          idu != idu_prec                                                       # Les deux sont différents

        if (commune_changee) {                                                  # Si changement de commune détecté
          log_debug("Changement commune : ", idu_prec, " → ", idu)              # Log debug

          # Suppression des anciennes couches dynamiques du DOM Leaflet
          proxy %>%
            leaflet::clearGroup("old50m") %>%                                   # Nettoie OLD50m
            leaflet::clearGroup("parcelle_lim") %>%                             # Nettoie parcelles
            leaflet::clearGroup("batis") %>%                                    # Nettoie bâtiments
            leaflet::clearGroup("ZU")                                           # Nettoie zones urbaines

          # Reset des flags pour permettre le rechargement
          rv_layers$added[["old50m"]]       <- FALSE                            # Reset flag OLD50m
          rv_layers$added[["parcelle_lim"]] <- FALSE                            # Reset flag parcelles
          rv_layers$added[["batis"]]        <- FALSE                            # Reset flag bâtiments
          rv_layers$added[["ZU"]]           <- FALSE                            # Reset flag ZU
        }

        # Mise à jour de l'IDU précédent (pour la prochaine comparaison)
        if (!is.null(idu)) {                                                    # Si IDU valide
          idu_precedent(idu)                                                    # Stocke pour prochaine itération
        }
        # ══════════════════════════════════════════════════════════════

        # Si aucune commune n'est sélectionnée → toutes les couches dépendantes de l'IDU
        # doivent être masquées car elles ne peuvent pas être calculées sans contexte communal.
        if (is.null(idu) || idu == "") {

          proxy %>%                                                             # Proxy Leaflet existant
            leaflet::hideGroup("old50m") %>%                                    # Cache la couche OLD50m
            leaflet::hideGroup("parcelle_lim") %>%                              # Cache les parcelles
            leaflet::hideGroup("batis") %>%                                     # Cache les bâtiments
            leaflet::hideGroup("ZU")                                            # Cache les zones urbaines (PLU)

          return(invisible(NULL))                                               # Sortie silencieuse → évite le reste du code
        }

        # Chargement (réactif) des données dynamiques pour la commune courante.
        # tryCatch empêche toute rupture du flux si un RDS / couche n'existe pas.
        dat_old50m    <- tryCatch(old50m(),    error = function(e) NULL)        # Zones OLD50m
        dat_parcelles <- tryCatch(parcelles(), error = function(e) NULL)        # Parcellaire
        dat_batis     <- tryCatch(batis(),     error = function(e) NULL)        # Bâti
        dat_zu        <- tryCatch(zu(),        error = function(e) NULL)        # Zones urbaines

        # Initialisation palette OLD50m
        pal_old50m <- NULL                                                      # Valeur défaut

        # Si la couche existe et possède la colonne "comptecommunal" → création d'une palette unique
        if (!is.null(dat_old50m) &&
            nrow(dat_old50m) > 0 &&
            !is.null(dat_old50m$comptecommunal)) {

          pal_old50m <- palette_old50m()                                        # colorFactor() généré en amont
        }

        # Fonction générique permettant :
        # - d'ajouter une couche UNE SEULE FOIS (évite duplication Leaflet)
        # - d'afficher / masquer selon les sélections de l'utilisateur
        add_once_show_or_hide <- function(group, add_fn, has_data) {

          # Si la couche est cochée dans l'UI
          if (group %in% couches) {

            # Ajout unique de la couche dans Leaflet :
            # rv_layers$added conserve l'état "ajouté au moins une fois"
            if (!isTRUE(rv_layers$added[[group]]) && has_data) {
              proxy <<- add_fn(proxy)                                           # Appel de la fonction spécifique à la couche
              rv_layers$added[[group]] <<- TRUE                                 # Marquage couche déjà injectée
            }

            proxy <<- proxy %>%
              leaflet::showGroup(group)                                         # Affiche la couche si cochée

          } else {                                                              # Si la couche est décochée
            if (isTRUE(rv_layers$added[[group]])) {                             # … mais a déjà été ajoutée auparavant
              proxy <<- proxy %>%
                leaflet::hideGroup(group)                                       # Masque la couche
            }
          }
        }

        # OLD50m ---------------------------------------------------------------
        # OLD50m ---------------------------------------------------------------
        add_once_show_or_hide(
          "old50m",                                                             # Nom du groupe Leaflet

          add_fn = function(p) {                                                # Fonction d'ajout unique
            if (!is.null(dat_old50m) &&
                nrow(dat_old50m) > 0 &&
                !is.null(pal_old50m)) {

              p %>%
                leaflet::addPolygons(
                  data = dat_old50m,                                              # Données géométriques
                  group = "old50m",                                               # Groupe Leaflet
                  fillColor = ~pal_old50m(as.character(comptecommunal)),          # Couleur par catégorie
                  fillOpacity = 0.45,                                             # Transparent mais visible
                  color = "#333333",                                              # Contours gris foncé
                  weight = 1,                                                     # Finesse contours
                  smoothFactor = 0,                                               # Pas de lissage Douglas-Peucker
                  noClip = TRUE,                                                  # Désactive le clipping → géométrie intégrale

                  # Surbrillance au survol : contour GRAS
                  highlightOptions = leaflet::highlightOptions(
                    weight = 4,                                                   # Contour GRAS au survol
                    color = "#000000",                                            # Contour noir
                    fillOpacity = 0.55,                                           # Légèrement plus opaque
                    bringToFront = TRUE                                           # Passe au premier plan
                  ),

                  options = leaflet::pathOptions(
                    className = "old50m-polygon",                                  # Classe CSS / identifiant pour JS
                    interactive = TRUE
                  )
                )

            } else {
              p                                                                 # Si aucune donnée → renvoie le proxy inchangé
            }
          },

          has_data = !is.null(dat_old50m) && nrow(dat_old50m) > 0               # Condition existence
        )

        # PARCELLES ------------------------------------------------------------
        add_once_show_or_hide(
          "parcelle_lim",                                                       # Nom groupe Leaflet

          add_fn = function(p) {
            if (!is.null(dat_parcelles) && nrow(dat_parcelles) > 0) {
              p %>%
                leaflet::addPolygons(
                  data  = dat_parcelles,                                        # Parcelles cadastrales
                  group = "parcelle_lim",
                  fill  = FALSE,                                                  # Pas de remplissage
                  color = "darkorange",                                           # Contours orange
                  weight = 1,                                                     # Trait fin
                  opacity = 0.30,                                                 # Transparence du contour
                  smoothFactor = 0                                                # Lissage
                )
            } else p                                                            # Aucun ajout si pas de données
          },

          has_data = !is.null(dat_parcelles) && nrow(dat_parcelles) > 0
        )

        # BATIS ----------------------------------------------------------------
        add_once_show_or_hide(
          "batis",

          add_fn = function(p) {
            if (!is.null(dat_batis) && nrow(dat_batis) > 0) {
              p %>%
                leaflet::addPolygons(
                  data  = dat_batis,                                            # Polygones des bâtiments
                  group = "batis",
                  fillColor   = "#ffcc33",                                      # Jaune pastel
                  fillOpacity = 1,                                              # Complètement opaque
                  color       = "#ffcc33",                                      # Bordure même couleur
                  weight      = 1,
                  opacity     = 0.3,                                            # Transparence bordure
                  smoothFactor = 2
                )
            } else p
          },

          has_data = !is.null(dat_batis) && nrow(dat_batis) > 0
        )

        # ZU (Zones Urbaines) -----------------------------------------------------
        add_once_show_or_hide(
          "ZU",

          add_fn = function(p) {
            if (!is.null(dat_zu) && nrow(dat_zu) > 0) {
              p %>%
                leaflet::addPolygons(
                  data  = dat_zu,                                               # Polygones ZU agrégés par typezone
                  group = "ZU",
                  color = "black",                                              # Contours nets
                  weight = 3,                                                   # Trait épais
                  opacity = 1,                                                  # Opaque
                  fill   = FALSE,                                               # Pas de remplissage
                  dashArray = "5,5",                                            # Style pointillé
                  smoothFactor = 2
                )
            } else p
          },

          has_data = !is.null(dat_zu) && nrow(dat_zu) > 0
        )
        # ──────────────────────────────────────────────────────────────
        # SIGNAL FRONTEND : couches communales prêtes
        # ──────────────────────────────────────────────────────────────
        # Ce message informe le JavaScript que les couches dépendantes
        # de la commune (OLD50m, parcelles, batis, ZU) ont été ajoutées
        # dans Leaflet.
        #
        # Utilisé pour déclencher le rebinding du hover OLD50m
        session$sendCustomMessage(
          "communeLayersReady",
          list(
            idu = idu_react()   # IDU courant (traçabilité / debug)
          )
        )

      }
    )

    # ──────────────────────────────────────────────────────────────
    # FONCTION ZOOM COMMUNE + UTILISATIONS
    # ──────────────────────────────────────────────────────────────
    zoom_commune <- function(commune_name) {
      shiny::req(commune_name, r_communes())

      dat <- r_communes()
      commune <- dat[dat$tex2 == commune_name, , drop = FALSE]
      shiny::req(nrow(commune) > 0)

      idu <- as.character(commune$idu[1])
      r_commune_courante(commune_name)

      commune <- sf::st_make_valid(commune)
      commune_wgs <- sf::st_transform(commune, 4326)
      bb <- sf::st_bbox(commune_wgs)

      # COUCHES dynamiques cochées automatiquement
      shiny::updateCheckboxGroupInput(
        session = session,
        inputId = "couches_select",
        selected = c("old50m", "parcelle_lim", "ZU", "batis")
      )

      proxy <- leaflet::leafletProxy("carte", session = session) %>%
        leaflet::clearGroup("selection_commune") %>%
        leaflet::hideGroup("dept_lim") %>%
        leaflet::addPolygons(
          data  = commune_wgs,
          group = "selection_commune",
          weight = 2,
          color  = "#444",
          fillOpacity = 0.05
        )

      if (all(is.finite(unname(bb)))) {
        proxy %>%
          leaflet::fitBounds(
            as.numeric(bb["xmin"]),
            as.numeric(bb["ymin"]),
            as.numeric(bb["xmax"]),
            as.numeric(bb["ymax"])
          )
      } else {
        cent <- sf::st_coordinates(sf::st_centroid(sf::st_geometry(commune_wgs)))[1, ]
        proxy %>%
          leaflet::flyTo(lng = cent[1], lat = cent[2], zoom = 15)
      }

      code_insee <- paste0("26", sprintf("%03d", as.numeric(idu)))
      session$sendCustomMessage("setCommuneBAN", list(commune = code_insee))
    }

    shiny::observeEvent(input$commune_search, {
      shiny::req(input$commune_select)
      zoom_commune(input$commune_select)
    })

    # ──────────────────────────────────────────────────────────────
    # AUTO-SELECTION COMMUNE DEPUIS ADRESSE
    # ──────────────────────────────────────────────────────────────
    shiny::observeEvent(r$adresse_commune_info, {
      info <- r$adresse_commune_info
      shiny::req(info, info$code_insee)

      commune_match <- r_communes() %>%
        dplyr::mutate(code_insee_complet = paste0("26", sprintf("%03d", as.numeric(idu)))) %>%
        dplyr::filter(code_insee_complet == info$code_insee)

      if (nrow(commune_match) > 0) {
        commune_name <- commune_match$tex2[1]
        auto_selection_en_cours(TRUE)

        shiny::updateSelectInput(session, "commune_select", selected = commune_name)
        r_commune_courante(commune_name)
        zoom_commune(commune_name)

        shiny::updateCheckboxGroupInput(
          session = session,
          inputId = "couches_select",
          selected = c("old50m", "parcelle_lim", "batis", "ZU")
        )

        shinyjs::delay(300, auto_selection_en_cours(FALSE))
      }
    })

    # ──────────────────────────────────────────────────────────────
    # RECHERCHE & MARQUEUR ADRESSE
    # ──────────────────────────────────────────────────────────────
    shiny::observeEvent(input$adresse_search, {
      shiny::req(input$adresse_sel_lat, input$adresse_sel_lon)

      lat <- as.numeric(input$adresse_sel_lat)
      lon <- as.numeric(input$adresse_sel_lon)
      shiny::req(!is.na(lat), !is.na(lon))

      shiny::updateCheckboxGroupInput(
        session = session,
        inputId = "couches_select",
        selected = c("old50m", "parcelle_lim", "ZU", "batis")
      )

      leaflet::leafletProxy("carte", session = session) %>%
        leaflet::clearGroup("adresse_marker") %>%
        leaflet::hideGroup("dept_lim") %>%
        leaflet::addMarkers(
          lng = lon, lat = lat,
          popup = input$adresse_sel_label,
          group = "adresse_marker"
        ) %>%
        leaflet::flyTo(lng = lon, lat = lat, zoom = 18)
    })

    # ──────────────────────────────────────────────────────────────
    # REINITIALISATION COMMUNE
    # ──────────────────────────────────────────────────────────────
    shiny::observeEvent(input$commune_reset, {
      session$sendCustomMessage("resetBAN", list())

      shiny::updateSelectInput(session, "commune_select", selected = "")
      r_commune_courante(NULL)
      idu_precedent(NULL)                                                       # [AJOUT] Reset IDU précédent

      shiny::updateTextInput(session, "adresse_input", value = "")
      shiny::updateTextInput(session, "adresse_sel_label", value = "")
      shiny::updateNumericInput(session, "adresse_sel_lon", value = NULL)
      shiny::updateNumericInput(session, "adresse_sel_lat", value = NULL)

      # Recocher uniquement DEPARTEMENT
      shiny::updateCheckboxGroupInput(
        session = session,
        inputId = "couches_select",
        selected = "dept_lim"
      )

      proxy <- leaflet::leafletProxy("carte", session = session)
      proxy %>%
        leaflet::clearGroup("selection_commune") %>%
        leaflet::clearGroup("old50m") %>%
        leaflet::clearGroup("parcelle_lim") %>%
        leaflet::clearGroup("batis") %>%
        leaflet::clearGroup("ZU") %>%
        leaflet::clearGroup("adresse_marker") %>%
        leaflet::setView(lng = 4.85, lat = 44.75, zoom = 9) %>%
        leaflet::showGroup("dept_lim")

      rv_layers$added[["old50m"]]      <- FALSE
      rv_layers$added[["parcelle_lim"]] <- FALSE
      rv_layers$added[["batis"]]       <- FALSE
      rv_layers$added[["ZU"]]          <- FALSE
    })

    # ──────────────────────────────────────────────────────────────
    # REINITIALISATION ADRESSE
    # ──────────────────────────────────────────────────────────────
    shiny::observeEvent(input$adresse_reset, {
      shiny::updateTextInput(session, "adresse_input", value = "")
      shiny::updateTextInput(session, "adresse_sel_label", value = "")
      shiny::updateNumericInput(session, "adresse_sel_lon", value = NULL)
      shiny::updateNumericInput(session, "adresse_sel_lat", value = NULL)

      leaflet::leafletProxy("carte", session = session) %>%
        leaflet::clearGroup("adresse_marker")

      commune_name <- r_commune_courante()
      if (!is.null(commune_name) && commune_name != "") {
        dat <- r_communes()
        commune <- dat[dat$tex2 == commune_name, , drop = FALSE]

        if (nrow(commune) > 0) {
          commune <- sf::st_make_valid(commune)
          commune_wgs <- sf::st_transform(commune, 4326)
          bb <- sf::st_bbox(commune_wgs)

          if (all(is.finite(unname(bb)))) {
            leaflet::leafletProxy("carte", session = session) %>%
              leaflet::fitBounds(
                as.numeric(bb["xmin"]),
                as.numeric(bb["ymin"]),
                as.numeric(bb["xmax"]),
                as.numeric(bb["ymax"])
              )
          }
        }
      }
    })
    # ──────────────────────────────────────────────────────────────
    # EXPORT CARTE (PNG / PDF) – inchangé fonctionnellement
    # ──────────────────────────────────────────────────────────────
    mod_carte_export_server(
      id             = "export",
      carte_id       = ns("carte"),
      parent_session = session
    )



    # ──────────────────────────────────────────────────────────────
    # INITIALISATION JS / OUTILS CARTE
    # ──────────────────────────────────────────────────────────────
    shiny::observeEvent(input$carte_center, {
      shinyjs::delay(250, {
        session$sendCustomMessage("initMapTools", list(
          mapId = ns("carte"),
          old50mHoverInputId = ns("old50m_hover_info"),
          mesureValeurId = ns("mesure_valeur")
        ))
      })
    }, once = TRUE)

    shinyjs::delay(250, {
      leaflet::leafletProxy("carte", session = session) %>%
        leaflet::setView(lng = 4.85, lat = 44.75, zoom = 9)
    })
  })
}
