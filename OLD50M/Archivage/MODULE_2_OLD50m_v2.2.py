# -*- coding: utf-8 -*-
"""
MODULE_2_OLD50m_v2.2.py — Exécution automatisée du module OLD50m pour le département de la Drôme
Auteur : MJMartinat
Objectif : Générer les zones d’obligation légale de débroussaillement (OLD) a 50m a l'échelle départementale
"""

import os, logging, pandas as pd, time
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

LOG_FILE = r"C:\Users\USER\Documents\WOLD50M\log\log_outil_old50m.log"
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
         -- ou bien test du scrip python sur une seule commune
         -- c.commune = '260275'
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



DROP SCHEMA IF EXISTS "{schema_travail}" CASCADE;            
CREATE SCHEMA "{schema_travail}";                            



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_commune_buffer" CASCADE;

CREATE TABLE "{schema_travail}"."{insee}_commune_buffer" AS			
SELECT c.geo_commune,                                 			
       ST_Buffer(c.geom, 100)::GEOMETRY(MULTIPOLYGON, 2154) AS geom                
FROM {SCHEMA_CADASTRE}.geo_commune AS c                                
WHERE c.geo_commune = '{code_commune}';                                 

CREATE INDEX idx_{insee}_commune_buffer 
ON "{schema_travail}"."{insee}_commune_buffer" 
USING GIST (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_commune_adjacente" CASCADE;   				

CREATE TABLE "{schema_travail}"."{insee}_commune_adjacente" AS 
SELECT DISTINCT 
       c.geo_commune,                                     								
       c.geom                                             								
FROM   {SCHEMA_CADASTRE}.geo_commune AS c                          							
WHERE  ST_Intersects(                                      								
          c.geom, 
          (SELECT geom 
           FROM "{schema_travail}"."{insee}_commune_buffer"))   								
AND c.geo_commune != '{code_commune}';                            								

CREATE INDEX idx_{insee}_commune_adjacente 
ON "{schema_travail}"."{insee}_commune_adjacente" 
USING GIST (geom);                                     								  



DROP TABLE IF EXISTS "{SCHEMA_PARCELLE}"."{insee}_parcelle";   						

CREATE TABLE "{SCHEMA_PARCELLE}"."{insee}_parcelle" AS
SELECT pi.idu,                                  										
       pi.geo_parcelle,                                     							
       pi.comptecommunal,                                   							
       pi.codecommune,                                     							    
       ST_SetSRID(                                          							
          ST_CollectionExtract(                             							
             ST_MakeValid(pi.geom),                         							
             3),                                            							
       2154) AS geom                                        							
FROM   {SCHEMA_CADASTRE}.{TABLE_PARCELLE} AS pi                       							
WHERE (
       LEFT(pi.geo_parcelle, 6) = '{code_commune}'                  							
       OR LEFT(pi.geo_parcelle, 6) 
	      IN (SELECT {TABLE_COMMUNE} 
              FROM "{schema_travail}"."{insee}_commune_adjacente")) 						    
AND    ST_Intersects(                                        							
          (SELECT geom 
           FROM "{schema_travail}"."{insee}_commune_buffer"), 
          pi.geom);                                         							
		  
		
ALTER TABLE "{SCHEMA_PARCELLE}"."{insee}_parcelle"
ALTER COLUMN geom 
TYPE geometry(MULTIPOLYGON, 2154)
USING ST_SetSRID(geom, 2154);

CREATE INDEX idx_{insee}_parcelle_geom 
ON "{SCHEMA_PARCELLE}"."{insee}_parcelle"
USING GIST (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ufr";   								

CREATE TABLE "{schema_travail}"."{insee}_ufr" AS
WITH cte AS (
	 SELECT uf.comptecommunal,                            							
	        ST_SetSRID(                                   							
	           ST_CollectionExtract(                      							
	              ST_MakeValid(                           							
	                 ST_Union(uf.geom)),                  							
	              3),                                     							
	        2154) AS geom                                 							
	 FROM   {SCHEMA_CADASTRE}.{TABLE_UF} AS uf            							
	 WHERE  (LEFT(uf.comptecommunal, 6) = '{code_commune}'         							
	        OR LEFT(uf.comptecommunal, 6) 
	           IN (SELECT {TABLE_COMMUNE} 
	                 FROM "{schema_travail}"."{insee}_commune_adjacente")) 				
	 GROUP BY uf.comptecommunal                           							
)
SELECT cte.comptecommunal,                                							
	   cte.geom                                           							
FROM   cte
JOIN   "{schema_travail}"."{insee}_commune_buffer" AS combuf    							
ON     ST_Intersects(combuf.geom, cte.geom);               							

CREATE INDEX idx_{insee}_ufr_geom
ON "{schema_travail}"."{insee}_ufr"
USING GIST (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_non_cadastre";   					

CREATE TABLE "{schema_travail}"."{insee}_non_cadastre" AS
SELECT ST_SetSRID(                                            				
          ST_CollectionExtract(                               				
             ST_MakeValid(                                    				
                ST_Difference(                                				
                   c.geom,                                    				
                   ST_Union(p.geom))),                        				
             3),                                              				
       2154) AS geom                                          				
FROM   "{SCHEMA_PARCELLE}"."{insee}_parcelle"        AS p,           				
       "{schema_travail}"."{insee}_commune_buffer"  AS c             			
WHERE  c.geo_commune = '{code_commune}'                               				
GROUP BY c.geom;                                              				
                                 
CREATE INDEX idx_{insee}_non_cadastre_geom 
ON "{schema_travail}"."{insee}_non_cadastre"
USING gist (geom);                                           



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati_cimetiere";   						

CREATE TABLE "{schema_travail}"."{insee}_bati_cimetiere" AS
SELECT NULL::integer AS fid,                                      					
       '{TABLE_CIMETIERE}' AS nature,                                     					
       c.geo_commune,                                             					
       ST_SetSRID(                                                					
          ST_CollectionExtract(                                   					
             ST_MakeValid(                                        					
                ST_Force2D(r.geometrie)),                         					
             3),                                                  					
       2154) AS geom                                              					
FROM   {SCHEMA_BDTOPO}.{TABLE_CIMETIERE}        AS r                              					
INNER JOIN {SCHEMA_CADASTRE}.geo_commune AS c                             					
ON ST_Intersects(r.geometrie, c.geom)                      				        	
WHERE  (c.geo_commune = '{code_commune}'                                   					
        OR (c.geo_commune 
	       IN (SELECT {TABLE_COMMUNE} 
               FROM "{schema_travail}"."{insee}_commune_adjacente") 
           AND ST_Intersects(
		          (SELECT geom 
                   FROM "{schema_travail}"."{insee}_commune_buffer"), 
                  r.geometrie)));                      					            

CREATE INDEX idx_{insee}_bati_cimetiere_geom 
ON "{schema_travail}"."{insee}_bati_cimetiere" 
USING GIST (geom);                                            				



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati_installation";

CREATE TABLE "{schema_travail}"."{insee}_bati_installation" AS
SELECT ROW_NUMBER() OVER (ORDER BY z.geometrie)::integer AS fid,                                                  
       CASE                                                                   
           WHEN z.nature = 'Camping' 
           THEN 'Camping'                                                     
           
           WHEN z.nature_detaillee = 'Centrale photovoltaïque' 
           THEN 'Centrale photovoltaïque'                                     
           
           WHEN z.nature = 'Carrière' 
           THEN 'Carrière'                                                    
           
           WHEN z.nature_detaillee = 'Centre d''enfouissement technique' 
           THEN 'Centre d''enfouissement technique'                           
       END AS nature,
       c.geo_commune,                                                         
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Force2D(z.geometrie)),                                     
             3),                                                              
       2154) AS geom                                                          
FROM {SCHEMA_BDTOPO}.{TABLE_INSTALLATION} z                                  
INNER JOIN {SCHEMA_CADASTRE}.geo_commune c                                           
ON ST_Intersects(z.geometrie, c.geom)                                         
WHERE (c.geo_commune = '{code_commune}'                                               
       OR c.geo_commune 
	      IN (SELECT {TABLE_COMMUNE} 
		      FROM "{schema_travail}"."{insee}_commune_adjacente"))                
AND (z.nature = 'Camping'                                                     
OR z.nature_detaillee = 'Centrale photovoltaïque'                             
OR z.nature = 'Carrière'                                                      
OR z.nature_detaillee = 'Centre d''enfouissement technique')                  
AND ST_Intersects(
       (SELECT geom 
	    FROM "{schema_travail}"."{insee}_commune_buffer"), 
	   z.geometrie);

CREATE INDEX idx_{insee}_bati_installation_geom
ON "{schema_travail}"."{insee}_bati_installation"
USING gist (geom);



DROP TABLE IF EXISTS "{SCHEMA_BATI}"."{insee}_bati_habitat";                

CREATE TABLE "{SCHEMA_BATI}"."{insee}_bati_habitat" AS
SELECT b.fid,                                                                   
       'Habitat' AS nature,                                                     
       c.geo_commune,                                                           
       ST_SetSRID(                                                              
          ST_CollectionExtract(                                                 
             ST_MakeValid(                                                      
                ST_Force2D(b.geometrie)),                                       
             3),                                                                
       2154) AS geom                                                            
FROM   {SCHEMA_BDTOPO}.{TABLE_BATI} b                                                      
INNER JOIN {SCHEMA_CADASTRE}.geo_commune c                                             
ON ST_Intersects(ST_Force2D(b.geometrie), c.geom)                               
LEFT JOIN "{schema_travail}"."{insee}_bati_cimetiere" cim                            
ON ST_Intersects(ST_Force2D(b.geometrie), cim.geom)                             
LEFT JOIN "{schema_travail}"."{insee}_bati_installation" inst                        
ON ST_Intersects(ST_Force2D(b.geometrie), inst.geom)                            
WHERE  (c.geo_commune = '{code_commune}'                                                
        OR c.geo_commune 
           IN (SELECT {TABLE_COMMUNE} 
               FROM "{schema_travail}"."{insee}_commune_adjacente"))                 
       AND ST_Intersects(                                                       
           (SELECT geom 
              FROM "{schema_travail}"."{insee}_commune_buffer"), 
           ST_Force2D(b.geometrie))
AND    ST_Area(b.geometrie) >= 6                                                
AND    cim.geom IS NULL                                                         
AND    inst.geom IS NULL;                                                       

CREATE INDEX idx_{insee}_bati_habitat_geom                                       
ON "{SCHEMA_BATI}"."{insee}_bati_habitat"                                        
USING GIST (geom);                                                              
                                                                 


DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati";    

CREATE TABLE "{schema_travail}"."{insee}_bati" AS                                   
SELECT *                                                             
FROM   "{SCHEMA_BATI}"."{insee}_bati_habitat"                          
UNION ALL
SELECT *                                                             
FROM   "{schema_travail}"."{insee}_bati_cimetiere"                        
UNION ALL
SELECT *                                                             
FROM   "{schema_travail}"."{insee}_bati_installation";                    

