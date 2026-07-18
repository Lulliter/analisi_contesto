# ==========================================================================
# ingestione/01a_get_istat_cens.R
# SOLO DOWNLOAD: censimento permanente popolazione per i comuni ER
# (età, sesso, cittadinanza) via API SDMX — RICETTA COLLAUDATA del vecchio repo:
# blocchi da 10 comuni + jolly "......" sulle altre dimensioni.
#
# NB ETÀ: questo flow (_TV_2) ha CLASSI DECENNALI (+ minorenni 0-17 a parte).
#         Le SINGOLE ETÀ esistono nel flow gemello "DF_DCSS_POP_DEMCITMIG_SETA_1"
#         (stessa ricetta, ~10x righe): se servono, scrivere un 01c che punta lì.
#
# NB storico (2026-07-17): il tentativo col dataflow "popolazione residente"
# 22_289_DF_DCIS_POPRES1_24 è un vicolo cieco — vedi dati/grezzi/istat_cens/_metadati.md.
#
# Output: dati/grezzi/istat_cens/istat_cens_pop_com_er_<anno>.rds (grezzo API)
# Quando: una volta l'anno → aggiornare ANNO_CENS e rilanciare
# Durata: ~33 blocchi x 20 sec ≈ 12-15 minuti (il rate limit ISTAT è severo)
# ==========================================================================

library(here)

source(here("R", "f_istat_scarica_cens.R"))   # f_scarica_istat_blocchi() (usa httr + rsdmx)

# --- Parametri ------------------------------------------------------------
ANNO_CENS  <- 2024   # anno di riferimento del censimento (verificato disponibile il 2026-07-17)
DATASET_ID <- "IT1,DF_DCSS_POP_DEMCITMIG_TV_2,1.0"

dir_out  <- here("dati", "grezzi", "istat_cens")
file_out <- file.path(dir_out, paste0("istat_cens_pop_com_er_", ANNO_CENS, ".rds"))
dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)

# Comuni ER: vettore creato da ingestione/00_prep_shp_situas.R
source(here("dati", "puliti", "istat_shp", "lista_PRO_COM_T_er_vec.R"))
# -> CODICI_COMUNI_ER (330 codici)

# --- Download (con cache: se il file c'è già, non riscaricare) --------------
if (file.exists(file_out)) {
  message("Già presente, salto il download: ", basename(file_out))
} else {

  dati_grezzi <- f_scarica_istat_blocchi(
    codici_territorio   = CODICI_COMUNI_ER,
    dataset_id          = DATASET_ID,
    anno                = ANNO_CENS,
    dimensioni_extra    = "......",   # jolly: NON elencare le età (limite URL!)
    codici_per_blocco   = 10,         # chiave corta = sotto il limite del server
    pausa_tra_richieste = 20,
    pausa_dopo_errore   = 30
  )

  # Controllo: tutti i comuni richiesti devono essere arrivati
  comuni_arrivati <- unique(dati_grezzi$REF_AREA)
  mancanti <- setdiff(CODICI_COMUNI_ER, comuni_arrivati)
  if (length(mancanti) > 0) {
    warning("Comuni mancanti (", length(mancanti), "): ",
            paste(head(mancanti, 10), collapse = ", "),
            " — rilancia lo script: i blocchi falliti verranno ritentati.")
  }

  saveRDS(dati_grezzi, file_out)
  message("Salvato: ", file_out, " (", nrow(dati_grezzi), " righe)")
}

# --- Territori di confronto: Italia, Nord-Est, ER, province ER (NUTS) --------
# Verificato il 2026-07-17: i codici NUTS esistono in questo flow (ITD52 = Parma)
AGGREGATI     <- c("IT", "ITD", "ITD5", paste0("ITD5", 1:9))
file_out_conf <- file.path(dir_out, paste0("istat_cens_pop_confronti_", ANNO_CENS, ".rds"))

if (file.exists(file_out_conf)) {
  message("Già presente, salto il download: ", basename(file_out_conf))
} else {
  grezzi_conf <- f_scarica_istat_blocchi(
    codici_territorio   = AGGREGATI,
    dataset_id          = DATASET_ID,
    anno                = ANNO_CENS,
    dimensioni_extra    = "......",
    codici_per_blocco   = 12,     # un blocco unico
    pausa_tra_richieste = 20
  )
  saveRDS(grezzi_conf, file_out_conf)
  message("Salvato: ", file_out_conf, " (", nrow(grezzi_conf), " righe)")
}
