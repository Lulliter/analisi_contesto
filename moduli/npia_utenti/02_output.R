# ___________________________________________________________________________
# Modulo: npia_utenti
# Scopo:  grafici e tabelle sugli utenti della neuropsichiatria infantile (NPIA)
#         dell'AUSL di Parma: accessi vs in carico (provincia), due tabelle di
#         composizione (accessi, in carico), in carico e tasso di accesso per
#         distretto, composizione per età, diagnosi principali e confronto con
#         gli adulti (fotografia 2024)
# Input:  output/npia_distretti_rev.rds, npia_prov.rds, npia_eta.rds, npia_diagnosi_2024.rds, npia_sma_2024.rds (da 01_dati.R)
# Output: output/plot_*.rds (ggplot; girafe() nella pagina) + .png + .csv; output/tab_*_ft.rds (flextable) + .csv
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
source(here("R", "formatting.R"))   # f_ft, f_ft_titolo_note (tabella)

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "npia_utenti", "output")

ANNO_ULTIMO <- 2024
# tutte le serie dal 2017: primo anno con tutte le misure nella definizione corrente
# (in carico rivisti 2013-14, accessi 2012-13 vecchia definizione: v. _metadati.md)
# e tre punti pre-Covid; interessa il recente, non lo storico (deciso 2026-10-14)
ANNO_PRIMO <- 2017
COVID <- 2020
# dal 2022 cartella clinica regionale anche in NPIA: possibile rottura di serie
ANNO_CARTELLA_REG <- 2022

CAP_NPIA <- f_caption_fonte("AUSL di Parma, DAISMDP, report di attività annuali 2016-2024 (sezione NPIA); dal 2022 nuova cartella clinica regionale, possibile rottura di serie")

# un colore per distretto (Totale Provincia fuori dai grafici per distretto: scala diversa):
# palette categorica dedicata ai distretti, definita in R/_parma_colors.R
COL_DISTRETTI <- cat_distretti

# asse y dei trend: tacche a passo fisso fino al multiplo che include il massimo (mai
# un valore oltre l'ultima tacca); restituisce la scale_y pronta
# promossa in R/grafici.R il 2026-10-15 (stesso comportamento, con argomento labels)
# f_scale_y_tacche <- function(valori, passo) {
#   lim <- ceiling(max(valori, na.rm = TRUE) / passo) * passo
#   scale_y_continuous(breaks = seq(0, lim, by = passo), limits = c(0, lim),
#                      labels = function(x) scales::number(x, big.mark = ".", decimal.mark = ","))
# }

# 1. Carica dati pronti ----------------------------------------------------
npia_distretti_rev <- readRDS(file.path(dir_mod, "npia_distretti_rev.rds"))
npia_prov          <- readRDS(file.path(dir_mod, "npia_prov.rds"))
npia_eta           <- readRDS(file.path(dir_mod, "npia_eta.rds"))
npia_diagnosi_2024 <- readRDS(file.path(dir_mod, "npia_diagnosi_2024.rds"))
npia_sma_2024      <- readRDS(file.path(dir_mod, "npia_sma_2024.rds"))

# 2. Accessi e in carico, provincia, 2017-2024 ------------------------------
# le due misure del report come "imbuto": chi arriva al servizio (accessi: almeno
# una prestazione, anche una sola consulenza) e chi è preso in carico (progetto
# terapeutico aperto). Serie di tutte le età: le uniche complete fino al 2024
LAB_MISURE <- c(accessi = "Accessi", in_carico = "In carico")
COL_MISURE <- c("Accessi" = grey_sc, "In carico" = blu_md)

# quota di in carico con 18+ anni nell'ultimo anno disponibile per età (2022): pazienti
# che compiono 18 anni restando in carico; serve al sottotitolo
QUOTA_18PLUS <- npia_prov |>
  filter(!is.na(in_carico_0_17)) |>
  slice_max(anno, n = 1) |>
  mutate(q = round((in_carico - in_carico_0_17) / in_carico * 100)) |>
  pull(q)

