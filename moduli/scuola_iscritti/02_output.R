# ___________________________________________________________________________
# Modulo: scuola_iscritti
# Scopo:  trend iscritti PR (totale e pannelli statale|paritaria); trend dei
#         PLESSI per gestione (infanzia inclusa, dalle anagrafi storiche);
#         % stranieri per provincia ER e per comune PR (top e code basse);
#         3 mappe comunali PR (plessi, alunni, % stranieri) + 2 mappe faceted
#         sulla scuola paritaria (% plessi con infanzia; % iscritti senza)
# Input:  output/*.rds (da 01_dati.R)
# Output: output/plot_*.rds e mappa_*.rds (ggplot; girafe() nella pagina di sito)
#         + .png per riuso rapido (nome file = oggetto)
# NB: gli ISCRITTI non coprono la scuola dell'infanzia (limite fonte MIM);
#     i conteggi di PLESSI dall'anagrafe invece sì
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(stringr)
library(purrr) # pmap/set_names/reduce/iwalk
library(glue)
library(ggplot2)
library(ggiraph)
library(scales) # percent nelle etichette (con scales:: esplicito nei plot salvati)
library(ggtext) # titoli/sottotitoli che vanno a capo da soli (element_textbox)
library(sf)        # per le mappe comunali
library(patchwork) # per impilare i pannelli statale/paritaria (operatore /)
library(readr)

source(here("R", "_parma_colors.R"))
source(here("R", "grafici.R"))   # temi, caption, mappe, salvataggio (v. indice in testa al file)
# promosse a R/ il 2026-09-10 (usate anche da scuola_disabilita)

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "scuola_iscritti", "output")

CAP <- f_caption_fonte("MIM, Portale unico dei dati della scuola (no scuola dell'infanzia)")
# per i grafici che uniscono MIM (primaria-secondarie) e ISTAT (infanzia), dal 2026-10-15
CAP_ISCR <- f_caption_fonte("MIM, Portale unico dei dati della scuola (primaria e secondarie); ISTAT, IstatData, Scuole (infanzia)")
ORDINI_LIV <- c("SCUOLA INFANZIA", "SCUOLA PRIMARIA", "SCUOLA SECONDARIA I GRADO", "SCUOLA SECONDARIA II GRADO")
ORDINI_LAB <- c("Infanzia", "Primaria", "Secondaria I grado", "Secondaria II grado")
# verdi per le LINEE dei 4 ordini, chiaro = piccoli → scuro = grandi: verde_eta4 parte troppo chiaro
# per una linea su fondo bianco (contrasto 1,7); qui da #6b9f52 (contrasto 3,1) al verde scuro di verde_eta4
VERDI_ORDINI <- setNames(grDevices::colorRampPalette(c("#6b9f52", verde_eta4[4]))(4), ORDINI_LAB)
# per i prodotti basati sull'ANAGRAFE scuole (che l'infanzia la include)
CAP_ANAGRAFE <- f_caption_fonte("MIM, anagrafe scuole (tutti gli ordini, infanzia inclusa)")

ANNO_PRIMO <- 2015  # primo a.s. della serie (2015/16)
ANNO_ULTIMO <- 2024 # a.s. 2024/25, per il grafico dei comuni
TOP_N_COMUNI <- 15
SOGLIA_RIF_STRANIERI <- 0.20 # linea di riferimento nei grafici per comune

PERIODO_AS <- glue("trend a.s. {f_lab_as(ANNO_PRIMO)}-{f_lab_as(ANNO_ULTIMO)}") # usato solo nei titoli dei grafici di trend


# 1. Carica dati pronti ----------------------------------------------------
iscritti_trend_pr <- readRDS(file.path(dir_mod, "iscritti_trend_pr.rds"))
stranieri_trend_prov_er <- readRDS(file.path(dir_mod, "stranieri_trend_prov_er.rds"))
scuola_comuni_pr <- readRDS(file.path(dir_mod, "scuola_comuni_pr.rds"))

# 2. Grafici ---------------------------------------------------------------

# Plot: trend iscritti PR per ordine di scuola (statale + paritaria) ----
# (2026-10-15) con l'infanzia da ISTAT: prep separata, 4 ordini, asse y con tacche sopra il massimo
iscritti_ordine_prep <- iscritti_trend_pr |>
  summarise(alunni = sum(alunni), .by = c(anno_inizio, ordine_scuola)) |>
  mutate(ordine_scuola = factor(ordine_scuola, levels = ORDINI_LIV, labels = ORDINI_LAB))

iscritti_ordine_prep

plot_iscritti_ordine_pr <- iscritti_ordine_prep |>
  ggplot(aes(x = anno_inizio, y = alunni, color = ordine_scuola, group = ordine_scuola)) +
  geom_line_interactive(aes(tooltip = ordine_scuola, data_id = ordine_scuola),
                        linewidth = rel(1.2)) +
  geom_point_interactive(aes(tooltip = alunni), size = 1.6) +
  # (2026-10-15) nome dell'ordine scritto in fondo a ogni linea, al posto della legenda
  geom_text(data = function(df) dplyr::filter(df, anno_inizio == max(anno_inizio)),
            aes(label = ordine_scuola), hjust = -0.08, size = 4, show.legend = FALSE) +
  scale_x_continuous(breaks = ANNO_PRIMO:ANNO_ULTIMO, labels = f_lab_as(ANNO_PRIMO:ANNO_ULTIMO), # etichette a.s. già calcolate (al render f_lab_as non c'è)
                     expand = expansion(mult = c(0.02, 0.25))) +
  f_scale_y_tacche(iscritti_ordine_prep$alunni, passo = 5000) +
  # gradazione unica (verde = giovani): chiaro = piccoli → scuro = grandi
  scale_color_manual(values = VERDI_ORDINI) +
  coord_cartesian(clip = "off") +
  f_theme_sito_trend() +
  theme(legend.position = "none") +
  labs(
    title = str_wrap(glue("Iscritti nelle scuole della provincia di Parma ({PERIODO_AS})"), 55),
    subtitle = "Indicatore: numero di iscritti, statali + paritarie, per ordine di scuola (infanzia inclusa)",
    caption = CAP_ISCR, x = "", y = ""
  )

