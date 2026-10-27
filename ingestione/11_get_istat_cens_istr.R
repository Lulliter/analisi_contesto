# ___________________________________________________________________________
# ingestione/11_get_istat_cens_istr.R
# SOLO DOWNLOAD: censimento permanente, categoria "Istruzione, lavoro e spostamenti
# per studio o lavoro" (struttura DCSS_ISTR_LAV_PEN_2), via API SDMX di IstatData.
# Tavole (righe di FLUSSI):
#   istr_eta   grado di istruzione ed età, 9 anni e più — comuni PR + confronti, 2018→
#   istr_citt  grado di istruzione e cittadinanza, 9 anni e più — comuni PR + confronti, 2018→
#   formaz     frequenza di un corso di formazione/aggiornamento professionale, 14 anni e più —
#              solo province e grandi comuni (struttura diversa: DCSS_LCAS_FRISC)
# Le altre tavole della categoria (condizione professionale, spostamenti) si aggiungono come righe di FLUSSI.
#
# Input:  API SDMX ISTAT (nessun file locale, salvo la lista dei comuni ER)
# Output: dati/grezzi/istat_cens_diplomi_profess/sdmx_struttura_<nome>.json (struttura + codelist, grezzo API)
#         dati/grezzi/istat_cens_diplomi_profess/sdmx_<nome>.rds (grezzo API: solo codici, niente etichette)
# Quando: una volta l'anno (nuovo anno censuario) → aggiornare ANNO_FINE, cancellare gli rds e rilanciare
# Durata: 3 richieste di struttura + fino a 3 blocchi di territori per tavola, con pause (rate limit ISTAT ~5 query/min): ~3-4 min
# NB 2026-10-27: chiavi prese dalle "Query del dato" del databrowser (download a mano di controllo
#     nella stessa cartella, un json per tavola). Territori a blocchi da 20 perché il server tronca le chiavi
#     lunghe (v. dati/grezzi/istat_cens/_metadati.md).
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(httr)
library(rsdmx) # per leggere SDMX in formato XML (JSON non lo legge)
library(dplyr)
library(purrr)
library(stringr)
library(jsonlite)
source(here("R", "istat.R"))   # f_codelist()

# Parametri ---------------------------------------------------------------
ANNO_INIZIO <- 2018   # primo anno del censimento permanente
ANNO_FINE   <- 2024   # ultimo anno disponibile (verificato il 2026-10-27)

dir_raw <- here("dati", "grezzi", "istat_cens_diplomi_profess")
dir.create(dir_raw, recursive = TRUE, showWarnings = FALSE)

# Comuni ER: vettore creato da ingestione/00_prep_shp_situas.R → CODICI_COMUNI_ER (330 codici)
source(here("dati", "puliti", "istat_shp", "lista_PRO_COM_T_er_vec.R"))

# Territori: i 44 comuni attuali della provincia di Parma + i 2 soppressi nel 2019
# (Mezzani 034021 e Sorbolo 034037, fusi in Sorbolo Mezzani 034051: hanno dati solo per il 2018)
# + Italia, Emilia-Romagna e le 9 province ER (ITD52 = Parma)
COMUNI_PR   <- c(str_subset(CODICI_COMUNI_ER, "^034"), "034021", "034037")
AGGREGATI   <- c("IT", "ITD5", paste0("ITD5", 1:9))
TERRITORI   <- c(COMUNI_PR, AGGREGATI)
PER_BLOCCO  <- 20
PAUSA_SEC   <- 20

