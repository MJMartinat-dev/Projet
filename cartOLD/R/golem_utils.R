# ──────────────────────────────────────────────────────────────────────────────
# FICHIER     : R/golem_utils.R
# AUTEUR      : MJ Martinat
# DATE        : 2025
# ORGANISATION: DDT de la Drôme
# DESCRIPTION : Fonctions utilitaires liees ou non a golem et a shiny
# ──────────────────────────────────────────────────────────────────────────────
# Conversion d'une liste R en liste HTML <li>
# ──────────────────────────────────────────────────────────────
#' Convertir une liste R en liste HTML <li>
#'
#' @param list An R list
#' @param class a class for the list
#'
#' @return an HTML list
#'
#' @examples
#' list_to_li(c("a", "b"))
#'
#' @importFrom shiny tags tagAppendAttributes tagList
#'
#' @noRd
list_to_li <- function(list, class = NULL) {                                    # Transforme un vecteur/liste R en liste HTML (<li>)
  if (is.null(class)) {                                                         # Cas simple : aucune classe CSS fournie
    tagList(                                                                    # Regroupe les elements <li> dans un tagList (liste de tags HTML)
      lapply(                                                                   # Applique tags$li a chaque element de 'list'
        list,                                                                   # Donnees source (vecteur ou liste R)
        tags$li                                                                 # Constructeur de balise <li> (contenu textuel implicite)
      )
    )
  } else {                                                                      # Cas avec classe CSS fournie
    res <- lapply(                                                              # Cree une liste de balises <li> a partir des elements de 'list'
      list,
      tags$li
    )
    res <- lapply(                                                              # Parcourt chaque <li> pour lui ajouter la classe CSS
      res,
      function(x) {                                                             # Fonction anonyme appliquee a chaque element <li>
        tagAppendAttributes(                                                    # Ajoute/modifie les attributs HTML de la balise
          x,                                                                    # Tag HTML cible (balise <li>)
          class = class                                                         # Ajoute l'attribut class avec la valeur passee en argument
        )
      }
    )
    tagList(res)                                                                # Retourne la liste de <li> enrichis, packagee dans un tagList
  }
}

# ──────────────────────────────────────────────────────────────
# Conversion d'une liste R en paragraphes <p>
# ──────────────────────────────────────────────────────────────
#' Convertir une liste R en paragraphes <p>
#'
#' @param list an R list
#' @param class a class for the paragraph tags
#'
#' @return An HTML tag
#'
#' @examples
#' list_to_p(c("This is the first paragraph", "this is the second paragraph"))
#'
#' @importFrom shiny tags tagAppendAttributes tagList
#'
#' @noRd
list_to_p <- function(list, class = NULL) {                                     # Transforme un vecteur/liste R en suite de <p> HTML
  if (is.null(class)) {                                                         # Si aucune classe CSS n’est specifiee
    tagList(                                                                    # Enveloppe la liste de <p> dans un objet tagList (structure HTML Shiny)
      lapply(                                                                   # Applique la meme fonction a chaque element de 'list'
        list,                                                                   # Donnees source a transformer en balises <p>
        tags$p                                                                  # Genere une balise <p> par element, contenu textuel implicite
      )
    )
  } else {                                                                      # Sinon, une classe CSS doit etre appliquee a chaque <p>
    res <- lapply(                                                              # Premiere passe : creer les balises <p> pour chaque element
      list,
      tags$p
    )
    res <- lapply(                                                              # Deuxieme passe : ajouter la classe CSS a chaque balise <p>
      res,
      function(x) {                                                             # Fonction anonyme appliquee a chaque element de la liste de tags
        tagAppendAttributes(                                                    # Ajoute des attributs HTML a la balise
          x,                                                                    # Balise <p> cible
          class = class                                                         # Ajout de l’attribut class avec la valeur donnee
        )
      }
    )
    tagList(res)                                                                # Emballe les balises finales dans un tagList (structure consolidee)
  }
}

