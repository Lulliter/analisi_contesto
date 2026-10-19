# ___________________________________________________________________________
# Modulo: anziani_non_autosuff
# Scopo:  due tabelle (Parma / ER / Italia × 2024 / 2036 / 2050: quanti anziani; quanti
#         non autosufficienti) e due grafici su Parma per classe d'età, 2024 / 2036 / 2050
#         (popolazione e di cui non autosufficienti; persone con demenza) + piramide delle demenze per sesso (2024) per la pagina Anziani
# Input:  output/anziani_stima_tot.rds, output/anziani_stima.rds, output/anziani_demenze_sesso.rds (da 01_dati.R)
# Output: output/tab_anziani_territori_ft.rds (+ .csv), output/tab_non_autosuff_ft.rds (+ .csv),
#         output/plot_stima_classi_pr.rds, output/plot_demenze_classi_pr.rds, output/plot_demenze_sesso_pr.rds (+ .png + .csv)
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(glue)
library(ggplot2)
library(ggiraph)
library(ggtext)

source(here("R", "_parma_colors.R"))
source(here("R", "grafici.R"))      # temi, caption, salvataggio
source(here("R", "formatting.R"))   # f_ft, f_ft_titolo_note (tabelle)

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "anziani_non_autosuff", "output")

ANNO_OGGI    <- 2024
ANNI_TABELLA <- c(2024, 2036, 2050)
ANNI_GRAFICO <- c(2024, 2036, 2050) # tre pannelli: il 2050 mostra l'onda degli 85+ che il 2036 non vede
LIV_QUINQ    <- c("65-69", "70-74", "75-79", "80-84", "85-89", "90+")   # classi della piramide (come in 01)

# caption: nota sulla stima (una riga, avvolta a 130 caratteri come le fonti) + fonte
NOTA_STIMA <- f_avvolgi_caption("Nota: stima = quota di anziani con gravi difficoltà rilevata da ISTAT nel 2019 per classe di età (65-74: 14,6%; 75-84: 32,5%; 85+: 63,8%), applicata assumento quote come 2024")
CAP_STIME  <- paste(NOTA_STIMA,
                    f_caption_fonte("ISTAT, censimento 2024 e previsioni 2024-2050 (scenario mediano); EHIS 2019; CERGAS Bocconi, Osservatorio Long Term Care (metodo)"),
                    sep = "\n")

# 1. Carica dati pronti ----------------------------------------------------
anziani_stima_tot <- readRDS(file.path(dir_mod, "anziani_stima_tot.rds"))
anziani_stima     <- readRDS(file.path(dir_mod, "anziani_stima.rds"))

# formati per le tabelle: anno come testo (colformat_int metterebbe il punto), con asterisco
# sugli anni di previsione, come nel grafico
f_anno_txt <- function(x) ifelse(x == ANNO_OGGI, as.character(x), paste0(x, "*"))
NOTA_ANNI <- "2024 = censimento al 31 dicembre; * e sfondo azzurro = popolazione da previsioni ISTAT, scenario mediano, base 1° gennaio 2024."
# sfondo delle righe di previsione: bg_previsione da R/formatting.R (v1.4)
BG_PREVISIONE <- bg_previsione

# 2. Tabella: quanti anziani, 3 territori × 3 anni --------------------------
tab_territori_prep <- anziani_stima_tot |>
  filter(anno %in% ANNI_TABELLA) |>
  mutate(anno = f_anno_txt(anno)) |>
  select(territorio, anno, pop_totale, n65_piu, p65_piu, n80_piu, p80_piu, ind_dip_anziani) |>
  arrange(territorio, anno)

tab_territori_prep

# __ tab_anziani_territori_ft ----
tab_anziani_territori_ft <- tab_territori_prep |>
  f_ft() |>
  colformat_double(j = c("pop_totale", "n65_piu", "n80_piu"), digits = 0) |>
  # percentuali con il simbolo nella cella
  colformat_double(j = c("p65_piu", "p80_piu"), digits = 1, suffix = "%") |>
  set_header_labels(territorio = "", anno = "Anno", pop_totale = "Residenti",
                    n65_piu = "n", p65_piu = "sui residenti", n80_piu = "n", p80_piu = "sui residenti",
                    ind_dip_anziani = "ogni 100 di 15-64 anni") |>
  add_header_row(values = c("", "", "", "65 anni e più", "80 anni e più", "Anziani"),
                 colwidths = c(1, 1, 1, 2, 2, 1)) |>
  merge_v(j = "territorio") |>
  valign(j = "territorio", valign = "top") |>
  align(align = "center", part = "header") |>
  bg(i = ~ grepl("\\*", anno), j = -1, bg = BG_PREVISIONE, part = "body") |>
  bold(j = "n65_piu", part = "body") |>
  f_ft_titolo_note(
    titolo = "Anziani e grandi anziani: Parma, Emilia-Romagna, Italia (2024, 2036, 2050)",
    note = c(NOTA_ANNI,
             "Ultima colonna: indice di dipendenza anziani (persone di 65 anni e più ogni 100 di 15-64 anni; può superare 100).",
             "Fonte: ISTAT, censimento permanente 2024 e previsioni della popolazione 2024-2050.")
  )

