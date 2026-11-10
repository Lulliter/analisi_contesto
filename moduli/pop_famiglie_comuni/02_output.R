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
#         output/mappa_famiglie_1_pr.png/.rds, mappa_famiglie_numerose_pr.png/.rds (conteggi, dal 2026-11-09)
#         output/famiglie_comuni.csv (tabella unica per i bottoni di scarico del sito)
#         output/famiglie_comuni_ft.rds + .csv (tabella delle % per comune, dal 2026-11-09)
# ___________________________________________________________________________

# Setup ---------------------------------------------------------------------
library(here)
library(dplyr, warn.conflicts = FALSE)
library(purrr)
library(sf)
library(ggplot2)
library(ggiraph)   # geom_sf_interactive (tooltip nelle mappe del sito)
library(flextable) # tabella delle % (dal 2026-11-09)

source(here("R", "_parma_colors.R"))
source(here("R", "grafici.R"))   # f_aggiungi_classe, f_disegna_mappa, f_salva_plot, f_caption_fonte
source(here("R", "formatting.R"))   # f_ft, f_ft_titolo_note

# Parametri -----------------------------------------------------------------
dir_out <- here("moduli", "pop_famiglie_comuni", "output")

famiglie_comuni_sf <- readRDS(file.path(dir_out, "famiglie_comuni_sf.rds"))
famiglie_comuni    <- readRDS(file.path(dir_out, "famiglie_comuni.rds"))

FONTE <- f_caption_fonte(paste0("ISTAT, Censimento permanente della popolazione 2024; ",
                                "confini ISTAT al 01/01/2026"))

# bordo della provincia coerente con la geometria dei comuni
pr_bordo_sf <- famiglie_comuni_sf |> summarise()

# 1) Scelta delle classi (esplorazione, da rileggere all'aggiornamento) ------
# Perché i gradini della tabella "indicatori" (sezione 2) sono quelli: campo dei valori
# nei 44 comuni e quanti comuni cadono in ciascuna classe. Esiti e scelte sotto ogni blocco.
# (spostato dalla coda dello script il 2026-11-09)

## __ Famiglie e quote (2026-11-06) ----
# quanti comuni per classe (gradini scelti il 2026-11-06; attesi famiglie: 2|9|11|15|5|2; 1 persona: 1|21|9|11|2; 5+: 7|12|22|3)
# table(cut(famiglie_comuni_sf$famiglie, c(0, 500, 1000, 2000, 5000, 10000, Inf)))
# table(cut(famiglie_comuni_sf$pct_famiglie_1, c(20, 30, 40, 50, 60, 70)))
# table(cut(famiglie_comuni_sf$pct_famiglie_numerose, c(0, 2, 4, 6, 8)))

## __ Conteggi: famiglie di 1 persona e famiglie numerose (2026-11-09) ----
# Per le mappe di numero al posto di quelle in % (in geogr_abitare le % vanno in tabella);
# famiglie (n.) come riferimento
famiglie_com <- st_drop_geometry(famiglie_comuni_sf)

# min | 25° | mediana | 75° | 90° | max
famiglie_com |>
  summarise(across(c(famiglie, famiglie_1, famiglie_numerose),
                   function(x) paste(round(quantile(x, c(0, .25, .5, .75, .9, 1))), collapse = " | "))) |>
  tidyr::pivot_longer(everything(), names_to = "indicatore", values_to = "campo")
# esito (2026-11-09): famiglie 307 | 1022 | 2109 | 3887 | 5765 | 95174; di 1 persona 184 | 428 | 789 | 1510 | 1993 | 41823;
#   numerose 2 | 22 | 108 | 222 | 292 | 3640