accessi_in_carico_prov_prep <- npia_distretti_rev |>
  filter(anno >= ANNO_PRIMO, distretto == "Totale Provincia") |>
  select(anno, accessi, in_carico) |>
  pivot_longer(-anno, names_to = "misura", values_to = "n") |>
  mutate(misura = factor(LAB_MISURE[misura], levels = LAB_MISURE),
         etichetta = scales::number(n, big.mark = ".", decimal.mark = ","))

accessi_in_carico_prov_prep

# __ plot_accessi_in_carico_prov ----
plot_accessi_in_carico_prov <- accessi_in_carico_prov_prep |>
  ggplot(aes(x = anno, y = n, color = misura, group = misura)) +
  annotate("rect", xmin = COVID - 0.5, xmax = COVID + 0.5, ymin = -Inf, ymax = Inf,
           fill = "grey85", alpha = 0.5) +
  annotate("text", x = COVID, y = Inf, label = "Covid", hjust = 0.5, vjust = 1.5,
           size = 3.5, color = grey_extra_sc) +
  geom_vline(xintercept = ANNO_CARTELLA_REG - 0.5, linetype = "dashed", color = grey_md1) +
  # etichetta verticale del tratteggio, nello spazio libero sotto la linea degli in carico (~4.000)
  annotate("text", x = ANNO_CARTELLA_REG - 0.5, y = 1800, label = "nuova cartella clinica",
           angle = 90, vjust = -0.4, size = 3, color = grey_extra_sc) +
  geom_line_interactive(aes(tooltip = misura, data_id = misura), linewidth = rel(1.2)) +
  geom_point_interactive(aes(tooltip = glue("{misura} {anno}: {etichetta}"), data_id = misura), size = 2) +
  scale_x_continuous(breaks = seq(ANNO_PRIMO, ANNO_ULTIMO, by = 1)) +
  f_scale_y_tacche(accessi_in_carico_prov_prep$n, passo = 1000) +
  scale_color_manual(values = COL_MISURE) +
  f_theme_sito_trend() +
  # anni orizzontali: 8 anni ci stanno (2026-10-15)
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5)) +
  labs(
    title = str_wrap(glue("Chi arriva alla neuropsichiatria infantile e chi viene preso in carico, provincia di Parma (trend {ANNO_PRIMO}-{ANNO_ULTIMO})"), 60),
    subtitle = glue("Indicatore: n. di utenti nell'anno; \"accessi\" = almeno una prestazione, \"in carico\" = progetto terapeutico aperto."),
    caption = f_avvolgi_caption(paste0(glue("Nota: il servizio è rivolto ai pazienti pediatrici, ma il {QUOTA_18PLUS}% degli \"in carico\" ha 18 anni o più"), "\n", CAP_NPIA)),
    x = "", y = ""
  )
# Il servizio è rivolto ai pazienti pediatrici, ma il {QUOTA_18PLUS}% degli \"in carico\" ha 18 anni o più
plot_accessi_in_carico_prov

# 3. Tabelle: chi sono gli utenti, provincia, 2017-2024 --------------------
# tutto ciò che il report dice sulla composizione, in due tabelle della stessa
# forma (per un tabset nel sito): accessi e in carico, ciascuna con totale,
# minori, stranieri %; le celle N.D. sono i buchi delle edizioni 2023-24 e dei
# dati per età (fino al 2022)
tab_utenti_base <- npia_distretti_rev |>
  filter(anno >= ANNO_PRIMO, distretto == "Totale Provincia") |>
  select(anno, accessi, accessi_residenti_0_17, accessi_stranieri_0_17) |>
  left_join(npia_prov, by = "anno") |>
  mutate(
    # stranieri in % sulla stessa base dei due blocchi: minori residenti (accessi), totale (in carico)
    acc_quota_stranieri = round(accessi_stranieri_0_17 / accessi_residenti_0_17 * 100, 1),
    quota_autismo = round(in_carico_autismo / in_carico * 100, 1),
    # anni come testo: colformat_int metterebbe il punto delle migliaia
    anno = as.character(anno))

