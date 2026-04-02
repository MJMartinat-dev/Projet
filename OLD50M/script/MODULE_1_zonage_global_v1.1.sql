--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                      MODULE 1 Prétraitements zonage global                                               ----
----     Traitements sous PostgreSQL/PostGIS pour corriger les couches de zonage d'urbanisme                  ----
----     et créer une couche contenant les zones urbaines de chaque commune concernée par les OLD             ----
----  Auteur          : Frédéric Sarret                                                                       ----
----  Version         : 1.1                                                                                   ----
----  License         : GNU GENERAL PUBLIC LICENSE  Version 3                                                 ----
----  Documentation   : https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/old50m    ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----   NOMMAGE DES COUCHES DE ZONAGE DES DOCUMENTS D'URBANISME                                                ----
----                                                                                                          ----
----   Le nom de la couche de zonage de la commune de Cassis (insee 13022) doit commencer par son numéro      ----
----   insee (exemple 13022_zonage) et doit posséder un attribut Typezone ou typezone ou TYPEZONE             ----
----   (comme les couches téléchargées sur le géoportail de l'urbanisme)                                      ----
----                                                                                                          ----
----   INTEGRATION DU NUMERO DE DEPARTEMENT                                                                   ----
----                                                                                                          ----
----   Remplacer "XX" par votre numéro de département, exemple "13"                                           ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

DO $$
	DECLARE 
	    -- Paramétrage départemental -------------------------------------------------------------
	    departement TEXT := 'XX';                                                                 -- <<< à modifier selon ton département
	
	    -- Schémas principaux (dynamiques) -------------------------------------------------------
	    schema_zonage_origine  TEXT := departement || '_zonage_urba';                             -- schéma où sont stockés les zonages des PLU
	    schema_zonage_resultat TEXT := departement || '_old50m_resultat';                         -- schéma où sera enregistrée la table de zonage départementale
	    schema_cadastre        TEXT := 'r_cadastre';                                              -- schéma créé par l'extension cadastre de QGIS 

	    -- Variables générales -------------------------------------------------------------------
	    r              RECORD;                                                                    -- Variable d'itération pour parcourir les résultats SQL
	    srid_source    INTEGER;                                                                   -- Stockage temporaire du SRID détecté
	
	    -- Paramétrage ---------------------------------------------------------------------------
	    schema_zonage_travail  TEXT := departement || '_zonage_travail';                          -- Schéma temporaire de travail
	    table_zonage_dept      TEXT := departement || '_zonage_global';                           -- Nom final de la table départementale
	    buffer_fuseau_zonage    DOUBLE PRECISION := 1;                                            -- Tolérance du buffer pour fusionner les limites de zonage
	    recalage_1              DOUBLE PRECISION := 0.1;                                          -- Paramètre de recalage géométrique (niveau 1)
	    recalage_2              DOUBLE PRECISION := 0.1;                                          -- Paramètre de recalage géométrique (niveau 2)
	    recalage_3              DOUBLE PRECISION := 0.1;                                          -- Paramètre de recalage géométrique (niveau 3)
	    -- Fin paramétrage -----------------------------------------------------------------------

		BEGIN                                                                                   -- Démarrage du bloc anonyme PL/pgSQL
		--*------------------------------------------------------------------------------------*--
		-- vérification et correction si les noms d'attribut des tables zonages ont des majuscules
		--*------------------------------------------------------------------------------------*--
		    FOR r IN                                                                              -- Boucle sur chaque colonne du schéma de zonage
		        SELECT table_schema, table_name, column_name                                      -- Récupération du schéma, de la table et du nom de colonne
		        FROM information_schema.columns                                                   -- Lecture du catalogue système des colonnes PostgreSQL
		        WHERE table_schema = schema_zonage_origine                                        -- Filtrage sur le schéma contenant les tables de zonage
		    LOOP                                                                                  -- Début du traitement pour chaque colonne trouvée
		        IF r.column_name <> lower(r.column_name) THEN                                     -- Si le nom de la colonne contient des majuscules
		            EXECUTE format(                                                               -- Construction et exécution d’une commande SQL dynamique
		                'ALTER TABLE %I.%I RENAME COLUMN %I TO %I;',                              -- Requête SQL : renommage de la colonne
		                r.table_schema,                                                           -- Nom du schéma concerné
		                r.table_name,                                                             -- Nom de la table concernée
		                r.column_name,                                                            -- Nom actuel de la colonne
		                lower(r.column_name)                                                      -- Nom cible en minuscules
		            );                                                                            -- Fin de l’exécution de la requête dynamique
		        END IF;                                                                           -- Fin du test conditionnel
		    END LOOP;                                                                             -- Fin de la boucle FOR


		--*------------------------------------------------------------------------------------*--
		-- vérification du système de coordonnées de référence et reprojection si nécessaire
		--*------------------------------------------------------------------------------------*--
		    FOR r IN                                                                                 -- Boucle sur chaque colonne de type géométrie du schéma de zonage
		        SELECT table_schema, table_name, column_name                                         -- Récupération du schéma, du nom de table et du nom de colonne
		        FROM information_schema.columns                                                      -- Lecture du catalogue système des colonnes PostgreSQL
		        WHERE table_schema = schema_zonage_origine                                           -- Filtrage sur le schéma contenant les données de zonage
		          AND udt_name = 'geometry'                                                          -- On ne sélectionne que les colonnes de type geometry
		    LOOP                                                                                     -- Début de la boucle pour chaque table et colonne géométrique
		        EXECUTE format('SELECT COUNT(*) FROM %I.%I', r.table_schema, r.table_name)            -- Compte le nombre d’enregistrements présents dans la table
		        INTO srid_source;                                                                    -- Stocke le résultat du comptage dans la variable srid_source
		        IF srid_source = 0 THEN                                                              -- Si aucune donnée n’est présente, on passe à la table suivante
		            RAISE NOTICE 'Table %I.%I : aucune donnée, ignorée', r.table_schema, r.table_name; -- Message informatif dans la console
		            CONTINUE;                                                                        -- Passe à l’itération suivante de la boucle
		        END IF;                                                                              -- Fin du test sur le nombre d’enregistrements
		
		        EXECUTE format(                                                                      -- Construction d'une requête dynamique
		            'SELECT ST_SRID(%I) FROM %I.%I WHERE %I IS NOT NULL LIMIT 1',                    -- Extraction du SRID d'une géométrie non nulle
		            r.column_name, r.table_schema, r.table_name, r.column_name                       -- Substitution des noms de colonnes et de tables dans la requête
		        )
		        INTO srid_source;                                                                    -- Stocke le SRID détecté dans la variable srid_source
		
		        IF srid_source IS NULL OR srid_source = 0 THEN                                       -- Si le SRID est indéfini ou nul
		            RAISE NOTICE 'Table %I.%I : SRID non défini, affectation SRID=2154 sans reprojection', -- Message d'information sur l'opération effectuée
		                         r.table_schema, r.table_name;                                       -- Paramètres du message NOTICE
		            EXECUTE format(                                                                  -- Construction et exécution d’une mise à jour dynamique
		                'UPDATE %I.%I SET %I = ST_SetSRID(%I, 2154) WHERE %I IS NOT NULL;',          -- Affectation du SRID 2154 (RGF93 / Lambert 93) sans reprojection
		                r.table_schema, r.table_name, r.column_name,                                 -- Schéma, table et colonne concernés
		                r.column_name, r.column_name                                                 -- Application sur les géométries non nulles
		            );
		
		        ELSIF srid_source != 2154 THEN                                                       -- Si le SRID existant est différent de 2154
		            RAISE NOTICE 'Table %I.%I : reprojection de SRID % vers 2154',                   -- Message d'information sur la reprojection en cours
		                         r.table_schema, r.table_name, srid_source;                          -- Paramètres du message NOTICE (schéma, table, ancien SRID)
		            EXECUTE format(                                                                  -- Exécution d'une mise à jour dynamique avec transformation de coordonnées
		                'UPDATE %I.%I                                                                
		                 SET %I = ST_Transform(%I, 2154)                                             
		                 WHERE %I IS NOT NULL;',                                                     -- Reprojection des géométries vers SRID 2154 uniquement pour les objets valides
		                r.table_schema, r.table_name,                                                -- Schéma et table concernés
		                r.column_name, r.column_name, r.column_name                                  -- Colonne géométrique ciblée
		            );
		
		        ELSE                                                                                 -- Cas où le SRID est déjà conforme à 2154
		            RAISE NOTICE 'Table %.% : déjà en SRID 2154, rien à faire',                      -- Message d'information indiquant qu'aucune action n'est nécessaire
		                         r.table_schema, r.table_name;                                       -- Paramètres du message NOTICE
		        END IF;                                                                              -- Fin du test conditionnel sur le SRID
		    END LOOP;                                                                                -- Fin de la boucle sur les colonnes géométriques


		--*------------------------------------------------------------------------------------*--
		--  Création du schéma de travail
		--*------------------------------------------------------------------------------------*--
			EXECUTE                                                                                  -- Exécution dynamique d'une commande SQL
				'DROP SCHEMA IF EXISTS ' || quote_ident(schema_zonage_travail) || ' CASCADE; ' ||    -- Suppression du schéma temporaire s’il existe déjà (avec suppression en cascade)
				'CREATE SCHEMA ' || quote_ident(schema_zonage_travail) || ';';                       -- Création d’un nouveau schéma de travail vide pour les traitements


		--*------------------------------------------------------------------------------------*--
		-- Boucle de correction des zonages urbains présents dans schema_zonage_origine
		--*------------------------------------------------------------------------------------*--
		    FOR r IN (                                                                               -- Parcourt chaque table communale présente dans le schéma d’origine
		        SELECT DISTINCT                                                                      -- Supprime les doublons de noms de tables
		            tablename,                                                                       -- Nom de la table communale
		            left(tablename, 5) AS insee,                                                     -- Code INSEE sur 5 caractères
		            concat(left(tablename, 2), '0', right(left(tablename, 5), 3)) AS inseelong       -- Code INSEE complet au format département+commune
		        FROM pg_catalog.pg_tables                                                            -- Lecture du catalogue des tables PostgreSQL
		        WHERE schemaname = schema_zonage_origine                                             -- Filtrage sur le schéma contenant les zonages à traiter
		    )
			
		    LOOP                                                                                     -- Début de la boucle de traitement par commune
		        EXECUTE                                                                              -- Exécution d'une commande SQL dynamique
				    --*------------------------------------------------------------------------------------*--
		        	---- Création de la table "26xxx_zonage_rg" : Regroupement des zones urbaines
		  			-- Description : Cette table regroupe les géométries des zones urbaines (type "U") en une seule 
		  			--               entité spatiale par type de zone. Les géométries sont validées et converties 
		  			--               en MultiPolygon pour garantir leur cohérence géométrique.
		            --*------------------------------------------------------------------------------------*--
		            'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.tablename || '_rg') || ';'; 
		
		        EXECUTE                                                                                                                             -- Exécution d’une nouvelle commande SQL dynamique
					'CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.tablename || '_rg') || ' AS                       -- Création de la table de regroupement des zones urbaines
					WITH union_zu AS (                                                                                                              -- CTE pour fusionner toutes les zones urbaines d’une même commune
					     SELECT ST_SetSRID(                                                                                                         -- Définit le système de coordonnées EPSG:2154
					               ST_Multi(                                                                                                        -- Convertit en MultiPolygon
					                  ST_MakeValid(                                                                                                 -- Rend valide les géométries avant union
					                     ST_Union(z.geom))),                                                                                        -- Fusionne toutes les géométries urbaines
					            2154) AS geom,                                                                                                      -- Affecte le SRID Lambert-93 au résultat
					            z.typezone                                                                                                          -- Type de zonage urbain (ex : "U" pour urbain)
					    FROM ' || quote_ident(schema_zonage_origine) || '.' || quote_ident(r.tablename) || ' z                                      -- Source : données du zonage urbain communal
					    WHERE z.typezone = ''U''                                                                                                    -- Filtre : ne garde que les zones de type "U" (urbaines)
					    GROUP BY z.typezone                                                                                                         -- Regroupement des géométries par type de zonage urbain
					),
					-- Épuration des épines externes (suppression de petits artefacts linéaires)
					epine_externe AS (
					    SELECT uzu.typezone,                                                                                                        -- Type de zonage urbain
					           ST_SetSRID(                                                                                                          -- Définit le système de coordonnées EPSG:2154
					              ST_Multi(                                                                                                         -- Convertit en MultiPolygon
					                 ST_CollectionExtract(                                                                                          -- Extrait uniquement les géométries de type polygone (type 3)
					                    ST_MakeValid(                                                                                               -- Corrige les géométries invalides
					                       ST_Snap(                                                                                                 -- Aligne les géométries tamponnées avec l’original
					                          ST_RemoveRepeatedPoints(                                                                              -- Supprime les sommets redondants
					                             ST_Buffer(                                                                                         -- Tampon négatif pour éliminer les épines externes
					                                uzu.geom, 
					                                ' || -0.0001 || ',                                                                              -- Taille du tampon négatif d’environ 10 nm
					                                ''join=mitre mitre_limit=5.0''),                                                                -- Paramètres du tampon : angles vifs, limite de jointure
					                             ' || 0.0003 || '),                                                                                 -- Nettoyage des points redondants proches (30 nm)
											  uzu.geom, 
											  ' || 0.0006 || ')),                                                                                   -- Distance d''accrochage à 60 nm
					                    3)), 
					           2154) AS geom                                                                                                        -- Géométrie nettoyée et reprojetée en 2154
					    FROM union_zu uzu                                                                                                           -- Source : zones urbaines fusionnées initialement
					),
					-- Épuration des épines internes (élimination de petits vides internes)
					epine_interne AS (
					    SELECT epext.typezone,                                                                                                      -- Type de zonage urbain conservé
					           ST_SetSRID(                                                                                                          -- Définit le SRID EPSG:2154
					              ST_Multi(                                                                                                         -- Convertit en MultiPolygon
					                 ST_CollectionExtract(                                                                                          -- Extrait les géométries de type polygone (3)
					                    ST_MakeValid(                                                                                               -- Corrige les géométries invalides
					                       ST_Snap(                                                                                                 -- Aligne le tampon sur la géométrie initiale
					                          ST_RemoveRepeatedPoints(                                                                              -- Supprime les sommets redondants
					                             ST_Buffer(                                                                                         -- Tampon positif pour éliminer les épines internes
					                                uzu.geom, 
					                                ' || 0.0001 || ',                                                                               -- Tille du tampon positif d’environ 10 nm
					                                ''join=mitre mitre_limit=5.0''),                                                                -- Paramètres du tampon (angles, joints)
					                             ' || 0.0003 || '),                                                                                 -- Nettoyage des points redondants dans un rayon de 3nm
					                          uzu.geom, 
					                          ' || 0.0006 || ')),                                                                                   -- Distance d''accrochage fin
					                    3)), 
					           2154) AS geom                                                                                                        -- Géométries finales après nettoyage et reprojection en 2154
					    FROM epine_externe epext                                                                                                    -- Source : zonage urbain déjà corrigées des épines externes
					    JOIN union_zu uzu                                                                                                           -- Jointure avec la géométrie initiale pour cohérence des types de zones
					    ON epext.typezone = uzu.typezone                                                                                            -- Association sur le type de zonage urbain
					)
					-- Résultat final : conversion en MultiPolygon valide
					SELECT epint.typezone,                                                                                                          -- Type de zone final
					       ST_SetSRID(                                                                                                              -- Définit le SRID EPSG:2154
					          ST_Multi(                                                                                                             -- Convertit en MultiPolygon
					             ST_CollectionExtract(                                                                                              -- Extrait uniquement les polygones (type 3)
					                ST_MakeValid(epint.geom),                                                                                       -- Corrige les géométries invalides
					                3)),
						   2154) AS geom                                                                                                            -- Résultat final : géométries propres et valides reprojetées en 2154
					FROM epine_interne epint;';                                                                                                     -- Source : zonage urbain corrigées externes + internes
					
		        EXECUTE                                                                                                                             -- Exécution d’un nouvel ordre SQL dynamique
					'CREATE INDEX IF NOT EXISTS idx_'  || r.insee || '_zonage_rg_geom                                 
					ON ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.tablename || '_rg') || '  
					USING gist (geom);';                                                                


				--*------------------------------------------------------------------------------------------------------------*--
		        EXECUTE                                                                                                                             -- Exécution d’une commande SQL dynamique unique
				    
					--*------------------------------------------------------------------------------------*--
					---- Création de la table "26xxx_pt_parcelle_fuseau_zu" : Regroupement des zones urbaines
					-- Description : Créer une nouvelle table avec les sommets des parcelles 
					-- situés à moins de 2 mètres d'une limite de zone urbaine.
					-- (objectif : réduire le nombre de sommets pour les calculs suivants)
					--*------------------------------------------------------------------------------------*--
					
					'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_pt_parcelle_fuseau_zu') || ';  -- Supprime la table existante si nécessaire
					 CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_pt_parcelle_fuseau_zu') || ' AS        -- Crée la table des points de parcelle proches du zonage
					WITH fuseau_zonage AS (                                                                                                         -- Étape 1 : création du fuseau autour des zones urbaines
						 SELECT ST_Buffer(                                                                                                          -- Génère une zone tampon autour du contour des zones urbaines
								   ST_Boundary(zrg.geom),                                                                                           -- Prend la frontière des polygones urbains
								   ' || buffer_fuseau_zonage || ',
								   2 ) AS geom                                                                                                      -- 2 segments par quart de cercle dans le tampon
						 FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.tablename || '_rg') || ' zrg                          -- Source : zones urbaines regroupées
					),
					parcelle_fuseau AS (                                                                                                            -- Étape 2 : sélection des parcelles intersectant le fuseau
						 SELECT ST_Collect(p.geom) AS geom                                                                                          -- Fusionne toutes les géométries intersectantes en un seul objet
						 FROM ' || quote_ident(schema_cadastre) || '.parcelle_info AS p,                                                            -- Source : parcelles cadastrales
						      fuseau_zonage                                                                                                         -- Jointure implicite sur le fuseau
						 WHERE LEFT(p.geo_parcelle, 6) =' || quote_literal(r.inseelong) ||'                                                         -- Filtrage sur le code INSEE de la commune
						 AND  ST_Intersects(p.geom, fuseau_zonage.geom)                                                                             -- Ne garde que les parcelles en contact avec le fuseau
					),
					pt_parcelle_fuseau AS (                                                                                                         -- Étape 3 : extraction des sommets individuels des parcelles
						 SELECT (ST_Dump(                                                                                                           -- Décompose les géométries
					          		ST_RemoveRepeatedPoints(                                                                                        -- Supprime les points redondants
					             	   ST_Points(parcelle_fuseau.geom)                                                                              -- Extrait les sommets de chaque polygone
					       		 ))).geom AS geom                                                                                                   -- Définit la colonne de sortie des points extraits
						 FROM parcelle_fuseau                                                                                                       -- Source : parcelles intersectant le fuseau
					)
					SELECT pt_parcelle_fuseau.geom                                                                                                 -- Sélection finale des points
					FROM pt_parcelle_fuseau, fuseau_zonage                                                                                         -- Jointure pour conserver la référence au fuseau
					WHERE ST_Within(pt_parcelle_fuseau.geom, fuseau_zonage.geom);';                                                                -- Exclut les points situés sur le bord du fuseau
				
				--*------------------------------------------------------------------------------------------------------------*--
				EXECUTE                                                                                                                            -- Exécution d’une commande SQL dynamique unique

					--*------------------------------------------------------------------------------------*--
					---- Création de la table "26xxx_zonage_corr1" : Extraction des points des contours des polygones
					-- Description : Cette table contient les points individuels extraits des contours des 
					--               zones urbaines. Les points sont extraits des géométries polygonales, y  
					--               compris les trous éventuels, afin de faciliter les analyses géométriques 
					--               et les traitements ultérieurs.
					--*------------------------------------------------------------------------------------*--
					
					'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr1') || ';  
					 
					CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr1') || ' AS        
					SELECT (ST_DumpPoints(zrg.geom)).path AS corr1path,                                                                           -- Identifie la position du point dans la structure géométrique (chemin)
					       (ST_DumpPoints(zrg.geom)).geom AS geom                                                                                 -- Géométrie du point individuel
					FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.tablename || '_rg') || ' AS zrg;';                       -- Source : table regroupant les zones urbaines corrigées


                --*------------------------------------------------------------------------------------------------------------*--
				EXECUTE                                                                                                                           -- Exécution d’une commande SQL dynamique unique
				
					--*------------------------------------------------------------------------------------*--
					---- Création de la table "26xxx_zonage_corr2" : sommets non concordants
					-- Description : Sélection des sommets du zonage 
					-- dont la géométrie n'est pas superposée à un sommet de parcelle
					--*------------------------------------------------------------------------------------*--
					'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr2') || ';
					
					CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr2') || ' AS      
					WITH union_pt_fuseau AS (                                                                                                     -- Étape 1 : regroupe tous les sommets des parcelles proches en une seule géométrie multipoint
						 SELECT ST_Union(geom) AS geom                                                                                            -- Fusion de l’ensemble des points 
						 FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_pt_parcelle_fuseau_zu') || '             -- Source : sommets des parcelles proches du zonage urbain
					)      
					SELECT zcorr1.corr1path AS corr2path,                                                                                         -- Identifiant du sommet extrait du zonage
						   zcorr1.geom                                                                                                            -- Géométrie du sommet du zonage
					FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr1') || ' AS zcorr1                 -- Source : table contenant les points du zonage
					INNER JOIN union_pt_fuseau                                                                                                    -- Jointure avec la géométrie regroupée du fuseau
					ON NOT ST_Intersects(zcorr1.geom, union_pt_fuseau.geom);';                                                                    -- Sélection des points du zonage ne coïncidant pas avec un point de parcelle


					--*------------------------------------------------------------------------------------------------------------*--
        			EXECUTE                                                                                                                       -- Exécution d’une commande SQL dynamique unique

						--*------------------------------------------------------------------------------------*--
						---- Création de la table "26xxx_zonage_corr3" : Recalage 1
						-- Description : Recalage des sommets du zonage sur le sommet existant 
						-- le plus proche de parcelle, jusqu'à une distance de 0,1 mètre (ajustable)
						--*------------------------------------------------------------------------------------*--
						'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr3') || '; 
						CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr3') || ' AS        
						WITH sommets_proches AS (                                                                                                -- Étape 1 : recherche des points du zonage proches des sommets de parcelles
						     SELECT zcorr2.corr2path AS corr3path,                                                                               -- Identifiant du sommet du zonage (hérité de corr2)
						            pt_parcelle.geom AS parcelle_geom,                                                                           -- Géométrie du sommet de parcelle
						            ST_Distance(zcorr2.geom, pt_parcelle.geom) AS dist,                                                          -- Distance entre le point du zonage et celui de la parcelle
						            ST_ClosestPoint(pt_parcelle.geom, zcorr2.geom) AS cp_geom                                                    -- Coordonnée du point de la parcelle le plus proche du sommet du zonage
						     FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr2') || ' AS zcorr2       -- Source : sommets du zonage non concordants
						     INNER JOIN ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_pt_parcelle_fuseau_zu') || ' AS pt_parcelle  -- Source : sommets des parcelles proches
						     ON ST_DWithin(zcorr2.geom, pt_parcelle.geom, ' || recalage_1 || ')                                                  -- Condition : points situés à moins de 0,1 mètre (seuil de recalage 1)
						)
						SELECT corr3path,                                                                                                        -- Identifiant du sommet recalé
						       (ARRAY_AGG(cp_geom ORDER BY dist ASC))[1] AS geom                                                                 -- Sélectionne le point le plus proche (premier de la liste triée par distance)
						FROM sommets_proches                                                                                                     -- Source : correspondances entre sommets du zonage et de parcelles
						GROUP BY corr3path;';                                                                                                    -- Regroupe les recalages par identifiant de sommet

					--*------------------------------------------------------------------------------------------------------------*--
					EXECUTE                                                                                                                  -- Exécution d’une commande SQL dynamique unique

						--*------------------------------------------------------------------------------------*--
						---- Création de la table "26xxx_zonage_corr4" : Recalage 2
						-- Description : Recalage des sommets du zonage sur le point le plus proche
						-- du segment de parcelle le plus proche, jusqu'à une distance de 0,1 mètres (ajustable)
						-- en excluant les sommets déjà recalé au recalage 1
						--*------------------------------------------------------------------------------------*--						   

						'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr4') || '; 
						
						CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr4') || ' AS       
						WITH sommets_non_recales AS (                                                                                       -- Étape 1 : sélection des sommets non encore recalés
							 SELECT zcorr2.corr2path,                                                                                       -- Identifiant du sommet initial (hérité de corr2)
									zcorr2.geom                                                                                             -- Géométrie du sommet du zonage
							 FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr2') || ' AS zcorr2  -- Source : sommets du zonage non concordants
							 LEFT JOIN ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr3') || ' AS zcorr3  -- Jointure pour vérifier les recalés au niveau 1
							 ON zcorr2.corr2path = zcorr3.corr3path                                                                         -- Correspondance sur l’identifiant de sommet
							 WHERE zcorr3.corr3path IS NULL                                                                                 -- Garde uniquement les sommets non recalés au recalage 1
						),
						sommets_projetes AS (                                                                                               -- Étape 2 : projection des sommets restants sur les segments de parcelle
							 SELECT sommets_non_recales.corr2path AS corr4path,                                                             -- Identifiant du sommet recalé niveau 2
									ST_Distance(                                                                                            -- Distance entre le sommet du zonage et son point projeté sur le segment
									   sommets_non_recales.geom, 
									   ST_ClosestPoint(parcelle.geom, sommets_non_recales.geom)
									) AS dist, 
									ST_ClosestPoint(parcelle.geom, sommets_non_recales.geom) AS cp                                          -- Coordonnée du point projeté sur la parcelle la plus proche
							 FROM sommets_non_recales                                                                                       -- Source : sommets du zonage à recaler
							 INNER JOIN ' || quote_ident(schema_cadastre) || '.parcelle_info AS parcelle                                    -- Source : géométrie du parcellaire cadastral
							 ON LEFT(parcelle.geo_parcelle, 6) = ' || quote_literal(r.inseelong) || '                                       -- Filtrage sur le code INSEE
							 AND ST_DWithin(sommets_non_recales.geom, parcelle.geom, ' || recalage_2 || ')                                  -- Condition : à moins de 0,1 mètre du segment de parcelle
							 AND NOT ST_Intersects(parcelle.geom, sommets_non_recales.geom)                                                 -- Exclut les sommets déjà présents sur le segment
						)
						SELECT corr4path,                                                                                                   -- Identifiant du sommet recalé (niveau 2)
							   (ARRAY_AGG(cp ORDER BY dist ASC))[1] AS geom                                                                 -- Sélection du point projeté le plus proche
						FROM sommets_projetes                                                                                               -- Source : projections calculées
						GROUP BY corr4path;';                                                                                               -- Regroupement par sommet

					--*------------------------------------------------------------------------------------------------------------*--
					EXECUTE                                                                                                                 -- Exécution d’une commande SQL dynamique unique

						--*------------------------------------------------------------------------------------*--
						---- Création de la table "26xxx_zonage_corr5" : Remplacement des sommets du zonage à recaler
						-- Description : Cette table fusionne les sommets recalés aux étapes 1 et 2 
						-- (corr3 et corr4) avec les points du zonage d’origine non modifiés.
						--*------------------------------------------------------------------------------------*--						   

						'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr5') || ';  
						
						 CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr5') || ' AS      
						WITH sommets_recales AS (                                                                                           -- Étape 1 : rassemble tous les points recalés
							 SELECT zcorr3.corr3path AS path,                                                                               -- Identifiant du sommet recalé au premier recalage
									zcorr3.geom                                                                                             -- Géométrie recalée
							 FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr3') || ' AS zcorr3  -- Source : recalage 1
							
							 UNION ALL
							
							 SELECT zcorr4.corr4path AS path,                                                                               -- Identifiant du sommet recalé au recalage 2
									zcorr4.geom                                                                                             -- Géométrie recalée
							 FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr4') || ' AS zcorr4  -- Source : recalage 2
						),
						sommets_nonrecales AS (                                                                                             -- Étape 2 : conserve les points d’origine non modifiés
							 SELECT zcorr1.corr1path AS path,                                                                               -- Identifiant du sommet d’origine
									zcorr1.geom                                                                                             -- Géométrie du point original
							 FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr1') || ' AS zcorr1  -- Source : sommets initiaux
							 LEFT JOIN sommets_recales                                                                                      -- Vérifie s’ils ont déjà été recalés
							 ON zcorr1.corr1path = sommets_recales.path                                                                     -- Association sur l’identifiant du sommet
							 WHERE sommets_recales.path IS NULL                                                                             -- Garde uniquement les points non recalés
						)
						SELECT sommets_recales.path,                                                                                        -- Identifiant du sommet recalé
							   sommets_recales.geom                                                                                         -- Géométrie recalée
						FROM sommets_recales                                                                                                -- Source : points recalés aux étapes précédentes
						
						UNION ALL                                                                                                           -- Combine les recalés et les non recalés
						
						SELECT sommets_nonrecales.path,                                                                                     -- Identifiant du sommet non recalé
							   sommets_nonrecales.geom                                                                                      -- Géométrie d’origine
						FROM sommets_nonrecales;';                                                                                          -- Source : points d’origine non recalés


					--*------------------------------------------------------------------------------------------------------------*--
					EXECUTE                                                                                                                 -- Exécution d’une commande SQL dynamique unique

					   --*------------------------------------------------------------------------------------*--
					   ---- Création de la table "26xxx_zonage_corr6" : Reconstruction des anneaux des polygones 
					   ----du zonage urbain
					   -- Description : Cette table crée des lignes avec les sommets recalés du zonage
					   -- en conservant les références des polygones d’origine et de leurs anneaux.
					   --*------------------------------------------------------------------------------------*--
					   
					   'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr6') || ';  
					   
					   CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr6') || ' AS      
					   SELECT zcorr5.path[' || 1 || '] AS path1,                                                                           -- Identifiant du polygone (indice principal)
							  zcorr5.path[' || 2 || '] AS path2,                                                                           -- Identifiant de l’anneau (1 = extérieur, >1 = intérieur)
							  ST_MakeLine(zcorr5.geom ORDER BY zcorr5.path) AS geom                                                        -- Reconstitue les lignes de chaque anneau à partir des sommets triés
					   FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr5') || ' AS zcorr5       -- Source : sommets recalés et non recalés
					   GROUP BY zcorr5.path[' || 1 || '], zcorr5.path[' || 2 || '];';                                                      -- Regroupe les segments par polygone et par anneau
						
					EXECUTE                                                                                                                -- Exécution d’un second ordre pour la création d’un index spatial
					   'CREATE INDEX idx_' || r.insee || '_zonage_corr6_geom                                
					   ON ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr6') || '                     
					   USING gist (geom);';         

					--*------------------------------------------------------------------------------------------------------------*--
					EXECUTE                                                                                                                -- Exécution d’une commande SQL dynamique unique

						--*------------------------------------------------------------------------------------*--
						---- Création de la table "26xxx_zonage_corr7" : Reconstruction des polygones du zonage urbain
						-- Description : Cette table reconstruit les polygones recalés du zonage urbain
						-- à partir des anneaux extérieurs et intérieurs générés à l’étape précédente (corr6).
						-- Chaque polygone est reformé en assurant la fermeture correcte des anneaux.
						--*------------------------------------------------------------------------------------*--
																	 
						'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr7') || '; 
						CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr7') || ' AS        
						WITH array_geom AS (                                                                                              -- Étape 1 : préparation des anneaux ordonnés
							 SELECT DISTINCT 
									path1,                                                                                                -- Identifiant du polygone
									ARRAY(                                                                                                -- Construction d’un tableau contenant les anneaux d’un même polygone
										  SELECT ST_AddPoint(corr6.geom, ST_StartPoint(corr6.geom)) AS geom                               -- Ferme chaque anneau en ajoutant le premier point à la fin
										  FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr6') || ' AS corr6
										  WHERE corr6.path1 = ag.path1                                                                    -- Sélectionne les anneaux appartenant au même polygone
										  ORDER BY corr6.path2                                                                            -- Trie les anneaux pour garantir l’ordre extérieur → intérieur
									) AS array_anneaux                                                                                    -- Résultat : tableau d’anneaux par polygone
							 FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr6') || ' AS ag    -- Source : anneaux reconstruits (corr6)
						)
						SELECT ag.path1 AS path1,                                                                                         -- Identifiant du polygone
							   ST_MakePolygon(                                                                                            -- Reconstitution du polygone complet
									ag.array_anneaux[' || 1 || '],                                                                        -- Premier anneau = contour extérieur
									ag.array_anneaux[' || 1 || ':]                                                                        -- Anneaux intérieurs éventuels
							   ) AS geom                                                                                                  -- Géométrie finale du polygone
						FROM array_geom AS ag;';                                                                                          -- Source : tableau d’anneaux regroupés
						
					EXECUTE   
					
						'CREATE INDEX idx_' || r.insee || '_zonage_corr7_geom                                 
						ON ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corr7') || '                     
						USING gist (geom);';        


					--*------------------------------------------------------------------------------------------------------------*--

					EXECUTE 

						--*------------------------------------------------------------------------------------*--
						---- Création de la table "26xxx_zonage_corrige" : ==== Recalage 3 ====
						-- Description : Création de points de recalage sur les sommets de parcelles proches du contour 
						-- du zonage (distance de 0.5 m ajustable) lorsqu'il n'y a pas de sommet du zonage en vis à vis
						-- L'objectif est de faire adhérer le contour du zonage au parcellaire pour réduire les artéfacts de calcul
					   --*------------------------------------------------------------------------------------*--

						'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_travail) || '.' ||quote_ident(r.insee || '_zonage_corrige') || ';  -- Suppression de la table si elle existe déjà

						CREATE TABLE ' || quote_ident(schema_zonage_travail) || '.' ||quote_ident(r.insee || '_zonage_corrige') || ' AS
						WITH anneaux_corr7 AS (                                                                                                 -- Étape 1 : extraction des anneaux extérieurs et intérieurs
							 SELECT path1,                                                                                                      -- Identifiant du polygone
									' || 0 || ' AS ring_index,                                                                                  -- Index logique pour l’anneau extérieur
									ST_ExteriorRing(geom) AS geom                                                                               -- Extraction du contour extérieur du polygone
							 FROM ' || quote_ident(schema_zonage_travail) || '.' ||quote_ident(r.insee || '_zonage_corr7') || '                 -- Source : polygones recalés (corr7)
							 
							 UNION ALL                                                                                                          -- Ajout des anneaux intérieurs
							 
							 SELECT path1,                                                                                                      -- Identifiant du polygone
									n AS ring_index,                                                                                            -- Numéro de l’anneau intérieur
									ST_InteriorRingN(geom, n) AS geom                                                                           -- Extraction du nième anneau intérieur
							 FROM ' || quote_ident(schema_zonage_travail) || '.' ||quote_ident(r.insee || '_zonage_corr7') || '                 -- Même source : table corr7
							 CROSS JOIN generate_series(1, ST_NumInteriorRings(geom)) AS n                                                      -- Génère la série d’indices des anneaux internes
						),
						zcorr7_segments AS (                                                                                                    -- Étape 2 : décomposition des anneaux en segments élémentaires
							 SELECT acorr7.path1,                                                                                               -- Identifiant du polygone d’origine
								   acorr7.ring_index,                                                                                           -- Identifiant de l’anneau (0 = extérieur, >0 = intérieur)
								   (ST_DumpSegments(acorr7.geom)).path AS segment_path,                                                         -- Index hiérarchique unique du segment
								   (ST_DumpSegments(acorr7.geom)).geom AS segment_geom                                                          -- Géométrie LINESTRING du segment
							 FROM anneaux_corr7 AS acorr7                                                                                       -- Source : CTE précédent (anneaux_corr7)
						),
						segments AS (                                                                                                           -- Étape 3 : détection des segments à compléter
							 SELECT DISTINCT 
									zcorr7_segments.path1,                                                                                      -- Identifiant du polygone
									zcorr7_segments.ring_index,                                                                                 -- Identifiant de l’anneau
									zcorr7_segments.segment_path,                                                                               -- Identifiant unique du segment
									zcorr7_segments.segment_geom                                                                                -- Géométrie du segment
							 FROM zcorr7_segments
							 JOIN ' || quote_ident(schema_zonage_travail) || '.' ||quote_ident(r.insee || '_pt_parcelle_fuseau_zu') || ' AS ppf -- Table des points de parcelles du fuseau
							 ON ST_DWithin(zcorr7_segments.segment_geom, ppf.geom, ' || recalage_3 || ')                                        -- Points situés à moins de la distance de recalage (ex. 0.5 m)
							 AND NOT ST_Intersects(zcorr7_segments.segment_geom, ppf.geom)                                                      -- Exclut les points déjà positionnés sur le segment
						), 
						points AS (                                                                                                             -- Étape 4 : association des points de parcelles aux segments concernés
							 SELECT segments.path1,                                                                                             -- Identifiant du polygone
									segments.ring_index,                                                                                        -- Identifiant de l’anneau
									segments.segment_path,                                                                                      -- Identifiant unique du segment associé
									ppf.geom AS point_geom                                                                                      -- Géométrie du point candidat à insérer
							 FROM segments
							 JOIN ' || quote_ident(schema_zonage_travail) || '.' ||quote_ident(r.insee || '_pt_parcelle_fuseau_zu') || ' AS ppf -- Table : points de parcelles issus du fuseau
							 ON ST_DWithin(segments.segment_geom, ppf.geom, ' || recalage_3 || ')                                               -- Distance maximale de recalage (ex. 0.5 m)
							 AND NOT ST_Intersects(segments.segment_geom, ppf.geom)                                                             -- Exclut les points déjà sur le segment
						),
						points_with_distance AS (                                                                                               -- Étape 5 : calcul de la distance du point au premier nœud du segment
							 SELECT points.path1,                                                                                               -- Identifiant du polygone
									points.ring_index,                                                                                          -- Identifiant de l’anneau
									points.segment_path,                                                                                        -- Identifiant unique du segment associé
									ST_Distance(points.point_geom, ST_PointN(segments.segment_geom, 1)) AS distance,                            -- Distance entre le point et le premier nœud du segment
									points.point_geom AS point_geom                                                                             -- Géométrie du point à intégrer dans la ligne
							 FROM points
							 JOIN segments                                                                                                      -- Association à la géométrie source du segment
							 ON points.path1 = segments.path1                                                                                   -- Condition : Correspondance par polygone
							 AND points.ring_index = segments.ring_index                                                                        -- Condition : Correspondance par anneau
							 AND points.segment_path = segments.segment_path                                                                    -- Condition : Correspondance par segment
						),
						combined_points AS (                                                                                                    -- Étape 6 : combinaison des points candidats et des sommets natifs du segment
							 SELECT path1,                                                                                                      -- Identifiant du polygone
									ring_index,                                                                                                 -- Identifiant de l’anneau
									segment_path,                                                                                               -- Identifiant unique du segment
									point_geom,                                                                                                 -- Géométrie du point candidat
									distance                                                                                                    -- Distance au premier nœud du segment
							 FROM points_with_distance                                                                                          -- Source : points de recalage
							 
							 UNION ALL                                                                                                          -- Ajout des sommets existants du segment d’origine
							 
							 SELECT path1,                                                                                                      -- Identifiant du polygone
									ring_index,                                                                                                 -- Identifiant de l’anneau
									segment_path,                                                                                               -- Identifiant unique du segment
									ST_PointN(segments.segment_geom, generate_series(1, ST_NumPoints(segments.segment_geom))) AS point_geom,    -- Extraction de chaque sommet du segment
									ST_Distance(                                                                                                -- Distance entre chaque sommet et le premier nœud
									   ST_PointN(segments.segment_geom, generate_series(1, ST_NumPoints(segments.segment_geom))),
									   ST_PointN(segments.segment_geom, 1)
									) AS distance
							 FROM segments
						),
						segments_complets AS (                                                                                                  -- Étape 7 : reconstruction des segments complétés
							 SELECT path1,                                                                                                      -- Identifiant du polygone
									ring_index,                                                                                                 -- Identifiant de l’anneau
									segment_path,                                                                                               -- Identifiant du segment reconstruit
									ST_MakeLine(point_geom ORDER BY distance) AS geom                                                           -- Reconstruction ordonnée du segment à partir des points triés
							 FROM combined_points
							 GROUP BY path1, ring_index, segment_path                                                                           -- Un segment complet par combinaison unique
						),
						segments_final AS (                                                                                                     -- Étape 8 : fusion des segments complétés et des segments inchangés
							 SELECT path1,                                                                                                      -- Identifiant du polygone
									ring_index,                                                                                                 -- Identifiant de l’anneau
									segment_path,                                                                                               -- Chemin unique du segment
									geom                                                                                                        -- Géométrie du segment complété
							 FROM segments_complets                                                                                             -- Source : segments recalés
							 
							 UNION ALL                                                                                                          -- Ajout des segments non modifiés
						
							 SELECT zcorr7_segments.path1,                                                                                      -- Identifiant du polygone
									zcorr7_segments.ring_index,                                                                                 -- Identifiant de l’anneau
									zcorr7_segments.segment_path,                                                                               -- Chemin unique du segment d’origine
									zcorr7_segments.segment_geom AS geom                                                                        -- Géométrie d’origine (non recalée)
							 FROM zcorr7_segments
							 LEFT JOIN segments_complets                                                                                        -- Exclut les segments déjà recalés
							 ON zcorr7_segments.path1 = segments_complets.path1
							 AND zcorr7_segments.ring_index = segments_complets.ring_index
							 AND zcorr7_segments.segment_path = segments_complets.segment_path
							 WHERE segments_complets.segment_path IS NULL                                                                       -- Garde uniquement les segments non recalés
						),
						anneaux_final AS (                                                                                                      -- Étape 9 : reconstruction des anneaux à partir des segments
							 SELECT path1,                                                                                                      -- Identifiant du polygone
									ring_index,                                                                                                 -- Identifiant de l’anneau (0 = extérieur, >0 = intérieur)
									ST_MakeLine(segments_final.geom ORDER BY segment_path) AS geom                                              -- Reconstruction ordonnée des anneaux
							 FROM segments_final
							 GROUP BY path1, ring_index                                                                                         -- Un anneau complet par combinaison unique
						),
						anneaux_boucles AS (                                                                                                    -- Étape 10 : fermeture des anneaux
							 SELECT path1,                                                                                                      -- Identifiant du polygone
									ring_index,                                                                                                 -- Identifiant de l’anneau
									ST_AddPoint(anneaux_final.geom, ST_StartPoint(anneaux_final.geom)) AS geom                                  -- Fermeture du contour
							 FROM anneaux_final
						),
						macro_anneaux AS (                                                                                                      -- Étape 11 : filtrage des anneaux significatifs
							 SELECT path1,                                                                                                      -- Identifiant du polygone
									ring_index,                                                                                                 -- Identifiant de l’anneau (0 = extérieur, >0 = intérieur)
									geom                                                                                                        -- Géométrie de l’anneau bouclé
							 FROM anneaux_boucles
							 WHERE ST_Area(                                                                                                     -- Calcul de la surface de l’anneau converti en polygone
									  ST_CollectionExtract(                                                                                     -- Extrait uniquement les polygones (type 3)
										 ST_MakeValid(                                                                                          -- Corrige les géométries invalides
											ST_MakePolygon(geom)),                                                                              -- Ferme la géométrie en surface
										 3)
								   ) > 1                                                                                                        -- Seuil minimal de 1 m² pour exclure les artefacts
						),
                        reconstruction_pg AS (                                                                                                  -- Étape 12 : reconstruction polygonale complète
                             SELECT path1,                                                                                                      -- Identifiant du polygone
                                    ST_SetSRID(                                                                                                 -- Définit le système de coordonnées EPSG:2154
                                        ST_Multi(                                                                                               -- Convertit en MultiPolygon
                                            ST_CollectionExtract(                                                                               -- Extrait uniquement les polygones (type 3)
                                                ST_MakeValid(                                                                                   -- Corrige la validité géométrique
                                                    ST_MakePolygon(                                                                             -- Construit le polygone complet
														-- MAX(macro_anneaux.geom) FILTER (WHERE ring_index = 0),                               -- Rédaction du code non conforme pouvant générer des erreurs
                                                        (ARRAY_AGG(macro_anneaux.geom) FILTER (WHERE ring_index = 0))[1],                       -- Anneau extérieur (un seul car path1 intégré dans le SELECT)
                                                        ARRAY_AGG(geom) FILTER (WHERE ring_index > 0))),                                        -- Anneaux intérieurs éventuels
                                                3)),
                                        2154) AS geom                                                                                           -- Géométrie résultante reprojetée en 2154     
                             FROM macro_anneaux
                             GROUP BY path1                                                                                                     -- Un polygone final par identifiant
                        )
						SELECT ST_SetSRID(                                                                                                      -- Étape 13 : normalisation du système de coordonnées
								  ST_Multi(                                                                                                     -- Conversion en MultiPolygon (standard homogène)
									 ST_CollectionExtract(                                                                                      -- Extrait uniquement les entités polygonales (type 3)
										ST_MakeValid(                                                                                           -- Corrige d’éventuelles géométries invalides après union
												 ST_Union(geom)),                                                                               -- Fusion spatiale des polygones recalés
											 3)),
								   2154) AS geom                                                                                                -- Géométrie résultante reprojetée en 2154
						FROM reconstruction_pg;';                                                                                               -- Source : polygones reconstruits
						
						EXECUTE                                                                                                              
						'CREATE INDEX idx_'  || r.insee || '_zonage_corrige_geom                                                            
						ON ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corrige') || '                   
						USING gist (geom);';                                                                                                
						
						RAISE NOTICE 'Fin de la correction du zonage pour la commune %', r.insee;                                               -- Message de suivi d’exécution (journalisation)
		    
			END LOOP;
	
		    RAISE NOTICE 'Fin de la correction des zonage';

			--*------------------------------------------------------------------------------------*--
			--  Assemblage des entités dans une couche globale
			--  Objectif : fusionner toutes les tables communales recalées (suffixe "_corrige")
			--  dans une table unique départementale, géométriquement homogène et indexée.
			--*------------------------------------------------------------------------------------*--
			EXECUTE                                                                                                                            -- Exécution dynamique : suppression de la table existante
				'DROP TABLE IF EXISTS ' || quote_ident(schema_zonage_resultat) || '.' || quote_ident(table_zonage_dept) || ' CASCADE;'; 

			EXECUTE                                                                                                                            -- Exécution dynamique : création de la table globale
				'CREATE TABLE ' || quote_ident(schema_zonage_resultat) || '.' || quote_ident(table_zonage_dept) || ' (                         -- Création de la table départementale
				     insee CHAR(5),                                                                                                            -- Code INSEE de la commune
				     geom GEOMETRY(MultiPolygon, 2154)                                                                                         -- Géométrie en Lambert-93
				);
				
				CREATE INDEX idx_' || table_zonage_dept || '_geom                                                                              -- Création de l’index spatial GiST
				ON ' || quote_ident(schema_zonage_resultat) || '.' || quote_ident(table_zonage_dept) || '                                      -- Table cible
				USING gist (geom);';                                                                                                           -- Indexation de la colonne géométrique
				
			FOR r IN (                                                                                                                         -- Boucle sur les tables communales recalées
				 SELECT DISTINCT 
					    tablename,                                                                                                             -- Nom complet de la table
					    LEFT(tablename, 5) AS insee                                                                                            -- Extraction du code INSEE
				 FROM pg_catalog.pg_tables 
				 WHERE schemaname = schema_zonage_travail                                                                                      -- Schéma de travail
				 AND RIGHT(tablename, 7) = 'corrige'                                                                                           -- Tables suffixées "_corrige"
			)
			LOOP
				 EXECUTE                                                                                                                       -- Insertion dynamique des géométries recalées
					 'INSERT INTO ' || quote_ident(schema_zonage_resultat) || '.' || quote_ident(table_zonage_dept) || '                       -- Insertion dans la table départementale
					  (insee, geom)
					  SELECT ' || quote_literal(r.insee) || ', zc.geom                                                                         -- Code INSEE + géométrie recalée
					  FROM ' || quote_ident(schema_zonage_travail) || '.' || quote_ident(r.insee || '_zonage_corrige') || ' AS zc;';           -- Source : table communale corrigée
			END LOOP;                                                                                                                          -- Fin de la boucle sur les communes
			
			RAISE NOTICE 'Fin de l''assemblage dans la couche %.%', schema_zonage_resultat, table_zonage_dept;                                 -- Journalise la fin de l’assemblage
			
			--*------------------------------------------------------------------------------------*--
			--  Suppression du schéma de travail
			--  Objectif : nettoyer l’espace temporaire après l’assemblage des zonages recalés
			--*------------------------------------------------------------------------------------*--
			EXECUTE                                                                                                                           -- Exécution dynamique : suppression complète du schéma de travail
				'DROP SCHEMA ' || quote_ident(schema_zonage_travail) || ' CASCADE;';                                                          -- Supprime le schéma temporaire et toutes ses dépendances (tables, index, vues)

END$$;                                                                                                                                        -- Fin du bloc PL/pgSQL anonyme
