--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----  OLD50M   Traitements sous PostgreSQL/PostGIS pour déterminer les obligations légales                    ----
----           de débroussaillement (OLD) de chaque propriétaire d'une commune                                ----
----  Auteurs         : Frédéric Sarret, Marie-Jeanne Martinat                                                ----
----  Version         : 1.16a                                                                                 ----
----  License         : GNU GENERAL PUBLIC LICENSE  Version 3                                                 ----
----  Documentation   : https://gitlab-forge.din.developpement-durable.gouv.fr/frederic.sarret/old_50m/       ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----   INTEGRATION DU CODE INSEE DE LA COMMUNE CONCERNEE                                                      ----
----                                                                                                          ----
----   Remplacer "260xxx" avec le code INSEE de la commune                                                    ----
----   Remplacer "26xxx" par le code INSEE de la commune                                                      ----
----   Remplacer "xxx" par les 3 derniers chiffres de ce code INSEE                                           ----
----                                                                                                          ----
----   Exemple pour la commune de CASSIS dont le code INSEE est 13022                                         ----
----   Remplacer "260xxx" par "130022"                                                                        ----
----   Remplacer "26xxx" par "13022"                                                                          ----
----   Et remplacer "xxx" par "022"                                                                           ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

-- CREATION DU SCHEMA DE TRAVAIL

DROP SCHEMA IF EXISTS "26xxx_wold50m" CASCADE;
COMMIT;
CREATE SCHEMA "26xxx_wold50m";
COMMIT;


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----                                             PARTIE I                                                     ----
----                          IDENTIFICATION ET GESTION DES PARCELLES CADASTRALES                             ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
---- OBJECTIFS :                                                                                              ----
---- - Structurer, organiser et optimiser les données cadastrales de la commune 26xxx pour faciliter leur     ----
----   exploitation dans les analyses géospatiales et dans le projet de cartographie communale des OLD.       ----
---- - Délimiter la zone géographique du projet en cours.                                                     ----
----                                                                                                          ----
---- MÉTHODOLOGIE :                                                                                           ----
---- - **Acquisition et filtrage des parcelles cadastrales** :                                                ----
----   - Sélection des parcelles spécifiques à la commune via le code commune "xxx" de la couche              ----
----     'parcelle_info' issue du schéma 'r_cadastre' construit avec le plugin 'cadastre' de QGis             ----
----   - Stockage des informations essentielles dans une table dédiée "26xxx_parcelle".                       ----
---- - **Structuration et correction des données** :                                                          ----
----   - Conversion des géométries en **MultiPolygon** pour assurer la cohérence géographique.                ----
----   - Application du **système de coordonnées SRID 2154 (Lambert 93)** pour une précision topographique.   ----
---- - **Fusion et optimisation des entités cadastrales** :                                                   ----
----   - Agrégation des parcelles cadastrales en une **entité unique** stockée dans la table                  ----
----     "26xxx_parcelle_rg" pour optimiser les traitements spatiaux.                                         ----
---- - **Indexation spatiale pour améliorer les performances** :                                              ----
----   - Création d’un **index spatial GIST** permettant d’accélérer les requêtes spatiales.                  ----
----                                                                                                          ----
---- RÉSULTATS ATTENDUS :                                                                                     ----
---- - **Base cadastrale corrigée et optimisée** pour les requêtes spatiales.                                 ----
---- - **Amélioration des performances** grâce à l’indexation et à la consolidation des géométries.           ----
----                                                                                                          ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
 
---- Création de la table "26xxx_parcelle" : Parcelles cadastrales de la commune avec codecommune égal à 'xxx'.

---- Description : table des parcelles cadastrales de la commune identifiée par son code INSEE 26xxx.
-- 				   -> Attributs : identifiant unique, compte communal du propriétaire, géométrie.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_parcelle";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_parcelle" AS
SELECT pi.idu,                                -- Identifiant unique de la parcelle
	   pi.geo_parcelle,                       -- N° de la parcelle
       pi.comptecommunal,                     -- N° du compte communal du propriétaire
	   pi.codecommune,                        -- 3 dernier chiffres du code INSEE
	   pi.geom                                -- géométrie de la parcelle
FROM r_cadastre.parcelle_info pi              -- Source : parcelle_info issu de Qgis
WHERE LEFT(pi.geo_parcelle, 6) = '260xxx';    -- Critère de sélection des parcelles de la commune 26xxx
--WHERE pi.codecommune = 'xxx';               -- Parcelles dont les 3 caractères du 'code commune' sont égaux à '005'
COMMIT;                                       -- Mais quelques rares parcelles ont une valeur d'attribut 'code commune' NULL

ALTER TABLE "26xxx_wold50m"."26xxx_parcelle"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);
COMMIT;

CREATE INDEX idx_26xxx_parcelle_geom 
ON "26xxx_wold50m"."26xxx_parcelle"
USING gist (geom);
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_parcelle_rg" : Union des parcelles cadastrales en une seule géométrie.

---- Description : Cette table regroupe toutes les parcelles cadastrales de la commune en une seule entité 
--                 géométrique
-- 				   -> Attributs : géométrie MultiPolygon

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_parcelle_rg";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_parcelle_rg" AS
SELECT ST_Multi(                         -- Convertit la géométrie fusionnée en MultiPolygon
          ST_Union(p.geom)               -- Fusionne toutes les géométries des parcelles cadastrales
       ) AS geom                         -- Définit la colonne résultante "geom"
FROM "26xxx_wold50m"."26xxx_parcelle" p; -- Source : table des parcelles cadastrales
COMMIT; 

CREATE INDEX idx_26xxx_parcelle_rg_geom 
ON "26xxx_wold50m"."26xxx_parcelle_rg"
USING gist (geom); 
COMMIT; 


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE 3                                                    ----
----                               GESTION DU PARCELLAIRE NON CADASTRE                                       ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
---- OBJECTIFS :                                                                                              ----
---- - Identifier et structurer les zones non cadastrées de la commune 26xxx pour faciliter                   ----
----   leur extraction dans les analyses géospatiales et dans le projet des OLD.                              ----
---- - Ces zones non cadastrées sont déduites vu que les règles ne s'appliquent pas directement sur celles-ci ----
----                                                                                                          ----
---- MÉTHODOLOGIE :                                                                                           ----
---- - **Détection et extraction des zones non cadastrées** :                                                 ----
----   - Calcul de la différence géométrique entre les contours administratifs de la commune                  ----
----     via la couche **'geo_commune'** et les parcelles cadastrales de la couche **'parcelle_info'**.       ----
----   - Stockage des zones non cadastrées dans une table dédiée **"26xxx_non_cadastre"**.                    ----
---- - **Structuration et correction des données** :                                                          ----
----   - Conversion des géométries en **MultiPolygon** pour assurer la cohérence géographique.                ----
----   - Application du **système de coordonnées SRID 2154 (Lambert 93)** pour une précision topographique.   ----
---- - **Optimisation des performances et des traitements spatiaux** :                                        ----
----   - Création d’un **index spatial GIST** permettant d’accélérer les requêtes spatiales.                  ----
----                                                                                                          ----
---- RÉSULTATS ATTENDUS :                                                                                     ----
---- - **Couche des zones non cadastrées corrigée et optimisée** pour les requêtes spatiales                  ----
---- - **Amélioration des performances** grâce à l’indexation et à l’optimisation des données.                ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--


---- Création de la table "26xxx_non_cadastre" : Identification des zones non cadastrées au sein de la commune.

---- Description : Cette table calcule et stocke les zones non cadastrées en soustrayant les parcelles cadastrées 
--				   26xxx de l'emprise géographique de la commune 26xxx.
-- 				   -> Attributs : géométrie MultiPolygon

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_non_cadastre";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_non_cadastre" AS
SELECT 
	ST_Multi(                              -- Convertit la géométrie résultante en **MultiPolygon**
	  ST_MakeValid(
		ST_Difference(
		  c.geom, 
		  ST_Union(p.geom)))) AS geom  -- Découpe la géométrie de la commune en soustrayant les parcelles cadastrées unifiées
FROM "26xxx_wold50m"."26xxx_parcelle" p, -- Source : parcelles cadastrées
      r_cadastre.geo_commune c           -- Source : contour géométrique de la commune
WHERE LEFT(p.idu, 3) = 'xxx'             -- Filtre : parcelles appartenant à la commune avec code INSEE 'xxx'
      AND c.idu = 'xxx'                  -- Sélectionne le contour de la commune avec le code INSEE 'xxx'
GROUP BY c.geom;                         -- Regroupe par la géométrie de la commune pour éviter les doublons
COMMIT; 


ALTER TABLE "26xxx_wold50m"."26xxx_non_cadastre"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154); 
COMMIT;  

CREATE INDEX idx_26xxx_non_cadastre_geom 
ON "26xxx_wold50m"."26xxx_non_cadastre"
USING gist (geom); 
COMMIT;  


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE 4                                                    ----
----                                       GESTION DES BÂTIMENTS                                             ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
---- - Extraction des bâtiments de la commune à partir de la couche batiment de la BD TOPO                   ----
---- - Identification des bâtiments situés dans la zone de débroussaillement à 200 m des massifs forestiers  ----
---- - Association des bâtiments aux comptes communaux à partir des unités foncières                         ----
---- - Regroupement des bâtiments par compte communal pour générer des entités géographiques agrégées        ----
---- - Génération de tampons de 50 m autour des bâtiments agrégés                                            ----
----                                                                                                         ----
----   Ce processus extrait et traite les bâtiments de la commune, identifie ceux situés dans la zone de     ----
----   débroussaillement de 200 m autour des massifs forestiers, les associe à des comptes communaux,        ----
----   regroupe leurs géométries par propriétaire, et crée des tampons de 50 m pour identifier la zone       ----
----   géographique à débroussailler.                                                                        ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--


---- Création de la table des cimetières

---- Description : Cette table extrait et stocke les géométries des cimetières pour la commune 26xxx,  
--                en s'appuyant sur la couche r_bdtopo.cimetiere et la jointure sur la commune cible.
--                -> Attributs : identifiant (NULL ici car pas présent), nature, idu commune, géométrie 2D

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_cimetiere";                       
CREATE TABLE "26xxx_wold50m"."26xxx_cimetiere" AS                             
SELECT NULL::integer AS fid,                                                  -- Identifiant (non renseigné car pas d'ID disponible dans la source)
       'Cimetiere' AS nature,                                                 -- Ajoute la valeur 'Cimetiere' dans la colonne nature
       c.idu,                                                                 -- Attribut idu : identifiant unique de la commune
       ST_Force2D(r.geom) AS geom                                        -- Géométrie convertie en 2D (projection XY)
FROM r_bdtopo.cimetiere r                                                     -- Source : couche BD TOPO cimetières
INNER JOIN r_cadastre.geo_commune c                                           -- Jointure spatiale avec la table des communes du cadastre
  ON ST_Intersects(r.geom, c.geom)                                       -- Condition de jointure spatiale : intersection des géométries
WHERE c.idu = 'xxx';                                                          -- Filtre sur la commune de code idu xxx
COMMIT;                                                                       -- Valide la création de la table

ALTER TABLE "26xxx_wold50m"."26xxx_cimetiere"                                 -- Modifie la structure de la table créée
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154)                           -- Change le type de la colonne geom en MultiPolygon, code EPSG 2154
USING ST_SetSRID(geom, 2154);                                                 -- Définit le SRID (projection) de la colonne geom à 2154
COMMIT;                                                                       -- Valide la modification

CREATE INDEX idx_26xxx_cimetiere_geom                                         -- Crée un index spatial sur la colonne geom
ON "26xxx_wold50m"."26xxx_cimetiere"                                          -- Nom de la table concernée
USING gist (geom);                                                            -- Type d'index spatial utilisé (gist)
COMMIT;                                                                       -- Valide la création de l'index

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table des installations spécifiques (campings, centrales, carrières, CET)

---- Description : Cette table regroupe les installations "excluantes" de la commune 26xxx
--                (campings, centrales photovoltaïques, carrières, CET) issues de la BD TOPO.
--                -> Attributs : identifiant (NULL ici), nature, idu commune, géométrie 2D

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_installation";                    
CREATE TABLE "26xxx_wold50m"."26xxx_installation" AS                         
WITH campings AS (                                                            -- Début de la CTE pour les campings
    SELECT NULL::integer AS fid,                                              -- Identifiant nul
           'Camping' AS nature,                                               -- Nature : Camping
           c.idu,                                                             -- idu : identifiant commune
           ST_Force2D(z.geom) AS geom                                    -- Géométrie projetée en 2D
    FROM r_bdtopo.zone_d_activite_ou_d_interet z                              -- Source : zones d'activité BD TOPO
    INNER JOIN r_cadastre.geo_commune c                                       -- Jointure avec la commune
      ON ST_Intersects(z.geom, c.geom)                                   -- Condition : intersection spatiale
    WHERE c.idu = 'xxx'                                                       -- Commune cible
      AND z.nature = 'Camping'                                                -- Filtre sur la nature Camping
),
centrales AS (                                                                -- Début de la CTE pour les centrales PV
    SELECT NULL::integer AS fid,                                              -- Identifiant nul
           'Centrale photovoltaïque' AS nature,                               -- Nature : Centrale photovoltaïque
           c.idu,                                                             -- idu commune
           ST_Force2D(z.geom) AS geom                                    -- Géométrie projetée en 2D
    FROM r_bdtopo.zone_d_activite_ou_d_interet z                              -- Source : zones d'activité BD TOPO
    INNER JOIN r_cadastre.geo_commune c                                       -- Jointure commune
      ON ST_Intersects(z.geom, c.geom)                                   -- Condition : intersection spatiale
    WHERE c.idu = 'xxx'                                                       -- Commune cible
      AND z.nature_detaillee = 'Centrale photovoltaïque'                      -- Filtre sur la nature détaillée centrale PV
),
carrieres AS (                                                                -- Début de la CTE pour les carrières
    SELECT NULL::integer AS fid,                                              -- Identifiant nul
           'Carrière' AS nature,                                              -- Nature : Carrière
           c.idu,                                                             -- idu commune
           ST_Force2D(z.geom) AS geom                                    -- Géométrie projetée en 2D
    FROM r_bdtopo.zone_d_activite_ou_d_interet z                              -- Source : zones d'activité BD TOPO
    INNER JOIN r_cadastre.geo_commune c                                       -- Jointure commune
      ON ST_Intersects(z.geom, c.geom)                                   -- Condition : intersection spatiale
    WHERE c.idu = 'xxx'                                                       -- Commune cible
      AND z.nature = 'Carrière'                                               -- Filtre sur la nature Carrière
),
cets AS (                                                                     -- Début de la CTE pour les CET
    SELECT NULL::integer AS fid,                                              -- Identifiant nul
           'Centre d''enfouissement technique' AS nature,                     -- Nature : CET (Centre d'enfouissement technique)
           c.idu,                                                             -- idu commune
           ST_Force2D(z.geom) AS geom                                    -- Géométrie projetée en 2D
    FROM r_bdtopo.zone_d_activite_ou_d_interet z                              -- Source : zones d'activité BD TOPO
    INNER JOIN r_cadastre.geo_commune c                                       -- Jointure commune
      ON ST_Intersects(z.geom, c.geom)                                   -- Condition : intersection spatiale
    WHERE c.idu = 'xxx'                                                       -- Commune cible
      AND z.nature_detaillee = 'Centre d''enfouissement technique'            -- Filtre sur la nature détaillée CET
)
SELECT * FROM campings                                                        -- Récupère tous les campings
UNION ALL
SELECT * FROM centrales                                                       -- Ajoute toutes les centrales PV
UNION ALL
SELECT * FROM carrieres                                                       -- Ajoute toutes les carrières
UNION ALL
SELECT * FROM cets;                                                           -- Ajoute tous les CET
COMMIT;                                                                       -- Valide la création de la table

ALTER TABLE "26xxx_wold50m"."26xxx_installation"                              -- Modifie la structure de la table créée
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154)                           -- Change le type de la colonne geom en MultiPolygon, code EPSG 2154
USING ST_SetSRID(geom, 2154);                                                 -- Définit le SRID (projection) de la colonne geom à 2154
COMMIT;                                                                       -- Valide la modification

CREATE INDEX idx_26xxx_installation_geom                                      -- Crée un index spatial sur la colonne geom
ON "26xxx_wold50m"."26xxx_installation"                                       -- Table cible de l'index
USING gist (geom);                                                            -- Type d'index spatial utilisé (gist)
COMMIT;                                                                       -- Valide la création de l'index

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table des bâtiments "Habitat" (hors zones excluantes)

---- Description : Cette table extrait les bâtiments d'habitat de la commune 26xxx,
--                en excluant ceux situés dans un cimetière, un camping, une centrale PV, une carrière ou un CET.
--                -> Attributs : fid, nature, idu, géométrie multi-polygone

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_bati_habitat";                    
CREATE TABLE "26xxx_wold50m"."26xxx_bati_habitat" AS                          
WITH bati_init AS (                                                           -- Début de la CTE pour la sélection initiale des bâtiments
    SELECT b.fid,                                                             -- Identifiant unique bâtiment
           'Habitat' AS nature,                                               -- Nature : Habitat
           c.idu,                                                             -- idu commune
           ST_Force2D(b.geom) AS geom                                    -- Géométrie en 2D
    FROM r_bdtopo.batiment b                                                  -- Source : bâtiments BD TOPO
    INNER JOIN r_cadastre.geo_commune c                                       -- Jointure avec la commune
      ON ST_Intersects(b.geom, c.geom)                                   -- Condition : intersection spatiale
    WHERE c.idu = 'xxx'                                                       -- Commune cible
      AND ST_Area(b.geom) >= 6                                           -- Surface supérieure ou égale à 6 m²
)
SELECT b.fid,                                                                 -- Identifiant bâtiment (issu de la CTE)
       b.nature,                                                              -- Nature (issu de la CTE)
       b.idu,                                                                 -- idu (issu de la CTE)
       ST_Multi(ST_CollectionExtract(ST_MakeValid(b.geom), 3)) AS geom        -- Géométrie validée, convertie en MultiPolygon (type 3)
FROM bati_init b                                                              -- Source : CTE bati_init
WHERE NOT EXISTS (
  SELECT 1 FROM r_bdtopo.cimetiere r                                          -- Sélectionne s'il existe une intersection avec un cimetière
  INNER JOIN r_cadastre.geo_commune c                                         -- Jointure avec la commune
    ON ST_Intersects(r.geom, c.geom)                                     -- Condition spatiale
  WHERE c.idu = 'xxx'                                                         -- Commune cible
    AND ST_Intersects(b.geom, r.geom)                                    -- Exclut les bâtiments présents dans un cimetière
)
AND NOT EXISTS (
  SELECT 1 FROM r_bdtopo.zone_d_activite_ou_d_interet z                       -- Sélectionne s'il existe une intersection avec une zone d'activité spécifique
  INNER JOIN r_cadastre.geo_commune c                                         -- Jointure avec la commune
    ON ST_Intersects(z.geom, c.geom)                                     -- Condition spatiale
  WHERE c.idu = 'xxx'                                                         -- Commune cible
    AND (
        z.nature = 'Camping'                                                  -- Filtre les campings
     OR z.nature_detaillee = 'Centrale photovoltaïque'                        -- Filtre les centrales photovoltaïques
     OR z.nature = 'Carrière'                                                 -- Filtre les carrières
     OR z.nature_detaillee = 'Centre d''enfouissement technique'              -- Filtre les CET
    )
    AND ST_Intersects(b.geom, z.geom)                                    -- Exclut les bâtiments présents dans une installation
);
COMMIT;                                                                       -- Valide la création de la table

ALTER TABLE "26xxx_wold50m"."26xxx_bati_habitat"                              -- Modifie la structure de la table créée
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154)                           -- Change le type de la colonne geom en MultiPolygon, code EPSG 2154
USING ST_SetSRID(geom, 2154);                                                 -- Définit le SRID (projection) de la colonne geom à 2154
COMMIT;                                                                       -- Valide la modification

CREATE INDEX idx_26xxx_bati_habitat_geom                                      -- Crée un index spatial sur la colonne geom
ON "26xxx_wold50m"."26xxx_bati_habitat"                                       -- Table cible de l'index
USING gist (geom);                                                            -- Type d'index spatial utilisé (gist)
COMMIT;                                                                       -- Valide la création de l'index

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table finale des bâtis (fusion des entités bâties et excluantes)

---- Description : Cette table fusionne les bâtiments "habitat", les cimetières et les installations 
--                spécifiques de la commune 26xxx.
--                -> Attributs : tous ceux des sources fusionnées (fid, nature, idu, géométrie)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_bati";                            
CREATE TABLE "26xxx_wold50m"."26xxx_bati" AS                                  
SELECT *                                                                      -- Sélectionne tous les champs
FROM "26xxx_wold50m"."26xxx_bati_habitat"                                     -- Source : table habitat
UNION ALL
SELECT *                                                                      -- Ajoute tous les champs de la table suivante
FROM "26xxx_wold50m"."26xxx_cimetiere"                                        -- Source : table cimetières
UNION ALL
SELECT *                                                                      -- Ajoute tous les champs de la table suivante
FROM "26xxx_wold50m"."26xxx_installation";                                    -- Source : table installations
COMMIT;                                                                       -- Valide la création de la table

ALTER TABLE "26xxx_wold50m"."26xxx_bati"                                      -- Modifie la structure de la table créée
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154)                           -- Change le type de la colonne geom en MultiPolygon, code EPSG 2154
USING ST_SetSRID(geom, 2154);                                                 -- Définit le SRID (projection) de la colonne geom à 2154
COMMIT;                                                                       -- Valide la modification

CREATE INDEX idx_26xxx_bati_geom                                              -- Crée un index spatial sur la colonne geom
ON "26xxx_wold50m"."26xxx_bati"                                               -- Table cible de l'index
USING gist (geom);                                                            -- Type d'index spatial utilisé (gist)
COMMIT;                                                                       -- Valide la création de l'index


--*-----------------------------------------------------------------------------------------------------------*--


