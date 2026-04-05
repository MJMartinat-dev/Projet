-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                     BOITE A OUTILS                                          --
--                                                                                             --
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------


-----------          
-- BASES --
-----------

---- Sélectionner toutes les colonnes avec "SELECT *"
SELECT * 
FROM nom_table;

-- Explication :
-- SELECT * : Sélectionne toutes les colonnes de la table.
-- FROM nom_table : Spécifie la table à interroger.

-- Bonnes pratiques :
-- Éviter SELECT * sur de grandes bases de données.
-- Utiliser LIMIT pour contrôler la taille des résultats.
-- Analyser la requête avec EXPLAIN ANALYZE pour vérifier son efficacité.

----------

---- Sélectionner des valeurs uniques avec 'SELECT DISTINCT'
SELECT DISTINCT nom_colonne
FROM nom_table;

--Explication :
-- SELECT DISTINCT : Permet de sélectionner des valeurs uniques d'une ou plusieurs colonnes.
--                   Élimine les doublons dans les résultats de la requête.
--                   Utilisé pour simplifier les résultats et ne garder que les valeurs distinctes.

-- Bonnes pratiques
-- Utiliser SELECT DISTINCT pour nettoyer les résultats et éliminer les répétitions.
-- Ne pas utiliser DISTINCT sur des colonnes avec de nombreuses valeurs uniques, 
-- car cela peut avoir un impact sur les performances.
-- Privilégier des index sur les colonnes utilisées avec DISTINCT pour optimiser les requêtes.

-----------

---- Gérer les valeurs NULL avec 'SELECT COALESCE()'
SELECT COALESCE(expression1, expression2,...) AS resultat
FROM nom_table1
LEFT JOIN nom_table2 
ON nom_table1.nom_colonne1 = nom_table2.nom_colonne1;

-- Explication :
-- COALESCE(expression1, expression2, ...) : Retourne la première valeur non-NULL 
--                                           parmi les expressions passées en argument.
--                                           Utilisé pour remplacer les valeurs NULL 
--                                           par une autre valeur disponible dans une 
--                                           autre colonne ou table.
--Si expression1 est NULL, garde expression2 et vice-versa.

-- Bonnes pratiques
-- Utiliser COALESCE() pour remplacer des NULL et obtenir des valeurs par défaut. 
-- Optimiser les performances en indexant les colonnes fréquemment utilisées 
-- avec COALESCE().
-- Ne pas trop enchaîner d'expressions dans COALESCE() si possible, cela peut 
-- ralentir les requêtes complexes.

----------

---- Stocker plusieurs valeurs dans un tableau avec 'SELECT ARRAY()'
SELECT 
    ARRAY(
        SELECT nom_colonne
        FROM nom_table
        WHERE condition
        ORDER BY nom_colonne ASC
    ) AS tableau;


-- Explication :
-- ARRAY(...) : Regroupe plusieurs valeurs en un tableau (ARRAY[]).
-- ORDER BY colonne ASC : Trie les valeurs avant de les stocker dans le tableau.
-- Utilisé pour regrouper des valeurs associées à une entité unique.

-- Bonnes pratiques
-- Utiliser ORDER BY dans ARRAY() pour s'assurer d’un ordre logique des valeurs.
-- Limiter la taille du tableau avec LIMIT si nécessaire pour éviter des dépassements mémoire.
-- Vérifier le contenu avec unnest() pour extraire les valeurs d’un tableau stocké.

----------

---- Agréger des géométries et les trier avec 'SELECT ARRAY_AGG(%ORDER BY%)'
SELECT (ARRAY_AGG(geom ORDER BY distance ASC))[1] AS geom
FROM nom_table;

