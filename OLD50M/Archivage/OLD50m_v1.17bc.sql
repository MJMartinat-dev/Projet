--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----  OLD50M   Traitements sous PostgreSQL/PostGIS pour déterminer les obligations légales                    ----
----           de débroussaillement (OLD) de chaque propriétaire d'une commune                                ----
----  Auteurs         : Frédéric Sarret, Marie-Jeanne Martinat                                                ----
----  Version         : 1.17bc                                                                                ----
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
                                                                                                              ----
----   Exemple pour la commune de CASSIS dont le code INSEE est 13022                                         ----
----   Remplacer "260xxx" par "130022"                                                                        ----
----   Remplacer "26xxx" par "13022"                                                                          ----
----   Et remplacer "xxx" par "022"                                                                           ----
----   Rappel : créer le schéma "13022_wold50m" dans votre base PostgreSQL                                    ----
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
---- OBJECTIFS :                                                                                              ----
---- - Repérer les endroits dans la commune 26xxx qui ne sont pas couverts par des parcelles du cadastre.     ----
---- - Créer une couche simple et lisible pour visualiser ces zones et les retirer facilement des             ----
----   analyses cartographiques si besoin.                                                                    ----
--*------------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE :                                                                                           ----
---- - **Sélection des données utiles** :                                                                     ----
----   - Récupération du contour de la commune 26xxx depuis la table des communes.                            ----
----   - Sélection de toutes les parcelles cadastrées qui se trouvent dans cette commune.                     ----
----                                                                                                          ----
---- - **Création des zones non cadastrées** :                                                                ----
----   - On enlève les surfaces des parcelles à celle de la commune pour obtenir les zones restantes.         ----
----   - La géométrie est nettoyée, puis transformée pour ne garder que les zones fermées (polygones).        ----
----   - Le résultat est converti au format MultiPolygon et mis en projection Lambert 93 (SRID 2154).         ----
----                                                                                                          ----
---- - **Enregistrement et optimisation** :                                                                   ----
----   - Le résultat est enregistré dans une nouvelle table dédiée : `26xxx_non_cadastre`.                    ----
----   - Un index spatial est ajouté pour rendre les traitements plus rapides ensuite.                        ----
--*------------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                     ----
---- - Une table qui affiche uniquement les zones sans parcelles dans la commune 26xxx.                       ----
---- - Des données prêtes à être utilisées dans un SIG comme QGIS ou pour des traitements automatiques.       ----
---- - Une exécution plus rapide des requêtes grâce à l’index spatial.                                        ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
 
---- Création de la table "26xxx_parcelle" : Parcelles cadastrales de la commune avec codecommune égal à 'xxx'.

---- Description : table des parcelles cadastrales de la commune identifiée par son code INSEE 26xxx.
-- 				   -> Attributs : identifiant unique, compte communal du propriétaire, géométrie.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_parcelle";
COMMIT;

-- CREATE TABLE "26xxx_wold50m"."26xxx_parcelle" AS
-- SELECT pi.idu,                                           -- Identifiant unique de la parcelle
-- 	   pi.geo_parcelle,                                  -- N° de la parcelle
--        pi.comptecommunal,                                -- N° du compte communal du propriétaire
-- 	   pi.codecommune,                                   -- 3 dernier chiffres du code INSEE
-- 	   ST_SetSRID(                                       -- Définit le SRID en 2154 (RGF93 / Lambert-93)
-- 	      ST_CollectionExtract(                          -- Nettoie et force le type géométrique
-- 	         ST_MakeValid(pi.geom),                      -- Rend la géométrie valide (répare les erreurs topologiques)
-- 	         3),                                         -- Extrait uniquement les polygones (type 3) : MultiPolygon
-- 	   2154) AS geom
-- FROM r_cadastre.parcelle_info pi                         -- Source : parcelle_info issu de Qgis
-- WHERE LEFT(pi.geo_parcelle, 6) = '260xxx';    -- Critère de sélection des parcelles de la commune 26xxx
-- --WHERE pi.codecommune = 'xxx';                 -- Parcelles dont les 3 caractères du 'code commune' sont égaux à 'xxx'
CREATE TABLE "26xxx_wold50m"."26xxx_parcelle" AS
SELECT 
    pi1.idu,                                             -- Identifiant unique de la parcelle
    pi1.geo_parcelle,                                      -- N° de la parcelle
    pi1.comptecommunal,                                    -- N° du compte communal du propriétaire
    pi1.codecommune,                                       -- 3 derniers chiffres du code INSEE
    ST_SetSRID(                                       -- Définit le SRID en 2154 (RGF93 / Lambert-93)
	      ST_CollectionExtract(                          -- Nettoie et force le type géométrique
	         ST_MakeValid(pi2.geom),                      -- Rend la géométrie valide (répare les erreurs topologiques)
	         3),                                         -- Extrait uniquement les polygones (type 3) : MultiPolygon
	   2154) AS geom
FROM r_cadastre.parcelle_info1 pi1                           -- Source 1 : parcelle_info1
LEFT JOIN r_cadastre.parcelle_info pi2                                       -- Source 2 : parcelle_info
ON pi1.idu = pi2.idu                                      -- Jointure sur l'identifiant unique de la parcelle
AND pi1.geo_parcelle = pi2.geo_parcelle
AND pi1.comptecommunal = pi2.comptecommunal
WHERE LEFT(pi1.geo_parcelle, 6) = '260xxx';                  -- Critère de sélection des parcelles de la commune 26xxx
COMMIT;

ALTER TABLE "26xxx_wold50m"."26xxx_parcelle"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);
COMMIT;

CREATE INDEX idx_26xxx_parcelle_geom 
ON "26xxx_wold50m"."26xxx_parcelle"
USING gist (geom);
COMMIT;


--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_parcelle_rg" : Union des parcelles cadastrales en une seule géométrie.

---- Description : Cette table regroupe toutes les parcelles cadastrales de la commune en une seule entité 
--                 géométrique
-- 				   -> Attributs : géométrie MultiPolygon

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_parcelle_rg";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_parcelle_rg" AS
SELECT ST_Multi(                                          -- Force le type MultiPolygon sur la géométrie fusionnée
           ST_CollectionExtract(                          -- Extrait uniquement les polygones valides après fusion
               ST_MakeValid(                              -- Rend la géométrie fusionnée valide
                   ST_Union(p.geom)),                     -- Fusionne toutes les géométries des parcelles cadastrales
                   3)                                     -- Type 3 = Polygon (ou MultiPolygon)
       ) AS geom                                          -- Colonne résultante contenant la géométrie globale                                          
FROM "26xxx_wold50m"."26xxx_parcelle" p;                  -- Source : table des parcelles cadastrales
COMMIT; 

CREATE INDEX idx_26xxx_parcelle_rg_geom 
ON "26xxx_wold50m"."26xxx_parcelle_rg"
USING gist (geom); 
COMMIT; 


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----                                             PARTIE II                                                    ----
----                               GESTION DU PARCELLAIRE NON CADASTRE                                        ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
---- OBJECTIFS :                                                                                              ----
---- - Identifier et structurer les zones non cadastrées de la commune 26xxx pour faciliter                   ----
----   leur extraction dans les analyses géospatiales et dans le projet des OLD.                              ----
---- - Ces zones non cadastrées sont déduites vu que les règles ne s'appliquent pas directement sur celles-ci ----
--*------------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE :                                                                                           ----
---- - **Détection et extraction des zones non cadastrées** :                                                 ----
----   - Calcul de la différence géométrique entre les contours administratifs de la commune                  ----
----     via la couche **'geo_commune'** et les parcelles cadastrales de la couche **'parcelle_info'**.       ----
----   - Stockage des zones non cadastrées dans une table dédiée **"26xxx_non_cadastre"**.                    ----
---- - **Structuration et correction des données** :                                                          ----
----   - Conversion des géométries en **MultiPolygon** pour assurer la cohérence géographique.                ----
----   - Application du **système de projection SRID 2154 (Lambert 93)** pour une précision topographique.   ----
---- - **Optimisation des performances et des traitements spatiaux** :                                        ----
----   - Création d’un **index spatial GIST** permettant d’accélérer les requêtes spatiales.                  ----
--*------------------------------------------------------------------------------------------------------------*--
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
SELECT ST_SetSRID(                                         -- Définit le SRID en 2154 (RGF93 / Lambert-93)
          ST_Multi(                                        -- Force le type MultiPolygon sur la géométrie résultante
             ST_CollectionExtract(                         -- Extrait uniquement les polygones valides
                ST_MakeValid(                              -- Rend la géométrie résultante valide
                   ST_Difference(                          -- Soustraction géométrique : commune - parcelles
                      c.geom,                              -- Géométrie du contour communal
                      ST_Union(p.geom))),                  -- Fusion de toutes les parcelles cadastrées   
                3)),                                       -- Type 3 = Polygone
       2154) AS geom                                       -- Résultat : zone non cadastrée dans la commune
FROM "26xxx_wold50m"."26xxx_parcelle" p,                   -- Source : parcelles cadastrales de la commune
     r_cadastre.geo_commune c                              -- Source : contours des communes
WHERE c.idu = 'xxx'                                        -- Filtre sur la commune INSEE = 26xxx
AND LEFT(p.idu, 3) = 'xxx'                                 -- Parcelles correspondant à la même commune
GROUP BY c.geom;                                           -- Regroupe pour générer une seule géométrie par commune
COMMIT;

ALTER TABLE "26xxx_wold50m"."26xxx_non_cadastre"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154); 
COMMIT;  

CREATE INDEX idx_26xxx_non_cadastre_geom 
ON "26xxx_wold50m"."26xxx_non_cadastre"
USING gist (geom); 
COMMIT;  


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----                                             PARTIE III                                                   ----
----                                       GESTION DES BÂTIMENTS                                              ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                              ----
---- - Produire une base géographique propre et structurée des entités bâtis de la commune 26xxx en raison de ----
----   la règles des OLD, où il faut débroussailler 50m autour des bâtiments.                                 ----
---- - Identifier les constructions dans la zone concernée des obligation légale de débroussaillement : 200m  ----
----   autour des massifs forestiers (OLD200m).                                                               ----
---- - Attribuer les comptes communaux aux batiments dans la zone préalablement sélectionnée.                 ----
---- - Intégrer les "Campings" et "Parcs Photovoltaïques" vu que les traitements pour ces structures ne sont  ----
----   réaliser à partir du bâtiments mais du périmètre de la structure (sources différentes).                ----
---- - Supprimer les bâtiments qui sont dans le périmètre des "Campings" et "Parcs Photovoltaïques".          ----
---- - Regrouper ces entités par compte communal et générer un tampon de 50 m pour chaque groupe pour         ----
----   déterminer le périmètre à débroussailler par propriétaire.                                             ----
--*------------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                   ----
----                                                                                                          ----
---- - **Extraction et nettoyage des entités bâtis (`26xxx_bati`)** :                                         ----
----   - Sélection des bâtiments intersectant la commune (surface ≥ 6 m²), typés 'Habitat'.                   ----
----   - Exclusion des bâtiments situés dans les zones 'Camping' ou 'Centrale photovoltaïque'.                ----
----   - Réintégration de ces zones comme entités surfaciques distinctes dans la même table.                  ----
----   - Standardisation géométrique : ST_MakeValid → ST_CollectionExtract → ST_Multi.                        ----
----   - Projection Lambert 93 et index spatial.                                                              ----
----                                                                                                          ----
---- - **Identification des bâtis en zone OLD 200 m (`26xxx_bati200`)** :                                     ----
----   - Filtrage spatial par intersection avec la couche `old200m`.                                          ----
----   - Extraction des géométries valides en MultiPolygon.                                                   ----
----                                                                                                          ----
---- - **Rattachement aux comptes communaux (`26xxx_bati200_cc`)** :                                          ----
----   - Association via le centroïde avec l’unité foncière correspondante.                                   ----
----   - En cas d’échec : attribution au compte le plus proche.                                               ----
----   - Projection en L93, typage MultiPolygon, indexation.                                                  ----
----                                                                                                          ----
---- - **Fusion par compte communal (`26xxx_bati200_cc_rg`)** :                                               ----
----   - Agrégation des géométries par compte avec ST_Union + ST_Multi.                                       ----
----   - Résultat : une emprise unique par compte communal.                                                   ----
----                                                                                                          ----
---- - **Tampons de 50 m (`26xxx_bati_tampon50`)** :                                                          ----
----   - Génération d’un tampon de 50 m autour de chaque groupe avec ST_Buffer.                               ----
--*------------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                     ----
---- - Les bâtiments de la communes et le périmètre des "Campings" et "Parcs Photovoltaïques" de la commune   ----
----   26xxx dans la zones des 200m autour des massifs forestiers reroupés ou non avec leur propre compte     ----
----   communal                                                                                               ----
---- - Zone à débroussailler par propriétaire autour de leurs bâtiments avec zone de supperposition           ----
--*------------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                             ----
---- - ST_Force2D : nécessaire pour éliminer les dimensions 3D inutiles dans ce contexte.                     ----
---- - ST_Area ≥ 6 : Seuil de 6 m² pour exclure les très petites constructions non soumises à réglementation, ----
----                 sans valeur foncière ni enjeu OLD, afin d’éliminer les artefacts tout en conservant les  ----
----                 véritables bâtiments.                                                                    ----
---- - ST_CollectionExtract(type 3) : permet d’éviter les erreurs lors des unions ou buffers.                 ----
---- - UNION ALL : permet de conserver les entités exclues (campings, centrales) à des fins de repérage.      ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--


---- Création de la table des cimetières

