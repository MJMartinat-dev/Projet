# Guide méthodologique OLD50m — Procédure opérationnelle 


## 1. Objectif du document
Ce guide fournit une **méthode pas-à-pas**, utilisable même par un novice en géomatique ou programmation,
pour produire les 4 couches OLD50m utiles à la DFCI :
- Les limites du parcellaire de la commune -> `[code_insee]_parcelle`
- Les bâtiments de la commune -> `[code_insee]_bati`
- Le zonage urbain réaligné sur les parcelles -> `[code_insee]_zonage_corr7` 
- Le zonage des Obligations légales de débroussaillement par commune et comptes communaux -> `[code_insee]_result4`

Il décrit les outils nécessaires, les données à préparer, les étapes de calcul (sans code, seulement la logique),
les contrôles qualité et la visualisation dans QGIS, ainsi qu’une ouverture vers la diffusion web via CARTOLD
(R Shiny Golem).

---

## 2. Présentation de l’outil
### 2.1 Objectif :
**OLD50m** est une procédure SQL/PostGIS qui calcule l’**obligation légale de débroussaillement**
dans un rayon de **50 m** autour des bâtiments et certaines infrastructures issues des zones d’activité 
ou d’intérêt et des cimetières qui se situe dans les **zones à risques situées à moins de 200m autour des 
massifs forestiers de 0,5ha**.

---

### 2.2 Fonctionnement :
Le traitement :
 1. restreint les données à la commune cible ;
 2. sélectionne les déclencheurs pertinents ;
 3. génère des tampons de 50 m autour des bâtis et infrastructures puis les nettoie ;
 4. corrige le zonage urbain via une chaîne de corrections (corr1 → … → corr7) ;
 5. croise les zones OLD avec les parcelles et unités foncières ;
 6. attribue un propriétaire (`comptecommunal`) ;
 7. arbitre les chevauchements par découpage Voronoï le long des limites bâties ;
 8. agrège les résultats par propriétaire ;
 9. identifie les zones non arbitrées restantes ;
 10. arbitre ces nouveaux ilôts ;
 11. agrège les résultats par propriétaire ;
 12. agrège le premiers résultats d'arbitrage avec le second ;
 13. ajoute les éoliennes (règle particulière) ;
 14. produit la table finale `result4` : la zone indicative des Obligations Légales de Débroussaillements par propriétaire.

---

## 3. Présentation du langage et des différentes versions de code
### 3.1 Langage de programmation :
  - **SQL (PostgreSQL + PostGIS)**

---

### 3.2 Où trouver le code :
  Localisation des scripts : 
      - "../script/Outil_OLD50m/"

---

### 3.3 Versions disponibles :
  - `OLD50m_v1.16a.sql`
  - `OLD50m_v1.16ac.sql`
  - `OLD50m_v1.16b.sql`
  - `OLD50m_v1.16bc.sql`

  - Script pour chargement des données de la BDTopo avec geometrie (imports QGIS ou GeoPackage) : 
      - OLD50m_v.1.16ac.sql et OLD50m_v1.16bc.sql 
  - Script pour chargement des données de la BDTopo avec geom (cas fréquent via ogr2ogr, Shapefile, ou certains modèles) :  
      - OLD50m_v.1.16a.sql et OLD50m_v1.16b.sql

---

### 3.3 Détermination automatique de la version à utiliser :
  - Contrôler les trois tables BD TOPO utilisées (batiment, cimetiere, zone_d_activite_ou_d_interet) :

