# ___________________________________________________________________________
# Modulo: formaz_e_rientro
# Scopo:  la "seconda chance" nella provincia di Parma: quanti adulti tornano a
#         scuola nei corsi serali (trend, con carcere e CPIA), quanto pesano
#         rispetto alla secondaria ordinaria nelle province ER, chi sono
#         (età, cittadinanza, tipo di istituto, anno di corso); prima, gli iscritti alle superiori
#         per tipo di scuola (Emilia-Romagna e Parma, un a.s. ogni due)
# Input:  output/*.rds (da 01_dati.R)
# Output: output/plot_*.rds (ggplot; girafe() nella pagina) + .png
#         output/tipi_scuola_ft.rds (flextable) + tipi_scuola.csv
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(stringr)
library(glue)
library(ggplot2)
library(ggiraph)
library(ggtext)
library(tidyr)
library(readr)
library(flextable)
library(janitor)   # tabyl() nelle esplorazioni
# paint (da r-universe, milesmcbain) solo per guardare i dati a mano: non caricato qui perché
# build.R esegue questo script

source(here("R", "_parma_colors.R"))
source(here("R", "grafici.R"))   # f_theme_sito*, f_caption_fonte, f_lab_as, f_salva_plot
source(here("R", "formatting.R"))   # f_ft, f_ft_titolo_note

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

# tabella dei tipi di scuola: a.s. mostrati (uno ogni due; si cambiano qui)
ANNI_TAB  <- c(2016, 2018, 2020, 2022, 2024)
ANNO_BASE <- 2018   # a.s. 2018/19: dal quale il MIM registra la IeFP a parte
TIPI_PROF <- c("Professionali", "IeFP nei professionali")
# esplorazioni: ordine dei tipi di scuola e tipi che sommano al totale (dalla bozza, 2026-10-30)
ORDINE_TIPI <- c("Licei", "di cui scientifici", "di cui classici", "Tecnici", "Professionali",
                 "IeFP nei professionali", "Totale")
TIPI_TOTALE <- c("Licei", "Tecnici", "Professionali", "IeFP nei professionali")
# righe: professionali e IeFP sommati, più il "di cui" IeFP come registrata dal MIM
PROF_IEFP       <- "Professionali e IeFP *"
IEFP_DI_CUI     <- "di cui IeFP **"
ORDINE_TIPI_TAB <- c("Licei", "Tecnici", PROF_IEFP, IEFP_DI_CUI, "Totale")
# riga della IeFP in rosso: dato parziale (v. nota con asterisco)
COL_IEFP <- seq_dummy_red[3]

# 1. Carica dati pronti ----------------------------------------------------
rientro_trend_pr <- readRDS(file.path(dir_mod, "rientro_trend_pr.rds"))
rientro_incidenza_prov_er <- readRDS(file.path(dir_mod, "rientro_incidenza_prov_er.rds"))
rientro_profilo_pr <- readRDS(file.path(dir_mod, "rientro_profilo_pr.rds"))
iscritti_tipo_scuola <- readRDS(file.path(dir_mod, "iscritti_tipo_scuola.rds"))
iscritti_tipo_utenza <- readRDS(file.path(dir_mod, "iscritti_tipo_utenza.rds"))
iscritti_indirizzi   <- readRDS(file.path(dir_mod, "iscritti_indirizzi.rds"))

# __ esplora: i dati nuovi su tipi di scuola, indirizzi e utenza ----
# paint(iscritti_tipo_scuola)
# paint(iscritti_indirizzi)
# paint(iscritti_tipo_utenza)
iscritti_indirizzi |> filter (tipo_scuola %in% TIPI_PROF) |> 
  tabyl(indirizzo, tipo_scuola) 
iscritti_tipo_scuola |> tabyl(anno_inizio)

# 2. Tipi di scuola -------------------------------------------------------