plot_iscritti_ordine_pr

# Plot: iscritti PR per ordine, statali + paritarie (barre impilate) ----
# (2026-10-15) al posto dei due pannelli statale | paritaria con 4 linee ciascuno (illeggibili):
# un pannello per ordine (2×2), ogni barra un anno, statali in basso e paritarie sopra;
# stessa funzione per iscritti e plessi. La versione precedente è commentata qui sotto.
COL_GESTIONE <- c("Statale" = seq_factor_blue[7], "Paritaria" = seq_factor_orange[6])

f_barre_gestione <- function(dati_prep, anni) {
  dati_prep |>
    ggplot(aes(x = anno_inizio, y = valore, fill = gestione)) +
    geom_col_interactive(aes(tooltip = etichetta, data_id = paste(ordine_scuola, gestione, anno_inizio),
                             group = gestione), width = 0.75) +
    facet_wrap(~ ordine_scuola, ncol = 2, scales = "free_y") +
    scale_x_continuous(breaks = anni, labels = f_lab_as(anni)) +
    # tacche fino a sopra il massimo in ogni pannello (scala libera): f_scale_y_sopra in R/grafici.R
    f_scale_y_sopra() +
    scale_fill_manual(values = COL_GESTIONE, breaks = c("Statale", "Paritaria")) +
    f_theme_sito_trend() +
    theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
          legend.position = "top",
          strip.text = element_text(face = "bold"))
}

iscritti_gestione_prep <- iscritti_trend_pr |>
  summarise(valore = sum(alunni), .by = c(anno_inizio, ordine_scuola, gestione)) |>
  mutate(ordine_scuola = factor(ordine_scuola, levels = ORDINI_LIV, labels = ORDINI_LAB),
         # primo livello = in cima alla barra
         gestione = factor(str_to_sentence(gestione), levels = c("Paritaria", "Statale")),
         etichetta = paste0(ordine_scuola, ", ", tolower(gestione), " ", f_lab_as(anno_inizio), ": ",
                            scales::number(valore, big.mark = ".", decimal.mark = ",")))

iscritti_gestione_prep

# __ plot_iscritti_ordine_gestione_pr ----
plot_iscritti_ordine_gestione_pr <- f_barre_gestione(iscritti_gestione_prep, seq(ANNO_PRIMO, ANNO_ULTIMO, by = 3)) +
  labs(
    title = str_wrap(glue("Iscritti a Parma: statali e paritarie a confronto ({PERIODO_AS})"), 55),
    subtitle = "Indicatore: numero di iscritti per ordine, statali e paritarie (infanzia inclusa); scala dell'asse y diversa per ogni ordine",
    caption = CAP_ISCR, x = "", y = ""
  )

plot_iscritti_ordine_gestione_pr


# ___ versione precedente (fino al 2026-10-15) ___
# # Plot: trend iscritti PR, facet statale | paritaria ----
# # (scale y libere: le paritarie sono ~1/10 delle statali — dichiarato nel sottotitolo)
# # un pannello per gestione, ognuno con la propria scala y e la propria legenda
# # (gradazione chiaro = piccoli → scuro = grandi; blu = statali, arancio = paritarie)
# # (2026-10-15) infanzia inclusa: 4 ordini, palette a 4, passo delle tacche per pannello
# f_pannello_gestione <- function(gest, pal4, passo) {
#   dati_prep <- iscritti_trend_pr |>
#     filter(gestione == gest) |>
#     summarise(alunni = sum(alunni), .by = c(anno_inizio, ordine_scuola)) |>
#     mutate(ordine_scuola = factor(ordine_scuola, levels = ORDINI_LIV, labels = ORDINI_LAB))
#   dati_prep |>
#     ggplot(aes(x = anno_inizio, y = alunni, color = ordine_scuola, group = ordine_scuola)) +
#     geom_line_interactive(aes(tooltip = ordine_scuola, data_id = paste(gest, ordine_scuola)),
#                           linewidth = rel(1.1)) +
#     geom_point_interactive(aes(tooltip = alunni), size = 1.6) + # linea + pallino: standard trend
#     scale_x_continuous(breaks = ANNO_PRIMO:ANNO_ULTIMO, labels = f_lab_as(ANNO_PRIMO:ANNO_ULTIMO)) + # etichette a.s. già calcolate (al render f_lab_as non c'è)
#     f_scale_y_tacche(dati_prep$alunni, passo = passo) +
#     scale_color_manual(values = setNames(pal4, ORDINI_LAB)) +
#     f_theme_sito_trend() +
#     # NB: stesso tipo di elemento del tema (textbox), se no il merge fallisce
#     theme(legend.position = "bottom",
#           plot.subtitle = ggtext::element_textbox_simple(
#             face = "bold", size = rel(0.95), margin = margin(b = 10)
#           )) +
#     labs(subtitle = str_to_sentence(gest), x = "", y = "")
# }
#
# plot_iscritti_ordine_gestione_pr <-
#   # toni dal 5° all'8° delle sequenziali: i primi sono troppo chiari per una linea (2026-10-15)
#   (f_pannello_gestione("statale", seq_factor_blue[5:8], passo = 5000) /
#      f_pannello_gestione("paritaria", seq_factor_orange[5:8], passo = 1000)) +
#   patchwork::plot_annotation(
#     title = str_wrap(glue("Iscritti a Parma: statali e paritarie a confronto ({PERIODO_AS})"), 55),
#     subtitle = "Indicatore: numero di iscritti per ordine (infanzia inclusa); scale dell'asse y diverse tra i pannelli (statali v. paritarie)",
#     caption = CAP_ISCR,
#     theme = f_theme_sito()   # titolo/sottotitolo/caption con le stesse dimensioni degli altri grafici
#   )
#
# plot_iscritti_ordine_gestione_pr

