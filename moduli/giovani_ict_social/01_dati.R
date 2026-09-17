# ___________________________________________________________________________
# Modulo: giovani_ict_social
# Fonti:  1) ISTAT - Indagine "Bambini e ragazzi: comportamenti, atteggiamenti e progetti futuri", 2023
#         2) ISTAT - Aspetti della vita quotidiana, uso di internet e del pc 2001→ (già pulita da ingestione/06b)
#         3) Eurostat - isoc_ai_iaiu, uso di strumenti di IA generativa, 2025 (grezzo da ingestione/07)
# Input:  dati/grezzi/istat_bambini_ragazzi/TAVOLE/Tavole A/Tav.8_a, 9_a, 10_a, 11_a (.xlsx)
#         dati/puliti/istat_ict/ict_uso_eta.rds, ict_uso_reg.rds
#         dati/grezzi/eurostat_isoc_ai/isoc_ai_iaiu.rds
# Output: moduli/giovani_ict_social/output/ragazzi_ict_social.rds (+ .csv)
#           formato lungo: 1 riga = indicatore × sesso × categoria (età, ripartizione, totale) × risposta
#         moduli/giovani_ict_social/output/ict_giovani_eta.rds, ict_reg.rds (+ .csv)
#           ritaglio delle serie internet/pc: classi giovani + totale (+ classe 15-19 = nostra stima,
#           colonna stima_nostra); cornice territoriale
#         moduli/giovani_ict_social/output/ia_eta_it_ue.rds (+ .csv)
#           uso dell'IA e scopi d'uso per classe d'età, Italia e UE
# NB: la fonte 1 è MONO-modulo → lettura qui, non in ingestione/. Ragazzi di 11-19 anni, un solo anno.
#     Le tavole 10 e 11 hanno come base i ragazzi che USANO INTERNET, non tutti gli 11-19enni
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(readxl)
library(stringr)

# Parametri ---------------------------------------------------------------
ANNO    <- 2023
dir_in  <- here("dati", "grezzi", "istat_bambini_ragazzi", "TAVOLE", "Tavole A")
dir_out <- here("moduli", "giovani_ict_social", "output")
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)

# 1 riga = 1 tavola da leggere
TAVOLE <- tribble(
  ~tavola, ~indicatore,              ~domanda,
  "8_a",   "amici_di_persona",       "Frequenza con cui vedono gli amici nel tempo libero",
  "9_a",   "amici_online",           "Frequenza di relazioni online o telefoniche con gli amici",
  "10_a",  "profilo_social",         "Disponibilità di un profilo sui social network (tra chi usa internet)",
  "11_a",  "nuove_amicizie_online",  "Uso di internet per fare nuove amicizie (tra chi usa internet)"
)
SESSI        <- c("MASCHI" = "Maschi", "FEMMINE" = "Femmine", "MASCHI E FEMMINE" = "Totale")
RIPARTIZIONI <- c("Nord-ovest", "Nord-est", "Centro", "Sud", "Isole")

# Funzione locale: una tavola xlsx → formato lungo (solo valori percentuali) ---
# Forma delle tavole (uguale per tutte, v. _metadati.md): riga 3 = le risposte, scritte due volte
# (valori assoluti, poi una colonna vuota, poi valori percentuali); tre blocchi in verticale
# aperti da una riga con MASCHI / FEMMINE / MASCHI E FEMMINE nella seconda colonna
f_leggi_tavola <- function(file) {
  grezzo <- read_excel(file, col_names = FALSE, col_types = "text")
  risposte <- grezzo[3, ] |> unlist() |> na.omit() |> unique()   # es. "Sì, su un social network", ..., "Totale"
  n <- length(risposte)
  col_pct <- (n + 3):(2 * n + 2)                                 # posizione delle colonne dei valori percentuali

  tab <- grezzo |>
    mutate(sesso = if_else(...2 %in% names(SESSI), ...2, NA_character_)) |>
    fill(sesso) |>                                               # il nome del blocco vale per le righe sotto
    filter(!is.na(sesso), !is.na(...1), !str_detect(...1, "^Fonte")) |>
    select(sesso, categoria = ...1, all_of(col_pct))
  names(tab)[-(1:2)] <- risposte

  tab |>
    pivot_longer(all_of(risposte), names_to = "risposta", values_to = "percentuale") |>
    mutate(percentuale = as.numeric(percentuale), sesso = unname(SESSI[sesso]))
}

