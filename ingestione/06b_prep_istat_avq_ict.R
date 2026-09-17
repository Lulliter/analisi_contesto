# ___________________________________________________________________________
# Ingestione: ISTAT, Aspetti della vita quotidiana — uso di internet e del pc (serie 2001→)
# Input:  dati/grezzi/istat_cittadini_ict/sdmx_internet_eta.rds, sdmx_pc_eta.rds, sdmx_internet_reg.rds
#         (solo codici) + sdmx_struttura_avq_persone.json (codelist: codice → dicitura ISTAT); da 06a
# Output: dati/puliti/istat_ict/ict_uso_eta.rds (internet + pc × frequenza × sesso × età, Italia) (+ .csv)
#         dati/puliti/istat_ict/ict_uso_reg.rds (internet × frequenza, 6 anni e più: Italia, Nord-est, ER) (+ .csv)
#         formato lungo: 1 riga = strumento × frequenza × dimensioni × anno; valore = per 100 persone
# NB: fonte MULTI-modulo. Manca il 2004. Basi diverse: internet 6 anni e più, pc 3 anni e più
#     → il "Totale" NON è confrontabile tra i due strumenti, le classi d'età sì
#     Valori mancanti: solo dove ISTAT segnala stato_oss "0" = "il dato non raggiunge la metà della cifra
#     minima considerata" (quota < 0,05%: i ".." delle tavole). Il pulito li lascia NA: se trattarli
#     come zero lo decide (e lo dichiara) il modulo che li usa
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(purrr)
library(readr)
library(stringr)
library(jsonlite)
source(here("R", "f_codelist.R"))   # una codelist del json ISTAT → tibble codice/etichetta

# Parametri ---------------------------------------------------------------
dir_in  <- here("dati", "grezzi", "istat_cittadini_ict")
dir_out <- here("dati", "puliti", "istat_ict")
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)

# Struttura della query ISTAT dal json della struttura -----------------------------------
# struttura è una lista di 4 elementi (names(struttura)):
#   $dataflows      (1)   la tavola richiesta: id, nome ("Internet - dettaglio età") e struttura a cui rimanda
#   $dataStructures (1)   la struttura DCCV_AVQ_PERSONE: le 8 dimensioni in ordine + il tempo (→ `dimensioni`),
#                         gli attributi (OBS_STATUS, note, unità di misura) e la misura (OBS_VALUE)
#   $codelists      (14)  le tabelle codice → etichetta, in italiano e inglese (→ `etichette`):
#                         8 per le dimensioni + 6 per gli attributi (CL_FLAG = OBS_STATUS, note, anno base, unità)
#   $conceptSchemes (2)   i nomi estesi dei concetti (es. AGE = "Età"): qui non servono
# Per esplorarla: names(struttura); str(struttura$dataflows, max.level = 2); View(struttura)
struttura <- jsonlite::fromJSON(file.path(dir_in, "sdmx_struttura_avq_persone.json"), simplifyVector = FALSE)$data
 
# Etichette ISTAT dal json della struttura -----------------------------------
  # struttura$codelists è una lista di 14 elementi, uno per codelist: CL_FREQ, CL_ETA1 ...
  # ogni elemento è una lista annidata con 2 pezzi: $id (nome della codelist) e $codes (lista di codici)
etichette <- struttura$codelists |> 
  # map(f_codelist) applica la funzione f_codelist ai 14 elementi della lista struttura$codelists, 
  # restituendo una lista di 14 tibble con le colonne codelist, codice, etichetta
  map(f_codelist) |> 
  # bind_rows() impila i 14 tibble in uno solo 
  bind_rows()

# funzione locale: dai codici di una colonna alle diciture della sua codelist
f_etichetta <- function(codici, nome_codelist) {
  tab <- filter(etichette, codelist == nome_codelist)
  tab$etichetta[match(codici, tab$codice)]
}

