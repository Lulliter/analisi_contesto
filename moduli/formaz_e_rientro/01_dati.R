# ___________________________________________________________________________
# Modulo: formaz_e_rientro
# Fonte:  MIM open data (via ingestione/02 → dati/puliti/mim_iscritti/): iscritti
#         per plesso con `percorso == "seconda_chance"` = corsi serali (percorsi
#         di II livello) e sezioni carcerarie; CPIA di Parma (bilancio di
#         sostenibilità + sito, trascritti a mano in dati/grezzi/iefp_cpia_ER_PR/)
# Input:  dati/puliti/mim_iscritti/scuole_iscritti_er.rds
#         dati/puliti/mim_iscritti/iscritti_it_percorso.rds (totali Italia, per la riga ITALIA)
#         dati/puliti/mim_iscritti/scuole_iscritti_cittadinanza_er.rds
#         dati/puliti/mim_iscritti/scuole_anagrafe_er.rds (caratteristica, grado, comune)
#         dati/grezzi/iefp_cpia_ER_PR/cpia_parma_iscritti.csv (a mano)
# Output: moduli/formaz_e_rientro/output/<oggetto>.rds + .csv (nome file = oggetto):
#         rientro_trend_pr          (anno × tipo [serale / carcere / CPIA]: alunni, PR)
#         rientro_incidenza_prov_er (anno × provincia ER: iscritti ai serali in % degli
#                                    iscritti alla sec. II grado ordinaria STATALE; + EMILIA-ROMAGNA e ITALIA)
#         rientro_profilo_pr        (ultimo a.s., serali PR: alunni per dimensione
#                                    [età / cittadinanza / tipo istituto / anno di corso] e valore)
#         rientro_sedi_pr           (ultimo a.s.: le sedi serali PR con comune,
#                                    tipo istituto, alunni, pro_com_t)
# NB: "seconda chance" = chi rientra in formazione da adulto. Nei dati MIM ci
#     sono SOLO i serali e il carcere; il CPIA (alfabetizzazione, licenza media,
#     ~3.000 iscritti) non compare nei file studenti open data (0 alunni in tutta
#     Italia) e arriva da fonte propria; IeFP negli enti di formazione: non in
#     casa (solo regionale, INAPP); IeFP negli istituti professionali: già
#     dentro gli iscritti ordinari, indistinguibile. Eventuali serali PARITARI
#     non sono identificabili (caratteristica vuota) e restano nell'ordinario
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(stringr)
library(readr)
library(purrr)
library(janitor)

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "formaz_e_rientro", "output")
if (!dir.exists(dir_mod)) dir.create(dir_mod, recursive = TRUE)
file_cpia <- here("dati", "grezzi", "iefp_cpia_ER_PR", "cpia_parma_iscritti.csv")

ANNO_ULTIMO <- 2024 # a.s. 2024/25, per profilo e sedi
# da `caratteristica` (anagrafe MIM) al tipo di seconda chance
TIPO_RIENTRO <- c("PERCORSO II LIVELLO" = "serale", "SPEC. PER CARCERARI" = "carcere")

# 1. Carica input (già puliti dall'ingestione) -----------------------------
scuole_iscritti_er <- readRDS(here("dati", "puliti", "mim_iscritti", "scuole_iscritti_er.rds"))
scuole_iscritti_cittadinanza_er <- readRDS(here("dati", "puliti", "mim_iscritti", "scuole_iscritti_cittadinanza_er.rds"))
scuole_anagrafe_er <- readRDS(here("dati", "puliti", "mim_iscritti", "scuole_anagrafe_er.rds"))
iscritti_it_percorso <- readRDS(here("dati", "puliti", "mim_iscritti", "iscritti_it_percorso.rds"))
cpia_parma_iscritti <- read_csv(file_cpia, col_types = cols(.default = col_character())) |>
  mutate(across(c(anno_inizio, alunni), as.integer))

