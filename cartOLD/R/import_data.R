# ──────────────────────────────────────────────────────────────────────────────
# FICHIER     : R/fct_import_data.R
# AUTEUR      : MJ Martinat
# DATE        : 2025
# ORGANISATION: DDT de la Drome
# DESCRIPTION : Chargement optimise des donnees GeoParquet
#               Chargement progressif par commune pour les couches lourdes
# ──────────────────────────────────────────────────────────────────────────────
# FONCTION DE RECHERCHE SECURISEE DES FICHIERS
# ──────────────────────────────────────────────────────────────
#' Rechercher securisee d un fichier dans plusieurs repertoires potentiels
#'
#' Cette fonction permet de rechercher un fichier dans plusieurs chemins
#' standards utilises par un package {golem} ou une application Shiny packagee.
#' Elle gere automatiquement les sous-dossiers et verifie tous les emplacements
#' pertinents jusqu’a trouver le fichier.
#'
#' @param filename Nom du fichier recherche (ex : `"communes.parquet"`).
#' @param subdir Sous-dossier optionnel où se trouve le fichier (ex : `"parcelles"`).
#'
#' @return Le chemin absolu du fichier trouve.
#'
#' @keywords internal
#'
#' @export
safe_path <- function(filename, subdir = NULL) {                                # Fonction de recherche multi-chemins

  if (!is.null(subdir)) {                                                       # Si un sous-dossier est fourni
    filename <- file.path(subdir, filename)                                     # Ajout du sous-dossier au chemin
  }

  paths <- c(                                                                   # Vecteur de chemins possibles
    app_sys(file.path("app/extdata", filename)),                                # Chemin interne {golem} via app_sys()
    file.path("inst/app/extdata", filename),                                    # Chemin dans l'arborescence installee du package
    file.path("app/extdata", filename),                                         # Chemin pour execution locale non installee
    file.path("extdata", filename)                                              # Chemin alternatif pour compatibilite
  )

  for (p in paths) {                                                            # Boucle sur la liste des chemins testes
    if (file.exists(p)) {                                                       # Si le fichier existe a cet emplacement
      message("→ Trouve : ", p)                                                 # Message utilisateur
      return(p)                                                                 # Retour du chemin trouve
    }
  }

  stop(                                                                         # Si aucun chemin ne contient le fichier → erreur
    "Fichier introuvable : ", filename,                                         # Message principal
    "\n   Chemins testes :\n   - ", paste(paths, collapse = "\n   - ")          # Liste des chemins testes
  )
}                                                                               # Fin fonction

# ──────────────────────────────────────────────────────────────
# FONCTION DE CHARGEMENT UNITAIRE AVEC VALIDATION
# ──────────────────────────────────────────────────────────────
#' Charger un fichier Parquet contenant des geometries sf, avec
#' gestion d'erreurs
#'
#' Cette fonction tente de charger un fichier GeoParquet via
#' `sfarrow::st_read_parquet`. Elle applique un mecanisme de
#' gestion d'erreurs robuste (`tryCatch`) afin d’eviter les
#' interruptions en cas de fichier manquant, corrompu ou illisible.
#' Une serie de validations est appliquee pour s’assurer que :
#' - le fichier existe,
#' - l objet retourne n est pas NULL,
#' - l’objet contient au moins une entite.
#'
#' @param filename Nom du fichier Parquet (ex : `"communes.parquet"`).
#' @param nom Nom descriptif a afficher dans les messages utilisateur.
#' @param subdir Sous-dossier eventuel où se trouve le fichier.
#'
#' @return Un objet `sf` si succes, sinon `NULL` sans interruption du flux.
#'
#' @keywords internal
#'
#' @export
charger <- function(filename, nom, subdir = NULL) {                             # Fonction de chargement avec validation
  tryCatch({                                                                    # Gestion securisee des erreurs

    path <- safe_path(filename, subdir)                                         # Resolution du chemin via safe_path()
    obj  <- sfarrow::st_read_parquet(path)                                      # Lecture du fichier Parquet en sf

    # ── Validations de base ──────────────────────────────────
    if (is.null(obj)) {                                                         # Verifie si l'objet n'est pas NULL
      warning("Attention! ", nom, " est NULL")                                  # Avertissement utilisateur
      return(NULL)                                                              # Retour anticipe
    }

    if (nrow(obj) == 0) {                                                       # Verifie qu il y a au moins une ligne
      warning("Attention! ", nom, " est vide (0 entites)")                      # Message si objet vide
      return(NULL)                                                              # Retour securitaire
    }

    message("OK ", nom, " : ", nrow(obj), " entites")                           # Message succes avec nombre d'entites
    return(obj)                                                                 # Retourne l'objet sf charge

  }, error = function(e) {                                                      # Si une erreur survient
    warning("Stop! Erreur chargement '", nom, "' : ", e$message)                # Message d’erreur informatif
    return(NULL)                                                                # Retourne NULL pour rester robuste
  })
}                                                                               # Fin fonction charger()

