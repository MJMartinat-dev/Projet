"""
MODULE_2_sql_to_python.py
    à partir d'un fichier d'entrée MODULE_2_OLD50m_v2.x.sql (calcul OLD sur une commune),
    génère le script python MODULE_2_OLD50m_v2.x.py pour exécution sur l'ensemble d'un département
Auteur : Frédéric Sarret
Objectif : Calculer les zones d’obligation légale de débroussaillement (OLD) a 50m a l'échelle départementale
Paramétrages :
    Ligne 136           numéro du département
    Lignes 159 à 163    paramètres de connexion à la base PostgreSQL
    Lignes 300 et 301   chemin et nom des fichiers d'entrée et de sortie
"""

import re
from pathlib import Path



def build_sql_template(sql_text):
    """
    Transforme le code SQL du MODULE_2 en SQL template pour intégration complète dans le script python.
    Remplacements inclus :
    - Schémas fixes
    - Tables
    - geo_commune sauf lorsqu'il est précédé d'un point
    - Littéraux 26xxx et 260xxx
    Suppression des lignes commençant par COMMIT
    Suppression des commentaires SQL (et des caractères bloquants)
    Suppression de lignes pour ne pas avoir plus de 3 lignes vides d'affilée
    """

    # =====================================================================
    # PASSAGE 1 : REMPLACEMENT DES SCHÉMAS
    # =====================================================================
    schema_map_fixed = {
        r'\br_bdtopo\b': '{SCHEMA_BDTOPO}',
        r'\br_cadastre\b': '{SCHEMA_CADASTRE}',
        r'\bpublic\b': '{SCHEMA_PUBLIC}',
        r'\b26xxx_wold50m\b': '{schema_travail}',
        r'\b26_old50m_parcelle\b': '{SCHEMA_PARCELLE}',
        r'\b26_old50m_bati\b': '{SCHEMA_BATI}',
        r'\b26_old50m_resultat\b': '{SCHEMA_RESULTAT}',
    }

    for pat, repl in schema_map_fixed.items():
        sql_text = re.sub(pat, repl, sql_text, flags=re.IGNORECASE)

    # =====================================================================
    # PASSAGE 2 : REMPLACEMENT DES TABLES
    # =====================================================================
    table_map = {
        r'\bparcelle_info\b': '{TABLE_PARCELLE}',
        r'\bgeo_unite_fonciere\b': '{TABLE_UF}',
        r'\bbatiment\b': '{TABLE_BATI}',
        r'\bcimetiere\b': '{TABLE_CIMETIERE}',
        r'\bzone_d_activite_ou_d_interet\b': '{TABLE_INSTALLATION}',
        r'\b26_zonage_global\b': '{TABLE_ZONAGE}',
        r'\bold200m\b': '{TABLE_OLD200M}',
        r'\beolien_filtre\b': '{TABLE_EOLIEN}',
    }

    for pat, repl in table_map.items():
        sql_text = re.sub(pat, repl, sql_text, flags=re.IGNORECASE)

    # Remplacer geo_commune sauf lorsqu'il est précédé d'un point (conservation de l'attribut geocommune)
    sql_text = re.sub(
        r'(?<!\.)\bgeo_commune\b',
        '{TABLE_COMMUNE}',
        sql_text,
        flags=re.IGNORECASE
    )

    # =====================================================================
    # PASSAGE 3 : Littéraux dans les chaînes : '26xxx' → {insee}
    # =====================================================================
    sql_text = sql_text.replace("26xxx", "{insee}")

    # =====================================================================
    # PASSAGE 4 : Littéraux dans les chaînes : '260xxx' → '{code_commune}'
    # =====================================================================
    sql_text = sql_text.replace("260xxx", "{code_commune}")

    # =====================================================================
    # PASSAGE 5 : Suppression des lignes commençant par COMMIT
    # =====================================================================
    lines = sql_text.splitlines()
    lines = [line for line in lines if not line.lstrip().startswith("COMMIT")]
    sql_text = "\n".join(lines)

    # =====================================================================
    # PASSAGE 6 : Suppression des commentaires SQL (et des caractères bloquants)
    # =====================================================================
    lines = sql_text.splitlines()
    lines = [re.sub(r"--.*$", "", line) for line in lines]
    sql_text = "\n".join(lines)

    # =====================================================================
    # PASSAGE 7 : Suppression de lignes pour ne pas avoir plus de 3 lignes vides d'affilée
    # =====================================================================
    lines = sql_text.splitlines()
    cleaned_lines = []
    empty_lines_count = 0
    for line in lines:
        if line.strip() == "":
            empty_lines_count += 1
            if empty_lines_count <= 3:
                cleaned_lines.append(line)
        else:
            empty_lines_count = 0
            cleaned_lines.append(line)
    sql_text = "\n".join(cleaned_lines)

    return sql_text



# =============================================================================
# PREPARATION DU SCRIPT PYTHON COMPLET 
# =============================================================================
    """
    Chaine de texte pour la construction du script python MODULE_2_OLD50m_v2.x.py
    avec la partie MODULE_SQL définie comme une variable =  chaine_sql_module_2 
    """

preparation_contenu = r'''# -*- coding: utf-8 -*-
"""
MODULE_2_OLD50m_v2.x.py — Exécution automatisée du module OLD50m pour le département de la Drôme
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

LOG_FILE = r"C:\Users\SARRETFR\Documents\WOLD50M\log\log_outil_old50m.log"
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
chaine_sql_module_2
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

'''

# =============================================================================
# GÉNÉRATION DU SCRIPT PYTHON GLOBAL
# =============================================================================

if __name__ == "__main__":
    import sys
    input_file = r"d:\chemin\complet\vers\MODULE_2_OLD50m_v2.x.sql"
    output_file = r"d:\chemin\complet\vers\MODULE_2_OLD50m_v2.x.py"
    if len(sys.argv) >= 2:
        input_file = sys.argv[1]
    if len(sys.argv) >= 3:
        output_file = sys.argv[2]
    with open(input_file, "r", encoding="utf-8") as f:
        raw_sql = f.read()
    var_chaine_sql_module_2 = build_sql_template(raw_sql)
    code_final = preparation_contenu.replace(
        "chaine_sql_module_2",
        var_chaine_sql_module_2.strip()
    )
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(code_final)
    print(f"✔ Script python global généré avec succès : {output_file}")