# prova su una tavola sola, per vedere cosa esce
f_leggi_tavola(file.path(dir_in, "Tav.10_a.xlsx"))

# 1. Leggo le quattro tavole ------------------------------------------------
ragazzi_grezzo <- TAVOLE |>
  mutate(dati = map(file.path(dir_in, paste0("Tav.", tavola, ".xlsx")), f_leggi_tavola)) |>
  unnest(dati)

# 2. Tengo età, ripartizione e totale ----------------------------------------
# (cittadinanza e generazione migratoria restano nel grezzo: qui non servono, e la riga
#  "Stranieri" è doppia in ogni blocco)
ragazzi_ict_social <- ragazzi_grezzo |>
  mutate(
    anno = ANNO,
    variabile = case_when(
      categoria %in% c("11-13 anni", "14-19 anni") ~ "eta",
      categoria %in% RIPARTIZIONI                  ~ "ripartizione",
      categoria == "TOTALE"                        ~ "totale"
    ),
    categoria = if_else(categoria == "TOTALE", "Totale", categoria)
  ) |>
  filter(!is.na(variabile)) |>
  select(indicatore, domanda, tavola, anno, sesso, variabile, categoria, risposta, percentuale)

ragazzi_ict_social

# Controlli ----------------------------------------------------------------
count(ragazzi_ict_social, indicatore, variabile)          # per indicatore: 3 sessi × (2 età + 5 ripartizioni + 1 totale) × n risposte
# le percentuali di ogni riga della tavola sommano a 100 (la risposta "Totale" vale 100)
ragazzi_ict_social |> filter(risposta == "Totale") |> count(percentuale)
# valore di prova, letto a mano dalla tavola 10.a: 14-19 anni, maschi e femmine, "No" = 4,6
ragazzi_ict_social |> filter(indicatore == "profilo_social", sesso == "Totale", categoria == "14-19 anni")

# 3. Salva nel proprio output/ -------------------------------------------------
saveRDS(ragazzi_ict_social, file.path(dir_out, "ragazzi_ict_social.rds"))
write_csv(ragazzi_ict_social, file.path(dir_out, "ragazzi_ict_social.csv"))

# 4. Uso di internet e del pc per età (serie 2001→, da ingestione/06b) -----------------
# Fonte MULTI-modulo già pulita: qui solo il ritaglio che serve ai grafici (giovani + totale)
dir_ict <- here("dati", "puliti", "istat_ict")
ETA_GIOVANI <- c("06-10", "11-14", "15-17", "18-19", "20-24")

ict_eta_ritaglio <- readRDS(file.path(dir_ict, "ict_uso_eta.rds")) |>
  filter(sesso == "Totale", eta %in% c(ETA_GIOVANI, "Totale"),
         frequenza %in% c("usano", "tutti i giorni")) |>
  select(strumento, frequenza, eta, anno, valore, popolazione_rif)

ict_eta_ritaglio

# classe 15-19 = NOSTRA stima: media di 15-17 e 18-19 pesata con gli anni d'età coperti (3 e 2),
# cioè assumendo leve di pari numerosità. I due valori sono sempre vicini, l'errore è sotto il decimo di punto.
# Serve ai grafici: le linee 15-17 e 18-19 si sovrappongono, e 15-19 si confronta meglio con il 14-19 delle altre fonti
PESI_15_19 <- c("15-17" = 3, "18-19" = 2)

ict_15_19 <- ict_eta_ritaglio |>
  filter(eta %in% names(PESI_15_19)) |>
  summarise(valore = weighted.mean(valore, PESI_15_19[eta]),
            .by = c(strumento, frequenza, anno, popolazione_rif)) |>
  mutate(eta = "15-19", stima_nostra = TRUE)

ict_giovani_eta <- ict_eta_ritaglio |>
  mutate(stima_nostra = FALSE) |>
  bind_rows(ict_15_19) |>
  arrange(strumento, frequenza, eta, anno)

