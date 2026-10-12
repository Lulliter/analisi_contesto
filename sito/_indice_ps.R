# _indice_ps.R
# Input:  sito/temi/*.qmd (campo `categories` dello YAML; le bozze con _ sono escluse)
#         _quarto.yml (testi brevi della navbar, usati come nome delle pagine)
# Output: assets/indice_ps.html — pannello del margine destro (margin-header di
#         _quarto.yml) con le pagine raggruppate per priorità e linea d'azione
#         del Piano Strategico 2024-27
# Uso:    lo lancia build.R; a mano: source("sito/_indice_ps.R"), poi quarto_render

# Setup ---
library(here)
library(dplyr)
library(purrr)

# Parametri ---
dir_pagine  <- here("sito", "temi")
file_quarto <- here("_quarto.yml")
file_out    <- here("assets", "indice_ps.html")

# Voci del pannello: una riga = una voce; il testo deve coincidere con le
# `categories` scritte nello YAML delle pagine (è l'unica fonte delle etichette)
etichette_ps <- tibble::tribble(
  ~gruppo,                ~etichetta,
  "Priorità strategiche", "P1 Disuguaglianze",
  "Priorità strategiche", "P2 Persone e istituzioni",
  "Priorità strategiche", "P3 Trasformazioni del territorio",
  "Linea d'azione",       "LA1 Welfare",
  "Linea d'azione",       "LA2 Territorio",
  "Linea d'azione",       "LA3 Capitale umano",
  "Linea d'azione",       "LA4 Sostegno (r)esistente"
)

# Nomi brevi dalla navbar ---
# href -> testo della voce (anche dentro i menu); chi non è in navbar usa il title
f_nomi_navbar <- function(file_quarto) {
  voci <- yaml::read_yaml(file_quarto)$website$navbar$left
  # appiattisce voci semplici e menu in un'unica lista di (text, href)
  piatte <- map(voci, function(v) if (is.null(v$menu)) list(v) else v$menu) |> list_flatten()
  piatte <- keep(piatte, function(v) !is.null(v$href))
  tibble(
    file = basename(map_chr(piatte, "href")),
    nome = map_chr(piatte, "text")
  )
}

# Pagine e tag ---
# una riga per coppia pagina-etichetta; pagine senza `categories` non compaiono
f_leggi_pagina <- function(file) {
  y <- rmarkdown::yaml_front_matter(file)
  tibble(
    file      = basename(file),
    titolo    = y$title,
    etichetta = as.character(unlist(y$categories))
  )
}
pagine <- list.files(dir_pagine, pattern = "^[^_].*\\.qmd$", full.names = TRUE) |>
  map(f_leggi_pagina) |>
  list_rbind() |>
  left_join(f_nomi_navbar(file_quarto), by = "file") |>
  mutate(
    nome = coalesce(nome, titolo),
    # link dalla radice del sito: vale per tutte le pagine (home e sito/temi/)
    href = paste0("/sito/temi/", sub("\\.qmd$", ".html", file))
  )

# Avviso: tag nello YAML che non stanno tra le voci (refuso o voce nuova da aggiungere)
tag_ignoti <- setdiff(pagine$etichetta, etichette_ps$etichetta)
if (length(tag_ignoti)) warning("categories non previste: ", paste(tag_ignoti, collapse = ", "))

# HTML ---
# un <details> per etichetta (chiuso), dentro l'elenco delle pagine con quel tag
f_blocco_etichetta <- function(etichetta) {
  righe <- filter(pagine, etichetta == .env$etichetta) |> arrange(nome)
  voci <- if (nrow(righe) == 0) {
    "<li class='indice-ps-vuoto'>nessuna pagina ancora</li>"
  } else {
    sprintf("<li><a href='%s'>%s</a></li>", righe$href, htmltools::htmlEscape(righe$nome))
  }
  c(sprintf("<details><summary>%s</summary>", htmltools::htmlEscape(etichetta)),
    "<ul>", voci, "</ul>", "</details>")
}

f_blocco_gruppo <- function(gruppo) {
  etichette <- filter(etichette_ps, gruppo == .env$gruppo)$etichetta
  c(sprintf("<p class='indice-ps-gruppo'>%s</p>", htmltools::htmlEscape(gruppo)),
    unlist(map(etichette, f_blocco_etichetta)))
}

html <- c(
  "<!-- generato da sito/_indice_ps.R: non modificare a mano -->",
  "<div id='indice-ps'>",
  unlist(map(unique(etichette_ps$gruppo), f_blocco_gruppo)),
  "</div>"
)
writeLines(html, file_out)
message("Scritto ", file_out, " (", nrow(pagine), " coppie pagina-etichetta)")
