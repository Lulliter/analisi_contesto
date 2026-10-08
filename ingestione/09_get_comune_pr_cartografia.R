# ___________________________________________________________________________
# Ingestione: livelli cartografici e dataset del portale Open Data del Comune
#             di Parma → dati/grezzi/comune_pr_open/
# Fonte:  https://opendata.comune.parma.it (v. dati/grezzi/comune_pr_open/_metadati.md)
# Input:  file pubblicati dal Comune (indirizzi nella tabella dei Parametri)
# Output: dati/grezzi/comune_pr_open/<file originale> (geojson; gli zip vengono
#         anche scompattati in una sottocartella)
# NB: per aggiornare (es. reticolo stradale 2025 → 2026) si cambia la riga
#     della tabella, prendendo il nuovo indirizzo dal catalogo (ingestione/08)
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(tibble)
library(purrr)

# Parametri ---------------------------------------------------------------
url_base <- "https://opendata.comune.parma.it/sites/default/files/"
dir_raw <- here("dati", "grezzi", "comune_pr_open")
# FALSE = non riscarica i file già presenti; TRUE = li sovrascrive
RISCARICA <- FALSE

# 1 riga = 1 file: nome con cui si salva, nome nell'indirizzo (con spazi e
# parentesi codificati), sottocartella dove scompattare (solo per gli zip)
file_comune <- tribble(
  ~dataset,                                                   ~file_raw,                                       ~file_url,                                             ~cartella_zip,
  "immobili-acer-di-parma-2022",                              "ACER_immobili.geojson",                         "ACER_immobili.geojson",                               NA,
  "quartieri-del-comune-di-parma-vigenti",                    "quartieri_vigenti.geojson",                     "quartieri_vigenti.geojson",                           NA,
  "livello-cartografico-dei-torrenti",                        "torrenti.geojson",                              "torrenti.geojson",                                    NA,
  "livello-cartografico-delle-linee-ferroviarie-di-parma",    "ferrovie.geojson",                              "ferrovie.geojson",                                    NA,
  "parchi-intitolati",                                        "parchi_intitolati.geojson",                     "parchi_intitolati.geojson",                           NA,
  "livello-cartografico-del-reticolo-stradale-di-parma-2025", "Grafo_stradale_PARMA_2025_RDN2008 (SHP).zip",   "Grafo_stradale_PARMA_2025_RDN2008%20%28SHP%29.zip",   "grafo_stradale_2025",
  "popolazione-residente-al-1-gennaio-2026",                  "Popolazione_residente_2026.csv",                "Popolazione_residente_2026.csv",                      NA,
  "popolazione-residente-al-1-gennaio-2026",                  "Descrizione_codifica_campi_2025.csv",           "Descrizione_codifica_campi_2025.csv",                 NA
)

# Funzioni locali ----------------------------------------------------------

# scarica un file (se manca o se RISCARICA) e, se è uno zip, lo scompatta
f_scarica_comune <- function(dataset, file_raw, file_url, cartella_zip) {
  percorso <- file.path(dir_raw, file_raw)
  if (!file.exists(percorso) || RISCARICA) {
    download.file(paste0(url_base, file_url), percorso, mode = "wb")
  }
  if (!is.na(cartella_zip)) {
    unzip(percorso, exdir = file.path(dir_raw, cartella_zip))
  }
}

# 1. Scarica ---------------------------------------------------------------
dir.create(dir_raw, showWarnings = FALSE)
pwalk(file_comune, f_scarica_comune)

# 2. Controlli ---------------------------------------------------------------
# tutti i file ci sono? (TRUE per ogni riga)
file.exists(file.path(dir_raw, file_comune$file_raw))
# contenuto delle cartelle scompattate (serve il percorso del .shp)
list.files(file.path(dir_raw, na.omit(file_comune$cartella_zip)), recursive = TRUE)