# ──────────────────────────────────────────────────────────────
# Conversion d'une liste R nommee en <li> etiquetes
# ──────────────────────────────────────────────────────────────
#' Convertir une liste R nommee en elements HTML <li>
#'
#' Cette fonction transforme une liste R **nommee** en une serie de balises HTML
#' `<li>`.
#' Le **nom de chaque element** devient une etiquette affichee en gras, et la
#' **valeur** est inseree apres les deux-points.
#'
#' Si une classe CSS est fournie, elle est appliquee a **chaque** element `<li>`.
#'
#' @param list Une liste R **nommee**.
#'        Les noms des elements servent de labels, les valeurs servent de contenus.
#' @param class Une classe CSS optionnelle a appliquer a chaque balise `<li>`.
#'
#' @return Un objet `shiny::tagList` contenant les balises `<li>` generees.
#'
#' @examples
#' named_to_li(list(a = "Valeur A", b = "Valeur B"))
#' named_to_li(list(clef1 = "Premier", clef2 = "Second"), class = "ligne-item")
#'
#' @importFrom shiny tags tagAppendAttributes tagList HTML
#'
#' @noRd
named_to_li <- function(list, class = NULL) {                                   # Transforme une liste nommee en liste HTML <li> avec nom en gras
  if (is.null(class)) {                                                         # Cas sans classe CSS specifiee
    res <- mapply(                                                              # mapply : associe noms et valeurs simultanement
      function(x, y) {                                                          # x = valeur, y = nom de l’element
        tags$li(                                                                # Genere une balise <li>
          HTML(                                                                 # Interprete le contenu comme HTML
            sprintf("<b>%s:</b> %s", y, x)                                      # Format : "<b>nom :</b> valeur"
          )
        )
      },
      list,                                                                     # Valeurs de la liste
      names(list),                                                              # Noms correspondants
      SIMPLIFY = FALSE                                                          # On retourne une liste de tags, pas un vecteur
    )
    tagList(res)                                                                # Regroupe les <li> dans un tagList
  } else {                                                                      # Cas où une classe CSS doit etre ajoutee
    res <- mapply(                                                              # Generation de base des balises <li>
      function(x, y) {                                                          # Fonction anonyme recevant x = valeur, y = nom de l’element
        tags$li(                                                                # Creation d’une balise HTML <li>
          HTML(                                                                 # Interpretation du texte comme contenu HTML (et non texte brut)
            sprintf("<b>%s:</b> %s", y, x)                                      # Formatage : nom en gras suivi de la valeur (genere "<b>nom:</b> valeur")
          )                                                                     # Fin HTML()
        )                                                                       # Fin balise <li>
      },                                                                        # Fin fonction anonyme
      list,
      names(list),
      SIMPLIFY = FALSE
    )
    res <- lapply(                                                              # Application de la classe CSS a chaque <li>
      res,
      function(x) {                                                             # Fonction appliquee a chaque balise
        tagAppendAttributes(                                                    # Ajout d'attributs HTML
          x,                                                                    # Balise <li> cible
          class = class                                                         # Ajout de la classe CSS fournie
        )
      }
    )
    tagList(res)                                                                # Retourne toutes les balises enrichies
  }
}

# ──────────────────────────────────────────────────────────────
# Suppression d'attributs HTML sur une balise Shiny
# ──────────────────────────────────────────────────────────────
#' Supprimer un ou plusieurs attributs d'une balise HTML
#'
#' Cette fonction retire un ou plusieurs attributs d'un objet `shiny.tag`.
#' Utile pour nettoyer ou modifier dynamiquement des balises HTML generees dans
#' une interface Shiny.
#'
#' @param tag La balise HTML (`shiny.tag`) depuis laquelle retirer des attributs.
#' @param ... Noms des attributs a supprimer (ex. `"class"`, `"style"`, `"src"`).
#'
#' @return La balise HTML modifiee, sans les attributs supprimes.
#'
#' @examples
#' a <- shiny::tags$p(src = "plop", "pouet")  # Balise <p> avec attribut src
#' tagRemoveAttributes(a, "src")              # Supprime l'attribut "src"
#'
#' @importFrom shiny tags
#'
#' @noRd
tagRemoveAttributes <- function(tag, ...) {                                     # Fonction supprimant des attributs d'une balise Shiny
  attrs <- as.character(list(...))                                              # Convertit les noms d'attributs variadiques (...) en vecteur de caracteres
  for (i in seq_along(attrs)) {                                                 # Boucle sur chaque attribut demande
    tag$attribs[[attrs[i]]] <- NULL                                             # Supprime l'attribut dans la liste attribs (mise a NULL = suppression)
  }
  tag                                                                           # Retourne la balise modifiee
}

