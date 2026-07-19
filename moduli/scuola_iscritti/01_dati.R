# ------------------------------------------------------------------------
# Modulo: scuola_iscritti
# Fonte:  MIM open data (via ingestione/02_prep_mim_studenti.R → dati/puliti/mim_iscritti/)
# Input:  dati/puliti/mim_iscritti/scuole_iscritti_er.rds
#         dati/puliti/mim_iscritti/scuole_iscritti_cittadinanza_er.rds
#         dati/puliti/mim_iscritti/scuole_anagrafe_er.rds (plessi paritarie)
#         dati/puliti/mim_iscritti/scuole_anagrafe_storico_er.rds (trend plessi)
# Output: moduli/scuola_iscritti/output/<oggetto>.rds + .csv (nome file = oggetto):
#         iscritti_trend_pr        (anno × ordine × gestione, provincia PR)
#         iscritti_trend_prov_er   (anno × provincia, totali per confronto)
#         stranieri_trend_prov_er  (anno × provincia, % stranieri)
#         scuola_comuni_pr         (anno × comune PR: plessi, alunni,
#                                   % stranieri, con pro_com_t per le mappe)
#         paritarie_comuni_pr      (anno × comune × ordine PR: % iscritti
#                                   in scuole paritarie sul totale)
#         paritarie_plessi_comuni_pr (comune × 4 ordini: % PLESSI paritari,
#                                   dall'anagrafe → infanzia inclusa)
#         plessi_trend_pr          (anno × 4 ordini × gestione: n. plessi,
#                                   dalle anagrafi storiche, infanzia inclusa)
# NB: gli ISCRITTI non coprono la scuola dell'infanzia (limite fonte MIM);
#     i conteggi di PLESSI dall'anagrafe invece sì
# ------------------------------------------------------------------------

library(here)
library(dplyr)
library(stringr) # str_detect in f_classifica_ordine
library(readr)
library(purrr)

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "scuola_iscritti", "output")
if (!dir.exists(dir_mod)) dir.create(dir_mod, recursive = TRUE)

# 1. Carica input (già puliti dall'ingestione) -----------------------------
scuole_iscritti_er <- readRDS(here("dati", "puliti", "mim_iscritti", "scuole_iscritti_er.rds"))
scuole_iscritti_cittadinanza_er <- readRDS(here("dati", "puliti", "mim_iscritti", "scuole_iscritti_cittadinanza_er.rds"))
scuole_anagrafe_er <- readRDS(here("dati", "puliti", "mim_iscritti", "scuole_anagrafe_er.rds"))

# Classifica il "grado" dell'anagrafe nei 4 ordini di scuola (NA = non è un
# plesso didattico di un ordine: istituti comprensivi, CPIA, convitti)
f_classifica_ordine <- function(grado) {
  case_when(
    str_detect(grado, "INFANZIA") ~ "Infanzia",
    str_detect(grado, "PRIMARIA") ~ "Primaria",
    str_detect(grado, "PRIMO GRADO") ~ "Secondaria I grado",
    str_detect(grado, "SECONDO GRADO|LICEO|TEC|PROF|SUPERIORE|MAGISTRALE|D'ARTE") ~ "Secondaria II grado",
    .default = NA_character_
  )
}

# 2. Aggregati per i grafici ----------------------------------------------

## __ Trend iscritti PR per ordine di scuola e gestione  -----
iscritti_trend_pr <- scuole_iscritti_er |>
  filter(provincia == "PARMA") |>
  summarise(alunni = sum(alunni), .by = c(anno_inizio, ordine_scuola, gestione))
iscritti_trend_pr

## __ Trend iscritti totali per provincia ER (per confronto tra province) -----
iscritti_trend_prov_er <- scuole_iscritti_er |>
  summarise(alunni = sum(alunni), .by = c(anno_inizio, provincia))
iscritti_trend_prov_er

## __ % stranieri per provincia ER e anno, + riga "EMILIA-ROMAGNA" (media regionale) -----
stranieri_trend_prov_er <- scuole_iscritti_cittadinanza_er |>
  summarise(alunni = sum(alunni),
            alunni_stranieri = sum(alunni_stranieri),
            .by = c(anno_inizio, provincia)) |>
  mutate(quota_stranieri = alunni_stranieri / alunni)

stranieri_trend_prov_er <- bind_rows(
  stranieri_trend_prov_er,
  stranieri_trend_prov_er |>
    summarise(alunni = sum(alunni),
              alunni_stranieri = sum(alunni_stranieri),
              .by = anno_inizio) |>
    mutate(provincia = "EMILIA-ROMAGNA",
           quota_stranieri = alunni_stranieri / alunni)
)
stranieri_trend_prov_er

