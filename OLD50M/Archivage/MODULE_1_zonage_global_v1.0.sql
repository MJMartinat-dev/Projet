--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                      MODULE 1 Prétraitements zonage global                                               ----
----     Traitements sous PostgreSQL/PostGIS pour corriger les couches de zonage d'urbanisme                  ----
----     et créer une couche contenant les zones urbaines de chaque commune concernée par les OLD             ----
----  Auteur          : Frédéric Sarret                                                                       ----
----  Version         : 1.0                                                                                   ----
----  License         : GNU GENERAL PUBLIC LICENSE  Version 3                                                 ----
----  Documentation   :                                                                                       ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----   INTEGRATION DU NUMERO DE DEPARTEMENT                                                                   ----
----                                                                                                          ----
----   Remplacer "26_" par votre numéro de département, exemple "13_"                                         ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

DO $$
DECLARE 
	schema_zonage_origine TEXT := '26_zonage_urba';       -- schéma où sont stockés les zonages des PLU
	schema_zonage_resultat TEXT := '26_old50m_resultat';  -- schéma où sera enregistrée la table de zonage départementale
	schema_cadastre TEXT := 'r_cadastre';                 -- schéma créé par l'extension cadastre de QGIS 
	r record;
	srid_source INTEGER;
-- paramétrage ---------------------------------------------------------------------------
	schema_zonage_travail TEXT := '26_zonage_travail';    -- schéma temporaire de travail
	table_zonage_dept TEXT := '26_zonage_global';         -- nom de la table de zonage départementale
	buffer_fuseau_zonage DOUBLE PRECISION := 1;           -- distance de buffer pour le fuseau du contour du zonage
	recalage_1 DOUBLE PRECISION := 0.1;                   -- distance de recalage
	recalage_2 DOUBLE PRECISION := 0.1;                   -- distance de recalage
	recalage_3 DOUBLE PRECISION := 0.1;                   -- distance de recalage
-- fin paramétrage -----------------------------------------------------------------------

BEGIN
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- vérification et correction si les noms d'attribut des tables zonages ont des majuscules
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
    FOR r IN
        SELECT table_schema, table_name, column_name
        FROM information_schema.columns
        WHERE table_schema = schema_zonage_origine
    LOOP
        -- Si le nom de la colonne n’est pas déjà en minuscule
        IF r.column_name <> lower(r.column_name) THEN
            EXECUTE format(
                'ALTER TABLE %I.%I RENAME COLUMN %I TO %I;',
                r.table_schema,
                r.table_name,
                r.column_name,
                lower(r.column_name)
            );
        END IF;
    END LOOP;

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- vérification du système de coordonnées de référence et reprojection si nécessaire
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
    FOR r IN
        SELECT table_schema, table_name, column_name
        FROM information_schema.columns
        WHERE table_schema = schema_zonage_origine
          AND udt_name = 'geometry'  -- uniquement les colonnes geometry
    LOOP
        -- Vérifie si la colonne contient des données
        EXECUTE format('SELECT COUNT(*) FROM %I.%I', r.table_schema, r.table_name)
        INTO srid_source;
        IF srid_source = 0 THEN
            RAISE NOTICE 'Table %I.%I : aucune donnée, ignorée', r.table_schema, r.table_name;
            CONTINUE;
        END IF;

        -- Récupère le SRID de la première géométrie non nulle
        EXECUTE format(
            'SELECT ST_SRID(%I) FROM %I.%I WHERE %I IS NOT NULL LIMIT 1',
            r.column_name, r.table_schema, r.table_name, r.column_name
        )
        INTO srid_source;

        IF srid_source IS NULL OR srid_source = 0 THEN
            RAISE NOTICE 'Table %I.%I : SRID non défini, affectation SRID=2154 sans reprojection',
                         r.table_schema, r.table_name;
            EXECUTE format(
                'UPDATE %I.%I SET %I = ST_SetSRID(%I, 2154) WHERE %I IS NOT NULL;',
                r.table_schema, r.table_name, r.column_name,
                r.column_name, r.column_name
            );
        ELSIF srid_source != 2154 THEN
            RAISE NOTICE 'Table %I.%I : reprojection de SRID % vers 2154',
                         r.table_schema, r.table_name, srid_source;
            EXECUTE format(
                'UPDATE %I.%I
                 SET %I = ST_Transform(%I, 2154)
                 WHERE %I IS NOT NULL;',
                r.table_schema, r.table_name,
                r.column_name, r.column_name, r.column_name
            );
        ELSE
            RAISE NOTICE 'Table %.% : déjà en SRID 2154, rien à faire',
                         r.table_schema, r.table_name;
        END IF;
    END LOOP;


