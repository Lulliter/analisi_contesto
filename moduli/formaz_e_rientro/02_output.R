# ___________________________________________________________________________
# Modulo: formaz_e_rientro
# Scopo:  la "seconda chance" nella provincia di Parma: quanti adulti tornano a
#         scuola nei corsi serali (trend, con carcere e CPIA), quanto pesano
#         rispetto alla secondaria ordinaria nelle province ER, chi sono
#         (età, cittadinanza, tipo di istituto, anno di corso)
# Input:  output/*.rds (da 01_dati.R)
# Output: output/plot_*.rds (ggplot; girafe() nella pagina) + .png
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(stringr)
library(glue)
library(ggplot2)
library(ggiraph)
library(ggtext)

source(here("R", "_parma_colors.R"))
source(here("R", "grafici.R"))   # f_theme_sito*, f_caption_fonte, f_lab_as, f_salva_plot

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "formaz_e_rientro", "output")

ANNO_PRIMO <- 2015   # a.s. 2015/16
ANNO_ULTIMO <- 2024  # a.s. 2024/25
CAP_MIM <- f_caption_fonte("MIM, Portale unico dei dati della scuola (scuole statali)")
CAP_MIM_TREND <- f_caption_fonte("MIM, Portale unico dei dati della scuola (scuole statali; sezioni carcerarie rilevate dal 2017/18)")

COL_TERRITORI <- c("Parma" = ylw_lg, "Emilia-Romagna" = grn_md, "Altre province ER" = grey_sc)
# arancio = seconda chance (convenzione _parma_colors.R, 2026-09-23): tre tonalità
# per le tre porte, le stesse in tutti i grafici del modulo. Niente giallo/grigio
# (= Parma / altre province) e niente blu (= neutro)
COL_PORTE <- c("CPIA" = seq_factor_orange[8], "serale" = seq_factor_orange[6], "carcere" = seq_factor_orange[4])
COL_TIPO <- c("corsi serali" = COL_PORTE[["serale"]], "sezioni carcerarie" = COL_PORTE[["carcere"]])

# ordine delle categorie nel profilo (una lista di livelli per dimensione)
LIVELLI_PROFILO <- c("minorenni", "18", "oltre 18",          # età
                     "italiani", "stranieri",               # cittadinanza
                     "professionale", "tecnico", "artistico/liceo", "altro", # tipo istituto
                     "1", "2", "3", "4", "5")               # anno di corso

# 1. Carica dati pronti ----------------------------------------------------
rientro_trend_pr <- readRDS(file.path(dir_mod, "rientro_trend_pr.rds"))
rientro_incidenza_prov_er <- readRDS(file.path(dir_mod, "rientro_incidenza_prov_er.rds"))
rientro_profilo_pr <- readRDS(file.path(dir_mod, "rientro_profilo_pr.rds"))

# 2. Grafici ---------------------------------------------------------------

# __ plot_rientro_porte_pr ----
# Le tre porte del rientro nell'ultimo a.s.: CPIA (fonte propria), serali, carcere
LBL_PORTE <- c("CPIA" = "CPIA (alfabetizzazione, licenza media, competenze di base)",
               "serale" = "corsi serali delle superiori",
               "carcere" = "sezioni scolastiche in carcere")

rientro_porte_prep <- rientro_trend_pr |>
  filter(anno_inizio == ANNO_ULTIMO) |>
  mutate(porta_lbl = LBL_PORTE[tipo],
         alunni_lbl = format(alunni, big.mark = ".", decimal.mark = ",")) |>
  arrange(alunni) |>
  mutate(porta_lbl = factor(porta_lbl, levels = porta_lbl))
rientro_porte_prep

