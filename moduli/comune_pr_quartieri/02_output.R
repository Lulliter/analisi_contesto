# ___________________________________________________________________________
# Modulo: comune_pr_quartieri
# Scopo:  (1) mappa sunto: immobili ACER per quartiere (n. sul quartiere);
#         (2) grafico a barre per quartiere; (3) una mappa
#             per quartiere con i singoli immobili (per un tabset nel sito);
#         (4) mappe per quartiere degli indicatori di popolazione (tabella
#             "1 riga = 1 mappa"); (5) classi di età per quartiere
# Input:  output/*.rds (da 01_dati.R)
# Output: output/mappa_acer_quartieri.rds|.png, plot_acer_quartieri.rds|.png,
#         output/mappa_acer_<quartiere>.rds|.png (13 mappe)
#         output/mappa_pop_<indicatore>.rds|.png, plot_pop_quartieri_eta.rds|.png
#         (csv per i bottoni: acer_immobili.csv, acer_quartieri.csv, pop_quartieri.csv
#         e pop_quartieri_eta.csv, da 01_dati.R)
# NB: punti e conteggi = EDIFICI, non alloggi (la fonte non riporta il n. di alloggi)
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(janitor)
library(dplyr)
library(purrr)
library(ggplot2)
library(ggiraph)
library(ggtext)    # sottotitoli che vanno a capo da soli (element_textbox)
library(ggrepel)   # numeri dei quartieri che non si sovrappongono
library(glue)      # caption con il link al portale
library(sf)

source(here("R", "_parma_colors.R"))
source(here("R", "grafici.R"))   # temi, caption, classi, salvataggio

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "comune_pr_quartieri", "output")
ANNO_DATI <- 2022
ANNO_POP <- 2026
CRS_METRICO <- 7791    # come in 01_dati.R
BUFFER_ZOOM <- 300     # metri di margine attorno al quartiere nelle mappe singole
# rapporto larghezza/altezza del riquadro delle mappe: con proporzioni fisse una
# zona stretta e alta lascerebbe titolo e sottotitolo in una colonna stretta
RAPPORTO_MAPPA <- 1.4
# fonte con l'indirizzo del portale per esteso (testo, non cliccabile)
FONTE_OPENDATA <- "Comune di Parma, https://opendata.comune.parma.it"
CAP <- f_caption_fonte(glue("{FONTE_OPENDATA} (immobili ACER 2022; quartieri vigenti)"))
CAP_POP <- f_caption_fonte(glue("{FONTE_OPENDATA} (popolazione al 1/1/2026; quartieri vigenti)"))
# nota a piè di mappa per gli indicatori sulle famiglie
CAP_FAMIGLIE <- paste0("Nota: famiglia anagrafica = persone coabitanti legate da matrimonio, parentela, affinità, adozione, tutela o vincoli affettivi (anche 1 sola); escluse le convivenze\n", CAP_POP)
CAP_QUARTIERE <- f_caption_fonte(glue("{FONTE_OPENDATA} (immobili ACER 2022; quartieri, strade 2025, torrenti, ferrovie, parchi)"))
# colori dello sfondo delle mappe per quartiere (tenui: il dato sono i punti)
COL_ACQUA <- scales::alpha(blu_lg, 0.35)
COL_PARCHI <- scales::alpha(grn_lg, 0.35)
# colore: blu = temi neutri nella convenzione di _parma_colors.R
COL_ACER <- blu_md
# palette a 4 classi della mappa sunto (DA SCEGLIERE): blu del repo, dal chiaro allo scuro
PAL_ACER <- c("#DCE6EE", blu_lg, blu_md, blu_sc)
# classi fisse della mappa sunto (conteggi da 9 a 148: i quintili darebbero tagli strani)
BREAKS_IMMOBILI <- c(0, 20, 50, 100, Inf)
ETICHETTE_IMMOBILI <- c("fino a 20", "21-50", "51-100", "oltre 100")

