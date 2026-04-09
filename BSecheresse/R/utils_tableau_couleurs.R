# ------------------------------------------------------------------------------
# FICHIER      : utils_tableau_couleurs.R
# ------------------------------------------------------------------------------
# AUTEUR       : MJMartinat
# Structure    : DDT de la Drôme
# DATE         : 2026-01-05
# ------------------------------------------------------------------------------
# DESCRIPTION  : Fonctions utilitaires pour appliquer les couleurs de restriction
#                aux tableaux HTML avec support d'impression PDF
# ------------------------------------------------------------------------------
# Palette de couleurs institutionnelles
# ------------------------------------------------------------------------------
COULEURS_RESTRICTION <- list(
  "Pas de restriction" = "#e6efff",
  "Vigilance"          = "#f7efa5",
  "Alerte"             = "#ffb542",
  "Alerte renforcée"   = "#ff4a29",
  "Crise"              = "#ad0021",
  "Non Définie"        = "#dddddd",
  "Inconnu"            = "#dddddd"
)


# ------------------------------------------------------------------------------
# Couleurs de texte (blanc sur fond foncé)
# ------------------------------------------------------------------------------
COULEURS_TEXTE <- list(
  "Pas de restriction" = "#000000",
  "Vigilance"          = "#000000",
  "Alerte"             = "#000000",
  "Alerte renforcée"   = "#000000",
  "Crise"              = "#ffffff",
  "Non Définie"        = "#000000",
  "Inconnu"            = "#000000"
)


# ------------------------------------------------------------------------------
#' Obtient la couleur de fond pour un niveau de restriction
# ------------------------------------------------------------------------------
#' @param niveau Niveau de restriction (ex: "Vigilance", "Alerte")
#' @return Code couleur hexadécimal
#' @export
couleur_restriction <- function(niveau) {
  if (is.na(niveau) || niveau == "") {
    return(COULEURS_RESTRICTION[["Non Définie"]])
  }

  if (niveau %in% names(COULEURS_RESTRICTION)) {
    return(COULEURS_RESTRICTION[[niveau]])
  }

  return(COULEURS_RESTRICTION[["Inconnu"]])
}


# ------------------------------------------------------------------------------
#' Obtient la couleur de texte pour un niveau de restriction
# ------------------------------------------------------------------------------
#' @param niveau Niveau de restriction
#' @return Code couleur hexadécimal
#' @export
couleur_texte_restriction <- function(niveau) {
  if (is.na(niveau) || niveau == "") {
    return(COULEURS_TEXTE[["Non Définie"]])
  }

  if (niveau %in% names(COULEURS_TEXTE)) {
    return(COULEURS_TEXTE[[niveau]])
  }

  return(COULEURS_TEXTE[["Inconnu"]])
}


# ------------------------------------------------------------------------------
#' Crée un span HTML avec style de couleur de restriction
# ------------------------------------------------------------------------------
#' @param texte Texte à afficher
#' @param niveau Niveau de restriction pour la couleur
#' @return Code HTML avec style inline
#' @export
span_couleur_restriction <- function(texte, niveau) {
  bg_color <- couleur_restriction(niveau)
  txt_color <- couleur_texte_restriction(niveau)

  glue::glue(
    '<span style="',
    'background-color:{bg_color}; ',
    'color:{txt_color}; ',
    'padding:2px 6px; ',
    'border-radius:3px; ',
    'display:inline-block; ',
    '-webkit-print-color-adjust:exact; ',
    'print-color-adjust:exact;',
    '">{texte}</span>'
  )
}


