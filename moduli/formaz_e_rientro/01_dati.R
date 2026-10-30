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
#         dati/grezzi/mim_open_data/ALUSECGRADOIND{STA,PAR}<a.s.>.csv (iscritti sec. II grado per
#             tipo di percorso, percorso e indirizzo, statali e paritarie; dal 2018/19)
#         dati/puliti/mim_iscritti/scuole_anagrafe_storico_er.rds (plessi ER per a.s., per la provincia)
#         dati/grezzi/iefp_cpia_ER_PR/cpia_parma_iscritti.csv (a mano)
# Output: moduli/formaz_e_rientro/output/<oggetto>.rds + .csv (nome file = oggetto):
#         rientro_trend_pr          (anno × tipo [serale / carcere / CPIA]: alunni, PR)
#         rientro_incidenza_prov_er (anno × provincia ER: iscritti ai serali in % degli
#                                    iscritti alla sec. II grado ordinaria STATALE; + EMILIA-ROMAGNA e ITALIA)
#         rientro_profilo_pr        (ultimo a.s., serali PR: alunni per dimensione
#                                    [età / cittadinanza / tipo istituto / anno di corso] e valore)
#         rientro_sedi_pr           (ultimo a.s.: le sedi serali PR con comune,
#                                    tipo istituto, alunni, pro_com_t)
#         iscritti_tipo_scuola      (Parma / ER × a.s. × gestione × tipo di scuola, + di cui licei
#                                    scientifici e classici: alunni, femmine; dal 2018/19)
#         iscritti_indirizzi        (Parma / ER × a.s. × gestione × utenza × tipo di scuola × settore
#                                    × indirizzo, tutti i tipi di scuola: alunni, femmine)
#         iscritti_tipo_utenza      (Parma / ER × a.s. × gestione × tipo di scuola × utenza
#                                    [diurno / serale / carcere]: alunni, femmine)
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

dir_mim        <- here("dati", "grezzi", "mim_open_data")
# iscritti per indirizzo (MIM): dal 2016/17; fino al 2017/18 la classificazione è diversa
# ("ISTITUTO TECNICO", "ISTITUTO PROFESSIONALE" con dentro la IeFP), quindi professionali e IeFP
# si confrontano nel tempo solo sommati (fino al 2026-10-30: ANNO_PRIMO_IND <- 2018)
ANNO_PRIMO_IND <- 2016
# tipo di percorso MIM → tipo di scuola (come nella Tab. 5 del Report giovani ER); le prime due
# etichette sono quelle fino al 2017/18
TIPI_SCUOLA <- c("ISTITUTO TECNICO" = "Tecnici", "ISTITUTO PROFESSIONALE" = "Professionali",
                 "LICEO" = "Licei", "TECNICO" = "Tecnici", "PROFESSIONALE" = "Professionali",
                 "PROFESSIONALE IeFP" = "IeFP nei professionali")
# "di cui" dei licei mostrati nella Tab. 5
LICEI_DI_CUI <- c("SCIENTIFICO" = "di cui scientifici", "CLASSICO" = "di cui classici")

# 1. Carica input (già puliti dall'ingestione) -----------------------------
scuole_iscritti_er <- readRDS(here("dati", "puliti", "mim_iscritti", "scuole_iscritti_er.rds"))
scuole_iscritti_cittadinanza_er <- readRDS(here("dati", "puliti", "mim_iscritti", "scuole_iscritti_cittadinanza_er.rds"))
scuole_anagrafe_er <- readRDS(here("dati", "puliti", "mim_iscritti", "scuole_anagrafe_er.rds"))
iscritti_it_percorso <- readRDS(here("dati", "puliti", "mim_iscritti", "iscritti_it_percorso.rds"))
scuole_anagrafe_storico_er <- readRDS(here("dati", "puliti", "mim_iscritti", "scuole_anagrafe_storico_er.rds"))
cpia_parma_iscritti <- read_csv(file_cpia, col_types = cols(.default = col_character())) |>
  mutate(across(c(anno_inizio, alunni), as.integer))

# 2. Iscritti alla secondaria di II grado per tipo di scuola (MIM, dal 2016/17) ----
# file MIM "per indirizzo", statali e paritarie, uno per a.s.; si tengono gli a.s. da ANNO_PRIMO_IND
files_indirizzo <- list.files(dir_mim, pattern = "^ALUSECGRADOIND(STA|PAR)\\d{14}\\.csv$", full.names = TRUE)
files_indirizzo <- files_indirizzo[as.integer(str_sub(basename(files_indirizzo), 18, 21)) >= ANNO_PRIMO_IND]
files_indirizzo   # attesi 18 file (9 a.s. × statali e paritarie)

iscritti_indirizzo_tutti <- files_indirizzo |>
  set_names() |>
  map(function(f) read_csv(f, col_types = cols(.default = col_character()))) |>
  list_rbind(names_to = "file") |>
  clean_names() |>
  mutate(gestione    = if_else(str_detect(file, "INDPAR"), "paritaria", "statale"),
         anno_inizio = as.integer(annoscolastico) %/% 100,
         across(c(annocorso, alunnimaschi, alunnifemmine), as.integer))