# Tavole: id dal databrowser; territori; chiave = filtro sulle dimensioni DOPO il territorio, nell'ordine
# di `dimensioni` (posizione vuota = tutte le modalità; "+" = oppure)
#   istr_eta, istr_citt (struttura DCSS_ISTR_LAV_PEN_2):
#     INDICATOR.GENDER.AGE_NOCLASS.CITIZENSHIP.EDU_ATTAIN.CUR_ACT_STAT.LOC_DEST.REAS_COMMUTING
#   formaz (struttura DCSS_LCAS_FRISC):
#     INDICATOR.GENDER.AGE_CLASS.WORK_HOME.VOCAT_TRAIN_ATT.DAY_NUR_PRIM_SCH.ENROL_COURSE
# Diciture ISTAT (dal json di controllo, 2026-10-27):
#   RESPOP_AV = popolazione residente al 31 dicembre; F, M, T = femmine, maschi, totale
#   età: Y9-24, Y25-49, Y50-64, Y_GE65, Y_GE9 (9 anni e più) — NON ci sono classi più fini
#   grado di istruzione: NED nessun titolo, PSE licenza elementare, LSE licenza media,
#     USE_IF diploma di II grado o qualifica professionale (compresi IFP e IFTS),
#     BL ITS o terziario di primo livello, ML_RDD terziario di secondo livello e dottorato
#     (ML e RDD separati solo per 9 anni e più); NON esiste un totale: si somma
#   cittadinanza (solo nella tavola TV_2, solo 9 anni e più): ITL italiani, FRGAPO stranieri e apolidi, TOTAL totale
#   formaz: Y_GE14 = 14 anni e più; VOCAT_TRAIN_ATT 1 = sì, 0 = no, 9 = totale (frequenta un corso di
#     formazione/aggiornamento professionale); le altre dimensioni solo TOTAL/9
FLUSSI <- list(
  istr_eta = list(
    id        = "IT1,DF_DCSS_ISTR_LAV_PEN_2_TV_1,1.0",
    territori = TERRITORI,
    chiave    = "RESPOP_AV.F+M+T.Y9-24+Y25-49+Y50-64+Y_GE65+Y_GE9..NED+PSE+LSE+USE_IF+BL+ML_RDD+ML+RDD..."
  ),
  istr_citt = list(
    id        = "IT1,DF_DCSS_ISTR_LAV_PEN_2_TV_2,1.0",
    territori = TERRITORI,
    chiave    = "RESPOP_AV.F+M+T.Y_GE9.FRGAPO+ITL+TOTAL.NED+PSE+LSE+USE_IF+BL+ML_RDD..."
  ),
  formaz = list(
    id        = "IT1,DF_DCSS_LCAS_FRISC_3,1.0",
    territori = AGGREGATI,   # niente comuni piccoli in questa tavola
    chiave    = "RESPOP_AV.F+M+T.Y_GE14..0+1+9.."
  )
)

# A) Metadati: struttura e codelist di ogni tavola (una tantum) ---------
# È la "Query struttura" del databrowser: dimensioni in ordine (= chiave) e codelist (codice → etichetta)
# Una per tavola, scaricate separatamente (istr_eta e istr_citt hanno le stesse dimensioni, formaz no)

# scarica una "Query struttura" e la salva così com'è (se il file c'è già, non riscarica)
f_get_cens_medatati <- function(url, file) {
  if (file.exists(file)) return(invisible(file))
  risposta <- GET(url, timeout(180))
  stop_for_status(risposta)
  writeBin(content(risposta, "raw"), file)
  Sys.sleep(PAUSA_SEC)
  invisible(file)
}

# A.1a) metadati istr_eta: grado di istruzione ed età -----
f_get_cens_medatati(
  url  = "https://esploradati.istat.it/SDMXWS/rest/dataflow/IT1/DF_DCSS_ISTR_LAV_PEN_2_TV_1/1.0/?detail=Full&references=Descendants",
  file = file.path(dir_raw, "sdmx_struttura_istr_eta.json")
)

# A.1b) metadati istr_citt: grado di istruzione e cittadinanza -----
f_get_cens_medatati(
  url  = "https://esploradati.istat.it/SDMXWS/rest/dataflow/IT1/DF_DCSS_ISTR_LAV_PEN_2_TV_2/1.0/?detail=Full&references=Descendants",
  file = file.path(dir_raw, "sdmx_struttura_istr_citt.json")
)

# A.2) metadati formaz: frequenza di un corso di formazione professionale -----
f_get_cens_medatati(
  url  = "https://esploradati.istat.it/SDMXWS/rest/dataflow/IT1/DF_DCSS_LCAS_FRISC_3/1.0/?detail=Full&references=Descendants",
  file = file.path(dir_raw, "sdmx_struttura_formaz.json")
)

# A) Esplorazione dei metadati: dimensioni ed etichette di una tavola -----
# da qui si guarda una struttura per volta: cambiare il nome del file (istr_eta, istr_citt, formaz)
struttura <- fromJSON(file.path(dir_raw, "sdmx_struttura_istr_eta.json"), simplifyVector = FALSE)$data

# dimensioni nell'ordine della chiave, con la codelist di ciascuna
f_dimensione <- function(x) {
  tibble(posizione = x$position, dimensione = x$id,
         codelist = str_extract(x$localRepresentation$enumeration, "CL_[A-Z0-9_]+"))
}

