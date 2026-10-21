# ___________________________________________________________________________
# Ingestione: previsioni demografiche ISTAT 2024-2050 (scenario mediano)
#             → dati/puliti/istat_previsioni/
# Fonte:  dati/grezzi/istat_trend_demog/ (demo.istat.it, download 2026-07-18,
#         vedi _metadati.md) — 5 file .csv.zip, base 1.1.2024
# Input:  PREVISIONI_Componenti_del_bilancio_demografico-Comuni_Emilia-Romagna.csv.zip
#         PREVISIONI_Principali_indicatori_strutturali-Comuni_Emilia-Romagna.csv.zip
#         PREVISIONI_Tassi_generici_del_movimento_demografico-Comuni_Emilia-Romagna.csv.zip
#         Previsioni_comunali_popolazione_per_eta-Comuni_Emilia-Romagna.csv.zip
#         Previsioni_comunali_popolazione_per_eta-Province.csv.zip
# Output: dati/puliti/istat_previsioni/previs_bilancio_comuni_er.rds
#         dati/puliti/istat_previsioni/previs_indicatori_comuni_er.rds
#         dati/puliti/istat_previsioni/previs_tassi_comuni_er.rds
#         dati/puliti/istat_previsioni/previs_pop_eta_comuni_er.rds
#         dati/puliti/istat_previsioni/previs_pop_eta_province.rds  (tutta Italia)
#         dati/puliti/istat_previsioni/previs_pop_eta_territori.rds — province ER
#           (nome ISTAT, es. "Parma") + Emilia-Romagna + Italia (somme delle province)
#           × anno × classe × sesso
#         dati/puliti/istat_previsioni/previs_struttura_territori.rds — stessi
#           territori × anno: n e % 0-14, 15-64, 65+, 80+, indice dipendenza anziani
#         (nome file = nome oggetto R; consumati dai moduli demo_trend_previs e
#          anziani_non_autosuff)
# NB: - SOLO scenario mediano (nei csv non c'è la colonna scenario)
#     - i file comunali coprono solo i comuni con >= 5.000 ab. al 1.1.2024:
#       195 comuni ER, 22 su 44 in provincia di Parma
#     - csv: separatore ";", virgola decimale, 1a riga = titolo (skip = 1);
#       readr legge i .zip direttamente senza scompattarli
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(readr)
library(dplyr)
library(janitor)
library(purrr)
library(stringr)

# Parametri ---------------------------------------------------------------
dir_in  <- here("dati", "grezzi", "istat_trend_demog")
dir_out <- here("dati", "puliti", "istat_previsioni")
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)

# codici provincia ER (vettore trasversale, senza zero iniziale): nei csv
# previsioni i codici sono a 3 cifre → padding
source(here("dati", "puliti", "istat_shp", "lista_COD_PROV_er_vec.R"))   # CODICI_PROV_ER
cod_prov_er_3 <- str_pad(CODICI_PROV_ER, 3, pad = "0")

# nome oggetto/rds = file zip di origine
file_zip <- c(
  previs_bilancio_comuni_er   = "PREVISIONI_Componenti_del_bilancio_demografico-Comuni_Emilia-Romagna.csv.zip",
  previs_indicatori_comuni_er = "PREVISIONI_Principali_indicatori_strutturali-Comuni_Emilia-Romagna.csv.zip",
  previs_tassi_comuni_er      = "PREVISIONI_Tassi_generici_del_movimento_demografico-Comuni_Emilia-Romagna.csv.zip",
  previs_pop_eta_comuni_er    = "Previsioni_comunali_popolazione_per_eta-Comuni_Emilia-Romagna.csv.zip",
  previs_pop_eta_province     = "Previsioni_comunali_popolazione_per_eta-Province.csv.zip"
)

# Funzioni locali ----------------------------------------------------------

