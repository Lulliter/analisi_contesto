# ___________________________________________________________________________
# Modulo: anziani_non_autosuff
# Scopo:  tabelle per territorio (Parma / ER / Italia × 2024 / 2036 / 2050): quanti anziani e
#         condizioni degli anziani (non autosufficienti, demenza, disabilità, gravi difficoltà);
#         due grafici su Parma per classe d'età, 2024 / 2036 / 2050
#         (popolazione e di cui non autosufficienti; persone con demenza) + piramide delle demenze per sesso (2024) per la pagina Anziani
#         + trend della quota di 65+ e 80+ 2024-2050 (province ER, ER, Italia) con linee su 2036 e 2050
# Input:  output/anziani_stima_tot.rds, output/anziani_stima.rds, output/anziani_demenze_sesso.rds,
#         output/anziani_quadro.rds (da 01_dati.R)
#         dati/puliti/istat_previsioni/previs_struttura_territori.rds (da ingestione/03)
# Output: output/tab_pop_pr_ft.rds, tab_pop_er_ft.rds, tab_pop_it_ft.rds + tab_pop_ft.csv: quanti anziani per
#           territorio (fino al 2026-10-20: tab_anziani_territori_ft)
#         output/plot_stima_classi_pr.rds, output/plot_demenze_classi_pr.rds, output/plot_demenze_sesso_pr.rds,
#         output/plot_quota_anziani.rds (+ .png + .csv)
#         output/tab_quadro_pr_ft.rds, tab_quadro_er_ft.rds, tab_quadro_it_ft.rds + tab_quadro_ft.csv:
#           condizioni degli anziani per territorio, una tabella per scheda del tabset (2026-10-20)
# NB (2026-10-20): "non autosufficienti" = gravi difficoltà nella cura della persona (ADL); prima
#     erano le gravi limitazioni funzionali della Tab. 1.2 CERGAS (v. 01_dati.R)
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
library(purrr)

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
# (fino al 2026-10-19: "Nota: stima = quota di anziani con gravi difficoltà rilevata da ISTAT nel 2019 per
#  classe di età (65-74: 14,6%; 75-84: 32,5%; 85+: 63,8%), applicata assumento quote come 2024")
NOTA_STIMA <- f_avvolgi_caption("Nota: stima = quota di anziani con gravi difficoltà nella cura della persona rilevata da ISTAT nel 2019 per classe di età (65-74: 2,6%; 75-84: 10,3%; 85+: 37,2%), applicata alla popolazione di ogni classe come se non cambiasse")
CAP_STIME  <- paste(NOTA_STIMA,
                    f_caption_fonte("ISTAT, censimento 2024 e previsioni 2024-2050 (scenario mediano); EHIS 2019; CERGAS Bocconi, Osservatorio Long Term Care (metodo)"),
                    sep = "\n")

# 1. Carica dati pronti ----------------------------------------------------
anziani_stima_tot <- readRDS(file.path(dir_mod, "anziani_stima_tot.rds"))
anziani_stima     <- readRDS(file.path(dir_mod, "anziani_stima.rds"))

# formati per le tabelle: anno come testo (colformat_int metterebbe il punto), con asterisco
# sugli anni di previsione, come nel grafico
f_anno_txt <- function(x) ifelse(x == ANNO_OGGI, as.character(x), paste0(x, "*"))
NOTA_ANNI <- "2024 = censimento; * = previsioni ISTAT 2024-2050, scenario mediano."
# sfondo degli anni di previsione nei grafici (riquadro azzurro): bg_previsione da R/formatting.R (v1.4);
# nelle tabelle dal 2026-10-20 niente sfondo, basta l'asterisco
BG_PREVISIONE <- bg_previsione

# 2. Tabelle per territorio: quanti anziani, 2024 / 2036 / 2050 ----------------
# (2026-10-20, sostituisce tab_anziani_territori_ft) anni in colonna come nelle tabelle delle
# condizioni (§ 3), una tabella per territorio nel tabset della pagina. Righe: residenti, 65+ e 80+
# (n e % sui residenti), 80+ in % sui 65+ e indice di dipendenza ("ogni 100", non una %), senza n
INDICATORI_POP <- tribble(
  ~indicatore, ~etichetta,
  "pop_totale", "Residenti",
  "n65_piu", "65 anni e più",
  "n80_piu", "80 anni e più",
  "quota_grandi_anziani", "80 anni e più, % sui 65+",
  "ind_dip_anziani", "Indice di dipendenza anziani (65+ ogni 100 di 15-64 anni)"
)

