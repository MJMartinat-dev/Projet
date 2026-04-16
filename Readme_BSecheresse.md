[//]: # (0x4d4a)

<div align="center">

# BSécheresse

**Génération automatisée du Bulletin Sécheresse du département de la Drôme**  
*DDT de la Drôme · 2023–2025 · Reporting multi-formats opérationnel*

[![GitLab](https://img.shields.io/badge/GitLab-Source-FC6D26?style=flat-square&logo=gitlab&logoColor=white)](https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/bsecheresse)
![R](https://img.shields.io/badge/R-276DC3?style=flat-square&logo=r&logoColor=white)
![RMarkdown](https://img.shields.io/badge/RMarkdown-reporting-blue?style=flat-square)
![Statut](https://img.shields.io/badge/Statut-Opérationnel-22c55e?style=flat-square)

</div>

---

## Présentation

**BSécheresse** est un ensemble de scripts R permettant de générer le **Bulletin Sécheresse** du département de la Drôme.  
Les données sont téléchargées automatiquement depuis [Hub'eau](https://hubeau.eaufrance.fr/) et d'autres sources via les scripts du répertoire `R/`.

Le pipeline produit des fichiers **PDF et HTML** dans le répertoire `sorties/`, ainsi que des **cartes de restriction** par type d'eau (superficielle et souterraine).

---

## Fichiers d'entrée requis

La plupart des données sont récupérées automatiquement. Deux fichiers doivent cependant être **préparés manuellement** et placés dans `data/` avant d'exécuter les scripts :

| Fichier | Contenu |
|---|---|
| `data/seuils_hydro.csv` | Seuils mensuels pour chaque station hydrométrique |
| `data/seuils_piezo.csv` | Seuils mensuels pour chaque station piézométrique |

Ces fichiers stockent les valeurs seuils mensuelles utilisées pour déterminer les **niveaux d'alerte** : vigilance, alerte, alerte renforcée et crise.  
Ils ne sont pas distribués avec le dépôt.

### Format attendu

- Séparateur : **point-virgule** (`;`)
- Encodage : **Windows-1252**

```
stations;date;vigilance;alerte;alerte_renforcee;crise
L'Aygues à Camaret;jan;0.50;0.75;1.00;1.25
```

La colonne `date` contient les abréviations des mois (`jan`, `feb`, `mar`, ...).

> Sans ces fichiers, les scripts s'arrêtent avec un message d'erreur.

---

## Stack technique

| Composant | Technologie |
|---|---|
| Traitement des données | R · dplyr · readr · lubridate · janitor · purrr |
| Requêtes API | httr · jsonlite (Hub'eau et autres sources) |
| Reporting | rmarkdown · knitr · kableExtra |
| Cartographie | sf + shapefile secteurs de gestion fourni |
| Utilitaires | stringr · tibble · glue · here · magrittr · progress |

---

## Installation

### Prérequis

- [R](https://www.r-project.org/) installé sur la machine

### Dépendances

```r
install.packages(c(
  "dplyr", "readr", "stringr", "tibble", "glue", "here",
  "knitr", "kableExtra", "magrittr", "lubridate", "janitor",
  "purrr", "progress", "httr", "jsonlite", "rmarkdown"
))
```

---

## Utilisation

### 1. Générer le bulletin

```bash
Rscript R/render_bulletin.R
```

Produit dans `sorties/` :
- `sorties/Bulletin_Secheresse.pdf`
- `sorties/Bulletin_Secheresse.html`

### 2. Générer les cartes de restriction

```bash
Rscript R/generate_restriction_map.R
```

Produit des images **PNG** dans `sorties/` — une carte par type d'eau (superficielle et souterraine) montrant les restrictions actuelles.  
Ces images peuvent être incluses dans le bulletin si nécessaire.

Un fichier shapefile des **secteurs de gestion** est fourni dans `data/`.

---

## Structure du projet

```
bsecheresse/
├── R/
│   ├── render_bulletin.R           ← point d'entrée principal — rendu PDF + HTML
│   ├── generate_restriction_map.R  ← génération des cartes de restriction
│   └── ...                         ← scripts d'aide (téléchargement, traitement)
├── data/
│   ├── seuils_hydro.csv            ← ⚠️ à préparer préalablement (non distribué)
│   ├── seuils_piezo.csv            ← ⚠️ à préparer préalablement (non distribué)
│   └── [shapefile secteurs]        ← secteurs de gestion (fourni)
└── sorties/                        ← livrables générés
    ├── Bulletin_Secheresse.pdf
    ├── Bulletin_Secheresse.html
    └── [cartes PNG]
```

---

## Livrables produits

| Format | Contenu | Usage |
|---|---|---|
| **PDF** | Bulletin mis en page, imprimable | Diffusion officielle, archives |
| **HTML** | Bulletin interactif navigable | Partage web, consultation en ligne |
| **PNG** | Cartes de restriction par type d'eau | Intégration dans le bulletin ou diffusion séparée |
| **XLSX** | Graphiques par stations avec tableaux|

---

## Données sources

- **Hub'eau** ([hubeau.eaufrance.fr](https://hubeau.eaufrance.fr/)) — données hydrométrique et piézométrique en temps réel
- **Fichiers seuils** — préparés par les services DDT à partir des données réglementaires locales
- **Shapefile secteurs de gestion** — fourni dans `data/`

---

## Liens

| | |
|---|---|
| 📁 Portfolio | [Voir le portfolio](../../portfolio/README.md) |
| 📬 Contact | ddt-sefen-pf@drome.gouv.fr |

---

<sub>Auteure : Marie-Jeanne Martinat · DDT de la Drôme · Licence GPL ≥ 3</sub>
