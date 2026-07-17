# ==========================================================================
# ingestione/01d_clean_istat_cens_seta.R
# PULIZIA: censimento per SINGOLE ETÀ (grezzo da 01c) → dati/puliti/
#
# Input:  dati/grezzi/istat_cens/istat_cens_pop_com_er_seta_<anno>.rds
# Output: dati/puliti/istat_cens/pop_com_er_eta_<anno>.rds
#         popolazione per comune × sesso × ETÀ SINGOLA (0-100) × cittadinanza,
#         con `eta` INTERA: qualsiasi classe si costruisce con un cut()/filter,
#         es. anziani: filter(eta >= 65); grandi anziani: eta >= 80.
#         (100 = "100 anni e più")
#
# NB: scritto PRIMA di aver visto il grezzo SETA — la struttura è assunta
#     identica al flow gemello di 01b (stessa famiglia DSD). Se al primo run
#     uno stopifnot esplode, guardare dplyr::glimpse(dati_grezzi_seta) e
#     adeguare i nomi qui sotto.
# ==========================================================================

library(here)
library(dplyr, warn.conflicts = FALSE)
library(stringr)

# --- Parametri ------------------------------------------------------------
ANNO_CENS <- 2024
file_in  <- here("dati", "grezzi", "istat_cens",
                 paste0("istat_cens_pop_com_er_seta_", ANNO_CENS, ".rds"))
dir_out  <- here("dati", "puliti", "istat_cens")
file_out <- file.path(dir_out, paste0("pop_com_er_eta_", ANNO_CENS, ".rds"))
dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)

dati_grezzi_seta <- readRDS(file_in)

# --- Verifica struttura attesa ---------------------------------------------
colonne_attese <- c("FREQ", "REF_AREA", "GENDER", "CITIZENSHIP",
                    "TIME_PERIOD", "OBS_VALUE")
stopifnot(all(colonne_attese %in% names(dati_grezzi_seta)))

# la colonna età nel flow SETA si chiama AGE_NOCLASS (verificato 2026-07-17)
col_eta <- intersect(c("AGE_NOCLASS", "AGE_CLASS", "AGE"), names(dati_grezzi_seta))[1]
stopifnot(!is.na(col_eta))
message("Colonna età: ", col_eta)

# colonne "costanti" attese (se esistono devono avere un solo valore)
for (cc in c("MARITAL_STATUS", "AREA_CONTRY_CITIZEN", "USUAL_RESID_1Y")) {
  if (cc %in% names(dati_grezzi_seta)) {
    stopifnot(n_distinct(dati_grezzi_seta[[cc]]) == 1)
  }
}

if ("INDICATOR" %in% names(dati_grezzi_seta)) {
  message("Indicatori presenti: ",
          paste(unique(dati_grezzi_seta$INDICATOR), collapse = ", "))
}
stopifnot(all(dati_grezzi_seta$TIME_PERIOD == as.character(ANNO_CENS)))

# --- Pulizia ----------------------------------------------------------------
pop_com_er_eta <- dati_grezzi_seta |>
  select(
    PRO_COM_T    = REF_AREA,
    sesso        = GENDER,
    eta_cod      = all_of(col_eta),   # "Y0" ... "Y99", "Y_GE100", "TOTAL"
    cittadinanza = CITIZENSHIP,
    anno         = TIME_PERIOD,
    popolazione  = OBS_VALUE
  ) |>
  mutate(
    popolazione = as.integer(popolazione),
    anno        = as.integer(anno),
    # età come numero: "Y7" -> 7, "Y_GE100" -> 100, "TOTAL" -> NA (riga di totale)
    # NB: il warning "NAs introduced by coercion" è BENIGNO: case_when valuta
    #     as.integer() anche sulle righe TOTAL, che poi scarta (gestite sotto)
    eta = case_when(
      eta_cod == "Y_GE100" ~ 100L,
      # str_extract restituisce NA sui non-match ("TOTAL"): niente warning di coercizione
      .default = as.integer(str_extract(eta_cod, "(?<=^Y)\\d+$"))
    )
  )

# codici età non riconosciuti? (né Y<num>, né Y_GE100, né TOTAL)
non_riconosciuti <- pop_com_er_eta |>
  filter(is.na(eta), eta_cod != "TOTAL") |>
  distinct(eta_cod)
stopifnot(nrow(non_riconosciuti) == 0)

