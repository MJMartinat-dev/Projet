# ──────────────────────────────────────────────────────────────────────────────
# SCRIPT      : data-raw/pre_data_parquet.R
# AUTEUR      : Marie-Jeanne MARTINAT
# STRUCTURE   : DDT de la Drôme
# DATE        : 2025
# OBJET       : Export PostgreSQL → GeoParquet avec transformation WGS84
#               Version sans simplification des geometries
# ──────────────────────────────────────────────────────────────────────────────
# ACTIVATION DES LIBRAIRIES
# ──────────────────────────────────────────────────────────────
library(DBI)                                                                    # Chargement du package DBI pour interface générique BD
library(RPostgres)                                                              # Driver PostgreSQL natif
library(sf)                                                                     # Gestion des objets spatiaux et transformations CRS
library(sfarrow)                                                                # Import / export GeoParquet optimisé
library(dplyr)                                                                  # Manipulation de données

# ──────────────────────────────────────────────────────────────
# FONCTION DE TRANSFORMATION MINIMALE WGS84
# ──────────────────────────────────────────────────────────────
#' Transforme en WGS84 sans modifier les géométries
#'
#' @param data Objet sf
#'
#' @param nom Nom pour les messages (optionnel)
#'
#' @return Objet sf en WGS84
#'
#' @importFrom sf st_crs st_transform
#'
#' @noRd
transformer_wgs84 <- function(data, nom = "couche") {                           # Debut fonction transformation CRS

  # ── Forcer Lambert 93 si CRS manquant ───────────────────────
  if (is.na(sf::st_crs(data))) {                                                # Si aucun systeme de coordonnees defini
    sf::st_crs(data) <- 2154                                                    # Définit EPSG:2154 (Lambert 93)
  }

  # ── Si pas en Lambert 93, transformer d abord ───────────────
  if (st_crs(data)$epsg != 2154) {                                              # Si CRS different de 2154
    data <- sf::st_transform(data, 2154)                                        # Transforme d abord en Lambert 93
  }

  # ── Transformation WGS84 DIRECTE (sans modification) ────────
  data <- sf::st_transform(data, 4326)                                          # Transforme en WGS84 (EPSG:4326)

  # ── Verification ────────────────────────────────────────────
  bbox <- sf::st_bbox(data)                                                     # Recupere la bounding box
  if (bbox["xmin"] > 100 || bbox["xmin"] < -180) {                              # Verifie coherence longitudes WGS84
    stop(sprintf("ERREUR %s : Transformation WGS84 ÉCHOUÉE ! Bbox: [%.2f, %.2f]",
                 nom, bbox["xmin"], bbox["ymin"]))                              # Stop si coordonnees incoherentes
  }

  # ── Confirmation ────────────────────────────────────────────
  cat(sprintf("   ✓ WGS84 OK : [%.2f, %.2f] - [%.2f, %.2f]\n",
              bbox["xmin"], bbox["ymin"], bbox["xmax"], bbox["ymax"]))          # Affiche confirmation bbox

  return(data)                                                                  # Renvoie l objet sf transforme
}                                                                               # Fin fonction transformer_wgs84

# ──────────────────────────────────────────────────────────────
# CONNEXION POSTGRESQL
# ──────────────────────────────────────────────────────────────
cat("Connexion à PostgreSQL...\n")                                              # Message d information utilisateur
readRenviron(".Renviron")                                                       # Charge les variables d environnement locales

con <- DBI::dbConnect(                                                          # Connexion PostgreSQL via RPostgres
  RPostgres::Postgres(),                                                        # Driver utilise
  host     = "localhost",                                                       # Hote PostgreSQL
  port     = 5432,                                                              # Port standard PostgreSQL
  dbname   = "old_dev",                                                         # Nom de la base de donnees
  user     = Sys.getenv("PG_USER"),                                             # Recuperation identifiant via .Renviron
  password = Sys.getenv("PG_PASSWORD")                                          # Recuperation mot de passe via .Renviron
)                                                                               # Fin dbConnect