______________________________________________________________________________________________________________________________________________________
WITH cible AS (                                                                                   -- liste des tables BD TOPO à contrôler
  SELECT unnest(ARRAY['batiment','cimetiere','zone_d_activite_ou_d_interet']) AS table_name       -- tables cibles : bâti, cimetière, ZA/ZI
),                                                                                                 -- fin CTE cible
geo_cols AS (                                                                                      -- CTE : détecter la présence des noms de colonnes géométriques
  SELECT c.table_name,                                                                             -- nom de la table
         MAX(CASE WHEN c.column_name = 'geometrie'    THEN 1 ELSE 0 END) AS a_geometrie,          -- 1 si la colonne 'geometrie' existe
         MAX(CASE WHEN c.column_name = 'geom'         THEN 1 ELSE 0 END) AS a_geom,               -- 1 si la colonne 'geom' existe
         MAX(CASE WHEN c.column_name = 'wkb_geometry' THEN 1 ELSE 0 END) AS a_wkb                 -- 1 si la colonne 'wkb_geometry' existe
  FROM information_schema.columns c                                                                -- métadonnées du schéma (colonnes)
  JOIN cible t ON t.table_name = c.table_name                                                      -- on limite l’analyse aux tables cibles
  WHERE c.table_schema = 'r_bdtopo'                                                                -- dans le schéma BD TOPO
  GROUP BY c.table_name                                                                            -- une ligne agrégée par table
)                                                                                                  -- fin CTE geo_cols
SELECT table_name AS table_bdtopo,                                                                 -- table contrôlée
       CASE                                                                                         -- détermination du nom de la colonne géométrique
         WHEN a_geometrie = 1 THEN 'geometrie'                                                     -- résultat : 'geometrie'
         WHEN a_geom      = 1 THEN 'geom'                                                          -- résultat : 'geom'
         WHEN a_wkb       = 1 THEN 'wkb_geometry'                                                  -- résultat : 'wkb_geometry'
         ELSE 'absent'                                                                             -- aucune colonne géométrique détectée
       END AS colonne_geo_detectee                                                                 -- colonne géométrique retenue
FROM geo_cols                                                                                      -- CTE précédente
ORDER BY table_name;                                                                               -- tri par nom de table pour lecture
______________________________________________________________________________________________________________________________________________________

---

## 4. Outils nécessaires 
### 4.1 Base de données PostgreSQL / PostGIS
#### Versions recommandées
- **PostgreSQL ≥ 16.0** (installation locale ou serveur dédié)  
- **PostGIS ≥ 3.5.0** (extension spatiale obligatoire)

---