-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
--  Création du schéma de travail
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
        EXECUTE 
	'DROP SCHEMA IF EXISTS ' || quote_ident(schema_zonage_travail) || ' CASCADE;
	CREATE SCHEMA ' || quote_ident(schema_zonage_travail) || ';';


-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- Boucle de correction des zonages urbains présents dans schema_zonage_origine
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

    FOR r IN (
	SELECT DISTINCT 
		tablename, 
		left(tablename, 5) AS insee, 
		concat(left(tablename, 2), '0', right(left(tablename, 5), 3)) AS inseelong 
	FROM pg_catalog.pg_tables 
	WHERE schemaname = schema_zonage_origine
	)
    LOOP

        EXECUTE 
--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "26xxx_zonage_rg" : Regroupement des zones urbaines
  -- Description : Cette table regroupe les géométries des zones urbaines (type "U") en une seule 
  --               entité spatiale par type de zone. Les géométries sont validées et converties 
  --               en MultiPolygon pour garantir leur cohérence géométrique.

-- Supprimer la table "26xxx_zonage_rg" si elle existe déjà pour éviter les conflits et doublons
'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.tablename || '_rg') || ';';

        EXECUTE 
-- Créer une nouvelle table "26xxx_zonage_rg" où les géométries des zones urbaines sont 
-- fusionnées, validées et regroupées par type de zone.
'CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.tablename || '_rg') || ' AS
WITH union_zu AS (
SELECT 
      ST_SetSRID(                                   -- Définit le système de coordonnées EPSG:2154
		ST_Multi(					--  Converties en MultiPolygon	  
          ST_MakeValid(					 --  Valide les géométries
             ST_Union(z.geom))),'      -- Fusionne les géométries
		   || 2154  || ') AS geom,                               -- Géométries résultantes
             z.typezone					    -- Type de zone (par exemple "U" pour urbain)
FROM ' || quote_ident(schema_zonage_origine) || '.' || quote_ident(r.tablename) || ' z     -- Source : données de zonage
WHERE z.typezone = ''U''				   -- Filtre : inclut uniquement les zones de type "U" (urbaines)
GROUP BY z.typezone              -- Regroupement des géométries par type de zone
),
-- 1) Épuration des épines externes 
--	 aller retour avec 3 noeuds disctincts alignés
--   supprime le noeud de l''extrémité 
epine_externe AS (
	SELECT uzu.typezone,                         -- 
        ST_SetSRID(                                   -- Définit le système de coordonnées EPSG:2154
		  ST_Multi(                                   -- Convertit en MultiPolygon
			ST_CollectionExtract(                     -- Extrait uniquement les géométries de type 3
  			  ST_MakeValid(
   				ST_Snap(                              -- Aligne le tampon de la géométrie sur la géométrie d''origine
     			  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  uzu.geom,' 
					  || -0.0001 || ',                        -- Ajout d''un tampon négatif de l''ordre de 10 nm
					  ''join=mitre mitre_limit=5.0''),'  -- 
					  || 0.0003 || '),			              -- Suppression des noeuds consécutifs proches de plus de 30 nm
				  uzu.geom,'
                   || 0.0006 || ')),' || 3 || ')),'    -- Avec une distance d''accrochage de l''ordre de 60 nm
		   || 2154 || ') AS geom                               -- Géométries résultantes
    FROM union_zu uzu           -- Source : 
	),
-- 2) Épuration des épines internes
epine_interne AS (
	SELECT epext.typezone,                      -- 
        ST_SetSRID(                                   -- Définit le système de coordonnées EPSG:2154
		  ST_Multi(                                   -- Convertit en MultiPolygon
			ST_CollectionExtract(                     -- Extrait uniquement les géométries de type 3
   			  ST_MakeValid(
   				ST_Snap(                              -- Aligne le tampon de la géométrie sur la géométrie d''origine
     			  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  uzu.geom,' 
					  || 0.0001 || ',                        -- Ajout d''un tampon négatif de l''ordre de 10 nm
					  ''join=mitre mitre_limit=5.0''),'  -- 
					  || 0.0003 || '),			              -- Suppression des noeuds consécutifs proches de plus de 30 nm
				  uzu.geom,'
                   || 0.0006 || ')),' || 3 || ')),'                      -- Avec une distance d''accrochage de l''ordre de 60 nm
		   || 2154 || ') AS geom                               -- Géométries résultantes
    FROM epine_externe epext                          -- Source : Zones corrigées sans épines extérieures
	JOIN union_zu uzu
	ON epext.typezone = uzu.typezone
	)
-- 3) Résultat final : on convertit la géométrie en MultiPolygon valide
SELECT epint.typezone,                          -- 
       ST_SetSRID(                                    -- Définit le système de coordonnées EPSG:2154
          ST_Multi(                                   -- Convertit en MultiPolygon
			 ST_CollectionExtract(                    -- Extrait uniquement les géométries de type 3
   				ST_MakeValid(epint.geom),'             -- Corrige les géométries invalides                                    
			 || 3 || ')),'
	    || 2154 || ') AS geom                                 -- Géométries résultantes
FROM epine_interne epint;';                             -- Source : Zones corrigées sans épines extérieures ni intérieures


        EXECUTE 
-- Créer un index spatial sur la colonne "geom" pour optimiser les requêtes spatiales 
'CREATE INDEX idx_'  || r.insee || '_zonage_rg_geom 
ON ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.tablename || '_rg') || '
USING gist (geom);';  -- Utilise un index spatial GiST pour optimiser les calculs géographiques


        EXECUTE 
--*------------------------------------------------------------------------------------------------------------*--
---- Création de la table "26xxx_pt_parcelle_fuseau_zu" : Regroupement des zones urbaines
  -- Description : Créer une nouvelle table avec les sommets des parcelles 
  -- situés à moins de 2 mètres d'une limite de zone urbaine.
  -- (on veut réduire le jeux de sommets dans les calculs suivants)

-- Supprimer la table "26xxx_pt_parcelle_fuseau_zu" si elle existe déjà pour éviter les conflits et doublons
'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_pt_parcelle_fuseau_zu') || ';';

        EXECUTE 
'CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_pt_parcelle_fuseau_zu') || ' AS
WITH 
fuseau_zonage AS (
	SELECT ST_Buffer(    -- Crée une zone tampon de 2 mètres autour des limites des zones urbaines
			ST_Boundary(zrg.geom),'
			|| buffer_fuseau_zonage || ','
			|| 2 || ') AS geom   -- 2 segments pour un quart de cercle du buffer
	FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.tablename || '_rg') || ' zrg  -- Source : zones urbaines regroupées
),
parcelle_fuseau AS (   -- jeu de parcelles intersectant le fuseau
	SELECT ST_Collect(   -- Collecte les géométries
			 p.geom) AS geom 
	FROM ' || quote_ident(schema_cadastre) || '.parcelle_info AS p, -- Source : parcelles initiales
     	fuseau_zonage  
	WHERE LEFT(p.geo_parcelle,' || 6 || ')=' || quote_literal(r.inseelong) ||'
	AND  ST_Intersects( -- Vérifie l''intersection entre les géométries
                    p.geom, 
					fuseau_zonage.geom
                    )
),
pt_parcelle_fuseau AS (   -- jeu des sommets des parcelles intersectant le fuseau
	SELECT (ST_Dump( -- Décompose les collections géométriques en entités individuelles
          		ST_RemoveRepeatedPoints( -- Supprime les points redondants pour éviter les doublons
             		ST_Points(parcelle_fuseau.geom) -- Extrait les sommets (points) de chaque géométrie polygonale
       		))).geom AS geom -- Définit la colonne résultante "geom" contenant les points extraits
	FROM parcelle_fuseau
)
SELECT pt_parcelle_fuseau.geom
FROM pt_parcelle_fuseau, fuseau_zonage
WHERE ST_Within(pt_parcelle_fuseau.geom, fuseau_zonage.geom);';   -- retire les points situés sur le contour du fuseau

-- Notes explicatives :
-- - ST_Points : Extrait tous les sommets individuels (points) des géométries polygonales.
-- - ST_RemoveRepeatedPoints : Supprime les points consécutifs identiques dans les géométries, réduisant les doublons.
-- - ST_Dump : Décompose les collections géométriques (comme MULTIPOINT) en entités géométriques simples (POINT).


        EXECUTE 
--*------------------------------------------------------------------------------------------------------------*--
---- Création de la table "26xxx_zonage_corr1" : Extraction des points des contours des polygones
  -- Description : Cette table contient les points individuels extraits des contours des zones urbaines.
  --               Les points sont extraits des géométries polygonales, y compris les trous éventuels, 
  --               afin de faciliter les analyses géométriques et les traitements ultérieurs.

-- Supprimer la table "26xxx_zonage_corr1" si elle existe déjà pour éviter tout conflit ou doublon.
'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr1') || ';';

        EXECUTE 
-- Créer une nouvelle table "26xxx_zonage_corr1" qui extrait les points des contours des zones 
-- urbaines, y compris ceux des éventuels trous internes.
'CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr1') || ' AS
SELECT (ST_DumpPoints(zrg.geom)).path AS corr1path, -- Décompose et extrait des points des contours
		(ST_DumpPoints(zrg.geom)).geom AS geom
FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.tablename || '_rg') || ' AS zrg;'; -- Source : table regroupant les géométries de zu

-- Notes explicatives :
-- ST_DumpPoints : Extrait tous les sommets individuels (points) des géométries polygonales, y compris 
--                 ceux des trous internes.

        EXECUTE 
--*------------------------------------------------------------------------------------------------------------*--
---- Création de la table "26xxx_zonage_corr2" : sommets non concordants
  -- Description : Sélection des sommets du zonage 
  -- dont la géométrie n'est pas superposée à un sommet de parcelle

-- Supprimer la table "26xxx_zonage_corr2" si elle existe déjà pour éviter tout conflit 
-- ou doublon.
'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr2') || ';';

        EXECUTE 
'CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr2') || ' AS
WITH 
union_pt_fuseau AS (         -- Union des points du fuseau (multipoint)
	SELECT ST_Union(geom) AS geom
	FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_pt_parcelle_fuseau_zu') || '
)      
SELECT zcorr1.corr1path AS corr2path,
	zcorr1.geom
FROM  ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr1') || ' zcorr1
INNER JOIN union_pt_fuseau
ON NOT ST_Intersects(zcorr1.geom, union_pt_fuseau.geom);';   -- sommets du zonage dont la géométrie n''est pas superposée à un sommet de parcelle


        EXECUTE 
---- Création de la table "26xxx_zonage_corr3" : Recalage 1
  -- Description : Recalage des sommets du zonage sur le sommet existant 
  -- le plus proche de parcelle, jusqu'à une distance de 0,1 mètres (ajustable)

-- Supprimer la table "26xxx_zonage_corr3" si elle existe déjà pour éviter tout conflit 
-- ou doublon.
'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr3') || ';';

        EXECUTE 
'CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr3') || ' AS
WITH 
sommets_proches AS (
  SELECT zcorr2.corr2path AS corr3path,
         pt_parcelle.geom AS parcelle_geom,
         ST_Distance(zcorr2.geom, pt_parcelle.geom) AS dist,
         ST_ClosestPoint(pt_parcelle.geom, zcorr2.geom) AS cp_geom
  FROM  ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr2') || ' zcorr2
  INNER JOIN ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_pt_parcelle_fuseau_zu') || ' pt_parcelle
  ON ST_DWithin(zcorr2.geom, pt_parcelle.geom, ' || recalage_1 || ')
)
SELECT corr3path,
       (ARRAY_AGG(cp_geom ORDER BY dist ASC))[' || 1 || '] AS geom
FROM sommets_proches
GROUP BY corr3path;';


       EXECUTE 
---- Création de la table "26xxx_zonage_corr4" : Recalage 2
  -- Description : Recalage des sommets du zonage sur le point le plus proche
  -- du segment de parcelle le plus proche, jusqu'à une distance de 0,1 mètres (ajustable)
  -- en excluant les sommets déjà recalé au recalage 1

-- Supprimer la table "26xxx_zonage_corr4" si elle existe déjà pour éviter tout conflit 
-- ou doublon.
'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr4') || ';';

       EXECUTE 
'CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr4') || ' AS
WITH 
sommets_non_recales AS (
	SELECT 
		zcorr2.corr2path,
		zcorr2.geom 
	FROM  ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr2') || ' zcorr2
	LEFT JOIN ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr3') || ' AS zcorr3
	ON zcorr2.corr2path = zcorr3.corr3path
	WHERE zcorr3.corr3path IS NULL -- Exclure les sommets déjà recalés au recalage 1
),
sommets_projetes AS (
  SELECT sommets_non_recales.corr2path AS corr4path,
         ST_Distance(sommets_non_recales.geom, 
		 			ST_ClosestPoint(parcelle.geom, sommets_non_recales.geom))
		 AS dist,
         ST_ClosestPoint(parcelle.geom, sommets_non_recales.geom) AS cp
  FROM  sommets_non_recales
  INNER JOIN ' || quote_ident(schema_cadastre) || '.parcelle_info AS parcelle
         ON  LEFT(parcelle.geo_parcelle,' || 6 || ')=' || quote_literal(r.inseelong) ||'
		 AND ST_DWithin(sommets_non_recales.geom, parcelle.geom, '  || recalage_2 || ')
         AND NOT ST_Intersects(parcelle.geom, sommets_non_recales.geom)
)
SELECT corr4path,
       (ARRAY_AGG(cp ORDER BY dist ASC))[' || 1 || '] AS geom