# __ tipi_scuola_ft_OLD ----
# un a.s. ogni due (ANNI_TAB); versione di lavoro con le esplorazioni in bozza_02_tipi_scuola.R
# statali e paritarie (dal 2026-10-30; prima solo statali, come la Tab. 5); professionali e IeFP sommati: fino al 2017/18 la IeFP è dentro
# "ISTITUTO PROFESSIONALE", dal 2018/19 quella del vecchio ordinamento esce via via e il MIM
# registra a parte solo una piccola parte della IeFP svolta negli istituti (v. callout Norma nella pagina)
# (fino al 2026-10-30 il commento diceva "contata tra i professionali": ipotesi non confermata)
# solo corsi diurni (dal 2026-10-30): serali e carcere (adulti) stanno nella sezione dedicata;
# prima da iscritti_tipo_scuola, con tutte le utenze
tipi_scuola_lungo <- iscritti_tipo_utenza |>
  # senza i "di cui" dei licei (tolti dalla tabella il 2026-10-30)
  # (fino al 2026-10-30 anche gestione == "statale")
  filter(anno_inizio %in% ANNI_TAB, utenza == "diurno", !str_detect(tipo_scuola, "^di cui")) |>
  mutate(tipo_scuola = if_else(tipo_scuola %in% TIPI_PROF, PROF_IEFP, tipo_scuola)) |>
  summarise(alunni = sum(alunni), .by = c(territorio, anno_inizio, tipo_scuola))

# di cui IeFP come registrata dal MIM: 0 negli a.s. senza IeFP (es. Parma 2024/25), n.d. prima del
# 2018/19, quando la IeFP non era registrata a parte
tipi_scuola_iefp <- iscritti_tipo_utenza |>
  filter(anno_inizio %in% ANNI_TAB, utenza == "diurno", tipo_scuola == "IeFP nei professionali") |>
  summarise(alunni = sum(alunni), .by = c(territorio, anno_inizio)) |>
  complete(territorio, anno_inizio = ANNI_TAB, fill = list(alunni = 0L)) |>
  mutate(alunni = if_else(anno_inizio < ANNO_BASE, NA_integer_, alunni),
         tipo_scuola = IEFP_DI_CUI)
tipi_scuola_iefp   # attese Parma: n.d. (2016/17), 338 (2018/19), poi pochi o 0

tipi_scuola_lungo <- bind_rows(tipi_scuola_lungo, tipi_scuola_iefp)

tipi_scuola_tot <- tipi_scuola_lungo |>
  filter(!str_detect(tipo_scuola, "^di cui")) |>
  summarise(alunni = sum(alunni), .by = c(territorio, anno_inizio)) |>
  mutate(tipo_scuola = "Totale")

# % sul totale dell'a.s. e variazione % sul primo a.s. della tabella
tipi_scuola_prep <- bind_rows(tipi_scuola_lungo, tipi_scuola_tot) |>
  mutate(pct_su_totale = 100 * alunni / alunni[tipo_scuola == "Totale"], .by = c(territorio, anno_inizio)) |>
  arrange(anno_inizio) |>
  mutate(var_su_primo = 100 * (alunni / first(alunni) - 1), .by = c(territorio, tipo_scuola))

tipi_scuola_prep
# riscontri 2024/25, solo statali (la Tab. 5 come traccia): Emilia-Romagna professionali + IeFP 41.992,
# totale 197.935; Parma professionali 3.331, totale 20.849. Con le paritarie: Parma totale 21.147
# (+298, quasi tutti licei e tecnici), Emilia-Romagna 203.331 (+5.396). Solo diurni (dal 2026-10-30):
# Parma totale circa 20.620 (professionali 3.035), Emilia-Romagna circa 199.260

# etichette delle colonne (a.s. "2016/17" e titoli che contengono gli a.s.)
f_lab_as_tab <- function(anno) paste0(anno, "/", sprintf("%02d", (anno + 1) %% 100))
lab_pct <- paste("% sul totale", f_lab_as_tab(ANNO_ULTIMO))
# (colonna della variazione tolta il 2026-10-30)
# lab_var <- paste("Var. %", f_lab_as_tab(ANNO_ULTIMO), "su", f_lab_as_tab(min(ANNI_TAB)))