# ------------------------------------------------------------------------------
#' Applique les couleurs de restriction à une colonne d'un tableau kable
# ------------------------------------------------------------------------------
#' @param kbl Objet kable
#' @param df Dataframe source
#' @param colonne_restriction Nom de la colonne contenant les niveaux
#' @return Objet kable modifié
#' @export
appliquer_couleurs_tableau <- function(kbl, df, colonne_restriction) {

  if (!requireNamespace("kableExtra", quietly = TRUE)) {
    return(kbl)
  }

  # Parcours des lignes pour appliquer les couleurs
  for (i in seq_len(nrow(df))) {
    niveau <- df[[colonne_restriction]][i]

    if (!is.na(niveau) && niveau != "") {
      bg_color <- couleur_restriction(niveau)
      txt_color <- couleur_texte_restriction(niveau)

      kbl <- kableExtra::row_spec(
        kbl,
        row = i,
        background = bg_color,
        color = txt_color,
        extra_css = "-webkit-print-color-adjust:exact; print-color-adjust:exact;"
      )
    }
  }

  return(kbl)
}


# ------------------------------------------------------------------------------
#' Génère un CSS inline pour forcer les couleurs à l'impression
# ------------------------------------------------------------------------------
#' @return Chaîne CSS
#' @export
css_print_colors <- function() {
  css <- '
<style>
@media print {
  * {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
    color-adjust: exact !important;
  }

  table, tr, td, th {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
  }
}

/* Classes de couleurs de restriction */
.restriction-pas { background-color: #e6efff !important; }
.restriction-vigilance { background-color: #f7efa5 !important; }
.restriction-alerte { background-color: #ffb542 !important; }
.restriction-alerte-renforcee { background-color: #ff4a29 !important; }
.restriction-crise { background-color: #ad0021 !important; color: white !important; }
.restriction-non-definie { background-color: #dddddd !important; }
</style>
'
  return(css)
}


# ------------------------------------------------------------------------------
#' Crée un tableau HTML avec couleurs de restriction
# ------------------------------------------------------------------------------
#' @param df Dataframe à afficher
#' @param col_restriction Colonne contenant les niveaux de restriction
#' @param titre Titre optionnel du tableau
#' @return Code HTML du tableau
#' @export
tableau_restriction_html <- function(df, col_restriction = NULL, titre = NULL) {

  if (!requireNamespace("kableExtra", quietly = TRUE)) {
    stop("Le package kableExtra est requis.")
  }

  # Création du tableau de base
  kbl <- knitr::kable(
    df,
    format = "html",
    escape = FALSE,
    row.names = FALSE,
    align = rep("c", ncol(df))
  ) %>%
    kableExtra::kable_styling(
      full_width = FALSE,
      position = "center",
      font_size = 10.5,
      bootstrap_options = c("striped", "bordered", "condensed")
    ) %>%
    kableExtra::row_spec(0, bold = TRUE, background = "#e6efff")

  # Application des couleurs si colonne spécifiée
  if (!is.null(col_restriction) && col_restriction %in% names(df)) {
    kbl <- appliquer_couleurs_tableau(kbl, df, col_restriction)
  }

  # Ajout du titre si spécifié
  if (!is.null(titre)) {
    html_out <- paste0(
      '<div style="margin:15px 0;">',
      '<div style="font-weight:bold; background:#001942; color:white; padding:8px; text-align:center;">',
      titre,
      '</div>',
      as.character(kbl),
      '</div>'
    )
  } else {
    html_out <- as.character(kbl)
  }

  return(html_out)
}

# ------------------------------------------------------------------------------
# Fonction de diagnostic
# ------------------------------------------------------------------------------
#' Vérifie que les couleurs sont correctement définies
#'
#' @return TRUE si OK, FALSE sinon avec message
#' @export
verifier_couleurs <- function() {
  message("=== Vérification des couleurs de restriction ===")

  for (niveau in names(COULEURS_RESTRICTION)) {
    bg <- COULEURS_RESTRICTION[[niveau]]
    txt <- COULEURS_TEXTE[[niveau]]
    message(sprintf("  %s : fond=%s, texte=%s", niveau, bg, txt))
  }

  message("================================================")
  return(TRUE)
}
