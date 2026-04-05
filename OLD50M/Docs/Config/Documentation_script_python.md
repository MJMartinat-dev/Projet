# MODULE_2_OLD50m_v2.1 — Calcul automatisé des zones OLD 50 m

**Auteur(s)** : Marie-Jeanne Martinat, Frédéric Sarret  
**Année** : 2025  
**Description** : Script Python embarquant du SQL (PostgreSQL/PostGIS) pour générer, à l’échelle départementale 
(paramètre `DEPT`, ex. 26 — Drôme), les couches nécessaires au calcul des obligations légales de débroussaillement 
(OLD) à 50 m : extraction parcellaire, unités foncières, sélection/fusion des entités bâties, rattachement aux 
comptes communaux, tampons 50 m et gestion des intersections/zonages.


## Installation de Python et Visual Studio Code
### Installation de Python
#### Télécharger la dernière version stable depuis :  
-> [https://www.python.org/downloads/](https://www.python.org/downloads/)

#### Lors de l’installation :
- Cocher **"Add Python to PATH"**.
- Lancer l’installation pour tous les utilisateurs (si possible).

#### Vérifier l’installation dans un terminal :


		   ```bash
		   python --version
		   ```


ou  


		   ```bash
		   py --version
		   ```


### Installation de Visual Studio Code
#### Télécharger depuis :  
-> [https://code.visualstudio.com/](https://code.visualstudio.com/)

#### Installer les extensions recommandées :
- **Python** (éditeur et exécution de scripts)
- **SQLTools** *(optionnel)* — pour la visualisation des requêtes SQL  
- **PostgreSQL** *(optionnel)* — pour interagir directement avec la base

#### Ouvrir le projet :
- Menu **Fichier → Ouvrir un dossier** → sélectionner le dossier contenant le script  
- Créer un nouveau terminal intégré (**Ctrl + `**) pour exécuter les commandes Python



## Exécution du module Python
### Ouvrir le projet dans VS Code
- Lancer **Visual Studio Code**.  
- Menu : **Fichier → Ouvrir un dossier** → sélectionner le dossier contenant `MODULE_2_OLD50m_v2.2.py`.  
- Ouvrir le terminal intégré :  

		   **Ctrl + `** (accent grave).



## Création de l’environnement virtuel Python
### Objectif
Isoler les dépendances du projet pour éviter les conflits entre librairies Python, tout en assurant la portabilité du module sur différents postes.

### Étapes
#### **Ouvrir un terminal** dans le dossier du projet (celui contenant `MODULE_2_OLD50m_v2.2.py`) :

		   ```bash
		   cd "chemin/vers/ton/projet"
		   ```

#### **Créer un environnement virtuel** nommé `venv` :

		   ```bash
		   python -m venv venv
		   ```

#### **Activer l’environnement virtuel** :
- **Sous Windows (PowerShell)** :

				 ```bash
				 venv\Scripts\Activate.ps1
				 ```

- **Sous Linux / macOS** :

				 ```bash
				 source venv/bin/activate
				 ```

#### Vérifier que l’environnement est actif :
- Le terminal affiche maintenant un préfixe `(venv)` avant la ligne de commande.
- Pour confirmer :

**Sous Windows (PowerShell)** :
				
					 ```bash
					 where python      
					 ```


**Sous Linux / macOS** :
				
					 ```bash
					 which python      
					 ```




## Installation des librairies Python (une par une avec proxy)
### Objectif
Installer les dépendances nécessaires à l’exécution du module `MODULE_2_OLD50m_v2.2.py` **dans l’environnement virtuel actif**, en passant par un proxy réseau.

### Librairies requises

| Librairie            | Description                                          |
|----------------------|------------------------------------------------------|
| **pandas**           | Manipulation et analyse de données tabulaires        |
| **logging**          | Gestion des journaux d’exécution (native à Python)   |
| **sqlalchemy**       | Interface haut niveau pour exécuter des requêtes SQL |
| **psycopg2-binary**  | Pilote PostgreSQL pour SQLAlchemy                    |



### Installation (avec proxy)
> Remplacer `http://user:password@proxy.mondomaine.fr:8080` par votre configuration réelle.

#### pandas

			```bash
			pip install pandas --proxy http://user:password@proxy.mondomaine.fr:8080
			```

#### logging

> Cette librairie est intégrée à Python, **aucune installation n’est nécessaire.**

#### sqlalchemy

			```bash
			pip install sqlalchemy --proxy http://user:password@proxy.mondomaine.fr:8080
			```

#### psycopg2-binary

			```bash
			pip install psycopg2-binary --proxy http://user:password@proxy.mondomaine.fr:8080
			```


### Vérification des installations

		```bash
		pip list
		```


Résultat attendu :
	
		```
		Package           Version
		-------------------------
		pandas            x.x.x
		SQLAlchemy        x.x.x
		psycopg2-binary   x.x.x
		```



## Modifications à apporter dans le code
### Objectif
Adapter le script `MODULE_2_OLD50m_v2.2.py` à votre environnement local avant exécution.  
Les ajustements concernent principalement la **connexion PostgreSQL**, le **chemin du fichier de logs**, et le **paramètre départemental**.

### Configuration de la base de données

Dans le code, repérer le bloc suivant :

		```python
		DB_CONFIG = {
			"host": "localhost",
			"port": "port",
			"dbname": "nom_database",
			"user": "nom_utilisateur",
			"password": "mdp_utilisateur"
		}
		```

Remplacez les valeurs selon votre configuration PostgreSQL locale ou distante :
		
		```python
		DB_CONFIG = {
			"host": "votre adresse",  # ou IP : 192.168.x.x
			"port": "votre port",
			"dbname": "nom de votre base de données",
			"user": "nom de votre rôle",
			"password": "mot de passe de votre rôle"
		}
		```


*Si vous utilisez une base sécurisée (SSL), ajoutez les paramètres nécessaires dans la chaîne de connexion SQLAlchemy.*

### Chemin du fichier de logs
Dans le code :
		

		```python
		LOG_FILE = r"C:\Users\NomUtilisateur\Documents\WOLD50M\log\log_outil_old50m.log"
		```


-> Adaptez ce chemin à votre arborescence en changeant NomUtilsateur par le vôtre.
		

### Département cible
Le script est paramétré pour le département **XX** :

		```python
		DEPT = 'XX'
		```

Modifiez cette valeur selon le code du département à traiter :

		```python
		DEPT = '83'  # Exemple : Var
		```

Les schémas et tables PostgreSQL seront automatiquement adaptés à cette valeur (`83_old50m_*`).

### Encodage et compatibilité PostgreSQL
La création du moteur SQLAlchemy utilise :

		```python
		engine = create_engine(
			f"postgresql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@"
			f"{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}?client_encoding=UTF8",
			future=True
		)
		```


*Ne pas modifier cette ligne sauf si votre base utilise un autre encodage (rare).*

### Configuration des schémas et des tables PostgreSQL
Adapter la configuration des **schémas** et **tables sources** du module `MODULE_2_OLD50m_v2.2.py` 
selon la structure réelle de votre base PostgreSQL/PostGIS.

#### Bloc concerné dans le code

			```python
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
			```


#### Signification des schémas

| Variable          | Description                                                                                  | Table source / résultat    |  
|-------------------|----------------------------------------------------------------------------------------------|----------------------------|
| `SCHEMA_BDTOPO`   | Schéma contenant les couches issues de la BD TOPO (bâtiments, cimetières, zones d’activités) | `r_bdtopo.batiment`        |
| `SCHEMA_CADASTRE` | Schéma issu du plugin **cadastre** (QGIS), contenant les parcelles et unités foncières       | `r_cadastre.parcelle_info` |
| `SCHEMA_PUBLIC`   | Schéma commun à plusieurs modules ou données partagées (OLD200m, etc.)                       | `public.old200m`           |
| `SCHEMA_PARCELLE` | Schéma de sortie pour les parcelles traitées dans le module OLD50m                           | `26_old50m_parcelle`       |
|                   |                              Ne pas modifier, conçu par le module 0                          |                            |
| `SCHEMA_BATI`     | Schéma de sortie des traitements sur les bâtiments                                           | `26_old50m_bati`           |
|                   |                              Ne pas modifier, conçu par le module 0                          |                            |
| `SCHEMA_RESULTAT` | Schéma final des résultats consolidés                                                        | `26_old50m_resultat`       |
|                   |                              Ne pas modifier, conçu par le module 0                          |                            |

> Les trois derniers schémas sont **dynamiques** : ils dépendent du code départemental (`DEPT`).

#### Signification des tables

| Variable              |Description                                                                                        | Table source / résultat        | 
|-----------------------|---------------------------------------------------------------------------------------------------|--------------------------------|
| `TABLE_COMMUNE`       | Contour des communes (table du cadastre)                                                          | `geo_commune`                  | 
| `TABLE_PARCELLE`      | Données cadastrales par parcelle                                                                  | `parcelle_info`                | 
| `TABLE_UF`            | Unités foncières (fusion des parcelles par propriétaire)                                          | `geo_unite_fonciere`           | 
| `TABLE_BATI`          | Bâtiments issus de la BD TOPO                                                                     | `batiment`                     |
| `TABLE_CIMETIERE`     | Couches des cimetières (BD TOPO)                                                                  | `cimetiere`                    |
| `TABLE_INSTALLATION`  | Installations diverses : campings, carrières, centrales PV, etc.                                  | `zone_d_activite_ou_d_interet` |
| `TABLE_ZONAGE`        | Couches de zonage urbain pour le département                                                      | `{DEPT}_zonage_global`         | 
| `TABLE_OLD200M`       | Zone tampon de 200 m autour des massifs forestiers                                                | `old200m`                      |
| `TABLE_EOLIEN`        | Données filtrées sur les éoliennes (si présentes)                                                 | `eolien_filtre`                |

#### À modifier selon votre base

- Si vos schémas portent d’autres noms (ex. `bdtopo_2025` ou `cadastre_v3`), adaptez directement :

			  ```python
			  SCHEMA_BDTOPO = 'bdtopo_2025'
			  SCHEMA_CADASTRE = 'cadastre_v3'
			  ```


- Si vos tables sources ont été renommées :

			  ```python
			  TABLE_PARCELLE = 'parcelles'
			  TABLE_BATI = 'bati_majic'
			  ```


- Si vos données **ne sont pas dans le schéma `public`**, ajustez les préfixes pour correspondre à votre structure PostgreSQL.


#### Bon à savoir
	Les schémas générés par le script (`*_old50m_*`) sont créés automatiquement à l’exécution.  
	Aucun besoin de les créer manuellement — ils seront écrasés et régénérés à chaque traitement.

## Lancer le script
Depuis le même terminal :

	```bash
	python MODULE_2_OLD50m_v2.1.py
	```
