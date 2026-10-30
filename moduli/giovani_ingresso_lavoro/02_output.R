# ___________________________________________________________________________
# Modulo: giovani_ingresso_lavoro
# Scopo:  occupazione e disoccupazione dei giovani: Parma tra le province dell'Emilia-Romagna
#         (25-34 anni, per sesso), Parma ed Emilia-Romagna rispetto a Nord-est, Italia e UE,
#         e come cambia la condizione dei giovani in regione rispetto al 2024 e al 2019
# Input:  output/condizione_rev.rds (da 01_dati.R)
# Output: output/plot_*.rds (ggplot; girafe() nella pagina) + .png
#         csv per i bottoni di scarico: tassi_prov_er.csv (condiviso dai due grafici per provincia),
#         variazioni_condizione_er.csv, tassi_territori.csv (condiviso dai due grafici di confronto)
#         output/aire_confronto_ft.rds (flextable) + aire_confronto.csv: giovani all'estero (AIRE)
# NB: stime campionarie (ISTAT, forze di lavoro, elaborate dalla Regione): per provincia e
#     sesso i valori sono indicativi; leggere le distanze grandi, non i decimali
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(glue)
library(ggplot2)
library(ggiraph)
library(ggtext)
library(flextable)

source(here("R", "_parma_colors.R"))
source(here("R", "grafici.R"))   # f_theme_sito, f_caption_fonte, f_salva_plot
source(here("R", "formatting.R"))   # f_ft, f_ft_titolo_note (tabella AIRE)

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "giovani_ingresso_lavoro", "output")
ANNO <- 2025

CAP_RER <- f_caption_fonte("Regione Emilia-Romagna, Report giovani 2026, su dati ISTAT (stima campionaria)")

# colori dei territori (convenzione _parma_colors.R: Parma giallo, ER verde, Italia blu)
COL_TERRITORI <- c("Parma" = ylw_lg, "Emilia-Romagna" = grn_md, "Italia" = blu_md, "Altre province ER" = grey_sc)
# condizioni nel lavoro (categoriche): occupati in verde, il resto in toni che non
# si confondono con Parma (giallo chiaro) ed evidenziazione (bordeaux)
# (fino al 2026-10-29: grey_md1, grn_md, ylw_sc, blu_lg)
# COL_CONDIZIONI <- c("Forze di lavoro" = grey_md1, "Occupati" = grn_md,
#                     "In cerca di lavoro" = ylw_sc, "Inattivi" = blu_lg)
# dal 2026-10-29: toni smorzati della palette Carto "Antique" (vedi _parma_colors.R), fuori dalle
# tinte riservate (giallo Parma, verde ER, blu Italia, bordeaux evidenziazione)
# COL_CONDIZIONI <- c("Forze di lavoro" = "#7C7C7C", "Occupati" = "#68855C",
#                     "In cerca di lavoro" = "#AF6458", "Inattivi" = "#526A83")
# dal 2026-10-29 (scelta di Luisa): occupati blu, in cerca verde, inattivi rosso
COL_CONDIZIONI <- c("Forze di lavoro" = grey_md1, "Occupati" = blu_lg,
                    "In cerca di lavoro" = grn_md, "Inattivi" = "#CC503E")
LAB_CONDIZIONI <- c(forza_lavoro = "Forze di lavoro", occupati = "Occupati",
                    in_cerca = "In cerca di lavoro", inattivi = "Inattivi")
COL_SESSO <- c("Maschi" = maschi, "Femmine" = femmine, "Totale" = grey_extra_sc)
LIV_SESSO <- c("Totale", "Maschi", "Femmine")
# territori del confronto, dal basso verso l'alto (Parma in cima)
LIV_TERRITORI <- c("UE 27", "Italia", "Nord-est", "Emilia-Romagna", "Parma")

# 1. Carica dati pronti ----------------------------------------------------
condizione_rev <- readRDS(file.path(dir_mod, "condizione_rev.rds"))

