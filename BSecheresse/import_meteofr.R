% Options for packages loaded elsewhere
\PassOptionsToPackage{unicode}{hyperref}
\PassOptionsToPackage{hyphens}{url}
%
\documentclass[
  10.5pt,
]{article}
\usepackage{amsmath,amssymb}
\usepackage{iftex}
\ifPDFTeX
  \usepackage[T1]{fontenc}
  \usepackage[utf8]{inputenc}
  \usepackage{textcomp} % provide euro and other symbols
\else % if luatex or xetex
  \usepackage{unicode-math} % this also loads fontspec
  \defaultfontfeatures{Scale=MatchLowercase}
  \defaultfontfeatures[\rmfamily]{Ligatures=TeX,Scale=1}
\fi
\usepackage{lmodern}
\ifPDFTeX\else
  % xetex/luatex font selection
    \setmainfont[]{Arial}
\fi
% Use upquote if available, for straight quotes in verbatim environments
\IfFileExists{upquote.sty}{\usepackage{upquote}}{}
\IfFileExists{microtype.sty}{% use microtype if available
  \usepackage[]{microtype}
  \UseMicrotypeSet[protrusion]{basicmath} % disable protrusion for tt fonts
}{}
\makeatletter
\@ifundefined{KOMAClassName}{% if non-KOMA class
  \IfFileExists{parskip.sty}{%
    \usepackage{parskip}
  }{% else
    \setlength{\parindent}{0pt}
    \setlength{\parskip}{6pt plus 2pt minus 1pt}}
}{% if KOMA class
  \KOMAoptions{parskip=half}}
