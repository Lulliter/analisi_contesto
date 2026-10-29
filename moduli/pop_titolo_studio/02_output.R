# ___________________________________________________________________________
# Modulo: pop_titolo_studio — 02_output.R
# Scopo:  titolo di studio dei residenti per la pagina "Dalla scuola al lavoro" (focus giovani):
#         1) provincia di Parma: licenza media, diploma, laurea o più per sesso, tutte le età,
#            2018 e 2024 (barre affiancate)
#         2) confronto provincia di Parma / Emilia-Romagna / Italia, 2024 (tabella)
#         3) comuni della provincia, 25-64 anni, 2024: tre mappe (laurea, diploma, licenza media)
#         (2026-10-28: barre e mappe 25-64 al posto di dumbbell per età e mappa laureati 25-49,
#          tenuti in coda come commento)
# Input:  output/titolo_studio_eta.rds (da 01_dati.R)
#         dati/puliti/istat_shp/PR_comuni_web_sf.rds (confini dei comuni PR, versione web)
# Output: output/plot_titoli_sesso_pr.rds/.png + titoli_sesso_pr.csv
#         output/titoli_confronto_ft.rds (flextable) + titoli_confronto.csv
#         output/mappa_laurea_25_64_pr, mappa_diploma_25_64_pr, mappa_licenza_media_25_64_pr (.rds/.png)
#         + titoli_comuni_pr.csv (tabella condivisa dalle tre mappe)
# NB: le tre categorie sono % sui residenti della stessa classe d'età (e sesso): non sommano a 100,
#     perché "nessun titolo" e "licenza elementare" non si mostrano
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(sf)
library(ggplot2)
library(ggiraph)
library(ggtext)
library(flextable)

source(here("R", "_parma_colors.R"))
source(here("R", "grafici.R"))      # f_theme_sito*, f_caption_fonte, f_aggiungi_classe, f_disegna_mappa, f_salva_plot
source(here("R", "formatting.R"))   # f_ft, f_ft_titolo_note

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "pop_titolo_studio", "output")

ANNO_PRIMO  <- 2018
ANNO_ULTIMO <- 2024

FONTE      <- f_caption_fonte("ISTAT, Censimento permanente della popolazione")
FONTE_MAPPA <- f_caption_fonte(paste0("ISTAT, Censimento permanente della popolazione (", ANNO_ULTIMO, "); confini ISTAT"))

# le tre categorie mostrate: codici ISTAT che le compongono
GRUPPI <- tribble(
  ~cod_titolo, ~gruppo,
  "LSE",    "Licenza media",
  "USE_IF", "Diploma o qualifica",
  "BL",     "Laurea o più",
  "ML_RDD", "Laurea o più"
)
LIVELLI_GRUPPI <- c("Licenza media", "Diploma o qualifica", "Laurea o più")

CLASSI_ETA <- c("Y9-24", "Y25-49", "Y50-64", "Y_GE65")

COL_SESSO <- c("Femmine" = femmine, "Maschi" = maschi)

# sfondo delle righe della provincia di Parma: ylw_lg schiarito (30% del colore, 70% bianco)
BG_PARMA <- "#FAECD1"

# età dei grafici: barre = tutte le età (9 e più), mappe = età lavorativa (25-64 = somma di 25-49 e 50-64)
ETA_BARRE <- "Y_GE9"
ETA_MAPPE <- c("Y25-49", "Y50-64")

# palette delle tre mappe: 4 toni distanziati di CARTO "BluYl" (rcartocolor::carto_pal(15, "BluYl")[c(2, 6, 10, 15)])
PAL_TITOLI <- c("#DBF3AA", "#74C6A1", "#10949A", "#045275")

# una riga = una mappa; stessa regola per tutte: 4 classi da 5 punti, l'ultima aperta
# (i tre titoli stanno in fasce troppo diverse per una scala unica: provata e scartata il 2026-10-28, sotto)
MAPPE_TITOLI <- tribble(
  ~nome,                          ~gruppo_sel,           ~titolo_mappa,                            ~breaks,                   ~etichette,
  "mappa_laurea_25_64_pr",        "Laurea o più",        "Max titolo di studio: laurea o più",        c(-Inf, 15, 20, 25, Inf),  c("meno del 15%", "15 – 20%", "20 – 25%", "25% e oltre"),
  "mappa_diploma_25_64_pr",       "Diploma o qualifica", "Max titolo di studio: diploma o qualifica", c(-Inf, 45, 50, 55, Inf),  c("meno del 45%", "45 – 50%", "50 – 55%", "55% e oltre"),
  "mappa_licenza_media_25_64_pr", "Licenza media",       "Max titolo di studio: licenza media",       c(-Inf, 25, 30, 35, Inf),  c("meno del 25%", "25 – 30%", "30 – 35%", "35% e oltre")
)

