```{=html}
<style>
body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
}

h1 {
    text-align: center;
    color: #1f4e79;
    font-size: 28px;
    margin-bottom: 5px;
}

h2 {
    text-align: center;
    font-weight: normal;
    margin-top: 0;
}

.section-title {
    background-color: #1f4e79;
    color: white;
    padding: 8px 12px;
    font-weight: bold;
    margin-top: 30px;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 10px;
}

th {
    background-color: #dde6f1;
    border: 1px solid #999;
    padding: 6px;
}

td {
    border: 1px solid #999;
    padding: 6px;
}

code {
    background-color: #f2f2f2;
    padding: 2px 4px;
}
</style>
```
# GUIDE TECHNIQUE

## render_bulletin.R

Document de maintenance pour la génération du bulletin sécheresse

::: section-title
OBJECTIF DU SCRIPT
:::

Ce script génère automatiquement le bulletin sécheresse en deux formats
:

  Format   Utilisation
  -------- ------------------------------------------------
  PDF      Impression, envoi par mail, archivage officiel
  HTML     Consultation en ligne, partage web

Les fichiers générés sont nommés avec la date du jour :

    Bulletin_Secheresse_2025-01-07.pdf
    Bulletin_Secheresse_2025-01-07.html

::: section-title
PRÉREQUIS
:::

### Logiciels nécessaires

• R (version 4.0 ou supérieure)\
• RStudio (recommandé)\
• TinyTeX (pour générer les PDF) → Installation :
`tinytex::install_tinytex()`

### Packages R nécessaires

Pour les installer, tapez dans la console R :

    install.packages(c("rmarkdown", "here", "glue"))

  Package     Rôle
  ----------- -----------------------------------------
  rmarkdown   Convertit les fichiers .Rmd en PDF/HTML
  here        Trouve les fichiers dans le projet
  glue        Insère des variables dans du texte

::: section-title
ORGANISATION DES FICHIERS
:::

    Secheresse/ ← RACINE DU PROJET
    ├── R/
    │   └── render_bulletin.R ← CE SCRIPT
    ├── fichiers/Rmd/
    │   └── bulletin_secheresse.Rmd ← TEMPLATE
    └── sorties/bulletins/
        ├── pdf/ ← SORTIE PDF
        └── html/ ← SORTIE HTML

::: section-title
EXPLICATION DU CODE
:::

`library(rmarkdown)`\
Rôle : Active le package rmarkdown pour convertir les fichiers .Rmd en
PDF/HTML.

`library(here)`\
Rôle : Active le package here qui permet de trouver les fichiers dans le
projet.

`library(glue)`\
Rôle : Active le package glue pour insérer des variables dans du texte.

`date_enregistrement <- format(Sys.Date(), "%Y-%m-%d")`\
Rôle : Récupère la date du jour et la formate en texte AAAA-MM-JJ.

  Élément       Signification
  ------------- -----------------------------
  Sys.Date()    Récupère la date système
  format(...)   Convertit en texte
  %Y            Année sur 4 chiffres (2025)
  %m            Mois sur 2 chiffres (01-12)
  %d            Jour sur 2 chiffres (01-31)

`rmarkdown::render(...)`\
Rôle : Convertit le fichier template .Rmd en document final.

  Paramètre       Rôle
  --------------- -------------------------------------------------
  input           Chemin vers le fichier template source
  output_format   Type de fichier (pdf_document ou html_document)
  output_file     Nom du fichier à créer
  output_dir      Dossier de destination

::: section-title
MODIFICATIONS COURANTES
:::

**Changer le dossier de sortie**

Avant :

    output_dir = here::here("sorties", "bulletins", "pdf")

Après :

    output_dir = here::here("exports", "pdf")

**Changer le nom des fichiers**

Avant :

    output_file = glue("Bulletin_Secheresse_{date_enregistrement}.pdf")

Après :

    output_file = glue("BSH_Drome_26_{date_enregistrement}.pdf")

**Générer pour une date spécifique**

Avant :

    date_enregistrement <- format(Sys.Date(), "%Y-%m-%d")

Après :

    date_enregistrement <- "2025-06-15"

⚠️ N'oubliez pas de remettre Sys.Date() après !

::: section-title
RÉSOLUTION DES ERREURS
:::

"there is no package called 'xxx'"\
Cause : Le package n'est pas installé.\
Solution :

    install.packages("xxx")

"pdflatex is not available"\
Cause : TinyTeX n'est pas installé.\
Solution :

    install.packages("tinytex")
    tinytex::install_tinytex()

Puis redémarrez RStudio.

"cannot open file '...bulletin_secheresse.Rmd'"\
Cause : Le fichier template n'est pas trouvé.

Solutions : • Vérifiez que le fichier existe dans fichiers/Rmd/\
• Ouvrez le projet via le fichier .Rproj

------------------------------------------------------------------------

Document rédigé par MJ Martinat - DDT Drôme