ALTER TABLE "{schema_travail}"."{insee}_bati"                                       
ALTER COLUMN geom 
TYPE geometry(MULTIPOLYGON, 2154)                            
USING ST_SetSRID(geom, 2154);                                                                                                                        

CREATE INDEX idx_{insee}_bati_geom                                              
ON "{schema_travail}"."{insee}_bati"                                               
USING gist (geom);                                                            



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati200";

CREATE TABLE "{schema_travail}"."{insee}_bati200" AS
SELECT DISTINCT                                                               
       b.nature,                                                              
       b.fid,                                                                 
       b.geo_commune,                                                         
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(b.geom),                                            
             3),                                                              
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_bati" b                                           
INNER JOIN {SCHEMA_PUBLIC}.{TABLE_OLD200M} o                                                   
ON ST_Intersects(o.geom, b.geom);                                             


CREATE INDEX idx_{insee}_bati200_geom 
ON "{schema_travail}"."{insee}_bati200"
USING gist (geom); 



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati200_cc";

CREATE TABLE "{schema_travail}"."{insee}_bati200_cc" AS
WITH 

bati_intersect AS (
    SELECT DISTINCT ON (b200.fid)                                             
           b200.fid,                                                          
           b200.nature,                                                       
           ufr.comptecommunal,                                                
           ST_CollectionExtract(                                              
              ST_MakeValid(b200.geom),                                        
              3) AS geom                                                      
    FROM "{schema_travail}"."{insee}_bati200" b200                                 
    JOIN "{schema_travail}"."{insee}_ufr" ufr                                      
    ON ST_Intersects(ST_Centroid(b200.geom), ufr.geom)                        
),

bati_non_associes AS (
    SELECT b200.fid,                                                          
           b200.nature,                                                       
           ST_CollectionExtract(                                              
              ST_MakeValid(b200.geom),                                        
              3) AS geom,                                                     
           (SELECT ufr.comptecommunal                                         
            FROM "{schema_travail}"."{insee}_ufr" ufr                              
            ORDER BY ST_Distance(ST_Centroid(b200.geom), ufr.geom)            
            LIMIT 1) AS comptecommunal_proche                                 
    FROM "{schema_travail}"."{insee}_bati200" b200                                 
    LEFT JOIN bati_intersect bi                                               
    ON b200.fid = bi.fid                                                      
    WHERE bi.fid IS NULL                                                      
),

bati_final AS (
    SELECT bi.fid,                                                            
           bi.nature,                                                         
           bi.comptecommunal,                                                 
           bi.geom                                                            
    FROM bati_intersect bi                                                    
    
    UNION ALL                                                                 
    
    SELECT bna.fid,                                                           
           bna.nature,                                                        
           bna.comptecommunal_proche AS comptecommunal,                       
           bna.geom                                                           
    FROM bati_non_associes bna                                                
)
SELECT bf.fid,                                                                
       bf.nature,                                                             
       bf.comptecommunal,                                                     
       ST_SetSRID(bf.geom, 2154) AS geom                                      
FROM bati_final bf;                                                           

CREATE INDEX idx_{insee}_bati200_cc_geom 
ON "{schema_travail}"."{insee}_bati200_cc" 
USING GIST (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati200_cc_rg";

CREATE TABLE "{schema_travail}"."{insee}_bati200_cc_rg" AS
SELECT b200cc.comptecommunal,                                                 
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Union(b200cc.geom)),                                       
             3),                                                              
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_bati200_cc" b200cc                                
GROUP BY b200cc.comptecommunal;                                               

CREATE INDEX idx_{insee}_bati200_cc_rg_geom 
ON "{schema_travail}"."{insee}_bati200_cc_rg"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_bati_tampon50";

CREATE TABLE "{schema_travail}"."{insee}_bati_tampon50" AS
SELECT b200ccrg.comptecommunal,                                               
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Buffer(b200ccrg.geom, 50, 16)),                            
             3),                                                              
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_bati200_cc_rg" b200ccrg;                          

CREATE INDEX idx_{insee}_bati_tampon50_geom 
ON "{schema_travail}"."{insee}_bati_tampon50"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_zonage_elargi";                 

CREATE TABLE "{schema_travail}"."{insee}_zonage_elargi" AS
WITH zonage_elargi AS (
	 SELECT ST_SetSRID(                                                       
	           ST_CollectionExtract(                                          
	              ST_MakeValid(                                               
	                 ST_Union(zcorr.geom)),                                   
	              3),                                                         
	        2154) AS geom                                                     
	 FROM "{SCHEMA_RESULTAT}"."{TABLE_ZONAGE}" AS zcorr                    
	 WHERE zcorr.insee = '{insee}'                                              
	 OR CONCAT(LEFT(zcorr.insee, 2), '0', RIGHT(zcorr.insee, 3)) 
	     IN (SELECT {TABLE_COMMUNE} 
	         FROM "{schema_travail}"."{insee}_commune_adjacente")                  
)
SELECT COALESCE(                                                              
           (SELECT geom FROM zonage_elargi),                                  
           ST_GeomFromText(                                                   
        'MULTIPOLYGON(((
        648291.57 6862250.49,
        648241.57 6862200.49,
        648191.57 6862250.49,
        648241.57 6862300.49,
        648291.57 6862250.49)))',
               2154)) AS geom;                                                

CREATE INDEX idx_{insee}_zonage_elargi_geom                                   
ON "{schema_travail}"."{insee}_zonage_elargi" 
USING gist (geom);                                                           



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_tampon_i";

CREATE TABLE "{schema_travail}"."{insee}_tampon_i" AS
SELECT t1.comptecommunal AS comptecomm1,                                      
       t2.comptecommunal AS comptecomm2,                                      
       ST_CollectionExtract(                                                  
          ST_MakeValid(                                                       
             ST_Intersection(t1.geom, t2.geom)),                              
          3) AS geom                                                          
FROM "{schema_travail}"."{insee}_bati_tampon50" t1                                 
JOIN "{schema_travail}"."{insee}_bati_tampon50" t2                                 
ON t1.comptecommunal <> t2.comptecommunal                                      
AND ST_DWithin(t1.geom, t2.geom, 0.01)                                        
AND ST_Intersects(t1.geom, t2.geom)                                           
WHERE ST_Area(ST_Intersection(t1.geom, t2.geom)) > 1;                         

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



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_tampon_ihu";

CREATE TABLE "{schema_travail}"."{insee}_tampon_ihu" AS

SELECT t.comptecomm1,                                                         
       t.comptecomm2,                                                         
       ST_CollectionExtract(                                                  
          ST_MakeValid(                                                       
             ST_Union(                                                        
                ST_MakeValid(                                                 
                   ST_Difference(                                             
                      ST_MakeValid(t.geom),                                   
                      ST_MakeValid(zcorr.geom))))),                           
          3) AS geom                                                          
FROM "{schema_travail}"."{insee}_tampon_i" AS t                                    
JOIN "{schema_travail}"."{insee}_zonage_elargi" AS zcorr                           
ON ST_Intersects(t.geom, zcorr.geom)                                          
WHERE ST_Area(ST_Difference(t.geom, zcorr.geom)) > 0                          
GROUP BY t.comptecomm1, t.comptecomm2, t.geom, zcorr.geom                     

UNION ALL                                                                     


SELECT t.comptecomm1,                                                         
       t.comptecomm2,                                                         
       ST_CollectionExtract(                                                  
          ST_MakeValid(t.geom),                                               
          3) AS geom                                                          
FROM "{schema_travail}"."{insee}_tampon_i" AS t                                    
WHERE NOT EXISTS (                                                            
      SELECT 1
      FROM "{schema_travail}"."{insee}_zonage_elargi" AS zcorr                    
      WHERE ST_Intersects(t.geom, zcorr.geom));                               

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



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_tampon_ihu_rg";

CREATE TABLE "{schema_travail}"."{insee}_tampon_ihu_rg" AS
SELECT ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Union(t.geom)),                                            
             3),                                                              
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_tampon_ihu" AS t;                                 

CREATE INDEX idx_{insee}_tampon_ihu_rg_geom
ON "{schema_travail}"."{insee}_tampon_ihu_rg"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_parcelle_batie";

CREATE TABLE "{schema_travail}"."{insee}_parcelle_batie" AS
SELECT p.comptecommunal,                                                      
       p.geo_parcelle,                                                        
       p.idu,                                                                 
       ST_CollectionExtract(                                                  
          ST_MakeValid(                                                       
             ST_Union(p.geom)),                                               
          3) AS geom                                                          
FROM "{SCHEMA_PARCELLE}"."{insee}_parcelle" p                                       
INNER JOIN "{schema_travail}"."{insee}_bati200_cc_rg" b                            
ON ST_Intersects(p.geom, b.geom)                                              
WHERE p.comptecommunal = b.comptecommunal                                     
GROUP BY p.comptecommunal, p.geo_parcelle, p.idu;                             

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



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_parcelle_batie_u";

CREATE TABLE "{schema_travail}"."{insee}_parcelle_batie_u" AS
SELECT comptecommunal,                                                        
	   idu,                                                                   
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Union(geom)),                                              
             3),                                                              
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_parcelle_batie"                                   
GROUP BY comptecommunal,idu;                                                  

CREATE INDEX idx_{insee}_parcelle_batie_u_geom
ON "{schema_travail}"."{insee}_parcelle_batie_u"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_parcelle_batie_ihu";

CREATE TABLE "{schema_travail}"."{insee}_parcelle_batie_ihu" AS
SELECT DISTINCT p.*                                             
FROM "{schema_travail}"."{insee}_parcelle_batie_u" AS p              
JOIN "{schema_travail}"."{insee}_tampon_ihu" AS t                    
ON p.comptecommunal = t.comptecomm1;                            

CREATE INDEX "idx_{insee}_parcelle_batie_ihu_geom" 
ON "{schema_travail}"."{insee}_parcelle_batie_ihu"
USING gist (geom); 



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ufr_bati";

CREATE TABLE "{schema_travail}"."{insee}_ufr_bati" AS
SELECT uf.comptecommunal,                                                     
       ST_CollectionExtract(                                                  
          ST_MakeValid(                                                       
             ST_Intersection(                                                 
                uf.geom,                                                      
                pb.geom)),                                                    
          3) AS geom                                                          
FROM "{schema_travail}"."{insee}_ufr" AS uf                                        
LEFT JOIN "{schema_travail}"."{insee}_parcelle_batie_u" pb                         
ON ST_Intersects(uf.geom, pb.geom)                                            
WHERE uf.comptecommunal = pb.comptecommunal;                                  

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



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_pt_interpol";

CREATE TABLE "{schema_travail}"."{insee}_pt_interpol" AS
WITH dumped_parcelles AS (
    SELECT p.comptecommunal,                               
		   p.idu,                                          
           (ST_DumpRings(                                  
              (ST_Dump(p.geom)).geom                       
           )).geom AS dumped_geom                          
    FROM "{schema_travail}"."{insee}_parcelle_batie_ihu" p      
)
SELECT comptecommunal,                                     
	   idu,
       ST_LineInterpolatePoints(
           ST_ExteriorRing(dumped_geom),                   
           1/ ST_Length(ST_ExteriorRing(dumped_geom))      
       ) AS geom                                           