FROM sommets_projetes
GROUP BY corr4path;';


       EXECUTE 
---- Création de la table "26xxx_zonage_corr5" : Remplace les sommets du zonage à recaler
-- par les sommets calculés aux recalages 1 et 2

-- Supprimer la table "26xxx_zonage_corr5" si elle existe déjà pour éviter tout conflit 
-- ou doublon.
'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr5') || ';';

       EXECUTE 
'CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr5') || ' AS
WITH
sommets_recales AS (
	SELECT zcorr3.corr3path AS path,  -- issu du recalage 1
		zcorr3.geom
	FROM  ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr3') || ' AS zcorr3
	UNION ALL
	SELECT zcorr4.corr4path AS path,  -- issu du recalage 2
		zcorr4.geom
	FROM  ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr4') || ' AS zcorr4
),
sommets_nonrecales AS (
	SELECT zcorr1.corr1path AS path,
       zcorr1.geom                          -- Points du zonage d''origine, uniquement si non recalés
	FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr1') || ' AS zcorr1
	LEFT JOIN sommets_recales
	ON zcorr1.corr1path = sommets_recales.path
	WHERE sommets_recales.path IS NULL      -- Exclure les points déjà recalés de cette sélection
)
SELECT sommets_recales.path,
		sommets_recales.geom 
FROM  sommets_recales
UNION ALL
SELECT sommets_nonrecales.path,
		sommets_nonrecales.geom 
FROM  sommets_nonrecales;';


       EXECUTE 
---- Création de la table "26xxx_zonage_corr6" : Reconstruction des anneaux des polygones du zonage urbain
  -- Description : Cette table crée des lignes avec les sommets recalés du zonage en gardant les références 
  -- des polygones d'origine et de leurs anneaux.

-- Supprimer la table "26xxx_zonage_corr6" si elle existe déjà pour éviter tout conflit
'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr6') || ';';

       EXECUTE 
-- Créer la table "26xxx_zonage_corr6" avec les anneaux reconstruits
'CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr6') || ' AS
SELECT zcorr5.path[' || 1 || '] AS path1,                              -- Identifiant du polygone
       zcorr5.path[' || 2 || '] AS path2,                              -- Identifiant de l''anneau (1 = extérieur, >1 = intérieur)
       ST_MakeLine(zcorr5.geom ORDER BY zcorr5.path) AS geom -- Reconstruction des anneaux avec tri
FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr5') || ' zcorr5
GROUP BY zcorr5.path[' || 1 || '], zcorr5.path[' || 2 || '];';

       EXECUTE 
-- Créer un index spatial GiST pour optimiser les requêtes
'CREATE INDEX idx_'  || r.insee || '_zonage_corr6_geom
ON ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr6') || '
USING gist (geom);';


       EXECUTE 
---- Création de la table "26xxx_zonage_corr7" : Reconstruction des polygones du zonage urbain
  -- Description : Cette table reconstruit les polygones recalés du zonage urbain à partir 
  -- des anneaux extérieurs et intérieurs.

-- Supprimer la table "26xxx_zonage_corr7" si elle existe déjà pour éviter tout conflit
'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr7') || ';';

       EXECUTE 
-- Créer la table "26xxx_zonage_corr7" avec les polygones reconstruits
'CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr7') || ' AS
WITH array_geom AS (
    SELECT DISTINCT path1,               -- Identifiant du polygone
           ARRAY(
                SELECT ST_AddPoint(corr6.geom, ST_StartPoint(corr6.geom)) AS geom -- Ferme l''anneau en ajoutant le premier point à la fin
                FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr6') || ' corr6
                WHERE corr6.path1 = ag.path1
                ORDER BY corr6.path2     -- Identifiant de l''anneau ordonné
           ) AS array_anneaux
    FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr6') || ' ag
)
SELECT ag.path1 AS path1,         -- Identifiant du polygone
       ST_MakePolygon(
            ag.array_anneaux[' || 1 || '],  -- premier anneau de la liste ordonnée (anneau extérieur)
            ag.array_anneaux[' || 1 || ':]  -- Anneaux intérieurs éventuels
       ) AS geom
FROM array_geom ag;';

       EXECUTE 