# minori in % sul totale invece che in valore assoluto (2026-10-15)
tab_accessi_prep <- tab_utenti_base |>
  mutate(quota_minori = round(accessi_residenti_0_17 / accessi * 100, 1)) |>
  # select(anno, totale = accessi, minori = accessi_residenti_0_17, quota_stranieri = acc_quota_stranieri)
  select(anno, totale = accessi, quota_minori, quota_stranieri = acc_quota_stranieri)

tab_in_carico_prep <- tab_utenti_base |>
  mutate(quota_minori = round(in_carico_0_17 / in_carico * 100, 1)) |>
  # select(anno, totale = in_carico, minori = in_carico_0_17, quota_stranieri, quota_femmine, quota_autismo)
  select(anno, totale = in_carico, quota_minori, quota_stranieri, quota_femmine, quota_autismo)

tab_accessi_prep
tab_in_carico_prep

# tinte pallide per ritrovare le categorie nelle due tabelle (convenzione: verde minori, viola stranieri)
BG_MINORI    <- "#E6F0E1"
BG_STRANIERI <- "#ECE6F1"
BG_FEMMINE   <- "#F6E7EA"

# stile comune alle due tabelle: etichette, grassetto sul totale, colori di categoria, N.D.
f_tab_utenti <- function(dati, titolo, note) {
  # simbolo % nei valori, non nelle intestazioni (2026-10-15)
  etichette <- c(anno = "Anno", totale = "Totale", quota_minori = "di cui minori (0-17)", quota_stranieri = "di cui stranieri",
                 quota_femmine = "di cui femmine", quota_autismo = "di cui con autismo")
  col_quote <- grep("^quota_", names(dati), value = TRUE)
  dati |>
    f_ft() |>
    # colformat_double(j = c("totale", "minori"), digits = 0, na_str = "N.D.") |>
    colformat_double(j = "totale", digits = 0, na_str = "N.D.") |>
    colformat_double(j = col_quote, digits = 1, suffix = "%", na_str = "N.D.") |>
    set_header_labels(values = as.list(etichette[names(dati)])) |>
    align(align = "center", part = "header") |>
    bold(j = "totale", part = "body") |>
    bg(j = "quota_minori", bg = BG_MINORI, part = "body") |>
    bg(j = "quota_stranieri", bg = BG_STRANIERI, part = "body") |>
    f_ft_titolo_note(titolo = titolo, note = note)
}

NOTA_ND <- "N.D. = non riportato nel report di quell'anno. Dal 2022 nuova cartella clinica regionale, possibile rottura di serie. Fonte: AUSL di Parma, DAISMDP, report di attività annuali."

# __ tab_accessi_ft ----
tab_accessi_ft <- f_tab_utenti(
  tab_accessi_prep,
  titolo = glue("Accessi alla neuropsichiatria infantile, provincia di Parma (trend {ANNO_PRIMO}-{ANNO_ULTIMO})"),
  note = c("Accessi = utenti con almeno una prestazione nell'anno (anche una sola consulenza), ogni età e residenza. Minori = residenti 0-17, in % sul totale degli accessi; stranieri come definiti nel report (origine o cittadinanza: da chiarire), in % sui minori residenti.",
           NOTA_ND)
)

tab_accessi_ft

# __ tab_in_carico_ft ----
tab_in_carico_ft <- f_tab_utenti(
  tab_in_carico_prep,
  titolo = glue("Pazienti in carico alla neuropsichiatria infantile, provincia di Parma (trend {ANNO_PRIMO}-{ANNO_ULTIMO})"),
  note = c("In carico = utenti con un progetto terapeutico aperto nell'anno. Minori = totale meno i pazienti con 18 anni e più, in % sul totale; stranieri come definiti nel report (origine o cittadinanza: da chiarire), in % su tutti i pazienti. Autismo = diagnosi in cartella (dal 2022 solo diagnosi principale).",
           NOTA_ND)
) |>
  bg(j = "quota_femmine", bg = BG_FEMMINE, part = "body")

tab_in_carico_ft