# 2. Grafici --------------------------------------------------------------

# ___ Province ER, 25-34 anni ______________________________________________

# dati condivisi dai due grafici per provincia (e dal csv): 9 province (Tab. 19) + regione (Tab. 17-18)
tassi_prov_er <- condizione_rev |>
  filter(anno == ANNO, classe_eta == "25-34",
         indicatore %in% c("tasso_occupazione", "tasso_disoccupazione"),
         (tabella == "19") | (territorio %in% c("Emilia-Romagna", "Italia") & tabella %in% c("17", "18"))) |>
  select(territorio, indicatore, sesso, valore)
# (2026-10-29: aggiunta l'Italia come barra, al posto della linea tratteggiata che non si capiva)
tassi_prov_er   # attese 66 righe: 11 territori × 2 indicatori × 3 (maschi, femmine, totale)
stopifnot(nrow(tassi_prov_er) == 66)

tassi_prov_er_prep <- tassi_prov_er |>
  mutate(
    territorio_display = factor(case_when(
      territorio == "Parma" ~ "Parma",
      territorio == "Emilia-Romagna" ~ "Emilia-Romagna",
      territorio == "Italia" ~ "Italia",
      .default = "Altre province ER"
    ), levels = names(COL_TERRITORI)),
    valore_lbl = scales::number(valore, accuracy = 0.1, decimal.mark = ",", suffix = "%"),
    tooltip = glue("{territorio}, {str_to_lower(sesso)}: {valore_lbl}"),
    id = paste(territorio, sesso),
    sesso = factor(sesso, levels = LIV_SESSO)
  )
tassi_prov_er_prep

# Italia (Tab. 17-18, 25-34): era la linea di riferimento in ogni pannello; dal 2026-10-29 l'Italia
# è una barra (in tassi_prov_er): l'oggetto resta solo come controllo dei valori
italia_25_34 <- condizione_rev |>
  filter(anno == ANNO, territorio == "Italia", classe_eta == "25-34",
         indicatore %in% c("tasso_occupazione", "tasso_disoccupazione")) |>
  select(indicatore, sesso, valore) |>
  mutate(sesso = factor(sesso, levels = LIV_SESSO))
italia_25_34   # attese 6 righe: occupazione 76,3 / 60,3 / 68,5; disoccupazione 8,3 / 9,9 / 9,0

# barre per provincia, un pannello per sesso; Italia ed Emilia-Romagna in cima, poi le province ordinate per il totale (lo stesso
# ordine nei tre pannelli, così si vede lo scarto tra maschi e femmine)
f_plot_tassi_prov <- function(prep, ind, passo, titolo, sottotitolo) {
  dati <- prep |> filter(indicatore == ind)
  # province ordinate per il totale; in cima Emilia-Romagna e Italia (l'ultimo livello sta in alto)
  ordine_prov <- dati |>
    filter(sesso == "Totale", !territorio %in% c("Emilia-Romagna", "Italia")) |>
    arrange(valore) |>
    pull(territorio)
  ordine <- c(ordine_prov, "Emilia-Romagna", "Italia")
  dati <- dati |> mutate(territorio = factor(territorio, levels = ordine))
  lim <- ceiling(max(dati$valore) / passo) * passo
  ggplot(dati, aes(x = valore, y = territorio, fill = territorio_display)) +
    geom_col_interactive(aes(tooltip = tooltip, data_id = id), width = 0.7) +
    geom_text(aes(label = valore_lbl), hjust = -0.15, size = 3.3) +
    # (fino al 2026-10-29 linea tratteggiata per l'Italia, ora barra)
    # geom_vline(data = italia |> filter(indicatore == ind), aes(xintercept = valore),
    #            colour = blu_md, linetype = "dashed", linewidth = 0.7) +
    # linea continua dalla fine della barra Italia, attraverso tutte le province (valore del pannello)
    # geom_vline(data = dati |> filter(territorio == "Italia"), aes(xintercept = valore),
    #            colour = blu_md, linewidth = 0.5) +
    # separatore tratteggiato sul bordo destro del pannello Totale: maschi e femmine sono un "di cui"
    geom_vline(data = data.frame(sesso = factor("Totale", levels = LIV_SESSO)), aes(xintercept = Inf),
               colour = grey_md1, linetype = "dashed", linewidth = 0.6) +
    facet_wrap(~ sesso) +
    coord_cartesian(clip = "off") +
    scale_x_continuous(limits = c(0, lim), breaks = seq(0, lim, passo),
                       labels = scales::label_number(suffix = "%", decimal.mark = ","),
                       expand = expansion(mult = c(0, 0.12))) +
    scale_fill_manual(values = COL_TERRITORI) +
    f_theme_sito() +
    theme(panel.grid.major.y = element_blank(), panel.spacing.x = unit(1.2, "lines")) +
    labs(title = titolo, subtitle = sottotitolo, caption = CAP_RER, x = NULL, y = NULL)
}