# tabella larga: un a.s. per colonna (alunni), poi % dell'ultimo a.s.
tipi_scuola <- tipi_scuola_prep |>
  mutate(as = f_lab_as_tab(anno_inizio)) |>
  select(territorio, tipo_scuola, as, alunni) |>
  pivot_wider(names_from = as, values_from = alunni) |>
  left_join(tipi_scuola_prep |>
              filter(anno_inizio == ANNO_ULTIMO) |>
              select(territorio, tipo_scuola, pct_su_totale),
            by = c("territorio", "tipo_scuola")) |>
  arrange(match(territorio, c("Emilia-Romagna", "Provincia di Parma")),
          match(tipo_scuola, ORDINE_TIPI_TAB)) |>
  rename(Territorio = territorio, `Tipo di scuola` = tipo_scuola,
         all_of(setNames("pct_su_totale", lab_pct)))

tipi_scuola

col_as  <- str_subset(names(tipi_scuola), "^\\d{4}/")
col_pct <- lab_pct


# __ NON QUI 1/2 ----
tipi_scuola_ft_OLD <- tipi_scuola |>
  mutate(across(all_of(col_as), as.numeric)) |>
  f_ft() |>
  # na_str ripetuto: questi colformat sovrascrivono quello di f_ft() e senza na_str le celle NA restano vuote
  # alunni come numeri decimali (v. sopra) per poter dare anche decimal.mark: colformat_int() non lo
  # accetta, e con il default "." R avvisa che big.mark e decimal.mark coincidono
  colformat_double(j = col_as, digits = 0, big.mark = ".", decimal.mark = ",", na_str = "N.D.") |>
  colformat_double(j = col_pct, digits = 1, decimal.mark = ",", suffix = "%", na_str = "N.D.") |>
  merge_v(j = "Territorio") |>
  valign(j = "Territorio", valign = "top") |>
  # righe "di cui" in corsivo (tutta la riga tranne il territorio), Totale in grassetto
  # (fino al 2026-10-30 corsivo solo sulla colonna "Tipo di scuola")
  italic(i = ~ str_detect(`Tipo di scuola`, "^di cui"), j = setdiff(names(tipi_scuola), "Territorio")) |>
  # highlight arancio pallido perche dato incompleto (la IeFP degli enti di formazione accreditati non è nei dati MIM)
  bg( i = ~ str_detect(`Tipo di scuola`, "^Professionali"), j = setdiff(names(tipi_scuola), "Territorio"), bg =  '#fee6ce'
        ) |>
  bold(i = ~ `Tipo di scuola` == "Totale", j = setdiff(names(tipi_scuola), "Territorio")) |>
  # riga IeFP in rosso: dato parziale
  color(i = ~ `Tipo di scuola` == IEFP_DI_CUI, j = setdiff(names(tipi_scuola), "Territorio"), color = COL_IEFP) |>
  f_ft_titolo_note(
    titolo = paste0("Iscritti alle scuole superiori per tipo di scuola: Emilia-Romagna e provincia di Parma (",
                    f_lab_as_tab(min(ANNI_TAB)), "-", f_lab_as_tab(ANNO_ULTIMO), ")"),
    note   = c("Fonte: MIM, Portale unico dei dati della scuola (scuole statali e paritarie)",
               "Gli alunni sono contati nella provincia della scuola; esclusi i corsi serali e le sezioni in carcere (adulti)",
               "* La IeFP qui conta solo una piccola parte, ovvero chi frequenta negli istituti professionali (in sussidiarietà), ma il MIM non registra gli iscrittti preso gli enti accreditati della regione",
               "** La riga indica esclusivamente la minima quota di studenti tracciata dai codici meccanografici del Ministero a partire dal 2018/19"
               )
  )

tipi_scuola_ft_OLD


# __ QUI 2/2 ----