# Plot: trend dei PLESSI, facet statale | paritaria (infanzia inclusa) ----
# Come il grafico degli iscritti per gestione, ma conta i PLESSI in anagrafe:
# fa vedere aperture/chiusure di scuole, e qui l'infanzia C'È (e la serie
# arriva all'a.s. 2026/27, oltre gli iscritti).

## dati
plessi_trend_pr <- readRDS(file.path(dir_mod, "plessi_trend_pr.rds"))

ordini_plessi_lbl <- c("Infanzia", "Primaria", "Secondaria I grado", "Secondaria II grado")

## (2026-10-15) barre impilate 2×2 come gli iscritti (stessa f_barre_gestione); versione precedente commentata sotto
plessi_gestione_prep <- plessi_trend_pr |>
  mutate(valore = n_plessi,
         ordine_scuola = factor(ordine_scuola, levels = ordini_plessi_lbl),
         gestione = factor(str_to_sentence(gestione), levels = c("Paritaria", "Statale")),
         etichetta = paste0(ordine_scuola, ", ", tolower(gestione), " ", f_lab_as(anno_inizio), ": ",
                            valore, " plessi"))

plessi_gestione_prep

# __ plot_plessi_ordine_gestione_pr ----
plot_plessi_ordine_gestione_pr <- f_barre_gestione(
  plessi_gestione_prep, seq(min(plessi_trend_pr$anno_inizio), max(plessi_trend_pr$anno_inizio), by = 3)) +
  labs(
    title = str_wrap("Plessi scolastici a Parma: statali e paritarie (infanzia inclusa)", 55),
    subtitle = "Indicatore: numero di sedi in anagrafe per a.s., statali e paritarie; scala dell'asse y diversa per ogni ordine",
    caption = CAP_ANAGRAFE, x = "", y = ""
  )

plot_plessi_ordine_gestione_pr


# ___ versione precedente (fino al 2026-10-15) ___
# ## un pannello per gestione (stesso schema del grafico iscritti, ma 4 ordini)
# f_pannello_plessi <- function(gest, pal4) {
#   df <- plessi_trend_pr |>
#     filter(gestione == gest) |>
#     mutate(ordine_scuola = factor(ordine_scuola, levels = ordini_plessi_lbl))
#
#   anni <- seq(min(df$anno_inizio), max(df$anno_inizio)) # fino al 2026/27 (anagrafi)
#
#   df |>
#     ggplot(aes(x = anno_inizio, y = n_plessi,
#                color = ordine_scuola, group = ordine_scuola)) +
#     geom_line_interactive(aes(tooltip = ordine_scuola, data_id = paste(gest, ordine_scuola)),
#                           linewidth = rel(1.1)) +
#     geom_point_interactive(aes(tooltip = n_plessi), size = 1.6) +
#     scale_x_continuous(breaks = anni, labels = f_lab_as(anni)) +
#     scale_color_manual(values = c(
#       "Infanzia"            = pal4[1],
#       "Primaria"            = pal4[2],
#       "Secondaria I grado"  = pal4[3],
#       "Secondaria II grado" = pal4[4]
#     )) +
#     f_theme_sito_trend() +
#     theme(legend.position = "bottom", # come i pannelli iscritti
#           plot.subtitle = ggtext::element_textbox_simple(
#             face = "bold", size = rel(0.95), margin = margin(b = 10)
#           )) +
#     labs(subtitle = str_to_sentence(gest), x = "", y = "")
# }
#
# ## composizione dei due pannelli
# plot_plessi_ordine_gestione_pr <-
#   (f_pannello_plessi("statale", seq_factor_blue[c(2, 4, 6, 8)]) /
#      f_pannello_plessi("paritaria", seq_factor_orange[c(2, 4, 6, 8)])) +
#   patchwork::plot_annotation(
#     title = str_wrap("Plessi scolastici a Parma: statali e paritarie (infanzia inclusa)", 55),
#     subtitle = "Indicatore: numero di sedi in anagrafe per a.s.; scale y diverse tra i pannelli",
#     caption = CAP_ANAGRAFE,
#     theme = f_theme_sito()   # titolo/sottotitolo/caption come gli altri grafici
#   )
#
# plot_plessi_ordine_gestione_pr

# Plot: % alunni stranieri per provincia ER, Parma evidenziata ----
# prep separata dal grafico (convenzione <nome>_prep)
stranieri_prov_prep <- stranieri_trend_prov_er |>
  mutate(
    highlight = provincia %in% c("PARMA", "EMILIA-ROMAGNA"),
    provincia_display = case_when(
      provincia == "PARMA" ~ "Parma",
      provincia == "EMILIA-ROMAGNA" ~ "Emilia-Romagna",
      .default = "Altre province ER"
    ),
    provincia_display = factor(
      provincia_display,
      levels = c("Parma", "Emilia-Romagna", "Altre province ER")
    )
  )

stranieri_prov_prep