# ──────────────────────────────────────────────────────────────
# Masquage CSS d'une balise (display:none)
# ──────────────────────────────────────────────────────────────
#' Masquer une balise HTML (affichage CSS : display:none)
#'
#' Cette fonction modifie une balise HTML (`shiny.tag`) pour la rendre invisible
#' en lui appliquant le style CSS `display: none;`.
#' Si la balise possede deja un attribut `style`, le style existant est conserve
#' et simplement prefixe.
#'
#' @param tag Une balise HTML (objet `shiny.tag`) a masquer.
#'
#' @return La balise HTML modifiee, non affichee.
#'
#' @examples
#' ## Masquer une balise <p>
#' a <- shiny::tags$p(src = "plop", "pouet")
#' undisplay(a)
#'
#' ## Masquer un bouton d'action
#' b <- shiny::actionButton("go_filter", "go")
#' undisplay(b)
#'
#' @importFrom shiny tagList
#'
#' @noRd
undisplay <- function(tag) {                                                    # Fonction pour appliquer display:none a une balise
  # if not already hidden                                                       # Verifie si la balise n'est pas deja masquee
  if (
    !is.null(tag$attribs$style) &&                                              # Si un attribut style existe deja
    !grepl("display:\\s+none", tag$attribs$style)                               # Et qu'il ne contient pas deja "display:none"
  ) {
    tag$attribs$style <- paste(                                                 # Prefixe display:none avant le style existant
      "display: none;",                                                         # Style CSS pour masquer la balise
      tag$attribs$style                                                         # Conserve les styles deja definis
    )
  } else {
    tag$attribs$style <- "display: none;"                                       # Si pas de style ou deja masque → definit simplement display:none
  }
  tag                                                                           # Retourne la balise modifiee
}

# ──────────────────────────────────────────────────────────────
# Reaffichage d une balise HTML (suppression de display:none)
# ──────────────────────────────────────────────────────────────
#' Reafficher une balise HTML precedemment masquee (suppression de display:none)
#'
#' Cette fonction retire le style CSS `display: none` d une balise HTML
#' (`shiny.tag`) si celui-ci est present.
#' Elle est le complement naturel de `undisplay()` et permet de rendre la balise
#' a nouveau visible dans l interface Shiny.
#'
#' @param tag Une balise HTML (objet `shiny.tag`) a rendre visible.
#'
#' @return La balise HTML modifiee, sans `display:none`.
#'
#' @examples
#' a <- shiny::tags$p("Texte")
#' undisplay(a)  # Masque la balise
#' display(a)    # La rend visible
#'
#' @importFrom shiny tagList
#'
#' @noRd
display <- function(tag) {                                                      # Fonction rendant visible une balise en supprimant display:none
  if (                                                                          # Test pour verifier la presence de style et de display:none
    !is.null(tag$attribs$style) &&                                              # Verifie qu'un attribut style existe bien
    grepl("display:\\s+none", tag$attribs$style)                                # Et que ce style contient "display: none"
  ) {
    tag$attribs$style <- gsub(                                                  # Remplace display:none par chaîne vide (suppression propre)
      "(\\s)*display:(\\s)*none(\\s)*(;)*(\\s)*",                               # Expression reguliere capturant toutes les variantes : espaces, ; optionnel
      "",                                                                       # Remplacement par vide → suppression
      tag$attribs$style                                                         # Style d'origine modifie
    )
  }
  tag                                                                           # Retourne la balise eventuellement modifiee
}

# ──────────────────────────────────────────────────────────────
# Masquage d’un element HTML via jQuery
# ──────────────────────────────────────────────────────────────
#' Masquer un element HTML via jQuery
#'
#' Cette fonction genere un script jQuery appliquant la methode `.hide()`
#' a l element HTML correspondant a l identifiant fourni.
#' C est un utilitaire simple pour masquer dynamiquement un element dans une
#' interface Shiny en utilisant du JavaScript côte client.
#'
#' @param id Identifiant HTML de l element a masquer (sans le prefixe '#').
#'
#'
#' @importFrom shiny tags
#'
#' @noRd
jq_hide <- function(id) {                                                       # Fonction generant un script jQuery de masquage
  tags$script(sprintf("$('#%s').hide()", id))                                   # Construit <script>$("#id").hide()</script> via sprintf
}