FROM dumped_parcelles                                      
WHERE ST_Length(ST_ExteriorRing(dumped_geom)) > 1;         

CREATE INDEX idx_{insee}_pt_interpol_geom
ON "{schema_travail}"."{insee}_pt_interpol"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_pt_interpol_rg";

CREATE TABLE "{schema_travail}"."{insee}_pt_interpol_rg" AS
SELECT p.comptecommunal,                                                      
       ST_SetSRID(                                                            
          (ST_Dump(p.geom)).geom,                                             
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_pt_interpol" p;                                   

CREATE INDEX idx_{insee}_pt_interpol_rg_geom
ON "{schema_travail}"."{insee}_pt_interpol_rg"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_voronoi";

CREATE TABLE "{schema_travail}"."{insee}_voronoi" AS
SELECT (ST_Dump(                                                              
          ST_VoronoiPolygons(                                                 
             ST_Collect(p.geom))                                              
       )).geom AS geom                                                        
FROM "{schema_travail}"."{insee}_pt_interpol_rg" p;                                

ALTER TABLE "{schema_travail}"."{insee}_voronoi"
ALTER COLUMN geom TYPE geometry(Polygon, 2154)
USING ST_SetSRID(geom, 2154);                                              

CREATE INDEX idx_{insee}_voronoi_geom
ON "{schema_travail}"."{insee}_voronoi"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_voronoi_cc";

CREATE TABLE "{schema_travail}"."{insee}_voronoi_cc" AS
SELECT p.comptecommunal,                                                      
       ST_CollectionExtract(                                                  
          ST_MakeValid(v.geom),                                               
          3) AS geom                                                          
FROM "{schema_travail}"."{insee}_voronoi" v                                        
INNER JOIN "{schema_travail}"."{insee}_pt_interpol_rg" p                           
ON ST_Within(p.geom, v.geom);                                                 

ALTER TABLE "{schema_travail}"."{insee}_voronoi_cc"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);                                              

CREATE INDEX idx_{insee}_voronoi_cc_geom
ON "{schema_travail}"."{insee}_voronoi_cc"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_voronoi_cc_rg";

CREATE TABLE "{schema_travail}"."{insee}_voronoi_cc_rg" AS
SELECT vcc.comptecommunal,                                                    
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Union(vcc.geom)),                                          
             3),                                                              
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_voronoi_cc" vcc                                   
GROUP BY vcc.comptecommunal;                                                  

CREATE INDEX idx_{insee}_voronoi_cc_rg_geom
ON "{schema_travail}"."{insee}_voronoi_cc_rg"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t1";

CREATE TABLE "{schema_travail}"."{insee}_b1_t1" AS
WITH tampon_extract AS (
     SELECT t.comptecomm1,                                                    
            t.comptecomm2,                                                    
            ST_CollectionExtract(                                             
               ST_MakeValid(t.geom),                                          
               3) AS geom                                                     
     FROM "{schema_travail}"."{insee}_tampon_ihu" t                                
     WHERE t.geom IS NOT NULL                                                 
     AND NOT ST_IsEmpty(t.geom)                                               
)
SELECT te.comptecomm1,                                                        
       te.comptecomm2,                                                        
       ST_SetSRID(te.geom, 2154) AS geom                                      
FROM tampon_extract te                                                        
WHERE te.geom IS NOT NULL                                                     
AND NOT ST_IsEmpty(te.geom);                                                  
				
DELETE FROM "{schema_travail}"."{insee}_b1_t1"
WHERE geom IS NULL  
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

CREATE INDEX "idx_{insee}_b1_t1_geom" 
ON "{schema_travail}"."{insee}_b1_t1"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t2";

CREATE TABLE "{schema_travail}"."{insee}_b1_t2" AS
SELECT b1.comptecomm1,                                                        
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Union(b1.geom)),                                           
             3),                                                              
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_b1_t1" b1                                         
GROUP BY b1.comptecomm1;                                                      

DELETE FROM "{schema_travail}"."{insee}_b1_t2"
WHERE geom IS NULL                                                           
OR ST_IsEmpty(geom)                                                       
OR NOT ST_IsValid(geom);  
   
CREATE INDEX idx_{insee}_b1_t2_geom
ON "{schema_travail}"."{insee}_b1_t2"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t3";

CREATE TABLE "{schema_travail}"."{insee}_b1_t3" AS
SELECT bt50.comptecommunal,                                                   
       ST_CollectionExtract(                                                  
          ST_MakeValid(                                                       
             ST_Union(                                                        
                ST_Difference(                                                
                   ST_MakeValid(bt50.geom),                                   
                   ST_MakeValid(zu.geom)))),                                  
       3) AS geom                                                             
FROM "{schema_travail}"."{insee}_bati_tampon50" bt50,                              
     "{schema_travail}"."{insee}_zonage_elargi" zu                                  
GROUP BY bt50.comptecommunal;                                                 

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
			 
			 

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t4";

CREATE TABLE "{schema_travail}"."{insee}_b1_t4" AS
SELECT t.comptecomm1,                                                         
       t.comptecomm2,                                                         
       ST_CollectionExtract(                                                  
          ST_MakeValid(                                                       
             ST_Intersection(                                                 
                ST_MakeValid(t.geom),                                         
                ST_MakeValid(u.geom))),                                       
       3) AS geom                                                             
FROM "{schema_travail}"."{insee}_tampon_ihu" t,                                    
     "{schema_travail}"."{insee}_ufr" u                                            
WHERE u.comptecommunal = t.comptecomm2                                        
AND ST_Intersects(t.geom, u.geom);                                            

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

				

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t5";

CREATE TABLE "{schema_travail}"."{insee}_b1_t5" AS
SELECT b4.comptecomm1 AS comptecommunal,                                      
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Union(b4.geom)),                                           
             3),                                                              
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_b1_t4" b4                                         
GROUP BY b4.comptecomm1;                                                      

DELETE FROM "{schema_travail}"."{insee}_b1_t5"
WHERE geom IS NULL                                                            
OR ST_IsEmpty(geom)                                                      
OR NOT ST_IsValid(geom);     

CREATE INDEX idx_{insee}_b1_t5_geom
ON "{schema_travail}"."{insee}_b1_t5"
USING gist (geom);

		

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t6";

CREATE TABLE "{schema_travail}"."{insee}_b1_t6" AS
SELECT b3.comptecommunal,                                                     
       ST_CollectionExtract(                                                  
          ST_MakeValid(                                                       
             ST_Intersection(                                                 
                ST_MakeValid(b3.geom),                                        
                ST_MakeValid(u.geom))),                                       
          3) AS geom                                                          
FROM "{schema_travail}"."{insee}_b1_t3" b3,                                        
     "{schema_travail}"."{insee}_ufr" u                                            
WHERE u.comptecommunal = b3.comptecommunal                                    
AND ST_Intersects(b3.geom, u.geom);                                           

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



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t7";

CREATE TABLE "{schema_travail}"."{insee}_b1_t7" AS
SELECT b6.comptecommunal,                                                     
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Union(b6.geom)),                                           
             3),                                                              
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_b1_t6" b6                                         
GROUP BY b6.comptecommunal;                                                   

DELETE FROM "{schema_travail}"."{insee}_b1_t7"
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                      
OR NOT ST_IsValid(geom);   

CREATE INDEX idx_{insee}_b1_t7_geom
ON "{schema_travail}"."{insee}_b1_t7"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t8";

CREATE TABLE "{schema_travail}"."{insee}_b1_t8" AS
WITH union_all AS (
     
     SELECT t7.comptecommunal,                                                
            ST_CollectionExtract(                                             
               ST_MakeValid(t7.geom),                                         
               3) AS geom                                                     
     FROM "{schema_travail}"."{insee}_b1_t7" t7                                    
     
     UNION ALL                                                                
     
     
     SELECT t5.comptecommunal,                                                
            ST_CollectionExtract(                                             
               ST_MakeValid(t5.geom),                                         
               3) AS geom                                                     
     FROM "{schema_travail}"."{insee}_b1_t5" t5                                    
)
SELECT comptecommunal,                                                        
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_UnaryUnion(                                                
                   ST_Collect(geom))),                                        
             3),                                                              
       2154) AS geom                                                          
FROM union_all                                                                
GROUP BY comptecommunal;                                                      

DELETE FROM "{schema_travail}"."{insee}_b1_t8"
WHERE geom IS NULL                                                          
OR ST_IsEmpty(geom)                                                        
OR NOT ST_IsValid(geom);                                               

CREATE INDEX idx_{insee}_b1_t8_geom
ON "{schema_travail}"."{insee}_b1_t8"
USING gist (geom);
    


DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t9";

CREATE TABLE "{schema_travail}"."{insee}_b1_t9" AS
SELECT COALESCE(b1.comptecomm1, b8.comptecommunal) AS comptecomm1,            
       b1.comptecomm2,                                                        
       CASE
           
           WHEN b8.comptecommunal IS NULL                                     
           THEN ST_SetSRID(                                                   
                   ST_CollectionExtract(                                      
                      ST_MakeValid(b1.geom),                                  
                      3),                                                     
                2154)                                                         
           
           
           WHEN b1.comptecomm1 IS NOT NULL                                    
           AND b8.comptecommunal IS NOT NULL                                  
           THEN ST_SetSRID(                                                   
                   ST_CollectionExtract(                                      
                      ST_MakeValid(                                           
                         ST_Difference(                                       
                            ST_MakeValid(b1.geom),                            
                            ST_MakeValid(b8.geom))),                          
                      3),                                                     
                2154)                                                         
           
           
           WHEN b1.comptecomm1 IS NULL                                        
           THEN NULL                                                          
       
	   END AS geom                                                            
FROM "{schema_travail}"."{insee}_b1_t1" b1                                         
FULL OUTER JOIN "{schema_travail}"."{insee}_b1_t8" b8                              
ON b1.comptecomm1 = b8.comptecommunal;                                        

DELETE FROM "{schema_travail}"."{insee}_b1_t9"
WHERE geom IS NULL                                                          
OR ST_IsEmpty(geom)                                                     
OR NOT ST_IsValid(geom);   

CREATE INDEX idx_{insee}_b1_t9_geom
ON "{schema_travail}"."{insee}_b1_t9"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t10";

CREATE TABLE "{schema_travail}"."{insee}_b1_t10" AS

WITH epine_externe AS (
     SELECT b9.comptecomm1,                                                   
            b9.comptecomm2,                                                   
            ST_CollectionExtract(                                             
               ST_MakeValid(                                                  
                  ST_Snap(                                                    
                     ST_RemoveRepeatedPoints(                                 
                        ST_Buffer(                                            
                           b9.geom,
                           -0.001,                                           
                           'join=mitre mitre_limit=5.0'),                     
                        0.003),                                              
                     b9.geom,                                                 
                     0.0006)),                                                
               3) AS geom                                                     
     FROM "{schema_travail}"."{insee}_b1_t9" b9                                    
),