plot_stranieri_prov_er <- stranieri_prov_prep |>
  ggplot(aes(x = anno_inizio, y = quota_stranieri,
             color = provincia_display, alpha = highlight, group = provincia)) +
  geom_line_interactive(aes(tooltip = provincia, data_id = provincia),
                        linewidth = rel(0.8)) +
  # pallini piccoli su TUTTE le linee (ereditano l'alpha: sulle grigie
  # restano tenui); su Parma/ER si sovrappongono quelli grandi qui sotto
  # geom_point_interactive(aes(tooltip = provincia, data_id = provincia),
  #                        size = 1) +
  geom_line_interactive(
    data = function(df) df |> dplyr::filter(highlight),
    aes(tooltip = provincia, data_id = provincia), linewidth = rel(1.5)
  ) +
  geom_point_interactive(
    data = function(df) df |> dplyr::filter(highlight),
    aes(tooltip = scales::percent(quota_stranieri, accuracy = 0.1)), size = 1.8
  ) +
  scale_x_continuous(breaks = ANNO_PRIMO:ANNO_ULTIMO, labels = f_lab_as(ANNO_PRIMO:ANNO_ULTIMO)) + # etichette a.s. già calcolate (al render f_lab_as non c'è)
  f_scale_y_tacche(stranieri_prov_prep$quota_stranieri, passo = 0.05,
                   labels = function(x) scales::percent(x, accuracy = 1)) +
  scale_alpha_manual(values = c(0.35, 1), guide = "none") +
  # come nei trend demografici: Parma gialla, regione verde, altre grigie
  scale_color_manual(values = c(
    "Parma" = ylw_lg,
    "Emilia-Romagna" = grn_md,
    "Altre province ER" = grey_sc
  )) +
  f_theme_sito_trend() +
  labs(
    # titolo corto (quello lungo scappava fuori); il dettaglio sta nel sottotitolo
    title = str_wrap(glue("Alunni stranieri per provincia ({PERIODO_AS})"), 55),
    subtitle = "Indicatore: % di alunni con cittadinanza non italiana sugli iscritti; scuole statali + paritarie (no infanzia)",
    caption = CAP,
    x = "",
    y = "In % degli iscritti della provincia"
  )

plot_stranieri_prov_er

# Plot: % stranieri per ordine di scuola, Parma (infanzia da ISTAT) ----
# (2026-10-15) dall'infanzia alle superiori: le classi più giovani hanno più stranieri?
stranieri_ordine_pr <- readRDS(file.path(dir_mod, "stranieri_ordine_pr.rds"))

stranieri_ordine_prep <- stranieri_ordine_pr |>
  mutate(ordine_scuola = factor(ordine_scuola, levels = ORDINI_LIV, labels = ORDINI_LAB),
         etichetta = paste0(ordine_scuola, " ", f_lab_as(anno_inizio), ": ",
                            scales::percent(quota_stranieri, accuracy = 0.1, decimal.mark = ",")))

stranieri_ordine_prep

# __ plot_stranieri_ordine_pr ----
plot_stranieri_ordine_pr <- stranieri_ordine_prep |>
  ggplot(aes(x = anno_inizio, y = quota_stranieri, color = ordine_scuola, group = ordine_scuola)) +
  geom_line_interactive(aes(tooltip = ordine_scuola, data_id = ordine_scuola), linewidth = rel(1.2)) +
  geom_point_interactive(aes(tooltip = etichetta, data_id = ordine_scuola), size = 1.6) +
  scale_x_continuous(breaks = ANNO_PRIMO:ANNO_ULTIMO, labels = f_lab_as(ANNO_PRIMO:ANNO_ULTIMO)) +
  f_scale_y_tacche(stranieri_ordine_prep$quota_stranieri, passo = 0.05,
                   labels = function(x) scales::percent(x, accuracy = 1)) +
  scale_color_manual(values = VERDI_ORDINI) +
  f_theme_sito_trend() +
  labs(
    title = str_wrap(glue("Alunni stranieri per ordine di scuola, provincia di Parma ({PERIODO_AS})"), 55),
    subtitle = "Indicatore: % di alunni con cittadinanza non italiana sugli iscritti dell'ordine; statali + paritarie",
    caption = CAP_ISCR, x = "", y = ""
  )

plot_stranieri_ordine_pr

# Plot: infanzia per provincia ER, Parma evidenziata (3 indicatori ISTAT) ----
# (2026-10-15) stesso disegno di plot_stranieri_prov_er; serie guidata da tabella, 1 riga = 1 grafico
infanzia_prov_er <- readRDS(file.path(dir_mod, "infanzia_prov_er.rds"))
CAP_INFANZIA <- f_caption_fonte("ISTAT, IstatData, Scuole (scuola dell'infanzia, statali e paritarie)")
ANNI_INFANZIA <- range(infanzia_prov_er$anno_inizio)

GRAFICI_INFANZIA <- tibble::tribble(
  ~nome,                             ~ind,                ~titolo,                                                          ~sottotitolo,                                                                                      ~suffisso, ~passo,
  "plot_infanzia_stranieri_prov_er", "stranieri_pct",     "Bambini stranieri nella scuola dell'infanzia, per provincia",    "Indicatore: % di iscritti con cittadinanza non italiana sul totale degli iscritti all'infanzia", "%", 5,
  "plot_infanzia_pubbliche_prov_er", "pubbliche_pct",     "Iscritti alla scuola dell'infanzia pubblica, per provincia",     "Indicatore: % di iscritti in scuole pubbliche sul totale degli iscritti all'infanzia",         "%", 10
  # tolto il 2026-10-15: la disabilità all'infanzia è già in scuola_disabilita (USR)
  # "plot_infanzia_disabili_prov_er",  "disabili_per_1000", "Bambini con disabilità nella scuola dell'infanzia, per provincia", "Indicatore: iscritti con disabilità ogni 1.000 iscritti all'infanzia", "", 5
)

# prep: Parma e regione evidenziate, etichette del tooltip già pronte
f_prep_infanzia <- function(ind, suffisso) {
  infanzia_prov_er |>
    filter(indicatore == ind) |>
    mutate(
      highlight = cod_territorio %in% c("ITD52", "ITD5"),
      territorio_display = case_when(cod_territorio == "ITD52" ~ "Parma",
                                     cod_territorio == "ITD5"  ~ "Emilia-Romagna",
                                     .default = "Altre province ER") |>
        factor(levels = c("Parma", "Emilia-Romagna", "Altre province ER")),
      etichetta = paste0(territorio, " ", f_lab_as(anno_inizio), ": ",
                         scales::number(valore, accuracy = 0.1, decimal.mark = ","), suffisso)
    )
}

