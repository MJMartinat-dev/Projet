# ------------------------------------------------------------------------------
# SCRIPT 06_creation_carte.R : GENERATION AUTOMATISEE DE LA CARTOGRAPHIE
# ------------------------------------------------------------------------------
# Auteur       : MJMartinat
# Structure    : DDT de la Drôme
# Date         : 2025
# ------------------------------------------------------------------------------
# DESCRIPTION  : Génère les 4 cartes préfectorales de restriction/perspective
#                - Eaux superficielles : restrictions + perspectives
#                - Eaux souterraines : restrictions + perspectives
#                Export PDF/JPG avec entête institutionnelle
# VERSION      : 1.0
# DÉPENDANCES  : sf, dplyr, tmap, here, readr, stringr, glue, janitor,
#                grid, gridExtra, png
# ------------------------------------------------------------------------------
# Chargement des bibliothèques
# ------------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(sf)                                                                   # Données spatiales
  library(dplyr)                                                                # Manipulation données
  library(tmap)                                                                 # Cartographie thématique
  library(here)                                                                 # Chemins relatifs
  library(readr)                                                                # Lecture fichiers CSV
  library(stringr)                                                              # Manipulation chaînes
  library(glue)                                                                 # Interpolation chaînes
  library(janitor)                                                              # Nettoyage noms colonnes
  library(grid)                                                                 # Graphiques bas niveau
  library(gridExtra)                                                            # Arrangement grobs
  library(png)                                                                  # Lecture images PNG
})


# ------------------------------------------------------------------------------
# Constante - Niveaux de palettes et légendes
# ------------------------------------------------------------------------------
LEVELS_RESTRICTION <- c(                                                        # Niveaux de restriction
  "Pas de restriction",                                                         # Niveau 1 - Normal

  "Vigilance",                                                                  # Niveau 2 - Surveillance
  "Alerte",                                                                     # Niveau 3 - Attention
  "Alerte renforcée",                                                           # Niveau 4 - Critique
  "Crise",                                                                      # Niveau 5 - Maximum
  "Non Définie",                                                                # Données manquantes
  "Inconnu"                                                                     # Valeur non reconnue
)

COULEURS_CARTE <- c(                                                            # Palette couleurs
  "#e6efff",                                                                    # Bleu très clair
  "#f7efa5",                                                                    # Jaune pâle
  "#ffb542",                                                                    # Orange
  "#ff4a29",                                                                    # Rouge vif
  "#ad0021",                                                                    # Bordeaux
  "#DDDDDD",                                                                    # Gris (Non Définie)
  "#DDDDDD"                                                                     # Gris (Inconnu)
)

NOMS_COULEURS <- stats::setNames(COULEURS_CARTE, LEVELS_RESTRICTION)            # Association noms/couleurs


# ------------------------------------------------------------------------------
# Fonction - Chargement des restrictions
# ------------------------------------------------------------------------------
charger_restrictions <- function() {

  fichier_csv <- here::here("donnees", "bulletin", "origines", "restrictions.csv") # Chemin CSV restrictions

  if (!file.exists(fichier_csv)) {                                              # Si fichier absent
    warning("Fichier restrictions.csv introuvable : ", fichier_csv)             # Avertissement
    return(NULL)                                                                # Retour NULL
  }

  restrictions_carte <- readr::read_delim(                                      # Lecture CSV délimité
    fichier_csv,                                                                # Fichier source
    delim = ";",                                                                # Délimiteur point-virgule
    locale = readr::locale(encoding = "Windows-1252"),                          # Encodage Windows
    show_col_types = FALSE                                                      # Masquer types colonnes
  ) %>%
    janitor::clean_names() %>%                                                  # Nettoyage noms colonnes
    dplyr::mutate(                                                              # Transformation colonnes
      restrictions = dplyr::case_when(                                          # Recodage restrictions
        restrictions == "N"  ~ "Pas de restriction",                            # N = Normal
        restrictions == "V"  ~ "Vigilance",                                     # V = Vigilance
        restrictions == "A"  ~ "Alerte",                                        # A = Alerte
        restrictions == "Ar" ~ "Alerte renforcée",                              # Ar = Alerte renforcée
        restrictions == "C"  ~ "Crise",                                         # C = Crise
        is.na(restrictions)  ~ "Non Définie",                                   # NA = Non définie
        TRUE                 ~ "Inconnu"                                        # Autre = Inconnu
      ),
      perspectives = dplyr::case_when(                                          # Recodage perspectives
        perspectives_restrictions == "N"  ~ "Pas de restriction",               # N = Normal
        perspectives_restrictions == "V"  ~ "Vigilance",                        # V = Vigilance
        perspectives_restrictions == "A"  ~ "Alerte",                           # A = Alerte
        perspectives_restrictions == "Ar" ~ "Alerte renforcée",                 # Ar = Alerte renforcée
        perspectives_restrictions == "C"  ~ "Crise",                            # C = Crise
        is.na(perspectives_restrictions)  ~ "Non Définie",                      # NA = Non définie
        TRUE                              ~ "Inconnu"                           # Autre = Inconnu
      ),
      bassins_versants = stringr::str_squish(stringr::str_to_lower(bassins_versants)) # Normalisation noms
    )

  return(restrictions_carte)                                                    # Retour dataframe
}


