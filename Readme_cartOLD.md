[//]: # (0x4d4a)

<div align="center">

# cartOLD

**Application Shiny modulaire pour la visualisation cartographique des Obligations Légales de Débroussaillement**  
*DDT de la Drôme · 2023–2025 · Version 0.0.1*

[![GitLab](https://img.shields.io/badge/GitLab-Source-FC6D26?style=flat-square&logo=gitlab&logoColor=white)](https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/cartOLD)
[![Live](https://img.shields.io/badge/🟢_Application_live-ssm--ecologie.shinyapps.io-009FDA?style=flat-square)](https://ssm-ecologie.shinyapps.io/cartOLD/)
![R](https://img.shields.io/badge/R-4.5.1-276DC3?style=flat-square&logo=r&logoColor=white)
![Shiny](https://img.shields.io/badge/Shiny-1.11.1-276DC3?style=flat-square)
![Licence](https://img.shields.io/badge/Licence-GPL_≥_3-blue?style=flat-square)
![Statut](https://img.shields.io/badge/Statut-Production-22c55e?style=flat-square)

</div>

---

## Présentation

**cartOLD** est une application Shiny packagée (framework **Golem**) permettant d'explorer de façon interactive les données d'Obligations Légales de Débroussaillement (OLD) à l'échelle du département de la Drôme.

Elle s'appuie sur les couches géographiques produites par [OLD50m](https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/old50m) et est destinée aux agents DDT, partenaires institutionnels et tout public autorisé.

---

## Fonctionnalités

### Cartographie interactive
- Carte Leaflet plein écran avec sélection de commune et **zoom automatique**
- Recherche d'adresse via l'**API BAN** (Base Adresse Nationale)
- Affichage dynamique des couches géographiques
- Échelle numérique dynamique (`1:xxxxx`), échelle graphique noir et blanc, rose des vents

### Couches disponibles

| Couche | Description |
|---|---|
| Limites départementales | Département de la Drôme |
| Limites communales | Communes de la Drôme |
| Zones OLD 200 m | Zones à risques — massifs forestiers sensibles |
| Zones OLD 50 m | Zones à débroussailler par propriétaire |
| Parcelles cadastrales | Source : données MAJIC/EDIGEO |
| Bâtiments | Source : BD TOPO IGN |
| Zonage PLU | Plans Locaux d'Urbanisme |

### Export et impression
- Capture de la carte en **PNG** via `html2canvas`
- Génération de **PDF** via RMarkdown
- Aperçu de l'export avant téléchargement

### Interface utilisateur
- Page d'accueil, modale d'avertissement au démarrage
- Sidebar masquable, interface responsive
- Mentions légales et politique de confidentialité intégrées

---

## Stack technique

| Composant | Technologie |
|---|---|
| Framework applicatif | R 4.5.1 · Shiny 1.11.1 · **Golem** |
| Cartographie | Leaflet · sf · sfarrow |
| Visualisation | r2d3 · RColorBrewer · htmlwidgets |
| Performance | memoise — cache des données spatiales |
| Front-end | CSS personnalisé · JavaScript (`script.js`) |
| Reporting | RMarkdown · markdown |
| Déploiement | shinyapps.io — compte `ssm-ecologie` |
| Tests | testthat ≥ 3.0.0 |

---

## Architecture

```
cartOLD/
├── R/
│   ├── app_config.R            ← configuration Golem
│   ├── app_server.R            ← logique serveur principale
│   ├── app_ui.R                ← interface utilisateur principale
│   ├── golem_utils.R           ← utilitaires Golem
│   ├── import_data.R           ← chargement et cache des données spatiales
│   ├── mod_accueil.R           ← module page d'accueil
│   ├── mod_aide.R              ← module aide utilisateur
│   ├── mod_avertissement.R     ← module modale de démarrage
│   ├── mod_carte.R             ← module cartographique principal
│   ├── mod_carte_aide.R        ← module aide contextuelle carte
│   ├── mod_carte_controls.R    ← module contrôles de navigation
│   ├── mod_carte_export.R      ← module export PNG/PDF
│   └── run_app.R               ← point d'entrée
├── data-raw/
│   └── pre_data.R              ← préparation des données brutes
├── dev/                        ← scripts de développement (non déployés)
│   ├── 01_start.R              ← initialisation projet Golem
│   ├── 02_dev.R                ← développement itératif
│   ├── 03_compile_rmd.R        ← compilation RMarkdown → HTML
│   ├── 04_fix_non_ascii.R      ← correction d'encodage
│   ├── 05_deploy.R             ← déploiement shinyapps.io
│   ├── run_dev.R               ← lancement en mode développement
│   └── rmd/                    ← sources des pages statiques
│       ├── accueil.Rmd
│       ├── aide.Rmd
│       ├── avertissement.Rmd
│       ├── confidentialite.Rmd
│       ├── mentions_legales.Rmd
│       └── rmd.css
├── inst/app/www/
│   ├── css/style.css           ← styles personnalisés
│   ├── html/                   ← pages HTML compilées
│   ├── icones/cartOLD.ico
│   ├── images/                 ← ressources visuelles
│   └── js/script.js            ← interactions front-end
├── guides/                     ← documentation technique PDF par fichier
├── tests/testthat/test-app.R
├── app.R
├── DESCRIPTION
├── LICENSE.md
└── NEWS.md
```

---

## Installation & lancement

### Prérequis

- R ≥ 4.5.1
- Accès aux données spatiales OLD50m (PostgreSQL/PostGIS ou fichiers `.parquet` via `sfarrow`)

### Dépendances

```r
install.packages(c(
  "golem", "shiny", "shinyjs", "leaflet", "sf", "sfarrow",
  "dplyr", "magrittr", "r2d3", "RColorBrewer", "htmlwidgets",
  "rmarkdown", "markdown", "base64enc", "config"
))
```

### Lancement en développement

```r
source("dev/run_dev.R")
```

### Déploiement

```r
source("dev/05_deploy.R")
```

> ⚠️ **Proxy ministériel** : activer les lignes proxy dans `.Renviron` (lignes 6–7) avant tout lancement, sans quoi l'application ne passe pas la sécurité réseau.

---

## Documentation technique

Des guides techniques PDF sont fournis dans `guides/` pour chaque fichier source :

| Fichier | Guide |
|---|---|
| `app_config.R` | `guides/R/guide_technique_app_config.pdf` |
| `app_server.R` | `guides/R/guide_technique_app_server.pdf` |
| `app_ui.R` | `guides/R/guide_technique_app_ui.pdf` |
| `mod_carte_controls.R` | `guides/R/guide_technique_mod_carte_controls.pdf` |
| `mod_carte_export.R` | `guides/R/guide_technique_mod_carte_export.pdf` |
| `script.js` | `guides/guide_technique_scriptjs.pdf` |
| Vue d'ensemble | `guides/guide_technique_app.pdf` |

---

## Historique

| Version | Date | Contenu |
|---|---|---|
| 0.0.1 | 2025 | Première version de production — voir [NEWS.md](./NEWS.md) |

---

## Liens

| | |
|---|---|
| 🔧 Données source | [OLD50m](https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/old50m) |
| 📁 Portfolio | [Voir le portfolio](../../portfolio/README.md) |
| 📬 Contact | ddt-sefen-pf@drome.gouv.fr |

---

<sub>Auteure : Marie-Jeanne Martinat · DDT de la Drôme – SEFEN – Pôle Forêt · Licence GPL ≥ 3</sub>