plot_rientro_porte_pr <- rientro_porte_prep |>
  ggplot(aes(x = alunni, y = porta_lbl, fill = tipo)) +
  geom_col_interactive(aes(tooltip = glue("{porta_lbl}: {alunni_lbl} ({fonte})"), data_id = tipo),
                       width = 0.6) +
  scale_fill_manual(values = COL_PORTE, guide = "none") +  # la porta si legge sull'asse y
  geom_text(aes(label = alunni_lbl), hjust = -0.15, size = 4.5) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15)),
                     labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
  scale_y_discrete(labels = function(x) stringr::str_wrap(x, 28)) +
  f_theme_sito() +
  theme(panel.grid.major.y = element_blank()) +
  labs(
    title = str_wrap(glue("Opzioni di rientro in formazione nella provincia di Parma (a.s. {f_lab_as(ANNO_ULTIMO)})"), 55),
    subtitle = "Indicatore: n. di iscritti nell'anno; corsi serali e carcere dai dati del Ministero (scuole statali), CPIA dal bilancio di sostenibilità del Centro (anno di riferimento dedotto, da confermare)",
    caption = f_caption_fonte("MIM, Portale unico dei dati della scuola; CPIA di Parma, Bilancio di sostenibilità"),
    x = "", y = ""
  )

plot_rientro_porte_pr

# __ plot_rientro_trend_pr ----
# Trend PR dei serali e del carcere (il CPIA ha un solo anno: sta nel sottotitolo)
rientro_trend_prep <- rientro_trend_pr |>
  filter(tipo %in% c("serale", "carcere")) |>
  mutate(tipo_lbl = factor(if_else(tipo == "serale", "corsi serali", "sezioni carcerarie"),
                           levels = names(COL_TIPO)),
         etichetta_as = f_lab_as(anno_inizio),
         alunni_lbl = format(alunni, big.mark = ".", decimal.mark = ","))
rientro_trend_prep