## __ Quadro comunale PR per anno: plessi con iscritti, alunni, % stranieri -----
# (pro_com_t per le mappe; "plessi" = sedi con almeno un iscritto, no infanzia)
scuola_comuni_pr <- scuole_iscritti_cittadinanza_er |>
  filter(provincia == "PARMA") |>
  summarise(n_plessi = n_distinct(codice_scuola),
            alunni = sum(alunni),
            alunni_stranieri = sum(alunni_stranieri),
            .by = c(anno_inizio, comune, pro_com_t)) |>
  mutate(quota_stranieri = alunni_stranieri / alunni)

scuola_comuni_pr

## __ Incidenza della scuola paritaria per comune PR, anno e ordine di scuola -----
# (quota 0 = ci sono scuole ma solo statali; il comune manca dal df se non
# ha proprio scuole di quell'ordine)
paritarie_comuni_pr <- scuole_iscritti_er |>
  filter(provincia == "PARMA") |>
  summarise(
    # NB: alunni_paritaria va calcolato PRIMA di alunni — in summarise le
    # espressioni si valutano in sequenza, e definire `alunni = sum(alunni)`
    # per primo sovrascriverebbe la colonna con il totale (scalare)
    alunni_paritaria = sum(alunni[gestione == "paritaria"]),
    alunni = sum(alunni),
    .by = c(anno_inizio, ordine_scuola, comune, pro_com_t)
  ) |>
  mutate(quota_paritaria = alunni_paritaria / alunni) |>
  select(anno_inizio, ordine_scuola, comune, pro_com_t,
         alunni, alunni_paritaria, quota_paritaria)
paritarie_comuni_pr

## __ Quota di PLESSI paritari per comune e ordine (dall'ANAGRAFE, quindi con -----
# anche l'INFANZIA che nei dati iscritti manca; a.s. dell'anagrafe = 2024/25).
# NB: esclusi dal conteggio i "gradi" che non sono plessi didattici di un
# ordine (istituti comprensivi = sedi direttive, CPIA/centri territoriali,
# convitti)
paritarie_plessi_comuni_pr <- scuole_anagrafe_er |>
  filter(provincia == "PARMA") |>
  mutate(ordine_scuola = f_classifica_ordine(grado)) |>
  filter(!is.na(ordine_scuola)) |>
  summarise(
    n_plessi_paritari = sum(gestione == "paritaria"),
    n_plessi = n(),
    .by = c(ordine_scuola, comune, pro_com_t)
  ) |>
  mutate(quota_plessi_paritari = n_plessi_paritari / n_plessi)
paritarie_plessi_comuni_pr

# Trend dei PLESSI per anno, ordine (infanzia inclusa) e gestione — per
# vedere aperture/chiusure di scuole. Dalle anagrafi storiche (ingestione/02).
scuole_anagrafe_storico_er <- readRDS(here("dati", "puliti", "mim_iscritti",
                                           "scuole_anagrafe_storico_er.rds"))

plessi_trend_pr <- scuole_anagrafe_storico_er |>
  filter(provincia == "PARMA") |>
  mutate(ordine_scuola = f_classifica_ordine(grado)) |>
  filter(!is.na(ordine_scuola)) |>
  summarise(n_plessi = n(), .by = c(anno_inizio, ordine_scuola, gestione))

# 3. Salva nel proprio output/ (rds + csv, nome file = oggetto) ------------
lista_out <- list(
  iscritti_trend_pr = iscritti_trend_pr,
  iscritti_trend_prov_er = iscritti_trend_prov_er,
  stranieri_trend_prov_er = stranieri_trend_prov_er,
  scuola_comuni_pr = scuola_comuni_pr,
  paritarie_comuni_pr = paritarie_comuni_pr,
  paritarie_plessi_comuni_pr = paritarie_plessi_comuni_pr,
  plessi_trend_pr = plessi_trend_pr
)


iwalk(lista_out, function(df, nome) {
  saveRDS(df, file.path(dir_mod, paste0(nome, ".rds")))
  write_csv(df, file.path(dir_mod, paste0(nome, ".csv")))
  message("Salvato: ", nome, " (", nrow(df), " righe)")
})

# Verifiche rapide (da eseguire a mano) ------------------------------------
iscritti_trend_pr |> summarise(alunni = sum(alunni), .by = anno_inizio)  # trend totale PR
stranieri_trend_prov_er |> filter(anno_inizio == 2024)                   # PR atteso ~18-19%
plessi_trend_pr |> count(anno_inizio)         # atteso: 12 a.s. (con anagrafi storiche)