---- Création de la table "26xxx_bati200" : Bâtiments dans la zone de débroussaillement.

---- Description : Cette table extrait les bâtiments situés dans une zone de débroussaillement définie à 200 mètres 
--				   des massifs forestiers en conservant les données du bâti qui intersecte la zone de 
--                 débroussaillement
-- 				   -> Attributs : Tous les attributs des bâtiments


DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_bati200";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_bati200" AS
SELECT DISTINCT b.nature,                         -- Tous les attributs des bâtiments de la table source
       b.fid,                                     -- Identifiant unique du bâtiment
	   b.idu,                                     -- Identifiant unique de la commune
       ST_Multi(                                  -- Convertit en MultiPolygon
		  ST_CollectionExtract(                   -- Extrait uniquement les polygones (type 3)
			 ST_MakeValid(b.geom),                -- Corrige les géométries invalides
	   3)) AS geom                                -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_bati" b               -- Source : Bâtiments de la commune 26xxx
INNER JOIN public.old200m o						  -- Source : Zone tampon de débroussaillement de 200m autour des massifs forestiers
ON  ST_Intersects(o.geom, b.geom);                -- Confition : Intersection entre bâtiments et old200m
COMMIT;  

CREATE INDEX idx_26xxx_bati200_geom 
ON "26xxx_wold50m"."26xxx_bati200"
USING gist (geom); 
COMMIT;  


--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_bati200_cc" : Association des bâtiments avec les comptes communaux.

---- Description : Cette table associe chaque bâtiment situé dans la zone de débroussaillement (200m autour des 
--				   massifs forestiers) à son compte communal correspondant. Cela permet d'identifier les 
--				   responsabilités et les obligations communales concernant ces bâtiments en zones à risque.
-- 				   -> Attributs : Tous les attributs des bâtiments, les N°s des comptes commuanux des 
--                                unités foncières

CREATE INDEX IF NOT EXISTS idx_unite_fonciere_geom 
ON r_cadastre.geo_unite_fonciere 
USING GIST (geom);
COMMIT;

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_bati200_cc";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_bati200_cc" AS
WITH 
-- Associer les bâtiments à une seule unité foncière (évite les coupures)
bati_intersect AS (
    SELECT DISTINCT ON (b.fid)                                 -- Assigne chaque bâtiment à UNE SEULE unité foncière
           b.fid,                                              -- Identifiant unique du bâtiment                          
           b.nature,                                           -- Nature du bâtiment                         
           uf.comptecommunal,                                  -- N° de compte communal                         
           ST_Multi(                                           -- Convertit en MultiPolygon
		      ST_CollectionExtract(                            -- Extrait uniquement les polygones (type 3)
			     ST_MakeValid(b.geom)                          -- Corrige les géométries invalides
		   , 3)) AS geom                                       -- Géométries résultantes
    FROM "26xxx_wold50m"."26xxx_bati200" b                     -- Source : Bâtiments dans la zone des 200m autour des massifs forestiers              
    JOIN r_cadastre.geo_unite_fonciere uf                      -- Source : unités foncières de la commune
    ON ST_Intersects(ST_Centroid(b.geom), uf.geom)       -- Condition : quand la géométrie des unités foncières intersecte le pseudo-centroide du bati  
),
-- Sélectionner les bâtiments qui ne sont pas associés à une unité foncière
bati_non_associes AS (
    SELECT b.fid,                                              -- Identifiant unique du bâtiment  
           b.nature,                                           -- Nature du bâtiment   
           ST_Multi(                                           -- Convertit en MultiPolygon
		      ST_CollectionExtract(                            -- Extrait uniquement les polygones (type 3)
			     ST_MakeValid(b.geom),                         -- Corrige les géométries invalides
		   3)) AS geom,                                         -- Géométries résultantes
-- Recherche du compte communal de l'unité foncière la plus proche
           (SELECT uf.comptecommunal                           -- N° de compte communal
            FROM r_cadastre.geo_unite_fonciere uf              -- Source : unités foncières de la commune
            ORDER BY ST_Distance(ST_Centroid(b.geom), uf.geom) -- Ordonne par distance la plus proche entre le centroïde du batiment et les unites foncieres
            LIMIT 1) AS comptecommunal_proche 
    FROM "26xxx_wold50m"."26xxx_bati200" b                     -- Source : Bâtiments dans la zone des 200m autour des massifs forestiers  
    LEFT JOIN bati_intersect bi                                -- Source : Résultat de la requête précédente
	ON b.fid = bi.fid                                          -- Condition : quand les identifiant unique du bati sont identiques
    WHERE bi.fid IS NULL                                       -- Filtre : Sélectionne uniquement les bâtiments non encore associés
),

-- Fusionner les résultats en garantissant l'unicité des bâtiments
bati_final AS (
    SELECT bi.fid,                                             -- Identifiant unique du bâtiment
	       bi.nature,                                          -- Nature du bâtiment 
	       bi.comptecommunal,                                  -- N° de compte communal
	       ST_SetSRID(                                         -- Définit le système de projection en L93
	          ST_Multi(                                        -- Convertit en MultiPolygon
		         ST_CollectionExtract(                         -- Extrait uniquement les polygones (type 3)
			        ST_MakeValid(bi.geom),                     -- Corrige les géométries invalides
	          3)), 
	       2154) AS geom                                       -- Géométries résultantes
	FROM bati_intersect bi
	
    UNION ALL                                                 -- Aggrège les données des tables entre elles
    SELECT bna.fid,                                           -- Identifiant unique du bâtiment
	       bna.nature,                                        -- Nature du bâtiment 
	       bna.comptecommunal_proche AS comptecommunal,       -- N° de compte communal
	       ST_SetSRID(                                        -- Définit le système de projection en L93
	          ST_Multi(                                       -- Convertit en MultiPolygon
		         ST_CollectionExtract(                        -- Extrait uniquement les polygones (type 3)
			        ST_MakeValid(bna.geom),                   -- Corrige les géométries invalides
	          3)), 
	       2154) AS geom                                      -- Géométries résultantes 
	FROM bati_non_associes bna                                -- Source : Bâtiments présents dans les 200m qui n'ont pas été prise en compte dans le résultat de la requête précédente
)
SELECT bf.fid,                                                -- Identifiant unique du bâtiment
       bf.nature,                                             -- Nature du bâtiment 
       bf.comptecommunal,                                     -- N° de compte communal
       ST_SetSRID(                                            -- Définit le système de projection en L93
	      ST_Multi(                                           -- Convertit en MultiPolygon
		     ST_CollectionExtract(                            -- Extrait uniquement les polygones (type 3)
			    ST_MakeValid(bf.geom),                        -- Corrige les géométries invalides
		  3)), 
	   2154) AS geom                                          -- Géométries résultantes 
FROM bati_final bf;                                           -- Source : Bâtiments dans la zone des 200m autour des massifs forestiers avec leur compte communaux
COMMIT;

CREATE INDEX idx_26xxx_bati200_cc_geom 
ON "26xxx_wold50m"."26xxx_bati200_cc" 
USING GIST (geom);
COMMIT;

 --*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_bati200_cc_rg" : Regroupement des bâtiments inclus dans la zone des 200m par 
---- N° de compte communal.

---- Description : Cette table fusionne les géométries des bâtiments situés dans la zone de débroussaillement (200m 
--				   autour des massifs forestiers) et les regroupe par N° de compte communal.
-- 				   -> Attributs : N° de compte communal, géométrie du ou des bâtiments en un seul multipolygone

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_bati200_cc_rg";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_bati200_cc_rg" AS
SELECT b.comptecommunal,                   -- N° de compte communal
	   ST_Multi(ST_Union(b.geom)) AS geom  -- Fusionne les géométries des bâtiments en une seule entité par compte communal
FROM "26xxx_wold50m"."26xxx_bati200_cc" b  -- Source : Bâtiments associés aux comptes communaux
GROUP BY b.comptecommunal;                 -- Regroupe par N° de compte communal
COMMIT; 

ALTER TABLE "26xxx_wold50m"."26xxx_bati200_cc_rg"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154);  
COMMIT; 

CREATE INDEX idx_26xxx_bati_cc200_rg_geom 
ON "26xxx_wold50m"."26xxx_bati200_cc_rg"
USING gist (geom);  
COMMIT; 

--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_bati_tampon50" : Zones tampons de 50 mètres autour des bâtiments.

---- Description : Cette table génère des zones tampons de 50 mètres autour des bâtiments grâce à la fonction 
--                 "ST_Buffer" de Qgis. Les géométries résultantes sont regroupées par compte communal
--				   et stockées sous forme de MultiPolygons.
-- 				   -> Attributs : N° de compte communal, géométrie du regroupement des bâtiments inclus dans 
--                                la zone des 200m par N° de compte communal

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_bati_tampon50";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_bati_tampon50" AS
SELECT b.comptecommunal,            -- N° de compte communal
	   ST_Multi(                    -- Convertit en MultiPolygon
	      ST_Buffer(b.geom, 50, 16) -- Génère un tampon de 50m autour des bâtiments
	   ) AS geom                    -- Géométrie résultante
FROM "26xxx_wold50m"."26xxx_bati200_cc_rg" b;  -- Source : bâtiments regroupés par cc entièrement dans la zone "old_200m"
COMMIT;

ALTER TABLE "26xxx_wold50m"."26xxx_bati_tampon50"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154); 
COMMIT;

CREATE INDEX idx_26xxx_bati_tampon50_geom 
ON "26xxx_wold50m"."26xxx_bati_tampon50"
USING gist (geom);  
COMMIT;  


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----                                            PARTIE 5                                                      ----
----                                 CORRECTION DU ZONAGE URBAIN                                              ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
---- - Identifier les zones urbaines ("U") de la commune en croisant les données des bâtiments et             ----
----   des zones cadastrales. S'il n'y a pas de zone urbaine, création d'une couche avec les géométries de    ----
----   la "Mairie" et des "Eglises".                                                                         ----
---- - Regrouper toutes les zones urbaines en une seule entité pour faciliter les calculs suivants            ----
---- - Détecter les parcelles situées à moins de 10 mètres des zones urbaines, en se concentrant sur 	      ----
----   celles qui sont les plus proches des zones habitées.                                                   ----
---- - Extraire les points présents sur les contours des zones urbaines et des parcelles voisines             ----
----   pour repérer les "points orphelins", c'est-à-dire ceux qui ne sont pas alignés avec le zonage          ----
----   urbain.                                                                                                ----
---- - Filtrer et éliminer les points situés trop près des limites parcellaires mais trop éloignés des        ----
----   zones urbaines, afin d'affiner les zones nécessitant une attention particulière pour le                ----
----   débroussaillage.                                                                                       ----
----                                                                                                          ----
---- Ce processus vise à corriger les limites des zones urbaines avec les parcelles cadastrales (petites      ----
---- erreurs dues à une reprojection, ou une numérisation incomplète, qui gênent le bon déroulement           ----
---- des requêtes                                                                                             ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_zonage" : Zonage urbain de la commune ayant pour valeur de l'attribut "partition"   
---- 'DU_26xxx' et pour valeur de l'attribut "typezone" 'U'.

-- Cette opération est réalisée dans QGIS avant d'importer les données dans PostgreSQL.	--

-- Étape 1 : Charger la couche WFS "Zonage du document d’urbanisme" depuis la GeoPlateforme.
-- Étape 2 : Sélectionner les zones urbaines "U" de la commune "26xxx" dans QGIS.
--           Expression de sélection : "partition" = 'DU_26xxx' AND "typezone" = 'U'.
-- Étape 3 : Exporter les zones sélectionnées sous le nom "26xxx_zonage" en EPSG:4326.
-- Étape 4 : Importer la couche "26xxx_zonage" dans PostgreSQL avec transformation en EPSG:2154.


--*------------------------------------------------------------------------------------------------------------*--
-- Ce code vérifie si une table nommée "26xxx_zonage" existe dans le schéma "26xxx_wold50m".                             --
-- Si elle existe mais est vide, la table est recréée et remplie avec des données géométriques                  --
-- représentant les zones urbaines contenant des mairies et des églises de la commune spécifiée,                --
-- calculées à partir des intersections entre bâtiments, zones d'intérêt et limites cadastrales. Si la          --
-- table contient déjà des données, un message correspondant est affiché sans effectuer                         --
-- d'autres actions.                                                                                         	--
--*------------------------------------------------------------------------------------------------------------*--

DO $$
BEGIN
    -- Vérifie si la table "26xxx_zonage" existe
    IF NOT EXISTS (
        SELECT 1                                                   -- Vérifie existence dans le catalogue
        FROM information_schema.tables
        WHERE table_schema = 'public'                              -- Schéma ciblé : public
        AND table_name = '26xxx_zonage'                            -- Nom exact de la table recherchée
    ) THEN
        RAISE NOTICE 'La table 26xxx_zonage n''existe pas. Création avec insertion des données...';  -- Message console

        CREATE TABLE public."26xxx_zonage" AS                      -- Création de la table avec insertion immédiate
        SELECT 'Mairie' AS nature,                                    -- Attribut nature
            'U' AS typezone,                                       -- Attribut zone urbaine
            'DU_26xxx' AS partition,                               -- Attribut de partition générique
            c.idu,                                                  -- Code INSEE de la commune
			ST_Force2D(                                            -- Force la géométrie en 2D
              ST_Intersection(                                     -- Intersecte les zones d’activité et les bâtiments
                ST_Union(t.geom),                             -- Union des géométries des zones d’activité
                ST_Union(b.geom)                              -- Union des géométries des bâtiments
              )
            ) AS geom
        FROM r_bdtopo.zone_d_activite_ou_d_interet t               -- Source : zones d’activités et d'intérêts issues de la BDTopo
        JOIN r_bdtopo.batiment b ON ST_Intersects(t.geom, b.geom)  -- Jointure spatiale bâtiments/zones
        JOIN r_cadastre.geo_commune c ON ST_Intersects(b.geom, c.geom) -- Jointure spatiale avec la commune
        WHERE t.nature = 'Mairie'                                  -- Filtrage : nature = Mairie
        AND c.idu = 'xxx'                                          -- Commune cible
        GROUP BY t.nature, t.geom, idu                        -- Agrégation pour ST_Union

        UNION ALL                                                  -- Ajout des bâtiments religieux

        SELECT 'Eglise' AS nature,                                    -- Attribut nature
            'U' AS typezone,                                       -- Attribut zone urbaine
            'DU_26xxx' AS partition,                               -- Attribut de partition générique
            c.idu,                                                  -- Code INSEE
			ST_Force2D(ST_Intersection(b.geom, c.geom)) AS geom-- Intersection bâtiment/commune
        FROM r_bdtopo.batiment b                                   -- Source : bâtiments issus de la BDTopo
        JOIN r_cadastre.geo_commune c ON ST_Intersects(b.geom, c.geom)  -- Jointure spatiale
        WHERE b.nature = 'Eglise'                                  -- Filtrage : nature = Eglise
        AND c.idu = 'xxx';                                         -- Commune cible

    ELSE
        RAISE NOTICE 'La table 26xxx_zonage existe déjà. Aucune donnée insérée.';  -- Aucun traitement si la table existe
    END IF;
END $$;  -- Fin du bloc DO

ALTER TABLE public."26xxx_zonage"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154);  
COMMIT;  

CREATE INDEX IF NOT EXISTS idx_26xxx_zonage_geom 
ON public."26xxx_zonage"
USING gist (geom); 
COMMIT; 


--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_zonage_rg" : Regroupement des zones urbaines
  -- Description : Cette table regroupe les géométries des zones urbaines (type "U") en une seule 
  --               entité spatiale par type de zone. Les géométries sont validées et converties 
  --               en MultiPolygon pour garantir leur cohérence géométrique.

-- Supprimer la table "26xxx_zonage_rg" si elle existe déjà pour éviter les conflits et doublons
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_rg";
COMMIT; 

-- Créer une nouvelle table "26xxx_zonage_rg" où les géométries des zones urbaines sont 
-- fusionnées, validées et regroupées par type de zone.
CREATE TABLE "26xxx_wold50m"."26xxx_zonage_rg" AS
WITH union_zu AS (
SELECT ST_Multi(						  --  Converties en MultiPolygon
          ST_MakeValid(					  --  Valide les géométries
             ST_Union(z.geom))) AS geom,  -- Fusionne les géométries
             z.typezone					  -- Type de zone (par exemple "U" pour urbain)
FROM public."26xxx_zonage" z			  -- Source : données de zonage
WHERE z.typezone = 'U'					  -- Filtre : inclut uniquement les zones de type "U" (urbaines)
GROUP BY z.typezone						  -- Regroupement des géométries par type de zone
),
-- 1) Épuration des épines externes 
--	 aller retour avec 3 noeuds disctincts alignés
--   supprime le noeud de l'extrémité 
epine_externe AS (
	SELECT uzu.typezone,                         -- 
        ST_SetSRID(                                   -- Définit le système de coordonnées EPSG:2154
		  ST_Multi(                                   -- Convertit en MultiPolygon
			ST_CollectionExtract(                     -- Extrait uniquement les géométries de type 3
  			  ST_MakeValid(
   				ST_Snap(                              -- Aligne le tampon de la géométrie sur la géométrie d'origine
     			  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  uzu.geom, 
					  -0.0001,                        -- Ajout d'un tampon négatif de l'ordre de 10 nm
					  'join=mitre mitre_limit=5.0'),  -- 
					  0.0003),			              -- Suppression des noeuds consécutifs proches de plus de 30 nm
				  uzu.geom,
                  0.0006)),3)),                       -- Avec une distance d'accrochage de l'ordre de 60 nm
		  2154) AS geom                               -- Géométries résultantes
    FROM union_zu uzu           -- Source : 
	),
-- 3) Épuration des épines internes
epine_interne AS (
	SELECT epext.typezone,                      -- 
        ST_SetSRID(                                   -- Définit le système de coordonnées EPSG:2154
		  ST_Multi(                                   -- Convertit en MultiPolygon
			ST_CollectionExtract(                     -- Extrait uniquement les géométries de type 3
   			  ST_MakeValid(
   				ST_Snap(                              -- Aligne le tampon de la géométrie sur la géométrie d'origine
     			  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  epext.geom, 
					  0.0001,                         -- Ajout d'un tampon positif de l'ordre de 10 nm [**param**]
					  'join=mitre mitre_limit=5.0'),  -- 
					  0.0003),			              -- Suppression des noeuds consécutifs proches de plus de 30 nm
				  uzu.geom,
                  0.0006)),3)),                       -- Avec une distance d'accrochage de l'ordre de 60 nm
		  2154) AS geom                               -- Géométries résultantes
    FROM epine_externe epext                          -- Source : Zones corrigées sans épines extérieures
	JOIN union_zu uzu
	ON epext.typezone = uzu.typezone
	)
-- 3) Résultat final : on convertit la géométrie en MultiPolygon valide
SELECT epint.typezone,                          -- 
       ST_SetSRID(                                    -- Définit le système de coordonnées EPSG:2154
          ST_Multi(                                   -- Convertit en MultiPolygon
			 ST_CollectionExtract(                    -- Extrait uniquement les géométries de type 3
   				ST_MakeValid(epint.geom),             -- Corrige les géométries invalides                                    
			 3)),
	    2154) AS geom                                 -- Géométries résultantes
FROM epine_interne epint;                             -- Source : Zones corrigées sans épines extérieures ni intérieures
--WHERE (ST_MakeValid(epint.geom) IS NOT NULL  
--	AND ST_IsEmpty(ST_MakeValid(epint.geom)) = false
--	AND ST_IsValid(ST_MakeValid(epint.geom)) = true);
COMMIT;  -- Valider l'assignation du système de coordonnées

-- Créer un index spatial sur la colonne "geom" pour optimiser les requêtes spatiales 
CREATE INDEX idx_26xxx_zonage_rg_geom 
ON "26xxx_wold50m"."26xxx_zonage_rg"
USING gist (geom);  -- Utilise un index spatial GiST pour optimiser les calculs géographiques
COMMIT;  -- Valider la création de l'index

-- Notes explicatives :
-- - ST_Union : Fusionne plusieurs géométries en une seule entité géographique.
-- - ST_MakeValid : Corrige les géométries invalides pour garantir leur conformité aux standards géométriques.
-- - ST_Multi : Convertit les géométries en MultiPolygon, assurant une cohérence typologique.


---- Création de la table "26xxx_zonage_rgs" : Géométries corrigées pour le zonage urbain
-- Description : Cette table contient les géométries corrigées et alignées des zones urbaines (type "U").
-- 				 Les géométries des zones de zonage urbain sont corrigées avec un alignement précis sur celles 
--				 des parcelles cadastrales.
-- Objectif : Assurer une compatibilité géométrique pour des analyses géospatiales précises et fiables.

-- Supprimer la table "26xxx_zonage_rgs" si elle existe déjà
-- Cette étape garantit une recréation propre de la table.
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_rgs";

-- Créer la table "26xxx_zonage_rgs" avec les géométries corrigées
-- Les géométries des zones urbaines sont alignées sur les géométries des parcelles, corrigées et fusionnées.
CREATE TABLE "26xxx_wold50m"."26xxx_zonage_rgs" AS
SELECT DISTINCT ST_Multi(  -- Convertit les résultats en MultiPolygon pour garantir la cohérence géométrique
					ST_Snap(  -- Aligne les points des géométries des zones urbaines sur celles des parcelles
						z.geom, ST_Collect(ST_MakeValid(p.geom)),  -- Corrige les géométries des parcelles
						0.05  -- Tolérance d'alignement : 50 centimètres
					)
				) AS geom  -- Géométrie finale corrigée
FROM "26xxx_wold50m"."26xxx_parcelle" AS p  -- Table des parcelles cadastrales
INNER JOIN "26xxx_wold50m"."26xxx_zonage_rg" AS z  -- Table des zones urbaines corrigées
ON ST_DWithin(z.geom, p.geom, 1)  -- Condition : les zones urbaines doivent être à 1 mètre des parcelles
GROUP BY z.geom;  -- Groupement par géométrie de zone pour garantir des résultats distincts
COMMIT;  -- Valider la création de la table

