# Projet OLD50m — Prévention des incendies de forêt  
Documentation consolidée — Modules 0, 1 et 2  
PostgreSQL 16 · PostGIS 3.5.3 · GEOS 3.13.1  

---

## Introduction

Le projet OLD50m est une suite de scripts SQL destinés à automatiser le calcul des obligations légales de débroussaillement autour des bâtiments et des infrastructures.  
Il s’appuie sur une base PostgreSQL/PostGIS et sur des données cadastrales, forestières et urbanistiques.  
L’objectif est de déterminer, pour chaque bâtiment, la zone à débroussailler selon la réglementation, et d’identifier le ou les propriétaires responsables, même en cas de superposition d’obligations.

Le système a été conçu pour fonctionner à l’échelle communale ou départementale, selon la structuration de la base.  
Les traitements produisent des couches SIG prêtes à être intégrées dans QGIS ou tout autre outil géomatique.

---

## Objectifs

- Identifier et arbitrer les zones à débroussailler conformément au Code forestier.  
- Générer automatiquement les couches spatiales correspondantes.  
- Faciliter leur intégration dans un SIG pour la cartographie et la gestion.  
- Automatiser les traitements afin d’assurer un suivi et une mise à jour régulière.

---

## Contexte réglementaire

Les scripts intègrent les règles principales du Code forestier, notamment :  
1. Les terrains situés à moins de 200 mètres d’un massif forestier sensible (article L134-9).  
2. L’obligation de débroussailler dans un rayon de 50 mètres autour de tout bâtiment ou installation.  
3. Le débroussaillement obligatoire sur l’ensemble des terrains situés en zone urbaine (zone U).  
4. En cas de superposition, la mise en œuvre de l'obligation incombe au propriétaire de la parcelle dès lors qu'il y est lui-même soumis.  
5. En cas de superposition sur la parcelle d'un tiers lui-même non tenu à une telle obligation, chacune des personnes concernées débroussaille les parties les plus proches des limites de parcelles abritant sa construction ou son installation.

---

## Structure du projet

Le traitement repose sur trois modules indépendants mais complémentaires :

| Module| Fichier                         | Rôle                                                     |
|-------|---------------------------------|----------------------------------------------------------|
|   0   | MODULE_0_creationbd_v0.1.sql    | Création des schémas et préparation de la base           |
|   1   | MODULE_1_zonage_global_v1.1.sql | Nettoyage, homogénéisation et fusion des zonages urbains |
|   2   | MODULE_2_OLD50m_v2.2.sql        | Calcul des OLD sur une commune                           |
|   2   | MODULE_2_sql_to_python.py       | Génère le script python MODULE_2_OLD50m_v2.2.py          |
|   2   | MODULE_2_OLD50m_v2.2.py         | Calcul des OLD sur un département                        |

---

## Environnement requis

- PostgreSQL 16 ou version ultérieure  
- PostGIS 3.5.3  
- GEOS 3.13.1  
- QGIS 3.34 ou supérieur (extension Cadastre recommandée)

Les scripts doivent être exécutés avec un utilisateur disposant des droits de création de schémas et d’exécution de blocs PL/pgSQL.

---

## Données nécessaires
1. **Fichiers fonciers** : MAJIC et EDIGEO, importés dans PostgreSQL via l'extension cadastre de QGIS dans le schéma `r_cadastre`.

2. **Couche bâtiments**    : Table `batiment` de la BD_TOPO  dans le schéma `r_bdtopo`.
   **Couche cimetière**    : Table 'cimetiere' de la BD_TOPO dans le schéma `r_bdtopo`.
   **Couche zones d'activités et d'intérêts** : 
                             Table `zone_d_activite_ou_d_interet` de la BD_TOPO  dans le schéma `r_bdtopo`.
                             ⚠️ Lors du chargement de la BDTopo, vérifier les identifiants des deux tables.

