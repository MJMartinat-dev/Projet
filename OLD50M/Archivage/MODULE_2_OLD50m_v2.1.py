# -*- coding: utf-8 -*-
"""
MODULE_2_OLD50m_v2.1.py — Exécution automatisée du module OLD50m pour le département de la Drôme
Auteur : MJMartinat
Objectif : Générer les zones d’obligation légale de débroussaillement (OLD) a 50m a l'échelle départementale
"""

import os, logging, pandas as pd
from sqlalchemy import create_engine, text

# =============================================================================
# CONFIGURATION DU CONTEXTE DEPARTEMENTAL (DRÔME)
# =============================================================================

DEPT = 'XX'

# Schemas
SCHEMA_BDTOPO   = 'r_bdtopo'
SCHEMA_CADASTRE = 'r_cadastre'
SCHEMA_PUBLIC   = 'public'
SCHEMA_PARCELLE = f'{DEPT}_old50m_parcelle'
SCHEMA_BATI     = f'{DEPT}_old50m_bati'
SCHEMA_RESULTAT = f'{DEPT}_old50m_resultat'

# Tables
TABLE_COMMUNE      = 'geo_commune'
TABLE_PARCELLE     = 'parcelle_info'
TABLE_UF           = 'geo_unite_fonciere'
TABLE_BATI         = 'batiment'
TABLE_CIMETIERE    = 'cimetiere'
TABLE_INSTALLATION = 'zone_d_activite_ou_d_interet'
TABLE_ZONAGE       = f'{DEPT}_zonage_global'
TABLE_OLD200M      = 'old200m'
TABLE_EOLIEN       = 'eolien_filtre'

# Base de donnees
DB_CONFIG = {
    "host": "localhost",
    "port": "port",
    "dbname": "nom_database",
    "user": "nom_utilisateur",
    "password": "mdp_utilisateur"
}

# =============================================================================
# INITIALISATION DU MOTEUR ET DES LOGS
# =============================================================================

engine = create_engine(
    f"postgresql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@"
    f"{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}?client_encoding=UTF8",
    future=True
)

LOG_FILE = r"C:\Users\NomUtilisateur\Documents\WOLD50M\log\log_outil_old50m.log"
logging.basicConfig(
    filename=LOG_FILE, level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s", datefmt="%Y-%m-%d %H:%M:%S",
    encoding='utf-8'
)
logging.getLogger().addHandler(logging.StreamHandler())

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

def get_communes(limit=None):
    """Récupère la liste des communes concernées par l’OLD200m."""
    query = f"""
        SELECT DISTINCT c.idu, c.tex2
        FROM {SCHEMA_CADASTRE}.{TABLE_COMMUNE} c
        JOIN {SCHEMA_PUBLIC}.{TABLE_OLD200M} o
        ON ST_Intersects(c.geom, o.geom)  -- Toutes les communes qui touchent
        WHERE 
         -- Filtrer pour garder seulement celles significativement impactées
         ST_Area(ST_Intersection(c.geom, o.geom)) / ST_Area(c.geom) > 0.01
         -- ou un seuil absolu en m²
         -- ST_Area(ST_Intersection(c.geom, o.geom)) > 5000
        ORDER BY c.idu
    """
    if limit:
        query += f" LIMIT {limit}"
    with engine.connect() as conn:
        return pd.read_sql(query, conn)


def prepare_sql_for_commune(raw_sql, insee, idu):
    """Injecte dynamiquement les variables dans le SQL a exécuter pour chaque commune."""
    context = {
        'insee': f"{DEPT}{idu}",
        'idu': idu,
        'code_commune': f"{DEPT}0{idu}",
        'schema_travail': f"{insee}_wold50m",

        # Schemas globaux
        'SCHEMA_BDTOPO': SCHEMA_BDTOPO,
        'SCHEMA_CADASTRE': SCHEMA_CADASTRE,
        'SCHEMA_PUBLIC': SCHEMA_PUBLIC,
        'SCHEMA_PARCELLE': SCHEMA_PARCELLE,
        'SCHEMA_BATI': SCHEMA_BATI,
        'SCHEMA_RESULTAT': SCHEMA_RESULTAT,

        # Tables
        'TABLE_COMMUNE': TABLE_COMMUNE,
        'TABLE_PARCELLE': TABLE_PARCELLE,
        'TABLE_UF': TABLE_UF,
        'TABLE_BATI': TABLE_BATI,
        'TABLE_CIMETIERE': TABLE_CIMETIERE,
        'TABLE_INSTALLATION': TABLE_INSTALLATION,
        'TABLE_ZONAGE': TABLE_ZONAGE,
        'TABLE_OLD200M': TABLE_OLD200M,
        'TABLE_EOLIEN': TABLE_EOLIEN,
    }

    for key, value in context.items():
        raw_sql = raw_sql.replace(f"{{{key}}}", value)

    return raw_sql

def execute_module(insee, idu, tex2, sql_template):
    logging.info(f"--- Début traitement {insee}_{tex2} ---")
    sql_script = prepare_sql_for_commune(sql_template, insee, idu)
    try:
        with engine.begin() as conn:
            # Découpe les instructions SQL par point-virgule
            for statement in sql_script.strip().split(';'):
                if statement.strip():  # ignore les lignes vides
                    conn.execute(text(statement + ';'))
        logging.info(f"--- Fin traitement {insee}_{tex2} ---")
    except Exception as e:
        logging.error(f"Erreur sur {insee}_ ({tex2}) : {e}")