# dati lunghi: territorio × anno × indicatore, con n e valore relativo (% o indice)
tab_pop_prep <- anziani_stima_tot |>
  filter(anno %in% ANNI_TABELLA) |>
  transmute(territorio, anno,
            pop_totale_n = pop_totale, pop_totale_rel = NA_real_,
            n65_piu_n = n65_piu, n65_piu_rel = p65_piu,
            n80_piu_n = n80_piu, n80_piu_rel = p80_piu,
            quota_grandi_anziani_n = NA_real_, quota_grandi_anziani_rel = round(n80_piu / n65_piu * 100, 1),
            ind_dip_anziani_n = NA_real_, ind_dip_anziani_rel = ind_dip_anziani) |>
  pivot_longer(-c(territorio, anno), names_to = c("indicatore", ".value"), names_pattern = "(.*)_(n|rel)$") |>
  inner_join(INDICATORI_POP, by = "indicatore") |>
  mutate(indicatore = factor(indicatore, levels = INDICATORI_POP$indicatore),
         # testo delle celle: n con il punto delle migliaia; % con il simbolo; indici senza; vuoto se manca
         n_txt = if_else(is.na(n), "", scales::number(n, big.mark = ".", decimal.mark = ",")),
         rel_txt = case_when(
           is.na(rel) ~ "",
           # l'indice di dipendenza non è una % (65+ e 15-64 sono gruppi diversi): senza simbolo
           indicatore == "ind_dip_anziani" ~ scales::number(rel, accuracy = 0.1, decimal.mark = ","),
           TRUE ~ paste0(scales::number(rel, accuracy = 0.1, decimal.mark = ","), "%")
         )) |>
  arrange(territorio, anno, indicatore)

tab_pop_prep

# riga dell'indice di dipendenza su fondo rosso pallido (palette rossa = anziani, come la riga dei
# non autosufficienti nelle tabelle delle condizioni): è l'indicatore di carico, e non è una %
BG_INDICE <- seq_factor_red[2]

# una flextable per territorio: indicatore, poi n e % (o indice) per anno
f_tab_pop <- function(terr) {
  dati <- tab_pop_prep |>
    filter(territorio == terr) |>
    select(etichetta, anno, n_txt, rel_txt) |>
    pivot_wider(names_from = anno, values_from = c(n_txt, rel_txt), names_vary = "slowest")
  dati |>
    f_ft() |>
    set_header_labels(values = c(list(etichetta = ""),
                                 setNames(as.list(rep("n", length(ANNI_TABELLA))), paste0("n_txt_", ANNI_TABELLA)),
                                 setNames(as.list(rep("% o indice", length(ANNI_TABELLA))), paste0("rel_txt_", ANNI_TABELLA)))) |>
    add_header_row(values = c("", f_anno_txt(ANNI_TABELLA)), colwidths = c(1, rep(2, length(ANNI_TABELLA)))) |>
    align(j = -1, align = "right", part = "body") |>
    align(align = "center", part = "header") |>
    bg(i = ~ etichetta == INDICATORI_POP$etichetta[INDICATORI_POP$indicatore == "ind_dip_anziani"],
       bg = BG_INDICE, part = "body") |>
    # layout fisso, altrimenti in HTML l'autofit di f_ft() ignora width()
    set_table_properties(layout = "fixed", opts_word = list(split = FALSE, repeat_headers = TRUE)) |>
    width(j = "etichetta", width = 2.6) |>
    f_ft_titolo_note(
      titolo = glue("Anziani e grandi anziani: {terr} (2024, 2036, 2050)"),
      note = c(NOTA_ANNI,
               "% sui residenti, salvo dove indicato. Indice di dipendenza anziani (riga colorata) = persone di 65 anni e più ogni 100 di 15-64 anni: non è una percentuale (i due gruppi sono distinti) e può superare 100.",
               "Fonte: ISTAT, censimento permanente 2024 e previsioni della popolazione 2024-2050, scenario mediano.")
    )
}

# __ tab_pop_ft ----
tab_pop_ft <- map(c(pr = "Provincia di Parma", er = "Emilia-Romagna", it = "Italia"), f_tab_pop)

tab_pop_ft$pr