---- Description : Cette table extrait et stocke les géométries des cimetières pour la commune 26xxx,  
--                en s'appuyant sur la couche r_bdtopo.cimetiere et la jointure sur la commune cible.
--                -> Attributs : identifiant (NULL ici car pas présent), nature, idu commune, géométrie 2D

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_cimetiere";                       
CREATE TABLE "26xxx_wold50m"."26xxx_cimetiere" AS                             
SELECT NULL::integer AS fid,                                                  -- Identifiant (non renseigné car pas d'ID disponible dans la source)
       'Cimetiere' AS nature,                                                 -- Ajoute la valeur 'Cimetiere' dans la colonne nature
       c.idu,                                                                 -- Attribut idu : identifiant unique de la commune
       ST_Force2D(r.geometrie) AS geom                                        -- Géométrie convertie en 2D (projection XY)
FROM r_bdtopo.cimetiere r                                                     -- Source : couche BD TOPO cimetières
INNER JOIN r_cadastre.geo_commune c                                           -- Jointure spatiale avec la table des communes du cadastre
  ON ST_Intersects(r.geometrie, c.geom)                                       -- Condition de jointure spatiale : intersection des géométries
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
           ST_Force2D(z.geometrie) AS geom                                    -- Géométrie projetée en 2D
    FROM r_bdtopo.zone_d_activite_ou_d_interet z                              -- Source : zones d'activité BD TOPO
    INNER JOIN r_cadastre.geo_commune c                                       -- Jointure avec la commune
      ON ST_Intersects(z.geometrie, c.geom)                                   -- Condition : intersection spatiale
    WHERE c.idu = 'xxx'                                                       -- Commune cible
      AND z.nature = 'Camping'                                                -- Filtre sur la nature Camping
),
centrales AS (                                                                -- Début de la CTE pour les centrales PV
    SELECT NULL::integer AS fid,                                              -- Identifiant nul
           'Centrale photovoltaïque' AS nature,                               -- Nature : Centrale photovoltaïque
           c.idu,                                                             -- idu commune
           ST_Force2D(z.geometrie) AS geom                                    -- Géométrie projetée en 2D
    FROM r_bdtopo.zone_d_activite_ou_d_interet z                              -- Source : zones d'activité BD TOPO
    INNER JOIN r_cadastre.geo_commune c                                       -- Jointure commune
      ON ST_Intersects(z.geometrie, c.geom)                                   -- Condition : intersection spatiale
    WHERE c.idu = 'xxx'                                                       -- Commune cible
      AND z.nature_detaillee = 'Centrale photovoltaïque'                      -- Filtre sur la nature détaillée centrale PV
),
carrieres AS (                                                                -- Début de la CTE pour les carrières
    SELECT NULL::integer AS fid,                                              -- Identifiant nul
           'Carrière' AS nature,                                              -- Nature : Carrière
           c.idu,                                                             -- idu commune
           ST_Force2D(z.geometrie) AS geom                                    -- Géométrie projetée en 2D
    FROM r_bdtopo.zone_d_activite_ou_d_interet z                              -- Source : zones d'activité BD TOPO
    INNER JOIN r_cadastre.geo_commune c                                       -- Jointure commune
      ON ST_Intersects(z.geometrie, c.geom)                                   -- Condition : intersection spatiale
    WHERE c.idu = 'xxx'                                                       -- Commune cible
      AND z.nature = 'Carrière'                                               -- Filtre sur la nature Carrière
),
cets AS (                                                                     -- Début de la CTE pour les CET
    SELECT NULL::integer AS fid,                                              -- Identifiant nul
           'Centre d''enfouissement technique' AS nature,                     -- Nature : CET (Centre d'enfouissement technique)
           c.idu,                                                             -- idu commune
           ST_Force2D(z.geometrie) AS geom                                    -- Géométrie projetée en 2D
    FROM r_bdtopo.zone_d_activite_ou_d_interet z                              -- Source : zones d'activité BD TOPO
    INNER JOIN r_cadastre.geo_commune c                                       -- Jointure commune
      ON ST_Intersects(z.geometrie, c.geom)                                   -- Condition : intersection spatiale
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
           ST_Force2D(b.geometrie) AS geom                                    -- Géométrie en 2D
    FROM r_bdtopo.batiment b                                                  -- Source : bâtiments BD TOPO
    INNER JOIN r_cadastre.geo_commune c                                       -- Jointure avec la commune
      ON ST_Intersects(b.geometrie, c.geom)                                   -- Condition : intersection spatiale
    WHERE c.idu = 'xxx'                                                       -- Commune cible
      AND ST_Area(b.geometrie) >= 6                                           -- Surface supérieure ou égale à 6 m²
)
SELECT b.fid,                                                                 -- Identifiant bâtiment (issu de la CTE)
       b.nature,                                                              -- Nature (issu de la CTE)
       b.idu,                                                                 -- idu (issu de la CTE)
       ST_Multi(ST_CollectionExtract(ST_MakeValid(b.geom), 3)) AS geom        -- Géométrie validée, convertie en MultiPolygon (type 3)
FROM bati_init b                                                              -- Source : CTE bati_init
WHERE NOT EXISTS (
  SELECT 1 FROM r_bdtopo.cimetiere r                                          -- Sélectionne s'il existe une intersection avec un cimetière
  INNER JOIN r_cadastre.geo_commune c                                         -- Jointure avec la commune
    ON ST_Intersects(r.geometrie, c.geom)                                     -- Condition spatiale
  WHERE c.idu = 'xxx'                                                         -- Commune cible
    AND ST_Intersects(b.geom, r.geometrie)                                    -- Exclut les bâtiments présents dans un cimetière
)
AND NOT EXISTS (
  SELECT 1 FROM r_bdtopo.zone_d_activite_ou_d_interet z                       -- Sélectionne s'il existe une intersection avec une zone d'activité spécifique
  INNER JOIN r_cadastre.geo_commune c                                         -- Jointure avec la commune
    ON ST_Intersects(z.geometrie, c.geom)                                     -- Condition spatiale
  WHERE c.idu = 'xxx'                                                         -- Commune cible
    AND (
        z.nature = 'Camping'                                                  -- Filtre les campings
     OR z.nature_detaillee = 'Centrale photovoltaïque'                        -- Filtre les centrales photovoltaïques
     OR z.nature = 'Carrière'                                                 -- Filtre les carrières
     OR z.nature_detaillee = 'Centre d''enfouissement technique'              -- Filtre les CET
    )
    AND ST_Intersects(b.geom, z.geometrie)                                    -- Exclut les bâtiments présents dans une installation
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

--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_bati200" : Bâtiments intersectant la zone OLD 200m dans la commune 26xxx.

-- Description : Cette table extrait les **bâtiments situés dans la zone des 200 mètres autour des massifs forestiers**
--               pour la commune 26xxx. Les géométries sont corrigées, transformées en MultiPolygon, et si besoin,
--               extraites depuis une GeometryCollection (type 3 uniquement).
--               → Attributs : nature (type de bâtiment), fid (identifiant bâtiment), idu (identifiant commune), 
--               geom (MultiPolygon, 2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_bati200";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_bati200" AS
SELECT DISTINCT 
       b.nature,                                                 -- Nature du bâtiment (habitat, agricole, etc.)
       b.fid,                                                    -- Identifiant unique du bâtiment
       b.idu,                                                    -- Identifiant de la commune

       -- Géométrie traitée selon son type : extraction si GeometryCollection, sinon conversion directe
       CASE 
           WHEN GeometryType(ST_MakeValid(b.geom)) = 'GEOMETRYCOLLECTION' 
           THEN ST_Multi(                                        -- Convertit en MultiPolygon
                   ST_CollectionExtract(                         -- Extrait uniquement les polygones (type 3)
                       ST_MakeValid(b.geom), 
                       3))

           ELSE ST_Multi(                                        -- Sinon : conversion directe en MultiPolygon
                   ST_MakeValid(b.geom))                         -- Géométrie simplement validée
       END AS geom                                               -- Géométrie résultante (MultiPolygon, 2154)

FROM "26xxx_wold50m"."26xxx_bati" b                              -- Source : bâtiments de la commune 26xxx
INNER JOIN public.old200m o                                     -- Source : zone OLD 200m (massifs forestiers)
ON ST_Intersects(o.geom, b.geom);                        -- Filtre : bâtiments intersectant la zone des 200m
COMMIT;

-- Création de l’index spatial pour optimiser les recherches spatiales
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
    SELECT DISTINCT ON (b200.fid)                                 -- Assigne chaque bâtiment à UNE SEULE unité foncière
           b200.fid,                                              -- Identifiant unique du bâtiment                          
           b200.nature,                                           -- Nature du bâtiment                         
           uf.comptecommunal,                                     -- N° de compte communal                         
           ST_Multi(                                              -- Convertit en MultiPolygon
		      ST_CollectionExtract(                               -- Extrait uniquement les polygones (type 3)
			     ST_MakeValid(b200.geom),                         -- Corrige les géométries invalides
		   3)) AS geom                                            -- Géométries résultantes
    FROM "26xxx_wold50m"."26xxx_bati200" b200                     -- Source : Bâtiments dans la zone des 200m autour des massifs forestiers              
    JOIN r_cadastre.geo_unite_fonciere uf                         -- Source : unités foncières de la commune
    ON ST_Intersects(ST_Centroid(b200.geom), uf.geom)             -- Condition : quand la géométrie des unités foncières intersecte le pseudo-centroide du bati  
),
-- Sélectionner les bâtiments qui ne sont pas associés à une unité foncière
bati_non_associes AS (
    SELECT b200.fid,                                              -- Identifiant unique du bâtiment  
           b200.nature,                                           -- Nature du bâtiment   
           ST_Multi(                                              -- Convertit en MultiPolygon
		      ST_CollectionExtract(                               -- Extrait uniquement les polygones (type 3)
			     ST_MakeValid(b200.geom),                         -- Corrige les géométries invalides
		   3)) AS geom,                                           -- Géométries résultantes
-- Recherche du compte communal de l'unité foncière la plus proche
           (SELECT uf.comptecommunal                              -- N° de compte communal
            FROM r_cadastre.geo_unite_fonciere uf                 -- Source : unités foncières de la commune
            ORDER BY ST_Distance(ST_Centroid(b200.geom), uf.geom) -- Ordonne par distance la plus proche entre le centroïde du batiment et les unites foncieres
            LIMIT 1) AS comptecommunal_proche 
    FROM "26xxx_wold50m"."26xxx_bati200" b200                     -- Source : Bâtiments dans la zone des 200m autour des massifs forestiers  
    LEFT JOIN bati_intersect bi                                   -- Source : Résultat de la requête précédente
	ON b200.fid = bi.fid                                          -- Condition : quand les identifiant unique du bati sont identiques
    WHERE bi.fid IS NULL                                          -- Filtre : Sélectionne uniquement les bâtiments non encore associés
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
SELECT b200cc.comptecommunal,                               -- N° de compte communal
	   ST_Multi(                                            -- Convertit en MultiPolygon
	      ST_Union(b200cc.geom)) AS geom                    -- Fusionne les géométries des bâtiments en une seule entité par compte communal
FROM "26xxx_wold50m"."26xxx_bati200_cc" b200cc              -- Source : Bâtiments associés aux comptes communaux
GROUP BY b200cc.comptecommunal;                             -- Regroupe par N° de compte communal
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
SELECT ST_Multi(                                            -- Convertit en MultiPolygon
	      ST_Buffer(b200ccrg.geom, 50, 16)                  -- Génère un tampon de 50m autour des bâtiments
	   ) AS geom,                                           -- Géométrie résultante
	   b200ccrg.comptecommunal                              -- N° de compte communal
FROM "26xxx_wold50m"."26xxx_bati200_cc_rg" b200ccrg;        -- Source : bâtiments regroupés par cc entièrement dans la zone "old_200m"
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
----                                            PARTIE IV                                                     ----
----                                 CORRECTION DU ZONAGE URBAIN                                              ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                              ----  
---- - Identifier les zones urbaines de la commune 26xxx à partir des données issues de la GeoPlateforme.     ----
---- - Création du zonage urbain si iexistant, si table vide (Création de la table obligatoire), à partir du  ----
----   parcellaire de la mairie.                                                                              ----
---- - Appliquer un recalage géométrique sur le zonage urbain via les points de parcelles proches.            ----  
---- - Conserver le zonage d'origine si la distance moyenne des points est suffisante (AVG > STDDEV).         ----  
---- - Sinon, reconstituer intégralement le zonage recalé avec snapping, reprojection et corrections.         ----
--*------------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                   ----  
----                                                                                                          ----  
---- - Import des zones urbaines 'U' depuis QGIS, pré-filtrées par partition.                                 ----  
---- - Application d’un snapping interne entre polygones pour recaler le zonage initial sur le zonage         ----
----   parcellaire.                                                                                           ----  
---- - Décomposition du zonage recalé en polygones élémentaires (dump).                                       ----  
---- - Sélection des parcelles à moins de 10 m du zonage recalé.                                              ----  
---- - Extraction des points des contours de ces parcelles, nettoyage (tolérance 0.25).                       ----  
---- - Filtrage des points situés dans une couronne externe de ±10 m autour du zonage.                        ----  
---- - Extraction structurée des points du contour du zonage (hiérarchie polygonale, anneau, rang).           ----  
---- - Calcul de la distance minimale entre chaque point du zonage et les points des parcelles.               ----  
---- - Si la moyenne est supérieure à l’écart-type → on conserve le zonage recalé simple.                     ----  
---- - Sinon, recalage complet par :                                                                          ----  
----   - Snapping sur points identiques, proches, intersections, centres.                                     ----  
----   - Projection sur bords de parcelles selon seuils adaptatifs (q10, q50, q100).                          ----  
----   - Réindexation complète des points recalés par anneau.                                                 ----  
----   - Réordonnancement spatial des points en fonction des segments proches.                                ----  
----   - Reconstruction polygonale fermée, avec gestion des anneaux internes.                                 ----  
----   - Union finale des polygones corrigés en MultiPolygon homogène.                                        ----  
--*------------------------------------------------------------------------------------------------------------*--  
---- RÉSULTATS ATTENDUS :                                                                                     ----  
---- - Zones urbaines brutes issues de la GeoPlateforme.                                                      ----  
---- - Zonage recalé géométriquement par snapping interne pour éviter les artefacts inetrnes.                 ----  
---- - Polygones unitaires extraits du zonage recalé.                                                         ----  
---- - Parcelles proches du zonage, dans un buffer de 10 m.                                                   ----  
---- - Points des contours des parcelles nettoyés et structurés.                                              ----  
---- - Points des parcelles en bande externe autour du zonage.                                                ----  
---- - Points du contour du zonage, hiérarchisés pour traitement.                                             ----  
---- - Résultat conditionnel : soit zonage simple, soit pipeline de recalage complet.                         ----  
---- - Points recalés par 6 méthodes : identiques, proches, internes, reprojetés simples ou élargis.          ----  
---- - Réindexation et réorganisation des points recalés.                                                     ----  
---- - Reconstruction polygonale propre avec trous éventuels.                                                 ----  
---- - Union finale des géométries recalées validées.                                                         ----  
--*------------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                             ----  
---- - ST_Snap avec une tolérance de 0.xxx : réaligne précisément les contours de zones juxtaposées pour      ----  
----   supprimer les décalages minimes (inférieurs au pixel cartographique).                                  ----  
---- - ST_Buffer ±10 m : permet de cibler uniquement les points de parcelles situés dans une bande pertinente ----  
----   autour du zonage, sans bruit géométrique inutile.                                                      ----  
---- - ST_RemoveRepeatedPoints : élimine les points superposés ou redondants qui empêchent les reconstructions----  
----   polygonales correctes (épines, segments nuls, etc.).                                                   ----  
---- - ST_ClosestPoint et ST_Snap : repositionnent les points du zonage sur les parcelles de manière fiable,  ----  
----   selon leur distance réelle aux références cadastrales.                                                 ----  
---- - ST_MakePolygon, ST_Union, ST_Multi : assurent une reconstruction correcte des polygones, sans trous,   ----  
----   sans croisements et avec format homogène (MultiPolygon, SRID 2154).                                    ----  
---- - Condition moyenne > écart-type : permet de statuer objectivement sur la nécessité de recalage complet  ----  
----   en fonction de la dispersion des distances minimales (statistique robuste).                            ----  
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_zonage" : Zonage urbain de la commune ayant pour valeur de l'attribut "partition"   
---- 'DU_26xxx' et pour valeur de l'attribut "typezone" 'U'.

-- Cette opération est réalisée dans QGIS avant d'importer les données dans PostgreSQL.	--

-- Étape 1 : Charger la couche WFS "Zonage du document d’urbanisme" depuis la GeoPlateforme.
-- Étape 2 : Sélectionner les zones urbaines "U" de la commune "26xxx" dans QGIS.
--           Expression de sélection : "partition" = 'DU_26xxx' AND "typezone" = 'U'.
-- Étape 3 : Exporter les zones sélectionnées sous le nom "26xxx_zonage" en EPSG:4xxx.
-- Étape 4 : Importer la couche "26xxx_zonage" dans PostgreSQL avec transformation en EPSG:2154.


--*------------------------------------------------------------------------------------------------------------*--
-- Ce code vérifie si une table nommée "26xxx_zonage" existe dans le schéma "26xxx_wold50m".                    --
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

        CREATE TABLE "26xxx_wold50m"."26xxx_zonage" AS                      
        SELECT 'Mairie' AS nature,                                 -- Nature du bâtiments
               'U' AS typezone,                                    -- Type de zone urbaine
               c.idu,                                              -- Code INSEE de la commune
               ST_Force2D(                                         -- Force la géométrie en 2D
                  ST_Intersection(                                 -- Intersecte les zones d’activité et les bâtiments
                     ST_Union(t.geometrie),                        -- Union des géométries des zones d’activité en une seule entités par attributs
                     ST_Union(b.geometrie))                        -- Union des géométries des bâtiments en une seule entités par attributs
               ) AS geom
        FROM r_bdtopo.zone_d_activite_ou_d_interet t               -- Source : zones d’activités et d'intérêts issues de la BDTopo
        JOIN r_bdtopo.batiment b 
		ON ST_Intersects(t.geometrie, b.geometrie)                 -- Condition : Jointure spatiale bâtiments/zones
        JOIN r_cadastre.geo_commune c 
		ON ST_Intersects(b.geometrie, c.geom)                      -- Condition : Jointure spatiale avec la commune
        WHERE t.nature = 'Mairie'                                  -- Filtre : nature est égale Mairie
        AND c.idu = 'xxx'                                          -- Filtre : Commune cible
        GROUP BY t.nature, t.geometrie, idu                        -- Regroupe par attributs

        UNION ALL                                                  -- Agrégation des deux tables

        SELECT 'Eglise' AS nature,                                 -- Nature du bâtiments
               'U' AS typezone,                                    -- Type de zone urbaine
               c.idu,                                              -- Code INSEE
               ST_Force2D(
                  ST_Intersection(b.geometrie, c.geom)) AS geom    -- Intersecte les bâtiment et la commune
        FROM r_bdtopo.batiment b                                   -- Source : bâtiments issus de la BDTopo
        JOIN r_cadastre.geo_commune c                              -- Source : communes issues du cadastre
		ON ST_Intersects(b.geometrie, c.geom)                      -- Condition : Jointure spatiale
        WHERE b.nature = 'Eglise'                                  -- Filtre : nature = Eglise
        AND c.idu = 'xxx';                                         -- Filtre : Commune cible

		RAISE NOTICE 'Création de la table terminée.';

    ELSE
        RAISE NOTICE 'La table 26xxx_zonage existe déjà. Copie depuis public.26xxx_zonage dans le schéma 26xxx_wold50m.';
        
		DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage";
        -- Si la table existe déjà : copie depuis public.26xxx_zonage
        CREATE TABLE "26xxx_wold50m"."26xxx_zonage" AS
        SELECT *                                                    -- Toutes les données
        FROM public."26xxx_zonage"                                  -- Source : zonage urbain
        WHERE typezone = 'U';                                         -- Filtre : le type de zone égale à U
    END IF;
END $$;  -- Fin du bloc DO

ALTER TABLE "26xxx_wold50m"."26xxx_zonage"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154);  
COMMIT;  

CREATE INDEX IF NOT EXISTS idx_26xxx_zonage_geom 
ON "26xxx_wold50m"."26xxx_zonage"
USING gist (geom); 
COMMIT; 


--*------------------------------------------------------------------------------------------------------------*--


---- Création de la table "26xxx_zonage_rg" : Zonage urbain recalé géométriquement avant union.

---- Description : Cette table regroupe les polygones du zonage de type 'U' (urbain) de la commune 26xxx,
--                 en appliquant un snapping géométrique préalable entre eux afin de corriger les petites
--                 discontinuités ou décalages avant l’union spatiale.
--                 Le snapping est appliqué sur chaque géométrie valide, en référence à l’enveloppe agrégée 
--                 de l’ensemble des polygones, avec une tolérance de 0.xxx unité.
--                 Après snapping, une fusion (`ST_Union`) est effectuée proprement, suivie d’un typage en 
--                 MultiPolygon (2154).
--                 -> Attributs : typezone ('U'), géométrie MultiPolygon (2154)
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_rg";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_zonage_rg" AS
-- construction de la géométrie de référence pour le snapping
WITH correction_geom AS (
     SELECT ST_MakeValid(z.geom) AS geom                              -- Corrige les géométries invalides
     FROM "26xxx_wold50m"."26xxx_zonage" z                            -- Source : Zonage urbain de la commune
     WHERE z.typezone = 'U'                                           -- Filtre sur le zonage urbain uniquement (type = 'U')
),
reference_geom AS (
     SELECT ST_Collect(cg.geom) AS ref_geom                           -- Construit la géométrie de référence : agrége de toutes les zones valides
     FROM correction_geom cg
),
snap AS (
     SELECT ST_Snap(cg.geom, rg.ref_geom, 0.01) AS geom              -- Snapping : ajustement géométrique avec une tolérance de 0.xxx
     FROM correction_geom cg                                          -- Source : Zonage urbain de la commune corrigé
     CROSS JOIN reference_geom rg                                     -- Applique la géométrie de référence à chaque polygone individuel pour l'alignement
)

-- Fusion propre et typée des géométries recalées
SELECT 'U'::text AS typezone,                                         -- Type de zone fixé à 'U' (urbain)
       ST_SetSRID(                                                    -- Définit le système de projection (L93:2154)
          ST_Multi(                                                   -- Convertit en MultiPolygon
             ST_CollectionExtract(                                    -- Extrait les objets de type polygone uniquement
                ST_Union(s.geom),                                       -- Fusionne de toutes les géométries recalées
                3)), 
       2154) AS geom                                                 -- Géométries résultantes
FROM snap s; 
COMMIT;

ALTER TABLE "26xxx_wold50m"."26xxx_zonage_rg"
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154) 
USING ST_SetSRID(geom, 2154);  
COMMIT;  

CREATE INDEX IF NOT EXISTS idx_26xxx_zonage_rg_geom 
ON "26xxx_wold50m"."26xxx_zonage_rg"
USING gist (geom); 
COMMIT; 


--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_zonage_rgid" : Décomposition du zonage urbain recalé en polygones unitaires.

---- Description : Cette table extrait chaque polygone composant le zonage recalé "U" (zonage_rg),
--                 en le décomposant à l’aide de la fonction `ST_Dump` pour permettre un traitement unitaire.
--                 Chaque polygone reçoit un identifiant de chemin (`path`) pour conserver sa hiérarchie interne.
--                 -> Attributs : chemin du polygone (`path`), géométrie unitaire (Polygon ou MultiPolygon, 2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_rgid";               
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_zonage_rgid" AS
SELECT (ST_Dump(zrg.geom)).path AS path,                               -- Chemin unique du polygone dans la structure géométrique
       (ST_Dump(zrg.geom)).geom AS geom                                -- Décompose la multi-géométrie en plusieurs géométries simples
FROM "26xxx_wold50m"."26xxx_zonage_rg" AS zrg                          -- Source : zonage urbain recalé et agrégé
WHERE zrg.geom IS NOT NULL                                             -- Filtre : exclusion des lignes sans géométrie
AND ST_IsValid(zrg.geom);                                              -- Filtre : exclusion des géométries invalides
COMMIT;

CREATE INDEX IF NOT EXISTS sidx_26xxx_26xxx_zonage_rgid_geom 
ON "26xxx_wold50m"."26xxx_zonage_rgid"
USING gist (geom);                                                      
COMMIT;


--*------------------------------------------------------------------------------------------------------------*--


---- Création de la table "26xxx_pts_parcelle_zu_t0" : Parcelles intersectant une zone tamponnée autour du zonage.

---- Description : Cette table regroupe les géométries des parcelles cadastrales qui intersectent une zone tampon 
--                 de 10 mètres autour de chaque polygone du zonage urbain recalé, pour identifier les parcelles 
--                 proches.
--                 Le résultat est une unique géométrie agrégée typée en MultiPolygon (SRID 2154).
--                 -> Attributs : géométrie agrégée des parcelles (MultiPolygon, 2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_pts_parcelle_zu_t0";       
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_pts_parcelle_zu_t0" AS
SELECT ST_SetSRID(                                                       -- Définit le système de projection EPSG:2154
           ST_Collect(pa.geom), 2154                                     -- Agrége toutes les géométries de parcelles concernées
       ) AS geom
FROM "26xxx_wold50m"."26xxx_parcelle" AS pa                              -- Source : parcelles cadastrales de la commune
JOIN "26xxx_wold50m"."26xxx_zonage_rgid" AS zrgid                        -- Source : polygones individuels du zonage urbain recalé
ON ST_Intersects(pa.geom, ST_Buffer(zrgid.geom, 10));                    -- Condition : intersection avec un tampon de 10 mètres
COMMIT;

CREATE INDEX IF NOT EXISTS sidx_26xxx_pts_parcelle_zu_t0_geom 
ON "26xxx_wold50m"."26xxx_pts_parcelle_zu_t0"
USING gist (geom);                                                     
COMMIT;


--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_pts_parcelle_zu_t1" : Extraction des points des contours des parcelles proches du 
---- zonage urbain.

---- Description : Cette table extrait individuellement tous les points formant les contours des parcelles situées 
--                 à proximité immédiate du zonage urbain (zone tamponnée de 10 m). 
--                 Les points sont nettoyés des doublons (tolérance 0.25) et identifiés grâce à leur chemin d'origine.
--                 Cette extraction servira de base pour le recalage géométrique du zonage.
--                 -> Attributs : identifiant du point (`path`), géométrie ponctuelle (Point, 2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_pts_parcelle_zu_t1";           
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_pts_parcelle_zu_t1" AS
SELECT (ST_Dump(                                                           -- Décompose la géométrie en points individuels
           ST_RemoveRepeatedPoints(                                        -- Supprime les points redondants (tolérance : 0.25)
              ST_Points(pts0.geom), 0.25)                                  -- Extrait les sommets des polygones (sous forme de multipoint)
       )).path AS path,                                                    -- Chemin d’accès du point dans la géométrie d’origine
       (ST_Dump(                                                           -- Décompose la géométrie en points individuels
           ST_RemoveRepeatedPoints(                                        -- Supprime les points redondants (tolérance : 0.25)
              ST_Points(pts0.geom), 0.25)                                  -- Extrait les sommets des polygones (sous forme de multipoint)
       )).geom AS geom                                                     -- Géométrie du point (type Point)

FROM "26xxx_wold50m"."26xxx_pts_parcelle_zu_t0" AS pts0;                   -- Source : parcelles ayant intersecté le buffer 10 m du zonage
COMMIT;

CREATE INDEX IF NOT EXISTS sidx_26xxx_pts_parcelle_zu_t1_geom 
ON "26xxx_wold50m"."26xxx_pts_parcelle_zu_t1"
USING gist (geom);                                                       
COMMIT;


--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_pts_parcelle_zu_t2" : Sélection des points situés dans la couronne externe du 
---- zonage urbain.

---- Description : Cette table extrait les points des parcelles situés dans une bande de 10 m autour du zonage 
--                 urbain, en excluant ceux qui se trouvent à moins de 10 m à l’intérieur. Elle sert à guider le 
--                 recalage en se concentrant uniquement sur les points d’ajustement proches des contours.
--                 -> Attributs : identifiant (`path`), géométrie ponctuelle typée (Point, 2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_pts_parcelle_zu_t2";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_pts_parcelle_zu_t2" AS
SELECT pts1.path,                                                 -- Identifiant du point dans le polygon
	   ST_SetSRID(pts1.geom, 2154) AS geom                       -- Définit le système de projection (L93 : 2154)
FROM "26xxx_wold50m"."26xxx_pts_parcelle_zu_t1" AS pts1,          -- Source : points des parcelles voisines ou dans la zone urbaine
     "26xxx_wold50m"."26xxx_zonage_rgid" zrgid                    -- Source : zonage urbain corrigé regroupé par identifiants
WHERE ST_Contains(                                                -- Filtre : point des parcelles contenu dans le zonage urbain et sa zone tampon externe de 10m
         ST_Buffer(zrgid.geom,10),                                  
		 pts1.geom)                                               
AND NOT ST_Contains(                                              -- Filtre : point des parcelles contenu dans le zonage urbain et sa zone tampon interne de 10m
           ST_Buffer(zrgid.geom,-10),                               
		   pts1.geom);                                            
COMMIT; 

CREATE INDEX sidx_26xxx_pts_parcelle_zu_t2_geom 
ON "26xxx_wold50m"."26xxx_pts_parcelle_zu_t2"
USING gist (geom); 
COMMIT; 


--*------------------------------------------------------------------------------------------------------------*--
---- Création de la table "26xxx_zonage_corr1" : Extraction structurée sans doublons des points du zonage urbain.

---- Description : Cette table extrait tous les points du contour du zonage urbain recalé, en structurant leur
--                 position hiérarchique (polygone, anneau, point). Les doublons exacts sont supprimés 
--                 au sein de chaque anneau, et les points sont réordonnés.
--                 -> Attributs : chemin hiérarchique [id_polygone, id_ring, id_point], géométrie du point

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr1";                   -- Suppression de la table si elle existe
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr1" AS
WITH point_zonage AS (
    -- Extraction des points de chaque anneau du zonage (après nettoyage des doublons de segments)
    SELECT 
        t.path AS path1,                                                    -- Chemin du polygone 
        (dp).path AS path2,                                                 -- Chemin de l’anneau et du point 
        (dp).geom AS geom                                                   -- Coordonnée du point extrait
    FROM (
        SELECT *, ST_DumpPoints(ST_RemoveRepeatedPoints(zrgid.geom)) AS dp  -- Suppression des points répétés avant découpage
        FROM "26xxx_wold50m"."26xxx_zonage_rgid" zrgid                      -- Source : zonage recalé, polygones unitaires
    ) t
),
points_uniques AS (
    -- Suppression des points strictement identiques (par anneau), avec conservation de l’ordre
    SELECT DISTINCT ON (path1[1], path2[1], geom)                           -- Valeurs uniques par polygone, anneau et coordonnées
           ARRAY[
               path1[1],                                                    -- ID du polygone
               path2[1],                                                    -- ID de l’anneau
               ROW_NUMBER() OVER (
                   PARTITION BY path1[1], path2[1] 
                   ORDER BY path2[2]                                        -- Ordre initial du point dans l’anneau
               )
           ] AS path,                                                       -- Chemin structuré : [polygone, anneau, rang du point]
           ST_SetSRID(geom, 2154)::geometry(Point, 2154) AS geom            -- Géométrie typée Point avec SRID EPSG:2154
    FROM point_zonage                                                       -- Source : Résultat de la requête point_zonage
)
SELECT *                                                                    -- Toutes les données
FROM points_uniques;                                                        -- Source : Résultat de la requête points_uniques
COMMIT;

CREATE INDEX IF NOT EXISTS sidx_26xxx_zonage_corr1_geom 
ON "26xxx_wold50m"."26xxx_zonage_corr1"
USING gist (geom);                                                          -- Index spatial GIST sur les points extraits
COMMIT;


--*------------------------------------------------------------------------------------------------------------*--
DO $$                                                                                   -- Bloc PL/pgSQL anonyme
DECLARE
    moyenne FLOAT;                                                                       -- Variable : moyenne des distances minimales
    ecart FLOAT;                                                                         -- Variable : écart-type des distances minimales
BEGIN
     -- ==========================================================
     -- Étape 1 : Calcul des statistiques globales (distances min)
     -- ==========================================================
     SELECT AVG(dist_min) AS moyenne_dist,                                               -- Moyenne des distances minimales
            STDDEV(dist_min) AS ecart_type                                               -- Écart-type des distances minimales
     INTO moyenne, ecart                                                                 -- Stockage des résultats dans variables locales
     FROM (                                                                              -- Sous-requête : distances minimales par path
           SELECT MIN(ST_Distance(z.geom, p.geom)) AS dist_min                           -- Distance minimale entre un point de zonage et un point de parcelle
           FROM "26xxx_wold50m"."26xxx_zonage_corr1" z,                                  -- Table : zonage corrigé initial
                "26xxx_wold50m"."26xxx_pts_parcelle_zu_t2" p                             -- Table : points de parcelles tampon 2
           GROUP BY z.path                                                               -- Regroupement par identifiant structuré (path)
          ) AS distances;                                                                -- Alias de la sous-requête

    RAISE NOTICE 'Moyenne = %, Écart type = %', moyenne, ecart;                          -- Affiche valeurs calculées

    -- ==========================================================
    -- Étape 2 : Bascule conditionnelle
    -- ==========================================================
    IF moyenne > ecart THEN                                                              -- Si moyenne > écart-type
       RAISE NOTICE 'Condition validée : moyenne > écart-type → on garde zonage_rg comme base'; -- Log info
       EXECUTE '                                                                         -- Début SQL dynamique
				DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr7";               -- Supprime table corr7 si déjà existante
				CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr7" AS                     -- Crée la table corr7
				SELECT *                                                                 -- Copie intégrale
				FROM "26xxx_wold50m"."26xxx_zonage_rg";                                  -- Depuis zonage_rg

				CREATE INDEX sidx_26xxx_zonage_corr7_geom                                 -- Crée index spatial
				ON "26xxx_wold50m"."26xxx_zonage_corr7"
				USING gist (geom);                                                       -- Type GiST sur colonne geom
				';
    ELSE                                                                                 -- Sinon → pipeline corr2
       RAISE NOTICE 'Condition non remplie → Exécution du pipeline zonage_corr2';        -- Log info

       -- ==========================================================
       -- Étape 3 : Pipeline corr2 → construction des points recalés
       -- ==========================================================
       EXECUTE '                                                                         -- Début SQL dynamique pipeline
				-- ==========================================================
				-- Corr2 
				-- Objectif : recalage des points
				-- ==========================================================
				DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr2";               -- Supprime la table si elle existe déjà
				
				CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr2" AS                     -- Crée une nouvelle table avec les résultats de la requête
				
				WITH
				
				-- Union des points des parcelles concernées
				points_parcelles_unifies AS (                                            -- CTE pour unifier tous les points de parcelles
				    SELECT ST_Union(geom) AS geom                                        -- Fusionne toutes les géométries en une seule
				    FROM "26xxx_wold50m"."26xxx_pts_parcelle_zu_t2"                      -- Table source des points de parcelles
				),
				
				-- Statistiques de distance entre chaque point du zonage et les points de parcelle
				stats_distances AS (                                                     -- CTE pour calculer les statistiques de distance
				    SELECT 
				        MIN(dist_min) AS dmin,                                           -- Distance minimale trouvée
				        AVG(dist_min) AS dmoyenne,                                       -- Distance moyenne calculée
				        MAX(dist_min) AS dmax                                            -- Distance maximale trouvée
				    FROM (
				        SELECT 
				            zc1.path,                                                    -- Identifiant du point de zonage
				            MIN(ST_Distance(zc1.geom, pts2.geom)) AS dist_min            -- Distance minimale vers un point de parcelle
				        FROM "26xxx_wold50m"."26xxx_zonage_corr1" zc1                    -- Points de zonage à corriger
				        JOIN "26xxx_wold50m"."26xxx_pts_parcelle_zu_t2" pts2             -- Points de parcelles de référence
				            ON ST_DWithin(zc1.geom, pts2.geom, 10)                       -- Filtre les points dans un rayon de 10 unités
				        GROUP BY zc1.path                                                -- Groupe par point de zonage
				    ) AS dist_stat                                                       -- Sous-requête pour les statistiques
				),
				
				-- Points identiques (intersections parfaites)
				points_identiques AS (                                                   -- CTE pour les points qui coïncident parfaitement
				    SELECT 
				        zc1.path,                                                        -- Identifiant du point
				        ''points_identiques''::text AS mode_recalage,                    -- Mode de correction appliqué
				        zc1.geom                                                         -- Géométrie conservée telle quelle
				    FROM "26xxx_wold50m"."26xxx_zonage_corr1" zc1                        -- Points de zonage source
				    JOIN points_parcelles_unifies ppu                                    -- Points de parcelles unifiés
				        ON ST_Intersects(zc1.geom, ppu.geom)                             -- Test d''intersection exacte
				),
				
				-- Construction des correspondances entre points du zonage et points de parcelles proches
				correspondances AS (                                                     -- CTE pour établir les correspondances point à point
				    SELECT 
				        zc1.path,                                                        -- Identifiant du point de zonage
				        ''points_proches''::text AS mode_recalage,                       -- Mode de correction pour points proches
				        zc1.geom AS geom_zonage,                                         -- Géométrie originale du zonage
				        pts2.geom AS geom_parcelle,                                      -- Géométrie du point de parcelle le plus proche
				        ST_Distance(zc1.geom, pts2.geom) AS dist,                        -- Distance entre les deux points
				        ROW_NUMBER() OVER (                                              -- Numérotation pour classer les correspondances
				            PARTITION BY zc1.path                                        -- Partitionnement par point de zonage
				            ORDER BY ST_Distance(zc1.geom, pts2.geom)                    -- Tri par distance croissante
				        ) AS rang -- Rang de proximité
				    FROM "26xxx_wold50m"."26xxx_zonage_corr1" zc1                        -- Points de zonage source
				    JOIN "26xxx_wold50m"."26xxx_pts_parcelle_zu_t2" pts2                 -- Points de parcelles cibles
				        ON ST_DWithin(zc1.geom, pts2.geom, (SELECT dmoyenne*2 FROM stats_distances)) -- Filtre par distance moyenne
				    LEFT JOIN points_identiques pi                                       -- Exclusion des points déjà identiques
				        ON zc1.path = pi.path -- Jointure sur l''identifiant
				    WHERE pi.path IS NULL -- Exclusion des points déjà traités
				),
				
				-- Application du snapping avec suppression des doublons géométriques
				points_proches AS ( -- CTE pour appliquer le snapping aux points proches
				    SELECT DISTINCT ON ( -- Suppression des doublons sur la géométrie résultante
				        ST_Snap(geom_zonage, geom_parcelle, (SELECT dmoyenne FROM stats_distances)) -- Géométrie après snapping
				    )
				        path, -- Identifiant conservé
				        mode_recalage, -- Mode de correction
				        ST_Snap(geom_zonage, geom_parcelle, (SELECT dmoyenne FROM stats_distances)) AS geom -- Application du snapping
				    FROM correspondances -- Source des correspondances
				    WHERE rang = 1 -- Seulement la correspondance la plus proche
				    ORDER BY
				        ST_Snap(geom_zonage, geom_parcelle, (SELECT dmoyenne FROM stats_distances)), -- Tri par géométrie résultante
				        path -- Puis par identifiant
				),
				
				-- Points reprojetés sur les bords de parcelles
				points_reprojetes AS ( -- CTE pour projeter les points sur les bordures
				    SELECT 
				        zc1.path, -- Identifiant du point
				        ''points_reprojetes''::text AS mode_recalage, -- Mode de correction par projection
				        ST_ClosestPoint( -- Trouve le point le plus proche sur la bordure
				            ST_Boundary(ST_MakeValid(pts0.geom)), -- Bordure de la parcelle validée
				            zc1.geom -- Point de zonage à projeter
				        ) AS geom -- Nouvelle position projetée
				    FROM "26xxx_wold50m"."26xxx_zonage_corr1" zc1 -- Points de zonage source
				    JOIN "26xxx_wold50m"."26xxx_pts_parcelle_zu_t0" pts0 -- Parcelles (polygones)
				        ON ST_DWithin(zc1.geom, ST_Boundary(pts0.geom), (SELECT dmoyenne FROM stats_distances)) -- Distance à la bordure
				        OR ST_Intersects( -- Ou intersection avec buffer
				            ST_Buffer(zc1.geom, (SELECT dmoyenne FROM stats_distances)), -- Zone tampon autour du point
				            ST_Boundary(pts0.geom) -- Bordure de parcelle
				        )
				    LEFT JOIN points_identiques pi ON zc1.path = pi.path -- Exclusion des points identiques
				    LEFT JOIN points_proches pp ON zc1.path = pp.path -- Exclusion des points proches
				    WHERE pi.path IS NULL AND pp.path IS NULL -- Points non encore traités
				),
				
				-- Reprojection vers intersections de bordures
				points_reprojetes_proches AS ( -- CTE pour affiner la projection vers les intersections
				    SELECT 
				        pr.path, -- Identifiant du point
				        ''points_reprojetes_proches''::text AS mode_recalage, -- Mode de correction affiné
				        COALESCE( -- Utilise la première valeur non nulle
				            (
				                SELECT ST_ClosestPoint( -- Point le plus proche sur l''intersection
				                    ST_Intersection( -- Intersection entre bordures
				                        ST_Boundary(zrgid.geom), -- Bordure du zonage rigide
				                        ST_Boundary(pts0.geom) -- Bordure de parcelle
				                    ),
				                    pr.geom -- Point reprojeté initial
				                )
				                FROM "26xxx_wold50m"."26xxx_zonage_rgid" zrgid -- Zonage rigide de référence
				                JOIN "26xxx_wold50m"."26xxx_pts_parcelle_zu_t0" pts0 -- Parcelles
				                    ON ST_Intersects(ST_Boundary(zrgid.geom), ST_Boundary(pts0.geom)) -- Bordures qui s''intersectent
				                WHERE ST_DWithin( -- Dans le rayon de distance moyenne
				                    pr.geom, -- Point reprojeté
				                    ST_Intersection(ST_Boundary(zrgid.geom), ST_Boundary(pts0.geom)), -- Intersection des bordures
				                    (SELECT dmoyenne FROM stats_distances) -- Distance seuil
				                )
				                ORDER BY ST_Distance( -- Tri par distance
				                    pr.geom, -- Point source
				                    ST_Intersection(ST_Boundary(zrgid.geom), ST_Boundary(pts0.geom)) -- Intersection cible
				                )
				                LIMIT 1 -- Premier résultat seulement
				            ),
				            pr.geom -- Valeur par défaut : position reprojetée initiale
				        ) AS geom -- Géométrie finale
				    FROM points_reprojetes pr -- Points reprojetés précédemment
				),
				
				-- Points internes aux parcelles
				points_internes AS ( -- CTE pour les points à l''intérieur des parcelles
				    SELECT 
				        zc1.path, -- Identifiant du point
				        ''points_internes''::text AS mode_recalage, -- Mode pour points internes
				        zc1.geom -- Géométrie conservée
				    FROM "26xxx_wold50m"."26xxx_zonage_corr1" zc1 -- Points de zonage
				    JOIN "26xxx_wold50m"."26xxx_pts_parcelle_zu_t0" pts0 -- Parcelles (polygones)
				        ON ST_Contains(pts0.geom, zc1.geom) -- Point contenu dans la parcelle
				        AND ST_DWithin(zc1.geom, ST_Boundary(pts0.geom), (SELECT dmax/2 FROM stats_distances)) -- Proche de la bordure
				    LEFT JOIN points_identiques pi ON zc1.path = pi.path -- Exclusion des points identiques
				    LEFT JOIN points_proches pp ON zc1.path = pp.path -- Exclusion des points proches
				    LEFT JOIN points_reprojetes_proches prp ON zc1.path = prp.path -- Exclusion des points reprojetés
				    WHERE pi.path IS NULL AND pp.path IS NULL AND prp.path IS NULL -- Points non encore traités
				),
				
				-- Snapping large
				points_proches2 AS ( -- CTE pour snapping avec tolérance élargie
				    SELECT 
				        zc1.path, -- Identifiant du point
				        ''points_proches2''::text AS mode_recalage, -- Mode de snapping élargi
				        ST_Snap( -- Application du snapping
				            zc1.geom, -- Point de zonage
				            pts2.geom, -- Point de parcelle cible
				            (SELECT dmax/2 FROM stats_distances) -- Tolérance élargie (demi distance max)
				        ) AS geom -- Nouvelle position
				    FROM "26xxx_wold50m"."26xxx_zonage_corr1" zc1 -- Points de zonage
				    JOIN "26xxx_wold50m"."26xxx_pts_parcelle_zu_t2" pts2 -- Points de parcelles
				        ON ST_DWithin(zc1.geom, pts2.geom, (SELECT dmax/2 FROM stats_distances)) -- Dans le rayon élargi
				        AND NOT ST_DWithin(zc1.geom, pts2.geom, (SELECT dmoyenne FROM stats_distances)) -- Mais pas dans le rayon normal
				    LEFT JOIN points_identiques pi ON zc1.path = pi.path -- Exclusions multiples
				    LEFT JOIN points_proches pp ON zc1.path = pp.path
				    LEFT JOIN points_reprojetes_proches prp ON zc1.path = prp.path
				    LEFT JOIN points_internes pi2 ON zc1.path = pi2.path
				    WHERE pi.path IS NULL AND pp.path IS NULL AND prp.path IS NULL AND pi2.path IS NULL -- Points non traités
				),
				
				-- Reprojection large
				points_reprojetes2 AS ( -- CTE pour reprojection avec tolérance élargie
				    SELECT 
				        zc1.path, -- Identifiant du point
				        ''points_reprojetes_2''::text AS mode_recalage, -- Mode de reprojection élargie
				        ST_ClosestPoint(ST_Boundary(pts0.geom), zc1.geom) AS geom -- Projection sur bordure la plus proche
				    FROM "26xxx_wold50m"."26xxx_zonage_corr1" zc1 -- Points de zonage
				    JOIN "26xxx_wold50m"."26xxx_pts_parcelle_zu_t0" pts0 -- Parcelles
				        ON ST_DWithin(zc1.geom, ST_Boundary(pts0.geom), (SELECT dmax/2 FROM stats_distances)) -- Dans le rayon élargi
				        AND NOT ST_DWithin(zc1.geom, ST_Boundary(pts0.geom), (SELECT dmoyenne FROM stats_distances)) -- Mais pas normal
				    LEFT JOIN points_identiques pi ON zc1.path = pi.path -- Exclusions multiples
				    LEFT JOIN points_proches pp ON zc1.path = pp.path
				    LEFT JOIN points_reprojetes_proches prp ON zc1.path = prp.path
				    LEFT JOIN points_internes pi2 ON zc1.path = pi2.path
				    LEFT JOIN points_proches2 pp2 ON zc1.path = pp2.path
				    WHERE pi.path IS NULL AND pp.path IS NULL AND prp.path IS NULL AND pi2.path IS NULL AND pp2.path IS NULL -- Points non traités
				),
				
				-- Points non recalés
				points_non_recales AS ( -- CTE pour les points qui ne peuvent pas être recalés
				    SELECT DISTINCT 
				        zc1.path, -- Identifiant du point
				        ''points_non_recales''::text AS mode_recalage, -- Mode pour points non modifiés
				        zc1.geom -- Géométrie originale conservée
				    FROM "26xxx_wold50m"."26xxx_zonage_corr1" zc1 -- Points de zonage
				    JOIN "26xxx_wold50m"."26xxx_zonage_rgid" zrgid -- Zonage rigide de référence
				        ON NOT ST_Contains(ST_Buffer(zrgid.geom, (SELECT dmax/2 FROM stats_distances)), zc1.geom) -- Point hors zone tampon
				    LEFT JOIN ( -- Union de tous les points déjà recalés
				        SELECT path FROM points_identiques
				        UNION ALL SELECT path FROM points_proches
				        UNION ALL SELECT path FROM points_reprojetes_proches
				        UNION ALL SELECT path FROM points_internes
				        UNION ALL SELECT path FROM points_proches2
				        UNION ALL SELECT path FROM points_reprojetes2
				    ) AS points_recales ON zc1.path = points_recales.path -- Jointure avec points traités
				    WHERE points_recales.path IS NULL -- Seulement les points non encore traités
				),
				
				-- Union de tous les points recalés
				points_final AS ( -- CTE finale combinant tous les résultats
				    SELECT * FROM points_identiques -- Points identiques
				    UNION ALL SELECT * FROM points_proches -- Points proches avec snapping
				    UNION ALL SELECT * FROM points_reprojetes_proches -- Points reprojetés précis
				    UNION ALL SELECT * FROM points_internes -- Points internes conservés
				    UNION ALL SELECT * FROM points_proches2 -- Points avec snapping élargi
				    UNION ALL SELECT * FROM points_reprojetes2 -- Points reprojetés élargi
				    UNION ALL SELECT * FROM points_non_recales -- Points non modifiés
				)
				
				-- Résultat final : 1 seule ligne par identifiant
				SELECT DISTINCT ON (path) * -- Suppression des doublons par identifiant
				FROM points_final; -- Source finale combinée
				
				-- Index spatial
				CREATE INDEX sidx_26xxx_zonage_corr2_geom -- Création d''un index spatial
				ON "26xxx_wold50m"."26xxx_zonage_corr2" -- Sur la table créée
				USING gist (geom); -- Utilisant la méthode GiST pour les géométries
				
				-- ==========================================================
				-- Corr3 (filtrage et simplification)
				-- Objectif : éliminer doublons, reconstruire anneaux fermés
				-- ==========================================================
				DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr3";                              -- Supprime corr3 si déjà existante
				
				CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr3" AS                                    -- Crée la table corr3
				WITH 
				    points_filtres AS (                                                                 -- Filtrage des points recalés
				        SELECT 
				            path[1] AS id_polygon,                                                      -- Identifiant polygone
				            path[2] AS id_ring,                                                         -- Identifiant anneau
				            path[3] AS id_point,                                                        -- Identifiant point
				            geom                                                                        -- Géométrie brute
				        FROM "26xxx_wold50m"."26xxx_zonage_corr2"                                       -- Source : corr2
				        WHERE mode_recalage NOT IN (''points_parcelles_non_recales'')                   -- Exclut points non pertinents
				    ),
				
				    points_dedoubles AS (                                                               -- Déduplication stricte
				        SELECT DISTINCT ON (id_polygon, id_ring, id_point)                              -- Garde un seul point par clé unique
				            id_polygon, id_ring, id_point, geom                                         -- Colonnes conservées
				        FROM points_filtres                                                             -- Source : points filtrés
				        ORDER BY id_polygon, id_ring, id_point                                          -- Ordre déterministe
				    ),
				
				    anneaux_lignes AS (                                                                 -- Construction de lignes
				        SELECT 
				            id_polygon,                                                                 -- Identifiant polygone
				            id_ring,                                                                    -- Identifiant anneau
				            ST_MakeLine(geom ORDER BY id_point) AS ligne,                               -- Chaîne les points en ligne ordonnée
				            COUNT(*) AS nb_points                                                       -- Nombre de points par anneau
				        FROM points_dedoubles                                                           -- Source : points uniques
				        GROUP BY id_polygon, id_ring                                                    -- Regroupement
				        HAVING COUNT(*) >= 3                                                            -- Minimum 3 points pour former un anneau
				    ),
				
				    anneaux_fermes AS (                                                                 -- Fermeture des anneaux
				        SELECT 
				            id_polygon,                                                                 -- Identifiant polygone
				            id_ring,                                                                    -- Identifiant anneau
				            CASE 
				                WHEN ST_IsClosed(ligne) THEN ligne                                      -- Si déjà fermé → garder
				                ELSE ST_AddPoint(ligne, ST_StartPoint(ligne))                           -- Sinon → ajouter premier point à la fin
				            END AS geom                                                                 -- Résultat : anneau fermé
				        FROM anneaux_lignes                                                             -- Source : lignes anneaux
				    )
					SELECT 
					    id_polygon,                                                                         -- Identifiant polygone
					    id_ring,                                                                            -- Identifiant anneau
					    ST_SetSRID(geom, 2154) AS geom                                                      -- Force SRID 2154
					FROM anneaux_fermes;                                                                    -- Source : anneaux fermés
					
					CREATE INDEX sidx_26xxx_zonage_corr3_geom                                               -- Nom de l’index spatial
					ON "26xxx_wold50m"."26xxx_zonage_corr3"                                                 -- Table cible
					USING gist (geom);                                                                      -- Index de type GiST sur géométrie


             		-- ==========================================================
					-- Corr4 : recalage avec ajout de points manquants et réindexation                 
					-- ==========================================================
					DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr4";                             -- Supprime la table si elle existe déjà
					
					CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr4" AS                                   -- Crée la table corr4
					WITH 
					stats_distances2 AS (                                                                  -- Calcul des statistiques de distances mises à jour
					    SELECT 
					        MIN(dist_min2) AS dmin2,                                                       -- Distance minimale
					        AVG(dist_min2) AS dmoyenne2,                                                   -- Distance moyenne
					        MAX(dist_min2) AS dmax2                                                       -- Distance maximale
					   FROM (                                                                              -- Sous-requête pour distances minimales par point
					        SELECT 
					            zc2.path,                                                                  -- Identifiant du point du zonage
					            MIN(ST_Distance(zc2.geom, pts2.geom)) AS dist_min2                         -- Distance minimale avec les points de parcelles
					        FROM "26xxx_wold50m"."26xxx_zonage_corr2" zc2                                  -- Source : points du zonage recalés corr2
					        JOIN "26xxx_wold50m"."26xxx_pts_parcelle_zu_t2" pts2                           -- Source : points de parcelles
					          ON ST_DWithin(zc2.geom, pts2.geom, 10)                                       -- Filtrage spatial : voisinage à 10 mètres
					        GROUP BY zc2.path                                                              -- Agrégation par identifiant de point
					    ) AS dist_stat                                                                     -- Alias de la sous-requête
					),
					
					points_zonage_existants AS (                                                           -- Points déjà présents dans corr2
					    SELECT path, mode_recalage, geom                                                   -- Sélectionne identifiant, mode et géométrie
					    FROM "26xxx_wold50m"."26xxx_zonage_corr2"                                          -- Source : table corr2
					),
					
					points_parcelles_proches_limites AS (                                                  -- Points de parcelles proches des limites de corr3
					    SELECT DISTINCT ON (pts2.geom)                                                     -- Évite doublons géométriques sur les points ajoutés
					           zc3.id_polygon,                                                             -- Identifiant polygone
					           zc3.id_ring,                                                                -- Identifiant anneau
					           pts2.geom,                                                                  -- Géométrie du point de parcelle
					           ''points_parcelles_proches_limites''::text AS mode_recalage                 -- Mode de recalage attribué
					    FROM "26xxx_wold50m"."26xxx_pts_parcelle_zu_t2" pts2                               -- Source : points de parcelles
					    JOIN "26xxx_wold50m"."26xxx_zonage_corr3" zc3                                      -- Source : anneaux issus de corr3
					      ON ST_DWithin(pts2.geom, zc3.geom, (SELECT dmoyenne2*1 FROM stats_distances2))   -- Condition de proximité élargie
					    WHERE NOT EXISTS (                                                                 -- Exclusion : évite doublons avec corr2
					        SELECT 1 
					        FROM points_zonage_existants pze
					        WHERE ST_DWithin(pts2.geom, pze.geom, 0.01)                                     -- Distance de 0.1 m considérée comme identique
					    )
					    ORDER BY pts2.geom, ST_Distance(pts2.geom, zc3.geom)                               -- Trie par géométrie et proximité
					),
					
					points_union AS (                                                                      -- Union des points existants et nouveaux
					    SELECT path[1] AS id_polygon, path[2] AS id_ring, path[3] AS id_point, geom, mode_recalage -- Décompose path en colonnes
					    FROM points_zonage_existants                                                       -- Partie : points existants
					    UNION ALL                                                                          -- Concaténation sans suppression des doublons
					    SELECT id_polygon, id_ring, NULL::int AS id_point, geom, mode_recalage             -- Partie : points nouveaux (id_point à réattribuer)
					    FROM points_parcelles_proches_limites                                              -- Source : points des parcelles proches
					),
					
					points_reindexes AS (                                                                  -- Réindexation ordonnée des points le long des anneaux
					    SELECT 
					        pu.id_polygon,                                                                 -- Identifiant polygone
					        pu.id_ring,                                                                    -- Identifiant anneau
					        ROW_NUMBER() OVER (                                                            -- Numérotation séquentielle
					            PARTITION BY pu.id_polygon, pu.id_ring                                     -- Partition par polygone et anneau
					            ORDER BY ST_LineLocatePoint(zc3.geom, pu.geom)                             -- Classement selon position le long de la ligne de corr3
					        ) AS id_point,                                                                 -- Nouvel identifiant de point
					        pu.geom,                                                                       -- Géométrie recalée
					        pu.mode_recalage                                                               -- Mode de recalage
					    FROM points_union pu                                                               -- Source : union des points
					    JOIN "26xxx_wold50m"."26xxx_zonage_corr3" zc3                                      -- Source : anneaux issus de corr3
					      ON pu.id_polygon = zc3.id_polygon                                                -- Appariement sur identifiant polygone
					     AND pu.id_ring    = zc3.id_ring                                                   -- Appariement sur identifiant anneau
					)
					
					SELECT                                                                                 -- Résultat final : table corr4
					    ARRAY[id_polygon, id_ring, id_point] AS path,                                      -- Reconstruit le path hiérarchique
					    mode_recalage,                                                                     -- Mode de recalage utilisé
					    geom                                                                               -- Géométrie corrigée
					FROM points_reindexes                                                                  -- Source : points réindexés
					ORDER BY id_polygon, id_ring, id_point;                                                -- Trie par identifiants pour stabilité

					CREATE INDEX sidx_26xxx_zonage_corr4_geom                                               -- Nom de l’index spatial
					ON "26xxx_wold50m"."26xxx_zonage_corr4"                                                 -- Table cible
					USING gist (geom);                                                                      -- Index de type GiST sur géométrie


             		-- ==========================================================
					-- Corr5 : reconstruction surfacique à partir des path corrigés de corr4              
					-- ==========================================================
					DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr5";                             -- Supprime la table corr5 si elle existe déjà
					
					CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr5" AS                                   -- Crée la table corr5
					WITH 
					anneaux AS (                                                                           -- Construction des anneaux fermés à partir des points de corr4
					    SELECT 
					        path[1] AS id_polygon,                                                         -- Identifiant du polygone
					        path[2] AS id_ring,                                                            -- Identifiant de l’anneau
					        CASE                                                                           -- Vérifie si l’anneau est déjà fermé
					            WHEN ST_IsClosed(ST_MakeLine(geom ORDER BY path[3]))                       -- Si fermé naturellement
					            THEN ST_MakeLine(geom ORDER BY path[3])                                    -- Conserve la ligne telle quelle
					            ELSE ST_AddPoint(                                                          -- Sinon ajoute le premier point à la fin
					                     ST_MakeLine(geom ORDER BY path[3]),                               -- Ligne construite par les points triés
					                     ST_StartPoint(ST_MakeLine(geom ORDER BY path[3]))                 -- Premier point repris pour fermeture
					                 )
					        END AS ligne                                                                   -- Géométrie de l’anneau fermé
					    FROM "26xxx_wold50m"."26xxx_zonage_corr4"                                          -- Source : points réindexés de corr4
					    GROUP BY path[1], path[2]                                                          -- Regroupe par polygone et anneau
					    HAVING COUNT(*) >= 3                                                               -- Condition : au moins trois points pour former un anneau
					),
					
					polygones AS (                                                                         -- Transformation des anneaux en polygones
					    SELECT 
					        id_polygon,                                                                    -- Identifiant polygone
					        id_ring,                                                                       -- Identifiant anneau
					        ST_MakeValid(ST_MakePolygon(ligne)) AS geom                                    -- Crée le polygone puis corrige sa validité
					    FROM anneaux                                                                       -- Source : anneaux fermés
					),
					
					multi AS (                                                                             -- Agrégation des polygones en multipolygones
					    SELECT 
					        id_polygon,                                                                    -- Identifiant polygone
					        ST_Multi(                                                                      -- Convertit en MultiPolygon
					            ST_CollectionExtract(                                                      -- Extrait uniquement les objets surfaciques
					                ST_BuildArea(ST_Collect(geom)), 3                                      -- Fusionne les polygones et extrait le type Polygon
					            )
					        )::geometry(MultiPolygon, 2154) AS geom                                        -- Définit le type final en MultiPolygon SRID 2154
					    FROM polygones                                                                     -- Source : polygones unitaires
					    GROUP BY id_polygon                                                                -- Regroupement par polygone
					)
					
					SELECT * FROM multi;                                                                   -- Résultat final : table corr5
					
					CREATE INDEX sidx_26xxx_zonage_corr5_geom                                              -- Création d’un index spatial GiST
					ON "26xxx_wold50m"."26xxx_zonage_corr5"                                                -- Table cible corr5
					USING gist (geom);                                                                     -- Index spatial optimisé pour la géométrie


             		-- ==========================================================
					-- Corr7 : union finale en un seul MultiPolygon                                      
					-- ==========================================================
					
					DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zonage_corr7";                              -- Supprime corr7 si elle existe déjà
					
					CREATE TABLE "26xxx_wold50m"."26xxx_zonage_corr7" AS                                    -- Crée la table corr7
					SELECT ST_SetSRID(                                                                      -- Attribue le SRID 2154 au résultat
					         ST_Multi(                                                                      -- Convertit en MultiPolygon
					           ST_Union(                                                                    -- Union spatiale de toutes les géométries
					             ST_CollectionExtract(ST_MakeValid(geom), 3)                                -- Nettoie les géométries et extrait uniquement les polygones (type 3)
					           )
					         ), 2154                                                                        -- Système de coordonnées Lambert-93 (EPSG:2154)
					       )::geometry(MultiPolygon,2154) AS geom                                           -- Définit le type explicitement
					FROM "26xxx_wold50m"."26xxx_zonage_corr5";                                              -- Source : table corr5
					
					CREATE INDEX IF NOT EXISTS sidx_26xxx_zonage_corr7_geom                                 -- Crée un index spatial si absent
					ON "26xxx_wold50m"."26xxx_zonage_corr7" 
					USING gist (geom);';                                                                      -- Index GiST pour optimiser les opérations spatiales

    END IF;
END
$$;


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----                                             PARTIE V                                                     ----
----                  ZONES TAMPONS ET INTERSECTIONS ENTRE COMPTES COMMUNAUX                                  ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                              ----
---- - Identifier les zones de recouvrement entre les tampons de 50 m autour des bâtiments.                   ----
---- - Repérer les cas où deux comptes communaux distincts partagent une zone tampon commune.                 ----
---- - Retirer des tampons les parties situées en zones urbaines, qui ne sont pas soumises aux OLD.           ----
---- - Nettoyer et fusionner les zones restantes pour obtenir un périmètre final d’arbitrage.                 ----
--*------------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                   ----
----                                                                                                          ----
---- - **Détection des intersections de tampons** :                                                           ----
----   - Chaque tampon de 50 m (autour des groupes de bâtiments par compte communal) est comparé aux autres.  ----
----   - Les cas où deux tampons se croisent, appartenant à des comptes communaux différents, sont extraits.  ----
----   - Le test ST_DWithin (0.01) évite les faux positifs liés à des artefacts géométriques.                 ----
----   - Seules les intersections ayant une surface > 1 m² sont conservées.                                   ----
----                                                                                                          ----
---- - **Retrait des zones urbaines des tampons croisés** :                                                   ----
----   - Les zones d’intersection sont croisées avec le zonage corrigé (zonage_corr7).                        ----
----   - Si elles chevauchent une zone urbaine, la partie urbaine est soustraite (ST_Difference).             ----
----   - Si aucune intersection avec une zone urbaine : la géométrie est conservée telle quelle.              ----
----   - La validité des géométries est systématiquement assurée (ST_MakeValid + ST_CollectionExtract).       ----
----                                                                                                          ----
---- - **Regroupement final** :                                                                               ----
----   - Toutes les zones restantes sont fusionnées spatialement.                                             ----
----   - Les petites pièces ou fragments sont intégrés en un seul MultiPolygon cohérent.                      ----
--*------------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                     ----
---- - Zones d’intersection entre tampons de bâtiments de comptes communaux différents.                       ----
---- - Zones d’intersection nettoyées des parties en zones urbaines.                                          ----
---- - Zone finale fusionnée pour usage dans des arbitrages de responsabilité OLD inter-propriétaires.        ----
--*------------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                             ----
---- - **ST_DWithin (0.01)** : tolérance de 1 cm pour détecter les intersections réelles, sans erreurs dues à ----
----   la précision flottante des géométries.                                                                 ----
---- - **ST_Intersection** : permet d’isoler précisément les surfaces partagées entre deux tampons.           ----
---- - **ST_Difference** : supprime uniquement les portions en zone urbaine, pour éviter les traitements      ----
----   injustifiés dans des périmètres non soumis aux OLD.                                                    ----
---- - **ST_MakeValid + ST_CollectionExtract (3)** : garantit que seules des géométries polygonales valides   ----
----   sont utilisées, ce qui évite les erreurs lors des fusions et analyses suivantes.                       ----
---- - **ST_Union + ST_Multi** : fusionne l’ensemble des zones tampon nettoyées en une entité unique prête    ----
----   pour l’analyse ou la cartographie finale.                                                              ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

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
SELECT  t.comptecomm1,                                     -- N° de compte communal du premier tampon
        t.comptecomm2,                                     -- N° de compte communal du second tampon
        ST_Multi(                                          -- Convertit la géométrie résultante en **MultiPolygon**
           ST_Union(                   				    -- Fusionne pour éviter les petits polygones isolés
              ST_MakeValid(         					    -- Corrige les géométries invalides
                 ST_Difference(     					    -- Garde uniquement la partie qui ne s'intersecte pas
                    ST_CollectionExtract(                  -- Extrait uniquement les polygones (type 3)
                       ST_MakeValid(t.geom),               -- Corrige les géométries invalides du zonage
                       3),
                    ST_CollectionExtract(                  -- Extrait uniquement les polygones (type 3)
                       ST_MakeValid(z7.geom),              -- Corrige les géométries invalides du zonage
                       3))))                               -- Corrige les géométries invalides du zonage
        ) AS geom                                          -- Géométrie résultante
FROM "26xxx_wold50m"."26xxx_tampon_i" AS t                 -- Source : zones tampons corrigées 
JOIN "26xxx_wold50m"."26xxx_zonage_corr7" AS z7            -- Source : zone urbaine
ON ST_Intersects(t.geom, z7.geom)                          -- Appliquer la soustraction uniquement si les géométries se recouvrent
WHERE ST_Area(ST_Difference(t.geom, z7.geom)) > 0
GROUP BY  t.comptecomm1, t.comptecomm2, t.geom, z7.geom

UNION ALL                                                  -- Combine les résultats des tampons ayant subi la soustraction et des tampons non affectés par les zones urbaines

-- Conserver les géométries sans intersection
SELECT t.comptecomm1,                                      -- N° de compte communal du premier tampon
       t.comptecomm2,                                      -- N° de compte communal du second tampon
       ST_Multi(                                           -- Convertit la géométrie résultante en **MultiPolygon**
		   ST_CollectionExtract(                           -- Extrait les **polygones** (type 3) 
		      ST_MakeValid(t.geom),                        -- Conserve la géométrie initiale des tampons non impactés et valides
	   3)) AS geom                                         -- Géométrie résultante
FROM "26xxx_wold50m"."26xxx_tampon_i" AS t                 -- Source : zones tampons corrigées 
WHERE NOT EXISTS (                                         -- Vérifie qu'il n'y a **pas d'intersection** avec des zones urbaines
      SELECT 1 
      FROM "26xxx_wold50m"."26xxx_zonage_corr7" AS z7      -- Source : zone urbaine
      WHERE ST_Intersects(t.geom, z7.geom));               -- Aucun recouvrement avec des zones urbaines
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
SELECT ST_Multi(                                            -- Convertit la géométrie résultante en **MultiPolygon**
		   ST_CollectionExtract(                            -- Extrait les **polygones** (type 3) 
		      ST_Union(                                     -- Regroupe les géométries en les fusionnant
				 ST_MakeValid(t.geom)),                     -- Rend valide les géométries
		3)) AS geom                                         -- Géométries fusionnées pour former une entité unique
FROM "26xxx_wold50m"."26xxx_tampon_ihu" AS t;               -- Source : zones tampons corrigées après exclusion des zones urbaines
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
----                                             PARTIE VI                                                   ----
----                                  GESTION DU PARCELLAIRE BÂTI                                            ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Identifier les parcelles cadastrales contenant un bâtiment situé dans la zone de débroussaillement    ----
----   (OLD 200 mètres autour des massifs forestiers > 0,5 ha).                                              ----
---- - Regrouper ces parcelles par compte communal afin d’individualiser les obligations de débroussaillement----
----   par propriétaire foncier.                                                                             ----
---- - Exclure les parcelles ne contenant aucun bâtiment ou situées hors de la zone OLD pour optimiser le    ----
----   périmètre des traitements.                                                                            ----
---- - Isoler les cas où des parcelles bâties sont situées dans des zones de recouvrement entre tampons      ----
----   de bâtiments appartenant à plusieurs comptes communaux différents.                                    ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
----                                                                                                         ----
---- - **Parcelles bâties intersectées (`parcelle_batie`)** :                                                ----
----   - Croisement spatial entre les bâtiments situés dans la zone OLD et les parcelles cadastrales.        ----
----   - Conservation uniquement des entités partageant un même compte communal pour éviter les erreurs      ----
----     d'alignement.                                                                                       ----
----   - Fusion des géométries des parcelles concernées avec ST_Union, pour simplifier les contours.         ----
----                                                                                                         ----
---- - **Fusion des parcelles bâties par compte communal (`parcelle_batie_u`)** :                            ----
----   - Regroupement par compte communal, avec transformation en MultiPolygon valide.                       ----
----   - Nettoyage géométrique systématique : ST_MakeValid → ST_CollectionExtract → ST_Multi.                ----
----                                                                                                         ----
---- - **Sélection des parcelles concernées par les arbitrages (`parcelle_batie_ihu`)** :                    ----
----   - Croisement des parcelles bâties avec les tampons inter-comptes corrigés.                            ----
----   - Conservation des seules parcelles dont le compte communal apparaît dans une zone tampon             ----
----     en conflit (signal d’un chevauchement foncier possible).                                            ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Liste des parcelles cadastrales contenant des bâtiments OLD, filtrée par compte communal.             ----
---- - Fusion de ces parcelles par propriétaire pour obtenir des emprises nettes.                            ----
---- - Identification des parcelles bâties impliquées dans un chevauchement entre tampons de comptes         ----
----   distincts (pré-arbitrage foncier).                                                                    ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_Intersects : permet d’associer précisément bâtiment et parcelle via leur emprise réelle.           ----
---- - ST_Union : fusionne les géométries redondantes au sein d’un même compte pour faciliter l’analyse.     ----
---- - ST_MakeValid + ST_CollectionExtract + ST_Multi : garantissent l’homogénéité géométrique du résultat   ----
----   et évitent les erreurs dans les traitements postérieurs.                                              ----
---- - Croisement avec les tampons inter-comptes : isole les cas où plusieurs propriétaires sont             ----
----   potentiellement en situation de responsabilité partagée, à traiter dans les arbitrages.               ----
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
SELECT p.comptecommunal AS comptecommunal,                    -- Numéro du compte communal
	   p.geo_parcelle,                                        -- Numéro de parcelles
	   p.idu,                                                 -- Identifiant des parcelles
       ST_Union(p.geom) AS geom                               -- Fusion des géométries des parcelles
FROM "26xxx_wold50m"."26xxx_parcelle" p                       -- Source : Parcelles cadastrales
INNER JOIN "26xxx_wold50m"."26xxx_bati200_cc_rg" b            -- Source : Bâtiments
ON ST_Intersects(p.geom, b.geom)                              -- Condition : le bâtiment est contenu dans la parcelle
WHERE p.comptecommunal = b.comptecommunal                     -- Condition : quand compte communaux égaux
GROUP BY p.comptecommunal, p.geo_parcelle, p.idu;             -- Regrouper par compte communal
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
SELECT comptecommunal,                                        -- Compte communal associé à la parcelle
       ST_Multi(                                              -- Convertit en Multipolygon
	      ST_CollectionExtract(                               -- Extrait seulement les type 3 : Polygon
			 ST_MakeValid(                                    -- Corrige les géométries invalides
				ST_Union(geom)),                              -- Regroupe et fusionne les géométries
	   3)) AS geom                                            -- Géométrie résultante
FROM "26xxx_wold50m"."26xxx_parcelle_batie"                   -- Source : Parcelles et bâtiments fusionnés
GROUP BY comptecommunal;                                      -- Regroupe uniquement par compte communal
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
SELECT DISTINCT p.*                                             -- Inclut toutes les colonnes des parcelles sans doublons
FROM "26xxx_wold50m"."26xxx_parcelle_batie_u" AS p              -- Source : Parcelles contenant des bâtiments
JOIN "26xxx_wold50m"."26xxx_tampon_ihu" AS t                    -- Source : Zones tampons corrigées pour les arbitrages
ON p.comptecommunal = t.comptecomm1;                            -- Condition : Correspondance des comptes communaux
COMMIT;  

CREATE INDEX "idx_26xxx_parcelle_batie_ihu_geom" 
ON "26xxx_wold50m"."26xxx_parcelle_batie_ihu"
USING gist (geom); 
COMMIT; 


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----                                       PARTIE VII :                                                       ----
----                                     UNITÉS FONCIÈRES                                                     ----
----                                                                                                          ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                              ----
---- - Regrouper les parcelles cadastrales contiguës appartenant à un même propriétaire en une seule unité    ----
----   foncière, identifiée par son compte communal.                                                          ----
---- - Produire une couche spatiale homogène, typée MultiPolygon, représentant les emprises foncières         ----
----   consolidées.                                                                                           ----
---- - Préparer une table de référence fiable pour l’analyse des responsabilités foncières et des zones       ----
----   d’obligation de débroussaillement (OLD).                                                               ----
--*------------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                   ----
---- - Sélection des entités issues de la table cadastrale `geo_unite_fonciere` pour la commune 26xxx         ----
----   via filtre sur les 6 premiers caractères du compte communal.                                           ----
---- - Agrégation des géométries des unités foncières par compte communal avec ST_Union.                      ----
---- - Nettoyage géométrique systématique : correction des invalidités (ST_MakeValid), extraction des         ----
----   polygones (ST_CollectionExtract), conversion en MultiPolygon (ST_Multi).                               ----
---- - Projection en Lambert 93 (SRID 2154) et indexation spatiale pour améliorer les performances.           ----
--*------------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                     ----
---- - Une couche consolidée des unités foncières par compte communal, prête à être croisée avec les          ----
----   autres couches (bâtiments, parcelles bâties, zones OLD, etc.).                                         ----
--*------------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                             ----
---- - ST_Union : fusionne toutes les parcelles contiguës d’un même propriétaire pour produire une emprise    ----
----   unique.                                                                                                ----
---- - ST_MakeValid : garantit la validité topologique des géométries issues des unions.                      ----
---- - ST_CollectionExtract(type 3) : supprime les artefacts non polygonaux générés lors des unions.          ----
---- - ST_Multi : homogénéise le format de sortie en MultiPolygon pour garantir la compatibilité des          ----
----   traitements suivants.                                                                                  ----
---- - Filtrage LEFT(comptecommunal, 6) = '260xxx' : sélection précise de la commune INSEE 26xxx.             ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--


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
SELECT uf1.comptecommunal,                                   -- N° du compte communal associé aux unités foncières
	    ST_SetSRID(                                           -- Définit le SRID en 2154 (RGF93 / Lambert-93)
	        ST_Multi(                                         -- Convertit en MultiPolygon
	            ST_CollectionExtract(                          -- Extrait seulement les types 3 : Polygon
	                ST_MakeValid(                              -- Corrige les géométries invalides
	                    ST_Union(uf2.geom)                    -- Fusionne les géométries de uf2 (geo_unite_fonciere)
	                ),
	            3)),                                          -- Extrait uniquement les polygones (type 3)
	        2154) AS geom                                      -- Définit le SRID pour la géométrie (Lambert-93)
FROM r_cadastre.geo_unite_fonciere1 uf1                     -- Source 1 : unités foncières de la table geo_unite_fonciere1
LEFT JOIN r_cadastre.geo_unite_fonciere uf2                     -- Source 2 : unités foncières de la table geo_unite_fonciere
ON uf1.comptecommunal = uf2.comptecommunal               -- Jointure sur le compte communal
WHERE LEFT(uf1.comptecommunal, 6) = '260xxx'                -- Filtre : uniquement les unités foncières de la commune 260xxx
GROUP BY uf1.comptecommunal;                                   -- Regroupe les géométries par compte communal
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

---- Création de la table "26xxx_ufr_bati" : intersections entre unités foncières et parcelles bâties de la commune 26xxx.

-- Description : Cette table identifie les zones bâties à l’intérieur des unités foncières,
--               en croisant les géométries des unités foncières avec celles des parcelles
--               où se trouvent des bâtiments (issues de la table "26xxx_parcelle_batie_u").
--               Seules les entités ayant le même numéro de compte communal sont conservées.
--               → Attributs : géométrie MultiPolygon (2154), numéro du compte communal associé.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ufr_bati";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ufr_bati" AS
SELECT uf.comptecommunal,                                 -- N° du compte communal des unités foncières
       ST_Multi(                                          -- Convertit en MultiPolygon
	      ST_MakeValid(                                   -- Corrige les géométries invalides
	         ST_Intersection(uf.geom, pb.geom)            -- Prend uniquement la partie commune (intersection)
	   )) AS geom
FROM "26xxx_wold50m"."26xxx_ufr" AS uf                    -- Source : Unités foncières
LEFT JOIN "26xxx_wold50m"."26xxx_parcelle_batie_u" pb     -- Source : Parcelles où est construit un bâtiment
ON  ST_Intersects(uf.geom, pb.geom)                       -- Condition spatiale : sélectionne uniquement les zones qui se croisent
WHERE uf.comptecommunal = pb.comptecommunal;              -- Filtre : comptes communaux identiques
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

--     FROM "26xxx_wold50m"."26xxx_parcelle_batie_ihu" p -- Source : Parcelles-bâties concernées par les arbitrages
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
----                                             PARTIE IX                                                   ----
----                           ARBITRAGE DES RESPONSABILITES OLD PAR PROPRIETAIRE                            ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Déterminer les zones de débroussaillement hors zonage U autour des bâtiments.                         ----
---- - Identifier les empiètements de ces zones sur les propriétés de comptes communaux voisins.             ----
---- - Séparer ce qui relève du propriétaire d’origine de ce qui doit être partagé ou arbitré.               ----
---- - Répartir équitablement les zones partagées en fonction de la position spatiale des bâtiments.         ----
---- - Nettoyer et fusionner les géométries finales à attribuer à chaque compte communal.                    ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - Génération des tampons de 50 m autour des bâtiments, hors zone U.                                     ----
---- - Croisement avec les unités foncières pour vérifier la propriété réelle du sol.                        ----
---- - Extraction des zones empiétant sur les unités foncières de voisins (comptecomm2 ≠ comptecomm1).       ----
---- - Soustraction des zones déjà prises en charge par le propriétaire 1.                                   ----
---- - Découpage Voronoï sur les contours de parcelles pour répartir les responsabilités en cas de partage.  ----
---- - Attribution des portions de superposition à chaque propriétaire selon leur aire d’influence.          ----
---- - Nettoyage topologique (tampons, snapping, suppressions d’artefacts), typage homogène.                 ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Une couche géographique par compte communal, contenant uniquement les zones OLD à débroussailler,     ----
----   hors zone urbaine, après exclusion des parties non cadastrées et arbitrage spatial Voronoï.           ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_Difference : exclusion rigoureuse des zones déjà traitées ou urbanisées.                           ----
---- - ST_Intersection : détection des conflits fonciers par recouvrement entre tampons et unités foncières. ----
---- - ST_VoronoiPolygons : découpage neutre des zones partagées à partir des distances aux bâtiments.       ----
----   → chaque bâtiment “rayonne” jusqu’au milieu du chemin vers les autres, formant une division équitable.----
---- - ST_Buffer ±0.01 : lissage des contours pour retirer les irrégularités géométriques (épines, bavures). ----
---- - ST_RemoveRepeatedPoints + ST_Snap : suppression des points inutiles et réalignement localisé.         ----
---- - ST_Union + ST_MakeValid + ST_CollectionExtract : fusion robuste, nettoyage topologique et typage 
----   homogène.                                                                                             ----
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

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t4";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t4" AS
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
								
DELETE FROM "26xxx_wold50m"."26xxx_b1_t4"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom); 
COMMIT; 
				
CREATE INDEX idx_26xxx_b1_t4_geom 
ON "26xxx_wold50m"."26xxx_b1_t4"
USING gist (geom);
COMMIT;
				
-----------------------------
-- Regroupement des zones de superposition à débroussailler par chaque voisin.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t5";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t5" AS
SELECT 
	b4.comptecomm1 AS comptecommunal,        -- N° du compte communal principal
	ST_SetSRID(                              -- Définit le système de coordonnées EPSG:2154
		ST_Multi(                            -- Convertit en MultiPolygon
			ST_CollectionExtract(            -- Extrait uniquement les géométries de type 3 (Polygone)
				ST_MakeValid(                -- Corrige les géométries invalides
					ST_Union(b4.geom)),      -- Regroupe les géométries en une seule entité
				3)),
		2154) AS geom                        -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t4" b4        -- Source : zones qui appartiennent à un voisin tenu de les débroussailler
GROUP BY b4.comptecomm1;                     -- Regroupe par compte communal
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_b1_t5"
WHERE geom IS NULL 
OR ST_IsEmpty(geom)  
OR NOT ST_IsValid(geom); 
COMMIT; 
				
CREATE INDEX "idx_26xxx_b1_t5_geom" 
ON "26xxx_wold50m"."26xxx_b1_t5"
USING gist (geom);
COMMIT;
				
-----------------------------
-- Intersection entre les 50 m hors zone U appartenant au propriétaire 1 et son unité foncière regroupée.
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t6";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t6" AS
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
				
DELETE FROM "26xxx_wold50m"."26xxx_b1_t6"
WHERE geom IS NULL
OR ST_IsEmpty(geom)
OR NOT ST_IsValid(geom);
COMMIT; 
 
CREATE INDEX idx_26xxx_b1_t6_geom 
ON "26xxx_wold50m"."26xxx_b1_t6"
USING gist (geom);
COMMIT;

-----------------------------
-- Regroupement des zones de superposition appartenant au propriétaire 1 par compte communal.
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t7";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t7" AS
SELECT
	b6.comptecommunal,                       -- N° de compte communal du propriétaire 1
		ST_SetSRID(                          -- Définit le système de coordonnées EPSG:2154
			ST_Multi(                        -- Convertit en MultiPolygon
				ST_CollectionExtract(        -- Extrait uniquement les géométries de type 3 (Polygone)
					ST_MakeValid(            -- Corrige les géométries invalides
						ST_Union(b6.geom)),  -- Regroupe les géométries en une seule entité
					3)),
		2154) AS geom                        -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t6" b6        -- Source : zones de superposition appartenant au propriétaire 1 avec cc
GROUP BY b6.comptecommunal;                  -- Regroupe par compte communal
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_b1_t7"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 
				
CREATE INDEX "idx_26xxx_b1_t7_geom" 
ON "26xxx_wold50m"."26xxx_b1_t7"
USING gist (geom);
COMMIT;

-----------------------------
-- Union des zones à débrousailler par le propriétaire 1 et par le voisin.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t8";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t8" AS
SELECT 
	COALESCE(b5.comptecommunal,b7.comptecommunal) AS comptecommunal,
	CASE 
	  -- 1er cas : les deux tables "26xxx_b1_t5" et "26xxx_b1_t7" existent
		WHEN b5.comptecommunal IS NOT NULL		  -- Filtre : Vérifie l'existence
		AND b7.comptecommunal IS NOT NULL         -- Filtre : Vérifie l'existence
		THEN
			ST_SetSRID(                           -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                           -- Convertit en MultiPolygon
				ST_CollectionExtract(             -- Extrait uniquement les géométries de type 3 (Polygone)
				  ST_MakeValid(                   -- Corrige les géométries invalides
					ST_Union(                     -- Fusionne les géométries des deux couches
					  ST_MakeValid(b5.geom),      -- Corrige les géométries invalides
					  ST_MakeValid(b7.geom))),    -- Corrige les géométries invalides
				  3)),
			  2154)
				
	  -- 2e cas : seule la table "26xxx_b1_t5" existe
		WHEN b5.comptecommunal IS NOT NULL		  -- Filtre : Vérifie l'existence
		THEN b5.geom
				
  -- 3e cas : seule la table "26xxx_b1_t7" existe
		WHEN b7.comptecommunal IS NOT NULL        -- Filtre : Vérifie l'existence
		THEN b7.geom  
		END AS geom                               -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t7" b7        	  -- Source : zones à débroussailler par le propriétaire 1
FULL OUTER JOIN "26xxx_wold50m"."26xxx_b1_t5" b5  -- Source : zones à débroussailler par le voisin
ON b5.comptecommunal = b7.comptecommunal;
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
-- Soustraction des zones de superposition ayant les deux communaux par les zones à débroussailler 
-- par le propriétaire 1 : zones de superposition à débroussailler également par un autre propriétaire.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t9";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t9" AS
SELECT
	b1.comptecomm1,                                 -- N° du compte communal 1
	b1.comptecomm2,                                 -- N° du compte communal 2
	CASE 
	-- 1er cas : des données existent dans la table "26xxx_b1_t8"
		WHEN b8.comptecommunal IS NOT NULL         -- Filtre : Vérifie l'existence
		THEN
			ST_SetSRID(                             -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                             -- Convertit en MultiPolygon
				ST_MakeValid(                       -- Corrige les géométries invalides
				  ST_Union(
					 ST_MakeValid(                  -- Corrige les géométries invalides
						ST_CollectionExtract(
						  ST_Difference(            -- Calcule la différence géométrique entre les zones de superposition et les zones à débroussailler par le propriétaire 1
							ST_MakeValid(b1.geom),  -- Corrige les géométries invalides
							ST_MakeValid(b8.geom)),
						  3))))),
			  2154)                      

	-- 2e cas : aucune donnée dans la table "26xxx_b1_t8"
		ELSE b1.geom
		END AS geom                                 -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t1" b1               -- Source : zones de superposition
FULL OUTER JOIN "26xxx_wold50m"."26xxx_b1_t8" b8
ON b1.comptecomm1 = b8.comptecommunal
GROUP BY b1.comptecomm1, b1.comptecomm2, b8.comptecommunal, b1.geom, b8.geom;
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
-- Nettoyage de la couche 26xxx_b1_t9
DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t10";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t10" AS
WITH
	-- 1) Épuration des épines externes 
	--	 aller retour avec 3 noeuds disctincts alignés
	--   supprime le noeud de l'extrémité 
epine_externe AS (
    SELECT
	b9.comptecomm1,                            -- N° du compte communal 1
	b9.comptecomm2,                               -- N° du compte communal 2
	ST_SetSRID(                                    -- Définit le système de coordonnées EPSG:2154
	  ST_Multi(                                   -- Convertit en MultiPolygon
		 ST_CollectionExtract(                     -- Extrait uniquement les géométries de type 3
			ST_MakeValid(
			  ST_Snap(                              -- Aligne le tampon de la géométrie sur la géométrie d'origine
				ST_RemoveRepeatedPoints(
				  ST_Buffer(
					b9.geom, 
					-0.0001,                        -- Ajout d'un tampon négatif de l'ordre de 10 nm
					'join=mitre mitre_limit=5.0'),  -- 
				  0.0003),			              -- Suppression des noeuds consécutifs proches de plus de 30 nm
				b9.geom,
				0.0006)),3)),                       -- Avec une distance d'accrochage de l'ordre de 60 nm
	  2154) AS geom                               -- Géométries résultantes
	FROM "26xxx_wold50m"."26xxx_b1_t9" b9           -- Source : 
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
			  b9.geom,
			  0.0006)),3)),                       -- Avec une distance d'accrochage de l'ordre de 60 nm
	  2154) AS geom                               -- Géométries résultantes
	FROM epine_externe epext                          -- Source : Zones à débroussailler hors et dans la zone urbaine régroupées par compte communal et corrigées sans épines extérieures
	JOIN "26xxx_wold50m"."26xxx_b1_t9" b9
	ON epext.comptecomm1 = b9.comptecomm1
	AND epext.comptecomm2 = b9.comptecomm2
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
	
