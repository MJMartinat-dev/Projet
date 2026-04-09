<h1 align="center">GUIDE TECHNIQUE</h1>
<h2 align="center"><code>utils.R</code></h2>
<p align="center"><em>Fonctions utilitaires pour les tableaux du bulletin sécheresse</em></p>

---

<h2 style="background-color:#2E74B5;color:white;padding:5px;">OBJECTIF DU SCRIPT</h2>

Ce script contient les fonctions utilitaires pour générer les tableaux colorés du bulletin :

| Fonction | Rôle |
|----------|------|
| `echapper_latex()` | Échappe les caractères spéciaux LaTeX |
| `echapper_html()` | Échappe les caractères spéciaux HTML |
| `echapper_format()` | Choisit automatiquement le bon échappement |
| `nettoyer_nom_station()` | Nettoie et formate les noms de stations |
| `couleur_seuil()` | Retourne une couleur selon valeur et seuils |
| `generer_bloc_secteur()` | Génère les tableaux colorés par secteur |

<h2 style="background-color:#2E74B5;color:white;padding:5px;">PRÉREQUIS</h2>

Packages R nécessaires :

```r
install.packages(c("dplyr", "stringr", "glue", "knitr", "kableExtra", "progress"))
```

<h2 style="background-color:#2E74B5;color:white;padding:5px;">FICHIERS UTILISÉS</h2>

<h3 style="border-bottom:2px solid #2E74B5;">Entrées</h3>

| Fichier | Description |
|---------|-------------|
| `donnees/bulletin/origines/restrictions.csv` | Niveaux de restriction par secteur |
| `seuils_hydro` (paramètre) | Référentiel seuils hydrologiques |
| `seuils_piezo` (paramètre) | Référentiel seuils piézométriques |

<h2 style="background-color:#2E74B5;color:white;padding:5px;">CODES DE RESTRICTION</h2>

| Code | Libellé | Couleur |
|------|---------|---------|
| N | Pas de restriction | Bleu clair #e6efff |
| V | Vigilance | Jaune #f7efa5 |
| A | Alerte | Orange #ffb542 |
| Ar | Alerte renforcée | Rouge/orange #ff4a29 |
| C | Crise | Rouge foncé #ad0021 |

<h2 style="background-color:#2E74B5;color:white;padding:5px;">MODIFICATIONS COURANTES</h2>

<h3 style="border-bottom:2px solid #2E74B5;">Changer les couleurs</h3>

Où : Section 4 (restrictions) et fonction `couleur_seuil()`

Exemple : Changer la couleur de Vigilance

➢ AVANT :
```r
restrictions == "V"  ~ "#f7efa5"
```

➢ APRÈS :
```r
restrictions == "V"  ~ "#90EE90"
```

<h3 style="border-bottom:2px solid #2E74B5;">Changer les largeurs de colonnes</h3>

Où : Fonction `generer_bloc_secteur()`, section 6.3.2 (LaTeX) ou 6.3.3 (HTML)

Exemple LaTeX :

➢ `kableExtra::column_spec(2, width = "10cm")`

Exemple HTML :

➢ `kableExtra::column_spec(2, width = "400px")`

<h3 style="border-bottom:2px solid #2E74B5;">Ajouter un nouveau niveau de restriction</h3>

➢ Ajouter le code dans `restriction_txt`

➢ Ajouter la couleur dans `couleur_restriction`

➢ Répéter pour `perspectives_txt` et `couleur_perspective`

➢ Ajouter dans `couleur_seuil()` si applicable

<h2 style="background-color:#2E74B5;color:white;padding:5px;">RÉSOLUTION DES ERREURS</h2>

<h3 style="border-bottom:2px solid #2E74B5;">"could not find function"</h3>

Cause : Package non chargé.

➢ Vérifiez que tous les `library()` sont exécutés.

<h3 style="border-bottom:2px solid #2E74B5;">Couleurs non affichées</h3>

Cause : Valeurs NA dans les colonnes couleur.

➢ Le script remplace automatiquement les NA par #FFFFFF.

<h3 style="border-bottom:2px solid #2E74B5;">Caractères mal affichés (accents)</h3>

Cause : Problème d'encodage du fichier restrictions.csv.

➢ Vérifiez l'encodage Windows-1252 ou modifiez :

```r
locale = readr::locale(encoding = "UTF-8")
```

<h3 style="border-bottom:2px solid #2E74B5;">Tableau trop large (PDF)</h3>

Cause : Noms de stations trop longs.

➢ L'option `scale_down` est activée. Si insuffisant, réduire `font_size` :

```r
font_size = 8
```

---

<p align="center"><em>Document rédigé par MJ Martinat - DDT Drôme</em></p>