# ──────────────────────────────────────────────────────────────
# CREATION DES DOSSIERS
# ──────────────────────────────────────────────────────────────
dir.create("inst/app/extdata", recursive = TRUE, showWarnings = FALSE)          # Cree le dossier principal extdata
dir.create("inst/app/extdata/parcelles", showWarnings = FALSE)                  # Sous-dossier pour les parcelles par commune
dir.create("inst/app/extdata/batis", showWarnings = FALSE)                      # Sous-dossier pour les batiments par commune
dir.create("inst/app/extdata/old50m", showWarnings = FALSE)                     # Sous-dossier pour les resultats OLD50m par commune
dir.create("inst/app/extdata/zu", showWarnings = FALSE)                         # Sous-dossier pour les zonages urbains par commune

# ──────────────────────────────────────────────────────────────
# DEPARTEMENT
# ──────────────────────────────────────────────────────────────
cat("\nExport : departement.parquet...\n")                                      # Message debut export departement

departement <- sf::st_read(                                                     # Lecture BD → sf
  con,                                                                          # Connexion PostgreSQL active
  query = "SELECT * FROM r_bdtopo.departement WHERE code_insee = '26'",         # Requete SQL : departement 26 uniquement
  quiet = TRUE                                                                  # Pas de messages bruites sf
)

departement <- transformer_wgs84(departement, nom = "departement")              # Transformation CRS → WGS84 avec controle bbox

sfarrow::st_write_parquet(departement, "inst/app/extdata/departement.parquet")  # Export GeoParquet dans extdata

cat(sprintf(" %d entité(s), %.2f MB\n\n",                                       # Résumé taille & nb entites
            nrow(departement),
            file.size("inst/app/extdata/departement.parquet") / 1024^2))

rm(departement)                                                                 # Libération memoire objet
gc()                                                                            # Garbage-collector

# ──────────────────────────────────────────────────────────────
# COMMUNES
# ──────────────────────────────────────────────────────────────
cat("Export : communes.parquet...\n")                                           # Message debut export communes

communes <- sf::st_read(                                                        # Lecture des communes
  con,
  query = "SELECT idu, tex2, geom FROM r_cadastre.geo_commune",                 # Requête SQL : attributs utiles + geometrie
  quiet = TRUE
)

# Version Lambert pour intersections
communes_lambert <- communes                                                    # Copie pour conserver version Lambert
if (is.na(sf::st_crs(communes_lambert))) sf::st_crs(communes_lambert) <- 2154   # Forçage CRS si absent → EPSG:2154 (Lambert 93)

communes <- transformer_wgs84(communes, nom = "communes")                       # Transformation pour export → WGS84

sfarrow::st_write_parquet(communes, "inst/app/extdata/communes.parquet")        # Export GeoParquet

cat(sprintf(" %d entité(s), %.2f MB\n\n",                                       # Résumé export
            nrow(communes),
            file.size("inst/app/extdata/communes.parquet") / 1024^2))

rm(communes)                                                                    # Nettoyage RAM
gc()                                                                            # Garbage-collector

# ──────────────────────────────────────────────────────────────
# OLD200
# ──────────────────────────────────────────────────────────────
cat("Export : old200.parquet...\n")                                             # Message debut export OLD200

old200 <- sf::st_read(                                                          # Lecture couche OLD200
  con,
  query = "SELECT geom FROM public.old200m",                                    # Requête SQL : geometrie uniquement
  quiet = TRUE
)

# Version Lambert pour intersections
old200_lambert <- old200                                                        # Copie pour calculs spatiaux ulterieurs
if (is.na(st_crs(old200_lambert))) st_crs(old200_lambert) <- 2154               # Forçage CRS si manquant → EPSG:2154

old200 <- transformer_wgs84(old200, nom = "old200")                             # Transformation WGS84

sfarrow::st_write_parquet(old200, "inst/app/extdata/old200.parquet")            # Export GeoParquet

cat(sprintf(" %d entité(s), %.2f MB\n\n",                                       # Résumé export
            nrow(old200),
            file.size("inst/app/extdata/old200.parquet") / 1024^2))

