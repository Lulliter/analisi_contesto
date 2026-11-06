# ___________________________________________________________________________
# Modulo: pop_famiglie_comuni — 02_output.R
# Scopo:  mappe dei 44 comuni della provincia di Parma: % di famiglie di una sola persona
#         e % di famiglie numerose (5 o più componenti); stessi indicatori delle mappe per
#         quartiere del Comune (comune_pr_quartieri), ma fonte e anno diversi
# Input:  output/famiglie_comuni_sf.rds, output/famiglie_comuni.rds   (da 01_dati.R)
#         R/_parma_colors.R, R/grafici.R
# Output: output/mappa_famiglie_pr.png/.rds (n. di famiglie; tooltip con i componenti medi)
#         output/mappa_pct_famiglie_1_pr.png/.rds
#         output/mappa_pct_famiglie_numerose_pr.png/.rds
#         output/famiglie_comuni.csv (tabella unica per i bottoni di scarico del sito)
# ___________________________________________________________________________

# Setup ---------------------------------------------------------------------
library(here)
library(dplyr, warn.conflicts = FALSE)
library(purrr)
library(sf)
library(ggplot2)
library(ggiraph)   # geom_sf_interactive (tooltip nelle mappe del sito)

source(here("R", "_parma_colors.R"))
source(here("R", "grafici.R"))   # f_aggiungi_classe, f_disegna_mappa, f_salva_plot, f_caption_fonte

# Parametri -----------------------------------------------------------------
dir_out <- here("moduli", "pop_famiglie_comuni", "output")

famiglie_comuni_sf <- readRDS(file.path(dir_out, "famiglie_comuni_sf.rds"))
famiglie_comuni    <- readRDS(file.path(dir_out, "famiglie_comuni.rds"))

FONTE <- f_caption_fonte(paste0("ISTAT, Censimento permanente della popolazione 2024; ",
                                "confini ISTAT al 01/01/2026"))

# bordo della provincia coerente con la geometria dei comuni
pr_bordo_sf <- famiglie_comuni_sf |> summarise()

# 1) Indicatori: 1 riga = 1 mappa -------------------------------------------
# gradini tondi e FISSI (campo nei comuni: famiglie 307-95.174; 1 persona 27-64%; 5+ 0,4-7,8%)
# conteggio (famiglie): classe alta aperta ("e oltre"), assorbe il capoluogo; tono tenue come le altre mappe di conteggio
indicatori <- tibble::tribble(
  ~var,                    ~titolo,                                   ~indicatore,                                                          ~gradini,               ~tono,
  "famiglie",              "Famiglie (2024)",                         "Indicatore: n. di famiglie",                                         c(0, 500, 1000, 2000, 5000, 10000, Inf), "tenue",
  "pct_famiglie_1",       "Famiglie di una sola persona (2024)",     "Indicatore: % di famiglie di 1 persona su tot. famiglie",            c(20, 30, 40, 50, 60, 70), "pieno",
  "pct_famiglie_numerose", "Famiglie numerose (2024)",                "Indicatore: % di famiglie con 5 o più componenti su tot. famiglie",  c(0, 2, 4, 6, 8),         "tenue"
)

# 2) Funzione di disegno ----------------------------------------------------
# valori solo nel tooltip, niente etichette in mappa:
# conteggio → n. famiglie e componenti medi; quote → % e n. famiglie
f_mappa_famiglie <- function(var, titolo, indicatore, gradini, tono) {
  lab_gradino <- if (var == "famiglie") {
    scales::label_number(accuracy = 1, big.mark = ".", decimal.mark = ",")
  } else {
    scales::label_number(accuracy = 1, suffix = "%")
  }
  # etichette "a – b"; se l'ultimo gradino è Inf, "a e oltre"
  etichette <- paste(lab_gradino(head(gradini, -1)), lab_gradino(tail(gradini, -1)), sep = " – ")
  if (is.infinite(tail(gradini, 1))) {
    etichette[length(etichette)] <- paste(lab_gradino(gradini[length(gradini) - 1]), "e oltre")
  }
  colori  <- if (tono == "tenue") seq_factor_blue[1:5] else seq_factor_blue[2:8]
  palette <- grDevices::colorRampPalette(colori)(length(gradini) - 1)

  mappa_prep <- famiglie_comuni_sf |>
    f_aggiungi_classe(var, lab_gradino, breaks = gradini, etichette = etichette) |>
    mutate(tooltip = if (var == "famiglie") {
      paste0(COMUNE, ": ", scales::number(famiglie, big.mark = ".", decimal.mark = ","), " famiglie (",
             scales::number(comp_per_famiglia, accuracy = 0.01, decimal.mark = ","), " componenti in media)")
    } else {
      paste0(COMUNE, ": ",
             scales::number(.data[[var]], accuracy = 0.1, decimal.mark = ",", suffix = "%"),
             " (", scales::number(famiglie, big.mark = ".", decimal.mark = ","), " famiglie)")
    })

  f_disegna_mappa(
    df_comuni    = mappa_prep,
    df_prov      = pr_bordo_sf,
    var          = var,
    titolo       = titolo,
    palette5     = palette,
    caption      = FONTE,
    sottotitolo  = indicatore,
    col_tooltip  = "tooltip",
    df_evidenzia = pr_bordo_sf
  )
}

# 3) Genera, mostra e salva -------------------------------------------------
mappe_famiglie <- indicatori |>
  pmap(f_mappa_famiglie) |>
  set_names(paste0("mappa_", indicatori$var, "_pr"))

# __ mappa_famiglie_pr / mappa_pct_famiglie_1_pr / mappa_pct_famiglie_numerose_pr ----
mappe_famiglie$mappa_famiglie_pr
mappe_famiglie$mappa_pct_famiglie_1_pr
mappe_famiglie$mappa_pct_famiglie_numerose_pr

iwalk(mappe_famiglie, function(m, nm) f_salva_plot(m, nm, dir_out = dir_out))

# 4) Tabella per i bottoni di scarico del sito ------------------------------
readr::write_csv(famiglie_comuni, file.path(dir_out, "famiglie_comuni.csv"))

# Verifiche rapide (a mano) -------------------------------------------------
# quanti comuni per classe (gradini scelti il 2026-11-06; attesi famiglie: 2|9|11|15|5|2; 1 persona: 1|21|9|11|2; 5+: 7|12|22|3)
# table(cut(famiglie_comuni_sf$famiglie, c(0, 500, 1000, 2000, 5000, 10000, Inf)))
# table(cut(famiglie_comuni_sf$pct_famiglie_1, c(20, 30, 40, 50, 60, 70)))
# table(cut(famiglie_comuni_sf$pct_famiglie_numerose, c(0, 2, 4, 6, 8)))
