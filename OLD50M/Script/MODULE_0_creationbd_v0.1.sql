--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----                      MODULE 0 Prétraitements sur la base de données                                      ----
----     Traitements sous PostgreSQL/PostGIS pour créer les schémas utiles aux calculs des OLD                ----
----                                                                                                          ----
----  Auteur          : Marie-Jeanne MARTINAT                                                                 ----
----  Version         : 0.1                                                                                   ----
----  License         : GNU GENERAL PUBLIC LICENSE  Version 3                                                 ----
----  Documentation   : https://gitlab-forge.din.developpement-durable.gouv.fr/frederic.sarret/old_50m/       ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--
----   INTEGRATION DU NUMERO DE DEPARTEMENT                                                                   ----
----                                                                                                          ----
----   Remplacer "XX" par votre numéro de département, exemple "13"                                           ----
--*------------------------------------------------------------------------------------------------------------*--
--*------------------------------------------------------------------------------------------------------------*--

DO $$
DECLARE
    -- ============================================
    -- Paramètre principal : code du département
    -- ============================================
    departement TEXT := 'XX';  -- <<< À adapter : ex. '13' pour les Bouches-du-Rhône

    -- ============================================
    -- Variables dynamiques pour les schémas
    -- ============================================
    schema_resultat TEXT;
    schema_parcelle TEXT;
    schema_bati     TEXT;
BEGIN
    -- =====================================================
    -- Construction dynamique des noms de schémas (SANS %I)
    -- =====================================================
    schema_resultat := departement || '_old50m_resultat';  -- Schéma des résultats de calculs OLD
    schema_parcelle := departement || '_old50m_parcelle';  -- Schéma des données cadastrales
    schema_bati     := departement || '_old50m_bati';      -- Schéma des données bâties

    -- =====================================================
    -- Création du schéma des RÉSULTATS OLD
    -- =====================================================
    EXECUTE 'DROP SCHEMA IF EXISTS ' || quote_ident(schema_resultat) || ' CASCADE;'; -- Supprime l'ancien schéma
    EXECUTE 'CREATE SCHEMA ' || quote_ident(schema_resultat) || ';';                 -- Crée le schéma neuf
    RAISE NOTICE 'Schéma % créé avec succès.', schema_resultat;

    -- =====================================================
    -- Création du schéma des PARCELLES
    -- =====================================================
    EXECUTE 'DROP SCHEMA IF EXISTS ' || quote_ident(schema_parcelle) || ' CASCADE;'; -- Supprime l'ancien schéma
    EXECUTE 'CREATE SCHEMA ' || quote_ident(schema_parcelle) || ';';                 -- Crée le schéma neuf
    RAISE NOTICE 'Schéma % créé avec succès.', schema_parcelle;

    -- =====================================================
    -- Création du schéma des BÂTIMENTS
    -- =====================================================
    EXECUTE 'DROP SCHEMA IF EXISTS ' || quote_ident(schema_bati) || ' CASCADE;';     -- Supprime l'ancien schéma
    EXECUTE 'CREATE SCHEMA ' || quote_ident(schema_bati) || ';';                     -- Crée le schéma neuf
    RAISE NOTICE 'Schéma % créé avec succès.', schema_bati;

    -- =====================================================
    -- Validation et résumé final
    -- =====================================================
    RAISE NOTICE 'Tous les schémas ont été créés pour le département %.', departement;
END $$;