# 2. Seconda chance nei dati MIM ------------------------------------------
# Il "grado" dell'anagrafe (es. "IST PROF INDUSTRIA E ARTIGIANATO") → tipo istituto
f_tipo_istituto <- function(grado) {
  case_when(
    str_detect(grado, "PROF") ~ "professionale",
    str_detect(grado, "TEC") ~ "tecnico",
    str_detect(grado, "D'ARTE|LICEO") ~ "artistico/liceo",
    .default = "altro"
  )
}

# fascia_eta è testo ("17 anni", "18 anni", "> di 18 anni") → 3 classi
f_classe_eta <- function(fascia) {
  case_when(
    str_starts(fascia, ">") ~ "oltre 18",
    str_detect(fascia, "^18") ~ "18",
    .default = "minorenni"
  )
}

# iscritti dei serali e del carcere, con caratteristica/grado/comune dall'anagrafe
iscritti_rientro <- scuole_iscritti_er |>
  filter(percorso == "seconda_chance") |>
  left_join(scuole_anagrafe_er |> select(codice_scuola, caratteristica, grado),
            by = "codice_scuola") |>
  mutate(tipo = TIPO_RIENTRO[caratteristica],          # NA = CPIA (senza alunni nel MIM)
         tipo_istituto = f_tipo_istituto(grado),
         classe_eta = f_classe_eta(fascia_eta))

stopifnot(!anyNA(iscritti_rientro$tipo)) # se fallisce: nuova caratteristica da mappare in TIPO_RIENTRO

## __ Trend PR per tipo (serale / carcere) + riga CPIA da fonte propria -----
rientro_trend_pr <- iscritti_rientro |>
  filter(provincia == "PARMA") |>
  summarise(alunni = sum(alunni), .by = c(anno_inizio, tipo)) |>
  mutate(fonte = "MIM open data")

rientro_trend_pr <- bind_rows(
  rientro_trend_pr,
  cpia_parma_iscritti |>
    transmute(anno_inizio, tipo = "CPIA", alunni, fonte)
) |>
  arrange(tipo, anno_inizio)

rientro_trend_pr

## __ Incidenza dei serali per provincia ER: in % degli iscritti alla sec. II grado ordinaria STATALE -----
# numeratore e denominatore dagli stessi dati MIM → confrontabile tra province.
# Solo statali su entrambi i lati (2026-09-23): i serali si identificano solo
# nelle statali; nelle paritarie ER nessun plesso di II grado ha più del 30% di
# iscritti sopra i 18 anni (verificato sul 2024/25), quindi serali paritari nei
# dati non ce ne sono; le private NON paritarie non sono nel MIM
serali_prov_er <- iscritti_rientro |>
  filter(tipo == "serale") |>
  summarise(alunni_serali = sum(alunni), .by = c(anno_inizio, provincia))

sec2_ordinaria_prov_er <- scuole_iscritti_er |>
  filter(percorso == "ordinario", gestione == "statale",
         ordine_scuola == "SCUOLA SECONDARIA II GRADO") |>
  summarise(alunni_sec2 = sum(alunni), .by = c(anno_inizio, provincia))

rientro_incidenza_prov_er <- sec2_ordinaria_prov_er |>
  left_join(serali_prov_er, by = c("anno_inizio", "provincia")) |>
  mutate(alunni_serali = coalesce(alunni_serali, 0L))  # province senza serali → 0

# riga ITALIA dai totali nazionali (stessa definizione: serali statali / sec. II ordinaria statale)
incidenza_it <- iscritti_it_percorso |>
  filter(gestione == "statale", ordine_scuola == "SCUOLA SECONDARIA II GRADO") |>
  summarise(alunni_sec2 = sum(alunni[percorso == "ordinario"]),
            alunni_serali = sum(alunni[caratteristica %in% "PERCORSO II LIVELLO"]),
            .by = anno_inizio) |>
  mutate(provincia = "ITALIA")

rientro_incidenza_prov_er <- bind_rows(
  rientro_incidenza_prov_er,
  rientro_incidenza_prov_er |>
    summarise(alunni_sec2 = sum(alunni_sec2), alunni_serali = sum(alunni_serali),
              .by = anno_inizio) |>
    mutate(provincia = "EMILIA-ROMAGNA"),
  incidenza_it
) |>
  mutate(quota_serali = alunni_serali / alunni_sec2) # frazione, come quota_ritardo negli altri moduli

