# ___________________________________________________________________________
# Ingestione: ISTAT, tavola "Scuole" (DCIS_SCUOLE1_4) — scuola dell'infanzia per provincia
# Scarico via API SDMX di IstatData (con cache) + pulizia in un solo script.
# Indicata dalla Regione ER in risposta alla richiesta n. 3 (2026-10-15): il dato
# c'è solo per provincia (niente comuni).
#
# Input:  API SDMX IstatData, tavola 52_1045_DF_DCIS_SCUOLE1_4
# Output: dati/grezzi/istat_scuole/sdmx_struttura_scuole1_4.json (struttura + codelist, grezzo API)
#         dati/grezzi/istat_scuole/sdmx_scuole_infanzia.rds (grezzo API: solo codici)
#         dati/puliti/istat_scuole/scuole_infanzia.rds (+ .csv)
#         formato lungo: 1 riga = territorio × gestione × indicatore × anno
#         dati/grezzi/istat_scuole/sdmx_struttura_scuole1_2.json + sdmx_infanzia_conteggi.rds (2a tavola, grezzi API)
#         dati/puliti/istat_scuole/infanzia_conteggi.rds (+ .csv): scuole, classi, iscritti per gestione
#         (statale / non statale pubblica / privata), sesso e cittadinanza; 1 riga = territorio ×
#         gestione × sesso × cittadinanza × conteggio × anno (2a tavola DCIS_SCUOLE1_2, dal 2026-10-15)
# Quando: una volta l'anno (nuovo anno scolastico pubblicato) → cancellare sdmx_scuole_infanzia.rds e rilanciare
# NB: fonte MULTI-modulo (scuola_iscritti; scuola_disabilita per gli alunni con disabilità).
#     Sono INDICATORI, non conteggi (manca il numero di iscritti): iscritti per classe,
#     stranieri e femmine per 100 iscritti, disabili per 1.000 iscritti, % in scuole pubbliche.
#     Gestione: pubblica / privata / totale (ISTAT non separa statale e comunale).
#     Anno: TIME_PERIOD = anno T dell'a.s. T-1/T (databrowser, "Anno T (anno scolastico T-1/T)"):
#     2025 = a.s. 2024/25 → anno_inizio = anno - 1, come negli altri dati scuola del repo
# NB 2026-10-15: scarico lanciato e verificato (11 territori, 2015-2025, 1.573 righe);
#     unisce i precedenti 10_get_istat_scuole.R e 10b_prep_istat_scuole.R
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(httr)
library(rsdmx)    # per leggere SDMX in formato XML
library(dplyr)
library(purrr)
library(readr)
library(stringr)
library(jsonlite)
source(here("R", "istat.R"))   # f_codelist()

# Parametri ---------------------------------------------------------------
dir_raw <- here("dati", "grezzi", "istat_scuole")
dir_out <- here("dati", "puliti", "istat_scuole")

# tavola e struttura (dal databrowser: "Query struttura")
URL_STRUTTURA <- "https://esploradati.istat.it/SDMXWS/rest/dataflow/IT1/52_1045_DF_DCIS_SCUOLE1_4/1.0/?detail=Full&references=Descendants"
file_raw_struttura <- file.path(dir_raw, "sdmx_struttura_scuole1_4.json")

# dati (dal databrowser: "Query dati"); territori: IT = Italia, ITD5 = Emilia-Romagna,
# ITD51-ITD59 = le nove province (ITD52 = Parma)
ID_TAVOLA <- "IT1,52_1045_DF_DCIS_SCUOLE1_4,1.0"
CHIAVE    <- "A.IT+ITD5+ITD51+ITD52+ITD53+ITD54+ITD55+ITD56+ITD57+ITD58+ITD59.DISAB+ENROL+FEM+FOR+PUB...PRE.ALL+PRI+PUB.."
# NB 2026-10-15: SCHO, CLAS, ENR (conteggi) NON sono in questa tavola: stanno nella DCIS_SCUOLE1_2 (sotto)
# primo anno; senza anno finale si prende sempre l'ultimo pubblicato
ANNO_INIZIO <- "2015-01-01"
file_raw_dati <- file.path(dir_raw, "sdmx_scuole_infanzia.rds")