-- Définir le système de coordonnées Lambert93 (EPSG:2154)
-- Cette étape garantit que toutes les géométries utilisent le même système de coordonnées.
ALTER TABLE "26xxx_wold50m"."26xxx_zonage_rgs"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154);  -- Applique EPSG:2154 comme système de coordonnées
COMMIT;  -- Valider l'assignation du système de coordonnées

-- Créer un index spatial sur la colonne "geom"
-- Cet index améliore les performances des requêtes spatiales.
CREATE INDEX idx_26xxx_zonage_rgs_geom 
ON "26xxx_wold50m"."26xxx_zonage_rgs"
USING gist (geom);  -- Utilise un index GiST pour optimiser les opérations spatiales
COMMIT;  -- Valider la création de l'index

-- Notes explicatives :
-- ST_MakeValid :
--    - Corrige les géométries invalides comme les auto-intersections.
--    - Garantit une compatibilité avec les fonctions géométriques.
-- ST_Buffer : Appliqué avec une valeur de 0, il corrige les défauts géométriques (exemple : chevauchements, artefacts).
-- ST_Snap :
--    - Aligne les géométries des zones sur les parcelles avec une tolérance définie (ici 1 cm).
--    - Permet de réduire les erreurs géométriques dues aux imprécisions dans les données sources.
-- ST_Multi : Convertit les géométries en MultiPolygon pour assurer une uniformité des types géométriques.


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----                             SOUS-PARTIE 1 : IDENTIFICATION DES POINTS ORPHELINS                          ----
----                                                                                                          ----
----  Objectif : Localiser les points orphelins sur le contour du zonage                                      ----
----                                                                                                          ----
----  Contexte : Ces points sont présents sur le contour du zonage et sont à moins de 10 cm d'une limite      ----
---   de parcelle, mais il n'y a pas de noeud existant sur le segment de la parcelle                          ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_parcelle_zu_t0" : Sélection des parcelles proches des 
  -- zones urbaines 
  -- Description : Cette table contient les géométries des parcelles situées à moins de 10 mètres
  --               des zones urbaines.Elle vise à réduire le nombre de parcelles participant au calcul 
  --               d'ajustement du zonage. Le contenu est une géométrie collection (ST_Collect), 
  --               non directement affichable dans QGIS.

-- Supprimer la table "26xxx_parcelle_zu_t0" si elle existe déjà pour éviter tous conflits 
-- et doublons
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_parcelle_zu_t0";

-- Créer la nouvelle table "26xxx_parcelle_zu_t0"  des parcelles proches des zones 
-- urbaines. La table collecte les géométries des parcelles situées à moins de 10 mètres des 
-- zones urbaines (ST_Buffer).
CREATE TABLE "26xxx_wold50m"."26xxx_parcelle_zu_t0" AS
SELECT ST_Collect(ptf4.geom) AS geom -- Collecte les géométries des parcelles dans une géométrie unique
FROM "26xxx_wold50m"."26xxx_parcelle" AS ptf4, -- Source : parcelles initiales
     "26xxx_wold50m"."26xxx_zonage_rgs" AS zrg  -- Source : zones urbaines
WHERE ST_Intersects( -- Vérifie l'intersection entre les géométries
                    ptf4.geom,
                    ST_Buffer(zrg.geom, 1)
                    ); -- Crée une zone tampon de 1 mètre autour des zones urbaines
COMMIT; -- Valider la création de la table

-- Créer un index spatial GiST sur la colonne "geom" améliorant les performances pour les calculs
CREATE INDEX idx_26xxx_parcelle_zu_t0_geom 
ON "26xxx_wold50m"."26xxx_parcelle_zu_t0"
USING gist (geom); -- Utilise un index spatial GiST pour optimiser les opérations
COMMIT; -- Valider la création de l'index

-- Notes explicatives : 
-- - ST_Collect : Combine les géométries des parcelles sélectionnées dans une seule entité géométrique. 
-- - ST_Buffer : Crée une zone tampon autour des zones urbaines, ici à 10 mètres. 
-- - ST_Intersects : Vérifie si les parcelles et les zones urbaines tamponnées se croisent. 

--*------------------------------------------------------------------------------------------------------------*--
---- Création de la table "26xxx_parcelle_zu_t1" : Extraction des sommets des parcelles 
  -- proches des zones urbaines
  -- Description : Cette table contient les points individuels extraits des géométries des parcelles
  --               proches des zones urbaines. Elle décompose les contours des parcelles en éliminant 
  --               les points redondants pour des analyses plus précises et ciblées.

-- Supprimer la table "26xxx_parcelle_zu_t1" si elle existe déjà pour éviter les conflits 
-- ou doublons.
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_parcelle_zu_t1";

-- Créer une nouvelle table "26xxx_parcelle_zu_t1" décomposant les géométries des 
-- parcelles proches des zones urbaines en points individuels.
CREATE TABLE "26xxx_wold50m"."26xxx_parcelle_zu_t1" AS
SELECT (ST_Dump( -- Décompose les collections géométriques en entités individuelles
          ST_RemoveRepeatedPoints( -- Supprime les points redondants pour éviter les doublons
             ST_Points(ptfz.geom) -- Extrait les sommets (points) de chaque géométrie polygonale
       ))).geom AS geom -- Définit la colonne résultante "geom" contenant les points extraits
FROM "26xxx_wold50m"."26xxx_parcelle_zu_t0" AS ptfz; -- Source : parcelles proches des zones urbaines
COMMIT; -- Valider la création de la table

-- Créer un index spatial GiST sur la colonne "geom" améliorant les performances des requêtes
CREATE INDEX idx_26xxx_parcelle_zu_t1_geom 
ON "26xxx_wold50m"."26xxx_parcelle_zu_t1"
USING gist (geom); -- Utilise un index spatial GiST pour optimiser les calculs géographiques
COMMIT; -- Valider la création de l'index

-- Notes explicatives :
-- - ST_Points : Extrait tous les sommets individuels (points) des géométries polygonales.
-- - ST_RemoveRepeatedPoints : Supprime les points consécutifs identiques dans les géométries, réduisant les doublons.
-- - ST_Dump : Décompose les collections géométriques (comme MULTIPOINT) en entités géométriques simples (POINT).

--*------------------------------------------------------------------------------------------------------------*--
---- Création de la table "26xxx_parcelle_zu_t2" : Union des sommets des parcelles 
  -- proches des zones urbaines

-- Supprimer la table "26xxx_parcelle_zu_t2" si elle existe déjà pour éviter les conflits 
-- ou doublons.
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_parcelle_zu_t2";

-- Créer une nouvelle table "26xxx_parcelle_zu_t2" Union des sommets des parcelles 
  -- proches des zones urbaines
CREATE TABLE "26xxx_wold50m"."26xxx_parcelle_zu_t2" AS
SELECT ST_Union(zut1.geom) AS geom
FROM "26xxx_wold50m"."26xxx_parcelle_zu_t1" zut1;
COMMIT; -- Valider la création de la table

-- Créer un index spatial GiST sur la colonne "geom" améliorant les performances des requêtes
CREATE INDEX idx_26xxx_parcelle_zu_t2_geom 
ON "26xxx_wold50m"."26xxx_parcelle_zu_t2"
USING gist (geom); -- Utilise un index spatial GiST pour optimiser les calculs géographiques
COMMIT; -- Valider la création de l'index

--*------------------------------------------------------------------------------------------------------------*--
---- Création de la table "26xxx_zonage_corr1" : Extraction des points des contours des polygones
  -- Description : Cette table contient les points individuels extraits des contours des zones urbaines.
  --               Les points sont extraits des géométries polygonales, y compris les trous éventuels, 
  --               afin de faciliter les analyses géométriques et les traitements ultérieurs.

-- Supprimer la table "26xxx_zonage_corr1" si elle existe déjà pour éviter tout conflit ou doublon.
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr1";

-- Créer une nouvelle table "26xxx_zonage_corr1" qui extrait les points des contours des zones 
-- urbaines, y compris ceux des éventuels trous internes.
CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr1" AS
SELECT (ST_DumpPoints(zrg.geom)).path AS corr1path, -- Décompose et extrait des points des contours
		(ST_DumpPoints(zrg.geom)).geom AS geom
FROM "26xxx_wold50m"."26xxx_zonage_rgs" AS zrg; -- Source : table regroupant les géométries de zu
COMMIT; -- Valider la création de la table

-- Créer un index spatial GiST sur la colonne "geom" améliorant les performances des requêtes
CREATE INDEX idx_26xxx_zonage_corr1_geom 
ON "26xxx_wold50m"."26xxx_zonage_corr1" -- Index appliqué à la table nouvellement créée
USING gist (geom); -- Utilise un index spatial GiST pour optimiser les calculs géométriques
COMMIT; -- Valider la création de l'index

-- Notes explicatives :
-- ST_DumpPoints : Extrait tous les sommets individuels (points) des géométries polygonales, y compris 
--                 ceux des trous internes.

--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_zonage_corr3" : Recale les points de contour du zonage sans "vis à vis" 
-- Description : Cette table contient les points du contour du zonage recalés 
-- sur le point le plus proche d'un segment de parcelle, jusquà une distance de 10 cm (ajustable)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr3";

CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr3" AS
-- extraction des sommets des parcelles proches
WITH sommets_parcelles AS (
  SELECT geom FROM "26xxx_wold50m"."26xxx_parcelle_zu_t1"
),

-- points du zonage déjà exactement sur un sommet de parcelle
exact_match AS (
  SELECT 
    z2.corr1path AS corr3path,
    z2.geom AS geom,
    'origine_sur_parcelle'::text AS recalage_mode
  FROM "26xxx_wold50m"."26xxx_zonage_corr1" z2
  JOIN sommets_parcelles p
    ON ST_Equals(z2.geom, p.geom)
),

-- points du zonage à snapper vers un sommet proche (si pas déjà traité)
snap_points AS (
  SELECT 
    z2.corr1path AS corr3path,
    p.geom AS geom,
    ST_Distance(z2.geom, p.geom) AS dist,
    'snap_sur_sommet'::text AS recalage_mode
  FROM "26xxx_wold50m"."26xxx_zonage_corr1" z2
  LEFT JOIN exact_match em ON z2.corr1path = em.corr3path
  JOIN sommets_parcelles p
    ON ST_DWithin(z2.geom, p.geom, 0.1)
  WHERE em.corr3path IS NULL
),

snap_min AS (
  SELECT DISTINCT ON (corr3path)
         corr3path,
         geom,
         recalage_mode
  FROM snap_points
  ORDER BY corr3path, dist ASC
),

--  projection orthogonale (segments)
segments_parcelles AS (
  SELECT (ST_Dump(ST_Boundary(geom))).geom AS segment
  FROM "26xxx_wold50m"."26xxx_parcelle_zu_t0"
),

projections AS (
  SELECT 
    z2.corr1path AS corr3path,
    ST_ClosestPoint(s.segment, z2.geom) AS geom,
    ST_Distance(z2.geom, s.segment) AS dist,
    'projection_segment'::text AS recalage_mode
  FROM "26xxx_wold50m"."26xxx_zonage_corr1" z2
  LEFT JOIN exact_match em ON z2.corr1path = em.corr3path
  LEFT JOIN snap_min sm ON z2.corr1path = sm.corr3path
  JOIN segments_parcelles s
    ON ST_DWithin(s.segment, z2.geom, 0.1)
  WHERE em.corr3path IS NULL AND sm.corr3path IS NULL
),

projections_min AS (
  SELECT DISTINCT ON (corr3path)
         corr3path,
         geom,
         recalage_mode
  FROM projections
  ORDER BY corr3path, dist ASC
),

-- points non traités (aucun recalage possible)
non_recales AS (
  SELECT 
    z2.corr1path AS corr3path,
    z2.geom,
    'non_recalé'::text AS recalage_mode
  FROM "26xxx_wold50m"."26xxx_zonage_corr1" z2
  LEFT JOIN exact_match em ON z2.corr1path = em.corr3path
  LEFT JOIN snap_min sm ON z2.corr1path = sm.corr3path
  LEFT JOIN projections_min pr ON z2.corr1path = pr.corr3path
  WHERE em.corr3path IS NULL AND sm.corr3path IS NULL AND pr.corr3path IS NULL
),

-- fusion ordonnée (ordre prioritaire respecté)
fusion_finale AS (
  SELECT * FROM exact_match
  UNION ALL
  SELECT * FROM snap_min
  UNION ALL
  SELECT * FROM projections_min
  UNION ALL
  SELECT * FROM non_recales
)
SELECT * FROM fusion_finale;
COMMIT;

-- Créer un index spatial GiST sur la colonne "geom" améliorant les performances
CREATE INDEX idx_26xxx_zonage_corr3_geom 
ON "26xxx_wold50m"."26xxx_zonage_corr3" -- Index appliqué sur la table 
USING gist (geom); -- Utilise un index spatial GiST pour optimiser les calculs géographiques
COMMIT; -- Valider la création de l'index

--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_zonage_corr4" : Remplace les points à recaler par les points recalés
-- du zonage

-- Supprimer la table "26xxx_zonage_corr4" si elle existe déjà pour éviter tout conflit 
-- ou doublon.
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr4";

CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr4" AS
SELECT z3.corr3path AS path,
		z3.geom -- Sélectionne les géométries des points du zonage
FROM  "26xxx_wold50m"."26xxx_zonage_corr3" AS z3 -- Source : points du zonage recalés
UNION ALL
SELECT z1.corr1path AS path,
       z1.geom -- Points du zonage d'origine, uniquement si non recalés
FROM "26xxx_wold50m"."26xxx_zonage_corr1" AS z1
LEFT JOIN "26xxx_wold50m"."26xxx_zonage_corr3" AS z3
ON z1.corr1path = z3.corr3path
WHERE z3.corr3path IS NULL; -- Exclure les points déjà recalés
COMMIT; -- Valider la création de la table

-- Créer un index spatial GiST sur la colonne "geom" améliorant les performances
CREATE INDEX idx_26xxx_zonage_corr4_geom 
ON "26xxx_wold50m"."26xxx_zonage_corr4" -- Index appliqué sur la table 
USING gist (geom); -- Utilise un index spatial GiST pour optimiser les calculs géographiques
COMMIT; -- Valider la création de l'index

--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_zonage_corr5" : Reconstruction des anneaux des polygones du zonage urbain
  -- Description : Cette table regroupe les points du zonage pour reconstruire les anneaux extérieurs 
  -- et intérieurs des polygones.

-- Supprimer la table "26xxx_zonage_corr4" si elle existe déjà pour éviter tout conflit
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr5";

-- Créer la table "26xxx_zonage_corr4" avec les anneaux reconstruits
CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr5" AS
SELECT corr4.path[1] AS path1, -- Identifiant du polygone
       corr4.path[2] AS path2, -- Identifiant de l'anneau (1 = extérieur, >1 = intérieur)
       ST_MakeLine(corr4.geom ORDER BY corr4.path) AS geom -- Reconstruction des anneaux avec tri
FROM "26xxx_wold50m"."26xxx_zonage_corr4" corr4
GROUP BY corr4.path[1], corr4.path[2];
COMMIT; -- Valide la création de la table

-- Créer un index spatial GiST pour optimiser les requêtes
CREATE INDEX idx_26xxx_zonage_corr5_geom
ON "26xxx_wold50m"."26xxx_zonage_corr5"
USING gist (geom);
COMMIT; -- Valide la création de l'index

--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_zonage_corr4" : Reconstruction des polygones du zonage urbain
  -- Description : Cette table reconstruit les polygones du zonage urbain à partir des anneaux extérieurs
  -- et intérieurs.

-- Supprimer la table "26xxx_zonage_corr4" si elle existe déjà pour éviter tout conflit
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr4";

-- Créer la table "26xxx_zonage_corr4" avec les polygones reconstruits
CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr4" AS
WITH array_geom AS (
    SELECT DISTINCT path1,
           ARRAY(
                SELECT ST_AddPoint(corr5.geom, ST_StartPoint(corr5.geom)) AS geom -- Ferme l'anneau en ajoutant le premier point à la fin
                FROM "26xxx_wold50m"."26xxx_zonage_corr5" corr5
                WHERE corr5.path1 = ag.path1
                ORDER BY corr5.path2
           ) AS array_anneaux
    FROM "26xxx_wold50m"."26xxx_zonage_corr5" ag
)
SELECT ag.path1 AS path1,
       ST_MakePolygon(
            ag.array_anneaux[1],  -- Anneau extérieur
            ag.array_anneaux[2:] -- Anneaux intérieurs
       ) AS geom
FROM array_geom ag;
COMMIT; -- Valide la création de la table

-- Créer un index spatial GiST pour optimiser les requêtes
CREATE INDEX idx_26xxx_zonage_corr4_geom
ON "26xxx_wold50m"."26xxx_zonage_corr4"
USING gist (geom);
COMMIT; -- Valide la création de l'index

-- Notes explicatives :
-- - ST_MakePolygon : Crée un polygone à partir d'un anneau extérieur et d'éventuels anneaux intérieurs.
-- - ARRAY : Regroupe les anneaux en un tableau pour chaque polygone.
-- - ORDER BY : Tri des anneaux pour garantir leur bon ordonnancement.

--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_zonage_corr7" : Regroupement des polygones en un MultiPolygon unique
  -- Description : Cette table regroupe tous les polygones corrigés pour créer une couche unique de zonage.

-- Supprimer la table "26xxx_zonage_corr7" si elle existe déjà pour éviter tout conflit
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr7";

-- Créer la table "26xxx_zonage_corr7" avec un MultiPolygon unique
CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr7" AS
SELECT ST_Multi(ST_Union(corr4.geom)) AS geom
FROM "26xxx_wold50m"."26xxx_zonage_corr4" corr4;
COMMIT; -- Valide la création de la table

-- Créer un index spatial GiST pour optimiser les requêtes
CREATE INDEX idx_26xxx_zonage_corr7_geom
ON "26xxx_wold50m"."26xxx_zonage_corr7"
USING gist (geom);
COMMIT; -- Valide la création de l'index

-- Notes explicatives :
-- - ST_Union : Fusionne toutes les géométries pour former un seul ensemble géométrique.
-- - ST_Multi : Convertit le résultat en MultiPolygon pour garantir une typologie cohérente.


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE 6                                                    ----
----                              GESTION DES ZONES DE SUPERPOSITION DES OLD                                 ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
---- - Création de la table des intersections des tampons : Identification des zones de recouvrement entre   ----
----   tampons de bâtiments appartenant à des comptes communaux différents.                                  ----
---- - Retrait des zones urbaines des tampons : Soustraction des parties des tampons qui se recouvrent       ----
----   avec des zones urbaines.                                                                              ----
---- - Nettoyage et suppression des géométries vides : Suppression des géométries inutiles ou invalides      ----
----   résultant des opérations de retrait.                                                                  ----
---- - Regroupement des zones restantes : Fusion des entités corrigées pour obtenir une géométrie unique et  ----
----   cohérente des zones tampons finales.                                                                  ----
----                                                                                                         ----
----   Ce processus identifie les zones de superposition entre les tampons de bâtiments appartenant à des    ----
----   comptes communaux différents, retire les parties des tampons situées dans les zones urbaines,         ----
----   nettoie les géométries inutiles et regroupe les entités restantes pour former une délimitation        ----
----   unique des zones tampons. Cette étape permettra d’arbitrer les responsabilités du débroussaillement   ----
---    dans les zones de superposition.                                                                      ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--


---- Création de la table "26xxx_tampon_i" : Intersections des zones tampons avec identification des deux comptes 
---- communaux

-- Description : Cette table contient les **zones d'intersection** entre les **tampons** des bâtiments (50m) 
--               appartenant à des comptes communaux différents. Elle permet de **détecter les zones de 
--               recouvrement** entre les tampons des bâtiments, en identifiant les **comptes communaux** 
--               impliqués dans ces intersections. Les intersections sont calculées avec une **tolérance de 1 cm**
--               pour assurer la précision de l'analyse géospatiale.
-- 				 -> Attributs : zone d'intersection entre les tampons des bâtiments de différents comptes 
--                              communaux (MultiPolygon, 2154), numéro du premier compte communal** impliqué dans 
--                              l'intersection, **numéro du deuxième compte communal** impliqué dans l'intersection.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_tampon_i";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_tampon_i" AS
SELECT ST_Multi(                                                 -- Convertit en Multipolygon
	      ST_Intersection(t1.geom, t2.geom)                      -- Intersection des tampons des bâtiments
	   ) AS geom,                                                -- Géométrie résultante
       t1.comptecommunal AS comptecomm1,                         -- N° du premier compte communal
       t2.comptecommunal AS comptecomm2                          -- N° du deuxième compte communal
FROM "26xxx_wold50m"."26xxx_bati_tampon50" t1                    -- Source : tampon de 50m autour des bâtis
JOIN "26xxx_wold50m"."26xxx_bati_tampon50" t2                    -- Source : tampon de 50m autour des bâtis
ON t1.comptecommunal <> t2.comptecommunal                        -- Condition : Exclut les intersections au sein d'un même compte communal
AND ST_DWithin(t1.geom, t2.geom, 0.01)                           -- Condition : Vérifie la proximité des tampons avec une tolérance de 1 cm
AND ST_Intersects(t1.geom, t2.geom)                              -- Condition : intersection géométriqueentre les deux mêmes géométries
AND ST_Area(ST_Intersection(t1.geom, t2.geom))>1
GROUP BY t1.comptecommunal, t2.comptecommunal, t1.geom, t2.geom; -- Regroupe en fonction des attributs
COMMIT;

ALTER TABLE "26xxx_wold50m"."26xxx_tampon_i"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154); 
COMMIT; 

CREATE INDEX "idx_26xxx_tampon_i_geom" 
ON "26xxx_wold50m"."26xxx_tampon_i"
USING gist (geom); 
COMMIT;  


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_tampon_ihu" : Retrait des zones urbaines des tampons.