DELETE FROM "26xxx_wold50m"."26xxx_b1_t10" 
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

CREATE INDEX "idx_26xxx_b1_t10_geom"  
ON "26xxx_wold50m"."26xxx_b1_t10"
USING gist (geom);  
COMMIT; 

-----------------------------
-- Regroupement des zones de superposition à débroussailler également par un autre propriétaire corrigées.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t11";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t11" AS
SELECT
	b10.comptecomm1,                     -- N° du compte communal
	ST_SetSRID(                          -- Définit le système de coordonnées EPSG:2154
		ST_Multi(                        -- Convertit en MultiPolygon
			ST_CollectionExtract(        -- Extrait uniquement les géométries de type 3 
				ST_MakeValid(            -- Corrige les géométries invalides
					ST_Union(b10.geom)), -- Fusionne les géométries en une seule
				3)),
		2154) AS geom                    -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t10" b10  -- Source : zones de superposition à débroussailler par un autre propriétaire
GROUP BY b10.comptecomm1;                -- Regroupe par compte communal
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_b1_t11" 
WHERE geom IS NULL  
OR ST_IsEmpty(geom)  
OR NOT ST_IsValid(geom);

CREATE INDEX "idx_26xxx_b1_t11_geom"  
ON "26xxx_wold50m"."26xxx_b1_t11"
USING gist (geom);  
COMMIT; 
			
