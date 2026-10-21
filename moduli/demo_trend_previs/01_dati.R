# ___________________________________________________________________________
# Modulo: demo_trend_previs — 01_dati.R
# Fonte:  ISTAT, previsioni demografiche 2024-2050, SOLO scenario mediano,
#         base 1.1.2024 (demo.istat.it; download 2026-07-18)
# Input:  dati/puliti/istat_previsioni/previs_pop_eta_territori.rds (aggregati per
#           territorio, promossi in ingestione/03 il 2026-10-20; prima
#           previs_pop_eta_province.rds sommato qui)
#         dati/puliti/istat_previsioni/previs_indicatori_comuni_er.rds
#         dati/puliti/istat_previsioni/previs_bilancio_comuni_er.rds
#         dati/puliti/istat_shp/lista_COD_PROV_er_vec.R (codici prov. ER)
# Output: output/previs_pop_totale.rds      — pop totale per territorio × anno
#           (9 province ER + aggregati Emilia-Romagna e Italia = somma province)
#         output/previs_piramide.rds        — quote per territorio (PR/ER/IT) ×
#           anno × sesso × classe quinquennale (stile pop_piramide_eta)
#         (previs_struttura_territori: dal 2026-10-20 in dati/puliti/istat_previsioni/)
#         output/previs_bilancio_territori.rds — nati, morti, saldo naturale
#           previsti per Parma e ER (somma comuni >= 5.000 ab.!) × anno
#         output/previs_indicatori_comuni_pr.rds — indicatori strutturali ISTAT
#           per i 22 comuni PR >= 5.000 ab. (nomi colonna abbreviati)
# NB: i file ISTAT province NON hanno aggregati: ER e Italia sono somme delle
#     province (verificato: 107 province, nessun totale)
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr, warn.conflicts = FALSE)
library(tidyr)
library(stringr)

# Parametri ---------------------------------------------------------------
dir_in  <- here("dati", "puliti", "istat_previsioni")
dir_out <- here("moduli", "demo_trend_previs", "output")
dir.create(dir_out, showWarnings = FALSE)

# codici provincia ER: vettore trasversale del repo (CODICI_PROV_ER, senza
# zero iniziale) — nei csv previsioni i codici sono a 3 cifre → padding
source(here("dati", "puliti", "istat_shp", "lista_COD_PROV_er_vec.R"))
cod_prov_er_3 <- str_pad(CODICI_PROV_ER, 3, pad = "0")
COD_PR <- "034"

# ordine delle classi quinquennali (come nei csv ISTAT: 00-04 … 95+)
LIVELLI_ETA <- c(paste0(sprintf("%02d", seq(0, 90, 5)), "-",
                        sprintf("%02d", seq(4, 94, 5))), "95+")

# 1) Carica input ----------------------------------------------------------
pop_eta_terr    <- readRDS(file.path(dir_in, "previs_pop_eta_territori.rds"))
indic_comuni    <- readRDS(file.path(dir_in, "previs_indicatori_comuni_er.rds"))
bilancio_comuni <- readRDS(file.path(dir_in, "previs_bilancio_comuni_er.rds"))

# (controllo sui codici ER spostato in ingestione/03)

# 2) Pop per età nei 3 territori di confronto: PR / ER / Italia -------------
# (ER e Italia = somma delle province, già fatta in ingestione/03)
pop_eta_territori <- pop_eta_terr |>
  filter(territorio %in% c("Parma", "Emilia-Romagna", "Italia")) |>
  # nella piramide la provincia si chiama "Provincia di Parma" (come prima)
  mutate(territorio = if_else(territorio == "Parma", "Provincia di Parma", territorio)) |>
  select(territorio, anno, eta, maschi, femmine, totale) |>
  mutate(
    territorio = factor(territorio,
                        levels = c("Provincia di Parma", "Emilia-Romagna", "Italia")),
    eta = factor(eta, levels = LIVELLI_ETA)
  )

# 3) previs_pop_totale: province ER (nomi) + ER + Italia --------------------
previs_pop_totale <- pop_eta_terr |>
  summarise(maschi = sum(maschi), femmine = sum(femmine), totale = sum(totale),
            .by = c(territorio, anno)) |>
  arrange(territorio, anno)

# (CONTROLLO sul totale ER spostato in ingestione/03)

# 4) previs_piramide: quote per territorio × anno (stile pop_piramide_eta) --
# quota = popolazione della cella / popolazione totale del territorio × anno:
# ogni piramide somma a 1 ed è confrontabile tra anni e territori
previs_piramide <- pop_eta_territori |>
  pivot_longer(c(maschi, femmine), names_to = "sesso", values_to = "popolazione") |>
  mutate(sesso_lbl = factor(if_else(sesso == "maschi", "Maschi", "Femmine"),
                            levels = c("Maschi", "Femmine"))) |>
  mutate(quota = popolazione / sum(popolazione), .by = c(territorio, anno)) |>
  select(territorio, anno, eta, sesso_lbl, popolazione, quota)

# CONTROLLO: le quote di ogni territorio × anno sommano a 1
chk_quote <- previs_piramide |>
  summarise(tot = sum(quota), .by = c(territorio, anno)) |>
  filter(abs(tot - 1) > 1e-9)

stopifnot(nrow(chk_quote) == 0)

# 5) previs_struttura_territori: spostato in ingestione/03_prep_istat_previsioni.R
#    il 2026-10-20 (serve anche ad anziani_non_autosuff)

# 6) previs_indicatori_comuni_pr: comuni PR, nomi brevi ---------------------
previs_indicatori_comuni_pr <- indic_comuni |>
  filter(codice_provincia == COD_PR) |>
  select(anno, codice_comune, comune,
         eta_media = eta_media_della_popolazione_in_anni_e_decimi_di_anno,
         p0_14   = popolazione_0_14_anni_percent,
         p15_64  = popolazione_15_64_anni_percent,
         p65_piu = popolazione_65_anni_e_piu_percent)

# 7) previs_bilancio_territori: nati, morti, saldo naturale -----------------
# ATTENZIONE: somma dei soli comuni >= 5.000 ab. (22 comuni PR, 195 ER) —
# copre gran parte della popolazione ma NON è il totale provinciale/regionale
previs_bilancio_territori <- bind_rows(
  bilancio_comuni |>
    filter(codice_provincia == COD_PR) |>
    mutate(territorio = "Parma"),
  bilancio_comuni |>
    mutate(territorio = "Emilia-Romagna")
) |>
  summarise(nati = sum(nati), morti = sum(morti), .by = c(territorio, anno)) |>
  mutate(saldo_naturale = nati - morti,
         territorio = factor(territorio, levels = c("Parma", "Emilia-Romagna")))

# 8) Salva ------------------------------------------------------------------
salva <- list(
  previs_pop_totale           = previs_pop_totale,
  previs_piramide             = previs_piramide,
  previs_indicatori_comuni_pr = previs_indicatori_comuni_pr,
  previs_bilancio_territori   = previs_bilancio_territori
)

purrr::iwalk(salva, function(df, nome) {
  saveRDS(df, file.path(dir_out, paste0(nome, ".rds")))
})