# grafico: linee grigie per le province, Parma e regione evidenziate con i pallini
f_plot_infanzia <- function(dati_prep, titolo, sottotitolo, suffisso, passo) {
  dati_prep |>
    ggplot(aes(x = anno_inizio, y = valore, color = territorio_display, alpha = highlight, group = territorio)) +
    geom_line_interactive(aes(tooltip = territorio, data_id = territorio), linewidth = rel(0.8)) +
    geom_line_interactive(data = function(df) dplyr::filter(df, highlight),
                          aes(tooltip = territorio, data_id = territorio), linewidth = rel(1.5)) +
    geom_point_interactive(data = function(df) dplyr::filter(df, highlight),
                           aes(tooltip = etichetta, data_id = territorio), size = 1.8) +
    scale_x_continuous(breaks = ANNI_INFANZIA[1]:ANNI_INFANZIA[2], labels = f_lab_as(ANNI_INFANZIA[1]:ANNI_INFANZIA[2])) +
    f_scale_y_tacche(dati_prep$valore, passo = passo,
                     labels = scales::label_number(suffix = suffisso, decimal.mark = ",")) +
    scale_alpha_manual(values = c(0.35, 1), guide = "none") +
    scale_color_manual(values = c("Parma" = ylw_lg, "Emilia-Romagna" = grn_md, "Altre province ER" = grey_sc)) +
    f_theme_sito_trend() +
    labs(title = str_wrap(glue("{titolo} (trend a.s. {f_lab_as(ANNI_INFANZIA[1])}-{f_lab_as(ANNI_INFANZIA[2])})"), 55),
         subtitle = sottotitolo, caption = CAP_INFANZIA, x = "", y = "")
}

# prep + grafici per tutte le righe della tabella
infanzia_prep <- map2(GRAFICI_INFANZIA$ind, GRAFICI_INFANZIA$suffisso, f_prep_infanzia) |>
  set_names(GRAFICI_INFANZIA$nome)
grafici_infanzia <- pmap(list(infanzia_prep, GRAFICI_INFANZIA$titolo, GRAFICI_INFANZIA$sottotitolo,
                              GRAFICI_INFANZIA$suffisso, GRAFICI_INFANZIA$passo),
                         f_plot_infanzia)

# __ grafici_infanzia ----
grafici_infanzia$plot_infanzia_stranieri_prov_er

# Plot: % alunni stranieri per comune PR (ultimo a.s., top N) ----
plot_stranieri_comuni_pr <- scuola_comuni_pr |>
  filter(anno_inizio == ANNO_ULTIMO, alunni >= 300) |>
  slice_max(quota_stranieri, n = TOP_N_COMUNI) |>
  mutate(comune = str_to_title(comune)) |>
  ggplot(aes(x = quota_stranieri, y = reorder(comune, quota_stranieri))) +
  geom_col_interactive(
    aes(tooltip = glue("{comune}: {scales::percent(quota_stranieri, accuracy = 0.1)} di {scales::number(alunni, big.mark = '.', decimal.mark = ',')} alunni"),
        data_id = comune),
    fill = pur_md # viola = stranieri/migrazioni (convenzione palette)
  ) +
  # linea di riferimento (soglia nei Parametri)
  geom_vline(xintercept = SOGLIA_RIF_STRANIERI, color = ylw_md,
             linetype = "dashed", linewidth = 0.85) +
  scale_x_continuous(labels = function(x) scales::percent(x, accuracy = 1)) +
  f_theme_sito_trend() +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5)) +
  labs(
    title = str_wrap(glue("Alunni stranieri per comune, provincia di Parma (a.s. {f_lab_as(ANNO_ULTIMO)})"), 55),
    subtitle = glue("Indicatore: % di alunni con cittadinanza non italiana sugli iscritti del comune; primi {TOP_N_COMUNI} comuni con almeno 300 iscritti; statali + paritarie (no infanzia)"),
    caption = CAP,
    x = "Alunni con cittadinanza non italiana, in % degli iscritti nel comune",
    y = ""
  )

plot_stranieri_comuni_pr

# Plot: % alunni stranieri per comune PR — i comuni con MENO stranieri ----
# (corrispettivo del precedente: coda bassa della distribuzione)
plot_stranieri_comuni_pr_min <- scuola_comuni_pr |>
  filter(anno_inizio == ANNO_ULTIMO, alunni >= 300) |>
  slice_min(quota_stranieri, n = TOP_N_COMUNI) |>
  mutate(comune = str_to_title(comune)) |>
  ggplot(aes(x = quota_stranieri, y = reorder(comune, -quota_stranieri))) +
  geom_col_interactive(
    aes(tooltip = glue("{comune}: {scales::percent(quota_stranieri, accuracy = 0.1)} di {scales::number(alunni, big.mark = '.', decimal.mark = ',')} alunni"),
        data_id = comune),
    fill = pur_lg # tinta più chiara della stessa famiglia del grafico "top"
  ) +
  # stessa linea di riferimento del grafico "top", per confronto immediato
  geom_vline(xintercept = SOGLIA_RIF_STRANIERI, color = ylw_md,
             linetype = "dashed", linewidth = 0.85) +
  scale_x_continuous(labels = function(x) scales::percent(x, accuracy = 1)) +
  f_theme_sito_trend() +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5)) +
  labs(
    title = str_wrap(glue("Alunni stranieri per comune: le incidenze più basse (a.s. {f_lab_as(ANNO_ULTIMO)})"), 55),
    subtitle = glue("Indicatore: % di alunni con cittadinanza non italiana sugli iscritti del comune; ultimi {TOP_N_COMUNI} comuni con almeno 300 iscritti; statali + paritarie (no infanzia)"),
    caption = CAP,
    x = "Alunni con cittadinanza non italiana, in % degli iscritti nel comune",
    y = ""
  )

