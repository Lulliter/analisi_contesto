# ________________________________________________________________________
# Modulo: giovani_benessere
# Fonte:  ISTAT Bes nazionale, aggiornamento 2026 (via ingestione/05 →
#         dati/puliti/istat_bes/): indicatori per età e sesso dall'indagine
#         "Aspetti della vita quotidiana" (stima campionaria, solo ITALIA per
#         età × sesso; per regione esiste solo il totale della popolazione)
# Input:  dati/puliti/istat_bes/bes_eta_sesso.rds
#         dati/puliti/istat_bes/bes_regioni.rds (cornice ER/Nord-est/Italia, totale)
# Output: moduli/giovani_benessere/output/<oggetto>.rds + .csv (nome file = oggetto):
#         bes_giovani_eta_sesso   (4 indicatori × 14-19 / 20-24 / Totale × sesso × anno, Italia)
#         bes_giovani_reg         (stessi indicatori, totale popolazione: ER, Nord-est, Italia)
# NB: l'indice di salute mentale (MH) e' un punteggio 0-100 (media, piu' alto =
#     meglio); gli altri tre sono % di persone con giudizio positivo. Tutti da
#     campione: commentare ordini di grandezza e trend, non i decimali.
#     Il salto della soddisfazione per la vita tra 2011 e 2012 (57 → 47 nei 14-19)
#     va verificato: possibile cambio di metodo dell'indagine.
# ________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(readr)
library(purrr)

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "giovani_benessere", "output")
if (!dir.exists(dir_mod)) dir.create(dir_mod, recursive = TRUE)

# indicatori Bes da tenere (codice = nome breve usato negli output)
INDICATORI <- c(
  "01SAL003B" = "salute_mentale",   # Indice di salute mentale (MH), 2016 →
  "05REL002"  = "amici",            # Soddisfazione per le relazioni amicali, 2005 →
  "08BSO001"  = "vita",             # Soddisfazione per la propria vita, 2010 →
  "08BSO003"  = "prospettive"       # Giudizio positivo sulle prospettive future, 2012 →
)
ETA_GIOVANI <- c("14-19", "20-24", "Totale")
TERRITORI_BES <- c("Emilia-Romagna", "Nord-est", "Italia")

# 1. Carica input (già puliti dall'ingestione) -----------------------------
bes_eta_sesso <- readRDS(here("dati", "puliti", "istat_bes", "bes_eta_sesso.rds"))
bes_regioni <- readRDS(here("dati", "puliti", "istat_bes", "bes_regioni.rds"))

# 2. Giovani per età e sesso (Italia) --------------------------------------
bes_giovani_eta_sesso <- bes_eta_sesso |>
  filter(cod_indicatore %in% names(INDICATORI), eta %in% ETA_GIOVANI) |>
  mutate(indicatore_breve = INDICATORI[cod_indicatore],
         anno = as.integer(anno)) |>
  select(cod_indicatore, indicatore_breve, indicatore, eta, sesso, anno,
         valore, poco_signif, unita_misura, fonte) |>
  arrange(indicatore_breve, eta, sesso, anno)
bes_giovani_eta_sesso

# 3. Cornice territoriale: stessi indicatori, totale popolazione -----------
# NB: nella tabella regionale la salute mentale ha codice "01SAL003" (tasso
#     STANDARDIZZATO per età), in quella per età e sesso "01SAL003B" (tasso
#     GREZZO): stesso indicatore, due versioni. Per il confronto territoriale sul
#     totale va bene lo standardizzato, ma i due numeri non sono identici (dirlo
#     nel blurb). Gli altri tre indicatori hanno lo stesso codice nelle due tabelle.
codici_reg <- sub("B$", "", names(INDICATORI))
names(codici_reg) <- INDICATORI

bes_giovani_reg <- bes_regioni |>
  filter(cod_indicatore %in% codici_reg, territorio %in% TERRITORI_BES) |>
  mutate(indicatore_breve = names(codici_reg)[match(cod_indicatore, codici_reg)],
         anno = as.integer(anno)) |>
  select(cod_indicatore, indicatore_breve, indicatore, territorio, livello, sesso, anno,
         valore, poco_signif, unita_misura, fonte) |>
  arrange(indicatore_breve, territorio, sesso, anno)
bes_giovani_reg

# 4. Salva nel proprio output/ (rds + csv, nome file = oggetto) ------------
lista_out <- list(
  bes_giovani_eta_sesso = bes_giovani_eta_sesso,
  bes_giovani_reg = bes_giovani_reg
)

iwalk(lista_out, function(df, nome) {
  saveRDS(df, file.path(dir_mod, paste0(nome, ".rds")))
  write_csv(df, file.path(dir_mod, paste0(nome, ".csv")))
  message("Salvato: ", nome, " (", nrow(df), " righe)")
})

# Verifiche rapide (da eseguire a mano) ------------------------------------
bes_giovani_eta_sesso |> count(indicatore_breve, eta, sesso) # 4 × 3 × 3 combinazioni
bes_giovani_eta_sesso |> filter(indicatore_breve == "salute_mentale", eta == "14-19", anno %in% 2019:2021) # attesi: Totale 72,9 → 73,9 → 70,3; Femmine 70,6 → 71,2 → 66,6
bes_giovani_eta_sesso |> filter(indicatore_breve == "amici", eta == "14-19", sesso == "Femmine", anno %in% c(2012, 2018, 2021, 2025)) # attesi: 47,2 → 37,4 → 34,3 → 37,3
bes_giovani_reg |> count(indicatore_breve, territorio) # 4 indicatori × 3 territori
bes_giovani_reg |> filter(indicatore_breve == "salute_mentale", sesso == "Totale", anno == 2025) # ER, Nord-est, Italia (standardizzato)