# __ plot_occupazione_prov_er ----
plot_occupazione_prov_er <- f_plot_tassi_prov(
  tassi_prov_er_prep, "tasso_occupazione", passo = 25,
  titolo = str_wrap(glue("Tasso di occupazione dei 25-34enni nelle province dell'Emilia-Romagna ({ANNO})"), 60),
  sottotitolo = "Indicatore: occupati in % della popolazione di riferimento; per provincia e sesso i valori sono indicativi"
)
plot_occupazione_prov_er

# __ plot_disoccupazione_prov_er ----
plot_disoccupazione_prov_er <- f_plot_tassi_prov(
  tassi_prov_er_prep, "tasso_disoccupazione", passo = 4,
  titolo = str_wrap(glue("Tasso di disoccupazione dei 25-34enni nelle province dell'Emilia-Romagna ({ANNO})"), 60),
  sottotitolo = "Indicatore: persone in cerca di lavoro in % di chi lavora o cerca lavoro, 25-34 anni (chi studia o non cerca è escluso dal calcolo); per provincia e sesso i valori sono indicativi"
)
plot_disoccupazione_prov_er

# ___ Variazioni per condizione, Emilia-Romagna ____________________________

# __ variazioni_condizione_er (dati e prep condivisi dai due grafici delle variazioni) ----
# var. % stampate (Tab. 14) per 15-24, 25-34 e 15 anni e oltre; nel pannello "15 anni e oltre"
# gli inattivi sono quelli di 15-64 anni (come nel Report: oltre i 64 sono quasi tutti pensionati)
variazioni_condizione_er <- condizione_rev |>
  filter(tabella == "14", misura %in% c("var_pct_su_2024", "var_pct_su_2019"),
         classe_eta %in% c("15-24", "25-34", "15-64") | (classe_eta == "15+" & indicatore != "inattivi")) |>
  select(classe_eta, indicatore, misura, valore)
variazioni_condizione_er   # attese 24 righe: 3 pannelli × 4 condizioni × 2 confronti

# popolazione 2025 per pannello (forze di lavoro + inattivi, migliaia stampate): va nell'etichetta
pop_pannelli <- condizione_rev |>
  filter(tabella == "14", misura == "migliaia", anno == ANNO,
         classe_eta %in% c("15-24", "25-34", "15+"), indicatore %in% c("forza_lavoro", "inattivi")) |>
  summarise(pop_migliaia = sum(valore), .by = classe_eta)
pop_pannelli   # attese: 15-24 424,7; 25-34 465,8; 15+ 3.891,4