# # scala unica per le tre mappe (tabset): classi di 5 punti, stesso colore = stesso valore
# BREAKS_TITOLI    <- c(-Inf, seq(15, 55, by = 5), Inf)
# ETICHETTE_TITOLI <- c("meno del 15%", paste0(seq(15, 50, by = 5), " – ", seq(20, 55, by = 5), "%"), "55% e oltre")
# # 10 toni distanziati di CARTO "BluYl" (rcartocolor::carto_pal(15, "BluYl")), senza il più chiaro;
# # col nome della classe, così ogni mappa prende solo i colori delle sue classi
# PAL_TITOLI <- setNames(c("#DBF3AA", "#C0E9A6", "#8CD2A2", "#74C6A1", "#46AEA0",
#                          "#2BA19D", "#058795", "#02798E", "#025F7E", "#045275"),
#                        ETICHETTE_TITOLI)
#
# # una riga = una mappa
# MAPPE_TITOLI <- tribble(
#   ~nome,                          ~gruppo_sel,           ~titolo_mappa,
#   "mappa_laurea_25_64_pr",        "Laurea o più",        "Laureati tra i 25 e i 64 anni",
#   "mappa_diploma_25_64_pr",       "Diploma o qualifica", "Diplomati tra i 25 e i 64 anni",
#   "mappa_licenza_media_25_64_pr", "Licenza media",       "Con licenza media tra i 25 e i 64 anni"
# )

# 1. Carica dati pronti ----------------------------------------------------
titolo_studio_eta <- readRDS(file.path(dir_mod, "titolo_studio_eta.rds"))

# tre categorie per territorio × sesso × età × anno: % sui residenti della stessa classe
# (laurea o più = somma di BL e ML_RDD; ML e RDD restano fuori, sono già dentro ML_RDD)
titoli_gruppi <- titolo_studio_eta |>
  inner_join(GRUPPI, by = "cod_titolo") |>
  summarise(valore = sum(valore), .by = c(livello, cod_territorio, territorio, sesso, cod_sesso,
                                          eta, cod_eta, anno, gruppo, totale)) |>
  mutate(pct    = 100 * valore / totale,
         gruppo = factor(gruppo, levels = LIVELLI_GRUPPI))

titoli_gruppi

# 2. Grafici e tabelle -----------------------------------------------------

# __ plot_titoli_sesso_pr ----
# provincia di Parma, tutte le età, femmine/maschi, 2018 e 2024
titoli_sesso_pr <- titoli_gruppi |>
  filter(cod_territorio == "ITD52", cod_sesso %in% c("F", "M"), cod_eta == ETA_BARRE,
         anno %in% c(ANNO_PRIMO, ANNO_ULTIMO)) |>
  select(territorio, sesso, gruppo, anno, valore, totale, pct)

# etichette e tooltip già pronti (il grafico si rilegge dal sito)
titoli_sesso_pr_prep <- titoli_sesso_pr |>
  mutate(
    pct_lbl = paste0(scales::number(pct, accuracy = 1), "%"),
    tooltip = paste0(sesso, ", ", anno, "<br>", gruppo, ": ",
                     scales::number(pct, accuracy = 0.1, decimal.mark = ","), "%")
  )

titoli_sesso_pr_prep

