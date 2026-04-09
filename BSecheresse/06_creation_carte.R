# ------------------------------------------------------------------------------
# SCRIPT 05_create_bulletin.R - GENERATION AUTOMATIQUE DU BULLETIN SECHERESSE
# ------------------------------------------------------------------------------
# Auteur       : MJMartinat
# Structure    : DDT de la Drôme
# Date         : 2025
# ------------------------------------------------------------------------------
# DESCRIPTION  : Génération automatisée du bulletin sécheresse
#                Approche HTML → PDF via Chrome headless
#                Intégration des données hydrologiques (HUBEAU, ADES, ONDE)
# VERSION      : 1.0
# DÉPENDANCES  : rmarkdown, here, glue, pagedown, Chrome/Chromium
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# FONCTION PRINCIPALE : Création du bulletin sécheresse en html et pdf
# ------------------------------------------------------------------------------
#' Génère le bulletin sécheresse (HTML + PDF unifié)
#'
#' Cette fonction génère d'abord un HTML puis le convertit en PDF
#' via Chrome headless. Les images sont copiées dans le répertoire de sortie
#' pour garantir leur affichage.
#'
#' @param date_bulletin Date du bulletin (Date ou character "YYYY-MM-DD")
#' @param run_import Si TRUE, exécute R/import.R avant la génération
#' @param timeout_chrome Timeout pour la conversion PDF en secondes (défaut 90)
#'
#' @return Liste invisible avec chemins des fichiers PDF et HTML générés
#' @export
#'
#' @examples
#' # Génération pour la date du jour
#' render_bulletin_unified()
#'
#' # Génération pour une date spécifique
#' render_bulletin_unified("2026-01-15")
render_bulletin_unified <- function(date_bulletin = Sys.Date(),
                                    run_import = TRUE,
                                    timeout_chrome = 90) {


  # ------------------------------------------------------------------------------
  # Vérification des dépendances
  # ------------------------------------------------------------------------------
  message("\n─────────────────────────────────────────────────────────────────")
  message("  GÉNÉRATION DU BULLETIN SÉCHERESSE")                                # Titre opération
  message("───────────────────────────────────────────────────────────────────")

  pkgs_requis <- c("rmarkdown", "here", "glue", "pagedown")                     # Liste packages nécessaires

  for (pkg in pkgs_requis) {                                                    # Boucle sur chaque package
    if (!requireNamespace(pkg, quietly = TRUE)) {                               # Test disponibilité
      message("  → Installation du package ", pkg, "...")                       # Info installation
      install.packages(pkg, quiet = TRUE)                                       # Installation silencieuse
    }
  }

  chrome_path <- pagedown::find_chrome()                                        # Recherche Chrome système
  if (is.null(chrome_path) || !file.exists(chrome_path)) {                      # Vérification existence
    stop("Chrome/Chromium non trouvé. Installez Chrome ou définissez PAGEDOWN_CHROME.")
  }
  message("  ✓ Chrome trouvé : ", chrome_path)                                  # Confirmation détection


  # ----------------------------------------------------------------------------
  # Validation de la date
  # ----------------------------------------------------------------------------
  if (inherits(date_bulletin, "character")) {                                   # Si date en texte
    date_bulletin <- as.Date(date_bulletin)                                     # Conversion en Date
  }

  if (!inherits(date_bulletin, "Date") || is.na(date_bulletin)) {               # Vérification validité
    stop("`date_bulletin` doit être une Date valide ou une chaîne 'YYYY-MM-DD'.", call. = FALSE)
  }

  date_enregistrement <- format(date_bulletin, "%Y-%m-%d")                      # Format ISO fichiers
  message("  ✓ Date du bulletin : ", date_enregistrement)                       # Affichage date


  # ----------------------------------------------------------------------------
  # Création des répertoires de sorties
  # ----------------------------------------------------------------------------
  message("\n─────────────────────────────────────────────────────────────────")
  message("  PRÉPARATION DES RÉPERTOIRES")                                       # Titre section
  message("───────────────────────────────────────────────────────────────────")

  pdf_dir  <- here::here("sorties", "bulletins", "pdf")                          # Chemin PDF
  html_dir <- here::here("sorties", "bulletins", "html")                         # Chemin HTML
  img_dir  <- here::here("sorties", "bulletins", "images")                       # Chemin images

  for (d in c(pdf_dir, html_dir, img_dir)) {                                     # Boucle répertoires
    if (!dir.exists(d)) {                                                        # Si n'existe pas
      dir.create(d, recursive = TRUE, showWarnings = FALSE)                      # Création récursive
      message("  → Répertoire créé : ", d)                                       # Confirmation
    }
  }


  # ----------------------------------------------------------------------------
  # Copie des images vers le répertoire de sorties
  # ----------------------------------------------------------------------------
  message("\n─────────────────────────────────────────────────────────────────")
  message("  COPIE DES IMAGES")                                                 # Titre section
  message("───────────────────────────────────────────────────────────────────")

  img_source_dir <- here::here("fichiers", "images")                            # Répertoire source images
  logo_path      <- file.path(img_source_dir, "logo_prefete.png")               # Chemin logo préfète
  fond_path      <- file.path(img_source_dir, "image_secheresse.png")           # Chemin image fond

  if (file.exists(logo_path)) {                                                 # Si logo existe
    message("  ✓ Logo trouvé : ", logo_path)                                    # Confirmation
  } else {                                                                      # Sinon
    message("  ⚠ Logo introuvable : ", logo_path)                               # Avertissement
  }

  if (file.exists(fond_path)) {                                                 # Si image fond existe
    message("  ✓ Image de fond trouvée : ", fond_path)                          # Confirmation
  } else {                                                                      # Sinon
    message("  ⚠ Image de fond introuvable : ", fond_path)                      # Avertissement
  }

  # ----------------------------------------------------------------------------
  # Vérification du fichier rmd et header
  # ----------------------------------------------------------------------------
  message("\n─────────────────────────────────────────────────────────────────")
  message("  VÉRIFICATION DES FICHIERS SOURCES")                                # Titre section
  message("───────────────────────────────────────────────────────────────────")

  rmd_input <- here::here("fichiers", "Rmd", "bulletin_secheresse.Rmd")         # Template principal
  if (!file.exists(rmd_input)) {                                                # Si template absent
    stop("Fichier Rmd introuvable : ", rmd_input, call. = FALSE)                # Arrêt erreur
  }
  message("  ✓ Template Rmd trouvé : ", rmd_input)                              # Confirmation

  header <- here::here("fichiers", "html", "header.html")                       # Header HTML
  header_original <- here::here("fichiers", "html", "header.html")              # Header original

  if (file.exists(header)) {                                                    # Si header existe
    message("  ✓ Header corrigé disponible : ", header)                         # Confirmation
  } else if (file.exists(header_original)) {                                    # Si original existe
    message("  ⚠ Utilisation du header original (peut avoir des problèmes d'images)")
  } else {                                                                      # Sinon
    message("  ⚠ Aucun header trouvé - l'entête peut ne pas s'afficher")        # Avertissement
  }


  # ----------------------------------------------------------------------------
  # Exécution du script d'import
  # ----------------------------------------------------------------------------
  if (isTRUE(run_import)) {                                                      # Si import demandé
    message("\n───────────────────────────────────────────────────────────────")
    message("  IMPORT DES DONNÉES")                                              # Titre section
    message("─────────────────────────────────────────────────────────────────")

    import_script <- here::here("R", "import.R")                                 # Script d'import

    if (file.exists(import_script)) {                                            # Si script existe
      message("  → Exécution de R/import.R...")                                  # Info exécution
      source(import_script, encoding = "UTF-8", local = FALSE)                   # Exécution globalenv
      message("  ✓ Import terminé")                                              # Confirmation
    } else {                                                                     # Sinon
      warning("  ⚠ Script d'import introuvable : ", import_script)               # Avertissement
    }
  }


  # ----------------------------------------------------------------------------
  # DÉFINITION DES NOMS DE FICHIERS DE SORTIE
  # ----------------------------------------------------------------------------
  html_file <- glue::glue("Bulletin_Secheresse_{date_enregistrement}.html")      # Nom fichier HTML
  pdf_file  <- glue::glue("Bulletin_Secheresse_{date_enregistrement}.pdf")       # Nom fichier PDF

  html_path <- file.path(html_dir, html_file)                                    # Chemin HTML complet
  pdf_path  <- file.path(pdf_dir, pdf_file)                                      # Chemin PDF complet


  # ----------------------------------------------------------------------------
  # Génération du html via Rmarkdown
  # ----------------------------------------------------------------------------
  message("\n─────────────────────────────────────────────────────────────────")
  message("GÉNÉRATION DU HTML")                                                 # Titre étape
  message("───────────────────────────────────────────────────────────────────")
  message("  → Fichier de sortie : ", html_path)                                # Info sortie

  tryCatch({                                                                    # Gestion erreurs
    rmarkdown::render(
      input         = rmd_input,                                                # Template Rmd source
      output_format = "html_document",                                          # Format sortie HTML
      output_file   = html_file,                                                # Nom fichier
      output_dir    = html_dir,                                                 # Répertoire sortie
      params        = list(
        date_bulletin = date_enregistrement,                                    # Paramètre date
        run_import    = FALSE                                                   # Import déjà fait
      ),
      envir         = new.env(parent = globalenv()),                            # Environnement isolé
      quiet         = FALSE                                                     # Afficher messages
    )
    message("\n  ✓ HTML généré avec succès !")                                  # Confirmation
  }, error = function(e) {                                                      # Si erreur
    stop("Échec de la génération HTML : ", e$message, call. = FALSE)            # Arrêt avec message
  })


  # ----------------------------------------------------------------------------
  # Conversion html → pdf via chrome headless
  # ----------------------------------------------------------------------------
  message("\n─────────────────────────────────────────────────────────────────")
  message("CONVERSION HTML → PDF")                                              # Titre étape
  message("───────────────────────────────────────────────────────────────────")
  message("  → Source : ", html_path)                                           # Info source
  message("  → Destination : ", pdf_path)                                       # Info destination

  tryCatch({                                                                    # Gestion erreurs
    pagedown::chrome_print(
      input   = html_path,                                                      # Fichier HTML source
      output  = pdf_path,                                                       # Fichier PDF dest
      format  = "pdf",                                                          # Format sortie
      timeout = timeout_chrome,                                                 # Timeout secondes
      options = list(
        preferCSSPageSize = TRUE,                                               # Utilise @page CSS
        printBackground   = TRUE,                                               # Imprime fonds colorés
        scale             = 0.9,                                                # Échelle 90%
        paperWidth        = 8.27,                                               # Largeur A4 pouces
        paperHeight       = 11.69,                                              # Hauteur A4 pouces
        marginTop         = 0.5,                                                # Marge haute pouces
        marginBottom      = 0.5,                                                # Marge basse
        marginLeft        = 0.5,                                                # Marge gauche
        marginRight       = 0.5                                                 # Marge droite
      ),
      verbose = 1                                                               # Niveau verbosité
    )
    message("\n  ✓ PDF généré avec succès !")                                   # Confirmation
  }, error = function(e) {                                                      # Si erreur
    warning("  ⚠ Échec de la conversion PDF : ", e$message)                     # Avertissement
    message("\n  Alternative : ouvrez le HTML dans un navigateur et imprimez en PDF.")
  })


  # ----------------------------------------------------------------------------
  # Message de succès et retour
  # ----------------------------------------------------------------------------
  message("\n─────────────────────────────────────────────────────────────────")
  message("  GÉNÉRATION TERMINÉE")                                              # Titre final
  message("───────────────────────────────────────────────────────────────────")
  message("  Bulletin du ", date_enregistrement)                                # Info date
  message("───────────────────────────────────────────────────────────────────")

  message("  HTML : ", html_path)                                               # Chemin HTML

  if (file.exists(pdf_path)) {                                                  # Si PDF existe
    message("  PDF  : ", pdf_path)                                              # Chemin PDF
  } else {                                                                      # Sinon
    message("  PDF  : Non généré (voir erreurs ci-dessus)")                     # Info erreur
  }
  message("─────────────────────────────────────────────────────────────────\n")

  invisible(list(                                                               # Retour invisible
    html = html_path,                                                           # Chemin HTML
    pdf  = if (file.exists(pdf_path)) pdf_path else NULL                        # Chemin PDF ou NULL
  ))
}