# 3. Tabelle per territorio: condizioni degli anziani, 2024 / 2036 / 2050 ----
# (2026-10-20, sostituisce tab_non_autosuff_ft) una tabella per territorio (schede del tabset
# nella pagina); righe = condizioni in
# ordine e testi del quadro di riferimento, con definizione; colonne = n e % sui 65+ per anno
anziani_quadro <- readRDS(file.path(dir_mod, "anziani_quadro.rds"))

# condizioni: etichetta e definizione come nel quadro di riferimento
# (claude_outputs/quadro_anziani_fragili.qmd); ordine: totale, poi da lieve a grave
CONDIZIONI <- tribble(
  ~indicatore, ~condizione, ~definizione,
  "n65_piu", "Totale: residenti di 65 anni e più",
    "Base delle percentuali",
  "nessuna_grave_difficolta_adl_o_iadl", "Senza gravi difficoltà nelle attività quotidiane",
    "Nessuna grave difficoltà in ADL o IADL; può avere difficoltà moderate",
  "gali_grave", "Con disabilità (GALI grave)",
    "Dichiara limitazioni gravi, per motivi di salute e da almeno 6 mesi, nelle attività che le persone svolgono abitualmente. Una sola domanda generale: non misura l'autonomia in attività specifiche",
  "gravi_difficolta_adl_o_iadl", "Con almeno una grave difficoltà nelle attività quotidiane (ADL o IADL)",
    "\u201cMolta difficoltà\u201d o \u201cnon sono in grado\u201d in almeno una attività di cura della persona (ADL) o della vita domestica (IADL: pasti, spesa, farmaci, gestione del denaro, lavori domestici leggeri e pesanti occasionali). Solo difficoltà gravi, nessun criterio di durata",
  "gravi_difficolta_adl", "di cui non autosufficienti nella cura della persona (ADL)",
    "Gravi difficoltà in almeno una attività di cura della persona: lavarsi, vestirsi, alzarsi dal letto o dalla sedia, usare il bagno, mangiare. Non significa dipendenza totale né permanente",
  "demenze", "Con demenza",
    "Alzheimer e altre demenze: stima con i tassi per età e sesso dell'Istituto Superiore di Sanità"
)

# apice della fonte per condizione: rimanda ai numeri della riga "Fonti:" nelle note
APICE_FONTE <- c(n65_piu = "¹", nessuna_grave_difficolta_adl_o_iadl = "²", gali_grave = "³",
                 gravi_difficolta_adl_o_iadl = "²", gravi_difficolta_adl = "²", demenze = "⁴")

# dati lunghi: quadro (§ 6 di 01_dati.R) + demenze e totale 65+ da anziani_stima_tot
tab_quadro_prep <- bind_rows(
  anziani_quadro |>
    transmute(territorio, anno, indicatore = as.character(indicatore), n = n_stimato, pct = pct_65_piu),
  anziani_stima_tot |>
    transmute(territorio, anno, indicatore = "demenze", n = demenze, pct = pct_demenze),
  anziani_stima_tot |>
    transmute(territorio, anno, indicatore = "n65_piu", n = n65_piu, pct = 100)
) |>
  filter(anno %in% ANNI_TABELLA) |>
  inner_join(CONDIZIONI, by = "indicatore") |>
  mutate(condizione_apice = paste0(condizione, APICE_FONTE[indicatore]),
         indicatore = factor(indicatore, levels = CONDIZIONI$indicatore),
         # stime arrotondate alle centinaia (ordine di grandezza); il totale resta esatto
         n = if_else(indicatore == "n65_piu", n, round(n, -2))) |>
  arrange(territorio, anno, indicatore)

tab_quadro_prep

# righe evidenziate (_parma_colors.R): non autosufficienza (ADL) in rosso pallido (palette anziani);
# disabilità e demenza, che vengono da altre fonti, in viola pallido; le altre righe senza colore
BG_CONDIZIONI <- c(
  "di cui non autosufficienti nella cura della persona (ADL)"              = seq_factor_red[2],
  "Con disabilità (GALI grave)"                                            = seq_dummy_purple[1],
  "Con demenza"                                                            = seq_dummy_purple[1]
)