variazioni_condizione_er_prep <- variazioni_condizione_er |>
  mutate(classe_pan = if_else(classe_eta == "15-64", "15+", classe_eta)) |>
  left_join(pop_pannelli, by = c("classe_pan" = "classe_eta")) |>
  mutate(
    eta_lbl = if_else(classe_pan == "15+", "15 anni e oltre", paste(classe_pan, "anni")),
    pop_lbl = scales::number(pop_migliaia, accuracy = 1, big.mark = ".", decimal.mark = ","),
    confronto = if_else(misura == "var_pct_su_2024", "2025 su 2024", "2025 su 2019"),
    condizione = LAB_CONDIZIONI[indicatore],
    valore_lbl = scales::number(valore, accuracy = 0.1, decimal.mark = ",", style_positive = "plus", suffix = "%"),
    tooltip = glue("{condizione}, {eta_lbl}, {confronto}: {valore_lbl}"),
    id = paste(classe_eta, indicatore, misura),
    # etichetta del pannello su due righe: età e popolazione
    pannello = as.character(glue("{eta_lbl}\n({pop_lbl} mila)")),
    vjust = if_else(valore >= 0, -0.4, 1.3),
    # barre orizzontali (dal 2026-10-29): etichetta a destra se positiva, a sinistra se negativa
    hjust = if_else(valore >= 0, -0.15, 1.15)
  ) |>
  # ordine di pannelli, righe e barre
  mutate(
    # pannello qui è ancora testo: i livelli sono le etichette nell'ordine 15-24, 25-34, 15+
    pannello = factor(pannello, levels = unique(pannello[order(match(classe_pan, c("15-24", "25-34", "15+")))])),
    confronto = factor(confronto, levels = c("2025 su 2024", "2025 su 2019")),
    condizione = factor(condizione, levels = names(COL_CONDIZIONI))
  )
variazioni_condizione_er_prep

# tacche dell'asse: da sotto il minimo a sopra il massimo (anche le etichette devono starci)
# (fino al 2026-10-29 barre verticali, con legenda)
# tacche_var <- pretty(range(variazioni_condizione_er_prep$valore) * 1.15, n = 6)
# tacche_var
#
# plot_variazioni_condizione_er <- variazioni_condizione_er_prep |>
#   ggplot(aes(x = condizione, y = valore, fill = condizione)) +
#   geom_hline(yintercept = 0, colour = grey_sc, linewidth = 0.3) +
#   geom_col_interactive(aes(tooltip = tooltip, data_id = id), width = 0.75) +
#   geom_text(aes(label = valore_lbl, vjust = vjust), size = 3.2) +
#   facet_grid(confronto ~ pannello) +
#   scale_y_continuous(breaks = tacche_var, limits = range(tacche_var),
#                      labels = scales::label_number(suffix = "%", decimal.mark = ",", style_positive = "plus")) +
#   scale_fill_manual(values = COL_CONDIZIONI) +
#   f_theme_sito() +
#   theme(axis.text.x = element_blank(), panel.grid.major.x = element_blank(),
#         strip.text.y = element_text(angle = 0)) +
#   labs(
#     title = str_wrap(glue("Giovani in Emilia-Romagna per condizione nel lavoro: variazioni {ANNO} su 2024 e su 2019"), 60),
#     subtitle = glue("Indicatore: variazione % delle persone in ciascuna condizione (tra parentesi la popolazione {ANNO}); per 15 anni e oltre, inattivi di 15-64 anni"),
#     caption = CAP_RER, x = NULL, y = NULL
#   )
# plot_variazioni_condizione_er

# barre orizzontali (dal 2026-10-29): lo 0 è una linea verticale, le condizioni si leggono sull'asse
# (niente legenda). Tacche ogni 20 punti, da sotto il minimo a sopra il massimo, con spazio per le etichette
tacche_var <- seq(floor(min(variazioni_condizione_er_prep$valore) * 1.15 / 20) * 20,
                  ceiling(max(variazioni_condizione_er_prep$valore) * 1.15 / 20) * 20, by = 20)
tacche_var   # attese: -60 -40 -20 0 20 40