# Funzioni locali ----------------------------------------------------------

# allarga il riquadro (bbox) sul lato corto fino al rapporto larghezza/altezza
# voluto, attorno allo stesso centro: la mappa riempie la figura
f_bbox_aspetto <- function(bbox, rapporto = RAPPORTO_MAPPA) {
  larg <- bbox[["xmax"]] - bbox[["xmin"]]
  alt <- bbox[["ymax"]] - bbox[["ymin"]]
  centro_x <- (bbox[["xmax"]] + bbox[["xmin"]]) / 2
  centro_y <- (bbox[["ymax"]] + bbox[["ymin"]]) / 2
  larg_nuova <- max(larg, alt * rapporto)
  alt_nuova <- max(alt, larg / rapporto)
  list(x = centro_x + c(-1, 1) * larg_nuova / 2,
       y = centro_y + c(-1, 1) * alt_nuova / 2)
}

# 1. Carica dati pronti ----------------------------------------------------
acer_immobili_sf <- readRDS(file.path(dir_mod, "acer_immobili_sf.rds"))
quartieri_sf <- readRDS(file.path(dir_mod, "quartieri_sf.rds"))
acer_quartieri <- readRDS(file.path(dir_mod, "acer_quartieri.rds"))
pop_quartieri <- readRDS(file.path(dir_mod, "pop_quartieri.rds"))
pop_quartieri_eta <- readRDS(file.path(dir_mod, "pop_quartieri_eta.rds"))
# sfondo delle mappe per quartiere
strade_sf <- readRDS(file.path(dir_mod, "strade_sf.rds"))
torrenti_sf <- readRDS(file.path(dir_mod, "torrenti_sf.rds"))
ferrovie_sf <- readRDS(file.path(dir_mod, "ferrovie_sf.rds"))
parchi_sf <- readRDS(file.path(dir_mod, "parchi_sf.rds"))

# ordine ufficiale dei quartieri (codice ID_QUART del Comune: dal centro, per
# circoscrizione), lo stesso in tutti i grafici e nelle schede del sito
ORDINE_QUARTIERI <- quartieri_sf |> st_drop_geometry() |> arrange(id_quart) |> pull(quartiere)
# per l'asse y dei grafici a barre: il primo livello sta in basso, quindi si
# rovescia (Parma Centro in alto)
LIVELLI_Y_QUARTIERI <- rev(ORDINE_QUARTIERI)

# 2. Mappa sunto: immobili per quartiere -----------------------------------
# (il riquadro della provincia, patchwork, è stato tolto il 2026-10-08)

## __ mappa_acer_quartieri_prep ----
mappa_acer_quartieri_prep <- quartieri_sf |>
  left_join(acer_quartieri, by = "quartiere") |>
  f_aggiungi_classe("n_immobili", label_fun = NULL,
                    breaks = BREAKS_IMMOBILI, etichette = ETICHETTE_IMMOBILI) |>
  mutate(
    tooltip_quartiere = paste0(quartiere, ": ", n_immobili,
                               " immobili ACER (", pct_immobili, "% del totale)")
  )

# riquadro del comune con le proporzioni della figura
riquadro_comune <- f_bbox_aspetto(st_bbox(quartieri_sf))
# stesso riquadro allargato a destra del 25%: la città si sposta a sinistra e
# la legenda (dentro il riquadro, a destra) non si sovrappone ai quartieri
riquadro_legenda <- riquadro_comune
riquadro_legenda$x[2] <- riquadro_comune$x[2] + 0.25 * diff(riquadro_comune$x)

# punto interno a ogni quartiere per l'etichetta
etichette_quartieri <- mappa_acer_quartieri_prep |>
  st_point_on_surface()