# 4. In carico per distretto, 2017-2024 ------------------------------------
# totale provinciale dell'ultimo anno, per il sottotitolo
tot_ultimo <- npia_distretti_rev |>
  filter(anno == ANNO_ULTIMO, distretto == "Totale Provincia") |>
  pull(in_carico)

in_carico_distretti_prep <- npia_distretti_rev |>
  filter(anno >= ANNO_PRIMO, distretto != "Totale Provincia", !is.na(in_carico)) |>
  select(anno, distretto, in_carico) |>
  mutate(distretto = factor(distretto, levels = names(COL_DISTRETTI)),
         etichetta = scales::number(in_carico, big.mark = ".", decimal.mark = ","))

in_carico_distretti_prep

# __ plot_in_carico_distretti ----
plot_in_carico_distretti <- in_carico_distretti_prep |>
  ggplot(aes(x = anno, y = in_carico, color = distretto, group = distretto)) +
  # fascia grigia sull'anno Covid
  annotate("rect", xmin = COVID - 0.5, xmax = COVID + 0.5, ymin = -Inf, ymax = Inf,
           fill = "grey85", alpha = 0.5) +
  annotate("text", x = COVID, y = Inf, label = "Covid", hjust = 0.5, vjust = 1.5,
           size = 3.5, color = grey_extra_sc) +
  # linea tratteggiata al cambio di cartella clinica
  geom_vline(xintercept = ANNO_CARTELLA_REG - 0.5, linetype = "dashed", color = grey_md1) +
  # etichetta verticale del tratteggio, nello spazio libero tra Fidenza (~900) e Parma (~1.900)
  annotate("text", x = ANNO_CARTELLA_REG - 0.5, y = 1400, label = "nuova cartella clinica",
           angle = 90, vjust = -0.4, size = 3, color = grey_extra_sc) +
  geom_line_interactive(aes(tooltip = distretto, data_id = distretto), linewidth = rel(1.2)) +
  geom_point_interactive(aes(tooltip = glue("{distretto} {anno}: {etichetta}"), data_id = distretto), size = 2) +
  scale_x_continuous(breaks = seq(ANNO_PRIMO, ANNO_ULTIMO, by = 1)) +
  f_scale_y_tacche(in_carico_distretti_prep$in_carico, passo = 500) +
  scale_color_manual(values = COL_DISTRETTI, name = "Distretti") +
  f_theme_sito_trend() +
  # anni orizzontali (2026-10-15)
  # theme(axis.text.x = element_text(angle = 45, hjust = 1),
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
        # il tema del sito spegne il titolo di legenda: qui serve ("Distretti")
        legend.title = element_text(size = rel(0.9), face = "bold")) +
  labs(
    title = str_wrap(glue("Pazienti pediatrici in carico alla neuropsichiatria infantile per distretto (trend {ANNO_PRIMO}-{ANNO_ULTIMO})"), 60),
    subtitle = glue("Indicatore: n. di utenti con un progetto terapeutico aperto nell'anno, per distretto sanitario dell'AUSL di Parma; in tutta la provincia {scales::number(tot_ultimo, big.mark = '.', decimal.mark = ',')} nel {ANNO_ULTIMO}"),
    caption = CAP_NPIA, x = "", y = ""
  )

plot_in_carico_distretti

# 5. Tasso di accesso dei minori per distretto, 2017-2022 -------------------
# accessi di residenti 0-17 per 1.000 residenti 0-17 (tasso stampato dal report,
# denominatori del Servizio Statistico della Provincia): toglie l'effetto della
# dimensione dei distretti; si ferma al 2022 (edizioni 2023-24 senza la tabella)
ANNO_ULTIMO_TASSO <- 2022

tasso_distretti_prep <- npia_distretti_rev |>
  filter(anno >= ANNO_PRIMO, anno <= ANNO_ULTIMO_TASSO, !is.na(tasso_accesso_x1000)) |>
  select(anno, distretto, tasso_accesso_x1000) |>
  mutate(distretto = factor(distretto, levels = c(names(COL_DISTRETTI), "Totale Provincia")),
         etichetta = scales::number(tasso_accesso_x1000, accuracy = 0.1, decimal.mark = ","))

