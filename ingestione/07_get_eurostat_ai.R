# ___________________________________________________________________________
# ingestione/07_get_eurostat_ai.R
# SOLO DOWNLOAD: uso di strumenti di IA generativa da parte delle persone (Eurostat, dataset
# isoc_ai_iaiu). È l'indagine europea armonizzata sull'uso delle ICT: per l'Italia i dati vengono
# dall'indagine ISTAT Aspetti della vita quotidiana. Tavola intera: tutti i paesi, tutte le
# caratteristiche (età, sesso, istruzione...), anno 2025 = prima rilevazione.
#
# Output: dati/grezzi/eurostat_isoc_ai/isoc_ai_iaiu.rds            (tavola come arriva: solo codici)
#         dati/grezzi/eurostat_isoc_ai/isoc_ai_iaiu_etichette.rds  (codice → dicitura Eurostat)
# Quando: una volta l'anno (Eurostat pubblica a dicembre) → cancellare i due rds e rilanciare
# NB: i dizionari Eurostat esistono solo in inglese, francese e tedesco: le diciture restano in
#     inglese qui, la traduzione si fa nel modulo che le usa
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(purrr)
library(eurostat)

# Parametri ---------------------------------------------------------------
dir_raw <- here("dati", "grezzi", "eurostat_isoc_ai")
if (!dir.exists(dir_raw)) dir.create(dir_raw, recursive = TRUE)

DATASET    <- "isoc_ai_iaiu"
DIMENSIONI <- c("indic_is", "ind_type", "unit", "geo")   # le colonne di codici di cui salvo le etichette
file_raw            <- file.path(dir_raw, "isoc_ai_iaiu.rds")
file_raw_etichette  <- file.path(dir_raw, "isoc_ai_iaiu_etichette.rds")

# Download con cache ---------------------------------------------------------
# get_eurostat() scarica la tavola INTERA (non si filtra alla fonte: è piccola, ~40.000 righe)
if (!file.exists(file_raw)) {
  isoc_ai_iaiu <- get_eurostat(DATASET, time_format = "num", cache = FALSE)
  saveRDS(isoc_ai_iaiu, file_raw)
}
isoc_ai_iaiu <- readRDS(file_raw)

isoc_ai_iaiu

# Etichette dei codici ---------------------------------------------------------
# get_eurostat_dic("ind_type") restituisce il dizionario di una dimensione (code_name, full_name);
# tengo solo i codici presenti in questa tavola
f_dizionario <- function(dimensione, dati) {
  get_eurostat_dic(dimensione) |>
    filter(code_name %in% dati[[dimensione]]) |>
    transmute(dimensione = dimensione, codice = code_name, etichetta = full_name)
}

if (!file.exists(file_raw_etichette)) {
  isoc_ai_iaiu_etichette <- DIMENSIONI |>
    map(f_dizionario, dati = isoc_ai_iaiu) |>
    bind_rows()
  saveRDS(isoc_ai_iaiu_etichette, file_raw_etichette)
}

isoc_ai_iaiu_etichette <- readRDS(file_raw_etichette)

count(isoc_ai_iaiu_etichette, dimensione)   # attesi: 4 indicatori, 104 caratteristiche, 3 unità, i paesi

# Verifiche rapide (da eseguire a mano) ------------------------------------
count(isoc_ai_iaiu, TIME_PERIOD)            # atteso: solo 2025
filter(isoc_ai_iaiu_etichette, dimensione %in% c("indic_is", "unit"))
# valori di prova (letti il 2026-09-17): Italia 16-19 anni = 51,9; Italia totale 16-74 = 19,9; UE totale = 32,7
isoc_ai_iaiu |>
  filter(indic_is == "I_IUAI", unit == "PC_IND", geo %in% c("IT", "EU27_2020"), ind_type %in% c("Y16_19", "IND_TOTAL"))

