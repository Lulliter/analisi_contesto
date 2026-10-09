# ___________________________________________________________________________
# Modulo: pop_mappe_tematiche — 02_output.R
# Scopo:  mappe tematiche comunali a classi, in DUE versioni: ER e solo PR.
#         Indicatori: % stranieri, densità ab/km2, % 65+, % 80+, % 0-14, % 18-29, % minorenni
#         NB: classi a gradini FISSI (dal 2026-10-09; prima quintili ER), uguali in
#         ER, PR e quartieri del Comune; solo la densità resta a quintili ER
# Input:  output/pop_mappe_sf.rds                          (da 01_dati.R)
#         dati/puliti/istat_shp/ER_provincie_sf.rds        (linee province)
#         R/_parma_colors.R                                (palette)
# Output: output/mappa_<indicatore>_er.png/.rds
#         output/mappa_<indicatore>_pr.png/.rds
#         output/pop_mappe_comuni.csv (tabella unica per i bottoni di scarico del sito)
# Stile:  come f_make_dummy_map: tema pulito, linee province, Parma in bordeaux
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr, warn.conflicts = FALSE)
library(purrr)
library(sf)
library(ggplot2)
library(ggiraph)   # geom_sf_interactive (tooltip nelle mappe del sito)
library(scales)

source(here("R", "_parma_colors.R"))
source(here("R", "grafici.R"))   # temi, caption, mappe, salvataggio (v. indice in testa al file)
# funzioni-mappa promosse a R/ il 2026-07-18 (2° utilizzatore: scuola_iscritti)

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "pop_mappe_tematiche")

pop_mappe_sf    <- readRDS(file.path(dir_mod, "output", "pop_mappe_sf.rds"))
er_provincie_sf <- readRDS(here("dati", "puliti", "istat_shp", "ER_provincie_sf.rds"))
parma_prov_sf   <- filter(er_provincie_sf, COD_PROV %in% c("34", 34))

FONTE <- f_caption_fonte(paste0("ISTAT, Censimento permanente della popolazione 2024; ",
                                "confini ISTAT al 01/01/2026 (versione generalizzata)"))

# --- 1) Classi -------------------------------------------------------------------
# Gradini tondi e FISSI, uguali per ER, PR e (dove possibile) per i quartieri del Comune:
# stesso colore = stessa %. Classi estreme aperte dove i comuni sono pochi.
# Densità: quintili ER (distribuzione troppo asimmetrica per gradini uguali).
# (f_aggiungi_classe: in R/)
lab_pct <- label_percent(accuracy = 1, decimal.mark = ",")   # soglie intere: niente decimali
lab_num <- label_number(accuracy = 1, big.mark = ".", decimal.mark = ",")

# etichette "a – b"; estremi aperti "meno di b" / "a e oltre"
f_etichette <- function(brks, lab) {
  lo <- head(brks, -1)
  hi <- tail(brks, -1)
  dplyr::case_when(is.infinite(lo) ~ paste("meno di", lab(hi)),
                   is.infinite(hi) ~ paste(lab(lo), "e oltre"),
                   .default = paste(lab(lo), lab(hi), sep = " – "))
}

# soglie (quote): da aggiornare se cambiano i campi di valori (verifiche in coda allo script)
classi_fisse <- list(
  quota_0_14      = c(-Inf, .08, .10, .12, .14, Inf),
  quota_minorenni = c(-Inf, .10, .12, .14, .16, Inf),
  quota_18_29     = c(-Inf, .10, .12, .14, .16, Inf),
  quota_65p       = c(-Inf, .20, .25, .30, .35, .40, Inf),
  quota_80p       = c(-Inf, .075, .10, .125, .15, Inf),
  quota_stranieri = c(-Inf, .05, .10, .15, .20, Inf)
)

pop_mappe_sf <- reduce(names(classi_fisse), function(df, var) {
  f_aggiungi_classe(df, var, lab_pct, breaks = classi_fisse[[var]],
                    etichette = f_etichette(classi_fisse[[var]], lab_pct))
}, .init = pop_mappe_sf) |>
  f_aggiungi_classe("dens_km2", lab_num)   # quintili ER