# un grafico per confronto (dal 2026-10-29: prima i due confronti erano righe di un solo grafico);
# stessa scala nei due grafici, così le barre si confrontano
f_plot_variazioni <- function(prep, conf, titolo) {
  prep |>
    filter(confronto == conf) |>
    ggplot(aes(x = valore, y = condizione, fill = condizione)) +
    geom_vline(xintercept = 0, colour = grey_sc, linewidth = 0.4) +
    geom_col_interactive(aes(tooltip = tooltip, data_id = id), width = 0.75) +
    geom_text(aes(label = valore_lbl, hjust = hjust), size = 3.2) +
    facet_wrap(~ pannello) +
    # niente tacche sull'asse x: ogni barra ha la sua etichetta, resta la linea dello zero
    # (fino al 2026-10-30, etichette sovrapposte tra i riquadri:)
    # scale_x_continuous(breaks = tacche_var, limits = range(tacche_var),
    #                    labels = scales::label_number(suffix = "%", decimal.mark = ",", style_positive = "plus")) +
    scale_x_continuous(limits = range(tacche_var), expand = expansion(mult = 0.05)) +
    # Forze di lavoro in alto (rev: l'ultimo livello sta in cima)
    scale_y_discrete(limits = rev) +
    scale_fill_manual(values = COL_CONDIZIONI, guide = "none") +
    # etichette libere di uscire dal riquadro (es. +24,7%)
    coord_cartesian(clip = "off") +
    f_theme_sito() +
    # (fino al 2026-10-30: theme(panel.grid.major.y = element_blank(), panel.spacing.x = unit(1.2, "lines")))
    theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_blank(),
          axis.text.x = element_blank(), panel.spacing.x = unit(2, "lines")) +
    labs(
      title = str_wrap(titolo, 60),
      subtitle = glue("Indicatore: variazione % delle persone in ciascuna condizione (tra parentesi la popolazione {ANNO}); per 15 anni e oltre, inattivi di 15-64 anni"),
      caption = CAP_RER, x = NULL, y = NULL
    )
}

# __ plot_variazioni_su_2024_er ----
plot_variazioni_su_2024_er <- f_plot_variazioni(
  variazioni_condizione_er_prep, "2025 su 2024",
  titolo = glue("Giovani in Emilia-Romagna per condizione nel lavoro: variazione {ANNO} su 2024")
)
plot_variazioni_su_2024_er

# __ plot_variazioni_su_2019_er ----
plot_variazioni_su_2019_er <- f_plot_variazioni(
  variazioni_condizione_er_prep, "2025 su 2019",
  titolo = glue("Giovani in Emilia-Romagna per condizione nel lavoro: variazione {ANNO} su 2019")
)
plot_variazioni_su_2019_er

# ___ Parma ed Emilia-Romagna a confronto __________________________________

# dati condivisi dai due grafici di confronto (e dal csv): UE 27, Italia, Nord-est, ER (Tab. 17-18)
# e Parma (Tab. 19, solo 25-34)
tassi_territori <- condizione_rev |>
  filter(anno == ANNO, misura == "pct", territorio %in% LIV_TERRITORI,
         indicatore %in% c("tasso_occupazione", "tasso_disoccupazione")) |>
  select(territorio, classe_eta, indicatore, sesso, valore)
count(tassi_territori, territorio, classe_eta)   # attese 6 righe per coppia; Parma solo 25-34

# punti (maschi, femmine, totale) ...
tassi_territori_prep <- tassi_territori |>
  mutate(
    # 2026-10-29: tolto il grassetto markdown su "Parma" (element_markdown sull'asse non veniva interpretato)
    territorio_lbl = factor(territorio, levels = LIV_TERRITORI),
    pannello = paste(classe_eta, "anni"),
    valore_lbl = scales::number(valore, accuracy = 0.1, decimal.mark = ",", suffix = "%"),
    tooltip = glue("{territorio}, {str_to_lower(sesso)} {classe_eta} anni: {valore_lbl}"),
    id = paste(territorio, classe_eta, indicatore, sesso),
    sesso = factor(sesso, levels = LIV_SESSO)
  )