\makeatother
\usepackage{xcolor}
\usepackage[margin=2cm]{geometry}
\usepackage{graphicx}
\makeatletter
\newsavebox\pandoc@box
\newcommand*\pandocbounded[1]{% scales image to fit in text height/width
  \sbox\pandoc@box{#1}%
  \Gscale@div\@tempa{\textheight}{\dimexpr\ht\pandoc@box+\dp\pandoc@box\relax}%
  \Gscale@div\@tempb{\linewidth}{\wd\pandoc@box}%
  \ifdim\@tempb\p@<\@tempa\p@\let\@tempa\@tempb\fi% select the smaller of both
  \ifdim\@tempa\p@<\p@\scalebox{\@tempa}{\usebox\pandoc@box}%
  \else\usebox{\pandoc@box}%
  \fi%
}
% Set default figure placement to htbp
\def\fps@figure{htbp}
\makeatother
\ifLuaTeX
  \usepackage{luacolor}
  \usepackage[soul]{lua-ul}
\else
  \usepackage{soul}
\fi
\setlength{\emergencystretch}{3em} % prevent overfull lines
\providecommand{\tightlist}{%
  \setlength{\itemsep}{0pt}\setlength{\parskip}{0pt}}
\setcounter{secnumdepth}{-\maxdimen} % remove section numbering
% ============================================================================
% FICHIER      : header.tex
% AUTEUR       : MJ Martinat
% DATE         : 2024-07-21 (corrigé 2026-01-04)
% DESCRIPTION  : En-tête LaTeX pour bulletins PDF XeLaTeX (mise en page DDT 26)
%                À inclure via l'option "in_header" du YAML d'un document Rmd.
%                NE PAS COMPILER CE FICHIER SEUL !
% CORRECTION   : En-tête avec image de fond identique au HTML
% ============================================================================

% --- Encodage UTF8 et polices Unicode (XeLaTeX obligatoire) -----------------
\usepackage{fontspec}
\usepackage{xunicode}
\defaultfontfeatures{Mapping=tex-text}

% --- Packages pour mise en page, tableaux et couleurs -----------------------
\usepackage{graphicx}
\usepackage{fancyhdr}
\usepackage{booktabs}
\usepackage[table]{xcolor}
\usepackage{colortbl}
\usepackage{float}
\usepackage{makecell}
\usepackage{multirow}
\usepackage{tikz}
\usepackage{eso-pic}

% --- Packages requis pour RMarkdown/Pandoc ----------------------------------
\usepackage{longtable}
\usepackage{array}
\usepackage{geometry}
\usepackage{hyperref}
\usepackage{bookmark}
\usepackage{enumitem}
\usepackage{amsmath}
\usepackage{amssymb}

% --- Définitions des couleurs institutionnelles -----------------------------
\definecolor{vigilance}{HTML}{F7EFA5}
\definecolor{alerte}{HTML}{FFB542}
\definecolor{alerterenforcee}{HTML}{FF4A29}
\definecolor{crise}{HTML}{AD0021}
\definecolor{pasdere}{HTML}{E6EFFF}
\definecolor{grisclair}{HTML}{F0F0F0}
\definecolor{bleuentete}{HTML}{001942}

% --- Style d'en-tête de tableau ---------------------------------------------
\renewcommand\theadfont{\normalsize\bfseries}

% --- Configuration de l'en-tête ---------------------------------------------
\pagestyle{fancy}
\fancyhf{}
\renewcommand{\headrulewidth}{0pt}
\setlength{\headheight}{2.5cm}
\setlength{\headsep}{0.5cm}

% --- Commande pour l'en-tête avec image de fond -----------------------------
\newcommand{\headerimage}{%
  \begin{tikzpicture}[remember picture,overlay]
    % Image de fond (si disponible)
    \IfFileExists{../images/image_secheresse.png}{%
      \node[anchor=north west, inner sep=0pt] at ([xshift=-1cm,yshift=1cm]current page.north west) {%
        \includegraphics[width=\paperwidth+2cm,height=2.8cm]{../images/image_secheresse.png}%
      };
    }{%
      % Fond bleu de secours si image non trouvée
      \fill[bleuentete] ([yshift=1cm]current page.north west) rectangle ([yshift=-2.5cm]current page.north east);
    }
  \end{tikzpicture}%
}

% --- En-tête personnalisé avec logo et texte --------------------------------
\fancyhead[L]{%
  \headerimage%
  \begin{tikzpicture}[remember picture,overlay]
    % Logo à gauche
    \IfFileExists{logo_prefete.png}{%
      \node[anchor=west, inner sep=0pt] at ([xshift=1.5cm,yshift=-1.25cm]current page.north west) {%
        \includegraphics[height=2cm]{logo_prefete.png}%
      };
    }{%
      \IfFileExists{marianne.png}{%
        \node[anchor=west, inner sep=0pt] at ([xshift=1.5cm,yshift=-1.25cm]current page.north west) {%
          \includegraphics[height=2cm]{marianne.png}%
        };
      }{%
        \node[anchor=west, text=white, font=\bfseries\Large] at ([xshift=1.5cm,yshift=-1.25cm]current page.north west) {[Logo]};
      }
    }
    % Texte à droite
    \node[anchor=east, text=white, font=\footnotesize, align=right] at ([xshift=-1.5cm,yshift=-1.25cm]current page.north east) {%
      \textbf{Direction Départementale des Territoires}\\
      \textbf{Service Eau Forêts Espaces Naturels}\\
      \textbf{Pôle Qualité Quantité Eau}\\
      \texttt{ddt-sefen-pe@drome.gouv.fr}%
    };
  \end{tikzpicture}%
}

% ============================================================================
% REMARQUES :
% - À inclure via includes: in_header: fichiers/tex/header.tex dans le YAML
% - Ne pas compiler ce fichier seul
% - Le script create_bulletin.R copie le logo avant la compilation
% - Pour questions : pôle SEFEN, DDT Drôme
% ============================================================================
% ============================================================================
% FICHIER      : main.tex
% AUTEUR       : MJMartinat
% DATE         : 2025
% DESCRIPTION  : Fragment LaTeX à inclure via before_body dans le YAML d’un
%                document R Markdown PDF.
%                Sert à insérer des définitions de couleurs et tout préambule
%                additionnel AVANT le corps du document.
%                NE PAS LANCER NI COMPILER CE FICHIER SEUL !
% ============================================================================

% --- Chargement du package xcolor pour les couleurs dans les tableaux
\usepackage[table]{xcolor}

% --- Définitions des couleurs institutionnelles pour les restrictions
\definecolor{vigilance}{HTML}{F7EFA5}
\definecolor{alerte}{HTML}{FFB542}
\definecolor{alerterenforcee}{HTML}{FF4A29}
\definecolor{crise}{HTML}{AD0021}
\definecolor{pasdere}{HTML}{E6EFFF}

% ============================================================================
% Ce fichier est inséré AVANT le corps du document, via :
% output:
%   pdf_document:
%     latex_engine: xelatex
%     includes:
%       before_body: chemin/vers/main.tex
%
% Il ne doit PAS contenir \documentclass, \begin{document} ni \end{document}.
% ============================================================================

% (Laisse ce fichier vide en dehors des définitions à inclure)

\usepackage{booktabs}
\usepackage{longtable}
\usepackage{array}
\usepackage{multirow}
\usepackage{wrapfig}
\usepackage{float}
\usepackage{colortbl}
\usepackage{pdflscape}
\usepackage{tabu}
\usepackage{threeparttable}
\usepackage{threeparttablex}
\usepackage[normalem]{ulem}
\usepackage{makecell}
\usepackage{xcolor}
\usepackage{bookmark}
\IfFileExists{xurl.sty}{\usepackage{xurl}}{} % add URL line breaks if available
\urlstyle{same}
\hypersetup{
  hidelinks,
  pdfcreator={LaTeX via pandoc}}

\author{}
\date{\vspace{-2.5em}}

\begin{document}

\begin{center}
\textbf{\LARGE Bulletin hydrologique de la} \\[0.5em]
\textbf{Direction Départementale des Territoires} \\[0.3em]
\textbf{du 05 janvier 2026}
\end{center}

\section{\texorpdfstring{\textsc{\ul{\textbf{Pluviométrie attendue
(Météo
France)}}}}{Pluviométrie attendue (Météo France)}}\label{pluviomuxe9trie-attendue-muxe9tuxe9o-france}

\begin{table}[!h]
\centering\begingroup\fontsize{10.5}{12.5}\selectfont

\resizebox{\ifdim\width>\linewidth\linewidth\else\width\fi}{!}{
\begin{tabular}{ccccccccc}
\toprule
\textbf{Station} & \textbf{Jour} & \textbf{Jour+1} & \textbf{Jour+2} & \textbf{Jour+3} & \textbf{Jour+4} & \textbf{Jour+5} & \textbf{Jour+6} & \textbf{Jour+7}\\
\midrule
\cellcolor{gray!10}{Hauterives} & \cellcolor{gray!10}{5.1} & \cellcolor{gray!10}{4.3} & \cellcolor{gray!10}{2.7} & \cellcolor{gray!10}{0.0} & \cellcolor{gray!10}{0.0} & \cellcolor{gray!10}{3.4} & \cellcolor{gray!10}{0.0} & \cellcolor{gray!10}{0.0}\\
Valence & 2.3 & 1.1 & 0.0 & 0.5 & 0.0 & 1.2 & 0.8 & 0.0\\
\cellcolor{gray!10}{Die} & \cellcolor{gray!10}{0.0} & \cellcolor{gray!10}{0.0} & \cellcolor{gray!10}{1.1} & \cellcolor{gray!10}{0.0} & \cellcolor{gray!10}{0.0} & \cellcolor{gray!10}{0.2} & \cellcolor{gray!10}{0.0} & \cellcolor{gray!10}{0.0}\\
Nyons & 0.0 & 0.0 & 1.0 & 0.0 & 0.0 & 0.2 & 0.0 & 0.0\\
\bottomrule
\end{tabular}}
\endgroup{}
\end{table}

\section{\texorpdfstring{\textsc{\ul{\textbf{Situation des différents
secteurs}}}}{Situation des différents secteurs}}\label{situation-des-diffuxe9rents-secteurs}

\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{GALAURE – DRÔME DES COLLINES}} \\ \textsc{SUPERFICIEL}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Débits} & \cellcolor{gray!10}{L'Herbasse à Clérieux [Pont de l'Herbasse]} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{0.64}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Débits & La Galaure à Saint - Uze & \cellcolor[HTML]{FFFFFF}{1.33} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{La Galaure à Hauterives} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & La Joyeuse à Momtmiral & \cellcolor[HTML]{FFFFFF}{Assec} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{La Limone à Montrigaud} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible faible}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & Le Chalon à Momtmiral & \cellcolor[HTML]{FFFFFF}{Ecoulement visible faible} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{Le Galaveyson à Montfalcon (38)} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & Le Bagnol à Montmiral & \cellcolor[HTML]{FFFFFF}{Ecoulement visible acceptable} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{GALAURE – DRÔME DES COLLINES}} \\ \textsc{SOUTERRAIN}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Nappes} & \cellcolor{gray!10}{FORAGE - MAUPAS (ROMANS SUR ISERE - 26)} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{163.85}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Nappes & PIEZOMETRE - CHEVAUX (CLAVEYSON - BRGM 26) - BSH & \cellcolor[HTML]{FFFFFF}{232.47} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Nappes} & \cellcolor{gray!10}{PIEZOMETRE - LES BALMES (ROMANS SUR ISERE - BRGM 26) - BSH} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{140.56}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Nappes & PIEZOMETRE - SALLE COMMUNALE (MARGES - BRGM 26) - BSH & \cellcolor[HTML]{FFFFFF}{247.05} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Nappes} & \cellcolor{gray!10}{PUITS - FONTCHAUDE (SAINT - BONNET - DE - CHAVAGNE - BRGM 38) - BSH} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{249.84}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{PLAINE DE VALENCE}} \\ \textsc{SUPERFICIEL}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Débits} & \cellcolor{gray!10}{La Barberolle à Barbières [Pont des Ducs]} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{0.08}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Débits & La Véore à Chabeuil [Pont des Faucons] & \cellcolor[HTML]{FFFFFF}{0.6} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{La Barberolle à Barbières} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & La Béaure à Rochefort & \cellcolor[HTML]{FFFFFF}{Ecoulement visible acceptable} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{La Véore à Chabeuil} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & Le ru. de Loye à Montéléger & \cellcolor[HTML]{FFFFFF}{Ecoulement visible acceptable} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{PLAINE DE VALENCE}} \\ \textsc{SOUTERRAIN}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Nappes} & \cellcolor{gray!10}{Forage - l Hotel (Charpey - BRGM 26)} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{268.4}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Nappes & PIEZOMETRE - FERME AGIRON (VALENCE - BRGM 26) - BSH & \cellcolor[HTML]{FFFFFF}{137.69} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Nappes} & \cellcolor{gray!10}{PUITS - BERNOIR (MONTMEYRAND - BRGM 26) - BSH} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{161.13}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{ROYAN – VERCORS}} \\ \textsc{SUPERFICIEL}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Débits} & \cellcolor{gray!10}{L'Adouin à Saint - Martin - en - Vercors [Tourtre]} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{0.17}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Débits & Le Meaudret à Méaudre (38) & \cellcolor[HTML]{FFFFFF}{0.46} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{La Vernaison à Saint Agnan} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{BASSIN DE LA DRÔME}} \\ \textsc{SUPERFICIEL}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Débits} & \cellcolor{gray!10}{La Drôme à Luc - en - Diois} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{1.91}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Débits & La Drôme à Saillans & \cellcolor[HTML]{FFFFFF}{10.1} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Débits} & \cellcolor{gray!10}{La Gervanne à Beaufort - sur - Gervanne [Résurgence des Fontaigneux]} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{0.64}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Débits & La Gervanne à Beaufort - sur - Gervanne [Résurgence des Fontaigneux] & \cellcolor[HTML]{FFFFFF}{0.96} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Débits} & \cellcolor{gray!10}{Le Bès à Châtillon - en - Diois} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{2.32}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Débits & Le ruisseau de Grenette à la Répara - Auriples & \cellcolor[HTML]{FFFFFF}{0.03} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{L'Esconavette à Montmaur - en - Diois} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & La Drôme à Charens & \cellcolor[HTML]{FFFFFF}{Ecoulement visible acceptable} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{La Drôme à Loriol - sur - Drôme} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & La Gervanne à Beaufort & \cellcolor[HTML]{FFFFFF}{Ecoulement visible acceptable} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{La Grenette à Grâne} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & La Sure à Vachères & \cellcolor[HTML]{FFFFFF}{Ecoulement visible acceptable} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{Le ru. de Marignac à Die} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{BASSIN DE LA DRÔME}} \\ \textsc{SOUTERRAIN}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Nappes} & \cellcolor{gray!10}{PIEZOMETRE - AUTOROUTE (LORIOL SUR DROME - BRGM 26) - BSH} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{94.6}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Nappes & PIEZOMETRE - CHAMP CAPTANT (EURRE - BRGM 26) - BSH & \cellcolor[HTML]{FFFFFF}{151.99} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Nappes} & \cellcolor{gray!10}{PIEZOMETRE - SILO (LIVRON SUR DROME - BRGM 26) - BSH} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{97.05}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Nappes & PUITS - AEP (GRANE - BRGM 26) - BSH & \cellcolor[HTML]{FFFFFF}{140.26} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{ROUBION – JABRON}} \\ \textsc{SUPERFICIEL}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Débits} & \cellcolor{gray!10}{Le Jabron à Souspierre} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{1.29}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Débits & Le Roubion à Soyans & \cellcolor[HTML]{FFFFFF}{1.41} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{La Tessonne à Mirmande} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & La Gumiane à Bouvières & \cellcolor[HTML]{FFFFFF}{Ecoulement visible acceptable} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{La Vence à Roussas} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Assec}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & le Roubion à Pont - de - Barret & \cellcolor[HTML]{FFFFFF}{Ecoulement visible acceptable} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{le Jabron à Comps} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{ROUBION – JABRON}} \\ \textsc{SOUTERRAIN}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Nappes} & \cellcolor{gray!10}{PIEZOMETRE - FIN DE ROUTE(SAINT - MARCEL - LES - SAUZET - BRGM 26)} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{107.52}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Nappes & PIEZOMETRE - LE PERTHUIS (SAOU - BRGM 26) - BSH & \cellcolor[HTML]{FFFFFF}{386.71} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{BERRE}} \\ \textsc{SUPERFICIEL}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{La Berre à Salles - sous - Bois} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{LEZ PROVENÇAL – LAUZON}} \\ \textsc{SUPERFICIEL}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Débits} & \cellcolor{gray!10}{L'Herin à Bouchet} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{0.002}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Débits & Le Lez à Bollène & \cellcolor[HTML]{FFFFFF}{0.251} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Débits} & \cellcolor{gray!10}{Le Lez à Grignan [Pont D 541]} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{0.183}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Débits & Le Lez à Suze - la - Rousse & \cellcolor[HTML]{FFFFFF}{0.297} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{L'Aulière à l'amont de Grillon (84)} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & La Coronne à Richerenches (84) & \cellcolor[HTML]{FFFFFF}{Ecoulement visible acceptable} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{La Talobre à Richerenches (84)} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible faible}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & Le Pègue à l'amont de Valréas (84) & \cellcolor[HTML]{FFFFFF}{Ecoulement visible acceptable} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{Le Lauzon à Solérieux} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{LEZ PROVENÇAL – LAUZON}} \\ \textsc{SOUTERRAIN}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Nappes} & \cellcolor{gray!10}{Nappe alluviale de la CORONNE (VALREAS)} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{232.94}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\
\cmidrule{1-5}\pagebreak[0]
Nappes & Nappe d'accompagnement de l'HERIN (VISAN) & \cellcolor[HTML]{FFFFFF}{116.29} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{f7efa5}{Vigilance}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{AEYGUES}} \\ \textsc{SUPERFICIEL}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Débits} & \cellcolor{gray!10}{L'Aigue à Saint - May - RD 562} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{3.89}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & L'ennuyé à Sainte Jalle & \cellcolor[HTML]{FFFFFF}{Ecoulement visible acceptable} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{La Lidane à Rosans} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Réseau ONDE & La Sauve à Venterol & \cellcolor[HTML]{FFFFFF}{Ecoulement visible acceptable} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\
\cmidrule{1-5}\pagebreak[0]
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{Le Rieu Foyro à Uchaux (84)} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{AEYGUES}} \\ \textsc{SOUTERRAIN}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Nappes} & \cellcolor{gray!10}{Nappe alluviale de L'AYGUES (SAINTE CECILE LES VIGNES)} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{120.05}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}}\\
\cmidrule{1-5}\pagebreak[0]
Nappes & Nappe d'accompagnement de l'AYGUES (VILLEDIEU) & \cellcolor[HTML]{FFFFFF}{190.71} & \cellcolor[HTML]{e6efff}{Pas de restriction} & \cellcolor[HTML]{e6efff}{Pas de restriction}\\*
\end{longtable}
\endgroup{} 
\begin{center}\fcolorbox{black}{gray!20}{\parbox{17cm}{\small \textbf{\textsc{LA MÉOUGE}} \\ \textsc{SUPERFICIEL}}}\end{center} 
\begingroup\fontsize{9}{11}\selectfont

\begin{longtable}{>{\raggedright\arraybackslash}p{3.97cm}>{\raggedright\arraybackslash}p{8.57cm}>{\centering\arraybackslash}p{3.97cm}>{\centering\arraybackslash}p{5.29cm}>{\centering\arraybackslash}p{5.29cm}}
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endfirsthead
\multicolumn{5}{@{}l}{\textit{(continued)}}\\
\toprule
Mode de gestion & Station & Mesure & Restriction & Perspective\\
\midrule
\endhead

\endfoot
\bottomrule
\endlastfoot
\cellcolor{gray!10}{Réseau ONDE} & \cellcolor{gray!10}{Le Rif à Pomet (05)} & \cellcolor[HTML]{FFFFFF}{\cellcolor{gray!10}{Ecoulement visible acceptable}} & \cellcolor[HTML]{e6efff}{\cellcolor{gray!10}{Pas de restriction}} & \cellcolor[HTML]{f7efa5}{\cellcolor{gray!10}{Vigilance}}\\*
\end{longtable}
\endgroup{}

\newpage
\begin{center}
\textbf{\large Restrictions provisoires de certains usages de l'eau}\\[0.5em]
\textbf{Situation actuelle et proposition d'évolution}
\end{center}
\vspace{1em}

\begin{center}\includegraphics{bulletin_secheresse_files/figure-latex/cartes_restriction-1} \end{center}

\end{document}
