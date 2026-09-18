# ___________________________________________________________________________
# ingestione/06a_get_istat_avq_ict.R
# SOLO DOWNLOAD: uso di internet e del pc per età e sesso (Italia, 2001→) e
# per regione (totale 6+), dall'indagine Aspetti della vita quotidiana,
# via API SDMX di IstatData (categoria "Internet e pc - tipo di utilizzatori").
# Tre richieste, serie complete (tutti gli anni), nessun blocco per territorio.
#
# Output: dati/grezzi/istat_cittadini_ict/sdmx_<nome>.rds (grezzo API: solo codici, niente etichette)
#         dati/grezzi/istat_cittadini_ict/sdmx_struttura_avq_persone.json (struttura + codelist, grezzo API)
# Quando: una volta l'anno (nuova edizione Cittadini e ICT, aprile) → cancellare i
#         tre rds e rilanciare
# Durata: 3 richieste x ~10 sec + pause (rate limit ISTAT ~5 query/min)
# NB 2026-09-17: lanciato e verificato (chiave "1+2+9" con età vuote OK; territori IT,
#     ITD = Nord-est, ITD5 = ER OK). Serie 2001→2025 SENZA il 2004 (24 anni); internet
#     da 6 anni (totale Y_GE6, 13 classi), pc da 3 anni (totale Y_GE3, 14 classi con Y3-5).
#     Colonne utili: TIME_PERIOD (anno), OBS_VALUE (valore).
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(httr)
library(rsdmx) # per leggere SDMX in formato XML (JSON non lo legge)
library(dplyr)
library(purrr)
library(stringr)
library(jsonlite)
source(here("R", "istat.R"))   # funzioni di ingestione ISTAT (v. indice in testa al file)

# Parametri ---------------------------------------------------------------
dir_raw <- here("dati", "grezzi", "istat_cittadini_ict")

# Struttura e codelist (una tantum: si rifà solo se ISTAT cambia la tavola) ---------
# È la "Query struttura" che il databrowser mostra accanto alla query dei dati (v. _metadati.md).
# Una sola risposta contiene: la tavola, la sua struttura (dimensioni in ordine = chiave)
# e le codelist (codice → etichetta). Il json è scaricato dalla SOLA tavola 237; vale anche per 241 e 239
# perché rimandano alla stessa struttura DCCV_AVQ_PERSONE (verifica più sotto, dopo `dimensioni`).
# NB: senza indicare un formato ISTAT risponde in JSON (non xml: readSDMX() non lo legge) → jsonlite.
# Salvo la risposta così com'è: è un grezzo, leggibile anche aprendolo con un editor.
URL_STRUTTURA <- "https://esploradati.istat.it/SDMXWS/rest/dataflow/IT1/83_63_DF_DCCV_AVQ_PERSONE_237/1.0/?detail=Full&references=Descendants"
file_raw_struttura <- file.path(dir_raw, "sdmx_struttura_avq_persone.json")

if (!file.exists(file_raw_struttura)) {
  risposta <- GET(URL_STRUTTURA, timeout(180))
  stop_for_status(risposta)
  writeBin(content(risposta, "raw"), file_raw_struttura)
}

# Leggo la struttura (JSON) e la converto in lista R
# Il json ha due pezzi: $meta (data e mittente della risposta) e $data, che è quello che tengo.
# struttura è una lista di 4 elementi (names(struttura)):
#   $dataflows      (1)   la tavola richiesta: id, nome ("Internet - dettaglio età") e struttura a cui rimanda
#   $dataStructures (1)   la struttura DCCV_AVQ_PERSONE: le 8 dimensioni in ordine + il tempo (→ `dimensioni`),
#                         gli attributi (OBS_STATUS, note, unità di misura) e la misura (OBS_VALUE)
#   $codelists      (14)  le tabelle codice → etichetta, in italiano e inglese (→ `etichette`):
#                         8 per le dimensioni + 6 per gli attributi (CL_FLAG = OBS_STATUS, note, anno base, unità)
#   $conceptSchemes (2)   i nomi estesi dei concetti (es. AGE = "Età"): qui non servono
# Per esplorarla: names(struttura); str(struttura$dataflows, max.level = 2); View(struttura)
struttura <- fromJSON(file_raw_struttura, simplifyVector = FALSE)$data