## __ mappa_acer_quartieri ----
mappa_acer_quartieri <- ggplot() +
  geom_sf_interactive(
    data = mappa_acer_quartieri_prep,
    aes(fill = classe_n_immobili, tooltip = tooltip_quartiere, data_id = quartiere),
    color = "white", linewidth = 0.4
  ) +
  # (etichette con il numero tolte il 2026-10-08: il valore sta nel tooltip)
  scale_fill_manual(values = PAL_ACER, drop = FALSE,
                    name = "immobili ACER\n(edifici)") +
  # datum = NA toglie il reticolo delle coordinate
  coord_sf(xlim = riquadro_legenda$x, ylim = riquadro_legenda$y,
           datum = NA, expand = FALSE) +
  labs(title = paste0("Immobili ACER per quartiere (", ANNO_DATI, ")"),
       subtitle = "Indicatore: n. di immobili ACER (edifici, non alloggi) per quartiere; Comune di Parma",
       caption = CAP) +
  f_theme_sito_mappa() +
  # legenda dentro il riquadro, come le mappe della popolazione
  theme(legend.position = "inside",
        legend.position.inside = c(0.98, 0.5),
        legend.justification = c(1, 0.5))

mappa_acer_quartieri

f_salva_plot(mappa_acer_quartieri, "mappa_acer_quartieri",
             dir_out = dir_mod, width = 9, height = 7)

# 3. Barre: immobili per quartiere ----------------------------------------

## __ plot_acer_quartieri_prep ----
plot_acer_quartieri_prep <- acer_quartieri |>
  mutate(quartiere = factor(quartiere, levels = LIVELLI_Y_QUARTIERI),
         tooltip_barra = paste0(quartiere, ": ", n_immobili,
                                " immobili (", pct_immobili, "% del totale)"))

## __ plot_acer_quartieri ----
plot_acer_quartieri <- plot_acer_quartieri_prep |>
  ggplot(aes(x = n_immobili, y = quartiere)) +
  geom_col_interactive(aes(tooltip = tooltip_barra, data_id = quartiere),
                       fill = COL_ACER, width = 0.7) +
  geom_text(aes(label = n_immobili), hjust = -0.2, size = 3.5, color = grey_extra_sc) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = paste0("Immobili ACER per quartiere, Comune di Parma (", ANNO_DATI, ")"),
    subtitle = "Indicatore: n. di immobili ACER (edifici, non alloggi) per quartiere",
    x = NULL, y = NULL,
    caption = CAP
  ) +
  f_theme_sito()

plot_acer_quartieri

f_salva_plot(plot_acer_quartieri, "plot_acer_quartieri",
             dir_out = dir_mod, width = 9, height = 6)

# 4. Una mappa per quartiere (per un tabset nel sito) ---------------------

## __ mappe_acer_quartiere_prep ----
immobili_prep <- acer_immobili_sf |>
  mutate(tooltip_immobile = paste0(
    indirizzo, "\nanno di costruzione: ",
    if_else(is.na(anno_costr), "n.d.", as.character(anno_costr))
  ))