-- Créer un index spatial GiST pour optimiser les requêtes
'CREATE INDEX idx_'  || r.insee || '_zonage_corr7_geom
ON ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr7') || '
USING gist (geom);';

-- Notes explicatives :
-- - ARRAY : Regroupe les anneaux en un tableau pour chaque polygone.
-- - ORDER BY : Tri des anneaux pour garantir leur bon ordonnancement.
-- - ST_MakePolygon : Crée un polygone à partir d'un anneau extérieur et d'éventuels anneaux intérieurs.

--*------------------------------------------------------------------------------------------------------------*--

--*------------------------------------------------------------------------------------------------------------*--

       EXECUTE 
---- Création de la table "26xxx_zonage_corrige" : ==== Recalage 3 ====
  -- Description : Création de points de recalage sur les sommets de parcelles proches du contour 
  -- du zonage (distance de 0.5 m ajustable) lorsqu'il n'y a pas de sommet du zonage en vis à vis
  -- L'objectif est de faire adhérer le contour du zonage au parcellaire pour réduire les artéfacts de calcul

-- Supprimer la table "26xxx_zonage_corrige" si elle existe déjà pour éviter tout conflit 
-- ou doublon.
'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corrige') || ';';

       EXECUTE 
'CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corrige') || ' AS
WITH
anneaux_corr7 AS (
  -- Extraction des anneaux extérieurs
  SELECT path1,'                        -- Identifiant du polygone
         || 0 || ' AS ring_index,              -- Identifiant de l''anneau extérieur
         ST_ExteriorRing(geom) AS geom
  FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr7') || '

  UNION ALL

  -- Extraction des anneaux intérieurs
  SELECT path1,                        -- Identifiant du polygone
         n AS ring_index,              -- Identifiant de l''anneau intérieur
         ST_InteriorRingN(geom, n) AS geom
  FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr7') || '
  CROSS JOIN generate_series(' || 1 || ', ST_NumInteriorRings(geom)) AS n
),
-- Notes explicatives :
-- - ST_NumInteriorRings : Calcule le nombre n d''anneaux intérieurs d''un polygone
-- - ST_InteriorRingN : Sélectionne le nième anneau intérieur d''un polygone
-- - generate_series : Crée une table incrémentée d''entiers de 1 à n.
zcorr7_segments AS (
    SELECT 
		acorr7.path1,                  -- Identifiant du polygone
		acorr7.ring_index,             -- Identifiant de l''anneau
        (ST_DumpSegments((acorr7.geom))).path AS segment_path, -- Chemin unique pour identifier chaque segment
		(ST_DumpSegments((acorr7.geom))).geom AS segment_geom  -- Extraction des segments de type LINESTRING des limites des polygones
    FROM anneaux_corr7 acorr7
),
-- Identifier les segments nécessitant une complétion en raison de la proximité de points de parcelles d''un segment
-- sans sommet du zonage en vis à vis
segments AS (
    SELECT DISTINCT 
		path1,                 -- Identifiant du polygone
		ring_index,            -- Identifiant de l''anneau
		segment_path,          -- Chemin unique du segment
        segment_geom           -- Géométrie du segment
    FROM zcorr7_segments
    JOIN ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_pt_parcelle_fuseau_zu') || ' AS ppf      -- Points des parcelles dans le fuseau
    ON ST_DWithin(zcorr7_segments.segment_geom, ppf.geom, '|| recalage_3 || ')     -- Critère de proximité : points à moins de 0,5 mètre
	AND NOT ST_Intersects(zcorr7_segments.segment_geom, ppf.geom)  -- exclut les points des parcelles présents sur le segment
),
-- Associer chaque point sélectionné au segment concerné
points AS (
    SELECT
		segments.path1,          -- Identifiant du polygone
		segments.ring_index,     -- Identifiant de l''anneau
		segments.segment_path,   -- Chemin unique du segment associé
		ppf.geom AS point_geom   -- Géométrie du point à intégrer dans le segment
    FROM segments
    JOIN ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_pt_parcelle_fuseau_zu') || ' AS ppf
    ON ST_DWithin(segment_geom, ppf.geom,' || recalage_3 || ')              -- Critère de proximité : points à moins de 0,5 mètre
	AND NOT ST_Intersects(segments.segment_geom, ppf.geom)  -- exclut les points des parcelles présents sur le segment
),
-- Calculer la distance de chaque point au premier nœud du segment associé
points_with_distance AS (
    SELECT 
		points.path1,                   -- Identifiant du polygone
		points.ring_index,              -- Identifiant de l''anneau
		points.segment_path,            -- Chemin unique du segment associé
        ST_Distance(points.point_geom, ST_PointN(segments.segment_geom, ' || 1 || ')) AS distance, -- Distance entre le point et le premier nœud du segment
        points.point_geom AS point_geom -- Géométrie du point à intégrer dans le segment
    FROM points
    JOIN segments
    ON points.path1 = segments.path1    -- Associer chaque point à son segment
	AND points.ring_index = segments.ring_index
	AND points.segment_path = segments.segment_path
),
-- Notes explicatives :
-- - ST_PointN : Renvoie la géométrie du nième point du segment.

