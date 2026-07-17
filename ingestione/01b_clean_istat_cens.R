# ==========================================================================
# ingestione/01b_clean_istat_cens.R
# PULIZIA: censimento `permanente` (grezzo API) → oggetto pulito in dati/puliti/
#
# Input:  dati/grezzi/istat_cens/istat_cens_pop_com_er_<anno>.rds  (da 01a)
# Output: dati/puliti/istat_cens/pop_com_er_<anno>.rds
#         (popolazione per comune × sesso × classe d'età decennale × cittadinanza)
#         dati/puliti/istat_cens/pop_com_er_minorenni_<anno>.rds
#         (popolazione MINORENNE per comune × sesso × cittadinanza — non
#          ricavabile dalle classi decennali!)
#
# NB ETÀ: CLASSI DECENNALI (è il massimo dettaglio del flow _TV_2);
#         per le SINGOLE ETÀ vedi nota in 01a (flow gemello SETA_1).
#
# Nota: il censimento viene aggiornato ogni anno, ma c'è un lag di tipo 1 anno e mezzo
# ==========================================================================

library(here)
library(dplyr, warn.conflicts = FALSE)
library(stringr)

# --- Parametri ------------------------------------------------------------
ANNO_CENS <- 2024
file_in  <- here("dati", "grezzi", "istat_cens",
                 paste0("istat_cens_pop_com_er_", ANNO_CENS, ".rds"))
dir_out  <- here("dati", "puliti", "istat_cens")
file_out <- file.path(dir_out, paste0("pop_com_er_", ANNO_CENS, ".rds"))
file_out_min <- file.path(dir_out, paste0("pop_com_er_minorenni_", ANNO_CENS, ".rds"))
dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)

dati_grezzi <- readRDS(file_in)

# --- Controlli sulle colonne "costanti" (se cambiano, meglio saperlo subito)
# INDICATOR contiene DUE indicatori, entrambi utili:
#   RESPOP_AV     = popolazione residente (per classi d'età decennali)
#   RESPOP_MIN_AV = popolazione residente MINORENNE (0-17, solo totale età)
stopifnot(
  all(dati_grezzi$FREQ == "A"),
  all(dati_grezzi$INDICATOR %in% c("RESPOP_AV", "RESPOP_MIN_AV")),
  all(dati_grezzi$MARITAL_STATUS == "ALL"),
  all(dati_grezzi$AREA_CONTRY_CITIZEN == "ALL"),
  all(dati_grezzi$USUAL_RESID_1Y == "ALL"),
  all(dati_grezzi$TIME_PERIOD == as.character(ANNO_CENS))
)

# --- Pulizia ----------------------------------------------------------------
# Ordine naturale delle classi d'età (per grafici e tabelle)
livelli_eta <- c(paste0("Y", seq(0, 90, 10), "-", seq(9, 99, 10)),  # Y0-9 ... Y90-99
                 "Y_GE100", "TOTAL")

pop_com_er <- dati_grezzi |>
  filter(INDICATOR == "RESPOP_AV") |>
  select(
    PRO_COM_T    = REF_AREA,      # codice comune alfanumerico (chiave verso gli shp)
    sesso        = GENDER,
    classe_eta   = AGE_CLASS,
    cittadinanza = CITIZENSHIP,   # ITL / FRGAPO (stranieri+apolidi) / TOTAL
    anno         = TIME_PERIOD,
    popolazione  = OBS_VALUE
  ) |>
  mutate(
    popolazione = as.integer(popolazione),
    anno        = as.integer(anno),
    classe_eta  = factor(classe_eta, levels = livelli_eta),
    # etichetta leggibile: "0-9", "10-19", ..., "100+", "Totale"
    classe_eta_lbl = case_when(
      classe_eta == "TOTAL"   ~ "Totale",
      classe_eta == "Y_GE100" ~ "100+",
      .default = str_remove(classe_eta, "^Y")
    )
  )

# --- Controlli di qualità ----------------------------------------------------
# 0) nessuna classe d'età inattesa (il factor() darebbe NA silenziosi)
stopifnot(!anyNA(pop_com_er$classe_eta))