-----------------------------
-- Découpe des zones de superposition d'obligation à débroussailler par le propriétaire 1 hors zone urbaine.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t12";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t12" AS
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
				
DELETE FROM "26xxx_wold50m"."26xxx_b1_t12" 
WHERE geom IS NULL  
OR ST_IsEmpty(geom)  
OR NOT ST_IsValid(geom);
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t12_geom"  
ON "26xxx_wold50m"."26xxx_b1_t12"
USING gist (geom);  
COMMIT; 

-----------------------------
-- Intersection entre les polygones de Voronoï et les zones de superposition également à 
-- débroussailler par un autre propriétaire : zones de superposition ayant plusieurs propriétaires
-- attribuées au propriétaire 1.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t13";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t13" AS
SELECT
	b10.comptecomm1,                           -- N° du compte communal principal
	ST_SetSRID(                                -- Définit le système de coordonnées EPSG:2154
	  ST_Multi(                                -- Convertit en MultiPolygon
		ST_CollectionExtract(                  -- Extrait uniquement les géométries de type 3
		  ST_MakeValid(                        -- Corrige les géométries invallides
			ST_Intersection(                   -- Calcule l'intersection des géométries
			  ST_MakeValid(b10.geom),
			  ST_MakeValid(v.geom))),
		  3)),
	  2154) AS geom                            -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t11" b10        -- Source : zones de superposition à débroussailler par un autre propriétaire