tasso_distretti_prep

# pallini solo sui distretti: sottoinsieme calcolato qui (nel ggplot niente funzioni
# non qualificate: l'rds si valuta al render del sito, dove dplyr non è caricato)
tasso_distretti_punti_prep <- tasso_distretti_prep |>
  filter(distretto != "Totale Provincia")

# il totale provincia qui ci sta (è un tasso, stessa scala): in grigio, senza pallini
COL_DISTRETTI_TOT <- c(COL_DISTRETTI, "Totale Provincia" = grey_md1)

# __ plot_tasso_distretti ----
plot_tasso_distretti <- tasso_distretti_prep |>
  ggplot(aes(x = anno, y = tasso_accesso_x1000, color = distretto, group = distretto)) +
  annotate("rect", xmin = COVID - 0.5, xmax = COVID + 0.5, ymin = -Inf, ymax = Inf,
           fill = "grey85", alpha = 0.5) +
  annotate("text", x = COVID, y = Inf, label = "Covid", hjust = 0.5, vjust = 1.5,
           size = 3.5, color = grey_extra_sc) +
  geom_vline(xintercept = ANNO_CARTELLA_REG - 0.5, linetype = "dashed", color = grey_md1) +
  geom_line_interactive(aes(tooltip = distretto, data_id = distretto), linewidth = rel(1.2)) +
  # pallini solo sui distretti (il totale è la linea di riferimento)
  geom_point_interactive(data = tasso_distretti_punti_prep,
                         aes(tooltip = glue("{distretto} {anno}: {etichetta} per 1.000"), data_id = distretto), size = 2) +
  scale_x_continuous(breaks = seq(ANNO_PRIMO, ANNO_ULTIMO_TASSO, by = 1)) +
  f_scale_y_tacche(tasso_distretti_prep$tasso_accesso_x1000, passo = 20) +
  scale_color_manual(values = COL_DISTRETTI_TOT, name = "Distretti") +
  f_theme_sito_trend() +
  # anni orizzontali: 6-8 anni ci stanno (2026-10-15)
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
        legend.title = element_text(size = rel(0.9), face = "bold")) +
  labs(
    title = str_wrap(glue("Minori che accedono alla neuropsichiatria infantile ogni 1.000 residenti, per distretto (trend {ANNO_PRIMO}-{ANNO_ULTIMO_TASSO})"), 60),
    subtitle = "Indicatore: accessi di residenti 0-17 per 1.000 residenti 0-17 del distretto (tasso calcolato dall'AUSL su popolazione del Servizio Statistico della Provincia); non disponibile dopo il 2022",
    caption = CAP_NPIA, x = "", y = "accessi ogni 1.000 residenti 0-17"
  )

plot_tasso_distretti

# 6. Composizione per età dei pazienti in carico, provincia, 2013-2022 -----
# quote % per classe d'età (solo Totale Provincia; le edizioni 2023-24 hanno le età
# solo come grafico): dice se cresce la fascia adolescenziale o quella scolare
ANNO_PRIMO_ETA <- 2013   # dal 2013 la serie in carico è nella definizione corrente

# verdi da chiaro (piccoli) a scuro (grandi), convenzione del repo; 18+ in grigio
COL_ETA <- c(grDevices::colorRampPalette(c(verde_eta4[1], verde_eta4[4]))(5), grey_md1) |>
  setNames(c("0-2", "3-5", "6-10", "11-13", "14-17", "18+"))

eta_prep <- npia_eta |>
  filter(anno >= ANNO_PRIMO_ETA) |>
  mutate(classe_eta = factor(classe_eta, levels = rev(names(COL_ETA))),
         quota = quota / 100,
         etichetta = scales::percent(quota, accuracy = 1),
         tooltip = glue("{anno}, {classe_eta} anni: {scales::number(n, big.mark = '.', decimal.mark = ',')} ({etichetta})"))

eta_prep

# etichette solo dove la fascia è leggibile (>= 5%: resta fuori solo la 0-2, al 3-4%);
# sottoinsieme calcolato qui, non dentro il ggplot (v. nota sopra)
eta_etichette_prep <- eta_prep |>
  filter(quota >= 0.05)

