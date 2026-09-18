# ___________________________________________________________________________
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
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
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
lab_num <- label_number(accuracy = 1, big.mark = ".", decimal.mark = ",")

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
f_mappa_er <- function(var, titolo, indicatore, palette5) {
  f_disegna_mappa(
    df_comuni = pop_mappe_sf,
    df_prov   = er_provincie_sf,
    var          = var,
    titolo       = paste0(titolo, " — comuni ER"),
    palette5     = palette5,
    caption      = FONTE,
    sottotitolo  = indicatore,
    df_evidenzia = parma_prov_sf
  )
}

# versione PR: zoom sulla provincia di Parma (classi ER, dichiarato in sottotitolo)
f_mappa_pr <- function(var, titolo, indicatore, palette5) {
  f_disegna_mappa(
    df_comuni    = pr_comuni_sf,
    df_prov      = pr_bordo_sf,      # bordo coerente con la geometria di dettaglio
    var          = var,
    titolo       = paste0(titolo, " — provincia di Parma"),
    palette5     = palette5,
    caption      = FONTE,
    sottotitolo  = paste0(indicatore, "; classi calcolate sui quintili dell'Emilia-Romagna"),
    df_evidenzia = pr_bordo_sf
  )
}

# (f_salva_mappa: ora in R/)

# --- 3) Definizione degli indicatori -----------------------------------------
# palette a 5 colori: f_pal5 ora in R/

indicatori <- tibble::tribble(
  ~var,              ~titolo,                                            ~indicatore,                                                    ~palette5,
  "quota_stranieri", "Stranieri e apolidi sulla popolazione (2024)",     "Indicatore: % di stranieri e apolidi sulla popolazione residente", f_pal5(seq_factor_purple),
  "dens_km2",        "Densità di popolazione, abitanti per km² (2024)",  "Indicatore: abitanti per km²",                                 f_pal5(seq_factor_blue),
  "quota_65p",       "Popolazione di 65 anni e oltre (2024)",            "Indicatore: % della popolazione con 65 anni e oltre",          f_pal5(seq_factor_red),
  "quota_0_14",      "Popolazione di 0-14 anni (2024)",                  "Indicatore: % della popolazione di 0-14 anni",                 f_pal5(seq_factor_green),
  "quota_minorenni", "Popolazione minorenne, 0-17 anni (2024)",          "Indicatore: % della popolazione di 0-17 anni",                 f_pal5(seq_factor_green)
)

# --- 4) Genera e salva (purrr) ------------------------------------------------
mappe_er <- indicatori |> pmap(f_mappa_er) |> set_names(indicatori$var)
mappe_pr <- indicatori |> pmap(f_mappa_pr) |> set_names(indicatori$var)
mappe_er$quota_stranieri # anteprima di una; tutte: mappe_er
mappe_pr$quota_stranieri # idem: mappe_pr

iwalk(mappe_er, function(m, nm) f_salva_mappa(m, paste0("mappa_", nm, "_er"), dir_out = file.path(dir_mod, "output")))
iwalk(mappe_pr, function(m, nm) f_salva_mappa(m, paste0("mappa_", nm, "_pr"), dir_out = file.path(dir_mod, "output")))

# Verifiche rapide (da eseguire a mano) ------------------------------------
# I numeri del blurb (Messaggio, 2026-09-11): quintili ER, Parma vs ER, comuni PR agli estremi
pop_com <- st_drop_geometry(pop_mappe_sf) |>
  mutate(is_pr = COD_PROV %in% c("34", 34))

# quintili ER (le soglie delle classi delle mappe) per ogni indicatore
pop_com |>
  select(quota_stranieri, dens_km2, quota_65p, quota_0_14, quota_minorenni) |>
  summarise(across(everything(), function(x) list(round(quantile(x, c(.2, .4, .6, .8)), 3)))) |>
  tidyr::pivot_longer(everything(), names_to = "indicatore", values_to = "soglie") |>
  tidyr::unnest_wider(soglie) # attesi (in %): stranieri 7,9|9,9|11,6|13,9; 65+ 22,8|24,4|26,2|30,6; 0-14 9,8|11,3|12,1|12,9; dens 39|100|180|292

# Parma vs ER: quote sul totale dei residenti (non media dei comuni)
pop_com |>
  summarise(pop = sum(pop_tot), sup = sum(sup_km2),
            stranieri = sum(pop_stranieri) / pop, anziani = sum(pop_65p) / pop,
            bambini = sum(pop_0_14) / pop, minorenni = sum(minorenni) / pop, dens = pop / sup,
            .by = is_pr) # attesi PR: 456 mila, stranieri 14,8%, 65+ 23,6%, 0-14 12,4%, 132 ab/km2; ER: 12,7%, 24,9%, 11,8%, 198

# comuni PR per quintile ER (colonne classe_<var> create da f_aggiungi_classe): quanti nel quinto più basso e più alto
pop_com |>
  filter(is_pr) |>
  select(COMUNE, starts_with("classe_")) |>
  tidyr::pivot_longer(starts_with("classe_"), names_to = "indicatore", values_to = "classe") |>
  mutate(quintile = as.integer(classe)) |> # 1 = più basso … 5 = più alto
  count(indicatore, quintile) |>
  tidyr::pivot_wider(names_from = quintile, values_from = n, values_fill = 0) # attesi: dens 18 nel 1° e 1 nel 5°; 65+ 12 nel 1° e 14 nel 5°; stranieri 12 nel 5°

# popolazione PR nei comuni meno densi (1° quintile ER) e nel capoluogo
pop_com |>
  filter(is_pr) |>
  summarise(pop_q1 = sum(pop_tot[dens_km2 <= quantile(pop_com$dens_km2, .2)]),
            pop_parma = pop_tot[COMUNE == "Parma"], pop_tot = sum(pop_tot)) # attesi: 28 mila (6%) e 199 mila (44%) su 456 mila

# comuni PR agli estremi di ogni indicatore (i nomi citati nel blurb)
f_estremi <- function(var, n = 5) {
  pop_com |>
    filter(is_pr) |>
    select(COMUNE, pop_tot, valore = all_of(var)) |>
    arrange(desc(valore)) |>
    (function(d) bind_rows(head(d, n) |> mutate(estremo = "alto"), tail(d, n) |> mutate(estremo = "basso")))()
}
f_estremi("quota_stranieri") # alto: Calestano 20,7; Langhirano 20,6; Parma 17,1 — basso: Albareto 3,3; Monchio 3,9
f_estremi("quota_65p")       # alto: Bore 47; Monchio 44; Tornolo 42; Palanzano 41 — basso: Torrile 18,3; Colorno 20,6
f_estremi("quota_0_14")      # alto: San Secondo 14,4; Langhirano 14,0; Colorno/Fidenza 13,7 — basso: Bore 3,7; Tornolo 3,8
f_estremi("dens_km2")        # alto: Parma 764; Fidenza 289 — basso: Valmozzola 8; Bardi 10

