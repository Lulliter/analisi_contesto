# ------- Flextable settings ----
# FT cheatsheet https://ardata-fr.github.io/flextable-book/static/pdf/cheat_sheet_flextable.pdf
library(dplyr)
library(stringr)
library(flextable)
library(systemfonts)

# --- Inspect available system fonts (optional) -----------------------------
# ---- VEDERE `_fonts.qmd` ------
# fonts <-  systemfonts::system_fonts() |>
#   # filter if family name contains "condensed"
#   filter(str_detect(family,  "Condensed"))  |>
#   select(name, family, style)

# 1) set target font with safe fallbacks -----------------------------
# verify a font exists on *your* system
f_has_font <- function(family) {
  suppressWarnings({
    fi <- systemfonts::system_fonts()
    any(tolower(fi$family) == tolower(family))
  })
}

# EXE
f_has_font("Roboto Condensed") # TRUE
f_has_font("Segoe UI") # FALSE
f_has_font("Libre Franklin") # TRUE

# Pick preferred or fallback font
f_pick_font <- function(
  candidates = c(
    "Roboto Condensed",
    "Libre Franklin",
    "Open Sans",
    "Segoe UI",
    "Tahoma",
    "Arial"
  )
) {
  for (fam in candidates) {
    if (f_has_font(fam)) return(fam)
  }
  "Arial" # absolute last-resort
}

# Define target font
target_font <- f_pick_font()
message("Using font: ", target_font)

# 2) set flextable defaults -----------------------------------------
set_flextable_defaults(
  line_spacing = 1,
  #scroll =           # NULL or a list if you want to add a scroll-box
  cs.family = target_font, # as decided above
  font.family = target_font, # as decided above
  font.size = 12,
  theme_fun = theme_box, #theme_vanilla,
  #padding = 1,
  padding.bottom = 2,
  padding.top = 2,
  padding.left = 4,
  padding.right = 4,
  background.color = "#F8F8F8",
  border.color = "#A6A6A6",
  border.width = .5,
  table.layout = "autofit" # adapts to content width (works for HTML & Word)
)

# ___ Default numbers format like in Italy ----
set_flextable_defaults(
  digits = 2,
  decimal.mark = ",",
  big.mark = "."
)

# ___ Border style ----
brdr_in <- fp_border_default(color = "#4c4c4c", width = 0.25)

# 3) Funzione CUSTOM per tabelle in Word ----
# f_ft_word <- function(ft) {
#   ft |>
#     set_table_properties(
#       width = 1,
#       layout = "autofit",
#       align = "left") |>
#     fit_to_width(max_width = 6.7) |>
#     autofit(add_w = 0.1, add_h = 0)
# }

# NOTA: f_ft_slides() è stato spostato in R/slides_formatting.R
# (con font.size, padding e line_spacing forzati esplicitamente).
# Da source() solo quando si renderizza presentazione/slides.qmd.

# NOTE: f_ft_word() is for Word (.docx) export only.
# Do NOT call it when rendering to HTML or revealjs — fit_to_width() and
# opts_word settings are ignored or can cause unwanted width behaviour.
f_ft_word <- function(ft) {
  ft |>
    set_table_properties(
      width = 1,
      layout = "autofit", # Word layout mode (diff flextable::autofit)
      align = "left",
      opts_word = list(
        split = FALSE, # <- DO NOT let rows break across pages
        repeat_headers = TRUE # <- repeat header row(s) on subsequent pages
      )
    ) |>
    fit_to_width(max_width = 6.7) |>
    autofit(add_w = 0.1, add_h = 0) # compute widths from content (once)
}

# --- OKKIO: QUESTA E' da aggiungere con -----
# ft |> f_ft_word()  # <-- applica le impostazioni per Word

#' Apply consistent footnote styling to flextable footer
#' Smaller italic text, white background, no border
f_ft_footnote <- function(ft) {
  ft |>
    style(
      part = "footer",
      pr_t = fp_text_default(font.size = 10, italic = TRUE, font.family = target_font),
      pr_c = officer::fp_cell(background.color = "white",
                              border = fp_border_default(width = 0))
    )
}

#' Style the "Totale" summary row (and optionally a totale column)
#'
#' Applies a darker grey background + bold to the last body row, which by
#' convention is always the totale row (added via add_body_row(top = FALSE)).
#' Optionally also bolds a "Totale" column (e.g. the row-sum column).
#' Call *after* add_body_row() and at the end of the pipeline.
#'
#' @param ft       A flextable object.
#' @param i        Row index of the Totale row. NULL = last body row (default).
#' @param col_j    Column index(es) to bold as "Totale column". NULL = skip.
#' @param bg_color Background color for the Totale row. Default "#CCCCCC".
f_ft_totale <- function(ft, i = NULL, col_j = NULL, bg_color = "#CCCCCC") {
  n <- nrow(ft$body$dataset)
  row_i <- if (is.null(i)) n else i
  ft <- ft |>
    bg(i = row_i, bg = bg_color, part = "body") |>
    bold(i = row_i, part = "body")
  if (!is.null(col_j)) {
    ft <- ft |> bold(j = col_j, part = "body")
  }
  ft
}

# ---- OKKIO: non usare doppio caption con tbl-cap e set_caption----


# 4) Color palettes -------------------------------------------------------

#' Sequential teal palette (5 levels, light → dark)
#' Use for ordered variables, e.g. ambito territoriale
seq_teal <- colorRampPalette(c("#d0ece7", "#0e6655"))(5)

#' Generic categorical palette (5 unordered levels)
#' Consistent saturation with the main category palette;
#' use for questions where category-specific colors don't apply
cat_generic <- c(
  "#e07b54",  # terracotta
  "#4eb3a5",  # teal
  "#7f9db9",  # grigio-blu
  "#c0a0c8",  # lavanda
  "#f2c14e"   # miele
)

# 5) ggplot2 minimal theme ------------------------------------------------
library(ggplot2)

#' Minimal ggplot2 theme for survey plots
#'
#' Uses the project font (`target_font`) and bumps axis text to a readable
#' size.  Intentionally leaves most decisions (colours, geoms, titles) to
#' the calling code so it stays useful across HTML, docx, and revealjs.
#'
#' @param base_size Base font size. Default 13; raise to ~16 for revealjs slides.
theme_survey <- function(base_size = 13) {
  ggplot2::theme_minimal(base_size = base_size, base_family = target_font) +
    ggplot2::theme(
      axis.text       = ggplot2::element_text(size = base_size),
      axis.title      = ggplot2::element_text(size = base_size - 1),
      plot.title      = ggplot2::element_text(face = "bold", size = base_size + 1),
      panel.grid.minor          = ggplot2::element_blank(),
      plot.caption              = ggplot2::element_text(hjust = 0),
      plot.caption.position     = "plot"
    )
}
