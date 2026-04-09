# ------------------------------------------------------------------------------
# SCRIPT      : utils.R
# ------------------------------------------------------------------------------
# AUTEUR      : MJ Martinat
# Structure   : DDT de la Drôme
# DATE        : 01/07/2025
# ------------------------------------------------------------------------------
# DESCRIPTION : Fonctions utilitaires pour l'échappement LaTeX/HTML, le
#               traitement des seuils et la génération automatique des blocs
#               sectoriels avec mise en forme colorée pour les bulletins
#               sécheresse.
# SORTIE      : Tableaux enrichis (HTML/LaTeX) avec couleurs par seuil et
#               restriction.
# ------------------------------------------------------------------------------
# Chargement des bibliothèques
# ------------------------------------------------------------------------------
library(dplyr)                                                                  # Manipulation/filtrage/joins (dplyr)
library(stringr)                                                                # Opérations robustes sur chaînes (regex, trim, etc.)
library(tibble)                                                                 # Tibbles (dataframes "modernes")
library(glue)                                                                   # Construction de texte paramétrée (LaTeX/HTML)
library(readr)                                                                  # Lecture fichiers (CSV/TSV) avec gestion encoding
library(here)                                                                   # Chemins projet portables (évite setwd)
library(knitr)                                                                  # Détection format de sortie (LaTeX/HTML) via knitr
library(kableExtra)                                                             # Mise en forme avancée des tableaux (HTML/LaTeX)
library(magrittr)                                                               # Pipe %>% et opérateur %||% (fallback)
library(lubridate)                                                              # Manipulation de dates (si besoin ailleurs)
library(janitor)                                                                # Nettoyage standardisé des noms de colonnes
library(purrr)                                                                  # Programmation fonctionnelle (pmap, map, etc.)
library(progress)                                                               # Barre de progression (console) pour étapes longues


# ------------------------------------------------------------------------------
# Fonctions d'échappement latex / html
# ------------------------------------------------------------------------------
#' Échappe les caractères spéciaux LaTeX
#' @param x Chaîne de caractères à échapper
#' @return Chaîne avec caractères spéciaux échappés pour LaTeX
echapper_latex <- function(x) {                                                 # Définition fonction : échappement LaTeX
  x %>%                                                                         # Début pipeline sur x
    stringr::str_replace_all("\\\\", "\\\\textbackslash{}") %>%                 # \ -> \textbackslash{} (évite conflit LaTeX)
    stringr::str_replace_all("([{}])", "\\\\\\1") %>%                           # { } -> \{ \} (protection des accolades)
    stringr::str_replace_all("_", "\\\\_") %>%                                  # _ -> \_ (underscore réservé en LaTeX)
    stringr::str_replace_all("%", "\\\\%") %>%                                  # % -> \% (commentaire LaTeX sinon)
    stringr::str_replace_all("&", "\\\\&") %>%                                  # & -> \& (tabular align sinon)
    stringr::str_replace_all("#", "\\\\#") %>%                                  # # -> \# (macro params sinon)
    stringr::str_replace_all("\\^", "\\\\^{}") %>%                              # ^ -> \^{} (accent circonflexe)
    stringr::str_replace_all("~", "\\\\~{}") %>%                                # ~ -> \~{} (tilde)
    stringr::str_replace_all("\\$", "\\\\$")                                    # $ -> \$ (mode math sinon)
}                                                                               # Fin fonction echapper_latex


# ------------------------------------------------------------------------------
#' Échappe les caractères spéciaux HTML
# ------------------------------------------------------------------------------
#' @param x Chaîne de caractères à échapper
#' @return Chaîne avec caractères spéciaux échappés pour HTML
echapper_html <- function(x) {                                                  # Définition fonction : échappement HTML
  x %>%                                                                         # Début pipeline sur x
    stringr::str_replace_all("&", "&amp;") %>%                                  # & -> &amp; (doit être en premier)
    stringr::str_replace_all("<", "&lt;") %>%                                   # < -> &lt; (évite injection balises)
    stringr::str_replace_all(">", "&gt;") %>%                                   # > -> &gt;
    stringr::str_replace_all('"', "&quot;") %>%                                 # " -> &quot; (attributs HTML)
    stringr::str_replace_all("'", "&#39;")                                      # ' -> &#39; (apostrophe)
}                                                                               # Fin fonction echapper_html