# versione per il sito (2026-10-30): senza la riga "di cui IeFP" (confonde: è solo la piccola parte
# registrata dal MIM, v. callout Norma); l'asterisco passa alla riga dei professionali
tipi_scuola_ft <- tipi_scuola |>
  filter(`Tipo di scuola` != IEFP_DI_CUI) |>
  mutate(`Tipo di scuola` = if_else(`Tipo di scuola` == PROF_IEFP, paste0(PROF_IEFP, "*"), `Tipo di scuola`)) |>
  mutate(across(all_of(col_as), as.numeric)) |>
  f_ft() |>
  # na_str ripetuto: questi colformat sovrascrivono quello di f_ft() e senza na_str le celle NA restano vuote
  # alunni come numeri decimali (v. sopra) per poter dare anche decimal.mark: colformat_int() non lo
  # accetta, e con il default "." R avvisa che big.mark e decimal.mark coincidono
  colformat_double(j = col_as, digits = 0, big.mark = ".", decimal.mark = ",", na_str = "N.D.") |>
  colformat_double(j = col_pct, digits = 1, decimal.mark = ",", suffix = "%", na_str = "N.D.") |>
  merge_v(j = "Territorio") |>
  valign(j = "Territorio", valign = "top") |>
  # righe "di cui" in corsivo (tutta la riga tranne il territorio), Totale in grassetto
  # (fino al 2026-10-30 corsivo solo sulla colonna "Tipo di scuola")
  italic(i = ~ str_detect(`Tipo di scuola`, "^di cui"), j = setdiff(names(tipi_scuola), "Territorio")) |>
  # highlight arancio pallido perche dato incompleto (la IeFP degli enti di formazione accreditati non è nei dati MIM)
  bg( i = ~ str_detect(`Tipo di scuola`, "^Professionali"), j = setdiff(names(tipi_scuola), "Territorio"), bg =  '#fee6ce'
  ) |>
  bold(i = ~ `Tipo di scuola` == "Totale", j = setdiff(names(tipi_scuola), "Territorio")) |>
  # (riga IeFP in rosso tolta insieme alla riga, 2026-10-30)
  f_ft_titolo_note(
    titolo = paste0("Iscritti alle scuole superiori per tipo di scuola: Emilia-Romagna e provincia di Parma (",
                    f_lab_as_tab(min(ANNI_TAB)), "-", f_lab_as_tab(ANNO_ULTIMO), ")"),
    note   = c("Fonte: MIM, Portale unico dei dati della scuola (scuole statali e paritarie)",
               "Gli alunni sono contati nella provincia della scuola; esclusi i corsi serali e le sezioni in carcere (adulti)",
               "* Per la IeFP solo chi la frequenta negli istituti professionali (in sussidiarietà): il MIM non registra gli iscritti agli enti di formazione accreditati dalla Regione"
    )
  )

tipi_scuola_ft

# __ esplora: % per tipo di scuola, tutti gli a.s. (statali) ----
iscritti_tipo_scuola |>
  filter(gestione == "statale", tipo_scuola %in% TIPI_TOTALE) |>
  mutate(pct = round(100 * alunni / sum(alunni), 1), .by = c(territorio, anno_inizio)) |>
  select(territorio, tipo_scuola, anno_inizio, pct) |>
  pivot_wider(names_from = anno_inizio, values_from = pct) |>
  arrange(territorio, match(tipo_scuola, ORDINE_TIPI))

# __ esplora: quanto pesano le paritarie (ultimo a.s.) ----
iscritti_tipo_scuola |>
  filter(tipo_scuola %in% TIPI_TOTALE, anno_inizio == ANNO_ULTIMO) |>
  select(territorio, tipo_scuola, gestione, alunni) |>
  pivot_wider(names_from = gestione, values_from = alunni, values_fill = 0) |>
  mutate(pct_paritarie = round(100 * paritaria / (statale + paritaria), 1))
# attese a Parma circa 300 alunni nelle paritarie (1,4%), quasi tutti nei licei

# __ esplora: % di femmine per tipo di scuola (tutte, ultimo a.s.) ----
iscritti_tipo_scuola |>
  filter(anno_inizio == ANNO_ULTIMO) |>
  mutate(pct_femmine = round(100 * alunni_femmine / alunni, 1)) |>
  # select(territorio, tipo_scuola, alunni, pct_femmine) |>
  arrange(territorio, match(tipo_scuola, ORDINE_TIPI))

# 3. Istruzione professionale ------------------------------------------------

# __ esplora: professionali e IeFP per a.s. (statali), e la loro somma ----
# la IeFP del vecchio ordinamento ("ex integrativa") esce via via dopo il 2018/19: per i confronti
# nel tempo conviene guardare la somma
iscritti_tipo_scuola |>
  filter(gestione == "statale", tipo_scuola %in% TIPI_PROF) |>
  select(territorio, anno_inizio, tipo_scuola, alunni) |>
  pivot_wider(names_from = tipo_scuola, values_from = alunni, values_fill = 0) |>
  mutate(`Professionali + IeFP` = Professionali + `IeFP nei professionali`) |>
  arrange(territorio, anno_inizio)