tab_anziani_territori_ft

# 3. Tabella: quanti non autosufficienti, 3 territori × 3 anni --------------
tab_non_autosuff_prep <- anziani_stima_tot |>
  filter(anno %in% ANNI_TABELLA) |>
  mutate(anno = f_anno_txt(anno)) |>
  select(territorio, anno, n65_piu, non_autosuff, pct_non_autosuff, assist_contin, pct_assist_contin,
         demenze, pct_demenze) |>
  arrange(territorio, anno)

tab_non_autosuff_prep

# __ tab_non_autosuff_ft ----
tab_non_autosuff_ft <- tab_non_autosuff_prep |>
  f_ft() |>
  colformat_double(j = c("n65_piu", "non_autosuff", "assist_contin", "demenze"), digits = 0) |>
  colformat_double(j = c("pct_non_autosuff", "pct_assist_contin", "pct_demenze"), digits = 1, suffix = "%") |>
  set_header_labels(territorio = "", anno = "Anno", n65_piu = "65 anni e più",
                    non_autosuff = "n", pct_non_autosuff = "sui 65+",
                    assist_contin = "n", pct_assist_contin = "sui 65+",
                    demenze = "n", pct_demenze = "sui 65+") |>
  add_header_row(values = c("", "", "", "Non autosufficienti", "di cui con assistenza continuativa", "Con demenza"),
                 colwidths = c(1, 1, 1, 2, 2, 2)) |>
  merge_v(j = "territorio") |>
  valign(j = "territorio", valign = "top") |>
  align(align = "center", part = "header") |>
  bg(i = ~ grepl("\\*", anno), j = -1, bg = BG_PREVISIONE, part = "body") |>
  bold(j = "non_autosuff", part = "body") |>
  f_ft_titolo_note(
    titolo = "Anziani non autosufficienti e con demenza, stima: Parma, Emilia-Romagna, Italia (2024, 2036, 2050)",
    note = c(NOTA_ANNI,
             "Nota: stima = quota di anziani con gravi difficoltà rilevata da ISTAT nel 2019 per classe di età (65-74, 75-84, 85 e più), applicata alla popolazione di ogni classe come se non cambiasse. Non autosufficienti = gravi difficoltà in almeno una attività di cura della persona o domestica (definizione Osservatorio Long Term Care); con assistenza continuativa = gravi difficoltà nella cura della persona. Demenza = tassi di prevalenza per sesso e classe quinquennale dell'Osservatorio Demenze ISS (Report 2024); con i tassi europei più recenti (Alzheimer Europe 2025) la stima sarebbe più alta di circa un sesto. Le tre stime non si sommano: chi ha una demenza è in gran parte anche non autosufficiente.",
             "Fonte: ISTAT, EHIS 2019 (prevalenze), censimento 2024 e previsioni 2024-2050 (popolazione); CERGAS Bocconi, Osservatorio Long Term Care (metodo); ISS, Osservatorio Demenze (tassi di demenza).")
  )

tab_non_autosuff_ft

# 4. Grafico: Parma per classe d'età, autosufficienti e non, 2024 / 2036 / 2050 -----
# barre impilate = tutti gli anziani della classe, divise in non autosufficienti (stima,
# definizione larga) e autosufficienti; un pannello per anno
stima_classi_pr_prep <- anziani_stima |>
  filter(territorio == "Provincia di Parma", anno %in% ANNI_GRAFICO,
         indicatore == "gravi_limitazioni_funzionali") |>
  mutate(autosuff = popolazione - n_stimato) |>
  select(anno, classe_eta, popolazione, prevalenza, "Non autosufficienti (stima)" = n_stimato, "Autosufficienti" = autosuff) |>
  pivot_longer(c("Non autosufficienti (stima)", "Autosufficienti"), names_to = "condizione", values_to = "n") |>
  mutate(condizione = factor(condizione, levels = c("Autosufficienti", "Non autosufficienti (stima)")),
         anno = factor(anno),
         etichetta = scales::number(n, big.mark = ".", decimal.mark = ","),
         # tooltip corto: la quota del pezzo sulla classe ("Autosufficienti: 85,4%")
         pct_pezzo = if_else(condizione == "Autosufficienti", 100 - prevalenza, prevalenza),
         pct_txt = paste0(scales::number(pct_pezzo, accuracy = 0.1, decimal.mark = ","), "%"),
         tooltip = glue("{condizione}: {pct_txt}"))