-- Description : Cette table extrait les zones tampon en excluant les géométries recouvrant des zones urbaines. 
--               Elle permet de **retirer** les parties des tampons qui se chevauchent avec les **zones urbaines**, 
--               ne conservant que les zones tampon pertinentes.
-- 				 -> Attributs : zone tampon corrigée après retrait des zones urbaines (MultiPolygon, 2154), 
--                              **Numéro du premier compte communal** impliqué dans l'intersection des tampons, 
--                              **Numéro du deuxième compte communal** impliqué dans l'intersection des tampons.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_tampon_ihu";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_tampon_ihu" AS
-- Géométries avec intersection
SELECT  t.comptecomm1,                                    -- N° de compte communal du premier tampon
        t.comptecomm2,                                    -- N° de compte communal du second tampon
        ST_Multi(                                         -- Convertit la géométrie résultante en **MultiPolygon**
		   ST_Union(                   				      -- Fusionne pour éviter les petits polygones isolés
			ST_MakeValid(         					      -- Corrige les géométries invalides
			   ST_Difference(     					      -- Garde uniquement la partie qui ne s'intersecte pas
				  ST_CollectionExtract(ST_MakeValid(t.geom), 3),
				  ST_CollectionExtract(ST_MakeValid(z_corr7.geom), 3))))  -- Corrige les géométries invalides du zonage
		) AS geom                                         -- Géométrie résultante
FROM "26xxx_wold50m"."26xxx_tampon_i" AS t                -- Source : zones tampons corrigées 
JOIN "26xxx_wold50m"."26xxx_zonage_corr7" AS z_corr7      -- Source : zone urbaine
ON ST_Intersects(t.geom, z_corr7.geom)                    -- Appliquer la soustraction uniquement si les géométries se recouvrent
WHERE ST_Area(ST_Difference(t.geom, z_corr7.geom)) > 0.01
GROUP BY  t.comptecomm1,t.comptecomm2,t.geom, z_corr7.geom

UNION ALL -- Combine les résultats des tampons ayant subi la soustraction et des tampons non affectés par les zones urbaines

-- Conserver les géométries sans intersection
SELECT t.comptecomm1,                                     -- N° de compte communal du premier tampon
       t.comptecomm2,                                     -- N° de compte communal du second tampon
       ST_Multi(                                          -- Convertit la géométrie résultante en **MultiPolygon**
		   ST_CollectionExtract(                          -- Extrait les **polygones** (type 3) 
		      ST_MakeValid(t.geom),                       -- Conserve la géométrie initiale des tampons non impactés et valides
	   3)) AS geom                                        -- Géométrie résultante
FROM "26xxx_wold50m"."26xxx_tampon_i" AS t                -- Source : zones tampons corrigées 
WHERE NOT EXISTS (                                        -- Vérifie qu'il n'y a **pas d'intersection** avec des zones urbaines
          SELECT 1 
          FROM "26xxx_wold50m"."26xxx_zonage_corr7" AS z_corr7 -- Source : zone urbaine
          WHERE ST_Intersects(t.geom, z_corr7.geom));           -- Aucun recouvrement avec des zones urbaines
COMMIT; 

ALTER TABLE "26xxx_wold50m"."26xxx_tampon_ihu"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154); 
COMMIT;

DELETE FROM "26xxx_wold50m"."26xxx_tampon_ihu"  
WHERE geom IS NULL  
OR ST_IsEmpty(geom)  
OR NOT ST_IsValid(geom); 
COMMIT; 

CREATE INDEX idx_26xxx_tampon_ihu_geom
ON "26xxx_wold50m"."26xxx_tampon_ihu"
USING gist (geom);  
COMMIT; 


--------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_tampon_ihu_rg" : Regroupement final des zones tampons après découpe.

-- Description : Cette table regroupe toutes les entités restantes après les opérations de découpe et de retrait 
--               des zones urbaines. L'objectif est de créer une **géométrie unique et cohérente** pour délimiter
--               les zones finales. Ces zones serviront de **base pour des calculs d'arbitrage**.
-- 				 -> Attributs : **Zone tampon finale**, après fusion des géométries et retrait des zones urbaines
--                              (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_tampon_ihu_rg";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_tampon_ihu_rg" AS
SELECT ST_Multi(                              -- Convertit la géométrie résultante en **MultiPolygon**
		   ST_CollectionExtract(              -- Extrait les **polygones** (type 3) 
		      ST_Union(                       -- Regroupe les géométries en les fusionnant
				 ST_MakeValid(t.geom)),       -- Rend valide les géométries
		3)) AS geom                           -- Géométries fusionnées pour former une entité unique
FROM "26xxx_wold50m"."26xxx_tampon_ihu" AS t; -- Source : zones tampons corrigées après exclusion des zones urbaines
COMMIT;

ALTER TABLE "26xxx_wold50m"."26xxx_tampon_ihu_rg"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154);  
COMMIT;  

CREATE INDEX "idx_26xxx_tampon_ihu_rg_geom"  
ON "26xxx_wold50m"."26xxx_tampon_ihu_rg"
USING gist (geom); 
COMMIT;  


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE 8                                                    ----
----                                  GESTION DU PARCELLAIRE BÂTI                                            ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
---- - Fusion des géométries des parcelles cadastrales avec les bâtiments qu’elles contiennent pour          ----
----   simplifier les relations spatiales.                                                                   ----
---- - Identification des parcelles contenant des bâtiments situés dans la zone de débroussaillement         ----
----   (200 m autour des massifs forestiers).                                                                ----
---- - Sélection des parcelles bâties concernées par les arbitrages géographiques via leur association       ----
----   avec les tampons corrigés.                                                                            ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_parcelle_batie" : Identification des parcelles intersectées par un bâtiment.

-- Description : Cette table **unit les géométries des parcelles cadastrales** avec celles des **bâtiments** 
--               qui y sont contenus. Elle permet d'établir une base unifiée pour l'analyse des relations spatiales 
--               entre **parcelles** et **bâtiments**.
-- 				 -> Attributs : **Numéro du compte communal** pour chaque parcelle et bâtiment, **numéro des
--                              parcelles cadastrales**, après fusion, **identifiant unique** de la parcelle, 
--                              **géométrie finale** des parcelles et bâtiments fusionnés (MultiPolygon, 2154).


DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_parcelle_batie";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_parcelle_batie" AS
SELECT p.comptecommunal AS comptecommunal,          -- Numéro du compte communal
	   p.geo_parcelle,                              -- Numéro de parcelles
	   p.idu,                                       -- Identifiant des parcelles
       ST_Union(p.geom) AS geom                     -- Fusion des géométries des parcelles
FROM "26xxx_wold50m"."26xxx_parcelle" p             -- Source : Parcelles cadastrales
INNER JOIN "26xxx_wold50m"."26xxx_bati200_cc_rg" b  -- Source : Bâtiments
ON ST_Intersects(p.geom,b.geom)                     -- Condition : le bâtiment est contenu dans la parcelle
WHERE p.comptecommunal=b.comptecommunal             -- Condition : quand compte communaux égaux
GROUP BY p.comptecommunal,p.geo_parcelle,p.idu;     -- Regrouper par compte communal
COMMIT;

CREATE INDEX idx_26xxx_parcelle_batie_geom 
ON "26xxx_wold50m"."26xxx_parcelle_batie"
USING gist (geom);  
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_parcelle_batie_u" : Regroupement et fusion des parcelles-bâties par compte 
-- communal dans la zone OLD.

-- Description : Cette table regroupe et fusionne les géométries des parcelles-bâties par le biais de l'attribut
--               compte communal dans la zone des 200m des massifs forestiers supérieurs à 0.5 ha. Ces géométries
--               sont converties en Multipolygon et rendues valides.
-- 				 -> Attributs : **Numéro du compte communal** associé à la parcelle contenant un bâtiment, 
--                              **identifiant unique** de la parcelle cadastrale, **géométrie de la parcelle 
--                              cadastrale** après fusion (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_parcelle_batie_u";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_parcelle_batie_u" AS
SELECT comptecommunal,                        -- Compte communal associé à la parcelle
       ST_Multi(                              -- Convertit en Multipolygon
	      ST_CollectionExtract(               -- Extrait seulement les type 3 : Polygon
			 ST_MakeValid(                    -- Corrige les géométries invalides
				ST_Union(geom)),              -- Regroupe et fusionne les géométries
	   3)) AS geom                            -- Géométrie résultante
FROM "26xxx_wold50m"."26xxx_parcelle_batie" -- Source : Parcelles et bâtiments fusionnés
GROUP BY comptecommunal;                      -- Regroupe uniquement par compte communal
COMMIT;

CREATE INDEX idx_26xxx_parcelle_batie_u_geom 
ON "26xxx_wold50m"."26xxx_parcelle_batie_u"
USING gist (geom); 
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

-- Création de la table "26xxx_parcelle_batie_ihu" : Parcelles bâties concernées par les arbitrages.

-- Description : Cette table identifie les **parcelles bâties** associées à des bâtiments situés dans la **zone 
--               "tampon_ihu"**. Les parcelles sélectionnées sont celles dont le **compte communal** figure dans 
--               la table **"tampon_ihu"**.
-- 				 -> Attributs : **numéro du compte communal** des parcelles bâties concernées par les arbitrages, 
--                              **identifiant de la parcelle cadastrale**, **identifiant unique** de la parcelle 
--                              cadastrale, **géométrie des parcelles bâties concernées** (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_parcelle_batie_ihu";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_parcelle_batie_ihu" AS
SELECT DISTINCT p.*                              -- Inclut toutes les colonnes des parcelles sans doublons
FROM "26xxx_wold50m"."26xxx_parcelle_batie_u" AS p -- Source : Parcelles contenant des bâtiments
JOIN "26xxx_wold50m"."26xxx_tampon_ihu" AS t     -- Source : Zones tampons corrigées pour les arbitrages
ON p.comptecommunal = t.comptecomm1;             -- Condition : Correspondance des comptes communaux
COMMIT;  

CREATE INDEX "idx_26xxx_parcelle_batie_ihu_geom" 
ON "26xxx_wold50m"."26xxx_parcelle_batie_ihu"
USING gist (geom); 
COMMIT; 



-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
----                                                                                                         ----
----                                             PARTIE 7                                                    ----
----                                  GESTION DES UNITÉS FONCIÈRES                                           ----
----                                                                                                         ----
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
----                                                                                                         ----
---- - Regroupement des parcelles contiguës appartenant au même propriétaire en une seule unité foncière par ----
----   compte communal.                                                                                      ----
---- - Fusion des unités foncières avec les parcelles cadastrales en cas d’intersection géométrique et       ----
----   correspondance du compte communal.                                                                    ----
---- - Création d’une table unifiée pour optimiser les recherches spatiales et simplifier les analyses       ----
----   foncières.                                                                                            ----
----                                                                                                         ----
----   Ce processus unifie les parcelles cadastrales et les unités foncières en des géométries consolidées   ----
----   par compte communal.                                                                                  ----
----                                                                                                         ----
-----------------------------------------------------------------------------------------------------------------
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_ufr" : Regroupement des unités foncières par compte communal.

-- Description : Les **unités foncières** représentent des regroupements de **parcelles cadastrales** 
--               appartenant à un même propriétaire. Cette table regroupe toutes les **unités foncières**
--               de la commune "26xxx" dans des géométries cohérentes, classées par **compte communal**. 
--               Chaque unité foncière est un **ensemble de parcelles contiguës** appartenant au même propriétaire.
-- 				 -> Attributs : **Zone foncière consolidée**, regroupant les **parcelles contiguës** d'un même
--                              propriétaire(MultiPolygon, 2154), **numéro du compte communal** associé à 
--                              l'unité foncière (identifie le propriétaire ou la commune).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ufr";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ufr" AS
SELECT uf.comptecommunal,              -- N° de compte communal associé aux unités foncières
	   ST_Multi(                       -- Convertit en MultiPolygon
          ST_CollectionExtract(        -- Extrait seulement les type 3 : Polygon
              ST_MakeValid(            -- Corrige les géométries invalides
	             ST_Union(uf.geom)),   -- Fusionne les géométries des unités foncières en une seule
	   3)) AS geom                     -- Géométrie résultante
FROM r_cadastre.geo_unite_fonciere uf  -- Source : unités foncières issues de la base cadastrale
WHERE LEFT(uf.comptecommunal,6) = '260xxx' -- Filtre : uniquement les unités foncières de la commune ayant le code INSEE '26xxx')  [**param**] 
GROUP BY uf.comptecommunal;            -- Regroupe les géométries par compte communal pour chaque propriétaire
COMMIT; 

ALTER TABLE "26xxx_wold50m"."26xxx_ufr"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154); 
COMMIT;  

CREATE INDEX "idx_26xxx_ufr_geom"  
ON "26xxx_wold50m"."26xxx_ufr"
USING gist (geom);  
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_ufr_bati" : Fusion des unités foncières et des parcelles cadastrales.