plot_stranieri_comuni_pr_min

# 3. Mappe comunali PR (ultimo a.s.) ---------------------------------------

## Scelta risoluzione sf  ------------------------------------------------
# dettaglio PR semplificato per il web (da ingestione/00b, 2026-10-09; prima il dettaglio pieno)
file_dett <- here("dati", "puliti", "istat_shp", "PR_comuni_web_sf.rds")
# dettaglio PR se disponibile (da ingestione/00b), altrimenti generalizzato
if (file.exists(file_dett)) {
  pr_comuni_sf <- readRDS(file_dett) |> select(PRO_COM_T, COMUNE)
} else {
  message("Confini PR web non trovati (esegui ingestione/00b): uso il generalizzato")
  pr_comuni_sf <- readRDS(here("dati", "puliti", "istat_shp", "ER_comuni_sf.rds")) |>
    filter(COD_PROV %in% c("34", 34)) |>
    select(PRO_COM_T, COMUNE)
}

pr_bordo_sf <- pr_comuni_sf |> summarise()

## 3a. mappa_comuni_prep: geometria + indicatori dell'ultimo a.s. ----------
mappa_comuni_prep <- pr_comuni_sf |>
  left_join(scuola_comuni_pr |> filter(anno_inizio == ANNO_ULTIMO),
            by = c("PRO_COM_T" = "pro_com_t")) |>
  # i comuni senza scuole (es. Bore, Valmozzola) non sono NA: hanno ZERO
  # plessi/alunni. Resta NA solo quota_stranieri (0/0 non calcolabile → grigio)
  mutate(across(c(n_plessi, alunni, alunni_stranieri),
                function(x) coalesce(x, 0L)))

## 3b. Gli indicatori da mappare: 1 riga = 1 mappa --------------------------
lab_pct <- label_percent(accuracy = 0.1)
lab_num <- label_number(accuracy = 1, big.mark = ".", decimal.mark = ",")

### Lista mappe -------------------------------------------------------------
# PER AGGIUNGERE UNA MAPPA basta una riga nella tabella `mappe_indicatori` (3b):
#   var       = colonna di scuola_comuni_pr da mappare (se non esiste ancora,
#               prima creala in 01_dati.R e rilancia 01)
#   titolo    = titolo del grafico (" — provincia di Parma" si aggiunge da solo)
#   palette5  = f_pal5(seq_factor_<colore>) da _parma_colors.R
#   legenda   = titolo della legenda
#   label_fun = formato delle etichette di classe (lab_num numeri, lab_pct %)
# Classi, disegno e salvataggio sono AUTOMATICI (3c); il file esce come
# mappa_<var>_comuni_pr (.rds + .png).

mappe_indicatori <- tibble::tribble(
  ~var,              ~titolo,                                    ~indicatore,                                                                  ~palette5,                 ~legenda,                   ~label_fun,
  "n_plessi",        "Plessi scolastici con iscritti",           "Indicatore: numero di plessi con iscritti nel comune",                       f_pal5(seq_factor_blue),   "N. plessi",                lab_num,
  "alunni",          "Alunni iscritti",                          "Indicatore: numero di alunni iscritti nelle scuole del comune",              f_pal5(seq_factor_green),  "N. alunni",                lab_num,
  "quota_stranieri", "Alunni con cittadinanza non italiana (%)", "Indicatore: % di alunni con cittadinanza non italiana sugli iscritti del comune", f_pal5(seq_factor_purple), "% stranieri\nsu iscritti", lab_pct
)

# classi: di default quintili; per i CONTEGGI (n_plessi) classi fisse
# "parlanti", perche' i quintili collassano (meta' dei comuni ha 1-3 plessi
# e uscivano classi tipo "4 - 76"). NULL = usa i quintili.
mappe_indicatori$breaks_fissi <- list(
  c(-0.5, 0.5, 2.5, 5.5, 10.5, Inf), # n_plessi → 0 | 1-2 | 3-5 | 6-10 | 11+
  NULL,                              # alunni → quintili
  NULL                               # quota_stranieri → quintili
)
mappe_indicatori$etichette <- list(
  c("0", "1-2", "3-5", "6-10", "11+"),
  NULL,
  NULL
)

# nota sulle classi che finisce nel sottotitolo di CIASCUNA mappa
mappe_indicatori$nota_classi <- c(
  "classi fisse (0, 1-2, 3-5, 6-10, 11+)",
  "classi = quintili dei comuni della provincia",
  "classi = quintili; in grigio i comuni senza scuole (quota non calcolabile)"
)

## 3c. Classi, disegno e salvataggio (automatici) ---------------------------
# Usa `R/f_aggiungi_classe-R` e aggiunge a mappa_comuni_prep una colonna 
# classe_<var> (mappe_indicatori) per OGNI riga della
# tabella mappe_indicatori (così una riga nuova nella tabella basta da sola).
#
# COME FUNZIONA reduce: scorre le righe della tabella (i = 1, 2, 3, ...)
# portandosi dietro il dataframe `df`, che parte da .init e a ogni riga
# riceve una colonna classe_<var> in più (con i breaks/etichette della riga,
# se fissati, altrimenti quintili). Con le 3 righe attuali equivale a:
#
#   mappa_comuni_prep |>
#     f_aggiungi_classe("n_plessi", lab_num,
#                       breaks = c(-0.5, 0.5, 2.5, 5.5, 10.5, Inf),
#                       etichette = c("0", "1-2", "3-5", "6-10", "11+")) |>
#     f_aggiungi_classe("alunni",          lab_num) |>   # quintili
#     f_aggiungi_classe("quota_stranieri", lab_pct)      # quintili
#
# (per debuggare un singolo passaggio, eseguire a mano una delle righe qui
# sopra e guardare la colonna classe_<var> che ne esce)
mappa_comuni_prep <- purrr::reduce(
  seq_len(nrow(mappe_indicatori)), # gli indici di riga della tabella
  .init = mappa_comuni_prep,       # punto di partenza dell'accumulatore df
  function(df, i) {
    f_aggiungi_classe(
      df,
      var       = mappe_indicatori$var[i],
      label_fun = mappe_indicatori$label_fun[[i]],
      breaks    = mappe_indicatori$breaks_fissi[[i]],
      etichette = mappe_indicatori$etichette[[i]]
    )
  }
)