stima_classi_pr_prep

# etichette: il n di ciascun pezzo al centro del pezzo (bianco sul rosso, scuro sul grigio) e il
# totale della classe sopra la barra; la % della classe sta nel tooltip
COL_TESTO <- c("Autosufficienti" = grey_extra_sc, "Non autosufficienti (stima)" = "white")
classi_tot <- stima_classi_pr_prep |>
  distinct(anno, classe_eta, popolazione) |>
  mutate(etichetta_tot = scales::number(popolazione, big.mark = ".", decimal.mark = ","))

# colori: rosso = anziani / invecchiamento (convenzione _parma_colors.R) per il bisogno, grigio per il resto
COL_COND <- c("Autosufficienti" = grey_md2, "Non autosufficienti (stima)" = seq_factor_red[7])

# etichette dell'asse x: asterisco sugli anni di previsione (vettore nominato, niente funzioni
# dentro il ggplot: l'rds si valuta al render del sito)
LAB_ANNI <- setNames(ifelse(ANNI_GRAFICO == ANNO_OGGI, ANNI_GRAFICO, paste0(ANNI_GRAFICO, "*")), ANNI_GRAFICO)

# asse y: tacche a passo fisso fino al multiplo che include il massimo (regola del sito)
PASSO_Y <- 10000
lim_y   <- ceiling(max(stima_classi_pr_prep$popolazione) * 1.05 / PASSO_Y) * PASSO_Y   # spazio per il totale sopra la barra

# __ plot_stima_classi_pr ----
# un pannello per classe d'età, gli anni sull'asse x: si legge la crescita nel tempo dentro ogni classe
plot_stima_classi_pr <- stima_classi_pr_prep |>
  ggplot(aes(x = anno, y = n, fill = condizione)) +
  # riquadro azzurro sugli anni di previsione (stesso colore delle righe di previsione nelle
  # tabelle), disegnato prima delle barre; 1,5 = metà tra la prima barra (2024) e la seconda
  annotate("rect", xmin = 1.5, xmax = Inf, ymin = -Inf, ymax = Inf, fill = BG_PREVISIONE) +
  geom_col_interactive(aes(tooltip = tooltip, data_id = interaction(anno, classe_eta, condizione)),
                       position = position_stack(), width = 0.7) +
  # asterisco sugli anni di previsione (spiegato nel sottotitolo); etichette calcolate fuori dal ggplot
  scale_x_discrete(labels = LAB_ANNI) +
  geom_text(aes(label = etichetta, color = condizione), position = position_stack(vjust = 0.5),
            size = 3.2, show.legend = FALSE) +
  scale_color_manual(values = COL_TESTO, guide = "none") +
  geom_text(data = classi_tot, aes(x = anno, y = popolazione, label = etichetta_tot),
            inherit.aes = FALSE, vjust = -0.5, size = 3.2, fontface = "bold", color = grey_extra_sc) +
  facet_wrap(~ classe_eta, ncol = 3, labeller = labeller(classe_eta = function(x) paste(x, "anni"))) +
  scale_fill_manual(values = COL_COND, name = NULL) +
  scale_y_continuous(breaks = seq(0, lim_y, by = PASSO_Y), limits = c(0, lim_y),
                     labels = function(x) scales::number(x, big.mark = ".", decimal.mark = ",")) +
  f_theme_sito() +
  theme(panel.grid.major.x = element_blank()) +
  labs(
    title = str_wrap(glue("Anziani autosufficienti e non, per classe di età, provincia di Parma ({paste(ANNI_GRAFICO, collapse = ', ')})"), 60),
    subtitle = "Indicatore: n. di residenti della classe di età, di cui stimati da noi non autosufficienti (gravi difficoltà in almeno una attività di cura della persona o domestica). * = popolazione da previsioni ISTAT (2024 = censimento)",
    caption = CAP_STIME, x = "", y = ""
  )