# ──────────────────────────────────────────────────────────────
# FONCTION D IMPORTATION PRINCIPALE (DONNEES DE BASE UNIQUEMENT)
# ──────────────────────────────────────────────────────────────
#' Importer les couches geographiques de base
#'
#' Cette fonction charge uniquement les couches legeres necessaires
#' au demarrage de l'application (departement, communes, OLD200, etc.).
#'
#' Les couches lourdes (parcelles, bâtiments, OLD50m, ZU) sont
#' volontairement initialisees a `NULL` :
#' elles seront chargees dynamiquement et a la demande via
#' `charger_couche_commune()`, afin d'accelerer le demarrage
#' et reduire la consommation memoire.
#'
#' @return Une liste nommee d'objets `sf` (ou `NULL` pour les couches non prechargees)
#'
#' @export
import_data <- function() {                                                     # Fonction d importation des couches de base
  message("\nChargement des donnees geographiques...\n")                        # Message d information a l utilisateur

  list(                                                                         # Retour sous forme de liste nommee
    # Couches legeres : chargees immediatement
    departement     = charger("departement.parquet", "Departement"),            # Departements (leger)
    communes        = charger("communes.parquet", "Communes"),                  # Communes (leger)
    old200          = charger("old200.parquet", "OLD200"),                      # OLD 200m (leger)
    communes_old200 = charger("communes_old200.parquet", "Communes OLD200"),    # Communes intersectees OLD200

    # Couches lourdes : NULL au demarrage, chargement a la demande
    parcelles_all   = NULL,                                                     # Parcelles cadastrales (tres lourd)
    batis_all       = NULL,                                                     # Bâtiments (lourd)
    old50m_all      = NULL,                                                     # OLD 50m (lourd + gradient)
    zu_all          = NULL                                                      # Zonage urbain PLU (taille variable)
  )                                                                             # Fin liste
}                                                                               # Fin fonction import_data()

# ──────────────────────────────────────────────────────────────
# FONCTION DE CHARGEMENT PAR COMMUNE (COUCHES LOURDES)
# ──────────────────────────────────────────────────────────────
#' Charge une couche geographique lourde pour une commune donnee
#'
#' Cette fonction permet de charger dynamiquement une couche lourde
#' (parcelles, bâtiments, OLD50m, zonage urbain) pour une commune specifique.
#'
#' Le nom du fichier Parquet est construit automatiquement a partir de l’IDU
#' communal (format DGFIP, ex. `1` → `26001`).
#' La fonction ne charge que la commune demandee pour limiter l’usage memoire
#' et optimiser les performances sur shinyapps.io.
#'
#' @param couche Nom de la couche : `"parcelles"`, `"batis"`, `"old50m"`, `"zu"`.
#' @param idu Code numerique de la commune (ex. `"1"` pour 26001).
#'
#' @return Un objet `sf` contenant la geometrie de la commune, ou `NULL` si erreur
#'         ou absence de donnees.
#'
#' @examples
#' \dontrun{
#'   parcelles_drome <- charger_couche_commune("parcelles", "1")
#'   batis_valence   <- charger_couche_commune("batis", "362")
#' }
#'
#' @export
charger_couche_commune <- function(couche, idu) {                               # Fonction de chargement cible par commune

  # ── Validation de la couche ─────────────────────────────────
  couches_valides <- c("parcelles", "batis", "old50m", "zu")                    # Liste des couches autorisees
  if (!couche %in% couches_valides) {                                           # Verifie la validite du parametre 'couche'
    stop("Couche invalide. Choisir parmi : ", paste(couches_valides, collapse = ", "))  # Erreur si couche inconnue
  }

  # ── Construction du nom de fichier ──────────────────────────
  prefixe  <- paste0("26", sprintf("%03d", as.numeric(idu)))                    # Construit le code communal complet (ex. "26001")
  filename <- paste0(prefixe, ".parquet")                                       # Nom du fichier Parquet attendu

  # ── Chargement ──────────────────────────────────────────────
  tryCatch({                                                                    # Bloc tryCatch pour une gestion robuste des erreurs

    path <- safe_path(filename, subdir = couche)                                # Trouve le chemin complet du fichier dans le sous-dossier
    obj  <- sfarrow::st_read_parquet(path)                                      # Lecture GeoParquet en sf

    if (!is.null(obj) && nrow(obj) > 0) {                                       # Verifie que des entites ont ete chargees
      message(sprintf(                                                          # Message succes
        "   ✓ %s : %d entite(s) chargee(s) pour la commune %s",
        couche, nrow(obj), prefixe
      ))
      return(obj)                                                               # Retour de l'objet sf
    } else {
      message(sprintf(                                                          # Message absence de donnees
        "   Attention! %s : aucune donnee pour la commune %s",
        couche, prefixe
      ))
      return(NULL)                                                              # Retour NULL si vide
    }

  }, error = function(e) {                                                      # Gestion des erreurs lors de la lecture ou du chemin
    message(sprintf(                                                            # Affiche l’erreur detaillee
      "   Stop! Erreur chargement %s pour commune %s : %s",
      couche, prefixe, e$message
    ))
    return(NULL)                                                                # Retour securitaire
  })
}                                                                               # Fin fonction