# ──────────────────────────────────────────────────────────────
# Ajout d’une etoile rouge pour champs obligatoires
# ──────────────────────────────────────────────────────────────
#' Ajouter une etoile rouge a la fin d'un texte HTML
#'
#' Cette fonction cree un fragment HTML contenant le texte fourni, suivi
#' d'une etoile rouge.
#' Elle est couramment utilisee pour indiquer les champs obligatoires dans une
#' interface Shiny (ex. formulaires administratifs ou DSFR).
#'
#' @param text Texte HTML ou chaîne de caracteres a afficher avant l'etoile rouge.
#'
#' @return Un element HTML (`<span>`) combinant le texte et l’etoile rouge.
#'
#' @examples
#' with_red_star("Nom")
#'
#' @importFrom shiny tags HTML
#'
#' @noRd
with_red_star <- function(text) {                                               # Fonction creant un texte avec etoile rouge
  shiny::tags$span(                                                             # Balise <span> englobante
    HTML(                                                                       # Interprete le contenu comme HTML (pas echappe)
      paste0(                                                                   # Concatene texte + etoile rouge
        text,                                                                   # Texte fourni
        shiny::tags$span(                                                       # Balise <span> pour l’etoile rouge
          style = "color:red",                                                  # Style CSS (etoile rouge)
          "*"                                                                   # Contenu de l’etoile obligatoire
        )
      )
    )
  )
}

# ──────────────────────────────────────────────────────────────
# Generation de retours à la ligne HTML <br/>
# ──────────────────────────────────────────────────────────────
#' Repeter plusieurs balises HTML <br/>
#'
#' Cette fonction genere un nombre donne de retours a la ligne HTML
#' en repetant la balise `<br/>`.
#' Utile pour inserer un espacement vertical dans une interface Shiny.
#'
#' @param times Nombre de balises `<br/>` a generer (1 par defaut).
#'
#' @return Un objet HTML contenant les balises `<br/>` repetees.
#'
#' @examples
#' rep_br(5)   # produit 5 retours a la ligne HTML
#'
#' @importFrom shiny HTML
#'
#' @noRd
rep_br <- function(times = 1) {                                                 # Genere un espacement vertical via plusieurs <br/>
  HTML(rep("<br/>", times = times))                                             # Repete "<br/>" 'times' fois et retourne en HTML
}

# ──────────────────────────────────────────────────────────────
# Creation d un lien HTML <a>
# ──────────────────────────────────────────────────────────────
#' Creer un lien HTML <a>
#'
#' Cette fonction genere une balise HTML `<a>` avec une URL et un texte
#' d affichage.
#' C est un raccourci pratique pour produire des liens cliquables
#' dans une interface Shiny.
#'
#' @param url L adresse URL vers laquelle le lien doit pointer.
#' @param text Le texte visible par l utilisateur.
#'
#' @return Une balise HTML `<a>`.
#' @noRd
#'
#' @examples
#' enurl("https://www.thinkr.fr", "ThinkR")
#'
#' @importFrom shiny tags
#'
#' @noRd
enurl <- function(url, text) {                                                  # Fonction utilitaire pour creer un lien HTML
  tags$a(href = url, text)                                                      # Balise <a> avec attribut href et texte d affichage
}

