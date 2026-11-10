# ___________________________________________________________________________
# Modulo: pop_famiglie_comuni — 01_dati.R
# Fonte:  ISTAT censimento permanente 2024, "Famiglie per numero di componenti - comuni"
#         (DF_DCSS_FAMIGLIE_TV_1); confini ISTAT al 01/01/2026
# Input:  dati/grezzi/istat_cens_famiglie/Famiglie per numero di componenti - comuni (IT1,DF_DCSS_FAMIGLIE_TV_1,1.0)_codici.csv
#         dati/grezzi/istat_cens_famiglie/Numero di famiglie e popolazione residente in famiglia - comuni (IT1,DF_DCSS_FAM_POP_TV_1,1.0).csv
#         (SDMX-CSV solo codici, scaricati a mano: vedi _metadati.md della cartella)
#         dati/puliti/istat_shp/PR_comuni_web_sf.rds   (44 comuni PR, geometria per il web)
# Output: output/famiglie_comuni.rds    — 44 comuni + Italia, Emilia-Romagna, provincia di Parma
#         output/famiglie_comuni_sf.rds — 44 comuni con geometria (per le mappe)
#         colonne: residenti, pop_in_famiglia, residenti_convivenza, famiglie, comp_per_famiglia,
#         famiglie_1, famiglie_numerose (5+), pct_famiglie_1, pct_famiglie_numerose
# ___________________________________________________________________________

# Setup ---------------------------------------------------------------------
library(here)
library(dplyr, warn.conflicts = FALSE)
library(tidyr)
library(sf)

# Parametri -----------------------------------------------------------------
ANNO_CENS <- "2024"
file_in   <- here("dati", "grezzi", "istat_cens_famiglie",
                  "Famiglie per numero di componenti - comuni (IT1,DF_DCSS_FAMIGLIE_TV_1,1.0)_codici.csv")
file_in_pop <- here("dati", "grezzi", "istat_cens_famiglie",
                    "Numero di famiglie e popolazione residente in famiglia - comuni (IT1,DF_DCSS_FAM_POP_TV_1,1.0).csv")
dir_out  <- here("moduli", "pop_famiglie_comuni", "output")
dir.create(dir_out, showWarnings = FALSE)

# territori di confronto tenuti (le altre province ER restano fuori)
CONFRONTI <- tibble::tribble(
  ~REF_AREA, ~territorio,
  "IT",      "Italia",
  "ITD5",    "Emilia-Romagna",
  "ITD52",   "Provincia di Parma"
)

# 1) Carica input -----------------------------------------------------------
# codici territorio come testo (zero iniziale: "034001")
fam_raw <- readr::read_csv(file_in,
                           col_types = readr::cols(.default = "c", OBS_VALUE = "d"))
fam_pop_raw <- readr::read_csv(file_in_pop,
                               col_types = readr::cols(.default = "c", OBS_VALUE = "d"))

pr_comuni_sf <- readRDS(here("dati", "puliti", "istat_shp", "PR_comuni_web_sf.rds")) |>
  select(PRO_COM_T, COMUNE)

# 2) Da formato lungo a una riga per territorio -----------------------------
fam_wide <- fam_raw |>
  filter(TIME_PERIOD == ANNO_CENS, INDICATOR == "NPHH_AV") |>
  select(REF_AREA, NUM_MEMB, OBS_VALUE) |>
  pivot_wider(names_from = NUM_MEMB, values_from = OBS_VALUE)

# CONTROLLO: la somma delle modalità coincide con il totale (verificato sul grezzo il 2026-11-06)
chk_somma <- fam_wide |>
  filter(rowSums(across(c(N1, N2, N3, N4, N5, N6_GE)), na.rm = TRUE) != TOT)
stopifnot(nrow(chk_somma) == 0)

# residenti, popolazione in famiglia e in convivenza: una riga per territorio
fam_pop_wide <- fam_pop_raw |>
  filter(TIME_PERIOD == ANNO_CENS) |>
  select(REF_AREA, INDICATOR, OBS_VALUE) |>
  pivot_wider(names_from = INDICATOR, values_from = OBS_VALUE)

# CONTROLLO: il numero di famiglie è lo stesso nelle due tavole (verificato il 2026-11-06)
chk_famiglie <- fam_wide |>
  inner_join(fam_pop_wide, by = "REF_AREA") |>
  filter(TOT != NPHH_AV)
stopifnot(nrow(chk_famiglie) == 0, setequal(fam_wide$REF_AREA, fam_pop_wide$REF_AREA))