# base comune del sottotitolo; la parte sulle classi arriva da nota_classi
SOTTOTITOLO_BASE <- "statali + paritarie (no infanzia)"

f_mappa_scuola_pr <- function(var, titolo, indicatore, palette5, legenda, nota_classi, label_fun) {
  # tooltip hover: "Comune: valore formattato" (n.d. dove il dato manca)
  df_con_tooltip <- mappa_comuni_prep |>
    mutate(tooltip_mappa = paste0(
      str_to_title(COMUNE), ": ",
      if_else(is.na(.data[[var]]), "n.d.", label_fun(.data[[var]]))
    ))

  f_disegna_mappa(
    df_comuni    = df_con_tooltip,
    df_prov      = pr_bordo_sf,
    var          = var,
    # str_wrap: titoli e sottotitoli lunghi andrebbero tagliati nel png
    titolo       = str_wrap(glue("{titolo} — provincia di Parma (a.s. {f_lab_as(ANNO_ULTIMO)})"), width = 55),
    palette5     = palette5,
    caption      = CAP,
    sottotitolo  = glue("{indicatore}; {SOTTOTITOLO_BASE}; {nota_classi}"),
    nome_legenda = legenda,
    col_tooltip  = "tooltip_mappa",
    df_evidenzia = NULL # niente bordo di evidenziazione: la mappa È già solo PR
  )
}

mappe_comuni_pr <- mappe_indicatori |>
  select(var, titolo, indicatore, palette5, legenda, nota_classi, label_fun) |>
  pmap(f_mappa_scuola_pr) |>
  set_names(paste0("mappa_", mappe_indicatori$var, "_comuni_pr"))

mappe_comuni_pr$mappa_quota_stranieri_comuni_pr # anteprima di una; tutte: mappe_comuni_pr
purrr::iwalk(mappe_comuni_pr, function(m, nome) {
  f_salva_plot(m, nome, dir_out = dir_mod)
})

## 3d. Mappa: % di PLESSI paritari per comune e ordine (2 x 2) -------------
# Base = ANAGRAFE scuole (cosi' c'e' anche l'INFANZIA, assente nei dati
# iscritti): quota di plessi paritari sul totale plessi del comune, per i
# 4 ordini. Classi fisse: 0 | fino al 25% | 25-50% | oltre 50%; in grigio i
# comuni senza plessi di quell'ordine.
paritarie_plessi_comuni_pr <- readRDS(file.path(dir_mod, "paritarie_plessi_comuni_pr.rds"))

ordini_lbl <- c("Infanzia", "Primaria", "Secondaria I grado", "Secondaria II grado")

# prep: griglia completa comune × ordine (i comuni senza plessi di un ordine
# devono comparire nel facet, in grigio), poi aggancio dati e geometria
paritarie_plessi_prep <- tidyr::crossing(
  PRO_COM_T = pr_comuni_sf$PRO_COM_T,
  ordine_scuola = ordini_lbl
) |>
  left_join(paritarie_plessi_comuni_pr,
            by = c("PRO_COM_T" = "pro_com_t", "ordine_scuola")) |>
  mutate(ordine_lbl = factor(ordine_scuola, levels = ordini_lbl)) |>
  left_join(pr_comuni_sf, by = "PRO_COM_T") |>
  sf::st_as_sf() |>
  f_aggiungi_classe(
    "quota_plessi_paritari", lab_pct,
    breaks    = c(0, 1e-9, 0.25, 0.50, 1),
    etichette = c("0", "fino al 25%", "25-50%", "oltre 50%")
  ) |>
  mutate(tooltip_mappa = paste0(
    str_to_title(COMUNE), ": ",
    if_else(is.na(quota_plessi_paritari), "nessuna scuola",
            paste0(lab_pct(quota_plessi_paritari),
                   " (", n_plessi_paritari, " su ", n_plessi, " plessi)"))
  ))

mappa_paritarie_plessi_pr <- ggplot() +
  geom_sf_interactive(
    data = paritarie_plessi_prep,
    aes(fill = classe_quota_plessi_paritari,
        tooltip = tooltip_mappa, data_id = paste(ordine_lbl, tooltip_mappa)),
    color = grey_sc, linewidth = 0.1
  ) +
  geom_sf(data = pr_bordo_sf, fill = NA, color = "#525252", linewidth = 0.2) +
  # 2 mappe per riga (2x2): con 3 o 4 in fila diventavano troppo piccole
  facet_wrap(vars(ordine_lbl), ncol = 2) +
  # arancio = paritarie (come nel grafico statali/paritarie)
  scale_fill_manual(values = seq_factor_orange[c(2, 4, 6, 8)], na.value = grey_m,
                    name = "% plessi\nparitari", drop = FALSE,
                    labels = f_lab_na("nessuna scuola")) +
  labs(
    title = str_wrap(glue("Presenza della scuola paritaria per comune e ordine — provincia di Parma (a.s. {f_lab_as(ANNO_ULTIMO)})"), 60),
    subtitle = glue(
      "Indicatore: % di plessi paritari sul totale dei plessi del comune, per ordine; ",
      "anagrafe scuole, infanzia inclusa; classi fisse; ",
      "in grigio i comuni senza plessi dell'ordine"
    ),
    caption = CAP_ANAGRAFE # infanzia inclusa: caption coerente
  ) +
  f_theme_sito_mappa()   # tema mappe del sito (R/grafici.R)