# ------------------------------------------------------------------------------
#' Échappe selon le format de sortie actuel (LaTeX ou HTML)
# ------------------------------------------------------------------------------
#' @param x Chaîne de caractères à échapper
#' @return Chaîne échappée selon le format de sortie knitr
echapper_format <- function(x) {                                                # Définition fonction : routeur échappement
  if (knitr::is_latex_output()) echapper_latex(x)                               # Si sortie LaTeX : échappement LaTeX
  else if (knitr::is_html_output()) echapper_html(x)                            # Si sortie HTML : échappement HTML
  else x                                                                        # Autre format : ne pas modifier (fallback)
}                                                                               # Fin fonction echapper_format


# ──────────────────────────────────────────────────────────────────────────────
# Fonction de nettoyage des noms de stations
# ──────────────────────────────────────────────────────────────────────────────
#' Nettoie et formate les noms de stations pour éviter les coupures
#' @param x Nom de station brut
#' @return Nom de station nettoyé avec espaces insécables si nécessaire
nettoyer_nom_station <- function(x) {                                           # Définition fonction : normalisation noms stations
  if (is.na(x) || x == "") return(x)                                            # Cas limite : NA ou chaîne vide -> renvoyer tel quel

  x %>%                                                                         # Début pipeline sur x
    stringr::str_squish() %>%                                                   # Supprime espaces multiples et trims (robuste PDF/HTML)
    stringr::str_replace_all("\\s*-\\s*", "-") %>%                              # Normalise tirets en supprimant espaces autour
    stringr::str_replace_all("([A-Z][a-z]+)([A-Z])", "\\1 \\2") %>%             # Sépare CamelCase : "LaGarde" -> "La Garde"
    stringr::str_replace_all("sur([A-Z])", "sur-\\1") %>%                       # Corrige "surGervanne" -> "sur-Gervanne"
    stringr::str_replace_all("en([A-Z])", "en-\\1") %>%                         # Corrige "enDiois" -> "en-Diois"
    stringr::str_replace_all("les([A-Z])", "les-\\1") %>%                       # Corrige "lesSauzet" -> "les-Sauzet"
    stringr::str_replace_all("de([A-Z])", "de-\\1") %>%                         # Corrige "deBarret" -> "de-Barret"
    stringr::str_replace_all("-", " - ") %>%                                    # Ajoute espaces autour du tiret pour lisibilité
    stringr::str_squish()                                                       # Nettoie espaces finaux (sécurité)
}                                                                               # Fin fonction nettoyer_nom_station


# ──────────────────────────────────────────────────────────────────────────────
# Chargement et nettoyage des données de restrictions
# ──────────────────────────────────────────────────────────────────────────────
restrictions <- readr::read_delim(                                              # Lecture du fichier restrictions.csv (source métier)
  here::here("donnees", "bulletin", "origines", "restrictions.csv"),            # Chemin projet (portable) vers source restrictions
  delim = ";",                                                                  # Délimiteur CSV attendu (format Excel FR fréquent)
  locale = readr::locale(encoding = "Windows-1252"),                            # Encodage Windows (accents) pour compatibilité
  show_col_types = FALSE                                                        # Désactive log de types (sortie console propre)
) %>%                                                                           # Pipeline
  janitor::clean_names()                                                        # Normalise noms colonnes : snake_case, minuscule

# ---- Création de la colonne perspectives_restrictions si absente -------------
if (!"perspectives_restrictions" %in% names(restrictions)) {                    # Test présence colonne perspectives
  restrictions$perspectives_restrictions <- NA_character_                       # Ajout colonne vide (char) pour éviter erreurs downstream
}                                                                               # Fin if ajout colonne perspectives