def fmt(t):  # transforme une durée au format hh:mm:ss
    h = int(t // 3600)
    m = int((t % 3600) // 60)
    s = int(t % 60)
    return f"{h:02d}:{m:02d}:{s:02d}"

# =============================================================================
# MODULE SQL EMBARQUE (a completer)
# =============================================================================

MODULE_SQL = """
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----  OLD50M   Traitements sous PostgreSQL/PostGIS pour déterminer les obligations légales                    ----
----           de débroussaillement (OLD) de chaque propriétaire d'une commune                                ----
----  Auteurs         : Frédéric Sarret, Marie-Jeanne Martinat                                                ----
----  Version         : 2.1 global                                                                           ----
----  License         : GNU GENERAL PUBLIC LICENSE  Version 3                                                 ----
----  Documentation   : https://gitlab-forge.din.developpement-durable.gouv.fr/frederic.sarret/old_50m/       ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----   INTEGRATION DU CODE INSEE DE LA COMMUNE CONCERNEE                                                      ----
----                                                                                                          ----
----   Remplacer "{code_commune}" avec le code INSEE de la commune                                            ----
----   Remplacer "{insee}" par le code INSEE de la commune                                                    ----
----   Remplacer "{idu}" par les 3 derniers chiffres de ce code INSEE                                         ----
----                                                                                                          ----
----   Exemple pour la commune de CASSIS dont le code INSEE est 13022                                         ----
----   Remplacer "{code_commune}" par "130022"                                                                ----
----   Remplacer "{insee}" par "13022"                                                                        ----
----   Et remplacer "{idu}" par "022"                                                                         ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

-- ======================================================
-- CRÉATION DU SCHÉMA DE TRAVAIL
-- Objectif : définir l’espace principal des tables intermédiaires de traitement
-- ======================================================
DROP SCHEMA IF EXISTS "{schema_travail}" CASCADE;            -- Supprime le schéma de travail s’il existe déja
CREATE SCHEMA "{schema_travail}";                            -- Crée le schéma de travail


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----                                             PARTIE I                                                     ----
----                          EXTRACTION DES PARCELLES CADASTRALES DE LA COMMUNE                              ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                              ----
---- - Extraire toutes les parcelles cadastrales situées dans la commune ayant pour code insee : {insee}.     ----
---- - Créer une table dédiée, optimisée et géographiquement validée pour l'analyse spatiale.                 ----
---- - Préparer la base cadastrale de référence pour les analyses des obligations légales de                  ----
----   débroussaillement (OLD).                                                                               ----
--*------------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                   ----
----                                                                                                          ----
---- - **Sélection des données sources** :                                                                    ----
----   - Extraction depuis la table `parcelle_info` du schéma `r_cadastre` (plugin cadastre de QGIS).         ----
----   - Filtrage des parcelles appartenant a la commune {insee} via les 6 premiers caractères de             ----
----     geo_parcelle = '{code_commune}'.                                                                     ----
----                                                                                                          ----
---- - **Validation et transformation géométrique** :                                                         ----
----   - Correction des géométries invalides avec ST_MakeValid.                                               ----
----   - Extraction et conversion en MultiPolygon avec ST_CollectionExtract.                                  ----
----   - Projection en Lambert 93 (SRID 2154).                                                                ----
----                                                                                                          ----
---- - **Optimisation** :                                                                                     ----
----   - Création d'un index spatial GIST sur la colonne géométrie pour améliorer les performances            ----
----     des requêtes spatiales.                                                                              ----
--*------------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                     ----
---- - Une table `{insee}_parcelle` contenant toutes les parcelles cadastrales de la commune {insee}.         ----
---- - Données géométriquement valides et prêtes pour l'analyse dans un SIG (QGIS, etc.).                     ----
---- - Requêtes spatiales optimisées grâce a l'indexation GIST.                                               ----
--*------------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                             ----
---- - ST_MakeValid : garantit la correction des erreurs topologiques (auto-intersections, polygones          ----
----   dégénérés, etc.).                                                                                      ----
---- - ST_CollectionExtract(type 3) : force le type Polygon/MultiPolygon et élimine les artefacts             ----
----   géométriques non polygonaux.                                                                           ----
---- - Filtrage LEFT(geo_parcelle, 6) = '{code_commune}' : sélection précise et performante sur le code       ----
----   commune (alternative au filtre sur codecommune qui peut contenir des valeurs NULL).                    ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_commune_buffer" : Zone tampon d'analyse péri-communale 
---- Description : Génère un buffer de 100m autour de la commune sélectionnée pour capturer les éléments cadastraux
--                 extérieurs (bâtiments, parcelles) susceptibles d'influencer le calcul des Obligations Légales
--                 de Débroussaillement (OLD) de 50m en limite communale. Cette approche garantit la complétude de
--                 l'analyse en zone transfrontalière.
--
---- Crédits     : Méthode développée par l'équipe géomatique DDTM33 (Gironde)
--
---- Attributs   : -> geo_commune : Code INSEE de la commune (VARCHAR)
--                 -> geom        : Zone tampon 100m (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_commune_buffer" CASCADE;

CREATE TABLE "{schema_travail}"."{insee}_commune_buffer" AS			
SELECT c.geo_commune,                                 			           -- Identifiant de la commune (code_commune)
       ST_Buffer(c.geom, 100)                                             -- Tampon de 100m autour du contour communal
	      ::GEOMETRY(MULTIPOLYGON, 2154) AS geom                
FROM {SCHEMA_CADASTRE}.{TABLE_COMMUNE} AS c                               -- Source : référentiel géographique communal issu des fichiers fonciers
WHERE c.geo_commune = '{code_commune}';                                   -- Filtre : quand les codes communes sont égaux 
                                                                          
CREATE INDEX idx_{insee}_commune_buffer 
ON "{schema_travail}"."{insee}_commune_buffer" 
USING GIST (geom);


--*------------------------------------------------------------------------------------------------------------*--
    
---- Création de la table "{insee}_commune_adjacente" : Identification des communes limitrophes 
---- Description : Identifie les communes adjacentes a la commune cible par intersection spatiale avec le tampon
--                 de 100m. Permet d'inclure les éléments cadastraux (bâtiments, parcelles) des communes
--                 voisines en zone transfrontalière dans l'analyse OLD. Les entités situées a moins de 50m de
--                 part et d'autre de la limite communale sont ainsi intégrées pour garantir la partie 
--                 réglementaire du calcul de débroussaillement.
--
---- Méthode     : Intersection spatiale (ST_Intersects) entre les contours communaux et 
--                 le buffer 100m, avec exclusion explicite de la commune cible.
--
---- Attributs   : -> geo_commune : Code INSEE de la commune adjacente (VARCHAR)
--                 -> geom        : Contour géographique de la commune (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_commune_adjacente" CASCADE; 																	

CREATE TABLE "{schema_travail}"."{insee}_commune_adjacente" AS 
SELECT DISTINCT 
       c.geo_commune,                                     				   -- Code commune de la commune limitrophe
       c.geom                                             				   -- Géométrie de la commune adjacente
FROM {SCHEMA_CADASTRE}.{TABLE_COMMUNE} AS c                               -- Source : référentiel géographique communal issu des fichiers fonciers
WHERE ST_Intersects(                                      			       -- Filtre : Intersection entre le tampon de 100m et les communes avoisinantes
         c.geom, 
         (SELECT geom 
          FROM "{schema_travail}"."{insee}_commune_buffer"))   		   -- Source : tampon de 100m autour de la commune cible
AND c.geo_commune != '{code_commune}';                            		   -- Exclusion explicite de la commune cible
                                                                          
CREATE INDEX idx_{insee}_commune_adjacente 
ON "{schema_travail}"."{insee}_commune_adjacente" 
USING GIST (geom);                													


--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_parcelle" : Parcelles cadastrales communales et adjacentes
---- Description : Extraction des parcelles de la commune cible (code INSEE : {insee}) ainsi que de celles
--                 des communes limitrophes comprises dans la zone tampon de 100 m. La table consolide les entités 
--                 cadastrales pertinentes pour l’analyse OLD en limite communale.
--
---- Méthode     : - Sélection par code INSEE (commune + adjacentes)
--                 - Filtrage spatial par intersection avec le buffer communal
--                 - Correction topologique (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du système de coordonnées (SRID 2154)
--
---- Attributs   : -> idu             : Identifiant unique de la parcelle
--                 -> geo_parcelle    : Code cadastral de la parcelle
--                 -> comptecommunal  : Identifiant du compte communal du propriétaire
--                 -> codecommune     : Code INSEE tronqué a 3 chiffres
--                 -> geom            : Géométrie valide (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{SCHEMA_PARCELLE}"."{insee}_parcelle";  					

CREATE TABLE "{SCHEMA_PARCELLE}"."{insee}_parcelle" AS
SELECT pi.idu,                                  										-- Identifiant unique de la parcelle
       pi.geo_parcelle,                                     							-- Numéro cadastral complet
       pi.comptecommunal,                                   							-- Compte communal du propriétaire
       pi.codecommune,                                     							-- 3 derniers chiffres du code INSEE
       ST_SetSRID(                                          							-- Définit le SRID en 2154 (RGF93 / Lambert-93)
          ST_CollectionExtract(                             							-- Extrait uniquement les entités polygonales valides (type 3)
             ST_MakeValid(pi.geom),                         							-- Corrige les géométries invalides 
             3),                                            							-- Type 3 = POLYGON / MULTIPOLYGON
       2154) AS geom                                        							-- Géométrie résultante normalisée en Lambert-93
FROM   {SCHEMA_CADASTRE}.{TABLE_PARCELLE} AS pi                       				    -- Source : référentiel géographique parcellaire issu des fichiers fonciers
WHERE (LEFT(pi.geo_parcelle, 6) = '{code_commune}'                  					-- Filtre : Egalité entre les 6 premiers chiffres des geo_parcelle et le code commune cible 
	   OR LEFT(pi.geo_parcelle, 6)                                                     -- Filtre : ou égalité entre les 6 premiers chiffres des geo_parcelle et le code commune des communes limitrophes
	      IN (SELECT geo_commune                                                    
          FROM "{schema_travail}"."{insee}_commune_adjacente")) 					    -- Source : Communes adjacentes intégrées
AND ST_Intersects(                                        							    -- Filtre : Intersection entre les parcelles et la commune cible et son tampon de 100m
       (SELECT geom 
        FROM "{schema_travail}"."{insee}_commune_buffer"),                            -- Source : Commune cible et son tampon de 100m
       pi.geom);                                         							
		
ALTER TABLE "{SCHEMA_PARCELLE}"."{insee}_parcelle"
ALTER COLUMN geom 
TYPE geometry(MULTIPOLYGON, 2154)
USING ST_SetSRID(geom, 2154);

CREATE INDEX idx_{insee}_parcelle_geom 
ON "{SCHEMA_PARCELLE}"."{insee}_parcelle"
USING GIST (geom);


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----                                       PARTIE II :                                                        ----
----                                     UNITÉS FONCIÈRES                                                     ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                              ----
---- - Regrouper les unités foncières de la commune {insee} par compte communal.                              ----
---- - Fusionner les géométries de toutes les unités foncières appartenant a un même compte communal.         ----
---- - Produire une couche spatiale homogène, typée MultiPolygon, représentant les emprises foncières         ----
----   consolidées par propriétaire.                                                                          ----
---- - Préparer une table de référence fiable pour l'analyse des responsabilités foncières et des zones       ----
----   d'obligation de débroussaillement (OLD).                                                               ----
--*------------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                   ----
---- - Sélection des unités foncières de la table `geo_unite_fonciere` pour la commune {insee}.               ----
---- - Filtrage sur les 6 premiers caractères du compte communal {code_commune}.                              ----
---- - Agrégation des géométries par compte communal avec ST_Union.                                           ----
---- - Nettoyage géométrique systématique : correction des invalidités (ST_MakeValid), extraction des         ----
----   polygones (ST_CollectionExtract), conversion en MultiPolygon.                                          ----
---- - Projection en Lambert 93 (SRID 2154) et indexation spatiale pour améliorer les performances.           ----
--*------------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                     ----
---- - Une couche consolidée des unités foncières par compte communal, prête a être croisée avec les          ----
----   autres couches (bâtiments, parcelles, zones OLD, etc.).                                                ----
--*------------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                             ----
---- - ST_Union : fusionne toutes les géométries d'unités foncières ayant le même compte communal pour        ----
----   produire une emprise unique par propriétaire.                                                          ----
---- - ST_MakeValid : garantit la validité topologique des géométries issues des unions.                      ----
---- - ST_CollectionExtract(type 3) : supprime les artefacts non polygonaux générés lors des unions.          ----
---- - Filtrage LEFT(comptecommunal, 6) = '{code_commune}' : sélection précise de la commune INSEE {insee}.   ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_ufr" : Regroupement des unités foncières par compte communal
---- Description : Agrège les unités foncières (UFR) par compte communal afin de reconstituer l’emprise foncière 
--                 consolidée de chaque propriétaire sur la commune cible et ses communes adjacentes. Cette table
--                 constitue la base de référence pour l’analyse OLD des continuités de propriété.
--
---- Méthode     : - Agrégation des géométries par compte communal
--                 - Correction topologique (ST_MakeValid)
--                 - Fusion spatiale (ST_Union)
--                 - Extraction polygonale (ST_CollectionExtract)
--                 - Harmonisation du système de coordonnées (SRID 2154 - Lambert 93)
--
---- Attributs   : -> comptecommunal : Identifiant du compte communal (propriétaire)
--                 -> geom            : Emprise foncière fusionnée (MULTIPOLYGON, Lambert-93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ufr";   									

CREATE TABLE "{schema_travail}"."{insee}_ufr" AS
WITH cte AS (
	 SELECT uf.comptecommunal,                            							-- N° de compte communal (propriétaire)
	        ST_SetSRID(                                   							-- Définit le SRID en 2154 (RGF93 / Lambert-93)
	           ST_CollectionExtract(                      							-- Extrait uniquement les entités polygonales valides
	              ST_MakeValid(                           							-- Corrige les géométries invalides
	                 ST_Union(uf.geom)),                  							-- Fusionne toutes les géométries d’un même compte communal
	              3),                                     							-- Type 3 = POLYGON / MULTIPOLYGON
	        2154) AS geom                                 							-- Géométrie finale normalisée
	 FROM   {SCHEMA_CADASTRE}.{TABLE_UF} AS uf            							-- Source : Référentiel des unités foncières issus des fichiers fonciers
	 WHERE  (LEFT(uf.comptecommunal, 6) = '{code_commune}'         				-- Filtre : Egalité entre les 6 premiers chiffres des geo_parcelle et le code commune cible 
	         OR LEFT(uf.comptecommunal, 6)                                         -- Filtre : ou égalité entre les 6 premiers chiffres des geo_parcelle et le code commune des communes limitrophes
	            IN (SELECT geo_commune 
	                FROM "{schema_travail}"."{insee}_commune_adjacente")) 		    -- Source : Communes adjacentes intégrées
	 GROUP BY uf.comptecommunal                           							-- Regroupement par compte communal
)
SELECT cte.comptecommunal,                                							-- N° de compte communal
	   cte.geom                                           							-- Géométrie résultante
FROM   cte
JOIN   "{schema_travail}"."{insee}_commune_buffer" AS combuf    					-- Source : Commune cible et son tampon de 100m
ON     ST_Intersects(combuf.geom, cte.geom);               						-- Condition : intersection avec la commune cible et son tampon

CREATE INDEX idx_{insee}_ufr_geom
ON "{schema_travail}"."{insee}_ufr"
USING GIST (geom);


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----                                             PARTIE III                                                   ----
----                               GESTION DU PARCELLAIRE NON CADASTRE                                        ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
---- OBJECTIFS :                                                                                              ----
---- - Identifier et structurer les zones non cadastrées de la commune {insee} pour faciliter                 ----
----   leur extraction dans les analyses géospatiales et dans le projet des OLD.                              ----
---- - Ces zones non cadastrées sont déduites vu que les règles ne s'appliquent pas directement sur celles-ci ----
--*------------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE :                                                                                           ----
---- - **Détection et extraction des zones non cadastrées** :                                                 ----
----   - Calcul de la différence géométrique entre les contours administratifs de la commune                  ----
----     via la couche **'geo_commune'** et les parcelles cadastrales de la couche **'{insee}_parcelle'**.    ----
----   - Stockage des zones non cadastrées dans une table dédiée **"{insee}_non_cadastre"**.                  ----
---- - **Structuration et correction des données** :                                                          ----
----   - Conversion des géométries en **MultiPolygon** pour assurer la cohérence géographique.                ----
----   - Application du **système de projection SRID 2154 (Lambert 93)** pour une précision topographique.    ----
---- - **Optimisation des performances et des traitements spatiaux** :                                        ----
----   - Création d'un **index spatial GIST** permettant d'accélérer les requêtes spatiales.                  ----
--*------------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                     ----
---- - **Couche des zones non cadastrées corrigée et optimisée** pour les requêtes spatiales                  ----
---- - **Amélioration des performances** grâce a l'indexation et a l'optimisation des données.                ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_non_cadastre" : Identification des zones non cadastrées au sein de la commune
---- Description : Détermine les secteurs du territoire communal dépourvus de parcelles cadastrées en soustrayant
--                 l’emprise parcellaire totale de la géométrie de la commune {insee}. Cette couche permet 
--                 d’identifier les zones non couvertes par le cadastre, telles que le domaine public, les espaces
--                 naturels ou forestiers.
--
---- Méthode     : - Union spatiale des parcelles cadastrées (ST_Union)
--                 - Différence géométrique avec la commune (ST_Difference)
--                 - Correction topologique (ST_MakeValid)
--                 - Extraction des polygones valides (ST_CollectionExtract)
--                 - Harmonisation du SRID (2154 - Lambert 93)
--
---- Attributs   : -> geom : Géométrie MULTIPOLYGON représentant les zones non cadastrées (SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_non_cadastre";   							

CREATE TABLE "{schema_travail}"."{insee}_non_cadastre" AS
SELECT ST_SetSRID(                                            				-- Définit le SRID en 2154 (RGF93 / Lambert-93)
          ST_CollectionExtract(                               				-- Extrait uniquement les entités polygonales valides
             ST_MakeValid(                                    				-- Corrige les géométries issues de la différence
                ST_Difference(                                				-- Soustraction géométrique : commune - emprise parcellaire
                   c.geom,                                    				-- Géométrie du contour communal (source : buffer)
                   ST_Union(p.geom))),                        				-- Fusion de toutes les parcelles en une seule géométrie
             3),                                              				-- Type 3 = POLYGON / MULTIPOLYGON
       2154) AS geom                                          				-- Géométrie résultante en Lambert-93
FROM   "{SCHEMA_PARCELLE}"."{insee}_parcelle" AS p,           				-- Source : parcelles cadastrales consolidées de la commune cible et son tampon
       "{schema_travail}"."{insee}_commune_buffer"  AS c             		-- Source : emprise communale avec son tampon de 100m
WHERE  c.geo_commune = '{code_commune}'                               		-- Filtre : Egalité entre les codes communes
GROUP BY c.geom;                                              				-- Regroupement par géométrie
                                 
CREATE INDEX idx_{insee}_non_cadastre_geom 
ON "{schema_travail}"."{insee}_non_cadastre"
USING gist (geom);                                          


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----                                             PARTIE IV                                                    ----
----                                       GESTION DES BÂTIMENTS                                              ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                              ----
---- - Produire une base géographique propre et structurée des entités bâties de la commune {insee} en raison ----
----   de la règle des OLD, où il faut débroussailler 50m autour des bâtiments.                               ----
---- - Identifier les constructions dans la zone concernée des obligations légales de débroussaillement :     ----
----   200m autour des massifs forestiers (OLD200m).                                                          ----
---- - Attribuer les comptes communaux aux bâtiments dans la zone préalablement sélectionnée.                 ----
---- - Intégrer les cimetières, campings, centrales PV, carrières et CET dans la base de données.             ----
---- - Exclure les bâtiments situés dans les périmètres des cimetières et installations spécifiques.          ----
---- - Regrouper ces entités par compte communal et générer un tampon de 50 m pour chaque groupe pour         ----
----   déterminer le périmètre a débroussailler par propriétaire.                                             ----
--*------------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                   ----
----                                                                                                          ----
---- - **Extraction des cimetières (`{insee}_bati_cimetiere`)** :                                             ----
----   - Sélection des cimetières de la BD TOPO intersectant la commune {insee}.                              ----
----   - Conversion en 2D, typage MultiPolygon, projection Lambert 93.                                        ----
----                                                                                                          ----
---- - **Extraction des installations spécifiques (`{insee}_bati_installation`)** :                           ----
----   - Sélection de 4 types d'installations via 4 CTEs :                                                    ----
----     • Campings (nature = 'Camping')                                                                      ----
----     • Centrales photovoltaïques (nature_detaillee = 'Centrale photovoltaïque')                           ----
----     • Carrières (nature = 'Carrière')                                                                    ----
----     • CET (nature_detaillee = 'Centre d'enfouissement technique')                                        ----
----   - Fusion via UNION ALL, typage MultiPolygon, projection Lambert 93.                                    ----
----                                                                                                          ----
---- - **Extraction des bâtiments habitat (`{insee}_bati_habitat`)** :                                        ----
----   - Sélection des bâtiments de la BD TOPO intersectant la commune (surface ≥ 6 m²).                      ----
----   - Exclusion des bâtiments situés dans les cimetières ET dans les installations spécifiques via         ----
----     NOT EXISTS.                                                                                          ----
----   - Standardisation géométrique : ST_MakeValid → ST_CollectionExtract → ST_Multi.                        ----
----   - Projection Lambert 93 et index spatial.                                                              ----
----                                                                                                          ----
---- - **Fusion des entités bâties (`{insee}_bati`)** :                                                       ----
----   - UNION ALL de 3 tables :                                                                              ----
----     • {insee}_bati_habitat (bâtiments hors zones exclues)                                                ----
----     • {insee}_bati_cimetiere                                                                             ----
----     • {insee}_bati_installation                                                                          ----
----   - Résultat : table unique contenant tous les types d'entités bâties et installations.                  ----
----                                                                                                          ----
---- - **Filtrage spatial en zone OLD 200m (`{insee}_bati200`)** :                                            ----
----   - Sélection DISTINCT des bâtiments intersectant la couche `old200m`.                                   ----
----   - Gestion conditionnelle des GeometryCollection via CASE.                                              ----
----   - Extraction des géométries valides en MultiPolygon.                                                   ----
----                                                                                                          ----
---- - **Rattachement aux comptes communaux (`{insee}_bati200_cc`)** :                                        ----
----   - Association en 2 étapes via 3 CTEs :                                                                 ----
----     1. bati_intersect : attribution par centroïde intersectant une unité foncière (DISTINCT ON fid)      ----
----     2. bati_non_associes : attribution au compte le plus proche (ST_Distance) pour les bâtiments non     ----
----        associés a l'étape 1                                                                              ----
----     3. bati_final : fusion des 2 résultats via UNION ALL                                                 ----
----   - Projection en L93, typage MultiPolygon, indexation.                                                  ----
----                                                                                                          ----
---- - **Fusion par compte communal (`{insee}_bati200_cc_rg`)** :                                             ----
----   - Agrégation des géométries par compte communal avec ST_Union.                                         ----
----   - Conversion en MultiPolygon via ST_Multi.                                                             ----
----   - Résultat : une emprise unique par compte communal.                                                   ----
----                                                                                                          ----
---- - **Génération des tampons de 50m (`{insee}_bati_tampon50`)** :                                          ----
----   - Application de ST_Buffer(geom, 50, 16) sur chaque regroupement par compte communal.                  ----
----   - Conversion en MultiPolygon, projection Lambert 93.                                                   ----
--*------------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                     ----
---- - Une table `{insee}_bati` contenant tous les bâtiments habitat, cimetières et installations de la       ----
----   commune {insee}.                                                                                       ----
---- - Une table `{insee}_bati200_cc` avec les bâtiments de la zone OLD200m associés a leur compte communal.  ----
---- - Une table `{insee}_bati200_cc_rg` avec les bâtiments regroupés par compte communal.                    ----
---- - Une table `{insee}_bati_tampon50` définissant la zone a débroussailler (50m) par propriétaire avec     ----
----   zones de superposition possibles entre propriétaires voisins.                                          ----
--*------------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                             ----
---- - ST_Force2D : nécessaire pour éliminer les dimensions 3D inutiles dans ce contexte.                     ----
---- - ST_Area ≥ 6 : Seuil de 6 m² pour exclure les très petites constructions non soumises a réglementation, ----
----                 sans valeur foncière ni enjeu OLD, afin d'éliminer les artefacts tout en conservant les  ----
----                 véritables bâtiments.                                                                    ----
---- - NOT EXISTS : permet d'exclure efficacement les bâtiments situés dans les zones spécifiques.            ----
---- - DISTINCT ON (fid) : garantit qu'un bâtiment n'est associé qu'a une seule unité foncière.               ----
---- - ST_CollectionExtract(type 3) : permet d'éviter les erreurs lors des unions ou buffers.                 ----
---- - UNION ALL : permet de conserver toutes les entités (habitat, cimetières, installations) dans une       ----
----               table unique sans dédoublonnage.                                                           ----
---- - ST_Buffer(..., 16) : qualité de 16 segments par quart de cercle pour des tampons lisses.               ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_bati_cimetiere" : Extraction des cimetières communaux et limitrophes
---- Description : Extrait les géométries des cimetières appartenant a la commune {insee} ainsi qu’a ses 
--                 communes adjacentes. Cette couche alimente l’analyse des contraintes foncières et 
--                 environnementales dans le cadre des OLD. Les entités sont issues de la BD TOPO et harmonisées
--                 en Lambert-93.
--
---- Méthode     : - Sélection des entités de type 'Cimetiere' dans la BD TOPO
--                 - Jointure spatiale avec la table communale du cadastre
--                 - Conversion en géométrie 2D et correction topologique
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Filtrage spatial par intersection avec le buffer communal
--
---- Attributs   : -> fid          : Identifiant fictif (NULL)
--                 -> nature       : Type d’entité ('Cimetiere')
--                 -> geo_commune  : Code INSEE de la commune
--                 -> geom         : Géométrie 2D valide (MULTIPOLYGON, Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati_cimetiere";   																			

CREATE TABLE "{schema_travail}"."{insee}_bati_cimetiere" AS
SELECT NULL::integer AS fid,                                      					-- Identifiant fictif (pas de clé primaire)
       'Cimetiere' AS nature,                                     					-- Typologie fixe de l’objet
       c.geo_commune,                                             					-- Code commune de la commune d’appartenance
       ST_SetSRID(                                                					-- Définit le SRID en 2154 (RGF93 / Lambert-93)
          ST_CollectionExtract(                                   					-- Extrait uniquement les entités polygonales valides
             ST_MakeValid(                                        					-- Corrige les géométries invalides
                ST_Force2D(r.geometrie)),                         					-- Convertit la géométrie 3D en 2D (X,Y)
             3),                                                  					-- Type 3 = POLYGON / MULTIPOLYGON
       2154) AS geom                                              					-- Géométrie résultante valide reprojetée en 2154
FROM   {SCHEMA_BDTOPO}.{TABLE_CIMETIERE} AS r                                   	-- Source : Référentiel des cimetieres issu de la BDTOPO
INNER JOIN {SCHEMA_CADASTRE}.{TABLE_COMMUNE} AS c                             	    -- Source : référentiel géographique communal issu des fichiers fonciers
ON ST_Intersects(r.geometrie, c.geom)                      				        -- Condition : le cimetière intersecte la commune
WHERE (c.geo_commune = '{code_commune}'                                   		    -- Filtre : Egalité entre les 6 premiers chiffres de la colonne geo_commune et le code commune cible 
       OR (c.geo_commune                                                           -- Filtre : ou égalité entre les 6 premiers chiffres des geo_parcelle et le code commune des communes limitrophes
           IN (SELECT geo_commune 
               FROM "{schema_travail}"."{insee}_commune_adjacente")                -- Source : Communes adjacentes intégrées
           AND ST_Intersects(                                                      -- Condition : intersection avec la commune cible et son tampon
                  (SELECT geom 
                   FROM "{schema_travail}"."{insee}_commune_buffer"),              -- Source : Commune cible et son tampon de 100m
                  r.geometrie)));                      					        

CREATE INDEX idx_{insee}_bati_cimetiere_geom 
ON "{schema_travail}"."{insee}_bati_cimetiere" 
USING GIST (geom);                            										  


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_bati_installation" : Extraction des installations spécifiques (campings, 
---- centrales, carrières, CET)
---- Description : Regroupe les installations excluantes présentes sur la commune {insee} et sur ses communes 
--                 adjacentes. Les entités concernées (campings, centrales photovoltaïques, carrières et 
--                 centres d’enfouissement technique - CET) proviennent de la BD TOPO. Cette couche identifie
--                 les occupations du sol a exclure du périmètre d’analyse OLD.
--
---- Méthode     : - Sélection des entités pertinentes dans la BD TOPO (zone_d_activite_ou_d_interet)
--                 - Classification de la nature selon les attributs 'nature' et 'nature_detaillee'
--                 - Correction topologique (ST_MakeValid + ST_CollectionExtract)
--                 - Conversion en géométrie 2D et harmonisation du SRID (2154 - Lambert 93)
--                 - Filtrage spatial par intersection avec le buffer communal de 100 m
--
---- Attributs   : -> fid          : Identifiant généré par ROW_NUMBER()
--                 -> nature       : Typologie d’installation (Camping, Centrale, Carrière, CET)
--                 -> geo_commune  : Code INSEE de la commune
--                 -> geom         : Géométrie valide en Lambert 93 (MULTIPOLYGON)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati_installation";

CREATE TABLE "{schema_travail}"."{insee}_bati_installation" AS
SELECT ROW_NUMBER() OVER (ORDER BY z.geometrie)::integer AS fid,              -- Création d'un identifiant numérique
       CASE                                                                   -- Définit la nature selon le type d'installation
           WHEN z.nature = 'Camping'                                          -- Condition : quand la nature de l'objet est camping
           THEN 'Camping'                                                     -- Met camping dans la colonne nature
           
           WHEN z.nature_detaillee = 'Centrale photovoltaïque'                -- Condition : quand la nature de l'objet est Centrale photovoltaïque
           THEN 'Centrale photovoltaïque'                                     -- Met Centrale photovoltaïque dans la colonne nature
           
           WHEN z.nature = 'Carrière'                                         -- Condition : quand la nature de l'objet est Carrière
           THEN 'Carrière'                                                    -- Met Carrière dans la colonne nature
           
           WHEN z.nature_detaillee = 'Centre d''enfouissement technique'      -- Condition : quand la nature de l'objet est Centre d''enfouissement technique'
           THEN 'Centre d''enfouissement technique'                           -- Met Centre d''enfouissement technique' dans la colonne nature
       END AS nature,                                                         -- Nature résultante
       c.geo_commune,                                                         -- N° du code commune
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (RGF93 / Lambert-93)
          ST_CollectionExtract(                                               -- Extrait uniquement les polygones valides
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_Force2D(z.geometrie)),                                     -- Géométrie convertie en 2D (projection XY)
             3),                                                              -- Type 3 = Polygone / MultiPolygon
       2154) AS geom                                                          -- Géométrie corrigée en Lambert 93
FROM {SCHEMA_BDTOPO}.{TABLE_INSTALLATION} z                                   -- Source : Référentiel des zones d'activités et d'intérêts issus de la BDTOPO
INNER JOIN {SCHEMA_CADASTRE}.{TABLE_COMMUNE} c                                -- Source : référentiel géographique communal issu des fichiers fonciers
ON ST_Intersects(z.geometrie, c.geom)                                         -- Condition : Intersection entre les installations et la commune cible
WHERE (c.geo_commune = '{code_commune}'                                       -- Filtre : Egalité des codes communes 
       OR c.geo_commune                                                       -- Filtre : ou égalité entre les 6 du code commune et le code commune des communes limitrophes
	      IN (SELECT geo_commune 
		      FROM "{schema_travail}"."{insee}_commune_adjacente"))           -- Source : Communes adjacentes intégrées
AND (z.nature = 'Camping'                                                     -- Filtre sur la nature Camping
OR z.nature_detaillee = 'Centrale photovoltaïque'                             -- Filtre sur la nature détaillée centrale PV
OR z.nature = 'Carrière'                                                      -- Filtre sur la nature Carrière
OR z.nature_detaillee = 'Centre d''enfouissement technique')                  -- Filtre sur la nature détaillée CET
AND ST_Intersects(                                                            -- Condition : intersection avec la commune cible et son tampon
       (SELECT geom 
	    FROM "{schema_travail}"."{insee}_commune_buffer"),                    -- Source : Commune cible et son tampon de 100m
	   z.geometrie);

CREATE INDEX idx_{insee}_bati_installation_geom
ON "{schema_travail}"."{insee}_bati_installation"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_bati_habitat" : Extraction des bâtiments d'habitat (hors zones excluantes)
---- Description : Identifie et extrait les bâtiments d’habitat situés dans la commune {insee}
--                 et ses communes adjacentes, tout en excluant ceux localisés dans un cimetière,
--                 un camping, une centrale photovoltaïque, une carrière ou un centre d’enfouissement
--                 technique (CET). Cette couche sert a l’analyse des zones d’habitat pertinentes
--                 dans le cadre des OLD.
--
---- Méthode     : - Sélection des bâtiments de la BD TOPO
--                 - Jointure spatiale avec la commune et les communes adjacentes
--                 - Exclusion des bâtiments situés dans des zones “excluantes”
--                 - Filtrage spatial par intersection avec le buffer communal (100 m)
--                 - Conversion en 2D, correction topologique et harmonisation du SRID (2154)
--                 - Filtrage surfacique (≥ 6 m²)
--
---- Attributs   :
--                 -> fid          : Identifiant unique du bâtiment
--                 -> nature       : Type d’objet ('Habitat')
--                 -> geo_commune  : Code INSEE de la commune
--                 -> geom         : Géométrie 2D valide (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{SCHEMA_BATI}"."{insee}_bati_habitat";                
                                                           

CREATE TABLE "{SCHEMA_BATI}"."{insee}_bati_habitat" AS
SELECT b.fid,                                                                   -- Identifiant unique du bâtiment BD TOPO
       'Habitat' AS nature,                                                     -- Valeur fixe : nature "Habitat"
       c.geo_commune,                                                           -- Code commune de la commune cible
       ST_SetSRID(                                                              -- Définit le système de coordonnées Lambert-93 (EPSG:2154)
          ST_CollectionExtract(                                                 -- Extrait uniquement les entités polygonales valides
             ST_MakeValid(                                                      -- Corrige les géométries invalides
                ST_Force2D(b.geometrie)),                                       -- Convertit la géométrie en 2D (projection XY)
             3),                                                                -- Type 3 = POLYGON / MULTIPOLYGON
       2154) AS geom                                                            -- Géométrie résultante reprojetée en Lambert-93
FROM   {SCHEMA_BDTOPO}.{TABLE_BATI} b                                           -- Source : Référentiel des batiments et d'intérêts issus de la BDTOPO
INNER JOIN {SCHEMA_CADASTRE}.{TABLE_COMMUNE} c                                  -- Source : référentiel géographique communal issu des fichiers fonciers
ON ST_Intersects(ST_Force2D(b.geometrie), c.geom)                               -- Condition : intersection entre le bâtiment et la commune
LEFT JOIN "{schema_travail}"."{insee}_bati_cimetiere" cim                       -- Source : cimetières communaux et limitrophes pour exclusion
ON ST_Intersects(ST_Force2D(b.geometrie), cim.geom)                             -- Condition : bâtiment a l’intérieur d’un cimetière
LEFT JOIN "{schema_travail}"."{insee}_bati_installation" inst                   -- Source : installations communales et limitrophes pour exclusion
ON ST_Intersects(ST_Force2D(b.geometrie), inst.geom)                            -- Condition : bâtiment dans une installation (camping, CET, etc.)
WHERE  (c.geo_commune = '{code_commune}'                                        -- Filtre : Egalité des codes communes
        OR c.geo_commune                                                        -- Filtre : ou égalité entre les 6 du code commune et le code commune des communes limitrophes
           IN (SELECT geo_commune 
               FROM "{schema_travail}"."{insee}_commune_adjacente"))            -- Source : Communes adjacentes intégrées
       AND ST_Intersects(                                                       -- Condition : intersection avec la commune cible et son tampon
           (SELECT geom 
              FROM "{schema_travail}"."{insee}_commune_buffer"),                -- Source : Commune cible et son tampon de 100m
           ST_Force2D(b.geometrie))
AND ST_Area(b.geometrie) >= 6                                                   -- Exclusion des bâtiments trop petits (< 6 m²)
AND cim.geom IS NULL                                                            -- Exclusion : pas dans un cimetière
AND inst.geom IS NULL;                                                          -- Exclusion : pas dans une installation spécifique
                                                                                
CREATE INDEX idx_{insee}_bati_habitat_geom                                       
ON "{SCHEMA_BATI}"."{insee}_bati_habitat"                                        
USING GIST (geom);                                                                       
                                                                 

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_bati" : Fusion des entités bâties et excluantes
---- Description : Fusionne l’ensemble des bâtiments issus des tables "habitat", "cimetiere" et 
--                 "installations specifiques" pour la commune {insee} et ses communes adjacentes. Cette table 
--                 constitue la couche finale regroupant toutes les entités bâties pertinentes pour l’analyse OLD.
--
---- Méthode     : - Union des trois tables sources (habitat, cimetière, installation)
--                 - Harmonisation du type géométrique (MULTIPOLYGON)
--                 - Affectation du SRID (2154 - Lambert 93)
--                 - Création d’un index spatial GIST sur la géométrie
--
---- Attributs   : -> fid          : Identifiant unique du bâtiment
--                 -> nature       : Type d’entité (Habitat, Cimetiere, Installation)
--                 -> geo_commune  : Code INSEE de la commune
--                 -> geom         : Géométrie valide en Lambert 93 (MULTIPOLYGON)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati";

CREATE TABLE "{schema_travail}"."{insee}_bati" AS                                   
SELECT *                                                                        -- Sélectionne tous les champs
FROM   "{SCHEMA_BATI}"."{insee}_bati_habitat"                                   -- Source : bâtiments de la commune cible et de sa zone tampon hors CTE
                                                                                
UNION ALL                                                                       -- Agrège les tables entre elles

SELECT *                                                                        -- Sélectionne tous les champs
FROM   "{schema_travail}"."{insee}_bati_cimetiere"                              -- Source : cimetiere de la commune cible et de sa zone tampon

UNION ALL                                                                       -- Agrège les tables entre elles

SELECT *                                                                        -- Sélectionne tous les champs
FROM   "{schema_travail}"."{insee}_bati_installation";                          -- Source : installations de la commune cible et de sa zone tampon                                                            -- Validation de la création

ALTER TABLE "{schema_travail}"."{insee}_bati"                                       
ALTER COLUMN geom 
TYPE geometry(MULTIPOLYGON, 2154)                            
USING ST_SetSRID(geom, 2154);                                                                                                                        

CREATE INDEX idx_{insee}_bati_geom                                              
ON "{schema_travail}"."{insee}_bati"                                               
USING gist (geom);                                                                                


--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_bati200" : Bâtiments situés dans la zone de débroussaillement (200 m)
---- Description : Extrait les bâtiments intersectant la zone de débroussaillement définie a 200 mètres
--                 autour des massifs forestiers pour la commune {insee}. Cette couche permet d’identifier
--                 les constructions concernées par les obligations légales de débroussaillement (OLD)
--                 sur le périmètre forestier élargi.
--
---- Méthode     : - Intersection spatiale entre les bâtiments fusionnés et la zone OLD 200 m
--                 - Correction topologique et extraction des polygones valides
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Création d’un index spatial GIST
--
---- Attributs   : -> nature       : Typologie du bâtiment (Habitat, Cimetiere, Installation)
--                 -> fid          : Identifiant unique du bâtiment
--                 -> geo_commune  : Code INSEE de la commune
--                 -> geom         : Géométrie valide en Lambert 93 (MULTIPOLYGON)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati200";

CREATE TABLE "{schema_travail}"."{insee}_bati200" AS
SELECT DISTINCT                                                               -- Élimine les doublons potentiels
       b.nature,                                                              -- Nature du bâtiment (Habitat, Cimetiere, Camping, etc.)
       b.fid,                                                                 -- Identifiant unique du bâtiment
       b.geo_commune,                                                         -- N° du code commune de la commune cible
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (RGF93 / Lambert-93)
          ST_CollectionExtract(                                               -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(b.geom),                                            -- Corrige les géométries invalides
             3),                                                              -- Type 3 = Polygone / MultiPolygon
       2154) AS geom                                                          -- Géométrie résultante en Lambert 93
FROM "{schema_travail}"."{insee}_bati" b                                      -- Source : Bâtiments de la commune cible
INNER JOIN {SCHEMA_PUBLIC}.{TABLE_OLD200M} o                                  -- Source : Zone tampon de débroussaillement de 200m autour des massifs forestiers
ON ST_Intersects(o.geom, b.geom);                                             -- Condition : Intersection entre bâtiments et old200m

CREATE INDEX idx_{insee}_bati200_geom 
ON "{schema_travail}"."{insee}_bati200"
USING gist (geom); 


--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_bati200_cc" : Association des bâtiments avec les comptes communaux
---- Description : Associe chaque bâtiment situé dans la zone de débroussaillement (200 m autour des massifs 
--                 forestiers) a son compte communal correspondant. Cette table permet d’identifier les
--                 propriétaires ou gestionnaires responsables au regard des obligations légales de débroussaillement
--                 (OLD) sur le périmètre forestier.
--
---- Méthode     : - Association spatiale des bâtiments a leur unité foncière via intersection du centroïde
--                 - Attribution du compte communal le plus proche pour les bâtiments non intersectants
--                 - Fusion des résultats pour garantir l’unicité des identifiants
--                 - Correction topologique et harmonisation du SRID (2154 - Lambert 93)
--                 - Indexation spatiale finale sur la géométrie
--
---- Attributs   : -> fid              : Identifiant unique du bâtiment
--                 -> nature           : Type d’entité bâtie (Habitat, Cimetiere, Installation)
--                 -> comptecommunal   : Identifiant du compte communal (propriétaire)
--                 -> geom             : Géométrie valide en Lambert 93 (MULTIPOLYGON)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati200_cc";

CREATE TABLE "{schema_travail}"."{insee}_bati200_cc" AS
-- Associer les bâtiments a une seule unité foncière (évite les doublons)
WITH bati_intersect AS (
     SELECT DISTINCT ON (b200.fid)                                             -- Assigne chaque bâtiment a UNE SEULE unité foncière
            b200.fid,                                                          -- Identifiant unique du bâtiment                          
            b200.nature,                                                       -- Nature du bâtiment                         
            ufr.comptecommunal,                                                -- N° de compte communal                         
            ST_CollectionExtract(                                              -- Extrait uniquement les polygones (type 3)
               ST_MakeValid(b200.geom),                                        -- Corrige les géométries invalides
               3) AS geom                                                      -- Géométrie résultante
     FROM "{schema_travail}"."{insee}_bati200" b200                            -- Source : Bâtiments dans la zone des 200m autour des massifs forestiers              
     JOIN "{schema_travail}"."{insee}_ufr" ufr                                 -- Source : unités foncières de la commune de la commune cible et son tempon
     ON ST_Intersects(ST_Centroid(b200.geom), ufr.geom)                        -- Condition : installation entre le centroïde du bâtiment et l'unité foncière
),
-- Sélectionner les bâtiments qui ne sont pas associés a une unité foncière
bati_non_associes AS (
     SELECT b200.fid,                                                          -- Identifiant unique du bâtiment  
            b200.nature,                                                       -- Nature du bâtiment   
            ST_CollectionExtract(                                              -- Extrait uniquement les polygones (type 3)
               ST_MakeValid(b200.geom),                                        -- Corrige les géométries invalides
               3) AS geom,                                                     -- Géométrie résultante
            (SELECT ufr.comptecommunal                                         -- Recherche du compte communal de l'unité foncière la plus proche
             FROM "{schema_travail}"."{insee}_ufr" ufr                         -- Source : unités foncières de la commune
             ORDER BY ST_Distance(ST_Centroid(b200.geom), ufr.geom)            -- Ordonne par distance la plus proche entre le centroïde du bâtiment et les unités foncières
             LIMIT 1) AS comptecommunal_proche                                 -- N° de compte communal de l'unité la plus proche
     FROM "{schema_travail}"."{insee}_bati200" b200                            -- Source : Bâtiments dans la zone des 200m autour des massifs forestiers  
     LEFT JOIN bati_intersect bi                                               -- Source : Résultat de la requête précédente
     ON b200.fid = bi.fid                                                      -- Condition : Egalité des identifiants uniques des bâ tis
     WHERE bi.fid IS NULL                                                      -- Filtre : Sélectionne uniquement les bâtiments non encore associés
),
-- Fusionner les résultats en garantissant l'unicité des bâtiments
bati_final AS (
     SELECT bi.fid,                                                            -- Identifiant unique du bâtiment
            bi.nature,                                                         -- Nature du bâtiment 
            bi.comptecommunal,                                                 -- N° de compte communal
            bi.geom                                                            -- Géométrie (déja validée et extraite)
     FROM bati_intersect bi                                                    -- Source : Bâtiments associés par intersection du centroïde
    
     UNION ALL                                                                 -- Agrège les données des tables entre elles
    
     SELECT bna.fid,                                                           -- Identifiant unique du bâtiment
            bna.nature,                                                        -- Nature du bâtiment 
            bna.comptecommunal_proche AS comptecommunal,                       -- N° de compte communal (unité la plus proche)
            bna.geom                                                           -- Géométrie (déja validée et extraite)
     FROM bati_non_associes bna                                                -- Source : Bâtiments associés par proximité
)
SELECT bf.fid,                                                                 -- Identifiant unique du bâtiment
       bf.nature,                                                              -- Nature du bâtiment 
       bf.comptecommunal,                                                      -- N° de compte communal
       ST_SetSRID(bf.geom, 2154) AS geom                                       -- Définit le système de projection en Lambert 93
FROM bati_final bf;                                                            -- Source : Bâtiments dans la zone des 200m avec leurs comptes communaux

CREATE INDEX idx_{insee}_bati200_cc_geom 
ON "{schema_travail}"."{insee}_bati200_cc" 
USING GIST (geom);


--*------------------------------------------------------------------------------------------------------------*--
 
---- Création de la table "{insee}_bati200_cc_rg" : Regroupement des bâtiments de la zone 200 m par compte communal
---- Description : Regroupe et fusionne les bâtiments situés dans la zone de débroussaillement (200 m autour des
--                 massifs forestiers) selon leur N° de compte communal. Cette couche permet de consolider l’emprise
--                 bâtie par propriétaire pour l’analyse des obligations légales de débroussaillement (OLD).
--
---- Méthode     : - Agrégation des bâtiments par N° de compte communal
--                 - Fusion spatiale des géométries (ST_Union)
--                 - Correction topologique et extraction des polygones valides
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Création d’un index spatial GIST sur la géométrie
--
---- Attributs   : -> comptecommunal : Identifiant du compte communal (propriétaire)
--                 -> geom            : Géométrie fusionnée des bâtiments par compte communal (MULTIPOLYGON)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati200_cc_rg";

CREATE TABLE "{schema_travail}"."{insee}_bati200_cc_rg" AS
SELECT b200cc.comptecommunal,                                                 -- N° de compte communal
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (RGF93 / Lambert-93)
          ST_CollectionExtract(                                               -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides après fusion
                ST_Union(b200cc.geom)),                                       -- Fusionne les géométries des bâtiments en une seule entité par compte communal
             3),                                                              -- Type 3 = Polygone / MultiPolygon
       2154) AS geom                                                          -- Géométrie résultante en Lambert 93
FROM "{schema_travail}"."{insee}_bati200_cc" b200cc                           -- Source : Bâtiments associés aux comptes communaux
GROUP BY b200cc.comptecommunal;                                               -- Regroupe par N° de compte communal

CREATE INDEX idx_{insee}_bati200_cc_rg_geom 
ON "{schema_travail}"."{insee}_bati200_cc_rg"
USING gist (geom);


--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_bati_tampon50" : Génération des zones tampons de 50 m autour des bâtiments
---- Description : Crée des zones tampons de 50 mètres autour des bâtiments regroupés par compte communal.
--                 Ces tampons matérialisent les périmètres d’application des obligations légales de
--                 débroussaillement (OLD) autour des constructions. 
--
---- Méthode     : - Application d’un tampon de 50 m autour des géométries bâties regroupées
--                 - Correction topologique et extraction des entités polygonales valides
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Création d’un index spatial GIST
--
---- Attributs   : -> comptecommunal  : Identifiant du compte communal (propriétaire)
--                 -> geom            : Géométrie du tampon de 50 m autour des bâtiments (MULTIPOLYGON)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati_tampon50";

CREATE TABLE "{schema_travail}"."{insee}_bati_tampon50" AS
SELECT b200ccrg.comptecommunal,                                               -- N° de compte communal
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (RGF93 / Lambert-93)
          ST_CollectionExtract(                                               -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides générées par le tampon
                ST_Buffer(b200ccrg.geom, 50, 16)),                            -- Génère un tampon de 50m autour des bâtiments (16 segments par quart de cercle)
             3),                                                              -- Type 3 = Polygone / MultiPolygon
       2154) AS geom                                                          -- Géométrie résultante en Lambert 93
FROM "{schema_travail}"."{insee}_bati200_cc_rg" b200ccrg;                     -- Source : bâtiments regroupés par compte communal dans la zone OLD 200m

CREATE INDEX idx_{insee}_bati_tampon50_geom 
ON "{schema_travail}"."{insee}_bati_tampon50"
USING gist (geom);


--*--------------------------------------------------------------------------------------------------------------*--
--*--------------------------------------------------------------------------------------------------------------*--
----                                                                                                            ----
----                                            PARTIE V                                                        ----
----                                 CORRECTION DU ZONAGE URBAIN                                                ----
----                                                                                                            ----
--*--------------------------------------------------------------------------------------------------------------*--
--*--------------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                                ----
---- - Corriger et étendre le zonage urbain en intégrant les zones adjacentes situées dans un tampon de 100 m.  ----
---- - Fusionner les zones urbaines de la commune cible avec celles des communes limitrophes pour garantir      ----
----   la cohérence spatiale dans le cadre des opérations d'aménagement de zones urbaines.                      ----
--*--------------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                     ----
----                                                                                                            ----
---- - **Sélection des zones urbaines (`{TABLE_ZONAGE}`)** :                                                    ----
----   - Filtrage des zones urbaines de la commune cible et des communes limitrophes a partir de la couche      ----
----     `{TABLE_ZONAGE}`.                                                                                      ----
----   - Extraction des zones urbaines situées dans un buffer de 100 mètres autour de la commune cible.         ----
----                                                                                                            ----
---- - **Fusion des géométries (`ST_Union`)** :                                                                 ----
----   - Union des zones urbaines de la commune cible et de ses voisines a l’aide de la fonction spatiale       ----
----     `ST_Union`.                                                                                            ----
----   - Correction topologique des géométries invalides avec `ST_MakeValid` et extraction des entités          ----
----     polygonales valides (`ST_CollectionExtract`).                                                          ----
----                                                                                                            ----
---- - **Gestion des géométries sans données (COALESCE)** :                                                     ----
----   - Si aucune donnée n’est présente, création d’une géométrie par défaut (exemple : un petit carré         ----
----     fictif).                                                                                               ----
----   - Harmonisation du système de référence spatial (SRID 2154 – Lambert 93).                                ----
----                                                                                                            ----
---- - **Indexation spatiale** :                                                                                ----
----   - Mise en place d’un index spatial GIST pour optimiser les requêtes géographiques.                       ----
--*--------------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                       ----
---- - Une table `{insee}_zonage_elargi` contenant la géométrie fusionnée des zones urbaines élargies.          ----
---- - Une géométrie propre, corrigée et validée pour chaque zone urbaine étendue.                              ----
---- - Optimisation des requêtes sur cette table grâce a un index spatial GIST.                                 ----
--*--------------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                               ----
---- - `ST_Union` : Fusion de géométries spatiales pour un agrégat cohérent des zones urbaines.                 ----
---- - `ST_MakeValid` et `ST_CollectionExtract` : Correction et validation des géométries invalides et          ----
----   extraction de celles de type POLYGON/MULTIPOLYGON.                                                       ----
---- - `COALESCE` : Traitement des cas où les données sont absentes avec une géométrie par défaut.              ----
---- - `ST_SetSRID(2154)` : Harmonisation de toutes les géométries dans le système de coordonnées Lambert 93.   ----
---- - Indexation spatiale GIST : Amélioration des performances des requêtes géospatiales.                      ----
--*--------------------------------------------------------------------------------------------------------------*--
--*--------------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_zonage_elargi" : Union des zones U communales et limitrophes dans le buffer 
---- de 100 m
---- Description   : Agrège les zones urbaines (zones U) de la commune {insee} et de ses communes adjacentes situées
----                 dans le tampon de 100 mètres. Cette couche permet d’étendre le périmètre d’analyse aux
----                 zones urbanisées contiguës afin de garantir la cohérence spatiale entre les zonages urbains
----                 et les limites communales dans le cadre des OLD.
----
---- Méthode       : - Sélection des zones U de la commune cible et des communes limitrophes
----                 - Union spatiale des géométries (ST_Union)
----                 - Correction topologique et extraction des polygones valides (ST_MakeValid + ST_CollectionExtract)
----                 - Harmonisation du SRID (2154 - Lambert 93)
----                 - Gestion des cas sans données via une géométrie par défaut
----                 - Indexation spatiale GIST
----
---- Attributs     : -> geom : Géométrie MULTIPOLYGON représentant l’union des zones U élargies (SRID 2154)


DROP TABLE IF EXISTS "{schema_travail}"."{insee}_zonage_elargi";                                                             

CREATE TABLE "{schema_travail}"."{insee}_zonage_elargi" AS
WITH zonage_elargi AS (
	 SELECT ST_SetSRID(                                                       -- Définit le SRID en 2154 (RGF93 / Lambert-93)
	           ST_CollectionExtract(                                          -- Extrait uniquement les entités polygonales valides (type 3)
	              ST_MakeValid(                                               -- Corrige les géométries invalides 
	                 ST_Union(zcorr.geom)),                                   -- Union spatiale des zones U
	              3),                                                         -- Type 3 = POLYGON / MULTIPOLYGON
	        2154) AS geom                                                     -- Géométrie résultante en Lambert-93
	 FROM "{SCHEMA_RESULTAT}"."{TABLE_ZONAGE}" AS zcorr                       -- Source : couche du zonage urbain global (zones U)
	 WHERE zcorr.insee = '{insee}'                                            -- Filtre : égalité du code insee
	 OR CONCAT(LEFT(zcorr.insee, 2), '0', RIGHT(zcorr.insee, 3))              -- Inclusion des communes limitrophes dans le filtre
	     IN (SELECT geo_commune                                               -- Sélection des communes adjacentes
	         FROM "{schema_travail}"."{insee}_commune_adjacente")             -- Source : table des communes adjacentes, selon un buffer de 100 m
)
SELECT COALESCE(                                                              -- Renvoie la géométrie calculée ou une géométrie par défaut si aucune donnée valide
           (SELECT geom FROM zonage_elargi),                                  -- Si les zones urbaines sont valides pour la commune et ses voisines
            ST_GeomFromText(                                                   -- Sinon : création d’une géométrie symbolique par défaut
               'MULTIPOLYGON(((                                           
               648291.57 6862250.49,
               648241.57 6862200.49,
               648191.57 6862250.49,
               648241.57 6862300.49,
               648291.57 6862250.49)))',
               2154)) AS geom;                                                -- Spécification du SRID 2154 (Lambert 93) pour garantir la cohérence géographique              

CREATE INDEX idx_{insee}_zonage_elargi_geom                                   
ON "{schema_travail}"."{insee}_zonage_elargi" 
USING gist (geom);                                                                 


--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                                                                                                          ----
----                                             PARTIE VI                                                    ----
----                  ZONES TAMPONS ET INTERSECTIONS ENTRE COMPTES COMMUNAUX                                  ----
----                                                                                                          ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                              ----
---- - Identifier les zones de recouvrement entre les tampons de 50 m autour des bâtiments de différents      ----
----   comptes communaux.                                                                                     ----
---- - Retirer des tampons les parties situées en zones urbaines, qui ne sont pas soumises aux OLD.           ----
---- - Produire une zone d'arbitrage finale fusionnée pour les cas de responsabilité partagée.                ----
--*------------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                   ----
---- - **Détection des intersections de tampons (`{insee}_tampon_i`)** :                                      ----
----   - Chaque tampon de 50 m (autour des groupes de bâtiments par compte communal) est comparé aux autres.  ----
----   - Les intersections entre tampons de comptes communaux différents sont extraites.                      ----
----   - Tolérance de 1 cm (ST_DWithin) pour éviter les faux positifs dus aux erreurs d'arrondi.              ----
----   - Filtre : seules les intersections de surface > 1 m² sont conservées.                                 ----
----                                                                                                          ----
---- - **Retrait des zones urbaines (`{insee}_tampon_ihu`)** :                                                ----
----   - Les zones d'intersection sont croisées avec le zonage urbain corrigé ({insee}_zonage_elargi).        ----
----   - Si intersection avec une zone urbaine : soustraction de la partie urbaine (ST_Difference).           ----
----   - Si aucune intersection : conservation de la géométrie originale.                                     ----
----   - Validation systématique des géométries (ST_MakeValid + ST_CollectionExtract).                        ----
----                                                                                                          ----
---- - **Fusion finale (`{insee}_tampon_ihu_rg`)** :                                                          ----
----   - Toutes les zones d'intersection nettoyées sont fusionnées en un seul MultiPolygon.                   ----
----   - Résultat : zone unique d'arbitrage pour les responsabilités OLD inter-propriétaires.                 ----
--*------------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                     ----
---- - Une table `{insee}_tampon_i` avec les intersections brutes entre tampons de comptes différents.        ----
---- - Une table `{insee}_tampon_ihu` avec les intersections nettoyées des zones urbaines.                    ----
---- - Une table `{insee}_tampon_ihu_rg` avec la zone d'arbitrage finale fusionnée.                           ----
--*------------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                             ----
---- - ST_DWithin(0.01) : tolérance de 1 cm pour détecter les intersections réelles sans erreurs dues a la    ----
----   précision flottante.                                                                                   ----
---- - ST_Intersection : isole précisément les surfaces partagées entre deux tampons.                         ----
---- - ST_Difference : supprime uniquement les portions en zone urbaine pour éviter les traitements           ----
----   injustifiés dans des périmètres non soumis aux OLD.                                                    ----
---- - ST_MakeValid + ST_CollectionExtract(3) : garantit que seules des géométries polygonales valides sont   ----
----   utilisées.                                                                                             ----
---- - GROUP BY avec ST_Union : évite les doublons et fusionne les intersections multiples.                   ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_tampon_i" : Intersections des zones tampons entre comptes communaux distincts
---- Description : Identifie les zones de recouvrement entre les tampons de 50 m générés autour des bâtiments
--                 appartenant a des comptes communaux différents. Cette couche permet de repérer les secteurs 
--                 d’interférence potentielle entre propriétés soumises a l’obligation de débroussaillement. 
--
---- Méthode     : - Auto-jointure de la table des tampons de 50 m par compte communal
--                 - Pré-filtrage spatial avec ST_DWithin (optimisation index)
--                 - Calcul de l’intersection réelle des géométries (ST_Intersection)
--                 - Nettoyage des résultats nuls, vides ou invalides
--                 - Harmonisation du type géométrique (MULTIPOLYGON) et du SRID (2154 - Lambert 93)
--                 - Création d’un index spatial GIST sur la géométrie
--
---- Attributs   : -> comptecomm1 : Identifiant du premier compte communal impliqué dans l’intersection
--                 -> comptecomm2 : Identifiant du second compte communal impliqué dans l’intersection
--                 -> geom         : Géométrie de l’intersection (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_tampon_i";

CREATE TABLE "{schema_travail}"."{insee}_tampon_i" AS
SELECT t1.comptecommunal AS comptecomm1,                                      -- N° du compte communal du premier propriétaire
       t2.comptecommunal AS comptecomm2,                                      -- N° du compte communal du second propriétaire
       ST_CollectionExtract(                                                  -- Extrait uniquement les entités polygonales valides (type 3)
          ST_MakeValid(                                                       -- Corrige les géométries invalides
             ST_Intersection(t1.geom, t2.geom)),                              -- Calcule l'intersection entre les deux tampons
          3) AS geom                                                          -- MultiPolygon résultant de type 3 = POLYGON / MULTIPOLYGON
FROM "{schema_travail}"."{insee}_bati_tampon50" t1                            -- Source : tampons de 50m autour des bâtiments
JOIN "{schema_travail}"."{insee}_bati_tampon50" t2                            -- Auto-jointure : même table pour trouver les chevauchements
ON t1.comptecommunal <> t2.comptecommunal                                     -- Condition : évite les doublons (A-B = B-A) et auto-intersection (A-A)
AND ST_DWithin(t1.geom, t2.geom, 0.01)                                        -- Pré-filtre spatial : géométries a moins de 1cm (optimisation index)
AND ST_Intersects(t1.geom, t2.geom)                                           -- Test précis : intersection géométrique réelle
WHERE ST_Area(ST_Intersection(t1.geom, t2.geom)) > 1;                         -- Filtre : surface d'intersection > 1m² (élimine micro-chevauchements)

DELETE FROM "{schema_travail}"."{insee}_tampon_i"
WHERE geom IS NULL                                                          
OR ST_IsEmpty(geom)                                                       
OR NOT ST_IsValid(geom);  

ALTER TABLE "{schema_travail}"."{insee}_tampon_i"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);   

CREATE INDEX idx_{insee}_tampon_i_geom
ON "{schema_travail}"."{insee}_tampon_i"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_tampon_ihu" : Retrait des zones urbaines des tampons de 50 m
---- Description : Extrait les zones tampons de 50 mètres en retirant les surfaces recouvrant les zones
--                 urbaines. Cette couche permet d’isoler uniquement les portions de tampons situées
--                 hors des secteurs urbanisés, garantissant une analyse centrée sur les zones a
--                 débroussailler effectivement. Les tampons non concernés par les zones urbaines
--                 sont conservés intégralement.
--
---- Méthode     : - Soustraction des zones urbaines intersectant les tampons (ST_Difference)
--                 - Validation et extraction des polygones valides (ST_MakeValid + ST_CollectionExtract)
--                 - Union des résultats avec les tampons non affectés par les zones urbaines
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Harmonisation du type géométrique (MULTIPOLYGON) et du SRID (2154 - Lambert 93)
--                 - Création d’un index spatial GIST pour optimiser les traitements
--
---- Attributs   : -> comptecomm1 : Identifiant du premier compte communal impliqué
--                 -> comptecomm2 : Identifiant du second compte communal impliqué
--                 -> geom         : Géométrie du tampon corrigée après retrait des zones urbaines (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_tampon_ihu";

CREATE TABLE "{schema_travail}"."{insee}_tampon_ihu" AS
-- Tampons intersectant des zones urbaines (soustraction)
SELECT t.comptecomm1,                                                         -- N° du compte communal du propriétaire 1
       t.comptecomm2,                                                         -- N° du compte communal du propriétaire 2
       ST_CollectionExtract(                                                  -- Extrait uniquement les entités polygonales valides (type 3)
          ST_MakeValid(                                                       -- Corrige les géométries invalides
             ST_Union(                                                        -- Fusionne les différences (si plusieurs zones urbaines)
                ST_MakeValid(                                                 -- Corrige les géométries invalides
                   ST_Difference(                                             -- Soustrait la zone urbaine du tampon
                      ST_MakeValid(t.geom),                                   -- Corrige les géométries invalides du tampon
                      ST_MakeValid(zcorr.geom))))),                           -- Corrige les géométries invalides du zonage urbain
          3) AS geom                                                          -- MultiPolygon résultant de type 3 = POLYGON / MULTIPOLYGON
FROM "{schema_travail}"."{insee}_tampon_i" AS t                               -- Source : zones de recouvrement entre les tampons
JOIN "{schema_travail}"."{insee}_zonage_elargi" AS zcorr                      -- Source : zonage urbain global élagi
ON ST_Intersects(t.geom, zcorr.geom)                                          -- Condition : intersection spatiale entre les tampons et la zone urbaine
WHERE ST_Area(ST_Difference(t.geom, zcorr.geom)) > 0                          -- Filtre : Aire supérieure a 0
GROUP BY t.comptecomm1, t.comptecomm2, t.geom, zcorr.geom                     -- Regroupement par tampon et zone urbaine

UNION ALL                                                                     -- Agrège avec les tampons non affectés

-- Tampons sans intersection avec zones urbaines (conservation)
SELECT t.comptecomm1,                                                         -- N° du compte communal du propriétaire 1
       t.comptecomm2,                                                         -- N° du compte communal du propriétaire 2
       ST_CollectionExtract(                                                  -- Extrait uniquement les entités polygonales valides (type 3)
          ST_MakeValid(t.geom),                                               -- Corrige les géométries invalides
          3) AS geom                                                          -- MultiPolygon résultant de type 3 = POLYGON / MULTIPOLYGON
FROM "{schema_travail}"."{insee}_tampon_i" AS t                               -- Source : zones de recouvrement entre les tampons
WHERE NOT EXISTS (                                                            -- Condition : aucune intersection avec zone urbaine
      SELECT 1
      FROM "{schema_travail}"."{insee}_zonage_elargi" AS zcorr                -- Sous-requête : zones urbaines globale élargie
      WHERE ST_Intersects(t.geom, zcorr.geom));                               -- Vérification d'intersection

DELETE FROM "{schema_travail}"."{insee}_tampon_ihu"
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                        
OR NOT ST_IsValid(geom);                                                   

ALTER TABLE "{schema_travail}"."{insee}_tampon_ihu"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);   

CREATE INDEX idx_{insee}_tampon_ihu_geom
ON "{schema_travail}"."{insee}_tampon_ihu"
USING gist (geom);  


--------------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_tampon_ihu_rg" : Fusion des zones tampons corrigées (hors zones urbaines)
---- Description : Regroupe et fusionne l’ensemble des tampons corrigés (après retrait des zones urbaines)
--                 en une seule entité spatiale. Cette couche synthétique permet d’obtenir une vision
--                 globale et continue des zones tampons résiduelles autour des bâtiments, excluant
--                 les emprises urbaines. Elle constitue une base utile pour les analyses de
--                 continuité de végétation et de risque incendie.
--
---- Méthode     : - Fusion de toutes les géométries tampon corrigées (ST_Union)
--                 - Validation topologique et extraction des polygones valides
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Indexation spatiale via GIST pour accélérer les requêtes géographiques
--
---- Attributs   : -> geom : Géométrie fusionnée des tampons hors zones urbaines (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_tampon_ihu_rg";

CREATE TABLE "{schema_travail}"."{insee}_tampon_ihu_rg" AS
SELECT ST_SetSRID(                                                            -- Définit le SRID en 2154 (Lambert 93)
          ST_CollectionExtract(                                               -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_Union(t.geom)),                                            -- Fusionne toutes les zones tampons en une seule entité
             3),                                                              -- Type 3 = Polygone / MultiPolygon
       2154) AS geom                                                          -- Géométrie fusionnée résultante en Lambert 93
FROM "{schema_travail}"."{insee}_tampon_ihu" AS t;                            -- Source : zones tampons après retrait des zones urbaines

CREATE INDEX idx_{insee}_tampon_ihu_rg_geom
ON "{schema_travail}"."{insee}_tampon_ihu_rg"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE VII                                                  ----
----                                  GESTION DU PARCELLAIRE BÂTI                                            ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Identifier les parcelles cadastrales contenant un bâtiment situé dans la zone de débroussaillement    ----
----   (OLD 200 mètres autour des massifs forestiers > 0,5 ha).                                              ----
---- - Regrouper ces parcelles par compte communal afin d'individualiser les obligations de débroussaillement----
----   par propriétaire foncier.                                                                             ----
---- - Isoler les parcelles bâties situées dans des zones de recouvrement entre tampons de bâtiments         ----
----   appartenant a plusieurs comptes communaux différents (zones d'arbitrage).                             ----
---- - Calculer l'intersection entre unités foncières et parcelles bâties pour analyse fine de l'occupation. ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
----                                                                                                         ----
---- - **Parcelles bâties (`{insee}_parcelle_batie`)** :                                                     ----
----   - Croisement spatial entre les bâtiments (regroupés par compte communal) et les parcelles cadastrales.----
----   - Sélection uniquement des parcelles intersectant un bâtiment de même compte communal.                ----
----   - Fusion des parcelles par (comptecommunal, geo_parcelle, idu).                                       ----
----                                                                                                         ----
---- - **Fusion par compte communal (`{insee}_parcelle_batie_u`)** :                                         ----
----   - Regroupement de toutes les parcelles bâties par compte communal.                                    ----
----   - Fusion spatiale avec ST_Union pour obtenir une emprise unique par propriétaire.                     ----
----   - Validation géométrique : ST_MakeValid → ST_CollectionExtract → ST_Multi.                            ----
----                                                                                                         ----
---- - **Parcelles en zone d'arbitrage (`{insee}_parcelle_batie_ihu`)** :                                    ----
----   - Sélection des parcelles bâties dont le compte communal apparaît dans les tampons inter-comptes      ----
----     (comptecomm1 OU comptecomm2).                                                                       ----
----   - Identification des parcelles impliquées dans un chevauchement potentiel de responsabilité OLD.      ----
----                                                                                                         ----
---- - **Intersection unités foncières / parcelles bâties (`{insee}_ufr_bati`)** :                           ----
----   - Calcul de l'intersection spatiale entre unités foncières et parcelles bâties.                       ----
----   - Conservation uniquement des zones de même compte communal.                                          ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Une table `{insee}_parcelle_batie` avec les parcelles contenant des bâtiments OLD.                    ----
---- - Une table `{insee}_parcelle_batie_u` avec les emprises foncières bâties par propriétaire.             ----
---- - Une table `{insee}_parcelle_batie_ihu` avec les parcelles en zone d'arbitrage inter-propriétaires.    ----
---- - Une table `{insee}_ufr_bati` avec l'intersection précise entre UF et parcelles bâties.                ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_Intersects : associe précisément bâtiment regroupé et parcelle via leur emprise réelle.            ----
---- - ST_Union : fusionne les parcelles d'un même compte pour faciliter l'analyse par propriétaire.         ----
---- - ST_MakeValid + ST_CollectionExtract : garantissent l'homogénéité géométrique du résultat.             ----
---- - Croisement avec tampons inter-comptes : isole les cas de responsabilité potentiellement partagée.     ----
---- - ST_Intersection (ufr_bati) : calcule précisément la zone bâtie au sein de chaque unité foncière.      ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_parcelle_batie" : Parcelles cadastrales intersectant des bâtiments OLD
---- Description : Identifie les parcelles cadastrales contenant au moins un bâtiment localisé dans la
--                 zone de débroussaillement (OLD – 200 m autour des massifs forestiers). Seules les
--                 parcelles appartenant au même compte communal que le bâtiment sont conservées, assurant
--                 la cohérence entre propriété bâtie et emprise parcellaire. Les parcelles intersectantes
--                 sont fusionnées par (comptecommunal, geo_parcelle, idu) pour constituer une géométrie
--                 unique par entité cadastrale.
--
---- Méthode     : - Jointure spatiale entre parcelles cadastrales et bâtiments regroupés (ST_Intersects)
--                 - Filtrage par identifiant de compte communal (égalité propriétaire)
--                 - Fusion géométrique des parcelles intersectantes (ST_Union)
--                 - Validation topologique et extraction des entités polygonales (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du type géométrique et du SRID (MULTIPOLYGON, 2154)
--                 - Nettoyage des géométries nulles ou invalides et indexation spatiale GIST
--
---- Attributs   : -> comptecommunal : Identifiant du compte communal (propriétaire)
--                 -> geo_parcelle   : Code cadastral de la parcelle
--                 -> idu            : Identifiant unique de la parcelle
--                 -> geom            : Géométrie fusionnée de la parcelle (MULTIPOLYGON, SRID 2154)


DROP TABLE IF EXISTS "{schema_travail}"."{insee}_parcelle_batie";

CREATE TABLE "{schema_travail}"."{insee}_parcelle_batie" AS
SELECT p.comptecommunal,                                                      -- N° du compte communal du propriétaire
       p.geo_parcelle,                                                        -- N° de parcelle cadastrale
       p.idu,                                                                 -- Identifiant unique de la parcelle
       ST_CollectionExtract(                                                  -- Extrait uniquement les polygones (type 3)
          ST_MakeValid(                                                       -- Corrige les géométries invalides
             ST_Union(p.geom)),                                               -- Fusionne les géométries des parcelles
          3) AS geom                                                          -- MultiPolygon résultant de type 3 = POLYGON / MULTIPOLYGON
FROM "{SCHEMA_PARCELLE}"."{insee}_parcelle" p                                 -- Source : parcelles cadastrales de la communes et communes du tampon de 100m
INNER JOIN "{schema_travail}"."{insee}_bati200_cc_rg" b                       -- Source : bâtiments regroupés par compte communal dans la zone OLD 200m
ON ST_Intersects(p.geom, b.geom)                                              -- Condition spatiale : bâtiment intersecte parcelle
WHERE p.comptecommunal = b.comptecommunal                                     -- Filtre : même propriétaire
GROUP BY p.comptecommunal, p.geo_parcelle, p.idu;                             -- Regroupement par compte communal, geo_parcelle et identifiant unique

DELETE FROM "{schema_travail}"."{insee}_parcelle_batie"
WHERE geom IS NULL                                                      
OR ST_IsEmpty(geom)                                                    
OR NOT ST_IsValid(geom); 

ALTER TABLE "{schema_travail}"."{insee}_parcelle_batie"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);    

CREATE INDEX idx_{insee}_parcelle_batie_geom 
ON "{schema_travail}"."{insee}_parcelle_batie"
USING gist (geom);  


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_parcelle_batie_u" : Fusion des parcelles bâties par compte communal
---- Description : Agrège et fusionne l’ensemble des parcelles bâties appartenant a un même compte communal
--                 dans la zone de débroussaillement (OLD). Cette couche fournit une représentation
--                 unifiée de l’emprise foncière bâtie de chaque propriétaire, facilitant l’analyse
--                 des obligations légales de débroussaillement a l’échelle foncière.
--
---- Méthode     : - Regroupement des parcelles bâties par compte communal
--                 - Fusion géométrique des parcelles (ST_Union)
--                 - Validation topologique et extraction des polygones valides
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Indexation spatiale via GIST pour optimisation des traitements
--
---- Attributs   : -> comptecommunal : Identifiant du compte communal (propriétaire)
--                 -> geom            : Géométrie fusionnée des parcelles bâties (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_parcelle_batie_u";

CREATE TABLE "{schema_travail}"."{insee}_parcelle_batie_u" AS
SELECT comptecommunal,                                                        -- Compte communal associé aux parcelles
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (Lambert 93)
          ST_CollectionExtract(                                               -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_Union(geom)),                                              -- Fusionne toutes les géométries des parcelles du même compte
             3),                                                              -- Type 3 = Polygone / MultiPolygon
       2154) AS geom                                                          -- Géométrie fusionnée par propriétaire en Lambert 93
FROM "{schema_travail}"."{insee}_parcelle_batie"                              -- Source : Parcelles contenant des bâtiments
GROUP BY comptecommunal;                                                      -- Regroupement par compte communal

CREATE INDEX idx_{insee}_parcelle_batie_u_geom
ON "{schema_travail}"."{insee}_parcelle_batie_u"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_parcelle_batie_ihu" : Parcelles bâties situées en zone d’arbitrage inter-propriétaires
---- Description : Identifie les parcelles bâties dont le compte communal est impliqué dans les zones de
--                 recouvrement entre tampons de bâtiments appartenant a des propriétaires différents
--                 (issues de la table tampon_ihu). Ces parcelles sont considérées comme situées en
--                 zone d’arbitrage potentiel pour l’application des obligations légales de débroussaillement.
--
---- Méthode     : - Jointure entre les parcelles bâties fusionnées et les zones de chevauchement inter-propriétaires
--                 - Sélection des parcelles associées a un des comptes communaux impliqués dans une intersection
--                 - Élimination des doublons via DISTINCT
--                 - Indexation spatiale GIST pour les analyses ultérieures
--
---- Attributs   : -> comptecommunal : Identifiant du compte communal concerné par l’arbitrage
--                 -> geom           : Géométrie des parcelles bâties en zone d’arbitrage (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_parcelle_batie_ihu";

CREATE TABLE "{schema_travail}"."{insee}_parcelle_batie_ihu" AS
SELECT DISTINCT p.*                                                  -- Inclut toutes les colonnes des parcelles sans doublons
FROM "{schema_travail}"."{insee}_parcelle_batie_u" AS p              -- Source : Parcelles contenant des bâtiments
JOIN "{schema_travail}"."{insee}_tampon_ihu" AS t                    -- Source : Zones tampons corrigées pour les arbitrages
ON p.comptecommunal = t.comptecomm1;                                 -- Condition : Correspondance des comptes communaux

CREATE INDEX "idx_{insee}_parcelle_batie_ihu_geom" 
ON "{schema_travail}"."{insee}_parcelle_batie_ihu"
USING gist (geom); 


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_ufr_bati" : Intersection entre unités foncières et parcelles bâties
---- Description : Calcule l’intersection spatiale entre les unités foncières (UFR) regroupées par compte communal
--                 et les parcelles bâties correspondantes. Cette couche permet d’isoler la partie bâtie a
--                 l’intérieur de chaque unité foncière, afin d’affiner l’analyse de l’occupation du sol et
--                 des emprises construites par propriétaire. Seules les correspondances de même compte communal
--                 sont conservées pour assurer la cohérence de propriété.
--
---- Méthode     : - Jointure spatiale entre unités foncières et parcelles bâties (ST_Intersects)
--                 - Calcul des intersections géométriques (ST_Intersection)
--                 - Validation topologique et extraction des entités polygonales (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Suppression des géométries nulles, vides ou invalides
--                 - Création d’un index spatial GIST
--
---- Attributs   : -> comptecommunal : Identifiant du compte communal (propriétaire)
--                 -> geom           : Géométrie d’intersection entre UFR et parcelles bâties (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ufr_bati";

CREATE TABLE "{schema_travail}"."{insee}_ufr_bati" AS
SELECT uf.comptecommunal,                                                     -- N° du compte communal du propriétaire
       ST_CollectionExtract(                                                  -- Extrait uniquement les polygones (type 3)
          ST_MakeValid(                                                       -- Corrige les géométries invalides
             ST_Intersection(                                                 -- Calcule l'intersection UF / parcelle bâtie
                uf.geom,                                                      -- Géométrie de l'unité foncière
                pb.geom)),                                                    -- Géométrie de la parcelle bâtie en zone U
          3) AS geom                                                          -- MultiPolygon résultant de type 3 = POLYGON / MULTIPOLYGON
FROM "{schema_travail}"."{insee}_ufr" AS uf                                   -- Source : unités foncières regroupées de la commune cible et son tampon
LEFT JOIN "{schema_travail}"."{insee}_parcelle_batie_u" pb                    -- Source : parcelles bâties avec zone urbaine
ON ST_Intersects(uf.geom, pb.geom)                                            -- Condition : Intersection entre les unités foncière et les parcelles baties
WHERE uf.comptecommunal = pb.comptecommunal;                                  -- Filtre : Egalité des comptes communaux

DELETE FROM "{schema_travail}"."{insee}_ufr_bati"
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                      
OR NOT ST_IsValid(geom);     

ALTER TABLE "{schema_travail}"."{insee}_ufr_bati"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154); 

CREATE INDEX idx_{insee}_ufr_bati_geom 
ON "{schema_travail}"."{insee}_ufr_bati"
USING gist (geom);  


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE VIII                                                 ----
----                            POLYGONES DE VORONOI POUR L'ARBITRAGE                                        ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Générer des polygones de Voronoi a partir des contours des parcelles bâties en zone d'arbitrage.      ----
---- - Attribuer chaque polygone de Voronoi a un compte communal pour délimiter les zones d'influence.       ----
---- - Produire une couche regroupée par propriétaire facilitant le calcul des responsabilités OLD.          ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
----                                                                                                         ----
---- - **Interpolation de points (`{insee}_pt_interpol`)** :                                                 ----
----   - Génération de points tous les mètres sur les contours extérieurs et intérieurs des parcelles        ----
----     bâties en zone d'arbitrage.                                                                         ----
----   - Décomposition des MultiPolygons et anneaux avec ST_Dump + ST_DumpRings.                             ----
----   - Utilisation de ST_LineInterpolatePoints pour espacer régulièrement les points.                      ----
----                                                                                                         ----
---- - **Éclatement en points individuels (`{insee}_pt_interpol_rg`)** :                                     ----
----   - Transformation des MultiPoints en Points individuels avec ST_Dump.                                  ----
----   - Nécessaire pour alimenter la fonction ST_VoronoiPolygons.                                           ----
----                                                                                                         ----
---- - **Calcul des polygones de Voronoi (`{insee}_voronoi`)** :                                             ----
----   - Génération des polygones de Voronoi a partir de tous les points interpolés.                         ----
----   - ST_VoronoiPolygons crée des zones d'influence autour de chaque point.                               ----
----                                                                                                         ----
---- - **Attribution aux comptes communaux (`{insee}_voronoi_cc`)** :                                        ----
----   - Jointure spatiale entre polygones de Voronoi et points interpolés via ST_Within.                    ----
----   - Chaque polygone hérite du compte communal du point qu'il contient.                                  ----
----                                                                                                         ----
---- - **Regroupement par propriétaire (`{insee}_voronoi_cc_rg`)** :                                         ----
----   - Fusion de tous les polygones de Voronoi d'un même compte communal.                                  ----
----   - Validation et nettoyage géométrique avec ST_MakeValid + ST_Union.                                   ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Une couche de points interpolés sur les contours des parcelles bâties en arbitrage.                   ----
---- - Des polygones de Voronoi délimitant les zones d'influence de chaque propriétaire.                     ----
---- - Une couche finale regroupée par compte communal pour calcul des responsabilités OLD.                  ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_DumpRings : extrait tous les anneaux (extérieurs ET intérieurs) pour interpolation complète.       ----
---- - ST_LineInterpolatePoints : génère des points régulièrement espacés (1m) le long des contours.         ----
---- - ST_VoronoiPolygons : calcule automatiquement les zones d'influence géométrique.                       ----
---- - ST_Within : associe précisément chaque polygone de Voronoi au point qu'il contient.                   ----
---- - ST_Union + regroupement : fusionne les zones d'influence par propriétaire pour analyse globale.       ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_pt_interpol" : Points interpolés sur les contours des parcelles bâties en 
--zone d’arbitrage
---- Description : Génère des points régulièrement espacés (tous les mètres) le long des contours extérieurs
--                 et intérieurs des parcelles bâties situées en zone d’arbitrage. Ces points constituent la
--                 base géométrique pour la génération ultérieure des polygones de Voronoï, utilisés afin de
--                 modéliser les zones d’influence spatiale de chaque propriétaire.
--
---- Méthode     : - Décomposition des géométries en polygones individuels (ST_Dump)
--                 - Extraction des anneaux extérieurs et intérieurs (ST_DumpRings)
--                 - Interpolation de points a intervalle régulier (ST_LineInterpolatePoints)
--                 - Filtrage des contours courts (< 1 mètre) pour éviter les divisions nulles
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Indexation spatiale GIST sur les géométries de points générées
--
---- Attributs   : -> comptecommunal : Identifiant du compte communal associé a chaque parcelle bâtie
--                 -> geom            : Ensemble des points interpolés le long des contours (MULTIPOINT, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_pt_interpol";

CREATE TABLE "{schema_travail}"."{insee}_pt_interpol" AS
WITH dumped_parcelles AS (
    SELECT p.comptecommunal,                                                     -- N° de comptes communaux 
           (ST_DumpRings(                                                        -- Décompose les anneaux (extérieurs ET intérieurs)
              (ST_Dump(p.geom)).geom                                             -- Décompose les MultiPolygons en Polygons individuels
           )).geom AS dumped_geom                                                -- Géométrie résultante : LineStrings des anneaux
    FROM "{schema_travail}"."{insee}_parcelle_batie_ihu" p                       -- Source : Parcelles bâties en zone d'arbitrage
)
SELECT comptecommunal,                                                           -- Conserve le compte communal de chaque parcelle
       ST_LineInterpolatePoints(
           ST_ExteriorRing(dumped_geom),                                         -- Extrait le contour extérieur de chaque polygone
           1/ ST_Length(ST_ExteriorRing(dumped_geom))                            -- Calcule des points régulièrement espacés (1 mètre) le long du contour  [**param**] 
       ) AS geom                                                                 -- Géométrie résultante
FROM dumped_parcelles                                                            -- Source : résultat du traitement sur ls parcelles-bâties arbitrées
WHERE ST_Length(ST_ExteriorRing(dumped_geom)) > 1;                               -- Filtre : ne conserve que les contours supérieurs a 1m  [**param**] 

CREATE INDEX idx_{insee}_pt_interpol_geom
ON "{schema_travail}"."{insee}_pt_interpol"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_pt_interpol_rg" : Conversion des MultiPoints en Points individuels pour Voronoï
---- Description : Décompose les géométries MultiPoint issues de l’interpolation en points simples afin de
--                 préparer le calcul des polygones de Voronoï. Cette étape est indispensable car la fonction
--                 ST_VoronoiPolygons ne traite que des collections de points unitaires.
--
---- Méthode     : - Décomposition des MultiPoints en entités ponctuelles (ST_Dump)
--                 - Affectation du SRID Lambert 93 (EPSG:2154)
--                 - Indexation spatiale GIST pour accélérer le calcul des diagrammes de Voronoï
--
---- Attributs   : -> comptecommunal : Identifiant du compte communal associé a chaque point
--                 -> geom            : Point individuel issu de la décomposition (POINT, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_pt_interpol_rg";

CREATE TABLE "{schema_travail}"."{insee}_pt_interpol_rg" AS
SELECT p.comptecommunal,                                                      -- N° de compte communal
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (Lambert 93)
          (ST_Dump(p.geom)).geom,                                             -- Éclate les MultiPoints en Points individuels
       2154) AS geom                                                          -- Point individuel en Lambert 93
FROM "{schema_travail}"."{insee}_pt_interpol" p;                              -- Source : Points interpolés (MultiPoints)

CREATE INDEX idx_{insee}_pt_interpol_rg_geom
ON "{schema_travail}"."{insee}_pt_interpol_rg"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_voronoi" : Polygones de Voronoï issus des points interpolés
---- Description : Génère les polygones de Voronoï a partir des points interpolés sur les contours des
--                 parcelles bâties. Chaque polygone représente la zone d’influence spatiale d’un point,
--                 c’est-a-dire la surface la plus proche de ce point par rapport a tous les autres.
--                 Cette couche constitue la base pour les analyses de proximité ou d’arbitrage entre
--                 propriétaires.
--
---- Méthode     : - Agrégation de l’ensemble des points en une géométrie MultiPoint (ST_Collect)
--                 - Génération du diagramme de Voronoï (ST_VoronoiPolygons)
--                 - Décomposition des géométries résultantes en polygones individuels (ST_Dump)
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Création d’un index spatial GIST pour accélérer les traitements géométriques
--
---- Attributs   : -> geom : Géométrie des polygones de Voronoï individuels (POLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_voronoi";

CREATE TABLE "{schema_travail}"."{insee}_voronoi" AS
SELECT (ST_Dump(                                                              -- Décompose la GeometryCollection en polygones individuels
          ST_VoronoiPolygons(                                                 -- Génère le diagramme de Voronoï
             ST_Collect(p.geom))                                              -- Collecte tous les points en une MultiPoint
       )).geom AS geom                                                        -- Polygon de Voronoï individuel
FROM "{schema_travail}"."{insee}_pt_interpol_rg" p;                           -- Source : points interpolés regroupés par compte

ALTER TABLE "{schema_travail}"."{insee}_voronoi"
ALTER COLUMN geom TYPE geometry(Polygon, 2154)
USING ST_SetSRID(geom, 2154);                                              

CREATE INDEX idx_{insee}_voronoi_geom
ON "{schema_travail}"."{insee}_voronoi"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_voronoi_cc" : Association des polygones de Voronoï aux comptes communaux
---- Description : Associe chaque polygone de Voronoï a un compte communal a partir des points interpolés
--                 dont ils dérivent. Chaque polygone hérite du compte communal du point situé a
--                 l’intérieur de sa géométrie, permettant ainsi de spatialiser les zones d’influence
--                 foncière par propriétaire.
--
---- Méthode     : - Jointure spatiale entre les polygones de Voronoï et les points interpolés (ST_Within)
--                 - Transfert du compte communal du point vers le polygone correspondant
--                 - Validation et extraction des polygones valides (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Création d’un index spatial GIST pour optimiser les analyses géographiques
--
---- Attributs   : -> comptecommunal : Identifiant du compte communal associé au polygone de Voronoï
--                 -> geom            : Géométrie du polygone de Voronoï (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_voronoi_cc";

CREATE TABLE "{schema_travail}"."{insee}_voronoi_cc" AS
SELECT p.comptecommunal,                                                      -- N° de compte communal du point interpolé
       ST_CollectionExtract(                                                  -- Extrait les polygones (type 3)
          ST_MakeValid(v.geom),                                               -- Corrige les géométries invalides
          3) AS geom                                                          -- MultiPolygon résultant de type 3 = POLYGON / MULTIPOLYGON
FROM "{schema_travail}"."{insee}_voronoi" v                                   -- Source : polygones de Voronoï (diagramme)
INNER JOIN "{schema_travail}"."{insee}_pt_interpol_rg" p                      -- Source : points interpolés regroupés
ON ST_Within(p.geom, v.geom);                                                 -- Condition : point contenu dans le polygone de Voronoï

ALTER TABLE "{schema_travail}"."{insee}_voronoi_cc"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);                                              

CREATE INDEX idx_{insee}_voronoi_cc_geom
ON "{schema_travail}"."{insee}_voronoi_cc"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_voronoi_cc_rg" : Fusion des polygones de Voronoï par compte communal
---- Description : Agrège et fusionne l’ensemble des polygones de Voronoï appartenant a un même compte communal,
--                 afin de définir la zone d’influence totale de chaque propriétaire dans la zone d’arbitrage.
--                 Cette couche permet une représentation spatiale consolidée des aires de proximité foncière.
--
---- Méthode     : - Regroupement des polygones de Voronoï par compte communal
--                 - Fusion géométrique des entités associées (ST_Union)
--                 - Validation topologique et extraction des polygones valides (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Création d’un index spatial GIST pour optimiser les analyses de voisinage
--
---- Attributs   : -> comptecommunal : Identifiant du compte communal (propriétaire)
--                 -> geom           : Géométrie fusionnée représentant la zone d’influence totale (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_voronoi_cc_rg";

CREATE TABLE "{schema_travail}"."{insee}_voronoi_cc_rg" AS
SELECT vcc.comptecommunal,                                                    -- N° de compte communal
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (Lambert 93)
          ST_CollectionExtract(                                               -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_Union(vcc.geom)),                                          -- Fusionne tous les polygones du même compte
             3),                                                              -- Type 3 = Polygone / MultiPolygon
       2154) AS geom                                                          -- Zone d'influence fusionnée en Lambert 93
FROM "{schema_travail}"."{insee}_voronoi_cc" vcc                              -- Source : Polygones de Voronoi avec comptes communaux
GROUP BY vcc.comptecommunal;                                                  -- Regroupement par compte communal

CREATE INDEX idx_{insee}_voronoi_cc_rg_geom
ON "{schema_travail}"."{insee}_voronoi_cc_rg"
USING gist (geom);


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
---- - Nettoyer et fusionner les géométries finales a attribuer a chaque compte communal.                    ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - Génération des tampons de 50 m autour des bâtiments, hors zone U.                                     ----
---- - Croisement avec les unités foncières pour vérifier la propriété réelle du sol.                        ----
---- - Extraction des zones empiétant sur les unités foncières de voisins (comptecomm2 ≠ comptecomm1).       ----
---- - Soustraction des zones déja prises en charge par le propriétaire 1.                                   ----
---- - Découpage Voronoï sur les contours de parcelles pour répartir les responsabilités en cas de partage.  ----
---- - Attribution des portions de superposition a chaque propriétaire selon leur aire d’influence.          ----
---- - Nettoyage topologique (tampons, snapping, suppressions d’artefacts), typage homogène.                 ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Une couche géographique par compte communal, contenant uniquement les zones OLD a débroussailler,     ----
----   hors zone urbaine, après exclusion des parties non cadastrées et arbitrage spatial Voronoï.           ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_Difference : exclusion rigoureuse des zones déja traitées ou urbanisées.                           ----
---- - ST_Intersection : détection des conflits fonciers par recouvrement entre tampons et unités foncières. ----
---- - ST_VoronoiPolygons : découpage neutre des zones partagées a partir des distances aux bâtiments.       ----
----   → chaque bâtiment “rayonne” jusqu’au milieu du chemin vers les autres, formant une division équitable.----
---- - ST_Buffer ±0.01 : lissage des contours pour retirer les irrégularités géométriques (épines, bavures). ----
---- - ST_RemoveRepeatedPoints + ST_Snap : suppression des points inutiles et réalignement localisé.         ----
---- - ST_Union + ST_MakeValid + ST_CollectionExtract : fusion robuste, nettoyage topologique et typage      ----
----   homogène.                                                                                             ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

-- Traitements de la boucle 1 sans fonction ni itération

-----------------------------

---- Création de la table "{insee}_b1_t1" : Zones de superposition entre propriétaires hors zones urbaines
---- Description : Extrait les zones de superposition (tampons intersectants) entre deux propriétaires distincts,
--                 situées en dehors des zones urbaines. Cette table permet d’identifier les emprises
--                 partagées ou conflictuelles susceptibles de nécessiter un arbitrage foncier dans le
--                 cadre des obligations légales de débroussaillement (OLD).
--
---- Méthode     : - Validation des géométries de tampons inter-propriétaires (ST_MakeValid)
--                 - Extraction des entités polygonales (ST_CollectionExtract)
--                 - Filtrage des géométries nulles ou vides
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Indexation spatiale GIST pour optimisation des requêtes
--
---- Attributs   : -> comptecomm1 : Identifiant du premier compte communal (propriétaire 1)
--                 -> comptecomm2 : Identifiant du second compte communal (propriétaire 2)
--                 -> geom         : Géométrie valide représentant la zone de superposition (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t1";

CREATE TABLE "{schema_travail}"."{insee}_b1_t1" AS
WITH tampon_extract AS (
     SELECT t.comptecomm1,                                                    -- N° du compte communal du propriétaire 1
            t.comptecomm2,                                                    -- N° du compte communal du propriétaire 2
            ST_CollectionExtract(                                             -- Extrait uniquement les polygones (type 3)
               ST_MakeValid(t.geom),                                          -- Corrige les géométries invalides
               3) AS geom                                                     -- Zones de superposition validées
     FROM "{schema_travail}"."{insee}_tampon_ihu" t                           -- Source : tampons en dehors de la zone urbaine
     WHERE t.geom IS NOT NULL                                                 -- Filtre : élimine les géométries nulles
     AND NOT ST_IsEmpty(t.geom)                                               -- Filtre : élimine les géométries vides
)
SELECT te.comptecomm1,                                                        -- N° du compte communal du propriétaire 1
       te.comptecomm2,                                                        -- N° du compte communal du propriétaire 2
       ST_SetSRID(te.geom, 2154) AS geom                                      -- Zone de superposition en Lambert 93
FROM tampon_extract te                                                        -- Source : CTE avec géométries extraites
WHERE te.geom IS NOT NULL                                                     -- Filtre final : élimine les géométries nulles résiduelles
AND NOT ST_IsEmpty(te.geom);                                                  -- Filtre final : élimine les géométries vides résiduelles
				
DELETE FROM "{schema_travail}"."{insee}_b1_t1"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

CREATE INDEX "idx_{insee}_b1_t1_geom" 
ON "{schema_travail}"."{insee}_b1_t1"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t2" : Fusion des zones de superposition hors zones urbaines par propriétaire
---- Description : Regroupe et fusionne toutes les zones de superposition (hors zones urbaines) identifiées
--                 dans la table b1_t1 pour chaque compte communal principal. Cette couche représente la
--                 surface totale de recouvrement associée a chaque propriétaire, utile pour l’évaluation
--                 des zones d’interaction foncière dans le cadre des analyses OLD.
--
---- Méthode     : - Agrégation des zones de superposition par compte communal principal
--                 - Fusion spatiale des géométries correspondantes (ST_Union)
--                 - Validation et extraction des entités polygonales valides (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Indexation spatiale GIST pour accélérer les analyses
--
---- Attributs   : -> comptecomm1  : Identifiant du compte communal principal (propriétaire)
--                 -> geom         : Géométrie fusionnée des zones de superposition (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t2";

CREATE TABLE "{schema_travail}"."{insee}_b1_t2" AS
SELECT b1.comptecomm1,                                                        -- N° du compte communal du propriétaire principal
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (source b1_t1 déja typée)
          ST_CollectionExtract(                                               -- Extrait les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_Union(b1.geom)),                                           -- Fusionne toutes les zones de superposition du propriétaire
             3),                                                              -- Type 3 = MultiPolygon
       2154) AS geom                                                          -- MultiPolygon en Lambert 93
FROM "{schema_travail}"."{insee}_b1_t1" b1                                    -- Source : zones de superposition hors zone urbaine
GROUP BY b1.comptecomm1;                                                      -- Regroupement par compte communal principal

DELETE FROM "{schema_travail}"."{insee}_b1_t2"
WHERE geom IS NULL                                                           
OR ST_IsEmpty(geom)                                                       
OR NOT ST_IsValid(geom);  
   
CREATE INDEX idx_{insee}_b1_t2_geom
ON "{schema_travail}"."{insee}_b1_t2"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t3" : Zones tampons de 50 m autour des bâtiments hors zones urbaines
---- Description : Génère les zones tampons de 50 mètres autour des bâtiments appartenant a chaque compte
--                 communal, tout en excluant les surfaces situées dans les zones urbaines (U) du PLU.
--                 Cette couche permet d’isoler les zones tampons pertinentes pour l’analyse des OLD,
--                 en dehors des périmètres déja urbanisés.
--
---- Méthode     : - Soustraction des zones urbaines aux tampons de 50 m (ST_Difference)
--                 - Fusion des tampons restants par compte communal (ST_Union)
--                 - Validation topologique et extraction des polygones valides (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du type géométrique et du SRID (MULTIPOLYGON, 2154)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Création d’un index spatial GIST pour les analyses de voisinage
--
---- Attributs   : -> comptecommunal : Identifiant du compte communal (propriétaire)
--                 -> geom            : Zone tampon de 50 m hors zone urbaine (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t3";

CREATE TABLE "{schema_travail}"."{insee}_b1_t3" AS
SELECT bt50.comptecommunal,                                                   -- N° du compte communal du propriétaire
       ST_CollectionExtract(                                                  -- Extrait les polygones UNE SEULE FOIS
          ST_MakeValid(                                                       -- Corrige les géométries invalides
             ST_Union(                                                        -- Fusionne les tampons par propriétaire
                ST_Difference(                                                -- Soustrait la zone U du tampon
                   ST_MakeValid(bt50.geom),                                   -- Valide la source tampon 50m
                   ST_MakeValid(zu.geom)))),                                  -- Valide la source zone urbaine
       3) AS geom                                                             -- MultiPolygon résultant de type 3 
FROM "{schema_travail}"."{insee}_bati_tampon50" bt50,                         -- Source : tampons de 50m autour des bâtiments
     "{schema_travail}"."{insee}_zonage_elargi" zu                            -- Source : zones urbaines corrigées du PLU
GROUP BY bt50.comptecommunal;                                                 -- Regroupement par compte communal

DELETE FROM "{schema_travail}"."{insee}_b1_t3"
WHERE geom IS NULL                                                          
OR ST_IsEmpty(geom)                                                      
OR NOT ST_IsValid(geom);                                                  

ALTER TABLE "{schema_travail}"."{insee}_b1_t3"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);

CREATE INDEX idx_{insee}_b1_t3_geom
ON "{schema_travail}"."{insee}_b1_t3"
USING gist (geom);
			 
			 
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t4" : Zones de superposition situées sur les unités foncières du voisin
---- Description : Identifie les zones de superposition (tampons) appartenant a des propriétaires distincts,
--                 mais situées sur les unités foncières du voisin (comptecomm2). Ces zones sont considérées
--                 comme a la charge du voisin pour le débroussaillement, car elles se trouvent a
--                 l’intérieur de ses emprises foncières.
--
---- Méthode     : - Jointure spatiale entre les tampons de superposition et les unités foncières (ST_Intersects)
--                 - Sélection des intersections où le comptecomm2 correspond au propriétaire de l’unité foncière
--                 - Calcul de l’intersection géométrique précise (ST_Intersection)
--                 - Validation topologique et extraction des polygones valides (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Création d’un index spatial GIST pour optimiser les requêtes spatiales
--
---- Attributs   : -> comptecomm1 : Identifiant du propriétaire principal
--                 -> comptecomm2 : Identifiant du voisin responsable du débroussaillement
--                 -> geom         : Géométrie des zones de superposition situées sur les parcelles du voisin (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t4";

CREATE TABLE "{schema_travail}"."{insee}_b1_t4" AS
SELECT t.comptecomm1,                                                         -- N° du compte communal du propriétaire principal
       t.comptecomm2,                                                         -- N° du compte communal du voisin responsable
       ST_CollectionExtract(                                                  -- Extrait les polygones (type 3)
          ST_MakeValid(                                                       -- Corrige les géométries invalides
             ST_Intersection(                                                 -- Calcule l'intersection tampon/unité foncière
                ST_MakeValid(t.geom),                                         -- Rend valide la géométrie du tampon
                ST_MakeValid(u.geom))),                                       -- Rend valide la géométrie de l'unité foncière
       3) AS geom                                                             -- MultiPolygon résultant de type 3 
FROM "{schema_travail}"."{insee}_tampon_ihu" t,                               -- Source : zones de superposition hors zone urbaine
     "{schema_travail}"."{insee}_ufr" u                                       -- Jointure avec les unités foncières regroupées
WHERE u.comptecommunal = t.comptecomm2                                        -- Condition 1 : UF appartenant au voisin (comptecomm2)
AND ST_Intersects(t.geom, u.geom);                                            -- Condition 2 : intersection spatiale effective

DELETE FROM "{schema_travail}"."{insee}_b1_t4"
WHERE geom IS NULL                                                       
OR ST_IsEmpty(geom)                                                      
OR NOT ST_IsValid(geom);      

ALTER TABLE "{schema_travail}"."{insee}_b1_t4"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);                                              

CREATE INDEX idx_{insee}_b1_t4_geom
ON "{schema_travail}"."{insee}_b1_t4"
USING gist (geom);

				
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t5" : Fusion des zones débroussaillées par les voisins
---- Description : Regroupe et fusionne toutes les zones de superposition situées sur les parcelles des voisins
--                 (comptecomm2) et débroussaillées par eux pour le compte des propriétaires principaux
--                 (comptecomm1). Cette table synthétise les surfaces dont le débroussaillement est assuré
--                 par autrui dans le cadre des obligations légales de débroussaillement (OLD).
--
---- Méthode     : - Regroupement des zones de superposition (b1_t4) par propriétaire principal (comptecomm1)
--                 - Fusion des géométries correspondantes (ST_Union)
--                 - Validation topologique et extraction des entités polygonales valides (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Création d’un index spatial GIST pour les traitements géographiques
--
---- Attributs   : -> comptecommunal : Identifiant du propriétaire principal bénéficiaire
--                 -> geom           : Géométrie des zones débroussaillées par les voisins (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t5";

CREATE TABLE "{schema_travail}"."{insee}_b1_t5" AS
SELECT b4.comptecomm1 AS comptecommunal,                                      -- N° du compte communal du propriétaire principal
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (source b1_t4 déja typée)
          ST_CollectionExtract(                                               -- Extrait les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_Union(b4.geom)),                                           -- Fusionne toutes les zones débroussaillées par les voisins
             3),                                                              -- Type 3 = MultiPolygon
       2154) AS geom                                                          -- MultiPolygon en Lambert 93
FROM "{schema_travail}"."{insee}_b1_t4" b4                                    -- Source : zones de superposition appartenant aux voisins
GROUP BY b4.comptecomm1;                                                      -- Regroupement par compte communal principal

DELETE FROM "{schema_travail}"."{insee}_b1_t5"
WHERE geom IS NULL                                                            
OR ST_IsEmpty(geom)                                                      
OR NOT ST_IsValid(geom);     

CREATE INDEX idx_{insee}_b1_t5_geom
ON "{schema_travail}"."{insee}_b1_t5"
USING gist (geom);

		
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t6" : Zones a débroussailler sur les parcelles propres
---- Description : Identifie les zones tampons de 50 mètres hors zone urbaine (U) qui se situent sur les 
--                 unités foncières du même propriétaire. Ces surfaces correspondent aux zones que le 
--                 propriétaire doit débroussailler directement, car elles se trouvent sur ses propres 
--                 parcelles et relèvent donc de sa responsabilité.
--
---- Méthode     : - Jointure spatiale entre les tampons de 50 m hors zones U et les unités foncières
--                 - Filtrage sur l’égalité des comptes communaux (propriétaire unique)
--                 - Calcul de l’intersection géométrique entre tampon et unité foncière (ST_Intersection)
--                 - Validation topologique et extraction des polygones valides (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du SRID (2154 - Lambert 93)
--                 - Suppression des géométries nulles, vides ou invalides
--                 - Création d’un index spatial GIST pour les traitements géographiques
--
---- Attributs   : -> comptecommunal : Identifiant du propriétaire concerné
--                 -> geom           : Géométrie des zones a débroussailler sur ses propres parcelles (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t6";

CREATE TABLE "{schema_travail}"."{insee}_b1_t6" AS
SELECT b3.comptecommunal,                                                     -- N° du compte communal du propriétaire
       ST_CollectionExtract(                                                  -- Extrait les polygones (type 3)
          ST_MakeValid(                                                       -- Corrige les géométries invalides
             ST_Intersection(                                                 -- Calcule l'intersection tampon/unité foncière
                ST_MakeValid(b3.geom),                                        -- Rend valide la géométrie du tampon 50m hors zone U
                ST_MakeValid(u.geom))),                                       -- Rend valide la géométrie de l'unité foncière
          3) AS geom                                                          -- MultiPolygon résultant de type 3 
FROM "{schema_travail}"."{insee}_b1_t3" b3,                                   -- Source : zones tampons de 50m hors zone urbaine
     "{schema_travail}"."{insee}_ufr" u                                       -- Jointure avec les unités foncières regroupées
WHERE u.comptecommunal = b3.comptecommunal                                    -- Condition 1 : même propriétaire
AND ST_Intersects(b3.geom, u.geom);                                           -- Condition 2 : intersection spatiale effective

DELETE FROM "{schema_travail}"."{insee}_b1_t6"
WHERE geom IS NULL                                                        
OR ST_IsEmpty(geom)                                                     
OR NOT ST_IsValid(geom);         

ALTER TABLE "{schema_travail}"."{insee}_b1_t6"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);            

CREATE INDEX idx_{insee}_b1_t6_geom
ON "{schema_travail}"."{insee}_b1_t6"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t7" : Fusion des zones a débroussailler sur les parcelles propres
---- Description : Regroupe et fusionne l’ensemble des zones tampons de 50 mètres situées sur les 
--                 parcelles appartenant au même propriétaire. Cette table fournit la surface totale 
--                 que chaque propriétaire doit débroussailler sur son propre foncier, en dehors des 
--                 zones urbaines.
--
---- Méthode     : - Regroupement des zones a débroussailler (b1_t6) par compte communal
--                 - Fusion spatiale des géométries par propriétaire (ST_Union)
--                 - Validation topologique et extraction des polygones valides (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du système de coordonnées (SRID 2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Création d’un index spatial GIST pour optimiser les analyses spatiales
--
---- Attributs   : -> comptecommunal : Identifiant du propriétaire
--                 -> geom           : Géométrie des zones a débroussailler sur les parcelles propres (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t7";

CREATE TABLE "{schema_travail}"."{insee}_b1_t7" AS
SELECT b6.comptecommunal,                                                     -- N° du compte communal du propriétaire
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (source b1_t6 déja typée)
          ST_CollectionExtract(                                               -- Extrait les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_Union(b6.geom)),                                           -- Fusionne toutes les zones du propriétaire
             3),                                                              -- Type 3 = MultiPolygon
       2154) AS geom                                                          -- MultiPolygon résultant en Lambert 93
FROM "{schema_travail}"."{insee}_b1_t6" b6                                    -- Source : zones de 50m sur parcelles propres
GROUP BY b6.comptecommunal;                                                   -- Regroupement par compte communal

DELETE FROM "{schema_travail}"."{insee}_b1_t7"
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                      
OR NOT ST_IsValid(geom);   

CREATE INDEX idx_{insee}_b1_t7_geom
ON "{schema_travail}"."{insee}_b1_t7"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t8" : Fusion des zones totales a débroussailler (propriétaire + voisins)
---- Description : Combine les zones de débroussaillement effectuées par le propriétaire sur ses propres 
--                 parcelles (b1_t7) et celles prises en charge par les voisins (b1_t5). La table agrège 
--                 l’ensemble des surfaces a débroussailler pour chaque propriétaire, garantissant une 
--                 vision unifiée de la responsabilité OLD.
--
---- Méthode     : - Union des géométries issues des tables b1_t7 (propriétaire) et b1_t5 (voisins)
--                 - Validation topologique (ST_MakeValid) et extraction polygonale (ST_CollectionExtract)
--                 - Fusion spatiale des géométries par compte communal (ST_UnaryUnion)
--                 - Harmonisation du système de coordonnées (SRID 2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Création d’un index spatial GIST pour les opérations de spatialisation avancées
--
---- Attributs   : -> comptecommunal : Identifiant du propriétaire (bénéficiaire ou débroussailleur)
--                 -> geom           : Géométrie totale a débroussailler (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t8";

CREATE TABLE "{schema_travail}"."{insee}_b1_t8" AS
WITH union_all AS (
     -- Partie 1 : Zones débroussaillées par le propriétaire lui-même
     SELECT t7.comptecommunal,                                                -- N° du compte communal
            ST_CollectionExtract(                                             -- Extrait les polygones (type 3)
               ST_MakeValid(t7.geom),                                         -- Corrige les géométries invalides
               3) AS geom                                                     -- MultiPolygon résultant de type 3 
     FROM "{schema_travail}"."{insee}_b1_t7" t7                               -- Source : zones propriétaire sur ses parcelles
     
     UNION ALL                                                                -- Empile les géométries sans éliminer les doublons
     
     -- Partie 2 : Zones débroussaillées par les voisins
     SELECT t5.comptecommunal,                                                -- N° du compte communal
            ST_CollectionExtract(                                             -- Extrait les polygones (type 3)
               ST_MakeValid(t5.geom),                                         -- Corrige les géométries invalides
               3) AS geom                                                     -- MultiPolygon résultant de type 3 
     FROM "{schema_travail}"."{insee}_b1_t5" t5                               -- Source : zones voisins sur leurs parcelles
)
SELECT comptecommunal,                                                        -- N° du compte communal
       ST_SetSRID(                                                            -- Définit le SRID en 2154
          ST_CollectionExtract(                                               -- Extrait les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_UnaryUnion(                                                -- Fusionne toutes les géométries du même compte
                   ST_Collect(geom))),                                        -- Collecte toutes les géométries
             3),                                                              -- Type 3 = MultiPolygon
       2154) AS geom                                                          -- MultiPolygon fusionné en Lambert 93
FROM union_all                                                                -- Source : empilage des deux tables
GROUP BY comptecommunal;                                                      -- Regroupement par compte communal

DELETE FROM "{schema_travail}"."{insee}_b1_t8"
WHERE geom IS NULL                                                          
OR ST_IsEmpty(geom)                                                        
OR NOT ST_IsValid(geom);                                               

CREATE INDEX idx_{insee}_b1_t8_geom
ON "{schema_travail}"."{insee}_b1_t8"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t9" : Zones de superposition restant a débroussailler par plusieurs propriétaires
---- Description : Cette table calcule les zones de superposition (issues de b1_t1) qui demeurent a la 
--                 charge de plusieurs propriétaires après soustraction des zones déja prises en compte 
--                 dans les surfaces a débroussailler (b1_t8). Elle permet d’identifier les espaces où 
--                 les responsabilités de débroussaillement se chevauchent encore entre propriétaires.
--
---- Méthode     : - Jointure entre les zones de superposition (b1_t1) et les zones déja débroussaillées (b1_t8)
--                 - Cas 1 : si une géométrie existe dans b1_t8, calcul de la différence géométrique (ST_Difference)
--                 - Cas 2 : si aucune donnée correspondante, conservation de la géométrie initiale
--                 - Correction topologique systématique (ST_MakeValid) et extraction polygonale (ST_CollectionExtract)
--                 - Conversion en MultiPolygon et harmonisation du SRID (2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Création d’un index spatial GIST pour l’optimisation des analyses géographiques
--
---- Attributs   : -> comptecomm1 : Identifiant du premier propriétaire impliqué dans la superposition
--                 -> comptecomm2 : Identifiant du second propriétaire impliqué dans la superposition
--                 -> geom        : Zone de superposition a débroussailler par plusieurs propriétaires (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t9";

CREATE TABLE "{schema_travail}"."{insee}_b1_t9" AS
SELECT COALESCE(b1.comptecomm1, b8.comptecommunal) AS comptecomm1,            -- N° du compte communal du propriétaire principal
       b1.comptecomm2,                                                        -- N° du compte communal du voisin (peut être NULL)
       CASE
           -- Cas 1 : Seulement b1_t1 existe (pas de zones débroussaillées)
           WHEN b8.comptecommunal IS NULL                                     -- Vérifie l'absence dans b1_t8
           THEN ST_SetSRID(                                                   -- Définit le SRID en 2154
                   ST_CollectionExtract(                                      -- Extrait les polygones (type 3)
                      ST_MakeValid(b1.geom),                                  -- Corrige les géométries invalides
                      3),                                                     -- Type 3 = MultiPolygon
                2154)                                                         -- SRID Lambert 93
           
           -- Cas 2 : Les deux existent (soustraction nécessaire)
           WHEN b1.comptecomm1 IS NOT NULL                                    -- Vérifie l'existence dans b1_t1
           AND b8.comptecommunal IS NOT NULL                                  -- Vérifie l'existence dans b1_t8
           THEN ST_SetSRID(                                                   -- Définit le SRID en 2154 (sources b1_t* déja typées)
                   ST_CollectionExtract(                                      -- Extrait les polygones (type 3)
                      ST_MakeValid(                                           -- Corrige les géométries invalides
                         ST_Difference(                                       -- Soustrait les zones déja débroussaillées
                            ST_MakeValid(b1.geom),                            -- Rend valide la géométrie de superposition
                            ST_MakeValid(b8.geom))),                          -- Rend valide la géométrie déja débroussaillée
                      3),                                                     -- Type 3 = MultiPolygon
                2154)                                                         -- SRID Lambert 93
           
           -- Cas 3 : Seulement b1_t8 existe (cas théorique rare)
           WHEN b1.comptecomm1 IS NULL                                        -- Vérifie l'absence dans b1_t1
           THEN NULL                                                          -- Pas de géométrie résultante (sera supprimée par DELETE)
       
	   END AS geom                                                            -- Géométrie résultante selon le cas
FROM "{schema_travail}"."{insee}_b1_t1" b1                                    -- Source : zones de superposition entre propriétaires
FULL OUTER JOIN "{schema_travail}"."{insee}_b1_t8" b8                         -- Jointure complète avec zones déja débroussaillées
ON b1.comptecomm1 = b8.comptecommunal;                                        -- Condition : même compte communal principal

DELETE FROM "{schema_travail}"."{insee}_b1_t9"
WHERE geom IS NULL                                                          
OR ST_IsEmpty(geom)                                                     
OR NOT ST_IsValid(geom);   

CREATE INDEX idx_{insee}_b1_t9_geom
ON "{schema_travail}"."{insee}_b1_t9"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t10" : Nettoyage géométrique avancé des zones de superposition
---- Description : Applique un double traitement géométrique pour supprimer les irrégularités 
--                 (épines externes et internes) présentes dans les zones de superposition entre 
--                 propriétaires. Le procédé utilise des tampons micro-scalaires (±0.001 m) et des 
--                 opérations de snapping de précision nanométrique pour lisser les contours sans 
--                 altérer la forme générale. Cette étape garantit des géométries propres, valides et 
--                 adaptées aux analyses spatiales de fine résolution.
--
---- Méthode     : - Étape 1 : Rétraction des épines externes par tampon négatif suivi de ST_Snap
--                 - Étape 2 : Remplissage des épines internes par tampon positif suivi de ST_Snap
--                 - Suppression des points dupliqués (ST_RemoveRepeatedPoints)
--                 - Validation topologique (ST_MakeValid)
--                 - Extraction des entités polygonales valides (ST_CollectionExtract)
--                 - Harmonisation du système de coordonnées (SRID 2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Indexation spatiale via GIST pour optimiser les traitements géographiques
--
---- Attributs   : -> comptecomm1 : Identifiant du propriétaire principal
--                 -> comptecomm2 : Identifiant du voisin
--                 -> geom        : Géométrie nettoyée des zones de superposition (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t10";

CREATE TABLE "{schema_travail}"."{insee}_b1_t10" AS
-- Épuration des épines externes (spikes sortants)
WITH epine_externe AS (
     SELECT b9.comptecomm1,                                                   -- N° du compte communal du propriétaire principal
            b9.comptecomm2,                                                   -- N° du compte communal du voisin
            ST_CollectionExtract(                                             -- Extrait les polygones (type 3)
               ST_MakeValid(                                                  -- Corrige les géométries invalides
                  ST_Snap(                                                    -- Aligne le tampon sur la géométrie d'origine
                     ST_RemoveRepeatedPoints(                                 -- Supprime les nœuds consécutifs proches (<30nm)
                        ST_Buffer(                                            -- Buffer négatif pour rétracter les épines externes
                           b9.geom,
                           -0.001,                                            -- Tampon négatif de 0.1mm (10nm)
                           'join=mitre mitre_limit=5.0'),                     -- Jointure en angle avec limite mitre
                        0.003),                                               -- Tolérance de suppression des points répétés (30nm)
                     b9.geom,                                                 -- Géométrie de référence pour le snap
                     0.0006)),                                                -- Distance d'accrochage (60nm)
               3) AS geom                                                     -- MultiPolygon résultant de type 3 
     FROM "{schema_travail}"."{insee}_b1_t9" b9                               -- Source : zones de superposition restantes
),
-- Épuration des épines internes (spikes rentrants)
epine_interne AS (
     SELECT epext.comptecomm1,                                                -- N° du compte communal du propriétaire principal
            epext.comptecomm2,                                                -- N° du compte communal du voisin
            ST_CollectionExtract(                                             -- Extrait les polygones (type 3)
               ST_MakeValid(                                                  -- Corrige les géométries invalides
                  ST_Snap(                                                    -- Aligne le tampon sur la géométrie d'origine
                     ST_RemoveRepeatedPoints(                                 -- Supprime les nœuds consécutifs proches (<30nm)
                        ST_Buffer(                                            -- Buffer positif pour combler les épines internes
                           epext.geom,
                           0.001,                                             -- Tampon positif de 0.1mm (10nm)
                           'join=mitre mitre_limit=5.0'),                     -- Jointure en angle avec limite mitre
                        0.003),                                               -- Tolérance de suppression des points répétés (30nm)
                     b9.geom,                                                 -- Géométrie d'origine pour le snap
                     0.0006)),                                                -- Distance d'accrochage (60nm)
               3) AS geom                                                     -- MultiPolygon résultant de type 3 
     FROM epine_externe epext                                                 -- Source : géométries sans épines externes
     INNER JOIN "{schema_travail}"."{insee}_b1_t9" b9                         -- Jointure avec géométrie d'origine
     ON epext.comptecomm1 = b9.comptecomm1                                    -- Condition 1 : même propriétaire principal
     AND epext.comptecomm2 = b9.comptecomm2                                   -- Condition 2 : même voisin
)
-- Requête finale : Validation et extraction des géométries nettoyées
SELECT epint.comptecomm1,                                                     -- N° du compte communal du propriétaire principal
       epint.comptecomm2,                                                     -- N° du compte communal du voisin
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (source b1_t9 déja typée)
          ST_CollectionExtract(                                               -- Extrait les polygones (type 3)
             ST_MakeValid(epint.geom),                                        -- Corrige les géométries invalides
             3),                                                              -- Type 3 = MultiPolygon
       2154) AS geom                                                          -- MultiPolygon nettoyé en Lambert 93
FROM epine_interne epint                                                      -- Source : géométries sans épines externes ni internes
WHERE epint.geom IS NOT NULL                                                  -- Filtre : élimine les géométries nulles
AND NOT ST_IsEmpty(epint.geom);                                               -- Filtre : élimine les géométries vides

DELETE FROM "{schema_travail}"."{insee}_b1_t10"
WHERE geom IS NULL                                                            
OR ST_IsEmpty(geom)                                                   
OR NOT ST_IsValid(geom);      

CREATE INDEX idx_{insee}_b1_t10_geom
ON "{schema_travail}"."{insee}_b1_t10"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t11" : Fusion finale des zones de superposition nettoyées par propriétaire
---- Description : Regroupe et fusionne toutes les zones de superposition nettoyées (issues de b1_t10) 
--                 associées a un même propriétaire principal (comptecomm1). Cette table synthétise les 
--                 surfaces restantes de recouvrement inter-propriétaires, a débroussailler par autrui 
--                 après le nettoyage géométrique. Elle constitue une vue consolidée des zones d’interaction 
--                 foncière entre voisins.
--
---- Méthode     : - Agrégation spatiale des géométries nettoyées par compte communal (ST_Union)
--                 - Validation topologique et extraction polygonale (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du système de coordonnées (SRID 2154 - Lambert 93)
--                 - Suppression des géométries nulles, vides ou invalides
--                 - Indexation spatiale (GIST) pour accélérer les traitements géographiques
--
---- Attributs   : -> comptecomm1 : Identifiant du propriétaire principal
--                 -> geom         : Surface totale de superposition nettoyée et fusionnée (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t11";

CREATE TABLE "{schema_travail}"."{insee}_b1_t11" AS
SELECT b10.comptecomm1,                                                       -- N° du compte communal du propriétaire principal
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (source b1_t10 déja typée)
          ST_CollectionExtract(                                               -- Extrait les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_Union(b10.geom)),                                          -- Fusionne toutes les zones de superposition nettoyées
             3),                                                              -- Type 3 = MultiPolygon
       2154) AS geom                                                          -- MultiPolygon en Lambert 93
FROM "{schema_travail}"."{insee}_b1_t10" b10                                  -- Source : zones de superposition nettoyées (sans épines)
GROUP BY b10.comptecomm1;                                                     -- Regroupement par compte communal principal

DELETE FROM "{schema_travail}"."{insee}_b1_t11"
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                      
OR NOT ST_IsValid(geom);   

CREATE INDEX idx_{insee}_b1_t11_geom
ON "{schema_travail}"."{insee}_b1_t11"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t12" : Zones tampons de 50m hors superposition et hors zone urbaine
---- Description : Produit les zones de débroussaillement strictement propres a chaque propriétaire, 
--                 en retirant des tampons de 50m hors zone U (b1_t3) toutes les zones de superposition 
--                 inter-propriétaires (b1_t2). Le résultat identifie les surfaces a débroussailler 
--                 exclusivement sous la responsabilité du propriétaire, sans empiètement sur les voisins.
--
---- Méthode     :
--                 - Jointure complète entre b1_t3 (zones tampons hors zone urbaine) et b1_t2 (zones de superposition)
--                 - Cas 1 : conservation des zones hors superposition (uniquement dans b1_t3)
--                 - Cas 2 : soustraction des zones de superposition (présentes dans b1_t3 et b1_t2)
--                 - Cas 3 : absence de tampon (aucune géométrie a conserver)
--                 - Validation topologique (ST_MakeValid) et extraction polygonale (ST_CollectionExtract)
--                 - Harmonisation du système de coordonnées (SRID 2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Indexation spatiale GIST pour les analyses ultérieures
--
---- Attributs   :
--                 -> comptecomm1 : Identifiant du propriétaire
--                 -> geom         : Zone tampon a débroussailler hors superposition (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t12";


CREATE TABLE "{schema_travail}"."{insee}_b1_t12" AS
SELECT COALESCE(b3.comptecommunal, b2.comptecomm1) AS comptecomm1,            -- N° du compte communal (priorité b1_t3)
       CASE
           -- Cas 1 : Seulement b1_t3 existe (pas de superposition)
           WHEN b2.comptecomm1 IS NULL                                        -- Vérifie l'absence dans b1_t2
           THEN ST_SetSRID(                                                   -- Définit le SRID en 2154
                   ST_CollectionExtract(                                      -- Extrait les polygones (type 3)
                      ST_MakeValid(b3.geom),                                  -- Corrige les géométries invalides
                      3),                                                     -- Type 3 = MultiPolygon
                2154)                                                         -- SRID Lambert 93 : 2154
           
           -- Cas 2 : Les deux existent (soustraction nécessaire)
           WHEN b3.comptecommunal IS NOT NULL                                 -- Vérifie l'existence dans b1_t3
            AND b2.comptecomm1 IS NOT NULL                                    -- Vérifie l'existence dans b1_t2
           THEN ST_SetSRID(                                                   -- Définit le SRID en 2154 (sources b1_t* déja typées)
                   ST_CollectionExtract(                                      -- Extrait les polygones (type 3)
                      ST_MakeValid(                                           -- Corrige les géométries invalides
                         ST_Difference(                                       -- Soustrait les zones de superposition
                            ST_MakeValid(b3.geom),                            -- Rend valide la géométrie tampon 50m hors zone U
                            ST_MakeValid(b2.geom))),                          -- Rend valide la géométrie de superposition
                      3),                                                     -- Type 3 = MultiPolygon
                2154)                                                         -- SRID Lambert 93 : 2154
           
           -- Cas 3 : Seulement b1_t2 existe (cas théorique rare)
           WHEN b3.comptecommunal IS NULL                                     -- Vérifie l'absence dans b1_t3
           THEN NULL                                                          -- Pas de géométrie résultante (sera supprimée par DELETE)
       END AS geom                                                            -- Géométrie résultante selon le cas
FROM "{schema_travail}"."{insee}_b1_t3" b3                                    -- Source : zones tampons de 50m hors zone urbaine
FULL OUTER JOIN "{schema_travail}"."{insee}_b1_t2" b2                         -- Jointure complète avec zones de superposition
ON b2.comptecomm1 = b3.comptecommunal;                                        -- Condition : Egalité des comptes communaux 

DELETE FROM "{schema_travail}"."{insee}_b1_t12"
WHERE geom IS NULL                                                            
OR ST_IsEmpty(geom)                                                       
OR NOT ST_IsValid(geom);  

CREATE INDEX idx_{insee}_b1_t12_geom
ON "{schema_travail}"."{insee}_b1_t12"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t13" : Attribution des zones de superposition selon le diagramme de Voronoï
---- Description : Associe chaque zone de superposition nettoyée (b1_t10) au propriétaire dont l’aire 
--                 d’influence (issue du diagramme de Voronoï agrégé par compte communal) la contient. 
--                 Cette étape spatialise l’attribution des zones partagées en fonction de la proximité 
--                 géographique des bâtiments, garantissant une répartition cohérente des responsabilités 
--                 de débroussaillement.
--
---- Méthode     : - Intersection spatiale entre les zones de superposition nettoyées et les polygones de Voronoï
--                 - Attribution au compte communal correspondant a la zone de Voronoï intersectée
--                 - Validation topologique et extraction des entités polygonales (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du système de coordonnées (SRID 2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Indexation spatiale (GIST) pour optimisation des requêtes spatiales
--
---- Attributs   : -> comptecomm1 : Identifiant du propriétaire (compte communal)
--                 -> geom        : Zone de superposition attribuée via Voronoï (MULTIPOLYGON, SRID 2154)


DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t13";
 
CREATE TABLE "{schema_travail}"."{insee}_b1_t13" AS
SELECT b10.comptecomm1,                                                       -- N° du compte communal du propriétaire principal
       ST_CollectionExtract(                                                  -- Extrait les polygones (type 3)
          ST_MakeValid(                                                       -- Corrige les géométries invalides
             ST_Intersection(                                                 -- Calcule l'intersection superposition/Voronoï
                ST_MakeValid(b10.geom),                                       -- Rend valide la géométrie de superposition nettoyée
                ST_MakeValid(v.geom))),                                       -- Rend valide la géométrie du polygone de Voronoï
          3) AS geom                                                          -- MultiPolygon résultant de type 3 
FROM "{schema_travail}"."{insee}_b1_t10" b10                                  -- Source : zones de superposition nettoyées (sans épines)
INNER JOIN "{schema_travail}"."{insee}_voronoi_cc_rg" v                       -- Jointure avec polygones de Voronoï regroupés par compte
ON v.comptecommunal = b10.comptecomm1                                         -- Condition : Egalité des comptes communaux
AND ST_Intersects(b10.geom, v.geom);                                          -- Condition : intersection entre les polygone de voronoi et zone de superposition

DELETE FROM "{schema_travail}"."{insee}_b1_t13"
WHERE geom IS NULL                                                          
OR ST_IsEmpty(geom)                                                        
OR NOT ST_IsValid(geom);                                                  

ALTER TABLE "{schema_travail}"."{insee}_b1_t13"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);  

CREATE INDEX idx_{insee}_b1_t13_geom
ON "{schema_travail}"."{insee}_b1_t13"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t14" : Fusion des zones de superposition attribuées par propriétaire
---- Description : Regroupe et fusionne toutes les zones de superposition attribuées via le diagramme de Voronoï 
--                 (issues de b1_t13) pour chaque propriétaire. Cette table synthétise les zones finales 
--                 de débroussaillement attribuées a chaque compte communal après répartition spatiale. 
--                 Le résultat fournit une vision consolidée des responsabilités OLD inter-propriétaires.
--
---- Méthode     : - Agrégation spatiale des géométries attribuées par compte communal (ST_Union)
--                 - Validation topologique et extraction polygonale (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du système de coordonnées (SRID 2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Indexation spatiale (GIST) pour accélérer les requêtes d’analyse
--
---- Attributs   : -> comptecommunal : Identifiant du propriétaire (compte communal)
--                 -> geom           : Zone fusionnée attribuée via Voronoï (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t14";
 
CREATE TABLE "{schema_travail}"."{insee}_b1_t14" AS
SELECT b13.comptecomm1 AS comptecommunal,                                     -- N° du compte communal du propriétaire
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (source b1_t13 déja typée)
          ST_CollectionExtract(                                               -- Extrait les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_Union(b13.geom)),                                          -- Fusionne toutes les zones attribuées via Voronoï
             3),                                                              -- Type 3 = MultiPolygon
       2154) AS geom                                                          -- MultiPolygon en Lambert 93
FROM "{schema_travail}"."{insee}_b1_t13" b13                                  -- Source : zones de superposition attribuées via Voronoï
GROUP BY b13.comptecomm1;                                                     -- Regroupement par compte communal

DELETE FROM "{schema_travail}"."{insee}_b1_t14"
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                        
OR NOT ST_IsValid(geom);                                                 

CREATE INDEX idx_{insee}_b1_t14_geom
ON "{schema_travail}"."{insee}_b1_t14"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t15" : Union finale des zones a débroussailler (avec et sans superposition)
---- Description : Combine les zones a débroussailler sur les parcelles propres du propriétaire (b1_t7) et 
--                 les zones hors superposition (b1_t12). Cette table représente l’emprise complète des surfaces 
--                 où le propriétaire est légalement tenu de débroussailler, qu’elles résultent d’une responsabilité 
--                 directe ou exclusive. Le résultat constitue la synthèse finale des obligations OLD par compte communal.
--
---- Méthode     : - Empilement des zones issues de b1_t7 (avec superposition) et b1_t12 (hors superposition)
--                 - Fusion spatiale par compte communal (ST_UnaryUnion sur ST_Collect)
--                 - Validation topologique et extraction polygonale (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du système de coordonnées (SRID 2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Indexation spatiale GIST pour les traitements cartographiques
--
---- Attributs   : -> comptecommunal : Identifiant du propriétaire (compte communal)
--                 -> geom           : Zone totale a débroussailler (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t15";
 
CREATE TABLE "{schema_travail}"."{insee}_b1_t15" AS
WITH union_all AS (
     -- Zones débroussaillées par le propriétaire sur ses parcelles (avec superposition)
     SELECT t7.comptecommunal,                                                -- N° du compte communal
            ST_CollectionExtract(                                             -- Extrait les polygones (type 3)
               ST_MakeValid(t7.geom),                                         -- Corrige les géométries invalides
               3) AS geom                                                     -- MultiPolygon résultant de type 3 
     FROM "{schema_travail}"."{insee}_b1_t7" t7                               -- Source : zones avec superposition débroussaillées par propriétaire
     
     UNION ALL                                                                -- Empile les géométries sans éliminer les doublons
     
     -- Zones sans superposition a débroussailler par le propriétaire
     SELECT t12.comptecomm1 AS comptecommunal,                                -- N° du compte communal
            ST_CollectionExtract(                                             -- Extrait les polygones (type 3)
               ST_MakeValid(t12.geom),                                        -- Corrige les géométries invalides
               3) AS geom                                                     -- MultiPolygon résultant de type 3 
     FROM "{schema_travail}"."{insee}_b1_t12" t12                             -- Source : zones sans superposition (b1_t3 - b1_t2)
)
SELECT comptecommunal,                                                        -- N° du compte communal du propriétaire
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (sources b1_t* déja typées)
          ST_CollectionExtract(                                               -- Extrait les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_UnaryUnion(                                                -- Fusionne toutes les géométries du même compte
                   ST_Collect(geom))),                                        -- Collecte toutes les géométries
             3),                                                              -- Type 3 = MultiPolygon
       2154) AS geom                                                          -- MultiPolygon fusionné en Lambert 93
FROM union_all                                                                -- Source : empilage des deux tables
GROUP BY comptecommunal;                                                      -- Regroupement par compte communal

DELETE FROM "{schema_travail}"."{insee}_b1_t15"
WHERE geom IS NULL                                                        
OR ST_IsEmpty(geom)                                                      
OR NOT ST_IsValid(geom);      

CREATE INDEX idx_{insee}_b1_t15_geom
ON "{schema_travail}"."{insee}_b1_t15"
USING gist (geom);
                                                    

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t16" : Zones finales a débroussailler par le propriétaire hors zone urbaine
---- Description : Fusionne les zones de superposition attribuées via le diagramme de Voronoï (b1_t14) avec 
--                 l’ensemble des zones a débroussailler du propriétaire, qu’elles soient issues ou non 
--                 de superpositions (b1_t15). Le résultat fournit la cartographie complète et consolidée 
--                 des surfaces a débroussailler pour chaque propriétaire, en dehors des zones urbaines (U).
--
---- Méthode     : - Empilement des zones issues de b1_t14 (Voronoï) et b1_t15 (avec/sans superposition)
--                 - Fusion spatiale globale par compte communal (ST_UnaryUnion sur ST_Collect)
--                 - Validation et extraction polygonale (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du système de coordonnées (SRID 2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Indexation spatiale (GIST) pour l’optimisation des analyses géographiques
--
---- Attributs   : -> comptecommunal : Identifiant du propriétaire (compte communal)
--                 -> geom           : Zone finale a débroussailler hors zone urbaine (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t16";

CREATE TABLE "{schema_travail}"."{insee}_b1_t16" AS
WITH union_all AS (
     -- Zones de superposition attribuées via Voronoï
     SELECT b14.comptecommunal,                                               -- N° du compte communal
            ST_CollectionExtract(                                             -- Extrait les polygones (type 3)
               ST_MakeValid(b14.geom),                                        -- Corrige les géométries invalides
               3) AS geom                                                     -- MultiPolygon résultant de type 3 
     FROM "{schema_travail}"."{insee}_b1_t14" b14                             -- Source : zones de superposition attribuées (Voronoï)
     
     UNION ALL                                                                -- Empile les géométries sans éliminer les doublons
     
     -- Zones avec et sans superposition a débroussailler
     SELECT b15.comptecommunal,                                               -- N° du compte communal
            ST_CollectionExtract(                                             -- Extrait les polygones (type 3)
               ST_MakeValid(b15.geom),                                        -- Corrige les géométries invalides
               3) AS geom                                                     -- MultiPolygon résultant de type 3 
     FROM "{schema_travail}"."{insee}_b1_t15" b15                             -- Source : zones avec/sans superposition
)
SELECT comptecommunal,                                                        -- N° du compte communal du propriétaire
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (sources b1_t* déja typées)
          ST_CollectionExtract(                                               -- Extrait les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_UnaryUnion(                                                -- Fusionne toutes les géométries du même compte
                   ST_Collect(geom))),                                        -- Collecte toutes les géométries
             3),                                                              -- Type 3 = MultiPolygon
       2154) AS geom                                                          -- MultiPolygon fusionné en Lambert 93
FROM union_all                                                                -- Source : empilage des deux tables
GROUP BY comptecommunal;                                                      -- Regroupement par compte communal

DELETE FROM "{schema_travail}"."{insee}_b1_t16"
WHERE geom IS NULL                                                          
OR ST_IsEmpty(geom)                                                       
OR NOT ST_IsValid(geom);                                            
   
CREATE INDEX idx_{insee}_b1_t16_geom
ON "{schema_travail}"."{insee}_b1_t16"
USING gist (geom);



--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t17" : Parties d'unités foncières situées en zone urbaine.
---- Description : Identifie les portions d’unités foncières (UF) localisées dans le zonage urbain corrigé 
--                 du PLU. Cette table met en évidence les surfaces appartenant a des propriétaires dont 
--                 une partie du foncier se trouve en zone U, qu’il s’agisse de parcelles bâties ou non bâties.
--
---- Méthode     : - Intersection spatiale entre les unités foncières regroupées (ufr) et le zonage urbain corrigé (zu)
--                 - Validation et extraction polygonale des géométries (ST_MakeValid + ST_CollectionExtract)
--                 - Harmonisation du système de coordonnées (SRID 2154 - Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Indexation spatiale GIST pour accélérer les analyses topologiques
--
---- Attributs   : -> comptecommunal : Identifiant du propriétaire (compte communal)
--                 -> geom           : Partie de l’unité foncière située en zone urbaine (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t17";

CREATE TABLE "{schema_travail}"."{insee}_b1_t17" AS
SELECT ufr.comptecommunal,                                                    -- N° du compte communal du propriétaire
       ST_CollectionExtract(                                                  -- Extrait les polygones (type 3)
          ST_MakeValid(                                                       -- Corrige les géométries invalides
             ST_Intersection(                                                 -- Calcule l'intersection UF/zone urbaine
                ST_MakeValid(ufr.geom),                                       -- Rend valide la géométrie de l'unité foncière
                ST_MakeValid(z_corr7.geom))),                                 -- Rend valide la géométrie du zonage urbain
       3) AS geom                                                             -- MultiPolygon résultant de type 3 
FROM "{schema_travail}"."{insee}_ufr" ufr                                     -- Source : unités foncières regroupées par compte
INNER JOIN "{schema_travail}"."{insee}_zonage_elargi" z_corr7                 -- Jointure avec le zonage urbain corrigé
ON ST_Intersects(ufr.geom, z_corr7.geom);                                     -- Condition : intersection spatiale effective

DELETE FROM "{schema_travail}"."{insee}_b1_t17"
WHERE geom IS NULL                                                        
OR ST_IsEmpty(geom)                                                  
OR NOT ST_IsValid(geom);    

ALTER TABLE "{schema_travail}"."{insee}_b1_t17"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);                                          

CREATE INDEX idx_{insee}_b1_t17_geom
ON "{schema_travail}"."{insee}_b1_t17"
USING gist (geom);

				
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t18" : Zones totales a débroussailler par le propriétaire.
---- Description : Produit la carte intégrale des zones a débroussailler pour chaque propriétaire, en fusionnant :
--                 - les parties d’unités foncières situées en zone urbaine (b1_t17),
--                 - et les zones finales a débroussailler hors zone urbaine (b1_t16).
--                 Le résultat constitue la surface totale a entretenir, couvrant l’ensemble du foncier concerné.
--
---- Méthode     : - Union des géométries issues des tables b1_t17 et b1_t16
--                 - Validation géométrique (ST_MakeValid) et homogénéisation polygonale (ST_CollectionExtract)
--                 - Fusion spatiale complète par propriétaire (ST_UnaryUnion sur ST_Collect)
--                 - Application du SRID 2154 (Lambert 93)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Création d’un index spatial GIST pour les requêtes topologiques
--
---- Attributs   : -> comptecommunal : Identifiant du propriétaire (compte communal)
--                 -> geom           : Zone totale a débroussailler (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t18";
 
CREATE TABLE "{schema_travail}"."{insee}_b1_t18" AS
WITH union_all AS (
     -- Partie 1 : Parties d'unités foncières en zone urbaine
     SELECT comptecommunal,                                                   -- N° du compte communal
            ST_CollectionExtract(                                             -- Extrait les polygones (type 3)
               ST_MakeValid(geom),                                            -- Corrige les géométries invalides
               3) AS geom                                                     -- MultiPolygon résultant de type 3 
     FROM "{schema_travail}"."{insee}_b1_t17"                                 -- Source : UF en zone urbaine
     
     UNION ALL                                                                -- Empile les géométries sans éliminer les doublons
     
     -- Partie 2 : Zones finales a débroussailler hors zone urbaine
     SELECT comptecommunal,                                                   -- N° du compte communal
            ST_CollectionExtract(                                             -- Extrait les polygones (type 3)
               ST_MakeValid(geom),                                            -- Corrige les géométries invalides
               3) AS geom                                                     -- MultiPolygon résultant de type 3 
     FROM "{schema_travail}"."{insee}_b1_t16"                                 -- Source : zones finales hors zone U
)
SELECT comptecommunal,                                                        -- N° du compte communal du propriétaire
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (sources b1_t* déja typées)
          ST_CollectionExtract(                                               -- Extrait les polygones (type 3)
             ST_MakeValid(                                                    -- Valide après fusion
                ST_UnaryUnion(                                                -- Fusionne toutes les géométries du même compte
                   ST_Collect(geom))),                                        -- Collecte toutes les géométries
             3),                                                              -- Type 3 = MultiPolygon
       2154) AS geom                                                          -- MultiPolygon fusionné en Lambert 93
FROM union_all                                                                -- Source : empilage des deux tables
GROUP BY comptecommunal;                                                      -- Regroupement par compte communal

DELETE FROM "{schema_travail}"."{insee}_b1_t18"
WHERE geom IS NULL                                                     
OR ST_IsEmpty(geom)                                                    
OR NOT ST_IsValid(geom); 

CREATE INDEX idx_{insee}_b1_t18_geom
ON "{schema_travail}"."{insee}_b1_t18"
USING gist (geom);

								
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t19" : Zones totales a débroussailler hors emprises non cadastrées.
---- Description : Cette étape retire des zones a débroussailler (issues de b1_t18) toutes les surfaces
--                 correspondant a des espaces non cadastrés (voirie, domaine public, zones sans référence
--                 foncière). Le résultat représente la zone finale réellement a la charge des propriétaires.
--
---- Méthode     : - Jointure spatiale entre les zones totales a débroussailler (b1_t18)
--                   et les emprises non cadastrées (non_cadastre)
--                 - Application d’une différence géométrique (ST_Difference) lorsque recouvrement
--                 - Validation et homogénéisation des géométries (ST_MakeValid + ST_CollectionExtract)
--                 - Standardisation du système de coordonnées (SRID 2154 - Lambert 93)
--                 - Suppression des géométries nulles, vides ou invalides
--                 - Indexation spatiale GIST pour optimiser la consultation
--
---- Attributs   : -> comptecommunal : Identifiant du propriétaire (compte communal)
--                 -> geom           : Zone finale a débroussailler hors domaine public (MULTIPOLYGON, SRID 2154)


DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t19";
 
CREATE TABLE "{schema_travail}"."{insee}_b1_t19" AS
SELECT b18.comptecommunal,                                                    -- N° du compte communal du propriétaire
       CASE
           -- Cas 1 : La zone intersecte une zone non cadastrée (soustraction nécessaire)
           WHEN nc.geom IS NOT NULL                                           -- Vérifie l'existence d'une zone non cadastrée
           THEN ST_CollectionExtract(                                         -- Extrait les polygones (type 3)
                   ST_MakeValid(                                              -- Corrige les géométries invalides
                      ST_Difference(                                          -- Soustrait la zone non cadastrée
                         ST_MakeValid(b18.geom),                              -- Rend valide la géométrie des zones totales
                         ST_MakeValid(nc.geom))),                             -- Rend valide la géométrie non cadastrée
                   3)                                                         -- Type 3 = MultiPolygon
           
           -- Cas 2 : Aucune zone non cadastrée n'intersecte (conserver tel quel)
           ELSE ST_CollectionExtract(                                         -- Extrait les polygones (type 3)
                   ST_MakeValid(b18.geom),                                    -- Corrige les géométries invalides
                   3)                                                         -- Type 3 = MultiPolygon
       END AS geom                                                            -- Géométrie résultante selon le cas
FROM "{schema_travail}"."{insee}_b1_t18" b18                                  -- Source : zones totales a débroussailler
LEFT JOIN "{schema_travail}"."{insee}_non_cadastre" nc                        -- Jointure avec les zones non cadastrées
ON ST_Intersects(b18.geom, nc.geom);                                          -- Condition : intersection spatiale

DELETE FROM "{schema_travail}"."{insee}_b1_t19"
WHERE geom IS NULL                                                        
OR ST_IsEmpty(geom)                                                      
OR NOT ST_IsValid(geom);     

ALTER TABLE "{schema_travail}"."{insee}_b1_t19"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);  

CREATE INDEX idx_{insee}_b1_t19_geom
ON "{schema_travail}"."{insee}_b1_t19"
USING gist (geom);
 

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_b1_t20" : Nettoyage géométrique final des zones a débroussailler.
---- Description : Réalise un traitement de correction géométrique sur les zones totales a débroussailler 
--                 (b1_t19) afin d’éliminer les artefacts topologiques : épines, micro-dents, points 
--                 doublons ou distorsions issues des opérations précédentes. Le processus s’appuie sur 
--                 une séquence contrôlée de buffers et de snaps a tolérance millimétrique.
--
---- Méthode     : - Application d’un buffer négatif suivi d’un snap pour retirer les épines externes
--                 - Application d’un buffer positif suivi d’un snap pour combler les épines internes
--                 - Suppression des sommets redondants (ST_RemoveRepeatedPoints)
--                 - Validation systématique des géométries (ST_MakeValid)
--                 - Homogénéisation polygonale (ST_CollectionExtract, type 3)
--                 - Projection finale en Lambert 93 (SRID 2154)
--                 - Nettoyage des géométries nulles, vides ou invalides
--                 - Indexation spatiale GIST pour une interrogation rapide
--
---- Attributs   : -> comptecommunal : Identifiant du propriétaire (compte communal)
--                 -> geom           : Zone finale a débroussailler nettoyée (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t20";

CREATE TABLE "{schema_travail}"."{insee}_b1_t20" AS
-- Épuration des épines externes (spikes sortants)
WITH epine_externe AS (
     SELECT b19.comptecommunal,                                               -- N° du compte communal du propriétaire
            ST_CollectionExtract(                                             -- Extrait les polygones (type 3)
               ST_MakeValid(                                                  -- Corrige les géométries invalides
                  ST_Snap(                                                    -- Aligne le tampon sur la géométrie d'origine
                     ST_RemoveRepeatedPoints(                                 -- Supprime les nœuds consécutifs proches (<0.3mm)
                        ST_Buffer(                                            -- Buffer négatif pour rétracter les épines externes
                           b19.geom,
                           -0.001,                                            -- Tampon négatif de 0.1mm
                           'join=mitre mitre_limit=5.0'),                     -- Jointure en angle avec limite mitre
                        0.003),                                               -- Tolérance de suppression des points répétés (0.3mm)
                     b19.geom,                                                -- Géométrie de référence pour le snap
                     0.0006)),                                                -- Distance d'accrochage (0.6mm)
               3) AS geom                                                     -- MultiPolygon résultant de type 3 
     FROM "{schema_travail}"."{insee}_b1_t19" b19                             -- Source : zones totales hors zones non cadastrées
),
-- Épuration des épines internes (spikes rentrants)
epine_interne AS (
     SELECT epext.comptecommunal,                                             -- N° du compte communal du propriétaire
            ST_CollectionExtract(                                             -- Extrait les polygones (type 3)
               ST_MakeValid(                                                  -- Corrige les géométries invalides
                  ST_Snap(                                                    -- Aligne le tampon sur la géométrie d'origine
                     ST_RemoveRepeatedPoints(                                 -- Supprime les nœuds consécutifs proches (<0.3mm)
                        ST_Buffer(                                            -- Buffer positif pour combler les épines internes
                           epext.geom,
                           0.001,                                             -- Tampon positif de 0.1mm
                           'join=mitre mitre_limit=5.0'),                     -- Jointure en angle avec limite mitre
                        0.003),                                               -- Tolérance de suppression des points répétés (0.3mm)
                     b19.geom,                                                -- Géométrie d'origine pour le snap
                     0.0006)),                                                -- Distance d'accrochage (0.6mm)
               3) AS geom                                                     -- MultiPolygon résultant de type 3 
     FROM epine_externe epext                                                 -- Source : géométries sans épines externes
     JOIN "{schema_travail}"."{insee}_b1_t19" b19                             -- Jointure avec géométrie d'origine
     ON epext.comptecommunal = b19.comptecommunal                             -- Condition : même propriétaire
)
-- Requête finale : Validation et extraction des géométries nettoyées
SELECT epint.comptecommunal,                                                  -- N° du compte communal du propriétaire
       ST_SetSRID(                                                            -- Définit le SRID en 2154 (source b1_t19 déja typée)
          ST_CollectionExtract(                                               -- Extrait les polygones (type 3)
             ST_MakeValid(epint.geom),                                        -- Corrige les géométries invalides
             3),                                                              -- Type 3 = MultiPolygon
       2154) AS geom                                                          -- MultiPolygon nettoyé en Lambert 93
FROM epine_interne epint                                                      -- Source : géométries sans épines externes ni internes
WHERE epint.geom IS NOT NULL                                                  -- Filtre : élimine les géométries nulles
AND NOT ST_IsEmpty(epint.geom);                                               -- Filtre : élimine les géométries vides

DELETE FROM "{schema_travail}"."{insee}_b1_t20"
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                       
OR NOT ST_IsValid(geom);    

CREATE INDEX idx_{insee}_b1_t20_geom
ON "{schema_travail}"."{insee}_b1_t20"
USING gist (geom);
                                                             

--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                                  PARTIE X                                               ----
----                                ZONES FINALES a DÉBROUSSAILLER PAR PROPRIÉTAIRE                          ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Regrouper, pour chaque propriétaire (comptecommunal), toutes les surfaces bâties a débroussailler.    ----
---- - Inclure a la fois les surfaces situées en zone urbaine (sur unité foncière) et hors zone U (zone OLD).----
---- - Supprimer toutes les zones non cadastrées ainsi que les artefacts géométriques (épines, trous, etc.). ----
---- - Générer une géométrie propre, valide, et consolidée par propriétaire, au format MultiPolygon 2154.    ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - Fusion des surfaces bâties hors zone U et des parties d’unités foncières situées en zone U.           ----
---- - Soustraction des zones non cadastrées pour limiter les surfaces a la propriété connue.                ----
---- - Nettoyage géométrique rigoureux (double tampon, suppression de doublons, snapping).                   ----
---- - Conversion en MultiPolygon et reprojection dans le système de projection Lambert 93 (EPSG:2154).      ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Pour chaque compte communal : une géométrie MultiPolygon (2154) valide, composée uniquement des       ----
----   surfaces bâties soumises a l’obligation légale de débroussaillement, situées soit dans les zones      ----
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

---- Création de la table "{insee}_result1" : Extraction finale des zones a débroussailler dans la bande OLD 200m.
---- Description : Cette table isole les zones effectivement situées dans la bande de 200 mètres autour des 
--                 massifs forestiers (old200m) a partir des zones finales a débroussailler (b1_t20). 
--                 Le résultat représente la zone réglementairement soumise a l’obligation de débroussaillement.
--
---- Méthode     : - Intersection spatiale entre les zones a débroussailler (b1_t20)
--                   et le périmètre réglementaire OLD 200m (old200m)
--                 - Validation et homogénéisation géométrique (ST_MakeValid + ST_CollectionExtract)
--                 - Projection en Lambert 93 (SRID 2154)
--                 - Suppression des entités nulles, vides ou invalides
--                 - Indexation spatiale GIST pour optimisation des performances
--
---- Attributs   : -> comptecommunal : Identifiant du propriétaire (compte communal)
--                 -> geom           : Géométrie intersectant la bande OLD 200m (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result1";
 
CREATE TABLE "{schema_travail}"."{insee}_result1" AS         
SELECT b20.comptecommunal,                                -- Conserve l’attribut comptecommunal
       ST_SetSRID(                                        -- Assigne le système de coordonnées EPSG:2154
          ST_CollectionExtract(                           -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                -- Corrige les géométries invalides
                ST_Intersection(                          -- Calcule l’intersection spatiale
                   ST_MakeValid(b20.geom),                -- Rend valide la géométrie des zones a débroussailler
                   ST_MakeValid(o.geom))),                -- Rend valide la géométrie du périmètre OLD200m              
             3),                                          -- Type 3 = Polygone / MultiPolygon
       2154) AS geom                                      -- Définit la SRID et nomme la colonne géométrie résultante
FROM "{schema_travail}"."{insee}_b1_t20" AS b20           -- Source : zones finales a débroussailler
JOIN {SCHEMA_PUBLIC}.{TABLE_OLD200M} AS o                 -- Jointure avec la couche de périmètre OLD 200m
ON ST_Intersects(b20.geom, o.geom);                       -- Conserve uniquement les entités qui s’intersectent
                                         
CREATE INDEX idx_{insee}_result1_geom 
ON "{schema_travail}"."{insee}_result1"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_result1_rg" : Fusion globale des zones bâties a débroussailler.
---- Description : Cette table regroupe l’ensemble des zones bâties a débroussailler, qu’elles soient 
--                 situées en zone urbaine (U) ou hors zone U, en une seule entité géographique. 
--                 Le processus applique une correction topologique, supprime les redondances 
--                 géométriques et produit un MultiPolygon unique prêt a l’export cartographique 
--                 ou a la diffusion.
--
---- Méthode     : - Union de toutes les géométries (ST_Union)
--                 - Validation et nettoyage topologique (ST_MakeValid)
--                 - Suppression des sommets redondants (ST_RemoveRepeatedPoints, tolérance 5 cm)
--                 - Conversion en MultiPolygon unique (ST_Multi)
--                 - Application du SRID 2154 (Lambert 93)
--                 - Suppression des entités nulles, vides ou invalides
--                 - Indexation spatiale GIST pour accélérer les requêtes
--
---- Attributs   : -> geom : Emprise totale des zones bâties a débroussailler (MULTIPOLYGON, SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result1_rg";

CREATE TABLE "{schema_travail}"."{insee}_result1_rg" AS                     
SELECT ST_SetSRID(                                           -- Assigne le système de coordonnées EPSG:2154
         ST_Multi(                                           -- Convertit en MultiPolygon car unique
            ST_Union(                                        -- Fusionne toutes les géométries en une seule entité
               ST_MakeValid(                                 -- Corrige les géométries invalides selon les règles de validité OGC
                  ST_RemoveRepeatedPoints(r1.geom, 0.01)     -- Supprime les sommets trop rapprochés (moins de 1 cm) pour nettoyer la topologie               
                  ))),                                   
       2154) AS geom                                         -- Définit la SRID et nomme la colonne géométrie résultante
FROM "{schema_travail}"."{insee}_result1" r1;                     -- Source : Résultats intermédiaires des zones a débroussailler

DELETE FROM "{schema_travail}"."{insee}_result1_rg"                                 
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                   
OR NOT ST_IsValid(geom);                                                
                                                                     

CREATE INDEX idx_{insee}_result1_rg_geom                           
ON "{schema_travail}"."{insee}_result1_rg"                            
USING gist (geom);                                               

														  
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ---- 
----                                             PARTIE XI :                                                 ----
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
----       déja fusionnées, avec correction et typage MultiPolygon.                                          ----
---- - **Nettoyage cadastral** :                                                                             ----
----     - Retrait des zones situées hors périmètre cadastral a l’aide d’une différence géométrique entre    ----
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

---- Création de la table "{insee}_trou1" : Détection des zones résiduelles non couvertes dans les tampons hors zone U
---- Description : Identifie les surfaces non couvertes par les zones a débroussailler consolidées (`result1_rg`)
--                 a l’intérieur des tampons fusionnés hors zone urbaine (`tampon_ihu_rg`). 
--                 Ces zones correspondent a des vides géométriques ou incohérences résiduelles 
--                 issues des opérations de différence et de fusion spatiale.
--
---- Méthode     : - Différence géométrique entre les tampons hors zone U et les zones OLD consolidées
--                 - Validation des géométries (ST_MakeValid)
--                 - Extraction des polygones valides (ST_CollectionExtract, type 3)
--                 - Harmonisation du système de coordonnées (EPSG:2154 - Lambert 93)
--
---- Attributs   : -> geom : géométrie MultiPolygon représentant les zones non couvertes (SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_trou1";                    
   
CREATE TABLE "{schema_travail}"."{insee}_trou1" AS
SELECT ST_SetSRID(                                          -- Définit le système de coordonnées EPSG:2154
          ST_CollectionExtract(                             -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                  -- Corrige les géométries invalides
                ST_Difference(                              -- Soustrait r1rg de t_ihu
                    ST_MakeValid(t_ihu.geom),               -- Corrige les géométries invalides   
	                ST_MakeValid(r1rg.geom))),              -- Corrige les géométries invalides  
             3),
        2154) AS geom                                       -- Géométrie résultante en 2154
FROM "{schema_travail}"."{insee}_tampon_ihu_rg" t_ihu       -- Tampons IHU (hors zone urbaine)
JOIN "{schema_travail}"."{insee}_result1_rg" r1rg           -- Zones OLD consolidées
ON ST_Intersects(t_ihu.geom, r1rg.geom);                    -- Condition : Intersection entre les zones de superpositions et le résultats 1

DELETE FROM "{schema_travail}"."{insee}_trou1"                               
WHERE geom IS NULL                                                     
OR ST_IsEmpty(geom)                                                  
OR NOT ST_IsValid(geom);                                          

CREATE INDEX idx_{insee}_trou1_geom                                      
ON "{schema_travail}"."{insee}_trou1"                                        
USING gist (geom);                                                      
 

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_trou2" : Exclusion des zones non cadastrées dans les zones résiduelles
---- Description : Cette table soustrait les zones non cadastrées des zones résiduelles identifiées dans "trou1".
--                 Elle élimine les portions de vides géométriques situées sur le domaine public ou hors parcelles.
--                 Le résultat conserve uniquement les zones résiduelles réellement situées sur du foncier cadastré.
--
---- Méthode     : - Intersection spatiale préalable pour limiter le calcul (ST_Intersects)
--                 - Différence géométrique entre les zones résiduelles et les zones non cadastrées
--                 - Validation et extraction des polygones valides (ST_MakeValid, ST_CollectionExtract)
--                 - Harmonisation du système de coordonnées (EPSG:2154 - Lambert 93)
--
---- Attributs   : -> geom : géométrie MultiPolygon représentant les zones résiduelles cadastrées (SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_trou2";
 
CREATE TABLE "{schema_travail}"."{insee}_trou2" AS
SELECT ST_SetSRID(                                                            -- Définit le système de coordonnées EPSG:2154
          ST_CollectionExtract(                                               -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_Difference(                                                -- Soustrait les zones non cadastrées
                   ST_MakeValid(t.geom),                                      -- Rend valide la géométrie des zones résiduelles
                   ST_MakeValid(nc.geom))),                                   -- Rend valide la géométrie des zones non cadastrées
             3),                                                              -- Type 3 
       2154) AS geom                                                          -- Géométrie finale Lambert 93
FROM "{schema_travail}"."{insee}_trou1" AS t                                  -- Source : zones résiduelles identifiées
CROSS JOIN "{schema_travail}"."{insee}_non_cadastre" AS nc                    -- Source : zones non cadastrées
WHERE ST_Intersects(t.geom, nc.geom);                                         -- Filtre spatial : uniquement les géométries intersectées

DELETE FROM "{schema_travail}"."{insee}_trou2"  
WHERE geom IS NULL 
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

CREATE INDEX idx_{insee}_trou2_geom                                   
ON "{schema_travail}"."{insee}_trou2"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_trou3" : Extraction des trous individuels et calcul de leur surface
---- Description : Cette table décompose les géométries issues de "{insee}_trou2" en polygones élémentaires, 
--                 identifie chaque trou par un chemin interne et calcule sa surface en m². 
--                 L’objectif est de repérer et quantifier les zones résiduelles indépendantes.
--
---- Méthode     : - Décomposition des MultiPolygons en polygones simples (ST_Dump)
--                 - Calcul de la surface individuelle (ST_Area)
--                 - Filtrage des géométries nulles, invalides ou insignifiantes (< 0.1 m²)
--
---- Attributs   : -> path     : identifiant structuré du polygone au sein de la géométrie d’origine
--                 -> surface  : aire du polygone (m²)
--                 -> geom     : géométrie Polygon, SRID 2154 (Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_trou3";                   
 

CREATE TABLE "{schema_travail}"."{insee}_trou3" AS                           
SELECT d.path,                                                          -- Chemin hiérarchique du polygone dans la géométrie initiale
       ST_Area(d.geom) AS surface,                                      -- Surface individuelle du trou (en m²)
       ST_SetSRID(d.geom, 2154) AS geom                                 -- Géométrie du polygone extrait avec SRID explicite
FROM (SELECT (ST_Dump(t.geom)).*                                        -- Décomposition des MultiPolygon en polygones simples
      FROM "{schema_travail}"."{insee}_trou2" t) AS d;                  -- Source : géométries des trous a détailler

DELETE FROM "{schema_travail}"."{insee}_trou3"                               
WHERE geom IS NULL                                                      
OR ST_IsEmpty(geom)                                                  
OR NOT ST_IsValid(geom)                                              
OR surface <= 0.1;                                                     

CREATE INDEX idx_{insee}_trou3_geom                                      
ON "{schema_travail}"."{insee}_trou3"                                      
USING gist (geom);                                                     
 

--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE XII                                                  ----
----                        RECONSTRUCTION DES ÎLOTS NON ATTRIBUÉS EN ZONES DE SUPERPOSITION                 ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Identifier les **zones de superposition** entre comptes communaux qui sont **restées non traitées**   ----
----   par les étapes de débroussaillement précédentes.                                                      ----
---- - Générer des **îlots polygonaux autonomes** dans ces zones, afin de les soumettre a une attribution    ----
----   différée ou partagée.                                                                                 ----
---- - Associer a chaque îlot la **liste exacte des comptes communaux concernés** pour appuyer un arbitrage. ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - **Intersection précise** entre les tampons des zones de superposition (`tampon_ihu`) et les **trous   ----
----    géométriques restants** (`trou3`) pour extraire uniquement les zones non couvertes situées dans des  ----
----    situations de chevauchement foncier.                                                                 ----
---- - **Nettoyage des doublons**, conversion en MultiPolygon et extraction uniquement des géométries valides----
---- - **Reconstituer les contours fermés** a partir des limites extraites, en les transformant en polygones.----
---- - **Attribution multi-comptes** : chaque polygone reconstruit est associé a tous les comptes communaux  ----
----    dont les tampons contiennent le **point central (PointOnSurface)** du polygone.                      ----
---- - **Fusion finale** par combinaison de comptes : Union des géométries en une seule entité              ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Un polygone distinct pour chaque îlot résiduel, correspondant a une zone de superposition non couverte----
---- - Pour chaque polygone, la liste complète des comptes communaux impliqués, sous forme de tableau.       ----
---- - Une table propre et consolidée, permettant une attribution claire des responsabilités de              ---- 
----   débroussaillement.                                                                                    ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - `ST_Intersection` : pour **isoler uniquement les zones non couvertes** dans les périmètres de conflit.----
---- - `ST_CollectionExtract + ST_Multi + ST_MakeValid` : garantissent que toutes les géométries sont bien   ----
----   **homogènes, valides et prêtes pour la reconstruction polygonale**.                                   ----
---- - `ST_Boundary` + `ST_Polygonize` : permettent de **reconstruire des polygones fermés** a partir des    ----
----   bords des zones résiduelles.                                                                          ----
---- - `ST_PointOnSurface + ST_Within` : lient chaque îlot au(x) compte(s) communal(aux) **de façon robuste**----
----   , même pour les géométries complexes.                                                                 ----
---- - `ARRAY_AGG(DISTINCT)` : évite les doublons de comptes lors de l’agrégation par îlot.                  ----
---- - `ST_Union` final : regroupe les géométries de chaque combinaison unique de comptes en une entité      ----
----   polygonale consolidée, **facilement visualisable et exploitable**.                                    ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_ilot_du_trou_t1" : Intersection entre zones de superpositions et trous résiduels
---- Description : Cette table calcule l’intersection entre les zones de superposition (tampons IHU) et les 
--                 polygones résiduels issus de "trou3". Elle permet d’identifier les portions de superpositions 
--                 encore non couvertes par les traitements précédents. Ces zones correspondent a des îlots 
--                 géométriques restant a traiter.
--
---- Méthode     : - Intersection spatiale entre tampons IHU et trous individuels
--                 - Validation et extraction des polygones valides (ST_MakeValid, ST_CollectionExtract)
--                 - Définition du système de coordonnées (EPSG:2154 - Lambert 93)
--
---- Attributs   : -> comptecomm1 : identifiant du premier compte communal
--                 -> comptecomm2 : identifiant du second compte communal
--                 -> geom        : géométrie MultiPolygon en Lambert 93 (SRID 2154)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t1";
 
CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t1" AS
SELECT t_ihu.comptecomm1,                                              -- N° du compte communal 1
       t_ihu.comptecomm2,                                              -- N° du compte communal 2
       ST_SetSRID(                                                     -- Définit le système de coordonnées EPSG:2154
          ST_CollectionExtract(                                        -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                             -- Corrige les géométries invalides
                ST_Intersection(                                       -- Calcule l’intersection trous/superpositions
                   ST_MakeValid(t_ihu.geom),                           -- Rend valide la géométrie des tampons IHU
                   ST_MakeValid(tr3.geom))),                           -- Rend valide la géométrie des trous individuels
             3),                                                       -- Type 3 
       2154) AS geom                                                   -- Géométrie finale Lambert 93
FROM "{schema_travail}"."{insee}_tampon_ihu" AS t_ihu                  -- Source : zones de superposition (tampons IHU)
JOIN "{schema_travail}"."{insee}_trou3" AS tr3                         -- Source : trous individuels corrigés
ON ST_Intersects(t_ihu.geom, tr3.geom);                                -- Filtre spatial : uniquement les intersections réelles
 
DELETE FROM "{schema_travail}"."{insee}_ilot_du_trou_t1"            
WHERE geom IS NULL 
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

CREATE INDEX idx_{insee}_ilot_du_trou_t1_geom                              
ON "{schema_travail}"."{insee}_ilot_du_trou_t1"
USING gist (geom);
 

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_ilot_du_trou_t2" : Consolidation des zones de superposition non couvertes
---- Description : Cette table regroupe les géométries issues de "ilot_du_trou_t1" en supprimant les doublons 
--                 et en ne conservant que les entités valides.
--
---- Méthode     : - Suppression des doublons (DISTINCT)
--                 - Validation des géométries (ST_IsValid)
--                 - Nettoyage des entités nulles ou vides
--
---- Attributs   : -> geom : géométrie MultiPolygon, EPSG:2154 (Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t2";


CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t2" AS
SELECT DISTINCT geom                                                         -- Supprime les doublons géométriques
FROM "{schema_travail}"."{insee}_ilot_du_trou_t1"                            -- Source : intersections trous/superpositions
WHERE geom IS NOT NULL;                                                      -- Filtre initial : exclut les géométries nulles

DELETE FROM "{schema_travail}"."{insee}_ilot_du_trou_t2"                        
WHERE geom IS NULL 
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

ALTER TABLE "{schema_travail}"."{insee}_ilot_du_trou_t2"
ALTER COLUMN geom 
TYPE geometry(MULTIPOLYGON, 2154)
USING ST_SetSRID(geom, 2154);

CREATE INDEX idx_{insee}_ilot_du_trou_t2_geom                                 
ON "{schema_travail}"."{insee}_ilot_du_trou_t2"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_ilot_du_trou_t3" : Reconstruction des polygones a partir des contours des zones de superposition non couvertes
---- Description : Cette table reconstruit les polygones a partir des limites des îlots de trous issus de "ilot_du_trou_t2".
--                 Elle applique un processus de polygonisation (ST_Polygonize) afin de générer de nouvelles entités 
--                 polygonales valides représentant les zones résiduelles non couvertes. Ces géométries reconstruites 
--                 constituent la base pour les analyses géospatiales finales.
--
---- Méthode     : - Extraction des contours (ST_Boundary)
--                 - Fusion topologique des lignes (ST_UnaryUnion)
--                 - Polygonisation des limites (ST_Polygonize)
--                 - Conversion des polygones simples en MultiPolygon
--
---- Attributs   : -> id   : identifiant unique du polygone reconstruit
--                 -> geom : géométrie MultiPolygon (EPSG:2154 - Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t3";

CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t3" AS
WITH limites_ilots AS (
    SELECT ST_Union(                                                 -- Fusion topologique robuste des contours
               ST_Boundary(                                          -- Extrait les limites sous forme de lignes
                   ST_CollectionExtract(                             -- Extrait uniquement les polygones (type 3)
                       ST_MakeValid(geom),                           -- Corrige les géométries invalides
                   3))) AS geom                                      -- Géométrie linéaire résultante
    FROM "{schema_travail}"."{insee}_ilot_du_trou_t2"                -- Source : zones consolidées des îlots
    WHERE ST_IsValid(geom)                                           -- Filtre : conserve uniquement les géométries valides
),
polygones_ilots AS (
    SELECT ST_Dump(                                                  -- Décompose les MultiPolygons en entités élémentaires
               ST_Polygonize(geom)) AS dmp                           -- Reconstruit des polygones fermés a partir des lignes fusionnées
    FROM limites_ilots                                               -- Source : limites fusionnées topologiquement
)
SELECT (dmp).path[1] AS id,                                          -- Identifiant séquentiel du polygone reconstruit
       CASE
           WHEN GeometryType((dmp).geom) = 'POLYGON'                 -- Cas : géométrie simple
               THEN ST_Multi((dmp).geom)                             -- Conversion en MultiPolygon
           WHEN GeometryType((dmp).geom) = 'MULTIPOLYGON'            -- Cas : déja MultiPolygon
               THEN (dmp).geom                                       -- Conserve la géométrie telle quelle
           ELSE NULL                                                 -- Cas : géométrie non polygonale (ignorée)
       END AS geom                                                   -- Géométrie résultante
FROM polygones_ilots                                                 -- Source : polygones générés
WHERE GeometryType((dmp).geom) IN ('POLYGON', 'MULTIPOLYGON');       -- Filtre : conserve uniquement les géométries polygonales

DELETE FROM "{schema_travail}"."{insee}_ilot_du_trou_t3"               
WHERE geom IS NULL 
OR ST_IsEmpty(geom)
OR NOT ST_IsValid(geom);

CREATE INDEX idx_{insee}_ilot_du_trou_t3_geom              
ON "{schema_travail}"."{insee}_ilot_du_trou_t3"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_ilot_du_trou_t4" : Attribution des îlots de trous aux comptes communaux.
---- Description : Cette table attribue chaque îlot généré aux comptes communaux concernés en fonction 
--                 des zones tamponnées. Elle lie chaque trou identifié a un ou plusieurs comptes 
--                 pour une gestion fine des zones a traiter.
--
---- Méthode     : - Génération d’un point interne pour chaque îlot (ST_PointOnSurface)
--                 - Jointure spatiale avec les zones tamponnées (ST_Within)
--                 - Agrégation des comptes communaux impliqués (ARRAY_AGG DISTINCT)
--                 - Fusion et validation des géométries
--
---- Attributs   : -> liste_ncc : liste des comptes communaux liés a chaque îlot
--                 -> geom      : géométrie MultiPolygon (EPSG:2154 - Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t4";

CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t4" AS
SELECT ARRAY_AGG(DISTINCT t.comptecomm1 ORDER BY t.comptecomm1) AS liste_ncc,   -- Liste triée et sans doublons
       ST_SetSRID(                                                              -- Définit la projection EPSG:2154
          ST_Multi(                                                             -- Convertit en MultiPolygon
             ST_CollectionExtract(                                              -- Extrait uniquement les polygones (type 3)
                ST_MakeValid(t3.geom),                                          -- Corrige les géométries invalides
             3)),                                                               -- Type 3 = Polygone
       2154) AS geom                                                            -- Géométrie résultante (Lambert 93)
FROM "{schema_travail}"."{insee}_ilot_du_trou_t3" t3                            -- Source : îlots polygonisés
INNER JOIN "{schema_travail}"."{insee}_tampon_ihu" t                            -- Source : zones tamponnées par compte communal
ON ST_Within(ST_PointOnSurface(t3.geom), t.geom)                                -- Test d’appartenance spatiale
WHERE GeometryType(t3.geom) IN ('POLYGON', 'MULTIPOLYGON')                      -- Filtre : types polygonaux uniquement
GROUP BY t3.geom;                                                               -- Agrégation par géométrie

DELETE FROM "{schema_travail}"."{insee}_ilot_du_trou_t4"                         
WHERE geom IS NULL 
OR ST_IsEmpty(geom)
OR NOT ST_IsValid(geom)
OR liste_ncc IS NULL
OR array_length(liste_ncc, 1) IS NULL;

CREATE INDEX idx_{insee}_ilot_du_trou_t4_geom                                
ON "{schema_travail}"."{insee}_ilot_du_trou_t4"
USING gist (geom);

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_ilots_final" : Résultat final des zones de superpositions non couvertes ayant plusieurs comptes communaux.
---- Description : Cette table stocke les zones de superpositions non couvertes associées a plusieurs comptes communaux.
--                 Les comptes sont regroupés dans une liste (tableau) et leurs géométries fusionnées pour obtenir
--                 une représentation unique par ensemble de comptes.
--
---- Méthode     : - Agrégation des comptes communaux (ARRAY_AGG DISTINCT)
--                 - Fusion géométrique topologique (ST_UnaryUnion)
--                 - Validation et extraction des MultiPolygons
--
---- Attributs   : -> id         : identifiant unique auto-incrémenté
--                 -> liste_ncc  : liste des comptes communaux
--                 -> geom       : géométrie MultiPolygon (EPSG:2154 - Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilots_final";

CREATE TABLE "{schema_travail}"."{insee}_ilots_final" ( 
    id SERIAL PRIMARY KEY,                                             -- Identifiant auto-incrémenté
    liste_ncc TEXT[],                                                  -- Liste des comptes communaux sous forme de tableau
    geom geometry(MultiPolygon, 2154)                                  -- Géométrie en MultiPolygon (Lambert 93)
);

INSERT INTO "{schema_travail}"."{insee}_ilots_final" (liste_ncc, geom)
SELECT it4.liste_ncc,                                                  -- Liste des comptes communaux
       ST_SetSRID(                                                     -- Définit la projection EPSG:2154
          ST_CollectionExtract(                                        -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                             -- Corrige les géométries invalides
                ST_Union(it4.geom)),                                   -- Fusion topologique des géométries par groupe
             3),
       2154) AS geom                                                   -- Géométrie résultante (MultiPolygon)
FROM "{schema_travail}"."{insee}_ilot_du_trou_t4" it4                       -- Source : îlots attribués aux comptes
GROUP BY it4.liste_ncc;                                                -- Regroupement par combinaison de comptes

DELETE FROM "{schema_travail}"."{insee}_ilots_final"
WHERE geom IS NULL 
OR ST_IsEmpty(geom)
OR NOT ST_IsValid(geom)
OR liste_ncc IS NULL
OR array_length(liste_ncc, 1) IS NULL;

CREATE INDEX idx_{insee}_ilots_final_geom
ON "{schema_travail}"."{insee}_ilots_final"
USING gist (geom);
 

--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE XIII                                                 ----
----                        ATTRIBUTION DES ÎLOTS RÉSIDUELS PAR POLYGONISATION VORONOÏ                       ----
----								                                                                          ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Répartir équitablement les zones de superposition non couvertes entre les propriétaires concernés.    ----
---- - Utiliser des polygones de Voronoï pour attribuer chaque portion de trou a un seul compte communal.    ----
---- - Intégrer les zones ainsi générées dans les surfaces finales a débroussailler par propriétaire.        ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - Interpolation régulière de points sur les bords des zones résiduelles.                                ----
---- - Génération de cellules de Voronoï a partir de ces points, découpées selon chaque îlot identifié.      ----
---- - Attribution des cellules a un compte communal par inclusion du point source.                          ----
---- - Regroupement des cellules attribuées pour chaque propriétaire.                                        ----
---- - Intersection finale avec les zones résiduelles pour obtenir les surfaces effectivement a traiter.     ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Une cellule polygonale par point interpolé, représentant une portion de trou affectée a un compte.    ----
---- - Une géométrie nette et homogène par propriétaire sur les zones non couvertes.                         ----
---- - Une répartition précise, sans chevauchement, des obligations sur les zones résiduelles partagées.     ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_VoronoiPolygons : pour découper automatiquement l’espace en zones d’influence autour de chaque     ----
----                        point.                                                                           ----
----   > Vulgarisation : chaque point rayonne dans toutes les directions jusqu’a toucher un voisin ,         ----
----     les frontières se forment a mi-distance, comme si chaque point « réclamait » son propre territoire. ----
---- - ST_Collect : pour regrouper tous les points en une géométrie MultiPoint, base de la polygonisation.   ----
---- - ST_Within : pour rattacher chaque cellule a son point source et en déduire le bon propriétaire.       ----
---- - ST_Intersection : pour découper précisément les cellules dans les contours réels des îlots.           ----
---- - ST_Union + ST_CollectionExtract : pour reconstituer des géométries propres, sans doublons ni erreurs. ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_ilot_voronoi_t1" : Polygones de Voronoï associés aux îlots de trous identifiés.
---- Description : Cette table génère des polygones de Voronoï a partir des points interpolés situés dans les îlots
--                 de superpositions non couvertes. Chaque polygone est attribué a un groupe de comptes communaux 
--                 selon son appartenance spatiale a un îlot.
--
---- Méthode     : - Agrégation des points par groupe de comptes (ST_Collect)
--                 - Calcul du diagramme de Voronoï (ST_VoronoiPolygons)
--                 - Décomposition des géométries (ST_Dump)
--                 - Projection et validation finale
--
---- Attributs   : -> id         : identifiant unique de l’îlot
--                 -> liste_ncc  : tableau des comptes communaux
--                 -> geom       : géométrie MultiPolygon (EPSG:2154 - Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_voronoi_t1";
 
CREATE TABLE "{schema_travail}"."{insee}_ilot_voronoi_t1" AS
SELECT DISTINCT
    ilfi.id,                                                                 -- Récupère l’identifiant unique de l’entité "ilfi"
    ilfi.liste_ncc,                                                          -- Récupère la liste des comptes communaux associés a l’entité
    ST_SetSRID(                                                              -- Définit le système de coordonnées de sortie (ici Lambert-93, EPSG:2154)
      ST_Multi(                                                              -- Force la géométrie de sortie en MultiPolygon, même si un seul polygone
        (ST_DUMP(                                                            -- Décompose les géométries complexes en éléments individuels (ici pour Voronoï)
          ST_VoronoiPolygons(                                                -- Génère les polygones de Voronoï a partir d’un ensemble de points
            ST_Collect(p.geom),                                              -- Agrège toutes les géométries de la table/alias "p" en une seule géométrie
            0,                                                               -- Tolérance = 0 → calcule des polygones Voronoï exacts sans simplification
            ST_Envelope(ilfi.geom)))                                         -- Limite l’extension des polygones Voronoï a l’emprise de la géométrie "ilfi"
--          ilfi.geom))                                                      -- Variante commentée : limite a la géométrie exacte d’"ilfi" plutôt qu’a son enveloppe
        ).geom                                                               -- Récupère la géométrie extraite par ST_DUMP
      )
    ,2154) AS geom                                                           -- Applique le SRID et renomme le résultat en "geom"
FROM "{schema_travail}"."{insee}_pt_interpol_rg" p                           -- Source : points interpolés regroupés
INNER JOIN "{schema_travail}"."{insee}_ilots_final" ilfi                     -- Source : îlots de trous avec cc
ON p.comptecommunal = ANY(ilfi.liste_ncc)                                    -- Jointure externe sur les comptes communaux
WHERE p.geom IS NOT NULL                                                     -- Filtre : Exclut les géométries invalides
AND ST_Area(ilfi.geom) > 0                                                   -- Filtre : Exclut les géométries de surface strictement égale a 0
GROUP BY ilfi.id, ilfi.liste_ncc;                                            -- Regroupe par liste de comptes communaux

CREATE INDEX idx_{insee}_ilot_voronoi_t1_geom
ON "{schema_travail}"."{insee}_ilot_voronoi_t1"
USING gist (geom);  
 

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_ilot_voronoi_t2" : Attribution des comptes communaux aux polygones Voronoï des trous.
---- Description : Cette table associe chaque polygone Voronoï issu des îlots de trous a un compte communal
--                 a partir des points interpolés. Chaque cellule Voronoï est donc affectée a un propriétaire précis.
--
---- Méthode     : - Jointure spatiale entre cellules Voronoï et points interpolés
--                 - Filtrage par appartenance des comptes a la liste de l’îlot
--                 - Validation et typage géométrique
--
---- Attributs   : -> id               : identifiant du polygone (hérité de l’îlot d’origine)
--                 -> comptecommunal   : compte communal associé au polygone
--                 -> geom             : géométrie MultiPolygon (EPSG:2154 - Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_voronoi_t2";

CREATE TABLE "{schema_travail}"."{insee}_ilot_voronoi_t2" AS                
SELECT iv1.id,                                                                -- Identifiant de l'îlot d'origine
       p.comptecommunal,                                                      -- Compte communal du point source
       ST_SetSRID(                                                            -- Définit le système de projection EPSG:2154
          ST_CollectionExtract(                                               -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(iv1.geom),                                          -- Corrige les géométries invalides
             3
          ),
          2154                                                                -- Code EPSG Lambert-93
       ) AS geom                                                              -- Nomme la colonne résultante
FROM "{schema_travail}"."{insee}_ilot_voronoi_t1" iv1                         -- Source : cellules de Voronoï par îlot
JOIN "{schema_travail}"."{insee}_pt_interpol_rg" p                            -- Source : points interpolés avec comptes communaux
ON ST_Within(p.geom, iv1.geom)                                                -- Condition : point contenu dans la cellule
AND p.comptecommunal = ANY(iv1.liste_ncc);                                    -- Condition : compte appartient a la liste de l'îlot

DELETE FROM "{schema_travail}"."{insee}_ilot_voronoi_t2"                    
WHERE geom IS NULL                                                     
OR ST_IsEmpty(geom)                                               
OR NOT ST_IsValid(geom);                                          

CREATE INDEX idx_{insee}_ilot_voronoi_t2_geom                            
ON "{schema_travail}"."{insee}_ilot_voronoi_t2"                             
USING gist (geom);                                                     
 
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_ilot_voronoi_t3" : Regroupement des polygones Voronoï des zones de superpositions 
---- non couvertes par compte communal.
---- Description : Cette table regroupe les polygones Voronoï générés a partir des zones de superposition non couvertes
--                 en un seul objet MultiPolygon par compte communal et par identifiant d’îlot. 
--                 Elle fournit une vision consolidée de la part attribuée a chaque propriétaire.
--
---- Méthode     : - Fusion géométrique par id et compte communal
--                 - Validation topologique et typage MultiPolygon
--
---- Attributs   : -> id               : identifiant de l’îlot
--                 -> comptecommunal   : propriétaire concerné
--                 -> geom             : géométrie MultiPolygon (EPSG:2154 - Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_voronoi_t3";          
  
CREATE TABLE "{schema_travail}"."{insee}_ilot_voronoi_t3" AS                     
SELECT iv2.id,                                                                -- Identifiant de l'îlot d'origine
       iv2.comptecommunal,                                                    -- Compte communal du propriétaire
       ST_SetSRID(                                                            -- Définit le système de projection EPSG:2154
          ST_CollectionExtract(                                               -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                                    -- Corrige les géométries invalides
                ST_Union(iv2.geom)),                                          -- Fusionne toutes les cellules du même groupe
             3),
        2154) AS geom                                                         -- Nomme la colonne résultante
FROM "{schema_travail}"."{insee}_ilot_voronoi_t2" iv2                         -- Source : cellules Voronoï attribuées
GROUP BY iv2.id, iv2.comptecommunal;                                          -- Regroupe par îlot et compte communal

DELETE FROM "{schema_travail}"."{insee}_ilot_voronoi_t3"                   
WHERE geom IS NULL                                                    
OR ST_IsEmpty(geom)                                               
OR NOT ST_IsValid(geom);                                          

CREATE INDEX idx_{insee}_ilot_voronoi_t3_geom                           
ON "{schema_travail}"."{insee}_ilot_voronoi_t3"                             
USING gist (geom);                                                   
  

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_ilot_voronoi_t4" : Découpe des polygones Voronoï avec les zones de superpositions 
---- non couvertes.
---- Description : Cette table découpe chaque polygone Voronoï produit pour les zones de superposition non couvertes 
--                 en intersection avec les îlots multi-propriétaires (`ilots_final`). 
--                 Chaque portion de Voronoï est ainsi attribuée a un seul propriétaire, garantissant une 
--                 répartition géométriquement cohérente des zones a débroussailler.
--
---- Méthode     : - Intersection entre les cellules Voronoï regroupées (t3) et les îlots multi-propriétaires
--                 - Validation topologique et extraction des polygones
--
---- Attributs   : -> id               : identifiant de l’îlot d’origine
--                 -> comptecommunal   : propriétaire unique
--                 -> geom             : géométrie MultiPolygon (EPSG:2154 - Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_voronoi_t4";


CREATE TABLE "{schema_travail}"."{insee}_ilot_voronoi_t4" AS
SELECT iv3.id,                                                              -- Identifiant de l’îlot d’origine
       iv3.comptecommunal,                                                  -- Compte communal du propriétaire
       ST_SetSRID(                                                          -- Définit le système de coordonnées EPSG:2154
          ST_CollectionExtract(                                             -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                                  -- Valide après intersection
                ST_Intersection(                                            -- Intersection Voronoï / îlot multi-propriétaire
                   ST_MakeValid(ilfi.geom),                                 -- Géométrie d’îlot validée
                   ST_MakeValid(iv3.geom))),                                -- Géométrie Voronoï validée          
          3), 
       2154) AS geom                                                        -- Géométrie résultante en MultiPolygon
FROM "{schema_travail}"."{insee}_ilots_final" ilfi                               -- Source : îlots de superposition non couverts
INNER JOIN "{schema_travail}"."{insee}_ilot_voronoi_t3" iv3                      -- Source : cellules Voronoï regroupées par propriétaire
ON ilfi.id = iv3.id                                                         -- Jointure sur l’identifiant d’îlot
AND ST_Intersects(ilfi.geom, iv3.geom);                                     -- Condition spatiale : intersection réelle

DELETE FROM "{schema_travail}"."{insee}_ilot_voronoi_t4"
WHERE geom IS NULL 
OR ST_IsEmpty(geom)
OR NOT ST_IsValid(geom);

CREATE INDEX idx_{insee}_ilot_voronoi_t4_geom
ON "{schema_travail}"."{insee}_ilot_voronoi_t4"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_ilot_voronoi_rg" : Zones non couvertes a débroussailler par propriétaire, regroupées.
---- Description : Cette table regroupe les zones non couvertes a débroussailler par chaque propriétaire 
--                 (compte communal), en fusionnant toutes les géométries issues de `{insee}_ilot_voronoi_t4`. 
--                 Le résultat est une géométrie unique par compte communal, représentée en MultiPolygon.
--
---- Méthode     : - Agrégation des zones par compte communal
--                 - Fusion topologique (ST_UnaryUnion)
--                 - Validation et typage MultiPolygon
--
---- Attributs   : -> comptecommunal : N° du propriétaire
--                 -> geom           : géométrie MultiPolygon (EPSG:2154 - Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_voronoi_rg";
 
CREATE TABLE "{schema_travail}"."{insee}_ilot_voronoi_rg" AS
SELECT iv4.comptecommunal,                                                  -- N° du compte communal (propriétaire)
       ST_SetSRID(                                                          -- Définit le système de projection EPSG:2154
          ST_CollectionExtract(                                             -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                                  -- Corrige les géométries invalides
                ST_Union(iv4.geom)),                                        -- Fusionne toutes les géométries du même compte communal       
          3), 
       2154) AS geom                                                        -- Géométrie résultante en Lambert-93
FROM "{schema_travail}"."{insee}_ilot_voronoi_t4" iv4                            -- Source : zones Voronoï découpées par propriétaire
GROUP BY iv4.comptecommunal;                                                -- Regroupement par compte communal

DELETE FROM "{schema_travail}"."{insee}_ilot_voronoi_rg"
WHERE geom IS NULL 
OR ST_IsEmpty(geom)
OR NOT ST_IsValid(geom);

CREATE INDEX idx_{insee}_ilot_voronoi_rg_geom
ON "{schema_travail}"."{insee}_ilot_voronoi_rg"
USING gist (geom);

 
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE XIV                                                  ----
----               FUSION FINALE ET EXTRACTION DES ZONES a DÉBROUSSAILLER PAR PROPRIÉTAIRE                   ----
----								                                                                         ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Regrouper toutes les zones a débroussailler (initiales et résiduelles) par propriétaire.              ----
---- - Nettoyer ces zones pour supprimer les artefacts géométriques liés aux traitements précédents.         ----
---- - Extraire uniquement les surfaces situées dans le périmètre réglementaire des 200 mètres OLD.          ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - Fusion des surfaces initiales et des surfaces générées par Voronoï, compte communal par compte.       ----
---- - Nettoyage géométrique en quatre étapes : tampons, alignements, suppressions d’épines et de trous.     ----
---- - Interception finale avec la zone des 200 mètres autour des massifs a enjeu, avec filtrage de surface. ----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Une géométrie unique par compte communal, intégrant toutes les zones a débroussailler.                ----
---- - Des contours corrigés et alignés, sans artefacts ni résidus.                                          ----
---- - Un extrait précis des surfaces réglementaires OLD supérieures a 0,5 ha.                               ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_Union + COALESCE : pour regrouper les géométries doublées ou exclusives d’une des sources.         ----
---- - ST_Buffer + ST_Snap : pour corriger les contours sans distorsion excessive.                           ----
---- - ST_RemoveRepeatedPoints : pour supprimer les sommets inutiles après tampon.                           ----
---- - ST_RemoveSmallParts : pour éliminer les petites entités inexploitables (< 1 m²).                      ----
---- - ST_Intersection : pour ne conserver que les surfaces réellement concernées par l’OLD.                 ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_result2" : Fusion des zones initiales et zones Voronoï par propriétaire.
---- Description : Cette table fusionne les géométries des deux tables sources :
--                 "{insee}_result1" (zones initiales) et "{insee}_ilot_voronoi_rg" (zones Voronoï).
--                 La fusion s’effectue uniquement lorsque des correspondances entre les comptes communaux existent.
--                 Le résultat fournit les zones a débroussailler complètes pour chaque propriétaire.
--
---- Méthode     : - Agrégation conditionnelle des deux sources (zones initiales et zones Voronoï)
--                 - Fusion topologique (ST_UnaryUnion)
--                 - Validation et typage MultiPolygon
--
---- Attributs   : -> comptecommunal : N° du propriétaire
--                 -> geom           : géométrie MultiPolygon (EPSG:2154 - Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result2";                   
 
CREATE TABLE "{schema_travail}"."{insee}_result2" AS                             
WITH union_all AS (                                        -- CTE : agrégation des deux sources
     SELECT r1.comptecommunal,                             -- N° de compte communal
	        ST_SetSRID(                                    -- Définit le système de projection EPSG:2154
               ST_CollectionExtract(                       -- Extrait uniquement les polygones (type 3)
                  ST_MakeValid(r1.geom),                   -- Corrige les géométries invalides
			      3),
            2154) AS geom                                  -- Nomme la colonne résultante
     FROM "{schema_travail}"."{insee}_result1" r1          -- Source : zones initiales a débroussailler
     WHERE geom IS NOT NULL                                -- Filtre les géométries NULL
     AND NOT ST_IsEmpty(geom)                              -- Filtre les géométries vides
    
     UNION ALL                                             -- Agrège les deux tables
    
     SELECT ivrg.comptecommunal,                           -- N° de compte communal
	        ST_SetSRID(                                    -- Définit le système de projection EPSG:2154
               ST_CollectionExtract(                       -- Extrait uniquement les polygones (type 3)
                  ST_MakeValid(ivrg.geom),                 -- Corrige les géométries invalides
			      3),
            2154) AS geom                                  -- Nomme la colonne résultante
      FROM "{schema_travail}"."{insee}_ilot_voronoi_rg" ivrg    -- Source : zones Voronoï attribuées
      WHERE geom IS NOT NULL                               -- Filtre les géométries NULL
      AND NOT ST_IsEmpty(geom)                             -- Filtre les géométries vides
)
SELECT ua.comptecommunal,                                  -- N° du compte communal
       ST_SetSRID(                                         -- Définit le système de projection EPSG:2154
          ST_CollectionExtract(                            -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                 -- Corrige les géométries invalides
                ST_UnaryUnion(                             -- Fusionne toutes les géométries du même compte
				   ST_Collect(geom))),                   
             3),
          2154) AS geom                                    -- Nomme la colonne résultante
FROM union_all ua                                          -- Source : les deux tables fusionnées
GROUP BY ua.comptecommunal;                                -- Regroupe par compte communal

DELETE FROM "{schema_travail}"."{insee}_result2"                            
WHERE geom IS NULL                                                      
OR ST_IsEmpty(geom)                                                 
OR NOT ST_IsValid(geom);                                            

CREATE INDEX idx_{insee}_result2_geom                                  
ON "{schema_travail}"."{insee}_result2"                                    
USING gist (geom);                                                 
 

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_result2_corr1" : Nettoyage topologique par double tampon et alignement.
---- Description :
--                 Cette table est générée a partir de "{insee}_result2".
--                 Les entités sont fusionnées par compte communal, puis nettoyées par un aller-retour
--                 de tampon négatif / positif aligné (via ST_Snap).
--                 L’objectif est de supprimer les épines et irrégularités topologiques tout en
--                 conservant la forme générale des zones a débroussailler.
--
---- Méthode     : - Tampon négatif (épines externes)
--                 - Tampon positif (épines internes)
--                 - Alignement des bords (ST_Snap)
--                 - Validation et conversion en MultiPolygon
--
---- Attributs   : -> comptecommunal : identifiant du propriétaire
--                 -> geom           : géométrie MultiPolygon (EPSG:2154 - Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result2_corr1";
 
CREATE TABLE "{schema_travail}"."{insee}_result2_corr1" AS
WITH 
-- Épuration des épines externes 
--	 aller retour avec 3 noeuds disctincts alignés
--   supprime le noeud de l'extrémité 
epine_externe AS (
	  SELECT r2.comptecommunal,                                        -- N° de compte communal
	         ST_SetSRID(                                               -- Définit le système de coordonnées EPSG:2154
	            ST_Multi(                                              -- Convertit en MultiPolygon
	               ST_CollectionExtract(                               -- Extrait uniquement les géométries de type 3
	                  ST_MakeValid(                                    -- Corrige les géométries invalides
	                     ST_Snap(                                      -- Aligne le tampon de la géométrie sur la géométrie d'origine
	                        ST_RemoveRepeatedPoints(                   -- Supprime les points redondants
	                           ST_Buffer(                              -- Tampon négatif de 10nm
	                              r2.geom, 
	                              -0.0001,                             -- Taille du tampon négatif de l'ordre de 10 nm
	                              'join=mitre mitre_limit=5.0'),       -- Paramètre du tampon
	                           0.0003),			                    -- Distance de suppression des noeuds consécutifs proches de plus de 30 nm
	                        r2.geom,
	                        0.0006)),                                  -- Avec une distance d'accrochage de l'ordre de 60 nm
				   3)),                                                -- Type 3 : Multipolygon
	         2154) AS geom                                             -- Géométries résultantes en 2154
	  FROM "{schema_travail}"."{insee}_result2" r2                     -- Source : Zones a débroussailler final hors éoliennes
),
-- Épuration des épines internes
epine_interne AS (
	  SELECT epext.comptecommunal,                                     -- N° de compte communal
	         ST_SetSRID(                                               -- Définit le système de coordonnées EPSG:2154
	            ST_Multi(                                              -- Convertit en MultiPolygon
	               ST_CollectionExtract(                               -- Extrait uniquement les géométries de type 3
	                  ST_MakeValid(                                    -- Corrige les géométries invalides
	                     ST_Snap(                                      -- Aligne le tampon de la géométrie sur la géométrie d'origine
	                        ST_RemoveRepeatedPoints(                   -- Supprime les points redondants
	                           ST_Buffer(
	                              epext.geom, 
	                              0.0001,                              -- Taille du tampon positif de l'ordre de 10 nm [**param**]
	                              'join=mitre mitre_limit=5.0'),       -- Paramètre du tampon
	                           0.0003),			                    -- Distance de suppression des noeuds consécutifs proches de plus de 30 nm
	                        r2.geom,
	                        0.0006)),
							3)),                                       -- Avec une distance d'accrochage de l'ordre de 60 nm
	         2154) AS geom                                             -- Géométries résultantes en 2154
	  FROM epine_externe epext                                         -- Source : Zones a débroussailler hors et dans la zone urbaine régroupées par compte communal et corrigées sans épines extérieures
	  JOIN "{schema_travail}"."{insee}_result2" r2
	  ON epext.comptecommunal = r2.comptecommunal
)
-- On convertit la géométrie en MultiPolygon valide
SELECT epint.comptecommunal,                                          -- N° de compte communal
       ST_SetSRID(                                                    -- Définit le système de coordonnées EPSG:2154
          ST_Multi(                                                   -- Convertit en MultiPolygon
			 ST_CollectionExtract(                                    -- Extrait uniquement les géométries de type 3
   				ST_MakeValid(epint.geom),                             -- Corrige les géométries invalides                                    
			 3)),
	    2154) AS geom                                                 -- Géométries résultantes
FROM epine_interne epint;                                             -- Source : Zones a débroussailler hors et dans la zone urbaine régroupées par compte communal et corrigées sans épines extérieures ni intérieures

CREATE INDEX idx_{insee}_result2_corr1_geom 
ON "{schema_travail}"."{insee}_result2_corr1" 
USING gist (geom); 


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_result3" : Zones a débroussailler dans la bande des 200 mètres autour des 
---- massifs sensibles.
---- Description : Cette table extrait, pour chaque propriétaire (compte communal), les zones a débroussailler
--                 situées dans la bande des 200 mètres autour des massifs forestiers sensibles (OLD 200m).
--                 Seules les zones supérieures a 0,5 hectare sont conservées.
--                 Le résultat est une intersection entre les zones finales corrigées ("result2_corr1")
--                 et la couche OLD 200m.
--
---- Méthode     : - Intersection spatiale entre "result2_corr1" et "old200m"
--                 - Validation et extraction des MultiPolygons
--                 - Indexation spatiale pour exploitation rapide
--
---- Attributs   : -> comptecommunal : identifiant du propriétaire
--                 -> geom           : géométrie MultiPolygon (EPSG:2154 - Lambert 93)

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result3";                 
  
CREATE TABLE "{schema_travail}"."{insee}_result3" AS                         
SELECT r2c1.comptecommunal,                                 -- N° du compte communal (propriétaire)
       ST_SetSRID(                                          -- Définit le système de projection EPSG:2154
          ST_CollectionExtract(                             -- Extrait uniquement les polygones (type 3)
             ST_MakeValid(                                  -- Corrige les géométries invalides après intersection
                ST_Intersection(                            -- Calcule l'intersection géométrique
                   o.geom,                                  -- Géométrie de la zone OLD 200m
                   r2c1.geom)),                             -- Géométrie des zones corrigées a débroussailler               
             3), 
       2154) AS geom                                        -- Nomme la colonne résultante
FROM "{schema_travail}"."{insee}_result2_corr1" r2c1        -- Source : zones finales corrigées
JOIN {SCHEMA_PUBLIC}.{TABLE_OLD200M} o                      -- Source : périmètre OLD 200m
ON ST_Intersects(r2c1.geom, o.geom);                        -- Filtre : ne traite que les intersections réelles

DELETE FROM "{schema_travail}"."{insee}_result3"                            
WHERE geom IS NULL                                                     
OR ST_IsEmpty(geom)                                               
OR NOT ST_IsValid(geom);                                          

CREATE INDEX idx_{insee}_result3_geom                                   
ON "{schema_travail}"."{insee}_result3"                                   
USING gist (geom);                                                    
 

--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                                                                                         ----
----                                             PARTIE XV                                                   ----
----                  INTÉGRATION DES PARCS ÉOLIENS DANS LES ZONES a DÉBROUSSAILLER                          ----
----                                                                                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
---- OBJECTIFS :                                                                                             ----
---- - Identifier les zones a débroussailler autour des éoliennes dans le périmètre OLD de 200 m.            ----
---- - Associer ces zones aux unités foncières et comptes communaux concernés.                               ----
---- - Supprimer les bâtiments situés dans les zones des parcs éoliens, pour éviter les doublons.            ----
---- - Fusionner l'ensemble des surfaces concernées, en rattachant chaque zone au bon gestionnaire.          ----
--*-----------------------------------------------------------------------------------------------------------*--
---- MÉTHODOLOGIE GLOBALE :                                                                                  ----
---- - Sélection des éoliennes situées dans la commune ciblée et intersectant le périmètre OLD.              ----
---- - Association de ces géométries aux unités foncières pour récupérer les comptes communaux.              ----
---- - Création d'un tampon de 10 m (emprise du pylône) suivi d'un tampon de 50 m (zone a débroussailler).   ----
---- - Suppression des bâtiments inclus dans ces zones pour éviter leur double prise en compte.              ----
---- - Fusion des zones OLD précédentes avec celles des éoliennes, avec rattachement du nom de parc.         ----
---- - Attribution des transformateurs aux parcs proches si situés a moins de 250 m, puis regroupement final.----
--*-----------------------------------------------------------------------------------------------------------*--
---- RÉSULTATS ATTENDUS :                                                                                    ----
---- - Une couche consolidée des zones a débroussailler, incluant les emprises éoliennes et transformateurs. ----
---- - Une géométrie par entité (compte communal ou parc), sans doublon et sans artefact.                    ----
---- - Une attribution cohérente des responsabilités de débroussaillement par gestionnaire.                  ----
--*-----------------------------------------------------------------------------------------------------------*--
---- CHOIX TECHNIQUES JUSTIFIÉS :                                                                            ----
---- - ST_Intersection : pour croiser précisément les géométries des éoliennes avec la commune et l'OLD.     ----
---- - ST_Buffer : pour définir les emprises de sécurité autour des infrastructures.                         ----
---- - ST_Union + ST_Multi + ST_CollectionExtract : pour fusionner et homogénéiser les géométries.           ----
---- - ST_DWithin : pour identifier les bâtiments ou zones proches a rattacher sans contact direct.          ----
---- - COALESCE : pour prioriser le nom de parc dans les cas d'attribution multiple.                         ----
---- - ST_Equals : pour effectuer une jointure exacte sur la géométrie lors de l'attribution des parcs.      ----
---- - ST_MakeValid : pour corriger les géométries invalides a chaque étape du processus.                    ----
--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_zold_eolien" : Zones a débroussailler autour des éoliennes.
---- Description :
--                 Cette table génère des zones a débroussailler autour des éoliennes d’un parc.
--                 Le processus consiste a :
--                     - Créer un tampon de 3 m autour de chaque éolienne (emprise du pylône),
--                     - Étendre ce tampon de 50 m supplémentaires pour obtenir la zone de débroussaillement totale (60 m),
--                     - Associer les géométries obtenues aux unités foncières cadastrales concernées.
--                 Les géométries finales sont fusionnées par compte communal et par parc.
--
---- Méthode     : - Intersection avec la commune {insee}
--                 - Filtrage dans la zone OLD200m
--                 - Association aux unités foncières cadastrales
--                 - Création des tampons (3 m, puis 60 m)
--                 - Fusion finale par parc et compte communal
--
---- Attributs   : -> nom_parc        : nom du parc éolien
--                 -> comptecommunal  : identifiant du compte communal
--                 -> geom            : géométrie MultiPolygon (EPSG:2154 - Lambert 93)


DROP TABLE IF EXISTS "{schema_travail}"."{insee}_zold_eolien";
 
CREATE TABLE "{schema_travail}"."{insee}_zold_eolien" AS
-- Création d'un tampon de 3 mètres (zone du pylône)
WITH tampon_3m AS (
     SELECT eol.nom_parc,                                      -- Nom du parc éolien
            ST_CollectionExtract(                              -- Extrait uniquement les polygones (type 3) de la collection
               ST_MakeValid(                                   -- Correction des géométries invalides
                  ST_Buffer(eol.geom, 3)),                     -- Crée un tampon de 3 mètres autour de la géométrie
            3) AS geom                                         -- Géométrie résultante
     FROM {SCHEMA_PUBLIC}.{TABLE_EOLIEN} eol                   -- Source : zones associées aux comptes communaux
), 
-- Intersection entre les éoliennes et la commune {insee}
intersection_communes AS (
     SELECT t3m.nom_parc,                                      -- Récupère le nom du parc éolien
            ST_CollectionExtract(                              -- Extrait uniquement les polygones (type 3) de la collection
               ST_MakeValid(                                   -- Répare les géométries invalides (auto-intersections, etc.)
                  ST_Intersection(t3m.geom, c.geom)),          -- Calcule l'intersection géométrique entre éolienne et commune
            3) AS geom                                         -- Géométrie résultante                                
     FROM tampon_3m t3m                                        -- Source : tampon de 10m autour des éoliennes filtrées depuis le RETN
     INNER JOIN {SCHEMA_CADASTRE}.{TABLE_COMMUNE} c            -- Jointure interne avec la table des communes cadastrales
     ON ST_Intersects(t3m.geom, c.geom)                        -- Condition de jointure : intersection spatiale entre les 2 géométries
     WHERE  (c.geo_commune = '{code_commune}'                  -- Filtre : Egalité des codes communes 
        OR (c.geo_commune 
	        -- Filtre : ou égalité entre les 6 premiers chiffres des geo_parcelle et le code commune des communes limitrophes
	        IN (SELECT geo_commune                                                    
                FROM "{schema_travail}"."{insee}_commune_adjacente")) -- Source : Communes adjacentes intégrées
			AND ST_Intersects(                                        -- Filtre : Intersection entre les parcelles et la commune cible et son tampon de 100m
			       (SELECT geom 
			        FROM "{schema_travail}"."{insee}_commune_buffer"),-- Source : Commune cible et son tampon de 100m, 
				   t3m.geom))
),
-- Intersection avec la zone OLD200m (Obligation Légale de Débroussaillement)
intersection_old200m AS (
     SELECT ic.nom_parc,                                        -- Conserve le nom du parc éolien
		    ST_CollectionExtract(                               -- Extrait uniquement les polygones de la collection
			   ST_MakeValid(                                    -- Correction des géométries invalides
				  ST_Intersection(ic.geom, old200.geom)),       -- Intersection entre éolienne (déja filtrée par commune) et zone OLD
            3) AS geom                                          -- Géométrie résultante
     FROM intersection_communes ic                              -- Source : résultat de la première CTE
     JOIN {SCHEMA_PUBLIC}.{TABLE_OLD200M} old200                -- Jointure avec les zones OLD (Obligation Légale de Débroussaillement)
     ON ST_Intersects(ic.geom, old200.geom)                     -- Condition : intersection spatiale
),
-- Association aux unités foncières cadastrales
intersection_cc AS (
     SELECT iold.nom_parc,                                     -- Nom du parc éolien
            uf.comptecommunal,                                 -- Identifiant du compte communal (propriétaire cadastral)
            CASE
                -- Si une unité foncière intersecte la zone éolienne
                WHEN uf.geom IS NOT NULL THEN
                     ST_SetSRID(                               -- Définit le SRID en Lambert 93
                        ST_CollectionExtract(                  -- Extrait les polygones de la collection
                           ST_MakeValid(                       -- Correction des géométries invalides
                              ST_Intersection(                 -- Intersection entre zone OLD et unité foncière
                                 ST_MakeValid(iold.geom),      -- Rend valide la géométrie de la zone OLD
                                 ST_MakeValid(uf.geom))),      -- Rend valide la géométrie de l'unité foncière
                           3),                                 -- Extrait les polygones uniquement
                     2154)                                     -- SRID Lambert 93
                
                -- Si aucune unité foncière n'intersecte (cas rare)
                ELSE ST_SetSRID(iold.geom, 2154)               -- Conserve la géométrie OLD telle quelle avec SRID
            END AS geom                                        -- Géométrie résultante
     FROM intersection_old200m iold                            -- Source : zones OLD intersectées
     LEFT JOIN {SCHEMA_CADASTRE}.{TABLE_UF} uf                 -- Jointure externe avec unités foncières (conserve les lignes sans UF)
     ON ST_Intersects(iold.geom, uf.geom)                      -- Condition : intersection spatiale
),
-- Zone a débroussailler (tampon supplémentaire de 50m = total 60m)
tampon_60m AS (
     SELECT icc.nom_parc,                                      -- Nom du parc éolien
            icc.comptecommunal,                                -- Compte communal
            ST_CollectionExtract(                              -- Extrait uniquement les polygones (type 3)
               ST_MakeValid(                                   -- Correction des géométries invalides
                  ST_Buffer(icc.geom, 50)),                    -- Ajoute 50m autour du tampon de 10m (total : 60m depuis l'éolienne)
               3) AS geom                                      -- Géométrie de la zone a débroussailler
     FROM intersection_cc icc                                  -- Source : tampons de 10m créés précédemment
)
-- Requête finale : Fusion des tampons par compte communal et parc
SELECT t60.nom_parc,                                           -- Nom du parc éolien
       t60.comptecommunal,                                     -- Compte communal
       ST_SetSRID(                                             -- Définit le SRID en Lambert 93
          ST_CollectionExtract(                                -- Extraction des polygones uniquement
             ST_MakeValid(                                     -- Correction finale des géométries
                ST_Union(t60.geom)),                           -- Fusionne toutes les géométries d'un même compte/parc en une seule entité
             3),                                               -- Géométrie fusionnée finale en MultiPolygon
	   2154) AS geom
FROM tampon_60m t60                                            -- Source : zones de débroussaillement de 60m
GROUP BY t60.nom_parc, t60.comptecommunal;                     -- Regroupement par parc et compte communal

CREATE INDEX idx_{insee}_zold_eolien_geom                     
ON "{schema_travail}"."{insee}_zold_eolien"                      
USING gist (geom);                    
                                                                    

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_result4" : Fusion de la zone OLD finale avec la zone a débroussailler des 
---- parcs éoliens.
---- Description : Cette table consolide les zones finales de débroussaillage issues de `result3`
--                 en supprimant celles recouvertes par des bâtiments situés dans les zones éoliennes,
--                 puis en ajoutant les tampons de débroussaillage autour des parcs éoliens (`zold_eolien`).
--                 Les transformateurs proches des zones éoliennes (moins de 250 m) héritent automatiquement
--                 du nom du parc éolien, conformément a la réglementation (bande de 500 m autour des éoliennes).
--
---- Méthode     : - Identifier les bâtiments présents dans les zones éoliennes.
--                 - Décomposer les zones finales a débroussailler (`result3`) en polygones simples.
--                 - Supprimer les bâtiments situés a moins de 30 m des zones éoliennes.
--                 - Fusionner les zones OLD nettoyées avec les zones de débroussaillage autour des éoliennes.
--                 -  Identifier les transformateurs proches (moins de 250 m) d’une zone éolienne.
--                 - Attribuer le nom du parc aux géométries concernées.
--                 - Fusionner l’ensemble par compte communal ou nom de parc.
--
---- Attributs  : -> comptecommunal : identifiant cadastral ou nom du parc éolien
--                -> geom           : géométrie MultiPolygon en EPSG:2154 (Lambert 93)
 
DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result4";
 
CREATE TABLE "{schema_travail}"."{insee}_result4" AS
-- Identification des bâtiments a exclure
WITH bati_a_exclure AS (
     SELECT ST_MakeValid(b200cc.geom) AS geom                             -- Corrige les géométries invalides des bâtiments a supprimer
     FROM "{schema_travail}"."{insee}_bati200_cc" b200cc                  -- Source : bâtiments dans la zone OLD 200m avec compte communal
     JOIN "{schema_travail}"."{insee}_zold_eolien" zeol                   -- Jointure avec les zones a débroussailler autour des parcs éoliens
     ON ST_Intersects(b200cc.geom, zeol.geom)                             -- Condition : le bâtiment intersecte la zone éolienne
),
-- Décomposition du résultat 3 en polygones simples
result3_polygones AS (
     SELECT r3.comptecommunal,                                            -- Récupère le numéro du compte communal
            (ST_Dump(r3.geom)).geom AS geom                               -- Décomposition des MultiPolygon en polygones simples individuels
     FROM "{schema_travail}"."{insee}_result3" r3                         -- Source : zone finale a débroussailler par propriétaire (sans zones éoliennes)
),
-- Suppression des bâtiments correspondants aux éoliennes
result3_nettoye AS (
     SELECT r3p.*                                                         -- Sélectionne toutes les colonnes de result3_polygones
     FROM result3_polygones r3p                                           -- Source : résultat 3 décomposé en polygones
     LEFT JOIN bati_a_exclure b                                           -- Jointure externe avec les bâtiments a exclure
     ON ST_DWithin(r3p.geom, b.geom, 30)                                  -- Condition : si le polygone est a moins de 30m d'un bâtiment a exclure
     WHERE b.geom IS NULL                                                 -- Filtre : conserve uniquement les polygones qui NE sont PAS proches d'un bâtiment a exclure
),
-- Union entre la zone finale a débroussailler et les zones éoliennes
fusion_zold_result3 AS (
     -- Partie 1 : Zones OLD nettoyées (sans bâtiments éoliens)
     SELECT r3n.comptecommunal AS comptecommunal,                         -- Compte communal d'origine
            ST_CollectionExtract(                                         -- Extrait uniquement les polygones (type 3)
               ST_MakeValid(r3n.geom),                                    -- Corrige les géométries invalides
               3) AS geom                                                 -- Résultat en MultiPolygon
     FROM result3_nettoye r3n                                             -- Source : zone finale 3 a débroussailler sans les bâtiments éoliens

     UNION ALL                                                            -- Agrège les tables ensemble (conserve tous les enregistrements)

     -- Partie 2 : Zones a débroussailler autour des éoliennes
     SELECT CONCAT('{code_commune}_', zeol.nom_parc) AS comptecommunal,           -- Utilise le n°insee + nom du parc éolien comme identifiant
            ST_CollectionExtract(                                         -- Extrait uniquement les polygones (type 3)
               ST_MakeValid(zeol.geom),                                   -- Corrige les géométries invalides
               3) AS geom                                                 -- Résultat en MultiPolygon
     FROM "{schema_travail}"."{insee}_zold_eolien" zeol                        -- Source : zone a débroussailler autour des éoliennes
),
-- Association des transformateurs aux zones a débroussailler par les gestionnaires des parcs éoliens
association_bati AS (
     SELECT DISTINCT ON (r3p.geom)                                        -- Une seule ligne par géométrie unique (élimine les doublons)
            zeol.nom_parc AS comptecommunal,                              -- Attribution du nom de parc comme compte communal
            ST_MakeValid(r3p.geom) AS geom                                -- Corrige les géométries invalides des transformateurs
     FROM result3_polygones r3p                                           -- Source : résultat final 3 décomposé en polygones
     JOIN "{schema_travail}"."{insee}_zold_eolien" zeol                        -- Jointure avec les zones a débroussailler autour des éoliennes
     ON ST_DWithin(r3p.geom, zeol.geom, 250)                              -- Condition : si la géométrie est a moins de 250m d'une zone éolienne
),
-- Attribution du nom du parc aux transformateurs proches
fusion_finale AS (
     SELECT COALESCE(assob.comptecommunal, fzr3.comptecommunal) AS comptecommunal, -- Priorité au nom de parc si présent, sinon compte communal
            ST_MakeValid(fzr3.geom) AS geom                               -- Corrige les géométries invalides
     FROM fusion_zold_result3 fzr3                                        -- Source : zone a débroussailler totale par propriétaire dans le cadre des OLD
     LEFT JOIN association_bati assob                                     -- Jointure externe avec les transformateurs proches des éoliennes
     ON ST_Equals(fzr3.geom, assob.geom)                                  -- Condition : jointure exacte sur la géométrie (identité stricte)
)
-- Requête finale : Fusion par compte communal ou nom de parc
SELECT comptecommunal,                                                    -- N° de compte communal ou nom de parc éolien
       ST_CollectionExtract(                                              -- Extrait uniquement les polygones (type 3)
          ST_MakeValid(                                                   -- Corrige les géométries invalides après fusion
             ST_Union(geom)),                                             -- Fusionne toutes les géométries d'un même compte/parc
          3) AS geom                                                      -- Géométrie fusionnée finale en MultiPolygon
FROM fusion_finale                                                        -- Source : résultat de la CTE "fusion_finale"
GROUP BY comptecommunal;                                                  -- Regroupement par compte communal ou nom de parc

ALTER TABLE "{schema_travail}"."{insee}_result4"
ALTER COLUMN geom 
TYPE geometry(MULTIPOLYGON, 2154)
USING ST_SetSRID(geom, 2154);

CREATE INDEX idx_{insee}_result4_geom                                       
ON "{schema_travail}"."{insee}_result4"                                        
USING gist (geom);                       

--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_result5" : Suppression des micro-anneaux de moins de 1 m².
---- Description : Cette table décompose les géométries MultiPolygon issues de `result4`
--                 en polygones simples, puis en anneaux (extérieurs et intérieurs).
--                 Les anneaux dont la surface est inférieure a 1 m² sont supprimés.
--                 Les polygones sont ensuite reconstruits et réassemblés en MultiPolygon
--                 pour chaque compte communal ou parc éolien.
--
---- Méthode     : - Décomposition des MultiPolygons en polygones simples.
--                 - Extraction et mesure des anneaux (ST_DumpRings).
--                 - Filtrage des anneaux inférieurs a 1 m².
--                 - Reconstruction des polygones a partir des anneaux conservés.
--                 - Fusion et conversion finale en MultiPolygon.
--
---- Attributs   : -> comptecommunal : identifiant du propriétaire ou du parc éolien.
--                 -> geom           : géométrie MultiPolygon en EPSG:2154 (Lambert 93).

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result5";  

CREATE TABLE "{schema_travail}"."{insee}_result5" AS
-- Décomposition des MultiPolygons en polygones simples
WITH poly_simples AS (
	 SELECT r4.comptecommunal,                                                       -- Compte communal ou parc éolien
		    (ST_Dump(r4.geom)).path AS path1,                                        -- Identifiant du polygone dans le multipolygone
		    (ST_Dump(r4.geom)).geom AS geom                                          -- Géométrie du polygone simple
	 FROM "{schema_travail}"."{insee}_result4" r4                                    -- Source : zones finales fusionnées
),
-- Extraction des anneaux (extérieurs et intérieurs)
rings_poly_simples AS (
	 SELECT ps.comptecommunal,                                                       -- Compte communal
		    ps.path1,                                                                -- Identifiant du polygone d’origine
		    ((ST_DumpRings(ps.geom)).path)[1] AS ring_index,                         -- Index de l’anneau (0 = extérieur, >0 = intérieur)
		    ST_Area((ST_DumpRings(ps.geom)).geom) AS surface,                        -- Surface de chaque anneau
		    (ST_DumpRings(ps.geom)).geom AS geom                                     -- Géométrie de l’anneau
	 FROM poly_simples ps
),
-- Filtrage des anneaux de moins de 1 m²
macro_anneaux AS (
	 SELECT rps.comptecommunal,                                                      -- Compte communal
		    rps.path1,                                                               -- Identifiant du polygone
		    rps.ring_index,                                                          -- Index de l’anneau
		    rps.surface,                                                             -- Surface en m²
		    ST_ExteriorRing(rps.geom) AS geom                                        -- Conversion des anneaux en lignes
	 FROM rings_poly_simples rps
	 WHERE rps.surface > 1                                                           -- Seuls les anneaux de plus de 1 m² sont conservés
),
-- Reconstruction des polygones a partir des anneaux conservés
reconstruction_pg AS (
	 SELECT ma.comptecommunal,                                                       -- Identifiant du compte communal ou du parc
		    ma.path1,                                                                -- Identifiant du polygone d’origine issu du dump
            CASE 
			    -- Cas 1 : présence d’au moins un anneau intérieur
			    WHEN COUNT(*) FILTER (WHERE ma.ring_index > 0) > 0 
			    THEN ST_SetSRID(                                                     -- Définit le SRID EPSG:2154
					    ST_CollectionExtract(                                        -- Extrait uniquement les polygones (type 3)
						   ST_MakeValid(                                             -- Corrige d’éventuelles incohérences topologiques
							  ST_MakePolygon(                                        -- Reconstitue le polygone complet
								 MAX(ma.geom) 
								 FILTER (WHERE ma.ring_index = 0),                   -- Anneau extérieur unique
								 ARRAY_AGG(ma.geom) 
								 FILTER (WHERE ma.ring_index > 0))),                 -- Liste des anneaux intérieurs					
					       3),
				     2154)

			    -- Cas 2 : absence d’anneaux intérieurs
			    ELSE ST_SetSRID(                                                     -- Définit le SRID EPSG:2154
					    ST_CollectionExtract(                                        -- Extrait uniquement les polygones (type 3)
						   ST_MakeValid(                                             -- Corrige les artefacts géométriques
							  ST_MakePolygon(                                        -- Reconstitue uniquement a partir de l’anneau extérieur
								 MAX(ma.geom) 
								 FILTER (WHERE ma.ring_index = 0))),
						   3),
				     2154)
					 
		    END AS geom                                                              -- Géométrie du polygone reconstruit (MultiPolygon compatible)

	 FROM macro_anneaux ma                                                           -- Source : anneaux filtrés (>1 m²)
	 GROUP BY ma.comptecommunal, ma.path1                                            -- Regroupement par entité et identifiant de polygone
),
-- Reconstruction des MultiPolygons
resultat_final AS (
	 SELECT rp.comptecommunal,                                                       -- N° de compte communal
		    ST_SetSRID(                                                              -- Définit le système de projection EPSG:2154
			   ST_Multi(                                                             -- Conversion en MultiPolygon
				  ST_CollectionExtract(                                              -- Extrait uniquement les polygones (type 3)
					 ST_MakeValid(                                                   -- Corrige les géométries invalides
					    ST_Union(rp.geom)),                                          -- Fusion des polygones du même compte
					 3)),
		    2154) AS geom                                                            -- Géométrie finale MultiPolygon
	 FROM reconstruction_pg rp                                                       -- Source : résultat de la requête précédente
	 GROUP BY rp.comptecommunal                                                      -- Regroupe par compte communal
)
-- Étape finale : Création de la table résultante
SELECT *                                                                             -- Toutes les données
FROM resultat_final;                                                                 -- Source : résultat de la requête précédente

CREATE INDEX idx_{insee}_result5_geom
ON "{schema_travail}"."{insee}_result5"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--

---- Création de la table "{insee}_result_final" : Suppression des géométries des communes limitrophes

-- Description : Déconstruction des multipolygones en polygones puis en anneaux
--               filtrage des anneaux de moins de 1 m²
--               reconstruction des polygones et multipolygones
--               -> Attributs : comptecommunal (N° du compte communal ou nom du parc éolien),
--                              geom (géométrie, MultiPolygon, 2154).
--  Cette table est enregistrée dans le schéma "{SCHEMA_RESULTAT}"

DROP TABLE IF EXISTS "{SCHEMA_RESULTAT}"."{insee}_result_final";


CREATE TABLE "{SCHEMA_RESULTAT}"."{insee}_result_final" AS 
SELECT r5.comptecommunal,                                                               -- Identifiant du gestionnaire (compte communal OU parc éolien)
       r5.geom                                                                          -- Géométrie MultiPolygon OLD finale (nettoyée Phases 1-2-3)
FROM "{schema_travail}"."{insee}_result5" r5                                            -- Source : zones OLD nettoyées Phase 3 (micro-trous éliminés)
WHERE LEFT(r5.comptecommunal, 6) = '{code_commune}';                                    -- FILTRE COMMUNAL CRITIQUE : conserve UNIQUEMENT la commune cible
                                                                                        -- LEFT(champ, 6) extrait les 6 premiers caractères
ALTER TABLE "{SCHEMA_RESULTAT}"."{insee}_result_final"
ALTER COLUMN geom 
TYPE geometry(MULTIPOLYGON, 2154)
USING ST_SetSRID(geom, 2154);

CREATE INDEX idx_{insee}_result_final_geom
ON "{SCHEMA_RESULTAT}"."{insee}_result_final"
USING gist (geom);


--*-----------------------------------------------------------------------------------------------------------*--
--*-----------------------------------------------------------------------------------------------------------*--
----                                 NETTOYAGE DU SCHÉMA DE TRAVAIL                                          ----
----                          (décommenter si suppression souhaitée)                                         ----
--*-----------------------------------------------------------------------------------------------------------*--
-- Description : Suppression complète du schéma de travail et de TOUTES ses tables (CASCADE).                ----
--               ATTENTION : Opération IRRÉVERSIBLE. a n''exécuter QUE si :                                  ----
--               • La table finale __CODE_INSEE___result_final a été vérifiée et validée                     ----
--               • Les exports nécessaires ont été réalisés                                                  ----
--               • Aucun besoin de traçabilité/debug des tables intermédiaires                               ----
--               Libère l''espace disque occupé par les tables temporaires de calcul.                        ----
--*-----------------------------------------------------------------------------------------------------------*--

 DROP SCHEMA "{schema_travail}" CASCADE;
 

"""
# =============================================================================
# EXECUTION PRINCIPALE
# =============================================================================

if __name__ == "__main__":
    start_total = time.perf_counter()   # début du traitement total

    logging.info(f"===== Lancement module OLD50m - Département {DEPT} =====")
    communes = get_communes()
   
    for _, row in communes.iterrows():
        start_iter = time.perf_counter()   # début de l’itération

        idu = str(row['idu']).zfill(3)
        insee = f"{DEPT}{idu}"
        code_commune = f"{DEPT}0{idu}"
        execute_module(insee, idu, row['tex2'], MODULE_SQL)

        elapsed_iter = time.perf_counter() - start_iter
        logging.info(f"Temps écoulé pour la commune {insee} : {fmt(elapsed_iter)}")

    total_elapsed = time.perf_counter() - start_total  # durée totale
    logging.info(f"===== Fin de traitement départemental — durée totale : {fmt(total_elapsed)} =====")