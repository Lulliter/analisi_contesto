# ___________________________________________________________________________
# Modulo: ia_pew_usa
# Scopo:  due grafici dal rapporto Pew "Americans and AI 2026" (adulti USA), ridisegnati nello stile del sito:
#         1. uso quotidiano dei chatbot per età (barre orizzontali impilate + totale in coda)
#         2. impatto atteso dell'IA nei prossimi 20 anni, sulla società e su di sé, per età
#            (barre divergenti: negativo a sinistra, positivo a destra; "non sa" in colonna a parte)
# Input:  output/uso_chatbot_eta.rds, output/impatto_ia_eta.rds (da 01_dati.R)
# Output: output/plot_uso_chatbot.rds, output/plot_impatto_ia.rds (+ .png; nome file = oggetto)
#         csv per i bottoni di scarico: output/uso_chatbot_eta.csv, output/impatto_ia_eta.csv (da 01_dati.R)
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
source(here("R", "grafici.R"))   # f_theme_sito, f_caption_fonte, f_salva_plot

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "ia_pew_usa", "output")
CAP <- f_caption_fonte("Pew Research Center, Americans and AI 2026 (adulti USA, febbraio 2026); stima campionaria")
# classi d'età dall'alto in basso (ggplot disegna i livelli dal basso: nel grafico si usa rev())
LIV_ETA <- c("Tutti gli adulti", "18-29 anni", "30-49 anni", "50-64 anni", "65 anni e più")
# uso: stessa tinta, il più intenso = più spesso
COL_FREQ <- c("Più volte al giorno" = blu_sc, "Circa una volta al giorno" = blu_lg)
# impatto: rosso = negativo, verde = positivo (lettura immediata); toni scuri delle scale di _parma_colors,
# così l'etichetta bianca dentro la barra resta leggibile
COL_GIUDIZIO <- c("Negativo" = seq_factor_red[7], "Positivo" = seq_factor_green[7])
X_NON_SA <- 62   # posizione (in punti %) della colonna "Non sa" a destra delle barre

# 1. Carica dati pronti ----------------------------------------------------
uso_chatbot_eta <- readRDS(file.path(dir_mod, "uso_chatbot_eta.rds"))
impatto_ia_eta  <- readRDS(file.path(dir_mod, "impatto_ia_eta.rds"))

# 2. Grafici -------------------------------------------------------------------

# __ plot_uso_chatbot ----
# barre = le due frequenze; il totale "ogni giorno" è scritto in coda alla barra
uso_chatbot_prep <- uso_chatbot_eta |>
  mutate(
    eta = factor(eta, levels = rev(LIV_ETA)),
    etichetta = paste0(percentuale, "%"),
    tooltip = glue("{eta} - {frequenza}: {percentuale}%"),
    id = paste(eta, frequenza)
  )
uso_barre <- uso_chatbot_prep |>
  filter(frequenza != "Ogni giorno (totale)") |>
  mutate(frequenza = factor(frequenza, levels = names(COL_FREQ)))
# il totale va scritto dove finisce la barra: la barra è la somma delle due parti arrotondate,
# che può differire dal totale Pew di un punto (18-29 anni: 21 + 11 = 32, totale 31)
fine_barra <- uso_barre |>
  summarise(fine = sum(percentuale), .by = eta)
uso_totale <- uso_chatbot_prep |>
  filter(frequenza == "Ogni giorno (totale)") |>
  left_join(fine_barra, by = "eta")

uso_barre

