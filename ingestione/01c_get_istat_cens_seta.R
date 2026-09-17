# ___________________________________________________________________________
# ingestione/01c_get_istat_cens_seta.R
# SOLO DOWNLOAD: censimento permanente, popolazione per SINGOLE ETÀ
# (0, 1, ..., 99, 100+) × sesso × cittadinanza, comuni ER.
#
# Flow gemello di 01a: "DF_DCSS_POP_DEMCITMIG_SETA_1" (SETA = singole età).
# Stessa ricetta collaudata: blocchi da 10 comuni + jolly "......".
# Serve perché le classi DECENNALI di 01a non permettono tagli tipo 65+.
#
# Output: dati/grezzi/istat_cens/istat_cens_pop_com_er_seta_<anno>.rds
# Quando: una volta l'anno → aggiornare ANNO_CENS e rilanciare
# Durata: ~33 blocchi x 20 sec + richieste più pesanti (~10x righe di 01a)
#         → mettere in conto 15-25 minuti
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)

source(here("R", "f_istat_scarica_cens.R"))   # f_scarica_istat_blocchi()

# --- Parametri ------------------------------------------------------------
ANNO_CENS  <- 2024
DATASET_ID <- "IT1,DF_DCSS_POP_DEMCITMIG_SETA_1,1.0"

dir_raw  <- here("dati", "grezzi", "istat_cens")
file_raw <- file.path(dir_raw, paste0("istat_cens_pop_com_er_seta_", ANNO_CENS, ".rds"))
dir.create(dir_raw, recursive = TRUE, showWarnings = FALSE)

# Comuni ER: vettore creato da ingestione/00_prep_shp_situas.R
source(here("dati", "puliti", "istat_shp", "lista_PRO_COM_T_er_vec.R"))
# -> CODICI_COMUNI_ER (330 codici)

# --- Download (con cache: se il file c'è già, non riscaricare) --------------
if (file.exists(file_raw)) {
  message("Già presente, salto il download: ", basename(file_raw))
} else {

  dati_grezzi_seta <- f_scarica_istat_blocchi(
    codici_territorio   = CODICI_COMUNI_ER,
    dataset_id          = DATASET_ID,
    anno                = ANNO_CENS,
    dimensioni_extra    = "......",   # jolly: mai elencare le 102 età (limite URL!)
    codici_per_blocco   = 10,
    pausa_tra_richieste = 20,
    pausa_dopo_errore   = 30,
    timeout_sec         = 240         # risposte ~10x più pesanti di 01a
  )

  # Controllo: tutti i comuni richiesti devono essere arrivati
  comuni_arrivati <- unique(dati_grezzi_seta$REF_AREA)
  mancanti <- setdiff(CODICI_COMUNI_ER, comuni_arrivati)
  if (length(mancanti) > 0) {
    warning("Comuni mancanti (", length(mancanti), "): ",
            paste(head(mancanti, 10), collapse = ", "),
            " — rilancia lo script per ritentare.")
  }

  saveRDS(dati_grezzi_seta, file_raw)
  message("Salvato: ", file_raw, " (", nrow(dati_grezzi_seta), " righe)")
}

# --- Territori di confronto (singole età): IT, Nord-Est, ER, province ER -----
AGGREGATI     <- c("IT", "ITD", "ITD5", paste0("ITD5", 1:9))
file_raw_conf <- file.path(dir_raw, paste0("istat_cens_pop_confronti_seta_", ANNO_CENS, ".rds"))

if (file.exists(file_raw_conf)) {
  message("Già presente, salto il download: ", basename(file_raw_conf))
} else {
  grezzi_conf_seta <- f_scarica_istat_blocchi(
    codici_territorio   = AGGREGATI,
    dataset_id          = DATASET_ID,
    anno                = ANNO_CENS,
    dimensioni_extra    = "......",
    codici_per_blocco   = 12,     # un blocco unico
    pausa_tra_richieste = 20,
    timeout_sec         = 240
  )
  saveRDS(grezzi_conf_seta, file_raw_conf)
  message("Salvato: ", file_raw_conf, " (", nrow(grezzi_conf_seta), " righe)")
}