# testo del tooltip per ogni indicatore ("Comune: valore"), stesso formato delle legende
pop_mappe_sf <- pop_mappe_sf |>
  mutate(tt_quota_stranieri = paste0(COMUNE, ": ", lab_pct(quota_stranieri)),
         tt_dens_km2        = paste0(COMUNE, ": ", lab_num(dens_km2), " ab/km²"),
         tt_quota_65p       = paste0(COMUNE, ": ", lab_pct(quota_65p)),
         tt_quota_80p       = paste0(COMUNE, ": ", lab_pct(quota_80p)),
         tt_quota_18_29     = paste0(COMUNE, ": ", lab_pct(quota_18_29)),
         tt_quota_0_14      = paste0(COMUNE, ": ", lab_pct(quota_0_14)),
         tt_quota_minorenni = paste0(COMUNE, ": ", lab_pct(quota_minorenni)))

# comuni PR per lo zoom: geometria di dettaglio semplificata per il web (da 00b, 2026-10-09;
# prima il dettaglio pieno: ~1 MB a widget), altrimenti ripiego sul generalizzato
file_dett <- here("dati", "puliti", "istat_shp", "PR_comuni_web_sf.rds")
if (file.exists(file_dett)) {
  pr_comuni_sf <- readRDS(file_dett) |>
    select(PRO_COM_T) |>
    left_join(st_drop_geometry(pop_mappe_sf), by = "PRO_COM_T")
} else {
  message("Confini PR web non trovati (esegui ingestione/00b): uso il generalizzato")
  pr_comuni_sf <- filter(pop_mappe_sf, COD_PROV %in% c("34", 34))
}

# bordo provincia PR coerente con la geometria usata (unione dei comuni)
pr_bordo_sf <- pr_comuni_sf |> summarise()

# --- 2) Funzioni di disegno ---------------------------------------------------
# (f_disegna_mappa: ora in R/; qui restano solo i wrapper er/pr)

# palette interpolata sulla sequenziale (2°-8° tono) per il numero di classi dell'indicatore
f_palette_classi <- function(var, seq8) {
  n_classi <- nlevels(pop_mappe_sf[[paste0("classe_", var)]])
  grDevices::colorRampPalette(seq8[2:8])(n_classi)
}

# versione ER: tutti i comuni, tutte le province
f_mappa_er <- function(var, titolo, indicatore, seq8, nota_classi) {
  f_disegna_mappa(
    df_comuni = pop_mappe_sf,
    df_prov   = er_provincie_sf,
    var          = var,
    titolo       = paste0(titolo, " — comuni ER"),
    palette5     = f_palette_classi(var, seq8),
    caption      = FONTE,
    sottotitolo  = paste0(indicatore, nota_classi),
    col_tooltip  = paste0("tt_", var),
    df_evidenzia = parma_prov_sf
  )
}

# versione PR: zoom sulla provincia di Parma (stesse classi dell'ER: le dice la legenda)
f_mappa_pr <- function(var, titolo, indicatore, seq8, nota_classi) {
  f_disegna_mappa(
    df_comuni    = pr_comuni_sf,
    df_prov      = pr_bordo_sf,      # bordo coerente con la geometria di dettaglio
    var          = var,
    titolo       = paste0(titolo, " — provincia di Parma"),
    palette5     = f_palette_classi(var, seq8),
    caption      = FONTE,
    sottotitolo  = paste0(indicatore, nota_classi),
    col_tooltip  = paste0("tt_", var),
    df_evidenzia = pr_bordo_sf
  )
}

# (f_salva_plot: in R/grafici.R)

# --- 3) Definizione degli indicatori -----------------------------------------
# seq8 = sequenziale a 8 toni (R/_parma_colors.R); nota_classi = coda del sottotitolo,
# solo dove le classi non sono i gradini fissi

indicatori <- tibble::tribble(
  ~var,              ~titolo,                                            ~indicatore,                                                        ~seq8,             ~nota_classi,
  "quota_stranieri", "Stranieri e apolidi sulla popolazione (2024)",     "Indicatore: % di stranieri e apolidi sulla popolazione residente", seq_factor_purple, "",
  "dens_km2",        "Densità di popolazione, abitanti per km² (2024)",  "Indicatore: abitanti per km²",                                     seq_factor_blue,   "; classi = quintili dei comuni dell'Emilia-Romagna",
  "quota_65p",       "Popolazione di 65 anni e oltre (2024)",            "Indicatore: % della popolazione con 65 anni e oltre",              seq_factor_red,    "",
  "quota_80p",       "Popolazione di 80 anni e oltre (2024)",            "Indicatore: % della popolazione con 80 anni e oltre",              seq_factor_red,    "",
  "quota_18_29",     "Giovani adulti di 18-29 anni (2024)",              "Indicatore: % della popolazione di 18-29 anni",                    seq_factor_green,  "",
  "quota_0_14",      "Popolazione di 0-14 anni (2024)",                  "Indicatore: % della popolazione di 0-14 anni",                     seq_factor_green,  "",
  "quota_minorenni", "Popolazione minorenne, 0-17 anni (2024)",          "Indicatore: % della popolazione di 0-17 anni",                     seq_factor_green,  ""
)