# ──────────────────────────────────────────────────────────────
# FONCTION DE CHARGEMENT MULTIPLE PAR COMMUNE
# ──────────────────────────────────────────────────────────────
#' Charge toutes les couches lourdes pour une commune
#'
#' Cette fonction charge en une seule operation l’ensemble des couches lourdes
#' disponibles pour une commune donnee :
#' - parcelles cadastrales
#' - bâtiments
#' - OLD50m (zone a debroussailler)
#' - zonage urbain (PLU/ZU)
#'
#' Chaque couche est chargee via `charger_couche_commune()`, ce qui assure :
#' - un chargement cible (reduit la RAM),
#' - un systeme d'erreur robuste,
#' - un comportement coherent dans l’ensemble du package.
#'
#' @param idu Identifiant de la commune (ex : `"1"` pour la commune 26001).
#'
#' @return Une liste nommee contenant : `parcelles`, `batis`, `old50m`, `zu`.
#'
#' @examples
#' \dontrun{
#'   donnees_commune <- charger_commune_complete("1")
#'   parcelles <- donnees_commune$parcelles
#' }
#'
#' @export
charger_commune_complete <- function(idu) {                                     # Fonction de chargement multiple
  message(sprintf("\n Chargement des donnees pour la commune 26%03d...",        # Message d'information a l'utilisateur
                  as.numeric(idu)))

  list(                                                                         # Retour sous forme de liste nommee
    parcelles = charger_couche_commune("parcelles", idu),                       # Chargement parcelles (lourd)
    batis     = charger_couche_commune("batis", idu),                           # Chargement bâtiments
    old50m    = charger_couche_commune("old50m", idu),                          # Chargement OLD50m
    zu        = charger_couche_commune("zu", idu)                               # Chargement ZU (zonage urbain)
  )                                                                             # Fin liste
}                                                                               # Fin fonction charger_commune_complete()

# ──────────────────────────────────────────────────────────────
# FONCTION DE CHARGEMENT MULTIPLE POUR PLUSIEURS COMMUNES
# ──────────────────────────────────────────────────────────────
#' Charge une couche geographique pour plusieurs communes et fusionne les resultats
#'
#' Cette fonction charge successivement une couche lourde (parcelles, bâtiments,
#' OLD50m ou ZU) pour un ensemble de communes, puis fusionne les objets `sf`
#' obtenus en un seul objet final via `rbind`.
#'
#' Les communes sans donnees valides sont ignorees automatiquement.
#'
#' @param couche Nom de la couche a charger : `"parcelles"`, `"batis"`,
#' `"old50m"`, ou `"zu"`.
#' @param idus Vecteur d'identifiants de communes (format DGFIP simplifie).
#'
#' @return Un objet `sf` fusionne contenant l'ensemble des entites des communes
#'
#' @examples
#' \dontrun{
#'   # Charger les parcelles de trois communes
#'   parcelles <- charger_couche_communes("parcelles", c("1", "2", "3"))
#' }
#'
#' @export
charger_couche_communes <- function(couche, idus) {                             # Fonction pour fusionner plusieurs communes

  message(sprintf("\n Chargement de %s pour %d commune(s)...",                  # Message utilisateur : debut chargement
                  couche, length(idus)))

  resultat_list <- list()                                                       # Liste qui va contenir les objets sf des communes
  success_count <- 0                                                            # Compteur de communes chargees avec succes

  for (idu in idus) {                                                           # Boucle sur toutes les communes du vecteur idus
    obj <- charger_couche_commune(couche, idu)                                  # Chargement individuel via fonction dediee

    if (!is.null(obj) && nrow(obj) > 0) {                                       # Verifie qu’un objet non vide a ete charge
      resultat_list[[length(resultat_list) + 1]] <- obj                         # Ajout a la liste des resultats
      success_count <- success_count + 1                                        # Increment du compteur de succes
    }
  }

  # ── Fusion des resultats  ───────────────────────────────────
  if (length(resultat_list) > 0) {                                              # On fusionne uniquement si au moins un resultat existe
    resultat <- do.call(rbind, resultat_list)                                   # Fusion sf par rbind
    message(sprintf("Ok! %s : %d commune(s) chargee(s), %d entite(s) total",    # Message succes avec details
                    couche, success_count, nrow(resultat)))
    return(resultat)                                                            # Retour de l objet fusionne
  } else {
    message(sprintf("   Attention! Aucune donnee chargee pour %s", couche))     # Message si aucune donnee n a ete chargee
    return(NULL)                                                                # Retour NULL pour rester coherent
  }
}                                                                               # Fin fonction