-- Description : Cette table combine les **unités foncières** (regroupements de parcelles d'un même propriétaire) 
--               avec les **parcelles cadastrales** correspondantes. Les géométries des unités foncières et des 
--               parcelles sont **fusionnées** en cas d'intersection et si elles appartiennent au même compte communal.
-- 				 -> Attributs : **zone foncière consolidée**, après **fusion des parcelles contiguës** 
--                              (MultiPolygon, 2154), **numéro du compte communal** associé à l'unité foncière
--                              (identifie le propriétaire ou la commune).


DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ufr_bati";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ufr_bati" AS
SELECT uf.comptecommunal,                             -- N° du compte communal des unités foncières
       ST_Multi(                                      -- Convertit en MultiPolygon
	      ST_MakeValid(                               -- Corrige les géométries invalides
	         ST_Intersection(uf.geom, pb.geom)        -- Prend uniquement la partie commune (intersection)
	   )) AS geom
FROM "26xxx_wold50m"."26xxx_ufr" AS uf                -- Source : Unités foncières
LEFT JOIN "26xxx_wold50m"."26xxx_parcelle_batie_u" pb  -- Source : Parcelles où est construit un bâtiment
ON  ST_Intersects(uf.geom, pb.geom)                   -- Condition spatiale : sélectionne uniquement les zones qui se croisent
WHERE uf.comptecommunal = pb.comptecommunal;          -- Filtre : comptes communaux identiques
COMMIT;


CREATE INDEX idx_26xxx_ufr_bati_geom 
ON "26xxx_wold50m"."26xxx_ufr_bati"
USING gist (geom);  
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE 9                                                    ----
----                      GÉNÉRATION ET TRAITEMENT DES ZONES DE VORONOI POUR L'ANALYSE                       ----
----                           DES PARCELLES ET BÂTIMENTS DANS LE CADRE DES OLD                              ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ---- 
---- Dans le cadre de l'application des Obligations Légales de Débroussaillement (OLD), ce segment de code   ---- 
---- vise à analyser les "superpositions sur la parcelle d'un tiers lui-même non tenu à une telle            ----
---- obligation, chacune des personnes concernées débroussaille les parties les plus proches des limites     ----
---- de parcelles abritant sa construction ou son installation."                                             ----
---- Le calcul des zones de Voronoi répond à ces critères. Il permet de diviser l'espace géographique        ----
---- en fonction des points interpolés (intersections, bâtiments, etc.), selon les comptes communaux.        ---- 
---- Les étapes suivantes sont réalisées :                                                                   ---- 
----                                                                                                         ---- 
----     - Transformation des points interpolés (MultiPoints) en points individuels                          ---- 
----     - Génération des polygones de Voronoi avec ces points                                               ---- 
----     - Identification du compte communal sur chaque polygone de Voronoi                                  ---- 
----     - Regroupement des polygones de Voronoi par compte communal                                         ---- 
----     - Optimisation des requêtes géospatiales                                                            ---- 
----                                                                                                         ---- 
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_pt_interpol" : Points interpolés tous les mètres sur le contour des parcelles 
---- bâties concernées par les arbitrages.

-- Description : Cette couche génère des **points** tous les mètres sur le **contour extérieur** des **parcelles 
--               bâties** identifiées dans **"26xxx_parcelle_batie_ihu"**. Ces points permettent d'introduire la 
--               fonction des polygones de voronoï
-- 				 -> Attributs : **Numéro du compte communal** des parcelles concernées par l'interpolation, 
--                              **Points interpolés** tous les mètres sur le contour des parcelles bâties 
--                              (MultiPoint, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_pt_interpol";
COMMIT;

-- CREATE TABLE "26xxx_wold50m"."26xxx_pt_interpol" AS
-- WITH dumped_parcelles AS (
--     -- Extraire les géométries individuelles des parcelles multi-polygones
--     SELECT p.comptecommunal,                          -- Compte communal des parcelles-bâties
--            (ST_Dump(p.geom)).geom AS dumped_geom      -- Décompose les géométries multi-polygones en polygones individuels

--     FROM "26011_wold50m"."26011_parcelle_batie_ihu" p -- Source : Parcelles-bâties concernées par les arbitrages
-- )
-- SELECT comptecommunal,                                -- Conserve le compte communal de chaque parcelle
--        ST_LineInterpolatePoints(
--            ST_ExteriorRing(dumped_geom),              -- Extrait le contour extérieur de chaque polygone
--            1/ ST_Length(ST_ExteriorRing(dumped_geom)) -- Calcule des points régulièrement espacés (1 mètre) le long du contour  [**param**] 
--        ) AS geom                                      -- Géométrie résultante
-- FROM dumped_parcelles                                 -- Source : Table résultante du traitement sur ls parcelles-bâties arbitrées
-- WHERE ST_Length(ST_ExteriorRing(dumped_geom)) > 1;    -- Filtre : ne conserve que les contours supérieurs à 1m  [**param**] 
-- COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_pt_interpol" AS
WITH dumped_parcelles AS (
    -- Extraire les géométries individuelles des parcelles éventuellement multi-parties et/ou avec anneaux intérieurs 
    SELECT p.comptecommunal,                          -- Compte communal des parcelles bâties
           (ST_DumpRings(                             -- Décompose les géométries polygones avec anneaux intérieurs en autant de polygones individuels
		   	(ST_Dump(p.geom)).geom                    -- Décompose les géométries multi-parties en polygones individuels
			   )).geom AS dumped_geom     
    FROM "26xxx_wold50m"."26xxx_parcelle_batie_ihu" p -- Source : Parcelles-bâties concernées par les arbitrages
)
SELECT comptecommunal,                                -- Conserve le compte communal de chaque parcelle
       ST_LineInterpolatePoints(
           ST_ExteriorRing(dumped_geom),              -- Extrait le contour extérieur de chaque polygone
           1/ ST_Length(ST_ExteriorRing(dumped_geom)) -- Calcule des points régulièrement espacés (1 mètre) le long du contour  [**param**] 
       ) AS geom                                      -- Géométrie résultante
FROM dumped_parcelles                                 -- Source : Table résultante du traitement sur ls parcelles-bâties arbitrées
WHERE ST_Length(ST_ExteriorRing(dumped_geom)) > 1;    -- Filtre : ne conserve que les contours supérieurs à 1m  [**param**] 
COMMIT;
ALTER TABLE "26xxx_wold50m"."26xxx_pt_interpol"
ALTER COLUMN geom TYPE geometry(MultiPoint, 2154) 
USING ST_SetSRID(geom, 2154); 
COMMIT;


ALTER TABLE "26xxx_wold50m"."26xxx_pt_interpol"
ALTER COLUMN geom TYPE geometry(MultiPoint, 2154) 
USING ST_SetSRID(geom, 2154); 
COMMIT;

CREATE INDEX "idx_26xxx_pt_interpol_geom"  
ON "26xxx_wold50m"."26xxx_pt_interpol"
USING gist (geom);  
COMMIT; 


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_pt_interpol_rg" : Transformation des points interpolés en points individuels.

-- Description : Cette table extrait les **points individuels** à partir des **MultiPoints** résultant des 
--               points interpolés. Elle permet de fournir une **représentation éclatée** des points pour 
--               introduire la fonction ST_VoronoiPolygons.
-- 				 -> Attributs : **numéro du compte communal** des parcelles concernées par l’interpolation 
--               des points le long de leur contour, géométrie des **points individuels** extraits des **MultiPoints** (Point, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_pt_interpol_rg";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_pt_interpol_rg" AS
SELECT p.comptecommunal,                    -- N° de compte communal
       (ST_Dump(p.geom)).geom AS geom       -- Éclate les MultiPoints en points individuels
FROM "26xxx_wold50m"."26xxx_pt_interpol" p; -- Source : Points interpolés générés le long des contours
COMMIT; 

ALTER TABLE "26xxx_wold50m"."26xxx_pt_interpol_rg"
ALTER COLUMN geom TYPE geometry(Point, 2154) 
USING ST_SetSRID(geom, 2154); 
COMMIT;

CREATE INDEX idx_26xxx_pt_interpol_rg_geom 
ON "26xxx_wold50m"."26xxx_pt_interpol_rg"
USING gist (geom);  
COMMIT; 


--*-----------------------------------------------------------------------------------------------------------*--

-- Création de la couche "26xxx_voronoi" : Calcul des polygones de Voronoi pour la couche de points interpolés.

-- Description : Calcul des **polygones de Voronoi** à partir des **points interpolés** générés à partir des 
--               **contours des parcelles bâties**. Les **polygones de Voronoi** sont utilisés pour diviser 
--               l'espace autour des points en régions d'influence.
-- 				 -> Attributs : géométrie des **Polygones de Voronoi** générés à partir des points interpolés 
--                              (Polygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_voronoi";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_voronoi" AS
SELECT (ST_DUMP(                               -- Décompose les polygones de Voronoi en entités géométriques individuelles
	       ST_VoronoiPolygons(                 -- Génère et extrait les polygones de Voronoi
			  ST_Collect(p.geom)))             -- Regroupe tous les points en une seule collection
	   ).geom AS geom                          -- Géométrie résultante
FROM "26xxx_wold50m"."26xxx_pt_interpol_rg" p; -- Source : points interpolés regroupés
COMMIT; 

ALTER TABLE "26xxx_wold50m"."26xxx_voronoi"
ALTER COLUMN geom TYPE geometry(Polygon, 2154) 
USING ST_SetSRID(geom, 2154); 
COMMIT; 

CREATE INDEX "idx_26xxx_voronoi_geom" 
ON "26xxx_wold50m"."26xxx_voronoi"
USING gist (geom); 
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la couche "26xxx_voronoi_cc" : Attribution des polygones de Voronoi aux comptes communaux.

-- Description : Cette table associe chaque **polygone de Voronoi** à un **compte communal** en utilisant une 
--               relation spatiale (**ST_Within**) avec les **points interpolés**. Les polygones de Voronoi, 
--               calculés à partir des **points interpolés** sur les **contours des parcelles**, permettent 
--               de délimiter des **zones d'influence** autour des points en fonction de leur proximité.
--               Cette étape est essentielle pour :
--                     - Lier les **zones de Voronoi** à des **attributs cadastraux** ou **communaux**.
--                     - Identifier et étudier les **zones d'influence** des **parcelles** ou des **bâtiments**.
--                     - Préparer des **données géospatiales consolidées**.
-- 				 -> Attributs : **Numéro du compte communal** des **polygones de Voronoi**, géométries des 
--                              **polygones de Voronoi** associé à chaque **compte communal** (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_voronoi_cc";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_voronoi_cc" AS
SELECT p.comptecommunal,                      -- Associe le compte communal de chaque point
       ST_Multi(                              -- Convertit en Multipolygone
		  ST_CollectionExtract(               -- Extrait les géométrie de type 3 ('Polygone')
			 ST_MakeValid(v.geom),            -- Corrige la géométrie des polygones de Voronoi
	   3)) AS geom
FROM "26xxx_wold50m"."26xxx_voronoi" v        -- Source : Polygones de Voronoi
JOIN "26xxx_wold50m"."26xxx_pt_interpol_rg" p -- Source : Points interpolés avec comptes communaux
ON ST_Within(p.geom, v.geom);                 -- Condition : Le point doit être inclus dans le polygone de Voronoi
COMMIT; 

CREATE INDEX idx_26xxx_voronoi_cc_geom 
ON "26xxx_wold50m"."26xxx_voronoi_cc"
USING gist (geom);
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la couche "26xxx_voronoi_cc_rg" : Regroupement et correction géométrique des polygones de Voronoi 
---- par "comptecommunal".

-- Description : Cette table regroupe les **polygones de Voronoi** en une seule entité géométrique par 
--               **compte communal**, tout en corrigeant les éventuelles anomalies géométriques. Les opérations 
--               incluent :
--               - Correction des anomalies géométriques (**auto-intersections**, **chevauchements**).
--               - Fusion des géométries pour chaque **compte communal**.
--               - Conversion en **MultiPolygon**.
-- 				 -> Attributs : **Numéro du compte communal** auquel les polygones de Voronoi sont associés, 
--                              géométrie des **Polygone de Voronoi regroupé** pour chaque **compte communal** 
--                              (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_voronoi_cc_rg";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_voronoi_cc_rg" AS
SELECT vcc.comptecommunal,                   -- N° de compte communal
       ST_Multi(                             -- Convertit en MultiPolygon
           ST_CollectionExtract(             -- Extrait uniquement les polygones (type 3)
               ST_MakeValid(                 -- Corrige les géométries invalides
                   ST_Union(vcc.geom)),      -- Fusionne les géométries 
       3)) AS geom                           -- Géométrie finale regroupée
FROM "26xxx_wold50m"."26xxx_voronoi_cc" vcc  -- Source : polygones de Voronoi avec comptes communaux
GROUP BY vcc.comptecommunal;                 -- Regroupe par compte communal
COMMIT;

ALTER TABLE "26xxx_wold50m"."26xxx_voronoi_cc_rg"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154); 
COMMIT;

CREATE INDEX idx_26xxx_voronoi_cc_rg_geom 
ON "26xxx_wold50m"."26xxx_voronoi_cc_rg"
USING gist (geom);  
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE 10                                                   ----
----                           ARBITRAGE DES RESPONSABILITES OLD PAR PROPRIETAIRE                            ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*-- 
----                                                                                                         ----
---- - Préparation des tables nécessaires aux calculs géométriques et aux arbitrages des zones à             ----
----   débroussailler.                                                                                       ----
---- - Création des couches géographiques représentant les zones d'intersection, les unités foncières, et    ----
----   les polygones spécifiques aux propriétaires ou aux zones urbaines.                                    ----
---- - Fusion et découpage des géométries pour regrouper les zones en fonction des limites cadastrales et    ----
----   des zones urbaines.                                                                                   ----
---- - Normalisation des géométries pour garantir leur compatibilité avec le système de projection EPSG:2154.----
---- - Identification des zones de superposition entre plusieurs propriétés ou acteurs.                      ----
---- - Arbitrage des zones à débroussailler pour les attribuer à des propriétaires spécifiques.              ----
---- - Suppression des géométries invalides ou nulles pour assurer la qualité des données.                   ----
---- - Fusion et agrégation des zones nettoyées pour produire des couches finales prêtes à l'analyse et      ----
----   à la visualisation.                                                                                   ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

-- Traitements de la boucle 1 sans fonction ni itération

-----------------------------
-- Sélection et union des zones de superposition en dehors de la zone urbaine pour le chaque compte communal du propriétaire 1.
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t1";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t1" AS
WITH
tampon_extract AS (
	SELECT 
		t.comptecomm1,                       -- N° du compte communal du propriétaire 1
		t.comptecomm2,                           -- N° du compte communal du propriétaire 2
		ST_SetSRID(                              -- Définit le système de coordonnées EPSG:2154
			ST_Multi(                             -- Convertit les géométries en MultiPolygon
				ST_CollectionExtract(              -- Extrait les polygones de la collection 
					ST_MakeValid(t.geom),           -- Corrige les géométries invalides
					3)), 
			2154) AS geom                            -- Géométrie résultante
	FROM "26xxx_wold50m"."26xxx_tampon_ihu" t   -- Source : zones de superposition
)
SELECT
	te.comptecomm1,                           -- N° du compte communal du propriétaire 1
	te.comptecomm2,                           -- N° du compte communal du propriétaire 2
	te.geom
FROM tampon_extract te
WHERE ST_GeometryType(te.geom)                   -- Vérifie que la géométrie est de type **Polygon** ou **MultiPolygon**
	IN ('ST_MultiPolygon', 'ST_Polygon');        -- Condition : géométrie est soit un **MultiPolygon** soit un **Polygon**
COMMIT; 
				
DELETE FROM "26xxx_wold50m"."26xxx_b1_t1"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t1_geom" 
ON "26xxx_wold50m"."26xxx_b1_t1"
USING gist (geom);
COMMIT;

-- Union des géométries des zones de superposition en dehors de la zone urbaine pour chaque compte communal.
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t2";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t2" AS
SELECT 
	b1.comptecomm1,                           -- N° de compte communal principal
	ST_SetSRID(                               -- Définit le système de coordonnées EPSG:2154
		ST_Multi(                               -- Convertit les géométries en MultiPolygon
			ST_CollectionExtract(                 -- Extrait les polygones de la collection 
				ST_MakeValid(
					ST_Union(                         -- Fusionne toutes les géométries en une seule entité géométrique
						ST_MakeValid(b1.geom))),        -- Corrige les géométries invalides
				3)),
		2154) AS geom                             -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t1" b1            -- Source : superpositions par compte communal
GROUP BY b1.comptecomm1;                         -- Regroupe les géométries par compte 
COMMIT; 
				
DELETE FROM "26xxx_wold50m"."26xxx_b1_t2"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t2_geom" 
ON "26xxx_wold50m"."26xxx_b1_t2"
USING gist (geom);
COMMIT;

-----------------------------
-- Calcul de la zone à 50 mètres autour des bâtiments de chaque propriétaire en dehors de la zone U du PLU.
-- cela comprend des zones avec ou sans superposition

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t3";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t3" AS
SELECT 
	bt50.comptecommunal,                              -- N° du compte communal du bâtiment 
	  ST_SetSRID(                                     -- Définit le système de coordonnées EPSG:2154
		ST_Multi(                                     -- Convertit en MultiPolygon
		  ST_MakeValid(                               -- Corrige les géométries invalides
			ST_Union(                                 -- Fusionne pour éviter les petits polygones isolés
			  ST_MakeValid(                           -- Corrige les géométries invalides
				ST_CollectionExtract(
				  ST_Difference(                      -- Calcule la différence géométrique entre le tampon et la zone U
					ST_MakeValid(bt50.geom),          -- Corrige les géométries invalides
					ST_MakeValid(z_corr7.geom)),
				  3))))),
		2154) AS geom                                 -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_bati_tampon50" AS bt50,   -- Source : zones tampons de 50m autour des bâtiments
	 "26xxx_wold50m"."26xxx_zonage_corr7" AS z_corr7  -- Source : zones urbaines corrigées du PLU
GROUP BY bt50.comptecommunal;	
COMMIT; 
				
DELETE FROM "26xxx_wold50m"."26xxx_b1_t3"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 
				
CREATE INDEX "idx_26xxx_b1_t3_geom" 
ON "26xxx_wold50m"."26xxx_b1_t3"
USING gist (geom);
COMMIT;
			   
-----------------------------
-- Sélection des zones de superposition qui appartiennent à un voisin tenu de les débroussailler.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t5";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t5" AS
SELECT 
	t.comptecomm1,                                -- N° du compte communal principal
	t.comptecomm2,                                -- N° du compte communal voisin 
	ST_SetSRID(                                   -- Définit le système de coordonnées EPSG:2154
		ST_Multi(                                 -- Convertit en MultiPolygon
			ST_CollectionExtract(                 -- Extrait uniquement les géométries de type 3 (Polygone)
				ST_MakeValid(                     -- Corrige les géométries invalides
					ST_Intersection(              -- Intersection entre les tampons et unités foncières
						ST_MakeValid(t.geom),
						ST_MakeValid(u.geom))), 
				3)),
		2154) AS geom                             -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_tampon_ihu" t,        -- Source : zone de superposition autour des bâtis
	 "26xxx_wold50m"."26xxx_ufr" u                -- Source : unités foncières 
WHERE u.comptecommunal = t.comptecomm2            -- Filtre : cc des unités foncières identiques au cc voisin
AND ST_Intersects(t.geom, u.geom);                -- Filtre : géométries des deux tables qui s'intersectent
								
DELETE FROM "26xxx_wold50m"."26xxx_b1_t5"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom); 
COMMIT; 
				
CREATE INDEX idx_26xxx_b1_t5_geom 
ON "26xxx_wold50m"."26xxx_b1_t5"
USING gist (geom);
COMMIT;
				
-----------------------------
-- Regroupement des zones de superposition à débroussailler par chaque voisin.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t6";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t6" AS
SELECT 
	b5.comptecomm1 AS comptecommunal,        -- N° du compte communal principal
	ST_SetSRID(                              -- Définit le système de coordonnées EPSG:2154
		ST_Multi(                            -- Convertit en MultiPolygon
			ST_CollectionExtract(            -- Extrait uniquement les géométries de type 3 (Polygone)
				ST_MakeValid(                -- Corrige les géométries invalides
					ST_Union(b5.geom)),      -- Regroupe les géométries en une seule entité
				3)),
		2154) AS geom                        -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t5" b5        -- Source : zones qui appartiennent à un voisin tenu de les débroussailler
GROUP BY b5.comptecomm1;                     -- Regroupe par compte communal
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_b1_t6"
WHERE geom IS NULL 
OR ST_IsEmpty(geom)  
OR NOT ST_IsValid(geom); 
COMMIT; 
				
CREATE INDEX "idx_26xxx_b1_t6_geom" 
ON "26xxx_wold50m"."26xxx_b1_t6"
USING gist (geom);
COMMIT;
				
-----------------------------
-- Intersection entre les 50 m hors zone U appartenant au propriétaire 1 et son unité foncière regroupée.
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t8";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t8" AS
SELECT
	b3.comptecommunal,                       -- N° du compte communal du propriétaire 1 
	ST_SetSRID(                              -- Définit le système de coordonnées EPSG:2154
	  ST_Multi(                              -- Convertit en MultiPolygon
		ST_CollectionExtract(                -- Extrait uniquement les géométries de type 3 (Polygone)
		  ST_MakeValid(                      -- Corrige les géométries invalides
			ST_Intersection(                 -- Intersection des géométries
			  ST_MakeValid(b3.geom),
			  ST_MakeValid(u.geom))),
		  3)),
	  2154) AS geom                          -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t3" b3        -- Source : zones tampons de 50 mètres autour des bâtiments hzu
JOIN "26xxx_wold50m"."26xxx_ufr" u           -- Source : unités foncières
ON u.comptecommunal = b3.comptecommunal      -- Filtre : uniquement les géométries qui se croisent
WHERE ST_Intersects(b3.geom, u.geom);        -- Filtre : uniquement les géométries qui se croisent
COMMIT; 
				
DELETE FROM "26xxx_wold50m"."26xxx_b1_t8"
WHERE geom IS NULL
OR ST_IsEmpty(geom)
OR NOT ST_IsValid(geom);
COMMIT; 
 
CREATE INDEX idx_26xxx_b1_t8_geom 
ON "26xxx_wold50m"."26xxx_b1_t8"
USING gist (geom);
COMMIT;

-----------------------------
-- Regroupement des zones de superposition appartenant au propriétaire 1 par compte communal.
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t9";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t9" AS
SELECT
	b8.comptecommunal,                       -- N° de compte communal du propriétaire 1
		ST_SetSRID(                          -- Définit le système de coordonnées EPSG:2154
			ST_Multi(                        -- Convertit en MultiPolygon
				ST_CollectionExtract(        -- Extrait uniquement les géométries de type 3 (Polygone)
					ST_MakeValid(            -- Corrige les géométries invalides
						ST_Union(b8.geom)),  -- Regroupe les géométries en une seule entité
					3)),
		2154) AS geom                        -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t8" b8        -- Source : zones de superposition appartenant au propriétaire 1 avec cc
GROUP BY b8.comptecommunal;                  -- Regroupe par compte communal
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_b1_t9"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 
				
CREATE INDEX "idx_26xxx_b1_t9_geom" 
ON "26xxx_wold50m"."26xxx_b1_t9"
USING gist (geom);
COMMIT;

-----------------------------
-- Union des zones à débrousailler par le propriétaire 1 et par le voisin.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t11";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t11" AS
SELECT 
	COALESCE(b6.comptecommunal,b9.comptecommunal) AS comptecommunal,
	CASE 
	  -- 1er cas : les deux tables "26xxx_b1_t6" et "26xxx_b1_t9" existent
		WHEN b6.comptecommunal IS NOT NULL		  -- Filtre : Vérifie l'existence
		AND b9.comptecommunal IS NOT NULL         -- Filtre : Vérifie l'existence
		THEN
			ST_SetSRID(                           -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                           -- Convertit en MultiPolygon
				ST_CollectionExtract(             -- Extrait uniquement les géométries de type 3 (Polygone)
				  ST_MakeValid(                   -- Corrige les géométries invalides
					ST_Union(                     -- Fusionne les géométries des deux couches
					  ST_MakeValid(b6.geom),      -- Corrige les géométries invalides
					  ST_MakeValid(b9.geom))),    -- Corrige les géométries invalides
				  3)),
			  2154)
				
	  -- 2e cas : seule la table "26xxx_b1_t6" existe
		WHEN b6.comptecommunal IS NOT NULL		  -- Filtre : Vérifie l'existence
		THEN b6.geom
				
  -- 3e cas : seule la table "26xxx_b1_t9" existe
		WHEN b9.comptecommunal IS NOT NULL        -- Filtre : Vérifie l'existence
		THEN b9.geom  
		END AS geom                               -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t9" b9        	  -- Source : zones à débroussailler par le propriétaire 1
FULL OUTER JOIN "26xxx_wold50m"."26xxx_b1_t6" b6  -- Source : zones à débroussailler par le voisin
ON b6.comptecommunal = b9.comptecommunal;
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_b1_t11" 
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 

CREATE INDEX idx_26xxx_b1_t11_geom 
ON "26xxx_wold50m"."26xxx_b1_t11"
USING gist (geom);
COMMIT;     

-----------------------------
-- Soustraction des zones de superposition ayant les deux communaux par les zones à débroussailler 
-- par le propriétaire 1 : zones de superposition à débroussailler également par un autre propriétaire.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t13";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t13" AS
SELECT
	b1.comptecomm1,                                 -- N° du compte communal 1
	b1.comptecomm2,                                 -- N° du compte communal 2
	CASE 
	-- 1er cas : des données existent dans la table "26xxx_b1_t11"
		WHEN b11.comptecommunal IS NOT NULL         -- Filtre : Vérifie l'existence
		THEN
			ST_SetSRID(                             -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                             -- Convertit en MultiPolygon
				ST_MakeValid(                       -- Corrige les géométries invalides
				  ST_Union(
					 ST_MakeValid(                  -- Corrige les géométries invalides
						ST_CollectionExtract(
						  ST_Difference(            -- Calcule la différence géométrique entre les zones de superposition et les zones à débroussailler par le propriétaire 1
							ST_MakeValid(b1.geom),  -- Corrige les géométries invalides
							ST_MakeValid(b11.geom)),
						  3))))),
			  2154)                      

	-- 2e cas : aucune donnée dans la table "26xxx_b1_t11"
		ELSE b1.geom
		END AS geom                                 -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t1" b1               -- Source : zones de superposition
FULL OUTER JOIN "26xxx_wold50m"."26xxx_b1_t11" b11
ON b1.comptecomm1 = b11.comptecommunal
GROUP BY b1.comptecomm1, b1.comptecomm2, b11.comptecommunal, b1.geom, b11.geom;
COMMIT; 
				
DELETE FROM "26xxx_wold50m"."26xxx_b1_t13" 
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t13_geom"  
ON "26xxx_wold50m"."26xxx_b1_t13"
USING gist (geom);  
COMMIT; 

-----------------------------
-- Nettoyage de la couche 26xxx_b1_t13
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t14";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t14" AS
WITH
	-- 1) Épuration des épines externes 
	--	 aller retour avec 3 noeuds disctincts alignés
	--   supprime le noeud de l'extrémité 
epine_externe AS (
    SELECT
	b13.comptecomm1,                           -- N° du compte communal 1
	b13.comptecomm2,                               -- N° du compte communal 2
	ST_SetSRID(                                    -- Définit le système de coordonnées EPSG:2154
	  ST_Multi(                                   -- Convertit en MultiPolygon
		 ST_CollectionExtract(                     -- Extrait uniquement les géométries de type 3
			ST_MakeValid(
			  ST_Snap(                              -- Aligne le tampon de la géométrie sur la géométrie d'origine
				ST_RemoveRepeatedPoints(
				  ST_Buffer(
					b13.geom, 
					-0.0001,                        -- Ajout d'un tampon négatif de l'ordre de 10 nm
					'join=mitre mitre_limit=5.0'),  -- 
				  0.0003),			              -- Suppression des noeuds consécutifs proches de plus de 30 nm
				b13.geom,
				0.0006)),3)),                       -- Avec une distance d'accrochage de l'ordre de 60 nm
	  2154) AS geom                               -- Géométries résultantes
	FROM "26xxx_wold50m"."26xxx_b1_t13" b13           -- Source : 
),
	-- 2) Épuration des épines internes
epine_interne AS (
	SELECT
	epext.comptecomm1,                            -- N° du compte communal 1
	epext.comptecomm2,                            -- N° du compte communal 2
	ST_SetSRID(                                   -- Définit le système de coordonnées EPSG:2154
	  ST_Multi(                                   -- Convertit en MultiPolygon
		ST_CollectionExtract(                     -- Extrait uniquement les géométries de type 3
		 ST_MakeValid(
			ST_Snap(                              -- Aligne le tampon de la géométrie sur la géométrie d'origine
			  ST_RemoveRepeatedPoints(
				ST_Buffer(
				  epext.geom, 
				  0.0001,                         -- Ajout d'un tampon positif de l'ordre de 10 nm [**param**]
				  'join=mitre mitre_limit=5.0'),  -- 
				0.0003),			              -- Suppression des noeuds consécutifs proches de plus de 30 nm
			  b13.geom,
			  0.0006)),3)),                       -- Avec une distance d'accrochage de l'ordre de 60 nm
	  2154) AS geom                               -- Géométries résultantes
	FROM epine_externe epext                          -- Source : Zones à débroussailler hors et dans la zone urbaine régroupées par compte communal et corrigées sans épines extérieures
	JOIN "26xxx_wold50m"."26xxx_b1_t13" b13
	ON epext.comptecomm1 = b13.comptecomm1
	AND epext.comptecomm2 = b13.comptecomm2
)
	-- 3) Résultat final : on convertit la géométrie en MultiPolygon valide
SELECT
	epint.comptecomm1,                             -- N° du compte communal 1
	epint.comptecomm2,                             -- N° du compte communal 2
	ST_SetSRID(                                    -- Définit le système de coordonnées EPSG:2154
		ST_Multi(                                  -- Convertit en MultiPolygon
			ST_CollectionExtract(                  -- Extrait uniquement les géométries de type 3
			    ST_MakeValid(epint.geom),          -- Corrige les géométries invalides                                    
				3)),
		2154) AS geom                              -- Géométries résultantes
FROM epine_interne epint                           -- Source : Zones à débroussailler hors et dans la zone urbaine régroupées par compte communal et corrigées sans épines extérieures ni intérieures
WHERE (ST_MakeValid(epint.geom) IS NOT NULL  
AND ST_IsEmpty(ST_MakeValid(epint.geom)) = false
AND ST_IsValid(ST_MakeValid(epint.geom)) = true);
COMMIT; 
	
DELETE FROM "26xxx_wold50m"."26xxx_b1_t14" 
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

CREATE INDEX "idx_26xxx_b1_t14_geom"  
ON "26xxx_wold50m"."26xxx_b1_t14"
USING gist (geom);  
COMMIT; 