3. **Zonage urbain**       : Tous les zonages urbains des communes du département touchés par la zone à risques des 200m autour des 
                             massifs forestiers dans le schéma `26_zonage_urba`. Le nom de la couche de zonage de la commune de Cassis (insee 13022) doit commencer par son numéro insee (exemple 13022_zonage) et doit posséder un attribut TYPEZONE ou typezone (comme les couches téléchargées sur le géoportail de l'urbanisme)

4. **Zones d’application OLD** :
                             Regroupement des tampons de 200 mètres autour des massifs forestiers sensibles `old200m` dans le schéma `public`
                             (source : télécharger la version allégée sur https://geoservices.ign.fr/debroussaillement et regrouper les entités).

5. **Eolienne**            : La couche AEROGENERATEUR_CSV au format csv du site géorisques via 'https://www.georisques.gouv.fr/donnees/bases-de-donnees/eolien-terrestre' 
                             est à traduire en couche de points puis propagée sous le nom "eolien_filtre" dans le schéma `public`.

Toutes les couches doivent être en système de coordonnées Lambert-93 (EPSG:2154).

---

## Module 0 — Création de la base et des schémas

Ce module initialise la structure de travail pour un département donné.  

Il crée trois schémas :  
- `{dep}_old50m_resultat` pour les résultats,  
- `{dep}_old50m_parcelle` pour les données cadastrales,  
- `{dep}_old50m_bati` pour les données bâties.  

Le code département est à adapter dans le script (`departement := 'XX'`).  
Le script supprime les anciens schémas, crée les nouveaux et affiche les messages de validation dans la console.

---

## Module 1 — Prétraitement du zonage global

Ce module nettoie et homogénéise le zonage urbain sur les parcelles cadastrales.  
Il convertit les noms de colonnes en minuscules, corrige les systèmes de coordonnées et fusionne les zones urbaines 
(type "U") en une seule couche départementale.

Le résultat est une table `{dep}_zonage_global` dans le schéma `{dep}_old50m_resultat`.  
Les géométries sont validées, converties en MultiPolygon et reprojetées en Lambert-93.  
Un index spatial est créé pour améliorer les performances.

---

## Module 2 — Calculs OLD50m

Ce module en code SQL effectue l’ensemble des traitements spatiaux pour une commune donnée.  
Il s’appuie sur les données cadastrales, les unités foncières, la BD TOPO et les zonages préparés.

Le code département est à adapter dans le script (`departement := 'XX'`).  
Les grandes étapes sont les suivantes :

1.  Création des schémas de travail
2.  PARTIE I    — Extraction des parcelles cadastrales de la commune
3.  PARTIE II   — Extraction des unités foncières
4.  PARTIE III  — Gestion du parcellaire non cadastré
5.  PARTIE IV   — Gestion des bâtiments
6.  PARTIE V    — Elargissement du zonage urbain
7.  PARTIE VI   — Zones tampons et intersections entre comptes communaux
8.  PARTIE VII  — Gestion du parcellaire bati
9.  PARTIE VIII — Polygon de Voronoï pour l'arbitrage
10. PARTIE IX   — Arbitrage des responsabilités d'OLD par propriétaire
12. PARTIE X    — Zones finales à débroussailler par propriétaire avec zones non couvertes
13. PARTIE XI   — Détection et extraction des zones non couvertes (trous)
14. PARTIE XII  — Reconstructions des ilots non attribués en zones de superposition
15. PARTIE XIII — Attributions des ilôts résiduels par polygonisation de voronoï
16. PARTIE XIV  — Fusion et extractions des zones à débroussailler par propriétaire
17. PARTIE XV   — Intégration des parcs éoliens dans les zones à débroussailler 
18. PARTIE XVI  — Enregistrement du résultat final et supression de la table de travail

Les résultats intermédiaires sont stockés dans le schéma `"26xxx_wold50m"` qui est ensuite
supprimé sauf si vous commentez les lignes de supression (DROP SCHEMA).  

Chaque table est indexée spatialement pour faciliter la consultation.

script MODULE_2_OLD50m_v2.2.py : Calcul départemental
Si vous avez adapté le script MODULE_2_OLD50m_v2.2.sql en fonction de vos tables locales
et noms d'attributs, le script MODULE_2_sql_to_python.py conservera vos adaptations pour
écrire votre version du script MODULE_2_OLD50m_v2.2.py

---

## Installation
### PostgreSQL et PostGIS
Installez PostgreSQL et PostGIS :
   ```bash
   sudo apt-get install postgresql postgis
   ```
Activez PostGIS dans votre base :
   ```sql
   CREATE EXTENSION postgis;
   CREATE EXTENSION postgis_topology;
   ```

### QGIS
   ```
   Installez QGIS avec l’extension cadastre (v2.2.1).
   ```
   
---
## Structure de la base de données PostgreSQL (pour modules 1 et 2)
📁 geobase  
│─ 📂 Extensions  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─ postgis  ; # version 3.5.0 ou ultérieure  
│─ 📂 Schémas;    
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│─ 📂 26_zonage_urba ; # stockage des couches de zonages d'urbanisme  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│─ 📂 26_zonage_travail ; # stockage temporaire créé par le Module 1 (temporaire)   

│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│─ 📂 26xxx_wold50m ; # stockage temporaire créé par le Module 2 pour la commune 26xxx (temporaire)  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│─ 📂 26_old50m_bati ; # stockage des batiments hors installations et cimetières    
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│─ 📂 26_old50m_parcelle ; # stockage des parcelles cadastrales  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│─ 📂 26_old50m_resultats ; # stockage des résultats des traitements  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─ 📂 public ; # stockage des couches générales  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│─ old200m  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─ eolien_filtre  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│─ 📂 r_cadastre ; # stockage des données cadastrales (créé avec extension cadastre de QGIS)   
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│─ geo_commune  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│─ geo_unite_fonciere  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─ parcelle_info  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─ 📂 r_bdtopo ; # stockage des couches de la BDTOPO  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│─ batiment  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│─ cimetiere  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─ zone_d_activite_ou_d_interet  

---

## Utilisation

1. Adapter les paramètres départementaux et communaux dans les scripts.  
2. Exécuter les modules dans l’ordre (0 → 1 → 2).  
3. Vérifier les logs et la validité des géométries.  
4. Visualiser les résultats dans QGIS pour analyse ou édition.  

Chaque module peut être relancé indépendamment après mise à jour des données sources.

---

## Références et licence

- Code forestier français : articles L132-1 et L134-9  
- Documentation PostGIS : https://postgis.net/docs/  
- IGN – BD TOPO et géoservices : https://geoservices.ign.fr/  
- Licence : GNU General Public License version 3  

Auteurs :  
Frédéric Sarret — Marie-Jeanne Martinat  
DDT de la Drôme – SEFEN – Pôle Forêt  
Contact : ddt-sefen-pf@drome.gouv.fr