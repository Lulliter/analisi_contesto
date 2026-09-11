# ------------------------------------------------------------------------
# Modulo: scuola_disabilita
# Fonte:  USR Emilia-Romagna, fact sheet "Studenti e studenti con disabilità"
#         (scuola STATALE, organico di fatto), trascritti in csv;
#         ISTAT, "L'inclusione scolastica degli alunni con disabilità" (Tavola 1,
#         serie nazionale, statali + non statali)
# Input:  dati/grezzi/istat_alunni_disab/usr_er_alunni_disab.csv
#         dati/grezzi/istat_alunni_disab/ISTAT_alunni-con-disabilita-as.-2024-25.xlsx
# Output: moduli/scuola_disabilita/output/<oggetto>.rds + .csv (nome file = oggetto):
#         disab_trend_prov_er   (anno × provincia ER, tutti i gradi: alunni,
#                                alunni con disabilità, quota)
#         disab_grado_prov_er   (anno × provincia × grado, solo a.s. con dettaglio)
#         disab_trend_italia    (anno × ordine di scuola: % alunni con disabilità, ISTAT)
# NB: USR-ER = solo scuole STATALI (infanzia inclusa); ISTAT = statali + paritarie.
#     I due numeri non sono direttamente confrontabili.
# ------------------------------------------------------------------------

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(readr)
library(readxl)
library(stringr)
library(purrr)

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "scuola_disabilita", "output")
if (!dir.exists(dir_mod)) dir.create(dir_mod, recursive = TRUE)

dir_grezzi <- here("dati", "grezzi", "istat_alunni_disab")
file_usER <- file.path(dir_grezzi, "usr_er_alunni_disab.csv")
file_istat <- file.path(dir_grezzi, "ISTAT_alunni-con-disabilita-as.-2024-25.xlsx")
FOGLIO_ISTAT <- "Tavola 1" # serie nazionale per ordine (per 100 alunni)

# 1. Carica input ---------------------------------------------------------
usr_er_alunni_disab <- read_csv(file_usER, show_col_types = FALSE)

# 2. USR-ER: una sola osservazione per anno × provincia × grado ---------------
# I fact sheet riportano l'a.s. corrente (provvisorio) e il precedente
# (definitivo): dove ci sono entrambi si tiene il DEFINITIVO
usr_er_disab <- usr_er_alunni_disab |>
  arrange(anno_inizio, provincia, grado, tipo_dato) |> # "definitivo" < "provvisorio"
  slice_head(n = 1, by = c(anno_inizio, provincia, grado)) |>
  mutate(quota_disab = alunni_disab / alunni)

## __ Trend per provincia ER, tutti i gradi -----
disab_trend_prov_er <- usr_er_disab |>
  filter(grado == "totale") |>
  select(anno_inizio, provincia, alunni, alunni_disab, quota_disab, tipo_dato)
disab_trend_prov_er

## __ Dettaglio per grado (solo gli a.s. in cui il fact sheet lo riporta) -----
disab_grado_prov_er <- usr_er_disab |>
  filter(grado != "totale") |>
  mutate(grado = factor(grado,
    levels = c("infanzia", "primaria", "sec_1_grado", "sec_2_grado"),
    labels = c("Infanzia", "Primaria", "Secondaria I grado", "Secondaria II grado")
  )) |>
  select(anno_inizio, provincia, grado, alunni, alunni_disab, quota_disab, tipo_dato)
disab_grado_prov_er

# 3. ISTAT Tavola 1: serie nazionale per ordine di scuola -------------------
# riga 1 = titolo, riga 2 = intestazioni, poi un a.s. per riga; note in coda
disab_trend_italia <- read_excel(file_istat, sheet = FOGLIO_ISTAT, skip = 1) |>
  rename(anno_scolastico = 1) |>
  select(!starts_with("...")) |> # colonne vuote senza nome a destra della tavola
  filter(str_starts(anno_scolastico, "a.s.")) |>
  # tutte le colonne dei valori a numerico PRIMA del pivot (una cella è testo, "2.9")
  mutate(across(-anno_scolastico, as.numeric)) |>
  # "a.s.2014/2015" → 2014; l'asterisco segna il dato provvisorio
  mutate(anno_inizio = as.integer(str_extract(anno_scolastico, "\\d{4}")),
         tipo_dato = if_else(str_detect(anno_scolastico, "\\*"), "provvisorio", "definitivo")) |>
  tidyr::pivot_longer(-c(anno_scolastico, anno_inizio, tipo_dato),
                      names_to = "ordine_scuola", values_to = "per_100_alunni") |>
  mutate(quota_disab = per_100_alunni / 100) |>
  select(anno_inizio, ordine_scuola, quota_disab, tipo_dato)

disab_trend_italia

# 4. Salva nel proprio output/ (rds + csv, nome file = oggetto) ------------
lista_out <- list(
  disab_trend_prov_er = disab_trend_prov_er,
  disab_grado_prov_er = disab_grado_prov_er,
  disab_trend_italia = disab_trend_italia
)

iwalk(lista_out, function(df, nome) {
  saveRDS(df, file.path(dir_mod, paste0(nome, ".rds")))
  write_csv(df, file.path(dir_mod, paste0(nome, ".csv")))
  message("Salvato: ", nome, " (", nrow(df), " righe)")
})

# Verifiche rapide (da eseguire a mano) ------------------------------------
disab_trend_prov_er |> filter(provincia == "Parma")         # 2024: 2.147 su 54.352 (~3,9%)
disab_trend_prov_er |> count(anno_inizio)                   # atteso: 9 a.s., 10 territori
disab_grado_prov_er |> filter(provincia == "Parma", anno_inizio == 2024)
disab_trend_italia |> filter(ordine_scuola == "Tutti gli ordini")  # 2,6% → 4,8%