rm(old200)                                                                      # Nettoyage mémoire
gc()                                                                            # Garbage-collector


# ──────────────────────────────────────────────────────────────
# COMMUNES_OLD200
# ──────────────────────────────────────────────────────────────
cat("Calcul : communes_old200.parquet...\n")                                    # Affiche un message indiquant le début du traitement

# ── Intersection spatiale entre communes et OLD200 en Lambert 93
communes_inter <- sf::st_intersection(communes_lambert, old200_lambert)         # Calcule les intersections spatiales entre les communes et la couche OLD200

# ── Calcul du ratio surface OLD/intersection ──────────────────
communes_inter$ratio <- as.numeric(sf::st_area(communes_inter)) /               # Calcule la surface de l'intersection
  as.numeric(sf::st_area(sf::st_geometry(                                       # Divise par la surface de la commune d'origine
    communes_lambert[match(communes_inter$idu, communes_lambert$idu), ]         # Récupère la commune correspondante via IDU
  )))                                                                           # Permet de connaître la proportion de la commune couverte

# ── Filtre : garde uniquement communes touchees >1% surface ──
communes_filtrees <- communes_inter[communes_inter$ratio > 0.01, ]              # Selectionne uniquement les communes ayant plus de 1% d intersection

# ── IMPORTANT : Recuperer les geometries des communes originales
# On fait une jointure avec les communes originales pour garder leurs geometries
communes_old200 <- communes_lambert[                                            # Recupere les communes d origine
  match(communes_filtrees$idu, communes_lambert$idu),                           # En utilisant les IDU filtres
] %>%                                                                           # Puis applique les transformations suivantes :
  dplyr::distinct(idu, tex2, .keep_all = TRUE) %>%                              # Supprime les doublons en conservant tous les attributs
  dplyr::arrange(idu)                                                           # Trie par IDU croissant

# ── Nettoyage des donnees : suppression des doublons et tri ──
communes_old200 <- communes_old200[!duplicated(communes_old200$idu), ]          # Supprime les doublons bases sur l IDU

# ── Conversion finale en WGS84 ───────────────────────────────
communes_old200 <- transformer_wgs84(communes_old200, nom = "communes_old200")  # Convertit les coordonnees en WGS84 (GPS)

# ── Export au format Parquet ─────────────────────────────────
sfarrow::st_write_parquet(communes_old200, "inst/app/extdata/communes_old200.parquet")     # Exporte le résultat au format Parquet

# ── Affiche info : nombre entites + taille fichier ───────────
cat(sprintf(" %d commune(s), %.2f MB\n\n",                                      # Affiche le nombre de communes et la taille du fichier
            nrow(communes_old200),
            file.size("inst/app/extdata/communes_old200.parquet") / 1024^2))

# ── Liste des communes a traiter ─────────────────────────────
communes_list <- communes_old200 %>%                                            # Base : communes OLD200 retenues
  sf::st_drop_geometry() %>%                                                    # Supprime geometrie
  select(idu) %>%                                                               # Ne garde que l IDU
  dplyr::arrange(idu)                                                           # Trie par commune

cat(sprintf("%d commune(s) à traiter pour les couches lourdes\n\n",             # Message console
            nrow(communes_list)))

# ── Nettoyage memoire : suppression objets lourds ────────────
rm(communes_lambert, old200_lambert, communes_inter)                            # Libere la memoire des objets inutiles
gc()                                                                            # Garbage collector : libere la RAM

# ──────────────────────────────────────────────────────────────
# PARCELLES (PAR COMMUNE)
# ──────────────────────────────────────────────────────────────
cat("Export : parcelles/ (par commune)...\n")                                   # Message console : debut export parcelles

success_count <- 0                                                              # Compteur succes
error_count <- 0                                                                # Compteur erreurs
total_size <- 0                                                                 # Accumulation taille fichiers exportes