# dimensioni nell'ordine della chiave, con la codelist (codice → etichetta) di ciascuna
f_dimensione <- function(x) {
  tibble(posizione = x$position, dimensione = x$id,
         codelist = str_extract(x$localRepresentation$enumeration, "CL_[A-Z0-9_]+"))
}

dimensioni <- struttura$dataStructures[[1]]$dataStructureComponents$dimensionList$dimensions |>
  map(f_dimensione) |>
  bind_rows()

dimensioni   # 8 dimensioni + il tempo (TIME_PERIOD, sempre ultimo, non sta nella chiave)

# Le tre tavole usano la stessa struttura? Il json sopra viene dalla sola tavola 237, ma lo uso per
# leggere anche 241 (pc) e 239 (internet per territorio). Verifica una tantum, 2 richieste leggere:
# senza `references` la risposta contiene solo la tavola e il nome della struttura a cui rimanda
f_struttura_di <- function(id_tavola) {
  url <- paste0("https://esploradati.istat.it/SDMXWS/rest/dataflow/IT1/", id_tavola, "/1.0/")
  risposta <- GET(url, timeout(60))
  stop_for_status(risposta)
  tavola <- fromJSON(content(risposta, "text", encoding = "UTF-8"), simplifyVector = FALSE)$data$dataflows[[1]]
  str_extract(tavola$structure, "DCCV[A-Z_]+")
}

struttura$dataflows[[1]]$structure                  # 237: ...DataStructure=IT1:DCCV_AVQ_PERSONE(1.0)
# f_struttura_di("83_63_DF_DCCV_AVQ_PERSONE_241")   # atteso "DCCV_AVQ_PERSONE" — verificato il 2026-09-17
# Sys.sleep(15)
# f_struttura_di("83_63_DF_DCCV_AVQ_PERSONE_239")   # atteso "DCCV_AVQ_PERSONE" — verificato il 2026-09-17

# etichette: codice → dicitura ISTAT (in italiano), per le codelist delle 8 dimensioni + OBS_STATUS
# (solo per guardare e capire: il grezzo è il json, questa tabella non si salva)
etichette <- struttura$codelists |>
  map(f_codelist) |>
  bind_rows() |>
  filter(codelist %in% c(dimensioni$codelist, "CL_FLAG"))

count(etichette, codelist)   # quanti codici per codelist (Territorio e Tipo dato sono enormi: valgono per tutta l'indagine)

# i codici che uso nella chiave, con la loro dicitura
etichette |> filter(codelist == "CL_TIPO_DATO_AVQ", str_detect(codice, "^6_INT|^3_PC"))
etichette |> filter(codelist == "CL_MISURA_AVQ")
etichette |> filter(codelist == "CL_SEXISTAT1")

# Download dei dati ---------------------------------------------------------------
# id = la tavola (dal databrowser); chiave = il filtro: un valore per dimensione, nell'ordine di
# `dimensioni`, separati da "."; posizione vuota = tutte le modalità; "+" = oppure
#   FREQ.REF_AREA.DATA_TYPE.MEASURE.SEX.AGE.EDU_LEV_HIGHEST.LABOUR_PROFESS_STATUS_B
# Diciture ISTAT (lette dalle codelist in sdmx_struttura_avq_persone.json, 2026-09-17):
#   FREQ A = annuale; REF_AREA IT = Italia, ITD = Nord-est, ITD5 = Emilia-Romagna
#   DATA_TYPE vuoto = tutti; nelle tavole 237/239 "persone di 6 anni e più per utilizzo di Internet
#     e frequenza di utilizzo": 6_INTSI usano Internet, 6_INTTUTTI tutti i giorni, 6_INT_1P_SETT una o
#     più volte alla settimana, 6_INT_QV_MESE qualche volta al mese, 6_INT_QV_ANNO qualche volta
#     all'anno, 6_INTNO non usano Internet; nella 241 gli analoghi 3_PC* ("persone di 3 anni e più")
#   MEASURE HSC = per 100 persone con le stesse caratteristiche
#   SEX 1 = maschi, 2 = femmine, 9 = totale; AGE vuoto = tutte le classi (Y_GE6 = 6 anni e più)
#   EDU_LEV_HIGHEST 99 = totale (titolo di studio); LABOUR_PROFESS_STATUS_B 99 = totale (condizione dichiarata)
FLUSSI <- list(
  internet_eta = list(id = "IT1,83_63_DF_DCCV_AVQ_PERSONE_237,1.0", chiave = "A.IT..HSC.1+2+9..99.99"),
  pc_eta       = list(id = "IT1,83_63_DF_DCCV_AVQ_PERSONE_241,1.0", chiave = "A.IT..HSC.1+2+9..99.99"),
  internet_reg = list(id = "IT1,83_63_DF_DCCV_AVQ_PERSONE_239,1.0", chiave = "A.IT+ITD+ITD5..HSC.9.Y_GE6.99.99")
)
PAUSA_SEC <- 15