# quanti comuni per classe con dati gradini (come f_prova_soglie in pop_mappe_tematiche/02_output.R)
f_prova_soglie <- function(var, soglie, df = famiglie_com) {
  table(cut(df[[var]], c(-Inf, soglie, Inf), right = FALSE, dig.lab = 6))
}
f_prova_soglie("famiglie", c(500, 1000, 2000, 5000, 10000))   # riferimento: gradini in uso
# famiglie di 1 persona: candidata A (come i conteggi di giovani e stranieri), candidata B (come le famiglie)
f_prova_soglie("famiglie_1", c(200, 500, 1000, 2000, 5000))
f_prova_soglie("famiglie_1", c(500, 1000, 2000, 5000, 10000))
# famiglie numerose: molto più piccole, due candidate
f_prova_soglie("famiglie_numerose", c(10, 25, 50, 100, 250))
f_prova_soglie("famiglie_numerose", c(20, 50, 100, 200, 500))
# esito (2026-11-09), comuni per classe: famiglie (riferimento) 2|9|11|15|5|2;
#   di 1 persona A 200…5000 → 1|14|12|12|4|1 (Parma da sola in alto); B 500…10000 → 15|12|12|4|0|1 (classe vuota)
#   numerose 10…250 → 4|9|2|6|16|7 (squilibrata); 20…500 → 10|5|6|11|10|2
# SCELTA (2026-11-09): di 1 persona A 200…5000 (stessa scala dei conteggi di giovani e stranieri);
#   numerose 20…500

# 2) Indicatori: 1 riga = 1 mappa -------------------------------------------
# gradini tondi e FISSI (campo nei comuni: famiglie 307-95.174; 1 persona 27-64%; 5+ 0,4-7,8%)
# conteggio (famiglie): classe alta aperta ("e oltre"), assorbe il capoluogo; tono tenue come le altre mappe di conteggio
indicatori <- tibble::tribble(
  ~var,                    ~titolo,                                   ~indicatore,                                                          ~gradini,               ~tono,
  "famiglie",              "Famiglie (2024)",                         "Indicatore: n. di famiglie",                                         c(0, 500, 1000, 2000, 5000, 10000, Inf), "tenue",
  "pct_famiglie_1",       "Famiglie di una sola persona (2024)",     "Indicatore: % di famiglie di 1 persona su tot. famiglie",            c(20, 30, 40, 50, 60, 70), "pieno",
  "pct_famiglie_numerose", "Famiglie numerose (2024)",                "Indicatore: % di famiglie con 5 o più componenti su tot. famiglie",  c(0, 2, 4, 6, 8),         "tenue",
  # conteggi (dal 2026-11-09; scelta delle classi in sezione 1)
  "famiglie_1",            "Famiglie di una sola persona (2024)",     "Indicatore: n. di famiglie di 1 persona",                            c(0, 200, 500, 1000, 2000, 5000, Inf), "tenue",
  "famiglie_numerose",     "Famiglie numerose (2024)",                "Indicatore: n. di famiglie con 5 o più componenti",                  c(0, 20, 50, 100, 200, 500, Inf),      "tenue"
)