# --- 4) Genera e salva (purrr) ------------------------------------------------
mappe_er <- indicatori |> pmap(f_mappa_er) |> set_names(indicatori$var)
mappe_pr <- indicatori |> pmap(f_mappa_pr) |> set_names(indicatori$var)
mappe_er$quota_stranieri # anteprima di una; tutte: mappe_er
mappe_pr$quota_stranieri # idem: mappe_pr

iwalk(mappe_er, function(m, nm) f_salva_plot(m, paste0("mappa_", nm, "_er"), dir_out = file.path(dir_mod, "output")))
iwalk(mappe_pr, function(m, nm) f_salva_plot(m, paste0("mappa_", nm, "_pr"), dir_out = file.path(dir_mod, "output")))

# --- 5) Tabella per i bottoni di scarico del sito (una sola per tutte le mappe) --
pop_mappe_comuni <- st_drop_geometry(pop_mappe_sf) |>
  select(PRO_COM_T, COMUNE, COD_PROV, pop_tot, sup_km2, dens_km2,
         quota_stranieri, quota_65p, quota_80p, quota_0_14, quota_18_29, quota_minorenni)
readr::write_csv(pop_mappe_comuni, file.path(dir_mod, "output", "pop_mappe_comuni.csv"))

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
            .by = is_pr) |>
  mutate(across(c(stranieri, anziani, bambini, minorenni), function(x) round(100 * x, 1)), dens = round(dens)) # attesi PR: 456 mila, stranieri 14,8%, 65+ 23,6%, 0-14 12,4%, 132 ab/km2; ER: 12,7%, 24,9%, 11,8%, 198

# comuni PR per classe (colonne classe_<var>; 1 = più bassa): dal 2026-10-09 gradini fissi, non più quintili, tranne la densità
pop_com |>
  filter(is_pr) |>
  select(COMUNE, starts_with("classe_")) |>
  # da fattore a intero PRIMA del pivot: altrimenti pivot_longer fonde i livelli dei 5 fattori
  mutate(across(starts_with("classe_"), as.integer)) |> # 1 = più basso … 5 = più alto
  tidyr::pivot_longer(starts_with("classe_"), names_to = "indicatore", values_to = "quintile") |>
  count(indicatore, quintile) |>
  tidyr::pivot_wider(names_from = quintile, values_from = n, values_fill = 0) # attesi (gradini fissi): 0-14 8|7|6|22|1; 65+ 1|20|9|4|6|4; stranieri 4|11|18|9|2; dens (quintili) 18 nel 1° e 1 nel 5°

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


# Scelta del passo delle classi (2026-10-09): campo dei valori nei 44 comuni PR, in %,
# e quanti comuni cadono in ciascuna classe con un dato passo
# (confrontare con l'analogo blocco in comune_pr_quartieri/02_output.R)
pop_pr_pct <- pop_com |>
  filter(is_pr) |>
  mutate(across(c(quota_stranieri, quota_65p, quota_80p, quota_0_14, quota_18_29, quota_minorenni), function(x) 100 * x))

pop_pr_pct |>
  summarise(across(c(quota_stranieri, quota_65p, quota_80p, quota_0_14, quota_18_29, quota_minorenni),
                   function(x) paste(round(range(x), 1), collapse = " – "))) |>
  tidyr::pivot_longer(everything(), names_to = "indicatore", values_to = "campo")

f_prova_passo <- function(var, passo, df = pop_pr_pct) {
  x    <- df[[var]]
  brks <- seq(floor(min(x) / passo) * passo, ceiling(max(x) / passo) * passo, by = passo)
  table(cut(x, brks, include.lowest = TRUE))
}
f_prova_passo("quota_0_14", 2)
f_prova_passo("quota_0_14", 2.5)
f_prova_passo("quota_65p", 5)
f_prova_passo("quota_stranieri", 5)
f_prova_passo("quota_stranieri", 2.5)
f_prova_passo("quota_80p", 2.5)   # soglie provvisorie in classi_fisse: 7,5 | 10 | 12,5 | 15
f_prova_passo("quota_18_29", 2)   # soglie provvisorie in classi_fisse: 10 | 12 | 14 | 16
