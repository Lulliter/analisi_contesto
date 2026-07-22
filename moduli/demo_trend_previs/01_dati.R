# ==========================================================================
# Modulo: demo_trend_previs — 01_dati.R
# Fonte:  ISTAT, previsioni demografiche 2024-2050, SOLO scenario mediano,
#         base 1.1.2024 (demo.istat.it; download 2026-07-18)
# Input:  dati/puliti/istat_previsioni/previs_pop_eta_province.rds
#         dati/puliti/istat_previsioni/previs_indicatori_comuni_er.rds
#         dati/puliti/istat_previsioni/previs_bilancio_comuni_er.rds
#         dati/puliti/istat_shp/lista_COD_PROV_er_vec.R (codici prov. ER)
# Output: output/previs_pop_totale.rds      — pop totale per territorio × anno
#           (9 province ER + aggregati Emilia-Romagna e Italia = somma province)
#         output/previs_piramide.rds        — quote per territorio (PR/ER/IT) ×
#           anno × sesso × classe quinquennale (stile pop_piramide_eta)
#         output/previs_struttura_territori.rds — % e n. assoluti 0-14, 15-64,
#           65+, 80+ e indice di dipendenza anziani, per territorio (province
#           ER + ER + Italia) × anno (calcolati dalle classi di età)
#         output/previs_bilancio_territori.rds — nati, morti, saldo naturale
#           previsti per Parma e ER (somma comuni >= 5.000 ab.!) × anno
#         output/previs_indicatori_comuni_pr.rds — indicatori strutturali ISTAT
#           per i 22 comuni PR >= 5.000 ab. (nomi colonna abbreviati)
# NB: i file ISTAT province NON hanno aggregati: ER e Italia sono somme delle
#     province (verificato: 107 province, nessun totale)
# ==========================================================================

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
pop_eta_prov    <- readRDS(file.path(dir_in, "previs_pop_eta_province.rds"))
indic_comuni    <- readRDS(file.path(dir_in, "previs_indicatori_comuni_er.rds"))
bilancio_comuni <- readRDS(file.path(dir_in, "previs_bilancio_comuni_er.rds"))

stopifnot(all(cod_prov_er_3 %in% pop_eta_prov$codice_provincia))

# 2) Pop per età nei 3 territori di confronto: PR / ER / Italia -------------
# (ER e Italia = somma delle province; tolgo la riga "Tutte le età",
#  i totali si ricalcolano dalle classi)
pop_eta_territori <- bind_rows(
  pop_eta_prov |>
    filter(codice_provincia == COD_PR) |>
    mutate(territorio = "Provincia di Parma"),
  pop_eta_prov |>
    filter(codice_provincia %in% cod_prov_er_3) |>
    mutate(territorio = "Emilia-Romagna"),
  pop_eta_prov |>
    mutate(territorio = "Italia")
) |>
  filter(eta != "Tutte le età") |>
  summarise(maschi = sum(maschi), femmine = sum(femmine), totale = sum(totale),
            .by = c(territorio, anno, eta)) |>
  mutate(
    territorio = factor(territorio,
                        levels = c("Provincia di Parma", "Emilia-Romagna", "Italia")),
    eta = factor(eta, levels = LIVELLI_ETA)
  )

# 3) previs_pop_totale: province ER (nomi) + ER + Italia --------------------
previs_pop_totale <- bind_rows(
  pop_eta_prov |>
    filter(codice_provincia %in% cod_prov_er_3, eta == "Tutte le età") |>
    select(territorio = provincia, anno, maschi, femmine, totale),
  pop_eta_territori |>
    filter(territorio != "Provincia di Parma") |>   # PR è già tra le province
    summarise(maschi = sum(maschi), femmine = sum(femmine), totale = sum(totale),
              .by = c(territorio, anno)) |>
    mutate(territorio = as.character(territorio))
) |>
  arrange(territorio, anno)

# CONTROLLO: il totale ER da somma classi == somma "Tutte le età" delle 9 prov.
chk_er <- previs_pop_totale |>
  filter(territorio == "Emilia-Romagna", anno == 2024) |>
  pull(totale)

stopifnot(chk_er == pop_eta_prov |>
            filter(codice_provincia %in% cod_prov_er_3,
                   eta == "Tutte le età", anno == 2024) |>
            pull(totale) |> sum())

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

# 5) previs_struttura_territori: % grandi classi di età ---------------------
# territori: le 9 province ER singole (nome ISTAT, es. "Parma") + aggregati
# "Emilia-Romagna" e "Italia" — così p04 può mostrare le altre province in
# grigio come p01. Età di inizio classe dai primi 2 caratteri ("00-04" → 0,
# "95+" → 95); 80+ possibile perché le classi quinquennali sono chiuse
pop_eta_struttura <- bind_rows(
  pop_eta_prov |>
    filter(codice_provincia %in% cod_prov_er_3, eta != "Tutte le età") |>
    mutate(territorio = provincia) |>
    select(territorio, anno, eta, totale),
  pop_eta_territori |>
    filter(territorio != "Provincia di Parma") |>   # PR è già tra le province
    mutate(territorio = as.character(territorio), eta = as.character(eta)) |>
    select(territorio, anno, eta, totale)
)

previs_struttura_territori <- pop_eta_struttura |>
  mutate(eta_num = as.integer(substr(eta, 1, 2))) |>
  summarise(
    pop_totale = sum(totale),
    # numeri assoluti (per dimensionare la platea, es. non autosufficienza)
    n0_14   = sum(totale[eta_num <= 10]),
    n15_64  = sum(totale[eta_num >= 15 & eta_num <= 60]),
    n65_piu = sum(totale[eta_num >= 65]),
    n80_piu = sum(totale[eta_num >= 80]),
    .by = c(territorio, anno)
  ) |>
  mutate(
    # quote % e indice di dipendenza anziani (65+ su 100 in età attiva)
    p0_14   = n0_14 / pop_totale * 100,
    p15_64  = n15_64 / pop_totale * 100,
    p65_piu = n65_piu / pop_totale * 100,
    p80_piu = n80_piu / pop_totale * 100,
    ind_dip_anziani = n65_piu / n15_64 * 100
  )

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
  previs_struttura_territori  = previs_struttura_territori,
  previs_indicatori_comuni_pr = previs_indicatori_comuni_pr,
  previs_bilancio_territori   = previs_bilancio_territori
)

purrr::iwalk(salva, function(df, nome) {
  saveRDS(df, file.path(dir_out, paste0(nome, ".rds")))
})