plot_titoli_sesso_pr <- ggplot(titoli_sesso_pr_prep,
                               aes(x = gruppo, y = pct, fill = sesso, group = sesso)) +
  geom_col_interactive(aes(tooltip = tooltip, data_id = tooltip, group = sesso),
                       position = position_dodge(width = 0.85), width = 0.8) +
  geom_text(aes(label = pct_lbl), position = position_dodge(width = 0.85),
            vjust = -0.4, size = 3.5) +
  scale_fill_manual(values = COL_SESSO) +
  # etichette lunghe a capo, altrimenti con due riquadri si sovrappongono
  scale_x_discrete(labels = scales::label_wrap(10)) +
  scale_y_continuous(labels = scales::label_number(suffix = "%"), expand = expansion(mult = c(0, 0.1))) +
  facet_wrap(~ anno) +
  f_theme_sito() +
  labs(
    title    = paste0("Max titolo di studio per sesso, provincia di Parma (", ANNO_PRIMO, " e ", ANNO_ULTIMO, ")"),
    subtitle = "Indicatore: % su tot. dei residenti di 9 anni e più dello stesso sesso; nessun titolo e licenza elementare non mostrati",
    caption  = FONTE, x = "", y = "", fill = ""
  )

plot_titoli_sesso_pr

# __ titoli_confronto_ft ----
# provincia di Parma / Emilia-Romagna / Italia, ultimo anno, sesso totale: una riga per età × territorio
titoli_confronto <- titoli_gruppi |>
  filter(cod_territorio %in% c("ITD52", "ITD5", "IT"), cod_sesso == "T", cod_eta %in% CLASSI_ETA,
         anno == ANNO_ULTIMO) |>
  mutate(
    territorio = case_when(cod_territorio == "ITD52" ~ "Provincia di Parma",
                           .default = territorio),
    territorio = factor(territorio, levels = c("Provincia di Parma", "Emilia-Romagna", "Italia")),
    eta        = paste(droplevels(eta), "anni")
  ) |>
  select(eta, cod_eta, territorio, gruppo, pct) |>
  pivot_wider(names_from = gruppo, values_from = pct) |>
  arrange(match(cod_eta, CLASSI_ETA), territorio) |>
  # ordine esplicito delle colonne (v. skill formatting-r)
  select(`Classe d'età` = eta, Territorio = territorio, all_of(LIVELLI_GRUPPI))

titoli_confronto

titoli_confronto_ft <- titoli_confronto |>
  f_ft() |>
  colformat_double(j = LIVELLI_GRUPPI, digits = 1, suffix = "%") |>
  merge_v(j = "Classe d'età") |>
  valign(j = "Classe d'età", valign = "top") |>
  # provincia di Parma in giallo pallido (non la colonna dell'età, che è unita su tre righe)
  bg(i = ~ Territorio == "Provincia di Parma", j = c("Territorio", LIVELLI_GRUPPI), bg = BG_PARMA, part = "body") |>
  # laurea a 9-24 anni in grigio: quasi nessuno ha l'età per averla
  color(i = ~ `Classe d'età` == "9-24 anni", j = "Laurea o più", color = grey_md1, part = "body") |>
  f_ft_titolo_note(
    titolo = paste0("Titolo di studio più alto per età: Parma, Emilia-Romagna e Italia (", ANNO_ULTIMO, ")"),
    note   = c(paste0("Fonte: ISTAT, Censimento permanente della popolazione (", ANNO_ULTIMO, ")"),
               "% su tot. dei residenti della stessa classe d'età; nessun titolo e licenza elementare non mostrati",
               "In grigio la laurea a 9-24 anni: la classe comprende soprattutto chi non ha ancora l'età per laurearsi")
  )

titoli_confronto_ft

# __ mappe_titoli_25_64_pr ----
# comuni della provincia, 25-64 anni (somma di 25-49 e 50-64), sesso totale, ultimo anno
titoli_comuni_25_64_pr <- titoli_gruppi |>
  filter(livello == "comune", cod_sesso == "T", cod_eta %in% ETA_MAPPE, anno == ANNO_ULTIMO) |>
  summarise(valore = sum(valore), totale = sum(totale), .by = c(cod_territorio, territorio, gruppo)) |>
  mutate(pct = 100 * valore / totale)

# versione larga per il csv (una tabella condivisa dalle tre mappe) e per il tooltip
titoli_comuni_pr <- titoli_comuni_25_64_pr |>
  select(cod_territorio, territorio, gruppo, pct, totale) |>
  pivot_wider(names_from = gruppo, values_from = pct) |>
  rename(pct_licenza_media = `Licenza media`, pct_diploma = `Diploma o qualifica`,
         pct_laurea = `Laurea o più`, residenti_25_64 = totale)

titoli_comuni_pr

