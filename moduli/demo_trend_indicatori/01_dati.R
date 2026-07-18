# ------------------------------------------------------------------------
# Modulo: demo_trend_indicatori
# Fonte:  ISTAT - Indicatori demografici ("Demografia in cifre"), livello
#         provinciale, serie 2002-2025 (ultimo anno provvisorio/stimato;
#         download 2026-07-18, vedi dati/grezzi/istat_trend_demog/_metadati.md)
# Input:  dati/grezzi/istat_trend_demog/Indicatori_demografici.xls
# Output: moduli/demo_trend_indicatori/output/<indicatore>.rds (formato tidy)
# Origine codice: dashboard/demographic_trends/data_load.R (vecchio repo)
# ------------------------------------------------------------------------

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(here)

# Funzioni locali di import (3 tipi di foglio xlsx ISTAT)
source(here("moduli", "demo_trend_indicatori", "f_import_istat_xlsx.R"))

# Parametri ---------------------------------------------------------------
xlsx_in <- here("dati", "grezzi", "istat_trend_demog", "Indicatori_demografici.xls")
dir_out <- here("moduli", "demo_trend_indicatori", "output")

if (!file.exists(xlsx_in)) {
  stop("File non trovato: ", xlsx_in)
}

# 1. Fogli con header semplice (2 righe) ----------------------------------
fogli_semplici <- c(
  "quoziente_di_natalità",
  "quoziente_di_mortalità",
  "quoziente_di_nuzialità",
  "saldo_migratorio_interno",
  "saldo_migratorio_con_l_estero",
  # "saldo_migratorio_altro_motivo": foglio non presente nel file 2026 (c'era nel vecchio)
  "saldo_migratorio_totale",
  "crescita_naturale",
  "tasso_di_crescita_totale",
  "tasso_di_fecondità_totale",
  "età_media_al_parto"
)

# un tibble tidy per foglio, in una lista con nomi = nome foglio
lista_semplici <- fogli_semplici |>
  set_names() |>
  map(function(x) f_import_istat_simple_sheet(file_path = xlsx_in, sheet_name = x))

# 2. Foglio speranza di vita (unico, anno × sesso × età) ------------------
speranza_tutti <- f_import_istat_speranza(file_path = xlsx_in)

# derivo i due dataset attesi da 02_output.R (nomi rds come nel vecchio repo);
# tengo il totale "Maschi e femmine"; il dettaglio M/F resta in speranza_di_vita.rds
lista_speranza <- list(
  speranza_di_vita = speranza_tutti,
  speranza_di_vita_0 = speranza_tutti |>
    filter(sesso == "Maschi e femmine", eta == 0) |>
    mutate(indicatore = "speranza_di_vita_0") |>
    select(-sesso, -eta),
  speranza_di_vita_65 = speranza_tutti |>
    filter(sesso == "Maschi e femmine", eta == 65) |>
    mutate(indicatore = "speranza_di_vita_65") |>
    select(-sesso, -eta)
)

# 3. Fogli con header complesso (3 righe) ---------------------------------
# (nomi rds identici al vecchio repo, sono quelli attesi da 02_output.R)
lista_complessi <- list(
  indicatori_struttura_popolazione = f_import_istat_complex_sheet(
    file_path = xlsx_in, sheet_name = "struttura_popolazione"
  ),
  indicatori_di_struttura = f_import_istat_complex_sheet(
    file_path = xlsx_in, sheet_name = "indicatori_di_struttura"
  )
)

# 4. Salva nel proprio output/ --------------------------------------------
lista_tutti <- c(lista_semplici, lista_speranza, lista_complessi)

iwalk(lista_tutti, function(df, nome) {
  saveRDS(df, file.path(dir_out, paste0(nome, ".rds")))
  message("Salvato: ", nome, ".rds (", nrow(df), " righe)")
})