# nomi brevi degli indicatori (codice ISTAT → nome) e unità di misura
INDICATORI <- tibble::tribble(
  ~DATA_TYPE, ~indicatore,           ~unita,
  "ENROL",    "iscritti_per_classe", "iscritti per classe",
  "DISAB",    "disabili_per_1000",   "per 1.000 iscritti",
  "FOR",      "stranieri_pct",       "% sugli iscritti",
  "FEM",      "femmine_pct",         "% sugli iscritti",
  "PUB",      "pubbliche_pct",       "% sugli iscritti"
)

# 2a tavola: "Infanzia - scuole, classi, bambini" (conteggi); stessa struttura DCIS_SCUOLE1 della prima,
# 9 dimensioni: FREQ.REF_AREA.DATA_TYPE.SEX.CITIZENSHIP.SCHOOL_LEVEL.TYPE_SCHOOL_MANAGEMENT.SCHOOL_YEAR.TYPE_SCHOOL
# (il csv del databrowser mostra solo 7 colonne: le ultime due sono costanti); vuoto = tutte le modalità
# NB 2026-10-15: con 7 posizioni nella chiave l'API risponde HTTP 422
URL_STRUTTURA_2 <- "https://esploradati.istat.it/SDMXWS/rest/dataflow/IT1/52_1045_DF_DCIS_SCUOLE1_2/1.0/?detail=Full&references=Descendants"
file_raw_struttura_2 <- file.path(dir_raw, "sdmx_struttura_scuole1_2.json")
ID_TAVOLA_2 <- "IT1,52_1045_DF_DCIS_SCUOLE1_2,1.0"
CHIAVE_2    <- "A.IT+ITD5+ITD51+ITD52+ITD53+ITD54+ITD55+ITD56+ITD57+ITD58+ITD59.CLAS+ENR+SCHO...PRE..."
file_raw_dati_2 <- file.path(dir_raw, "sdmx_infanzia_conteggi.rds")
CONTEGGI <- c(SCHO = "scuole", CLAS = "classi", ENR = "iscritti")

dir.create(dir_raw, showWarnings = FALSE, recursive = TRUE)
dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

# 1. Struttura e codelist (una tantum: si rifà solo se ISTAT cambia la tavola) ---------
# senza indicare un formato ISTAT risponde in JSON → jsonlite; salvo la risposta così com'è
if (!file.exists(file_raw_struttura)) {
  risposta <- GET(URL_STRUTTURA, timeout(180))
  stop_for_status(risposta)
  writeBin(content(risposta, "raw"), file_raw_struttura)
}

struttura <- fromJSON(file_raw_struttura, simplifyVector = FALSE)$data

# dimensioni nell'ordine della chiave, con la codelist di ciascuna
f_dimensione <- function(x) {
  tibble(posizione = x$position, dimensione = x$id,
         codelist = str_extract(x$localRepresentation$enumeration, "CL_[A-Z0-9_]+"))
}

dimensioni <- struttura$dataStructures[[1]]$dataStructureComponents$dimensionList$dimensions |>
  map(f_dimensione) |>
  bind_rows()

# leggere qui l'ordine delle dimensioni: è quello della CHIAVE
dimensioni

# etichette: codice → dicitura ISTAT, per tutte le codelist
etichette <- struttura$codelists |>
  map(f_codelist) |>
  bind_rows()

# struttura e codelist della 2a tavola (le dimensioni non sono le stesse della prima)
if (!file.exists(file_raw_struttura_2)) {
  Sys.sleep(15)
  risposta <- GET(URL_STRUTTURA_2, timeout(180))
  stop_for_status(risposta)
  writeBin(content(risposta, "raw"), file_raw_struttura_2)
}