-- Combiner les points à intégrer avec les sommets des segments à compléter
combined_points AS (
    SELECT 
		path1,                  -- Identifiant du polygone
		ring_index,             -- Identifiant de l''anneau
		segment_path,           -- Chemin unique du segment
        point_geom,             -- Géométrie du point orphelin
		distance                -- Distance entre le point et le premier nœud du segment
    FROM points_with_distance
    UNION ALL                   -- Combiner les points  à intégrer et les sommets existants
    SELECT 
		path1,                  -- Identifiant du polygone
		ring_index,             -- Identifiant de l''anneau
		segment_path,           -- Chemin unique du segment associé
        ST_PointN(segments.segment_geom, generate_series(' || 1 || ', ST_NumPoints(segments.segment_geom))) AS point_geom, -- Ajouter les sommets du segment
		ST_Distance(
			ST_PointN(segments.segment_geom, generate_series(' || 1 || ', ST_NumPoints(segments.segment_geom))),
			ST_PointN(segments.segment_geom, ' || 1 || ')) AS distance
    FROM segments
),
-- Construire une nouvelle LINESTRING pour chaque segment à compléter à partir doints ordonnés par distance
segments_complets AS (
    SELECT 
		path1,                 -- Identifiant du polygone
		ring_index,            -- Identifiant de l''anneau
		segment_path,          -- Chemin unique du segment
        ST_MakeLine(point_geom 
		   		ORDER BY distance
			) AS geom          -- Construction de la LINESTRING triée
    FROM combined_points
    GROUP BY path1,ring_index,segment_path -- Regrouper par segment à compléter
),
-- Fusionner les segments complétés avec les segments non modifiés
segments_final AS (
    SELECT
		path1,                                   -- Identifiant du polygone
		ring_index,                              -- Identifiant de l''anneau
		segments_complets.segment_path,          -- Chemin unique du segment complété
        segments_complets.geom AS geom           -- Géométrie du segment complété
    FROM segments_complets
    UNION ALL                                    -- Combiner avec les segments non modifiés
    SELECT
		zcorr7_segments.path1,                   -- Identifiant du polygone
		zcorr7_segments.ring_index,              -- Identifiant de l''anneau
		zcorr7_segments.segment_path,            -- Chemin unique du segment non modifié
        zcorr7_segments.segment_geom AS geom     -- Géométrie du segment non modifié
    FROM zcorr7_segments
	LEFT JOIN segments_complets
	ON zcorr7_segments.path1 = segments_complets.path1
	AND zcorr7_segments.ring_index = segments_complets.ring_index
	AND zcorr7_segments.segment_path = segments_complets.segment_path
	WHERE segments_complets.segment_path IS NULL -- Exclure les segments complétés
),
-- Reconstruction des lignes des anneaux à partir des segments
anneaux_final AS (
	SELECT 
		path1,                              -- Identifiant du polygone
		ring_index,                         -- Identifiant de l''anneau (0 = extérieur, >0 = intérieur)
		ST_MakeLine(segments_final.geom ORDER BY segment_path) AS geom -- Reconstruction des anneaux avec tri
	FROM segments_final
GROUP BY path1, ring_index
),
-- Rebouclage des lignes des anneaux
anneaux_boucles AS (
	SELECT
		path1,                    -- Identifiant du polygone
		ring_index,               -- Identifiant de l''anneau (0= extérieur, >0 = intérieur)
		ST_AddPoint(anneaux_final.geom, ST_StartPoint(anneaux_final.geom)) AS geom-- Ferme l''anneau en ajoutant le premier point à la fin
	FROM anneaux_final
),
-- Sélection des anneaux formant une surface de plus de 1 m2
macro_anneaux AS (
	SELECT
		path1,                    -- Identifiant du polygone
		ring_index,               -- Identifiant de l''anneau (0= extérieur, >0 = intérieur)
		geom
	FROM anneaux_boucles
	WHERE ST_Area(
			ST_CollectionExtract( 
				ST_MakeValid(
					ST_MakePolygon(geom)
					)
				,' || 3 || ')
			) > ' || 1 || '                
),
-- Reconstruction des polygones
reconstruction_pg AS (
SELECT 
	path1,                                              -- Identifiant du polygone
 	CASE 
		WHEN COUNT(*) FILTER (WHERE ring_index > ' || 0 || ') > ' || 0 || ' -- quand il y a un ou plusieurs anneaux intérieurs
		THEN
		ST_SetSRID(                                     -- Définit le système de projection EPSG:2154
			ST_Multi(                                   -- Convertit en MultiPolygon
				ST_CollectionExtract(                   -- Extrait uniquement les polygones (type 3)
					ST_MakeValid(                       -- Corrige les géométries invalides
						ST_MakePolygon(
							MAX(macro_anneaux.geom) FILTER (WHERE ring_index = ' || 0 || '),   -- anneau extérieur
							ARRAY_AGG(geom) FILTER (WHERE ring_index > ' || 0 || ')            -- anneaux intérieurs 	   
				)),' || 3 || ')),
			' || 2154 || ')     
		ELSE -- quand il n''y pas d''anneau intérieur dans le polygone à reconstruire
		ST_SetSRID(                                     -- Définit le système de projection EPSG:2154
			ST_Multi(                                   -- Convertit en MultiPolygon								
				ST_CollectionExtract(                   -- Extrait uniquement les polygones (type 3)
					ST_MakeValid(                       -- Corrige les géométries invalides
						ST_MakePolygon(
							MAX(macro_anneaux.geom) FILTER (WHERE ring_index = 0)
					)),' || 3 || ')),
			' || 2154 || ')   
		END AS geom
  FROM macro_anneaux
  GROUP BY path1
 )