epine_interne AS (
     SELECT epext.comptecomm1,                                                
            epext.comptecomm2,                                                
            ST_CollectionExtract(                                             
               ST_MakeValid(                                                  
                  ST_Snap(                                                    
                     ST_RemoveRepeatedPoints(                                 
                        ST_Buffer(                                            
                           epext.geom,
                           0.001,                                            
                           'join=mitre mitre_limit=5.0'),                     
                        0.003),                                              
                     b9.geom,                                                 
                     0.0006)),                                                
               3) AS geom                                                     
     FROM epine_externe epext                                                 
     INNER JOIN "{schema_travail}"."{insee}_b1_t9" b9                              
     ON epext.comptecomm1 = b9.comptecomm1                                    
     AND epext.comptecomm2 = b9.comptecomm2                                   
)

SELECT epint.comptecomm1,                                                     
       epint.comptecomm2,                                                     
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(epint.geom),                                        
             3),                                                              
       2154) AS geom                                                          
FROM epine_interne epint                                                      
WHERE epint.geom IS NOT NULL                                                  
AND NOT ST_IsEmpty(epint.geom);                                               

DELETE FROM "{schema_travail}"."{insee}_b1_t10"
WHERE geom IS NULL                                                            
OR ST_IsEmpty(geom)                                                   
OR NOT ST_IsValid(geom);      

CREATE INDEX idx_{insee}_b1_t10_geom
ON "{schema_travail}"."{insee}_b1_t10"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t11";

CREATE TABLE "{schema_travail}"."{insee}_b1_t11" AS
SELECT b10.comptecomm1,                                                       
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Union(b10.geom)),                                          
             3),                                                              
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_b1_t10" b10                                       
GROUP BY b10.comptecomm1;                                                     

DELETE FROM "{schema_travail}"."{insee}_b1_t11"
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                      
OR NOT ST_IsValid(geom);   

CREATE INDEX idx_{insee}_b1_t11_geom
ON "{schema_travail}"."{insee}_b1_t11"
USING gist (geom);

			

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t12";

CREATE TABLE "{schema_travail}"."{insee}_b1_t12" AS
SELECT COALESCE(b3.comptecommunal, b2.comptecomm1) AS comptecomm1,            
       CASE
           
           WHEN b2.comptecomm1 IS NULL                                        
           THEN ST_SetSRID(                                                   
                   ST_CollectionExtract(                                      
                      ST_MakeValid(b3.geom),                                  
                      3),                                                     
                2154)                                                         
           
           
           WHEN b3.comptecommunal IS NOT NULL                                 
            AND b2.comptecomm1 IS NOT NULL                                    
           THEN ST_SetSRID(                                                   
                   ST_CollectionExtract(                                      
                      ST_MakeValid(                                           
                         ST_Difference(                                       
                            ST_MakeValid(b3.geom),                            
                            ST_MakeValid(b2.geom))),                          
                      3),                                                     
                2154)                                                         
           
           
           WHEN b3.comptecommunal IS NULL                                     
           THEN NULL                                                          
       END AS geom                                                            
FROM "{schema_travail}"."{insee}_b1_t3" b3                                         
FULL OUTER JOIN "{schema_travail}"."{insee}_b1_t2" b2                              
ON b2.comptecomm1 = b3.comptecommunal;                                        

DELETE FROM "{schema_travail}"."{insee}_b1_t12"
WHERE geom IS NULL                                                            
OR ST_IsEmpty(geom)                                                       
OR NOT ST_IsValid(geom);  

CREATE INDEX idx_{insee}_b1_t12_geom
ON "{schema_travail}"."{insee}_b1_t12"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t13";

CREATE TABLE "{schema_travail}"."{insee}_b1_t13" AS
SELECT b10.comptecomm1,                                                       
       ST_CollectionExtract(                                                  
          ST_MakeValid(                                                       
             ST_Intersection(                                                 
                ST_MakeValid(b10.geom),                                       
                ST_MakeValid(v.geom))),                                       
          3) AS geom                                                          
FROM "{schema_travail}"."{insee}_b1_t10" b10                                       
INNER JOIN "{schema_travail}"."{insee}_voronoi_cc_rg" v                            
ON v.comptecommunal = b10.comptecomm1                                         
AND ST_Intersects(b10.geom, v.geom);                                       

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



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t14";

CREATE TABLE "{schema_travail}"."{insee}_b1_t14" AS
SELECT b13.comptecomm1 AS comptecommunal,                                     
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Union(b13.geom)),                                          
             3),                                                              
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_b1_t13" b13                                       
GROUP BY b13.comptecomm1;                                                     

DELETE FROM "{schema_travail}"."{insee}_b1_t14"
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                        
OR NOT ST_IsValid(geom);                                                 

CREATE INDEX idx_{insee}_b1_t14_geom
ON "{schema_travail}"."{insee}_b1_t14"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t15";

CREATE TABLE "{schema_travail}"."{insee}_b1_t15" AS
WITH union_all AS (
     
     SELECT t7.comptecommunal,                                                
            ST_CollectionExtract(                                             
               ST_MakeValid(t7.geom),                                         
               3) AS geom                                                     
     FROM "{schema_travail}"."{insee}_b1_t7" t7                                    
     
     UNION ALL                                                                
     
     
     SELECT t12.comptecomm1 AS comptecommunal,                                
            ST_CollectionExtract(                                             
               ST_MakeValid(t12.geom),                                        
               3) AS geom                                                     
     FROM "{schema_travail}"."{insee}_b1_t12" t12                                  
)
SELECT comptecommunal,                                                        
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_UnaryUnion(                                                
                   ST_Collect(geom))),                                        
             3),                                                              
       2154) AS geom                                                          
FROM union_all                                                                
GROUP BY comptecommunal;                                                      

DELETE FROM "{schema_travail}"."{insee}_b1_t15"
WHERE geom IS NULL                                                        
OR ST_IsEmpty(geom)                                                      
OR NOT ST_IsValid(geom);      

CREATE INDEX idx_{insee}_b1_t15_geom
ON "{schema_travail}"."{insee}_b1_t15"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t16";

CREATE TABLE "{schema_travail}"."{insee}_b1_t16" AS
WITH union_all AS (
     
     SELECT b14.comptecommunal,                                               
            ST_CollectionExtract(                                             
               ST_MakeValid(b14.geom),                                        
               3) AS geom                                                     
     FROM "{schema_travail}"."{insee}_b1_t14" b14                                  
     
     UNION ALL                                                                
     
     
     SELECT b15.comptecommunal,                                               
            ST_CollectionExtract(                                             
               ST_MakeValid(b15.geom),                                        
               3) AS geom                                                     
     FROM "{schema_travail}"."{insee}_b1_t15" b15                                  
)
SELECT comptecommunal,                                                        
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_UnaryUnion(                                                
                   ST_Collect(geom))),                                        
             3),                                                              
       2154) AS geom                                                          
FROM union_all                                                                
GROUP BY comptecommunal;                                                      

DELETE FROM "{schema_travail}"."{insee}_b1_t16"
WHERE geom IS NULL                                                          
OR ST_IsEmpty(geom)                                                       
OR NOT ST_IsValid(geom);                                            
   
CREATE INDEX idx_{insee}_b1_t16_geom
ON "{schema_travail}"."{insee}_b1_t16"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t17";

CREATE TABLE "{schema_travail}"."{insee}_b1_t17" AS
SELECT ufr.comptecommunal,                                                    
       ST_CollectionExtract(                                                  
          ST_MakeValid(                                                       
             ST_Intersection(                                                 
                ST_MakeValid(ufr.geom),                                       
                ST_MakeValid(z_corr7.geom))),                                 
       3) AS geom                                                             
FROM "{schema_travail}"."{insee}_ufr" ufr                                          
INNER JOIN "{schema_travail}"."{insee}_zonage_elargi" z_corr7                       
ON ST_Intersects(ufr.geom, z_corr7.geom);                                     

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

				

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t18";

CREATE TABLE "{schema_travail}"."{insee}_b1_t18" AS
WITH union_all AS (
     
     SELECT comptecommunal,                                                   
            ST_CollectionExtract(                                             
               ST_MakeValid(geom),                                            
               3) AS geom                                                     
     FROM "{schema_travail}"."{insee}_b1_t17"                                      
     
     UNION ALL                                                                
     
     
     SELECT comptecommunal,                                                   
            ST_CollectionExtract(                                             
               ST_MakeValid(geom),                                            
               3) AS geom                                                     
     FROM "{schema_travail}"."{insee}_b1_t16"                                      
)
SELECT comptecommunal,                                                        
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_UnaryUnion(                                                
                   ST_Collect(geom))),                                        
             3),                                                              
       2154) AS geom                                                          
FROM union_all                                                                
GROUP BY comptecommunal;                                                      

DELETE FROM "{schema_travail}"."{insee}_b1_t18"
WHERE geom IS NULL                                                     
OR ST_IsEmpty(geom)                                                    
OR NOT ST_IsValid(geom); 

CREATE INDEX idx_{insee}_b1_t18_geom
ON "{schema_travail}"."{insee}_b1_t18"
USING gist (geom);
				
				

DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t19";

CREATE TABLE "{schema_travail}"."{insee}_b1_t19" AS
SELECT b18.comptecommunal,                                                    
       CASE
           
           WHEN nc.geom IS NOT NULL                                           
           THEN ST_CollectionExtract(                                         
                   ST_MakeValid(                                              
                      ST_Difference(                                          
                         ST_MakeValid(b18.geom),                              
                         ST_MakeValid(nc.geom))),                             
                   3)                                                         
           
           
           ELSE ST_CollectionExtract(                                         
                   ST_MakeValid(b18.geom),                                    
                   3)                                                         
       END AS geom                                                            
FROM "{schema_travail}"."{insee}_b1_t18" b18                                       
LEFT JOIN "{schema_travail}"."{insee}_non_cadastre" nc                             
ON ST_Intersects(b18.geom, nc.geom);                                          

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



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_b1_t20";

CREATE TABLE "{schema_travail}"."{insee}_b1_t20" AS

WITH epine_externe AS (
     SELECT b19.comptecommunal,                                               
            ST_CollectionExtract(                                             
               ST_MakeValid(                                                  
                  ST_Snap(                                                    
                     ST_RemoveRepeatedPoints(                                 
                        ST_Buffer(                                            
                           b19.geom,
                           -0.001,                                           
                           'join=mitre mitre_limit=5.0'),                     
                        0.003),                                              
                     b19.geom,                                                
                     0.0006)),                                                
               3) AS geom                                                     
     FROM "{schema_travail}"."{insee}_b1_t19" b19                                  
),

epine_interne AS (
     SELECT epext.comptecommunal,                                             
            ST_CollectionExtract(                                             
               ST_MakeValid(                                                  
                  ST_Snap(                                                    
                     ST_RemoveRepeatedPoints(                                 
                        ST_Buffer(                                            
                           epext.geom,
                           0.001,                                            
                           'join=mitre mitre_limit=5.0'),                     
                        0.003),                                              
                     b19.geom,                                                
                     0.0006)),                                                
               3) AS geom                                                     
     FROM epine_externe epext                                                 
     JOIN "{schema_travail}"."{insee}_b1_t19" b19                                  
     ON epext.comptecommunal = b19.comptecommunal                             
)