# Funzione locale: codici → etichette, tipi giusti ---------------------------
f_pulisci_avq <- function(dati) {
  # OBS_STATUS arriva solo se l'API lo manda per quella tavola (in sdmx_internet_reg manca): lo creo vuoto
  if (!"OBS_STATUS" %in% names(dati)) dati$OBS_STATUS <- NA_character_
  dati |>
    as_tibble() |>
    mutate(
      anno       = as.integer(TIME_PERIOD),
      valore     = as.numeric(OBS_VALUE),
      stato_oss_lab = f_etichetta(OBS_STATUS, "CL_FLAG"),                      # dicitura della segnalazione ISTAT sul valore
      territorio = f_etichetta(REF_AREA, "CL_ITTER107"),
      sesso      = f_etichetta(SEX, "CL_SEXISTAT1") |> str_to_sentence(),      # "Maschi", come nel Bes
      tipo_dato  = f_etichetta(DATA_TYPE, "CL_TIPO_DATO_AVQ"),                 # dicitura ISTAT intera
      strumento  = if_else(str_detect(DATA_TYPE, "^6_INT"), "internet", "pc"),
      # frequenza = ultimo pezzo della dicitura ISTAT (dopo l'ultimo ":"), uguale per internet e pc
      frequenza  = str_extract(tipo_dato, "[^:]+$") |> str_trim(),
      frequenza  = case_when(str_detect(frequenza, "^non usano") ~ "non usano",
                             str_detect(frequenza, "^usano")     ~ "usano",
                             .default = frequenza),
      popolazione_rif = if_else(strumento == "internet", "6 anni e più", "3 anni e più"),
      # età come in bes_eta_sesso (si ordina da sola): "06-10", "15-17", "75 e più", "Totale"
      eta = case_when(
        AGE %in% c("Y_GE6", "Y_GE3") ~ "Totale",
        AGE == "Y_GE75"              ~ "75 e più",
        .default = str_remove(AGE, "^Y") |> str_replace("^(\\d)-(\\d)$", "0\\1-0\\2") |> str_replace("^(\\d)-", "0\\1-")
      )
    ) |>
    select(strumento, frequenza, territorio, sesso, eta, anno, valore,
           stato_oss = OBS_STATUS, stato_oss_lab, popolazione_rif, tipo_dato, cod_tipo_dato = DATA_TYPE, cod_eta = AGE)
}

# 1. Internet + pc per età e sesso (Italia) --------------------------------
ict_uso_eta <- bind_rows(readRDS(file.path(dir_in, "sdmx_internet_eta.rds")),
                         readRDS(file.path(dir_in, "sdmx_pc_eta.rds"))) |>
  f_pulisci_avq() |>
  arrange(strumento, frequenza, sesso, eta, anno)

ict_uso_eta
# controllo a occhio della ricodifica delle età
count(ict_uso_eta, strumento, eta, cod_eta)   

# 2. Internet per territorio (6 anni e più, sesso totale) --------------------
ict_uso_reg <- readRDS(file.path(dir_in, "sdmx_internet_reg.rds")) |>
  f_pulisci_avq() |>
  arrange(frequenza, territorio, anno)

ict_uso_reg

# Controlli ----------------------------------------------------------------
# nessun codice rimasto senza etichetta; nessun valore diventato NA nella conversione a numero
stopifnot(!anyNA(ict_uso_eta$tipo_dato), !anyNA(ict_uso_eta$sesso), !anyNA(ict_uso_reg$territorio))
# valori mancanti ammessi SOLO dove ISTAT segnala "0" = "il dato non raggiunge la metà della cifra
# minima considerata" (quota < 0,05%: i ".." delle tavole). Edizione 2025: 30 righe, frequenze rare e over 75
ict_uso_eta |> filter(is.na(valore)) |> count(stato_oss, stato_oss_lab)
stopifnot(all(ict_uso_eta$stato_oss[is.na(ict_uso_eta$valore)] == "0"))
stopifnot(!anyNA(ict_uso_reg$valore))

# Salvataggio ----------------------------------------------------------------
saveRDS(ict_uso_eta, file.path(dir_out, "ict_uso_eta.rds"))
write_csv(ict_uso_eta, file.path(dir_out, "ict_uso_eta.csv"))
saveRDS(ict_uso_reg, file.path(dir_out, "ict_uso_reg.rds"))
write_csv(ict_uso_reg, file.path(dir_out, "ict_uso_reg.csv"))
