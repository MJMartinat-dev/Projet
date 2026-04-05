# ──────────────────────────────────────────────────────────────────────────────
# FICHIER       : app_ui.R
# AUTEUR        : Marie-Jeanne MARTINAT
# ORGANISATION  : DDT de la Drôme
# DATE          : 2025
# DESCRIPTION   : Interface utilisateur de l'application cartOLD
#                 - Navigation par onglets (Accueil / Carte / Avertissement / Aide)
#                 - Footer institutionnel + version dynamique
#                 - Injection des ressources externes (CSS/JS) via {golem}
# ──────────────────────────────────────────────────────────────────────────────
# CENTRALISATION DE L INTERFACE UTILISATEUR
# ──────────────────────────────────────────────────────────────────────────────
#' Interface utilisateur de l'application
#'
#' Construit la structure complète de l'interface avec :
#' - Barre de navigation (navbar) avec logo et titre
#' - Quatre onglets : Accueil, Carte interactive, Avertissement et Aide
#' - Footer avec mentions légales et informations de version
#'
#' @param request Paramètre interne Shiny pour bookmarking (ne pas supprimer)
#'
#' @return Un objet `shiny.tag.list` contenant l'UI complète
#'
#' @importFrom shiny tagList fluidPage navbarPage tabPanel tags
#' @importFrom shinyjs useShinyjs
#'
#' @noRd
app_ui <- function(request) {                                                   # Fonction principale UI
  shiny::tagList(                                                               # Regroupement de l en-tête et du corps Shiny

    golem_add_external_resources(),                                             # Injection CSS/JS/html/images/icones

    shinyjs::useShinyjs(),                                                      # Activation du shinyjs (show/hide/toggle/etc.)

    shiny::fluidPage(                                                           # Container Bootstrap responsive (corps)

      shiny::navbarPage(                                                        # Barre navigation principale
        title = shiny::tags$div(                                                # Titre = bloc logo + texte
          shiny::img(                                                           # Logo Préfecture
            src   = "www/images/logo_prefete_drome.jpg",                        # Chemin logo (via add_resource_path('www', …))
            style = "height: 60px; width: 80px;"                                # Hauteur pour aligner la navbar
          ),
          "cartOLD"                                                             # Texte titre application
        ),
        id          = "b-nav",                                                  # ID pour navigation JS
        theme       = NULL,                                                     # Pas de theme Bootstrap (CSS personnalise)
        windowTitle = "cartOLD",                                                # Titre dans l onglet du navigateur

        # ── Onglet Accueil ────────────────────────
        shiny::tabPanel(                                                        # Premier onglet
          title = shiny::tags$span(                                             # Titre avec icone Font Awesome
            shiny::tags$i(
              class = "fa-solid fa-house",                                      # Icone maison
              style = "margin-right: 5px;"                                      # Espacement icone / texte
            ),
            "Accueil"                                                           # Libelle de l onglet
          ),
          value = "accueil",                                                    # ID interne onglet (pour navigation programmee)
          mod_accueil_ui("accueil_ui_1")                                        # Module UI Accueil
        ),

        # ── Onglet Carte interactive ──────────────
        shiny::tabPanel(                                                        # Deuxieme onglet
          title = shiny::tags$span(                                             # Titre avec icone
            shiny::tags$i(
              class = "fa-solid fa-map-location-dot",                           # Icone carte + pointeur
              style = "margin-right: 5px;"                                      # Marges a droite de l icone
            ),
            "Carte interactive"                                                 # Libelle de l'onglet
          ),
          value = "carte",                                                      # ID interne onglet
          mod_carte_ui("carte_ui_1")                                            # Module UI Carte
        ),

        # ── Onglet Avertissement ───────────────────
        shiny::tabPanel(                                                        # Troisieme onglet
          title = shiny::tags$span(                                             # Titre avec icone d alerte
            shiny::tags$i(
              class = "fa-solid fa-triangle-exclamation",                       # Icone avertissement Font Awesome
              style = "margin-right: 5px; color: #eab308;"                      # Marge à droite + couleur rappel de l icone
            ),
            "Avertissement"                                                     # Texte affiche dans onglet
          ),
          value = "avertissement",                                              # ID unique pour navigation
          mod_avertissement_ui("avertissement_ui_1")                            # Appel module UI Avertissement
        ),

        # ── Onglet Aide ────────────────────────────
        shiny::tabPanel(                                                        # Quatrieme onglet
          title = shiny::tags$span(                                             # Titre avec icone info
            shiny::tags$i(
              class = "fa-solid fa-circle-info",                                # Icone info Font Awesome
              style = "margin-right: 5px;"                                      # Espace a droite de l icone
            ),
            "Aide"                                                              # Texte affiche dans onglet
          ),
          value = "aide",                                                       # ID unique pour navigation
          mod_aide_ui("aide_ui_1")                                              # Appel module UI Aide
        ),

        # ── Footer ─────────────────────────────────
        footer = shiny::tags$footer(                                            # Pied de page global
          class = "pd-page",                                                    # Classe CSS
          style = paste(                                                        # Style inline pour compatibilite immediate
            "background: #465F9D;",                                             # Bleu ministeriel
            "margin: 0px;",                                                     # Pas de marge externe
            "padding: 2px;",                                                    # Padding minimal
            "border-top: 1px solid #465F9D;",                                   # Ligne de separation
            "text-align: center;"                                               # Texte centre
          ),

          # ── Liens lgeaux + structure ─────────────
          shiny::tags$div(                                                      # Bloc texte + liens legaux
            shiny::tags$a(                                                      # Lien mentions legales
              href   = "www/html/mentions_legales.html",                        # Fichier HTML statique
              target = "_blank",                                                # Ouverture nouvel onglet
              "Mentions légales"                                                # Libelle du lien
            ),
            " | ",                                                              # Séparateur
            shiny::tags$a(                                                      # Lien confidentialite
              href   = "www/html/confidentialite.html",                         # Fichier HTML statique
              target = "_blank",                                                # Nouvel onglet
              "Confidentialité"                                                 # Libelle du lien
            ),
            " | ",                                                              # Separateur
            shiny::tags$span("Préfète de la Drôme - DDT de la Drôme")           # Texte institutionnel
          ),

          # Version + année courante
          shiny::tags$div(                                                      # Bloc version/copyright
            style = "font-size: 0.9em; color: #ddd;",                           # Style texte secondaire
            sprintf(
              "Version %s - © %s",                                              # Format d affichage
              tryCatch(                                                         # Recuperation robuste version package
                as.character(utils::packageVersion("cartOLD")),                 # Version depuis DESCRIPTION
                error = function(e) "0.0.1"                                     # Valeur de fallback si erreur (dev / non installé)
              ),
              format(Sys.Date(), "%Y")                                          # Annee courante
            )
          )
        )                                                                       # Fin footer
      )                                                                         # Fin navbarPage
    )                                                                           # Fin fluidPage
  )                                                                             # Fin tagList
}                                                                               # Fin app_ui()