# __ plot_eta ----
plot_eta <- eta_prep |>
  ggplot(aes(x = anno, y = quota, fill = classe_eta, group = classe_eta)) +
  geom_col_interactive(aes(tooltip = tooltip, data_id = classe_eta), position = position_fill(), width = 0.8) +
  geom_text(data = eta_etichette_prep, aes(label = etichetta),
            position = position_fill(vjust = 0.5), size = 3, color = "white") +
  scale_x_continuous(breaks = seq(ANNO_PRIMO_ETA, ANNO_ULTIMO_TASSO, by = 1)) +
  scale_y_continuous(labels = function(x) scales::percent(x, accuracy = 1)) +
  scale_fill_manual(values = COL_ETA, name = "Età (anni)", breaks = names(COL_ETA)) +
  f_theme_sito() +
  theme(legend.title = element_text(size = rel(0.9), face = "bold"),
        panel.grid.major.x = element_blank()) +
  labs(
    title = str_wrap(glue("Età dei pazienti in carico alla neuropsichiatria infantile, provincia di Parma ({ANNO_PRIMO_ETA}-{ANNO_ULTIMO_TASSO})"), 60),
    subtitle = "Indicatore: % dei pazienti in carico per classe di età; la fascia 6-10 anni (ingresso nella scuola primaria) è la più numerosa; dati per età non disponibili dopo il 2022",
    caption = CAP_NPIA, x = "", y = ""
  )

plot_eta

# 6b. Diagnosi principali dei pazienti in carico, fotografia 2024 ----------
# una diagnosi principale per paziente (dal 2022); i "disturbi evolutivi globali
# (autismo)", dicitura del report (p. 10), evidenziati: gruppo più numeroso e in crescita
ANNO_DIAGNOSI <- 2024
DIAG_EVIDENZA <- "Disturbi evolutivi globali (autismo)"
# soglie di evidenza nella tabella: i numeri che il report stesso commenta (femmine sopra la
# metà; stranieri sopra la loro quota tra i minori residenti, "circa il 30%" secondo il report)
SOGLIA_FEMMINE   <- 60
SOGLIA_STRANIERI <- 35
BG_EVIDENZA      <- "#FFF2B3"   # giallo pallido per le celle oltre soglia

diagnosi_prep <- npia_diagnosi_2024 |>
  mutate(diagnosi = factor(diagnosi_principale, levels = rev(diagnosi_principale)),
         evidenza = if_else(diagnosi_principale == DIAG_EVIDENZA, "autismo", "altre"),
         etichetta = scales::percent(pct / 100, accuracy = 0.1, decimal.mark = ","),
         tooltip = glue("{diagnosi_principale}: {scales::number(n, big.mark = '.', decimal.mark = ',')} pazienti ({etichetta})\n",
                        "età media {scales::number(eta_media, accuracy = 0.1, decimal.mark = ',')} anni; ",
                        "femmine {scales::number(femmine_pct, accuracy = 1)}%; stranieri {scales::number(stranieri_pct, accuracy = 1)}%"))

diagnosi_prep

# __ plot_diagnosi ----
plot_diagnosi <- diagnosi_prep |>
  ggplot(aes(x = n, y = diagnosi, fill = evidenza)) +
  geom_col_interactive(aes(tooltip = tooltip, data_id = diagnosi), width = 0.75) +
  geom_text(aes(label = etichetta), hjust = -0.15, size = 3.2, color = grey_extra_sc) +
  scale_x_continuous(labels = function(x) scales::number(x, big.mark = ".", decimal.mark = ","),
                     expand = expansion(mult = c(0, 0.12))) +
  scale_fill_manual(values = c(autismo = grn_sc, altre = grn_lg), guide = "none") +
  f_theme_sito() +
  theme(panel.grid.major.y = element_blank()) +
  labs(
    title = str_wrap(glue("Diagnosi principale dei pazienti in carico alla neuropsichiatria infantile, provincia di Parma ({ANNO_DIAGNOSI})"), 60),
    subtitle = glue("Indicatore: n. di pazienti in carico per diagnosi principale (una per paziente) e % sul totale ({scales::number(sum(diagnosi_prep$n), big.mark = '.', decimal.mark = ',')}); in evidenza i disturbi evolutivi globali (autismo)"),
    caption = CAP_NPIA, x = "", y = ""
  )