plot_uso_chatbot <- uso_barre |>
  ggplot(aes(x = percentuale, y = eta, fill = frequenza)) +
  # reverse = TRUE: "più volte al giorno" parte da zero, come nella legenda
  geom_col_interactive(aes(tooltip = tooltip, data_id = id, group = frequenza),
                       position = position_stack(reverse = TRUE), width = 0.7) +
  geom_text(aes(label = etichetta, group = frequenza),
            position = position_stack(vjust = 0.5, reverse = TRUE), color = "white", size = 4.5) +
  # totale giornaliero in coda alla barra (1 punto dopo la fine), in grassetto
  geom_text(data = uso_totale, aes(x = fine + 1, y = eta, label = etichetta),
            inherit.aes = FALSE, hjust = 0, fontface = "bold", size = 4.8) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.1))) +
  scale_fill_manual(values = COL_FREQ) +
  f_theme_sito() +
  theme(axis.text.x = element_blank(), panel.grid.major = element_blank()) +
  # titolo: element_text non va a capo da solo (il textbox è solo per il sottotitolo) → str_wrap a 55 come negli altri moduli
  labs(title = str_wrap("1 adulto su 3 sotto i 50 anni usa l'IA ogni giorno", 55),
       subtitle = "Indicatore: % degli adulti USA della stessa età che dicono di usare chatbot di IA ogni giorno; in grassetto il totale",
       caption = CAP, x = "", y = "")

plot_uso_chatbot

# __ plot_impatto_ia ----
# negativo con segno meno (barra a sinistra dello zero), positivo a destra; etichette sempre positive
impatto_ia_prep <- impatto_ia_eta |>
  mutate(
    eta = factor(eta, levels = rev(LIV_ETA)),
    ambito = factor(ambito, levels = c("Sulla società", "Su di sé")),
    x = if_else(giudizio == "Negativo", -percentuale, percentuale),
    etichetta = paste0(percentuale, "%"),
    tooltip = glue("{ambito}, {eta} - {giudizio}: {percentuale}%"),
    id = paste(ambito, eta, giudizio)
  )
impatto_barre  <- impatto_ia_prep |> filter(giudizio != "Non sa")
# la posizione della colonna "Non sa" va nei dati, non come costante negli aes(): il grafico è
# riletto dal sito, dove X_NON_SA non esiste (gli aes si valutano al render)
impatto_non_sa <- impatto_ia_prep |> filter(giudizio == "Non sa") |> mutate(x_non_sa = X_NON_SA)

impatto_barre

plot_impatto_ia <- impatto_barre |>
  ggplot(aes(x = x, y = eta, fill = giudizio)) +
  geom_col_interactive(aes(tooltip = tooltip, data_id = id, group = giudizio), width = 0.7) +
  geom_vline(xintercept = 0, color = grey_extra_sc, linewidth = 0.4) +
  geom_text(aes(x = x / 2, label = etichetta, group = giudizio), color = "white", size = 4.2) +
  # colonna "Non sa": valore a destra e intestazione sopra la prima riga di ogni pannello
  geom_text(data = impatto_non_sa, aes(x = x_non_sa, y = eta, label = etichetta),
            inherit.aes = FALSE, color = grey_sc, size = 4) +
  annotate("text", x = X_NON_SA, y = length(LIV_ETA) + 0.8, label = "Non sa",
           color = grey_sc, fontface = "bold", size = 4) +
  facet_wrap(~ ambito, ncol = 1) +
  scale_x_continuous(limits = c(-55, X_NON_SA + 5)) +
  scale_y_discrete(expand = expansion(add = c(0.6, 1.2))) +   # spazio sopra per l'intestazione "Non sa"
  scale_fill_manual(values = COL_GIUDIZIO) +
  f_theme_sito() +
  theme(axis.text.x = element_blank(), panel.grid.major = element_blank(),
        strip.text = element_text(hjust = 0)) +
  labs(title = str_wrap("Giovani più pessimisti sull'impatto dell'IA, anziani più incerti", 55),
       subtitle = "Indicatore: % degli adulti USA della stessa età che prevedono per i prossimi 20 anni un impatto dell'IA negativo o positivo; non mostrato chi lo prevede ugualmente positivo e negativo (dal 23 al 32%)",
       caption = CAP, x = "", y = "")

plot_impatto_ia

# 3. Salva (rds per il sito + png per riuso rapido; nome file = oggetto) ----
f_salva_plot(plot_uso_chatbot, "plot_uso_chatbot", dir_mod, height = 6)
f_salva_plot(plot_impatto_ia,  "plot_impatto_ia",  dir_mod, height = 8.5)