# ──────────────────────────────────────────────────────────────────────────────
# INJECTION DES RESSOURCES EXTERNES
# ──────────────────────────────────────────────────────────────────────────────
#' Ajoute les ressources externes a l application
#'
#' - Ajoute le dossier `www/` comme ressource statique (CSS / JS / images)
#' - Injecte les librairies externes (CDN)
#' - Charge la configuration JavaScript globale de l application
#' - Ajoute la favicon et les styles critiques
#'
#' @return Balise <head> contenant toutes les ressources
#'
#' @importFrom golem add_resource_path bundle_resources
#' @importFrom shiny tags
#'
#' @noRd
golem_add_external_resources <- function() {

  # ───────────────────────────────────────────────────────────
  # DETERMINATION DU CHEMIN DES RESSOURCES
  # ───────────────────────────────────────────────────────────
  # L application fonctionne dans deux contextes :
  # - Developpement local → fichiers dans inst/app/www
  # - Deploiement (shinyapps.io) → inst/ est installe dans le
  #   package
  #
  # tryCatch() permet de tester app_sys() en production, sinon
  # fallback en dev.
  # ───────────────────────────────────────────────────────────
  www_path <- tryCatch(
    app_sys("app/www"),                                                         # Cas production : package installe
    error = function(e) {
      if (dir.exists("inst/app/www")) {
        "inst/app/www"                                                          # Cas developpement golem classique
      } else {
        "app/www"                                                               # Cas developpement minimaliste / fallback
      }
    }
  )

  # ───────────────────────────────────────────────────────────
  # EXPORT DU DOSSIER "www"
  # ───────────────────────────────────────────────────────────
  # Permet a Shiny d acceder aux ressources statiques :
  #   - CSS, JS, HTML, images
  # Le préfixe "www" sera resolu automatiquement dans toutes les URL.
  # ───────────────────────────────────────────────────────────
  golem::add_resource_path("www", www_path)

  # ───────────────────────────────────────────────────────────
  # CONSTRUCTION DU <head>
  # ───────────────────────────────────────────────────────────
  # Les ressources sont ajoutees dans l ordre :
  #   - favicon
  #   - configuration JavaScript globale
  #   - CSS critique inline
  #   - bundle golem (charge tous les fichiers du dossier www_path)
  #   - CDN externes : Font Awesome, html2canvas, plugin IGN
  #
  # shiny::tags$head() encapsule l ensemble.
  # ───────────────────────────────────────────────────────────
  shiny::tags$head(

    # ───────────────────────────────────────────────────────────
    # FAVICON
    # ───────────────────────────────────────────────────────────
    # Permet d afficher l icone cartOLD dans l onglet du navigateur.
    # Le chemin est relatif au prefixe "www" defini plus haut.
    # ───────────────────────────────────────────────────────────
    shiny::tags$link(
      rel  = "icon",
      type = "image/x-icon",
      href = "www/icones/cartOLD.ico"
    ),

    # ───────────────────────────────────────────────────────────
    # CONFIGURATION JAVASCRIPT GLOBALE
    # ───────────────────────────────────────────────────────────
    # On initialise ici un objet "window.cartOLD" contenant des
    # parametres accessibles a tout le JavaScript custom :
    #   - version
    #   - mode debug
    #   - endpoints API
    # Ce bloc est execute au chargement du <head>.
    # ───────────────────────────────────────────────────────────
    shiny::tags$script(shiny::HTML("
      window.cartOLD = {
        version: '1.0.0',
        debug: false,
        communeBAN: null,
        initialized: false,
        apiEndpoints: {
          ban: 'https://api-adresse.data.gouv.fr/search/',
          ign: 'https://data.geopf.fr/wmts'
        }
      };
      console.log('[cartOLD] Configuration JS globale chargée');
    ")),

    # ───────────────────────────────────────────────────────────
    # CSS CRITIQUE INLINE
    # ───────────────────────────────────────────────────────────
    # Ici les styles courts et necessaires au rendu initial de
    # Leaflet. Cela evite un flash de mauvaise mise en page.
    # ───────────────────────────────────────────────────────────
    shiny::tags$style(shiny::HTML("
      .leaflet-container {
        font-family: Arial, sans-serif;
      }
    ")),

    # ───────────────────────────────────────────────────────────
    # CHARGEMENT DES RESSOURCES GOLEM
    # ───────────────────────────────────────────────────────────
    # bundle_resources() scanne automatiquement le dossier :
    #   - css/
    #   - js/
    #   - images/
    #   - html/
    # Et injecte chaque fichier dans le <head>.
    #
    # IMPORTANT :
    # Ne pas recharger manuellement ces fichiers ailleurs, golem
    # s en charge.
    # ───────────────────────────────────────────────────────────
    golem::bundle_resources(
      path = www_path,
      app_title = "cartOLD"
    ),

    # ───────────────────────────────────────────────────────────
    # LIBRAIRIES EXTERNES (CDN)
    # ───────────────────────────────────────────────────────────
    # Ce sont les dependances front-end indispensables a l application.
    # Chacune est chargee en HTTPS depuis un CDN stable.
    # ───────────────────────────────────────────────────────────
    # ── Font Awesome 6.5.2 (icônes utilisées dans la navbar,
    #    etc.) ──────────────────────────────────────────────────
    shiny::tags$link(
      rel = "stylesheet",
      href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css"
    ),

    # ── html2canvas : necessaire pour l export des cartes en PNG
    shiny::tags$script(
      src = "https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"
    ),

    # ── Plugin Leaflet IGN : permet d accéder aux couches WMTS
    #    du Geoportail ───────────────────────────────────────────
    shiny::tags$script(
      src = "https://ignf.github.io/geoportal-extensions/leaflet-latest/dist/GpPluginLeaflet.js",
      `data-key` = "essentiels"                                                 # Cle API publique pour couches gratuites
    )
  )
}

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU FICHIER
# ──────────────────────────────────────────────────────────────────────────────