# 3) Correzioni e indicatori ------------------------------------------------
# N6_GE manca per Albareto (034001) e Monchio delle Corti (034022): con ogni probabilità
# cella a zero omessa da ISTAT (vedi _metadati.md, Insidie) → posta a 0 e segnalata in `nota_6p`
# INST_RESPOP_AV (residenti in convivenza) manca per 4 comuni (034019, 034026, 034038, 034040):
# lì popolazione in famiglia = residenti, quindi zero omesso → posto a 0 e segnalato in `nota_convivenze`
famiglie_comuni <- fam_wide |>
  left_join(fam_pop_wide, by = "REF_AREA") |>
  mutate(
    nota_6p           = if_else(is.na(N6_GE), "famiglie di 6+ componenti assenti nella fonte: poste a 0", NA_character_),
    N6_GE             = replace_na(N6_GE, 0),
    nota_convivenze   = if_else(is.na(INST_RESPOP_AV), "residenti in convivenza assenti nella fonte: posti a 0", NA_character_),
    INST_RESPOP_AV    = replace_na(INST_RESPOP_AV, 0),
    residenti            = RESPOP_AV,
    pop_in_famiglia      = POPHH_AV,
    residenti_convivenza = INST_RESPOP_AV,
    famiglie          = TOT,
    comp_per_famiglia = round(pop_in_famiglia / famiglie, 2),
    famiglie_1        = N1,
    famiglie_numerose = N5 + N6_GE,
    pct_famiglie_1        = round(famiglie_1 / famiglie * 100, 1),
    pct_famiglie_numerose = round(famiglie_numerose / famiglie * 100, 1)
  ) |>
  # nome del territorio: comuni dai confini ISTAT, confronti dalla tabella dei Parametri
  left_join(st_drop_geometry(pr_comuni_sf), by = c("REF_AREA" = "PRO_COM_T")) |>
  left_join(CONFRONTI, by = "REF_AREA") |>
  mutate(tipo_territorio = if_else(is.na(COMUNE), "confronto", "comune"),
         territorio      = coalesce(COMUNE, territorio)) |>
  # solo i 44 comuni PR e i confronti scelti
  filter(!is.na(territorio)) |>
  select(cod_territorio = REF_AREA, territorio, tipo_territorio,
         residenti, pop_in_famiglia, residenti_convivenza, famiglie, comp_per_famiglia,
         famiglie_1, famiglie_numerose, pct_famiglie_1, pct_famiglie_numerose, nota_6p, nota_convivenze)

# CONTROLLO: residenti = in famiglia + in convivenza (dopo aver posto a 0 le convivenze mancanti)
stopifnot(all(famiglie_comuni$residenti == famiglie_comuni$pop_in_famiglia + famiglie_comuni$residenti_convivenza))

# CONTROLLO: tutti e soli i 44 comuni PR, più i 3 confronti
stopifnot(sum(famiglie_comuni$tipo_territorio == "comune") == 44,
          setequal(famiglie_comuni$cod_territorio[famiglie_comuni$tipo_territorio == "comune"], pr_comuni_sf$PRO_COM_T),
          sum(famiglie_comuni$tipo_territorio == "confronto") == nrow(CONFRONTI))

# 4) Join con la geometria (sf a sinistra per tenere la classe sf) ----------
famiglie_comuni_sf <- pr_comuni_sf |>
  left_join(filter(famiglie_comuni, tipo_territorio == "comune"),
            by = c("PRO_COM_T" = "cod_territorio"))

stopifnot(!anyNA(famiglie_comuni_sf$famiglie))

# 5) Salva ------------------------------------------------------------------
saveRDS(famiglie_comuni, file.path(dir_out, "famiglie_comuni.rds"))
saveRDS(famiglie_comuni_sf, file.path(dir_out, "famiglie_comuni_sf.rds"))

# Verifiche rapide (a mano) -------------------------------------------------
# attesi (2026-11-06): % famiglie di 1 persona Italia 38,2; ER 40,3; prov. PR 40,6; Comune di Parma 43,9;
# nei comuni da 27,3 a 63,9. Famiglie 5+: Italia, ER e prov. PR 4,4; Parma 3,8; nei comuni da 0,4 a 7,8
# componenti per famiglia: prov. PR 2,14; Parma 2,06; nei comuni da 1,55 a 2,48
# residenti in convivenza: prov. PR 4.436; Parma 3.086
# famiglie_comuni |> arrange(desc(pct_famiglie_1)) |> print(n = 50)