# mappa di un quartiere: zoom sul quartiere (+ margine, con le proporzioni della
# figura). Sfondo: strade (nome nel tooltip, principali piu' spesse), torrenti,
# ferrovia, parchi (nome nel tooltip), confini e nomi degli altri quartieri;
# sopra, i suoi immobili in blu con bordo bianco (punti vicini distinti).
# Lo sfondo e' ritagliato sul riquadro: meno elementi nel widget del sito
f_mappa_quartiere <- function(nome) {
  quartiere_sel <- quartieri_sf |> filter(quartiere == nome)
  etichette_altri <- etichette_quartieri |> filter(quartiere != nome)
  zoom <- f_bbox_aspetto(st_bbox(st_buffer(quartiere_sel, BUFFER_ZOOM)))
  immobili_sel <- immobili_prep |> filter(quartiere == nome)
  riquadro <- st_bbox(c(xmin = zoom$x[1], xmax = zoom$x[2],
                        ymin = zoom$y[1], ymax = zoom$y[2]),
                      crs = st_crs(quartieri_sf))
  strade_zoom <- st_crop(strade_sf, riquadro)
  torrenti_zoom <- st_crop(torrenti_sf, riquadro)
  ferrovie_zoom <- st_crop(ferrovie_sf, riquadro)
  parchi_zoom <- st_crop(parchi_sf, riquadro)

  ggplot() +
    # fondo: quartiere scelto in avorio, gli altri in bianco
    geom_sf(data = quartieri_sf, fill = "white", color = NA) +
    geom_sf(data = quartiere_sel, fill = grey_extrlight, color = NA) +
    # parchi e torrenti
    geom_sf_interactive(data = parchi_zoom, aes(tooltip = parco, data_id = parco),
                        fill = COL_PARCHI, color = NA) +
    geom_sf(data = torrenti_zoom, fill = COL_ACQUA, color = NA) +
    # strade: locali sottili, principali piu' spesse; ferrovia tratteggiata
    geom_sf_interactive(data = filter(strade_zoom, !principale),
                        aes(tooltip = descvia, data_id = descvia),
                        color = grey_md2, linewidth = 0.25) +
    geom_sf_interactive(data = filter(strade_zoom, principale),
                        aes(tooltip = descvia, data_id = descvia),
                        color = grey_md1, linewidth = 0.7) +
    geom_sf(data = ferrovie_zoom, color = grey_sc, linewidth = 0.4, linetype = "dashed") +
    # confini: tutti i quartieri sottili, quello scelto marcato
    geom_sf(data = quartieri_sf, fill = NA, color = grey_md1, linewidth = 0.3) +
    geom_sf(data = quartiere_sel, fill = NA, color = grey_extra_sc, linewidth = 0.6) +
    # nomi dei quartieri vicini come riferimento (quelli fuori riquadro non si vedono)
    geom_sf_text(data = etichette_altri, aes(label = quartiere),
                 size = 3, color = grey_sc, fontface = "italic") +
    geom_sf_interactive(
      data = immobili_sel,
      aes(fill = "1 punto =\n1 edificio ACER", tooltip = tooltip_immobile, data_id = ide),
      shape = 21, color = "white", stroke = 0.3, size = 2
    ) +
    scale_fill_manual(values = COL_ACER, name = NULL) +
    coord_sf(xlim = zoom$x, ylim = zoom$y,
             datum = NA, expand = FALSE) +
    labs(
      title = paste0("Immobili ACER: quartiere ", nome, " (", ANNO_DATI, ")"),
      subtitle = paste0("Indicatore: localizzazione degli immobili ACER (",
                        nrow(immobili_sel), " nel quartiere)"),
      caption = CAP_QUARTIERE
    ) +
    f_theme_sito_mappa()   # legenda a destra
}

# una mappa per quartiere, in ordine ufficiale;
# nomi = nome file (es. mappa_acer_parma_centro)
nomi_mappe <- paste0("mappa_acer_", janitor::make_clean_names(ORDINE_QUARTIERI))

mappe_acer_quartiere <- ORDINE_QUARTIERI |>
  map(f_mappa_quartiere) |>
  set_names(nomi_mappe)

## __ ESEMPIO mappe_acer_quartiere ----
mappe_acer_quartiere$mappa_acer_montanara
mappe_acer_quartiere$mappa_acer_san_leonardo
mappe_acer_quartiere$mappa_acer_lubiana


iwalk(mappe_acer_quartiere, function(p, nome) {
  f_salva_plot(p, nome, dir_out = dir_mod, width = 9, height = 7)
})

# 5. Popolazione per quartiere: mappe degli indicatori ---------------------

# valori del comune (per il sottotitolo) e dei soli quartieri (per le mappe)
pop_comune <- pop_quartieri |> filter(quartiere == "Comune di Parma")
bordo_comune_sf <- quartieri_sf |> summarise()

# valori dei soli quartieri (per i gradini delle scale)
pop_soli_quartieri <- pop_quartieri |> filter(quartiere != "Comune di Parma")