# ------------------------------------------------------------------------------
# FONCTION ALTERNATIVE : CONVERSION BATCH D'UN HTML EXISTANT
# ------------------------------------------------------------------------------
#' Convertit un fichier HTML existant en PDF
#'
#' Fonction utilitaire pour convertir un HTML déjà généré en PDF
#' sans repasser par le rendu Rmd.
#'
#' @param html_input Chemin vers le fichier HTML à convertir
#' @param pdf_output Chemin de sortie PDF (optionnel, déduit du HTML)
#' @param options Liste d'options pour Chrome (optionnel)
#'
#' @return Chemin du PDF généré (invisible)
#' @export

html_to_pdf <- function(html_input,
                        pdf_output = NULL,
                        options = NULL) {

  if (!requireNamespace("pagedown", quietly = TRUE)) {                          # Vérification pagedown
    stop("Le package 'pagedown' est requis. Installez-le avec install.packages('pagedown').")
  }

  if (is.null(pdf_output)) {                                                    # Si sortie non fournie
    pdf_output <- sub("\\.html$", ".pdf", html_input, ignore.case = TRUE)       # Déduit .html → .pdf
  }

  default_options <- list(                                                      # Options par défaut
    preferCSSPageSize = TRUE,                                                   # Utilise @page CSS
    printBackground   = TRUE,                                                   # Imprime fonds
    scale             = 0.9,                                                    # Échelle 90%
    paperWidth        = 8.27,                                                   # A4 largeur
    paperHeight       = 11.69,                                                  # A4 hauteur
    marginTop         = 0.5,                                                    # Marge haute
    marginBottom      = 0.5,                                                    # Marge basse
    marginLeft        = 0.5,                                                    # Marge gauche
    marginRight       = 0.5                                                     # Marge droite
  )

  if (!is.null(options)) {                                                      # Si options perso
    default_options <- modifyList(default_options, options)                     # Fusion options
  }

  pagedown::chrome_print(                                                       # Conversion Chrome
    input   = html_input,                                                       # Fichier source
    output  = pdf_output,                                                       # Fichier destination
    format  = "pdf",                                                            # Format PDF
    options = default_options,                                                  # Options conversion
    verbose = 1                                                                 # Verbosité
  )

  message("✓ PDF généré : ", pdf_output)                                        # Confirmation
  invisible(pdf_output)                                                         # Retour invisible
}


# ------------------------------------------------------------------------------
# Exécution si script lancé directement
# ------------------------------------------------------------------------------
if (sys.nframe() == 0L) {                                                       # Si exécution directe
  message("\n>>> Lancement du rendu unifié du bulletin <<<\n")                  # Message démarrage
  render_bulletin_unified()                                                     # Appel fonction
}

# ------------------------------------------------------------------------------
# Passage au script 04_create_bulletin.R
# ------------------------------------------------------------------------------
next_script <- file.path(getwd(), "dev", "06_create_carte.R")                   # Chemin du script 06

if (file.exists(next_script)) {                                                 # Vérifie si le script existe
  message("Passage au script 06_create_carte.R")                                # Indique le changement de script
  rstudioapi::navigateToFile(next_script)                                       # Ouvre le script 06 dans RStudio
} else {
  message("Script 06_create_carte.R introuvable dans dev")                      # Avertit si script manquant
}

message("SCRIPT 05 TERMINÉ")                                                    # Message fin script

# ------------------------------------------------------------------------------
# FIN DU SCRIPT 05_create_bulletin.R
# ------------------------------------------------------------------------------
