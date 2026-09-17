# ___________________________________________________________________________
# Modulo: scuola_abband_neet
# Fonte:  MIM open data (via ingestione/02 → dati/puliti/mim_iscritti/): iscritti
#         per anno di corso e fascia d'età → RITARDO SCOLASTICO (proxy del rischio
#         dispersione); ISTAT Bes dei territori (via ingestione/04 →
#         dati/puliti/istat_bes/): NEET, competenze non adeguate, ecc.
# Input:  dati/puliti/mim_iscritti/scuole_iscritti_er.rds
#         dati/puliti/mim_iscritti/scuole_anagrafe_er.rds (caratteristica: esclusione serali ecc.)
#         dati/puliti/istat_bes/bes_territori.rds
#         dati/puliti/istat_bes/bes_regioni.rds (Bes nazionale, via ingestione/05)
# Output: moduli/scuola_abband_neet/output/<oggetto>.rds + .csv (nome file = oggetto):
#         ritardo_trend_prov_er   (anno × provincia ER × ordine: alunni, in ritardo, quota;
#                                  + righe EMILIA-ROMAGNA)
#         ritardo_corso_prov_er   (ultimo a.s.: provincia ER × ordine × anno di corso — l'accumulo
#                                  del ritardo lungo il percorso)
#         ritardo_comuni_pr       (anno × comune PR × ordine, con pro_com_t per le mappe)
#         bes_istruzione_prov_er  (indicatori BES dominio Istruzione: province ER,
#                                  ER, Nord-est, Italia; per sesso e anno)
#         bes_istruzione_reg      (indicatori BES nazionale dominio Istruzione: ER, Nord-est,
#                                  Italia per sesso e anno; qui c'è l'uscita precoce 18-24,
#                                  che NON esiste a livello provinciale)
# NB: ritardo = età superiore a quella regolare per l'anno di corso (età al 31/12:
#     verificato sui dati nazionali, 92% dei bambini di 1ª primaria ha "6 anni").
#     Include ripetenze e inserimenti in classi inferiori (es. alunni arrivati
#     dall'estero); NON conta chi ha già lasciato la scuola. Statali + paritarie, no infanzia.
#     ESCLUSI i corsi serali (percorsi di II livello), CPIA, sedi carcerarie e ospedaliere:
#     sono adulti/rientri in formazione, tutti "in ritardo" per costruzione
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(stringr)
library(readr)
library(purrr)
library(janitor)

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "scuola_abband_neet", "output")
if (!dir.exists(dir_mod)) dir.create(dir_mod, recursive = TRUE)

# Età regolare = base dell'ordine + anno di corso, con l'età misurata dal MIM
# al 31 DICEMBRE dell'a.s. (non a settembre): entra in 1ª primaria chi compie
# 6 anni entro il 31/12, quindi a fine anno TUTTI i regolari di 1ª hanno 6 anni,
# nati prima o dopo settembre non fa differenza (a settembre sarebbero 5 o 6).
# Verifica sui dati nazionali 2024/25: 92% dei bambini di 1ª a "6 anni", 6% a
# "< di 6" (= anticipatari, non in ritardo), 2% sopra. Da cui: 1ª primaria = 6
# (5+1), 5ª = 10; 1ª media = 11 (10+1); 1ª superiore = 14 (13+1), 5ª = 18.
# In ritardo = età > regolare (ripetenti o inseriti in classe più bassa).
ETA_BASE <- c("SCUOLA PRIMARIA" = 5, "SCUOLA SECONDARIA I GRADO" = 10, "SCUOLA SECONDARIA II GRADO" = 13)
TERRITORI_BES <- c("Emilia-Romagna", "Nord-est", "Italia") # oltre alle province ER
ANNO_ULTIMO <- 2024 # a.s. 2024/25, per la tabella per anno di corso
# caratteristiche di scuola (anagrafe MIM, solo statali) escluse dal ritardo
CARATT_ESCLUSE <- c("PERCORSO II LIVELLO", "CPIA", "SPEC. PER CARCERARI", "C/O IST. OSPEDALIERO")

# 1. Carica input (già puliti dall'ingestione) -----------------------------
scuole_iscritti_er <- readRDS(here("dati", "puliti", "mim_iscritti", "scuole_iscritti_er.rds"))
scuole_anagrafe_er <- readRDS(here("dati", "puliti", "mim_iscritti", "scuole_anagrafe_er.rds"))
bes_territori <- readRDS(here("dati", "puliti", "istat_bes", "bes_territori.rds"))
bes_regioni <- readRDS(here("dati", "puliti", "istat_bes", "bes_regioni.rds"))

# 2. Ritardo scolastico ---------------------------------------------------
# fascia_eta è testo: "12 anni", "< di 11 anni", "> di 13 anni" → età numerica
# ("< di 11" → 10, "> di 13" → 14: basta per il confronto con l'età regolare)
f_eta_num <- function(fascia) {
  n <- as.integer(str_extract(fascia, "\\d+"))
  case_when(
    str_starts(fascia, "<") ~ n - 1L,
    str_starts(fascia, ">") ~ n + 1L,
    .default = n
  )
}

iscritti_ritardo <- scuole_iscritti_er |>
  # esclusione serali ecc. (paritarie: caratteristica NA → restano dentro)
  left_join(scuole_anagrafe_er |> select(codice_scuola, caratteristica), by = "codice_scuola") |>
  filter(!caratteristica %in% CARATT_ESCLUSE) |>
  mutate(
    eta = f_eta_num(fascia_eta),               # NA se "Non Classificabile" (16 alunni in Italia in 10 a.s.)
    eta_regolare = ETA_BASE[ordine_scuola] + anno_corso,
    in_ritardo = !is.na(eta) & eta > eta_regolare
  )

