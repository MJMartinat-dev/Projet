[//]: # (0x4d4a)

<div align="center">

# OLD50m

**Calcul automatisé des Obligations Légales de Débroussaillement à 50 mètres**  
*DDT de la Drôme · 2023–2025 · Version 2.3*

[![GitLab](https://img.shields.io/badge/GitLab-Source-FC6D26?style=flat-square&logo=gitlab&logoColor=white)](https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/old50m)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![PostGIS](https://img.shields.io/badge/PostGIS-3.5.3-009FDA?style=flat-square)
![Python](https://img.shields.io/badge/Python-3.x-3776AB?style=flat-square&logo=python&logoColor=white)
![Licence](https://img.shields.io/badge/Licence-GPL_≥_3-blue?style=flat-square)
![Statut](https://img.shields.io/badge/Statut-Production-22c55e?style=flat-square)

</div>

---

## Présentation

**OLD50m** est une suite de scripts SQL et Python destinée à automatiser le calcul des Obligations Légales de Débroussaillement (OLD) à l'échelle communale ou départementale, conformément au **Code forestier** (articles L132-1 et L134-9).

Le système détermine, pour chaque bâtiment situé dans une zone à risques incendie, la zone à débroussailler et identifie le ou les propriétaires responsables — y compris en cas de superposition d'obligations entre parcelles.

Les couches spatiales produites alimentent directement l'application [cartOLD](https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/cartold), dédiée à leur visualisation interactive.

---

## Contexte réglementaire

| Article | Obligation |
|---|---|
| L134-9 Code forestier | Débroussaillement obligatoire sur les terrains situés à moins de 200 m d'un massif forestier sensible |
| Rayon 50 m | Débroussaillement dans un rayon de 50 m autour de tout bâtiment ou installation |
| Zone U (PLU) | Débroussaillement obligatoire sur l'ensemble des terrains en zone urbaine |
| Superposition | Si les zones se superposent sur la parcelle d'un tiers non soumis à l'obligation, chaque propriétaire débroussaille les parties les plus proches de ses constructions |

---

## Fonctionnalités

### Pipeline de traitement en trois modules

| Module | Fichier | Rôle |
|---|---|---|
| **0** | `MODULE_0_creationbd_v0.1.sql` | Création des schémas PostgreSQL de travail |
| **1** | `MODULE_1_zonage_global_v1.1.sql` | Nettoyage et homogénéisation des zonages urbains (PLU) |
| **2 — SQL** | `MODULE_2_OLD50m_v2.3.sql` | Calcul complet des OLD sur **une commune** |
| **2 — Python** | `MODULE_2_OLD50m_v2.3.py` | Exécution automatisée sur **tout un département** |
| **Utilitaire** | `MODULE_2_sql_to_python.py` | Transpilation SQL → Python en conservant les adaptations locales |

### Module 2 — Étapes de traitement spatial (16 parties)

1. Extraction des parcelles cadastrales de la commune
2. Extraction des unités foncières
3. Gestion du parcellaire non cadastré
4. Gestion des bâtiments
5. Élargissement du zonage urbain
6. Zones tampons et intersections entre comptes communaux
7. Gestion du parcellaire bâti
8. Polygones de Voronoï pour l'arbitrage
9. Arbitrage des responsabilités OLD par propriétaire
10. Zones finales à débroussailler avec zones non couvertes
11. Détection et extraction des zones non couvertes (trous)
12. Reconstruction des îlots non attribués en zones de superposition
13. Attribution des îlots résiduels par polygonisation de Voronoï
14. Fusion et extraction des zones à débroussailler par propriétaire
15. Intégration des parcs éoliens dans les zones à débroussailler
16. Enregistrement du résultat final et suppression des tables de travail

### Paramétrabilité

- Adaptable à **tout département** via la variable `departement := 'XX'`
- Paramètres de tolérance géométrique configurables (`recalage_1/2/3`, `buffer_fuseau_zonage`)
- Chaque module peut être relancé indépendamment après mise à jour des données sources

---

## Stack technique

| Composant | Technologie |
|---|---|
| Base de données spatiale | PostgreSQL 16 · PostGIS 3.5.3 · GEOS 3.13.1 |
| Langage de traitement | SQL / PL/pgSQL · Python 3.x |
| Pilote Python | SQLAlchemy · pandas |
| Projection de référence | Lambert-93 (EPSG:2154) |
| SIG bureautique | QGIS 3.34+ · Extension Cadastre v2.2.1 |
| Sources de données | MAJIC/EDIGEO · BD TOPO IGN · Géoportail de l'urbanisme · GéoRisques |
| Application de visualisation | [cartOLD](https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/cartold) |

---

## Architecture

### Structure du projet

```
old50m/
├── script/                              ← scripts opérationnels (version courante)
│   ├── MODULE_0_creationbd_v0.1.sql     ← initialisation des schémas PostgreSQL
│   ├── MODULE_1_zonage_global_v1.1.sql  ← prétraitement des zonages urbains
│   ├── MODULE_2_OLD50m_v2.3.sql         ← calcul OLD sur une commune (SQL)
│   ├── MODULE_2_OLD50m_v2.3.py          ← calcul OLD sur un département (Python)
│   └── MODULE_2_sql_to_python.py        ← transpilateur SQL → Python
├── Archivage/                           ← versions antérieures (v1.16 à v2.2)
├── docs/
│   ├── Bases juridiques/                ← textes réglementaires (Code forestier, Code urbanisme)
│   ├── Config/                          ← documentation proxy et configuration Python
│   ├── Guides/                          ← guide méthodologique, présentation, guide débroussaillement
│   └── Outils/                          ← boîte à outils SQL, docs PostgreSQL et PostGIS
├── Qgis_projet/                         ← projet QGIS de visualisation des résultats
├── cartes/                              ← exports cartographiques
└── README.md
```

### Structure de la base de données PostgreSQL

```
geobase
├── Extensions
│   └── postgis (≥ 3.5.0)
└── Schémas
    ├── r_cadastre                   ← données cadastrales (extension cadastre QGIS)
    │   ├── geo_commune
    │   ├── geo_unite_fonciere
    │   └── parcelle_info
    ├── r_bdtopo                     ← BD TOPO IGN
    │   ├── batiment
    │   ├── cimetiere
    │   └── zone_d_activite_ou_d_interet
    ├── {dep}_zonage_urba            ← zonages PLU par commune
    ├── {dep}_zonage_travail         ← schéma temporaire (Module 1)
    ├── {dep}xxx_wold50m             ← schéma temporaire par commune (Module 2)
    ├── {dep}_old50m_parcelle        ← données cadastrales préparées
    ├── {dep}_old50m_bati            ← données bâties préparées
    ├── {dep}_old50m_resultat        ← résultats des calculs OLD ✓
    └── public
        ├── old200m                  ← massifs forestiers sensibles (source IGN)
        └── eolien_filtre            ← parcs éoliens (source GéoRisques)
```

---

## Données nécessaires

| Source | Contenu | Schéma cible |
|---|---|---|
| MAJIC / EDIGEO | Fichiers fonciers — importés via l'extension Cadastre de QGIS | `r_cadastre` |
| BD TOPO IGN | Bâtiments, cimetières, zones d'activités et d'intérêts | `r_bdtopo` |
| Géoportail de l'urbanisme | Zonages PLU de toutes les communes concernées par les OLD | `{dep}_zonage_urba` |
| IGN Géoservices | Tampons OLD 200 m autour des massifs forestiers sensibles | `public.old200m` |
| GéoRisques | Aérogénérateurs (éolien terrestre) au format CSV → couche de points | `public.eolien_filtre` |

> ⚠️ Toutes les couches doivent être en **Lambert-93 (EPSG:2154)**.  
> ⚠️ Lors du chargement de la BD TOPO, vérifier les identifiants des tables `batiment` et `zone_d_activite_ou_d_interet`.

---

## Installation & utilisation

### Prérequis

- PostgreSQL ≥ 16
- PostGIS ≥ 3.5.3
- QGIS ≥ 3.34 avec l'extension **Cadastre** (v2.2.1)
- Python 3.x avec `sqlalchemy` et `pandas`

### Installation PostgreSQL / PostGIS

```bash
sudo apt-get install postgresql postgis
```

```sql
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
```

### Dépendances Python

```bash
pip install sqlalchemy pandas
```

### Exécution

```
1. Adapter le numéro de département (departement := 'XX') dans chaque script
2. Configurer les paramètres de connexion PostgreSQL dans le script Python
3. Exécuter les modules dans l'ordre : 0 → 1 → 2
4. Vérifier les logs et la validité des géométries
5. Visualiser les résultats dans QGIS
```

> ⚠️ **Proxy ministériel** : activer la configuration proxy avant tout lancement réseau (voir `docs/Config/config_proxy.md`).

### Calcul départemental automatisé (Module 2 Python)

Si le script SQL a été adapté aux tables locales, utiliser le transpilateur avant de lancer le calcul départemental :

```bash
python MODULE_2_sql_to_python.py   # génère MODULE_2_OLD50m_v2.3.py
python MODULE_2_OLD50m_v2.3.py     # calcul sur l'ensemble des communes du département
```

---

## Documentation technique

| Document | Contenu |
|---|---|
| `docs/Guides/OLD50m_guide_methodologique.md` | Guide méthodologique complet |
| `docs/Guides/OLD50m_V2.3_evolutions.pdf` | Évolutions de la version 2.3 |
| `docs/Guides/DIAG_old50m_Trous_Ilots.pdf` | Diagramme de traitement des trous et îlots |
| `docs/Guides/guide_debroussaillement_2025_PLANCHES_BD.pdf` | Guide terrain débroussaillement 2025 |
| `docs/Config/Documentation_script_python.md` | Documentation du script Python |
| `docs/Outils/Boite_outils.sql` | Requêtes utilitaires PostGIS |

---

## Historique

| Version | Auteur(s) | Évolutions principales |
|---|---|---|
| v1.16 | F. Sarret | Première version de production SQL |
| v2.1 | F. Sarret | Refonte modulaire, ajout Python |
| v2.2 | F. Sarret · MJ Martinat | Gestion des îlots résiduels et des parcs éoliens |
| **v2.3** | MJ Martinat | Version courante — voir `docs/Guides/OLD50m_V2.3_evolutions.pdf` |

---

## Liens

| | |
|---|---|
| 🗺️ Application de visualisation | [cartOLD](https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/cartold) |
| 📁 Portfolio | [Voir le portfolio](../../portfolio/README.md) |
| 📬 Contact | ddt-sefen-pf@drome.gouv.fr |

---

<sub>Auteurs : Frédéric Sarret · Marie-Jeanne Martinat · DDT de la Drôme – SEFEN – Pôle Forêt · Licence GPL ≥ 3</sub>