# ──────────────────────────────────────────────────────────────
# VERSION CACHEE AVEC MEMOISE
# ──────────────────────────────────────────────────────────────
#' Importer les donnees avec mise en cache
#'
#' Cette version utilise `memoise::memoise` pour eviter de recharger les
#' donnees a chaque appel.
#'
#' Premier appel :
#'    - charge reellement les donnees via `import_data()`
#'
#' Appels suivants :
#'    - renvoie immediatement la version en cache (RAM),
#'    - reduction drastique du temps de chargement,
#'    - ideal sur shinyapps.io où l’I/O disque est lent.
#'
#' @return Une liste nommee d'objets `sf`, identique a `import_data()`.
#'
#' @export
import_data_cached <- memoise::memoise(import_data)                             # Version memorisee en RAM de import_data()

#' Version cachee du chargement d'une couche par commune
#'
#' Cette version memoïsee de `charger_couche_commune()` permet :
#' - d eviter les relectures repetees d’un meme fichier Parquet pour une commune,
#' - d accelerer les interactions utilisateur (ex : navigation commune → commune → retour),
#' - de reduire la charge disque sur shinyapps.io.
#'
#' @param couche Nom de la couche ("parcelles", "batis", "old50m", "zu").
#' @param idu Identifiant de la commune (ex. `"1"` → 26001).
#'
#' @return Un objet `sf` ou `NULL` selon les donnees disponibles.
#' @export
charger_couche_commune_cached <- memoise::memoise(charger_couche_commune)       # Mise en cache des appels individuels par commune

# ──────────────────────────────────────────────────────────────
# FONCTION UTILITAIRE : LISTE DES COMMUNES DISPONIBLES
# ──────────────────────────────────────────────────────────────
#' Lister les communes disponibles pour une couche donnee
#'
#' Recherche dans les repertoires standards (compatibles {golem} et
#' installation du package) l'ensemble des fichiers `.parquet` d'une couche.
#'
#' Les fichiers attendus ont le format :
#'
#' **26XXX.parquet**
#'
#' où `XXX` correspond au code IDU simplifie (1 → 001, 12 → 012, etc.).
#'
#' La fonction retourne la liste triee des IDU disponibles.
#'
#' @param couche Nom de la couche : `"parcelles"`, `"batis"`, `"old50m"`, `"zu"`.
#'
#' @return Un vecteur numerique contenant les IDU disponibles.
#'         Retourne `numeric(0)` si aucun dossier trouve.
#'
#' @export
lister_communes_disponibles <- function(couche) {                               # Fonction listant les IDU disponibles

  couches_valides <- c("parcelles", "batis", "old50m", "zu")                    # Couches autorisees
  if (!couche %in% couches_valides) {                                           # Validation de l'argument 'couche'
    stop("Couche invalide. Choisir parmi : ", paste(couches_valides, collapse = ", "))  # Erreur si couche inconnue
  }

  # Chemins possibles
  paths <- c(                                                                   # Emplacements possibles selon installation
    app_sys(file.path("app/extdata", couche)),                                  # Repertoire interne golem installe
    file.path("inst/app/extdata", couche),                                      # Repertoire inst/ lors du build
    file.path("app/extdata", couche),                                           # Repertoire local de developpement
    file.path("extdata", couche)                                                # Repertoire alternatif
  )

  for (p in paths) {                                                            # Teste chaque chemin
    if (dir.exists(p)) {                                                        # Si le dossier existe
      files <- list.files(p, pattern = "\\.parquet$", full.names = FALSE)       # Liste les fichiers .parquet
      idus  <- gsub("26(\\d{3})\\.parquet", "\\1", files)                       # Extraction des 3 chiffres IDU
      idus  <- as.numeric(idus)                                                 # Conversion en numerique
      return(sort(idus))                                                        # Retour trie
    }
  }

  warning("Dossier introuvable pour la couche : ", couche)                      # Avertissement si aucun chemin valide
  return(numeric(0))                                                            # Retour vecteur vide
}                                                                               # Fin fonction

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU FICHIER
# ──────────────────────────────────────────────────────────────────────────────