rientro_incidenza_prov_er

## __ Profilo dei serali PR, ultimo a.s.: una tabella lunga (dimensione × valore) -----
# così un solo oggetto alimenta più grafici (barre per età, cittadinanza, istituto, anno di corso)
serali_ultimo_pr <- iscritti_rientro |>
  filter(provincia == "PARMA", tipo == "serale", anno_inizio == ANNO_ULTIMO)

# cittadinanza dal file gemello (stesso plesso, stesso a.s.)
cittadinanza_serali_pr <- scuole_iscritti_cittadinanza_er |>
  filter(provincia == "PARMA", percorso == "seconda_chance", anno_inizio == ANNO_ULTIMO) |>
  left_join(scuole_anagrafe_er |> select(codice_scuola, caratteristica), by = "codice_scuola") |>
  filter(caratteristica == "PERCORSO II LIVELLO") |>
  summarise(italiani = sum(alunni_ita), stranieri = sum(alunni_stranieri)) |>
  tidyr::pivot_longer(everything(), names_to = "valore", values_to = "alunni") |>
  mutate(dimensione = "cittadinanza")

rientro_profilo_pr <- bind_rows(
  serali_ultimo_pr |> count(dimensione = "età", valore = classe_eta, wt = alunni, name = "alunni"),
  cittadinanza_serali_pr,
  serali_ultimo_pr |> count(dimensione = "tipo istituto", valore = tipo_istituto, wt = alunni, name = "alunni"),
  serali_ultimo_pr |> count(dimensione = "anno di corso", valore = as.character(anno_corso), wt = alunni, name = "alunni")
) |>
  mutate(quota = alunni / sum(alunni), .by = dimensione,
         anno_inizio = ANNO_ULTIMO) |>
  select(anno_inizio, dimensione, valore, alunni, quota)
rientro_profilo_pr

## __ Sedi serali PR, ultimo a.s. (per mappa/tabella) -----
rientro_sedi_pr <- serali_ultimo_pr |>
  summarise(alunni = sum(alunni), .by = c(anno_inizio, codice_scuola, comune, pro_com_t, tipo_istituto)) |>
  left_join(scuole_anagrafe_er |> select(codice_scuola, grado), by = "codice_scuola") |>
  arrange(desc(alunni))
rientro_sedi_pr

# 3. Salva nel proprio output/ (rds + csv, nome file = oggetto) ------------
lista_out <- list(
  rientro_trend_pr = rientro_trend_pr,
  rientro_incidenza_prov_er = rientro_incidenza_prov_er,
  rientro_profilo_pr = rientro_profilo_pr,
  rientro_sedi_pr = rientro_sedi_pr
)

iwalk(lista_out, function(df, nome) {
  saveRDS(df, file.path(dir_mod, paste0(nome, ".rds")))
  write_csv(df, file.path(dir_mod, paste0(nome, ".csv")))
  message("Salvato: ", nome, " (", nrow(df), " righe)")
})

# Verifiche rapide (da eseguire a mano) ------------------------------------
iscritti_rientro |> count(caratteristica, tipo, wt = alunni)                # solo serale e carcere
rientro_trend_pr |> filter(tipo == "serale")                               # PR: 704 (2015) → 502 (2024)
rientro_incidenza_prov_er |> filter(anno_inizio == ANNO_ULTIMO) |> arrange(desc(quota_serali)) # PR ~2,5% (2,4 con le paritarie nel denominatore), ER ~2%, Italia ~3,2%
rientro_incidenza_prov_er |> filter(provincia == "ITALIA")                     # Italia in crescita: 2,3% (2015) → 3,2% (2024)
rientro_profilo_pr |> filter(dimensione == "cittadinanza")                  # 2024: 323 italiani, 179 stranieri
rientro_sedi_pr                                                            # 8 sedi, 6 a Parma + Fidenza + Salsomaggiore
