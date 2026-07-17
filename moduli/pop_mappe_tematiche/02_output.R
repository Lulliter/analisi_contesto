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

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "pop_mappe_tematiche")

pop_mappe_sf    <- readRDS(file.path(dir_mod, "output", "pop_mappe_sf.rds"))
er_provincie_sf <- readRDS(here("dati", "puliti", "istat_shp", "ER_provincie_sf.rds"))
parma_prov_sf   <- filter(er_provincie_sf, COD_PROV %in% c("34", 34))

FONTE <- paste0("Fonte: ISTAT, Censimento permanente della popolazione 2024;\n",
                "confini ISTAT al 01/01/2026 (versione generalizzata)")

# --- 1) Classi a quintili calcolate sull'ER ----------------------------------
f_aggiungi_classe <- function(df_sf, var, label_fun) {
  brks <- quantile(df_sf[[var]], probs = seq(0, 1, 0.2), na.rm = TRUE)
  df_sf |>
    mutate("classe_{var}" := cut(
      .data[[var]], breaks = brks, include.lowest = TRUE,
      labels = paste(label_fun(head(brks, -1)), label_fun(tail(brks, -1)),
                     sep = " – ")))
}

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
# base comune (usata da f_mappa_er e f_mappa_pr)
f_disegna_mappa <- function(df_comuni, df_prov, var, titolo, palette5,
                          sottotitolo = NULL, caption = FONTE,
                          df_evidenzia = parma_prov_sf) {
  ggplot() +
    geom_sf(data = df_comuni, aes(fill = .data[[paste0("classe_", var)]]),
            color = grey_sc, linewidth = 0.1) +
    geom_sf(data = df_prov, fill = NA, color = "#525252", linewidth = 0.2) +
    geom_sf(data = df_evidenzia, fill = NA, color = burg_md, linewidth = 0.6) +
    scale_fill_manual(values = palette5, na.value = grey_m,
                      name = NULL, drop = FALSE) +
    labs(title = titolo, subtitle = sottotitolo, caption = caption) +
    theme_minimal() +
    theme(
      axis.text    = element_blank(),
      axis.title   = element_blank(),
      axis.ticks   = element_blank(),
      panel.grid   = element_blank(),
      plot.caption = element_text(hjust = 0, size = 7, colour = "grey30")
    )
}

# versione ER: tutti i comuni, tutte le province
f_mappa_er <- function(var, titolo, palette5) {
  f_disegna_mappa(
    df_comuni = pop_mappe_sf,
    df_prov   = er_provincie_sf,
    var       = var,
    titolo    = paste0(titolo, " — comuni ER"),
    palette5  = palette5
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
    sottotitolo  = "Classi calcolate sui quintili dell'Emilia-Romagna",
    df_evidenzia = pr_bordo_sf
  )
}

# salvataggio (png per riuso rapido + rds per ricomposizione nel sito)
f_salva_mappa <- function(mappa, nome_file) {
  ggsave(file.path(dir_mod, "output", paste0(nome_file, ".png")),
         mappa, width = 8, height = 6, dpi = 300, bg = "white")
  saveRDS(mappa, file.path(dir_mod, "output", paste0(nome_file, ".rds")))
  message("Salvata: ", nome_file)
}

# --- 3) Definizione degli indicatori -----------------------------------------
# palette a 5 colori estratte dalle sequenziali di _parma_colors.R
f_pal5 <- function(seq8) seq8[c(2, 3, 5, 6, 8)]

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

iwalk(mappe_er, function(m, nm) f_salva_mappa(m, paste0("mappa_", nm, "_er")))
iwalk(mappe_pr, function(m, nm) f_salva_mappa(m, paste0("mappa_", nm, "_pr")))