tassi_territori_prep

# Parma 15-24 non è pubblicata: riga "n.d." perché i due pannelli abbiano gli stessi territori allineati
tassi_territori_nd <- tassi_territori_prep |>
  distinct(indicatore, pannello) |>
  filter(pannello == "15-24 anni") |>
  mutate(territorio_lbl = factor("Parma", levels = LIV_TERRITORI),
         tooltip = "Parma, 15-24 anni: dato provinciale non pubblicato nel Report")
tassi_territori_nd   # attese 2 righe (occupazione, disoccupazione)

# ... e segmenti tra femmine e maschi (lo scarto di genere)
tassi_territori_segm <- tassi_territori_prep |>
  filter(sesso != "Totale") |>
  select(territorio_lbl, pannello, indicatore, sesso, valore) |>
  pivot_wider(names_from = sesso, values_from = valore)
tassi_territori_segm

f_plot_tassi_territori <- function(punti, segm, nd, ind, titolo, sottotitolo) {
  ggplot(punti |> filter(indicatore == ind), aes(x = valore, y = territorio_lbl)) +
    geom_segment(data = segm |> filter(indicatore == ind),
                 aes(x = Femmine, xend = Maschi, y = territorio_lbl, yend = territorio_lbl),
                 colour = grey_md2, linewidth = 2) +
    geom_point_interactive(aes(colour = sesso, shape = sesso, size = sesso, tooltip = tooltip, data_id = id)) +
    # territori senza dato (Parma 15-24): "n.d." a inizio asse
    geom_text_interactive(data = nd |> filter(indicatore == ind),
                          aes(x = 0, y = territorio_lbl, label = "n.d.", tooltip = tooltip),
                          hjust = 0, colour = grey_sc, size = 3.5) +
    # asse y comune (stessi territori allineati nei due pannelli), asse x libero
    facet_wrap(~ pannello, scales = "free_x") +
    # asse da 0 fino a una tacca "tonda" oltre il massimo, in ogni pannello
    scale_x_continuous(breaks = function(lim) pretty(c(0, lim[2]), n = 4),
                       limits = function(lim) range(pretty(c(0, lim[2]), n = 4)),
                       labels = scales::label_number(suffix = "%", decimal.mark = ","),
                       expand = expansion(mult = c(0, 0.03))) +
    scale_colour_manual(values = COL_SESSO) +
    scale_shape_manual(values = c("Totale" = 124, "Maschi" = 16, "Femmine" = 16)) +
    scale_size_manual(values = c("Totale" = 7, "Maschi" = 3.5, "Femmine" = 3.5)) +
    f_theme_sito() +
    theme(panel.grid.major.y = element_blank(),
          panel.spacing.x = unit(1.5, "lines")) +
    labs(title = titolo, subtitle = sottotitolo, caption = CAP_RER, x = NULL, y = NULL)
}

# __ plot_occupazione_territori ----
plot_occupazione_territori <- f_plot_tassi_territori(
  tassi_territori_prep, tassi_territori_segm, tassi_territori_nd, "tasso_occupazione",
  titolo = str_wrap(glue("Tasso di occupazione dei giovani: Parma ed Emilia-Romagna a confronto ({ANNO})"), 60),
  sottotitolo = "Indicatore: occupati in % della popolazione della stessa età"
)
plot_occupazione_territori

# __ plot_disoccupazione_territori ----
plot_disoccupazione_territori <- f_plot_tassi_territori(
  tassi_territori_prep, tassi_territori_segm, tassi_territori_nd, "tasso_disoccupazione",
  titolo = str_wrap(glue("Tasso di disoccupazione dei giovani: Parma ed Emilia-Romagna a confronto ({ANNO})"), 60),
  sottotitolo = "Indicatore: persone in cerca di lavoro in % di chi lavora o cerca lavoro, della stessa età"
)
plot_disoccupazione_territori

