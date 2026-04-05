# Historique des versions - cartOLD

## Version 0.0.1 (2025)

### Première version de production

**Fonctionnalités principales**

- Carte interactive Leaflet plein écran
- Sélection de commune avec zoom automatique
- Recherche d'adresse via API BAN (Base Adresse Nationale)
- Affichage dynamique des couches géographiques
- Export de la carte en PNG et PDF

**Couches cartographiques**

- Limites départementales (Drôme)
- Limites communales
- Zones OLD 200 mètres (zones à risques)
- Zones OLD 50 mètres (zones à débroussailler)
- Parcelles cadastrales
- Bâtiments
- Zonage urbain PLU (Plan Local d'Urbanisme)

**Contrôles et navigation**

- Échelle numérique dynamique (format 1:xxxxx)
- Échelle graphique avec segments noir et blanc
- Rose des vents avec indicateur Nord
- Légende dynamique adaptée aux couches affichées
- Toggle sidebar pour afficher/masquer les contrôles

**Interface utilisateur**

- Page d'accueil avec présentation de l'application
- Modale d'avertissement au démarrage
- Navbar avec liens vers mentions légales et confidentialité
- Interface responsive adaptée aux différentes tailles d'écran

**Performance et optimisation**

- Cache des données spatiales avec memoise
- Chargement asynchrone des tuiles de carte
- Gestion optimisée des couches Leaflet (show/hide)

**Export et impression**

- Capture de la carte via html2canvas
- Génération de PDF via RMarkdown
- Aperçu de l'export avant téléchargement

**Technologies**

- R 4.5.1
- Shiny 1.11.1
- Leaflet pour la cartographie interactive
- sf pour les données spatiales
- API BAN pour le géocodage