# 3) Funzione di disegno ----------------------------------------------------
# valori solo nel tooltip, niente etichette in mappa:
# famiglie → n. famiglie e componenti medi; quote → "% di N famiglie"; altri conteggi → solo il numero (senza "famiglie")
f_mappa_famiglie <- function(var, titolo, indicatore, gradini, tono) {
  lab_gradino <- if (startsWith(var, "pct_")) {
    scales::label_number(accuracy = 1, suffix = "%")
  } else {
    scales::label_number(accuracy = 1, big.mark = ".", decimal.mark = ",")
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
    } else if (startsWith(var, "pct_")) {
      # quote: "% di N famiglie" (il totale, non il numeratore; 2026-11-09, prima "% (N famiglie)")
      paste0(COMUNE, ": ",
             scales::number(.data[[var]], accuracy = 0.1, decimal.mark = ",", suffix = "%"),
             " di ", scales::number(famiglie, big.mark = ".", decimal.mark = ","), " famiglie")
    } else {
      # conteggi: solo comune e numero, senza "famiglie" (si confondeva col totale; 2026-11-09)
      paste0(COMUNE, ": ", scales::number(.data[[var]], big.mark = ".", decimal.mark = ","))
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

# 4) Genera, mostra e salva -------------------------------------------------
mappe_famiglie <- indicatori |>
  pmap(f_mappa_famiglie) |>
  set_names(paste0("mappa_", indicatori$var, "_pr"))

# __ mappa_famiglie_pr / mappa_pct_famiglie_1_pr / mappa_pct_famiglie_numerose_pr ----
mappe_famiglie$mappa_famiglie_pr
mappe_famiglie$mappa_pct_famiglie_1_pr
mappe_famiglie$mappa_pct_famiglie_numerose_pr

# __ mappa_famiglie_1_pr / mappa_famiglie_numerose_pr (conteggi; dal 2026-11-09) ----
mappe_famiglie$mappa_famiglie_1_pr
mappe_famiglie$mappa_famiglie_numerose_pr

iwalk(mappe_famiglie, function(m, nm) f_salva_plot(m, nm, dir_out = dir_out))

# 5) Tabella per i bottoni di scarico del sito ------------------------------
readr::write_csv(famiglie_comuni, file.path(dir_out, "famiglie_comuni.csv"))

# 6) Tabella delle % per comune (dal 2026-11-09) -----------------------------
# accompagna le mappe di numero nella pagina: le quote stanno qui, non in mappa
BG_PARMA <- "#FAECD1"   # giallo pallido di Parma, come in pop_titolo_studio e giovani_ingresso_lavoro
# famiglie di una persona oltre questa quota: sfondo rosso pallido della riga (dal 2026-11-10)
SOGLIA_SOLI <- 50
BG_SOLI <- seq_dummy_red[1]   # "#fee0d2", il rosso più chiaro di R/_parma_colors.R

## __ famiglie_comuni_tab_prep ----
# confronti in testa (provincia, regione, Italia), poi i 44 comuni in ordine alfabetico
famiglie_comuni_tab_prep <- famiglie_comuni |>
  mutate(ordine = if_else(tipo_territorio == "confronto", 0, 1),
         famiglie = as.integer(famiglie)) |>
  arrange(ordine, match(cod_territorio, c("ITD52", "ITD5", "IT")), territorio) |>
  # ordine esplicito delle colonne (v. skill formatting-r)
  select(Territorio = territorio, Famiglie = famiglie,
         `% di 1 persona` = pct_famiglie_1, `% numerose (5+)` = pct_famiglie_numerose)

famiglie_comuni_tab_prep

## __ famiglie_comuni_ft ----
famiglie_comuni_ft <- famiglie_comuni_tab_prep |>
  f_ft() |>
  colformat_double(j = c("% di 1 persona", "% numerose (5+)"), digits = 1, suffix = "%") |>
  # confronti in grassetto, provincia di Parma in giallo pallido
  bold(i = ~ Territorio %in% c("Provincia di Parma", "Emilia-Romagna", "Italia"), part = "body") |>
  bg(i = ~ Territorio == "Provincia di Parma", bg = BG_PARMA, part = "body") |>
  # comuni dove le famiglie di una persona sono più della metà
  bg(i = ~ `% di 1 persona` > SOGLIA_SOLI, bg = BG_SOLI, part = "body") |>
  f_ft_titolo_note(
    titolo = "Famiglie di una persona e famiglie numerose per comune (2024)",
    note   = c("Fonte: ISTAT, Censimento permanente della popolazione 2024",
               "% su tot. famiglie del territorio; famiglie numerose = 5 o più componenti",
               "su sfondo rosso i comuni dove le famiglie di una persona sono più della metà")
  )

famiglie_comuni_ft

saveRDS(famiglie_comuni_ft, file.path(dir_out, "famiglie_comuni_ft.rds"))
# dati della tabella per i bottoni di scarico (stesso nome dell'rds, come le altre tabelle del sito)
readr::write_csv(famiglie_comuni_tab_prep, file.path(dir_out, "famiglie_comuni_ft.csv"))