# ──────────────────────────────────────────────────────────────
# Raccourci Bootstrap : colonne
# ──────────────────────────────────────────────────────────────
#' Wrapper pour column(12, ...)
#'
#' Permet d ecrire plus rapidement une colonne de largeur 12
#' dans une grille bootstrap Shiny.
#'
#' @importFrom shiny column
#'
#' @noRd
col_12 <- function(...) {                                                       # Colonne Bootstrap de largeur 12
  column(12, ...)                                                               # Appelle shiny::column avec largeur 12
}
#' @importFrom shiny column
col_10 <- function(...) {                                                       # Colonne Bootstrap de largeur 10
  column(10, ...)                                                               # Appelle shiny::column avec largeur 10
}
#' @importFrom shiny column
col_8 <- function(...) {                                                        # Colonne Bootstrap de largeur 8
  column(8, ...)                                                                # Appelle shiny::column avec largeur 8
}
#' @importFrom shiny column
col_6 <- function(...) {                                                        # Colonne Bootstrap de largeur 6
  column(6, ...)                                                                # Appelle shiny::column avec largeur 6
}
#' @importFrom shiny column
col_4 <- function(...) {                                                        # Colonne Bootstrap de largeur 4
  column(4, ...)                                                                # Appelle shiny::column avec largeur 4
}
#' @importFrom shiny column
col_3 <- function(...) {                                                        # Colonne Bootstrap de largeur 3
  column(3, ...)                                                                # Appelle shiny::column avec largeur 3
}
#' @importFrom shiny column
col_2 <- function(...) {                                                        # Colonne Bootstrap de largeur 2
  column(2, ...)                                                                # Appelle shiny::column avec largeur 2
}
#' @importFrom shiny column
col_1 <- function(...) {                                                        # Colonne Bootstrap de largeur 1
  column(1, ...)                                                                # Appelle shiny::column avec largeur 1
}

