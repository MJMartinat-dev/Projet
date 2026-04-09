# ──────────────────────────────────────────────────────────────────────────────
# SCRIPT      : render_bulletin.R
# ──────────────────────────────────────────────────────────────────────────────
# AUTEUR      : MJMartinat
# DATE        : 2025-01-07
# DESCRIPTION : Génération automatique du bulletin sécheresse (PDF + HTML)
# SORTIE      : sorties/bulletins/pdf + sorties/bulletins/html
# ──────────────────────────────────────────────────────────────────────────────
# CHARGEMENT DES BIBLIOTHÈQUES
# ──────────────────────────────────────────────────────────────────────────────
library(rmarkdown)                                                              # Conversion Rmd vers PDF/HTML
library(here)                                                                   # Gestion chemins relatifs
library(glue)                                                                   # Interpolation variables

# ──────────────────────────────────────────────────────────────────────────────
# DÉFINITION DE LA DATE
# ──────────────────────────────────────────────────────────────────────────────
date_enregistrement <- format(Sys.Date(), "%Y-%m-%d")                           # Date au format AAAA-MM-JJ

# ──────────────────────────────────────────────────────────────────────────────
# GÉNÉRATION DU BULLETIN PDF
# ──────────────────────────────────────────────────────────────────────────────
rmarkdown::render(
  input = here::here("fichiers", "Rmd", "bulletin_secheresse.Rmd"),             # Template source
  output_format = "pdf_document",                                               # Format PDF
  output_file = glue("Bulletin_Secheresse_{date_enregistrement}.pdf"),          # Nom fichier
  output_dir = here::here("sorties", "bulletins", "pdf")                        # Dossier destination
)

# ──────────────────────────────────────────────────────────────────────────────
# GÉNÉRATION DU BULLETIN HTML
# ──────────────────────────────────────────────────────────────────────────────
rmarkdown::render(
  input = here::here("fichiers", "Rmd", "bulletin_secheresse.Rmd"),             # Template source
  output_format = "html_document",                                              # Format HTML
  output_file = glue("Bulletin_Secheresse_{date_enregistrement}.html"),         # Nom fichier
  output_dir = here::here("sorties", "bulletins", "html")                       # Dossier destination
)