SELECT epint.comptecommunal,                                                  
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(epint.geom),                                        
             3),                                                              
       2154) AS geom                                                          
FROM epine_interne epint                                                      
WHERE epint.geom IS NOT NULL                                                  
AND NOT ST_IsEmpty(epint.geom);                                               

DELETE FROM "{schema_travail}"."{insee}_b1_t20"
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                       
OR NOT ST_IsValid(geom);    

CREATE INDEX idx_{insee}_b1_t20_geom
ON "{schema_travail}"."{insee}_b1_t20"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result1";

CREATE TABLE "{schema_travail}"."{insee}_result1" AS         
WITH
decoupe AS (
	SELECT b20.comptecommunal,                            
       ST_SetSRID(                                        
          ST_CollectionExtract(                           
             ST_MakeValid(                                
                ST_Intersection(                          
                   ST_MakeValid(b20.geom),                
                   ST_MakeValid(o.geom))),                
             3),                                          
       2154) AS geom                                      
	FROM "{schema_travail}"."{insee}_b1_t20" AS b20            
	JOIN {SCHEMA_PUBLIC}.{TABLE_OLD200M} AS o                              
	ON ST_Intersects(b20.geom, o.geom)                    
)


SELECT
decoupe.comptecommunal,
ST_Multi(
    (
        SELECT ST_Collect(
                 ST_MakePolygon(
                   ST_ExteriorRing((g).geom)
                 )
               )
        FROM ST_Dump(decoupe.geom) AS g
    )
) AS geom
FROM decoupe;

CREATE INDEX idx_{insee}_result1_geom 
ON "{schema_travail}"."{insee}_result1"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result1_rg";

CREATE TABLE "{schema_travail}"."{insee}_result1_rg" AS                     
SELECT ST_SetSRID(                                           
         ST_Multi(                                           
            ST_Union(                                        
               ST_MakeValid(                                 
                  ST_RemoveRepeatedPoints(r1.geom, 0.01)     
                  ))),                                   
       2154) AS geom                                         
FROM "{schema_travail}"."{insee}_result1" r1;                     

DELETE FROM "{schema_travail}"."{insee}_result1_rg"                                 
WHERE geom IS NULL                                                         
OR ST_IsEmpty(geom)                                                   
OR NOT ST_IsValid(geom);                                                

CREATE INDEX idx_{insee}_result1_rg_geom                           
ON "{schema_travail}"."{insee}_result1_rg"                            
USING gist (geom);                                               



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_trou1";                    

CREATE TABLE "{schema_travail}"."{insee}_trou1" AS
SELECT ST_SetSRID(                                          
          ST_CollectionExtract(                             
             ST_MakeValid(                                  
                ST_Difference(                              
                    ST_MakeValid(t_ihu.geom),               
	                ST_MakeValid(r1rg.geom))),              
             3),
        2154) AS geom                                       
FROM "{schema_travail}"."{insee}_tampon_ihu_rg" t_ihu            
JOIN "{schema_travail}"."{insee}_result1_rg" r1rg                
ON ST_Intersects(t_ihu.geom, r1rg.geom);                    

DELETE FROM "{schema_travail}"."{insee}_trou1"                               
WHERE geom IS NULL                                                     
OR ST_IsEmpty(geom)                                                  
OR NOT ST_IsValid(geom);                                          

CREATE INDEX idx_{insee}_trou1_geom                                      
ON "{schema_travail}"."{insee}_trou1"                                        
USING gist (geom);                                                      



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_trou2";

CREATE TABLE "{schema_travail}"."{insee}_trou2" AS
SELECT ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Difference(                                                
                   ST_MakeValid(t.geom),                                      
                   ST_MakeValid(nc.geom))),                                   
             3),                                                              
       2154) AS geom                                                          
FROM "{schema_travail}"."{insee}_trou1" AS t                                       
CROSS JOIN "{schema_travail}"."{insee}_non_cadastre" AS nc                         
WHERE ST_Intersects(t.geom, nc.geom);                                         

DELETE FROM "{schema_travail}"."{insee}_trou2"  
WHERE geom IS NULL 
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

CREATE INDEX idx_{insee}_trou2_geom                                   
ON "{schema_travail}"."{insee}_trou2"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_trou3";                     

CREATE TABLE "{schema_travail}"."{insee}_trou3" AS                           
SELECT d.path,                                                          
       ST_Area(d.geom) AS surface,                                      
       ST_SetSRID(d.geom, 2154) AS geom                                 
FROM (SELECT (ST_Dump(t.geom)).*                                        
      FROM "{schema_travail}"."{insee}_trou2" t) AS d;                       

DELETE FROM "{schema_travail}"."{insee}_trou3"                               
WHERE geom IS NULL                                                      
OR ST_IsEmpty(geom)                                                  
OR NOT ST_IsValid(geom)                                              
OR surface <= 0.1;                                                     

CREATE INDEX idx_{insee}_trou3_geom                                      
ON "{schema_travail}"."{insee}_trou3"                                      
USING gist (geom);                                                     



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_trou4";                     

CREATE TABLE "{schema_travail}"."{insee}_trou4" AS                           
SELECT
	path AS id,
	ST_SimplifyPreserveTopology(
		ST_Buffer(geom, 0.5)
		,1) AS geom
FROM "{schema_travail}"."{insee}_trou3";

CREATE INDEX idx_{insee}_trou4_geom                                
ON "{schema_travail}"."{insee}_trou4"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_trou5";                     

CREATE TABLE "{schema_travail}"."{insee}_trou5" AS                           
WITH
premier_tri AS (
	SELECT tr3.path AS idtrou,                                                    
	   ARRAY_AGG(DISTINCT t.comptecomm1 ORDER BY t.comptecomm1) AS liste_ncc_1,   
       tr3.geom                                                                   
	FROM "{schema_travail}"."{insee}_trou3" tr3
	INNER JOIN "{schema_travail}"."{insee}_tampon_ihu" t                               
	ON (ST_Overlaps(tr3.geom, ST_Buffer(t.geom, -.01))                            
		OR ST_Contains(t.geom, tr3.geom))                                         
	WHERE GeometryType(tr3.geom) IN ('POLYGON', 'MULTIPOLYGON')                   
	GROUP BY tr3.path, tr3.geom                                                   
	),


central_pts AS (
    SELECT
        id AS idtrou,
		(ST_DumpPoints(
			tr4.geom)).geom AS pt
    FROM "{schema_travail}"."{insee}_trou4" tr4
),

b_polys AS (
    SELECT p.comptecommunal, p.idu, premier_tri.idtrou, 
	 ST_SetSRID(                                                  
		ST_CoverageSimplify(p.geom, 2) OVER ()                    
		,2154) AS covgeom,                                        
		p.geom
    FROM "{schema_travail}"."{insee}_parcelle_batie" p
	INNER JOIN premier_tri
	ON p.comptecommunal = ANY(premier_tri.liste_ncc_1)            
),
b_pts AS (
    SELECT
        b.idtrou,
		b.comptecommunal,
		b.idu AS bid,
        ST_SetSRID((ST_DumpPoints(b.covgeom)).geom, 2154) AS pt
    FROM b_polys b
),

lignes_visee AS (
    SELECT DISTINCT
		b.idtrou,
		b.bid,
        b.comptecommunal,
		ST_SetSRID(                                                
			ST_MakeLine(a.pt, b.pt)
			, 2154) AS line_geom
    FROM central_pts a
    JOIN b_pts b
	ON b.idtrou = a.idtrou
	AND ST_Distance(a.pt, b.pt) < 50
),

lignes_visee_directes AS (
	SELECT  lv.idtrou, lv.bid, lv.comptecommunal, lv.line_geom AS geom
    FROM lignes_visee lv
	
    WHERE NOT EXISTS (
        SELECT 1
        FROM b_polys bp
        WHERE bp.idtrou = lv.idtrou
        AND bp.idu != lv.bid
        AND ST_Crosses(lv.line_geom, bp.geom)      
	)                                              
),

ncc_parcelle_visible AS (
	SELECT lvd.idtrou, lvd.comptecommunal
    FROM lignes_visee_directes lvd
	GROUP BY lvd.comptecommunal, lvd.idtrou   
),

liste_ncc_visible AS (
	SELECT 
	idtrou,                                                                 
	array_agg(comptecommunal ORDER BY comptecommunal) AS liste_trou_ncc_vis 
	FROM ncc_parcelle_visible
	GROUP BY idtrou
)
SELECT
ccv.idtrou,
array_length(premier_tri.liste_ncc_1, 1) AS nb_liste1,
array_length(ccv.liste_trou_ncc_vis, 1) AS nb_liste2,
premier_tri.liste_ncc_1,
ccv.liste_trou_ncc_vis,
premier_tri.geom
FROM premier_tri
JOIN liste_ncc_visible ccv
ON premier_tri.idtrou = ccv.idtrou;

CREATE INDEX idx_{insee}_trou5_geom                                
ON "{schema_travail}"."{insee}_trou5"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_trou6";    

CREATE TABLE "{schema_travail}"."{insee}_trou6" AS          
SELECT
tr5.idtrou,
tr5.liste_trou_ncc_vis[1] AS comptecommunal,
ST_SetSRID(
	ST_Multi(
		ST_MakeValid(tr5.geom)                         
		),               
	2154) AS geom                                      
FROM "{schema_travail}"."{insee}_trou5" tr5
WHERE tr5.nb_liste2 = 1;

CREATE INDEX idx_{insee}_trou6_geom                                
ON "{schema_travail}"."{insee}_trou6"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_trou_final";                     

CREATE TABLE "{schema_travail}"."{insee}_trou_final" AS                           
SELECT
tr5.idtrou,
tr5.nb_liste1,
tr5.nb_liste2,
tr5.liste_ncc_1,
tr5.liste_trou_ncc_vis,
ST_SetSRID(
	ST_Multi(
		ST_MakeValid(tr5.geom)         
		),               
	2154) AS geom                                  
FROM "{schema_travail}"."{insee}_trou5" tr5
LEFT JOIN "{schema_travail}"."{insee}_trou6" tr6
ON tr5.idtrou = tr6.idtrou
WHERE tr6.idtrou IS NULL;

CREATE INDEX idx_{insee}_trou_final_geom                                
ON "{schema_travail}"."{insee}_trou_final"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t1";

CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t1" AS
SELECT trf.idtrou,
	   t_ihu.comptecomm1,                                              
       t_ihu.comptecomm2,                                              
       ST_SetSRID(                                                     
          ST_CollectionExtract(                                        
             ST_MakeValid(                                             
                ST_Intersection(                                       
                   ST_MakeValid(trf.geom),                             
                   ST_MakeValid(t_ihu.geom))),                         
             3),                                                       
       2154) AS geom                                                   