# ------------------------------------------------------------------------------
# Fonction - chargement du fond de carte
# ------------------------------------------------------------------------------
charger_fond_carte <- function() {

  fichier_shp <- here::here("donnees", "bulletin", "origines", "2025_Secteurs_Secheresse_interdep.shp") # Chemin shapefile

  if (!file.exists(fichier_shp)) {                                              # Si fichier absent
    warning("Shapefile introuvable : ", fichier_shp)                            # Avertissement
    return(NULL)                                                                # Retour NULL
  }

  bv_carte <- sf::st_read(fichier_shp, quiet = TRUE) %>%                        # Lecture shapefile
    dplyr::mutate(                                                              # Transformation
      Secteur = stringr::str_squish(stringr::str_to_lower(Secteur))             # Normalisation noms
    )

  return(bv_carte)                                                              # Retour sf object
}


# ------------------------------------------------------------------------------
# Fonction - Préparation des données cartographiques
# ------------------------------------------------------------------------------

preparer_donnees_carte <- function() {

  message("=== Chargement des données cartographiques ===")                     # Message démarrage

  restrictions_carte <- charger_restrictions()                                  # Chargement restrictions
  if (is.null(restrictions_carte)) {                                            # Si échec chargement
    stop("Impossible de charger les données de restrictions.")                  # Arrêt erreur
  }
  message("  ✓ Restrictions chargées : ", nrow(restrictions_carte), " lignes")  # Confirmation

  bv_carte <- charger_fond_carte()                                              # Chargement fond carte
  if (is.null(bv_carte)) {                                                      # Si échec chargement
    stop("Impossible de charger le fond de carte.")                             # Arrêt erreur
  }
  message("  ✓ Fond de carte chargé : ", nrow(bv_carte), " secteurs")           # Confirmation

  restrictions_sup <- restrictions_carte %>%                                    # Filtrage eaux
    dplyr::filter(type_d_eau == "Superficiel")                                  # Superficielles

  restrictions_sou <- restrictions_carte %>%                                    # Filtrage eaux
    dplyr::filter(type_d_eau == "Souterrain")                                   # Souterraines

  bv_sup <- dplyr::left_join(                                                   # Jointure superficiel
    bv_carte,                                                                   # Fond de carte
    restrictions_sup,                                                           # Restrictions sup
    by = c("Secteur" = "bassins_versants")                                      # Clé de jointure
  )

  bv_sou <- dplyr::left_join(                                                   # Jointure souterrain
    bv_carte,                                                                   # Fond de carte
    restrictions_sou,                                                           # Restrictions sou
    by = c("Secteur" = "bassins_versants")                                      # Clé de jointure
  )

  message("  ✓ Jointures effectuées")                                           # Confirmation
  message("────────────────────────────────────────────────────────────────\n") # Séparateur

  return(list(                                                                  # Retour liste
    bv_sup = bv_sup,                                                            # Données superficielles
    bv_sou = bv_sou                                                             # Données souterraines
  ))
}