JOIN "26xxx_wold50m"."26xxx_voronoi_cc_rg" v   -- Source : polygones Voronoï regroupé par cc
ON v.comptecommunal = b10.comptecomm1          -- Condition : comptes communaux identiques
WHERE ST_Intersects(b10.geom, v.geom);         -- Condition : uniquement les géométries qui s'intersectent
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
-- Regroupement des zones de superposition corrigées ayant plusieurs propriétaires attribuées au propriétaire 1.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t14";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t14" AS
SELECT
	b13.comptecomm1 AS comptecommunal,   -- N° du compte communal principal
	ST_SetSRID(                          -- Définit le système de coordonnées EPSG:2154
	  ST_Multi(                          -- Convertit en MultiPolygon
		ST_CollectionExtract(            -- Extrait uniquement les géométries de type 3
		  ST_MakeValid(                  -- Corrige les géométries invalides
			ST_Union(                    -- Fusionne les géométries en une seule
			  ST_MakeValid(b13.geom))),  -- Corrige les géométries invalides
		  3)),
	  2154) AS geom                      -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t13" b13  -- Source : zones de Voronoi uniquement à débroussailler par le propriétaire 1 corrigées
GROUP BY b13.comptecomm1;                -- Regroupe par compte communal
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_b1_t14"  
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t14_geom"  
ON "26xxx_wold50m"."26xxx_b1_t14"
USING gist (geom);  
COMMIT; 