plot_diagnosi

# __ tab_diagnosi_ft ----
tab_diagnosi_prep <- npia_diagnosi_2024 |>
  select(diagnosi_principale, n, pct, eta_media, femmine_pct, stranieri_pct)

tab_diagnosi_ft <- tab_diagnosi_prep |>
  f_ft() |>
  colformat_double(j = "n", digits = 0) |>
  # simbolo % nei valori, non nelle intestazioni (2026-10-15)
  colformat_double(j = c("pct", "femmine_pct", "stranieri_pct"), digits = 1, suffix = "%") |>
  # set_header_labels(diagnosi_principale = "", n = "N. di pazienti", pct = "% di pazienti",
  #                   eta_media = "Età media (anni)", femmine_pct = "Femmine (%)", stranieri_pct = "Stranieri (%)") |>
  set_header_labels(diagnosi_principale = "", n = "N. di pazienti", pct = "Sul totale",
                    eta_media = "Età media (anni)", femmine_pct = "Femmine", stranieri_pct = "Stranieri") |>
  # header a due righe: le colonne sotto ogni etichetta sono quelle del select() sopra, in ordine
  add_header_row(values = c("Diagnosi principale", "Incidenza per classi demografiche"), colwidths = c(4, 2)) |>
  align(align = "center", part = "header") |>
  align(j = -1, align = "right", part = "body") |>
  bold(j = "n", part = "body") |>
  # stesse tinte di categoria delle tabelle accessi / in carico
  bg(j = "femmine_pct", bg = BG_FEMMINE, part = "body") |>
  bg(j = "stranieri_pct", bg = BG_STRANIERI, part = "body") |>
  # in giallo le celle oltre soglia (come fa il testo del report) e il nome della diagnosi
  bg(i = ~ femmine_pct > SOGLIA_FEMMINE, j = "femmine_pct", bg = BG_EVIDENZA, part = "body") |>
  bg(i = ~ stranieri_pct > SOGLIA_STRANIERI, j = "stranieri_pct", bg = BG_EVIDENZA, part = "body") |>
  bg(i = ~ femmine_pct > SOGLIA_FEMMINE | stranieri_pct > SOGLIA_STRANIERI, j = "diagnosi_principale",
     bg = BG_EVIDENZA, part = "body") |>
  f_ft_titolo_note(
    titolo = glue("Pazienti in carico alla neuropsichiatria infantile per diagnosi principale, provincia di Parma ({ANNO_DIAGNOSI})"),
    note = c(glue("Una diagnosi principale per paziente (dal 2022). Femmine e stranieri in % dei pazienti con quella diagnosi; in giallo le femmine oltre il {SOGLIA_FEMMINE}% e gli stranieri oltre il {SOGLIA_STRANIERI}% (la loro quota tra i minori residenti secondo il report). Stranieri come definiti nel report (origine o cittadinanza: da chiarire); raggruppamenti e diciture del report."),
             "Fonte: AUSL di Parma, DAISMDP, report di attività 2024.")
  )

tab_diagnosi_ft

# 6c. Minori vs adulti: confronto NPIA / SMA, fotografia 2024 ---------------
# riferimento macro: gli stessi sei indicatori per i due servizi, valori del report
LAB_CONFRONTO <- c(accessi = "Accessi (utenti con almeno una prestazione)",
                   in_carico = "In carico (progetto terapeutico aperto)",
                   in_carico_pop_target_pct = "In carico, % della popolazione di riferimento",
                   femmine_pct = "Femmine, % degli in carico",
                   stranieri_pct = "Stranieri, % degli in carico",
                   diagnosi_principale_prima = "Diagnosi più frequente, % degli in carico")