# gradini "tondi" e di ampiezza uguale sul campo di valori di un gruppo di indicatori
f_gradini <- function(vars) pretty(range(unlist(pop_soli_quartieri[vars])), n = 5)

# 1 riga = 1 mappa. Le mappe dello stesso "gruppo" hanno la STESSA scala (gradini
# calcolati sui valori di tutto il gruppo): stesso colore = stessa %.
# legenda = titolo breve della legenda (la base della misura);
# suffisso = "%" per le percentuali, "‰" per i rapporti per 1.000;
# tono = "pieno" o "tenue" (senza i toni più scuri, per valori piccoli in assoluto)
mappe_pop_def <- tibble::tribble(
  ~var,                    ~titolo,                                ~indicatore,                                                         ~legenda,                         ~suffisso, ~gruppo,        ~tono,    ~seq8,             ~caption,
  "pct_bambini_0_14",      "Bambini e ragazzi di 0-14 anni",       "Indicatore: % di 0-14 anni su tot. residenti",                      "% sui residenti",                "%",       "giovani",      "pieno",  seq_factor_green,  CAP_POP,
  "pct_minori_0_17",       "Residenti minorenni",                  "Indicatore: % di 0-17 anni su tot. residenti",                      "% sui residenti",                "%",       "giovani",      "pieno",  seq_factor_green,  CAP_POP,
  "pct_giovani_18_29",     "Giovani adulti di 18-29 anni",         "Indicatore: % di 18-29 anni su tot. residenti (solo residenti, esclusi studenti fuori sede)", "% sui residenti", "%", "giovani", "pieno", seq_factor_green, CAP_POP,
  "pct_stranieri",         "Stranieri residenti",                  "Indicatore: % di stranieri su tot. residenti",                      "% sui residenti",                "%",       "stranieri",    "pieno",  seq_factor_purple, CAP_POP,
  "pct_stranieri_minori",  "Stranieri tra i minori",               "Indicatore: % di stranieri su tot. residenti di 0-17 anni",         "% sui minori",                   "%",       "stranieri",    "pieno",  seq_factor_purple, CAP_POP,
  "pct_anziani_65",        "Residenti di 65 anni e oltre",         "Indicatore: % di 65+ su tot. residenti",                            "% sui residenti",                "%",       "anziani",      "pieno",  seq_factor_red,    CAP_POP,
  "pct_anziani_80",        "Residenti di 80 anni e oltre",         "Indicatore: % di 80+ su tot. residenti",                            "% sui residenti",                "%",       "anziani",      "pieno",  seq_factor_red,    CAP_POP,
  "pct_anziani_soli",      "Anziani che vivono soli",              "Indicatore: % in famiglia di 1 persona su tot. 65+ in famiglia",    "% sugli anziani\nin famiglia",   "%",       "anziani_soli", "pieno",  seq_factor_red,    CAP_FAMIGLIE,
  "famiglie",              "Famiglie anagrafiche",                 "Indicatore: n. di famiglie anagrafiche (stesso stato di famiglia; escluse le convivenze)", "famiglie", "", "famiglie_n", "tenue", seq_factor_blue, CAP_FAMIGLIE,
  "pct_famiglie_1",        "Famiglie di una sola persona",         "Indicatore: % di famiglie di 1 persona su tot. famiglie",           "% sulle famiglie",               "%",       "famiglie_1",   "pieno",  seq_factor_blue,   CAP_FAMIGLIE,
  "pct_famiglie_numerose", "Famiglie numerose",                    "Indicatore: % di famiglie con 5 o più componenti su tot. famiglie", "% sulle famiglie",               "%",       "famiglie",     "tenue",  seq_factor_blue ,  CAP_FAMIGLIE,
  "acer_per_1000",         "Immobili ACER ogni 1.000 residenti",   "Indicatore: immobili ACER (edifici, 2022) ogni 1.000 residenti (‰)", "‰ sui residenti",               "‰",       "acer",         "tenue",  seq_factor_blue,   f_caption_fonte(glue("{FONTE_OPENDATA} (immobili ACER 2022; popolazione al 1/1/2026; quartieri vigenti)")),
  "convivenza_per_1000",   "Residenti in convivenze anagrafiche",  "Indicatore: residenti in convivenza ogni 1.000 residenti (‰)",      "‰ sui residenti",               "‰",       "convivenze",   "tenue",  seq_factor_grey,   paste0("Nota: convivenze anagrafiche = residenze per anziani, comunità, accoglienza, istituti religiosi, carcere\n", CAP_POP)
) |>
  group_by(gruppo) |>
  mutate(gradini = list(f_gradini(var))) |>
  ungroup()