plot_stima_classi_pr

# 4b. Grafico: demenze stimate a Parma per classe d'età, 2024 / 2036 / 2050 ----
# stesso impianto del grafico sopra (pannelli per classe, anni sull'asse x), una sola barra:
# i casi stimati. Il dettaglio per sesso sta nel testo (solo 2024: il rapporto cambia poco)
anziani_demenze_sesso <- readRDS(file.path(dir_mod, "anziani_demenze_sesso.rds"))

demenze_classi_pr_prep <- anziani_demenze_sesso |>
  filter(territorio == "Provincia di Parma", anno %in% ANNI_GRAFICO) |>
  # dalle classi quinquennali alle tre classi dell'altro grafico; tasso della classe = casi / residenti
  mutate(classe_eta = case_when(classe_quinq %in% c("65-69", "70-74") ~ "65-74",
                                classe_quinq %in% c("75-79", "80-84") ~ "75-84",
                                TRUE ~ "85+"),
         classe_eta = factor(classe_eta, levels = c("65-74", "75-84", "85+"))) |>
  summarise(casi = sum(casi), popolazione = sum(popolazione), .by = c(anno, classe_eta)) |>
  mutate(anno = factor(anno),
         tasso = 100 * casi / popolazione,
         etichetta = scales::number(casi, big.mark = ".", decimal.mark = ","),
         tasso_txt = paste0(scales::number(tasso, accuracy = 0.1, decimal.mark = ","), "%"),
         # tooltip corto: tasso sulla classe e denominatore ("4,5% su 24.300")
         pop_txt = scales::number(popolazione, big.mark = ".", decimal.mark = ","),
         tooltip = glue("{tasso_txt} su {pop_txt}"))

demenze_classi_pr_prep

PASSO_Y_DEM <- 1000
lim_y_dem   <- ceiling(max(demenze_classi_pr_prep$casi) * 1.08 / PASSO_Y_DEM) * PASSO_Y_DEM

NOTA_DEMENZE <- f_avvolgi_caption("Nota: stima = tassi di prevalenza per sesso ed età usati dall'ISS (Bacigalupo et al. 2018) applicati alla popolazione residente; non comprende le demenze sotto i 65 anni")
CAP_DEMENZE  <- paste(NOTA_DEMENZE,
                      f_caption_fonte("ISS, Report Nazionale 2024 del Fondo per l'Alzheimer e le demenze (tassi); ISTAT, censimento 2024 e previsioni 2024-2050 (scenario mediano)"),
                      sep = "\n")

# __ plot_demenze_classi_pr ----
plot_demenze_classi_pr <- demenze_classi_pr_prep |>
  ggplot(aes(x = anno, y = casi)) +
  # riquadro azzurro sugli anni di previsione (stesso colore delle righe di previsione nelle
  # tabelle), disegnato prima delle barre; 1,5 = metà tra la prima barra (2024) e la seconda
  annotate("rect", xmin = 1.5, xmax = Inf, ymin = -Inf, ymax = Inf, fill = BG_PREVISIONE) +
  geom_col_interactive(aes(tooltip = tooltip, data_id = interaction(anno, classe_eta)),
                       fill = seq_factor_red[7], width = 0.7) +
  scale_x_discrete(labels = LAB_ANNI) +
  geom_text(aes(label = etichetta), vjust = -0.5, size = 3.2, fontface = "bold", color = grey_extra_sc) +
  facet_wrap(~ classe_eta, ncol = 3, labeller = labeller(classe_eta = function(x) paste(x, "anni"))) +
  scale_y_continuous(breaks = seq(0, lim_y_dem, by = PASSO_Y_DEM), limits = c(0, lim_y_dem),
                     labels = function(x) scales::number(x, big.mark = ".", decimal.mark = ",")) +
  f_theme_sito() +
  theme(panel.grid.major.x = element_blank()) +
  labs(
    title = str_wrap(glue("Persone con demenza (stima) per classe di età, provincia di Parma ({paste(ANNI_GRAFICO, collapse = ', ')})"), 60),
    subtitle = "Indicatore: n. stimato di residenti di 65 anni e più con demenza. * = popolazione da previsioni ISTAT (2024 = censimento)",
    caption = CAP_DEMENZE, x = "", y = ""
  )

plot_demenze_classi_pr

