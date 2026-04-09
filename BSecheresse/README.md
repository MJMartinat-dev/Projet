# Bulletin Sécheresse

Ce dépôt contient les scripts R utilisés pour générer le "Bulletin Sécheresse"
pour le département de la Drôme. Les données sont téléchargées depuis Hub'eau et d'autres sources
via les scripts d'aide trouvés dans le répertoire `R/`.

## Fichiers d'entrée requis

La plupart des données sont récupérées automatiquement, cependant deux fichiers doivent être préparés
manuellement et placés dans le répertoire `data/` avant d'exécuter les scripts :

- `seuils_hydro.csv`
- `seuils_piezo.csv`

Ces tables stockent les valeurs seuils mensuelles pour chaque station de surveillance et sont
utilisées pour déterminer les niveaux d'alerte (vigilance, alerte, alerte renforcée et crise).
Elles ne sont pas distribuées avec le référentiel.

### Création des fichiers

Chaque CSV doit utiliser un point-virgule (`;`) comme séparateur et être encodé en utilisant
`Windows-1252`. La structure minimale attendue par le code est la suivante :

```
stations;date;vigilance;alerte;alerte_renforcee;crise
L'Aygues à Camaret;jan;0.50;0.75;1.00;1.25
```

La colonne `date` doit contenir les abréviations des mois (par exemple `jan`, `feb`, ...).
Remplissez les lignes avec vos propres valeurs de seuil pour chaque station et chaque mois,
puis sauvegardez les deux fichiers sous `data/seuils_hydro.csv` et
`data/seuils_piezo.csv` respectivement.

Sans ces fichiers, les scripts s'arrêteront avec un message d'erreur.

## Conditions requises

Vous devez avoir [R](https://www.r-project.org/) installé sur votre machine. Les scripts
dépendent également de plusieurs paquets R. Ils peuvent être installés avec :


Traduit avec DeepL.com (version gratuite)

```r
install.packages(c(
  "dplyr", "readr", "stringr", "tibble", "glue", "here",
  "knitr", "kableExtra", "magrittr", "lubridate", "janitor",
  "purrr", "progress", "httr", "jsonlite", "rmarkdown"
))
```
## Rendre le bulletin

Après avoir installé les paquets et préparé les fichiers d'entrée, exécutez :

```bash
Rscript R/render_bulletin.R
```

Le script produit maintenant des fichiers PDF et HTML dans le répertoire `sorties/` :
`sorties/Bulletin_Secheresse.pdf` et `sorties/Bulletin_Secheresse.html`.

## Générer des cartes de restriction

Un fichier shapefile des secteurs de gestion est fourni dans le répertoire `data/`. Exécutez le script
suivant pour créer une carte par type d'eau (superficielle et
souterraine) montrant les restrictions actuelles :

```bash
Rscript R/generate_restriction_map.R
```

Les images PNG résultantes sont sauvegardées dans le répertoire `sorties/` et peuvent être
incluses dans le bulletin si nécessaire.