# ---- Conversion des codes de restrictions en libellés clairs + couleurs officielles
restrictions <- restrictions %>%                                                # Pipeline de transformation restrictions
  dplyr::mutate(                                                                # Création de colonnes dérivées
    restriction_txt = dplyr::case_when(                                         # Libellé "Restriction" (état actuel)
      restrictions == "N"  ~ "Pas de restriction",                              # N = normal / pas de restriction
      restrictions == "V"  ~ "Vigilance",                                       # V = vigilance
      restrictions == "A"  ~ "Alerte",                                          # A = alerte
      restrictions == "Ar" ~ "Alerte renforcée",                                # Ar = alerte renforcée
      restrictions == "C"  ~ "Crise",                                           # C = crise
      is.na(restrictions)  ~ "Non Définie",                                     # NA = non défini (donnée absente)
      TRUE ~ "Inconnu"                                                          # Autre valeur = anomalie
    ),                                                                          # Fin mapping restriction_txt
    couleur_restriction = dplyr::case_when(                                     # Couleur officielle associée à l'état actuel
      restrictions == "N"  ~ "#e6efff",                                         # Couleur "Normal" (bleu très clair)
      restrictions == "V"  ~ "#f7efa5",                                         # Couleur "Vigilance" (jaune pâle)
      restrictions == "A"  ~ "#ffb542",                                         # Couleur "Alerte" (orange)
      restrictions == "Ar" ~ "#ff4a29",                                         # Couleur "Alerte renforcée" (rouge/orange fort)
      restrictions == "C"  ~ "#ad0021",                                         # Couleur "Crise" (rouge foncé)
      TRUE ~ "#DDDDDD"                                                          # Couleur fallback (gris) en cas d'inconnu
    ),                                                                          # Fin mapping couleur_restriction
    perspectives_txt = dplyr::case_when(                                        # Libellé "Perspective" (projection / tendance)
      perspectives_restrictions == "N"  ~ "Pas de restriction",                 # Même codification que restrictions
      perspectives_restrictions == "V"  ~ "Vigilance",                          # V
      perspectives_restrictions == "A"  ~ "Alerte",                             # A
      perspectives_restrictions == "Ar" ~ "Alerte renforcée",                   # Ar
      perspectives_restrictions == "C"  ~ "Crise",                              # C
      is.na(perspectives_restrictions)  ~ "Non Définie",                        # NA
      TRUE ~ "Inconnu"                                                          # Autre
    ),                                                                          # Fin mapping perspectives_txt
    couleur_perspective = case_when(                                            # Couleur associée à la perspective
      perspectives_restrictions == "N"  ~ "#e6efff",                            # Normal
      perspectives_restrictions == "V"  ~ "#f7efa5",                            # Vigilance
      perspectives_restrictions == "A"  ~ "#ffb542",                            # Alerte
      perspectives_restrictions == "Ar" ~ "#ff4a29",                            # Alerte renforcée
      perspectives_restrictions == "C"  ~ "#ad0021",                            # Crise
      TRUE ~ "#DDDDDD"                                                          # Fallback
    )                                                                           # Fin mapping couleur_perspective
  )                                                                             # Fin mutate restrictions