plot_rientro_trend_pr <- rientro_trend_prep |>
  ggplot(aes(x = anno_inizio, y = alunni, color = tipo_lbl, group = tipo_lbl)) +
  geom_line_interactive(aes(tooltip = tipo_lbl, data_id = tipo_lbl), linewidth = rel(1.2)) +
  geom_point_interactive(aes(tooltip = glue("{tipo_lbl} {etichetta_as}: {alunni_lbl}")), size = 1.8) +
  scale_x_continuous(breaks = ANNO_PRIMO:ANNO_ULTIMO, labels = f_lab_as(ANNO_PRIMO:ANNO_ULTIMO)) +
  scale_y_continuous(limits = c(0, NA), labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
  scale_color_manual(values = COL_TIPO) +
  f_theme_sito_trend() +
  labs(
    title = str_wrap(glue("Adulti che tornano a scuola nella provincia di Parma (trend a.s. {f_lab_as(ANNO_PRIMO)}-{f_lab_as(ANNO_ULTIMO)})"), 55),
    subtitle = "Indicatore: n. di iscritti ai corsi serali (percorsi di II livello) e alle sezioni carcerarie delle scuole statali; il CPIA non è nei dati aperti del Ministero e non ha una serie storica",
    caption = CAP_MIM_TREND, x = "", y = ""
  )

plot_rientro_trend_pr

# __ plot_rientro_incidenza_prov_er ----
# Barre per provincia (ultimo a.s.), Parma e regione evidenziate; l'Italia è una
# linea verticale di riferimento (colore Italia della convenzione)
rientro_incidenza_prep <- rientro_incidenza_prov_er |>
  filter(anno_inizio == ANNO_ULTIMO, provincia != "ITALIA") |>
  mutate(
    territorio_display = factor(case_when(
      provincia == "PARMA" ~ "Parma",
      provincia == "EMILIA-ROMAGNA" ~ "Emilia-Romagna",
      .default = "Altre province ER"
    ), levels = names(COL_TERRITORI)),
    provincia_lbl = str_to_title(provincia) |> str_replace("Forli'-Cesena", "Forlì-Cesena"),
    quota_lbl = scales::percent(quota_serali, accuracy = 0.1, decimal.mark = ",")
  ) |>
  arrange(quota_serali) |>
  mutate(provincia_lbl = factor(provincia_lbl, levels = provincia_lbl))
rientro_incidenza_prep

# valore Italia (numero e etichetta già calcolati: niente funzioni nel grafico)
italia_quota <- rientro_incidenza_prov_er |>
  filter(anno_inizio == ANNO_ULTIMO, provincia == "ITALIA") |> pull(quota_serali)
italia_lbl <- paste0("Italia ", scales::percent(italia_quota, accuracy = 0.1, decimal.mark = ","))

plot_rientro_incidenza_prov_er <- rientro_incidenza_prep |>
  ggplot(aes(x = quota_serali, y = provincia_lbl, fill = territorio_display)) +
  geom_col_interactive(aes(tooltip = glue("{provincia_lbl}: {quota_lbl}"), data_id = provincia_lbl),
                       width = 0.7) +
  geom_text(aes(label = quota_lbl), hjust = -0.2, size = 4) +
  geom_vline(xintercept = italia_quota, colour = blu_md, linetype = "dashed", linewidth = 0.8) +
  annotate("label", x = italia_quota, y = nrow(rientro_incidenza_prep) / 2 + 0.5, label = italia_lbl,
           colour = blu_md, fill = "white", label.size = 0, size = 4, fontface = "bold") +
  coord_cartesian(clip = "off") +  # l'etichetta centrata sulla linea può sforare il 3,5% senza essere tagliata
  scale_x_continuous(limits = c(0, 0.035), breaks = seq(0, 0.035, 0.005),
                     expand = expansion(mult = c(0, 0.04)), # un po' d'aria a destra: l'etichetta "3,5%" altrimenti esce dal bordo
                     labels = scales::label_percent(accuracy = 0.1, decimal.mark = ",")) +
  scale_fill_manual(values = COL_TERRITORI) +
  f_theme_sito() +
  theme(panel.grid.major.y = element_blank()) +
  labs(
    title = str_wrap(glue("Iscritti ai corsi serali nelle province dell'Emilia-Romagna (a.s. {f_lab_as(ANNO_ULTIMO)})"), 55),
    subtitle = "Indicatore: iscritti ai corsi serali in % rispetto agli iscritti alla secondaria di II grado ordinaria delle scuole statali dello stesso territorio (i serali non sono compresi nel denominatore)",
    caption = CAP_MIM, x = "", y = ""
  )

plot_rientro_incidenza_prov_er

# __ plot_rientro_profilo_pr ----
# Chi sono: 4 pannelli (età, cittadinanza, tipo istituto, anno di corso), % sul totale dei serali PR
rientro_profilo_prep <- rientro_profilo_pr |>
  mutate(
    dimensione = factor(dimensione, levels = c("età", "cittadinanza", "tipo istituto", "anno di corso")),
    valore = factor(valore, levels = rev(LIVELLI_PROFILO)),   # rev: il primo livello in alto
    quota_lbl = scales::percent(quota, accuracy = 1, decimal.mark = ","),
    alunni_lbl = format(alunni, big.mark = ".", decimal.mark = ",")
  )
rientro_profilo_prep

plot_rientro_profilo_pr <- rientro_profilo_prep |>
  ggplot(aes(x = quota, y = valore)) +
  geom_col_interactive(aes(tooltip = glue("{valore}: {alunni_lbl} ({quota_lbl})"), data_id = paste(dimensione, valore)),
                       fill = COL_PORTE[["serale"]], width = 0.7) +
  geom_text(aes(label = quota_lbl), hjust = -0.2, size = 4) +
  facet_wrap(~ dimensione, scales = "free_y") +
  scale_x_continuous(limits = c(0, 1), expand = expansion(mult = c(0, 0.15)),
                     labels = scales::label_percent(accuracy = 1, decimal.mark = ",")) +
  f_theme_sito() +
  theme(panel.grid.major.y = element_blank()) +
  labs(
    title = str_wrap(glue("Chi frequenta i corsi serali nella provincia di Parma (a.s. {f_lab_as(ANNO_ULTIMO)})"), 55),
    subtitle = "Indicatore: % di iscritti ai corsi serali (scuole statali) per classe di età, cittadinanza, tipo di istituto e anno di corso, sul totale degli iscritti ai serali",
    caption = CAP_MIM, x = "", y = ""
  )

plot_rientro_profilo_pr

# 3. Salva (rds per il sito + png; nome file = oggetto) --------------------
f_salva_plot(plot_rientro_porte_pr, "plot_rientro_porte_pr", dir_out = dir_mod, height = 4.5)
f_salva_plot(plot_rientro_trend_pr, "plot_rientro_trend_pr", dir_out = dir_mod, height = 6)
f_salva_plot(plot_rientro_incidenza_prov_er, "plot_rientro_incidenza_prov_er", dir_out = dir_mod, height = 6)
f_salva_plot(plot_rientro_profilo_pr, "plot_rientro_profilo_pr", dir_out = dir_mod, height = 7)