# ──────────────────────────────────────────────────────────────
# Transformation d une balise HTML en actionButton Shiny
# ──────────────────────────────────────────────────────────────
#' Transformer une balise HTML en bouton d action Shiny
#'
#' Cette fonction modifie une balise HTML compatible (ex. `shiny::tags$button`,
#' `shiny::tags$a`) pour qu elle se comporte comme un bouton d action Shiny.
#' Elle ajoute un identifiant si necessaire, et applique la classe CSS
#' `action-button`, permettant la detection des clics côte serveur.
#'
#' @param tag Une balise HTML (`shiny.tag`) compatible avec un comportement de bouton.
#' @param inputId Identifiant unique pour lier un input côte serveur.
#'
#' @return La balise HTML modifiee, prete a emettre un evenement Shiny.
#'
#' @examples
#' if (interactive()) {
#'   library(shiny)
#'
#'   link <- a(href = "#", "Mon lien", style = "color: lightblue;")
#'
#'   ui <- fluidPage(
#'     make_action_button(link, inputId = "mylink")
#'   )
#'
#'   server <- function(input, output, session) {
#'     observeEvent(input$mylink, {
#'       showNotification("Clique detecte !")
#'     })
#'   }
#'
#'   shinyApp(ui, server)
#' }
#'
#' @importFrom shiny tags
#'
#' @noRd
make_action_button <- function(tag, inputId = NULL) {                           # Transforme une balise en bouton d'action
  # ── Verifications initiales ──────────────────────
  if (!inherits(tag, "shiny.tag")) stop("Must provide a shiny tag.")            # Verifie que l objet est une balise HTML Shiny
  if (!is.null(tag$attribs$class)) {                                            # Si une classe existe deja
    if (isTRUE(grepl("action-button", tag$attribs$class))) {                    # Verifie si c est deja un bouton
      stop("tag is already an action button")                                   # Interdit un double marquage
    }
  }
  if (is.null(inputId) && is.null(tag$attribs$id)) {                            # Cas : aucun id fourni
    stop("tag does not have any id. Please use inputId to be able to
           access it on the server side.")                                      # Un id est obligatoire pour un actionButton
  }

  # ── Gestion de l’identifiant ──────────────────────                                                                   # Gestion de l’identifiant
  if (!is.null(inputId)) {                                                       # Un inputId est fourni
    if (!is.null(tag$attribs$id)) {                                              # Mais la balise possede deja un id
      warning(                                                                   # Avertissement : l id existant sera utilise
        paste(
          "tag already has an id. Please use input$",
          tag$attribs$id,
          "to access it from the server side. inputId will be ignored."
        )
      )
    } else {
      tag$attribs$id <- inputId                                                 # Affecte l id fourni
    }
  }

  # ── Gestion de la classe CSS ──────────────────────
  if (is.null(tag$attribs$class)) {                                             # Si aucune classe n existe
    tag$attribs$class <- "action-button"                                        # Initialise avec la classe action-button
  } else {
    tag$attribs$class <- paste(tag$attribs$class, "action-button")              # Ajoute action-button aux classes existantes
  }

  tag                                                                           # Retourne la balise modifiee
}

# ──────────────────────────────────────────────────────────────
# Inclusion d un fichier RMarkdown rendu en HTML
# ──────────────────────────────────────────────────────────────
#' Inclure du contenu HTML genere a partir d un fichier RMarkdown
#'
#' Cette fonction rend un fichier RMarkdown au format Markdown, puis le convertit
#' en HTML avant de le renvoyer comme fragment HTML utilisable dans une interface
#' Shiny.
#' Le fichier genere temporairement est automatiquement supprime.
#'
#' @param path Chemin du fichier `.Rmd` a rendre.
#'
#' @return Un fragment HTML (`shiny::HTML`) pret a etre insere dans l UI.
#'
#' @importFrom rmarkdown render
#' @importFrom markdown markdownToHTML
#' @importFrom shiny HTML
#'
#' @noRd
includeRMarkdown <- function(path){                                             # Fonction d'inclusion de contenu RMarkdown converti en HTML

  md <- tempfile(fileext = '.md')                                               # Fichier Markdown temporaire genere

  on.exit(unlink(md), add = TRUE)                                               # Suppression automatique du fichier apres execution

  rmarkdown::render(                                                            # Genere un fichier .md depuis le .Rmd
    path,
    output_format = 'md_document',                                              # Format de sortie Markdown
    output_dir = tempdir(),                                                     # Repertoire temporaire
    output_file = md,                                                           # Chemin du fichier md
    quiet = TRUE                                                                # Sans messages de rendu
  )

  html <- markdown::markdownToHTML(md, fragment.only = TRUE)                    # Conversion du Markdown en HTML fragment

  Encoding(html) <- "UTF-8"                                                     # Assure une bonne gestion UTF-8

  return(shiny::HTML(html))                                                     # Retourne le fragment HTML pret pour Shiny
}

# ──────────────────────────────────────────────────────────────
# Operateur valeur par defaut (interne)
# ──────────────────────────────────────────────────────────────
#' Operateur valeur par defaut
#'
#' Retourne `a` si `a` n'est pas NULL.
#' Sinon retourne `b`.
#' C'est un operateur infix que tu places entre deux valeurs
#' pratique pour eviter les tests repetitifs sur `NULL`.
#'
#' @param a Premiere valeur a tester.
#' @param b Valeur de repli si `a` est NULL.
#'
#' @return `a` si non NULL, sinon `b`.
#'
#' @keywords internal
`%||%` <- function(a, b) {                                                      # Operateur personnalise "%||%"
  if (!is.null(a)) a else b                                                     # Retourne a sauf si NULL → retourne b
}

# ──────────────────────────────────────────────────────────────
# Forçage de prise en compte des assets statiques dans le build
# ──────────────────────────────────────────────────────────────
#' Forcer build R pour les ressources statiques
#'
#' Assure que le dossier `inst/app/www` est conserve lors du build et de
#' l’installation du package, meme s il n est pas explicitement reference
#' ailleurs dans le code.
#' Cette fonction est volontairement factice : elle ne fait qu acceder aux
#' dossiers afin qu ils soient enregistres comme dependances.
#'
#' @return Invisible TRUE
#'
#' @keywords internal
#'
#' @noRd
dummy_assets <- function() {                                                    # Fonction factice assets
  if (dir.exists("inst/app/www/css")) TRUE                                      # Declenche prise en compte du dossier CSS
  if (dir.exists("inst/app/www/html")) TRUE                                     # Declenche prise en compte du dossier HTML
  if (dir.exists("inst/app/www/icones")) TRUE                                   # Declenche prise en compte du dossier icônes
  if (dir.exists("inst/app/www/images")) TRUE                                   # Declenche prise en compte du dossier images
  if (dir.exists("inst/app/www/js")) TRUE                                       # Declenche prise en compte du dossier JavaScript
  if (dir.exists("inst/app/www/rmd")) TRUE                                      # Declenche prise en compte du dossier RMarkdown
  invisible(TRUE)                                                               # Retour invisible TRUE
}                                                                               # Fin fonction

# ──────────────────────────────────────────────────────────────
# Declaration de variables globales
# ──────────────────────────────────────────────────────────────
#' Declarer des variables globales
#'
#' Permet d'eviter les avertissements lors de `R CMD check` concernant
#' l'utilisation de variables supposees non definies dans le code.
#' Ces variables sont declarees comme globales pour le package.
#'
#' @keywords internal
#'
#' @importFrom utils globalVariables
#'
#' @noRd
utils::globalVariables(c(
  # Variables spatiales / attributaires
  "geom", "label", "value", "typezone", "tex2", "idu", "idn",

  # Variables communes / territoires
  "commune_idu", "comptecommunal", "r_communes", "e_communes",
  "code_insee_complet",

  # Variables export / traitement
  "out_file", "carte",

  # Variables configuration golem
  "get_golem_config", "app_title",

  # Variables legende cartographique
  "legend_row_fill", "legend_row_outline",

  # Variables Shiny / reactive
  "ns", "showNotification",

  # Variables data processing
  "mod_accueil", "mod_side", "avertissement"
))

# ──────────────────────────────────────────────────────────────
# Operateur negatif de %in%
# Test utilitaire : non NULL
# Test utilitaire : non NA
# ──────────────────────────────────────────────────────────────
#' Versions inversees des operateurs %in%, is.null et is.na
#'
#' @examples
#' 1 %not_in% 1:10
#' not_null(NULL)
#'
#' @noRd
`%not_in%` <- Negate(`%in%`)                                                    # Inversion de l operateur %in%

not_null <- Negate(is.null)                                                     # Retourne TRUE si non NULL

not_na <- Negate(is.na)                                                         # Retourne TRUE si non NA

# ──────────────────────────────────────────────────────────────
#' Suppression des elements NULL d un vecteur ou d une liste
# ──────────────────────────────────────────────────────────────
#' Supprimer les elements NULL d un vecteur ou d une liste
#'
#' @example
#' drop_nulls(list(1, NULL, 2))
#'
#' @noRd
drop_nulls <- function(x) {                                                     # Fonction suppression NULL
  x[!sapply(x, is.null)]                                                        # Filtre tous les elements non NULL
}

# ──────────────────────────────────────────────────────────────
# Operateur valeur par defaut (exporte)
# ──────────────────────────────────────────────────────────────
#' Renvoie y si x est NULL, sinon renvoie x
#'
#' @param x,y Deux elements dont l'un peut etre NULL
#'
#' @examples
#' NULL %||% 1
#'
#' @export
#'
#' @noRd
"%||%" <- function(x, y) {                                                      # Deuxieme definition de %||%
  if (is.null(x)) {                                                             # Si x est NULL
    y                                                                           # Retourne y
  } else {
    x                                                                           # Sinon retourne x
  }
}

# ──────────────────────────────────────────────────────────────
# Operateur valeur par defaut pour NA
# ──────────────────────────────────────────────────────────────
#' Si x est NA, retourne y, sinon retourne x
#'
#' @param x,y Deux elements dont l un peut etre NA
#'
#' @examples
#' NA %|NA|% 1
#'
#' @noRd
"%|NA|%" <- function(x, y) {                                                    # Operateur valeur par defaut pour NA
  if (is.na(x)) {                                                               # Si x est NA
    y                                                                           # Retourne y
  } else {
    x                                                                           # Sinon retourne x
  }
}

# ──────────────────────────────────────────────────────────────
# Alias de shiny::reactiveValues() et reactiveValuesToList()
# ──────────────────────────────────────────────────────────────
#' Alias raccourcis pour reactiveValues et reactiveValuesToList
#'
#' @inheritParams shiny::reactiveValues
#' @inheritParams shiny::reactiveValuesToList
#'
#' @importFrom shiny reactiveValues reactiveValuesToList
#' @noRd
rv <- function(...) shiny::reactiveValues(...)                                  # Raccourci creation reactiveValues
rvtl <- function(...) shiny::reactiveValuesToList(...)                          # Raccourci conversion en liste

# ──────────────────────────────────────────────────────────────────────────────
# FIN DU FICHIER
# ──────────────────────────────────────────────────────────────────────────────