# controllo: età non classificabile = casi sporadici; l'ordine deve essere sempre noto
stopifnot(sum(iscritti_ritardo$alunni[is.na(iscritti_ritardo$eta)]) < 50,
          !anyNA(iscritti_ritardo$eta_regolare))

## __ Trend per provincia ER e ordine (+ totale regionale) -----
ritardo_trend_prov_er <- iscritti_ritardo |>
  summarise(alunni_ritardo = sum(alunni[in_ritardo]), # PRIMA di alunni: in summarise le
            alunni = sum(alunni),                     # espressioni si valutano in sequenza
            .by = c(anno_inizio, provincia, ordine_scuola))

ritardo_trend_prov_er <- bind_rows(
  ritardo_trend_prov_er,
  ritardo_trend_prov_er |>
    summarise(alunni = sum(alunni), alunni_ritardo = sum(alunni_ritardo),
              .by = c(anno_inizio, ordine_scuola)) |>
    mutate(provincia = "EMILIA-ROMAGNA")
) |>
  mutate(quota_ritardo = alunni_ritardo / alunni)
ritardo_trend_prov_er

## __ Per anno di corso, ultimo a.s.: l'accumulo del ritardo lungo il percorso -----
ritardo_corso_prov_er <- iscritti_ritardo |>
  filter(anno_inizio == ANNO_ULTIMO) |>
  summarise(alunni_ritardo = sum(alunni[in_ritardo]), # prima di alunni (vedi sopra)
            alunni = sum(alunni),
            .by = c(anno_inizio, provincia, ordine_scuola, anno_corso))

ritardo_corso_prov_er <- bind_rows(
  ritardo_corso_prov_er,
  ritardo_corso_prov_er |>
    summarise(alunni = sum(alunni), alunni_ritardo = sum(alunni_ritardo),
              .by = c(anno_inizio, ordine_scuola, anno_corso)) |>
    mutate(provincia = "EMILIA-ROMAGNA")
) |>
  mutate(quota_ritardo = alunni_ritardo / alunni)
ritardo_corso_prov_er

## __ Comuni PR per anno e ordine (pro_com_t per le mappe) -----
# NB: il comune è quello della SCUOLA, non della residenza dell'alunno
ritardo_comuni_pr <- iscritti_ritardo |>
  filter(provincia == "PARMA") |>
  summarise(alunni_ritardo = sum(alunni[in_ritardo]), # idem: prima di alunni
            alunni = sum(alunni),
            .by = c(anno_inizio, comune, pro_com_t, ordine_scuola)) |>
  mutate(quota_ritardo = alunni_ritardo / alunni)
ritardo_comuni_pr

# 3. BES: dominio Istruzione, province ER + territori di confronto ----------
bes_istruzione_prov_er <- bes_territori |>
  filter(str_starts(dominio, "Istruzione"),
         str_starts(cod_territorio, "02-09-") | territorio %in% TERRITORI_BES) |>
  select(cod_indicatore, indicatore, sesso, territorio, livello, anno, valore, unita_misura, fonte)
bes_istruzione_prov_er

# 3b. BES nazionale: dominio Istruzione, ER + territori di confronto ----------
# (cornice regionale: uscita precoce 18-24, formazione continua ecc., fino al 2025)
bes_istruzione_reg <- bes_regioni |>
  filter(str_starts(dominio, "Istruzione"), territorio %in% TERRITORI_BES) |>
  select(cod_indicatore, indicatore, sesso, territorio, livello, anno, valore, poco_signif, unita_misura, fonte)
bes_istruzione_reg

# 4. Salva nel proprio output/ (rds + csv, nome file = oggetto) ------------
lista_out <- list(
  ritardo_trend_prov_er = ritardo_trend_prov_er,
  ritardo_corso_prov_er = ritardo_corso_prov_er,
  ritardo_comuni_pr = ritardo_comuni_pr,
  bes_istruzione_prov_er = bes_istruzione_prov_er,
  bes_istruzione_reg = bes_istruzione_reg
)

iwalk(lista_out, function(df, nome) {
  saveRDS(df, file.path(dir_mod, paste0(nome, ".rds")))
  write_csv(df, file.path(dir_mod, paste0(nome, ".csv")))
  message("Salvato: ", nome, " (", nrow(df), " righe)")
})

# Verifiche rapide (da eseguire a mano) ------------------------------------
iscritti_ritardo |> count(ordine_scuola, anno_corso, fascia_eta, in_ritardo) |> filter(anno_corso == 1) # sanity check della regola
iscritti_ritardo |> count(caratteristica, wt = alunni) # devono restare solo NORMALE, convitti, DI MONTAGNA, NA (paritarie)
# double check (Se vuoi essere sicura che gli NA siano tutti paritarie e non statali con anagrafe mancante, un controllo rapido in console:)
iscritti_ritardo |> count(gestione, is.na(caratteristica), wt = alunni)
ritardo_trend_prov_er |> filter(provincia %in% c("PARMA", "EMILIA-ROMAGNA"), anno_inizio == 2024) # attesi: primaria ~2-3%, sec I ~7-9%, sec II ~18-20% (era 21,3% coi serali)
ritardo_corso_prov_er |> filter(provincia == "PARMA") |> select(ordine_scuola, anno_corso, quota_ritardo) # crescente lungo il percorso
ritardo_comuni_pr |> filter(anno_inizio == 2024, ordine_scuola == "SCUOLA SECONDARIA II GRADO") |> arrange(desc(quota_ritardo))
bes_istruzione_prov_er |> distinct(cod_indicatore, indicatore)
bes_istruzione_reg |> filter(cod_indicatore == "02IST005-N22", sesso == "Totale", anno == 2025) # uscita precoce: ER 6,0; Nord-est 6,8; Italia 8,2

