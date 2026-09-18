# ________________________________________________________________________
# Modulo: giovani_benessere
# Scopo:  come stanno i 14-19enni in Italia, per sesso, prima e dopo il
#         lockdown: indice di salute mentale (2016-2025) e soddisfazione per le
#         relazioni amicali (2005-2025, la serie lunga che mostra la deriva
#         delle ragazze dal 2012). Solo Italia: il Bes per età × sesso non
#         esiste per regione (cornice ER nel testo, da bes_giovani_reg)
# Input:  output/bes_giovani_eta_sesso.rds (da 01_dati.R)
# Output: output/plot_*.rds (ggplot; girafe() nella pagina) + .png
# ________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(stringr)
library(purrr)
library(glue)
library(ggplot2)
library(ggiraph)
library(scales)
library(ggtext)

source(here("R", "_parma_colors.R"))
source(here("R", "grafici.R"))   # temi, caption, mappe, salvataggio (v. indice in testa al file)

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "giovani_benessere", "output")

CAP_BES <- f_caption_fonte("ISTAT, Bes (aggiornamento 2026), indagine Aspetti della vita quotidiana; stima campionaria")
# definizione ISTAT dell'indice (Bes, cap. Salute), da mettere in caption sopra la fonte
NB_MH <- paste(
  "NB: L'indice di salute mentale è una misura di disagio psicologico (psychological distress) ottenuta dalla sintesi dei punteggi individuali riferiti a 4 dimensioni della salute mentale (ansia, depressione, perdita di controllo comportamentale o emozionale e benessere psicologico)."
)
ETA_PLOT <- "14-19"
ANNO_ULTIMO <- 2025
LOCKDOWN <- c(2020, 2021)  # anni evidenziati con una fascia grigia
# etichette e colori per sesso (maschi/femmine da _parma_colors; totale grigio)
COL_SESSO <- c("Femmine" = femmine, "Maschi" = maschi, "Totale" = grey_sc)

# 1. Carica dati pronti ----------------------------------------------------
bes_giovani_eta_sesso <- readRDS(file.path(dir_mod, "bes_giovani_eta_sesso.rds"))

# 2. Indice di salute mentale per sesso, 2016-2025: 14-19, 20-24, popolazione --
salute_mentale_prep <- bes_giovani_eta_sesso |>
  filter(indicatore_breve == "salute_mentale") |>
  mutate(sesso = factor(sesso, levels = names(COL_SESSO)),
         etichetta = scales::number(valore, accuracy = 0.1, decimal.mark = ","))

salute_mentale_prep

# caption = nota + fonte; con la caption in textbox (ggtext) i "\n" diventano <br>
CAP_MH <- str_replace_all(paste0(NB_MH, "<br>", CAP_BES), "\n", "<br>")

# grafico per una classe di età (stessa scala y per confrontarli)
f_plot_salute_mentale <- function(dati, eta_sel, chi) {
  dati |>
    filter(eta == eta_sel) |>
    ggplot(aes(x = anno, y = valore, color = sesso, group = sesso)) +
    # fascia grigia sugli anni della pandemia
    annotate("rect", xmin = LOCKDOWN[1] - 0.5, xmax = LOCKDOWN[2] + 0.5,
             ymin = -Inf, ymax = Inf, fill = "grey85", alpha = 0.5) +
    annotate("text", x = mean(LOCKDOWN), y = Inf, label = "pandemia",
             hjust = 0.5, vjust = 1.5, size = 3.5, color = grey_extra_sc) +
    geom_line_interactive(aes(tooltip = sesso, data_id = sesso), linewidth = rel(1.2)) +
    geom_point_interactive(aes(tooltip = glue("{sesso} {anno}: {etichetta}"), data_id = sesso), size = 2) +
    scale_x_continuous(breaks = seq(2016, ANNO_ULTIMO, by = 1)) +
    scale_y_continuous(limits = c(60, 80)) +
    scale_color_manual(values = COL_SESSO) +
    f_theme_sito_trend() +
    theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
          # caption lunga: textbox che va a capo da sola alla larghezza del grafico
          plot.caption = ggtext::element_textbox_simple(size = rel(0.65), lineheight = 1.1, margin = margin(t = 8)),
          plot.caption.position = "plot") +
    labs(
      title = str_wrap(glue("Salute mentale {chi} in Italia (trend 2016-{ANNO_ULTIMO})"), 55),
      subtitle = "Indicatore: indice di salute mentale (punteggio 0-100, più alto = meglio), per sesso. Stima campionaria: leggere il trend, non i decimali",
      caption = CAP_MH, x = "", y = ""
    )
}