FROM "{schema_travail}"."{insee}_tampon_ihu" AS t_ihu                       
JOIN "{schema_travail}"."{insee}_trou_final" AS trf                         
ON t_ihu.comptecomm1 = ANY(trf.liste_trou_ncc_vis)                     
AND t_ihu.comptecomm2 = ANY(trf.liste_trou_ncc_vis)                    
AND ST_Intersects(t_ihu.geom, trf.geom);                               

DELETE FROM "{schema_travail}"."{insee}_ilot_du_trou_t1"            
WHERE geom IS NULL 
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

CREATE INDEX idx_{insee}_ilot_du_trou_t1_geom                              
ON "{schema_travail}"."{insee}_ilot_du_trou_t1"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t1_abs";

CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t1_abs" AS
WITH
union_ilt1 AS (
	SELECT
	ilt1.idtrou,
	ST_Union(ilt1.geom) AS geom
	FROM "{schema_travail}"."{insee}_ilot_du_trou_t1" ilt1
	GROUP BY idtrou
),
difference AS (
	SELECT
	trf.idtrou,
       ST_SetSRID(                                                     
          ST_CollectionExtract(                                        
             ST_MakeValid(                                             
                ST_Difference(                                         
                   ST_MakeValid(trf.geom),                             
                   ST_MakeValid(union_ilt1.geom))),                    
             3),                                                       
       2154) AS geom                                                   
	FROM union_ilt1                        
	JOIN "{schema_travail}"."{insee}_trou_final" AS trf                       
	ON union_ilt1.idtrou = trf.idtrou                                  
),
dumpdiff AS (
	SELECT
	difference.idtrou,
	ST_Area((ST_Dump(difference.geom)).geom) AS surface,
	(ST_Dump(difference.geom)).geom AS geom                                                  
	FROM difference                        
),
nettoyage AS (
	SELECT
	dumpdiff.idtrou,
	ST_Union(dumpdiff.geom) AS geom
	FROM dumpdiff
	WHERE surface > 0.1
	GROUP BY dumpdiff.idtrou                                           
),
jointure1 AS (
	SELECT 
	nettoyage.idtrou,
	t_ihu.comptecomm1,
	t_ihu.comptecomm2,
	nettoyage.geom
	FROM nettoyage
	JOIN "{schema_travail}"."{insee}_tampon_ihu" AS t_ihu                   
	ON ST_Within(
		ST_PointOnSurface(nettoyage.geom),
		t_ihu.geom)                                                    
),
jointure2 AS (
	SELECT 
	jointure1.idtrou,
	jointure1.comptecomm1,
	jointure1.comptecomm2,
	trf.liste_trou_ncc_vis,
	jointure1.geom
	FROM jointure1
	JOIN "{schema_travail}"."{insee}_trou_final" AS trf                       
	ON ST_Within(
		ST_PointOnSurface(jointure1.geom),
		trf.geom)                                 
)
SELECT 
jointure2.idtrou,
jointure2.comptecomm1 AS comptecommunal,
ST_SetSRID(
	ST_Multi(
		ST_MakeValid(jointure2.geom)              
		),               
	2154) AS geom                                 
FROM jointure2
WHERE jointure2.comptecomm1 = ANY(jointure2.liste_trou_ncc_vis);

DELETE FROM "{schema_travail}"."{insee}_ilot_du_trou_t1_abs"            
WHERE geom IS NULL 
OR ST_IsEmpty(geom) 
OR NOT ST_IsValid(geom);

CREATE INDEX idx_{insee}_ilot_du_trou_t1_abs_geom                              
ON "{schema_travail}"."{insee}_ilot_du_trou_t1_abs"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t2";

CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t2" AS
SELECT DISTINCT geom                                                         
FROM "{schema_travail}"."{insee}_ilot_du_trou_t1"                                 
WHERE geom IS NOT NULL;                                                      

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



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t3";

CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t3" AS
WITH
collection_poly AS (
	SELECT 
	ST_Collect(iltt2.geom) AS geom
	FROM "{schema_travail}"."{insee}_ilot_du_trou_t2" iltt2
),

segments AS (                               
	SELECT DISTINCT
	(ST_DumpSegments(
		collection_poly.geom
		)).geom AS geom
	FROM collection_poly
),

collection_segment AS (                     
	SELECT 
	ST_Collect(segments.geom) AS geom
	FROM segments
),

unaryunion AS (                                   
	SELECT 
	ST_UnaryUnion(
		collection_segment.geom) AS geom
	FROM collection_segment
),

polygonize AS (
	SELECT
	ST_collectionExtract(                   
		ST_Polygonize(unaryunion.geom)
	,3) AS geom
	FROM unaryunion
)

SELECT
	(ST_Dump(polygonize.geom)).path AS id,
	(ST_Dump(polygonize.geom)).geom AS geom        
FROM polygonize;

ALTER TABLE "{schema_travail}"."{insee}_ilot_du_trou_t3"
ALTER COLUMN geom 
TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);   

CREATE INDEX idx_{insee}_ilot_du_trou_t3_geom              
ON "{schema_travail}"."{insee}_ilot_du_trou_t3"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t4";

CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t4" AS
SELECT t3.id, 
	   array_length(ARRAY_AGG(DISTINCT t.comptecomm1), 1) AS nb_liste_ncc,
	   ARRAY_AGG(DISTINCT t.comptecomm1 ORDER BY t.comptecomm1) AS liste_ncc,   
       ST_SetSRID(                                                              
          ST_Multi(                                                             
             ST_CollectionExtract(                                              
                ST_MakeValid(t3.geom),                                          
             3)),                                                               
       2154) AS geom                                                            
FROM "{schema_travail}"."{insee}_ilot_du_trou_t3" t3
INNER JOIN "{schema_travail}"."{insee}_tampon_ihu" t
ON ST_Within(ST_PointOnSurface(t3.geom), t.geom)
INNER JOIN "{schema_travail}"."{insee}_trou5" tr5
ON ST_Intersects(t3.geom, tr5.geom)
AND t.comptecomm1 = ANY(tr5.liste_trou_ncc_vis)

GROUP BY t3.id, t3.geom;

DELETE FROM "{schema_travail}"."{insee}_ilot_du_trou_t4"                         
WHERE geom IS NULL 
OR ST_IsEmpty(geom)
OR NOT ST_IsValid(geom)
OR liste_ncc IS NULL
OR array_length(liste_ncc, 1) IS NULL;

CREATE INDEX idx_{insee}_ilot_du_trou_t4_geom                                
ON "{schema_travail}"."{insee}_ilot_du_trou_t4"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t5";

CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t5" ( 
    id SERIAL PRIMARY KEY,                                             
    liste_ncc TEXT[],                                                  
    geom geometry(MultiPolygon, 2154)                                  
);

INSERT INTO "{schema_travail}"."{insee}_ilot_du_trou_t5" (liste_ncc, geom)
SELECT it4.liste_ncc,                                                  
       ST_SetSRID(                                                     
          ST_CollectionExtract(                                        
             ST_MakeValid(                                             
                ST_Union(it4.geom)),                                   
             3),
       2154) AS geom                                                   
FROM "{schema_travail}"."{insee}_ilot_du_trou_t4" it4                       
WHERE ST_Area(it4.geom) > 0.001                                        
GROUP BY it4.liste_ncc;                                                

DELETE FROM "{schema_travail}"."{insee}_ilot_du_trou_t5"
WHERE geom IS NULL 
OR ST_IsEmpty(geom)
OR NOT ST_IsValid(geom)
OR liste_ncc IS NULL
OR array_length(liste_ncc, 1) IS NULL;

CREATE INDEX idx_{insee}_ilot_du_trou_t5_geom
ON "{schema_travail}"."{insee}_ilot_du_trou_t5"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t6";                     

CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t6" AS                           
    SELECT
		id,
		liste_ncc,
 		 ST_SimplifyPreserveTopology(
			ST_Buffer(geom, 0.5)
			,1) AS geom
   FROM "{schema_travail}"."{insee}_ilot_du_trou_t5";

CREATE INDEX idx_{insee}_ilot_du_trou_t6_geom                                
ON "{schema_travail}"."{insee}_ilot_du_trou_t6"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t7";

CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t7" AS
WITH


central_pts AS (
    SELECT
        id AS idilotrou,
		liste_ncc,
		(ST_DumpPoints(
			it6.geom)).geom AS pt
    FROM "{schema_travail}"."{insee}_ilot_du_trou_t6" it6
),

b_polys AS (
    SELECT p.comptecommunal, p.idu, central_pts.idilotrou, 
	 ST_SetSRID(                                                  
		ST_CoverageSimplify(p.geom, 2) OVER ()                    
		,2154) AS covgeom,                                        
		p.geom
    FROM "{schema_travail}"."{insee}_parcelle_batie" p
	INNER JOIN central_pts
	ON p.comptecommunal = ANY(central_pts.liste_ncc)              
),
b_pts AS (
    SELECT
        b.idilotrou,
		b.comptecommunal,
		b.idu AS bid,
        ST_SetSRID((ST_DumpPoints(b.covgeom)).geom, 2154) AS pt
    FROM b_polys b
),

lignes_visee AS (
    SELECT DISTINCT
        
		b.idilotrou,
		b.bid,
        b.comptecommunal,
		ST_SetSRID(                                               
			ST_MakeLine(a.pt, b.pt)
			, 2154) AS line_geom
    FROM central_pts a
    JOIN b_pts b
	ON b.idilotrou = a.idilotrou
	AND ST_Distance(a.pt, b.pt) < 50
),

lignes_visee_directes AS (
	SELECT  lv.idilotrou, lv.bid, lv.comptecommunal, lv.line_geom AS geom
    FROM lignes_visee lv
	
    WHERE NOT EXISTS (
        SELECT 1
        FROM b_polys bp
        WHERE bp.idilotrou = lv.idilotrou
        AND bp.idu != lv.bid
        AND ST_Crosses(lv.line_geom, bp.geom)      
	)                                              
),

parcelle_visible_du_trou AS (
	SELECT lvd.idilotrou, lvd.bid 
    FROM lignes_visee_directes lvd
	GROUP BY lvd.bid, lvd.idilotrou  
),

liste_parc_visible AS (
	SELECT 
	idilotrou, 
	array_agg(bid ORDER BY bid) AS liste_parc_vis 
	FROM parcelle_visible_du_trou
	GROUP BY idilotrou
)
SELECT
lpv.idilotrou,
array_length(ilt5.liste_ncc, 1) AS nb_liste_ncc,
array_length(lpv.liste_parc_vis, 1) AS nb_liste_parc_visible,
ilt5.liste_ncc,
lpv.liste_parc_vis,
ilt5.geom
FROM "{schema_travail}"."{insee}_ilot_du_trou_t5" ilt5
JOIN liste_parc_visible lpv
ON ilt5.id = lpv.idilotrou;

CREATE INDEX idx_{insee}_ilot_du_trou_t7_geom                                
ON "{schema_travail}"."{insee}_ilot_du_trou_t7"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_du_trou_t8";