-----------------------------
-- Union des zones sans superpositions d'obligation à débroussailler par le propriétaire 1 et des 
-- zones de superposition regroupées appartenant au propriétaire 1 : zones sans et avec 
-- superpositions d'obligation à débroussailler par le propriétaire 1.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t15";        -- Supprime la table cible si elle existe déjà

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t15" AS                    -- Crée une nouvelle table avec les résultats de la requête
WITH s7 AS (                                                      -- Déclare une première CTE "s7" basée sur la table b1_t7
  SELECT 
    REPLACE(TRIM(comptecommunal),' ','') AS comptecommunal, -- Supprime espaces avant/après et enlève les espaces internes dans l'identifiant
    ST_SetSRID(                                             -- Attribue le système de coordonnées EPSG:2154
      ST_Multi(                                             -- Transforme en MultiPolygon
        ST_CollectionExtract(                               -- Ne conserve que les géométries de type polygone (3)
          ST_MakeValid(geom),                               -- Corrige les géométries invalides
        3)                                                  -- Spécifie qu’on garde les polygones
      ), 2154                                               -- Définit le code EPSG du système de coordonnées
    ) AS geom                                               -- Nom de la colonne géométrique nettoyée
  FROM "26xxx_wold50m"."26xxx_b1_t7"                        -- Source des zones de superposition
),

s12 AS (                                                    -- Déclare une deuxième CTE "s12" basée sur la table b1_t12
  SELECT 
    REPLACE(TRIM(comptecomm1),' ','') AS comptecommunal,    -- Nettoie la clé de la même manière que pour s7
    ST_SetSRID(                                             -- Attribue le système de coordonnées EPSG:2154
      ST_Multi(                                             -- Transforme en MultiPolygon
        ST_CollectionExtract(                               -- Ne conserve que les polygones (type 3)
          ST_MakeValid(geom),                               -- Corrige les géométries invalides
        3)                                                  -- Spécifie qu’on garde les polygones
      ), 2154                                               -- Définit le code EPSG du système de coordonnées
    ) AS geom                                               -- Nom de la colonne géométrique nettoyée
  FROM "26xxx_wold50m"."26xxx_b1_t12"                       -- Source des zones sans superposition
),

src AS (                                                    -- Troisième CTE qui fusionne s7 et s12
  SELECT * FROM s7                                          -- Récupère toutes les colonnes de s7
  UNION ALL                                                 -- Ajoute toutes les lignes de s12 (y compris doublons)
  SELECT * FROM s12                                         -- Récupère toutes les colonnes de s12
)

SELECT 
  comptecommunal,                                           -- Identifiant communal
  ST_UnaryUnion(ST_Collect(geom)) AS geom                   -- Dissout toutes les géométries du même compte en une seule
FROM src                                                    -- Source = les deux CTE fusionnées
GROUP BY comptecommunal;                                    -- Regroupe les résultats par identifiant communal

COMMIT;                                                     -- Valide la création de la table

DELETE FROM "26xxx_wold50m"."26xxx_b1_t15"                  -- Supprime de la table les géométries indésirables
WHERE geom IS NULL                                          -- Cas où la géométrie est nulle
   OR ST_IsEmpty(geom)                                      -- Cas où la géométrie est vide
   OR NOT ST_IsValid(geom);                                 -- Cas où la géométrie est invalide
COMMIT;                                                     -- Valide la suppression

CREATE INDEX "idx_26xxx_b1_t15_geom"                        -- Crée un index spatial pour accélérer les requêtes
ON "26xxx_wold50m"."26xxx_b1_t15" USING GIST (geom);        -- Index de type GIST sur la colonne geom
COMMIT;                                                     -- Valide la création de l’index


-----------------------------
-- Union des zones de superposition corrigées, regroupées ayant plusieurs propriétaires  
-- attribuées aupropriétaire 1 et des zones sans et avec superpositions d'obligation 
-- corrigées à débroussailler par le propriétaire 1 : Zones finales à débroussailler par
-- le propriétaire 1 hors zone urbaine

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t16";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t16" AS
SELECT 
	COALESCE(b14.comptecommunal,b15.comptecommunal) AS comptecommunal,
	CASE 
	-- 1er cas : Les deux tables "26xxx_b1_t14" et "26xxx_b1_t15" existent
		WHEN b14.comptecommunal IS NOT NULL       -- Filtre : Vérifie l'existence des résultats
		AND b15.comptecommunal IS NOT NULL        -- Filtre : Vérifie l'existence des résultats
		THEN
			ST_SetSRID(                           -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                           -- Convertit en MultiPolygon
				ST_CollectionExtract(             -- Extrait uniquement les géométries de type 3
				  ST_MakeValid(                   -- Corrige les géométries invalides
					ST_Union(                     -- Fusionne les géométries entre elles
					  ST_MakeValid(b15.geom),     -- Corrige les géométries invalides
						ST_MakeValid(b14.geom))), -- Corrige les géométries invalides
				  3)),
			  2154)
				
	 -- 2e cas : Seule la table "26xxx_b1_t15" existe
		WHEN b15.comptecommunal IS NOT NULL          -- Filtre : Vérifie l'existence des résultats
		THEN b15.geom
					
	-- 3e cas : Seule la table "26xxx_b1_t14" existe
		WHEN b14.comptecommunal IS NOT NULL          -- Filtre : Vérifie l'existence des résultats
		THEN b14.geom
		END AS geom                                  -- Géométries résultantes 
FROM "26xxx_wold50m"."26xxx_b1_t14" b14              -- Source : zones de superposition corrigées ayant plusieurs propriétaires attribuées au propriétaire 1 regroupées
FULL OUTER JOIN "26xxx_wold50m"."26xxx_b1_t15" b15   -- Source : zones sans et avec superpositions d'obligation corrigées à débroussailler par le propriétaire 1
ON b14.comptecommunal = b15.comptecommunal;
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
-- Intersection des unités foncières regroupées et du zonage urbain : 
-- Parties d'unité foncière de chaque propriétaire en zone U, baties ou non baties

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t17";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t17" AS
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
			
DELETE FROM "26xxx_wold50m"."26xxx_b1_t17"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT; 

CREATE INDEX "idx_26xxx_b1_t17_geom"  
ON "26xxx_wold50m"."26xxx_b1_t17"
USING gist (geom);  
COMMIT; 

				
-----------------------------
-- Union entre les unités foncières du propriétaire 1 en zu et les zones de superposition à débroussailler 
-- par le même propriétaire : zones totales à débroussailler par le propriétaire 1 

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t18";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t18" AS
SELECT
	COALESCE(b17.comptecommunal, b16.comptecommunal) AS comptecommunal, -- Sélectionne l'un ou l'autre compte communal,
	CASE 
	-- Cas où les deux tables contiennent des données
		WHEN b17.comptecommunal IS NOT NULL 
		AND b16.comptecommunal IS NOT NULL 
		THEN
			ST_SetSRID(                              -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                              -- Convertit en MultiPolygon
				ST_CollectionExtract(                -- Extrait uniquement les géométries de type 3
				  ST_MakeValid(                      -- Corrige les géométries invalides
					ST_Union(                        -- Fusionne les géométries	
					  ST_MakeValid(b16.geom),        -- Corrige les géométries invalides
					  ST_MakeValid(b17.geom))),      -- Corrige les géométries invalides
				  3)),
			  2154) 
				
	-- Cas où seule la table "26xxx_b1_t17" contient des données
		WHEN b17.comptecommunal IS NOT NULL 
		THEN b17.geom
				
	-- Cas où seule la table "26xxx_b1_t16" contient des données
		WHEN b16.comptecommunal IS NOT NULL 
		THEN b16.geom
				
	-- Sinon résultat null
		ELSE NULL                                    -- Aucun résultat valide
		END AS geom                                  -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t17" b17              -- Source : unité foncière du propriétaire 1 en zone U
FULL OUTER JOIN "26xxx_wold50m"."26xxx_b1_t16" b16   -- Jointure complète externe avec les zones de superposition après arbitrage ayant des cc
ON b17.comptecommunal = b16.comptecommunal;          -- Condition : comptes communaux identiques
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
-- Suppression des zones non cadastrées des zones totales à débroussailler par le propriétaire 1.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t19";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t19" AS
SELECT
	b18.comptecommunal,                              -- N° du compte communal
	CASE 
	-- Cas où la géométrie intersecte une zone non cadastrée, soustrait la zone non cadastrée
		WHEN ST_Intersects(b18.geom, nc.geom) 
	    THEN
			ST_SetSRID(                              -- Définit le système de coordonnées EPSG:2154
			  ST_Multi(                              -- Convertit en MultiPolygon
				ST_MakeValid(
				  ST_Union(
					ST_CollectionExtract(            -- Extrait uniquement les géométries de type 3
					  ST_MakeValid(
						ST_Difference(               -- Supprime la zone non cadastrée
						  ST_MakeValid(b18.geom),    -- Corrige les géométries invalides
						  ST_MakeValid(nc.geom))),
					  3)))),
			  2154)                                 
	
	-- Cas où aucune intersection n'existe, garde la géométrie d'origine
	    ELSE b18.geom
		END AS geom                                  -- Géométries résultantes
FROM "26xxx_wold50m"."26xxx_b1_t18" b18              -- Source : zones totales à débroussailler par le propriétaire 1 
LEFT JOIN "26xxx_wold50m"."26xxx_non_cadastre" nc    -- Source : zones non cadastrées
ON ST_Intersects(b18.geom, nc.geom)                  -- Condition : intersection entre  les zones non cadastrées
GROUP BY b18.comptecommunal, b18.geom, nc.geom;
COMMIT; 

DELETE FROM "26xxx_wold50m"."26xxx_b1_t19"  
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom); 
COMMIT;
				
CREATE INDEX "idx_26xxx_b1_t19_geom"  
ON "26xxx_wold50m"."26xxx_b1_t19"
USING gist (geom);  
COMMIT; 

-----------------------------
-- Correction des zones totales à débroussailler par le propriétaire 1 non cadastrées.

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_b1_t20";

CREATE TABLE "26xxx_wold50m"."26xxx_b1_t20" AS
WITH
	-- 1) Épuration des épines externes 
	--	 aller retour avec 3 noeuds disctincts alignés
	--   supprime le noeud de l'extrémité 
epine_externe AS (
    SELECT
		b19.comptecommunal,                        -- N° de compte communal
		ST_SetSRID(                                -- Définit le système de coordonnées EPSG:2154
		  ST_Multi(                                -- Convertit en MultiPolygon
			ST_CollectionExtract(                  -- Extrait uniquement les géométries de type 3
			  ST_MakeValid(
				ST_Snap(                           -- Aligne le tampon de la géométrie sur la géométrie d'origine
				  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  b19.geom, 
					  -0.0001,                     -- Ajout d'un tampon négatif de l'ordre de 0,1 mm
					  'join=mitre mitre_limit=5.0'), 
					0.0003),			           -- Suppression des noeuds consécutifs proches de plus de 0,3 mm
				  b19.geom,
				   0.0006)),3)),                   -- Avec une distance d'accrochage de l'ordre de 0,6 mm
		  2154) AS geom                            -- Géométries résultantes
	FROM "26xxx_wold50m"."26xxx_b1_t19" b19            -- Source : 
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
				  b19.geom,
				  0.0006)),3)),                    -- Avec une distance d'accrochage de l'ordre de 0,6 mm
		  2154) AS geom                            -- Géométries résultantes
	FROM epine_externe epext                           -- Source : Zones à débroussailler hors et dans la zone urbaine régroupées par compte communal et corrigées sans épines extérieures
	JOIN "26xxx_wold50m"."26xxx_b1_t19" b19
	ON epext.comptecommunal = b19.comptecommunal
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
	
DELETE FROM "26xxx_wold50m"."26xxx_b1_t20" 
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

CREATE INDEX "idx_26xxx_b1_t20_geom"  
ON "26xxx_wold50m"."26xxx_b1_t20"
USING gist (geom);  
COMMIT;
                                                                       