ict_giovani_eta
# controllo a mano sul 2025, internet tutti i giorni: (3 × 94,0 + 2 × 96,1) / 5 = 94,84
filter(ict_giovani_eta, strumento == "internet", frequenza == "tutti i giorni", anno == 2025)
count(ict_giovani_eta, strumento, frequenza, eta)     # 24 anni per ogni combinazione (7 classi: le 5 ISTAT + 15-19 + Totale)
filter(ict_giovani_eta, is.na(valore))                # atteso: nessun mancante in questo ritaglio

# cornice territoriale (solo per il testo: ER e Nord-est ~2 punti sopra l'Italia)
ict_reg <- readRDS(file.path(dir_ict, "ict_uso_reg.rds")) |>
  filter(frequenza %in% c("usano", "tutti i giorni")) |>
  select(frequenza, territorio, anno, valore)

ict_reg

saveRDS(ict_giovani_eta, file.path(dir_out, "ict_giovani_eta.rds"))
write_csv(ict_giovani_eta, file.path(dir_out, "ict_giovani_eta.csv"))
saveRDS(ict_reg, file.path(dir_out, "ict_reg.rds"))
write_csv(ict_reg, file.path(dir_out, "ict_reg.csv"))

# 5. Uso dell'IA generativa: Italia e UE (Eurostat, 2025; grezzo da ingestione/07) ----------
# Fonte MONO-modulo: il ritaglio e le etichette in italiano si fanno qui
dir_ai <- here("dati", "grezzi", "eurostat_isoc_ai")

# classi d'età NON sovrapposte, dalla più giovane; etichetta da mostrare nei grafici
ETA_AI <- c("Y16_19" = "16-19", "Y20_24" = "20-24", "Y25_34" = "25-34", "Y35_44" = "35-44",
            "Y45_54" = "45-54", "Y55_64" = "55-64", "Y65_74" = "65-74", "IND_TOTAL" = "Totale 16-74")
TERRITORI_AI <- c("IT" = "Italia", "EU27_2020" = "UE (27 paesi)")
# indicatore + base della percentuale da usare (v. _metadati.md): adozione sul totale delle persone,
# scopi su chi ha usato l'IA
INDICATORI_AI <- tribble(
  ~indic_is,  ~unit,          ~indicatore,       ~etichetta_indicatore,
  "I_IUAI",   "PC_IND",       "uso_ia",          "Ha usato strumenti di IA generativa (ultimi 3 mesi)",
  "I_IUAIFE", "PC_IND_IUAI",  "scopo_studio",    "Per lo studio (istruzione formale)",
  "I_IUAIPR", "PC_IND_IUAI",  "scopo_privato",   "Per scopi privati",
  "I_IUAIWP", "PC_IND_IUAI",  "scopo_lavoro",    "Per lavoro"
)

ia_eta_it_ue <- readRDS(file.path(dir_ai, "isoc_ai_iaiu.rds")) |>
  inner_join(INDICATORI_AI, by = c("indic_is", "unit")) |>          # tiene solo le 4 coppie indicatore-base
  filter(geo %in% names(TERRITORI_AI), ind_type %in% names(ETA_AI)) |>
  mutate(territorio = unname(TERRITORI_AI[geo]), eta = unname(ETA_AI[ind_type])) |>
  select(indicatore, etichetta_indicatore, territorio, eta, anno = TIME_PERIOD, valore = values,
         cod_indicatore = indic_is, cod_base = unit, cod_eta = ind_type)

ia_eta_it_ue

count(ia_eta_it_ue, indicatore, territorio)     # 8 classi per ogni combinazione
filter(ia_eta_it_ue, is.na(valore))             # mancanti: da guardare (classi piccole?)
# valore di prova: Italia 16-19, uso_ia = 51,9; scopo_studio = 78,1
filter(ia_eta_it_ue, territorio == "Italia", eta == "16-19")

saveRDS(ia_eta_it_ue, file.path(dir_out, "ia_eta_it_ue.rds"))
write_csv(ia_eta_it_ue, file.path(dir_out, "ia_eta_it_ue.csv"))