-----------------------------
-- Regroupement des zones de superposition à débroussailler également par un autre propriétaire corrigées.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t15";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t15" AS
SELECT
	b14.comptecomm1,                     -- N° du compte communal
	ST_SetSRID(                          -- Définit le système de coordonnées EPSG:2154
		ST_Multi(                        -- Convertit en MultiPolygon
			ST_CollectionExtract(        -- Extrait uniquement les géométries de type 3 
				ST_MakeValid(            -- Corrige les géométries invalides
					ST_Union(b14.geom)), -- Fusionne les géométries en une seule
				3)),
		2154) AS geom                    -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t14" b14  -- Source : zones de superposition à débroussailler par un autre propriétaire
GROUP BY b14.comptecomm1;                -- Regroupe par compte communal
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_b1_t15" 
WHERE geom IS NULL  
OR ST_IsEmpty(geom)  
OR NOT ST_IsValid(geom);

CREATE INDEX "idx_26xxx_b1_t15_geom"  
ON "26xxx_wold50m"."26xxx_b1_t15"
USING gist (geom);  
COMMIT; 
			
-----------------------------
-- Découpe des zones de superposition d’obligation à débroussailler par le propriétaire 1 hors zone urbaine.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t16";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t16" AS
SELECT
	b3.comptecommunal AS comptecomm1,                -- N° du compte communal principal
	CASE 
	-- Si aucune superposition n'est trouvée, conserver la géométrie d'origine
		WHEN b2.comptecomm1 IS NULL                  -- Condition : N° de compte communal principal null
		THEN b3.geom
		-- Sinon, la différence géométrique est calculée pour retirer les surfaces en superposition
		ELSE
			ST_SetSRID(                              -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                              -- Convertit en MultiPolygon								
				 ST_MakeValid(                       -- Corrige les géométries invalides
					ST_Union(
					  ST_MakeValid(                  -- Corrige les géométries invalides
						ST_CollectionExtract(
						  ST_Difference(             -- Calcule la différence géométrique entre le tampon et la zone U
							ST_MakeValid(b3.geom),   -- Corrige les géométries invalides
							ST_MakeValid(b2.geom)),
						  3))))),
			  2154)                                  -- Géométries résultantes
		END AS geom                                  -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t3" b3                -- Source : zones tampons de 50 mètres autour des bâtiments hzu
FULL OUTER JOIN "26xxx_wold50m"."26xxx_b1_t2" b2     -- Source : zones de superposition pour le compte communal du propriétaire 1
ON b2.comptecomm1 = b3.comptecommunal                -- Condition : Les comptes communaux doivent être égaux
GROUP BY b3.comptecommunal, b2.comptecomm1, b3.geom, b2.geom;
COMMIT; 
				
DELETE FROM "26xxx_wold50m"."26xxx_b1_t16" 
WHERE geom IS NULL  
OR ST_IsEmpty(geom)  
OR NOT ST_IsValid(geom);
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t16_geom"  
ON "26xxx_wold50m"."26xxx_b1_t16"
USING gist (geom);  
COMMIT; 

-----------------------------
-- Intersection entre les polygones de Voronoï et les zones de superposition également à 
-- débroussailler par un autre propriétaire : zones de superposition ayant plusieurs propriétaires
-- attribuées au propriétaire 1.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t18";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t18" AS
SELECT
	b14.comptecomm1,                           -- N° du compte communal principal
	ST_SetSRID(                                -- Définit le système de coordonnées EPSG:2154
	  ST_Multi(                                -- Convertit en MultiPolygon
		ST_CollectionExtract(                  -- Extrait uniquement les géométries de type 3
		  ST_MakeValid(                        -- Corrige les géométries invallides
			ST_Intersection(                   -- Calcule l'intersection des géométries
			  ST_MakeValid(b14.geom),
			  ST_MakeValid(v.geom))),
		  3)),
	  2154) AS geom                            -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t14" b14        -- Source : zones de superposition à débroussailler par un autre propriétaire
JOIN "26xxx_wold50m"."26xxx_voronoi_cc_rg" v   -- Source : polygones Voronoï regroupé par cc
ON v.comptecommunal = b14.comptecomm1          -- Condition : comptes communaux identiques
WHERE ST_Intersects(b14.geom, v.geom);         -- Condition : uniquement les géométries qui s'intersectent
COMMIT; 
				
DELETE FROM "26xxx_wold50m"."26xxx_b1_t18"  
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t18_geom"  
ON "26xxx_wold50m"."26xxx_b1_t18"
USING gist (geom);  
COMMIT; 

-----------------------------
-- Regroupement des zones de superposition corrigées ayant plusieurs propriétaires attribuées au propriétaire 1.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t20";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t20" AS
SELECT
	b18.comptecomm1 AS comptecommunal,   -- N° du compte communal principal
	ST_SetSRID(                          -- Définit le système de coordonnées EPSG:2154
	  ST_Multi(                          -- Convertit en MultiPolygon
		ST_CollectionExtract(            -- Extrait uniquement les géométries de type 3
		  ST_MakeValid(                  -- Corrige les géométries invalides
			ST_Union(                    -- Fusionne les géométries en une seule
			  ST_MakeValid(b18.geom))),  -- Corrige les géométries invalides
		  3)),
	  2154) AS geom                      -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t18" b18  -- Source : zones de Voronoi uniquement à débroussailler par le propriétaire 1 corrigées
GROUP BY b18.comptecomm1;                -- Regroupe par compte communal
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_b1_t20"  
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t20_geom"  
ON "26xxx_wold50m"."26xxx_b1_t20"
USING gist (geom);  
COMMIT; 

-----------------------------
-- Union des zones sans superpositions d’obligation à débroussailler par le propriétaire 1 et des 
-- zones de superposition regroupées appartenant au propriétaire 1 : zones sans et avec 
-- superpositions d'obligation à débroussailler par le propriétaire 1.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t21";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t21" AS
SELECT 
	COALESCE(b9.comptecommunal,b16.comptecomm1) AS comptecommunal,
	CASE 
	-- 1er cas : Si des données existent dans les deux tables "26xxx_b1_t9" et "26xxx_b1_t16"
		WHEN b9.comptecommunal IS NOT NULL      -- Filtre : Vérifie l'existence des résultats
		AND b16.comptecomm1 IS NOT NULL         -- Filtre : Vérifie l'existence des résultats
		THEN
			ST_SetSRID(                         -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                         -- Convertit en MultiPolygon
				ST_CollectionExtract(           -- Extrait uniquement les géométries de type 3
				  ST_MakeValid(                 -- Corrige les géométries invalides
					ST_Union(                   -- Fusionne les géométries
					  ST_MakeValid(b9.geom),    -- Corrige les géométries invalides
					  ST_MakeValid(b16.geom))), -- Corrige les géométries invalides
				  3)),
			  2154)
				
	-- 2e cas : Seule la table "26xxx_b1_t9" a des données
		WHEN b9.comptecommunal IS NOT NULL 
		THEN b9.geom                           -- Source : zones de superposition regroupées appartenant au propriétaire 1 
				
	-- 3e cas : Seule la table "26xxx_b1_t16" a des données
		WHEN b16.comptecomm1 IS NOT NULL  
		THEN b16.geom                          -- Source : zones sans superpositions d’obligation à débroussailler par le propriétaire 1
	-- Sinon résultat null
		ELSE NULL                              -- Aucun résultat valide
		END AS geom                            -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t9" b9               -- Source : zones de superposition regroupées appartenant au propriétaire 1 
FULL OUTER JOIN "26xxx_wold50m"."26xxx_b1_t16" b16  -- Source : zones sans superpositions d’obligation à débroussailler par le propriétaire 1
ON b9.comptecommunal = b16.comptecomm1;
COMMIT; 
				
DELETE FROM "26xxx_wold50m"."26xxx_b1_t21"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom); 
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t21_geom"  
ON "26xxx_wold50m"."26xxx_b1_t21"
USING gist (geom);  
COMMIT; 

-----------------------------
-- Union des zones de superposition corrigées, regroupées ayant plusieurs propriétaires  
-- attribuées aupropriétaire 1 et des zones sans et avec superpositions d'obligation 
-- corrigées à débroussailler par le propriétaire 1 : Zones finales à débroussailler par
-- le propriétaire 1 hors zone urbaine

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t23";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t23" AS
SELECT 
	COALESCE(b20.comptecommunal,b21.comptecommunal) AS comptecommunal,
	CASE 
	-- 1er cas : Les deux tables "26xxx_b1_t20" et "26xxx_b1_t21" existent
		WHEN b20.comptecommunal IS NOT NULL       -- Filtre : Vérifie l'existence des résultats
		AND b21.comptecommunal IS NOT NULL        -- Filtre : Vérifie l'existence des résultats
		THEN
			ST_SetSRID(                           -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                           -- Convertit en MultiPolygon
				ST_CollectionExtract(             -- Extrait uniquement les géométries de type 3
				  ST_MakeValid(                   -- Corrige les géométries invalides
					ST_Union(                     -- Fusionne les géométries entre elles
					  ST_MakeValid(b21.geom),     -- Corrige les géométries invalides
						ST_MakeValid(b20.geom))), -- Corrige les géométries invalides
				  3)),
			  2154)
				
	 -- 2e cas : Seule la table "26xxx_b1_t21" existe
		WHEN b21.comptecommunal IS NOT NULL          -- Filtre : Vérifie l'existence des résultats
		THEN b21.geom
					
	-- 3e cas : Seule la table "26xxx_b1_t20" existe
		WHEN b20.comptecommunal IS NOT NULL          -- Filtre : Vérifie l'existence des résultats
		THEN b20.geom
		END AS geom                                  -- Géométries résultantes 
FROM "26xxx_wold50m"."26xxx_b1_t20" b20              -- Source : zones de superposition corrigées ayant plusieurs propriétaires attribuées au propriétaire 1 regroupées
FULL OUTER JOIN "26xxx_wold50m"."26xxx_b1_t21" b21   -- Source : zones sans et avec superpositions d'obligation corrigées à débroussailler par le propriétaire 1
ON b20.comptecommunal = b21.comptecommunal;
COMMIT; 
			
DELETE FROM "26xxx_wold50m"."26xxx_b1_t23"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t23_geom"  
ON "26xxx_wold50m"."26xxx_b1_t23"
USING gist (geom);  
COMMIT; 

-----------------------------
-- Intersection des unités foncières regroupées et du zonage urbain : 
-- Parties d'unité foncière de chaque propriétaire en zone U, baties ou non baties

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t26";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t26" AS
SELECT
	ufr.comptecommunal,                            -- N° du compte communale à partir des unités foncières
	ST_SetSRID(                                    -- Définit le système de coordonnées EPSG:2154
	  ST_Multi(                                    -- Convertit en MultiPolygon
		ST_CollectionExtract(                      -- Extrait uniquement les géométries de type 3
		  ST_MakeValid(                            -- Corrige les géométries invalides
			ST_Intersection(					   -- Calcule l'intersection des géométries
			  ST_MakeValid(ufr.geom),
			  ST_MakeValid(z_corr7.geom))), 
		  3)),
	  2154) AS geom                                -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_ufr" ufr               -- Source : unités foncières
JOIN "26xxx_wold50m"."26xxx_zonage_corr7" z_corr7  -- Source : zonage urbain corrigé
ON ST_Intersects(ufr.geom, z_corr7.geom);          -- Filtre : uniquement les géométries dont l'intersection est une surface
COMMIT; 
			
DELETE FROM "26xxx_wold50m"."26xxx_b1_t26"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t26_geom"  
ON "26xxx_wold50m"."26xxx_b1_t26"
USING gist (geom);  
COMMIT; 

				
-----------------------------
-- Union entre les unités foncières du propriétaire 1 en zu et les zones de superposition à débroussailler 
-- par le même propriétaire : zones totales à débroussailler par le propriétaire 1 

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t28";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t28" AS
SELECT
	COALESCE(b26.comptecommunal, b23.comptecommunal) AS comptecommunal, -- Sélectionne l'un ou l'autre compte communal,
	CASE 
	-- Cas où les deux tables contiennent des données
		WHEN b26.comptecommunal IS NOT NULL 
		AND b23.comptecommunal IS NOT NULL 
		THEN
			ST_SetSRID(                              -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                              -- Convertit en MultiPolygon
				ST_CollectionExtract(                -- Extrait uniquement les géométries de type 3
				  ST_MakeValid(                      -- Corrige les géométries invalides
					ST_Union(                        -- Fusionne les géométries	
					  ST_MakeValid(b23.geom),        -- Corrige les géométries invalides
					  ST_MakeValid(b26.geom))),      -- Corrige les géométries invalides
				  3)),
			  2154) 
				
	-- Cas où seule la table "26xxx_b1_t26" contient des données
		WHEN b26.comptecommunal IS NOT NULL 
		THEN b26.geom
				
	-- Cas où seule la table "26xxx_b1_t23" contient des données
		WHEN b23.comptecommunal IS NOT NULL 
		THEN b23.geom
				
	-- Sinon résultat null
		ELSE NULL                                    -- Aucun résultat valide
		END AS geom                                  -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t26" b26              -- Source : unité foncière du propriétaire 1 en zone U
FULL OUTER JOIN "26xxx_wold50m"."26xxx_b1_t23" b23   -- Jointure complète externe avec les zones de superposition après arbitrage ayant des cc
ON b26.comptecommunal = b23.comptecommunal;          -- Condition : comptes communaux identiques
COMMIT; 
			
DELETE FROM "26xxx_wold50m"."26xxx_b1_t28"  
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom); 
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t28_geom"  
ON "26xxx_wold50m"."26xxx_b1_t28"
USING gist (geom);  
COMMIT; 
				
-----------------------------
-- Suppression des zones non cadastrées des zones totales à débroussailler par le propriétaire 1.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t29";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t29" AS
SELECT
	b28.comptecommunal,                              -- N° du compte communal
	CASE 
	-- Cas où la géométrie intersecte une zone non cadastrée, soustrait la zone non cadastrée
		WHEN ST_Intersects(b28.geom, nc.geom) 
	    THEN
			ST_SetSRID(                              -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                              -- Convertit en MultiPolygon
				ST_MakeValid(
				  ST_Union(
					ST_CollectionExtract(            -- Extrait uniquement les géométries de type 3
					  ST_MakeValid(
						ST_Difference(               -- Supprime la zone non cadastrée
						  ST_MakeValid(b28.geom),    -- Corrige les géométries invalides
						  ST_MakeValid(nc.geom))),
					  3)))),
			  2154)                                 
	
	-- Cas où aucune intersection n'existe, garde la géométrie d'origine
	    ELSE b28.geom
		END AS geom                                  -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t28" b28              -- Source : zones totales à débroussailler par le propriétaire 1 
LEFT JOIN "26xxx_wold50m"."26xxx_non_cadastre" nc    -- Source : zones non cadastrées
ON ST_Intersects(b28.geom, nc.geom)                  -- Condition : intersection entre  les zones non cadastrées
GROUP BY b28.comptecommunal, b28.geom, nc.geom;
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_b1_t29"  
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom); 
COMMIT;
				
CREATE INDEX "idx_26xxx_b1_t29_geom"  
ON "26xxx_wold50m"."26xxx_b1_t29"
USING gist (geom);  
COMMIT; 

-----------------------------
-- Correction des zones totales à débroussailler par le propriétaire 1 non cadastrées.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t30";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t30" AS
WITH
	-- 1) Épuration des épines externes 
	--	 aller retour avec 3 noeuds disctincts alignés
	--   supprime le noeud de l'extrémité 
epine_externe AS (
    SELECT
		b29.comptecommunal,                        -- N° de compte communal
		ST_SetSRID(                                -- Définit le système de coordonnées EPSG:2154
		  ST_Multi(                                -- Convertit en MultiPolygon
			ST_CollectionExtract(                  -- Extrait uniquement les géométries de type 3
			  ST_MakeValid(
				ST_Snap(                           -- Aligne le tampon de la géométrie sur la géométrie d'origine
				  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  b29.geom, 
					  -0.0001,                     -- Ajout d'un tampon négatif de l'ordre de 0,1 mm
					  'join=mitre mitre_limit=5.0'), 
					0.0003),			           -- Suppression des noeuds consécutifs proches de plus de 0,3 mm
				  b29.geom,
				   0.0006)),3)),                   -- Avec une distance d'accrochage de l'ordre de 0,6 mm
		  2154) AS geom                            -- Géométries résultantes
	FROM "26xxx_wold50m"."26xxx_b1_t29" b29            -- Source : 
),
	-- 2) Épuration des épines internes
epine_interne AS (
	SELECT
		epext.comptecommunal,                      -- N° de compte communal
		ST_SetSRID(                                -- Définit le système de coordonnées EPSG:2154
		  ST_Multi(                                -- Convertit en MultiPolygon
			ST_CollectionExtract(                  -- Extrait uniquement les géométries de type 3
			  ST_MakeValid(
				ST_Snap(                           -- Aligne le tampon de la géométrie sur la géométrie d'origine
				  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  epext.geom, 
					  0.0001,                      -- Ajout d'un tampon positif de l'ordre de 0,1 mm
					  'join=mitre mitre_limit=5.0'), 
					0.0003),			           -- Suppression des noeuds consécutifs proches de plus de 0,3 mm
				  b29.geom,
				  0.0006)),3)),                    -- Avec une distance d'accrochage de l'ordre de 0,6 mm
		  2154) AS geom                            -- Géométries résultantes
	FROM epine_externe epext                           -- Source : Zones à débroussailler hors et dans la zone urbaine régroupées par compte communal et corrigées sans épines extérieures
	JOIN "26xxx_wold50m"."26xxx_b1_t29" b29
	ON epext.comptecommunal = b29.comptecommunal
)
	-- 3) Résultat final : on convertit la géométrie en MultiPolygon valide
SELECT
	epint.comptecommunal,                          -- N° de compte communal
	ST_SetSRID(                                    -- Définit le système de coordonnées EPSG:2154
	  ST_Multi(                                    -- Convertit en MultiPolygon
		ST_CollectionExtract(                      -- Extrait uniquement les géométries de type 3
		  ST_MakeValid(epint.geom),                -- Corrige les géométries invalides                                    
		  3)),
	  2154) AS geom                                -- Géométries résultantes
FROM epine_interne epint                           -- Source : Zones à débroussailler hors et dans la zone urbaine régroupées par compte communal et corrigées sans épines extérieures ni intérieures
WHERE (ST_MakeValid(epint.geom) IS NOT NULL  
AND ST_IsEmpty(ST_MakeValid(epint.geom)) = false
AND ST_IsValid(ST_MakeValid(epint.geom)) = true);
COMMIT; 
	
DELETE FROM "26xxx_wold50m"."26xxx_b1_t30" 
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

CREATE INDEX "idx_26xxx_b1_t30_geom"  
ON "26xxx_wold50m"."26xxx_b1_t30"
USING gist (geom);  
COMMIT; 


DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_result1";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_result1" AS
SELECT 
	b30.comptecommunal,
	b30.geom
FROM "26xxx_wold50m"."26xxx_b1_t30" b30;
COMMIT;

CREATE INDEX idx_26xxx_result1_geom 
ON "26xxx_wold50m"."26xxx_result1"
USING gist (geom);
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_result1_rg" : Correction des zones bâties à débroussailler hors zone et 
---- dans la zone urbaine regroupées en une seule entité.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_result1_rg";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_result1_rg" AS
SELECT ST_SetSRID( 
		 ST_Multi(                        -- Convertit en MultiPolygon
	       ST_CollectionExtract(          -- Extrait uniquement les géométries de type 3
			 ST_MakeValid(                -- Corrige les géométries invalides
	           ST_Union(r1.geom)),        -- Unit les géométries pour former un MultiPolygon unique
		   3)),
		 2154) AS geom                    -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_result1" r1;  -- Source : zones bâties à débroussailler hors zone et dans la zone urbaine par cc
COMMIT; 

CREATE INDEX idx_26xxx_result1_rg_geom 
ON "26xxx_wold50m"."26xxx_result1_rg"
USING gist (geom); 
COMMIT; 


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE 12                                                   ----
----                         IDENTIFICATION ET TRAITEMENT DES TROUS INDIVIDUELS                              ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
---- - Découpe des zones tamponnées :                                                                        ----
----     - Identification des zones non arbitrées après soustraction des surfaces couvertes par des tampons. ----
----     - Relation avec le projet : Cette étape permet de compléter les arbitrages.                         ----
----                                                                                                         ----
---- - Soustraction des zones non cadastrées :                                                               ----
----    - Retrait des zones non cadastrées                                                                   ----
----    - Relation avec le projet : Assure qu'un propriétaire soit identifié                                 ----
----                                                                                                         ----
---- - Analyse des trous individuels :                                                                       ----
----    - Extraction des trous restants = zones non arbitrées par les calculs précédents.                    ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--


---- Création de la table "26xxx_trou1" : Découpe des géométries des zones à débroussailler corrigées et 
---- regroupées à partir des zones tampons hors zonage urbain pour obtenir les zones restantes **non 
---- couvertes** ou **exclues**.