for (i in seq_len(nrow(communes_list))) {                                       # Boucle sur chaque commune selectionnee
  idu <- communes_list$idu[i]                                                   # IDU de la commune courante
  prefixe <- paste0("26", sprintf("%03d", as.numeric(idu)))                     # Code INSEE complet (ex : 26001)
  table_name <- paste0(prefixe, "_parcelle")                                    # Nom table SQL (stockée par commune)

  tryCatch({                                                                    # Securisation : capture erreurs SQL ou lecture

    parcelle <- st_read(                                                        # Lecture depuis PostgreSQL
      con,
      query = sprintf('SELECT * FROM "26_old50m_parcelle"."%s"', table_name),   # Requete dynamique (table par commune)
      quiet = TRUE                                                              # Pas de messages sf
    )

    parcelle$commune_idu <- idu                                                 # Ajout IDU pour tracking dans l app

    # ── Transformation ────────────────────────────────────────
    parcelle <- transformer_wgs84(parcelle, nom = prefixe)                      # Passage Lambert → WGS8

    output_file <- sprintf("inst/app/extdata/parcelles/%s.parquet", prefixe)    # Chemin de sortie Parquet
    sfarrow::st_write_parquet(parcelle, output_file)                            # Export parquet optimise

    total_size <- total_size + file.size(output_file)                           # Ajout taille fichier produit
    success_count <- success_count + 1                                          # Increment succes

    if (i %% 10 == 0) {                                                         # Message progression tous les 10 exports
      cat(sprintf("   Progression : %d / %d\n", i, nrow(communes_list)))
    }

  }, error = function(e) {                                                      # En cas d erreur SQL / sf
    cat(sprintf("Erreur %s : %s\n", prefixe, e$message))                        # Message erreur détaillé
    error_count <- error_count + 1                                              # Incrément compteur erreurs
  })
}

cat(sprintf("\n   Succès : %d / %d commune(s), %.2f MB\n",                      # Rapport final export
            success_count, nrow(communes_list), total_size / 1024^2))

if (error_count > 0) {                                                          # Si erreurs sur certaines communes
  cat(sprintf("   Erreurs : %d commune(s)\n", error_count))
}
cat("\n")                                                                       # Saut de ligne

gc()                                                                            # Garbage collector pour libérer la mémoire

# ──────────────────────────────────────────────────────────────
# BÂTIMENTS (PAR COMMUNE)
# ──────────────────────────────────────────────────────────────
cat("Export : batis/ (par commune)...\n")                                       # Message console : debut export batiments

success_count <- 0                                                              # Compteur communes exportees avec succes
error_count <- 0                                                                # Compteur erreurs (communes absentes ou SQL KO)
total_size <- 0                                                                 # Accumulateur de la taille totale exportee en Parquet

for (i in seq_len(nrow(communes_list))) {                                       # Boucle sur chaque commune OLD200 retenue
  idu <- communes_list$idu[i]                                                   # IDU de la commune courante
  prefixe <- paste0("26", sprintf("%03d", as.numeric(idu)))                     # Code INSEE complet (26XXX)
  table_name <- paste0(prefixe, "_bati_habitat")                                # Nom de la table PostgreSQL contenant les batiments

  tryCatch({                                                                    # Gestion d erreur securisee

    bati <- st_read(                                                            # Lecture des batiments depuis PostgreSQL
      con,
      query = sprintf('SELECT * FROM "26_old50m_bati"."%s"', table_name),       # Requete dynamique (une table par commune)
      quiet = TRUE                                                              # Supprime messages sf
    )

    bati$commune_idu <- idu                                                     # Ajout champ commune pour usage app Shiny

    # ── Transformation ────────────────────────────────────────
    bati <- transformer_wgs84(bati, nom = prefixe)                              # CRS → WGS84, geometrie conservée

    output_file <- sprintf("inst/app/extdata/batis/%s.parquet", prefixe)        # Chemin du fichier de sortie
    st_write_parquet(bati, output_file)                                         # Export parquet haute performance

    total_size <- total_size + file.size(output_file)                           # Taille cumulee
    success_count <- success_count + 1                                          # Succès +1

    if (i %% 10 == 0) {                                                         # Progression tous les 10 traitements
      cat(sprintf("   Progression : %d / %d\n", i, nrow(communes_list)))
    }

  }, error = function(e) {                                                      # En cas d erreur SQL ou geometrie KO
    cat(sprintf("Erreur %s : %s\n", prefixe, e$message))                        # Message erreur detaille
    error_count <- error_count + 1                                              # Erreur +1
  })
}