# ------------------------------------------------------------------------------
# FONCTION : couleur_seuil()
# ------------------------------------------------------------------------------
# Retourne une couleur HTML selon la valeur observée et les seuils
# ──────────────────────────────────────────────────────────────────────────────
couleur_seuil <- function(Mode_de_gestion, Stations, date_str, valeur, seuils_hydro, seuils_piezo) {  # Signature : dépend mode + station + date + valeur + seuils
  if (is.na(valeur) || is.na(Stations) || is.na(date_str)) return("#FFFFFF")    # Si donnée incomplète : fond blanc (neutralité visuelle)

  val <- suppressWarnings(as.numeric(valeur)) %>% round(4)                      # Conversion numérique sécurisée + arrondi (stabilité comparaisons)
  if (is.na(val)) return("#FFFFFF")                                             # Si conversion échoue : blanc (évite erreurs compare)

  date_obs_ref <- parse_obs_date(Mode_de_gestion, date_str)                     # Normalise la date d'observation pour matcher dates des seuils

  seuils <- if (Mode_de_gestion == "Débits") {                                  # Choix référentiel seuils selon mode
    seuils_hydro %>% dplyr::rename(date_seuil_ref = date)                       # Harmonise nom de colonne date (hydro)
  } else if (Mode_de_gestion == "Nappes") {                                     # Cas nappes (piézo)
    seuils_piezo %>% dplyr::rename(date_seuil_ref = date)                       # Harmonise nom de colonne date (piézo)
  } else {                                                                      # Autre mode non géré
    return("#FFFFFF")                                                           # Retour blanc (mode inconnu)
  }                                                                             # Fin sélection seuils

  seuils <- seuils %>%                                                          # Pipeline normalisation du référentiel de seuils
    dplyr::rename_with(~ tolower(gsub(" ", "_", .x))) %>%                       # Standardise noms colonnes : minuscules + underscores
    dplyr::mutate(                                                              # Casts et colonnes de matching
      vigilance        = as.numeric(vigilance),                                 # Cast seuil vigilance en numérique
      alerte           = as.numeric(alerte),                                    # Cast seuil alerte en numérique
      alerte_renforcee = as.numeric(alerte_renforcee),                          # Cast seuil alerte renforcée en numérique
      crise            = as.numeric(crise),                                     # Cast seuil crise en numérique
      stations_clean   = stringi::stri_trans_general(
                                       trimws(stations),
                                       "Latin-ASCII") %>%
                         toupper(),                                             # Normalise station (ASCII + uppercase)
      codes_clean      = stringi::stri_trans_general(
                                       trimws(code_stations),
                                       "Latin-ASCII") %>%
                         toupper()                                              # Normalise code station (ASCII + uppercase)
    )                                                                           # Fin mutate seuils normalisés

  nom_station <- stringi::stri_trans_general(
                               trimws(Stations),
                               "Latin-ASCII") %>%
                 toupper()                                                      # Normalise station observée pour matching robuste

  seuils_match <- seuils %>%                                                    # Recherche du seuil applicable à (date, station)
    dplyr::filter(                                                              # Filtre sur date et station/codestation
      date_seuil_ref == date_obs_ref &                                          # Match exact date de seuil (référentiel)
      (stations_clean == nom_station | codes_clean == nom_station)              # Match station par libellé ou code
    )                                                                           # Fin filter seuils_match

  if (nrow(seuils_match) == 0) return("#FFFFFF")                                # Aucun seuil trouvé : blanc (évite faux signal)
  seuil <- seuils_match[1, ]                                                    # Prend la première ligne si doublons (déterminisme)

  return(                                                                       # Retour couleur selon hiérarchie des seuils (plus critique en premier)
    dplyr::case_when(                                                           # Classification couleur
      is.na(val)                   ~ "#FFFFFF",                                 # Sécurité : si NA malgré tout
      val <= seuil$crise           ~ "#ad0021",                                 # ≤ crise -> rouge foncé
      val <= seuil$alerte_renforcee ~ "#ff4a29",                                # ≤ alerte renforcée -> rouge/orange fort
      val <= seuil$alerte          ~ "#ffb542",                                 # ≤ alerte -> orange
      val <= seuil$vigilance       ~ "#f7efa5",                                 # ≤ vigilance -> jaune pâle
      val > seuil$vigilance        ~ "#e6efff",                                 # > vigilance -> bleu clair (normal)
      TRUE                         ~ "#FFFFFF"                                  # Fallback (ne devrait pas arriver)
    )                                                                           # Fin case_when
  )                                                                             # Fin return couleur
}                                                                               # Fin fonction couleur_seuil