-- Description : Cette table **stocke** les résultats de la soustraction géométrique entre les zones tampons 
--               définies dans **`26xxx_tampon_ihur`** et les zones à débroussailler définies dans 
--               **"26xxx_result1_rg**. Elle est utilisée pour **identifier** les zones restantes **non 
--               couvertes** ou **exclues** après l'opération de découpe.
-- 				 -> Attributs : **N° du compte communal**, **géométrie résultante** après découpe géométrique
--                              (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_trou1";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_trou1" AS
SELECT ST_SetSRID(
		 ST_Multi(                                          -- Convertit en MultiPolygon 
           ST_CollectionExtract(                            -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(
			   ST_Difference(                               -- Calcule la différence géométrique entre deux ensembles
                 ST_MakeValid(t_ihu_rg.geom),               -- Corrige les géométries invalides
                 ST_MakeValid(r1rg.geom))),
			3)),
		2154) AS geom                                       -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_tampon_ihu_rg" t_ihu_rg,        -- Source : zones tampons hors zonage urbain regroupées après découpe
     "26xxx_wold50m"."26xxx_result1_rg" r1rg;                -- Source : zones bâties à débroussailler hors zone et dans la zone urbaine unifiées et corrigées 
COMMIT;

CREATE INDEX idx_26xxx_trou1_geom
ON "26xxx_wold50m"."26xxx_trou1"
USING gist (geom); 
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_trou2" : Découpe des zones restantes **non couvertes** ou **exclues** par les 
---- zones non cadastrées pour obtenir des zones restantes **non couvertes** ou **exclues** non cadastrées.

-- Description : Cette table **soustrait** les **zones non cadastrées** (non_cadastre) des surfaces 
--               définies dans **trou_decoupe1**. Elle garantit également la **validité des géométries** 
--               et extrait uniquement les **polygones**. Cette étape permet de créer des zones précises, 
--               nettoyées et homogènes, prêtes pour des analyses géospatiales avancées.
-- 				 -> Attributs : **Géométrie** résultante de la soustraction des zones non cadastrées (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_trou2";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_trou2" AS
SELECT ST_SetSRID(
		 ST_Multi(                               -- Convertit en MultiPolygon 
           ST_CollectionExtract(                 -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                       -- Corrige les géométries invalides
               ST_Difference(t.geom, nc.geom)),  -- Soustrait les géométries non cadastrées
			 3)),
		2154) AS geom                            -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_trou1" t,            -- Source : zones restantes non couvertes
     "26xxx_wold50m"."26xxx_non_cadastre" nc;    -- Source : zones non cadastrées
COMMIT; 

CREATE INDEX idx_26xxx_trou2_geom
ON "26xxx_wold50m"."26xxx_trou2"
USING gist (geom); 
COMMIT; 


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_trou3" : Extraction des trous individuels et calcul de leur surface
-- Description : Cette table extrait les trous individuels des géométries et calcule leur surface. 
-- Objectif : Identifier et quantifier chaque trou individuel.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_trou3";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_trou3" AS
SELECT (ST_Dump(ST_Multi(t.geom))).path AS path,             -- Extrait le chemin des géométries décomposées de chaque trou
       ST_Area((ST_Dump(ST_Multi(t.geom))).geom) AS surface, -- Calcule la **surface** de chaque trou extrait
       (ST_Dump(ST_Multi(t.geom))).geom AS geom              -- Extrait les géométries des trous sous forme de polygone
FROM "26xxx_wold50m"."26xxx_trou2" t;                        -- Source : zones restantes non couvertes non cadastrées
COMMIT;

CREATE INDEX idx_26xxx_trou3_geom
ON "26xxx_wold50m"."26xxx_trou3"
USING gist (geom); 
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_trou4" : Correction des géométries de la couche "26xxx_trou3" 
-- Description : Correction des géométries de la couche trou3 avec la méthode des épines externes/internes
-- Objectif : Supprimer les artefacts qui ne disparaissent

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_trou4";

CREATE TABLE "26xxx_wold50m"."26xxx_trou4" AS
WITH
	-- 1) Épuration des épines externes 
	--	 aller retour avec 3 noeuds disctincts alignés
	--   supprime le noeud de l'extrémité 
epine_externe AS (
    SELECT
		tr3.path,                        -- path du trou3
		ST_SetSRID(                                -- Définit le système de coordonnées EPSG:2154
		  ST_Multi(                                -- Convertit en MultiPolygon
			ST_CollectionExtract(                  -- Extrait uniquement les géométries de type 3
			  ST_MakeValid(
				ST_Snap(                           -- Aligne le tampon de la géométrie sur la géométrie d'origine
				  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  tr3.geom, 
					  -0.0001,                     -- Ajout d'un tampon négatif de l'ordre de 0,1 mm
					  'join=mitre mitre_limit=5.0'), 
					0.0003),			           -- Suppression des noeuds consécutifs proches de plus de 0,3 mm
				  tr3.geom,
				   0.0006)),3)),                   -- Avec une distance d'accrochage de l'ordre de 0,6 mm
		  2154) AS geom                            -- Géométries résultantes
	FROM "26xxx_wold50m"."26xxx_trou3" tr3            -- Source : 
),
	-- 2) Épuration des épines internes
epine_interne AS (
	SELECT
		epext.path,                        -- path du trou3
		ST_SetSRID(                                -- Définit le système de coordonnées EPSG:2154
		  ST_Multi(                                -- Convertit en MultiPolygon
			ST_CollectionExtract(                  -- Extrait uniquement les géométries de type 3
			  ST_MakeValid(
				ST_Snap(                           -- Aligne le tampon de la géométrie sur la géométrie d'origine
				  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  epext.geom, 
					  0.0001,                      -- Ajout d'un tampon positif de l'ordre de 0,1 mm
					  'join=mitre mitre_limit=5.0'), 
					0.0003),			           -- Suppression des noeuds consécutifs proches de plus de 0,3 mm
				  tr3.geom,
				  0.0006)),3)),                    -- Avec une distance d'accrochage de l'ordre de 0,6 mm
		  2154) AS geom                            -- Géométries résultantes
	FROM epine_externe epext                           -- Source : Zones à débroussailler hors et dans la zone urbaine régroupées par compte communal et corrigées sans épines extérieures
	JOIN "26xxx_wold50m"."26xxx_trou3" tr3
	ON epext.path = tr3.path
)
	-- 3) Résultat final : on convertit la géométrie en MultiPolygon valide
SELECT
	epint.path,                        -- path du trou3
	ST_SetSRID(                                    -- Définit le système de coordonnées EPSG:2154
	  ST_Multi(                                    -- Convertit en MultiPolygon
		ST_CollectionExtract(                      -- Extrait uniquement les géométries de type 3
		  ST_MakeValid(epint.geom),                -- Corrige les géométries invalides                                    
		  3)),
	  2154) AS geom                                -- Géométries résultantes
FROM epine_interne epint                           -- Source : Zones à débroussailler hors et dans la zone urbaine régroupées par compte communal et corrigées sans épines extérieures ni intérieures
WHERE (ST_MakeValid(epint.geom) IS NOT NULL  
AND ST_IsEmpty(ST_MakeValid(epint.geom)) = false
AND ST_IsValid(ST_MakeValid(epint.geom)) = true);
COMMIT; 
	
DELETE FROM "26xxx_wold50m"."26xxx_trou4" 
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

CREATE INDEX "idx_26xxx_trou4_geom"  
ON "26xxx_wold50m"."26xxx_trou4"
USING gist (geom);  
COMMIT; 


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE 13                                                   ----
----                        CONSOLIDATION ET ANALYSES SPATIALES DES ÎLOTS GÉOMÉTRIQUES                       ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
---- - Création de la table ilot_du_trou_t1 pour décomposer les trous en ilots en fonction des tampons       ----
----   d'intersection présents dans le trou.                                                                 ----
----   Le propriétaire, dont le bâtiment est à plus de 50 mètres, mais qui a son polygone de voronoi sur     ----
----   la surface de ce trou ne sera plus retenu parmi les propriétaires entrant dans le calcul.             ----
---- - Consolidation des données uniques et validées dans ilot_du_trou_t2 en filtrant les doublons.          ----
---- - Génération des polygones des îlots dans ilot_du_trou_t3 à partir des bordures géométriques, grâce à   ----
----   la fonction ST_Polygonize.                                                                            ----
---- - Association des comptes communaux aux îlots générés dans ilot_du_trou_t4, en utilisant les relations  ----
----   entre îlots et tampons.                                                                               ----
---- - Résultat final des îlots dans la table "26xxx_ilots_final", intégrant les géométries et               ----
----   les comptes communaux associés.                                                                       ----
----                                                                                                         ----
----   Ces étapes permettent d'obtenir des îlots avec des comptes communaux filtrés pour l'arbitrage         ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "ilot_du_trou_t1" : Intersection entre les  zones de superpositions et les trous 
---- donnant les zones de superposition non couvertes par les traitements précédents.