# --- Controlli di qualità ----------------------------------------------------
# 1) tutti e soli i 330 comuni ER
source(here("dati", "puliti", "istat_shp", "lista_PRO_COM_T_er_vec.R"))
stopifnot(setequal(unique(pop_com_er_eta$PRO_COM_T), CODICI_COMUNI_ER))

# 2) coerenza: somma delle età singole = riga TOTAL
#    (per ogni comune × sesso × cittadinanza; se TOTAL non esiste, salta)
if (any(pop_com_er_eta$eta_cod == "TOTAL")) {
  chk_eta <- pop_com_er_eta |>
    summarise(
      somma_eta = sum(popolazione[eta_cod != "TOTAL"]),
      totale    = sum(popolazione[eta_cod == "TOTAL"]),
      .by = c(PRO_COM_T, sesso, cittadinanza)
    ) |>
    filter(somma_eta != totale)
  stopifnot(nrow(chk_eta) == 0)
}

# 3) controllo incrociato con 01b (se l'oggetto decennale esiste):
#    stesso totale complessivo di popolazione
file_01b <- file.path(dir_out, paste0("pop_com_er_", ANNO_CENS, ".rds"))
if (file.exists(file_01b)) {
  tot_decennali <- readRDS(file_01b) |>
    filter(classe_eta == "TOTAL") |>
    summarise(tot = sum(popolazione), .by = c(sesso, cittadinanza))
  tot_seta <- pop_com_er_eta |>
    filter(eta_cod == "TOTAL") |>
    summarise(tot = sum(popolazione), .by = c(sesso, cittadinanza))
  chk_incrocio <- anti_join(tot_decennali, tot_seta,
                            by = c("sesso", "cittadinanza", "tot"))
  stopifnot(nrow(chk_incrocio) == 0)
  message("Controllo incrociato con l'oggetto decennale (01b): OK")
}

# --- Salva (solo le età singole: le righe TOTAL sono ridondanti) --------------
pop_com_er_eta <- pop_com_er_eta |>
  filter(eta_cod != "TOTAL") |>
  select(-eta_cod) |>
  relocate(eta, .after = sesso)

saveRDS(pop_com_er_eta, file_out)
message("Salvato: ", file_out, " (", nrow(pop_com_er_eta), " righe, ",
        n_distinct(pop_com_er_eta$PRO_COM_T), " comuni, età 0-100)")

# --- Territori di confronto per singole età (IT, Nord-Est, ER, province ER) ---
file_in_conf <- here("dati", "grezzi", "istat_cens",
                     paste0("istat_cens_pop_confronti_seta_", ANNO_CENS, ".rds"))

if (!file.exists(file_in_conf)) {
  message("File confronti seta non trovato: esegui prima il blocco confronti di 01c.")
} else {
  pop_confronti_eta <- readRDS(file_in_conf) |>
    select(
      territorio   = REF_AREA,      # IT / ITD / ITD5 / ITD51-59 (ITD52 = Parma)
      sesso        = GENDER,
      eta_cod      = AGE_NOCLASS,
      cittadinanza = CITIZENSHIP,
      anno         = TIME_PERIOD,
      popolazione  = OBS_VALUE
    ) |>
    mutate(
      popolazione = as.integer(popolazione),
      anno        = as.integer(anno),
      # (stesso warning benigno di sopra sulle righe TOTAL)
      eta = case_when(
        eta_cod == "Y_GE100"           ~ 100L,
        str_detect(eta_cod, "^Y\\d+$") ~ as.integer(str_remove(eta_cod, "^Y")),
        .default = NA_integer_
      )
    ) |>
    filter(eta_cod != "TOTAL") |>
    select(-eta_cod) |>
    relocate(eta, .after = sesso)

  stopifnot(!anyNA(pop_confronti_eta$eta))

  file_out_conf <- file.path(dir_out, paste0("pop_confronti_eta_", ANNO_CENS, ".rds"))
  saveRDS(pop_confronti_eta, file_out_conf)
  message("Salvato: ", file_out_conf, " (", nrow(pop_confronti_eta), " righe, ",
          n_distinct(pop_confronti_eta$territorio), " territori)")
}

# Ispezioni utili (a mano):
# count(pop_com_er_eta, sesso)
# count(pop_com_er_eta, cittadinanza)
# summary(pop_com_er_eta$eta)
# Esempio d'uso nei moduli — quota 65+ per comune:
pop_com_er_eta |>
  filter(cittadinanza == "TOTAL") |>
  summarise(pop_tot = sum(popolazione),
            pop_65p = sum(popolazione[eta >= 65]), .by = PRO_COM_T) |>
  mutate(quota_65p = pop_65p / pop_tot)