# geometrie + dati + tooltip comune a tutte le mappe (con i residenti: nei comuni piccoli la stima è fragile)
mappe_titoli_base <- readRDS(here("dati", "puliti", "istat_shp", "PR_comuni_web_sf.rds")) |>
  select(PRO_COM_T) |>
  left_join(titoli_comuni_pr, by = c("PRO_COM_T" = "cod_territorio")) |>
  mutate(tooltip = paste0(
    territorio, " (25-64 anni: ", scales::number(residenti_25_64, big.mark = ".", decimal.mark = ","), " residenti)",
    "<br>laurea o più: ", scales::number(pct_laurea, accuracy = 0.1, decimal.mark = ","), "%",
    "<br>diploma o qualifica: ", scales::number(pct_diploma, accuracy = 0.1, decimal.mark = ","), "%",
    "<br>licenza media: ", scales::number(pct_licenza_media, accuracy = 0.1, decimal.mark = ","), "%"
  ))

# comuni senza dati dopo il join: atteso nessuno (Sorbolo Mezzani ha il codice 034051)
filter(mappe_titoli_base, is.na(pct_laurea))

# bordo della provincia coerente con la geometria usata (unione dei comuni)
pr_bordo_sf <- mappe_titoli_base |> summarise()

# una mappa per gruppo: classi fisse da MAPPE_TITOLI, disegno standard
f_mappa_titolo <- function(gruppo_sel, titolo_mappa, breaks, etichette) {
  df <- mappe_titoli_base |>
    left_join(filter(titoli_comuni_25_64_pr, gruppo == gruppo_sel) |> select(cod_territorio, pct),
              by = c("PRO_COM_T" = "cod_territorio")) |>
    f_aggiungi_classe("pct", label_fun = NULL, breaks = breaks, etichette = etichette)
    # (con la scala unica: in legenda solo le classi con almeno un comune)
    # |> mutate(classe_pct = droplevels(classe_pct))
  f_disegna_mappa(
    df_comuni   = df,
    df_prov     = pr_bordo_sf,
    var         = "pct",
    titolo      = paste0(titolo_mappa, ", per comune (", ANNO_ULTIMO, ")"),
    palette5    = PAL_TITOLI,
    caption     = FONTE_MAPPA,
    sottotitolo = paste0("Indicatore: % di residenti di 25-64 anni con titolo più alto = ", tolower(gruppo_sel),
                         ", su tot. dei residenti di 25-64 anni"),
    col_tooltip = "tooltip"
  )
}

mappe_titoli_25_64_pr <- pmap(select(MAPPE_TITOLI, -nome), f_mappa_titolo) |>
  setNames(MAPPE_TITOLI$nome)

# check mappe -----
mappe_titoli_25_64_pr$mappa_licenza_media_25_64_pr
mappe_titoli_25_64_pr$mappa_diploma_25_64_pr
mappe_titoli_25_64_pr$mappa_laurea_25_64_pr
 

# 3. Salva (rds per il sito + png; csv per i bottoni di scarico; nome file = oggetto) ----
f_salva_plot(plot_titoli_sesso_pr, "plot_titoli_sesso_pr", dir_out = dir_mod, height = 6)
write_csv(titoli_sesso_pr, file.path(dir_mod, "titoli_sesso_pr.csv"))

saveRDS(titoli_confronto_ft, file.path(dir_mod, "titoli_confronto_ft.rds"))
write_csv(titoli_confronto, file.path(dir_mod, "titoli_confronto.csv"))

walk2(mappe_titoli_25_64_pr, names(mappe_titoli_25_64_pr),
      function(p, nome) f_salva_plot(p, nome, dir_out = dir_mod, height = 7))
write_csv(titoli_comuni_pr, file.path(dir_mod, "titoli_comuni_pr.csv"))

# Verifiche rapide (da eseguire a mano) ------------------------------------
# provincia di Parma, 9 anni e più: % per sesso e anno (attesi da fissare dopo il primo lancio)
titoli_sesso_pr |> arrange(gruppo, sesso, anno)

# comuni agli estremi, 25-64 anni, laurea
titoli_comuni_pr |> arrange(pct_laurea) |> slice(c(1:3, (n() - 2):n()))

