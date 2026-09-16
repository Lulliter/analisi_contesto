# ==========================================================================
# ingestione/06a_get_istat_avq_ict.R
# SOLO DOWNLOAD: uso di internet e del pc per età e sesso (Italia, 2001→) e
# per regione (totale 6+), dall'indagine Aspetti della vita quotidiana,
# via API SDMX di IstatData (categoria "Internet e pc - tipo di utilizzatori").
# Tre richieste, serie complete (tutti gli anni), nessun blocco per territorio.
#
# Output: dati/grezzi/istat_cittadini_ict/sdmx_<nome>.rds (grezzo API, con etichette)
# Quando: una volta l'anno (nuova edizione Cittadini e ICT, aprile) → cancellare i
#         tre rds e rilanciare
# Durata: 3 richieste x ~10 sec + pause (rate limit ISTAT ~5 query/min)
# NB 2026-09-15: scritto ma NON ANCORA LANCIATO. Da verificare al primo lancio:
#     la chiave con "1+2+9" e le età lasciate vuote; i codici territorio ITD5 (ER)
#     e ITD (Nord-est), letti dalla lista del dataflow 239.
# ==========================================================================

# Setup -------------------------------------------------------------------
library(here)
library(httr)
library(rsdmx)

# Parametri ---------------------------------------------------------------
dir_out <- here("dati", "grezzi", "istat_cittadini_ict")

# dataflow (id IstatData) e chiave SDMX: FREQ.REF_AREA.DATA_TYPE.MEASURE.SEX.AGE.EDU.LAB
# MEASURE = HSC (per 100 persone con le stesse caratteristiche); SEX 1/2/9; "" = tutti
# tipi di dato attesi: 6_INTSI (ha usato internet), 6_INTTUTTI (tutti i giorni),
# 6_INT_1P_SETT, 6_INT_QV_MESE, 6_INT_QV_ANNO, 6_INTNO (mai); per il pc: 3_PC* analoghi
FLUSSI <- list(
  internet_eta = list(id = "IT1,83_63_DF_DCCV_AVQ_PERSONE_237,1.0", chiave = "A.IT..HSC.1+2+9..99.99"),
  pc_eta       = list(id = "IT1,83_63_DF_DCCV_AVQ_PERSONE_241,1.0", chiave = "A.IT..HSC.1+2+9..99.99"),
  internet_reg = list(id = "IT1,83_63_DF_DCCV_AVQ_PERSONE_239,1.0", chiave = "A.IT+ITD+ITD5..HSC.9.Y_GE6.99.99")
)
PAUSA_SEC <- 15

# Una richiesta SDMX: serie complete, etichette incluse ---------------------
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
  file_out <- file.path(dir_out, paste0("sdmx_", nome, ".rds"))
  if (file.exists(file_out)) {
    message("Già presente, salto: ", basename(file_out))
    next
  }
  dati <- f_get_avq(FLUSSI[[nome]]$id, FLUSSI[[nome]]$chiave)
  saveRDS(dati, file_out)
  message("Salvato: ", basename(file_out), " (", nrow(dati), " righe)")
  Sys.sleep(PAUSA_SEC)
}

# Verifiche rapide (da eseguire a mano) ------------------------------------
# internet_eta <- readRDS(file.path(dir_out, "sdmx_internet_eta.rds"))
# table(internet_eta$DATA_TYPE, internet_eta$AGE)   # 6 tipi di dato × 13 classi d'età
# range(internet_eta$obsTime)                       # atteso 2001 → 2025
# internet_eta |> dplyr::filter(DATA_TYPE == "6_INTTUTTI", SEX == 9, AGE == "Y15-17", obsTime %in% c("2010", "2025")) # attesi 52,9 e 94,0