# ------------------------------------------------------------------------------
# Fonction - Création d'une carte TMAP
# ------------------------------------------------------------------------------
carte_restriction <- function(data, var_txt) {

  data$Secteur_affiche <- stringr::str_replace_all(                             # Labels avec retour ligne
    as.character(data$Secteur),                                                 # Colonne secteur
    "\\s*[-–]\\s*",                                                             # Motif tiret
    "\n-\n"                                                                     # Remplacement
  )

  tmap::tm_shape(data) +                                                        # Définition données
    tmap::tm_polygons(                                                          # Polygones colorés
      col = var_txt,                                                            # Variable couleur
      palette = NOMS_COULEURS,                                                  # Palette définie
      border.col = "grey40",                                                    # Couleur bordures
      lwd = 1.5                                                                 # Épaisseur bordures
    ) +
    tmap::tm_text(                                                              # Étiquettes texte
      "Secteur_affiche",                                                        # Variable texte
      size = 0.45,                                                              # Taille police
      col = "grey20",                                                           # Couleur texte
      just = "center",                                                          # Centrage
      bg.color = "white",                                                       # Fond blanc
      bg.alpha = 0.25,                                                          # Transparence fond
      remove.overlap = FALSE,                                                   # Pas suppression chevauchement
      lines = TRUE,                                                             # Multiligne activé
      bg.padding = 0.05,                                                        # Padding fond
      shadow = FALSE                                                            # Pas d'ombre
    ) +
    tmap::tm_layout(                                                            # Mise en page
      frame = FALSE,                                                            # Pas de cadre
      lwd = 0,                                                                  # Épaisseur ligne 0
      legend.show = FALSE,                                                      # Légende masquée
      inner.margins = c(0, 0, 0, 0),                                            # Marges internes
      outer.margins = c(0, 0, 0, 0),                                            # Marges externes
      bg.color = "white",                                                       # Fond blanc
      asp = NA                                                                  # Ratio auto
    )
}