plot_salute_mentale_14_19 <- f_plot_salute_mentale(salute_mentale_prep, "14-19", "dei 14-19enni")
plot_salute_mentale_20_24 <- f_plot_salute_mentale(salute_mentale_prep, "20-24", "dei 20-24enni")
plot_salute_mentale_totale <- f_plot_salute_mentale(salute_mentale_prep, "Totale", "della popolazione (14 anni e più)")

plot_salute_mentale_20_24

# 3. Soddisfazione per le relazioni amicali per sesso, 2005-2025: 14-19, 20-24, popolazione --
amici_prep <- bes_giovani_eta_sesso |>
  filter(indicatore_breve == "amici") |>
  mutate(sesso = factor(sesso, levels = names(COL_SESSO)),
         quota = valore / 100,
         etichetta = scales::percent(quota, accuracy = 0.1, decimal.mark = ","))

amici_prep

# grafico per una classe di età (stessa scala y per confrontare i livelli)
f_plot_amici <- function(dati, eta_sel, chi) {
  dati |>
    filter(eta == eta_sel) |>
    ggplot(aes(x = anno, y = quota, color = sesso, group = sesso)) +
    annotate("rect", xmin = LOCKDOWN[1] - 0.5, xmax = LOCKDOWN[2] + 0.5,
             ymin = -Inf, ymax = Inf, fill = "grey85", alpha = 0.5) +
    annotate("text", x = mean(LOCKDOWN), y = Inf, label = "pandemia",
             hjust = 0.5, vjust = 1.5, size = 3.5, color = grey_extra_sc) +
    geom_line_interactive(aes(tooltip = sesso, data_id = sesso), linewidth = rel(1.2)) +
    geom_point_interactive(aes(tooltip = glue("{sesso} {anno}: {etichetta}"), data_id = sesso), size = 2) +
    scale_x_continuous(breaks = seq(2005, ANNO_ULTIMO, by = 1)) +
    scale_y_continuous(labels = function(x) scales::percent(x, accuracy = 1), limits = c(0.15, 0.55)) +
    scale_color_manual(values = COL_SESSO) +
    f_theme_sito_trend() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          plot.caption = ggtext::element_textbox_simple(size = rel(0.65), lineheight = 1.1, margin = margin(t = 8)),
          plot.caption.position = "plot") +
    labs(
      title = str_wrap(glue("Soddisfazione per le relazioni con gli amici {chi} in Italia (trend 2005-{ANNO_ULTIMO})"), 55),
      subtitle = "Indicatore: % di molto soddisfatti, per sesso. Stima campionaria: leggere il trend, non i decimali",
      caption = str_replace_all(CAP_BES, "\n", "<br>"), x = "", y = ""
    )
}

plot_amici_14_19 <- f_plot_amici(amici_prep, "14-19", "dei 14-19enni")
plot_amici_20_24 <- f_plot_amici(amici_prep, "20-24", "dei 20-24enni")
plot_amici_totale <- f_plot_amici(amici_prep, "Totale", "della popolazione (14 anni e più)")

plot_amici_totale

# 4. Salva (rds per il sito + png; nome file = oggetto) --------------------
lista_plot <- list(
  plot_salute_mentale_14_19 = plot_salute_mentale_14_19,
  plot_salute_mentale_20_24 = plot_salute_mentale_20_24,
  plot_salute_mentale_totale = plot_salute_mentale_totale,
  plot_amici_14_19 = plot_amici_14_19,
  plot_amici_20_24 = plot_amici_20_24,
  plot_amici_totale = plot_amici_totale
)

iwalk(lista_plot, function(p, nome) {
  saveRDS(p, file.path(dir_mod, paste0(nome, ".rds")))
  ggsave(file.path(dir_mod, paste0(nome, ".png")), p, width = 9, height = 6, dpi = 300, device = ragg::agg_png)
  message("Salvato: ", nome, " (.rds + .png)")
})