cat(sprintf("\n   Succès : %d / %d commune(s), %.2f MB\n",                      # Resume final
            success_count, nrow(communes_list), total_size / 1024^2))

if (error_count > 0) {                                                          # Si au moins une erreur
  cat(sprintf("   Erreurs : %d commune(s)\n", error_count))
}
cat("\n")                                                                       # Ligne vide pour lisibilite

gc()                                                                            # Liberation memoire

# ──────────────────────────────────────────────────────────────
# OLD50M (PAR COMMUNE)
# ──────────────────────────────────────────────────────────────
cat("Export : old50m/ (par commune)...\n")                                      # Message console : debut export OLD50m

success_count <- 0                                                              # Compteur succes
error_count <- 0                                                                # Compteur erreurs
total_size <- 0                                                                 # Taille cumulee des fichiers exportes

for (i in seq_len(nrow(communes_list))) {                                       # Boucle sur chaque commune retenue
  idu <- communes_list$idu[i]                                                   # IDU commune courante
  prefixe <- paste0("26", sprintf("%03d", as.numeric(idu)))                     # Code INSEE (26XXX)
  table_name <- paste0(prefixe, "_result_final")                                # Nom table SQL contenant OLD50m pour la commune

  tryCatch({                                                                    # Capture erreurs potentielles

    result <- st_read(                                                          # Lecture OLD50m PostgreSQL
      con,
      query = sprintf('SELECT * FROM "26_old50m_resultat"."%s"', table_name),   # Requête SQL dynamique
      quiet = TRUE                                                              # Sans messages de sf
    )

    result$commune_idu <- idu                                                   # Ajout IDU pour correspondance app

    # ── Transformation ────────────────────────────────────────
    result <- transformer_wgs84(result, nom = prefixe)                          # Passage Lambert → WGS84

    output_file <- sprintf("inst/app/extdata/old50m/%s.parquet", prefixe)       # Destination Parquet
    st_write_parquet(result, output_file)                                       # Écriture fichier

    total_size <- total_size + file.size(output_file)                           # Ajout taille fichier
    success_count <- success_count + 1                                          # Succès +1

    if (i %% 10 == 0) {                                                         # Progression toutes les 10 communes
      cat(sprintf("   Progression : %d / %d\n", i, nrow(communes_list)))
    }

  }, error = function(e) {                                                      # Si erreur SQL ou geometrique
    cat(sprintf("Erreur %s : %s\n", prefixe, e$message))                        # Message erreur
    error_count <- error_count + 1                                              # Erreur +1
  })
}

cat(sprintf("\n   Succès : %d / %d commune(s), %.2f MB\n",                      # Recapitulatif final
            success_count, nrow(communes_list), total_size / 1024^2))

if (error_count > 0) {                                                          # S’il y a eu des erreurs
  cat(sprintf("   Erreurs : %d commune(s)\n", error_count))
}
cat("\n")                                                                       # Ligne vide

gc()                                                                            # Libere la memoire RAM

# ──────────────────────────────────────────────────────────────
# ZONAGE URBAIN (PAR COMMUNE)
# ──────────────────────────────────────────────────────────────
cat("Export : zu/ (depuis 26_zonage_global)...\n")                              # Message console : debut export zonage urbain ZU

success_count <- 0                                                              # Compteur communes exportees avec succes
error_count <- 0                                                                # Compteur communes sans données ou en erreur
total_size <- 0                                                                 # Taille cumulee des exports Parquet
communes_absentes <- character()                                                # Liste des codes INSEE sans zonage disponible

dir.create("inst/app/extdata/zu", recursive = TRUE, showWarnings = FALSE)       # Cree le dossier ZU si absent

