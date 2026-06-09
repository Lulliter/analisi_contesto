# R/slides_formatting.R -----------------------------------------------------
# Helper di formatting dedicati alle slide revealjs (presentazione/slides.qmd).
#
# LOGICA GENERALE
# ---------------
# Le flextables vengono rese INLINE come HTML dentro le slides (non come PNG).
# Questo evita:
#   - il crash delle emoji (il device png base di R non le rende)
#   - i problemi di font piccolo / interlinea enorme / overflow margini.
#
# Il layout di una tabella su slide si controlla su DUE livelli:
#   1) DENTRO la flextable (qui, via f_ft_slides): font.size, line_spacing,
#      padding, larghezza colonne. Questi diventano style="..." inline nel HTML
#      e quindi "vincono" sempre rispetto al CSS esterno.
#   2) FUORI la flextable (brand/CRP-revealjs.scss): centratura nel contenuto
#      della slide, max-width, overflow verticale, margini.
#
# Carica DOPO R/formatting.R, perché riusa `target_font` e `brdr_in`.
# ---------------------------------------------------------------------------

library(flextable)
library(ggplot2)

# 1) flextable per slide --------------------------------------------------

#' Prepara una flextable per slides revealjs
#'
#' Leve di dimensionamento:
#'   - `font_size`    : cambia grandezza dei caratteri (14 → 16 → 18 …)
#'   - `stretch`      : TRUE = la tabella occupa il 100% della larghezza slide
#'                      (consigliato, rende le tabelle "grandi" senza altri tocchi);
#'                      FALSE = larghezza basata sul contenuto, capped a `max_width`
#'   - `pad`          : padding verticale celle (più aria tra le righe)
#'   - `line_spacing` : interlinea DENTRO le celle (leva più efficace di `pad`
#'                      per "arieggiare" una tabella, 1 = stretto, 1.3–1.5 = largo)
#'
#' Altezza effettiva di una riga ≈ line_spacing × font_size + 2×pad
#' (quindi per far respirare la tabella alzare line_spacing ha più effetto
#' che alzare pad).
#'
#' @param ft           Oggetto flextable.
#' @param font_size    Dimensione carattere in pt (default 16).
#' @param stretch      Se TRUE (default) la tabella riempie la larghezza slide.
#' @param max_width    Larghezza massima in pollici usata solo se `stretch = FALSE`
#'                     (default 10.5 ~ area utile su slide 1050x700).
#' @param pad          Padding verticale celle in pt (default 2).
#' @param line_spacing Interlinea dentro le celle (default 1 = compatto).
f_ft_slides <- function(ft,
                        font_size    = 16,
                        stretch      = TRUE,
                        max_width    = 10.5,
                        pad          = 2,
                        line_spacing = 1) {
  ft <- ft |>
    # 1. font coerente (usa target_font definito in R/formatting.R)
    fontsize(size = font_size, part = "all") |>
    font(fontname = target_font, part = "all") |>
    # 2. interlinea configurabile, applicata a header/body/footer.
    #    Quarto/revealjs può iniettare line-height 1.3-1.5 dal tema: forzando
    #    line_spacing a livello flextable lo style inline vince.
    line_spacing(space = line_spacing, part = "all") |>
    # 3. padding verticale configurabile
    padding(padding.top = pad, padding.bottom = pad, part = "all") |>
    # 4. ricalcola le larghezze colonna in base al nuovo font
    autofit()

  # 5. dimensionamento orizzontale
  if (stretch) {
    # tabella = 100% della larghezza del contenitore (slide)
    ft <- ft |> set_table_properties(width = 1, layout = "autofit")
  } else {
    # tetto in pollici (utile se la tabella deve restare compatta)
    ft <- ft |> fit_to_width(max_width = max_width)
  }

  # 6. footer leggermente più piccolo + italico (se c'è)
  ft |>
    style(
      part = "footer",
      pr_t = fp_text_default(
        font.size   = font_size - 2,
        italic      = TRUE,
        font.family = target_font
      )
    )
}

#' Versione "stretta" per tabelle con tante colonne o testi lunghi
#'
#' Font più piccolo + padding minimo. Utile quando la tabella ha troppe
#' colonne per stare a 16pt (es. s2-volumi 7 colonne, s5-flotta con emoji,
#' s8-collaborazioni con matrice 5 colonne).
f_ft_slides_tight <- function(ft,
                              font_size    = 13,
                              stretch      = TRUE,
                              max_width    = 10.5,
                              pad          = 1,
                              line_spacing = 1) {
  f_ft_slides(ft,
              font_size    = font_size,
              stretch      = stretch,
              max_width    = max_width,
              pad          = pad,
              line_spacing = line_spacing)
}


# 2) ggplot theme per slide -----------------------------------------------

#' Variante di theme_survey() tunata per revealjs
#'
#' Font più grande (base_size 16) perché i plot vengono salvati come PNG e
#' scalati a schermo pieno: i valori di theme_survey() (base 13) risultano
#' piccoli se proiettati.
#'
#' @param base_size Default 16.
theme_survey_slides <- function(base_size = 16) {
  theme_survey(base_size = base_size)
}