# 4c. Grafico: piramide delle demenze stimate a Parma per sesso, solo 2024 ----
# maschi a sinistra, femmine a destra (come p03_piramide_pr in demo_trend_previs); il
# rapporto donne/uomini cambia poco nel tempo, quindi basta il 2024
demenze_sesso_pr_prep <- anziani_demenze_sesso |>
  filter(territorio == "Provincia di Parma", anno == ANNO_OGGI) |>
  mutate(sesso = factor(sesso, levels = c("Maschi", "Femmine")),
         classe_quinq = factor(classe_quinq, levels = LIV_QUINQ),
         # valori negativi per i maschi: la barra va a sinistra dello zero
         casi_s = if_else(sesso == "Maschi", -casi, casi),
         # allineamento dell'etichetta calcolato qui, non dentro aes(): l'rds si valuta al render
         # del sito, dove dplyr non è caricato
         hjust_lab = if_else(sesso == "Maschi", 1.15, -0.15),
         etichetta = scales::number(casi, big.mark = ".", decimal.mark = ","),
         tasso_txt = paste0(scales::number(tasso, accuracy = 0.1, decimal.mark = ","), "%"),
         tooltip = glue("{sesso} {classe_quinq}: {etichetta} casi (tasso {tasso_txt})"))

demenze_sesso_pr_prep

# colori maschi / femmine della palette (come le piramidi del sito)
COL_SESSO <- c("Maschi" = maschi, "Femmine" = femmine)

# asse x simmetrico, tacche a passo fisso fino al multiplo che include il massimo (+ spazio etichette)
PASSO_X_PIR <- 500
lim_x_pir   <- ceiling(max(demenze_sesso_pr_prep$casi) * 1.15 / PASSO_X_PIR) * PASSO_X_PIR

# __ plot_demenze_sesso_pr ----
plot_demenze_sesso_pr <- demenze_sesso_pr_prep |>
  ggplot(aes(x = casi_s, y = classe_quinq, fill = sesso)) +
  geom_col_interactive(aes(tooltip = tooltip, data_id = interaction(sesso, classe_quinq)), width = 0.85) +
  geom_vline(xintercept = 0, colour = "white", linewidth = 0.2) +
  # n in fondo a ogni barra, fuori dalla barra (a sinistra per i maschi, a destra per le femmine)
  geom_text(aes(label = etichetta, hjust = hjust_lab), size = 3.2, color = grey_extra_sc) +
  scale_x_continuous(breaks = seq(-lim_x_pir, lim_x_pir, by = PASSO_X_PIR), limits = c(-lim_x_pir, lim_x_pir),
                     labels = function(x) scales::number(abs(x), big.mark = ".", decimal.mark = ",")) +
  scale_fill_manual(values = COL_SESSO, name = NULL) +
  f_theme_sito_piramide() +
  labs(
    title = str_wrap(glue("Persone con demenza (stima) per età e sesso, provincia di Parma ({ANNO_OGGI})"), 60),
    subtitle = "Indicatore: n. stimato di residenti con demenza per classe di età e sesso (censimento 2024)",
    caption = CAP_DEMENZE, x = "", y = ""
  )

plot_demenze_sesso_pr

# 5. Salva (rds per il sito + png + csv; nome file = oggetto) ---------------
f_salva_plot(plot_stima_classi_pr, "plot_stima_classi_pr", dir_mod, height = 6)
write_csv(stima_classi_pr_prep |> select(-tooltip, -etichetta, -pct_txt), file.path(dir_mod, "plot_stima_classi_pr.csv"))
f_salva_plot(plot_demenze_classi_pr, "plot_demenze_classi_pr", dir_mod, height = 6)
f_salva_plot(plot_demenze_sesso_pr, "plot_demenze_sesso_pr", dir_mod, height = 5.5)
write_csv(demenze_sesso_pr_prep |> select(-tooltip, -etichetta, -tasso_txt, -casi_s, -hjust_lab), file.path(dir_mod, "plot_demenze_sesso_pr.csv"))
write_csv(demenze_classi_pr_prep |> select(-tooltip, -etichetta, -tasso_txt, -pop_txt), file.path(dir_mod, "plot_demenze_classi_pr.csv"))

saveRDS(tab_anziani_territori_ft, file.path(dir_mod, "tab_anziani_territori_ft.rds"))
write_csv(tab_territori_prep, file.path(dir_mod, "tab_anziani_territori_ft.csv"))
saveRDS(tab_non_autosuff_ft, file.path(dir_mod, "tab_non_autosuff_ft.rds"))
write_csv(tab_non_autosuff_prep, file.path(dir_mod, "tab_non_autosuff_ft.csv"))