mappa_paritarie_plessi_pr
f_salva_plot(mappa_paritarie_plessi_pr, "mappa_paritarie_plessi_pr",
              dir_out = dir_mod, width = 9, height = 8)

## 3e. Mappa: % di ISCRITTI in paritarie per comune e ordine ----------------
# Complementare alla 3d: qui i pesi veri (alunni), ma SENZA infanzia perché
# gli iscritti MIM non la rilevano. Classi fisse: 0 | fino al 10% | 10-25% |
# oltre 25%; in grigio i comuni senza scuole dell'ordine.
paritarie_comuni_pr <- readRDS(file.path(dir_mod, "paritarie_comuni_pr.rds"))

paritarie_iscritti_prep <- tidyr::crossing(
  PRO_COM_T = pr_comuni_sf$PRO_COM_T,
  ordine_scuola = c("SCUOLA PRIMARIA", "SCUOLA SECONDARIA I GRADO",
                    "SCUOLA SECONDARIA II GRADO")
) |>
  left_join(paritarie_comuni_pr |> filter(anno_inizio == ANNO_ULTIMO),
            by = c("PRO_COM_T" = "pro_com_t", "ordine_scuola")) |>
  mutate(ordine_lbl = factor(
    ordine_scuola,
    levels = c("SCUOLA PRIMARIA", "SCUOLA SECONDARIA I GRADO", "SCUOLA SECONDARIA II GRADO"),
    labels = c("Primaria", "Secondaria I grado", "Secondaria II grado")
  )) |>
  left_join(pr_comuni_sf, by = "PRO_COM_T") |>
  sf::st_as_sf() |>
  f_aggiungi_classe(
    "quota_paritaria", lab_pct,
    breaks    = c(0, 1e-9, 0.10, 0.25, 1),
    etichette = c("0", "fino al 10%", "10-25%", "oltre 25%")
  ) |>
  mutate(tooltip_mappa = paste0(
    str_to_title(COMUNE), ": ",
    if_else(is.na(quota_paritaria), "nessuna scuola",
            paste0(lab_pct(quota_paritaria),
                   " (", alunni_paritaria, " su ", alunni, " iscritti)"))
  ))

mappa_paritarie_iscritti_pr <- ggplot() +
  geom_sf_interactive(
    data = paritarie_iscritti_prep,
    aes(fill = classe_quota_paritaria,
        tooltip = tooltip_mappa, data_id = paste(ordine_lbl, tooltip_mappa)),
    color = grey_sc, linewidth = 0.1
  ) +
  geom_sf(data = pr_bordo_sf, fill = NA, color = "#525252", linewidth = 0.2) +
  # 2 per riga anche qui (la terza va a capo da sola)
  facet_wrap(vars(ordine_lbl), ncol = 2) +
  scale_fill_manual(values = seq_factor_orange[c(2, 4, 6, 8)], na.value = grey_m,
                    name = "% iscritti\nin paritarie", drop = FALSE,
                    labels = f_lab_na("nessuna scuola")) +
  labs(
    title = str_wrap(glue("Iscritti alla scuola paritaria per comune e ordine — provincia di Parma (a.s. {f_lab_as(ANNO_ULTIMO)})"), 60),
    subtitle = glue(
      "Indicatore: % di iscritti in paritarie sul totale del comune, per ordine; ",
      "senza infanzia (non rilevata dai dati iscritti MIM, ",
      "v. mappa dei plessi); classi fisse; in grigio i comuni senza scuole dell'ordine"
    ),
    caption = CAP
  ) +
  f_theme_sito_mappa()   # tema mappe del sito (R/grafici.R)

mappa_paritarie_iscritti_pr
f_salva_plot(mappa_paritarie_iscritti_pr, "mappa_paritarie_iscritti_pr",
              dir_out = dir_mod, width = 9, height = 8)

# 4. Salva i grafici (rds per il sito + png; nome file = oggetto) ----------
lista_plot <- list(
  plot_iscritti_ordine_pr = plot_iscritti_ordine_pr,
  plot_iscritti_ordine_gestione_pr = plot_iscritti_ordine_gestione_pr,
  plot_stranieri_prov_er = plot_stranieri_prov_er,
  plot_stranieri_ordine_pr = plot_stranieri_ordine_pr,
  plot_stranieri_comuni_pr = plot_stranieri_comuni_pr,
  plot_stranieri_comuni_pr_min = plot_stranieri_comuni_pr_min,
  plot_plessi_ordine_gestione_pr = plot_plessi_ordine_gestione_pr
)

# grafici dell'infanzia (ISTAT), 2026-10-15
lista_plot <- c(lista_plot, grafici_infanzia)

purrr::iwalk(lista_plot, function(p, nome) {
  # i grafici a doppio pannello hanno bisogno di più altezza
  altezza <- if (nome %in% c("plot_iscritti_ordine_gestione_pr",
                             "plot_plessi_ordine_gestione_pr")) 8 else 6
  saveRDS(p, file.path(dir_mod, paste0(nome, ".rds")))
  ggsave(file.path(dir_mod, paste0(nome, ".png")), p,
         width = 9, height = altezza, dpi = 300, device = ragg::agg_png)
  message("Salvato: ", nome, " (.rds + .png)")
})

# Verifiche per BLURB  -----


# 2. % alunni stranieri 2024/25, Parma vs media ER, statali + paritarie (blurb scuola_iscritti)
stranieri <- read_csv(here("moduli", "scuola_iscritti", "output", "stranieri_trend_prov_er.csv"), show_col_types = FALSE)
stranieri |>
  filter(anno_inizio == 2024) |>
  mutate(quota = round(100 * quota_stranieri, 1)) |>
  arrange(desc(quota)) |>
  select(provincia, alunni, alunni_stranieri, quota)  # attesi (solo ordinario, 2026-09-23): Parma 21,6 (2ª dopo Piacenza 25,2); ER 18,7