# __ esplora: indirizzi dei professionali a Parma (statali, ultimo a.s.) ----
# settore "NUOVI PROFESSIONALI" = ordinamento attuale; gli altri settori = vecchio ordinamento
iscritti_indirizzi |>
  filter(territorio == "Provincia di Parma", gestione == "statale", anno_inizio == ANNO_ULTIMO,
         tipo_scuola %in% TIPI_PROF) |>
  summarise(alunni = sum(alunni), alunni_femmine = sum(alunni_femmine),
            .by = c(utenza, settore, indirizzo)) |>
  mutate(pct_femmine = round(100 * alunni_femmine / alunni, 1)) |>
  arrange(utenza, desc(alunni)) |>
  print(n = Inf)

# __ esplora: settori dei tecnici, Parma ed Emilia-Romagna (statali, ultimo a.s.) ----
iscritti_indirizzi |>
  filter(gestione == "statale", anno_inizio == ANNO_ULTIMO, tipo_scuola == "Tecnici") |>
  summarise(alunni = sum(alunni), .by = c(territorio, settore)) |>
  mutate(pct = round(100 * alunni / sum(alunni), 1), .by = territorio)

# __ esplora: indirizzi dei tecnici a Parma (statali, ultimo a.s.) ----
# NB: nel biennio l'indirizzo ("... - BIENNIO COMUNE"), dal terzo anno l'articolazione
iscritti_indirizzi |>
  filter(territorio == "Provincia di Parma", gestione == "statale", anno_inizio == ANNO_ULTIMO,
         tipo_scuola == "Tecnici") |>
  summarise(alunni = sum(alunni), .by = c(settore, indirizzo)) |>
  arrange(settore, desc(alunni)) |>
  print(n = Inf)

# 4. Adulti negli istituti professionali --------------------------------------

# __ esplora: utenza per tipo di scuola (statali, ultimo a.s.) ----
# adulti = serale + carcere; attese a Parma circa 9% nei professionali (269 serale + 27 carcere su 3.331)
iscritti_tipo_utenza |>
  filter(gestione == "statale", anno_inizio == ANNO_ULTIMO, tipo_scuola %in% TIPI_TOTALE) |>
  select(territorio, tipo_scuola, utenza, alunni) |>
  pivot_wider(names_from = utenza, values_from = alunni, values_fill = 0) |>
  mutate(totale = diurno + serale + carcere,
         pct_adulti = round(100 * (serale + carcere) / totale, 1)) |>
  arrange(territorio, match(tipo_scuola, ORDINE_TIPI))

# __ esplora: adulti nei professionali a Parma, per a.s. ----
iscritti_tipo_utenza |>
  filter(gestione == "statale", territorio == "Provincia di Parma", tipo_scuola %in% TIPI_PROF) |>
  summarise(alunni = sum(alunni), .by = c(anno_inizio, utenza)) |>
  pivot_wider(names_from = utenza, values_from = alunni, values_fill = 0) |>
  arrange(anno_inizio)

# 5. Adulti che tornano a scuola (grafici) -------------------------------

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

# 6. Salva (rds per il sito + png; nome file = oggetto) --------------------
saveRDS(tipi_scuola_ft, file.path(dir_mod, "tipi_scuola_ft.rds"))
# csv per i bottoni: stesse righe della tabella del sito, senza il "di cui IeFP" (dal 2026-10-30)
write_csv(tipi_scuola |> filter(`Tipo di scuola` != IEFP_DI_CUI), file.path(dir_mod, "tipi_scuola.csv"))
f_salva_plot(plot_rientro_porte_pr, "plot_rientro_porte_pr", dir_out = dir_mod, height = 4.5)
f_salva_plot(plot_rientro_trend_pr, "plot_rientro_trend_pr", dir_out = dir_mod, height = 6)
f_salva_plot(plot_rientro_incidenza_prov_er, "plot_rientro_incidenza_prov_er", dir_out = dir_mod, height = 6)
f_salva_plot(plot_rientro_profilo_pr, "plot_rientro_profilo_pr", dir_out = dir_mod, height = 7)
