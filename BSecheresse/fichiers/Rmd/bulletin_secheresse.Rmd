---
output:
  pdf_document:
    includes:
      in_header: ../tex/header.tex
  html_document:
    df_print: paged
    toc: false
    number_sections: false
    theme: flatly
    self_contained: true
    includes:
      in_header: ../html/header.html
params:
  date_bulletin: !r Sys.Date()
  run_import: true
---

```{r setup, include=FALSE}
# =============================================================================
# CONFIGURATION KNITR
# =============================================================================
knitr::opts_chunk$set(
  echo = FALSE, 
  warning = FALSE, 
  message = FALSE,
  fig.align = "center",
  out.width = "100%"
)

# =============================================================================
# CHARGEMENT DES PACKAGES
# =============================================================================
library(rmarkdown)
library(magrittr)
library(tidyverse)
library(stringr)
library(here)
library(readr)
library(lubridate)
library(glue)
library(kableExtra)
library(sf)
library(tmap)
library(grid)
library(gridExtra)
library(png)
```

```{r importation, include=FALSE}
# =============================================================================
# IMPORTATION DES DONNÉES
# =============================================================================
source(here::here("R", "import.R"), encoding = "UTF-8", local = knitr::knit_global())
source(here::here("R", "utils.R"), encoding = "UTF-8", local = knitr::knit_global())

# Source du script de création de carte (crée bv_sup et bv_sou)
source(here::here("dev", "06_creation_carte.R"), encoding = "UTF-8", local = FALSE)
```

```{r titre, results='asis'}
# =============================================================================
# TITRE DU BULLETIN
# =============================================================================
date_affichee <- format(as.Date(params$date_bulletin), "%d %B %Y")

cat(glue::glue('
<div class="titre-bulletin">
  <h1 style="font-weight:bold; font-size:2em; margin-bottom:5px;">
    Bulletin hydrologique de la
  </h1>
  <h2 style="font-weight:bold; font-size:1.25em; margin-bottom:5px;">
    Direction Départementale des Territoires
  </h2>
  <p style="font-weight:bold;">du {date_affichee}</p>
</div>
'))
```

```{r pluvio_titre, results='asis'}
# =============================================================================
# TITRE SECTION PLUVIOMÉTRIE
# =============================================================================
cat('
<div class="pluviometrie" style="max-width:max-content; margin:0 auto;">
<h2 style="font-variant:small-caps; text-decoration:underline; font-weight:bold; font-size:14px;">
  Pluviométrie attendue (Météo France)
</h2>
')
```

```{r tab_pluvio, results='asis'}
# =============================================================================
# TABLEAU DES PRÉVISIONS MÉTÉOROLOGIQUES
# =============================================================================
previsions <- readr::read_csv2(
  here::here("donnees", "bulletin", "origines", "previsions_meteo.csv"),
  show_col_types = FALSE
)

# Renommage des colonnes
names(previsions) <- names(previsions) %>%
  stringr::str_replace("^J$", "Jour") %>%
  stringr::str_replace("^J_(\\d+)$", "Jour+\\1")

kbl_pluvio <- knitr::kable(
  previsions,
  format    = "html",
  escape    = FALSE,
  row.names = FALSE,
  col.names = stringr::str_to_title(names(previsions)),
  align     = rep("c", ncol(previsions))
) %>%
  kableExtra::kable_styling(
    full_width        = TRUE,
    position          = "center",
    font_size         = 10.5,
    bootstrap_options = c("striped", "hover", "condensed", "bordered")
  ) %>%
  kableExtra::row_spec(0, bold = TRUE, background = "#e6efff") %>%
  kableExtra::column_spec(1:ncol(previsions), width = "80px")

cat(glue::glue(
  '<div style="max-width: max-content; width:100% important!; margin:15px auto;">',
  '{kbl_pluvio}',
  '</div>',
  '</div>'
))
```

```{r situation_titre, results='asis'}
# =============================================================================
# TITRE SECTION SITUATION
# =============================================================================
cat('
<div class="situation" style="max-width:max-content; margin:0 auto;">
<h2 style="font-variant:small-caps; text-decoration:underline; font-weight:bold; font-size:14px;">
  Situation des différents secteurs
</h2>
')
```

```{r tableau_secteurs, results='asis'}
# =============================================================================
# GÉNÉRATION DES TABLEAUX PAR SECTEUR
# =============================================================================
blocs <- generer_bloc_secteur(
  donnees      = donnees,
  seuils_hydro = seuils_hydro,
  seuils_piezo = seuils_piezo,
  restrictions = restrictions
)

for (bloc in blocs) {
  cat(bloc$texte, "\n")
}

cat('</div>')
```

```{r carte_titre, results='asis'}
# =============================================================================
# TITRES DE LA SECTION CARTOGRAPHIE
# =============================================================================
cat('
<div class="cartographie" style="max-width:max-content; margin:0 auto; page-break-before:always;">
<div style="text-align:center; margin:30px 0 20px 0;">
  <h2 style="font-weight:bold; font-variant:small-caps; text-decoration:underline; margin-bottom:10px;">
    Restrictions provisoires de certains usages de l\'eau
  </h2>
  <h3 style="font-weight:bold; font-variant:small-caps; text-decoration:underline;">
    Situation actuelle et proposition d\'évolution
  </h3>
</div>
')
```

```{r cartes_restriction, fig.height=10, fig.width=8, dpi=150}
# =============================================================================
# GÉNÉRATION DES CARTES DE RESTRICTIONS
# La fonction creation_carte() génère déjà sa propre légende intégrée
# =============================================================================

if (exists("bv_sup") && exists("bv_sou")) {
  
  # Création de la grille de cartes (avec légende intégrée)
  grille_finale <- creation_carte(bv_sup, bv_sou)
  
  # Affichage
  grid::grid.newpage()
  grid::grid.draw(grille_finale)
  
}
```

```{r fermer_div, results='asis'}
# =============================================================================
# FERMETURE DU DIV CARTOGRAPHIE
# =============================================================================
cat('</div>')
```