# ------------------------------------------------------------------------------
# Fonction principale - Création planche cartographique
# ------------------------------------------------------------------------------
creation_carte <- function(bv_sup, bv_sou,
                           dossier_export = here::here("sorties", "cartes"),
                           exporter = FALSE) {

  tmap::tmap_mode("plot")                                                       # Mode statique


  # ---- Construction des 4 cartes ---------------------------------------------
  c1 <- carte_restriction(bv_sup, "restrictions")                               # Carte sup restrictions
  c2 <- carte_restriction(bv_sup, "perspectives")                               # Carte sup perspectives
  c3 <- carte_restriction(bv_sou, "restrictions")                               # Carte sou restrictions
  c4 <- carte_restriction(bv_sou, "perspectives")                               # Carte sou perspectives

  g1 <- tmap::tmap_grob(c1)                                                     # Conversion grob c1
  g2 <- tmap::tmap_grob(c2)                                                     # Conversion grob c2
  g3 <- tmap::tmap_grob(c3)                                                     # Conversion grob c3
  g4 <- tmap::tmap_grob(c4)                                                     # Conversion grob c4


  # ---- Titres et labels ------------------------------------------------------
  titre_col1 <- grid::textGrob(                                                 # Titre colonne 1
    "Restrictions actuelles",                                                   # Texte
    gp = grid::gpar(fontsize = 15, fontface = "bold"),                          # Style gras 15pt
    hjust = 0.5                                                                 # Centré horizontal
  )

  titre_col2 <- grid::textGrob(                                                 # Titre colonne 2
    "Perspectives d'évolution",                                                 # Texte
    gp = grid::gpar(fontsize = 15, fontface = "bold"),                          # Style gras 15pt
    hjust = 0.5                                                                 # Centré horizontal
  )

  label_sup <- grid::textGrob(                                                  # Label superficielles
    "SUPERFICIELLES",                                                           # Texte
    rot = 90,                                                                   # Rotation 90°
    gp = grid::gpar(fontsize = 13, fontface = "bold")                           # Style gras 13pt
  )

  label_sou <- grid::textGrob(                                                  # Label souterraines
    "SOUTERRAINES",                                                             # Texte
    rot = 90,                                                                   # Rotation 90°
    gp = grid::gpar(fontsize = 13, fontface = "bold")                           # Style gras 13pt
  )


  # ---- Arrangement des lignes de cartes --------------------------------------
  ligne1 <- gridExtra::arrangeGrob(                                             # Ligne 1 cartes
    label_sup, g1, g2,                                                          # Label + 2 cartes
    ncol = 3,                                                                   # 3 colonnes
    widths = grid::unit(c(1.5, 9, 9), "cm"),                                    # Largeurs colonnes
    heights = grid::unit(6.8, "cm")                                             # Hauteur ligne
  )

  ligne2 <- gridExtra::arrangeGrob(                                             # Ligne 2 cartes
    label_sou, g3, g4,                                                          # Label + 2 cartes
    ncol = 3,                                                                   # 3 colonnes
    widths = grid::unit(c(1.5, 9, 9), "cm"),                                    # Largeurs colonnes
    heights = grid::unit(6.8, "cm")                                             # Hauteur ligne
  )

  titres_cols <- gridExtra::arrangeGrob(                                        # Ligne titres colonnes
    grid::nullGrob(), titre_col1, titre_col2,                                   # Vide + 2 titres
    ncol = 3,                                                                   # 3 colonnes
    widths = grid::unit(c(1.5, 9, 9), "cm")                                     # Largeurs colonnes
  )


  # ---- Titres généraux -------------------------------------------------------
  titre_principal <- grid::textGrob(                                            # Titre principal
    "RESTRICTIONS PROVISOIRES DE CERTAINS USAGES DE L'EAU",                     # Texte
    gp = grid::gpar(fontsize = 16, fontface = "bold")                           # Style gras 16pt
  )

  titre_secondaire <- grid::textGrob(                                           # Titre secondaire
    "SITUATION ACTUELLE ET PROPOSITION D'ÉVOLUTION",                            # Texte
    gp = grid::gpar(fontsize = 14, fontface = "bold")                           # Style gras 14pt
  )


  # ---- Légende ---------------------------------------------------------------
  legende_grob <- grid::grobTree(                                               # Arbre grobs légende
    grid::textGrob(                                                             # Titre légende
      "Niveau de restriction",                                                  # Texte titre
      x = 0.5,                                                                  # Position X centrée
      y = 0.85,                                                                 # Position Y haute
      gp = grid::gpar(                                                          # Paramètres graphiques
        fontsize = 11,                                                          # Taille police 11pt
        fontface = "bold"                                                       # Style gras
      ),
      just = "center"),                                                         # Justification centrée
    # Ligne 1 légende
    grid::rectGrob(                                                             # Rectangle couleur 1
      x = 0.05,                                                                 # Position X gauche
      y = 0.55,                                                                 # Position Y milieu
      width = 0.032,                                                            # Largeur rectangle
      height = 0.18,                                                            # Hauteur rectangle
      gp = grid::gpar(                                                          # Paramètres graphiques
        fill = COULEURS_CARTE[1],                                               # Remplissage bleu clair
        col = "black",                                                          # Bordure noire
        lwd = 1)),                                                              # Épaisseur bordure
    grid::textGrob(                                                             # Label niveau 1
      LEVELS_RESTRICTION[1],                                                    # Texte "Pas de restriction"
      x = 0.10,                                                                 # Position X
      y = 0.55,                                                                 # Position Y
      gp = grid::gpar(fontsize = 8.5),                                          # Taille police 8.5pt
      just = "left"),                                                           # Aligné gauche
    grid::rectGrob(                                                             # Rectangle couleur 2
      x = 0.28,                                                                 # Position X
      y = 0.55,                                                                 # Position Y
      width = 0.032,                                                            # Largeur rectangle
      height = 0.18,                                                            # Hauteur rectangle
      gp = grid::gpar(                                                          # Paramètres graphiques
        fill = COULEURS_CARTE[2],                                               # Remplissage jaune
        col = "black",                                                          # Bordure noire
        lwd = 1)),                                                              # Épaisseur bordure
    grid::textGrob(                                                             # Label niveau 2
      LEVELS_RESTRICTION[2],                                                    # Texte "Vigilance"
      x = 0.33,                                                                 # Position X
      y = 0.55,                                                                 # Position Y
      gp = grid::gpar(fontsize = 8.5),                                          # Taille police 8.5pt
      just = "left"),                                                           # Aligné gauche
    grid::rectGrob(                                                             # Rectangle couleur 3
      x = 0.51,                                                                 # Position X
      y = 0.55,                                                                 # Position Y
      width = 0.032,                                                            # Largeur rectangle
      height = 0.18,                                                            # Hauteur rectangle
      gp = grid::gpar(                                                          # Paramètres graphiques
        fill = COULEURS_CARTE[3],                                               # Remplissage orange
        col = "black",                                                          # Bordure noire
        lwd = 1)),                                                              # Épaisseur bordure
    grid::textGrob(                                                             # Label niveau 3
      LEVELS_RESTRICTION[3],                                                    # Texte "Alerte"
      x = 0.56,                                                                 # Position X
      y = 0.55,                                                                 # Position Y
      gp = grid::gpar(fontsize = 8.5),                                          # Taille police 8.5pt
      just = "left"),                                                           # Aligné gauche
    grid::rectGrob(                                                             # Rectangle couleur 4
      x = 0.70,                                                                 # Position X
      y = 0.55,                                                                 # Position Y
      width = 0.032,                                                            # Largeur rectangle
      height = 0.18,                                                            # Hauteur rectangle
      gp = grid::gpar(                                                          # Paramètres graphiques
        fill = COULEURS_CARTE[4],                                               # Remplissage rouge
        col = "black",                                                          # Bordure noire
        lwd = 1)),                                                              # Épaisseur bordure
    grid::textGrob(                                                             # Label niveau 4
      LEVELS_RESTRICTION[4],                                                    # Texte "Alerte renforcée"
      x = 0.75,                                                                 # Position X
      y = 0.55,                                                                 # Position Y
      gp = grid::gpar(fontsize = 8.5),                                          # Taille police 8.5pt
      just = "left"),                                                           # Aligné gauche
    # Ligne 2 légende
    grid::rectGrob(                                                             # Rectangle couleur 5
      x = 0.18,                                                                 # Position X
      y = 0.20,                                                                 # Position Y bas
      width = 0.032,                                                            # Largeur rectangle
      height = 0.18,                                                            # Hauteur rectangle
      gp = grid::gpar(                                                          # Paramètres graphiques
        fill = COULEURS_CARTE[5],                                               # Remplissage bordeaux
        col = "black",                                                          # Bordure noire
        lwd = 1)),                                                              # Épaisseur bordure
    grid::textGrob(                                                             # Label niveau 5
      LEVELS_RESTRICTION[5],                                                    # Texte "Crise"
      x = 0.23,                                                                 # Position X
      y = 0.20,                                                                 # Position Y
      gp = grid::gpar(fontsize = 8.5),                                          # Taille police 8.5pt
      just = "left"),                                                           # Aligné gauche
    grid::rectGrob(                                                             # Rectangle couleur 6
      x = 0.42,                                                                 # Position X
      y = 0.20,                                                                 # Position Y
      width = 0.032,                                                            # Largeur rectangle
      height = 0.18,                                                            # Hauteur rectangle
      gp = grid::gpar(                                                          # Paramètres graphiques
        fill = COULEURS_CARTE[6],                                               # Remplissage gris
        col = "black",                                                          # Bordure noire
        lwd = 1)),                                                              # Épaisseur bordure
    grid::textGrob(                                                             # Label niveau 6
      LEVELS_RESTRICTION[6],                                                    # Texte "Non Définie"
      x = 0.47,                                                                 # Position X
      y = 0.20,                                                                 # Position Y
      gp = grid::gpar(fontsize = 8.5),                                          # Taille police 8.5pt
      just = "left"),                                                           # Aligné gauche
    grid::rectGrob(                                                             # Rectangle couleur 7
      x = 0.65,                                                                 # Position X
      y = 0.20,                                                                 # Position Y
      width = 0.032,                                                            # Largeur rectangle
      height = 0.18,                                                            # Hauteur rectangle
      gp = grid::gpar(                                                          # Paramètres graphiques
        fill = COULEURS_CARTE[7],                                               # Remplissage gris
        col = "black",                                                          # Bordure noire
        lwd = 1)),                                                              # Épaisseur bordure
    grid::textGrob(                                                             # Label niveau 7
      LEVELS_RESTRICTION[7],                                                    # Texte "Inconnu"
      x = 0.70,                                                                 # Position X
      y = 0.20,                                                                 # Position Y
      gp = grid::gpar(fontsize = 8.5),                                          # Taille police 8.5pt
      just = "left")                                                            # Aligné gauche
  )
  legende_avec_marges <- gridExtra::arrangeGrob(                                # Légende avec marges
    grid::nullGrob(),                                                           # Espace gauche
    legende_grob,                                                               # Contenu légende
    ncol = 2,                                                                   # 2 colonnes
    widths = grid::unit(c(0.75, 6.4), "null")                                   # Largeurs relatives
  )


  # ---- Corps de page ---------------------------------------------------------
  page_corps <- gridExtra::arrangeGrob(                                         # Corps page
    titre_principal, titre_secondaire, titres_cols,                             # Titres
    ligne1, ligne2, legende_avec_marges,                                        # Cartes + légende
    ncol = 1,                                                                   # 1 colonne
    heights = grid::unit(c(0.25, 0.45, 0.40, 6.5, 6.5, 0.9), "null")            # Hauteurs relatives
  )


  # ---- Entête avec logo ------------------------------------------------------
  path_bg   <- here::here("fichiers", "images", "image_secheresse.png")         # Chemin image fond
  path_logo <- here::here("fichiers", "images", "logo_prefete.png")             # Chemin logo préfète
  couleur_entete <- "#001942"                                                   # Bleu DDT

  bg_grob <- if (file.exists(path_bg)) {                                        # Si image fond existe
    img_bg <- png::readPNG(path_bg)                                             # Lecture PNG
    grid::rasterGrob(                                                           # Création grob raster
      img_bg,                                                                   # Image source
      width = 1.2,                                                              # Largeur 120%
      height = 1.2,                                                             # Hauteur 120%
      x = 0.5,                                                                  # Position X centrée
      y = 0.85                                                                  # Position Y haute
    )
  } else {                                                                      # Sinon
    grid::rectGrob(                                                             # Rectangle de secours
      gp = grid::gpar(                                                          # Paramètres graphiques
        fill = couleur_entete,                                                  # Remplissage bleu DDT
        col = NA                                                                # Pas de bordure
      )
    )
  }

  logo_grob <- if (file.exists(path_logo)) {                                    # Si logo existe
    img_logo <- png::readPNG(path_logo)                                         # Lecture PNG
    grid::rasterGrob(                                                           # Création grob raster
      img_logo,                                                                 # Image logo
      width = grid::unit(0.35, "npc"),                                          # Largeur 35% parent
      height = grid::unit(0.50, "npc"),                                         # Hauteur 50% parent
      x = 0.25,                                                                 # Position X gauche
      y = 0.62,                                                                 # Position Y
      just = "left"                                                             # Aligné gauche
    )
  } else {                                                                      # Sinon
    grid::textGrob(                                                             # Texte de secours
      "DDT",                                                                    # Texte fallback
      x = 0,                                                                    # Position X
      just = "left",                                                            # Aligné gauche
      gp = grid::gpar(                                                          # Paramètres graphiques
        col = "white",                                                          # Couleur blanche
        fontsize = 15,                                                          # Taille 15pt
        fontface = "bold"                                                       # Style gras
      )
    )
  }

  texte_entete <- grid::textGrob(                                               # Texte entête
    "Direction Départementale des Territoires\n
    Service Eau Forêts Espaces Naturels\n
    Pôle Qualité Quantité Eau",                                                 # Contenu texte
    x = 0.95,                                                                   # Position X droite
    y = 0.65,                                                                   # Position Y
    just = "right",                                                             # Aligné droite
    gp = grid::gpar(                                                            # Paramètres graphiques
      col = "white",                                                            # Couleur blanche
      fontsize = 12.5,                                                          # Taille 12.5pt
      fontface = "bold"                                                         # Style gras
    )
  )

  contenu_entete <- gridExtra::arrangeGrob(                                     # Arrangement entête
    logo_grob,                                                                  # Grob logo
    texte_entete,                                                               # Grob texte
    ncol = 2,                                                                   # 2 colonnes
    widths = grid::unit(                                                        # Largeurs colonnes
      c(0.23, 0.77),                                                            # 23% + 77%
      "npc"                                                                     # Unité relative
    )
  )

  entete_grob <- grid::grobTree(                                                # Assemblage entête
    bg_grob,                                                                    # Fond image/couleur
    contenu_entete                                                              # Logo + texte
  )

  pied_page <- grid::rectGrob(                                                  # Pied de page
    gp = grid::gpar(                                                            # Paramètres graphiques
      fill = couleur_entete,                                                    # Remplissage bleu DDT
      col = NA                                                                  # Pas de bordure
    )
  )


  # ---- Page finale -----------------------------------------------------------
  page_finale <- gridExtra::arrangeGrob(                                        # Page complète
    entete_grob,                                                                # Bandeau entête
    page_corps,                                                                 # Corps principal
    pied_page,                                                                  # Bandeau pied
    ncol = 1,                                                                   # 1 colonne
    heights = grid::unit(                                                       # Hauteurs sections
      c(1.2, 9.6, 0.4),                                                         # Entête + corps + pied
      "null"                                                                    # Unité relative
    )
  )


  # ---- Export ----------------------------------------------------------------
  if (exporter) {                                                               # Si export demandé
    dir.create(
      file.path(dossier_export, "pdf"),
      recursive = TRUE,
      showWarnings = FALSE
    )                                                                           # Création dossier PDF
    dir.create(
      file.path(dossier_export, "jpg"),
      recursive = TRUE,
      showWarnings = FALSE
    )                                                                           # Création dossier JPG

    date_enregistrement <- format(Sys.Date(), "%Y-%m-%d")                       # Date format ISO

    # Export PDF
    fichier_pdf <- file.path(
      dossier_export,
      "pdf",                                                                    # Chemin fichier PDF
      glue::glue("carte_restrictions_{date_enregistrement}.pdf")
    )
    tryCatch({                                                                  # Gestion erreurs
      grDevices::pdf(fichier_pdf, width = 10, height = 12)                      # Ouverture device PDF
      grid::grid.newpage()                                                      # Nouvelle page
      grid::grid.draw(page_finale)                                              # Dessin page
      grDevices::dev.off()                                                      # Fermeture device
      message("✓ PDF généré : ", fichier_pdf)                                   # Confirmation
    }, error = function(e) {                                                    # Si erreur
      if (dev.cur() > 1) dev.off()                                              # Fermeture device
      warning("Erreur export PDF : ", e$message)                                # Avertissement
    })

    # Export JPG
    fichier_jpg <- file.path(
      dossier_export,
      "jpg",                              # Chemin fichier JPG
      glue::glue("carte_restrictions_{date_enregistrement}.jpg")
    )
    tryCatch({                                                                  # Gestion erreurs
      grDevices::jpeg(
        fichier_jpg,
        width = 10,
        height = 12,
        units = "in",
        res = 300)                                                              # Ouverture device JPG
      grid::grid.newpage()                                                      # Nouvelle page
      grid::grid.draw(page_finale)                                              # Dessin page
      grDevices::dev.off()                                                      # Fermeture device
      message("✓ JPG généré : ", fichier_jpg)                                   # Confirmation
    }, error = function(e) {                                                    # Si erreur
      if (dev.cur() > 1) dev.off()                                              # Fermeture device
      warning("Erreur export JPG : ", e$message)                                # Avertissement
    })
  }

  return(page_finale)                                                           # Retour grob page
}


