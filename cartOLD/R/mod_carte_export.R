# ══════════════════════════════════════════════════════════════════════════════
# FICHIER      : mod_carte_export.R
# AUTEUR       : MJ Martinat
# ORGANISATION : DDT de la Drôme
# DATE         : 2025
# OBJET        : Module d'export cartographique (PNG / PDF) – cartOLD
# DESCRIPTION  : Export PDF A4 PAYSAGE - Carte 3/4 + Légende 1/4 ALIGNÉES
# VERSION      : 1.0
# ══════════════════════════════════════════════════════════════════════════════
# INTERFACE UTILISATEUR DU MODULE
# ══════════════════════════════════════════════════════════════════════════════
#' UI du module Export Carte
#'
#' Genere l interface utilisateur pour l export de cartes :
#' - Bouton de generation d apercu
#' - Export PNG (image simple)
#' - Export PDF (document complet avec legende)
#'
#' @param id Identifiant du module (namespace)
#'
#' @return Un objet `shiny.tag.list`
#'
#' @importFrom shiny tagList tags icon actionButton uiOutput NS
#'
#' @export
mod_carte_export_ui <- function(id) {
  ns <- shiny::NS(id)                                                          # Namespace pour isolation des IDs
  shiny::tagList(                                                              # Liste de tags HTML
    shiny::tags$div(                                                           # Conteneur principal
      class = "export-description",                                            # Classe CSS
      shiny::tags$p(                                                           # Paragraphe d'introduction
        shiny::icon("info-circle"),                                            # Icône d'information
        " Exportez la carte actuelle :"                                        # Texte explicatif
      ),
      shiny::tags$ul(                                                          # Liste à puces
        shiny::tags$li(                                                        # Item PNG
          shiny::tags$strong("PNG"),                                           # Format en gras
          " : Image simple de la carte"                                        # Description PNG
        ),
        shiny::tags$li(                                                        # Item PDF
          shiny::tags$strong("PDF"),                                           # Format en gras
          " : Document complet avec légende et informations"                   # Description PDF
        )
      )
    ),
    shiny::actionButton(                                                       # Bouton d'action
      inputId = ns("carte_export"),                                            # ID avec namespace
      label   = "Générer l'aperçu",                                            # Texte du bouton
      icon    = shiny::icon("camera"),                                         # Icône caméra
      class   = "btn-primary btn-block"                                        # Classes Bootstrap
    ),
    shiny::uiOutput(ns("modal_export"))                                        # Sortie UI pour modale
  )
}