-- Description : Cette table réalise l’**intersection** entre les **tampons** des géométries et les **trous 
--               individuels** pour obtenir une **découpe géométrique** précise. Elle permet de créer une 
--               **géométrie découpée** des zones non couvertes par la fonction I, tout en tenant compte des 
--               zones de superpositions.
-- 				 -> Attributs : **N° du premier compte communal**, **n° du deuxième compte communal**, 
--                              **géométries** après intersection des tampons et des trous (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_du_trou_t1";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_du_trou_t1" AS
SELECT t_ihu.comptecomm1,                       -- N° compte communal 1
       t_ihu.comptecomm2,                       -- N° compte communal 2
       ST_SetSRID(
		  ST_Multi(                             -- Convertit en MultiPolygon 
			 ST_MakeValid(
			    ST_CollectionExtract(             -- Extrait uniquement les polygones (type 3)
                   ST_Intersection(                -- Intersecte les trous avec les zones de superposition
                      ST_MakeValid(t_ihu.geom),     -- Corrige les géométries invalides
                      ST_MakeValid(tr4.geom)),      -- Corrige les géométries invalides 
			    3))),
		    2154) AS geom                        -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_tampon_ihu" t_ihu   -- Source : zones de superpositions
JOIN "26xxx_wold50m"."26xxx_trou4" tr4          -- Source : zones restantes non couvertes non cadastrées (trous individuels)
ON ST_Intersects(t_ihu.geom, tr4.geom);         -- Condition : intersection des géométries
-- AND tr4.path[1] = 1;                         -- Optionnel : filtre pour un trou spécifique
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_ilot_du_trou_t1" 
WHERE ST_IsEmpty(geom) 
AND geom IS NULL;  

CREATE INDEX idx_ilot_du_trou_t1_geom 
ON "26xxx_wold50m"."26xxx_ilot_du_trou_t1"
USING GIST (geom);
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "ilot_du_trou_t2" : Consolidation des zones de superposition non couvertes corrigées.

-- Description : Cette table **filtre les doublons** et conserve uniquement les **géométries uniques et valides** 
--               issues de `"ilot_du_trou_t1"`. L'objectif est d'éliminer les **répétitions** et les **géométries  
--               invalides** pour fournir une **base de données cohérente** pour les traitements spatiaux ultérieurs.
-- 				 -> Attributs : **Géométrie consolidée et validée** (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_du_trou_t2";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_du_trou_t2" AS
SELECT DISTINCT geom                     
FROM "26xxx_wold50m"."26xxx_ilot_du_trou_t1"   -- Source : 
WHERE geom IS NOT NULL;                        -- Filtre : Exclut les géométries nulles
COMMIT; 

CREATE INDEX idx_ilot_du_trou_t2_geom 
ON "26xxx_wold50m"."26xxx_ilot_du_trou_t2"
USING GIST (geom); 
COMMIT; 


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "ilot_du_trou_t3" : Reconstruction des polygones à partir des contours des zones de 
---- superposition non couvertes corrigées et consolidées (ilots de trous).

-- Description : Cette table **reconstruit les polygones** à partir des **contours des trous** extraits dans
--               `"ilot_du_trou_t2"`. Elle applique des opérations de **polygonisation** pour générer des
--               **entités spatiales valides**. L'objectif est de **convertir les limites des trous en 
--               nouvelles entités polygonales distinctes** pouvant être exploitées dans les traitements 
--               géométriques suivants.
-- 				 -> Attributs :  **Identifiant unique** pour chaque polygone reconstruit, **géométrie 
--                               reconstruite** après polygonisation (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_du_trou_t3";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_du_trou_t3" AS
WITH limites_ilots AS (
   SELECT ST_Multi(                              -- Convertit en MultiPolygon
             ST_Union(                           -- Fusionne les géométries en une seule entité
                ST_Boundary(                     -- Extrait les contours des trous sous forme de lignes
				   ST_CollectionExtract(         -- Extrait uniquement les polygones (type 3)
				      ST_MakeValid(geom),        -- Corrige les géométries invalides
		   3)))) AS geom                         -- Géométries résultantes
   FROM "26xxx_wold50m"."26xxx_ilot_du_trou_t2"  -- Source : zones de superposition non couvertes corrigées et consolidées
   WHERE ST_IsValid(geom)                        -- Filtre : exclut les géométries invalides
), 
polygones_ilots AS (
   SELECT ST_Dump(ST_Polygonize(geom)) AS dmp    -- Convertit les lignes en **polygones fermés**
   FROM limites_ilots                            -- Source : requête précédente
)
SELECT
	(dmp).path[1] AS id,                         -- **Identifiant unique** pour chaque polygone généré
    CASE
	-- Cas 1 : quand la géométrie est de type POLYGON
    WHEN GeometryType((dmp).geom) = 'POLYGON' 
	THEN ST_Multi((dmp).geom)                    -- Convertit en MultiPolygon

    -- Cas 2 : quand la géométrie est déjà de type MULTIPOLYGON   
	WHEN GeometryType((dmp).geom) = 'MULTIPOLYGON' 
	THEN (dmp).geom                              -- Reste inchangé

	-- Autres cas : pour les géométries autres que POLYGON et MULTIPOLYGON
    ELSE NULL                                    -- Renvoie null
    END AS geom                                  -- Géométries résultantes
FROM polygones_ilots                             -- Source : requête précédente
WHERE GeometryType((dmp).geom) 
IN ('POLYGON', 'MULTIPOLYGON');            -- Filtre : Garde uniquement les types attendus
COMMIT;

CREATE INDEX idx_ilot_du_trou_t3_geom 
ON "26xxx_wold50m"."26xxx_ilot_du_trou_t3" 
USING gist (geom); 
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_ilot_du_trou_t4" : Attribution des îlots de trous aux comptes communaux.

-- Description : Cette table **attribue** chaque îlot généré aux **comptes communaux concernés**, en fonction 
--               des zones tamponnées. Elle permet de lier chaque trou identifié à **un ou plusieurs comptes** 
--               pour une gestion précise des zones à traiter.
-- 				 -> Attributs : **Liste des comptes communaux** liés à chaque îlot, **géométrie des îlots** 
--                              (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_du_trou_t4";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_du_trou_t4" AS
SELECT
	ARRAY_AGG(DISTINCT t.comptecomm1			  -- Agrège les cc associés à chaque géométrie d'îlot
				ORDER BY t.comptecomm1) AS liste_ncc,
    CASE
	-- Cas 1 : quand la géométrie est de type POLYGON 
    WHEN GeometryType(t3.geom) = 'POLYGON' 
	THEN
		ST_Multi(                                 -- Convertit en MultiPolygon
		  ST_CollectionExtract(                   -- Extrait uniquement les polygones (type 3)
			ST_MakeValid(t3.geom),                -- Corrige les géométries invalides
			3))

	-- Cas 2 : quand la géométrie est déjà de type MULTIPOLYGON   
    WHEN GeometryType(t3.geom) = 'MULTIPOLYGON' 
	THEN
		ST_Multi(                                 -- Convertit en MultiPolygon
		  ST_CollectionExtract(                   -- Extrait uniquement les polygones (type 3)
			ST_MakeValid(t3.geom),                -- Corrige les géométries invalides
			3))

	-- Cas 3 : Autres cas : pour les géométries autres que POLYGON et MULTIPOLYGON
    ELSE NULL                                     -- Élimine les géométries non conformes
    END AS geom                                   -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_ilot_du_trou_t3" t3   -- Source : zones avec trous individuels
INNER JOIN "26xxx_wold50m"."26xxx_tampon_ihu" t   -- Source : zone de superpositions
ON ST_Within(ST_PointOnSurface(t3.geom), t.geom)  -- Joint si le **point sur la surface** du trou est dans la zone tampon
WHERE GeometryType(t3.geom) 
      IN ('POLYGON', 'MULTIPOLYGON')              -- Filtre : Garde uniquement les types attendus
GROUP BY t3.geom;                                 -- Regroupe par géométrie des trous
COMMIT;

CREATE INDEX idx_ilot_du_trou_t4_geom 
ON "26xxx_wold50m"."26xxx_ilot_du_trou_t4" 
USING gist (geom); 
COMMIT;

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_ilots_final" : Résultat final des zone de superpositions non couverte ayant 
---- plusieurs comptes communaux

-- Description : Cette table stocke les zones de superpositions non couverte ayant plusieurs comptes communaux.
--               Les comptes communaux étant inscrits dans une liste sous forme d'un tableau. 
-- 				 -> Attributs : Identifiant unique auto-incrémenté pour chaque îlot consolidé, **liste des 
--                              comptes communaux** associés à chaque îlot, **géométrie consolidée** des îlots,
--                              (MultiPolygon,EPSG:2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilots_final";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilots_final" (
    id SERIAL PRIMARY KEY,                         -- Identifiant auto-incrémenté
    liste_ncc TEXT[],                              -- Liste des comptes communaux sous forme de tableau
    geom geometry(MultiPolygon, 2154)              -- Géométrie en MultiPolygon avec SRID 2154
);
COMMIT;

INSERT INTO "26xxx_wold50m"."26xxx_ilots_final" (liste_ncc, geom)
SELECT
	it4.liste_ncc,                                -- Liste des comptes communaux associés à l'îlot
    ST_SetSRID(                                   -- Définit le système de coordonnées EPSG:2154
      ST_Multi(                                   -- Convertit en MultiPolygon
        ST_CollectionExtract(                     -- Extrait uniquement les géométries de type 3
          ST_ForceCollection(                     -- Force les géométrie (quelle qu'elle soit) à devenir des polygones ou multipolygon
            ST_MakeValid(                         -- Corrige les géométries invalides
			  ST_Union(it4.geom))),               -- Fusionne les géométries en une seule entité        
          3)),
      2154) AS geom                               -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_ilot_du_trou_t4" it4  -- Source : îlots de trous avec comptes communaux
GROUP BY it4.liste_ncc; 		                  -- Regroupe par liste de comptes communaux
COMMIT;

CREATE INDEX idx_26xxx_ilots_final_geom 
ON "26xxx_wold50m"."26xxx_ilots_final"
USING GIST (geom); 
COMMIT; 


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE 14                                                   ----
----                     		   TRAITEMENTS DES POLYGONES DE VORONOI                                      ----
----                                A L'INTERIEUR DES ILOTS DES TROUS                                        ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
---- - La fonction traite les polygones Voronoi basés sur les géométries des îlots                           ----
---- - Les polygones Voronoi sont générés à partir des géométries des points interpolés avec des             ----
----   identifiants uniques.                                                                                 ----
---- - Chaque polygone Voronoi est associé aux comptes communaux correspondants.                             ----
---- - Les géométries sont fusionnées, découpées et validées pour obtenir les résultats finaux.              ----
---- - Les polygones Voronoi finaux sont insérés dans une table résultat.                                    ----
---- - Les intersections entre les polygones Voronoi et les géométries des îlots permettent de connaître     ----
----   le propriétaire responsable du débroussaillement sur cette intersection.                              ----
----                                                                                                         ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--


---- Création de la table "26xxx_ilot_voronoi_t1" : Création des polygones Voronoi pour chaque zone de 
---- superpositions non couverte ayant plusieurs comptes communaux.

-- Description : Cette table génère et stocke les **polygones Voronoi** associés aux zones de **superpositions 
--               non couvertes** contenant **plusieurs comptes communaux**. Chaque polygone Voronoi représente 
--               une zone d’influence autour des points d’interpolation, permettant une segmentation précise du 
--               territoire.
-- 				 -> Attributs : **Identifiant unique** de chaque polygone Voronoi, **liste des comptes communaux**
--                              associés à chaque polygone Voronoi, **géométrie** des polygones Voronoi 
--                              (MultiPolygon, 2154).
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_voronoi_t1";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_voronoi_t1" AS
SELECT DISTINCT
    ilfi.id,                                          -- Récupère l’identifiant unique de l’entité "ilfi"
    ilfi.liste_ncc,                                   -- Récupère la liste des comptes communaux associés à l’entité
    ST_SetSRID(                                       -- Définit le système de coordonnées de sortie (ici Lambert-93, EPSG:2154)
      ST_Multi(                                       -- Force la géométrie de sortie en MultiPolygon, même si un seul polygone
        (ST_DUMP(                                     -- Décompose les géométries complexes en éléments individuels (ici pour Voronoï)
          ST_VoronoiPolygons(                         -- Génère les polygones de Voronoï à partir d’un ensemble de points
            ST_Collect(p.geom),                       -- Agrège toutes les géométries de la table/alias "p" en une seule géométrie
            0,                                        -- Tolérance = 0 → calcule des polygones Voronoï exacts sans simplification
            ST_Envelope(ilfi.geom)))                  -- Limite l’extension des polygones Voronoï à l’emprise de la géométrie "ilfi"
--          ilfi.geom))                               -- Variante commentée : limite à la géométrie exacte d’"ilfi" plutôt qu’à son enveloppe
        ).geom                                        -- Récupère la géométrie extraite par ST_DUMP
      )
    ,2154) AS geom                                    -- Applique le SRID et renomme le résultat en "geom"
FROM "26xxx_wold50m"."26xxx_pt_interpol_rg" p          -- Source : points interpolés regroupés
INNER JOIN "26xxx_wold50m"."26xxx_ilots_final" ilfi    -- Source : îlots de trous avec cc
ON p.comptecommunal = ANY(ilfi.liste_ncc)              -- Jointure externe sur les comptes communaux
WHERE p.geom IS NOT NULL                               -- Filtre : Exclut les géométries invalides
AND ST_Area(ilfi.geom) > 0                             -- Filtre : Exclut les géométries de surface strictement égale à 0
GROUP BY ilfi.id, ilfi.liste_ncc;                      -- Regroupe par liste de comptes communaux
COMMIT; 

CREATE INDEX idx_26xxx_ilot_voronoi_t1_geom
ON "26xxx_wold50m"."26xxx_ilot_voronoi_t1"
USING gist (geom);  
COMMIT; 


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_ilot_voronoi_t2" : Attribution des comptes communaux aux polygones Voronoi des 
---- trous.

-- Description : Cette table **associe les polygones Voronoi** générés dans `26xxx_ilot_voronoi_t1` aux **comptes 
--               communaux**. L'objectif est d'affecter **chaque polygone Voronoi** au bon **compte communal**,
--                en utilisant les **points interpolés** comme référence pour l'association.
-- 				 -> Attributs : **N° du compte communal** associé à chaque polygone Voronoi, **géométrie** des 
--                              polygones Voronoi (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_voronoi_t2";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_voronoi_t2" AS
SELECT DISTINCT 
	iv1.id,
	p.comptecommunal,                -- N° du compte communal
	ST_SetSRID(
	  ST_Multi(                      -- Convertit en MultiPolygon
		ST_CollectionExtract(        -- Extrait uniquement les polygones (type 3)
		  ST_MakeValid(iv1.geom),    -- Corrige les géométries invalides
		3)),
	2154) AS geom                    -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_ilot_voronoi_t1" iv1 -- Source : polygones de Voronoi pour chaque zone de superpositions non couverte ayant plusieurs comptes communaux
JOIN "26xxx_wold50m"."26xxx_pt_interpol_rg" p    -- Jointure avec la table des points interpolés
ON ST_Within(p.geom, iv1.geom)                   -- Filtre : points sont contenus dans les polygones de Voronoi
AND p.comptecommunal = ANY(iv1.liste_ncc);       -- Filtre : Compare le cc directement avec les cc du tableau
COMMIT; 

CREATE INDEX idx_26xxx_ilot_voronoi_t2_geom
ON "26xxx_wold50m"."26xxx_ilot_voronoi_t2"
USING gist (geom);  
COMMIT; 

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_ilot_voronoi_t3" : Regroupement des polygones Voronoi des zones de 
---- superpositions non couvertes par compte communal.

-- Description : Cette table regroupe les **polygones Voronoi** générés à partir des **zones de superposition 
--               non couvertes** en un seul MultiPolygon pour chaque **compte communal**.
-- 				 -> Attributs : **N° du compte communal** associé à chaque polygone Voronoi, **géométrie des 
--                              polygones Voronoi** (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_voronoi_t3";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_voronoi_t3" AS
SELECT 
	iv2.id,
	iv2.comptecommunal,                             -- N° de compte communal
	ST_SetSRID(
      ST_Multi(                                     -- Convertit en MultiPolygon
		ST_CollectionExtract(                       -- Extrait uniquement les polygones (type 3)
		  ST_MakeValid(                             -- Corrige les géométries invalides
			ST_Union(iv2.geom)),                    -- Fusionne les polygones en une seule MultiGéométrie
		3)),
	2154) AS geom                                   -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_ilot_voronoi_t2" iv2    -- Source : polygones Voronoi des zones de superpositions non couvertes avec cc
GROUP BY iv2.id, iv2.comptecommunal;                -- Regroupe par compte communal
COMMIT;

CREATE INDEX idx_26xxx_ilot_voronoi_t3_geom
ON "26xxx_wold50m"."26xxx_ilot_voronoi_t3"
USING gist (geom); 
COMMIT; 

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table temporaire "26xxx_ilot_voronoi_t4" : Découpe des polygones Voronoi avec les zones de 
---- superpositions non couvertes ayant plusieurs comptes communaux pour extraire les zones non couvertes à 
---- débroussailler par propriétaire.

-- Description : Cette table découpe les **polygones Voronoi** associés aux zones de **superpositions non 
--               couvertes** ayant plusieurs comptes communaux. Elle permet ainsi d'extraire les **zones non 
--               couvertes** à débroussailler par **propriétaire**. Les géométries des polygones sont ajustées 
--               afin de garantir des **zones distinctes**.
-- 				 -> Attributs : **N° du compte communal** associé à la zone de débroussaillage, **géométrie** 
--                              des zones découpées (MultiPolygon, EPSG:2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_voronoi_t4";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_voronoi_t4" AS
SELECT 
	iv3.id,
	iv3.comptecommunal,                                -- N° de compte communal
	ST_SetSRID(
      ST_Multi(                                        -- Convertit en MultiPolygon
		ST_CollectionExtract(                          -- Extrait uniquement les polygones (type 3)
		  ST_MakeValid(                                -- Corrige les géométries invalides
			ST_Intersection(ilfi.geom, iv3.geom)),     -- Intersecte les géométries entre elles
		3)),
	2154) AS geom                                      -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_ilots_final" ilfi          -- Source : zone de superpositions non couverte ayant plusieurs cc
JOIN "26xxx_wold50m"."26xxx_ilot_voronoi_t3" iv3       -- Joint avec les polygones Voronoi des zones de superpositions non couvertes regroupés par compte communal
ON ilfi.id = iv3.id
AND ST_Intersects(ilfi.geom, iv3.geom)                  -- Filtre : Vérifie que les géométries s'intersectent
AND ST_IsValid(ST_Intersection(ilfi.geom, iv3.geom));   -- Filtre : Vérifie que l'intersection est valide
-- AND ST_Area(ST_Intersection(ilfi.geom, iv3.geom)) > 0;  -- Filtre : Ne conserve que les zones ayant une surface non nulle
COMMIT; 

CREATE INDEX idx_26xxx_ilot_voronoi_t4_geom
ON "26xxx_wold50m"."26xxx_ilot_voronoi_t4"
USING gist (geom); 
COMMIT; 

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_ilot_voronoi_rg" : zones non couvertes à débroussailler par propriétaire
---- regroupées en une seule entités.

-- Description : Cette table regroupe les **géométries** zones non couvertes à débroussailler regroupées en une 
--               seule entités de la table "26xxx_ilot_voronoi_t4" pour chaque **compte communal**, pour 
--               chaque propriétaire.
-- 				 -> Attributs : **N° du compte communal** associé à chaque zone de débroussaillage, **géométrie 
--                              des zones fusionnées** (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_voronoi_rg";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_voronoi_rg" AS
SELECT
	iv4.comptecommunal,                            -- N° du compte communal
	ST_SetSRID(
      ST_Multi(                                    -- Convertit en MultiPolygon 
	    ST_CollectionExtract(                      -- Extrait uniquement les polygones (type 3)
		  ST_MakeValid(                            -- Corrige les géométries invalides
            ST_Union(iv4.geom)),                   -- Fusionne les géométries en un seul MultiPolygon
		  3)),
	  2154) AS geom                                -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_ilot_voronoi_t4" iv4   -- Source : zones non couvertes à débroussailler par propriétaire
GROUP BY iv4.comptecommunal;                       -- Regroupe par compte communal
COMMIT; 

CREATE INDEX idx_26xxx_ilot_voronoi_rg_geom 
ON "26xxx_wold50m"."26xxx_ilot_voronoi_rg" 
USING gist (geom);
COMMIT;  


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE 15                                                   ----
----                        FUSION ET FILTRAGE FINAL DES GÉOMÉTRIES SPATIALES                                ----
----								                                                                         ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                                                                                         ----
---- - Fusion conditionnelle des géométries :                                                                ----
----     - Combine et ajuste les géométries des zones en fusionnant celles qui se chevauchent.               ----
----                                                                                                         ----
---- - Intersection avec la couche de référence :                                                            ----
----     - exclut les zones situées à plus de 200 mètres des massifs forestiers sensibles (couche old_200m)  ----
----                                                                                                         ----
---- - Nettoyage final des géométries pour supprimer les principaux artéfacts.                               ----
----     - exclut les parties de polygones qui ont des surfaces très très faibles                            ----
----     - apporte une meilleure lisibilité de la couche de résultat pour les interfaces graphiques          ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--


---- Création de la nouvelle table "26xxx_result2" : Résultat final des zones à débroussailler pour chaque
---- propriétaire.

-- Description : Cette table **fusionne conditionnellement les géométries** des deux tables sources : 
--               "26xxx_result1" et "26xxx_ilot_voronoi_rg". La fusion se fait uniquement 
--               lorsque des **correspondances entre les comptes communaux** sont trouvées. Elle permet 
--               d'obtenir les zones à débroussailler pour chaque propriétaire dans leur totalité.
-- 				 -> Attributs : **N° du compte communal** associé à chaque zone de débroussaillage, 
--                              **géométrie fusionnée** des zones de débroussaillage (MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_result2";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_result2" AS
WITH union_geom AS (	
	SELECT
		COALESCE(r1.comptecommunal, ivrg.comptecommunal) AS comptecommunal, -- Sélectionne l'un ou l'autre compte communal,
		CASE 
		-- Cas où les deux tables contiennent des données
		WHEN r1.comptecommunal IS NOT NULL             -- Condition : Si compte communale des zones à débroussailler non null
		AND ivrg.comptecommunal IS NOT NULL            -- Condition : Si compte communale des trous comblés non null
		THEN
			ST_SetSRID(                                -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                                -- Convertit en MultiPolygon
				ST_CollectionExtract(                  -- Extrait uniquement les géométries de type 3
				  ST_MakeValid(                        -- Corrige les géométries invalides
					ST_Union(                          -- Fusionne les géométries
					  ST_MakeValid(ivrg.geom),         -- Corrige les géométries invalides
					  ST_MakeValid(r1.geom))),         -- Corrige les géométries invalides
				  3)),
			  2154)                                           
		-- Cas où seule la table "26xxx_result1" contient des données
		WHEN r1.comptecommunal IS NOT NULL 
		THEN
			r1.geom
		-- Cas où seule la table "26xxx_ilot_voronoi_rg" contient des données
		WHEN ivrg.comptecommunal IS NOT NULL 
		THEN ivrg.geom
		-- Sinon résultat null
		ELSE NULL                                      -- Aucun résultat valide
		END AS geom                                    -- Géométries résultantes
	FROM "26xxx_wold50m"."26xxx_result1" r1            -- Source : Zone à débroussailler corrigée avant comblement des trous
	FULL OUTER JOIN "26xxx_wold50m"."26xxx_ilot_voronoi_rg" ivrg  -- Source : trous comblés par cc
	ON r1.comptecommunal = ivrg.comptecommunal                    -- Condition :  si comptes communaux identiques
)
SELECT
	u.comptecommunal,
	ST_SetSRID(                                        -- Définit le système de coordonnées EPSG:2154
	  ST_Multi(                                        -- Convertit en MultiPolygon
		ST_CollectionExtract(                          -- Extrait uniquement les géométries de type 3
		  ST_MakeValid(                                -- Corrige les géométries invalides
			ST_Union(u.geom)),                         -- Fusionne en une seule entité
		  3)),
	  2154) AS geom                                    -- Géométries résultantes
FROM union_geom u                                      -- Source : résultat de la requête précédente
GROUP BY comptecommunal;                               -- Regroupe par compte communal
COMMIT;

CREATE INDEX idx_26xxx_result2_geom  
ON "26xxx_wold50m"."26xxx_result2"  
USING gist (geom); 
COMMIT;

--*-----------------------------------------------------------------------------------------------------------*--

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_result2_corr1";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_result2_corr1" AS
WITH 
-- 1) Épuration des épines externes 
--	 aller retour avec 3 noeuds disctincts alignés
--   supprime le noeud de l'extrémité 
epine_externe AS (
	SELECT r2.comptecommunal,                         -- N° de compte communal
        ST_SetSRID(                                   -- Définit le système de coordonnées EPSG:2154
		  ST_Multi(                                   -- Convertit en MultiPolygon
			ST_CollectionExtract(                     -- Extrait uniquement les géométries de type 3
  			  ST_MakeValid(
   				ST_Snap(                              -- Aligne le tampon de la géométrie sur la géométrie d'origine
     			  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  r2.geom, 
					  -0.0001,                        -- Ajout d'un tampon négatif de l'ordre de 10 nm
					  'join=mitre mitre_limit=5.0'),  -- 
					  0.0003),			              -- Suppression des noeuds consécutifs proches de plus de 30 nm
				  r2.geom,
                  0.0006)),3)),                       -- Avec une distance d'accrochage de l'ordre de 60 nm
		  2154) AS geom                               -- Géométries résultantes
    FROM "26xxx_wold50m"."26xxx_result2" r2           -- Source : 
),
-- 2) Épuration des épines internes
epine_interne AS (
	SELECT epext.comptecommunal,                      -- N° de compte communal
        ST_SetSRID(                                   -- Définit le système de coordonnées EPSG:2154
		  ST_Multi(                                   -- Convertit en MultiPolygon
			ST_CollectionExtract(                     -- Extrait uniquement les géométries de type 3
   			  ST_MakeValid(
   				ST_Snap(                              -- Aligne le tampon de la géométrie sur la géométrie d'origine
     			  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  epext.geom, 
					  0.0001,                         -- Ajout d'un tampon positif de l'ordre de 10 nm [**param**]
					  'join=mitre mitre_limit=5.0'),  -- 
					  0.0003),			              -- Suppression des noeuds consécutifs proches de plus de 30 nm
				  r2.geom,
                  0.0006)),3)),                       -- Avec une distance d'accrochage de l'ordre de 60 nm
		  2154) AS geom                               -- Géométries résultantes
    FROM epine_externe epext                          -- Source : Zones à débroussailler hors et dans la zone urbaine régroupées par compte communal et corrigées sans épines extérieures
	JOIN "26xxx_wold50m"."26xxx_result2" r2
	ON epext.comptecommunal = r2.comptecommunal
)
-- 3) Résultat final : on convertit la géométrie en MultiPolygon valide
SELECT epint.comptecommunal,                          -- N° de compte communal
       ST_SetSRID(                                    -- Définit le système de coordonnées EPSG:2154
          ST_Multi(                                   -- Convertit en MultiPolygon
			 ST_CollectionExtract(                    -- Extrait uniquement les géométries de type 3
   				ST_MakeValid(epint.geom),             -- Corrige les géométries invalides                                    
			 3)),
	    2154) AS geom                                 -- Géométries résultantes
FROM epine_interne epint;                             -- Source : Zones à débroussailler hors et dans la zone urbaine régroupées par compte communal et corrigées sans épines extérieures ni intérieures
--WHERE (ST_MakeValid(epint.geom) IS NOT NULL  
--	AND ST_IsEmpty(ST_MakeValid(epint.geom)) = false
--	AND ST_IsValid(ST_MakeValid(epint.geom)) = true);
COMMIT;

CREATE INDEX idx_26xxx_result2_corr1_geom 
ON "26xxx_wold50m"."26xxx_result2_corr1" 
USING gist (geom); 
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_result3" : zones à déroussailler pour chaque propriétaire dans la zone des 200m
---- autour des massifs forestiers sensibles supérieurs à 0,5 hectares.

-- Description : Cette table identifie les **zones à débroussailler** pour chaque propriétaire dans la **zone des 
--               200 mètres** autour des massifs forestiers sensibles, en tenant compte des zones supérieures à 
--               **0,5 hectare**. Elle découpe les géométries des résultats précédents avec celles des zones 
--               d’application des 200m.  
-- 				 -> Attributs : **N° du compte communal** associé à la zone de débroussaillage, **géométrie des
--                              zones à débroussailler** dans la **zone des 200m** (MultiPolygon, EPSG:2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_result3";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_result3" AS
SELECT r2c1.comptecommunal,             		  -- N° du compte communal
       ST_SetSRID(                    		      -- Définit le système de coordonnées EPSG:2154
         ST_Multi(                     		      -- Convertit en MultiPolygon 
	       ST_CollectionExtract(      		      -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(
			   ST_Intersection(         		  -- Découpe les géométries du résultat final en fonction des 200m
			     o.geom,
			     r2c1.geom)),
			3)),
		2154) AS geom                             -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_result2_corr1" r2c1   -- Source : zones à déroussailler pour chaque propriétaire
JOIN public.old200m o                 		      -- Source : champ d'application des OLD 200m
ON ST_Intersects(r2c1.geom, o.geom);              -- Condition : Joint si chevauchement des géométries
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_result3" 
WHERE ST_IsEmpty(geom);
COMMIT; 

CREATE INDEX idx_26xxx_result3_geom 
ON "26xxx_wold50m"."26xxx_result3"
USING gist (geom); 
COMMIT; 


--*-----------------------------------------------------------------------------------------------------------*--


---- Création de la table "26xxx_zold_eolien" : Génération des zones tampon autour des éoliennes
---- et association aux unités foncières et communes concernées.

-- Description : Cette table crée des zones tampon de 5 mètres autour du centre des éoliennes pour représenter le mat,
--               puis des tampons supplémentaires de 50 mètres à partir de ces premiers tampons. 
--               Les géométries résultantes sont ensuite associées aux communes et unités foncières correspondantes 
--               pour obtenir les informations de compte communal.
--               -> Attributs : nom_parc (nom du parc éolien), comptecommunal (N° du compte communal),
--                              geom (géométrie des zones tampon, MultiPolygon, 2154).
  
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zold_eolien";
COMMIT;
 
CREATE TABLE "26xxx_wold50m"."26xxx_zold_eolien" AS
WITH eolien_reprojete AS (
-- Reprojection des géométries en EPSG:2154 si nécessaire
    SELECT eof.nom_parc,                                         -- Nom du parc éolien
    	CASE
        WHEN ST_SRID(geom) = 2154                  -- Condition : Si le système de projestion est L93
		THEN ST_SetSRID(                           -- Définit le système de coordonnées EPSG:2154
				ST_Multi(eof.geom),
			 2154)                                 -- Corrige les géométries invalides
		ELSE ST_Transform(
				ST_Multi(eof.geom),                -- Convertit en MultiPolygon
			 2154)                                 -- Reprojection en EPSG:2154
        END AS geom                                -- Géométries résultantes
    FROM public.eolien_filtre eof                  -- Source : éoliennes filtrées du RETN
),
-- Intersection des éoliennes avec la commune 26xxx pour récupérer le code communal
intersection_communes AS (
    SELECT eor.nom_parc,                           -- Nom du parc éolien
           ST_SetSRID(                             -- Définit le système de coordonnées EPSG:2154
		      ST_Multi(                            -- Convertit en MultiPolygon
			     ST_MakeValid(
			        ST_Intersection(
				       eor.geom,
					   c.geom))),
		   2154) AS geom   
    FROM eolien_reprojete eor                      -- Source :éoliennes filtrées et reprojetées du RETN
    INNER JOIN r_cadastre.geo_commune c            -- Source : communes du cadastre
    ON ST_Intersects(eor.geom, c.geom)             -- Condition : quand les éoliennes intersectent la commune 
    WHERE c.idu = 'xxx'                            -- Filtre : commune avec idu = 'xxx'
),
-- Intersection des résultats précédents avec les zones OLD200m
intersection_old200m AS (
    SELECT i.nom_parc AS comptecommunal,           -- Nom du parc éolien en tant que compte communal
           ST_SetSRID(                             -- Définit le système de coordonnées EPSG:2154
		      ST_Multi(                            -- Convertit en MultiPolygon
			     ST_MakeValid(
			        ST_Intersection(
				       i.geom,
					   o.geom))),
		   2154) AS geom      
    FROM intersection_communes i                   -- Source : Les éoliennes intersectent la zone des 200m autour des massifs forestiers
    INNER JOIN public.old200m o                    -- Source : zones OLD200m
    ON ST_Intersects(i.geom, o.geom)               -- Condition : intersection avec OLD200m
),
-- Création du tampon de 3 mètres autour de chaque entité intersectée
tampon_3m AS (
    SELECT comptecommunal,                       -- N° du compte communal
           ST_SetSRID(                           -- Définit le système de coordonnées EPSG:2154
		      ST_Multi(                          -- Convertit en MultiPolygon
			     ST_Buffer(geom, 3)),            -- Crée un tampon de 3 m autour de la géométrie [**param**]
			2154) AS geom                        -- Géométries résultantes
    FROM intersection_old200m                    -- Source : Les éoliennes intersectent la zone des 200m autour des massifs forestiers
),
tampon_50m_apres_3m AS (
    -- Création du tampon de 50 mètres à partir du tampon de 3 mètres
    SELECT comptecommunal,                       -- N° du compte communal
           ST_SetSRID(                           -- Définit le système de coordonnées EPSG:2154
             ST_Multi(                           -- Convertit en MultiPolygon 
	           ST_Buffer(geom, 50)),             -- Crée un tampon de 50 m autour de la géométrie [**param**]
		   2154) AS geom                         -- Géométries résulatantes
    FROM tampon_3m                               -- Source : Résultat de la requête précédente
)
-- Regroupement des tampons de 50 mètres par nom_parc et comptecommunal
SELECT comptecommunal,                       -- N° du compte communal
	   ST_Multi(                             -- Convertit en MultiPolygon 
          ST_CollectionExtract(              -- Extrait uniquement les polygones (type 3)
	         ST_MakeValid(                   -- Corrige les géométries invalides
			    ST_Union(geom)),             -- Fusionne les géométries en une seule entité
		  3)) AS geom                        -- Géométries résultantes
FROM tampon_50m_apres_3m                     -- Source : Résultat de la requête précédente
GROUP BY comptecommunal;                     -- Regroupe par nom de parc et compte communal
COMMIT;

-- Création d'un index spatial pour optimiser les requêtes
CREATE INDEX idx_26xxx_zold_eolien_geom
ON "26xxx_wold50m"."26xxx_zold_eolien"
USING gist (geom);
COMMIT;

-----------------------------------------------

---- Création de la table "26xxx_result4" : Fusion des zones tampon éoliennes et des zones à débroussailler

-- Description : Cette table combine les zones tampon autour des éoliennes avec les zones à débroussailler
--               pour chaque propriétaire dans la zone des 200m autour des massifs forestiers supérieurs à 0,5 hectares.
--               -> Attributs : comptecommunal (N° du compte communal ou nom du parc éolien),
--                              geom (géométrie des zones combinées, MultiPolygon, 2154).

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_result4";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_result4" AS
SELECT zeo.comptecommunal,                             -- N° de compte communal
	   zeo.geom
FROM "26xxx_wold50m"."26xxx_zold_eolien" zeo           -- Source : eoliennes dans la zone des old 200m de la commune xxx
WHERE ST_Area(zeo.geom) > 0                            -- Supprime les géométries nulles

UNION ALL                                              -- Aggrège les tables

SELECT r3.comptecommunal,                              -- N° de compte communal
	   r3.geom
FROM "26xxx_wold50m"."26xxx_result3" r3;               -- Source : zone à débroussailler corrigée sans les eoliennes
COMMIT;

CREATE INDEX idx_26xxx_result4_geom
ON "26xxx_wold50m"."26xxx_result4"
USING gist (geom);
COMMIT;