--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                                  PARTIE X                                               ----
----                                ZONES FINALES À DÉBROUSSAILLER PAR PROPRIÉTAIRE                          ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Regrouper, pour chaque propriétaire (comptecommunal), toutes les surfaces bâties à débroussailler.    ----
---- - Inclure à la fois les surfaces situées en zone urbaine (sur unité foncière) et hors zone U (zone OLD).----
---- - Supprimer toutes les zones non cadastrées ainsi que les artefacts géométriques (épines, trous, etc.). ----
---- - Générer une géométrie propre, valide, et consolidée par propriétaire, au format MultiPolygon 2154.    ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - Fusion des surfaces bâties hors zone U et des parties d’unités foncières situées en zone U.           ----
---- - Soustraction des zones non cadastrées pour limiter les surfaces à la propriété connue.                ----
---- - Nettoyage géométrique rigoureux (double tampon, suppression de doublons, snapping).                   ----
---- - Conversion en MultiPolygon et reprojection dans le système de projection Lambert 93 (EPSG:2154).     ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Pour chaque compte communal : une géométrie MultiPolygon (2154) valide, composée uniquement des       ----
----   surfaces bâties soumises à l’obligation légale de débroussaillement, situées soit dans les zones      ----
----   urbaines (parties bâties d’unités foncières), soit dans les zones OLD hors zonage U, après nettoyage. ----
---- - Une géométrie unique (fusion de l’ensemble des comptes communaux) représentant toutes les surfaces    ----
----   bâties conservées après exclusion des zones non cadastrées et correction topologique complète.        ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_ForceCollection : garantit la compatibilité de typage pour les extractions géométriques.           ----
---- - ST_CollectionExtract : isole les polygones pour éviter les entités parasites (Line, Point, etc.).     ----
---- - ST_MakeValid : élimine les défauts topologiques empêchant les traitements en aval.                    ----
---- - ST_Union : fusionne toutes les entités concernées, par propriétaire ou globalement.                   ----
---- - ST_Multi + ST_SetSRID : impose un typage homogène MultiPolygon et la projection officielle 2154.      ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_result1" : Zones finales à débroussailler par le propriétaire 1, toutes situations 
---- confondues.
-- Description : Cette table rassemble les **zones à débroussailler finales** attribuées au propriétaire 1 
--               (compte communal), qu’elles soient situées **hors ou en zone urbaine**, après nettoyage, arbitrages 
--               fonciers, et suppression des artefacts (épines et zones non cadastrées). Ces surfaces sont prêtes 
--               à être cartographiées ou exportées.
--               → Attributs : comptecommunal (identifiant du propriétaire), geom (MultiPolygon, 2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_result1";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_result1" AS   -- crée une nouvelle table résultat
SELECT                                             -- début de la sélection des champs
    b20.comptecommunal,                            -- conserve l’attribut comptecommunal
    ST_SetSRID(                                    -- assigne le système de coordonnées EPSG:2154
        ST_Multi(                                  -- force le résultat en MultiPolygon
            ST_CollectionExtract(                  -- extrait uniquement les polygones (type 3)
                    ST_MakeValid(                  -- corrige les géométries invalides
                        ST_Intersection(ST_MakeValid(b20.geom), ST_MakeValid(o.geom))   -- calcule l’intersection avec old200m
                    ), 
                3)                                 -- type 3 = Polygone
        ),
        2154) AS geom                              -- définit la SRID et nomme la colonne géométrie
FROM "26xxx_wold50m"."26xxx_b1_t20" b20            -- table source des géométries initiales
JOIN public.old200m o                              -- jointure avec la couche de découpe old200m
  ON ST_Intersects(b20.geom, o.geom);              -- ne garde que les objets qui s’intersectent
COMMIT;                                            -- valide la transaction

CREATE INDEX idx_26xxx_result1_geom 
ON "26xxx_wold50m"."26xxx_result1"
USING gist (geom);
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_result1_rg" : Zones bâties à débroussailler hors zone U et en zone urbaine, fusionnées.

-- Description : Cette table regroupe en une seule entité géographique l’ensemble des **zones bâties à débroussailler**
--               du propriétaire 1, situées **hors zone urbaine** et **dans le zonage urbain corrigé**, après nettoyage
--               complet. Le résultat est un **MultiPolygon unique** par commune, prêt à être exporté ou affiché.
--               → Attributs : geom (MultiPolygon, 2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_result1_rg";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_result1_rg" AS
SELECT ST_Multi(                                       -- Convertit en MultiPolygon 
         ST_Union(                                     -- Fusionne toutes les géométries en une seule entité 
             ST_RemoveRepeatedPoints(                  -- Supprime les sommets trop rapprochés (moins de 3 cm) pour nettoyer la topologie
               ST_MakeValid(r1.geom),                  -- Corrige les géométries invalides selon les règles de validité OGC
               0.01                                    -- Tolérance pour la suppression des points dupliqués : 3 cm
             ))) AS geom                               -- Géométrie résultante
FROM "26xxx_wold50m"."26xxx_result1" r1                -- Source : Résultat intermédiaires des zones à débroussailler
WHERE ST_Area(r1.geom) > 0;                            -- Condition de filtre : on ne traite que les géométries ayant une aire strictement positive
COMMIT;

DELETE FROM "26xxx_wold50m"."26xxx_result1_rg"                                 
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                   
OR NOT ST_IsValid(geom);                                                
COMMIT;                                                                     

CREATE INDEX idx_26xxx_result1_rg_geom                           
ON "26xxx_wold50m"."26xxx_result1_rg"                            
USING gist (geom);                                               
COMMIT;                                                          


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ---- 
----                                             PARTIE 5 :                                                  ----
----                        DÉTECTION ET EXTRACTION DES ZONES NON COUVERTES (TROUS)                          ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Détecter les portions de tampon de 50 m autour des bâtiments situées hors zone urbaine                ----
----   qui n'ont été prises en compte dans aucune zone de débroussaillement validée.                         ----
---- - Supprimer les zones non cadastrées de ces surfaces pour isoler uniquement les lacunes cadastrales.    ----
---- - Extraire chaque entité polygonale restante et mesurer sa surface pour permettre un filtrage ultérieur.----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - **Calcul des zones non couvertes** :                                                                  ----
----     - Soustraction géométrique entre les tampons hors zone urbaine et les zones de débroussaillement    ----
----       déjà fusionnées, avec correction et typage MultiPolygon.                                          ----
---- - **Nettoyage cadastral** :                                                                             ----
----     - Retrait des zones situées hors périmètre cadastral à l’aide d’une différence géométrique entre    ----
----       les zones non couvertes et les entités non cadastrées.                                            ----
---- - **Extraction unitaire et mesure** :                                                                   ----
----     - Décomposition des multipolygones restants pour obtenir des polygones simples, chacun doté         ----
----       de son identifiant et de sa surface réelle.                                                       ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Polygones non couverts issus des tampons, situés uniquement dans le périmètre cadastral.              ----
---- - Surface connue pour chaque polygone résiduel, permettant tri ou exclusion par seuil.                  ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_Difference : isole les zones ignorées en comparant le tampon brut et les zones validées.           ----
---- - ST_MakeValid + ST_CollectionExtract + ST_Multi : standardisent la géométrie pour garantir un          ----
----   traitement fiable, sans erreurs de type ou de structure.                                              ----
---- - ST_Dump : décompose chaque multipolygone en polygones simples distincts.                              ----
---- - ST_Area : fournit une mesure de surface pour évaluer l’importance de chaque zone résiduelle.          ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_trou1" : Zones restantes non couvertes à l’intérieur des tampons hors zone U.

-- Description : Cette table calcule, pour chaque zone tampon autour des bâtiments situés hors zone urbaine, les parties
--               qui ne sont **pas couvertes** par les zones à débroussailler déjà consolidées (`result1_rg`).
--               Le but est de détecter des **zones oubliées ou exclues**, souvent issues de petites erreurs de jointure.
--               → Attributs : geom (MultiPolygon, 2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_trou1";
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_trou1" AS
SELECT ST_SetSRID(                                                      -- Définit le système de projection EPSG:2154
          ST_Multi(                                                     -- Convertit en MultiPolygon
             ST_CollectionExtract(                                      -- Extrait uniquement les polygones (type 3)
                ST_MakeValid(                                           -- Corrige les géométries invalides
                   ST_Difference(                                       -- Calcule les zones des tampons non couvertes
	                  ST_MakeValid(t_ihu.geom),                         -- Corrige les géométries invalides   
	                  ST_MakeValid(r1rg.geom))),                        -- Corrige les géométries invalides       
	            3)),                                                    
       2154) AS geom                                                    -- Géométrie résultante
FROM "26xxx_wold50m"."26xxx_tampon_ihu_rg" t_ihu                        -- Source : tampons autour des bâtiments (hors zone urbaine)
JOIN "26xxx_wold50m"."26xxx_result1_rg" r1rg                            -- Source : zones à débroussailler consolidées (résultat global)
ON ST_Intersects(t_ihu.geom, r1rg.geom)                                 -- Ne traite que les tampons qui intersectent les zones consolidées
WHERE t_ihu.geom IS NOT NULL                                            -- Exclut les géométries nulles
AND NOT ST_IsEmpty(t_ihu.geom)                                          -- Exclut les géométries vides
AND ST_IsValid(t_ihu.geom);                                             -- Facultatif : vérifie que les géométries d'entrée sont valides
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
               ST_Difference(                    -- Soustrait les géométries non cadastrées
			      ST_MakeValid(t.geom),          -- Corrige les géométries invalides
				  ST_MakeValid(nc.geom))),       -- Corrige les géométries invalides
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
-- Description : Cette table extrait les composants polygonaux (trous) de la couche "26xxx_trou2", les identifie 
--               par un chemin, et calcule leur surface unitaire. Le résultat est une liste de polygones 
--               indépendants, chacun avec sa surface.
--               → Attributs : path (identifiant structuré), surface (m²), geom (Polygon, 2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_trou3";
COMMIT;


CREATE TABLE "26xxx_wold50m"."26xxx_trou3" AS
SELECT d.path,                                            -- Chemin hiérarchique du polygone dans la géométrie initiale
       ST_Area(d.geom) AS surface,                        -- Surface individuelle du trou (en m²)
       d.geom                                             -- Géométrie du polygone extrait (trou)
FROM (SELECT (ST_Dump(ST_Multi(t.geom))).*                -- Décomposition explicite des MultiPolygon en polygones simples
      FROM "26xxx_wold50m"."26xxx_trou2" t) AS d;         -- Source : géométries des trous à détailler
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
----                                             PARTIE XI                                                   ----
----                        CONSOLIDATION ET ANALYSES SPATIALES DES ÎLOTS GÉOMÉTRIQUES                       ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
-- PARTIE 6 : RECONSTRUCTION DES ÎLOTS NON ATTRIBUÉS EN ZONES DE SUPERPOSITION
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Identifier les **zones de superposition** entre comptes communaux qui sont **restées non traitées**   ----
----   par les étapes de débroussaillement précédentes.                                                      ----
---- - Générer des **îlots polygonaux autonomes** dans ces zones, afin de les soumettre à une attribution    ----
----   différée ou partagée.                                                                                 ----
---- - Associer à chaque îlot la **liste exacte des comptes communaux concernés** pour appuyer un arbitrage. ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - **Intersection précise** entre les tampons des zones de superposition (`tampon_ihu`) et les **trous   ----
----    géométriques restants** (`trou3`) pour extraire uniquement les zones non couvertes situées dans des  ----
----    situations de chevauchement foncier.                                                                 ----
---- - **Nettoyage des doublons**, conversion en MultiPolygon et extraction uniquement des géométries valides----
---- - **Reconstituer les contours fermés** à partir des limites extraites, en les transformant en polygones.----
---- - **Attribution multi-comptes** : chaque polygone reconstruit est associé à tous les comptes communaux  ----
----    dont les tampons contiennent le **point central (PointOnSurface)** du polygone.                      ----
---- - **Fusion finale** par combinaison de comptes : Union des géométries en une seule entité              ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Un polygone distinct pour chaque îlot résiduel, correspondant à une zone de superposition non couverte----
---- - Pour chaque polygone, la liste complète des comptes communaux impliqués, sous forme de tableau.       ----
---- - Une table propre et consolidée, permettant une attribution claire des responsabilités de              ---- 
----   débroussaillement.                                                                                    ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - `ST_Intersection` : pour **isoler uniquement les zones non couvertes** dans les périmètres de conflit.----
---- - `ST_CollectionExtract + ST_Multi + ST_MakeValid` : garantissent que toutes les géométries sont bien   ----
----   **homogènes, valides et prêtes pour la reconstruction polygonale**.                                   ----
---- - `ST_Boundary` + `ST_Polygonize` : permettent de **reconstruire des polygones fermés** à partir des    ----
----   bords des zones résiduelles.                                                                          ----
---- - `ST_PointOnSurface + ST_Within` : lient chaque îlot au(x) compte(s) communal(aux) **de façon robuste**----
----   , même pour les géométries complexes.                                                                 ----
---- - `ARRAY_AGG(DISTINCT)` : évite les doublons de comptes lors de l’agrégation par îlot.                  ----
---- - `ST_Union` final : regroupe les géométries de chaque combinaison unique de comptes en une entité      ----
----   polygonale consolidée, **facilement visualisable et exploitable**.                                    ----
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
----                                             PARTIE XII                                                  ----
----                        ATTRIBUTION DES ÎLOTS RÉSIDUELS PAR POLYGONISATION VORONOÏ                       ----
----								                                                                          ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Répartir équitablement les zones de superposition non couvertes entre les propriétaires concernés.    ----
---- - Utiliser des polygones de Voronoï pour attribuer chaque portion de trou à un seul compte communal.    ----
---- - Intégrer les zones ainsi générées dans les surfaces finales à débroussailler par propriétaire.        ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - Interpolation régulière de points sur les bords des zones résiduelles.                                ----
---- - Génération de cellules de Voronoï à partir de ces points, découpées selon chaque îlot identifié.      ----
---- - Attribution des cellules à un compte communal par inclusion du point source.                          ----
---- - Regroupement des cellules attribuées pour chaque propriétaire.                                        ----
---- - Intersection finale avec les zones résiduelles pour obtenir les surfaces effectivement à traiter.     ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Une cellule polygonale par point interpolé, représentant une portion de trou affectée à un compte.    ----
---- - Une géométrie nette et homogène par propriétaire sur les zones non couvertes.                         ----
---- - Une répartition précise, sans chevauchement, des obligations sur les zones résiduelles partagées.     ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_VoronoiPolygons : pour découper automatiquement l’espace en zones d’influence autour de chaque     ----
----                        point.                                                                           ----
----   > Vulgarisation : chaque point rayonne dans toutes les directions jusqu’à toucher un voisin ;         ----
----     les frontières se forment à mi-distance, comme si chaque point « réclamait » son propre territoire. ----
---- - ST_Collect : pour regrouper tous les points en une géométrie MultiPoint, base de la polygonisation.   ----
---- - ST_Within : pour rattacher chaque cellule à son point source et en déduire le bon propriétaire.       ----
---- - ST_Intersection : pour découper précisément les cellules dans les contours réels des îlots.           ----
---- - ST_Union + ST_CollectionExtract : pour reconstituer des géométries propres, sans doublons ni erreurs. ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_ilot_voronoi_t1" : Polygones de Voronoï associés aux îlots de trous identifiés.

-- Description : Cette table génère des **polygones de Voronoï** à partir des **points interpolés** situés dans les îlots
--               de superpositions non couvertes. Chaque polygone est **attribué à un groupe de comptes communaux**
--               selon son appartenance spatiale à un îlot.
--               → Attributs : id (identifiant de l’îlot), liste_ncc (tableau des comptes communaux), geom (MultiPolygon, 2154)

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

---- Création de la table "26xxx_ilot_voronoi_t2" : Attribution des comptes communaux aux polygones Voronoï des trous.

-- Description : Cette table **associe chaque polygone Voronoï** issu des îlots de trous à un **compte communal**
--               à partir des **points interpolés**. Chaque polygone est donc affecté à un propriétaire précis.
--               → Attributs : id (identifiant du polygone), comptecommunal (propriétaire affecté), geom (MultiPolygon, 2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_voronoi_t2";      
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_voronoi_t2" AS
SELECT DISTINCT iv1.id,                                             -- Identifiant du polygone Voronoï (hérité de l’îlot d’origine)
       p.comptecommunal,                                            -- N° du compte communal auquel est rattachée cette portion
       ST_SetSRID(                                                  -- Définit le système de projection EPSG:2154
         ST_Multi(                                                  -- Convertit en MultiPolygon
           ST_CollectionExtract(                                    -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(iv1.geom),                                -- Corrige les géométries invalides
           3)),
       2154) AS geom                                                -- Géométrie finale résultante (MultiPolygon, 2154)
FROM "26xxx_wold50m"."26xxx_ilot_voronoi_t1" iv1                    -- Source : polygones Voronoï générés pour chaque îlot
JOIN "26xxx_wold50m"."26xxx_pt_interpol_rg" p                       -- Source : points interpolés avec leur compte communal
  ON ST_Within(p.geom, iv1.geom)                                    -- Filtre spatial : le point est contenu dans le polygone Voronoï
 AND p.comptecommunal = ANY(iv1.liste_ncc);                         -- Filtre logique : le compte du point appartient à la liste associée à l’îlot
COMMIT;

CREATE INDEX idx_26xxx_ilot_voronoi_t2_geom
ON "26xxx_wold50m"."26xxx_ilot_voronoi_t2"
USING gist (geom); 
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_ilot_voronoi_t3" : Regroupement des polygones Voronoi des zones de 
---- superpositions non couvertes par compte communal.

-- Description : Cette table regroupe les **polygones Voronoï** générés à partir des **zones de superposition non couvertes** 
--               en un seul objet géographique **MultiPolygon** par **compte communal** et par identifiant d’îlot (id).
--               Cela permet d’obtenir une vue consolidée de la part attribuée à chaque propriétaire.
--               → Attributs : id (identifiant de l’îlot), comptecommunal (propriétaire), geom (MultiPolygon, 2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_voronoi_t3";          -- Supprime la table si elle existe
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_voronoi_t3" AS
SELECT iv2.id,                                                         -- Identifiant de l’îlot Voronoï
       iv2.comptecommunal,                                             -- N° de compte communal du propriétaire
       ST_SetSRID(                                                     -- Définit le système de projection EPSG:2154
         ST_Multi(                                                     -- Convertit en MultiPolygon
           ST_CollectionExtract(                                       -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                             -- Corrige les géométries invalides
               ST_Union(iv2.geom)),                                    -- Fusionne toutes les géométries du même groupe
           3)),
       2154) AS geom                                                   -- Géométrie résultante (MultiPolygon, 2154)
FROM "26xxx_wold50m"."26xxx_ilot_voronoi_t2" iv2                       -- Source : polygones Voronoï attribués aux comptes communaux
GROUP BY iv2.id, iv2.comptecommunal;                                   -- Regroupe par identifiant d’îlot et compte communal
COMMIT;

CREATE INDEX idx_26xxx_ilot_voronoi_t3_geom                            -- Crée un index spatial pour accélérer les requêtes géographiques
ON "26xxx_wold50m"."26xxx_ilot_voronoi_t3"
USING gist (geom); 
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--
---- Création de la table "26xxx_ilot_voronoi_t4" : Découpe des polygones Voronoï avec les zones de 
---- superpositions non couvertes ayant plusieurs comptes communaux, pour extraire les zones à débroussailler 
---- par propriétaire.

-- Description : Cette table découpe chaque **polygone Voronoï** produit pour les zones de **superposition non 
--               couvertes** en intersection avec les **îlots multi-propriétaires** (`ilots_final`). Chaque portion 
--               de Voronoï est ainsi affectée à **un seul propriétaire**, permettant une attribution claire.
--               → Attributs : id (îlot initial), comptecommunal (propriétaire unique), geom (MultiPolygon, 2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_voronoi_t4";                
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_voronoi_t4" AS
SELECT iv3.id,                                                                -- Identifiant de l’îlot
       iv3.comptecommunal,                                                    -- N° de compte communal associé au Voronoï
       ST_SetSRID(                                                            -- Définit le système de projection EPSG:2154
          ST_Multi(                                                           -- Convertit en MultiPolygon
             ST_CollectionExtract(                                            -- Extrait uniquement les polygones (type 3)
                ST_MakeValid(                                                 -- Corrige les géométries invalides
                   ST_Intersection(                                           -- Calcule l’intersection entre l’îlot et le Voronoï
				      ST_MakeValid(ilfi.geom),                                -- Corrige les géométries invalides
					  ST_MakeValid(iv3.geom))),                               -- Corrige les géométries invalides
                3)), 
       2154) AS geom                                                          -- Géométrie résultante (MultiPolygon, 2154)
FROM "26xxx_wold50m"."26xxx_ilots_final" ilfi                                 -- Source : îlots de superposition non couverts
JOIN "26xxx_wold50m"."26xxx_ilot_voronoi_t3" iv3                              -- Source : polygones Voronoï affectés aux propriétaires
ON ilfi.id = iv3.id                                                           -- Jointure sur l’identifiant d’îlot
AND ST_Intersects(ilfi.geom, iv3.geom)                                        -- Ne conserve que les géométries qui se croisent
AND ST_IsValid(ST_Intersection(ilfi.geom, iv3.geom));                         -- Vérifie la validité géométrique de l’intersection
-- AND ST_Area(ST_Intersection(ilfi.geom, iv3.geom)) > 0                      -- Optionnel : supprime les intersections vides
COMMIT;

CREATE INDEX idx_26xxx_ilot_voronoi_t4_geom                                   
ON "26xxx_wold50m"."26xxx_ilot_voronoi_t4"
USING gist (geom);
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--
---- Création de la table "26xxx_ilot_voronoi_rg" : Zones non couvertes à débroussailler par propriétaire, regroupées.

-- Description : Cette table regroupe les **zones non couvertes** à débroussailler par **chaque propriétaire**
--               (compte communal), en **fusionnant** toutes les géométries issues de `26xxx_ilot_voronoi_t4`.
--               Le résultat est une **géométrie unique par compte communal**, représentée en MultiPolygon.
--               → Attributs : comptecommunal (N° du propriétaire), geom (MultiPolygon, EPSG:2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_ilot_voronoi_rg";               
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_ilot_voronoi_rg" AS
SELECT iv4.comptecommunal,                                                     -- N° du compte communal (propriétaire)
       ST_SetSRID(                                                             -- Définit le système de projection EPSG:2154
          ST_Multi(                                                            -- Convertit le résultat en MultiPolygon
             ST_CollectionExtract(                                             -- Extrait uniquement les polygones (type 3)
                ST_MakeValid(                                                  -- Corrige les géométries invalides
                   ST_Union(iv4.geom)),                                        -- Fusionne toutes les géométries du compte communal
                   3)), 
       2154) AS geom                                                           -- Géométrie résultante (MultiPolygon, 2154)
FROM "26xxx_wold50m"."26xxx_ilot_voronoi_t4" iv4                               -- Source : zones Voronoi découpées par propriétaire
GROUP BY iv4.comptecommunal;                                                   -- Regroupe les géométries par compte communal
COMMIT;

CREATE INDEX idx_26xxx_ilot_voronoi_rg_geom                               
ON "26xxx_wold50m"."26xxx_ilot_voronoi_rg" 
USING gist (geom);
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE 15                                                   ----
----               FUSION FINALE ET EXTRACTION DES ZONES À DÉBROUSSAILLER PAR PROPRIÉTAIRE                   ----
----								                                                                          ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Regrouper toutes les zones à débroussailler (initiales et résiduelles) par propriétaire.              ----
---- - Nettoyer ces zones pour supprimer les artefacts géométriques liés aux traitements précédents.         ----
---- - Extraire uniquement les surfaces situées dans le périmètre réglementaire des 200 mètres OLD.          ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - Fusion des surfaces initiales et des surfaces générées par Voronoï, compte communal par compte.       ----
---- - Nettoyage géométrique en quatre étapes : tampons, alignements, suppressions d’épines et de trous.     ----
---- - Interception finale avec la zone des 200 mètres autour des massifs à enjeu, avec filtrage de surface. ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Une géométrie unique par compte communal, intégrant toutes les zones à débroussailler.                ----
---- - Des contours corrigés et alignés, sans artefacts ni résidus.                                          ----
---- - Un extrait précis des surfaces réglementaires OLD supérieures à 0,5 ha.                               ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_Union + COALESCE : pour regrouper les géométries doublées ou exclusives d’une des sources.         ----
---- - ST_Buffer + ST_Snap : pour corriger les contours sans distorsion excessive.                           ----
---- - ST_RemoveRepeatedPoints : pour supprimer les sommets inutiles après tampon.                           ----
---- - ST_RemoveSmallParts : pour éliminer les petites entités inexploitables (< 1 m²).                      ----
---- - ST_Intersection : pour ne conserver que les surfaces réellement concernées par l’OLD.                 ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la nouvelle table "26xxx_result3" : Résultat final des zones à débroussailler pour chaque
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
	SELECT COALESCE(r1.comptecommunal, ivrg.comptecommunal) AS comptecommunal, -- Sélectionne l'un ou l'autre compte communal,
		   CASE 
			 -- Cas où les deux tables contiennent des données
			 WHEN r1.comptecommunal IS NOT NULL                      -- Condition : Si compte communale des zones à débroussailler non null
			  AND ivrg.comptecommunal IS NOT NULL                    -- Condition : Si compte communale des trous comblés non null
			 THEN ST_SetSRID(                                        -- Définit le système de projection EPSG:2154
					 ST_Multi(                                       -- Convertit en MultiPolygon
						ST_CollectionExtract(                        -- Extrait uniquement les géométries de type 3
						   ST_MakeValid(                             -- Corrige les géométries invalides
							  ST_Union(                              -- Fusionne les géométries
							    ST_MakeValid(ivrg.geom),             -- Corrige les géométries invalides
								ST_MakeValid(r1.geom))),             -- Corrige les géométries invalides
						3)),
				   2154)                                           
			 -- Cas où seule la table "26xxx_result1" contient des données
			 WHEN r1.comptecommunal IS NOT NULL 
			 THEN ST_SetSRID(                                       -- Définit le système de projection EPSG:2154
					 ST_Multi(                                      -- Convertit en MultiPolygon
						ST_CollectionExtract(                       -- Extrait uniquement les géométries de type 3
						   ST_MakeValid(r1.geom),                   -- Corrige les géométries invalides
					 3)),
				   2154)
			 -- Cas où seule la table "26xxx_ilot_voronoi_rg" contient des données
			 WHEN ivrg.comptecommunal IS NOT NULL 
			 THEN ST_SetSRID(                                       -- Définit le système de projection EPSG:2154
					 ST_Multi(                                      -- Convertit en MultiPolygon
						ST_CollectionExtract(                       -- Extrait uniquement les géométries de type 3
						   ST_MakeValid(ivrg.geom),                 -- Corrige les géométries invalides
					 3)),
				   2154)
			 -- Sinon résultat null
			 ELSE NULL                                              -- Aucun résultat valide
		  END AS geom                                               -- Géométries résultantes
	FROM "26xxx_wold50m"."26xxx_result1" r1                         -- Source : Zone à débroussailler corrigée avant comblement des trous
	FULL OUTER JOIN "26xxx_wold50m"."26xxx_ilot_voronoi_rg" ivrg    -- Source : trous comblés par cc
	ON r1.comptecommunal = ivrg.comptecommunal                      -- Condition :  si comptes communaux identiques
)
SELECT u.comptecommunal,
	   ST_SetSRID(                                                  -- Définit le système de projection EPSG:2154
		  ST_Multi(                                                 -- Convertit en MultiPolygon
			 ST_CollectionExtract(                                  -- Extrait uniquement les géométries de type 3
			    ST_MakeValid(                                       -- Corrige les géométries invalides
				   ST_Union(u.geom)),                               -- Fusionne en une seule entité
		  3)),
	   2154) AS geom                                                -- Géométries résultantes
FROM union_geom u                                                   -- Source : résultat de la requête précédente
GROUP BY comptecommunal;                                            -- Regroupe par compte communal
COMMIT;

CREATE INDEX idx_26xxx_result2_geom  
ON "26xxx_wold50m"."26xxx_result2"  
USING gist (geom); 
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_result2_corr1" : nettoyage topologique par double tampon et alignement

-- Description : Cette table est générée à partir de la table "26xxx_result2". Les entités sont fusionnées
--               par compte communal à l’aide de ST_Union (et ST_MakeValid), puis nettoyées via un tampon
--               négatif suivi d’un tampon positif, chacun étant aligné par ST_Snap sur le tampon précédent.
--               Un nettoyage final des petits trous (inférieurs à 1 m²) est effectué, suivi d’un casting en 
--               MultiPolygon (EPSG:2154).
--               → Attributs : comptecommunal (texte), geom (MultiPolygon en Lambert 93)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_result2_corr1";                     
COMMIT;                                                                     

CREATE TABLE "26xxx_wold50m"."26xxx_result2_corr1" AS      -- Crée la nouvelle table corrigée                              
WITH origine AS (                                          -- fusion et validation                                                     
     SELECT r2.comptecommunal,                             -- Compte communal d’origine                                        
            ST_Union(ST_MakeValid(r2.geom)) AS geom        -- Fusionne et corrige les géométries invalides                   
     FROM "26xxx_wold50m"."26xxx_result2" r2               -- Source des entités brutes                          
     GROUP BY r2.comptecommunal                            -- Regroupement par compte communal                                      
), 
tampon_correction_externe AS (                             -- tampon négatif pour supprimer épines externes                                                   
     SELECT o.comptecommunal,                              -- N° du compte communal                                         
            ST_RemoveRepeatedPoints(                       -- Supprime les sommets trop rapprochés                                   
                ST_Buffer(                                 -- Applique un tampon négatif                                            
                    o.geom,                                -- Géométrie d’origine  
                    -0.001,                                -- Réduction de 3 mm                                           
                    'join=mitre mitre_limit=5.0'),         -- Garde les angles vifs, limite la longueur des arêtes fines
                0.003) AS geom                             -- Supprime les sommets espacés de moins de 3 mm                                        
     FROM origine o                                        -- Source : géométrie fusionnée et validée
), 
alignement_correction_externe AS (                         -- Étape 3 : réalignement externe                                                        
     SELECT tce.comptecommunal,                            -- N° du compte communal                                       
            ST_Snap(                                       -- Réaligne les sommets proches                                                  
                tce.geom,                                  -- Géométrie issue du tampon externe
                o.geom,                                    -- Géométrie d’origine
                0.006) AS geom                             -- Distance d’accrochage : 6 mm                                       
     FROM tampon_correction_externe tce                    -- Source : géométrie après tampon externe
     JOIN origine o ON tce.comptecommunal = o.comptecommunal   -- Jointure sur compte communal
),
tampon_correction_interne AS (                             -- tampon positif pour supprimer artefacts internes                                                  
     SELECT ace.comptecommunal,                            -- N° du compte communal                                       
            ST_RemoveRepeatedPoints(                       -- Supprime sommets trop rapprochés                                   
                ST_Buffer(                                 -- Applique un tampon positif                                            
                    ace.geom,                              -- Géométrie issue de l’alignement externe
                    0.001,                                 -- Dilatation de 3 mm                                           
                    'join=mitre mitre_limit=5.0'),         -- Conserve les angles vifs
                0.003) AS geom                             -- Supprime les sommets espacés de moins de 3 mm
     FROM alignement_correction_externe ace                -- Source : géométrie après réalignement externe
),
alignement_correction_interne AS (                         -- réalignement interne                                                         
     SELECT tci.comptecommunal,                            -- N° du compte communal                                       
            ST_Snap(                                       -- Réaligne les sommets proches                                                  
                tci.geom,                                  -- Géométrie issue du tampon interne
                ace.geom,                                  -- Référence = géométrie après correction externe
                0.006) AS geom                             -- Distance d’accrochage : 6 mm                                       
     FROM tampon_correction_interne tci                    -- Source : géométrie après tampon interne
     JOIN alignement_correction_externe ace                -- Jointure avec correction externe
     ON tci.comptecommunal = ace.comptecommunal            -- Condition de jointure sur le compte communal
),
geom_finale AS (                                           -- nettoyage final (suppression petits morceaux et trous)                                                                            
     SELECT aci.comptecommunal,                            -- Identifiant communal                                      
            ST_SetSRID(                                    -- Définit le SRID EPSG:2154                                              
                ST_Multi(                                  -- Convertit en MultiPolygon                                            
                    ST_CollectionExtract(                  -- Extrait uniquement les polygones (type 3)                           
                        ST_RemoveSmallParts(               -- Supprime les morceaux ou trous trop petits                         
                            ST_MakeValid(aci.geom),        -- Corrige la géométrie
                            1,0),                          -- Supprime parties inférieures à 1 m²
                    3)),                                   -- Extraction type polygone uniquement
            2154) AS geom                                  -- Géométrie finale validée
     FROM alignement_correction_interne aci                -- Source : géométrie après réalignement interne
)
SELECT *                                                   -- Sélectionne toutes les colonnes                                                             
FROM geom_finale                                           -- Source : résultat final
WHERE geom IS NOT NULL                                     -- Exclut les géométries nulles                                               
  AND NOT ST_IsEmpty(geom)                                 -- Exclut les géométries vides                                            
  AND ST_IsValid(geom);                                    -- Conserve uniquement les géométries valides                                              
COMMIT;                                                    -- Valide la création

CREATE INDEX idx_26xxx_result2_corr1_geom                  -- Crée un index spatial pour accélérer les requêtes                                             
ON "26xxx_wold50m"."26xxx_result2_corr1"                   -- Table cible
USING gist (geom);                                         -- Type d’index GIST (spatial)
COMMIT;                                                    -- Valide l’index


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_result3" : Zones à débroussailler dans la bande des 200 mètres autour des massifs sensibles.

-- Description : Cette table extrait, pour chaque **propriétaire** (compte communal), les **zones à débroussailler**
--               situées dans le périmètre des **200 mètres autour des massifs forestiers sensibles** (OLD 200m),
--               en ne conservant que les zones supérieures à **0,5 hectare**. Le résultat est une **intersection**
--               entre les zones finales de débroussaillement (`result2`) et la couche OLD 200m.
--               → Attributs : comptecommunal (N° du propriétaire), geom (MultiPolygon, EPSG:2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_result3";                             
COMMIT;

CREATE TABLE "26xxx_wold50m"."26xxx_result3" AS
SELECT r2c1.comptecommunal,                              -- N° du compte communal (propriétaire)
	   ST_SetSRID(                                       -- Définit le système de projection EPSG:2154
	      ST_Multi(                                      -- Convertit en MultiPolygon
	         ST_CollectionExtract(                       -- Extrait uniquement les polygones (type 3)
	            ST_MakeValid(                            -- Corrige les géométries invalides
	               ST_Intersection(                      -- Calcule l'intersection géométrique
	                  ST_MakeValid(o.geom),              -- Corrige les géométries invalides
	                  ST_MakeValid(r2c1.geom))),         -- Corrige les géométries invalides
	            3)), 
	   2154) AS geom                                     -- Géométrie résultante (MultiPolygon, EPSG:2154)
FROM "26xxx_wold50m"."26xxx_result2_corr1" r2c1          -- Source : zones finales à débroussailler
JOIN public.old200m o                                    -- Source : zones d'application OLD 200m
ON ST_Intersects(r2c1.geom, o.geom);                     -- Ne conserve que les géométries intersectant la zone des 200m
COMMIT;

DELETE FROM "26xxx_wold50m"."26xxx_result3"                                        
WHERE geom IS NULL 
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);
COMMIT;

CREATE INDEX idx_26xxx_result3_geom                                             
ON "26xxx_wold50m"."26xxx_result3"
USING gist (geom);
COMMIT;


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
---- PARTIE : INTÉGRATION DES PARCS ÉOLIENS DANS LES ZONES À DÉBROUSSAILLER                                  ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Identifier les zones à débroussailler autour des éoliennes dans le périmètre OLD de 200 m.            ----
---- - Associer ces zones aux unités foncières et comptes communaux concernés.                               ----
---- - Supprimer les bâtiments situés dans les zones des parcs éoliens, pour éviter les doublons.            ----
---- - Fusionner l’ensemble des surfaces concernées, en rattachant chaque zone au bon gestionnaire.          ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - Sélection des éoliennes situées dans la commune ciblée et intersectant le périmètre OLD.              ----
---- - Association de ces géométries aux unités foncières pour récupérer les comptes communaux.              ----
---- - Création d’un tampon de 10 m (emprise du pylône) suivi d’un tampon de 50 m (zone à débroussailler).   ----
---- - Suppression des bâtiments inclus dans ces zones pour éviter leur double prise en compte.              ----
---- - Fusion des zones OLD précédentes avec celles des éoliennes, avec rattachement du nom de parc.         ----
---- - Attribution des transformateurs aux parcs proches si situés à moins de 250 m, puis regroupement final.----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Une couche consolidée des zones à débroussailler, incluant les emprises éoliennes et transformateurs. ----
---- - Une géométrie par entité (compte communal ou parc), sans doublon et sans artefact.                    ----
---- - Une attribution cohérente des responsabilités de débroussaillement par gestionnaire.                  ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_Intersection : pour croiser précisément les géométries des éoliennes avec la commune et l’OLD.     ----
---- - ST_Buffer : pour définir les emprises de sécurité autour des infrastructures.                         ----
---- - ST_Union + ST_Multi + ST_CollectionExtract : pour fusionner et homogénéiser les géométries.           ----
---- - ST_DWithin : pour identifier les bâtiments ou zones proches à rattacher sans contact direct.          ----
---- - COALESCE : pour prioriser le nom de parc dans les cas d’attribution multiple.                         ----
---- Création de la table "26xxx_zold_eolien" : Zones à débroussailler autour des éoliennes                  ----
---- en les associant aux unités foncières et communes concernées.                                           ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_zold_eolien" : Zones à débroussailler autour des éoliennes
---- en les associant aux unités foncières et communes concernées.

-- Description : Cette table crée des zones tampon de 10 mètres autour des éoliennes pourformer le pylone, 
--               puis des tampons supplémentaires de 50 mètres à partir de ces premiers tampons pour la zone
--               à débroussailler. Les géométries résultantes sont ensuite associées aux unités foncières 
--               cadastrales pour déterminer les comptes communaux concernés.
--               → Attributs : nom_parc (texte), comptecommunal (texte), geom (MultiPolygon en EPSG:2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_zold_eolien";                       
COMMIT;                                                                        

CREATE TABLE "26xxx_wold50m"."26xxx_zold_eolien" AS 
WITH intersection_communes AS (
-- Intersection entre éoliennes et commune 26xxx
     SELECT eol.nom_parc,                                                        -- Nom du parc éolien
            ST_SetSRID(                                                          -- Définit le système de projection à EPSG:2154
               ST_Multi(                                                         -- Convertit au format MultiPolygon
                  ST_MakeValid(                                                  -- Corrige les géométries invalides
                     ST_Intersection(                                            -- Calcule l’intersection géométrique
                        ST_MakeValid(eol.geom),                                  -- Corrige les géométries invalides des éoliennes 
                        ST_MakeValid(c.geom)))),                                 -- Corrige les géométries invalides de la commune  
            2154) AS geom                                                        
     FROM public.eolien_filtre eol                                               -- Source : éoliennes issues du RETN
     INNER JOIN r_cadastre.geo_commune c                                         -- Jointure avec la table des communes
     ON ST_Intersects(eol.geom, c.geom)                                          -- Condition : les géométries doivent s’intersecter
     WHERE c.idu = 'xxx'                                                         -- Filtre : uniquement la commune 26xxx
),
-- Intersection avec la zone des OLD200m
intersection_old200m AS (                                                       
     SELECT ic.nom_parc,                                                         -- Nom du parc éolien
            ST_SetSRID(                                                          -- Définit le système de projection (L93 : 2154)
               ST_Multi(                                                         -- Convertit au format MultiPolygon
                  ST_MakeValid(                                                  -- Corrige les géométries invalides
                     ST_Intersection(                                            -- Calcule l’intersection avec les zones OLD
                        ST_MakeValid(ic.geom),                                   -- Corrige les géométries invalides issue de l’intersection précédente
                        ST_MakeValid(old200.geom)))),                            -- Corrige les géométries invalides des zones OLD
            2154) AS geom                                                        
     FROM intersection_communes ic                                               -- Source : intersection des éoliennes avec la commune
     INNER JOIN public.old200m old200                                            -- Jointure avec la table des zones OLD
     ON ST_Intersects(ic.geom, old200.geom)                                      -- Condition : intersection spatiale
),
-- Association aux unités foncières
intersection_cc AS (                                                            
     SELECT iold.nom_parc,                                                       -- Nom du parc éolien
            uf.comptecommunal,                                                   -- Numéro de compte communal issu de l’unité foncière
            CASE
                -- Si une UF intersecte effectivement la zone
                WHEN uf.geom IS NOT NULL THEN                                    
                     ST_SetSRID(                                                  -- Définit le système de projection (L93 : 2154)
                        ST_Multi(                                                 -- Convertit au format MultiPolygon
                           ST_MakeValid(                                          -- Corrige les géométries invalides
                              ST_Intersection(                                    -- Calcule l’intersection avec les unités foncières
                                 ST_MakeValid(iold.geom),                         -- Corrige les géométries invalides de la zone éolienne
                                 ST_MakeValid(uf.geom)))),                        -- Corrige les géométries invalides de l’unité foncière                        
                     2154)

                -- Sinon, on garde la géométrie telle quelle
                ELSE ST_SetSRID(iold.geom, 2154)                                  -- Définit le système de projection (L93 : 2154)
			   
            END AS geom                                                           -- Géométrie résultante
     FROM intersection_old200m iold                                               -- Source : tampons sur zones OLD
     LEFT JOIN r_cadastre.geo_unite_fonciere uf                                   -- Jointure avec la table des unités foncières
     ON ST_Intersects(iold.geom, uf.geom)                                         -- Condition : intersection spatiale
),
-- Création d’un tampon de 10 mètres
tampon_10m AS (                                                                  
     SELECT icc.nom_parc,                                                         -- Nom du parc
            icc.comptecommunal,                                                   -- Compte communal associé
            ST_SetSRID(                                                           -- Définit le système de projection (L93 : 2154)
               ST_Multi(                                                          -- Convertit au format MultiPolygon
                  ST_CollectionExtract(                                           -- Extrait uniquement les géométries de type 3
                     ST_ForceCollection(
                        ST_MakeValid(                                             -- Corrige les géométries invalides
                           ST_Buffer(icc.geom, 3))),                             -- Tampon de 10m autour de la géométrie
                        3)),
            2154) AS geom                                                         
     FROM intersection_cc icc                                                     -- Source : zones associées aux comptes communaux
),
-- Zone à débroussailler autour des éoliennes
tampon_60m AS (                                                       
     SELECT t10.nom_parc,                                                         -- Nom du parc éolien
            t10.comptecommunal,                                                   -- Compte communal
            ST_Multi(                                                             -- Convertit au format MultiPolygon
               ST_CollectionExtract(                                              -- Extrait uniquement les géométries de type 3
                  ST_MakeValid(                                                   -- Corrige les géométries invalides
                     ST_Buffer(t10.geom, 50)),                                    -- Crée la zone à débroussailler de 50m autour des éoliennes
                  3)) AS geom                                                         
     FROM tampon_10m t10                                                          -- Source : tampons de 10m précédents
)
-- Fusion des tampons par compte et parc
SELECT t60.nom_parc,                                                              -- Nom du parc éolien
	   t60.comptecommunal,                                                        -- Compte communal
	   ST_Multi(                                                                  -- Convertit au format MultiPolygon
	      ST_CollectionExtract(                                                   -- Extrait uniquement les géométries de type 3
		     ST_MakeValid(                                                        -- Corrige les géométries invalides
			    ST_Union(t60.geom)),                                              -- Fusionne les géométries en une seul entité
			    3)) AS geom                                                  
FROM tampon_60m t60                                                               -- Source : tampons de 60m précédents
GROUP BY t60.nom_parc, t60.comptecommunal;                                        -- Regroupement par attribut
COMMIT;                                                                         

CREATE INDEX idx_26xxx_zold_eolien_geom                                        
ON "26xxx_wold50m"."26xxx_zold_eolien"                                          
USING gist (geom);                                                             
COMMIT;                                                                        


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_result4" : Fusion de la zone OLD finale avec la zone à débroussailler des parc 
---- éoliens.

-- Description : Cette table consolide les entités issues de result3 en supprimant celles recouvertes par des bâtiments 
--               sur les zones éoliennes, puis ajoute les géométries des tampons éoliens ("zold"). Elle attribue 
--               automatiquement le nom du parc aux entités (transformateurs) proches d'une zone zold (rayon de 250 m)
--               en raison de l'interdiction de bâtir 500m autour des éoliennes.
--               → Attributs : comptecommunal (texte), geom (MultiPolygon en EPSG:2154)

DROP TABLE IF EXISTS "26xxx_wold50m"."26xxx_result4";                                      
COMMIT;                                                                                     

CREATE TABLE "26xxx_wold50m"."26xxx_result4" AS                                            
WITH bati_a_exclure AS (
-- Sélection des bâtiments à exclure
     SELECT ST_MakeValid(b200cc.geom) AS geom                             --Corrige les géométries invalides des bâtiments à supprimer
     FROM "26xxx_wold50m"."26xxx_bati200_cc" b200cc                       -- Source : bâtiments dans la zone des old 200m avec compte communal
     JOIN "26xxx_wold50m"."26xxx_zold_eolien" zeol                        -- Source : zones à débroussailler autour des parcs éoliens
     ON ST_Intersects(b200cc.geom, zeol.geom)                             -- Condition : le bâtiment intersecte la zone 
),
-- Décomposition du résulat final 3 des OLD en Polygone
result3_polygones AS (
     SELECT r3.comptecommunal,                                            -- Numéro du compte communal
            (ST_Dump(r3.geom)).geom AS geom                               -- Décomposition des MultiPolygon en polygones simples
     FROM "26xxx_wold50m"."26xxx_result3" r3                              -- Source : Zone finale à débroussailler par propriétaire sans les zones attribuées aux éoliennes
),
-- Suppression des batiments correspondants aux éoliennes
result3_nettoye AS (
     SELECT r3p.*                                                         -- Sélection de toutes les données
     FROM result3_polygones r3p                                           -- Source : résulat final 3 des OLD en Polygone
     LEFT JOIN bati_a_exclure b                                           -- Source : bâtiments à exclure
     ON ST_DWithin(r3p.geom, b.geom, 30)                                  -- Condition : Si intersection entre les bâtiments à exclure et la zone à débroussailler dans un rayon de 30m
     WHERE b.geom IS NULL                                                 -- Filtre : quand batiment à exclure est null
),
-- Union entre la zone finale à débroussailler 3 et la zone à débroussailler auttour des éoliennes
fusion_zold_result3 AS (
     SELECT r3n.comptecommunal AS comptecommunal,                         -- Compte communal d’origine
            ST_Multi(                                                     -- Convertit au format MultiPolygon
			   ST_CollectionExtract(                                      -- Extrait uniquement les géométries de type 3
			      ST_MakeValid(r3n.geom),                                 -- Corrige les géométries invalides
				  3)) AS geom                   
     FROM result3_nettoye r3n                                             -- Source : Zone finale 3 à débroussailler sans les bâtiments correspondants aux éoliennes

     UNION ALL                                                            -- Aggrège les tables ensembles

     SELECT zeol.nom_parc AS comptecommunal,                              -- Nom du parc éolien comme identifiant
            ST_Multi(                                                     -- Convertit au format MultiPolygon
			   ST_CollectionExtract(                                      -- Extrait uniquement les géométries de type 3
			      ST_MakeValid(zeol.geom),                                -- Corrige les géométries invalides
				  3)) AS geom                     
     FROM "26xxx_wold50m"."26xxx_zold_eolien" zeol                        -- Source : zone à débroussailler autour des éoliennes
),
-- Association des transformateurs aux zones à débroussailler par les gérants du parcs éoliens
association_bati AS (
     SELECT DISTINCT ON (r3p.geom)                                        -- Une seule ligne par géométrie
            zeol.nom_parc AS comptecommunal,                              -- Attribution du nom de parc comme compte communal
            ST_MakeValid(r3p.geom) AS geom                                -- Corrige les géométries invalides
     FROM result3_polygones r3p                                           -- Source : résulat final 3 des OLD en Polygone
     JOIN "26xxx_wold50m"."26xxx_zold_eolien" zeol                        -- Source : zone à débroussailler autour des éoliennes
     ON ST_DWithin(r3p.geom, zeol.geom, 250)                              -- Si la géométrie est à moins de 250m d'une zold
),
-- Attribution du nom du parc aux transformateurs
fusion_finale AS (
     SELECT COALESCE(assob.comptecommunal, fzr3.comptecommunal) AS comptecommunal,-- Priorité au nom de parc si présent
            ST_MakeValid(fzr3.geom) AS geom                               -- Corrige les géométries invalides
     FROM fusion_zold_result3 fzr3                                        -- Source : Zone à débroussailler totale par propriétaire dans le cadre des OLD
     LEFT JOIN association_bati assob                                     -- Source : Zone à débroussailler autour des éoliennes avec transformateurs
	 ON ST_Equals(fzr3.geom, assob.geom)                                  -- Jointure exacte sur la géométrie
)
-- Union par compte communal
SELECT comptecommunal,                                                    -- N° de compte communal ou nom de parc
       ST_Multi(                                                          -- Convertit au format MultiPolygon
	      ST_CollectionExtract(                                           -- Extrait uniquement les géométries de type 3
		     ST_MakeValid(                                                -- Corrige les géométries invalides
			    ST_Union(geom)),                                          -- Fusion des géométries avec nettoyage final
				3)) AS geom                  
FROM fusion_finale                                                        -- Source : résulat de la requête "fusion_finale"
GROUP BY comptecommunal;                                                  -- Regroupement des attributs
COMMIT;                                                                                     

CREATE INDEX idx_26xxx_result4_geom                                                        
ON "26xxx_wold50m"."26xxx_result4"
USING gist (geom);                                                                          
COMMIT;                                                                                 