# ___ Giovani all'estero (iscritti AIRE) ___________________________________

# __ aire_confronto_ft ----
# Parma ed Emilia-Romagna, 19-34 anni, 2025 (Tab. 2-3; Parma con il valore assoluto corretto in 01_dati.R);
# l'Italia non è nel Report: riga N.D. finché non c'è un'altra fonte
BG_PARMA <- "#FAECD1"   # giallo pallido di Parma, come in pop_titolo_studio

aire_confronto <- condizione_rev |>
  filter(indicatore == "iscritti_aire", anno == ANNO, classe_eta == "19-34",
         territorio %in% c("Parma", "Emilia-Romagna"),
         misura %in% c("n", "per_1000", "diff_per_1000_su_2023")) |>
  select(territorio, misura, valore) |>
  pivot_wider(names_from = misura, values_from = valore) |>
  bind_rows(tibble(territorio = "Italia")) |>
  arrange(match(territorio, c("Parma", "Emilia-Romagna", "Italia"))) |>
  # ordine esplicito delle colonne (v. skill formatting-r)
  select(Territorio = territorio,
         `Iscritti di 19-34 anni` = n,
         `Ogni 1.000 residenti di 19-34 anni` = per_1000,
         `In più ogni 1.000 rispetto al 2023` = diff_per_1000_su_2023)
aire_confronto   # attese: Parma 7.177 / 92,0 / 10,9; Emilia-Romagna 64.126 / 87,1 / 10,7; Italia N.D.

aire_confronto_ft <- aire_confronto |>
  f_ft() |>
  colformat_double(j = "Iscritti di 19-34 anni", digits = 0, na_str = "N.D.") |>
  bg(i = ~ Territorio == "Parma", bg = BG_PARMA, part = "body") |>
  f_ft_titolo_note(
    titolo = glue("Giovani di 19-34 anni residenti all'estero: Parma, Emilia-Romagna e Italia ({ANNO})"),
    note   = c("Fonte: Regione Emilia-Romagna, Report giovani 2026, su dati del Ministero dell'Interno (AIRE)",
               "Iscritti AIRE: cittadini italiani residenti all'estero da più di 12 mesi, compresi i nati all'estero con cittadinanza italiana; non sono le partenze dell'anno",
               "Parma: il Report stampa per errore i valori assoluti di Piacenza (qui corretti); Italia: dato non disponibile nella fonte")
  )
aire_confronto_ft

# 3. Salva (rds per il sito + png; csv per i bottoni di scarico; nome file = oggetto) ----
f_salva_plot(plot_occupazione_prov_er, "plot_occupazione_prov_er", dir_out = dir_mod, height = 7)
f_salva_plot(plot_disoccupazione_prov_er, "plot_disoccupazione_prov_er", dir_out = dir_mod, height = 7)
# f_salva_plot(plot_variazioni_condizione_er, "plot_variazioni_condizione_er", dir_out = dir_mod, height = 9)
f_salva_plot(plot_variazioni_su_2024_er, "plot_variazioni_su_2024_er", dir_out = dir_mod, height = 4.5)
f_salva_plot(plot_variazioni_su_2019_er, "plot_variazioni_su_2019_er", dir_out = dir_mod, height = 4.5)
f_salva_plot(plot_occupazione_territori, "plot_occupazione_territori", dir_out = dir_mod, height = 6)
f_salva_plot(plot_disoccupazione_territori, "plot_disoccupazione_territori", dir_out = dir_mod, height = 6)

write_csv(tassi_prov_er, file.path(dir_mod, "tassi_prov_er.csv"))
write_csv(variazioni_condizione_er, file.path(dir_mod, "variazioni_condizione_er.csv"))
write_csv(tassi_territori, file.path(dir_mod, "tassi_territori.csv"))

saveRDS(aire_confronto_ft, file.path(dir_mod, "aire_confronto_ft.rds"))
write_csv(aire_confronto, file.path(dir_mod, "aire_confronto.csv"))
