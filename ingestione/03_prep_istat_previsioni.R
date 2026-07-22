# ------------------------------------------------------------------------
# Ingestione: previsioni demografiche ISTAT 2024-2050 (scenario mediano)
#             → dati/puliti/istat_previsioni/
# Fonte:  dati/grezzi/istat_trend_demog/ (demo.istat.it, download 2026-07-18,
#         vedi _metadati.md) — 5 file .csv.zip, base 1.1.2024
# Input:  PREVISIONI_Componenti_del_bilancio_demografico-Comuni_Emilia-Romagna.csv.zip
#         PREVISIONI_Principali_indicatori_strutturali-Comuni_Emilia-Romagna.csv.zip
#         PREVISIONI_Tassi_generici_del_movimento_demografico-Comuni_Emilia-Romagna.csv.zip
#         Previsioni_comunali_popolazione_per_eta-Comuni_Emilia-Romagna.csv.zip
#         Previsioni_comunali_popolazione_per_eta-Province.csv.zip
# Output: dati/puliti/istat_previsioni/previs_bilancio_comuni_er.rds
#         dati/puliti/istat_previsioni/previs_indicatori_comuni_er.rds
#         dati/puliti/istat_previsioni/previs_tassi_comuni_er.rds
#         dati/puliti/istat_previsioni/previs_pop_eta_comuni_er.rds
#         dati/puliti/istat_previsioni/previs_pop_eta_province.rds  (tutta Italia)
#         (nome file = nome oggetto R; consumati dal modulo demo_trend_previs)
# NB: - SOLO scenario mediano (nei csv non c'è la colonna scenario)
#     - i file comunali coprono solo i comuni con >= 5.000 ab. al 1.1.2024:
#       195 comuni ER, 22 su 44 in provincia di Parma
#     - csv: separatore ";", virgola decimale, 1a riga = titolo (skip = 1);
#       readr legge i .zip direttamente senza scompattarli
# ------------------------------------------------------------------------

library(here)
library(readr)
library(dplyr)
library(janitor)
library(purrr)

# Parametri ---------------------------------------------------------------
dir_in  <- here("dati", "grezzi", "istat_trend_demog")
dir_out <- here("dati", "puliti", "istat_previsioni")
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)

# nome oggetto/rds = file zip di origine
file_zip <- c(
  previs_bilancio_comuni_er   = "PREVISIONI_Componenti_del_bilancio_demografico-Comuni_Emilia-Romagna.csv.zip",
  previs_indicatori_comuni_er = "PREVISIONI_Principali_indicatori_strutturali-Comuni_Emilia-Romagna.csv.zip",
  previs_tassi_comuni_er      = "PREVISIONI_Tassi_generici_del_movimento_demografico-Comuni_Emilia-Romagna.csv.zip",
  previs_pop_eta_comuni_er    = "Previsioni_comunali_popolazione_per_eta-Comuni_Emilia-Romagna.csv.zip",
  previs_pop_eta_province     = "Previsioni_comunali_popolazione_per_eta-Province.csv.zip"
)

# Funzioni locali ----------------------------------------------------------

# Legge un csv ISTAT previsioni: ";", virgola decimale, titolo in riga 1;
# i codici comune/provincia restano character (leading zero)
f_leggi_previs <- function(zip_file) {
  read_csv2(
    file.path(dir_in, zip_file),
    skip = 1,
    col_types = cols(
      .default           = col_guess(),
      `Codice comune`    = col_character(),
      `Codice provincia` = col_character()
    ),
    locale = locale(encoding = "UTF-8")
  ) |>
    clean_names()
}

# 1. Lettura e pulizia -----------------------------------------------------
lista_previs <- map(file_zip, f_leggi_previs)

# controllo rapido: anni 2024-2050 e nessun NA nei codici
walk(lista_previs, function(df) {
  stopifnot(range(df$anno) == c(2024, 2050))
})

# 2. Salva in dati/puliti/istat_previsioni/ --------------------------------
iwalk(lista_previs, function(df, nome) {
  saveRDS(df, file.path(dir_out, paste0(nome, ".rds")))
})