# Una richiesta SDMX: serie complete (tutti gli anni) ---------------------
f_get_avq <- function(dataset_id, chiave) {
  url <- paste0("https://esploradati.istat.it/SDMXWS/rest/data/", dataset_id, "/", chiave, "/ALL/?detail=full")
  message("URL richiesta: ", url)
  risposta <- GET(url, add_headers(Accept = "application/vnd.sdmx.structurespecificdata+xml;version=2.1"), timeout(120))
  if (status_code(risposta) != 200) stop("Errore HTTP ", status_code(risposta), " su ", dataset_id)
  tmp <- tempfile(fileext = ".xml")
  writeBin(content(risposta, "raw"), tmp)
  dati <- as.data.frame(readSDMX(tmp, isURL = FALSE), labels = TRUE)
  unlink(tmp)
  dati
}

# Download con cache --------------------------------------------------------
for (nome in names(FLUSSI)) {
  file_raw <- file.path(dir_raw, paste0("sdmx_", nome, ".rds"))
  if (file.exists(file_raw)) {
    message("Già presente, salto: ", basename(file_raw))
    next
  }
  dati <- f_get_avq(FLUSSI[[nome]]$id, FLUSSI[[nome]]$chiave)
  saveRDS(dati, file_raw)
  message("Salvato: ", basename(file_raw), " (", nrow(dati), " righe)")
  Sys.sleep(PAUSA_SEC)
}

# Verifiche rapide (da eseguire a mano) ------------------------------------
# NB: con questo formato SDMX le colonne sono TIME_PERIOD (anno) e OBS_VALUE (valore)
# OBS_STATUS quasi tutto NA è normale, non è un problema del download. È l'attributo SDMX per la "bandierina" sul singolo valore (provvisorio, stimato, rottura di serie, non significativo…)
# Dove NON è NA vale "0" = "il dato non raggiunge la metà della cifra minima considerata" (i ".." delle tavole ISTAT): lì OBS_VALUE manca. Edizione 2025: 30 celle piccole su 11.664 (frequenze rare, over 75)

internet_eta <- readRDS(file.path(dir_raw, "sdmx_internet_eta.rds"))
count(internet_eta, OBS_STATUS, valore_mancante = is.na(OBS_VALUE))   # attesi: NA/FALSE quasi tutte; "0"/TRUE poche
table(internet_eta$DATA_TYPE, internet_eta$AGE)   # 6 tipi di dato × 13 classi d'età
range(internet_eta$TIME_PERIOD)                   # atteso 2001 → 2025
sort(unique(internet_eta$TIME_PERIOD))            # quale anno manca? (atteso 2004)
internet_eta |> dplyr::filter(DATA_TYPE == "6_INTTUTTI", SEX == 9, AGE == "Y15-17", TIME_PERIOD %in% c("2010", "2025")) |> dplyr::select(TIME_PERIOD, OBS_VALUE) # attesi 52,9 e 94,0

internet_reg <- readRDS(file.path(dir_raw, "sdmx_internet_reg.rds"))
table(internet_reg$REF_AREA, internet_reg$DATA_TYPE)   # attesi IT, ITD (Nord-est), ITD5 (ER)
pc_eta <- readRDS(file.path(dir_raw, "sdmx_pc_eta.rds"))
table(pc_eta$DATA_TYPE, pc_eta$AGE)
dplyr::glimpse(internet_eta)
dplyr::distinct(internet_eta, DATA_TYPE, dplyr::pick(dplyr::contains("DATA_TYPE")))
#
# le classi d'età scaricate, con la dicitura ISTAT (attese 15: le 13 di internet + Y_GE3 e Y3-5 del pc)
etichette |> filter(codelist == "CL_ETA1", codice %in% c(internet_eta$AGE, pc_eta$AGE))