# controllo: i gradini di ogni gruppo
mappe_pop_def |> distinct(gruppo, gradini) |> tidyr::unnest_wider(gradini, names_sep = "_")

# mappa di un indicatore per quartiere, a classi di ampiezza uguale (gradini del
# gruppo); colori interpolati sulla sequenziale (pieno: 2°-8° tono; tenue: 1°-5°);
# valori (nome quartiere + valore) solo nel tooltip, niente etichette in mappa
f_mappa_pop <- function(var, titolo, indicatore, legenda, suffisso, gruppo, tono,
                        seq8, caption, gradini) {
  # conteggi (suffisso vuoto) senza decimali, percentuali con 1 decimale
  lab_val <- function(x) scales::number(x, accuracy = if (suffisso == "") 1 else 0.1,
                                        big.mark = ".", decimal.mark = ",", suffix = suffisso)
  # etichette dei gradini: decimali solo se il passo è sotto 1
  lab_gradino <- scales::label_number(accuracy = if (diff(gradini)[1] < 1) 0.1 else 1,
                                      big.mark = ".", decimal.mark = ",", suffix = suffisso)
  colori <- if (tono == "tenue") seq8[1:5] else seq8[2:8]
  palette <- grDevices::colorRampPalette(colori)(length(gradini) - 1)

  mappa_prep <- quartieri_sf |>
    left_join(pop_quartieri, by = "quartiere") |>
    f_aggiungi_classe(var, lab_gradino, breaks = gradini) |>
    mutate(tooltip = paste0(quartiere, ": ", lab_val(.data[[var]]),
                            # per le famiglie anche dimensione media o n. di famiglie
                            if (var == "famiglie") {
                              paste0(" famiglie (", scales::number(comp_per_famiglia, accuracy = 0.01, decimal.mark = ","), " componenti in media)")
                            } else if (var %in% c("pct_famiglie_1", "pct_famiglie_numerose")) {
                              paste0(" (", scales::number(famiglie, big.mark = "."), " famiglie)")
                            } else ""))

  mappa <- f_disegna_mappa(
    df_comuni = mappa_prep, df_prov = bordo_comune_sf, var = var,
    titolo = paste0(titolo, " per quartiere (", ANNO_POP, ")"),
    sottotitolo = paste0(indicatore, "; Comune di Parma: ", lab_val(pop_comune[[var]])),
    palette5 = palette, caption = caption, nome_legenda = legenda,
    col_tooltip = "tooltip", col_bordi = "white"
  )
  # in legenda anche le classi del gruppo senza quartieri (ggplot2 >= 3.5 le
  # disegna solo con show.legend = TRUE); qui in locale per non toccare R/
  mappa$layers[[1]]$show.legend <- TRUE

  mappa +
    # confini dei quartieri in grigio, visibili anche sui toni chiari
    geom_sf(data = quartieri_sf, fill = NA, color = grey_sc, linewidth = 0.2) +
    # quadratini della legenda con bordo grigio sottile
    guides(fill = guide_legend(override.aes = list(color = grey_md1, linewidth = 0.2))) +
    # legenda dentro il riquadro, nello spazio vuoto a destra della città
    theme(legend.position = "inside",
          legend.position.inside = c(0.98, 0.5),
          legend.justification = c(1, 0.5)) +
    coord_sf(xlim = riquadro_legenda$x, ylim = riquadro_legenda$y,
             datum = NA, expand = FALSE)
}

