# ------------------------------------------------------------------------------
# SCRIPT 07_create_graphique.R : GENERATION AUTOMATIQUE DES GRAPHIQUES
# ------------------------------------------------------------------------------
# Auteur       : MJMartinat
#                Adapté à partir du code de Neil Guion et de la DDT38
# Structure    : DDT de la Drôme
# Date         : 2025
# ------------------------------------------------------------------------------
# DESCRIPTION  : Génération des chroniques et graphiques pour le suivi
#                sécheresse (données HYDRO + ADES)
#                - Téléchargement données HUBEAU
#                - Calcul niveaux de gravité
#                - Export PDF graphiques par station
#                - Export Excel tableau synthèse
# VERSION      : 1.0
# DÉPENDANCES  : here, lubridate, dplyr, zoo, plyr, openxlsx, png, grid
# ------------------------------------------------------------------------------
# Configuration locale et chargement des packages
# ------------------------------------------------------------------------------
Sys.setlocale("LC_TIME", "fr_FR.UTF-8")                                         # Locale française dates

library(here)                                                                   # Chemins relatifs projet
library(lubridate)                                                              # Manipulation dates
library(dplyr)                                                                  # Manipulation données
library(zoo)                                                                    # Séries temporelles
library(plyr)                                                                   # Split-apply-combine
library(openxlsx)                                                               # Export Excel
library(png)                                                                    # Lecture images PNG
library(grid)                                                                   # Graphiques bas niveau
library(sf)                                                                     # Package spatial moderne basé sur le standard OGC "Simple Features".
library(ggplot2)                                                                # Moteur de visualisation basé sur la "Grammar of Graphics".

# ------------------------------------------------------------------------------
# Paramétrages générals
# ------------------------------------------------------------------------------
# ---- Répertoires -------------------------------------------------------------
wd_out <- here::here("sorties", "graphique")                                    # Répertoire sorties

# ---- Options -----------------------------------------------------------------
react <- TRUE                                                                   # TRUE = réactualiser données
juste_derniere_obs <- FALSE                                                     # FALSE = tableau 6 mois
add_mod_nappe <- FALSE                                                          # Ajout évolutions nappe
wd_chro_completes <- here::here(
  "graphique",
  "sorties",
  "Chroniques_completes",
  "RETEX_2023"
)                                                                               # Chroniques complètes
page_de_garde <- TRUE                                                           # Ajout page de garde PDF
add.carto <- FALSE                                                              # Ajout carte UG stations

# ---- Paramètres code ---------------------------------------------------------
aujourdhui <- Sys.Date()                                                        # Date du jour
dep <- 26                                                                       # Code département Drôme
numero_annee_bsh <- as.numeric(format(aujourdhui, "%Y")) - 1                    # Année BSH (n-1)
annee <- as.numeric(format(aujourdhui, "%Y"))                                   # Année courante
numero_mois_bsh <- as.numeric(format(aujourdhui, "%m"))                         # Mois du BSH
numero_quinzaine_bsh <- 1                                                       # Numéro quinzaine

jours_dans_mois <- lubridate::days_in_month(                                    # Nb jours dans mois
  lubridate::ymd(                                                               # Conversion date
    paste(                                                                      # Concaténation
      numero_annee_bsh,                                                         # Année
      numero_mois_bsh, "15"                                                     # Mois + jour 15
))) %>%
as.numeric()                                                                    # Conversion numérique

date_debut <- lubridate::ymd(                                                   # Date début période
  paste(                                                                        # Concaténation
    numero_annee_bsh,                                                           # Année BSH
    1,                                                                          # Mois janvier
    1,                                                                          # Jour 1
    sep = "-"                                                                   # Séparateur
))

source(here::here(
  "R",
  "import_donnees_graph.R"
  ), encoding = "UTF-8")                                                        # Chargement HUBEAU

jdm <- lubridate::days_in_month(                                                # Jours par mois
  lubridate::ymd(                                                               # Conversion date
    paste(                                                                      # Concaténation
      numero_annee_bsh,                                                         # Année
      1:12,                                                                     # Mois 1 à 12
      "15"                                                                      # Jour 15
)))

names(jdm) <- c("Jan",                                                          # Janvier
                "Fév",                                                          # Février
                "Mars",                                                         # Mars
                "Avr",                                                          # Avril
                "Mai",                                                          # Mai
                "Juin",                                                         # Juin
                "Juil",                                                         # Juillet
                "Août",                                                         # Août
                "Sept",                                                         # Septembre
                "Oct",                                                          # Octobre
                "Nov",                                                          # Novembre
                "Déc"                                                           # Décembre
                )

# ---- Paramètres sécheresse ---------------------------------------------------
coul_grav <- c(                                                                 # Couleurs par niveau
  "Hors vigilance" = "green3",                                                  # Vert
  "Vigilance" = "yellow",                                                       # Jaune
  "Alerte" = "orange",                                                          # Orange
  "Alerte renforcée" = "red",                                                   # Rouge
  "Crise" = "darkorchid4"                                                       # Violet foncé
)

coul_tend <- c(
  "↓" = "tomato",
  "↑" = "olivedrab2",
  "~" = "yellow")                                                               # Couleurs tendances

nom_AP <- c(AC_Drome = "Drôme\nN°26-2023-04-07-00012")                          # Nom arrêté préfectoral

nJtendan <- 10                                                                  # Nb jours tendance


# ------------------------------------------------------------------------------
# Fonction id_grav - Calcul de niveau de gravité
# ------------------------------------------------------------------------------
id_grav <- function(x, S, l) {                                                  # Fonction calcul gravité

  x <- x[order(x[, l["date"]]), ]                                               # Tri par date
  x$j <- as.numeric(format(as.Date(x[, l['date']]), "%j"))                      # Jour julien
  x$grav_sug <- 0                                                               # Init gravité suggérée
  x$grav <- 0                                                                   # Init gravité finale

  if (nrow(S) == 0 || ncol(S) < 4) {                                            # Si seuils invalides
    return(x)                                                                   # Retour données brutes
  }

  for (i in 10:nrow(x)) {                                                       # Boucle à partir jour 10

    idx_jours <- x[(i - 10):i, "j"]                                             # Indices fenêtre glissante

    idx_valides <- idx_jours[idx_jours >= 1 & idx_jours <= nrow(S)]             # Indices valides

    if (length(idx_valides) < 7) {                                              # Si moins de 7 valides
      x$grav[i] <- x$grav[i - 1]                                                # Garder gravité précédente
      x$grav_sug[i] <- 0                                                        # Gravité suggérée = 0
      next                                                                      # Passer à suivant
    }

    diff_s <- x[(i - 10):i, l['mes']] - S[idx_jours, 1:4]                       # Diff mesures vs seuils

    if (all(is.na(diff_s))) {                                                   # Si tout NA
      x$grav[i] <- x$grav[i - 1]                                                # Garder gravité précédente
      x$grav_sug[i] <- 0                                                        # Gravité suggérée = 0
      next                                                                      # Passer à suivant
    }

    tail_diff <- tail(diff_s, 7)                                                # 7 derniers jours
    depassements <- colSums(tail_diff <= 0, na.rm = TRUE) >= 5                  # >= 5 dépassements

    grav_i <- tail(which(depassements), 1)                                      # Dernier niveau dépassé
    grav_i <- ifelse(length(grav_i) > 0, grav_i, 0)                             # 0 si aucun

    grav_precedent <- x$grav[i - 1]                                             # Gravité jour précédent
    if (is.na(grav_precedent)) grav_precedent <- 0                              # 0 si NA

    if (grav_i >= grav_precedent) {                                             # Si aggravation
      x$grav[i] <- grav_i                                                       # Nouveau niveau
    } else {                                                                    # Sinon
      if (grav_precedent > 0 && grav_precedent <= ncol(diff_s)) {               # Si niveau valide
        col_check <- diff_s[, grav_precedent]                                   # Colonne à vérifier
        if (all(is.na(col_check))) {                                            # Si tout NA
          x$grav[i] <- grav_precedent                                           # Garder niveau
        } else if (all(col_check >= 0, na.rm = TRUE)) {                         # Si tous au-dessus
          x$grav[i] <- grav_precedent - 1                                       # Descendre d'un niveau
        } else {                                                                # Sinon
          x$grav[i] <- grav_precedent                                           # Garder niveau
        }
      } else {                                                                  # Sinon
        x$grav[i] <- grav_precedent                                             # Garder niveau
      }
    }

    x$grav_sug[i] <- grav_i                                                     # Enregistrer suggéré
  }

  x                                                                             # Retour dataframe
}