SELECT 
	ST_SetSRID(                     -- Attribue le SRID 2154 au résultat
		ST_Multi(                   -- Convertit en MultiPolygon
			ST_CollectionExtract(   -- Extrait uniquement les polygones (type 3)
				ST_MakeValid(       -- Corrige les géométries invalides
					ST_Union(geom)  -- Union spatiale de toutes les géométries
		),' || 3 || ')), ' || 2154 || '                 -- Système de coordonnées Lambert-93 (EPSG:2154)
	) AS geom  
FROM reconstruction_pg;';

       EXECUTE 
-- Créer un index spatial GiST pour optimiser les requêtes
'CREATE INDEX idx_'  || r.insee || '_zonage_corrige_geom
ON ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corrige') || '
USING gist (geom);';

    END LOOP;
	
	RAISE NOTICE 'Fin de la correction des zonage';


-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
--  Assemblage des entités dans une couche globale
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

       EXECUTE 
---- Création de la table "zonage_global"

-- Supprimer la table "zonage_global" si elle existe déjà pour éviter tout conflit 
-- ou doublon.
'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_resultat) || '.' || quote_ident(table_zonage_dept) || ' CASCADE;';

       EXECUTE 
-- Créer la table "zonage_global" qui contiendra tous les zonage corrigés
	'CREATE TABLE ' || quote_ident(schema_zonage_resultat) || '.' || quote_ident(table_zonage_dept) || ' (
	insee CHAR(5),
    geom GEOMETRY(MultiPolygon, 2154)
	);

-- Créer un index spatial GiST pour optimiser les requêtes
	CREATE INDEX idx_' || table_zonage_dept || '_geom
	ON ' || quote_ident(schema_zonage_resultat) || '.' || quote_ident(table_zonage_dept) || '
	USING gist (geom);';

    FOR r IN (
	SELECT DISTINCT 
		tablename, 
		left(tablename, 5) AS insee
	FROM pg_catalog.pg_tables 
	WHERE schemaname = schema_zonage_travail
	AND RIGHT(tablename, 7) = 'corrige'
	)
    LOOP

        EXECUTE 
	'INSERT INTO ' || quote_ident(schema_zonage_resultat) || '.' || quote_ident(table_zonage_dept) || ' (insee, geom)
	SELECT ' || quote_literal(r.insee) || ', zc.geom
	FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corrige') || ' AS zc;';

   END LOOP;

	RAISE NOTICE 'Fin de l''assemblage dans la couche %.%', schema_zonage_resultat, table_zonage_dept;


-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
--  Suppression du schéma de travail
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
       EXECUTE 
	'DROP SCHEMA ' || quote_ident(schema_zonage_travail) || ' CASCADE;';


END$$;