struttura_2 <- fromJSON(file_raw_struttura_2, simplifyVector = FALSE)$data

dimensioni_2 <- struttura_2$dataStructures[[1]]$dataStructureComponents$dimensionList$dimensions |>
  map(f_dimensione) |>
  bind_rows()

# ordine della CHIAVE_2 e codelist di ogni dimensione
dimensioni_2

etichette_2 <- struttura_2$codelists |>
  map(f_codelist) |>
  bind_rows()

# 2. Scarico dei dati (con cache: per riscaricare cancellare l'rds) -------------
f_get_sdmx <- function(dataset_id, chiave, inizio) {
  url <- paste0("https://esploradati.istat.it/SDMXWS/rest/data/", dataset_id, "/", chiave,
                "/ALL/?detail=full&startPeriod=", inizio)
  message("URL richiesta: ", url)
  risposta <- GET(url, add_headers(Accept = "application/vnd.sdmx.structurespecificdata+xml;version=2.1"), timeout(120))
  if (status_code(risposta) != 200) stop("Errore HTTP ", status_code(risposta), " su ", dataset_id)
  tmp <- tempfile(fileext = ".xml")
  writeBin(content(risposta, "raw"), tmp)
  dati <- as.data.frame(readSDMX(tmp, isURL = FALSE), labels = TRUE)
  unlink(tmp)
  dati
}

if (!file.exists(file_raw_dati)) {
  Sys.sleep(15)
  saveRDS(f_get_sdmx(ID_TAVOLA, CHIAVE, ANNO_INIZIO), file_raw_dati)
}

scuole_infanzia_raw <- readRDS(file_raw_dati)

if (!file.exists(file_raw_dati_2)) {
  Sys.sleep(15)
  saveRDS(f_get_sdmx(ID_TAVOLA_2, CHIAVE_2, ANNO_INIZIO), file_raw_dati_2)
}

infanzia_conteggi_raw <- readRDS(file_raw_dati_2)

# verifiche sul grezzo della 2a tavola: SCHO e CLAS solo sul totale di sesso e cittadinanza;
# gestione ALL, PUB = STA + PUB_NSTA (comunali e altri enti pubblici), PRI
count(infanzia_conteggi_raw, DATA_TYPE, SEX, CITIZENSHIP)
count(infanzia_conteggi_raw, TYPE_SCHOOL_MANAGEMENT)

# verifiche sul grezzo: 11 territori (IT, ITD5, 9 province), anni dal 2015
count(scuole_infanzia_raw, REF_AREA)
sort(unique(scuole_infanzia_raw$TIME_PERIOD))
# 13 serie per territorio (4 indicatori × 3 gestioni + PUB sul totale); niente colonna OBS_STATUS
count(scuole_infanzia_raw, DATA_TYPE, TYPE_SCHOOL_MANAGEMENT)

# 3. Pulizia: codici → etichette, tipi giusti ---------------------------------
# dai codici di una colonna alle diciture della SUA codelist
# (gli stessi codici, es. PUB o FOR, hanno significati diversi in codelist diverse)
f_etichetta <- function(codici, nome_codelist) {
  tab <- filter(etichette, codelist == nome_codelist)
  tab$etichetta[match(codici, tab$codice)]
}

scuole_infanzia <- scuole_infanzia_raw |>
  as_tibble() |>
  left_join(INDICATORI, by = "DATA_TYPE") |>
  mutate(
    anno       = as.integer(TIME_PERIOD),
    # a.s. T-1/T: anno di inizio, come anno_inizio dei dati MIM (etichetta "2024/25" con f_lab_as)
    anno_inizio = anno - 1L,
    valore     = as.numeric(OBS_VALUE),
    territorio = f_etichetta(REF_AREA, "CL_ITTER107"),
    gestione   = f_etichetta(TYPE_SCHOOL_MANAGEMENT, "CL_NATGIUR1"),
    tipo_dato  = f_etichetta(DATA_TYPE, "CL_TIPO_DATO_ISTR")
  ) |>
  select(territorio, cod_territorio = REF_AREA, gestione, indicatore, unita, anno, anno_inizio, valore,
         tipo_dato, cod_tipo_dato = DATA_TYPE, cod_gestione = TYPE_SCHOOL_MANAGEMENT) |>
  arrange(indicatore, gestione, cod_territorio, anno)

