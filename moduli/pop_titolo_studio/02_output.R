# ___________________________________________________________________________
# Modulo: pop_titolo_studio — 02_output.R
# Scopo:  titolo di studio dei residenti per la pagina "Dalla scuola al lavoro" (focus giovani):
#         1) provincia di Parma: licenza media, diploma, laurea o più per classe d'età e sesso,
#            2018 e 2024 (dumbbell)
#         2) confronto provincia di Parma / Emilia-Romagna / Italia, 2024 (tabella)
#         3) comuni della provincia: % di laureati 25-49 anni, 2024 (mappa)
# Input:  output/titolo_studio_eta.rds (da 01_dati.R)
#         dati/puliti/istat_shp/PR_comuni_web_sf.rds (confini dei comuni PR, versione web)
# Output: output/plot_titoli_eta_pr.rds/.png + titoli_eta_pr.csv
#         output/titoli_confronto_ft.rds (flextable) + titoli_confronto.csv
#         output/mappa_laurea_25_49_pr.rds/.png + titoli_comuni_pr.csv
# NB: le tre categorie sono % sui residenti della stessa classe d'età (e sesso): non sommano a 100,
#     perché "nessun titolo" e "licenza elementare" non si mostrano
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(tidyr)
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

# __ plot_titoli_eta_pr ----
# provincia di Parma, 4 classi d'età × femmine/maschi, 2018 e 2024
titoli_eta_pr <- titoli_gruppi |>
  filter(cod_territorio == "ITD52", cod_sesso %in% c("F", "M"), cod_eta %in% CLASSI_ETA,
         anno %in% c(ANNO_PRIMO, ANNO_ULTIMO)) |>
  mutate(eta = droplevels(eta)) |>
  select(territorio, eta, sesso, gruppo, anno, valore, totale, pct)

# posizione verticale: giovani in alto; femmine poco sopra, maschi poco sotto la riga dell'età
# etichette e tooltip già pronti (il grafico si rilegge dal sito: niente funzioni negli aes)
titoli_eta_pr_prep <- titoli_eta_pr |>
  mutate(
    y_num    = (nlevels(eta) + 1 - as.integer(eta)) + if_else(sesso == "Femmine", 0.15, -0.15),
    anno_lbl = factor(anno),
    pct_lbl  = paste0(scales::number(pct, accuracy = 0.1, decimal.mark = ","), "%"),
    tooltip  = paste0(sesso, " di ", eta, " anni, ", anno, "<br>", gruppo, ": ", pct_lbl)
  )

# un segmento per riga: dal primo all'ultimo anno (colonne con nome fisso: il grafico si rilegge dal sito)
titoli_eta_pr_segm <- titoli_eta_pr_prep |>
  select(eta, sesso, gruppo, y_num, anno, pct) |>
  mutate(anno = if_else(anno == ANNO_PRIMO, "pct_inizio", "pct_fine")) |>
  pivot_wider(names_from = anno, values_from = pct)

titoli_eta_pr_prep

plot_titoli_eta_pr <- ggplot() +
  geom_segment(data = titoli_eta_pr_segm,
               aes(x = pct_inizio, xend = pct_fine, y = y_num, yend = y_num, color = sesso),
               linewidth = 1, alpha = 0.6) +
  geom_point_interactive(data = titoli_eta_pr_prep,
                         aes(x = pct, y = y_num, color = sesso, shape = anno_lbl,
                             tooltip = tooltip, data_id = tooltip),
                         size = 3, stroke = 1.2, fill = "white") +
  # 2018 = pallino vuoto, 2024 = pallino pieno
  scale_shape_manual(values = setNames(c(21, 16), c(ANNO_PRIMO, ANNO_ULTIMO))) +
  scale_color_manual(values = COL_SESSO) +
  scale_y_continuous(breaks = seq_along(CLASSI_ETA),
                     labels = rev(paste(levels(titoli_eta_pr_prep$eta), "anni"))) +
  scale_x_continuous(limits = c(0, NA), labels = scales::label_number(suffix = "%")) +
  facet_wrap(~ gruppo, ncol = 1) +
  f_theme_sito() +
  theme(panel.grid.major.y = element_blank()) +
  labs(
    title    = paste0("Titolo di studio per età e sesso, provincia di Parma (", ANNO_PRIMO, " e ", ANNO_ULTIMO, ")"),
    subtitle = paste0("Indicatore: % su tot. dei residenti della stessa classe d'età e sesso; pallino vuoto ",
                      ANNO_PRIMO, ", pieno ", ANNO_ULTIMO, "; nessun titolo e licenza elementare non mostrati"),
    caption  = FONTE, x = "", y = ""
  )

plot_titoli_eta_pr

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
  f_ft_titolo_note(
    titolo = paste0("Titolo di studio per età: Parma, Emilia-Romagna e Italia (", ANNO_ULTIMO, ")"),
    note   = "% su tot. dei residenti della stessa classe d'età; nessun titolo e licenza elementare non mostrati"
  )