for (i in seq_len(nrow(communes_list))) {                                       # Boucle sur l ensemble des communes OLD200
  idu <- communes_list$idu[i]                                                   # IDU de la commune courante (ex : 1 → 26001)

  # ── Construction du code INSEE à partir de l'IDU ─────────────
  insee_code <- paste0("26", sprintf("%03d", as.numeric(idu)))                  # Code INSEE complet 26XXX
  prefixe <- insee_code  # même format pour le préfixe fichier                  # Prefixe fichier identique au code INSEE

  tryCatch({                                                                    # Securisation lecture PostgreSQL

    # ── Requête avec le code INSEE complet ─────────────────────
    query <- sprintf(                                                           # Construction dynamique de la requete SQL
      "SELECT * FROM \"26_old50m_resultat\".\"26_zonage_global\" WHERE insee = '%s'",
      insee_code
    )

    zonage <- st_read(con, query = query, quiet = TRUE)                         # Lecture des polygones de zonage urbain

    if (nrow(zonage) == 0) {                                                    # Si aucune donnee trouvee pour cette commune
      communes_absentes <- c(communes_absentes, insee_code)                     # Ajout à la liste des absents
      error_count <- error_count + 1                                            # Erreur +1
      next                                                                      # Passe à la commune suivante
    }

    # ── Ajout IDU pour compatibilité ──────────────────────────
    zonage$commune_idu <- idu                                                   # Ajout du champ IDU pour coherence applicative

    # ── Transformation WGS84 ──────────────────────────────────
    zonage <- transformer_wgs84(zonage, nom = prefixe)                          # Transformation CRS → WGS84 (geometrie conservee)

    # ── Export Parquet ────────────────────────────────────────
    output_file <- sprintf("inst/app/extdata/zu/%s.parquet", prefixe)           # Chemin du fichier cible
    st_write_parquet(zonage, output_file)                                       # Export au format Parquet

    success_count <- success_count + 1                                          # Compteur de succes +1
    total_size <- total_size + file.size(output_file)                           # Ajout taille fichier exporte

    if (i %% 20 == 0) {                                                         # Message progression toutes les 20 communes
      cat(sprintf("   %d / %d communes (INSEE %s)\n",
                  i, nrow(communes_list), insee_code))
    }

  }, error = function(e) {                                                      # Gestion fine des erreurs
    cat(sprintf("   Erreur IDU %s (INSEE %s) : %s\n",                           # Message erreur détaillé
                idu, insee_code, e$message))
    error_count <- error_count + 1                                              # Erreur +1
  })
}

# ──────────────────────────────────────────────────────────────
# RAPPORT FINAL
# ──────────────────────────────────────────────────────────────
cat(sprintf("\n✓ Export terminé : %d / %d communes\n",                          # Resume succes
            success_count, nrow(communes_list)))
cat(sprintf("  Taille totale : %.2f MB\n", total_size / 1024^2))                # Taille totale des exports

if (error_count > 0) {                                                          # Si des communes n ont pas ete trouvees
  cat(sprintf("⚠ %d communes non trouvées\n", error_count))                    # Avertissement
  if (length(communes_absentes) > 0 && length(communes_absentes) <= 10) {       # Si peu nombreuses, affichage liste
    cat(sprintf("  Codes absents : %s\n", paste(communes_absentes, collapse = ", ")))
  }
}

gc(verbose = FALSE)                                                             # Nettoyage memoire (mode silencieux)

# ──────────────────────────────────────────────────────────────
# FERMETURE
# ──────────────────────────────────────────────────────────────

dbDisconnect(con)                                                               # Fermeture propre connexion PostgreSQL

cat("\n═════════════════════════════════════════════════════════════\n")        # Bandeau decoratif console
cat("                     EXPORT TERMINÉ                            \n")        # Message final
cat("═════════════════════════════════════════════════════════════\n\n")        # Bandeau decoratif console

cat("Vérifier maintenant :\n")

# ──────────────────────────────────────────────────────────────────────────────
# FIN
# ──────────────────────────────────────────────────────────────────────────────
