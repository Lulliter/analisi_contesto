# ==========================================================================
# Modulo: pop_mappe_tematiche — 02_output.R
# Scopo:  mappe tematiche comunali a quintili, in DUE versioni: ER e solo PR.
#         Indicatori: % stranieri, densità ab/km2, % 65+, % 0-14, % minorenni
#         NB: le classi (quintili) sono SEMPRE calcolate sull'ER, così un comune
#         ha lo stesso colore in entrambe le versioni (PR = zoom, non ricalcolo)
# Input:  output/pop_mappe_sf.rds                          (da 01_dati.R)
#         dati/puliti/istat_shp/ER_provincie_sf.rds        (linee province)
#         R/_parma_colors.R                                (palette)
# Output: output/mappa_<indicatore>_er.png/.rds
#         output/mappa_<indicatore>_pr.png/.rds
# Stile:  come f_make_dummy_map: tema pulito, linee province, Parma in bordeaux
# ==========================================================================

library(here)
library(dplyr, warn.conflicts = FALSE)
library(purrr)
library(sf)
library(ggplot2)
library(scales)

source(here("R", "_parma_colors.R"))
source(here("R", "f_caption_fonte.R"))
# funzioni-mappa promosse a R/ il 2026-07-18 (2° utilizzatore: scuola_iscritti)
source(here("R", "f_aggiungi_classe.R"))
source(here("R", "f_disegna_mappa.R"))
source(here("R", "f_salva_mappa.R"))
source(here("R", "f_pal5.R"))

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "pop_mappe_tematiche")

pop_mappe_sf    <- readRDS(file.path(dir_mod, "output", "pop_mappe_sf.rds"))
er_provincie_sf <- readRDS(here("dati", "puliti", "istat_shp", "ER_provincie_sf.rds"))
parma_prov_sf   <- filter(er_provincie_sf, COD_PROV %in% c("34", 34))

FONTE <- f_caption_fonte(paste0("ISTAT, Censimento permanente della popolazione 2024;\n",
                                "confini ISTAT al 01/01/2026 (versione generalizzata)"))

# --- 1) Classi a quintili calcolate sull'ER ----------------------------------
# (f_aggiungi_classe: ora in R/)

lab_pct <- label_percent(accuracy = 0.1)
lab_num <- label_number(accuracy = 1, big.mark = ".")

pop_mappe_sf <- pop_mappe_sf |>
  f_aggiungi_classe("quota_stranieri", lab_pct) |>
  f_aggiungi_classe("dens_km2",        lab_num) |>
  f_aggiungi_classe("quota_65p",       lab_pct) |>
  f_aggiungi_classe("quota_0_14",      lab_pct) |>
  f_aggiungi_classe("quota_minorenni", lab_pct)

# comuni PR per lo zoom: geometria di DETTAGLIO se disponibile (da 00b),
# altrimenti ripiego sul generalizzato
file_dett <- here("dati", "puliti", "istat_shp", "PR_comuni_dettaglio_sf.rds")
if (file.exists(file_dett)) {
  pr_comuni_sf <- readRDS(file_dett) |>
    select(PRO_COM_T) |>
    left_join(st_drop_geometry(pop_mappe_sf), by = "PRO_COM_T")
} else {
  message("Dettaglio PR non trovato (esegui ingestione/00b): uso il generalizzato")
  pr_comuni_sf <- filter(pop_mappe_sf, COD_PROV %in% c("34", 34))
}

# bordo provincia PR coerente con la geometria usata (unione dei comuni)
pr_bordo_sf <- pr_comuni_sf |> summarise()

# --- 2) Funzioni di disegno ---------------------------------------------------
# (f_disegna_mappa: ora in R/; qui restano solo i wrapper er/pr)

# versione ER: tutti i comuni, tutte le province
f_mappa_er <- function(var, titolo, palette5) {
  f_disegna_mappa(
    df_comuni = pop_mappe_sf,
    df_prov   = er_provincie_sf,
    var          = var,
    titolo       = paste0(titolo, " — comuni ER"),
    palette5     = palette5,
    caption      = FONTE,
    df_evidenzia = parma_prov_sf
  )
}

# versione PR: zoom sulla provincia di Parma (classi ER, dichiarato in sottotitolo)
f_mappa_pr <- function(var, titolo, palette5) {
  f_disegna_mappa(
    df_comuni    = pr_comuni_sf,
    df_prov      = pr_bordo_sf,      # bordo coerente con la geometria di dettaglio
    var          = var,
    titolo       = paste0(titolo, " — provincia di Parma"),
    palette5     = palette5,
    caption      = FONTE,
    sottotitolo  = "Classi calcolate sui quintili dell'Emilia-Romagna",
    df_evidenzia = pr_bordo_sf
  )
}

# (f_salva_mappa: ora in R/)

# --- 3) Definizione degli indicatori -----------------------------------------
# palette a 5 colori: f_pal5 ora in R/

indicatori <- tibble::tribble(
  ~var,              ~titolo,                                            ~palette5,
  "quota_stranieri", "Stranieri e apolidi sulla popolazione (2024)",     f_pal5(seq_factor_purple),
  "dens_km2",        "Densità di popolazione, abitanti per km² (2024)",  f_pal5(seq_factor_blue),
  "quota_65p",       "Popolazione di 65 anni e oltre (2024)",            f_pal5(seq_factor_red),
  "quota_0_14",      "Popolazione di 0-14 anni (2024)",                  f_pal5(seq_factor_green),
  "quota_minorenni", "Popolazione minorenne, 0-17 anni (2024)",          f_pal5(seq_factor_green)
)

# --- 4) Genera e salva (purrr) ------------------------------------------------
mappe_er <- indicatori |> pmap(f_mappa_er) |> set_names(indicatori$var)
mappe_pr <- indicatori |> pmap(f_mappa_pr) |> set_names(indicatori$var)

iwalk(mappe_er, function(m, nm) f_salva_mappa(m, paste0("mappa_", nm, "_er"), dir_out = file.path(dir_mod, "output")))
iwalk(mappe_pr, function(m, nm) f_salva_mappa(m, paste0("mappa_", nm, "_pr"), dir_out = file.path(dir_mod, "output")))