CREATE TABLE "{schema_travail}"."{insee}_ilot_du_trou_t8" AS
WITH
filtrage AS (
	SELECT
	ilt7.idilotrou,
	ilt7.nb_liste_ncc,
	ilt7.nb_liste_parc_visible,
	ilt7.liste_ncc,
	ilt7.liste_parc_vis,
	ilt7.geom
	FROM "{schema_travail}"."{insee}_ilot_du_trou_t7" ilt7
	WHERE ilt7.nb_liste_parc_visible = 1
)
SELECT 
	filtrage.idilotrou,
	pbat.comptecommunal,
	filtrage.geom
FROM filtrage
LEFT JOIN "{schema_travail}"."{insee}_parcelle_batie" pbat
ON filtrage.liste_parc_vis[1] = pbat.idu;

CREATE INDEX idx_{insee}_ilot_du_trou_t8_geom                                
ON "{schema_travail}"."{insee}_ilot_du_trou_t8"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_final";

CREATE TABLE "{schema_travail}"."{insee}_ilot_final" AS
	SELECT
	ilt7.idilotrou,
	ilt7.nb_liste_ncc,
	ilt7.nb_liste_parc_visible,
	ilt7.liste_ncc,
	ilt7.liste_parc_vis,
	ilt7.geom
	FROM "{schema_travail}"."{insee}_ilot_du_trou_t7" ilt7
	WHERE ilt7.nb_liste_parc_visible > 1;

CREATE INDEX idx_{insee}_ilot_final_geom                                
ON "{schema_travail}"."{insee}_ilot_final"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_voronoi_t1";

CREATE TABLE "{schema_travail}"."{insee}_ilot_voronoi_t1" AS
WITH
jointure1 AS (          
	SELECT
	ilfi.idilotrou,
	p.comptecommunal,
	p.idu,
	ilfi.geom AS ilotrou_geom
	
	FROM "{schema_travail}"."{insee}_ilot_final" ilfi
	INNER JOIN "{schema_travail}"."{insee}_parcelle_batie" p
	ON p.idu = ANY(ilfi.liste_parc_vis)
	ORDER BY ilfi.idilotrou, p.comptecommunal
),
jointure2 AS (           
	SELECT
	jt1.idilotrou,
	jt1.comptecommunal,
	jt1.idu,
	jt1.ilotrou_geom,
	pi.geom AS pt_interpol_geom
	FROM jointure1 jt1
	LEFT JOIN "{schema_travail}"."{insee}_pt_interpol" pi
	ON pi.idu = jt1.idu
	ORDER BY jt1.idilotrou, jt1.comptecommunal, jt1.idu
),
regroup1 AS(           
	SELECT
	jt2.idilotrou,
	jt2.comptecommunal,
	jt2.ilotrou_geom,
	ST_Union(pt_interpol_geom) AS geom
	FROM jointure2 jt2
	GROUP BY jt2.idilotrou, jt2.comptecommunal, jt2.ilotrou_geom
	ORDER BY jt2.idilotrou, jt2.comptecommunal
),
voro1 AS (
SELECT 
    regroup1.idilotrou,                               
	regroup1.ilotrou_geom,
    ST_SetSRID(                                       
      ST_Multi(                                       
	   ST_MakeValid(
        (ST_DUMP(                                     
          ST_VoronoiPolygons(                         
            ST_Collect(regroup1.geom),                       
            0,                                        
            ST_Envelope(regroup1.ilotrou_geom)))                  
        ).geom                                        
      ))
    ,2154) AS geom                                    
FROM regroup1                                         
WHERE regroup1.geom IS NOT NULL                       

GROUP BY idilotrou,	regroup1.ilotrou_geom             
)
SELECT DISTINCT
voro1.idilotrou,
pi.comptecommunal,
voro1.geom
FROM voro1
INNER JOIN "{schema_travail}"."{insee}_ilot_final" ilfi
ON voro1.idilotrou = ilfi.idilotrou
INNER JOIN "{schema_travail}"."{insee}_pt_interpol" pi
ON pi.idu = ANY(ilfi.liste_parc_vis)
AND ST_Intersects(pi.geom, voro1.geom);


CREATE INDEX idx_{insee}_ilot_voronoi_t1_geom
ON "{schema_travail}"."{insee}_ilot_voronoi_t1"
USING gist (geom);  



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_voronoi_t2";          

CREATE TABLE "{schema_travail}"."{insee}_ilot_voronoi_t2" AS                     
SELECT iv2.idilotrou,                                                                
       iv2.comptecommunal,                                                    
       ST_SetSRID(                                                            
          ST_CollectionExtract(                                               
             ST_MakeValid(                                                    
                ST_Union(iv2.geom)),                                          
             3),
        2154) AS geom                                                         
FROM "{schema_travail}"."{insee}_ilot_voronoi_t1" iv2                              
GROUP BY iv2.idilotrou, iv2.comptecommunal;                                          

DELETE FROM "{schema_travail}"."{insee}_ilot_voronoi_t2"                   
WHERE geom IS NULL                                                    
OR ST_IsEmpty(geom)                                               
OR NOT ST_IsValid(geom);                                          

CREATE INDEX idx_{insee}_ilot_voronoi_t2_geom                           
ON "{schema_travail}"."{insee}_ilot_voronoi_t2"                             
USING gist (geom);                                                   



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_voronoi_t3";

CREATE TABLE "{schema_travail}"."{insee}_ilot_voronoi_t3" AS
SELECT iv2.idilotrou,                                                              
       iv2.comptecommunal,                                                  
       ST_SetSRID(                                                          
          ST_CollectionExtract(                                             
             ST_MakeValid(                                                  
                ST_Intersection(                                            
                   ST_MakeValid(ilfi.geom),                                 
                   ST_MakeValid(iv2.geom))),                                
          3), 
       2154) AS geom                                                        
FROM "{schema_travail}"."{insee}_ilot_final" ilfi                               
INNER JOIN "{schema_travail}"."{insee}_ilot_voronoi_t2" iv2                      
ON ilfi.idilotrou = iv2.idilotrou                                                         
AND ST_Intersects(ilfi.geom, iv2.geom);                                     

DELETE FROM "{schema_travail}"."{insee}_ilot_voronoi_t3"
WHERE geom IS NULL 
OR ST_IsEmpty(geom)
OR NOT ST_IsValid(geom);

CREATE INDEX idx_{insee}_ilot_voronoi_t3_geom
ON "{schema_travail}"."{insee}_ilot_voronoi_t3"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_ilot_voronoi_rg";

CREATE TABLE "{schema_travail}"."{insee}_ilot_voronoi_rg" AS
SELECT iv3.comptecommunal,                                                  
       ST_SetSRID(                                                          
          ST_CollectionExtract(                                             
             ST_MakeValid(                                                  
                ST_Union(iv3.geom)),                                        
          3), 
       2154) AS geom                                                        
FROM "{schema_travail}"."{insee}_ilot_voronoi_t3" iv3                            
GROUP BY iv3.comptecommunal;                                                

DELETE FROM "{schema_travail}"."{insee}_ilot_voronoi_rg"
WHERE geom IS NULL 
OR ST_IsEmpty(geom)
OR NOT ST_IsValid(geom);

CREATE INDEX idx_{insee}_ilot_voronoi_rg_geom
ON "{schema_travail}"."{insee}_ilot_voronoi_rg"
USING gist (geom);



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result2";                   

CREATE TABLE "{schema_travail}"."{insee}_result2" AS                             
WITH 
union_all AS (                                           
	SELECT 
		r1.comptecommunal,                               
		ST_SetSRID(                                      
			ST_CollectionExtract(                        
				ST_MakeValid(r1.geom),                   
			3),
		2154) AS geom                                    
	FROM "{schema_travail}"."{insee}_result1" r1              
	WHERE geom IS NOT NULL                               
	AND NOT ST_IsEmpty(geom)                             
    
	UNION ALL                                            
    
	SELECT 
		comptecommunal,                                  
		geom                                 
	FROM "{schema_travail}"."{insee}_trou6"                   
	WHERE geom IS NOT NULL                               
	AND NOT ST_IsEmpty(geom)                             
    
	UNION ALL                                            

    SELECT 
		comptecommunal,                                  
	    geom                             
    FROM "{schema_travail}"."{insee}_ilot_du_trou_t1_abs"     
    
	UNION ALL                                            
   
	SELECT
		comptecommunal,                                  
		geom                                 
	FROM "{schema_travail}"."{insee}_ilot_du_trou_t8"         
	WHERE geom IS NOT NULL                               
	AND NOT ST_IsEmpty(geom)                             
    
    UNION ALL                                            
    
    SELECT ivrg.comptecommunal,                          
	    ST_SetSRID(                                      
            ST_CollectionExtract(                        
                ST_MakeValid(ivrg.geom),                 
			    3),
            2154) AS geom                                
    FROM "{schema_travail}"."{insee}_ilot_voronoi_rg" ivrg    
    WHERE geom IS NOT NULL                               
    AND NOT ST_IsEmpty(geom)                             
)
SELECT ua.comptecommunal,                                
       ST_SetSRID(                                       
          ST_CollectionExtract(                          
             ST_MakeValid(                               
                ST_UnaryUnion(                           
				   ST_Collect(geom))),                   
             3),
          2154) AS geom                                  
FROM union_all ua                                        
GROUP BY ua.comptecommunal;                              

DELETE FROM "{schema_travail}"."{insee}_result2"                            
WHERE geom IS NULL                                                      
OR ST_IsEmpty(geom)                                                 
OR NOT ST_IsValid(geom);                                            

CREATE INDEX idx_{insee}_result2_geom                                  
ON "{schema_travail}"."{insee}_result2"                                    
USING gist (geom);                                                 



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result2_corr1";

CREATE TABLE "{schema_travail}"."{insee}_result2_corr1" AS
WITH 



epine_externe AS (
	SELECT r2.comptecommunal,                         
        ST_SetSRID(                                   
		  ST_Multi(                                   
			ST_CollectionExtract(                     
  			  ST_MakeValid(
   				ST_Snap(                              
     			  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  r2.geom, 
					  -0.0001,                        
					  'join=mitre mitre_limit=5.0'),  
					  0.0003),			              
				  r2.geom,
                  0.0006)),3)),                       
		  2154) AS geom                               
    FROM "{schema_travail}"."{insee}_result2" r2           
),

epine_interne AS (
	SELECT epext.comptecommunal,                      
        ST_SetSRID(                                   
		  ST_Multi(                                   
			ST_CollectionExtract(                     
   			  ST_MakeValid(
   				ST_Snap(                              
     			  ST_RemoveRepeatedPoints(
					ST_Buffer(
					  epext.geom, 
					  0.0001,                         
					  'join=mitre mitre_limit=5.0'),  
					  0.0003),			              
				  r2.geom,
                  0.0006)),3)),                       
		  2154) AS geom                               
    FROM epine_externe epext                          
	JOIN "{schema_travail}"."{insee}_result2" r2
	ON epext.comptecommunal = r2.comptecommunal
)

SELECT epint.comptecommunal,                          
       ST_SetSRID(                                    
          ST_Multi(                                   
			 ST_CollectionExtract(                    
   				ST_MakeValid(epint.geom),             
			 3)),
	    2154) AS geom                                 