scuole_infanzia

# 4. Pulizia della 2a tavola (conteggi) ------------------------------------
# etichetta dalla codelist della dimensione (presa da dimensioni_2: niente nomi scritti a mano)
f_etichetta_2 <- function(codici, dimensione) {
  nome_codelist <- dimensioni_2$codelist[dimensioni_2$dimensione == dimensione]
  tab <- filter(etichette_2, codelist == nome_codelist)
  tab$etichetta[match(codici, tab$codice)]
}

infanzia_conteggi <- infanzia_conteggi_raw |>
  as_tibble() |>
  mutate(
    anno        = as.integer(TIME_PERIOD),
    anno_inizio = anno - 1L,
    valore      = as.numeric(OBS_VALUE),
    conteggio   = unname(CONTEGGI[DATA_TYPE]),
    territorio  = f_etichetta_2(REF_AREA, "REF_AREA"),
    gestione    = f_etichetta_2(TYPE_SCHOOL_MANAGEMENT, "TYPE_SCHOOL_MANAGEMENT"),
    sesso       = f_etichetta_2(SEX, "SEX"),
    cittadinanza = f_etichetta_2(CITIZENSHIP, "CITIZENSHIP")
  ) |>
  select(territorio, cod_territorio = REF_AREA, gestione, cod_gestione = TYPE_SCHOOL_MANAGEMENT,
         sesso, cittadinanza, conteggio, anno, anno_inizio, valore) |>
  arrange(conteggio, cod_gestione, cod_territorio, sesso, cittadinanza, anno)

infanzia_conteggi

# Controlli ----------------------------------------------------------------
# ogni codice ha la sua etichetta; nessun valore perso nella conversione a numero
stopifnot(!anyNA(scuole_infanzia$territorio), !anyNA(scuole_infanzia$gestione),
          !anyNA(scuole_infanzia$tipo_dato), !anyNA(scuole_infanzia$indicatore))
count(scuole_infanzia, valore_mancante = is.na(valore))
# attesi: 5 indicatori; gestione "totale", "pubblica", "privata" (pubbliche_pct solo sul totale)
count(scuole_infanzia, indicatore, gestione)
# Parma ed Emilia-Romagna, ultimo anno, gestione totale: a colpo d'occhio
scuole_infanzia |>
  filter(cod_territorio %in% c("ITD5", "ITD52"), gestione == "totale", anno == max(anno)) |>
  select(territorio, indicatore, valore)

# 2a tavola: etichette complete; iscritti di Parma nell'ultimo anno per gestione (totale = pubblica + privata?)
stopifnot(!anyNA(infanzia_conteggi$territorio), !anyNA(infanzia_conteggi$gestione),
          !anyNA(infanzia_conteggi$sesso), !anyNA(infanzia_conteggi$cittadinanza))
count(infanzia_conteggi, conteggio, gestione)
infanzia_conteggi |>
  filter(cod_territorio == "ITD52", conteggio == "iscritti", sesso == "totale",
         cittadinanza == "totale", anno == max(anno)) |>
  select(gestione, valore)

# Salvataggio ----------------------------------------------------------------
saveRDS(scuole_infanzia, file.path(dir_out, "scuole_infanzia.rds"))
write_csv(scuole_infanzia, file.path(dir_out, "scuole_infanzia.csv"))
saveRDS(infanzia_conteggi, file.path(dir_out, "infanzia_conteggi.rds"))
write_csv(infanzia_conteggi, file.path(dir_out, "infanzia_conteggi.csv"))
