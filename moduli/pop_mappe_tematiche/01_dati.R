# ==========================================================================
# Modulo: pop_mappe_tematiche — 01_dati.R
# Fonte:  ISTAT censimento permanente 2024 + confini ISTAT 01/01/2026 (generalizzati)
# Input:  dati/puliti/istat_shp/ER_comuni_sf.rds
#         dati/puliti/istat_shp/ER_provincie_sf.rds
#         dati/puliti/istat_cens/pop_com_er_2024.rds            (classi decennali)
#         dati/puliti/istat_cens/pop_com_er_eta_2024.rds        (singole età)
#         dati/puliti/istat_cens/pop_com_er_minorenni_2024.rds  (0-17 anni)
# Output: output/pop_mappe_sf.rds — sf dei 330 comuni ER con indicatori:
#         pop_tot, quota_stranieri, dens_km2, quota_65p, quota_0_14, quota_minorenni
# ==========================================================================

library(here)
library(dplyr, warn.conflicts = FALSE)
library(sf)
library(tidyr)

# Parametri ---------------------------------------------------------------
ANNO_CENS <- 2024
dir_out   <- here("moduli", "pop_mappe_tematiche", "output")
dir.create(dir_out, showWarnings = FALSE)

# 1) Carica input -----------------------------------------------------------
er_comuni_sf    <- readRDS(here("dati", "puliti", "istat_shp", "ER_comuni_sf.rds"))
er_provincie_sf <- readRDS(here("dati", "puliti", "istat_shp", "ER_provincie_sf.rds"))

pop_cl  <- readRDS(here("dati", "puliti", "istat_cens",
                        paste0("pop_com_er_", ANNO_CENS, ".rds")))       # classi decennali
pop_eta <- readRDS(here("dati", "puliti", "istat_cens",
                        paste0("pop_com_er_eta_", ANNO_CENS, ".rds")))   # singole età
pop_min <- readRDS(here("dati", "puliti", "istat_cens",
                        paste0("pop_com_er_minorenni_", ANNO_CENS, ".rds")))  # 0-17

# 2) Codice del sesso "totale" (robusto: T oppure 9) --------------------------
sessi_presenti <- unique(pop_eta$sesso)
sesso_tot <- dplyr::case_when(
  "T" %in% sessi_presenti ~ "T",
  "9" %in% sessi_presenti ~ "9",
  .default = NA_character_
)
if (is.na(sesso_tot)) {
  stop("Codice sesso 'totale' non riconosciuto. Valori presenti: ",
       paste(sessi_presenti, collapse = ", "))
}

# 3) Indicatori per comune ----------------------------------------------------
# 3a. da singole età: totale, 65+, 0-14
ind_eta <- pop_eta |>
  filter(sesso == sesso_tot, cittadinanza == "TOTAL") |>
  summarise(
    pop_tot  = sum(popolazione),
    pop_65p  = sum(popolazione[eta >= 65]),
    pop_0_14 = sum(popolazione[eta <= 14]),
    .by = PRO_COM_T
  )

# 3b. da classi (riga TOTAL): quota stranieri (FRGAPO = stranieri e apolidi)
ind_stran <- pop_cl |>
  filter(sesso == sesso_tot, classe_eta == "TOTAL",
         cittadinanza %in% c("FRGAPO", "TOTAL")) |>
  pivot_wider(id_cols = PRO_COM_T, names_from = cittadinanza,
              values_from = popolazione) |>
  mutate(quota_stranieri = FRGAPO / TOTAL) |>
  select(PRO_COM_T, pop_stranieri = FRGAPO, quota_stranieri)

# 3c. minorenni (0-17): indicatore dedicato RESPOP_MIN_AV
ind_min <- pop_min |>
  filter(sesso == sesso_tot, cittadinanza == "TOTAL") |>
  select(PRO_COM_T, minorenni)

# 3d. unisci e calcola le quote
ind_com <- ind_eta |>
  left_join(ind_stran, by = "PRO_COM_T") |>
  left_join(ind_min,   by = "PRO_COM_T") |>
  mutate(
    quota_65p       = pop_65p / pop_tot,
    quota_0_14      = pop_0_14 / pop_tot,
    quota_minorenni = minorenni / pop_tot
  )

# CONTROLLO di plausibilità: 0-14 <= minorenni (0-17) per ogni comune
stopifnot(all(ind_com$pop_0_14 <= ind_com$minorenni))

# CONTROLLO: i totali delle due vie (età singole vs classi) devono coincidere
chk_tot <- pop_cl |>
  filter(sesso == sesso_tot, classe_eta == "TOTAL", cittadinanza == "TOTAL") |>
  select(PRO_COM_T, tot_classi = popolazione) |>
  left_join(ind_eta, by = "PRO_COM_T") |>
  filter(tot_classi != pop_tot)
stopifnot(nrow(chk_tot) == 0)

# 4) Join con la geometria (sf a sinistra per tenere la classe sf) ------------
pop_mappe_sf <- er_comuni_sf |>
  left_join(ind_com, by = "PRO_COM_T") |>
  mutate(
    # superficie dalla geometria (km2). NB confini GENERALIZZATI: per mappe ok,
    # NON usare per statistiche ufficiali di superficie (TODO: superficie ISTAT)
    sup_km2  = as.numeric(st_area(geometry)) / 1e6,
    dens_km2 = pop_tot / sup_km2
  )

# CONTROLLO: nessun comune senza dati (o dato senza comune)
stopifnot(!anyNA(pop_mappe_sf$pop_tot))
stopifnot(nrow(pop_mappe_sf) == nrow(er_comuni_sf))

# 5) Salva --------------------------------------------------------------------
saveRDS(pop_mappe_sf, file.path(dir_out, "pop_mappe_sf.rds"))
message("Salvato: output/pop_mappe_sf.rds (", nrow(pop_mappe_sf), " comuni)")
# (le linee province il 02_output le legge direttamente da dati/puliti/istat_shp/)

# Ispezioni utili (a mano):
# summary(select(st_drop_geometry(pop_mappe_sf), pop_tot:dens_km2))