FROM epine_interne epint;                             

CREATE INDEX idx_{insee}_result2_corr1_geom 
ON "{schema_travail}"."{insee}_result2_corr1" 
USING gist (geom); 



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result3";                 

CREATE TABLE "{schema_travail}"."{insee}_result3" AS                         
SELECT r2c1.comptecommunal,                                 
       ST_SetSRID(                                          
          ST_CollectionExtract(                             
             ST_MakeValid(                                  
                ST_Intersection(                            
                   o.geom,                                  
                   r2c1.geom)),                             
             3), 
       2154) AS geom                                        
FROM "{schema_travail}"."{insee}_result2_corr1" r2c1             
JOIN {SCHEMA_PUBLIC}.{TABLE_OLD200M} o                                       
ON ST_Intersects(r2c1.geom, o.geom);                        

DELETE FROM "{schema_travail}"."{insee}_result3"                            
WHERE geom IS NULL                                                     
OR ST_IsEmpty(geom)                                               
OR NOT ST_IsValid(geom);                                          

CREATE INDEX idx_{insee}_result3_geom                                   
ON "{schema_travail}"."{insee}_result3"                                   
USING gist (geom);                                                    



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_zold_eolien";

CREATE TABLE "{schema_travail}"."{insee}_zold_eolien" AS

WITH tampon_3m AS (
     SELECT eol.nom_parc,                                      
            ST_CollectionExtract(                              
               ST_MakeValid(                                   
                  ST_Buffer(eol.geom, 3)),                    
            3) AS geom                                         
     FROM {SCHEMA_PUBLIC}.{TABLE_EOLIEN} eol                             
), 

intersection_communes AS (
     SELECT t3m.nom_parc,                                      
            ST_CollectionExtract(                              
               ST_MakeValid(                                   
                  ST_Intersection(t3m.geom, c.geom)),          
            3) AS geom                                         
     FROM tampon_3m t3m                                       
     INNER JOIN {SCHEMA_CADASTRE}.geo_commune c                       
     ON ST_Intersects(t3m.geom, c.geom)                        
     WHERE  (c.geo_commune = '{code_commune}'                          
        OR (c.geo_commune 
	       IN (SELECT {TABLE_COMMUNE} 
               FROM "{schema_travail}"."{insee}_commune_adjacente") 
           AND ST_Intersects(
				  (SELECT ST_Union(geom) 
				   FROM "{schema_travail}"."{insee}_commune_buffer"), 
				   t3m.geom)))
),

intersection_old200m AS (
     SELECT ic.nom_parc,                                       
		    ST_CollectionExtract(                              
			   ST_MakeValid(                                   
				  ST_Intersection(ic.geom, old200.geom)),      
            3) AS geom                                                  
     FROM intersection_communes ic                             
     JOIN {SCHEMA_PUBLIC}.{TABLE_OLD200M} old200                                
     ON ST_Intersects(ic.geom, old200.geom)                    
),

intersection_cc AS (
     SELECT iold.nom_parc,                                     
            uf.comptecommunal,                                 
            CASE
                
                WHEN uf.geom IS NOT NULL THEN
                     ST_SetSRID(                               
                        ST_CollectionExtract(                  
                           ST_MakeValid(                       
                              ST_Intersection(                 
                                 ST_MakeValid(iold.geom),      
                                 ST_MakeValid(uf.geom))),      
                           3),                                 
                     2154)                                     
                
                
                ELSE ST_SetSRID(iold.geom, 2154)               
            END AS geom                                        
     FROM intersection_old200m iold                            
     LEFT JOIN {SCHEMA_CADASTRE}.{TABLE_UF} uf                
     ON ST_Intersects(iold.geom, uf.geom)                      
),

tampon_60m AS (
     SELECT icc.nom_parc,                                      
            icc.comptecommunal,                                
            ST_CollectionExtract(                              
               ST_MakeValid(                                   
                  ST_Buffer(icc.geom, 50)),                    
               3) AS geom                                      
     FROM intersection_cc icc                                  
)

SELECT t60.nom_parc,                                           
       t60.comptecommunal,                                     
       ST_SetSRID(                                             
          ST_CollectionExtract(                                
             ST_MakeValid(                                     
                ST_Union(t60.geom)),                           
             3),                                               
	   2154) AS geom
FROM tampon_60m t60                                            
GROUP BY t60.nom_parc, t60.comptecommunal;                     

CREATE INDEX idx_{insee}_zold_eolien_geom                     
ON "{schema_travail}"."{insee}_zold_eolien"                      
USING gist (geom);                    



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result4";

CREATE TABLE "{schema_travail}"."{insee}_result4" AS

WITH bati_a_exclure AS (
     SELECT ST_MakeValid(b200cc.geom) AS geom                             
     FROM "{schema_travail}"."{insee}_bati200_cc" b200cc                       
     JOIN "{schema_travail}"."{insee}_zold_eolien" zeol                        
     ON ST_Intersects(b200cc.geom, zeol.geom)                             
),

result3_polygones AS (
     SELECT r3.comptecommunal,                                            
            (ST_Dump(r3.geom)).geom AS geom                               
     FROM "{schema_travail}"."{insee}_result3" r3                              
),

result3_nettoye AS (
     SELECT r3p.*                                                         
     FROM result3_polygones r3p                                           
     LEFT JOIN bati_a_exclure b                                           
     ON ST_DWithin(r3p.geom, b.geom, 30)                                  
     WHERE b.geom IS NULL                                                 
),

fusion_zold_result3 AS (
     
     SELECT r3n.comptecommunal AS comptecommunal,                         
            ST_CollectionExtract(                                         
               ST_MakeValid(r3n.geom),                                    
               3) AS geom                                                 
     FROM result3_nettoye r3n                                             

     UNION ALL                                                            

     
     SELECT CONCAT('{code_commune}_', zeol.nom_parc) AS comptecommunal,           
            ST_CollectionExtract(                                         
               ST_MakeValid(zeol.geom),                                   
               3) AS geom                                                 
     FROM "{schema_travail}"."{insee}_zold_eolien" zeol                        
),

association_bati AS (
     SELECT DISTINCT ON (r3p.geom)                                        
            zeol.nom_parc AS comptecommunal,                              
            ST_MakeValid(r3p.geom) AS geom                                
     FROM result3_polygones r3p                                           
     JOIN "{schema_travail}"."{insee}_zold_eolien" zeol                        
     ON ST_DWithin(r3p.geom, zeol.geom, 250)                              
),

fusion_finale AS (
     SELECT COALESCE(assob.comptecommunal, fzr3.comptecommunal) AS comptecommunal, 
            ST_MakeValid(fzr3.geom) AS geom                               
     FROM fusion_zold_result3 fzr3                                        
     LEFT JOIN association_bati assob                                     
     ON ST_Equals(fzr3.geom, assob.geom)                                  
)

SELECT comptecommunal,                                                    
       ST_CollectionExtract(                                              
          ST_MakeValid(                                                   
             ST_Union(geom)),                                             
          3) AS geom                                                      
FROM fusion_finale                                                        
GROUP BY comptecommunal;                                                  

ALTER TABLE "{schema_travail}"."{insee}_result4"
ALTER COLUMN geom 
TYPE geometry(MULTIPOLYGON, 2154)
USING ST_SetSRID(geom, 2154);

CREATE INDEX idx_{insee}_result4_geom                                       
ON "{schema_travail}"."{insee}_result4"                                        
USING gist (geom);                       



DROP TABLE IF EXISTS "{schema_travail}"."{insee}_result5";  

CREATE TABLE "{schema_travail}"."{insee}_result5" AS

WITH poly_simples AS (
	 SELECT r4.comptecommunal,                                   
		    (ST_Dump(r4.geom)).path AS path1,                    
		    (ST_Dump(r4.geom)).geom AS geom                      
	 FROM "{schema_travail}"."{insee}_result4" r4                     
),

rings_poly_simples AS (
	 SELECT ps.comptecommunal,                                   
		    ps.path1,                                            
		    ((ST_DumpRings(ps.geom)).path)[1] AS ring_index,     
		    ST_Area((ST_DumpRings(ps.geom)).geom) AS surface,    
		    (ST_DumpRings(ps.geom)).geom AS geom                 
	 FROM poly_simples ps
),

macro_anneaux AS (
	 SELECT rps.comptecommunal,                                  
		    rps.path1,                                           
		    rps.ring_index,                                      
		    rps.surface,                                         
		    ST_ExteriorRing(rps.geom) AS geom                    
	 FROM rings_poly_simples rps
	 WHERE rps.surface > 1                                       
),

reconstruction_pg AS (
	 SELECT ma.comptecommunal,                                   
		    ma.path1,                                            
            CASE 
			    
			    WHEN COUNT(*) FILTER (WHERE ma.ring_index > 0) > 0 
			    THEN ST_SetSRID(                                     
					    ST_CollectionExtract(                        
						   ST_MakeValid(                             
							  ST_MakePolygon(                        
								 MAX(ma.geom) 
								 FILTER (WHERE ma.ring_index = 0),   
								 ARRAY_AGG(ma.geom) 
								 FILTER (WHERE ma.ring_index > 0))), 
					       3),
				     2154)

			    
			    ELSE ST_SetSRID(                                     
					    ST_CollectionExtract(                        
						   ST_MakeValid(                             
							  ST_MakePolygon(                        
								 MAX(ma.geom) 
								 FILTER (WHERE ma.ring_index = 0))),
						   3),
				     2154)
					 
		    END AS geom                                              

	 FROM macro_anneaux ma                                           
	 GROUP BY ma.comptecommunal, ma.path1                            
),

resultat_final AS (
	 SELECT rp.comptecommunal,                                       
		    ST_SetSRID(                                              
			   ST_Multi(                                             
				  ST_CollectionExtract(
					 ST_MakeValid(
					    ST_Union(rp.geom)),                          
					 3)),
		    2154) AS geom                                            
	 FROM reconstruction_pg rp
	 GROUP BY rp.comptecommunal
)

SELECT * 
FROM resultat_final;

CREATE INDEX idx_{insee}_result5_geom
ON "{schema_travail}"."{insee}_result5"
USING gist (geom);



DROP TABLE IF EXISTS "{SCHEMA_RESULTAT}"."{insee}_result_final";

CREATE TABLE "{SCHEMA_RESULTAT}"."{insee}_result_final" AS 
SELECT r5.comptecommunal,                                                               
       r5.geom                                                                          
FROM "{schema_travail}"."{insee}_result5" r5                                                 
WHERE LEFT(r5.comptecommunal, 6) = '{code_commune}';                                            
                                                                                        
ALTER TABLE "{SCHEMA_RESULTAT}"."{insee}_result_final"
ALTER COLUMN geom 
TYPE geometry(MULTIPOLYGON, 2154)
USING ST_SetSRID(geom, 2154);

CREATE INDEX idx_{insee}_result_final_geom
ON "{SCHEMA_RESULTAT}"."{insee}_result_final"
USING gist (geom);



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