# colora le righe delle condizioni in BG_CONDIZIONI (una chiamata bg() per condizione)
f_bg_condizioni <- function(ft) {
  reduce(names(BG_CONDIZIONI), function(ft, cond) {
    # l'etichetta in tabella ha l'apice della fonte in coda: lo tolgo per il confronto
    bg(ft, i = which(sub("[¹²³⁴]$", "", ft$body$dataset$condizione) == cond), bg = BG_CONDIZIONI[[cond]], part = "body")
  }, .init = ft)
}

# una flextable per territorio: condizione, definizione, poi n e % per anno
f_tab_quadro <- function(terr) {
  dati <- tab_quadro_prep |>
    filter(territorio == terr) |>
    select(condizione = condizione_apice, definizione, anno, n, pct) |>
    pivot_wider(names_from = anno, values_from = c(n, pct), names_vary = "slowest")
  dati |>
    f_ft() |>
    colformat_double(j = paste0("n_", ANNI_TABELLA), digits = 0) |>
    colformat_double(j = paste0("pct_", ANNI_TABELLA), digits = 1, suffix = "%") |>
    set_header_labels(values = c(list(condizione = "Condizione dell'anziano", definizione = "Definizione operativa"),
                                 setNames(as.list(rep("n", length(ANNI_TABELLA))), paste0("n_", ANNI_TABELLA)),
                                 setNames(as.list(rep("sui 65+", length(ANNI_TABELLA))), paste0("pct_", ANNI_TABELLA)))) |>
    add_header_row(values = c("", "", f_anno_txt(ANNI_TABELLA)), colwidths = c(1, 1, rep(2, length(ANNI_TABELLA)))) |>
    align(align = "center", part = "header") |>
    # righe evidenziate con il colore della condizione
    f_bg_condizioni() |>
    # riga del totale (la prima) in corsivo: è la base, non una condizione
    italic(i = 1, part = "body") |>
    width(j = "condizione", width = 1.8) |>
    # layout fisso, altrimenti in HTML l'autofit di f_ft() ignora width()
    set_table_properties(layout = "fixed", opts_word = list(split = FALSE, repeat_headers = TRUE)) |>
    width(j = "definizione", width = 3.2) |>
    f_ft_titolo_note(
      titolo = glue("Anziani per condizione, stima: {terr} (2024, 2036, 2050)"),
      note = c("NB: le righe non vanno sommate: i non autosufficienti sono compresi in chi ha almeno una grave difficoltà; disabilità e demenza vengono da altre fonti e si sovrappongono alle altre righe.",
               "n = stima arrotondata alle centinaia; % sui residenti di 65 anni e più.",
               NOTA_ANNI,
               "Stima: quote per classe di età costanti nel tempo; per disabilità e gravi difficoltà solo due classi (65-74, 75+), quindi la crescita al 2050 è sottostimata.",
               "Fonti: ¹ ISTAT, censimento 2024 e previsioni 2024-2050; ² ISTAT, EHIS 2019; ³ ISTAT, Disabilità in cifre 2023 (quote dell'Emilia-Romagna); ⁴ ISS, Osservatorio Demenze 2024.")
    )
}

# __ tab_quadro_ft ----
tab_quadro_ft <- map(c(pr = "Provincia di Parma", er = "Emilia-Romagna", it = "Italia"), f_tab_quadro)

# __ PREVIEW ----

tab_quadro_ft$pr
tab_quadro_ft$er
tab_quadro_ft$it

# 4. Grafico: non autosufficienti a Parma per classe d'età, 2024 / 2036 / 2050 ----
# (2026-10-20) stesso impianto del grafico delle demenze (§ 4b): pannelli per classe, anni
# sull'asse x, una sola barra con i non autosufficienti nella cura della persona (ADL, stima);
# etichette come nella tabella delle condizioni (§ 3), che è il riferimento per le definizioni
stima_classi_pr_prep <- anziani_stima |>
  filter(territorio == "Provincia di Parma", anno %in% ANNI_GRAFICO,
         indicatore == "gravi_difficolta_adl") |>
  mutate(anno = factor(anno),
         # stime arrotondate alle centinaia, come nella tabella
         etichetta = scales::number(n_stimato, accuracy = 100, big.mark = ".", decimal.mark = ","),
         # tooltip corto: quota sulla classe e denominatore ("10,3% su 38.800")
         prev_txt = paste0(scales::number(prevalenza, accuracy = 0.1, decimal.mark = ","), "%"),
         pop_txt = scales::number(popolazione, big.mark = ".", decimal.mark = ","),
         tooltip = glue("{prev_txt} su {pop_txt}"))

