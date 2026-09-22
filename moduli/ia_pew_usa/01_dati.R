# ___________________________________________________________________________
# Modulo: ia_pew_usa
# Fonte:  Pew Research Center, "Americans and AI 2026" (adulti USA, 17-23 febbraio 2026)
# Scopo:  due tavole del rapporto (uso quotidiano dei chatbot; impatto atteso dell'IA) per età,
#         in formato lungo con etichette in italiano
# Input:  dati/grezzi/pew_ipsos_ai/1_in_3_adults_..._data_2026-06-17.csv
#         dati/grezzi/pew_ipsos_ai/young_adults_are_more_skeptical_..._data_2026-06-17.csv
# Output: output/uso_chatbot_eta.rds (+ .csv), output/impatto_ia_eta.rds (+ .csv)
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(tidyr)
library(readr)

# Parametri ---------------------------------------------------------------
ANNO    <- 2026
dir_in  <- here("dati", "grezzi", "pew_ipsos_ai")
dir_out <- here("moduli", "ia_pew_usa", "output")
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)
file_uso     <- file.path(dir_in, "1_in_3_adults_under_50_say_they_use_ai_chatbots_daily_data_2026-06-17.csv")
file_impatto <- file.path(dir_in, "young_adults_are_more_skeptical_about_ais_future_impact_older_adults_more_unsure_data_2026-06-17.csv")

# etichette Pew → italiano (nomi = dicitura del csv)
LAB_ETA      <- c("U.S. adults" = "Tutti gli adulti", "Ages 18-29" = "18-29 anni", "30-49" = "30-49 anni",
                  "50-64" = "50-64 anni", "65+" = "65 anni e più")
LAB_FREQ     <- c("Several times a day or more" = "Più volte al giorno", "About once a day" = "Circa una volta al giorno",
                  "NET Daily" = "Ogni giorno (totale)")
LAB_AMBITO   <- c("Society" = "Sulla società", "Them, personally" = "Su di sé")
LAB_GIUDIZIO <- c("Negative" = "Negativo", "Positive" = "Positivo", "Not sure" = "Non sa")

# 1. Uso quotidiano dei chatbot ---------------------------------------------
# nel csv: 3 righe di titolo (l'ultima vuota), poi intestazione + 5 righe di dati, sotto note e fonte
uso_grezzo <- read_csv(file_uso, skip = 3, n_max = 5, col_types = cols(.default = "c"))
uso_grezzo

uso_chatbot_eta <- uso_grezzo |>
  rename(eta = 1) |>                                   # la prima colonna non ha nome
  pivot_longer(-eta, names_to = "frequenza", values_to = "percentuale") |>
  mutate(
    anno        = ANNO,
    eta         = unname(LAB_ETA[eta]),
    frequenza   = unname(LAB_FREQ[frequenza]),
    percentuale = parse_number(percentuale)            # "16%" → 16
  ) |>
  select(anno, eta, frequenza, percentuale)

uso_chatbot_eta

# 2. Impatto atteso dell'IA nei prossimi 20 anni ----------------------------
# stessa forma: intestazione + 10 righe (5 età × 2 domande)
impatto_grezzo <- read_csv(file_impatto, skip = 3, n_max = 10, col_types = cols(.default = "c"))
impatto_grezzo

impatto_ia_eta <- impatto_grezzo |>
  rename(eta = 1, ambito = Question) |>
  pivot_longer(c(Negative, Positive, `Not sure`), names_to = "giudizio", values_to = "percentuale") |>
  mutate(
    anno        = ANNO,
    eta         = unname(LAB_ETA[eta]),
    ambito      = unname(LAB_AMBITO[ambito]),
    giudizio    = unname(LAB_GIUDIZIO[giudizio]),
    percentuale = parse_number(percentuale)
  ) |>
  select(anno, ambito, eta, giudizio, percentuale)

impatto_ia_eta

# Controlli ----------------------------------------------------------------
# nessuna etichetta rimasta NA (dicitura del csv non prevista in LAB_*)
count(uso_chatbot_eta, eta, frequenza) |> filter(is.na(eta) | is.na(frequenza))   # atteso: 0 righe
count(impatto_ia_eta, ambito, eta, giudizio) |> filter(if_any(everything(), is.na)) # atteso: 0 righe
# valori di prova letti sui grafici Pew: 30-49 anni ogni giorno = 34; 18-29, società, negativo = 48
uso_chatbot_eta |> filter(eta == "30-49 anni", frequenza == "Ogni giorno (totale)")
impatto_ia_eta |> filter(eta == "18-29 anni", ambito == "Sulla società", giudizio == "Negativo")

# 3. Salva nel proprio output/ -------------------------------------------------
saveRDS(uso_chatbot_eta, file.path(dir_out, "uso_chatbot_eta.rds"))
write_csv(uso_chatbot_eta, file.path(dir_out, "uso_chatbot_eta.csv"))
saveRDS(impatto_ia_eta, file.path(dir_out, "impatto_ia_eta.rds"))
write_csv(impatto_ia_eta, file.path(dir_out, "impatto_ia_eta.csv"))