# 1) tutti e soli i 330 comuni ER
source(here("dati", "puliti", "istat_shp", "lista_PRO_COM_T_er_vec.R"))
stopifnot(setequal(unique(pop_com_er$PRO_COM_T), CODICI_COMUNI_ER))

# 2) coerenza interna: somma delle classi d'età = TOTAL
#    (per ogni comune × sesso × cittadinanza)
chk_eta <- pop_com_er |>
  summarise(
    somma_classi = sum(popolazione[classe_eta != "TOTAL"]),
    totale       = sum(popolazione[classe_eta == "TOTAL"]),
    .by = c(PRO_COM_T, sesso, cittadinanza)
  ) |>
  filter(somma_classi != totale)
stopifnot(nrow(chk_eta) == 0)

# 3) coerenza cittadinanza: ITL + FRGAPO = TOTAL (sul totale età)
chk_cit <- pop_com_er |>
  filter(classe_eta == "TOTAL") |>
  summarise(
    somma_parti = sum(popolazione[cittadinanza != "TOTAL"]),
    totale      = sum(popolazione[cittadinanza == "TOTAL"]),
    .by = c(PRO_COM_T, sesso)
  ) |>
  filter(somma_parti != totale)
stopifnot(nrow(chk_cit) == 0)

# --- Minorenni (oggetto separato) ---------------------------------------------
pop_com_er_min <- dati_grezzi |>
  filter(INDICATOR == "RESPOP_MIN_AV") |>
  select(
    PRO_COM_T    = REF_AREA,
    sesso        = GENDER,
    classe_eta   = AGE_CLASS,     # atteso: solo totale (verificato sotto)
    cittadinanza = CITIZENSHIP,
    anno         = TIME_PERIOD,
    minorenni    = OBS_VALUE
  ) |>
  mutate(minorenni = as.integer(minorenni), anno = as.integer(anno))

# i minorenni arrivano senza dettaglio per classi d'età
stopifnot(n_distinct(pop_com_er_min$classe_eta) == 1)
pop_com_er_min <- select(pop_com_er_min, -classe_eta)

stopifnot(setequal(unique(pop_com_er_min$PRO_COM_T), CODICI_COMUNI_ER))

# --- Salva -------------------------------------------------------------------
saveRDS(pop_com_er, file_out)
message("Salvato: ", file_out, " (", nrow(pop_com_er), " righe, ",
        n_distinct(pop_com_er$PRO_COM_T), " comuni)")

saveRDS(pop_com_er_min, file_out_min)
message("Salvato: ", file_out_min, " (", nrow(pop_com_er_min), " righe)")

# --- Territori di confronto (IT, Nord-Est, ER, province ER) -------------------
file_in_conf <- here("dati", "grezzi", "istat_cens",
                     paste0("istat_cens_pop_confronti_", ANNO_CENS, ".rds"))

if (!file.exists(file_in_conf)) {
  message("File confronti non trovato: esegui prima il blocco confronti di 01a.")
} else {
  pop_confronti <- readRDS(file_in_conf) |>
    filter(INDICATOR == "RESPOP_AV") |>
    select(
      territorio   = REF_AREA,      # IT / ITD / ITD5 / ITD51-59 (ITD52 = Parma)
      sesso        = GENDER,
      classe_eta   = AGE_CLASS,
      cittadinanza = CITIZENSHIP,
      anno         = TIME_PERIOD,
      popolazione  = OBS_VALUE
    ) |>
    mutate(
      popolazione = as.integer(popolazione),
      anno        = as.integer(anno),
      classe_eta  = factor(classe_eta, levels = livelli_eta)
    )

  stopifnot(!anyNA(pop_confronti$classe_eta))

  file_out_conf <- file.path(dir_out, paste0("pop_confronti_", ANNO_CENS, ".rds"))
  saveRDS(pop_confronti, file_out_conf)
  message("Salvato: ", file_out_conf, " (", nrow(pop_confronti), " righe, ",
          n_distinct(pop_confronti$territorio), " territori)")
}

# Ispezioni utili (da eseguire a mano se vuoi):
# count(pop_com_er, sesso)          # codici sesso presenti (F/M/totale?)
# count(pop_com_er, cittadinanza)
# count(pop_com_er, classe_eta, classe_eta_lbl)