stima_classi_pr_prep

# etichette dell'asse x: asterisco sugli anni di previsione (vettore nominato, niente funzioni
# dentro il ggplot: l'rds si valuta al render del sito)
LAB_ANNI <- setNames(ifelse(ANNI_GRAFICO == ANNO_OGGI, ANNI_GRAFICO, paste0(ANNI_GRAFICO, "*")), ANNI_GRAFICO)

# asse y: tacche a passo fisso fino al multiplo che include il massimo (regola del sito)
PASSO_Y <- 2000
lim_y   <- ceiling(max(stima_classi_pr_prep$n_stimato) * 1.08 / PASSO_Y) * PASSO_Y   # spazio per l'etichetta

# __ plot_stima_classi_pr ----
plot_stima_classi_pr <- stima_classi_pr_prep |>
  ggplot(aes(x = anno, y = n_stimato)) +
  # riquadro azzurro sugli anni di previsione (solo nei grafici; nelle tabelle basta l'asterisco),
  # disegnato prima delle barre; 1,5 = metà tra la prima barra (2024) e la seconda
  annotate("rect", xmin = 1.5, xmax = Inf, ymin = -Inf, ymax = Inf, fill = BG_PREVISIONE) +
  geom_col_interactive(aes(tooltip = tooltip, data_id = interaction(anno, classe_eta)),
                       fill = seq_factor_red[7], width = 0.7) +
  scale_x_discrete(labels = LAB_ANNI) +
  geom_text(aes(label = etichetta), vjust = -0.5, size = 3.2, fontface = "bold", color = grey_extra_sc) +
  facet_wrap(~ classe_eta, ncol = 3, labeller = labeller(classe_eta = function(x) paste(x, "anni"))) +
  scale_y_continuous(breaks = seq(0, lim_y, by = PASSO_Y), limits = c(0, lim_y),
                     labels = function(x) scales::number(x, big.mark = ".", decimal.mark = ",")) +
  f_theme_sito() +
  theme(panel.grid.major.x = element_blank()) +
  labs(
    title = str_wrap(glue("Non autosufficienti nella cura della persona (stima) per classe di età, provincia di Parma ({paste(ANNI_GRAFICO, collapse = ', ')})"), 60),
    subtitle = "Indicatore: n. stimato di residenti di 65 anni e più con gravi difficoltà in almeno una attività di cura della persona. * = popolazione da previsioni ISTAT (2024 = censimento)",
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
         # stime arrotondate alle centinaia, come nella tabella
         etichetta = scales::number(casi, accuracy = 100, big.mark = ".", decimal.mark = ","),
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
  # riquadro azzurro sugli anni di previsione (solo nei grafici; nelle tabelle basta l'asterisco),
  # disegnato prima delle barre; 1,5 = metà tra la prima barra (2024) e la seconda
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
         # stime arrotondate alle decine (numeri piccoli per classe quinquennale e sesso)
         etichetta = scales::number(casi, accuracy = 10, big.mark = ".", decimal.mark = ","),
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

# 4d. Grafico: quota di 65+ e 80+, 2024-2050 — Parma / ER / Italia, altre province ER grigie ----
# stesso grafico di p04_quota_anziani (demo_trend_previs) con le linee sugli anni di
# riferimento della pagina (2036, 2050); dati da dati/puliti (contratto tra moduli)
previs_struttura <- readRDS(here("dati", "puliti", "istat_previsioni", "previs_struttura_territori.rds"))

TERRITORI_HL  <- c("Parma", "Emilia-Romagna", "Italia")
COL_TERRITORI <- c("Parma" = ylw_lg, "Emilia-Romagna" = grn_md, "Italia" = blu_md,
                   "Altre provincie ER" = grey_sc)
CAP_PREVIS    <- f_caption_fonte("Istat, Previsioni della popolazione 2024-2050, scenario mediano (demo.istat.it)")

quota_anziani_prep <- previs_struttura |>
  pivot_longer(c(p65_piu, p80_piu), names_to = "indicatore", values_to = "valore") |>
  mutate(
    indicatore = factor(indicatore, levels = c("p65_piu", "p80_piu"),
                        labels = c("65 anni e più", "80 anni e più")),
    highlight = territorio %in% TERRITORI_HL,
    territorio_display = factor(if_else(highlight, territorio, "Altre provincie ER"),
                                levels = c(TERRITORI_HL, "Altre provincie ER")),
    highlight = factor(highlight),
    # id e tooltip calcolati qui: l'rds si valuta al render del sito
    id = gsub("'", "", territorio),
    valore_txt = scales::number(valore, accuracy = 0.1, decimal.mark = ",")
  )

quota_anziani_prep

# __ plot_quota_anziani ----
plot_quota_anziani <- quota_anziani_prep |>
  ggplot(aes(x = anno, y = valore, color = territorio_display, alpha = highlight, group = territorio)) +
  # 2036 e 2050: anni di riferimento della pagina
  geom_vline(xintercept = c(2036, 2050), linetype = "dashed", colour = "grey60", linewidth = 0.4) +
  geom_line_interactive(aes(tooltip = territorio, data_id = id), linewidth = rel(0.8)) +
  geom_line_interactive(data = function(df) dplyr::filter(df, territorio_display != "Altre provincie ER"),
                        aes(tooltip = territorio, data_id = id), linewidth = rel(1.5)) +
  geom_point_interactive(data = function(df) dplyr::filter(df, territorio_display != "Altre provincie ER"),
                         aes(tooltip = valore_txt, data_id = id), size = 1.4) +
  facet_wrap(vars(indicatore), scales = "free_y") +
  # tacche ogni 6 anni fino al 2042, poi 2050 (2048 si sovrapporrebbe)
  scale_x_continuous(breaks = c(seq(2024, 2042, by = 6), 2050)) +
  scale_alpha_manual(values = c(0.3, 1), guide = "none") +
  scale_color_manual(values = COL_TERRITORI, name = NULL) +
  f_theme_sito_trend() +
  theme(strip.text = element_text(size = rel(1.1), face = "bold")) +
  labs(
    title = "Quota di popolazione anziana prevista (2024-2050)",
    subtitle = "Indicatore: % della popolazione con 65+ e 80+ anni; previsioni Istat, scenario mediano; linee tratteggiate: 2036 e 2050",
    caption = CAP_PREVIS, x = "", y = "%"
  )

plot_quota_anziani

# 5. Salva (rds per il sito + png + csv; nome file = oggetto) ---------------
f_salva_plot(plot_stima_classi_pr, "plot_stima_classi_pr", dir_mod, height = 6)
write_csv(stima_classi_pr_prep |> select(anno, classe_eta, popolazione, prevalenza, n_stimato), file.path(dir_mod, "plot_stima_classi_pr.csv"))
f_salva_plot(plot_demenze_classi_pr, "plot_demenze_classi_pr", dir_mod, height = 6)
f_salva_plot(plot_demenze_sesso_pr, "plot_demenze_sesso_pr", dir_mod, height = 5.5)
f_salva_plot(plot_quota_anziani, "plot_quota_anziani", dir_mod, height = 6)
write_csv(quota_anziani_prep |> select(territorio, anno, indicatore, valore), file.path(dir_mod, "plot_quota_anziani.csv"))
write_csv(demenze_sesso_pr_prep |> select(-tooltip, -etichetta, -tasso_txt, -casi_s, -hjust_lab), file.path(dir_mod, "plot_demenze_sesso_pr.csv"))
write_csv(demenze_classi_pr_prep |> select(-tooltip, -etichetta, -tasso_txt, -pop_txt), file.path(dir_mod, "plot_demenze_classi_pr.csv"))

# tabelle "quanti anziani" per territorio: tab_pop_pr_ft.rds, tab_pop_er_ft.rds, tab_pop_it_ft.rds; un csv per tutte
iwalk(tab_pop_ft, function(ft, sigla) saveRDS(ft, file.path(dir_mod, paste0("tab_pop_", sigla, "_ft.rds"))))
write_csv(tab_pop_prep |> select(territorio, anno, indicatore = etichetta, n, valore_relativo = rel), file.path(dir_mod, "tab_pop_ft.csv"))
# tabelle per territorio: tab_quadro_pr_ft.rds, tab_quadro_er_ft.rds, tab_quadro_it_ft.rds; un csv per tutte
iwalk(tab_quadro_ft, function(ft, sigla) saveRDS(ft, file.path(dir_mod, paste0("tab_quadro_", sigla, "_ft.rds"))))
write_csv(tab_quadro_prep |> select(territorio, anno, condizione, definizione, n, pct), file.path(dir_mod, "tab_quadro_ft.csv"))