# comuni per classe, per ogni mappa: attesi laurea 9|25|9|1 (Parma sola nell'ultima),
# diploma 4|29|9|2, licenza media 4|16|20|4
map(mappe_titoli_25_64_pr, function(p) count(sf::st_drop_geometry(p$layers[[1]]$data), classe_pct))

# Versioni precedenti (non usate nel sito) --------------------------------
# fino al 2026-10-28: dumbbell per età e sesso e mappa dei laureati 25-49; sostituiti da barre
# per sesso (tutte le età) e mappe 25-64 perché più semplici da leggere. Codice tenuto come commento
# # __ plot_titoli_eta_pr (versione precedente)
# # provincia di Parma, 4 classi d'età × femmine/maschi, 2018 e 2024
# titoli_eta_pr <- titoli_gruppi |>
#   filter(cod_territorio == "ITD52", cod_sesso %in% c("F", "M"), cod_eta %in% CLASSI_ETA,
#          anno %in% c(ANNO_PRIMO, ANNO_ULTIMO)) |>
#   mutate(eta = droplevels(eta)) |>
#   select(territorio, eta, sesso, gruppo, anno, valore, totale, pct)
#
# # posizione verticale: giovani in alto; femmine poco sopra, maschi poco sotto la riga dell'età
# # etichette e tooltip già pronti (il grafico si rilegge dal sito: niente funzioni negli aes)
# titoli_eta_pr_prep <- titoli_eta_pr |>
#   mutate(
#     y_num    = (nlevels(eta) + 1 - as.integer(eta)) + if_else(sesso == "Femmine", 0.15, -0.15),
#     anno_lbl = factor(anno),
#     pct_lbl  = paste0(scales::number(pct, accuracy = 0.1, decimal.mark = ","), "%"),
#     tooltip  = paste0(sesso, " di ", eta, " anni, ", anno, "<br>", gruppo, ": ", pct_lbl)
#   )
#
# # un segmento per riga: dal primo all'ultimo anno (colonne con nome fisso: il grafico si rilegge dal sito)
# titoli_eta_pr_segm <- titoli_eta_pr_prep |>
#   select(eta, sesso, gruppo, y_num, anno, pct) |>
#   mutate(anno = if_else(anno == ANNO_PRIMO, "pct_inizio", "pct_fine")) |>
#   pivot_wider(names_from = anno, values_from = pct)
#
# titoli_eta_pr_prep
#
# plot_titoli_eta_pr <- ggplot() +
#   geom_segment(data = titoli_eta_pr_segm,
#                aes(x = pct_inizio, xend = pct_fine, y = y_num, yend = y_num, color = sesso),
#                linewidth = 1, alpha = 0.6) +
#   geom_point_interactive(data = titoli_eta_pr_prep,
#                          aes(x = pct, y = y_num, color = sesso, shape = anno_lbl,
#                              tooltip = tooltip, data_id = tooltip),
#                          size = 3, stroke = 1.2, fill = "white") +
#   # 2018 = pallino vuoto, 2024 = pallino pieno
#   scale_shape_manual(values = setNames(c(21, 16), c(ANNO_PRIMO, ANNO_ULTIMO))) +
#   scale_color_manual(values = COL_SESSO) +
#   scale_y_continuous(breaks = seq_along(CLASSI_ETA),
#                      labels = rev(paste(levels(titoli_eta_pr_prep$eta), "anni"))) +
#   scale_x_continuous(limits = c(0, NA), labels = scales::label_number(suffix = "%")) +
#   facet_wrap(~ gruppo, ncol = 1) +
#   f_theme_sito() +
#   theme(panel.grid.major.y = element_blank()) +
#   labs(
#     title    = paste0("Titolo di studio per età e sesso, provincia di Parma (", ANNO_PRIMO, " e ", ANNO_ULTIMO, ")"),
#     subtitle = paste0("Indicatore: % su tot. dei residenti della stessa classe d'età e sesso; pallino vuoto ",
#                       ANNO_PRIMO, ", pieno ", ANNO_ULTIMO, "; nessun titolo e licenza elementare non mostrati"),
#     caption  = FONTE, x = "", y = ""
#   )
#
# plot_titoli_eta_pr
#
# # __ mappa_laurea_25_49_pr (versione precedente)
# # comuni della provincia, 25-49 anni, sesso totale, ultimo anno
# titoli_comuni_pr <- titoli_gruppi |>
#   filter(livello == "comune", cod_sesso == "T", cod_eta == "Y25-49", anno == ANNO_ULTIMO) |>
#   select(cod_territorio, territorio, gruppo, pct, totale) |>
#   pivot_wider(names_from = gruppo, values_from = pct) |>
#   rename(pct_licenza_media = `Licenza media`, pct_diploma = `Diploma o qualifica`,
#          pct_laurea = `Laurea o più`, residenti_25_49 = totale)
#
# titoli_comuni_pr
#
# # classi a gradini fissi (campo 2024: da ~15% nei comuni di montagna a 42% nel capoluogo)
# BREAKS_LAUREA    <- c(-Inf, 19, 21, 24, 26, Inf)
# ETICHETTE_LAUREA <- c("meno del 19%", "19 – 21%", "21 – 24%", "24 – 26%", "26% e oltre")
#
# # geometrie + dati, classe e tooltip (con il numero di residenti: nei comuni piccoli la stima è fragile)
# mappa_laurea_25_49_prep <- readRDS(here("dati", "puliti", "istat_shp", "PR_comuni_web_sf.rds")) |>
#   select(PRO_COM_T) |>
#   left_join(titoli_comuni_pr, by = c("PRO_COM_T" = "cod_territorio")) |>
#   f_aggiungi_classe("pct_laurea", label_fun = NULL, breaks = BREAKS_LAUREA, etichette = ETICHETTE_LAUREA) |>
#   mutate(tooltip = paste0(
#     territorio, " (25-49 anni: ", scales::number(residenti_25_49, big.mark = ".", decimal.mark = ","), " residenti)",
#     "<br>laurea o più: ", scales::number(pct_laurea, accuracy = 0.1, decimal.mark = ","), "%",
#     "<br>diploma o qualifica: ", scales::number(pct_diploma, accuracy = 0.1, decimal.mark = ","), "%",
#     "<br>licenza media: ", scales::number(pct_licenza_media, accuracy = 0.1, decimal.mark = ","), "%"
#   ))
#
# # comuni senza dati dopo il join: atteso nessuno (Sorbolo Mezzani ha il codice 034051)
# filter(mappa_laurea_25_49_prep, is.na(pct_laurea))
#
# # bordo della provincia coerente con la geometria usata (unione dei comuni)
# pr_bordo_sf <- mappa_laurea_25_49_prep |> summarise()
#
# mappa_laurea_25_49_pr <- f_disegna_mappa(
#   df_comuni    = mappa_laurea_25_49_prep,
#   df_prov      = pr_bordo_sf,
#   var          = "pct_laurea",
#   titolo       = paste0("Laureati tra i 25 e i 49 anni, per comune (", ANNO_ULTIMO, ")"),
#   palette5     = f_pal5(seq_factor_green),
#   caption      = FONTE_MAPPA,
#   sottotitolo  = "Indicatore: % di residenti di 25-49 anni con laurea triennale, ITS, magistrale o dottorato, su tot. dei residenti di 25-49 anni",
#   col_tooltip  = "tooltip"
# )
#
# mappa_laurea_25_49_pr
#
# f_salva_plot(plot_titoli_eta_pr, "plot_titoli_eta_pr", dir_out = dir_mod, height = 10)
# write_csv(titoli_eta_pr, file.path(dir_mod, "titoli_eta_pr.csv"))
# f_salva_plot(mappa_laurea_25_49_pr, "mappa_laurea_25_49_pr", dir_out = dir_mod, height = 7)
# write_csv(titoli_comuni_pr, file.path(dir_mod, "titoli_comuni_pr.csv"))
#
# # provincia di Parma, femmine 25-49, laurea o più: attesi 32,6% (2018) e 38,0% (2024); maschi 23,6% e 27,1%
# titoli_eta_pr |> filter(eta == "25-49", gruppo == "Laurea o più")
#
# # comuni agli estremi della mappa: attesi in basso Palanzano (~15%, 210 residenti 25-49), in alto Parma (42%)
# titoli_comuni_pr |> arrange(pct_laurea) |> slice(c(1:3, (n() - 2):n()))
#
# # comuni per classe: con questi gradini attesi circa 9 | 12 | 9 | 7 | 7
# count(sf::st_drop_geometry(mappa_laurea_25_49_prep), classe_pct_laurea)