mappe_pop <- mappe_pop_def |>
  pmap(f_mappa_pop) |>
  set_names(paste0("mappa_pop_", mappe_pop_def$var))

## __ ESEMPIO mappe_pop ----
tabyl(mappe_pop_def$var)
mappe_pop$mappa_pop_pct_stranieri
mappe_pop$mappa_pop_pct_stranieri_minori

mappe_pop$mappa_pop_pct_bambini_0_14
mappe_pop$mappa_pop_pct_minori_0_17
mappe_pop$mappa_pop_pct_giovani_18_29

mappe_pop$mappa_pop_pct_famiglie_numerose

mappe_pop$mappa_pop_pct_anziani_soli
mappe_pop$mappa_pop_pct_anziani_65
mappe_pop$mappa_pop_pct_anziani_80

mappe_pop$mappa_pop_convivenza_per_1000
mappe_pop$mappa_pop_acer_per_1000



iwalk(mappe_pop, function(p, nome) {
  f_salva_plot(p, nome, dir_out = dir_mod, width = 9, height = 7)
})

# 6. Classi di età per quartiere -------------------------------------------

## __ plot_pop_quartieri_eta_prep ----
# colori delle classi: verdi per le età giovani (chiaro = piccoli), grigio per
# gli adulti, rossi per gli anziani (convenzione di _parma_colors.R)
COL_CLASSI_ETA <- c(grDevices::colorRampPalette(c(verde_eta4[1], verde_eta4[4]))(6),
                    grey_md2, seq_factor_red[c(4, 6)])

plot_pop_quartieri_eta_prep <- pop_quartieri_eta |>
  mutate(
    # comune in fondo, quartieri in ordine ufficiale (Parma Centro in alto)
    quartiere = factor(quartiere, levels = c("Comune di Parma", LIVELLI_Y_QUARTIERI)),
    tooltip = paste0(quartiere, ", ", classe_eta, " anni: ",
                     scales::number(pct, accuracy = 0.1, decimal.mark = ","), "%")
  )

## __ plot_pop_quartieri_eta ----
# barre al 100%: la composizione per età di ogni quartiere, 0-2 anni a sinistra
plot_pop_quartieri_eta <- plot_pop_quartieri_eta_prep |>
  ggplot(aes(x = pct, y = quartiere, fill = classe_eta)) +
  geom_col_interactive(aes(tooltip = tooltip, data_id = tooltip, group = classe_eta),
                       position = position_stack(reverse = TRUE),
                       width = 0.75, color = "white", linewidth = 0.2) +
  scale_fill_manual(values = COL_CLASSI_ETA, name = "classe di età (anni)") +
  # a destra un po' di margine, altrimenti l'etichetta "100%" esce dal riquadro
  scale_x_continuous(labels = scales::label_number(suffix = "%"),
                     expand = expansion(mult = c(0, 0.05))) +
  # legenda a destra in colonna: 9 classi in riga non stanno nella larghezza
  # del grafico (nel riquadro Plots di RStudio escono dal bordo)
  guides(fill = guide_legend(ncol = 1)) +
  labs(
    title = paste0("Residenti per classe di età e quartiere (", ANNO_POP, ")"),
    subtitle = "Indicatore: % su tot. residenti del quartiere per classe di età (anni compiuti); Comune di Parma",
    x = NULL, y = NULL, caption = CAP_POP
  ) +
  f_theme_sito() +
  theme(legend.title = element_text(size = rel(0.9)),
        legend.position = "right")

plot_pop_quartieri_eta
f_salva_plot(plot_pop_quartieri_eta, "plot_pop_quartieri_eta",
             dir_out = dir_mod, width = 9, height = 7)

