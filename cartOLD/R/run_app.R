# ──────────────────────────────────────────────────────────────────────────────
# FICHIER     : run_app.R
# AUTEUR      : MJ Martinat
# DATE        : 2025
# ORGANISATION: DDT de la Drôme - Ministère de la Transition Écologique
# DESCRIPTION : Fonction de lancement de l'application cartOLD
#               Version DÉPLOIEMENT DIRECT sur shinyapps.io
# ──────────────────────────────────────────────────────────────────────────────
#' Lancement de l'application Shiny
#'
#' Fonction principale pour démarrer l'application cartOLD.
#' Version simplifiée pour déploiement direct (sans golem::with_golem_options).
#'
#' @param onStart Fonction à exécuter au démarrage de l'application
#' @param options Liste d'options pour shiny::shinyApp
#' @param enableBookmarking Active le système de bookmarking Shiny
#' @param uiPattern Pattern URL pour l'UI (défaut "/")
#' @param ... Arguments additionnels (ignorés en déploiement direct)
#'
#' @return Objet shiny.appobj (application Shiny)
#'
#' @export
#'
#' @importFrom shiny shinyApp
#'
#' @examples
#' if (interactive()) {
#'   run_app()
#' }

run_app <- function(
  onStart = NULL,                                                               # Fonction démarrage optionnelle
  options = list(),                                                             # Options Shiny
  enableBookmarking = NULL,                                                     # Bookmarking optionnel
  uiPattern = "/",                                                              # Pattern URL par défaut
  ...                                                                           # Arguments additionnels ignorés
) {                                                                             # Début corps fonction

  shiny::shinyApp(                                                              # Création application Shiny
    ui = app_ui,                                                                # Interface utilisateur
    server = app_server,                                                        # Logique serveur
    onStart = onStart,                                                          # Fonction démarrage
    options = options,                                                          # Options application
    enableBookmarking = enableBookmarking,                                      # Bookmarking
    uiPattern = uiPattern                                                       # Pattern URL
  )                                                                             # Fin shinyApp
}                                                                               # Fin fonction

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU FICHIER
# ──────────────────────────────────────────────────────────────────────────────
