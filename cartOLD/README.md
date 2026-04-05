# cartOLD — Cartographie interactive des Obligations Légales de Débroussaillement

> Application Shiny modulaire de visualisation cartographique interactive dédiée aux zones
> d'Obligations Légales de Débroussaillement (OLD) du département de la Drôme.

---

## Sommaire

- [Présentation](#présentation)
- [Fonctionnalités](#fonctionnalités)
- [Architecture technique](#architecture-technique)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Lancement de l'application](#lancement-de-lapplication)
- [Structure du projet](#structure-du-projet)
- [Couches cartographiques](#couches-cartographiques)
- [Pipeline de données](#pipeline-de-données)
- [Export cartographique](#export-cartographique)
- [Tests](#tests)
- [Déploiement](#déploiement)
- [Workflow de développement](#workflow-de-développement)
- [Historique des versions](#historique-des-versions)
- [Licence](#licence)
- [Auteur et organisation](#auteur-et-organisation)

---

## Présentation

**cartOLD** est une application web cartographique développée avec le framework R Shiny.
Elle permet aux agents de la Direction Départementale des Territoires de la Drôme (DDT 26)
de visualiser et d'explorer interactivement les données relatives aux Obligations Légales
de Débroussaillement (OLD), conformément au Code forestier.

L'application s'appuie sur le framework [golem](https://thinkr-open.github.io/golem/) pour
structurer l'application comme un package R modulaire, garantissant la maintenabilité, la
reproductibilité et la facilité de déploiement.

**Application déployée** : [https://ssm-ecologie.shinyapps.io/cartOLD/](https://ssm-ecologie.shinyapps.io/cartOLD/)

**Organisation** : DDT de la Drôme — Ministère de la Transition Écologique
**Service** : Service Eau, Forêts et Espaces Naturels — Pôle Forêt

---

## Fonctionnalités

### Navigation cartographique

- Carte [Leaflet](https://rstudio.github.io/leaflet/) en plein écran
- Sélection d'une commune avec zoom automatique sur l'emprise communale
- Recherche d'adresse via l'**API BAN** (Base Adresse Nationale)
- Sidebar latérale rétractable (style LizMap) pour les contrôles

### Couches et affichage

- Affichage dynamique des couches géographiques (activation/désactivation)
- Légende dynamique s'adaptant aux couches visibles
- Fond de carte configurable

### Contrôles cartographiques flottants

- **Échelle numérique** dynamique (format `1:xxxxx`) mise à jour en temps réel
- **Échelle graphique** avec segments noir et blanc
- **Rose des vents** avec indicateur Nord
- **Outil de mesure de distance** interactif (activation/effacement)

### Export

- **Capture PNG** de la carte via `html2canvas` (JavaScript)
- **Génération PDF** A4 paysage avec mise en page institutionnelle via RMarkdown
- Prévisualisation de l'export avant téléchargement

### Interface utilisateur

- Page d'accueil avec présentation de l'application
- Modale d'avertissement au démarrage (contexte métier OLD)
- Aide contextuelle intégrée
- Liens vers mentions légales et politique de confidentialité
- Interface responsive adaptée aux différentes résolutions d'écran

---

## Architecture technique

```
┌─────────────────────────────────────────────────────────────┐
│                   APPLICATION cartOLD                       │
│                  (Package R / golem)                        │
├──────────────────────┬──────────────────────────────────────┤
│      UI (app_ui.R)   │       SERVER (app_server.R)          │
├──────────────────────┴──────────────────────────────────────┤
│                    MODULES SHINY                            │
│  ┌─────────────┐ ┌──────────┐ ┌────────────────────────┐   │
│  │ mod_accueil │ │ mod_aide │ │   mod_avertissement    │   │
│  └─────────────┘ └──────────┘ └────────────────────────┘   │
│  ┌────────────────────────────────────────────────────┐     │
│  │                   mod_carte                        │     │
│  │  ┌──────────────────┐  ┌──────────────────────┐   │     │
│  │  │ mod_carte_aide   │  │ mod_carte_controls   │   │     │
│  │  └──────────────────┘  └──────────────────────┘   │     │
│  │  ┌──────────────────┐                              │     │
│  │  │ mod_carte_export │                              │     │
│  │  └──────────────────┘                              │     │
│  └────────────────────────────────────────────────────┘     │
├─────────────────────────────────────────────────────────────┤
│                   DONNÉES SPATIALES                         │
│    GeoParquet (inst/app/extdata/)  ←  PostgreSQL/PostGIS    │
│    Chargement via {sfarrow} + mise en cache {memoise}       │
├─────────────────────────────────────────────────────────────┤
│                    ASSETS STATIQUES                         │
│    CSS (style.css)  |  JS (script.js)  |  HTML compilés     │
└─────────────────────────────────────────────────────────────┘
```

### Technologies utilisées

| Domaine | Technologie | Rôle |
|---|---|---|
| Framework applicatif | R + Shiny + golem | Structure modulaire du package |
| Cartographie | leaflet | Carte interactive |
| Données spatiales | sf, sfarrow | Lecture et manipulation des géométries |
| Performance | memoise | Cache des données spatiales |
| UI dynamique | shinyjs, r2d3 | Interactions DOM et visualisations D3 |
| Export | base64enc, rmarkdown, grDevices | Génération PNG / PDF |
| Couleurs | RColorBrewer | Palettes cartographiques |
| Manipulation données | dplyr, magrittr | Traitement et filtrage |
| Configuration | config | Gestion des environnements (dev/prod) |
| Frontend | JavaScript (script.js), CSS (style.css) | UI personnalisée et comportements carte |
| Géocodage | API BAN | Recherche d'adresse |
| Tests | testthat | Tests unitaires |

---

## Prérequis

- **R** ≥ 4.5.1
- **RStudio** (recommandé) ou tout IDE compatible R
- Accès à une base de données **PostgreSQL / PostGIS** pour la préparation des données (étape préalable uniquement)
- Connexion internet pour l'API BAN et les tuiles de fond de carte

### Packages R requis

Les dépendances sont déclarées dans le fichier `DESCRIPTION` et s'installent automatiquement :

```r
base64enc, config, dplyr, golem, grDevices, htmlwidgets,
leaflet, magrittr, r2d3, RColorBrewer, rmarkdown, markdown,
sf, sfarrow, shiny, shinyjs, stats, utils
```

---

## Installation

### 1. Cloner le dépôt

```bash
git clone https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/cartold.git
cd cartold
```

### 2. Installer les dépendances R

```r
# Depuis la console R ou RStudio
install.packages("remotes")
remotes::install_deps()
```

Ou manuellement :

```r
install.packages(c(
  "base64enc", "config", "dplyr", "golem", "htmlwidgets",
  "leaflet", "magrittr", "r2d3", "RColorBrewer", "rmarkdown",
  "markdown", "sf", "sfarrow", "shiny", "shinyjs"
))
```

### 3. Placer les données spatiales

Les fichiers GeoParquet doivent être présents dans :

```
inst/app/extdata/
├── departement.parquet
├── communes.parquet
├── communes_old200.parquet
├── old200.parquet
├── old50m.parquet
├── parcelles/          ← chargement progressif par commune
│   └── *.parquet
├── batis/              ← chargement progressif par commune
│   └── *.parquet
└── zu.parquet
```

> Ces fichiers sont générés par le script `data-raw/pre_data.R` à partir de la base PostgreSQL/PostGIS.
> Voir la section [Pipeline de données](#pipeline-de-données).

---

## Lancement de l'application

### Mode développement local

```r
# Depuis RStudio ou la console R, à la racine du projet
source("dev/run_dev.R")
```

Ou directement :

```r
pkgload::load_all()
cartOLD::run_app()
```

### Via le fichier app.R (déploiement direct)

```r
source("app.R")
```

### Configurer l'environnement

L'application utilise le fichier `inst/golem-config.yml` pour distinguer les environnements :

```yaml
default:
  golem_name: cartOLD
  golem_version: 0.0.1
  app_prod: no

production:
  app_prod: yes

dev:
  app_prod: no
  golem_wd: !expr here::here()
```

Pour activer le mode production :

```r
Sys.setenv(GOLEM_CONFIG_ACTIVE = "production")
```

---

## Structure du projet

```
cartOLD/
├── R/                          # Code source de l'application
│   ├── app_config.R            # Configuration golem et chemins
│   ├── app_ui.R                # Interface utilisateur principale
│   ├── app_server.R            # Logique serveur principale
│   ├── run_app.R               # Fonction de lancement
│   ├── import_data.R           # Chargement des données GeoParquet
│   ├── golem_utils.R           # Utilitaires golem
│   ├── mod_accueil.R           # Module page d'accueil
│   ├── mod_aide.R              # Module aide utilisateur
│   ├── mod_avertissement.R     # Module modale d'avertissement
│   ├── mod_carte.R             # Module carte principale (Leaflet)
│   ├── mod_carte_aide.R        # Module aide contextuelle carte
│   ├── mod_carte_controls.R    # Module contrôles flottants
│   └── mod_carte_export.R      # Module export PNG/PDF
├── inst/
│   ├── app/
│   │   ├── extdata/            # Données spatiales GeoParquet (non versionnées)
│   │   └── www/
│   │       ├── css/style.css   # Feuille de styles principale
│   │       ├── js/script.js    # Scripts JavaScript personnalisés
│   │       ├── html/           # Pages HTML compilées (accueil, aide…)
│   │       ├── icones/         # Favicon de l'application
│   │       └── images/         # Images statiques
│   └── golem-config.yml        # Configuration des environnements
├── data-raw/
│   └── pre_data.R              # Pipeline PostgreSQL → GeoParquet
├── dev/
│   ├── 01_start.R              # Initialisation du projet golem
│   ├── 02_dev.R                # Ajout de fonctions/modules
│   ├── 03_compile_rmd.R        # Compilation des pages Rmd → HTML
│   ├── 04_fix_non_ascii.R      # Correction encodage non-ASCII
│   ├── 05_deploy.R             # Scripts de déploiement
│   ├── run_dev.R               # Lancement en mode développement
│   ├── config_attachment.yaml  # Configuration des dépendances
│   └── rmd/                    # Sources Rmd des pages statiques
│       ├── accueil.Rmd
│       ├── aide.Rmd
│       ├── avertissement.Rmd
│       ├── confidentialite.Rmd
│       └── mentions_legales.Rmd
├── guides/                     # Documentation technique PDF
├── tests/
│   └── testthat/
│       └── test-app.R          # Tests unitaires
├── rsconnect/                  # Configuration déploiement shinyapps.io
├── app.R                       # Point d'entrée (déploiement direct)
├── DESCRIPTION                 # Métadonnées du package R
├── NAMESPACE                   # Exports du package
└── NEWS.md                     # Historique des versions
```

---

## Couches cartographiques

| Couche | Description | Chargement |
|---|---|---|
| `departement` | Limites départementales (Drôme) | Complet au démarrage |
| `communes` | Limites communales | Complet au démarrage |
| `communes_old200` | Communes avec zones OLD 200m | Complet au démarrage |
| `old200` | Zones OLD 200 mètres (risques incendie) | Complet au démarrage |
| `old50m` | Zones OLD 50 mètres (débroussaillement obligatoire) | Complet au démarrage |
| `parcelles` | Parcelles cadastrales | **Progressif par commune** |
| `batis` | Bâtiments | **Progressif par commune** |
| `zu` | Zonage urbain PLU | Complet au démarrage |

> Les couches lourdes (parcelles, bâtiments) utilisent un chargement progressif à la sélection
> de commune, associé à un cache `memoise` pour éviter les rechargements inutiles.

**Projection** : toutes les données sont stockées en **WGS84 (EPSG:4326)** pour une
compatibilité directe avec Leaflet, après transformation depuis Lambert 93 (EPSG:2154)
lors du pipeline de préparation.

---

## Pipeline de données

Le script `data-raw/pre_data.R` assure la chaîne de traitement **PostgreSQL/PostGIS → GeoParquet**.

### Étapes

```
PostgreSQL/PostGIS (Lambert 93 / EPSG:2154)
        │
        │  DBI + RPostgres
        ▼
  Objet sf en mémoire
        │
        │  sf::st_transform() → EPSG:4326 (WGS84)
        ▼
  Validation bbox (cohérence WGS84)
        │
        │  sfarrow::st_write_parquet()
        ▼
  GeoParquet → inst/app/extdata/
```

### Exécution du pipeline

```r
# Configurer la connexion PostgreSQL dans pre_data.R
# puis exécuter :
source("data-raw/pre_data.R")
```

### Points de vigilance

- Les données spatiales **ne sont pas versionnées** dans le dépôt Git (`.gitignore` ou `.rscignore`)
- Le script doit être exécuté par un agent disposant d'un accès à la base PostgreSQL
- Les fichiers GeoParquet doivent être régénérés à chaque mise à jour de la base source

---

## Export cartographique

### Format PNG

La capture PNG utilise la librairie JavaScript **`html2canvas`** pour photographier le
contenu DOM de la carte Leaflet. Le résultat est retourné côté serveur R via un message
JavaScript, encodé en **base64**.

### Format PDF

La génération PDF s'appuie sur **RMarkdown** :

- Gabarit A4 paysage
- Mise en page institutionnelle (logo Préfète de la Drôme)
- Intégration de la capture PNG de la carte
- Informations contextuelles (commune, date, échelle)

### Workflow d'export

```
Utilisateur clique "Générer l'aperçu"
        │
        │  JavaScript (html2canvas)
        ▼
  Capture PNG du canvas Leaflet
        │
        │  Shiny.setInputValue() → R
        ▼
  Génération aperçu (modale)
        │
        │  Choix format : PNG / PDF
        ▼
  PNG : téléchargement direct
  PDF : render RMarkdown → téléchargement
```

---

## Tests

Les tests unitaires sont écrits avec `testthat` et couvrent :

1. **Chargement de l'application** : présence des fichiers `app.R`, `app_ui.R`, `app_server.R`
2. **Structure des données** : présence des fichiers GeoParquet attendus dans `inst/app/extdata/`
3. **Assets web** : présence du CSS et du JavaScript

### Exécution des tests

```r
# Depuis la racine du projet
testthat::test_dir("tests/testthat")

# Ou via devtools
devtools::test()
```

---

## Déploiement

L'application est déployée sur **shinyapps.io** sous le compte `ssm-ecologie`.

**URL de production** : [https://ssm-ecologie.shinyapps.io/cartOLD/](https://ssm-ecologie.shinyapps.io/cartOLD/)

### Déploiement via rsconnect

```r
# Configurer le compte shinyapps.io (une seule fois)
rsconnect::setAccountInfo(
  name   = "ssm-ecologie",
  token  = "<VOTRE_TOKEN>",
  secret = "<VOTRE_SECRET>"
)

# Déployer l'application
source("dev/05_deploy.R")
```

### Variables d'environnement de production

```r
Sys.setenv(GOLEM_CONFIG_ACTIVE = "production")
```

> **Important** : les fichiers GeoParquet doivent être inclus dans le bundle de déploiement.
> Vérifier que `inst/app/extdata/` contient les données à jour avant tout déploiement.

---

## Workflow de développement

Le développement suit les étapes structurées du framework `golem` :

```
dev/01_start.R        → Initialisation du projet
dev/02_dev.R          → Développement (modules, fonctions, dépendances)
dev/03_compile_rmd.R  → Compilation Rmd → HTML (pages statiques)
dev/04_fix_non_ascii.R→ Correction des caractères non-ASCII
dev/05_deploy.R       → Déploiement sur shinyapps.io
```

### Ajouter un module

```r
# Dans dev/02_dev.R
golem::add_module(name = "nom_module")
```

### Mettre à jour les pages HTML

Modifier les fichiers sources `dev/rmd/*.Rmd`, puis recompiler :

```r
source("dev/03_compile_rmd.R")
```

### Vérifier l'encodage

```r
source("dev/04_fix_non_ascii.R")
```

---

## Historique des versions

### Version 0.0.1 (2025) — Première version de production

- Carte interactive Leaflet plein écran
- Sélection de commune avec zoom automatique
- Recherche d'adresse via API BAN
- Affichage dynamique des couches OLD (200m et 50m), communes, parcelles, bâtiments, PLU
- Échelle numérique et graphique dynamiques
- Rose des vents
- Légende dynamique
- Export PNG et PDF A4 paysage
- Cache des données spatiales avec `memoise`
- Outil de mesure de distance
- Interface responsive

---

## Licence

Ce projet est distribué sous licence **GPL (≥ 3)**.

Voir le fichier [LICENSE.md](LICENSE.md) pour les termes complets.

---

## Auteur et organisation

**Auteure** : Marie-Jeanne MARTINAT
**Contact** : marie-jeanne.martinat@i-carre.net

**Organisation** : Direction Départementale des Territoires de la Drôme (DDT 26)
**Service** : Service Eau, Forêts et Espaces Naturels — Pôle Forêt
**Ministère** : Ministère de la Transition Écologique

**Dépôt** :
[https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/cartold](https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/cartold)