#### Installation et configuration
- **Windows**  
  - Télécharger l’installeur officiel sur [postgresql.org](https://www.postgresql.org/download/windows/).  
  - Installer via Stack Builder → cocher **PostGIS**.  
  - Vérifier que le service PostgreSQL démarre automatiquement.  

- **macOS**  
  - Installation via [Postgres.app](https://postgresapp.com/) (GUI et services intégrés),  
  - ou via Homebrew :  
    ```bash
    brew install postgresql postgis
    ```  
  - Activer PostGIS dans chaque base :  
    ```sql
    CREATE EXTENSION postgis;
    ```

- **Linux (Debian/Ubuntu)**  
  - Paquets disponibles via apt :  
    ```bash
    sudo apt update
    sudo apt install postgresql postgis postgresql-contrib
    ```  
  - Vérifier la version avec :  
    ```bash
    psql --version
    ```

---

### 4.2 Outils SIG et utilitaires complémentaires
#### QGIS (≥ 3.22)
**Rôle** :  
- Visualisation cartographique, contrôle qualité visuel, export de couches.  
- Indispensable pour l’interprétation des résultats et la validation opérationnelle.  
- Plugin **Cadastre** : import du PCI (Plan Cadastral Informatisé) et gestion des données cadastrales.

**Installation** :  
- **Windows** : télécharger depuis [qgis.org](https://qgis.org/downloads/). Choisir la version LTR (Long Term Release) pour plus de stabilité.  
- **macOS** : installer via Homebrew :  
  ```bash
  brew install qgis
  ```  
  ou utiliser les paquets `.dmg` disponibles sur [qgis.org](https://qgis.org/downloads/).  
- **Linux (Debian/Ubuntu)** :  
  ```bash
  sudo apt update
  sudo apt install qgis python3-qgis qgis-plugin-grass
  ```

**Bonnes pratiques** :  
- Toujours installer la version LTR pour les environnements de production.  
- Vérifier que le plugin Cadastre est activé (`Extensions > Installer/Gérer les extensions`).  

---

#### pgAdmin 4
**Rôle** :  
- Administration et gestion PostgreSQL/PostGIS.  
- Suivi des transactions, plan d’exécution des requêtes, gestion des rôles et droits, export SQL.  

**Installation** :  
- **Windows & macOS** : paquets disponibles sur [pgadmin.org](https://www.pgadmin.org/download/).  
- **Linux (Debian/Ubuntu)** :  
  ```bash
  sudo apt install pgadmin4
  ```

**Bonnes pratiques** :  
- Créer une connexion dédiée par projet (ici `old50m`).  
- Sauvegarder régulièrement les scripts SQL exécutés (journalisation).  

---

#### GDAL/OGR (≥ 3.6)
**Rôle** :  
- Conversion et traitement de données géospatiales (raster et vecteur).  
- Outils en ligne de commande pour importer/exporter les données vers PostGIS.  
- Vérification des métadonnées et des projections.  

**Installation** :  
- **Windows** : via OSGeo4W (choisir **GDAL**).  
- **macOS** :  
  ```bash
  brew install gdal
  ```  
- **Linux (Debian/Ubuntu)** :  
  ```bash
  sudo apt install gdal-bin
  ```

**Commandes principales utilisées** :  
- Import/export de couches :  
  ```bash
  ogr2ogr -f "PostgreSQL" PG:"dbname=old50m user=postgres" source.gpkg
  ```  
- Vérification des projections :  
  ```bash
  gdalinfo source.gpkg
  ```

**Bonnes pratiques** :  
- Toujours vérifier le **SRID** avant import (`EPSG:2154` attendu).  
- Utiliser GeoPackage (`.gpkg`) plutôt que Shapefile (limite en taille/attributs).  


---

### 4.3 Points de vigilance
- **Compatibilité versions** : vérifier que QGIS ↔ PostGIS ↔ PostgreSQL sont cohérents (ex. QGIS 3.22 peut refuser une base PostGIS < 3.0).  
- **Performances** : privilégier une installation **locale ou serveur LAN** pour limiter les latences lors des unions spatiales lourdes.  
- **Traçabilité** : maintenir un journal des versions de PostgreSQL/PostGIS utilisées dans la production (utile pour audits DFCI).

---

## 5. Données et paramètres
### 5.1 Données sources attendues (SRID : EPSG:2154)
_________________________________________________________________________________________________________________
| Designation              | Schéma.Table                            | Champs utiles    | Définition             |
|--------------------------|-----------------------------------------|------------------|---------------------   |
| old200m                  | `public.old200m`                        |`geom`            | Zone à risque autour   |
|                          |                                         |                  | des massifs forestiers |
|--------------------------|-----------------------------------------|------------------|------------------------|
| Commune                  | `r_cadastre.geo_commune`                | `idu` (= INSEE), | Emprise communale      | 
|                          |                                         | `geom`           |                        |
|--------------------------|-----------------------------------------|------------------|------------------------|
| Parcelles                | `r_cadastre.parcelle_info`              | `idu`, `         | Délimitation des       |
|                          |                                         | `comptecommunal`,| parcelles              | 
|                          |                                         | `geom`           |                        | 
|--------------------------|-----------------------------------------|------------------|------------------------|
| Unités foncières         | `r_cadastre.geo_unite_fonciere`         | `geom`           | Ensemble de parcelles  |
|                          |                                         |                  | contiguës d'un même    |
|                          |                                         |                  | propriétaire           |
|--------------------------|-----------------------------------------|------------------|------------------------|
| Bâtiments                | `r_bdtopo.batiment`                     | type/nature,     | Ensemble des batiments |                      |
|                          |                                         | `geom`           | nationals              | 
|--------------------------|-----------------------------------------|------------------|------------------------|
| Eoliennes                | `public.eolien_filtre`                  | `geom`           | Réseau éolien national |
|--------------------------|-----------------------------------------|------------------|------------------------|
| Zones d’activité/intérêt | `r_bdtopo.zone_d_activite_ou_d_interet` | `nature`,        | Parcs photovoltaïques  |
|                          |                                         | `geom`           | Campings
|                          |                                         |                  | CTE                    | 
|--------------------------|-----------------------------------------|------------------|------------------------|
| Autres                   | `r_bdtopo.cimetiere`                    | `geom`           | Cimetières             |
|__________________________|_________________________________________|__________________|________________________|

Exemple : `"13022_wold50m"`.  
Ce schéma contient toutes les tables intermédiaires et finales liées à la commune.

---

### 5.2 Paramètres opérationnels
#### Paramétrage par commune
Avant exécution, travailler sur une **copie** du script choisi (ex. `OLD50m_v1.16b.sql`)  
et remplacer les *placeholders* par les identifiants de la commune cible :

- **`26xxx` → code INSEE (5 chiffres)**  
  Exemple : `13022` (Marseille 2ᵉ arrondissement).  
  → Correspond au champ officiel `idu` dans `geo_commune`.  

- **`xxx` → 3 derniers chiffres du code INSEE**  
  Exemple : `022` pour la commune `13022`.  
  → Utilisé par certains imports PCI et variantes de scripts.  

- **`260xxx` → code technique à 6 chiffres**  
  Exemple : `130022`.  
  → Clé composite utilisée dans certains contextes (plugin Cadastre, interopérabilité PCI).  

Le **schéma de travail** suit la convention :  
"<INSEE>_wold50m"

Exemple : `"13022_wold50m"`.  
Ce schéma contient toutes les tables intermédiaires et finales liées à la commune.

---

#### Paramètres opérationnels
- **Schémas source** :  
  - `r_cadastre` : parcelles, unités foncières, communes  
  - `r_bdtopo` : bâtiments, cimetières, zones d’activité  
  - `public` : zone à risque de 200m autour des massifs forestiers, répertoire national des éoliennes, les zonage urbain de la commune
  - ⚠️ Ces noms peuvent être adaptés si vos données sources sont chargées dans d’autres schémas.

- **Distance de tampon** :  
  - Standard : **50 m** autour des déclencheurs (bâtis, cimetières, zones d’activité).  
  - Exceptions : **100 m** sur les installations classées SEVESO, certains PPRIF (Plans de Prévention des Risques Incendie de Forêt) ou par décision municipale.  
  - Ces adaptations doivent être validées par l’autorité compétente avant exécution.

- **Seuils surfaciques** :  
  - Standard : suppression des fragments < **6 m²**.  
  - Optionnel : dans certains contextes, seuil relevé à **6 m²** (adaptation locale ou optimisation des résultats).  
  - Objectif : éliminer les polygones résiduels parasites et améliorer la lisibilité cartographique.

---

#### Bonnes pratiques
- Toujours consigner les **paramètres spécifiques** (tampon > 50 m, seuils modifiés) dans un **journal de traitement**.  
- Préférer un script distinct par commune (ex. `OLD50m_v1.16b_13022.sql`) plutôt que de modifier en continu un même fichier.  
- Vérifier après exécution que le schéma produit (`<INSEE>_wold50m`) contient bien les 4 couches finales attendues :  
  - `<INSEE>_parcelle`  
  - `<INSEE>_bati`  
  - `<INSEE>_zonage_corr7`  
  - `<INSEE>_result4`


---

## 7. Étapes de calcul (sans code, mais détaillées)

### 7.1 Les 5 règles structurantes
1. **Restriction communale** : ne traiter que l’emprise de la commune cible.  
2. **Déclencheurs** : bâtis, cimetières, zones d’activités/intérêt issues de la BD TOPO®, filtrés et nettoyés.  
3. **Tampons 50 m** : générer et agréger des buffers normalisés autour des déclencheurs.  
4. **Zonage urbain corrigé** : exclure ou limiter via le document d’urbanisme, corrigé par une chaîne de traitements (corr1 → corr7).  
5. **Parcellaire et propriétaires** : affecter les polygones OLD au champ `comptecommunal`, arbitrer les chevauchements (Voronoï/îlots), consolider les résultats.

### 7.2 Fil technique détaillé (14 étapes)
#### **PARTIE 1 : Gestion du parcellaire cadastral**
- Extraction des parcelles de la commune
- Regroupement en une géométrie unique
- Indexation spatiale pour optimisation

#### **PARTIE 3 : Parcellaire non cadastré**
- Identification des zones non cadastrées (différence commune/parcelles)
- Préparation pour exclusion ultérieure

#### **PARTIE 4 : Gestion des bâtiments**
- Extraction des bâtiments > 6m²
- Exclusion des zones spécifiques (cimetières, campings, etc.)
- Identification dans la zone OLD 200m
- Association aux comptes communaux
- Création tampons 50m

#### **PARTIE 5 : Correction zonage urbain**
- Import/création des zones urbaines
- Correction géométrique (snap sur parcelles)
- Élimination des épines géométriques

#### **PARTIE 6 : Gestion des superpositions**
- Identification des intersections entre tampons
- Soustraction des zones urbaines
- Regroupement des zones d'arbitrage

#### **PARTIE 7-8 : Unités foncières et parcelles bâties**
- Consolidation des unités foncières
- Association parcelles/bâtiments
- Préparation pour Voronoï

#### **PARTIE 9 : Polygones de Voronoï**
- Interpolation de points sur contours (1m)
- Génération des polygones de Voronoï
- Attribution aux comptes communaux

#### **PARTIE 10 : Arbitrage des responsabilités**
- Algorithme complexe d'attribution
- Gestion des zones partagées
- Consolidation par propriétaire

#### **PARTIES 11-14 : Traitement des zones résiduelles**
- Identification des "trous" non arbitrés
- Création d'îlots géométriques
- Application Voronoï sur îlots
- Attribution finale

#### **PARTIE 15 : Finalisation**
- Fusion des résultats
- Intersection avec zone OLD 200m
- Nettoyage géométrique final


---

## 7. Résultats attendus
Les résultats attendus de cette méthodologie incluent plusieurs couches géographiques essentielles pour l'analyse et la gestion des données communales. Voici un aperçu des couches à produire :

<INSEE>_parcelle : Cette couche représente les limites parcellaires de la commune, fournissant une base géographique pour toutes les analyses ultérieures.
<INSEE>_bati : Cette couche inclut les bâtiments situés dans la commune, classés selon leur zone d'Obligation Légale de Débroussaillement (OLD), qu'ils soient en zone avec ou sans OLD.
<INSEE>_zonage_corr7 : Cette couche présente le zonage urbain de la commune, réaligné sur les limites parcellaires, permettant une meilleure compréhension des réglementations d'urbanisme.
<INSEE>_result4 : Cette couche indique les zones d'Obligations Légales de Débroussaillement attribuées à chaque propriétaire, où chaque compte communal correspond à un propriétaire unique.
---

## 8. Visualisation (QGIS)

Pour visualiser les résultats dans QGIS, suivez les étapes ci-dessous :

- Créer une connexion PostGIS vers la base de données old50m.
- Charger les 4 couches depuis le schéma "<INSEE>_wold50m".
- Symbologie conseillée :
    - <INSEE>_result4 : Utiliser un remplissage catégorisé aux compte communaux de couleur aléatoire semi-transparent avec un contour net. Ajouter des étiquettes basées sur comptecommunal pour identifier les zones.
    - <INSEE>_bati : Appliquer des symboles contrastés avec une couleur correspondant à la base de données Topographique (BDTopo) pour une meilleure visibilité.
    - <INSEE>_parcelle : Utiliser des traits fins orange sans aplat de couleur pour délimiter les parcelles sans surcharger la carte.
    - <INSEE>_zonage_corr7 : Appliquer des pointillés noirs sans aplat de couleur pour représenter le zonage de manière claire.

- Contrôles visuels rapides : Effectuer des vérifications sur les distances, les chevauchements et les continuités entre les différentes couches pour assurer l'intégrité des données.
- Export : Il est recommandé d'exporter les données au format GeoPackage, mais les formats GeoJSON ou Shapefile peuvent également être utilisés selon les besoins.

---

## 9. Prochainement — CARTOLD (R Shiny Golem)

Le projet CARTOLD vise à offrir une publication interactive des résultats, permettant aux utilisateurs de filtrer les cartes par commune ou par propriétaire. Voici les étapes de préparation :

- Vues SQL simplifiées : Créer des vues SQL simplifiées pour chaque commune afin de faciliter l'accès aux données.
E- xports versionnés : Préparer des exports en GeoPackage et GeoJSON qui seront versionnés pour assurer la traçabilité des données.
C- atalogue de métadonnées : Établir un catalogue de métadonnées comprenant le titre, un résumé, la projection utilisée et la date de création des données.
Attention aux points suivants :
- Simplification géométrique : Mettre en place une simplification géométrique côté serveur pour améliorer les performances de l'application.
- Protection des données nominatives : Assurer la protection des données sensibles, notamment celles liées au comptecommunal.
- Traçabilité des versions : Maintenir une traçabilité des versions des données, incluant des informations sur la variante du script, la date de mise à jour et le code INSEE associé.

Cette méthodologie vise à garantir une gestion efficace et sécurisée des données tout en facilitant leur accessibilité et leur utilisation par les parties prenantes.

---
