[//]: # (0x4d4a)

# Projets

> Réalisations techniques développées en contexte public.  
> Chaque projet est documenté, versionné et conçu pour être maintenable par d'autres équipes.

---

## OLD50m

[![GitLab](https://img.shields.io/badge/GitLab-old50m-FC6D26?style=flat-square&logo=gitlab&logoColor=white)](https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/old50m)
![Statut](https://img.shields.io/badge/Statut-Transféré_IGN_(national)-22c55e?style=flat-square)

**Co-création · SQL / PostGIS**

| | |
|---|---|
| Contexte | DDT de la Drôme — 2023/2025 |
| Stack | PostgreSQL · PostGIS · SQL · SLD |
| Impact | Repris à l'échelle nationale par l'IGN |

**Description**  
Outil de traitement et d'analyse géospatiale des données OLD (Occupation des Logements et Densité). Conçu en co-création, documenté pour permettre un transfert autonome à l'IGN pour déploiement national.

**Points techniques notables**
- Architecture SQL reproductible et paramétrable
- Requêtes PostGIS optimisées sur grands volumes
- Documentation technique orientée reprise externe

---

## cartOLD

[![GitLab](https://img.shields.io/badge/GitLab-cartOLD-FC6D26?style=flat-square&logo=gitlab&logoColor=white)](https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/cartOLD)
[![Live](https://img.shields.io/badge/🟢_Application_live-ssm--ecologie.shinyapps.io-009FDA?style=flat-square)](https://ssm-ecologie.shinyapps.io/cartOLD/)
![Statut](https://img.shields.io/badge/Statut-Déployé_multi--publics-22c55e?style=flat-square)

**Création · RShiny Golem · Application web**

| | |
|---|---|
| Contexte | DDT de la Drôme — 2023/2025 |
| Stack | R · RShiny · Golem · RMarkdown · CSS · JavaScript |
| Volume | 14 scripts R · CSS/JS personnalisés · RMarkdown intégré |

**Description**  
Application web interactive de cartographie et d'analyse des données OLD, déployée pour plusieurs publics (agents DDT, partenaires institutionnels). Développée avec le framework Golem pour une architecture modulaire et maintenable.

**Points techniques notables**
- Architecture Golem (modules, tests, packaging R)
- Habillage CSS/JS sur mesure
- Exports RMarkdown dynamiques intégrés à l'application
- Déployée sur Shiny Server avec gestion des droits d'accès multi-publics

---

## BSécheresse

[![GitLab](https://img.shields.io/badge/GitLab-BSécheresse-FC6D26?style=flat-square&logo=gitlab&logoColor=white)](https://gitlab-forge.din.developpement-durable.gouv.fr/pub/dd/ddt-26-public/bsecheresse)
![Statut](https://img.shields.io/badge/Statut-Opérationnel-22c55e?style=flat-square)

**Création · R · RMarkdown · Reporting automatisé**

> ⚠️ *URL GitLab reconstruite par analogie — à corriger si le slug exact diffère.*

| | |
|---|---|
| Contexte | DDT de la Drôme — 2023/2025 |
| Stack | R · RMarkdown · HTML · CSS · LaTeX · JavaScript |
| Volume | 12 scripts R · 2 CSS · 1 JS · 7 scripts de développement |

**Description**  
Outil de suivi et de reporting sur les indicateurs de sécheresse à l'échelle du département. Production de livrables HTML, PDF (LaTeX) et rapports automatisés.

**Points techniques notables**
- Pipeline de traitement R entièrement automatisé
- Sorties multi-formats : HTML interactif, PDF LaTeX, RMarkdown
- Scripts de développement séparés des scripts de production

---

## Observatoire du territoire drômois

![Statut](https://img.shields.io/badge/Statut-Opérationnel-22c55e?style=flat-square)
![Accès](https://img.shields.io/badge/Accès-GitLab_institutionnel_interne-grey?style=flat-square)

**Création · RShiny · Analyse territoriale**

| | |
|---|---|
| Contexte | DDT de la Drôme — Alternance 2022/2023 |
| Stack | R · RShiny · RStudio |

**Description**  
Application Shiny de visualisation et d'analyse des données territoriales drômoises, développée dans le cadre de l'alternance. Première brique d'une série d'outils ayant évolué vers cartOLD.

---

## Priorisation PPRN — DREAL BFC

![Accès](https://img.shields.io/badge/Accès-GitLab_institutionnel_interne-grey?style=flat-square)

**Méthodologie · Model Builder · QGIS**

| | |
|---|---|
| Contexte | DREAL Bourgogne-Franche-Comté — Stage 2021/2022 |
| Stack | QGIS · Modele CCR · Model Builder · ASTER'X |

**Description**  
Méthodologie de priorisation pour l'élaboration et la révision des Plans de Prévention des Risques Naturels (PPRN). Automatisation par Model Builder — coordination COPIL avec les DDTs de la région. Projet confidentiel.

---

## Organisation du répertoire

```
projets/
├── OLD50m/
│   ├── README.md
│   └── ...
├── cartOLD/
│   ├── README.md
│   └── ...
├── BSécheresse/
│   ├── README.md
│   └── ...
└── observatoire-territoire/
    ├── README.md
    └── ...
```

---

<sub>Projets publics hébergés sur la forge GitLab du Ministère de la Transition Écologique. Les projets internes sont accessibles sur demande.</sub>