# ------------------------------------------------------------------------------
# Exécution - Chargement et création au niveau global
# ------------------------------------------------------------------------------
tryCatch({                                                                      # Gestion erreurs
  donnees_carte <- preparer_donnees_carte()                                     # Préparation données
  bv_sup <- donnees_carte$bv_sup                                               # Export global sup
  bv_sou <- donnees_carte$bv_sou                                               # Export global sou
  message("✓ Données cartographiques disponibles (bv_sup, bv_sou)")             # Confirmation
}, error = function(e) {                                                        # Si erreur
  warning("Erreur chargement données carte : ", e$message)                      # Avertissement
})

if (sys.nframe() == 0L) {                                                       # Si exécution directe
  if (exists("bv_sup") && exists("bv_sou")) {                                   # Si données existent
    creation_carte(bv_sup, bv_sou, exporter = TRUE)                             # Création et export
  }
}


# ------------------------------------------------------------------------------
# Passage au script 07_create_graphique.R
# ------------------------------------------------------------------------------
next_script <- file.path(getwd(), "dev", "07_create_graphique.R")               # Chemin du script 07

if (file.exists(next_script)) {                                                 # Vérifie si le script existe
  message("Passage au script 07_create_graphique.R")                            # Indique le changement de script
  rstudioapi::navigateToFile(next_script)                                       # Ouvre le script 06 dans RStudio
} else {
  message("Script 07_create_graphique.R introuvable dans dev")                  # Avertit si script manquant
}

message("SCRIPT 06 TERMINÉ")                                                    # Message fin script


# ──────────────────────────────────────────────────────────────────────────────
# FIN DU SCRIPT 06_create_carte
# ──────────────────────────────────────────────────────────────────────────────