# ──────────────────────────────────────────────────────────────────────────────
# FONCTION : generer_bloc_secteur()
# ------------------------------------------------------------------------------
# Génère les blocs sectorisés avec colonnes adaptées
# ──────────────────────────────────────────────────────────────────────────────
generer_bloc_secteur <- function(donnees, seuils_hydro, seuils_piezo, restrictions) {

  # ---- Nettoyage initial des données -----------------------------------------
  donnees <- donnees %>%                                                        # Pipeline sur données brutes bulletin
    dplyr::filter(!(is.na(Mode_de_gestion) & is.na(Stations) & is.na(Mesures))) %>% # Exclut lignes vides (évite tableaux inutiles)
    dplyr::mutate(                                                              # Normalise colonnes clés de jointure + stations
      bassins_versants = stringr::str_squish(
                                  stringr::str_to_lower(bassins_versants)),     # Normalise BV (lower + trim) pour jointure stable
      type_d_eau       = stringr::str_squish(
                                  stringr::str_to_lower(type_d_eau)),           # Normalise type d'eau (lower + trim) pour jointure stable
      Stations         = sapply(Stations, nettoyer_nom_station)                 # Applique nettoyage station (évite coupures/artefacts)
    ) %>%                                                                       # Fin mutate
    dplyr::left_join(                                                           # Ajout des restrictions (état/perspective/couleurs)
      restrictions %>%                                                          # Table restrictions (référentiel)
        dplyr::mutate(
          dplyr::across(
            c(bassins_versants, type_d_eau),
              ~ stringr::str_squish(
                         stringr::str_to_lower(.)))),                           # Normalise clés côté restrictions
      by = c("bassins_versants", "type_d_eau")                                  # Jointure sur BV + type d'eau (contrat métier)
    ) %>%                                                                       # Fin left_join
    dplyr::mutate(                                                              # Remplissage des valeurs manquantes (robustesse)
      restriction_txt = dplyr::if_else(
                                  is.na(restriction_txt),
                                  "Non communiqué",
                                  restriction_txt
                                  ),                                            # Libellé restriction par défaut
      couleur_restriction = dplyr::if_else(
                                      is.na(couleur_restriction),
                                      "#FFFFFF",
                                      couleur_restriction
                                      ),                                        # Couleur restriction par défaut
      perspectives_txt   = dplyr::if_else(
                                     is.na(perspectives_txt),
                                     "Non communiqué",
                                     perspectives_txt
                                     ),                                         # Libellé perspective par défaut
      couleur_perspective = dplyr::if_else(
                                      is.na(couleur_perspective),
                                      "#FFFFFF",
                                      couleur_perspective
                                      ),                                        # Couleur perspective par défaut
      Date_obs = dplyr::case_when(                                              # Normalisation de Date_obs vers un format ISO YYYY-MM-DD
        nchar(Date_obs) == 2 ~ paste0(format(Sys.Date(), "%Y"), "-", Date_obs, "-01"), # Cas "MM" -> YYYY-MM-01 (mois seul)
        nchar(Date_obs) == 5 ~ paste0(format(Sys.Date(), "%Y"), "-", Date_obs), # Cas "MM-DD" -> YYYY-MM-DD (année courante)
        grepl("^\\d{1,2}-[a-zA-Zéèêàâôûîç]+$", Date_obs) ~ {                    # Cas "15-août" (jour + mois texte)
          jour <- stringr::str_extract(Date_obs, "^\\d{1,2}")                   # Extrait le jour (1 ou 2 chiffres)
          mois <- stringr::str_extract(Date_obs, "[a-zA-Zéèêàâôûîç]+$")         # Extrait le mois en toutes lettres (avec accents)
          mois_num <- dplyr::recode(                                            # Conversion mois texte -> mois numérique (2 chiffres)
            stringr::str_to_lower(mois),                                        # Normalise en minuscule
            "janvier" = "01",
            "février" = "02",
            "fevrier" = "02",
            "mars" = "03",
            "avril" = "04",
            "mai" = "05",
            "juin" = "06",
            "juillet" = "07",
            "août" = "08",
            "aout" = "08",
            "septembre" = "09",
            "octobre" = "10",
            "novembre" = "11",
            "décembre" = "12",
            "decembre" = "12"
          )                                                                     # Fin recode mois_num
          paste0(
            format(Sys.Date(), "%Y"),
            "-",
            mois_num,
            "-",
            stringr::str_pad(jour, 2, pad = "0"))                               # Construit date ISO année courante
        },                                                                      # Fin cas jour-mois texte
        TRUE ~ Date_obs                                                         # Sinon : conserve tel quel (supposé déjà ISO)
      )                                                                         # Fin case_when Date_obs
    )                                                                           # Fin mutate Date_obs

  # ---- Barre de progression pour attribution des couleurs --------------------
  pb <- progress::progress_bar$new(                                             # Initialise progress bar
    format = "  Attribution des couleurs [:bar] :percent",                      # Format affiché
    total = nrow(donnees), clear = FALSE, width = 60                            # Total = nb lignes ; width = largeur barre
  )                                                                             # Fin progress_bar$new

  donnees$couleur_mesure <- purrr::pmap_chr(                                    # Calcul couleur (seuil) ligne par ligne (chr)
    list(                                                                       # Liste des colonnes passées à la fonction
      donnees$Mode_de_gestion %||% NA_character_,                               # Mode (Débits/Nappes) ; fallback NA
      donnees$Stations %||% NA_character_,                                      # Station ; fallback NA
      donnees$Date_obs %||% NA_character_,                                      # Date observation ; fallback NA
      donnees$Mesures %||% NA_character_                                        # Valeur mesure ; fallback NA
    ),                                                                          # Fin list arguments pmap
    function(mode, station, date, mesure) {                                     # Fonction appelée pour chaque ligne
      pb$tick()                                                                 # Incrémente barre de progression
      couleur_seuil(mode, station, date, mesure, seuils_hydro, seuils_piezo)    # Calcule couleur selon seuils + contexte
    }                                                                           # Fin fonction pmap
  )                                                                             # Fin pmap_chr

  # ---- Génération des tableaux par secteur -----------------------------------
  tableaux   <- list()                                                          # Liste de sortie (chaque bloc = list(texte, tableau))
  format_kbl <- if (knitr::is_latex_output()) "latex" else "html"               # Choix format tableau selon sortie knitr

  for (secteur in unique(donnees$bassins_versants)) {                           # Boucle sur chaque bassin versant
    sous_bv <- dplyr::filter(donnees, bassins_versants == secteur)              # Sous-ensemble données pour ce BV

    for (type_eau in unique(sous_bv$type_d_eau)) {                              # Boucle sur chaque type d'eau au sein du BV
      sous_type <- dplyr::filter(sous_bv, type_d_eau == type_eau)               # Sous-ensemble BV + type d'eau
      if (nrow(sous_type) == 0) next                                            # Sécurité : rien à faire si vide

      # ---- Construction du dataframe du bloc ----------------------------------
      df_bloc <- sous_type %>%                                                  # Pipeline pour construire df_bloc
        dplyr::transmute(                                                       # Sélection/renommage colonnes de sortie
          Mode_de_gestion,                                                      # Mode de gestion (Débits/Nappes)
          Stations,                                                             # Station (nettoyée plus haut)
          Mesure = Mesures,                                                     # Renomme Mesures -> Mesure (affichage)
          couleur_mesure,                                                       # Couleur associée à la mesure (seuil)
          Restriction = restriction_txt,                                        # Libellé restriction (référentiel)
          couleur_restriction,                                                  # Couleur restriction
          Perspective = perspectives_txt,                                       # Libellé perspective
          couleur_perspective                                                   # Couleur perspective
        ) %>%                                                                   # Fin transmute
        dplyr::mutate(
          dplyr::across(
            dplyr::starts_with("couleur_"),
            ~ if_else(is.na(.), "#FFFFFF", .))) %>%                             # Sécurise couleurs manquantes -> blanc
        dplyr::mutate(est_titre = FALSE)                                        # Colonne potentielle (non utilisée ici) : marqueur de titre

      # ---- Format latex -------------------------------------------------------
      if (format_kbl == "latex") {

        # Largeurs de colonnes adaptées (total = 17cm)
        # Mode: 2cm | Station: 5cm | Mesure: 2.5cm | Restriction: 3.5cm | Perspective: 4cm
        kbl_bloc <- knitr::kable(                                               # Génère table LaTeX de base
          df_bloc %>%
            dplyr::select(
              Mode_de_gestion,
              Stations,
              Mesure,
              Restriction,
              Perspective
            ),                                                                  # Colonnes affichées (sans couleurs internes)
            format    = "latex",                                                # Format LaTeX
            booktabs  = TRUE,                                                   # Style booktabs (lignes propres)
            longtable = TRUE,                                                   # Table multipage si nécessaire
            escape    = FALSE,                                                  # Laisse passer contenu déjà échappé/HTML/LaTeX
            row.names = FALSE,                                                  # Pas de colonne rownames
            col.names = c(
              "Mode de gestion",
              "Station",
              "Mesure",
              "Restriction",
              "Perspective"
            ),                                                                  # En-têtes affichés
            align     = c(
              "l",
              "l",
              "c",
              "c",
              "c"
            )                                                                   # Alignement colonnes (texte/général)
        ) %>%                                                                   # Fin kable
          kableExtra::kable_styling(                                            # Options globales de style
            full_width    = FALSE,                                              # Ne pas étirer pleine page
            position      = "center",                                           # Centrage
            latex_options = c(
              "hold_position",
              "striped",
              "repeat_header",
              "scale_down"
            ),                                                                  # Options : placement/stripes/repeat/scale
            font_size     = 9                                                   # Police petite pour densité
          ) %>%                                                                 # Fin styling
          kableExtra::column_spec(
            1,
            width = "3.97cm"
          ) %>%                                                                 # Largeur col 1 (mode) en cm
          kableExtra::column_spec(
            2,
            width = "8.57cm"
          ) %>%                                                                 # Largeur col 2 (station) en cm
          kableExtra::column_spec(
            3,
            width = "3.97cm",
            background = df_bloc$couleur_mesure
          ) %>%                                                                 # Col 3 (mesure) + fond couleur seuil
          kableExtra::column_spec(
            4,
            width = "5.29cm",
            background = df_bloc$couleur_restriction
          ) %>%                                                                 # Col 4 (restriction) + fond couleur
          kableExtra::column_spec(
            5,
            width = "5.29cm",
            background = df_bloc$couleur_perspective
          ) %>%                                                                 # Col 5 (perspective) + fond couleur
          kableExtra::collapse_rows(
            columns = 1:2,
            valign = "middle"
          )                                                                     # Fusion des cellules identiques (mode+station)

        # En-tête du bloc (largeur = 17cm)
        bloc_header <- glue::glue(                                              # Construit header LaTeX (encadré)
          "\\begin{{center}}",                                                  # Centre le bloc titre
          "\\fcolorbox{{black}}{{gray!20}}{{\\parbox{{17cm}}{{",                # Cadre noir + fond gris + boîte 17cm
          "\\small \\textbf{{\\textsc{{{echapper_format(stringr::str_to_upper(secteur))}}}}} \\\\ ", # Ligne 1 : BV en majuscules
          "\\textsc{{{echapper_format(stringr::str_to_upper(type_eau))}}}",     # Ligne 2 : type d'eau en majuscules
          "}}}}",                                                               # Fermetures parbox/fcolorbox
          "\\end{{center}}"                                                     # Fin centrage
        )                                                                       # Fin glue bloc_header

        tableaux[[length(tableaux) + 1]] <- list(texte = bloc_header, tableau = kbl_bloc) # Stocke le bloc (header + tableau) dans la liste

        # ---- Format html ------------------------------------------------------
      } else if (format_kbl == "html") {                                        # Branche HTML

        kbl_bloc <- knitr::kable(                                               # Génère table HTML de base
          df_bloc %>% dplyr::select(
            Mode_de_gestion,
            Stations,
            Mesure,
            Restriction,
            Perspective
          ),                                                                    # Colonnes affichées
          format    = "html",                                                   # Format HTML
          escape    = FALSE,                                                    # Permet insertion HTML (span, etc.) si présent
          row.names = FALSE,                                                    # Pas de rownames
          col.names = c(
            "Mode de gestion",
            "Station",
            "Mesure",
            "Restriction",
            "Perspective"
          ),                                                                    # En-têtes affichés
          align     = "l"                                                       # Alignement global (CSS bootstrap gère le reste)
        ) %>%                                                                   # Fin kable HTML
          kableExtra::kable_styling(                                            # Style bootstrap
            bootstrap_options = c(
              "striped",
              "hover",
              "condensed",
              "bordered"
            ),                                                                  # Options bootstrap : zebra/hover/condensé/bordures
            full_width        = FALSE,                                          # Ne pas étirer 100%
            position          = "center",                                       # Centrage
            font_size         = 10                                              # Taille police
          ) %>%                                                                 # Fin styling HTML
          kableExtra::column_spec(
            1,
            width = "150px"
          ) %>%                                                                 # Largeur col 1 (mode) en px
          kableExtra::column_spec(
            2,
            width = "324px"
          ) %>%                                                                 # Largeur col 2 (station) en px
          kableExtra::column_spec(
            3, width = "150px",
            background = df_bloc$couleur_mesure
          ) %>%                                                                 # Col 3 + fond couleur seuil
          kableExtra::column_spec(
            4,
            width = "200px",
            background = df_bloc$couleur_restriction
          ) %>%                                                                 # Col 4 + fond restriction
          kableExtra::column_spec(
            5,
            width = "200px",
            background = df_bloc$couleur_perspective
          ) %>%                                                                 # Col 5 + fond perspective
          kableExtra::collapse_rows(
            columns = 4:5,
            valign = "middle"
          )                                                                     # Fusion des cellules (restriction/perspective) si identiques

        bloc_complet <- glue::glue(                                                        # Construit un bloc HTML complet (titre + tableau)
          "<div style='width: 1024px; margin: 10px auto;'>",                               # Conteneur largeur fixe (alignement stable)
          "<div style='border:1px solid black; padding:6px; font-weight:bold; ",           # Style bandeau titre (bord + padding + gras)
          "background-color:#f0f0f0; text-align:center; margin-bottom:4px;'>",             # Fond gris + centré + marge
          "<span style='text-transform:uppercase'>{echapper_format(secteur)}</span><br/>", # Ligne 1 : BV uppercase
          "<span style='text-transform:uppercase'>{echapper_format(type_eau)}</span>",     # Ligne 2 : type d'eau uppercase
          "</div>",                                                                        # Fin bandeau titre
          "{kbl_bloc}",                                                                    # Injection tableau HTML
          "</div>"                                                                         # Fin conteneur
        )                                                                       # Fin glue bloc_complet

        tableaux[[length(tableaux) + 1]] <- list(texte = bloc_complet, tableau = kbl_bloc) # Stocke le bloc HTML dans la liste
      }                                                                         # Fin if format (latex/html)
    }                                                                           # Fin boucle type_d_eau
  }                                                                             # Fin boucle secteur (BV)

  return(tableaux)                                                              # Retourne la liste des blocs prêts à être imprimés (Rmd)
}                                                                               # Fin fonction generer_bloc_secteur
