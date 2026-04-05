# ──────────────────────────────────────────────────────────────────────────────
# FICHIER      : R/app_server.R
# AUTEUR       : Marie-Jeanne MARTINAT
# ORGANISATION : DDT de la Drôme
# DATE         : 2025
# DESCRIPTION  : Logique serveur principale de l application cartOLD
#                Version déployée directement sur shinyapps.io
#                Gere l orchestration generale du backend de l application :
#                - Creation d'un conteneur reactif partage entre modules
#                - Configuration des options globales de Shiny
#                - Etablissement des relais d informations entre JavaScript et R
#                - Initialisation des modules serveur
# ──────────────────────────────────────────────────────────────────────────────
# CENTRALISATION DES FONCTIONS SERVER
# ───────────────────────────────────────────────────────────
#' Fonction principale du serveur Shiny
#'
#' Assure la coordination générale du backend de l application par les actions suivantes :
#' - Creation d'un conteneur reactif qui permet l echange d informations entre les modules
#' - Configuration des parametres globaux de Shiny
#' - Mise en place des liaisons d informations entre JavaScript et R
#' - Initialisation des differents modules du serveur
#'
#' @param input   Liste des entrées réactives envoyées par l’UI
#' @param output  Liste des sorties envoyées vers l'UI
#' @param session Contexte de session Shiny (communication avec le client)
#'
#' @importFrom shiny reactiveValues observeEvent
#' @noRd
app_server <- function(input, output, session) {

  # ───────────────────────────────────────────────────────────
  # CONTENEUR REACTIF PARTAGE ENTRE MODULES
  # ───────────────────────────────────────────────────────────
  # 'r' agit comme un espace memoire partage permettant aux modules
  # de communiquer sans passer par des inputs/outputs visibles.
  # Exemple : r$adresse_commune_info, r$navigate_to_aide, r$data, etc.
  r <- shiny::reactiveValues()


  # ───────────────────────────────────────────────────────────
  # PARAMETRES GLOBAUX SHINY
  # ───────────────────────────────────────────────────────────
  # shiny.sanitize.errors = TRUE :
  # - evite l'affichage des messages d erreur R côte navigateur
  # - ameliore la securite (pas de fuite d informations internes)
  # - recommande en production
  options(
    shiny.sanitize.errors = TRUE
  )


  # ───────────────────────────────────────────────────────────
  # RELAIS ENTRE LE JAVASCRIPT ET LE SERVEUR R
  # ───────────────────────────────────────────────────────────
  # Le script JS externe envoie des données via input$adresse_commune_info.
  # Cette info doit etre repercutee dans 'r' pour que les modules
  # puissent reagir automatiquement quand une adresse est selectionnee.
  shiny::observeEvent(input$adresse_commune_info, {
    r$adresse_commune_info <- input$adresse_commune_info                        # Mise à jour du conteneur partagé
  })


  # ───────────────────────────────────────────────────────────
  # INITIALISATION DES MODULES SERVEUR
  # ───────────────────────────────────────────────────────────
  # Chaque module gere une partie logique specifique :
  # - accueil : page statique
  # - avertissement : mentions légales
  # - aide : tutoriels / FAQ
  # - carte : traitement géospatial + Leaflet + data
  #
  # Le conteneur 'r' est transmis uniquement la ou necessaire.
  mod_accueil_server("accueil_ui_1")                                            # Serveur du module d'accueil
  mod_avertissement_server("avertissement_ui_1")                                # Serveur du module d'avertissement
  mod_aide_server("aide_ui_1")                                                  # Serveur du module d'aide
  mod_carte_server("carte_ui_1", r)                                             # Serveur du module carte : seul module necessitant un acces complet aux donnees reactives


  # ───────────────────────────────────────────────────────────
  # NAVIGATION PROGRAMMATIQUE (JS → SERVEUR → UI)
  # ───────────────────────────────────────────────────────────
  # Certains elements JS déclenchent r$navigate_to_aide.
  # Des que ce flag s active, on bascule l utilisateur sur l onglet "Aide".
  shiny::observeEvent(r$navigate_to_aide, {
    shiny::updateNavbarPage(
      session = session,                                                       # Session active
      inputId = "b-nav",                                                       # ID de la barre de navigation définie dans l'UI
      selected = "aide"                                                        # Onglet a activer
    )
  }, ignoreInit = TRUE)                                                        # Pas de declenchement au chargement
}                                                                              # Fin de app_server()


# ──────────────────────────────────────────────────────────────────────────────
# FIN DU FICHIER
# ──────────────────────────────────────────────────────────────────────────────
