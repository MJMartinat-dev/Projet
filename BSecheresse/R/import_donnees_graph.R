# ------------------------------------------------------------------------------
# SCRIPT      : import_donnees_graph.R
# ------------------------------------------------------------------------------
# AUTEUR      : MJMartinat
# Structure   : DDT de la Drôme
# DATE        : 01/06/2025
# ------------------------------------------------------------------------------
# DESCRIPTION : Fonctions d'import des données hydrologiques via API Hub'eau
#               pour le suivi sécheresse (débits HYDRO et niveaux nappes ADES)
# ADAPTATION  : Code de Neil Guion et DDT38
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# FONCTION : hubO
# -----------------------------------------------------------------------------
# Description : Télécharge les données de suivi hydrologique depuis Hub'eau
#               - HYDRO : débits journaliers élaborés (QmnJ)
#               - ADES  : niveaux piézométriques des nappes
#
# Arguments :
#   staCSV     : Chemin vers le fichier CSV listant les stations à interroger
#   date_debut : Date de début de la période (format YYYY-MM-DD)
#   ori        : Source des données ("hydro" ou "ades")
#
# Retour :
#   - Si ori = "hydro" : data.frame avec colonnes code_station, date_obs_elab, resultat_obs_elab
#   - Si ori = "ades"  : liste de data.frames par station (code_bss, date_mesure, niveau_nappe_eau)
# ------------------------------------------------------------------------------

hubO <- function(staCSV, date_debut, ori = "hydro") {

  # staCSV = files_AC[[1]] ; ori = "ades"

  # URL de base de l'API Hub'eau
  source_url <- "https://hubeau.eaufrance.fr/api/"

  # ----------------------------------------------------------------------------
  # Lecture de la liste des stations à interroger
  # ----------------------------------------------------------------------------
  liste_sta <- read.table(
    staCSV,
    sep = ",",
    header = TRUE,
    quote = "\""
  )
  liste_sta <- liste_sta[liste_sta$integrer == "O", ]


  # ----------------------------------------------------------------------------
  # Requête API selon la source (HYDRO ou ADES)
  # ----------------------------------------------------------------------------
  if (ori == "hydro") {
    # ---- HYDRO : Débits journaliers élaborés (QmnJ) --------------------------
    url <- paste0(
      source_url,
      "v2/hydrometrie/obs_elab.csv?",
      "code_entite=", paste(liste_sta$code_entite, collapse = "&code_entite="),
      "&date_debut_obs_elab=", date_debut,
      "&date_fin_obs_elab=", format(aujourdhui),
      "&fields=code_station%2Cdate_obs_elab%2Cresultat_obs_elab",
      "&grandeur_hydro_elab=QmnJ",
      "&sort=asc&size=20000"
    )

    p <- read.table(url, sep = ";", header = TRUE, as.is = TRUE)
  }

  if (ori == "ades") {
    # ---- ADES : Niveaux piézométriques des nappes ----------------------------
    url <- paste0(
      source_url,
      "v1/niveaux_nappes/chroniques.csv?",
      "code_bss=", sub("/", "%2F", liste_sta$code_entite),
      "&date_debut_mesure=", date_debut,
      "&date_fin_mesure=", format(aujourdhui),
      "&fields=code_bss%2Cdate_mesure%2Cniveau_nappe_eau",
      "&size=20000&sort=asc"
    )

    p <- lapply(url, read.table, sep = ";", h = TRUE, as.is = TRUE)

    # ---- Mode debug (désactivé par défaut) -----------------------------------
    if (FALSE) {
      p <- list()
      for (i in 1:length(url)) {
        print(liste_sta$code_entite[i])
        p[[i]] <- read.table(url[[i]], sep = ";", header = TRUE, as.is = TRUE)
      }
    }

    names(p) <- liste_sta$code_entite
  }

  p
}