# formato per riga: conteggi senza decimali, percentuali con 1 decimale
# f_num_riga <- function(x, pct) if_else(pct, scales::number(x, accuracy = 0.1, decimal.mark = ","),
#                                        scales::number(x, big.mark = ".", decimal.mark = ","))
# con il simbolo % nei valori percentuali (2026-10-15)
f_num_riga <- function(x, pct) if_else(pct, paste0(scales::number(x, accuracy = 0.1, decimal.mark = ","), "%"),
                                       scales::number(x, big.mark = ".", decimal.mark = ","))

confronto_adulti_prep <- npia_sma_2024 |>
  mutate(pct = grepl("pct|prima", indicatore),
         npia = f_num_riga(npia, pct),
         sma  = f_num_riga(sma, pct),
         indicatore = LAB_CONFRONTO[indicatore]) |>
  select(indicatore, npia, sma)

confronto_adulti_prep

# __ tab_confronto_adulti_ft ----
tab_confronto_adulti_ft <- confronto_adulti_prep |>
  f_ft() |>
  set_header_labels(indicatore = "", npia = "Pazienti pediatrici (NPIA)", sma = "Adulti (SMA)") |>
  align(j = c("npia", "sma"), align = "right", part = "all") |>
  f_ft_titolo_note(
    titolo = glue("Minori e adulti nei servizi di salute mentale dell'AUSL di Parma ({ANNO_DIAGNOSI})"),
    note = c("NPIA = neuropsichiatria dell'infanzia e dell'adolescenza; SMA = salute mentale adulti. Popolazione di riferimento: minorenni (NPIA) e maggiorenni (SMA) residenti. Stranieri come definiti nel report (tra i residenti: circa il 30% dei minorenni e il 14% dei maggiorenni, secondo il report). Diagnosi più frequente: disturbi evolutivi globali (autismo) tra i minori, schizofrenia e disturbi deliranti tra gli adulti.",
             "Fonte: AUSL di Parma, DAISMDP, report di attività 2024.")
  )

tab_confronto_adulti_ft

# 7. Salva (rds per il sito + png + csv dei dati; nome file = oggetto) -----
lista_plot <- list(plot_accessi_in_carico_prov = plot_accessi_in_carico_prov,
                   plot_in_carico_distretti = plot_in_carico_distretti,
                   plot_tasso_distretti = plot_tasso_distretti,
                   plot_eta = plot_eta,
                   plot_diagnosi = plot_diagnosi)
lista_prep <- list(plot_accessi_in_carico_prov = accessi_in_carico_prov_prep,
                   plot_in_carico_distretti = in_carico_distretti_prep,
                   plot_tasso_distretti = tasso_distretti_prep,
                   plot_eta = eta_prep |> select(-tooltip),
                   plot_diagnosi = diagnosi_prep |> select(-tooltip))

purrr::iwalk(lista_plot, function(p, nome) f_salva_plot(p, nome, dir_mod, height = 6))
purrr::iwalk(lista_prep, function(d, nome) write_csv(select(d, -etichetta), file.path(dir_mod, paste0(nome, ".csv"))))

# tabelle: flextable in rds (rilette tal quali dal sito) + csv dei dati
saveRDS(tab_accessi_ft, file.path(dir_mod, "tab_accessi_ft.rds"))
write_csv(tab_accessi_prep, file.path(dir_mod, "tab_accessi_ft.csv"))
saveRDS(tab_in_carico_ft, file.path(dir_mod, "tab_in_carico_ft.rds"))
write_csv(tab_in_carico_prep, file.path(dir_mod, "tab_in_carico_ft.csv"))
saveRDS(tab_diagnosi_ft, file.path(dir_mod, "tab_diagnosi_ft.rds"))
write_csv(tab_diagnosi_prep, file.path(dir_mod, "tab_diagnosi_ft.csv"))
saveRDS(tab_confronto_adulti_ft, file.path(dir_mod, "tab_confronto_adulti_ft.rds"))
write_csv(npia_sma_2024, file.path(dir_mod, "tab_confronto_adulti_ft.csv"))