--  Explication :
-- ARRAY_AGG(geom ORDER BY distance ASC) : Crée un tableau (array) de géométries 
--                                         en les triant par distance croissante.
-- [1] : Sélectionne le premier élément du tableau trié 
--       (c'est-à-dire la géométrie la plus proche si triée par distance).
-- Utilisé pour récupérer la géométrie la plus proche d’une autre géométrie en 
-- fonction d'une distance.

-- Bonnes pratiques
-- Utiliser ARRAY_AGG() pour agréger et trier les résultats lorsque vous avez 
-- besoin d’une liste ordonnée.
-- S'assurer que l'ordre de tri est correctement défini (par exemple, avec ST_Distance() 
-- ou d'autres critères géospatiaux).
-- Optimiser les performances avec des index spatiaux GIST sur les colonnes géométriques.

----------

----  Renommer une colonne ou une expression avec 'AS'
SELECT identifiant AS id, 
       nom_zone AS zone, 
	   geom AS geom
FROM nom_table ;

-- Explication :
-- geom AS geom : Renomme le résultat de geom en geom dans les résultats de la requête.
-- Cela améliore la lisibilité des résultats sans modifier la structure de la table.

-- Bonnes pratiques :
-- Utiliser des noms clairs et explicites pour les alias.
-- Éviter les espaces dans les alias (utiliser _ ou des guillemets doubles si nécessaire, ex. : "Nom Complet").
-- Préférer les alias courts et significatifs pour améliorer la lisibilité.

----------

---- Sélectionner des données avec 'FROM'
SELECT identifiant, 
       nom_zone, 
	   geom AS geom
FROM nom_table;

-- Explication :
-- FROM nom_table: Spécifie la table nom_table comme source des données pour la requête.

-- Bonnes pratiques :
-- Limiter le nombre de résultats avec LIMIT si la table contient beaucoup de données.
-- Utiliser WHERE pour filtrer les données et améliorer les performances.
-- Indexer les colonnes fréquemment utilisées pour accélérer les requêtes.

----------

---- Trier les résultats avec 'ORDER BY'
SELECT colonne1, colonne2
FROM nom_table
ORDER BY colonne1 ASC;

-- Explication :
-- ORDER BY colonne1 ASC : Trie les résultats par ordre croissant (ASC par défaut).
-- ORDER BY colonne1 DESC : Trie les résultats par ordre décroissant.

-- Bonnes pratiques
-- Utiliser ORDER BY pour organiser les résultats avant affichage ou agrégation.
-- Privilégier des index sur les colonnes triées pour optimiser les performances.
-- Combiner ORDER BY avec LIMIT pour récupérer uniquement les premiers résultats.

----------

---- Combiner plusieurs conditions avec 'AND'
SELECT identifiant, 
       nom_zone, 
	   geom AS geom
FROM nom_table
WHERE niveau_risque > 3 
AND statut = 'Actif';

-- Explication :
-- WHERE niveau_risque > 3 AND statut = 'Actif' : Sélectionne uniquement les entités de la nom_table 
--                                                ayant un niveau supérieur à 3 et un statut actif.
-- AND : Combine plusieurs conditions qui doivent toutes être vraies pour que l'enregistrement 
--       soit sélectionné.

-- Bonnes pratiques :
-- Indexer les colonnes utilisées dans AND (niveau_risque, statut) pour améliorer les performances.
-- Éviter d'enchaîner trop de conditions AND sans nécessité, car cela peut ralentir la requête.
-- Utiliser des parenthèses ( ) pour structurer les conditions complexes et éviter les ambiguïtés.

----------

---- Tester plusieurs conditions alternatives avec 'OR'
SELECT identifiant, 
       nom_zone, 
	   geom AS geom
FROM nom_table
WHERE niveau_risque > 3 
OR statut = 'Actif';

-- Explication :
-- WHERE niveau_risque > 3 OR statut = 'Actif' : Sélectionne les entités de nom_table qui ont soit
--                                               un niveau de risque supérieur à 3, soit un statut actif.
-- OR : L’enregistrement est sélectionné si au moins une des conditions est vraie.

-- Bonnes pratiques :
-- Prioriser AND sur OR lorsque possible, car OR peut ralentir les performances.
-- Indexer les colonnes utilisées avec OR (niveau_risque, statut) pour accélérer la recherche.
-- Utiliser des parenthèses ( ) pour éviter les ambiguïtés lorsque combiné avec AND.

----------

---- Combiner 'AND' et 'OR' avec des parenthèses
SELECT identifiant, 
       nom_zone
	   geom AS geom
FROM nom_table
WHERE (niveau_risque > 3 AND statut = 'Actif')
OR (niveau_risque > 5);

-- Explication :
-- (niveau_risque > 3 AND statut = 'Actif') : Sélectionne les zones actives avec un risque > 3.
-- OR (niveau_risque > 5) : Sélectionne aussi les zones avec un niveau de risque > 5, quel que soit leur statut.

-- Bonnes pratiques :
-- Utiliser des parenthèses ( ) pour éviter des erreurs logiques et clarifier l’ordre d’exécution des conditions.
-- Analyser la performance avec EXPLAIN ANALYZE pour optimiser les requêtes combinant OR et AND.
	
----------

---- Exclure des valeurs avec 'NOT'
SELECT identifiant,
       nom_zone, 
	   geom AS geom
FROM nom_table
WHERE NOT niveau_risque > 3;

-- Explication :
-- NOT niveau_risque > 3 : Sélectionne les zones à risque dont le niveau n'est pas supérieur à 3.
-- NOT : Inverse la condition qui suit.

-- Bonnes pratiques :
-- Utiliser NOT avec précaution, car il peut empêcher l'utilisation efficace des index.
-- Vérifier avec EXPLAIN ANALYZE pour s'assurer que la requête reste performante.

----------

---- Vérifier si une valeur est NULL avec 'IS NULL'
SELECT *
FROM nom_table
WHERE nom_colonne IS NULL;

-- Explication :
-- IS NULL : Vérifie si une colonne contient la valeur NULL.
-- Utilisé pour identifier les enregistrements où une valeur est manquante ou non définie.

-- Bonnes pratiques
-- Utiliser IS NULL pour filtrer les valeurs manquantes dans les colonnes.
-- Ne pas utiliser = pour vérifier NULL car cela retourne toujours FALSE.
-- Combiner IS NULL avec IS NOT NULL pour exclure ou inclure des résultats. 
-- Utiliser des indices pour les colonnes fréquemment vérifiées avec IS NULL
-- pour améliorer les performances.

----------

---- Vérifier que la valeur n'est pas NULL avec 'IS NOT NULL'
SELECT *
FROM nom_table
WHERE nom_colonne IS NOT NULL;

-- Explication :
-- IS NOT NULL : Vérifie que la colonne ne contient pas la valeur NULL.
-- Utilisé pour filtrer les enregistrements où une valeur est présente.

-- Bonnes pratiques
-- Utiliser IS NOT NULL pour exclure les valeurs manquantes dans les résultats.
-- Ne pas confondre NULL avec une chaîne vide ('') ou zéro (0), qui sont des 
-- valeurs valides.
-- Créer un index sur les colonnes fréquemment filtrées avec IS NOT NULL
-- pour optimiser les requêtes.

---------

---- Vérifier si une géométrie est vide avec 'ST_IsEmpty()'
SELECT ST_IsEmpty(geom) AS geom
FROM nom_table;

-- Explication :
-- ST_IsEmpty(geom) : Retourne TRUE si la géométrie est vide (pas de points,
--                    de lignes ou de polygones).
--                    Utilisé pour vérifier si une géométrie existe et a 
--                    une surface ou des sommets.

-- Bonnes pratiques
-- Utiliser ST_IsEmpty() pour nettoyer les données avant des analyses géospatiales.
-- Utiliser ST_Union() avec ST_IsEmpty() pour gérer les agrégations et 
-- exclure les géométries vides.

----------

-- Exclure les géométries vides avec 'NOT ST_IsEmpty()'
SELECT *
FROM nom_table
WHERE NOT ST_IsEmpty(geom);

-- Explication :
-- NOT ST_IsEmpty(geom) : Sélectionne les géométries non vides 
--                        (qui ont une surface, des points ou des lignes).
--                        Utilisé pour exclure les enregistrements où 
--                        la géométrie est vide.

-- Bonnes pratiques
-- Privilégier NOT ST_IsEmpty() pour exclure les géométries inutiles lors 
-- des requêtes ou mises à jour.

----------

---- Ajouter de la logique conditionnelle dans une requête avec 'CASE'
SELECT 
    CASE
        WHEN condition1 THEN valeur1
        WHEN condition2 THEN valeur2
        ELSE valeur_par_defaut
    END AS nom_colonne
FROM nom_table;

-- Explication :
-- CASE : Structure conditionnelle qui permet de vérifier plusieurs conditions 
--        et retourner une valeur différente selon la condition.
-- WHEN : Spécifie une condition.
-- THEN : Définit la valeur à retourner lorsque la condition est vraie.
-- ELSE : Définit la valeur par défaut lorsque aucune condition n'est vraie.
-- END : Termine le bloc CASE.

-- Bonnes pratiques
-- Utiliser CASE pour ajouter des conditions complexes dans une seule colonne 
-- sans avoir à multiplier les requêtes.
-- Éviter d'utiliser des conditions trop complexes dans CASE qui peuvent 
-- alourdir la lisibilité et les performances.
-- Utiliser CASE dans des expressions de calcul ou dans ORDER BY pour 
-- un tri dynamique.



--------------------------------------------------------------
-- PostGIS : Gestion des Tables et Optimisation des Données --
--------------------------------------------------------------

---- Suppression d'une table avec "DROP TABLE"
DROP TABLE IF EXISTS nom_table;

DROP TABLE IF EXISTS travaux_realises CASCADE;

-- Explication :
-- DROP TABLE : Supprime complètement la table.
-- IF EXISTS : Évite une erreur si la table existe.
-- CASCADE : Supprime aussi les objets dépendants (Attention ! Cette commande est irréversible. Assurez-vous 
--           d'avoir une sauvegarde avant de l'exécuter si nécessaire.)


---- Création d'une table avec "CREATE TABLE"
CREATE TABLE nom_table (
    id SERIAL PRIMARY KEY,
    nom_colonne1 TYPE1,
    nom_colonne2 TYPE2,
    nom_colonne3 TYPE3
);

-- Explication :
-- CREATE TABLE : Crée une nouvelle table dans la base de données.
-- id SERIAL PRIMARY KEY : Colonne auto-incrémentée servant d'identifiant unique.
-- colonne1 TYPE1 : Définit une colonne avec un type spécifique (INTEGER, VARCHAR, DATE, GEOMETRY, etc.).

-- Bonnes pratiques :
-- Toujours définir une clé primaire (PRIMARY KEY).
-- Utiliser des contraintes (NOT NULL, CHECK, UNIQUE) pour garantir l'intégrité des données.
-- Pour les données spatiales, utiliser GEOMETRY ou GEOGRAPHY avec PostGIS.

----------

---- Ajouter une colonne géométrique avec "ALTER TABLE"
ALTER TABLE nom_table
ADD COLUMN geom geometry(TYPE, SRID);

-- Explication :
-- ALTER TABLE : Modifie la structure de la table existante.
-- ADD COLUMN geom geometry(TYPE, SRID); : Ajoute une nouvelle colonne geom de type géométrique.
-- TYPE : Spécifie le type géométrique (Point, LineString, Polygon, MultiPolygon, etc.).
-- SRID : Définit le système de référence spatiale (ex. 4326 pour WGS 84, 2154 pour Lambert-93).

----------

---- Mettre à jour des données avec "UPDATE"
UPDATE nom_table
SET colonne = nouvelle_valeur
WHERE condition;

-- Explication :
-- UPDATE nom_table : Met à jour une table spécifique.
-- SET colonne = nouvelle_valeur : Modifie la valeur d’une colonne.
-- WHERE condition : Applique le changement seulement aux enregistrements correspondants.

----------

---- Création d’un index spatial pour optimiser les performances avec "CREATE INDEX"
CREATE INDEX nom_index
ON nom_table
USING GIST (colonne_geom);

-- Explication :
-- CREATE INDEX : Crée un index sur une table.
-- nom_de_l_index : Nom de l’index (ex. idx_parcelles_geom).
-- ON nom_de_la_table : Définit la table concernée.
-- USING GIST (colonne_geom) : Utilise l’index GIST sur la colonne géométrique.

-- Bonnes pratiques :
-- Toujours indexer les colonnes géométriques utilisées dans les requêtes spatiales.
-- Utiliser GIST pour des recherches complexes et BRIN pour des très grandes tables.
-- Vérifier l’efficacité de l’index avec EXPLAIN ANALYZE.

----------

---- Valider une transaction avec "COMMIT"
COMMIT;

-- Explication :
-- COMMIT; : Valide toutes les modifications effectuées dans la transaction en cours.
--           Une fois le COMMIT; exécuté, les changements deviennent permanents et visibles pour les autres utilisateurs.

----------

---- Supprimer les enregistrements qui ont des géométries invalides, vides ou NULL avec 'DELETE'
DELETE FROM nom_table
WHERE geom IS NULL  
OR ST_IsEmpty(geom)  
OR NOT ST_IsValid(geom);

-- Explication :
-- DELETE : Supprime de la table en fonction des confitions données
-- geom IS NULL : Supprime les enregistrements où la colonne geom est NULL (pas de géométrie).
-- ST_IsEmpty(geom) : Supprime les enregistrements où la géométrie est vide (aucune forme définie).
-- NOT ST_IsValid(geom) : Supprime les géométries invalides (qui ne respectent pas les règles topologiques, 
-- comme des polygones auto-intersectants).

-- Bonnes pratiques
-- Utiliser DELETE avec des conditions de géométrie pour garantir des données spatiales valides 
-- dans la base.
-- Toujours tester les conditions avec SELECT avant de supprimer des données.
-- Créer un index GIST sur les géométries pour améliorer les performances des requêtes géométriques.


----------------------------------------------------------
-- PostGIS : Normalisation et Correction des Géométries --
----------------------------------------------------------

---- Assigner un SRID à une géométrie avec 'ST_SetSRID'
SELECT ST_SetSRID(geom, 2154) AS geom
FROM nom_table
WHERE id = 'identifiant';

-- Explication :
-- ST_SetSRID(geom, 2154) : Cette fonction assigne un SRID (Spatial Reference System Identifier) à une géométrie geom. Le SRID 2154 correspond
--                          au système de coordonnées Réseau Français Lambert 93 (projection planimétrique en mètres).

-- Bonnes pratiques :
-- Vérifier le SRID d'origine avant de définir un nouveau SRID. Si une géométrie a déjà un SRID, assurez-vous qu'il est compatible 
-- avec le système de coordonnées du SRID que vous souhaitez assigner.
-- S'assurer que la géométrie est valide avant d'appliquer un SRID. Le changement de SRID peut affecter le positionnement spatial si le système
-- de coordonnées est incorrect ou mal appliqué.
-- Le SRID 2154 utilise des mètres comme unité, donc il est essentiel de connaître les unités utilisées pour les calculs du projet.

----------

---- Convertir au format Multi ou conserver le format "ST_Multi"
SELECT ST_Multi(geom) AS geom
FROM nom_table;

-- Explication :
-- ST_Multi(geom) : Convertit une géométrie simple (Polygon, LineString, Point) en une géométrie multiple (MultiPolygon, MultiLineString, MultiPoint).
--                  Conserve la multi-géométrie si la géométrie est déjà multiple.
-- FROM nom_table : Applique l’opération sur la colonne geom de la table.

----------

----  Extraire une sous-collection géométrique avec 'ST_CollectionExtract()'
SELECT ST_CollectionExtract(geom, 3) AS geom
FROM nom_table;

-- Explication :
-- ST_CollectionExtract(geom, 3) : Extrait une sous-collection géométrique de type Polygon (niveau 3), 
--                                 à partir d'une collection géométrique comme MultiPoint, MultiLineString, 
--                                 ou MultiPolygon.
-- 3 : Extrait des Polygones (MultiPolygon → Polygon). Il existe également deux autres niveaux (1 : Extrait 
--     des Points (MultiPoint → Point), 2 : Extrait des Lignes (MultiLineString → LineString)).

-- Bonnes pratiques
-- Utiliser ST_CollectionExtract() pour décomposer des collections géométriques complexes en éléments simples.
-- S'assurer que le niveau (1, 2, ou 3) est correct pour extraire la géométrie désirée.
-- Créer un index spatial GIST pour optimiser les requêtes qui manipulent des collections géométriques.

---------

---- Corriger les erreurs topologiques avec "ST_MakeValid(geom)"
SELECT ST_MakeValid(geom) AS geom
FROM nom_table;

-- Explication :
-- ST_MakeValid(geom) : Corrige les géométries invalides (auto-intersections, trous non valides, 
--                      polygones dégénérés). Utilisé pour garantir des objets valides avant de 
--                      réaliser des traitements SIG.

--  Bonnes pratiques
-- Utiliser ST_IsValid() avant ST_MakeValid() pour identifier les géométries problématiques.
-- Créer un index GIST après correction pour optimiser les performances.
-- Vérifier le résultat avec ST_AsText() avant intégration dans un SIG.

---------------------------------------------------------
-- PostGIS : Manipulation et Traitement des Géométries --
---------------------------------------------------------

---- Agréger plusieurs géométries en une seule collection avec "ST_Collect()"
SELECT ST_Collect(geom) AS geom
FROM nom_table;

-- Explication :
-- Regroupe plusieurs géométries en un seul objet sans les fusionner.
-- Peut contenir plusieurs types (MultiPoint, MultiLineString, MultiPolygon).
-- Utilisé pour stocker ou analyser des ensembles de géométries liées.

-- Bonnes pratiques
-- Utiliser ST_Collect() pour regrouper des objets sans les fusionner (ST_Union() pour fusionner).
-- Vérifier le type de géométrie avec ST_GeometryType().
-- Créer un index GIST pour optimiser les requêtes sur les collections spatiales.

----------
---- Fusionner des géométries avec "ST_Union()"
SELECT ST_Union(geom)
FROM nom_table;

-- Explication :
-- (geom) : Fusionne plusieurs géométries en une seule.
-- FROM nom_table : Applique l’opération sur toutes les géométries de la table.

----------

---- Regrouper des géométries par groupe avec "ST_Union()" et "GROUP BY"
SELECT colonne_groupe, 
       ST_Union(geom) AS geom
FROM nom_table
GROUP BY colonne_groupe;

-- Explication :
-- ST_Union(geom) : Fusionne les géométries appartenant à un même groupe.
-- GROUP BY colonne_groupe : Regroupe les objets par valeur unique d’une colonne.

-- Bonnes pratiques :
-- Créer un index GIST pour améliorer les performances sur des grands jeux de données.
-- Utiliser ST_Multi() si la couche cible attend du MultiPolygon.
-- Toujours filtrer (WHERE) avant ST_Union() pour éviter des traitements inutiles.

----------

---- Fusionner des résultats avec 'UNION ALL'
SELECT nom_colonne1, nom_colonne2
FROM nom_table1
UNION ALL
SELECT nom_colonne1, nom_colonne2
FROM nom_table2;

-- Explication :
-- UNION ALL : Fusionne les résultats de deux requêtes, y compris les doublons.
--             Contrairement à UNION, qui élimine les doublons, UNION ALL 
--             conserve toutes les lignes, même celles qui se répètent.
--             Utilisé pour combiner rapidement plusieurs ensembles de résultats 
--             sans filtrer les doublons.
-- Attention même nombre de colonnes obligatoire.

-- Bonnes pratiques
-- Utiliser UNION ALL lorsque vous souhaitez conserver les doublons et optimiser 
-- les performances.
-- Éviter UNION ALL si vous avez besoin de résultats uniques, car cela peut entraîner 
-- un traitement inutile des doublons.
-- Assurer une compatibilité de structure entre les deux ensembles de résultats 
-- (mêmes types de données et nombre de colonnes).

----------

---- Calculer l'intersection de deux géométries avec 'ST_Intersection()'
SELECT ST_Intersection(geom1, geom2) AS geom
FROM nom_table1 t1
JOIN nom_table2 t2 
ON ST_Intersects(t1.geom, t2.geom);

-- Explication :
-- ST_Intersection(geom1, geom2) : Cette fonction calcule l'intersection géométrique entre deux géométries, geom1 et geom2. Elle retourne la géométrie
--                                 résultante de l'intersection, qui peut être un polygone, une ligne ou un point, en fonction de la nature des 
--                                 géométries impliquées.
--                                 - Si les géométries sont des polygones, l'intersection sera une zone partagée entre elles.
--                                 - Si l'une des géométries est une ligne, l'intersection peut être une ligne partagée.
--                                 - Si les géométries sont des points, l'intersection sera le point de contact entre les deux.

-- Bonnes pratiques :
-- Vérifier la compatibilité des types de géométries : Assurez-vous que les géométries à intersecter sont compatibles (polygone avec polygone,
--                                                     ligne avec ligne, etc.).
-- Pré-filtrer avec ST_Intersects() : Utilisez cette fonction pour réduire les géométries à analyser, ce qui améliore les performances.
-- Gestion des résultats divers : L'intersection peut renvoyer différents types de géométries. Assurez-vous de gérer le type de géométrie 
--                                attendu pour éviter les erreurs.
-- Assurer la validité des géométries : Vérifiez que les géométries sont valides avant d’appliquer l’intersection pour éviter des résultats erronés.

----------

---- Différence spatiale entre deux géométries avec "ST_Difference()"
SELECT ST_Difference(t1.geom, t2.geom)
FROM nom_table1 t1, nom_table2 t2
WHERE ST_Intersects(t1.geom, t2.geom);

-- Explication :
-- ST_Difference(a, b) : Renvoie la partie de a qui n’intersecte pas b.
-- FROM nom_table1 t1, nom_table2 t2 : Applique l’opération entre deux couches géographiques.
-- WHERE ST_Intersects(c.geom, p.geom) : Sélectionne seulement les objets qui se croisent.

-- Bonnes pratiques :
-- Filtrer avec ST_Intersects() avant ST_Difference() pour éviter les calculs inutiles.
-- Créer des index GIST sur les colonnes géométriques pour améliorer la performance.
-- Vérifier les types (ST_GeometryType()) pour éviter les erreurs de compatibilité.

---------------------------------------------------------------------
-- PostGIS : Optimisation des Jointures et Associations de Données --
---------------------------------------------------------------------

 ---- Effectuer une jointure entre deux tables avec 'JOIN'
SELECT t1.identifiant1, t1.nom_zone, t1.geom1, t2.niveau_risque
FROM nom_table1 t1
JOIN nom_table2 t2 
ON t1.identifiant1 = t2.identifiant2;

-- Explication :
-- JOIN : Effectue une jointure entre les tables nom_table2 et infos_risque en associant les données qui ont une correspondance.
-- ON t1.identifiant1 = t2.identifiant2 : l'attribut identifiant1 de nom_table1 doit correspondre à l'attribut identifiant2 dans nom_table2.

-- Bonnes pratiques :
-- Toujours définir une condition avec ON pour éviter un produit cartésien entre les tables.
-- Indexer les colonnes utilisées pour la jointure (id et zone_id) pour améliorer les performances.
-- Privilégier des alias (t1, t2) pour rendre la requête plus lisible.

----------

---- Lier deux tables avec "INNER JOIN" ... "ON" ...
SELECT t1.*, t2.nom_colonne
FROM nom_table1 t1
INNER JOIN nom_table2 t2
ON t1.nom_colonne_commune = t2.nom_colonne_commune;

-- Explication :
-- INNER JOIN table2 : Fait une jointure interne entre table1 et table2. Une jointure interne 
--                    (INNER JOIN) est une opération en SQL permettant de lier deux tables en 
--                    associant leurs données selon une condition commune. Elle ne retourne que 
--                    les lignes ayant une correspondance dans les deux tables.
-- ON t1.colonne_commune = t2.colonne_commune : Associe les lignes ayant une correspondance, 
--                                              selon une colonne commune.

-- Exemple :
-- Table1          Table2
-- +----+----+    +----+----+
-- | ID | A  |    | ID | B  |
-- +----+----+    +----+----+
-- |  1 | X  |    |  1 | Y  |
-- |  2 | Z  |    |  3 | W  |
-- |  3 | V  |    |  2 | U  |
-- +----+----+    +----+----+

-- Résultat (INNER JOIN ON ID)
-- +----+----+----+
-- | ID | A  | B  |
-- +----+----+----+
-- |  1 | X  | Y  |
-- |  3 | V  | W  |
-- +----+----+----+ 

-- L'ID `2` de `Table1` et `ID 3` de `Table2` sont ignorés car **pas de correspondance**.

-- Bonnes pratiques :
-- Créer des index sur les colonnes utilisées dans ON pour améliorer la performance.
-- Toujours vérifier les correspondances avant d’exécuter un INNER JOIN massif.
-- Utiliser ST_Intersects() ou ST_Contains() pour les jointures spatiales.

----------

---- Récupérer toutes les lignes de la table de gauche avec 'LEFT JOIN'
SELECT t1.*, t2.colonne
FROM table1 t1
LEFT JOIN table2 t2
ON t1.nom_colonne1 = t2.nom_colonne1;

-- Explication :
-- LEFT JOIN table2 : Effectue une jointure gauche entre table1 et table2.
-- Retourne toutes les lignes de table1, même si aucune correspondance n'existe dans table2.
-- Les colonnes de table2 seront NULL pour les enregistrements de table1 sans correspondance.

-- Bonnes pratiques
-- Utiliser LEFT JOIN lorsque vous souhaitez récupérer toutes les lignes de la table de
-- gauche et les correspondances de la table de droite, ou NULL si aucune correspondance.
-- Utiliser avec WHERE pour filtrer les résultats avec des valeurs NULL dans la table de droite.
-- Créer un index GIST ou B-tree sur les colonnes de jointure pour améliorer les 
-- performances de la requête.


----------------------------------------------------------
-- PostGIS : Analyse Spatiale et Relations Géométriques --
----------------------------------------------------------

----Vérifier si deux géométries se croisent avec "ST_Intersects()"
SELECT * 
FROM nom_table1 t1
INNER JOIN nom_table2 t2
ON ST_Intersects(t1.geom, t2.geom);

-- Explication :
-- ST_Intersects(geom1, geom2) : Retourne TRUE si geom1 et geom2 ont une intersection.
--                               Utilisé avec INNER JOIN, WHERE ou SELECT pour identifier 
--                               les objets spatiaux qui se chevauchent.

-- Bonnes pratiques :
-- Créer des index GIST pour optimiser les performances des ST_Intersects().
-- Utiliser WHERE pour limiter les requêtes et améliorer la vitesse.
-- Comparer avec ST_Contains() ou ST_Within() selon le besoin spécifique.

----------

---- Vérifier si le point représentatif d’une surface intersecte une autre géométrie avec "ST_PointOnSurface()"
SELECT * 
FROM nom_table1 t1
INNER JOIN nom_table2 t2
ON ST_Intersects(ST_PointOnSurface(t1.geom), t2.geom);

-- Explication :
-- ST_PointOnSurface(geom) : Extrait un point à l’intérieur d’un polygone.
-- ST_Intersects(geom1, geom2) : Vérifie si deux géométries se croisent.

-- Bonnes pratiques :
-- Utiliser ST_PointOnSurface() pour garantir que le point est à l’intérieur.
-- Créer un index GIST pour améliorer la rapidité des jointures.
-- Tester avec ST_AsText() pour valider le bon positionnement des points.

----------

---- Vérifier si une géométrie est contenue dans une autre avec "ST_Within()"
SELECT * 
FROM nom_table1 t1
WHERE ST_Within(t1.geom, (SELECT geom FROM nom_table2 WHERE condition));

-- Explication :
-- ST_Within(geom1, geom2) : Retourne TRUE si geom1 est totalement à l’intérieur de geom2.
--                           Utilisé avec WHERE pour filtrer les objets spatiaux.

-- Bonnes pratiques :
-- Utiliser ST_Within() pour s’assurer qu’un objet est totalement inclus.
-- Privilégier ST_Intersects() si une relation partielle est acceptable.
-- Créer un index spatial GIST pour optimiser les performances.

----------

---- Vérifier si deux géométries sont à une certaine distance avec 'ST_DWithin()'
SELECT *
FROM nom_table1
JOIN nom_table2
ON ST_DWithin(geom1, geom2, distance);

-- Explication :
-- ST_DWithin(geom1, geom2, distance) : Retourne TRUE si la distance entre geom1 et geom2 
--                                      est inférieure ou égale à la distance spécifiée.
-- geom1 et geom2 : Géométries à comparer (par exemple, Point, Polygon, etc.).
-- distance : Distance maximale en unités du SRID (par exemple, 0.1 pour 10 cm).

-- Bonnes pratiques
-- Utiliser ST_DWithin() pour des requêtes de proximité efficaces plutôt 
-- que de calculer directement la distance avec ST_Distance().
-- Créer un index spatial GIST pour optimiser les performances de ST_DWithin() 
-- sur des grandes bases de données.


---------------------------------------------------------------
-- PostGIS : Filtres, Jointures et Optimisation des Requêtes --
---------------------------------------------------------------

---- Filtrer les données avec "WHERE"
SELECT nom_colonnes
FROM nom_table
WHERE condition;

-- Explication :
-- WHERE condition : Filtre les résultats en fonction d’une condition.
--                   Utilisé avec SELECT, UPDATE, DELETE et INNER JOIN.

-- Bonnes pratiques :
-- Créer des index sur les colonnes fréquemment utilisées dans WHERE.
-- Utiliser EXPLAIN ANALYZE pour analyser la performance des requêtes.
-- Éviter LIKE '%mot%' qui empêche l’utilisation d’un index.

----------

---- Filtrer des enregistrements avec "WHERE LEFT()"
SELECT * 
FROM nom_de_la_table 
WHERE LEFT(colonne_texte, n) = 'valeur';

-- Explication :
-- LEFT(colonne_texte, n) : Extrait les n premiers caractères de la colonne.

-- Alternative avec LIKE (Meilleure performance)
SELECT * 
FROM nom_de_la_table  
WHERE idu LIKE 'xxx%';

----------

---- Filtrer des enregistrements avec 'WHERE EXISTS'
SELECT identifiant, 
       nom_zone, 
	   geom1
FROM nom_table1 t1
WHERE EXISTS (
    SELECT 1
    FROM nom_table2 t2
    WHERE t2.identifiant2 = t1.identifiant1
);

-- Explication :
-- WHERE EXISTS (...) : Vérifie si une condition est satisfaite dans une sous-requête.
-- SELECT 1 FROM nom_table2 WHERE t2.identifiant2 = t1.identifiant1 : sous-requête qui vérifie si la table1 a au moins une valeur 
--                                                                    associé à la table2. Si la sous-requête retourne une ligne, 
--                                                                    la condition est vraie et l'enregistrement de la table 1 est 
--                                                                    conservé.

-- Bonnes pratiques :
-- Préférer EXISTS à IN lorsque la sous-requête retourne un grand nombre de lignes pour améliorer les performances.
-- Indexer les colonnes de jointure pour accélérer la vérification d’existence.
-- Utiliser SELECT 1 au lieu de SELECT * dans la sous-requête pour optimiser l'exécution.

----------

---- Exclure les enregistrements existants en fonction d'une condition spatiale avec 'WHERE NOT EXISTS'
SELECT *
FROM nom_table1
WHERE NOT EXISTS (
    SELECT 1 
    FROM nom_table2
    WHERE ST_Intersects(nom_table1.geom, nom_table.geom2)
);

-- Explication :
-- WHERE NOT EXISTS : Filtre les enregistrements où la condition dans la sous-requête ne retourne aucune ligne.
-- ST_Intersects(geom1, geom2) : Vérifie si les géométries de geom1 et geom2 se croisent.
-- Utilisé pour exclure les enregistrements de nom_table1 qui intersectent ceux de nom_table2.

-- Bonnes pratiques
-- Utiliser WHERE NOT EXISTS pour exclure des éléments basés sur une condition géospatiale.
-- Créer un index GIST sur les colonnes géométriques pour améliorer les performances des requêtes 
-- spatiales avec ST_Intersects().
-- Vérifier la performance de la sous-requête avec EXPLAIN ANALYZE pour voir si l'index 
-- est utilisé correctement.

---------

---- Sélectionner les objets intersectant une zone tampon avec "ST_Intersects(ST_Buffer())"
SELECT * 
FROM nom_table
WHERE ST_Intersects(
        geom1,
        ST_Buffer(geom2, distance)
);

--  Explication :
-- ST_Intersects(geom1, geom2) : Vérifie si geom1 et geom2 se croisent.
-- ST_Buffer(geom2, distance) : Crée une zone tampon (périmètre = distance) autour de geom2.
-- Utilisé pour détecter les objets situés à proximité d’un élément géographique.

-- Bonnes pratiques
-- Privilégier une tolérance raisonnable dans ST_Buffer() pour éviter des calculs inutiles.
-- Créer un index GIST sur les géométries pour optimiser les performances.
-- Tester avec EXPLAIN ANALYZE pour vérifier l’efficacité de la requête.

----------

---- Exclure les géométries qui se croisent avec 'WHERE NOT ST_Intersects()'
SELECT *
FROM nom_table
WHERE NOT ST_Intersects(geom1, geom2);

-- Explication :
-- ST_Intersects(geom1, geom2) : Vérifie si deux géométries se croisent ou se chevauchent.
-- NOT ST_Intersects(geom1, geom2) : Exclut les enregistrements où les géométries se croisent.
--                                   **Utilisé pour filtrer les résultats afin de ne garder
--                                   que les géométries qui ne se croisent pas.

-- Bonnes pratiques
-- Utiliser NOT ST_Intersects() pour exclure les objets géospatiaux qui se croisent.
-- Utiliser des index spatiaux (GIST) pour améliorer la performance des requêtes 
-- géométriques, notamment avec ST_Intersects() et NOT ST_Intersects().
-- Vérifier les résultats avec ST_AsText() pour visualiser les géométries exclues.

----------

---- Vérifier le type de géométrie avec 'WHERE ST_GeometryType()' et 'IN'
SELECT *
FROM nom_table
WHERE ST_GeometryType(geom) IN ('type_geometrie');

-- Explication :
-- ST_GeometryType(geom) : Cette fonction retourne le type de la géométrie de l'objet géospatial spécifié (ici geom). Elle renvoie une chaîne de 
--                         caractères représentant le type de la géométrie, comme ST_Polygon pour un polygone, ST_LineString pour une ligne, ou 
--                         ST_Point pour un point.
--                         Cette fonction est particulièrement utile pour effectuer des traitements sur des géométries spécifiques (par exemple, 
--                         n'effectuer certaines analyses que sur des polygones ou multipolygones).
-- IN ('type_geometrie') : Cette expression permet de vérifier si le type de géométrie correspond à l'un des types spécifiés dans la liste 
--                         ('type_geometrie'). 

-- Bonnes pratiques :
-- Utilisation avec des requêtes de filtrage : Lorsque vous souhaitez limiter les résultats aux géométries d'un type spécifique.
-- Compatibilité avec d'autres types : Vous pouvez étendre la liste dans IN pour inclure d'autres types de géométries, 
--                                     comme 'ST_LineString', 'ST_Point', etc., en fonction des besoins de votre projet.

----------


---- Exclure des correspondances spécifiques entre deux tables avec 'WHERE !='
SELECT *
FROM nom_table1 t1
INNER JOIN nom_table2 t2
ON t1.colonne_commune = t2.colonne_commune
WHERE t1.nom_colonne1 != t2.nom_colonne1;

-- Explication :
-- t1.nom_colonne1 != t2.nom_colonne1 : Exclut les lignes où les valeurs de nom_colonne1
--                                      dans table1 et table2 sont égales.
-- Condition != dans WHERE : assure que les enregistrements de table1 et table2 ont des
--                           valeurs différentes dans nom_colonne1.

-- Bonnes pratiques
-- Utiliser != dans WHERE pour exclure des correspondances spécifiques après une jointure.
-- Assurez-vous que les colonnes comparées (nom_colonne1) sont de types compatibles.
-- Optimiser la requête avec des index sur les colonnes comparées pour de meilleures performances.


-------------------------------------------------------------------
-- PostGIS : Alignement et Réduction de Précision des Géométries --
-------------------------------------------------------------------

---- Aligner une géométrie sur une grille avec "ST_SnapToGrid()"
SELECT ST_SnapToGrid(geom, valeur) AS geom
FROM nom_table;

UPDATE nom_table
SET geom = ST_SnapToGrid(geom, valeur);

-- Explication :
-- ST_SnapToGrid(geom, valeur) : Aligne les sommets d’une géométrie sur une grille de résolution valeur.
-- AS geom : Renomme la colonne résultante.
-- FROM nom_table : Applique la fonction sur les données d’une table.
-- UPDATE nom_table : Met à jour une table spécifique.
-- SET colonne = nouvelle_valeur : Modifie la valeur d’une colonne.

-- Bonnes pratiques :
-- Tester ST_SnapToGrid() avant d’appliquer UPDATE sur des données critiques.
-- Créer un index spatial après modification pour optimiser les performances.
-- Utiliser ST_SnapToGrid() pour préparer des données SIG à une grille prédéfinie.

----------

---- Aligner une géométrie sur une autre avec "ST_Snap()"
SELECT ST_Snap(geom1, geom2, tolérance) AS geom
FROM nom_table;

-- Explication :
-- Aligne les sommets de geom1 et de geom2 dans la limite de la tolérance, c'est-à-dire avec 
-- une distance d'accrochage.
-- geom1 : Géométrie à ajuster.
-- geom2 : Géométrie de référence.
-- tolérance : Distance maximale d'ajustement.

-- Bonnes pratiques
-- Utiliser ST_MakeValid() avant ST_Snap() pour éviter les erreurs de géométrie.
-- Privilégier une tolérance raisonnable (0.2 à 1.0) pour éviter des ajustements excessifs.
-- Créer un index GIST sur les géométries avant d’appliquer ST_Snap().

----------

 ---- Réduire la précision d'une géométrie avec 'ST_ReducePrecision()'
SELECT ST_ReducePrecision(geom, 'valeur') AS geom
FROM nom_table
WHERE id = 'identifiant';

-- Explication :
-- ST_ReducePrecision(geom, valeur) : Cette fonction réduit la précision d’une géométrie en arrondissant les coordonnées des points.
--                                    La valeur valeur définit la précision des coordonnées après réduction.
-- valeur : La précision de la réduction, exprimée en unités du système de coordonnées (par exemple, en degrés ou en mètres selon le SRID).
-- Cette fonction est utile pour simplifier des géométries complexes, en réduisant la taille des données tout en maintenant une approximation
-- de la forme originale.

-- Bonnes pratiques :
-- Choisir une valeur appropriée pour la précision : Trop de réduction peut rendre la géométrie trop approximative, tandis qu'une précision
-- trop élevée peut ne pas réduire suffisamment la taille des données.
-- Tester sur un sous-ensemble de données avant de l'appliquer à l'ensemble de la base pour vérifier l'impact sur la qualité des géométries.
-- Utiliser avec des géométries grandes ou complexes pour optimiser le stockage et les performances des requêtes géospatiales.
-- Utiliser ST_Simplify() si l’objectif est de réduire le nombre de points dans une géométrie tout en maintenant la forme géométrique 
-- approximativement correcte.


---------------------------------------------------------------------
-- PostGIS : Manipulation, Interpolation et Analyse des Géométries --
---------------------------------------------------------------------

---- Convertir une géométrie en 2D avec "ST_Force2D()"
SELECT ST_Force2D(geom) AS geom
FROM nom_table;

-- Explication :
-- ST_Force2D(geom) : Supprime les composantes Z (altitude) et M (mesures) pour ne garder que X et Y.
-- AS geom : Renomme la colonne pour une compatibilité avec d’autres requêtes.
-- FROM nom_table : Applique l’opération sur la table spécifiée.

-- Bonnes pratiques :
-- Utiliser ST_Force2D() pour éviter des erreurs avec des fonctions non compatibles avec la 3D.
-- Vérifier les dimensions avant la conversion avec ST_HasZ() et ST_HasM().
-- Créer un index spatial après la conversion pour optimiser les performances.

----------

---- Calculer la distance entre deux géométries avec 'ST_Distance()'
SELECT ST_Distance(geom1, geom2) AS distance
FROM nom_table;

-- Explication :
-- ST_Distance(geom1, geom2) : Calcule la distance minimale entre deux géométries (geom1 et geom2).
--                             Retourne la distance en unités du SRID de la géométrie (par exemple, 
--                             en mètres si SRID = 4326 est transformé en EPSG:3857 ou autre système
--                             métrique).

-- Bonnes pratiques
-- Utiliser ST_Distance() pour mesurer les distances entre géométries dans des systèmes 
-- de projection métriques.
-- Utiliser ST_Transform() pour transformer les géométries en un SRID métrique avant 
-- de calculer la distance.

----------

---- Calculer la longueur avec 'ST_Length(geom)'
SELECT ST_Length(geom) AS geom
FROM nom_table
WHERE id = 'identifiant';

-- Explication :
-- ST_Length(geom) : Cette fonction calcule la longueur d'une géométrie de type LINESTRING ou MULTILINESTRING.
--                   Elle retourne la distance totale parcourue le long de la ligne, exprimée dans les unités 
--                   du système de coordonnées.

-- Bonnes pratiques :
-- Vérifier l'unité de mesure utilisée par le SRID de la géométrie. Si le SRID est en degrés, la longueur ne
-- sera pas en mètres ou kilomètres.
-- Cette fonction est utilisée pour déterminer la longueur de l'objet (routes, de frontières ou d'autres 
-- géométries linéaires).
	
---------

---- Calculer l'inverse de la longueur avec '1 / ST_Length(geom)'
SELECT 1 / ST_Length(geom) AS geom
FROM nom_table
WHERE id = 'identifiant';

-- Explication :
-- 1 / ST_Length(geom) : Cette expression retourne l'inverse de la longueur calculée par ST_Length(geom). 
--                       L'inverse de la longueur peut être utile pour répartir des points régulièrement 
--                       le long de la géométrie (par exemple, pour créer des intervalles réguliers sur une ligne).
--                       Si la longueur de la géométrie est L, alors 1 / L donnera un rapport inverse de la distance : 
--                       un nombre qui représente combien de fois cette longueur peut tenir dans l'unité 1

-- Bonnes pratiques :
-- Vérifier l'unité de mesure : Comme avec ST_Length(geom).
-- Assurez-vous que le système de coordonnées utilisé permet d'obtenir des valeurs précises pour l'inverse de la longueur.
-- Cela peut être utile pour des applications où vous souhaitez effectuer des calculs proportionnels sur la longueur d'une
-- ligne.

---------

---- Interpoler des points le long du contour extérieur d’un polygone avec 'ST_LineInterpolatePoints()'
SELECT ST_LineInterpolatePoints(
           ST_ExteriorRing(geom), 
           1 / ST_Length(ST_ExteriorRing(geom))
       ) AS interpolated_points
FROM nom_table
WHERE id = 'identifiant';

-- Explication :
-- ST_ExteriorRing(geom) : Cette fonction extrait le contour extérieur d'une géométrie polygonale.
--                         Elle renvoie la géométrie délimitant l'extérieure du polygone.
-- ST_Length(ST_ExteriorRing(geom)) : Calcule la longueur totale du périmètre extérieur du polygone. 
--                                    Cela donne la distance totale autour de la zone géographique.
-- ST_LineInterpolatePoints(ST_ExteriorRing(geom), 1 / ST_Length(ST_ExteriorRing(geom))) : Interpole 
--                         des points le long du périmètre extérieur du polygone à intervalles réguliers. 
--                         Ici, le nombre de points est déterminé par l'inverse de la longueur totale du
--                         périmètre. Cela permet de placer un point à chaque unité de longueur du périmètre, 
--                         garantissant que les points sont uniformément répartis.

-- Bonnes pratiques :
-- Tester avec SELECT pour s'assurer que les points sont correctement répartis sur le périmètre.
-- Utiliser cette approche pour des tâches nécessitant des points réguliers sur des contours polygonaux.
-- Assurer que la géométrie est valide avant d'utiliser cette fonction.
	
---------

---- Interpoler des points le long d'une ligne avec 'ST_LineInterpolatePoints()'
SELECT ST_LineInterpolatePoints(geom, 'valeur') AS geom
FROM nom_table
WHERE id = 'identifiant';

-- Explication :
-- ST_LineInterpolatePoints(geom, 'valeur') : Cette fonction génère des 'n' points  uniformément
--                                            espacés le long d’une ligne géographique.
-- Second paramètre ('valeur') : nombre de points à interpoler le long de la ligne, répartis de 
--                               manière égale.

-- Bonnes pratiques :
-- Tester avec SELECT avant de procéder à des mises à jour ou des insertions de données 
-- pour vérifier le bon espacement des points.
-- Assurez-vous que geom est bien de type LINESTRING ou MULTILINESTRING, sinon l’utilisation
-- de la fonction échouera.
-- Réévaluer le nombre de points (le second paramètre) en fonction de la longueur de
-- la ligne et de la précision souhaitée.


---------

---- Extraire le périmètre extérieur d'un polygone avec 'ST_ExteriorRing()'
SELECT ST_ExteriorRing(geom) AS geom
FROM nom_table
WHERE id = 'identifiant';

-- Explication :
-- ST_ExteriorRing(geom) : Cette fonction permet d'extraire le périmètre extérieur (ou anneau extérieur)
--                         d'une géométrie de type polygone. Elle renvoie une ligne (type LINESTRING) 
--                         représentant le contour extérieur du polygone.
--                         Cette fonction est utilisée pour travailler spécifiquement avec les bords 
--                         extérieurs des polygones, ignorants les anneaux intérieurs.

-- Bonnes pratiques :
-- Tester avec un SELECT pour s'assurer que la géométrie est correctement extraite et qu’il s'agit bien
-- du périmètre extérieur du polygone.
-- Vérifier que la géométrie est un polygone valide avant d'utiliser cette fonction, car elle peut 
-- échouer sur des géométries non fermées ou incorrectes.

---------

---- Extraire la frontière d’une géométrie avec 'ST_Boundary(geom)'
SELECT ST_Boundary(geom) AS geom
FROM nom_table
WHERE identifiant = 1;

-- Explication :
-- ST_Boundary(geom) : Retourne la frontière d’une géométrie en fonction de son type :
	-- Pour un polygone (POLYGON), la frontière est une ligne (LINESTRING) correspondant au contour.
	-- Pour une ligne (LINESTRING), la frontière est un ensemble de points (POINTS) représentant les extrémités.
	-- Pour un point (POINT), la frontière est vide (GEOMETRYCOLLECTION EMPTY).
-- La requête extrait la frontière de la géométrie geom pour l’identifiant 1 dans nom_table.

-- Bonnes pratiques :
-- Utiliser ST_IsValid(geom) pour s’assurer que la géométrie est valide avant d’extraire la frontière.
-- Combiner avec ST_ExteriorRing() si vous travaillez spécifiquement avec des polygones.

----------

---- Créer une zone tampon autour d’une géométrie avec "ST_Buffer()"
SELECT ST_Buffer(geom, distance, segments) AS geom
FROM nom_table;

-- Explication :
-- ST_Buffer(geom, distance, segments) : Crée une zone tampon (périmètre) autour de la géométrie.
-- distance : Définit la largeur du buffer (en unités du SRID, souvent en mètres).
-- segments : Détermine le nombre de segments utilisés pour lisser les bords arrondis.

-- Bonnes pratiques :
-- Utiliser ST_Buffer() avec ST_Intersects() pour des requêtes efficaces.
-- Créer un index GIST après avoir généré un buffer pour accélérer les requêtes.
-- Tester avec ST_AsText() pour vérifier la précision du buffer avant utilisation en SIG.


-----------------------------------------------------------
-- PostGIS : Extraction et Transformation des Géométries --
-----------------------------------------------------------

---- Extraire les sommets d’une géométrie avec "ST_Points()"
SELECT ST_Points(geom) AS geom
FROM nom_table;

-- Explication :
-- Extrait tous les sommets (POINTS) d’une géométrie linéaire ou polygonale.
-- Convertit un LineString ou Polygon en une collection de points (MultiPoint).
-- Utile pour analyser la structure des géométries complexes.

-- Bonnes pratiques
-- Utiliser ST_Dump() après ST_Points() pour obtenir chaque point individuellement.
-- Vérifier le type de géométrie avec ST_GeometryType() après extraction.
-- Créer un index GIST sur les points générés pour optimiser les recherches spatiales.

-----------

---- Trouver le point le plus proche entre deux géométries avec 'ST_ClosestPoint()'
SELECT ST_ClosestPoint(geom1, geom2) AS geom
FROM nom_table;

-- Explication :
-- ST_ClosestPoint(geom1, geom2) : Retourne le point le plus proche de geom1 sur geom2.
--                                 Utilisé pour identifier le point sur geom2 qui est 
--                                 le plus proche de geom1.

-- Bonnes pratiques
-- Utiliser ST_ClosestPoint() pour obtenir des résultats précis quand vous travaillez 
-- avec des géométries complexes (lignes, polygones).
-- Vérifier la compatibilité des géométries (SRID) avant d'utiliser ST_ClosestPoint(),
-- sinon transformez-les avec ST_Transform().
-- Optimiser avec des index spatiaux (GIST) sur les géométries concernées pour 
-- améliorer la performance des calculs de distances.

----------

---- Éliminer les sommets en double d’une géométrie avec "ST_RemoveRepeatedPoints()"
SELECT ST_RemoveRepeatedPoints(geom) AS geom
FROM nom_table;

-- Explication :
-- Supprime les sommets redondants dans une géométrie sans modifier sa structure.
-- Évite les erreurs topologiques causées par des sommets superposés.
-- Optimise le stockage et le traitement des géométries.

-- Bonnes pratiques
-- Utiliser ST_RemoveRepeatedPoints() avant ST_Union() ou ST_Snap() pour éviter les erreurs de fusion.
-- Vérifier les modifications avec ST_NPoints() avant et après nettoyage.
-- Créer un index GIST après transformation pour optimiser les requêtes spatiales.

-----------

---- Éliminer les sommets en double d’une géométrie avec 'ST_RemoveRepeatedPoints()' et une tolérance
SELECT ST_RemoveRepeatedPoints(geom, 0.001) AS geom
FROM nom_table;

-- Explication :
-- ST_RemoveRepeatedPoints(geom, tolérance) : Supprime les sommets redondants d’une géométrie sans 
-- modifier sa structure.
-- Tolérance (0.001) : Définit la distance minimale sous laquelle deux sommets successifs d'une 
--                     géométrie linéaire ou polygonale sont considérés comme identiques et 
--                     fusionnés en un seul point.
--					   Si deux sommets sont séparés par une distance inférieure ou égale à 0.001 
--                     unités (selon le SRID de la géométrie), l'un des deux est supprimé.
--					   Si la tolérance est trop élevée, des sommets essentiels à la forme originale 
--                     peuvent être supprimés, ce qui peut altérer la géométrie.
--					   Si la tolérance est trop faible, les sommets en double ne seront pas éliminés 
--                     efficacement.

-- Bonnes pratiques :
-- Déterminer la tolérance en fonction du SRID :
--    - Dans un SRID métrique (EPSG:2154 - Lambert 93), 0.001 correspond à 1 mm.
--    - Dans un SRID géographique (EPSG:4326 - WGS84), 0.001 représente environ 0.11 mètres (~11 cm à l'équateur).
--    - Ajuster la tolérance en fonction de la précision des données et des distances utilisées dans le projet.
-- Vérifier l’impact avec ST_NPoints(), cela permet de mesurer combien de points sont supprimés.
-- Créer un index spatial GIST après transformation pour optimiser les performances :
-- Tester la tolérance sur un sous-ensemble de données avant d’appliquer sur l’ensemble.

-----------

---- Extraire les points d’une géométrie avec 'ST_DumpPoints()'
SELECT 
    (ST_DumpPoints(geom)).path AS path, 
    (ST_DumpPoints(geom)).geom AS geom      
FROM nom_table;

-- Explication :
-- ST_DumpPoints(geom) : Décompose une géométrie en points individuels.
-- path : Retourne un chemin ou un identifiant pour chaque point dans la géométrie 
--        (utile pour suivre les sous-parties dans une géométrie complexe).
-- geom : Retourne chaque point individuel dans la géométrie.

--  Bonnes pratiques
-- Utiliser ST_DumpPoints() pour décomposer une géométrie complexe en points simples,
-- surtout pour les polygones complexes ou les Multi géométries.
-- Vérifier les résultats avec ST_AsText() pour avoir une meilleure visualisation des points extraits.
-- Créer un index GIST pour optimiser les performances sur les points extraits.

-----------
-----------

---- Extraire les anneaux d’un polygone avec 'ST_DumpRings()'
SELECT (ST_DumpRings(geom)).path AS path, 
       (ST_DumpRings(geom)).geom AS geom
FROM nom_table;

-- Explication :
-- ST_DumpRings(geom) : Cette fonction extrait les anneaux d’un polygone sous forme de LINESTRING.
-- path : Indique la position de l’anneau dans la géométrie.
-- {0} → Anneau extérieur (contour du polygone).
-- {1}, {2}, ... → Anneaux intérieurs (trous du polygone).

-- Bonnes pratiques :
-- Utiliser ST_DumpRings() pour isoler et analyser les anneaux individuels d’un polygone.
-- Vérifier la validité des anneaux avec ST_IsValid() avant toute modification.
-- Créer un index GIST sur les anneaux extraits pour optimiser les requêtes spatiales.

----------

---- Extraire les segments d'une géométrie avec 'ST_DumpSegments()'

SELECT (ST_DumpSegments(geom)).geom AS geom
FROM nom_table;

--Explication :
-- ST_DumpSegments(geom) : Décompose une géométrie linéaire en segments individuels.
-- segment : Retourne chaque segment sous forme de LineString, permettant une analyse plus fine des éléments d'une géométrie.

-- Bonnes pratiques :
-- Utiliser ST_DumpSegments() pour identifier les sous-parties d'un LineString ou d'un Polygon.
-- Créer un index GIST après extraction pour optimiser les recherches spatiales.
-- Vérifier la structure des segments avec ST_AsText() pour une meilleure visualisation.

----------

---- Transformer une collection géométrique en entités individuelles avec "ST_Dump()"
SELECT (ST_Dump(geom)).geom AS geom
FROM nom_table;

--  Explication :
-- ST_Dump(geom) : Décompose une géométrie complexe (MultiPoint, MultiLineString, MultiPolygon) en entités 
--                 individuelles (Point, LineString, Polygon).
--                 Renvoie chaque sous-géométrie séparément sous forme d’un GEOMETRY.
--                 Utile pour convertir des MULTI en SIMPLE avant des traitements SIG.

-- Bonnes pratiques
-- Toujours utiliser ST_Dump() avant ST_Union() pour éviter des erreurs de fusion.
-- Vérifier le type de géométrie avec ST_GeometryType() après décomposition.
-- Créer un index GIST après transformation pour optimiser les performances spatiales.

-----------

---- Comprendre le path dans les fonctions ST_Dump de PostGIS
-- Dans PostGIS, la fonction ST_Dump et ses variantes (ST_DumpRings, ST_DumpSegments, ST_DumpPoints) sont 
-- utilisées pour décomposer des géométries complexes en leurs sous-composantes. Ces fonctions attribuent 
-- un identifiant appelé path, qui permet de repérer la position hiérarchique de chaque élément extrait.
-- Le path est représenté sous forme d’une liste d’indices {x, y, z}, où :
    -- x : Identifie le premier niveau (MultiPolygon, MultiLineString, MultiPoint, GeometryCollection).
    -- y : Indique l’élément interne (un polygone dans un MultiPolygon, un anneau dans un polygone, un segment d’une ligne, etc.).
    -- z : Permet de descendre à un niveau plus profond, comme les points d’un segment de ligne ou d’un polygone.

-- Le tableau suivant détaille l’utilisation du path dans chaque fonction ST_Dump :
---------------------------------------------------------------------------------------------------------------------------------------------
--        Fonction        --                But                --  Type de géométrie extrait   --    Interprétation du path                --
---------------------------------------------------------------------------------------------------------------------------------------------
-- ST_Dump(geom)          -- Décomposer une géométrie multiple --  Point, LineString, Polygon  -- {0} → Premier élément du Multi-objet.    --
--				          -- (MultiPoint, MultiLineString,     --                              -- {1} → Deuxième élément.                  --
--                        -- MultiPolygon, GeometryCollection) --                              -- {2} → Troisième élément, etc.            --
--                        -- en géométries simples.		       --                              --                                          --
---------------------------------------------------------------------------------------------------------------------------------------------
-- ST_DumpSegments(geom)  -- Extraire chaque anneau (contour)  --  LineString (contours)       -- {0} → Anneau extérieur du polygone.      --
-- 			           	  -- d’un polygone (extérieur et       --                              -- {1}, {2} → Anneaux intérieurs (trous).   --	 
--			           	  -- intérieurs).                      --                              --	                                       --
---------------------------------------------------------------------------------------------------------------------------------------------			         
-- ST_DumpSegments(geom)  -- Fractionner une géométrie linéaire-- LineString (segments)	       -- {0} → Premier segment.                   --
--			           	  -- (LineString ou contour de polygone--                              -- {1} → Deuxième segment.                  --
--			           	  -- ) en segments individuels.        --                              -- {2}, etc.                                --
---------------------------------------------------------------------------------------------------------------------------------------------			                    
-- ST_DumpPoints(geom)    -- Extraire chaque sommet (point)    --  Point (sommets)	           -- {0,0} → Premier point du premier élément.--
--			           	  -- d’une géométrie (ligne, polygone, --                              -- {0,1} → Deuxième point du premier élément--
--			           	  -- multipolygone).                   --                              -- {1,0} → Premier point du deuxième élément--	  
--			           	  --                                   --                              -- (ex. anneau intérieur).
---------------------------------------------------------------------------------------------------------------------------------------------
		
-- Exemple d’application du path
-- Prenons un MultiPolygon composé de deux polygones :
    -- Le premier polygone a un trou.
    -- Le deuxième polygone est un polygone simple sans trou.

---------------------------------
-- Table      --     source :  --
---------------------------------
-- ID	      --     GEOM      --
---------------------------------
-- 1	MultiPolygon contenant --
-- deux polygones (un avec     --
-- un trou)                    -- 
---------------------------------


----------------------------------------
-- Résultat avec ST_Dump(geom) :      --
----------------------------------------
-- path	 -- geom (Polygon)    --
--------------------------------
-- {0}	 -- Premier polygone  --
--------------------------------
-- {1}	 -- Deuxième polygone --
--------------------------------

----------------------------------------
-- Résultat avec ST_DumpRings(geom) : --
----------------------------------------
-- path	 -- geom (LineString)    --
-----------------------------------
-- {0}	 -- Contour du premier   --
--       -- polygone (extérieur) --
-----------------------------------
-- {1}	 -- Contour du trou      -- 
--       -- (anneau intérieur)   --
-----------------------------------
-- {2}	Contour du deuxième      -- 
--      polygone                 --
-----------------------------------

-----------------------------------------
-- Résultat avec ST_DumpPoints(geom) : --
-----------------------------------------
-- path	 -- geom (Point)         --
-----------------------------------
-- {0,0} --	Premier sommet du    --
--       -- premier polygone     --
-----------------------------------
-- {0,1} -- Deuxième sommet du   --
--       -- premier polygone     --
-----------------------------------
-- {1,0} --	Premier sommet du    --
--       -- deuxième polygone    --
-----------------------------------

-- Le path permet ainsi d’organiser et d’accéder précisément aux éléments internes 
-- d’une géométrie complexe, facilitant leur manipulation et leur analyse.

----------

-- Créer une ligne à partir de plusieurs points ordonnés avec 'ST_MakeLine()'
SELECT ST_MakeLine(geom ORDER BY path) AS geom
FROM nom_table;

-- Explication :
-- ST_MakeLine(geom ORDER BY path) : Créée une ligne en ordonnant les points 
--                                   selon la colonne path.
-- ST_MakeLine(geom) : Crée une ligne à partir de plusieurs points géométriques 
--                     sans tenir compte de l’ordre.
--                     Retourne un LineString à partir des géométries données.

-- Bonnes pratiques
-- Utiliser ST_MakeLine(geom ORDER BY path) lorsque l'ordre des points est 
-- important pour créer une ligne correcte.
-- Privilégier ST_MakeLine(geom) quand l'ordre des points n’a pas d’importance.
-- Créer un index GIST sur les colonnes géométriques pour améliorer les performances 
-- des opérations de ligne.

----------

---- Créer une ligne avec 'ST_MakeLine()'
SELECT ST_MakeLine(geom) AS geom
FROM nom_table;

-- Explication :
-- ST_MakeLine(geom) : Créée une ligne à partir de plusieurs géométries de type Point, 
--                     mais sans tenir compte de l'ordre.

--  Bonnes pratiques
-- Utiliser ORDER BY avant ST_MakeLine() pour s'assurer que les points sont 
-- correctement ordonnés.
-- Vérifier la validité de la ligne avec ST_IsValid() après création.
-- Créer un index GIST pour accélérer les calculs de géométrie.

----------

---- Créer un polygone à partir de lignes avec 'ST_MakePolygon()'
SELECT ST_MakePolygon(
			resultat_array[1],  -- Anneau extérieur
			resultat_array[2:]  -- Anneaux intérieurs (facultatif)
		) AS geom
FROM nom_table;

-- Explication :
-- ST_MakePolygon(geom1, geom2) : Crée un polygone à partir de deux ensembles de lignes.
   -- geom1 : L'anneau extérieur (la frontière du polygone).
   -- geom2 : Les anneaux intérieurs (les trous ou zones à l'intérieur du polygone, s’il y en a).
-- resultat_array[1] : Le premier élément de l'array (le contour extérieur du polygone).
-- resultat_array[2:] : Les autres éléments de l'array (les anneaux intérieurs).

-- Bonnes pratiques
-- Vérifier que resultat_array[1] contient l'anneau extérieur valide avant de créer le polygone.
-- Créer un index GIST sur la géométrie pour améliorer les performances spatiales.
-- Utiliser ST_IsValid() pour vérifier la validité du polygone créé.

----------

---- Ajouter un point au début d'une géométrie avec 'ST_AddPoint()' et 'ST_StartPoint()'
SELECT ST_AddPoint(geom1, ST_StartPoint(geom1)) AS geom
FROM nom_table;

-- Explication :
-- ST_StartPoint(geom1) : Retourne le premier point d'une géométrie de type
--                        LineString ou Polygon.
-- ST_AddPoint(geom1, point) : Ajoute un point à geom1.

-- Bonnes pratiques
-- Utiliser ST_StartPoint() pour accéder au premier point d'une géométrie LineString ou Polygon.
-- Vérifier la validité de la géométrie après modification avec ST_IsValid().
-- Créer un index GIST sur les colonnes géométriques pour optimiser les calculs géométriques.

----------

---- Créer une géométrie vide avec 'ST_GeomFromText('POLYGON EMPTY', 2154)'
SELECT ST_GeomFromText('POLYGON EMPTY', 2154) AS geom;

-- Explication :
-- ST_GeomFromText('POLYGON EMPTY', 2154) : Génère un polygone vide dans le système de coordonnées 
--                                          EPSG:2154 (Lambert 93, utilisé en France).
--                                          Le résultat est un objet GEOMETRY valide mais sans contenu.

-- Bonnes pratiques :
-- Utiliser ST_IsEmpty() pour tester si une géométrie est vide.
-- Éviter d'insérer des géométries vides dans des analyses spatiales où elles ne sont pas utiles.


-----------------------
-- FONCTIONS PLPGSQL --
-----------------------

---- Vérifier l’existence d’une table et insérer des données si nécessaire avec un bloc "DO $$"
DO $$ 
BEGIN 
    -- Vérifie si la table existe dans le schéma spécifié
    IF EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'nom_schema' 
        AND table_name = 'nom_table'
    ) THEN
        -- Vérifie si la table est vide
        IF NOT EXISTS (
            SELECT 1 FROM "nom_schema"."nom_table" LIMIT 1
        ) THEN
            RAISE NOTICE 'La table nom_table est vide. Création des données...';
            
            -- Supprime la table pour éviter les conflits
            DROP TABLE IF EXISTS "nom_schema"."nom_table";
            
            -- Crée la table avec les nouvelles données
            CREATE TABLE "nom_schema"."nom_table" AS 
            WITH unioned AS (
                -- Sélectionne les entités correspondantes
                SELECT 
                    ST_Force2D(ST_Intersection(ST_Union(t.geom), ST_Union(b.geom))) AS geom, 
                    'valeur1' AS colonne1,
                    'valeur2' AS colonne2,
                    'valeur3' AS colonne3,
                    c.id
                FROM nom_source1 t
                JOIN nom_source2 b ON ST_Intersects(t.geom, b.geom)
                JOIN nom_source3 c ON ST_Intersects(b.geom, c.geom)
                WHERE t.nom_colonne = 'valeur_condition'
                GROUP BY t.nom_colonne, t.geom, c.id

                UNION ALL

                -- Deuxième sélection
                SELECT 
                    ST_Force2D(ST_Intersection(b.geom, c.geom)) AS geom, 
                    'valeur4' AS colonne1,
                    'valeur5' AS colonne2,
                    'valeur6' AS colonne3,
                    c.id
                FROM nom_source2 b
                JOIN nom_source3 c ON ST_Intersects(b.geom, c.geom)
                WHERE b.nom_colonne = 'valeur_condition2'
            )
            SELECT 
                row_number() OVER () AS id, 
                geom, 
                colonne1, 
                colonne2, 
                colonne3, 
                id 
            FROM unioned;
        ELSE
            RAISE NOTICE 'La table nom_table contient déjà des données.';
        END IF;
    END IF;
END $$;

-- Explication :
-- Vérifie si la table "nom_table" existe dans le schéma "nom_schema".
-- Si elle existe, vérifie si elle est vide.
-- Si elle est vide, la recrée et insère les données.
-- Utilise ST_Intersection(), ST_Union(), et ST_Force2D() pour gérer les géométries.

-- Bonnes pratiques
-- Utiliser IF NOT EXISTS pour éviter les erreurs lors de la création d’objets.
-- Créer un index GIST après la création d’une table spatiale.
-- Tester avec RAISE NOTICE pour afficher des messages de validation.

----------

---- Créer ou remplacer une fonction avec 'CREATE OR REPLACE FUNCTION'
CREATE OR REPLACE FUNCTION nom_fonction(paramètres)
RETURNS type_retour AS $$
BEGIN
    -- Corps de la fonction
END;
$$ LANGUAGE plpgsql;

-- Explication :
-- CREATE OR REPLACE FUNCTION : Cette commande permet de créer une fonction dans PostgreSQL (ou de la remplacer si 
--                              elle existe déjà) sans avoir à la supprimer manuellement au préalable.
-- nom_fonction : Le nom de la fonction que tu veux créer ou remplacer.
-- paramètres : Les paramètres d'entrée de la fonction, si nécessaire. Tu peux définir les types de chaque paramètre.
-- RETURNS type_retour : Déclare le type de données que la fonction renverra (par exemple, INTEGER, TEXT, BOOLEAN, GEOMETRY, etc.).
-- PL/pgSQL : Langage utilisé pour définir le corps de la fonction. C'est le langage procédural de PostgreSQL,
--            mais tu peux utiliser aussi d'autres langages comme SQL, plpythonu, etc.

-- Bonnes pratiques :
-- Gestion des erreurs : Utilise des blocs EXCEPTION pour gérer les erreurs dans tes fonctions, surtout si elles
--                       manipulent des données sensibles ou complexes.
-- Commentaires : Ajoute des commentaires dans le code de ta fonction pour faciliter la maintenance et la 
--                compréhension par d'autres développeurs.

----------

---- Utilisation de 'DECLARE' dans une fonction PostgreSQL

-- Dans PostgreSQL, le mot-clé DECLARE est utilisé pour déclarer des variables locales au début d'une fonction ou d'un bloc de code. 
-- Ces variables peuvent ensuite être utilisées dans le corps de la fonction.
CREATE OR REPLACE FUNCTION nom_fonction(paramètres)
RETURNS type_retour AS $$
DECLARE
    -- Déclaration des variables locales
    variable1 type1;
    variable2 type2;
BEGIN
    -- Corps de la fonction
    -- Utilisation des variables
    variable1 := valeur1;
    variable2 := valeur2;
    RETURN resultat;  -- Retourne une valeur (si la fonction a un type de retour autre que VOID)
END;
$$ LANGUAGE plpgsql;

-- Explication :
-- DECLARE : Ce mot-clé est utilisé pour définir des variables qui seront uniquement accessibles à l'intérieur de la fonction 
--           ou du bloc où elles sont déclarées. Elles sont généralement définies avec un type de données spécifique.
-- variable1 type1; : Exemple de déclaration d'une variable nommée variable1 de type type1 (par exemple, INTEGER, TEXT, BOOLEAN,
--                    GEOMETRY, etc.).
-- BEGIN ... END : Tout le code de la fonction se trouve à l'intérieur du bloc BEGIN ... END. C'est dans ce bloc que tu peux
--                 utiliser les variables déclarées.

-- Bonnes pratiques :
-- Initialisation des variables : Toujours initialiser les variables avant de les utiliser dans le corps de la fonction, 
-- surtout si elles doivent être affectées dans des calculs ou des conditions.
-- Types compatibles : Assure-toi que le type des variables déclarées correspond à l'utilisation prévue.
-- Lisibilité : Donne des noms explicites à tes variables pour rendre le code plus compréhensible.

----------

---- Utilisation de 'FOR variable IN SELECT' dans une fonction PostgreSQL

-- La structure FOR variable IN SELECT ... est une boucle en PL/pgSQL qui permet de parcourir un ensemble de résultats retournés
-- par une requête SELECT. Elle permet de traiter chaque ligne du résultat de manière itérative.
FOR variable IN
    SELECT nom_colonne
    FROM nom_table
LOOP
    -- Corps de la boucle : traitement de chaque ligne
    -- variable peut être utilisée pour accéder à chaque valeur
END LOOP;

-- Explication :
-- FOR variable IN : Cette syntaxe permet d'itérer sur les résultats d'une requête SELECT. À chaque itération, une ligne du résultat 
--                   est affectée à la variable.
-- SELECT 'nom_colonne FROM nom_table : La requête retourne un ensemble de valeurs (ici des valeurs d'une colonne appelée 
--                                      'nom_colonne' dans la table nom_table), et la boucle les traite une par une.
-- variable : C'est la variable qui va contenir chaque valeur retournée par la requête à chaque itération. 
--            Tu peux utiliser cette variable dans le corps de la boucle.

-- Bonnes pratiques :
-- Limiter les résultats : Si la requête renvoie un grand nombre de lignes, il peut être judicieux de la limiter (avec WHERE, LIMIT, etc.)
--                         pour éviter de surcharger la fonction et ses performances.
-- Gestion des erreurs : Si nécessaire, utilise des blocs EXCEPTION pour gérer des erreurs dans le traitement de chaque ligne,
--                       comme un problème avec une valeur de colonne.
-- Optimisation : Assure-toi que la requête dans le FOR est bien optimisée.

----------

----- Utilisation de 'LIMIT' dans une requête SQL
-- Le mot-clé LIMIT est utilisé pour restreindre le nombre de lignes retournées par une requête SQL. Cela peut être particulièrement 
-- utile lorsque tu ne veux traiter qu'un sous-ensemble des résultats, par exemple, pour tester une requête, limiter le nombre de 
-- résultats retournés ou éviter une surcharge dans des boucles.

SELECT nom_colonne
FROM nom_table
LIMIT 'valeur';

-- Explication :
-- LIMIT n : Limite le nombre de lignes retournées à n, où n est un entier positif.
-- LIMIT dans une boucle FOR : Si tu utilises une boucle FOR dans une fonction PL/pgSQL, tu peux aussi appliquer un LIMIT dans la requête
--                             pour ne traiter qu'un nombre restreint de résultats.

-- Bonnes pratiques :
-- Utiliser avec ORDER BY : Si tu veux que les résultats soient retournés dans un ordre spécifique, utilise ORDER BY avec LIMIT.
-- Gestion des résultats : Si tu utilises LIMIT dans des boucles ou des traitements, sois conscient que tu pourrais ne pas traiter 
--                         tous les résultats. Assure-toi que cette limitation est bien intentionnelle.

----------

---- Utilisation de LOOP en PL/pgSQL (PostgreSQL)
-- Le LOOP est une structure de contrôle en PL/pgSQL qui permet d'exécuter un bloc d'instructions de manière répétée. 
-- C'est une boucle infinie, qui continue à s'exécuter jusqu'à ce qu'elle rencontre un EXIT ou une autre condition d'arrêt explicite.

LOOP
    -- Instructions à exécuter à chaque itération
    -- Condition d'arrêt avec EXIT ou une autre logique
END LOOP;

-- Explication :
-- LOOP : Lance une boucle qui répète un bloc de code.
-- EXIT : Une instruction qui permet de sortir de la boucle. Cette instruction est souvent utilisée avec une condition 
--        (par exemple, un test de valeur ou une limite de nombre d'itérations).
-- Condition d'arrêt : Sans une condition explicite, la boucle sera infinie, il faut donc s'assurer qu'il existe une 
--                     logique pour sortir de la boucle, généralement avec EXIT WHEN.

-- Bonnes pratiques :
-- Condition d'arrêt : Toujours avoir une condition d'arrêt dans une boucle pour éviter les boucles infinies.
--                     Utilise EXIT WHEN pour rendre l'arrêt plus explicite et lisible.
-- Optimisation : Si la boucle parcourt un grand nombre de résultats, veille à optimiser les requêtes ou les calculs 
--                effectués à chaque itération pour ne pas nuire aux performances.
-- Gestion des erreurs : Utilise des blocs EXCEPTION pour capturer et gérer des erreurs dans la boucle si nécessaire.

----------

---- Utilisation de 'RAISE NOTICE' en PL/pgSQL
-- La commande RAISE NOTICE en PostgreSQL est utilisée pour afficher des messages dans le journal (log) du serveur, 
-- ce qui peut être très utile pour le débogage, l'affichage d'informations intermédiaires ou pour signaler des événements dans une fonction.

RAISE NOTICE 'Message à afficher';

-- Explication :
-- RAISE NOTICE : Cette instruction génère un message qui sera affiché dans les logs de PostgreSQL, mais qui ne bloque
--                pas l'exécution de la fonction (contrairement à des exceptions).
-- 'Message à afficher' : Le message que tu souhaites afficher. Cela peut être un simple texte ou une valeur dynamique, 
--                        par exemple une variable ou un champ de table.

-- Bonnes pratiques :
-- Niveau de détail : Utilise RAISE NOTICE pour des informations non critiques, comme des messages de suivi ou de débogage. 
--                    Pour des erreurs graves, tu devrais utiliser RAISE EXCEPTION.
-- Messages clairs : Fournis des messages explicites pour aider à comprendre rapidement ce qui se passe dans la fonction.
-- Performance : L'affichage des messages avec RAISE NOTICE peut ralentir l'exécution si utilisé excessivement, surtout dans des boucles. 
--               Utilise-le principalement pour le débogage et supprime-le une fois que tout est fonctionnel.

----------

---- Utilisation de 'TRUNCATE' en SQL (PostgreSQL)
-- TRUNCATE est une commande SQL qui permet de supprimer rapidement toutes les lignes d'une table sans supprimer la table elle-même. 
-- Contrairement à DELETE, TRUNCATE est généralement beaucoup plus rapide, car il ne génère pas de journaux pour chaque ligne supprimée.

TRUNCATE TABLE nom_table;

-- Explication :
-- TRUNCATE TABLE : Cette commande vide une table, c'est-à-dire qu'elle supprime toutes les lignes de la table sans condition. 
--                  La structure de la table (les colonnes, les contraintes, etc.) reste intacte.
--                  L'opération TRUNCATE est plus rapide que DELETE car elle ne génère pas un journal d'opérations pour chaque ligne supprimée, 
--                  elle modifie plutôt les pointeurs dans les fichiers de la table.
--                  En PostgreSQL, TRUNCATE réinitialise aussi les compteurs des colonnes de type SERIAL ou BIGSERIAL
--                  (les identifiants auto-incrémentés), sauf si tu spécifies autrement avec l'option RESTART IDENTITY.

-- Bonnes pratiques :
-- Utiliser avec précaution : TRUNCATE est une commande irréversible, et il est important de t'assurer que tu veux réellement supprimer toutes 
--                            les données avant de l'exécuter.
-- Transaction : Pour plus de sécurité, exécuter la commande TRUNCATE dans une transaction permet de pouvoir annuler l'opération en cas d'erreur.
-- Contrainte de clé étrangère : Si la table que tu souhaites vider est référencée par d'autres tables avec des contraintes de clé étrangère, 
--                               veille à utiliser CASCADE ou gérer les relations de manière appropriée pour éviter les erreurs.

----------

---- Insérer des données dans une table avec 'INSERT INTO'
INSERT INTO nom_table (identifiant, nom_zone, geom)
VALUES ('identifiant', 'nom_zone', 'geom');



-- Explication :
-- INSERT INTO zones_risque (id, nom_zone, geom) : Ajoute une nouvelle ligne dans la table nom_table, en précisant les colonnes à remplir.
-- VALUES (..., ..., ...) : valeurs des colonnes.

-- Bonnes pratiques :
-- Toujours préciser les colonnes pour éviter les erreurs si la structure de la table change.
-- Utiliser ST_GeomFromText() pour manipuler des données géospatiales sous forme de texte.
-- Vérifier que l'identifiant est unique si c'est une clé primaire.
-- Utiliser RETURNING * pour récupérer l’ID ou d'autres informations après insertion.

----------

---- Insérer des données depuis une autre table avec 'INSERT INTO' ... 'SELECT'
INSERT INTO nom_table2 (nom_zone, geom)
SELECT nom_zone, geom 
FROM nom_table1 
WHERE niveau_risque > 3;

-- Explication :
-- INSERT INTO nom_table2 (nom_zone, geom) : Ajoute plusieurs enregistrements à la table nom_table2, en récupérant les valeurs depuis une autre 
--                                           table (nom_table1).
-- SELECT : Récupère toutes les données issues du traitements suivant le 'SELECT'.

-- Bonnes pratiques :
-- Toujours tester la requête SELECT seule avant d'exécuter INSERT INTO ... SELECT pour s'assurer que les données récupérées sont correctes.
-- S’assurer que les types de colonnes correspondent entre les deux tables.
-- Utiliser des filtres (WHERE) pour éviter d’insérer des données non pertinentes.

----------