# ══════════════════════════════════════════════════════════════════════════════
# SERVEUR DU MODULE
# ══════════════════════════════════════════════════════════════════════════════
#' Serveur du module Export Carte
#'
#' Gere la logique serveur pour l export de cartes :
#' - Capture de la carte Leaflet via message JavaScript
#' - Affichage de l apercu dans une modale
#' - Telechargement PNG (image base64 decodee)
#' - Telechargement PDF (document A4 paysage avec mise en page complexe)
#'
#' @param id Identifiant du module (namespace)
#' @param carte_id Identifiant de la carte Leaflet a capturer
#' @param parent_session Session Shiny parente pour envoi de messages
#'
#' @return NULL (effets de bord via observeEvent et downloadHandler)
#'
#' @importFrom shiny moduleServer observeEvent req showModal modalDialog modalButton
#' @importFrom shiny downloadButton downloadHandler tagList tags
#' @importFrom base64enc base64decode
#' @importFrom png readPNG
#' @importFrom jpeg readJPEG
#' @importFrom grDevices pdf dev.off
#' @importFrom graphics layout par plot.new rasterImage rect text segments
#'
#' @export
mod_carte_export_server <- function(id, carte_id, parent_session) {
  shiny::moduleServer(id, function(input, output, session) {                   # Initialisation serveur module
    ns <- session$ns                                                           # Récupération fonction namespace

    # ──────────────────────────────────────────────────────────────────────────
    # Declenchement de la capture de carte
    # ──────────────────────────────────────────────────────────────────────────
    shiny::observeEvent(input$carte_export, {                                  # Réaction au clic bouton export
      parent_session$sendCustomMessage(                                        # Envoi message JavaScript
        type = "capture-map",                                                  # Type de message
        message = list(                                                        # Contenu du message
          mapId    = carte_id,                                                 # ID carte à capturer
          outputId = ns("map_capture")                                         # ID output pour image
        )
      )
    })

    # ──────────────────────────────────────────────────────────────────────────
    # Affichage de l apercu dans une modale
    # ──────────────────────────────────────────────────────────────────────────
    shiny::observeEvent(input$map_capture, {                                   # Réaction à réception image
      shiny::req(input$map_capture)                                            # Vérification présence image
      shiny::showModal(                                                        # Affichage modale
        shiny::modalDialog(                                                    # Création dialogue modal
          title     = "Aperçu de l'export",                                    # Titre modale
          size      = "l",                                                     # Taille large
          easyClose = TRUE,                                                    # Fermeture clic extérieur
          footer    = shiny::tagList(                                          # Pied avec boutons
            shiny::modalButton("Fermer"),                                      # Bouton fermeture
            shiny::downloadButton(                                             # Bouton téléchargement PNG
              outputId = ns("download_png"),                                   # ID avec namespace
              label    = "Télécharger PNG",                                    # Texte bouton
              icon     = shiny::icon("download")                               # Icône téléchargement
            ),
            shiny::downloadButton(                                             # Bouton téléchargement PDF
              outputId = ns("download_pdf"),                                   # ID avec namespace
              label    = "Télécharger PDF",                                    # Texte bouton
              icon     = shiny::icon("file-pdf")                               # Icône PDF
            )
          ),
          shiny::tagList(                                                      # Contenu modale
            shiny::tags$img(                                                   # Balise image
              src   = input$map_capture,                                       # Source base64
              style = "max-width:100%;border:1px solid #cccccc;"               # Style CSS
            ),
            shiny::tags$div(                                                   # Div timestamp
              paste("Carte générée le", format(Sys.time(), "%d/%m/%Y %H:%M")), # Texte date/heure
              style = "margin-top:10px;text-align:center;color:#666666;"       # Style CSS
            )
          )
        )
      )
    })

    # ──────────────────────────────────────────────────────────────────────────
    # Telechargement PNG
    # ──────────────────────────────────────────────────────────────────────────
    output$download_png <- shiny::downloadHandler(                             # Handler téléchargement PNG
      filename = function() {                                                  # Fonction nom fichier
        paste0("carte_OLD_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".png")      # Nom avec horodatage
      },
      content = function(file) {                                               # Fonction contenu
        shiny::req(input$map_capture)                                          # Vérification image présente
        img_b64 <- sub("^data:image/png;base64,", "", input$map_capture)       # Suppression préfixe base64
        img_bin <- base64enc::base64decode(img_b64)                            # Décodage base64
        base::writeBin(img_bin, file)                                          # Écriture binaire fichier
      },
      contentType = "image/png"                                                # Type MIME
    )

    # ──────────────────────────────────────────────────────────────────────────
    # Telechargement PDF
    # ──────────────────────────────────────────────────────────────────────────
    output$download_pdf <- shiny::downloadHandler(                             # Handler téléchargement PDF
      filename = function() {                                                  # Fonction nom fichier
        paste0("carte_OLD_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".pdf")      # Nom avec horodatage
      },
      content = function(file) {                                               # Fonction contenu PDF
        shiny::req(input$map_capture)                                          # Vérification image présente

        # Preparation de l image capturee
        img_b64  <- sub("^data:image/png;base64,", "", input$map_capture)      # Suppression préfixe base64
        img_tmp  <- tempfile(fileext = ".png")                                 # Fichier temporaire PNG
        base::writeBin(base64enc::base64decode(img_b64), img_tmp)             # Écriture image temporaire
        img      <- png::readPNG(img_tmp)                                      # Lecture image PNG
        base::unlink(img_tmp)                                                  # Suppression fichier temporaire

        # Chemins des ressources graphiques
        path_bg   <- "inst/app/www/images/feux_sud_est.png"                    # Chemin fond entête
        path_logo <- "inst/app/www/images/logo_prefete_drome.jpg"              # Chemin logo préfet
        couleur_entete <- "#AED3BD"                                            # Couleur entête vert pastel

        # Initialisation peripherique PDF
        grDevices::pdf(file, width = 11.69, height = 8.27)                     # Format A4 paysage pouces
        on.exit(grDevices::dev.off(), add = TRUE)                              # Fermeture auto périphérique

        # Definition de la mise en page matricielle
        graphics::layout(                                                      # Mise en page grille
          matrix(c(                                                            # Matrice zones
            1,1,1,1,                                                           # Zone 1 : ENTÊTE
            2,2,2,2,                                                           # Zone 2 : TITRE
            3,3,3,4,                                                           # Zone 3 : CARTE + Zone 4 : LÉGENDE
            5,5,5,5,                                                           # Zone 5 : AVERTISSEMENT
            6,6,6,6                                                            # Zone 6 : PIED
          ), ncol = 4, byrow = TRUE),                                          # 4 colonnes par ligne
          heights = c(0.12, 0.05, 0.75, 0.24, 0.05)                            # Hauteurs relatives zones
        )

        # ══════════════════════════════════════════════════════════════════════
        # ZONE 1 : EN-TETE AVEC FOND ET LOGO
        # ══════════════════════════════════════════════════════════════════════
        graphics::par(mar = c(0, 0, 0, 0))                                     # Suppression marges
        graphics::plot.new()                                                   # Nouveau graphique vide

        # Fond de l en-tete
        if (file.exists(path_bg)) {                                            # Test existence fichier fond
          tryCatch({                                                           # Gestion erreurs
            img_bg <- png::readPNG(path_bg)                                    # Lecture image fond
            graphics::rasterImage(img_bg, 0, 0, 1, 1)                          # Affichage plein écran
          }, error = function(e) {                                             # En cas erreur
            graphics::rect(0, 0, 1, 1, col = couleur_entete, border = NA)      # Rectangle couleur
          })
        } else {                                                               # Fichier absent
          graphics::rect(0, 0, 1, 1, col = couleur_entete, border = NA)        # Rectangle couleur
        }

        # Logo prefecture
        if (file.exists(path_logo)) {                                          # Test existence logo
          tryCatch({                                                           # Gestion erreurs
            img_logo <- jpeg::readJPEG(path_logo)                              # Lecture logo JPEG
            graphics::rasterImage(                                             # Affichage logo
              img_logo,                                                        # Image logo
              0.00,                                                            # Position gauche 0%
              0.05,                                                            # Position basse 5%
              0.18,                                                            # Position droite 18%
              0.95                                                             # Position haute 95%
            )
          }, error = function(e) {})                                           # Erreur silencieuse
        }

        # Textes de l en-tete alignes a droite
        graphics::text(                                                        # Texte principal
          0.98, 0.68,                                                          # Position 98% largeur 68% hauteur
          "Direction Départementale des Territoires",                          # Intitulé DDT
          adj  = c(1, 0.5),                                                    # Alignement droite centré
          cex  = 1.15,                                                         # Taille texte
          font = 2,                                                            # Gras
          col  = "black"                                                       # Noir
        )

        graphics::text(                                                        # Texte secondaire
          0.98, 0.46,                                                          # Position 98% largeur 46% hauteur
          "Service Eau, Forêts et Espaces Naturels",                           # Intitulé service
          adj  = c(1, 0.5),                                                    # Alignement droite centré
          cex  = 1.00,                                                         # Taille texte
          font = 2,                                                            # Gras
          col  = "black"                                                       # Noir
        )

        graphics::text(                                                        # Texte tertiaire
          0.98, 0.26,                                                          # Position 98% largeur 26% hauteur
          "Pôle Forêt",                                                        # Intitulé pôle
          adj  = c(1, 0.5),                                                    # Alignement droite centré
          cex  = 0.95,                                                         # Taille texte
          font = 2,                                                            # Gras
          col  = "black"                                                       # Noir
        )

        # ══════════════════════════════════════════════════════════════════════
        # ZONE 2 : TITRE DU DOCUMENT
        # ══════════════════════════════════════════════════════════════════════
        graphics::par(mar = c(0, 0, 0, 0))                                     # Suppression marges
        graphics::plot.new()                                                   # Nouveau graphique vide
        graphics::text(0.5, 0.5,                                               # Position centrée
                       "CARTOGRAPHIE INDICATIVE DES OBLIGATIONS LÉGALES DE DÉBROUSSAILLEMENT", # Titre
                       cex = 1.15, font = 2, adj = c(0.5, 0.5))                # Taille gras centré

        # ══════════════════════════════════════════════════════════════════════
        # ZONE 3 : CARTE (3/4 DE LA LARGEUR)
        # ══════════════════════════════════════════════════════════════════════
        graphics::par(mar = c(0, 0, 0, 0))                                     # Suppression marges
        graphics::plot.new()                                                   # Nouveau graphique vide
        left_margin <- 0.02                                                    # Marge gauche 2%
        right_margin <- 0.98                                                   # Marge droite 98%

        graphics::rasterImage(img, left_margin, 0, right_margin, 1)            # Affichage carte
        graphics::rect(left_margin, 0, right_margin, 1, lwd = 1.5)             # Cadre autour carte

        # ══════════════════════════════════════════════════════════════════════
        # ZONE 4 : LEGENDE (1/4 DE LA LARGEUR, ALIGNEE AVEC LA CARTE)
        # ══════════════════════════════════════════════════════════════════════
        graphics::par(mar = c(0, 0, 0, 0))                                     # Suppression marges
        graphics::plot.new()                                                   # Nouveau graphique vide
        graphics::rect(left_margin - 0.25, 0, right_margin - 0.1, 1,           # Rectangle fond
                       col = "#F8F8F8", border = "white")                      # Gris clair sans bordure

        # Titre de la legende
        graphics::text(0.5, 0.97, "LÉGENDE", cex = 0.95, font = 2)             # Titre centré gras

        # Trait de separation sous le titre
        graphics::segments(                                                    # Ligne horizontale
          x0 = left_margin + 0.025,                                            # Départ horizontal
          x1 = right_margin - 0.1,                                             # Arrivée horizontale
          y0 = 0.94,                                                           # Position verticale
          y1 = 0.94,                                                           # Position verticale
          col = "#999999"                                                      # Gris
        )

        # Initialisation des positions verticales
        y_pos <- 0.89                                                          # Position départ éléments
        y_step <- 0.12                                                         # Espacement vertical

        # Element 1 : Departement
        graphics::rect(0.05, y_pos - 0.02, 0.25, y_pos + 0.02,                 # Rectangle symbole
                       border = "#465F9D", lwd = 2, col = NA)                  # Bordure bleue
        graphics::text(0.30, y_pos, "Département", adj = 0, cex = 0.85)        # Texte descriptif
        y_pos <- y_pos - y_step                                                # Ligne suivante

        # Element 2 : Communes
        graphics::rect(0.05, y_pos - 0.02, 0.25, y_pos + 0.02,                 # Rectangle symbole
                       border = "#2c3e50", lwd = 1.5, col = NA)                # Bordure gris foncé
        graphics::text(0.30, y_pos, "Communes", adj = 0, cex = 0.85)           # Texte descriptif
        y_pos <- y_pos - y_step                                                # Ligne suivante

        # Element 3 : OLD 200m zones a risques
        graphics::rect(0.05, y_pos - 0.02, 0.25, y_pos + 0.02,                 # Rectangle symbole
                       border = "blue", lwd = 2, lty = 2,                      # Bordure bleue pointillée
                       col = rgb(0, 0, 225, 64, maxColorValue = 255))          # Remplissage bleu transparent
        graphics::text(0.30, y_pos, "Zones à risques", adj = 0, cex = 0.85)    # Texte principal
        graphics::text(0.30, y_pos - 0.035, "(OLD 200m)",                      # Texte secondaire
                       adj = 0, cex = 0.75, col = "grey40")                    # Petit gris
        y_pos <- y_pos - y_step - 0.04                                         # Ligne suivante espace supplémentaire

        # Element 4 : OLD 50m zones a debroussailler
        graphics::rect(0.05, y_pos - 0.02, 0.25, y_pos + 0.02,                 # Rectangle symbole
                       border = "black", lwd = 2, col = "#6D7EC3")             # Bordure noire remplissage bleu-violet
        graphics::text(0.30, y_pos + 0.01, "Zones à", adj = 0, cex = 0.85)     # Texte ligne 1
        graphics::text(0.30, y_pos - 0.03, "débroussailler",                   # Texte ligne 2
                       adj = 0, cex = 0.85)                                    # Taille normale
        graphics::text(0.30, y_pos - 0.065, "(OLD 50m)",                       # Texte ligne 3
                       adj = 0, cex = 0.75, col = "grey40")                    # Petit gris
        y_pos <- y_pos - y_step - 0.07                                         # Ligne suivante grand espace

        # Element 5 : Parcelles
        graphics::rect(0.05, y_pos - 0.02, 0.25, y_pos + 0.02,                 # Rectangle symbole
                       border = "#ff6a00", lwd = 2, col = NA)                  # Bordure orange
        graphics::text(0.30, y_pos + 0.01, "Limites", adj = 0, cex = 0.85)     # Texte ligne 1
        graphics::text(0.30, y_pos - 0.03, "parcellaires",                     # Texte ligne 2
                       adj = 0, cex = 0.85)                                    # Taille normale
        y_pos <- y_pos - y_step - 0.03                                         # Ligne suivante petit espace supplémentaire

        # Element 6 : Batiments
        graphics::rect(0.05, y_pos - 0.02, 0.25, y_pos + 0.02,                 # Rectangle symbole
                       border = "#ffa400", lwd = 1, col = "#ffa400")           # Bordure et remplissage orange
        graphics::text(0.30, y_pos, "Bâtiments", adj = 0, cex = 0.85)          # Texte descriptif
        y_pos <- y_pos - y_step                                                # Ligne suivante

        # Element 7 : PLU zonage urbain
        graphics::rect(0.05, y_pos - 0.02, 0.25, y_pos + 0.02,                 # Rectangle symbole
                       border = "black", lwd = 2, lty = 2, col = NA)           # Bordure noire pointillée
        graphics::text(0.30, y_pos + 0.01, "Zonage urbain", adj = 0, cex = 0.85) # Texte ligne 1
        graphics::text(0.30, y_pos - 0.03, "(PLU)", adj = 0, cex = 0.85)       # Texte ligne 2

        # ══════════════════════════════════════════════════════════════════════
        # ZONE 5 : AVERTISSEMENT ET INFORMATIONS PREALABLES
        # ══════════════════════════════════════════════════════════════════════
        graphics::par(mar = c(0, 0, 0, 0))                                     # Suppression marges
        graphics::plot.new()                                                   # Nouveau graphique vide

        # Cadre d avertissement
        graphics::rect(0, 0, 1, 1, col = "#FFF9E6",                             # Fond jaune très clair
                       border = "#FFA500", lwd = 2)                            # Bordure orange épaisse
        graphics::text(0.5, 0.94, "Avertissements et informations préalables", # Titre avertissement
                       font = 2, col = "#CC0000", cex = 0.90, adj = c(0.5, 0.5)) # Gras rouge centré

        # Texte de l avertissement
        texte_avertissement <- c(                                              # Vecteur lignes texte
          "Sur le territoire d'une commune, la cartographie indique la zone à débroussailler par chaque propriétaire.",
          "",                                                                  # Ligne vide
          "La cartographie est indicative, non opposable, et constitue un document d'information. Elle ne prétend que donner un aperçu",
          "le plus réaliste possible des périmètres à débroussailler.",
          "",                                                                  # Ligne vide
          "De nombreux paramètres peuvent en effet altérer l'exactitude des zones à débroussailler :",
          "  • changement récent de propriétaire, nouvelles constructions,",   # Puce 1
          "  • parcellaire cadastral imprécis,",                               # Puce 2
          "  • présence de routes, voies ferrées, lignes électriques,",        # Puce 3
          "  • pente des terrains, ...",                                       # Puce 4
          "  • ripisylves et forêts alluviales, ..."                           # Puce 5
        )

        y_text <- 0.82                                                         # Position verticale départ
        for (ligne in texte_avertissement) {                                   # Boucle chaque ligne
          graphics::text(0.02, y_text, ligne,                                  # Affichage ligne
                         adj = c(0, 0.5), cex = 0.85, col = "black")           # Aligné gauche noir
          y_text <- y_text - 0.075                                             # Décalage vertical
        }

        # ══════════════════════════════════════════════════════════════════════
        # ZONE 6 : PIED DE PAGE
        # ══════════════════════════════════════════════════════════════════════
        graphics::par(mar = c(0, 0, 0, 0))                                     # Suppression marges
        graphics::plot.new()                                                   # Nouveau graphique vide
        graphics::rect(0, 0, 1, 1, col = couleur_entete, border = NA)          # Fond vert pastel
        graphics::text(0.5, 0.5,                                               # Position centrée
                       paste("Sources : IGN – Réalisation DDT 26 –",           # Texte sources
                             format(Sys.Date(), "%d/%m/%Y")),                  # Date du jour
                       cex = 0.75, col = "black", adj = c(0.5, 0.5))           # Petit noir centré
      },
      contentType = "application/pdf"                                          # Type MIME
    )
  })
}