# ------------------------------------------------------------------------------
# Configuration labels par type de suivi
# ------------------------------------------------------------------------------
labs <- list(                                                                   # Labels par suivi
  hydro = c(
    mes = "resultat_obs_elab",
    date = "date_obs_elab",
    sta = "code_station"
  ),                                                                            # HYDRO
  ades = c(
    mes = "niveau_nappe_eau",
    date = "date_mesure",
    sta = "code_bss"
  )                                                                             # ADES
)


# ------------------------------------------------------------------------------
# Téléchargement données hydro/ades années N et N-1
# ------------------------------------------------------------------------------
telech <- lapply(names(labs), function(suivi) {                                 # Boucle sur suivis

  files_AC <- list.files(                                                       # Liste fichiers stations
    here::here(
      "donnees",
      "graphique",
      "origines",
      paste0("stations_", suivi)
    ),                                                                          # Répertoire
    full.names = TRUE,                                                          # Chemins complets
    pattern = suivi                                                             # Pattern fichier
  )

  if (suivi == "ades" | suivi == "hydro") {                                     # Si ADES ou HYDRO
    files_AC <- files_AC[1]                                                     # Premier fichier seulement
  }

  ordre_sta <- lapply(files_AC, function(x) {
    x <- read.table(x,sep = ",", header = TRUE, quote = "\"")                   # Lecture CSV
    x[x$integrer == "O", "code_entite"]                                         # Stations à intégrer
  })

  if (suivi == "hydro") names(ordre_sta) <- sub("_hydro.csv", "", basename(files_AC)) # Noms HYDRO
  if (suivi == "ades") names(ordre_sta) <- sub("_ades.csv", "", basename(files_AC))   # Noms ADES

  der_telech <- tail(
    sort(
      dir(
        here::here(
          "sorties",
          "graphique",
          "donnees"
        ),
      full.names = TRUE,
      pattern = suivi)),
  1)                                                                            # Dernier téléchargement

  tmp <- if (length(der_telech) > 0) {                                          # Si fichier existe
    date_str <- sapply(strsplit(basename(der_telech),"_",fixed = TRUE),
      "[", 2)                                                                   # Extraction date
    date_fichier <- tryCatch(                                                   # Conversion date
      as.Date(date_str, format = "%Y-%m-%d"),                                   # Format ISO
      error = function(e) NA                                                    # NA si erreur
    )
    if (is.na(date_fichier)) {                                                  # Si date invalide
      15                                                                        # Forcer rechargement
    } else {                                                                    # Sinon
      as.numeric(difftime(aujourdhui, date_fichier, units = "days"))            # Nb jours depuis
    }
  } else {                                                                      # Sinon
    15                                                                          # Forcer rechargement
  }

  if (tmp > 7 | react) {                                                        # Si > 7 jours ou react
    AP <- lapply(files_AC, hubO, date_debut = date_debut, ori = suivi)          # Téléchargement HUBEAU
    names(AP) <- sub(paste("_", suivi, ".csv", sep = ""), "", basename(files_AC)) # Noms AC
    if (suivi == "hydro") AP <- lapply(AP, function(x) split(x, x$code_station)) # Split par station
    for (l in names(AP)) AP[[l]] <- AP[[l]][intersect(ordre_sta[[l]], names(AP[[l]]))] # Filtrage
    save(AP, file = here::here("sorties", "graphique", "donnees", paste0("Donnees_", aujourdhui, "_", suivi, ".Rdata"))) # Sauvegarde
  } else {                                                                      # Sinon
    load(der_telech)                                                            # Chargement existant
    warning(paste(
      "Attention, les donnees utilisées datent de", tmp, "jours\n", # Avertissement
      "pour télécharger les données récentes définir 'react = T' en haut du script"))
  }

  infos_sta <- lapply(
    files_AC,
    read.table,
    h = TRUE,
    as.is = TRUE,
    sep = ",",
    dec = ",",
    quote = "\"",
    encoding = "UTF-8"
  )                                                                             # Infos stations

  names(infos_sta) <- sub(
    paste(
      "_",
      suivi,
      ".csv",
      sep = ""),
    "",
    basename(files_AC)
  )                                                                             # Noms

  list(a = AP, b = infos_sta)                                                   # Retour liste
})

names(telech) <- names(labs)                                                    # Noms suivis


# ------------------------------------------------------------------------------
# Génération des graphiques pdf
# ------------------------------------------------------------------------------
# ---- Lecture des données spatiales ---------------------------------------
UG <- sf::st_read(
  here::here(
    "donnees",
    "graphique",
    "origines",
    "sig",
    "UG_ESU",
    "ESU_84_Dept26_2023.shp"
))

