
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                      MODULE 0 Prétraitements sur la base de données                                      ----
----     Traitements sous PostgreSQL/PostGIS pour créer les schémas utiles aux calculs des OLD                ----
----                                                                                                          ----
----  Auteur          : Marie-Jeanne MARTINAT                                                                 ----
----  Version         : 0.0                                                                                   ----
----  License         : GNU GENERAL PUBLIC LICENSE  Version 3                                                 ----
----  Documentation   :                                                                                       ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

-- ======================================================
-- CRÉATION DU SCHÉMA DES ZONAGES URBAINS 
-- Objectif : stocker les données des zonages urbains de chaque commune 
-- ======================================================
DROP SCHEMA IF EXISTS "26_zonage_urba" CASCADE;           -- Supprime le schéma des résultat s’il existe
COMMIT;                                                   -- Valide la suppression
CREATE SCHEMA "26_zonage_urba";                           -- Crée le schéma des résultats
COMMIT;                                                   -- Valide la création

-- ======================================================
-- CRÉATION DU SCHÉMA DES RESULTATS 
-- Objectif : stocker les données résultantes (zonage_global et résultats finaux)
-- ======================================================
DROP SCHEMA IF EXISTS "26_old50m_resultat" CASCADE;       -- Supprime le schéma des résultat s’il existe
COMMIT;                                                   -- Valide la suppression
CREATE SCHEMA "26_old50m_resultat";                       -- Crée le schéma des résultats
COMMIT;                                                   -- Valide la création

-- ======================================================
-- CRÉATION DU SCHÉMA DES PARCELLES
-- Objectif : stocker les données cadastrales (parcelles et unités foncières)
-- ======================================================
DROP SCHEMA IF EXISTS "26_old50m_parcelle" CASCADE;       -- Supprime le schéma des parcelles s’il existe
COMMIT;                                                   -- Valide la suppression
CREATE SCHEMA "26_old50m_parcelle";                       -- Crée le schéma des parcelles
COMMIT;                                                   -- Valide la création

-- ======================================================
-- CRÉATION DU SCHÉMA DES BÂTIMENTS
-- Objectif : accueillir les données liées aux constructions bâties
-- ======================================================
DROP SCHEMA IF EXISTS "26_old50m_bati" CASCADE;           -- Supprime le schéma des bâtiments existant
COMMIT;                                                   -- Valide la suppression
CREATE SCHEMA "26_old50m_bati";                           -- Crée le schéma des bâtiments
COMMIT;                                                   -- Valide la création