# solo plessi ER, con provincia e caratteristica dall'anagrafe dello stesso a.s. (i plessi cambiano
# codice negli anni). utenza: diurno (ragazzi), serale o carcere (adulti), dalla caratteristica del
# plesso; le paritarie non hanno caratteristica e restano "diurno"
iscritti_indirizzo_er <- iscritti_indirizzo_tutti |>
  inner_join(scuole_anagrafe_storico_er |> select(anno_inizio, codice_scuola, gestione, provincia, caratteristica),
             by = c("anno_inizio", "codicescuola" = "codice_scuola", "gestione")) |>
  transmute(anno_inizio, gestione, provincia, codice_scuola = codicescuola,
            utenza      = coalesce(unname(TIPO_RIENTRO[caratteristica]), "diurno"),
            anno_corso  = annocorso,
            tipo_scuola = unname(TIPI_SCUOLA[tipopercorso]),
            settore     = percorso,
            indirizzo,
            alunni_femmine = alunnifemmine,
            alunni         = alunnimaschi + alunnifemmine)

# tutti i tipi di percorso riconosciuti
stopifnot(!anyNA(iscritti_indirizzo_er$tipo_scuola))
count(iscritti_indirizzo_er, utenza, wt = alunni)   # serale e carcere pochi rispetto al diurno

# provincia di Parma ed Emilia-Romagna (somma delle province), per le variabili in `per`
f_somma_territori <- function(df, per) {
  bind_rows(
    df |> filter(provincia == "PARMA") |> mutate(territorio = "Provincia di Parma"),
    df |> mutate(territorio = "Emilia-Romagna")
  ) |>
    summarise(alunni = sum(alunni), alunni_femmine = sum(alunni_femmine),
              .by = all_of(c("territorio", per)))
}

# __ a) tipi di scuola, tutti gli iscritti ----
# territorio × a.s. × gestione × tipo di scuola, più i "di cui" dei licei
iscritti_tipo_scuola <- bind_rows(
  f_somma_territori(iscritti_indirizzo_er, c("anno_inizio", "gestione", "tipo_scuola")),
  iscritti_indirizzo_er |>
    filter(tipo_scuola == "Licei", settore %in% names(LICEI_DI_CUI)) |>
    mutate(tipo_scuola = unname(LICEI_DI_CUI[settore])) |>
    f_somma_territori(c("anno_inizio", "gestione", "tipo_scuola"))
)
iscritti_tipo_scuola

# __ b) settori e indirizzi, tutti i tipi di scuola ----
# territorio × a.s. × gestione × utenza × tipo di scuola × settore × indirizzo
# (per i professionali: settore "NUOVI PROFESSIONALI" = ordinamento dal 2018/19; gli altri settori =
# vecchio ordinamento, che resta soprattutto nei serali; per i tecnici: economico / tecnologico)
# (fino al 2026-10-30 solo professionali e IeFP, il filtro ora si fa in 02_output.R:)
# iscritti_professionali <- iscritti_indirizzo_er |>
#   filter(tipo_scuola %in% c("Professionali", "IeFP nei professionali")) |>
#   f_somma_territori(c("anno_inizio", "gestione", "utenza", "tipo_scuola", "settore", "indirizzo"))
iscritti_indirizzi <- iscritti_indirizzo_er |>
  f_somma_territori(c("anno_inizio", "gestione", "utenza", "tipo_scuola", "settore", "indirizzo"))
iscritti_indirizzi

# __ c) adulti negli istituti professionali (e negli altri tipi di scuola) ----
# territorio × a.s. × gestione × tipo di scuola × utenza (diurno / serale / carcere)
iscritti_tipo_utenza <- f_somma_territori(iscritti_indirizzo_er,
                                          c("anno_inizio", "gestione", "tipo_scuola", "utenza"))
iscritti_tipo_utenza

# 3. Adulti che tornano a scuola (seconda chance) nei dati MIM -------------
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

# 4. Salva nel proprio output/ (rds + csv, nome file = oggetto) ------------
lista_out <- list(
  rientro_trend_pr = rientro_trend_pr,
  rientro_incidenza_prov_er = rientro_incidenza_prov_er,
  rientro_profilo_pr = rientro_profilo_pr,
  rientro_sedi_pr = rientro_sedi_pr,
  iscritti_tipo_scuola = iscritti_tipo_scuola,
  iscritti_indirizzi = iscritti_indirizzi,
  iscritti_tipo_utenza = iscritti_tipo_utenza
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
# riscontro con la Tab. 5 del Report giovani ER 2026 (statali, 2024/25):
# licei 86.363, tecnici 69.580, professionali 41.436, IeFP 556, totale 197.935
iscritti_tipo_scuola |> filter(gestione == "statale", territorio == "Emilia-Romagna", anno_inizio == 2024) |> count(tipo_scuola, wt = alunni)
# Parma statali 2024/25: licei 9.808, tecnici 7.710, professionali 3.331, IeFP nessuno
iscritti_tipo_scuola |> filter(gestione == "statale", territorio == "Provincia di Parma", anno_inizio == 2024) |> count(tipo_scuola, wt = alunni)