donnees <- lapply(names(labs), function(suivi) {                                # Boucle sur suivis

  AP <- telech[[suivi]]$a                                                       # Données téléchargées
  infos_sta <- telech[[suivi]]$b                                                # Infos stations

  # ---- Chargement des seuils -------------------------------------------------
  tmp <- list.files(                                                            # Liste fichiers seuils
    here::here(
      "donnees",
      "graphique",
      "origines",
      paste0("stations_", suivi),
      "seuils"
    ),                                                                          # Répertoire
    full.names = TRUE                                                           # Chemins complets
  )
  seuils <- lapply(
    tmp,
    read.table,
    h = TRUE,
    as.is = TRUE,
    sep = ",",
    dec = ","
  )                                                                             # Lecture seuils

  names(seuils) <- sub(".csv", "", basename(tmp))                               # Noms stations
  seuils <- seuils[sapply(seuils, nrow) > 0]                                    # Filtrer non vides

  if (suivi == "hydro") seuils <- lapply(seuils, "*", 1000)                     # Conversion L/s

  if (suivi == "ades") {                                                        # Si ADES
    tmp <- unlist(lapply(AP, names))                                            # Noms stations
    a <- sapply(strsplit(tmp, "/", fixed = TRUE), "[", 1)                       # Code BSS simple
    names(a) <- tmp                                                             # Noms complets
    tmp <- names(seuils)                                                        # Noms seuils
    for (i in 1:length(a)) names(seuils)[names(seuils) == a[i]] <- names(a)[i]  # Renommage
  }

  # ---- Génération PDF des graphes --------------------------------------------
  tmp <- names(AP)                                                              # Noms AC
  names(tmp) <- tmp                                                             # Auto-nommage

  datGrav <- lapply(tmp, function(lab_AP) {                                     # Boucle sur AC

    stations <- AP[[lab_AP]]                                                    # Stations de l'AC
    sta_AP <- infos_sta[[lab_AP]]                                               # Infos stations AC

    grDevices::pdf(
      here::here(
        "sorties",
        "graphique",
        "pdf",
        paste0("suivis_", toupper(suivi), ifelse(add_mod_nappe & suivi == "ades", "_&proj", ""), "_", lab_AP, ".pdf")
      ),                                                                        # Chemin fichier
      height = 7.07,                                                            # Hauteur pouces
      width = 10,                                                               # Largeur pouces
      useDingbats = FALSE                                                       # Pas de Dingbats
    )

    if (page_de_garde) {                                                        # Si page de garde
      logo <- png::readPNG(
        here::here(
          "fichiers",
          "images",
          "logo_prefete.png"
        ))                                                                      # Lecture logo
      plot(
        c(0, 1),
        c(0, 1),
        type = "n",
        bty = "n",
        axes = FALSE,
        xlab = "",
        ylab = ""
      )                                                                         # Plot vide

      text(
        0.5,
        0.95,
        paste("Synthèse Ressource",
              ifelse(suivi == "hydro",
                     "ESU",
                     "ESO")),
        adj = 0.5)                                                              # Titre

      text(
        1,
        0.87,
        paste("Direction départementale des territoires",
              "\n",
              "Service Eau Forêt Espaces Naturels"),
        font = 2,
        adj = 1
      )                                                                         # Service

      text(
        0.5,
        0.62,
        paste("Stations de suivi des arrêtés cadre :\n
              Galaure-Drôme des Collines(Drôme-Isère)\n
              Drôme", "\n"),
        adj = 0.5,
        font = 2
      )                                                                         # AC

      text(
        0.5,
        0.39,
        paste("État des ressources suivies par",                                # Texte état
              ifelse(suivi == "hydro",
                              "station débimétrique",
                              "piézomètre"
              ),
              "\n",                                                             # Type
              format(aujourdhui, "%d %b %Y")
         ),                                  # Date
         adj = 0.5,
         font = 2
      )                                                                         # Style gras

      text(
        0,
        0.12,
        paste("État de la ressource par zone d'alerte\n",                                                                     # Explication
              "Les niveaux ", ifelse(suivi == "hydro", "débimétriques", "piézomètriques"), " sont présentés ",                # Type mesure
              "sur un graphique annuel représentant les années ", annee - 1, " et ", annee, "\n",                             # Années
              "Les seuils sécheresse sont représenté (quand ceux-ci sont disponibles) et un niveau de gestion est suggéré\n", # Seuils
              "au regard des conditions de franchissement définies dans l'Arrêté Cadre.\n\n",                                 # Conditions
              sep = ""),
        adj = 0
      )                                                                         # Alignement gauche

      grid::grid.raster(
        logo,
        x = .1,
        y = .8,
        width = .25,
        just = "left"
      )                                                                         # Affichage logo
    }

    tmp <- names(stations)                                                      # Noms stations
    names(tmp) <- tmp                                                           # Auto-nommage

    tabGravTot <- lapply(tmp, function(j) {                                     # Boucle sur stations

      station <- stations[[j]]                                                  # Données station

      if (any(names(seuils) == j)) {                                            # Si seuils existent
        seuils_sta <- seuils[[j]]                                               # Seuils station
        seuils_sta$j <- 1:nrow(seuils_sta)                                      # Index jour
      } else {                                                                  # Sinon
        if (any(ls() == "seuils_sta")) rm(seuils_sta)                           # Supprimer si existe
      }

      nom_sta <- unique(sta_AP$Station[sta_AP$code_entite == j])                # Nom station

      station[, labs[[suivi]]["date"]] <- as.Date(station[, labs[[suivi]]["date"]]) # Conversion date
      station$Y <- as.numeric(format(station[, labs[[suivi]]['date']], "%Y"))   # Année
      station$j <- as.numeric(format(station[, labs[[suivi]]['date']], "%j"))   # Jour julien

      if (any(ls() == "seuils_sta")) {                                          # Si seuils existent
        tabGrav <- id_grav(station, l = labs[[suivi]], S = seuils_sta)          # Calcul gravité
        grav <- names(coul_grav)[tail(tabGrav$grav, 1) + 1]                     # Dernier niveau
      } else {                                                                  # Sinon
        tabGrav <- station                                                      # Données brutes
        grav <- NULL                                                            # Pas de niveau
      }

      cGravSta <- coul_grav[grav]                                               # Couleur niveau

      tmp <- lm(tail(station[, c("j", labs[[suivi]]['mes'])], nJtendan))        # Régression tendance
      tmp <- coef(summary(tmp))                                                 # Coefficients
      if (nrow(tmp) > 1) {                                                      # Si coefficients
        tendance <- sign(tmp[2, 1]) * (tmp[2, 4] <= 0.05)                       # Signe si signif
        tendance <- if (tendance < 0) "baisse"
                    else if (tendance > 0) "hausse"
                    else "incertain" # Texte
      } else {                                                                  # Sinon
        tendance <- "stable"                                                    # Stable
      }

      nder <- 60                                                                # Nb jours zoom
      periode <- list(                                                          # Périodes graphes
        tot = station[, labs[[suivi]]['date']],                                 # Période totale
        der = tail(station[, labs[[suivi]]['date']], nder)                      # Derniers jours
      )

      if (!add.carto) graphics::layout(
        matrix(1:2, nrow = 1),
        widths = c(0.65, 0.35)
      )                                                                         # Layout 2 graphes
      if (add.carto) graphics::layout(
        matrix(
          c(1, 1, 1, 3, 1, 1, 1, 2, 1, 1, 1, 2),
          nrow = 3,
          byrow = TRUE),
          widths = c(0.65, 0.35)
        )                                                                       # Layout 3 graphes
      par(mar = c(5, 4.2, 5, 1), cex = 1)                                       # Marges

      for (p in names(periode)) {                                               # Boucle périodes

        X <- station[station[, labs[[suivi]]['date']] %in% periode[[p]], ]      # Données période
        X[, labs[[suivi]]['date']] <- as.Date(X[, labs[[suivi]]['date']])       # Conversion date

        if (p == "der" & any(diff(X$j) < 1)) {                                  # Si changement année
          tmp <- which(X$j == 1)                                                # Index 1er janvier
          X$jr <- X$j                                                           # Copie jour
          X$jr[1:(tmp - 1)] <- -(tmp - 2):0                                     # Jours négatifs
        } else {                                                                # Sinon
          X$jr <- X$j                                                           # Jour = jour julien
        }

        if (any(ls() == "seuils_sta")) {                                        # Si seuils existent
          rg <- range(seuils_sta[X$j, 1:4])                                     # Range seuils
        } else {                                                                # Sinon
          rg <- range(X[, labs[[suivi]]['mes']])                                # Range mesures
        }

        rg <- range(c(rg, X[, labs[[suivi]]['mes']]))                           # Range combiné
        if (p == "tot") rg[2] <- rg[2] + 0.08 * diff(rg)                        # Marge haute

        maStation <- station[1, ]                                               # Station courante

        rg_num <- rg                                                            # Range numérique
        rg_min <- suppressWarnings(min(rg_num, na.rm = TRUE))                   # Min sécurisé
        rg_max <- suppressWarnings(max(rg_num, na.rm = TRUE))                   # Max sécurisé

        if (!is.finite(rg_min) || !is.finite(rg_max)) {                         # Si non fini
          rg_min <- 0                                                           # Min = 0
          rg_max <- 1                                                           # Max = 1
        }

        get_seuil_vigilance <- function(seuils_list, id) {                      # Helper seuil vigilance
          if (!id %in% names(seuils_list)) return(NA_real_)                     # Si absent retour NA
          s <- seuils_list[[id]]                                                # Seuils station
          if (is.null(s)) return(NA_real_)                                      # Si NULL retour NA
          if (!("Vigilance" %in% names(s))) return(NA_real_)                    # Si pas Vigilance NA
          v <- suppressWarnings(as.numeric(s$Vigilance))                        # Conversion num
          if (length(v) == 0) return(NA_real_)                                  # Si vide NA
          v <- v[is.finite(v)]                                                  # Garder finis
          if (length(v) == 0) return(NA_real_)                                  # Si vide NA
          max(v, na.rm = TRUE)                                                  # Retour max
        }

        if ("code_station" %in% names(maStation)) {                             # Si HYDRO
          id_sta <- maStation$code_station                                      # Code station
          seuil_vigilance <- get_seuil_vigilance(seuils, id_sta)                # Seuil vigilance
          limite_y <- NA_real_                                                  # Init limite Y
          if (is.finite(seuil_vigilance)) {                                     # Si seuil fini
            limite_y <- 1.5 * seuil_vigilance                                   # Limite = 1.5x seuil
          }
        } else {                                                                # Si ADES
          id_sta <- maStation$code_bss                                          # Code BSS
          seuil_vigilance <- get_seuil_vigilance(seuils, id_sta)                # Seuil vigilance
          limite_y <- NA_real_                                                  # Init limite Y
          if (is.finite(seuil_vigilance)) {                                     # Si seuil fini
            s <- seuils[[id_sta]]                                               # Seuils station
            if (!is.null(s) && "Crise" %in% names(s)) {                         # Si seuil Crise
              cr <- suppressWarnings(as.numeric(s$Crise))                       # Conversion num
              cr <- cr[is.finite(cr)]                                           # Garder finis
              if (length(cr) > 0) {                                             # Si valeurs
                limite_y <- seuil_vigilance + (seuil_vigilance - max(cr, na.rm = TRUE)) # Calcul limite
              }
            }
          }
        }

        if (!is.finite(limite_y) || limite_y <= rg_min) {                       # Si limite invalide
          limite_y <- rg_max                                                    # Limite = max
        }

        limite_y <- limite_y + 0.05 * (limite_y - rg_min)                       # Ajout marge

        graphics::plot(                                                         # Création des points
          range(X$jr),
          c(rg_min, rg_max),                                                    # Ranges X et Y
          type = "n",
          las = 1,
          xaxt = "n",
          xlab = NA,                                                            # Options affichage
          ylab = ifelse(suivi == "hydro", "Débit (l/s)", "Hauteur nappe (m)"),  # Label Y
          main = ifelse(
            p == "tot",                                                         # Titre
            paste(nom_sta, "\n(code station : ", j, ")", sep = ""),             # Titre total
            paste(nder, "derniers jours")),                                     # Titre zoom
          cex.main = 1.1,                                                       # Taille titre
          ylim = c(rg_min, limite_y)                                            # Limites Y
        )

        spY <- split(X, X$Y)                                                    # Split par année

        graphics::lines(
          spY[[as.character(annee)]]$j,
          spY[[as.character(annee)]][, labs[[suivi]]['mes']],
          col = "black",
          pch = 15,
          lwd = 2
        )                                                                       # Ligne année n
        if (length(spY) > 1) {                                                  # Si année n-1
          graphics::lines(
            spY[[as.character(annee - 1)]]$jr,
            spY[[as.character(annee - 1)]][, labs[[suivi]]['mes']],
            col = "gray82",
            pch = 15,
            lwd = 1
          )                                                                     # Ligne n-1
        }

        if (p == "tot") {                                                       # Si période totale
          graphics::mtext(
            paste(
              "Tendance des",
              nJtendan,
              "derniers jours :",
              tendance),
            side = 1,
            col = coul_tend[tendance],
            adj = 0,
            line = 2.5
          )                                                                     # Tendance
          graphics::abline(
            v = cumsum(c(0, jdm)),
            lty = 3,
            col = 8
          )                                                                     # Lignes mois
          graphics::mtext(
            names(jdm),
            at = zoo::rollmean(cumsum(c(0, jdm)), 2),
            side = 1,
            line = 0.5
          )                                                                     # Noms mois
          graphics::mtext(
            paste(
              c("Zone d'Alerte : ",
                paste(
                  sort(sta_AP$Zone[sta_AP$code_entite == j]),
                       collapse = " / ")
                ),
              collapse = ""),
            col = "forestgreen",
            adj = 0,
            side = 3
          )                                                                     # Zone alerte
          graphics::legend(
            "topright",
            names(spY),
            col = c("gray82",
                    "black"),
            lty = 1,
            lwd = c(1, 2),
            bg = "white"
          )                                                                     # Légende années
          if (any(names(seuils) == j)) {                                        # Si seuils
            graphics::legend(
              "topleft",
              names(coul_grav)[-1],
              ncol = 2,
              col = coul_grav[-1],
              lty = 1,
              lwd = 2,
              bg = "white"
            )                                                                   # Légende seuils
          }
        } else {                                                                # Si zoom
          graphics::mtext(
            paste("Niveau suggéré :", grav),
            side = 3,
            col = cGravSta,
            adj = 1,
            line = 0.2
          )                                                                     # Niveau suggéré
          tmp <- format(X[, labs[[suivi]]['date']], "%d") == "01"               # 1er du mois
          graphics::abline(
            v = X$jr[tmp],
            lty = 3,
            col = 8
          )                                                                     # Lignes 1er
          graphics::mtext(
            format(X[tmp, labs[[suivi]]['date']], "%d-%b"),
            at = X$jr[tmp],
            side = 1,
            line = 0.5
          )                                                                     # Labels dates
        }

        if (any(ls() == "seuils_sta")) {                                        # Si seuils existent
          for (i in 1:4) {                                                      # Boucle 4 seuils
            if (p == "der") lines(
              X$jr,
              seuils_sta[X$j, i],
              col = coul_grav[i + 1],
              type = 'l',
              lwd = 2
            )                                                                   # Seuils zoom
            if (p == "tot") lines(
              1:365,
              seuils_sta[1:365, i],
              col = coul_grav[i + 1],
              type = 'l',
              lwd = 2
            )                                                                   # Seuils total
          }
        }

        if (suivi == "hydro") {                                                 # Si HYDRO
          tmp <- unique(sta_AP$"DOE_m3.s"[sta_AP$code_entite == j]) * 1000      # DOE en L/s
          if (!is.na(tmp)) {                                                    # Si existe
            graphics::abline(
              h = tmp,
              lty = 2
            )                                                                   # Ligne DOE
            graphics::mtext(
              "DOE",
              side = 4,
              at = tmp,
              las = 1,
              font = 3,
              cex = 0.8,
              xpd = TRUE
            )                                                                   # Label DOE
          }
          tmp <- unique(sta_AP$"DCR_m3.s"[sta_AP$code_entite == j]) * 1000      # DCR en L/s
          if (!is.na(tmp)) {                                                    # Si existe
            graphics::abline(
              h = tmp,
              lty = 1
            )                                                                   # Ligne DCR
            graphics::mtext(
              "DCR",
              side = 4,
              at = tmp,
              las = 1,
              font = 3,
              cex = 0.8,
              xpd = TRUE
            )                                                                   # Label DCR
          }
        }

        if (suivi == "ades") {                                                  # Si ADES
          tmp <- unique(sta_AP$"NPA"[sta_AP$code_entite == j])                  # NPA
          if (!is.na(tmp)) {                                                    # Si existe
            graphics::abline(
              h = tmp,
              lty = 2
            )                                                                   # Ligne NPA
            graphics::mtext(
              "NPA",
              side = 4,
              at = tmp,
              las = 1,
              font = 3,
              cex = 0.8,
              xpd = TRUE
            )                                                                   # Label NPA
          }
          tmp <- unique(sta_AP$"NPC"[sta_AP$code_entite == j])                  # NPC
          if (!is.na(tmp)) {                                                    # Si existe
            graphics::abline(
              h = tmp,
              lty = 1
            )                                                                   # Ligne NPC
            graphics::mtext(
              "NPC",
              side = 4,
              at = tmp,
              las = 1,
              font = 3,
              cex = 0.8,
              xpd = TRUE
            )                                                                   # Label NPC
          }
        }

        if (add_mod_nappe & suivi == "ades" & p == "tot") {                     # Si projection nappe
          lab_mes <- ifelse(suivi == "ades", "Cote", "Mesure")                  # Label mesure
          file_chro <- here::here(
            "donnees",
            "sorties",
            "graphique",
            "Chroniques_completes",
            "RETEX_2023",
            "ades",
            paste0(sub("/", "_", j, fixed = TRUE), ".csv")
          )                                                                     # Fichier chrono

          if (file.exists(file_chro)) {                                         # Si fichier existe
            chro_sta <- utils::read.table(
              file_chro,
              sep = ";",
              header = TRUE
            )                                                                   # Lecture chrono
            chro_sta$Date <- as.Date(chro_sta$Date, format = "%d/%m/%Y")        # Conversion date
            chro_sta$Y <- as.numeric(format(chro_sta$Date, "%Y"))               # Année
            chro_sta$j <- as.numeric(format(chro_sta$Date, "%j"))               # Jour julien
            chro_sta <- chro_sta[, c("Date", "j", "Y", lab_mes)]                # Colonnes utiles

            annee_cplte <- data.frame(j = 1:365, mes = NA)                      # Année complète
            names(annee_cplte) <- c("j", lab_mes)                               # Noms colonnes

            spy_chro <- split(chro_sta, chro_sta$Y)                             # Split par année
            tmp <- lapply(spy_chro, function(X) {                               # Boucle années
              X <- merge(X, annee_cplte, all = TRUE)                            # Fusion
              X <- X[!duplicated(X$j), ]                                        # Dédoublonnage
              X$Date <- as.Date(
                paste(
                  X$j,
                  na.omit(unique(X$Y))),
                format = "%j %Y"
              )                                                                 # Reconst date
              X                                                                 # Retour
            })
            chro_sta <- do.call("rbind", tmp)                                   # Combinaison

            tmp <- zoo::rollmean(
              chro_sta[, lab_mes],
              10,
              na.rm = TRUE,
              align = "right"
            )                                                                   # Moyenne mobile
            chro_sta <- chro_sta[(nrow(chro_sta) - length(tmp) + 1):nrow(chro_sta), ] # Alignement
            chro_sta[, lab_mes] <- tmp                                          # Remplacement
            chro_sta$Y <- as.numeric(format(chro_sta$Date, "%Y"))               # Année

            last_date <- station$j[which.max(station[, labs[[suivi]]['date']])] # Dernier jour
            last_data <- station[which.max(station[, labs[[suivi]]['date']]), labs[[suivi]]['mes']] # Dernière valeur
            spy_chro <- split(chro_sta, chro_sta$Y)                             # Split par année
            spy_chro <- spy_chro[!names(spy_chro) %in% as.character(annee)]     # Exclure année n

            spy_chro <- lapply(spy_chro, function(X) {                          # Boucle années
              X[, lab_mes] <- X[, lab_mes] - X[X$j == last_date, lab_mes] + last_data # Recalage
              X                                                                 # Retour
            })
            chro_sta <- do.call('rbind', spy_chro)                              # Combinaison
            tmp <- tapply(
              chro_sta[, lab_mes],
              chro_sta$j,
              quantile,
              p = c(0.1, 0.25, 0.5, 0.75, 0.9),
              na.rm = TRUE
            )                                                                   # Quantiles
            tmp <- as.data.frame(do.call("rbind", tmp))                         # Conversion df
            tmp$j <- as.numeric(rownames(tmp))                                  # Index jour
            hz_proj <- seq.Date(aujourdhui, aujourdhui + 6 * 30, by = "day")    # Horizon projection
            tmp <- tmp[as.numeric(format(hz_proj, "%j")), ]                     # Filtrage jours

            sp_proj <- split(tmp, format(hz_proj, "%Y"))                        # Split par année

            lapply(sp_proj, function(tmp) {                                     # Boucle années
              graphics::polygon(
                c(tmp$j,
                  rev(tmp$j)),
                c(tmp[, 1],
                  rev(tmp[, 5])
                ),
                col = rgb(0.4, 0.4, 1, 0.1),
                border = NA
              )                                                                 # Intervalle 10-90%
              graphics::polygon(
                c(tmp$j,
                  rev(tmp$j)),
                c(tmp[, 2],
                  rev(tmp[, 4])),
                col = rgb(0.4, 0.4, 1, 0.4),
                border = NA
              )                                                                 # Intervalle 25-75%
              graphics::lines(
                tmp$j,
                tmp[, 3],
                col = "black",
                lty = 2
              )                                                                 # Médiane
            })
          }
        }
      }

      if (add.carto) {                                                          # Si carto activée
        graphics::par(mar = c(0, 0, 0, 0))                                      # Marges nulles
        graphics::plot(UG)                                                      # Plot UG
        tmp <- if (suivi == "hydro") SIG_hydro else SIG_ades                    # Données SIG
        id <- ifelse(
          suivi == "hydro",
          substr(j, 1, 8),
          j
        )                                                                       # ID station
        graphics::points(
          SIG_hydro[, c("x", "y")],
          pch = 22,
          bg = "white"
        )                                                                       # Points HYDRO
        graphics::points(
          SIG_ades[, c("x", "y")],
          pch = 24,
          bg = "white"
        )                                                                       # Points ADES
        graphics::points(
          tmp[tmp$Code == id, c("x", "y")],
          cex = 2.5,
          col = "green",
          lwd = 1.5)                                                            # Station courante
        graphics::points(
          tmp[tmp$Code == id, c("x", "y")],
          pch = ifelse(suivi == "hydro", 22, 24),
          cex = ifelse(suivi == "hydro", 1.5, 1.3),
          bg = ifelse(suivi == "hydro", "red", "blue")
        )                                                                       # Symbole
        graphics::legend(
          "bottomleft",
          c("suivis HYDRO", "suivis ADES"),
          pch = c(22, 24),
          pt.cex = c(1.5, 1.3),
          bty = "n"
        )                                                                       # Légende
      }

      tabGrav                                                                   # Retour tableau gravité
    })

    dev.off()                                                                   # Fermeture PDF
    tabGravTot                                                                  # Retour données
  })

  list(a = datGrav, b = infos_sta)                                              # Retour liste
})

names(donnees) <- names(labs)                                                   # Noms suivis


# ------------------------------------------------------------------------------
# Tableaux des niveaux de gravité
# ------------------------------------------------------------------------------
MAXDATE <- max(sapply(names(telech), function(suivi) {                          # Date max données
  a <- telech[[suivi]][["a"]]                                                   # Données suivi
  max(sapply(a, function(AC) {                                                  # Max par AC
    max(sapply(AC, function(x) max(x[, labs[[suivi]]['date']])))                # Max par station
  }))
}))

labs_y <- c(
  "Zone",
  "code_entite",
  "Station",
  "UG",
  "repr",
  "der_obs",
  "date_der_obs",
  "tendance (10 der. j)"
)                                                                               # Labels colonnes

tabs <- lapply(names(donnees), function(suivi) {                                # Boucle suivis

  tabs_Resultats <- list()                                                      # Init résultats
  datGrav <- donnees[[suivi]]$a                                                 # Données gravité
  infos_sta <- donnees[[suivi]]$b                                               # Infos stations
  infos_sta <- lapply(infos_sta, function(x) x[, names(x) %in% labs_y])         # Filtrage colonnes

  for (lab_AP in names(datGrav)) {                                              # Boucle AC
    print(paste(lab_AP, "-----", suivi))                                        # Affichage progression

    resultat <- lapply(names(datGrav[[lab_AP]]), function(i, s = suivi) {       # Boucle stations

      x <- datGrav[[lab_AP]][[i]]                                               # Données station
      mask <- difftime(aujourdhui, x[, labs[[s]]["date"]], units = "days") / 30 <= 6 & # Filtre 6 mois
        substr(x[, labs[[s]]["date"]], 9, 10) %in% c("01", "15")                # 1er et 15 du mois
      mask[length(mask)] <- TRUE                                                # Inclure dernier

      if (any(names(x) == "grav")) {                                            # Si gravité existe
        y <- names(coul_grav)[x[mask, "grav"] + 1]                              # Noms niveaux
      } else {                                                                  # Sinon
        y <- rep("-", sum(mask))                                                # Tirets
      }

      tmp <- lm(tail(x[, c("j", labs[[s]]['mes'])], nJtendan))                  # Régression tendance
      tmp <- coef(summary(tmp))                                                 # Coefficients
      if (nrow(tmp) > 1) {                                                      # Si coefficients
        tendance <- sign(tmp[2, 1]) * (tmp[2, 4] <= 0.05)                       # Signe si signif
        tendance <- if (tendance < 0) "↓" else if (tendance > 0) "↑" else "~"   # Symbole
      } else {                                                                  # Sinon
        tendance <- "→"                                                         # Stable
      }

      y <- c(y, tendance)                                                     # Ajout tendance
      y <- as.data.frame(as.list(y))                                          # Conversion df
      names(y) <- c(format(x[mask, labs[[s]]["date"]], "%d/%m/%y"),           # Noms colonnes dates
                    paste("tendance (", nJtendan, " der. j)", sep = ""))      # Nom tendance

      y <- cbind(infos_sta[[lab_AP]][infos_sta[[lab_AP]]$code_entite == i, c("Zone", "code_entite", "Station", "UG", "repr")], y) # Ajout infos

      y <- as.data.frame(y)                                                     # Conversion df
      y$date_der_obs <- tail(setdiff(names(y), labs_y), 1)                      # Date dernière obs
      names(y)[names(y) == unique(y$date_der_obs)] <- "der_obs"                 # Renommage
      y[c(labs_y[1:5], setdiff(names(y), labs_y), tail(labs_y, 3))]             # Réordonnancement
    })

    tmp <- sort(unique(unlist(lapply(resultat, names))))                        # Toutes colonnes
    names(tmp) <- tmp                                                           # Auto-nommage
    date_cols <- setdiff(names(tmp), labs_y)                                    # Colonnes dates
    dates <- character(0)                                                       # Init dates
    if (length(date_cols) > 0) {                                                # Si colonnes dates
      dates_parsed <- as.Date(date_cols, format = "%d/%m/%y")                   # Parsing dates
      dates_valides <- date_cols[!is.na(dates_parsed)]                          # Dates valides
      if (length(dates_valides) > 0) {                                          # Si dates valides
        dates_parsed <- as.Date(dates_valides, format = "%d/%m/%y")             # Parsing
        dates <- format(sort(dates_parsed), format = "%d/%m/%y")                # Tri formaté
      }
    }
    tmp <- tmp[c(labs_y[1:5], dates, tail(labs_y, 3))]                          # Réordonnancement
    resultat <- lapply(resultat, function(a) {                                  # Boucle résultats
      b <- setdiff(tmp, names(a))                                               # Colonnes manquantes
      b <- matrix(
        "-",
        ncol = length(b),
        nrow = nrow(a),
        dimnames = list(rownames(a), b)
      )                                                                         # Remplissage
      cbind(a, b)[, tmp]                                                        # Combinaison
    })

    resultat <- unique(do.call("rbind", resultat))                              # Combinaison unique
    tabs_Resultats[[lab_AP]] <- resultat                                        # Stockage
  }

  return(tabs_Resultats)                                                        # Retour résultats
})

names(tabs) <- names(donnees)                                                   # Noms suivis


# ------------------------------------------------------------------------------
# Export excel avec openxlsx
# ------------------------------------------------------------------------------
if (TRUE) {                                                                      # Export activé

  coul_esoesu <- c(sup = "lightblue", sou = "lightgreen")                        # Couleurs ESO/ESU

  resultat <- lapply(tabs, function(x) {                                         # Combinaison tabs
    do.call('rbind', x)                                                          # Rbind
  })

  tmp <- sort(unique(unlist(lapply(resultat, names))))                          # Toutes colonnes
  names(tmp) <- tmp                                                             # Auto-nommage
  date_cols <- setdiff(names(tmp), labs_y)                                      # Colonnes dates
  dates <- character(0)                                                         # Init dates
  if (length(date_cols) > 0) {                                                  # Si colonnes dates
    dates_parsed <- as.Date(date_cols, format = "%d/%m/%y")                     # Parsing dates
    dates_valides <- date_cols[!is.na(dates_parsed)]                            # Dates valides
    if (length(dates_valides) > 0) {                                            # Si dates valides
      dates_parsed <- as.Date(dates_valides, format = "%d/%m/%y")               # Parsing
      dates <- format(sort(dates_parsed), format = "%d/%m/%y")                  # Tri formaté
    }
  }
  tmp <- tmp[c(labs_y[1:5], dates, tail(labs_y, 3))]                            # Réordonnancement

  resultat <- lapply(resultat, function(a) {                                    # Boucle résultats
    b <- setdiff(tmp, names(a))                                                 # Colonnes manquantes
    b <- matrix(
      "-",
      ncol = length(b),
      nrow = nrow(a),
      dimnames = list(rownames(a), b)
    )                                                                           # Remplissage
    cbind(a, b)[, tmp]                                                          # Combinaison
  })

  resultat <- unique(do.call("rbind", resultat))                                # Combinaison unique

  if (TRUE) {                                                                   # Ordre zones fixe
    ord_ZA <- data.frame(Zone = c(                                              # Zones ordonnées
      "Galaure – Drôme des Collines",                                           # Zone 1
      "Plaine de Valence",                                                      # Zone 2
      "Royan – Vercors",                                                        # Zone 3
      "Bassin de la Drôme",                                                     # Zone 4
      "Roubion – Jabron",                                                       # Zone 5
      "Lez – AEygues - Ouvèze"                                                  # Zone 6
    ))
  } else {                                                                      # Ordre alphabétique
    ord_ZA <- data.frame(Zone = sort(resultat$Zone))                            # Tri alpha
  }

  resultat <- merge(
    ord_ZA,
    resultat,
    all = TRUE,
    sort = FALSE
  )                                                                             # Fusion ordonnée

  if (juste_derniere_obs) resultat <- resultat[, labs_y]                        # Si dernière obs seule

  wb <- openxlsx::createWorkbook()                                              # Création workbook

  openxlsx::addWorksheet(
    wb,
    "Feuille1"
  )                                                                             # Ajout feuille

  style_head <- openxlsx::createStyle(
    halign = "center",
    valign = "center",
    textDecoration = "bold")                                                    # Style entête
  style_V <- openxlsx::createStyle(
    halign = "center",
    valign = "center",
    textDecoration = "bold",
    fgFill = "#FFFF00")                                                         # Vigilance
  style_A <- openxlsx::createStyle(
    halign = "center",
    valign = "center",
    textDecoration = "bold",
    fgFill = "#FFA500")                                                         # Alerte
  style_AR <- openxlsx::createStyle(
    halign = "center",
    valign = "center",
    textDecoration = "bold",
    fgFill = "#FF0000")                                                         # Alerte renf
  style_C <- openxlsx::createStyle(
    halign = "center",
    valign = "center",
    textDecoration = "bold",
    fgFill = "#9932CC")                                                         # Crise
  style_RAS <- openxlsx::createStyle(
    halign = "center",
    valign = "center",
    textDecoration = "bold",
    fgFill = "#00CD00")                                                         # Hors vigilance
  style_B <- openxlsx::createStyle(
    halign = "center",
    valign = "center",
    textDecoration = "bold",
    fgFill = "#FFFF00")                                                         # Baisse
  style_S <- openxlsx::createStyle(
    halign = "center",
    valign = "center",
    textDecoration = "bold",
    fgFill = "#9ACD32")                                                         # Stable
  style_H <- openxlsx::createStyle(
    halign = "center",
    valign = "center",
    textDecoration = "bold",
    fgFill = "#FF6347")                                                         # Hausse
  style_ESO <- openxlsx::createStyle(
    halign = "center",
    valign = "center",
    textDecoration = "bold",
    fgFill = "#90EE90")                                                         # ESO
  style_ESU <- openxlsx::createStyle(
    halign = "center",
    valign = "center",
    textDecoration = "bold",
    fgFill = "#ADD8E6")                                                         # ESU
  style_Z <- openxlsx::createStyle(
    halign = "center",
    valign = "center",
    textDecoration = "bold",
    border = "TopBottomLeftRight")                                              # Zone

  tmp <- c("Hors vigilance" = "Ok",
           "Vigilance" = "Vigi.",
           "Alerte" = "Alerte",
           "Alerte renforcée" = "Al. renf.",
           "Crise" = "Crise")                                                   # Abréviations

  resultat_abb <- resultat                                                      # Copie pour abrév
  for (i in names(tmp)) {                                                       # Boucle niveaux
    for (j in names(resultat_abb)) {                                            # Boucle colonnes
      x <- resultat_abb[, j]                                                    # Valeurs colonne
      x[x == i] <- tmp[i]                                                       # Remplacement
      resultat_abb[, j] <- x                                                    # Affectation
    }
  }

  resultat_abb[] <- lapply(resultat_abb, as.character)                          # Conversion character

  openxlsx::writeData(
    wb,
    "Feuille1",
    resultat_abb,
    headerStyle = style_head
  )                                                                             # Écriture données

  for (i in 1:nrow(resultat)) {                                                 # Boucle lignes

    cols_grav <- 6:(ncol(resultat) - 2)                                         # Colonnes gravité

    for (col in cols_grav) {                                                    # Boucle colonnes
      val <- as.character(resultat[i, col])                                     # Valeur cellule
      if (!is.na(val)) {                                                        # Si non NA
        if (val == names(coul_grav)[2]) openxlsx::addStyle(
          wb,
          "Feuille1",
          style_V,
          rows = i + 1,
          cols = col
        )                                                                       # Style V
        if (val == names(coul_grav)[3]) openxlsx::addStyle(
          wb,
          "Feuille1",
          style_A,
          rows = i + 1,
          cols = col
        )                                                                       # Style A
        if (val == names(coul_grav)[4]) openxlsx::addStyle(
          wb,
          "Feuille1",
          style_AR,
          rows = i + 1,
          cols = col
        )                                                                       # Style AR
        if (val == names(coul_grav)[5]) openxlsx::addStyle(
          wb,
          "Feuille1",
          style_C,
          rows = i + 1,
          cols = col
        )                                                                       # Style C
        if (val == names(coul_grav)[1]) openxlsx::addStyle(
          wb,
          "Feuille1",
          style_RAS,
          rows = i + 1,
          cols = col
        )                                                                       # Style RAS
      }
    }

    val_ug <- as.character(resultat[i, 4])                                      # Valeur UG
    if (!is.na(val_ug)) {                                                       # Si non NA
      if (val_ug == names(coul_esoesu)[2]) openxlsx::addStyle(
        wb,
        "Feuille1",
        style_ESO,
        rows = i + 1,
        cols = 2:4
      )                                                                         # Style ESO
      if (val_ug == names(coul_esoesu)[1]) openxlsx::addStyle(
        wb,
        "Feuille1",
        style_ESU,
        rows = i + 1,
        cols = 2:4
      )                                                                         # Style ESU
    }

    val_tend <- as.character(resultat[i, ncol(resultat)])                       # Valeur tendance
    if (!is.na(val_tend)) {                                                     # Si non NA
      if (val_tend == names(coul_tend)[3]) openxlsx::addStyle(
        wb,
        "Feuille1",
        style_B,
        rows = i + 1,
        cols = ncol(resultat)
      )                                                                         # Style baisse
      if (val_tend == names(coul_tend)[2]) openxlsx::addStyle(
        wb,
        "Feuille1",
        style_S,
        rows = i + 1,
        cols = ncol(resultat)
      )                                                                         # Style stable
      if (val_tend == names(coul_tend)[1]) openxlsx::addStyle(
        wb,
        "Feuille1",
        style_H,
        rows = i + 1,
        cols = ncol(resultat)
      )                                                                         # Style hausse
    }

    openxlsx::addStyle(
      wb,
      "Feuille1",
      style_Z,
      rows = i + 1,
      cols = 1
    )                                                                           # Style zone
  }

  openxlsx::setColWidths(
    wb,
    "Feuille1",
    cols = 1:ncol(resultat),
    widths = "auto"
  )                                                                             # Largeurs auto

  plyr::d_ply(                                                                  # Fusion cellules Zone
    dplyr::transmute(
      resultat,
      Zone,
      nr = row_number() + 1
     ),                                                                         # Numéros lignes
    .variables = "Zone",                                                        # Variable groupement
    .fun = function(x) {                                                        # Fonction fusion
      openxlsx::mergeCells(
        wb,
        "Feuille1",
        cols = 1,
        rows = min(x$nr):max(x$nr)
      )                                                                         # Fusion
    }
  )

  openxlsx::saveWorkbook(
    wb,
    here::here(
      "sorties",
      "graphique",
      "xlsx",
      paste0(aujourdhui, "_niveaux_gravite.xlsx")
    ),
    overwrite = TRUE
  )                                                                             # Sauvegarde
}

# ------------------------------------------------------------------------------
# Téléchargement des stations HYDRO et ADES pour le département 26
# depuis l'API HUBEAU (données publiques OFB/BRGM) → Génère les shapefiles
# utilisés dans la section cartographie
# ------------------------------------------------------------------------------
dep <- "26"                                                                      # Code département Drôme

# ---- Stations HYDRO (hydrométrie — débits) issues de l API v2 :
#      referentiel/stations en GeoJSON -----------------------------------------
url_hydro <- paste0(
  "https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/stations",
  "?code_departement=", dep,
  "&format=geojson",
  "&size=500"                                                                    # Max par page
)

message("Téléchargement stations HYDRO (dept ", dep, ")...")
SIG_hydro <- tryCatch(
  sf::st_read(url_hydro, quiet = TRUE),
  error = function(e) {
    stop("Erreur API HYDRO : ", e$message,
         "\nVérifiez votre connexion ou consultez https://hubeau.eaufrance.fr/status")
  }
)
message("  → ", nrow(SIG_hydro), " stations HYDRO téléchargées")

    # ---- Garder uniquement les colonnes utiles + renommer pour cohérence avec
    #      le script -----------------------------------------------------------
    SIG_hydro <- SIG_hydro[, c("code_station", "libelle_station",
                               "code_commune_station", "libelle_commune",
                               "geometry")]
    names(SIG_hydro)[names(SIG_hydro) == "code_station"] <- "NUMERO"                 # Nom attendu dans le script

    # ---- Sauvegarde shapefile HYDRO ------------------------------------------
    dir_hydro <- here::here(
      "donnees",
      "graphique",
      "origines",
      "sig"
    )
    dir.create(dir_hydro, recursive = TRUE, showWarnings = FALSE)

    sf::st_write(SIG_hydro,
                 file.path(dir_hydro, "Stations_HYDRO.shp"),
                 delete_layer = TRUE)                                                # Écrasement si existe
    message("  → Sauvegardé : ", file.path(dir_hydro, "Stations_HYDRO.shp"))


# ---- Stations ADES (piézométrie — nappes souterraines) via jsonlite + retry :
#      plus robuste que st_read sur cette API (503 fréquents) ------------------
library(jsonlite)

url_ades <- paste0(
  "https://hubeau.eaufrance.fr/api/v1/niveaux_nappes/stations",
  "?code_departement=", dep,
  "&format=json",
  "&size=500"                                                                    # Max par page
)

message("Téléchargement stations ADES (dept ", dep, ")...")

# Fonction avec retry (5 tentatives, pause croissante)
fetch_ades <- function(url, max_retry = 5) {
  for (i in seq_len(max_retry)) {
    tryCatch({
      res <- jsonlite::fromJSON(url)
      return(res)
    }, error = function(e) {
      message("  tentative ", i, "/", max_retry, " échouée : ", e$message)
      if (i < max_retry) Sys.sleep(i * 5)                                        # Pause croissante : 5, 10, 15, 20s
    })
  }
  stop("API ADES injoignable après ", max_retry, " tentatives.\n",
       "Vérifiez : https://hubeau.eaufrance.fr/status")
}

res_ades <- fetch_ades(url_ades)
df_ades  <- res_ades$data                                                       # Déjà un data.frame (jsonlite simplifie)

message("  → ", nrow(df_ades), " stations ADES téléchargées")
message("  Colonnes retournées : ", paste(names(df_ades), collapse = ", "))     # DIAGNOSTIC

    # ---- Garder uniquement les colonnes utiles + renommer --------------------
    df_ades <- data.frame(
      numero_sta      = df_ades$code_bss,                                       # Nom attendu dans le script
      nom_bss         = df_ades$libelle_pe,                                     # Libelle attendu dans le script
      code_commune    = df_ades$code_commune_insee,                             # Code Insee des communes attendu dans le script
      libelle_commune = df_ades$nom_commune,                                    # Nom des communes attendu dans le script
      x               = as.numeric(df_ades$x),                                  # Longitude (CRS84)
      y               = as.numeric(df_ades$y),                                  # Latitude  (CRS84)
      stringsAsFactors = FALSE
    )

    # ---- Vers objet sf — l'API retourne x=longitude, y=latitude en CRS84
    #      (cf. doc officielle) On crée en 4326 puis on reprojette en Lambert-93
    #      (2154) pour être cohérent avec HYDRO --------------------------------
    SIG_ades <- sf::st_as_sf(df_ades, coords = c("x", "y"), crs = 4326)
    SIG_ades <- sf::st_transform(SIG_ades, crs = 2154)                          # Reprojection → Lambert-93

    # ---- Sauvegarde shapefile ADES -------------------------------------------
    dir_ades <- here::here(
      "donnees",                                                                # Dossier données projet
      "graphique",                                                              # Sous-domaine cartographique
      "origines",                                                               # Données sources / intermédiaires
      "sig"                                                                     # Espace dédié aux couches SIG exportées
    )

    dir.create(
      dir_ades,
      recursive = TRUE,                                                         # Crée toute l'arborescence si nécessaire
      showWarnings = FALSE                                                      # Évite message si le dossier existe déjà
    )

    sf::st_write(
      SIG_ades,
      file.path(dir_ades, "Stations_ADES.shp"),                                 # Construction propre du chemin
      delete_layer = TRUE                                                       # Écrase couche existante si présente
    )

    message(
      "  → Sauvegardé : ",
      file.path(dir_ades, "Stations_ADES.shp")
    )                                                                           # Log explicite pour suivi batch / script automatisé


# ---- Résumé ------------------------------------------------------------------
message("\n--- Téléchargement terminé ---")
message("Fichiers générés dans : ", dir_hydro)
message("  Stations_HYDRO.shp  → ", nrow(SIG_hydro), " stations")
message("  Stations_ADES.shp   → ", nrow(SIG_ades),  " stations")
message("\nCes fichiers sont utilisés dans la section 'add.carto' de 07_create_graphique.R")


# ------------------------------------------------------------------------------
# Synthèse cartographique ESO / ESU (optionnel)
# Version modernisée : remplacement de maptools (archivé) par sf + ggplot2
# ------------------------------------------------------------------------------
if (TRUE) {                                                                     # Section désactivée

  # ---- Lecture des données spatiales ---------------------------------------
  UG          <- sf::st_read(
    here::here(
      "donnees",
      "graphique",
      "origines",
      "sig",
      "UG_ESU",
      "ESU_84_Dept26_2023.shp"
  ))                                                                            # Zones d'alerte (polygones)
  SIG_ades    <- sf::st_read(
    here::here(
      "donnees",
      "graphique",
      "origines",
      "sig",
      "Stations_ADES.shp"
  ))                                                                            # Stations ADES (points)
  SIG_hydro   <- sf::st_read(
    here::here(
      "donnees",
      "graphique",
      "origines",
      "sig",
      "Stations_HYDRO.shp"
  ))                                                                            # Stations HYDRO (points)
  SIG_hydro   <- sf::st_transform(
    SIG_hydro,
    crs = 2154
  )


  # ---- Préparation des données attributaires ---------------------------------
    # Copie et troncature des codes_entite (max 8 car, hors codes avec "/")
  res <- resultat                                                               # Copie locale pour éviter modification de l’objet source

  idx_sans_slash <- !grepl("/", res$code_entite, fixed = TRUE)                  # Identifie les codes simples (sans "/")

  res$code_entite[idx_sans_slash] <-                                            # Normalisation clé station
    substr(res$code_entite[idx_sans_slash], 1, 8)                               # Troncature à 8 caractères

  # Nettoyage du champ NUMERO dans HYDRO (suppression espaces + troncature)
  SIG_hydro$NUMERO <-                                                           # Nettoyage identifiant HYDRO
    substr(gsub(" ", "", SIG_hydro$NUMERO), 1, 8)                               # Suppression espaces + troncature

  # ---- Jointures attributaires (données résultats ↔ données spatiales) -------
    # On joint uniquement les attributs nécessaires ; on garde la géométrie sf
    SIG_ades <-                                                                 # Jointure gauche ADES
      dplyr::left_join(SIG_ades, res,                                           # Conserve géométrie sf
                       by = c("numr_st" = "code_entite"))                       # Clé station ADES

    SIG_hydro <-                                                                # Jointure gauche HYDRO
      dplyr::left_join(SIG_hydro, res,                                          # Conserve géométrie sf
                       by = c("NUMERO" = "code_entite"))                        # Clé station HYDRO


  # Dédoublonnage sur géométrie + niveau de gravité
    SIG_ades <-                                                                 # Sélection minimale ADES
      unique(SIG_ades[, c("geometry", "der_obs")])                              # 1 point par géométrie/niveau

    SIG_hydro <-                                                                # Sélection minimale HYDRO
      unique(SIG_hydro[, c("geometry", "der_obs")])                             # 1 point par géométrie/niveau


  # ---- Construction de la carte avec ggplot2 ---------------------------------
    # Titre et sous-titre avec la date formatée
    titre <- "Synthèse cartographique"                                          # Titre principal de la carte

    sous_titre <- format(Sys.Date(), "%d %b %Y")                                # Date du jour formatée (affichage dynamique)

    carte <- ggplot2::ggplot() +                                                # Initialisation du canvas ggplot (sans data globale)
        # Fond : polygones des zones d'alerte
        ggplot2::geom_sf(                                                       # Ajout couche spatiale zones d’alerte
          data = UG,                                                            # Objet sf polygones
          fill = NA,                                                            # Pas de remplissage (fond transparent)
          colour = "black",                                                     # Contour noir
          linewidth = 0.6                                                       # Épaisseur trait
        ) +                                                                     # Première couche cartographique

        # Points HYDRO (carrés)
        ggplot2::geom_sf(                                                       # Ajout couche stations HYDRO
          data = SIG_hydro,                                                     # Objet sf contenant points HYDRO
          aes = ggplot2::aes(colour = der_obs),                                 # Mapping esthétique : couleur selon niveau de gravité
          shape = 15,                                                           # Symbole carré plein (différenciation visuelle HYDRO)
          size = 3,                                                             # Taille des points (lisibilité PDF/A4)
          na.rm = TRUE                                                          # Ignore les lignes avec NA (évite warnings rendu)
        ) +

        # Points ADES (triangles)
        ggplot2::geom_sf(                                                       # Ajout couche stations ADES
          data = SIG_ades,                                                      # Objet sf contenant points ADES
          aes = ggplot2::aes(colour = der_obs),                                 # Mapping couleur selon niveau de gravité
          shape = 17,                                                           # Symbole triangle plein (distinction HYDRO)
          size = 2.8,                                                           # Taille légèrement inférieure aux HYDRO
          na.rm = TRUE                                                          # Ignore observations sans niveau (NA)
        ) +                                                                     # Superposition sur couches précédentes


        # Palette de couleurs (ajuster selon `coul_grav`)
        ggplot2::scale_colour_manual(                                           # Échelle couleur personnalisée
          name = "Niveau de gravité",                                           # Titre de la légende
          values = coul_grav,                                                   # Vecteur nommé : nom = niveau, valeur = couleur
          drop = FALSE                                                          # Conserve tous les niveaux même absents des données
        ) +

        # Légende des types de stations
        ggplot2::scale_shape_manual(                                            # Définition échelle manuelle des formes
          name = "Type de suivi",                                               # Titre de la légende formes
          values = c("HYDRO" = 15, "ADES" = 17),                                # Mapping type → code symbole ggplot
          labels = c("suivis HYDRO", "suivis ADES")                             # Libellés affichés dans la légende
        ) +

        # Titre et date
        ggplot2::labs(                                                          # Définition métadonnées du graphique
          title = titre,                                                        # Titre principal
          subtitle = sous_titre                                                 # Sous-titre (date dynamique)
        ) +

        # Thème propre et sobrement cartographique
        ggplot2::theme_void() +                                                 # Suppression axes, grilles et fond (rendu cartographique pur)
          ggplot2::theme(                                                       # Personnalisation fine du thème
            plot.title = ggplot2::element_text(                                 # Paramétrage titre principal
              hjust = 0,                                                        # Alignement à gauche
              face  = "bold",                                                   # Gras
              size  = 13                                                        # Taille adaptée export PDF
            ),
            plot.subtitle = ggplot2::element_text(                              # Paramétrage sous-titre (date)
              hjust = 1,                                                        # Alignement à droite
              face  = "italic",                                                 # Style italique
              size  = 9                                                         # Taille secondaire
            ),
            legend.position = "bottom",                                         # Placement des légendes sous la carte
            legend.box = "vertical",                                            # Empilement vertical des blocs de légende
            legend.key.size = ggplot2::unit(0.4, "cm"),                         # Taille des symboles en légende

            legend.text = ggplot2::element_text(size = 8)                       # Taille texte légende
          )

  # ---- Export en PDF ---------------------------------------------------------
    grDevices::pdf(                                                             # Ouverture du device PDF (sortie graphique)
      file = here::here(                                                        # Construction du chemin de sortie (portable)
        "sorties", "graphique", "pdf",                                          # Arborescence projet
        paste0(                                                                 # Nom de fichier horodaté
          "Carto_ESO_ESU_",
          format(Sys.Date(), "%Y-%m-%d"),                                       # Date ISO pour tri lexical
          ".pdf"
        )
      ),
      width = 6,                                                                # Largeur du PDF en pouces
      height = 6,                                                               # Hauteur du PDF en pouces
      useDingbats = FALSE                                                       # Désactive Dingbats (évite soucis polices/symboles)
    )                                                                           # Device actif : tout plot ensuite va dans le PDF
    print(carte)                                                                # Rendu explicite de l’objet ggplot dans le device
    dev.off()                                                                   # Fermeture du device (flush + finalisation du fichier PDF)
}                                                                               # Fermeture du bloc parent (if / function / loop)

# ------------------------------------------------------------------------------
# Message de fin
# ------------------------------------------------------------------------------
message("Script terminé avec succès!")                                          # Message succès
message(
  paste(
    "Fichiers PDF générés dans:",
    here::here(
      "sorties",
      "graphique",
      "pdf"
)))                                                                             # Chemin PDF
message(
  paste(
    "Fichier Excel généré:",
    here::here(
      "sorties",
      "graphique",
      "xlsx",
      paste0(aujourdhui, "_niveaux_gravite.xlsx")
)))                                                                             # Chemin Excel

message("SCRIPT 07 TERMINÉ")                                                    # Message fin script


# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT 07_create_graphique.R
# ──────────────────────────────────────────────────────────────────────────────