titoli_confronto_ft

# __ mappa_laurea_25_49_pr ----
# comuni della provincia, 25-49 anni, sesso totale, ultimo anno
titoli_comuni_pr <- titoli_gruppi |>
  filter(livello == "comune", cod_sesso == "T", cod_eta == "Y25-49", anno == ANNO_ULTIMO) |>
  select(cod_territorio, territorio, gruppo, pct, totale) |>
  pivot_wider(names_from = gruppo, values_from = pct) |>
  rename(pct_licenza_media = `Licenza media`, pct_diploma = `Diploma o qualifica`,
         pct_laurea = `Laurea o più`, residenti_25_49 = totale)

titoli_comuni_pr

# classi a gradini fissi (campo 2024: da ~15% nei comuni di montagna a 42% nel capoluogo)
BREAKS_LAUREA    <- c(-Inf, 19, 21, 24, 26, Inf)
ETICHETTE_LAUREA <- c("meno del 19%", "19 – 21%", "21 – 24%", "24 – 26%", "26% e oltre")

# geometrie + dati, classe e tooltip (con il numero di residenti: nei comuni piccoli la stima è fragile)
mappa_laurea_25_49_prep <- readRDS(here("dati", "puliti", "istat_shp", "PR_comuni_web_sf.rds")) |>
  select(PRO_COM_T) |>
  left_join(titoli_comuni_pr, by = c("PRO_COM_T" = "cod_territorio")) |>
  f_aggiungi_classe("pct_laurea", label_fun = NULL, breaks = BREAKS_LAUREA, etichette = ETICHETTE_LAUREA) |>
  mutate(tooltip = paste0(
    territorio, " (25-49 anni: ", scales::number(residenti_25_49, big.mark = ".", decimal.mark = ","), " residenti)",
    "<br>laurea o più: ", scales::number(pct_laurea, accuracy = 0.1, decimal.mark = ","), "%",
    "<br>diploma o qualifica: ", scales::number(pct_diploma, accuracy = 0.1, decimal.mark = ","), "%",
    "<br>licenza media: ", scales::number(pct_licenza_media, accuracy = 0.1, decimal.mark = ","), "%"
  ))

# comuni senza dati dopo il join: atteso nessuno (Sorbolo Mezzani ha il codice 034051)
filter(mappa_laurea_25_49_prep, is.na(pct_laurea))

# bordo della provincia coerente con la geometria usata (unione dei comuni)
pr_bordo_sf <- mappa_laurea_25_49_prep |> summarise()

mappa_laurea_25_49_pr <- f_disegna_mappa(
  df_comuni    = mappa_laurea_25_49_prep,
  df_prov      = pr_bordo_sf,
  var          = "pct_laurea",
  titolo       = paste0("Laureati tra i 25 e i 49 anni, per comune (", ANNO_ULTIMO, ")"),
  palette5     = f_pal5(seq_factor_green),
  caption      = FONTE_MAPPA,
  sottotitolo  = "Indicatore: % di residenti di 25-49 anni con laurea triennale, ITS, magistrale o dottorato, su tot. dei residenti di 25-49 anni",
  col_tooltip  = "tooltip"
)

mappa_laurea_25_49_pr

# 3. Salva (rds per il sito + png; csv per i bottoni di scarico; nome file = oggetto) ----
f_salva_plot(plot_titoli_eta_pr, "plot_titoli_eta_pr", dir_out = dir_mod, height = 10)
write_csv(titoli_eta_pr, file.path(dir_mod, "titoli_eta_pr.csv"))

saveRDS(titoli_confronto_ft, file.path(dir_mod, "titoli_confronto_ft.rds"))
write_csv(titoli_confronto, file.path(dir_mod, "titoli_confronto.csv"))

f_salva_plot(mappa_laurea_25_49_pr, "mappa_laurea_25_49_pr", dir_out = dir_mod, height = 7)
write_csv(titoli_comuni_pr, file.path(dir_mod, "titoli_comuni_pr.csv"))

# Verifiche rapide (da eseguire a mano) ------------------------------------
# provincia di Parma, femmine 25-49, laurea o più: attesi 32,6% (2018) e 38,0% (2024); maschi 23,6% e 27,1%
titoli_eta_pr |> filter(eta == "25-49", gruppo == "Laurea o più")

# comuni agli estremi della mappa: attesi in basso Palanzano (~15%, 210 residenti 25-49), in alto Parma (42%)
titoli_comuni_pr |> arrange(pct_laurea) |> slice(c(1:3, (n() - 2):n()))

# comuni per classe: con questi gradini attesi circa 9 | 12 | 9 | 7 | 7
count(sf::st_drop_geometry(mappa_laurea_25_49_prep), classe_pct_laurea)