# Legge un csv ISTAT previsioni: ";", virgola decimale, titolo in riga 1;
# i codici comune/provincia restano character (leading zero)
f_leggi_previs <- function(zip_file) {
  read_csv2(
    file.path(dir_in, zip_file),
    skip = 1,
    col_types = cols(
      .default           = col_guess(),
      `Codice comune`    = col_character(),
      `Codice provincia` = col_character()
    ),
    locale = locale(encoding = "UTF-8")
  ) |>
    clean_names()
}

# 1. Lettura e pulizia -----------------------------------------------------
lista_previs <- map(file_zip, f_leggi_previs)

# controllo rapido: anni 2024-2050 e nessun NA nei codici
walk(lista_previs, function(df) {
  stopifnot(range(df$anno) == c(2024, 2050))
})

# 2. Aggregati per territorio: province ER + Emilia-Romagna + Italia --------
# (promossi da demo_trend_previs/01_dati.R il 2026-10-20: servono anche ad
#  anziani_non_autosuff). I file province NON hanno aggregati: ER e Italia sono
#  somme delle province; via "Tutte le età", i totali si ricalcolano dalle
#  classi. Età di inizio classe dai primi 2 caratteri ("00-04" → 0, "95+" → 95).
#  Province col nome ISTAT ("Parma"): i moduli che mostrano "Provincia di Parma"
#  rinominano in casa
pop_eta_prov <- lista_previs$previs_pop_eta_province

stopifnot(all(cod_prov_er_3 %in% pop_eta_prov$codice_provincia))

previs_pop_eta_territori <- bind_rows(
  pop_eta_prov |>
    filter(codice_provincia %in% cod_prov_er_3) |>
    mutate(territorio = provincia),
  pop_eta_prov |>
    filter(codice_provincia %in% cod_prov_er_3) |>
    mutate(territorio = "Emilia-Romagna"),
  pop_eta_prov |>
    mutate(territorio = "Italia")
) |>
  filter(eta != "Tutte le età") |>
  summarise(maschi = sum(maschi), femmine = sum(femmine), totale = sum(totale),
            .by = c(territorio, anno, eta)) |>
  mutate(eta_num = as.integer(substr(eta, 1, 2)))

# CONTROLLO: totale ER dalle classi == somma "Tutte le età" delle 9 province
chk_er <- previs_pop_eta_territori |>
  filter(territorio == "Emilia-Romagna", anno == 2024) |>
  pull(totale) |> sum()

stopifnot(chk_er == pop_eta_prov |>
            filter(codice_provincia %in% cod_prov_er_3,
                   eta == "Tutte le età", anno == 2024) |>
            pull(totale) |> sum())

# grandi classi di età (n e %) e indice di dipendenza anziani (65+ su 100 in
# età attiva); 80+ possibile perché le classi quinquennali sono chiuse
previs_struttura_territori <- previs_pop_eta_territori |>
  summarise(
    pop_totale = sum(totale),
    n0_14   = sum(totale[eta_num <= 10]),
    n15_64  = sum(totale[eta_num >= 15 & eta_num <= 60]),
    n65_piu = sum(totale[eta_num >= 65]),
    n80_piu = sum(totale[eta_num >= 80]),
    .by = c(territorio, anno)
  ) |>
  mutate(
    p0_14   = n0_14 / pop_totale * 100,
    p15_64  = n15_64 / pop_totale * 100,
    p65_piu = n65_piu / pop_totale * 100,
    p80_piu = n80_piu / pop_totale * 100,
    ind_dip_anziani = n65_piu / n15_64 * 100
  )

lista_previs <- c(lista_previs, list(
  previs_pop_eta_territori   = previs_pop_eta_territori,
  previs_struttura_territori = previs_struttura_territori
))

# 3. Salva in dati/puliti/istat_previsioni/ --------------------------------
iwalk(lista_previs, function(df, nome) {
  saveRDS(df, file.path(dir_out, paste0(nome, ".rds")))
})