dimensioni <- struttura$dataStructures[[1]]$dataStructureComponents$dimensionList$dimensions |>
  map(f_dimensione) |>
  bind_rows()

dimensioni   # istr_eta e istr_citt: attese 10 = FREQ, REF_AREA + le 8 della chiave; formaz: 9

# etichette delle codelist usate (solo per guardare: il grezzo è il json)
etichette <- struttura$codelists |>
  map(f_codelist) |>
  bind_rows() |>
  filter(codelist %in% dimensioni$codelist)

count(etichette, codelist)

# B) Dati: funzioni di download -----

# Una richiesta SDMX: un blocco di territori, tutti gli anni del periodo
f_get_cens_istr <- function(dataset_id, territori, chiave) {
  url <- paste0("https://esploradati.istat.it/SDMXWS/rest/data/", dataset_id, "/",
                "A.", paste(territori, collapse = "+"), ".", chiave, "/ALL/?detail=full",
                "&startPeriod=", ANNO_INIZIO, "-01-01&endPeriod=", ANNO_FINE, "-12-31",
                "&dimensionAtObservation=TIME_PERIOD")
  message("URL richiesta: ", url)
  risposta <- GET(url, add_headers(Accept = "application/vnd.sdmx.structurespecificdata+xml;version=2.1"), timeout(180))
  if (status_code(risposta) != 200) stop("Errore HTTP ", status_code(risposta), " su ", dataset_id)
  tmp <- tempfile(fileext = ".xml")
  writeBin(content(risposta, "raw"), tmp)
  dati <- as.data.frame(readSDMX(tmp, isURL = FALSE), labels = TRUE)
  unlink(tmp)
  Sys.sleep(PAUSA_SEC)
  dati
}

# Download con cache: una tavola = un rds; i blocchi di territori si uniscono

# scarica una tavola di FLUSSI a blocchi di territori, la salva e la restituisce (se il file c'è già, lo rilegge)
f_get_cens_dati <- function(flusso, file) {
  if (file.exists(file)) return(readRDS(file))
  blocchi <- split(flusso$territori, ceiling(seq_along(flusso$territori) / PER_BLOCCO))
  dati <- blocchi |>
    map(function(x) f_get_cens_istr(flusso$id, x, flusso$chiave)) |>
    bind_rows()
  saveRDS(dati, file)
  dati
}

# B.1a) dati istr_eta: grado di istruzione ed età -----
istr_eta <- f_get_cens_dati(FLUSSI$istr_eta, file.path(dir_raw, "sdmx_istr_eta.rds"))

# B.1b) dati istr_citt: grado di istruzione e cittadinanza -----
istr_citt <- f_get_cens_dati(FLUSSI$istr_citt, file.path(dir_raw, "sdmx_istr_citt.rds"))

# B.2) dati formaz: frequenza di un corso di formazione professionale -----
formaz <- f_get_cens_dati(FLUSSI$formaz, file.path(dir_raw, "sdmx_formaz.rds"))

# C) Verifiche rapide (da eseguire a mano) ------------------------------------
# istr_eta <- readRDS(file.path(dir_raw, "sdmx_istr_eta.rds"))
glimpse(istr_eta)
setdiff(TERRITORI, istr_eta$REF_AREA)                  # territori mancanti: atteso nessuno
count(istr_eta, TIME_PERIOD)                           # attesi 2018 → ANNO_FINE
count(istr_eta, OBS_STATUS, mancante = is.na(OBS_VALUE))
table(istr_eta$AGE_NOCLASS, istr_eta$EDU_ATTAIN)       # ML e RDD solo con Y_GE9
# riscontro col json scaricato a mano: comune di Parma, totale, 9+, 2024, nessun titolo (NED) → atteso 6575
istr_eta |> filter(REF_AREA == "034027", GENDER == "T", AGE_NOCLASS == "Y_GE9", TIME_PERIOD == "2024")

# istr_citt <- readRDS(file.path(dir_raw, "sdmx_istr_citt.rds"))
setdiff(TERRITORI, istr_citt$REF_AREA)
table(istr_citt$CITIZENSHIP, istr_citt$EDU_ATTAIN)    # 3 cittadinanze × 6 titoli

# formaz <- readRDS(file.path(dir_raw, "sdmx_formaz.rds"))
count(formaz, TIME_PERIOD)                            # quali anni ci sono (il json di controllo ha solo il 2024)
table(formaz$REF_AREA, formaz$VOCAT_TRAIN_ATT)        # 11 territori × 3 (sì, no, totale)
