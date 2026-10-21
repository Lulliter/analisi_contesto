# ___________________________________________________________________________
# Modulo: anziani_non_autosuff — 00_prep_prevalenze.R (fino al 2026-10-20: 00_prep_prevalenze_pdf.R)
# Scopo:  prevalenze per età (e sesso) da 5 fonti → un'unica tabella letta da 01_dati.R.
#         Una lettera per fonte, la stessa in Input, Parametri e titoli di sezione:
#         [A] CERGAS, 8° Rapporto OLTC (pdf; bib OLTC_8rapp_2026): Tab. 1.2 prevalenze per età (p. 19),
#             Tab. 1.1 totale 65+ (p. 18-19) = gravi limitazioni motorie, sensoriali e cognitive
#         [B] ISTAT, report anziani 2019 (pdf; bib IstatAnziani2019): "I numeri chiave" p. 2, ADL gravi
#         [C] ISS, Report Nazionale demenze 2024 (pdf): Tab. 1.1 tassi per sesso × classe quinquennale
#         [D] ISTAT, EHIS 2019, tavole cap. 3 (xlsx): 3.2.1 ADL, 3.3.1 IADL, 3.4.1 ADL o IADL; solo 65-74 / 75+
#         [E] ISTAT, Disabilità in cifre (xls): GALI 2023, Emilia-Romagna e Italia × 65-74 / 75+
#         [R] riscontro: trascrizione a mano di [A] e [B]; NON una fonte, serve solo al controllo del § 6
# Input:  [A] dati/grezzi/cergas_oltc/oltc_8_rapporto_2026.pdf
#         [B] dati/grezzi/istat_ehis_2019/istat_report_anziani_2019.pdf
#             (scaricato da https://www.istat.it/it/files/2021/07/Report-anziani-2019.pdf)
#         [C] dati/grezzi/iss_demenze/ReportNazionale_2024.pdf
#         [D] dati/grezzi/istat_ehis_2019/ehis2019_3_limitazioni.xlsx
#         [E] dati/grezzi/istat_disab_cifre_gali_2023/gali_2023_eta_regione.xls
#         [R] moduli/anziani_non_autosuff/riscontro_prevalenze_a_mano.csv (sta nel modulo, non in grezzi/)
# Output: moduli/anziani_non_autosuff/output/prevalenze.rds (+ .csv) (fino al 2026-10-20: prevalenze_pdf)
#           colonne: indicatore, classe_eta, sesso, territorio, valore, fonte, nota
# Sezioni: 1 [A] · 2 [B] · 3 [C] · 4 [D] · 5 [E] · 6 unione e controlli · 7 salva
# NB pdf ([A]-[C]): il numero di pagina del pdf dipende dalla copia (copertine, frontespizi): lo
#     script trova la pagina dal titolo + righe della tabella e stampa il numero STAMPATO in fondo
#     alla pagina, che è quello da confrontare col pdf aperto. Per rivedere: lanciare riga per riga;
#     ogni blocco stampa la pagina trovata, le righe catturate dalla regex e i numeri letti.
#     pdftools::pdf_text restituisce il testo pagina per pagina con l'impaginazione conservata; le
#     tabelle si leggono riga per riga con espressioni regolari. Se un pdf cambia impaginazione
#     (nuova edizione) le regex vanno riviste: i controlli in coda devono tornare TRUE
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(stringr)
library(purrr)
library(readr)
library(tidyr)
library(pdftools)
library(readxl)

# Parametri ---------------------------------------------------------------
dir_out <- here("moduli", "anziani_non_autosuff", "output")

# file di input: lettere come nell'intestazione e nei titoli di sezione
# [A] CERGAS, 8° Rapporto OLTC (pdf)
file_oltc  <- here("dati", "grezzi", "cergas_oltc", "oltc_8_rapporto_2026.pdf")
# [B] ISTAT, report anziani 2019 (pdf)
file_istat <- here("dati", "grezzi", "istat_ehis_2019", "istat_report_anziani_2019.pdf")
# [C] ISS, Report Nazionale demenze 2024 (pdf)
file_iss   <- here("dati", "grezzi", "iss_demenze", "ReportNazionale_2024.pdf")
# [D] ISTAT, EHIS 2019, tavole cap. 3 (xlsx)
file_ehis  <- here("dati", "grezzi", "istat_ehis_2019", "ehis2019_3_limitazioni.xlsx")
# [E] ISTAT, Disabilità in cifre, GALI 2023 (xls)
file_gali  <- here("dati", "grezzi", "istat_disab_cifre_gali_2023", "gali_2023_eta_regione.xls")
# [R] riscontro a mano di [A] e [B] (NON una fonte)
file_csv_mano <- here("moduli", "anziani_non_autosuff", "riscontro_prevalenze_a_mano.csv")

# [D] tavole EHIS da leggere: foglio → tema
TAVOLE_EHIS <- c(tavola3.2.1 = "adl", tavola3.3.1 = "iadl", tavola3.4.1 = "adl_o_iadl")
# [E] territori GALI da tenere
TERRITORI_GALI <- c("Emilia-Romagna", "Italia")

# numeri italiani nel testo ("14,6" → 14.6; "6.913.692" → 6913692)
f_num_it <- function(x) as.numeric(str_replace(str_remove_all(x, "\\."), ",", "."))

# numero di pagina STAMPATO: l'ultimo numero isolato nel testo della pagina (piè di pagina);
# NA se la pagina non lo ha. Serve a citare la pagina come la si legge sul pdf
f_pag_stampata <- function(testo_pagina) {
  righe <- str_split(testo_pagina, "\n")[[1]] |> str_squish()
  righe <- righe[righe != ""]
  ult <- tail(righe, 1)
  if (length(ult) == 1 && str_detect(ult, "^\\d{1,3}$")) as.integer(ult) else NA_integer_
}

# 1. [A] CERGAS, 8° Rapporto OLTC (pdf) ----
# ___ Tab. 1.2 p. 19 -----
# (prevalenze per 3 classi d'età)  
testo_oltc <- pdf_text(file_oltc)

# pagina che contiene la Tab. 1.2: titolo E righe della tabella (il titolo da solo compare anche
# nel testo che la cita)
pag_tab12 <- which(str_detect(testo_oltc, "Tabella 1\\.2") & str_detect(testo_oltc, "\\n\\s*65-74\\s+\\d+,\\d%"))[1]
pag_tab12; f_pag_stampata(testo_oltc[pag_tab12])   # stampata attesa: 19
# [A] TABELLA TRASCRITTA: CERGAS Tab. 1.2 — per vedere la pagina come la vede R:
cat(testo_oltc[pag_tab12])

righe_tab12 <- str_split(testo_oltc[pag_tab12], "\n")[[1]]
# righe che la regex cattura (devono essere le 3 della tabella)
str_subset(righe_tab12, "^\\s*(65-74|75-84|85 e più)\\s+\\d+,\\d%")

# righe della tabella: "65-74   14,6%   6.913.692   1.009.399" (classe, prevalenza, pop, stima)
oltc_classi <- righe_tab12 |>
  str_subset("^\\s*(65-74|75-84|85 e più)\\s+\\d+,\\d%") |>
  str_match("^\\s*(65-74|75-84|85 e più)\\s+(\\d+,\\d)%\\s+([\\d.]+)\\s+([\\d.]+)") |>
  as.data.frame() |>
  transmute(classe_eta = recode(V2, "85 e più" = "85+"),
            prevalenza = f_num_it(V3),
            pop_italia_2023 = f_num_it(V4),
            stima_italia_2023 = f_num_it(V5))

oltc_classi   # attese 3 righe: 14,6 / 32,5 / 63,8

# ___ Tab. 1.1 p. 18 -----
# Over 65 con limitazioni funzionali: stima del bisogno potenziale (anni 2013-2016; 2019-2023)
# la colonna "Modalità di calcolo" dice "19,8% della popola-" (2013-16) e
# "28,4% della popola-" (2019-23). "Tabella 1.1" compare prima nel testo come rimando,
# quindi la pagina si cerca dalla frase, non dal titolo
# diagnosi: le righe con "della popola" in tutto il pdf (attese 5: 4 × 19,8 e 1 × 28,4)
str_split(testo_oltc, "\n") |> unlist() |> str_subset("della popola")

# pagine della Tab. 1.1: la colonna "Modalità di calcolo" dice "19,8% / 28,4% della popola-
# zione di riferimento" (a capo dentro la cella); la frase "% della popolazione" da sola compare
# anche altrove nel Rapporto (es. "32,5% della popolazione dell'UE")
pag_tab11 <- which(str_detect(testo_oltc, "\\d+,\\d\\s*%\\s*della\\s+popola") &
                     str_detect(testo_oltc, "zione di riferimento"))
pag_tab11; sapply(testo_oltc[pag_tab11], f_pag_stampata) |> unname()   # stampate attese: 18, 19

oltc_tot <- str_c(testo_oltc[pag_tab11], collapse = "\n") |>
  str_extract_all("\\d+,\\d\\s*%\\s*della\\s+popola") |>
  unlist() |>
  str_extract("\\d+,\\d") |>
  f_num_it() |>
  unique()

oltc_tot   # attesi due valori: 19,8 (metodo 2013-2016) e 28,4 (dal 2019)
stopifnot(length(oltc_tot) == 2)
# [A] TABELLA TRASCRITTA: CERGAS Tab. 1.1 (colonna "Modalità di calcolo"), pagine pag_tab11

prev_oltc <- bind_rows(
  oltc_classi |>
    transmute(indicatore = "gravi_limitazioni_funzionali", classe_eta, sesso = "Totale",
              territorio = "Italia", valore = prevalenza,
              fonte = glue::glue("OLTC_8rapp_2026 Tab. 1.2 (p. {f_pag_stampata(testo_oltc[pag_tab12])}; pdf p. {pag_tab12})"),
              # 2026-10-20: nel report ISTAT (p. 2) questi valori stanno nella colonna "gravi limitazioni
              # motorie, sensoriali e cognitive", NON in ADL o IADL (tav. 3.4.1: 12,2 / 43,6 per 65-74 / 75+);
              # il Rapporto li presenta come ADL o IADL gravi
              nota = "gravi limitazioni motorie, sensoriali e cognitive (report ISTAT p. 2); il Rapporto le presenta come ADL o IADL gravi"),
  tibble(indicatore = "gravi_limitazioni_funzionali", classe_eta = "65+", sesso = "Totale",
         territorio = "Italia", valore = max(oltc_tot),
         fonte = glue::glue("OLTC_8rapp_2026 Tab. 1.1 (p. {str_c(sapply(testo_oltc[pag_tab11], f_pag_stampata), collapse = '-')}; pdf p. {str_c(pag_tab11, collapse = '-')})"),
         nota = "definizione CERGAS di anziani non autosufficienti")
)

# 2. [B] ISTAT, report anziani 2019 (pdf) ----
# p. 2 "I numeri chiave": una riga per classe d'età (65-74, 75-84, 75 e oltre, 85 e oltre),
# Totale, Uomini, Donne; 7 colonne di tassi per 100. Qui servono:
#   4ª colonna = gravi limitazioni motorie, sensoriali e cognitive → è la fonte della Tab. 1.2
#                CERGAS (14,6 / 32,5 / 63,8; totale 28,4): usata SOLO come controllo incrociato
#   6ª colonna = gravi difficoltà nelle attività di cura della persona (ADL)
# (p. 7 Nord-est: tassi standardizzati, restano solo nel csv a mano)
if (file.exists(file_istat)) {
  testo_istat <- pdf_text(file_istat)
  righe_istat <- str_split(testo_istat[2], "\n")[[1]]
  # [B] TABELLA TRASCRITTA: ISTAT "I numeri chiave", p. 2 (stampata 2)
  cat(testo_istat[2])

  righe_tab <- righe_istat |>
    str_subset("^\\s*(65-74|75-84|75 e oltre|85 e oltre|Totale|Uomini|Donne)\\s+\\d+,\\d")

  istat_classi <- tibble(
    riga   = str_extract(righe_tab, "65-74|75-84|75 e oltre|85 e oltre|Totale|Uomini|Donne"),
    numeri = str_extract_all(righe_tab, "\\d+,\\d")
  ) |>
    mutate(classe_eta = case_when(riga == "85 e oltre" ~ "85+",
                                  riga == "75 e oltre" ~ "75+",
                                  riga %in% c("Totale", "Uomini", "Donne") ~ "65+",
                                  TRUE ~ riga),
           sesso      = case_when(riga == "Uomini" ~ "Maschi",
                                  riga == "Donne"  ~ "Femmine",
                                  TRUE ~ "Totale"),
           gravi_limitazioni = f_num_it(map_chr(numeri, 4)),
           gravi_adl         = f_num_it(map_chr(numeri, 6))) |>
    select(classe_eta, sesso, gravi_limitazioni, gravi_adl)

  istat_classi
  # attese ADL:          65-74 2,6; 75-84 10,3; 75+ 18,3; 85+ 37,2; 65+ 10,6 (M 7,5; F 13,3)
  # attese limitazioni:  14,6; 32,5; 41,9; 63,8; 28,4 (M 22,8; F 32,8)
  stopifnot(nrow(istat_classi) == 7, !anyNA(istat_classi$gravi_adl))

  # controllo incrociato: le limitazioni ISTAT per 65-74 / 75-84 / 85+ / 65+ devono coincidere
  # con la Tab. 1.2 e la Tab. 1.1 del CERGAS lette sopra
  controllo_istat_cergas <- istat_classi |>
    filter(sesso == "Totale", classe_eta != "75+") |>
    select(classe_eta, istat = gravi_limitazioni) |>
    left_join(prev_oltc |> select(classe_eta, cergas = valore), by = "classe_eta")
  controllo_istat_cergas   # attese 4 righe con istat == cergas
  stopifnot(all(controllo_istat_cergas$istat == controllo_istat_cergas$cergas))

  prev_istat <- istat_classi |>
    transmute(indicatore = "gravi_difficolta_adl", classe_eta, sesso, territorio = "Italia",
              valore = gravi_adl, fonte = "IstatAnziani2019 p. 2",
              nota = "cura della persona (ADL)")
} else {
  message("pdf ISTAT non trovato: le prevalenze ADL restano quelle del csv trascritto a mano")
  prev_istat <- read_csv(file_csv_mano, show_col_types = FALSE) |>
    filter(str_starts(fonte, "IstatAnziani2019"), territorio == "Italia")
}

# 3. [C] ISS, Report Nazionale demenze 2024 (pdf) ----
# ___ Tab. 1.1 "Casi prevalenti demenza ≥65 anni" (sesso × classi quinquennali) ----
# ISS, Report Nazionale 2024, Tab. 1.1 (p. 1 del cap. 1): per ogni classe (65-69 … ≥90) e per sesso:
# popolazione, tasso × 100, casi; poi colonne totale. Tassi di Bacigalupo et al. 2018
testo_iss <- pdf_text(file_iss)
pag_iss <- which(str_detect(testo_iss, "Tabella 1\\.1 Italia\\. Casi prevalenti"))[1]
pag_iss; f_pag_stampata(testo_iss[pag_iss])   # stampata attesa: 1 (prima pagina del capitolo 1)
# [C] TABELLA TRASCRITTA: ISS Tab. 1.1
cat(testo_iss[pag_iss])

righe_iss <- str_split(testo_iss[pag_iss], "\n")[[1]]

# righe: "65-69   1.713.300   0,9   15.420   1.875.973   1,1   20.636   3.589.273   36.055"
# ("≥90" può arrivare come "!90" o "≥90" dall'estrazione: accetto entrambi).
# Le classi sono vincolate a 65-69 … 85-89 e ≥90 perché sulla stessa pagina c'è la Tab. 1.2
# (demenza giovanile, 35-39 … 60-64) con lo stesso formato
CLASSI_ISS <- "((65|70|75|80|85)-\\d{2}|[≥!]\\s?90)"
iss_classi <- righe_iss |>
  str_subset(str_c("^\\s*", CLASSI_ISS, "\\s+[\\d.]+\\s+\\d+,?\\d*\\s+[\\d.]+\\s+[\\d.]+\\s+\\d+,?\\d*")) |>
  str_match(str_c("^\\s*", CLASSI_ISS, "\\s+([\\d.]+)\\s+(\\d+,?\\d*)\\s+([\\d.]+)\\s+([\\d.]+)\\s+(\\d+,?\\d*)\\s+([\\d.]+)")) |>
  as.data.frame() |>
  # V2 = classe; V3 = gruppo interno (65|70|…) della regex, non serve; dati da V4 in poi
  transmute(classe_eta = if_else(str_detect(V2, "90"), "90+", V2),
            pop_m = f_num_it(V4), tasso_m = f_num_it(V5), casi_m = f_num_it(V6),
            pop_f = f_num_it(V7), tasso_f = f_num_it(V8), casi_f = f_num_it(V9))

iss_classi   # attese 6 righe (65-69 … 90+); nessuna riga della Tab. 1.2 (35-39 … 60-64)
stopifnot(nrow(iss_classi) == 6)

# controllo: i casi ricalcolati (pop × tasso) tornano con quelli stampati, e il totale = 1.126.961
iss_classi |>
  mutate(ric_m = round(pop_m * tasso_m / 100), ric_f = round(pop_f * tasso_f / 100),
         scarto_m = ric_m - casi_m, scarto_f = ric_f - casi_f)
# la somma delle righe stampate fa 1.126.963: il totale del Rapporto (1.126.961) è arrotondato a parte
sum(iss_classi$casi_m + iss_classi$casi_f)   # atteso 1126961 (± qualche unità)
stopifnot(abs(sum(iss_classi$casi_m + iss_classi$casi_f) - 1126961) <= 5)

prev_iss <- iss_classi |>
  select(classe_eta, Maschi = tasso_m, Femmine = tasso_f) |>
  pivot_longer(c(Maschi, Femmine), names_to = "sesso", values_to = "valore") |>
  mutate(indicatore = "demenze", territorio = "Italia",
         fonte = glue::glue("ISS Report Nazionale 2024 Tab. 1.1 (p. {f_pag_stampata(testo_iss[pag_iss])}; pdf p. {pag_iss})"),
         nota = "tassi di prevalenza Bacigalupo et al. 2018; demenza late onset (≥ 65 anni)") |>
  select(indicatore, classe_eta, sesso, territorio, valore, fonte, nota)

# 4. [D] ISTAT, EHIS 2019, tavole cap. 3 (xlsx) ----
# legge una tavola EHIS del cap. 3: etichette in colonna 1, modalità (NO/SI oppure
# Nessuna/Moderata/Grave) nella riga che contiene "Non indicato"; sesso nelle righe
# "MASCHI" / "FEMMINE" / "MASCHI E FEMMINE" sopra le classi d'età
f_leggi_tavola_ehis <- function(foglio) {
  raw <- read_excel(file_ehis, sheet = foglio, col_names = FALSE, .name_repair = "minimal")
  riga_mod <- which(apply(raw, 1, function(r) any(r %in% "Non indicato")))[1]
  modalita <- as.character(unlist(raw[riga_mod, -1]))
  modalita[is.na(modalita)] <- "Totale"
  names(raw) <- c("etichetta", modalita)
  raw |>
    slice((riga_mod + 1):n()) |>
    filter(!is.na(etichetta)) |>
    mutate(across(-etichetta, as.character),
           sesso = if_else(etichetta %in% c("MASCHI", "FEMMINE", "MASCHI E FEMMINE"), etichetta, NA_character_)) |>
    fill(sesso) |>
    filter(etichetta != sesso) |>
    pivot_longer(-c(etichetta, sesso), names_to = "modalita", values_to = "valore") |>
    mutate(valore = as.numeric(valore), foglio = foglio)
}

ehis_raw <- map(names(TAVOLE_EHIS), f_leggi_tavola_ehis) |>
  list_rbind()

# controllo: modalità e classi lette per foglio
count(ehis_raw, foglio, modalita)
count(ehis_raw, foglio, etichetta)

# difficoltà gravi (Grave / SI), moderate e, per ADL o IADL, nessuna grave difficoltà (NO)
prev_ehis <- ehis_raw |>
  filter(modalita %in% c("Grave", "SI", "Moderata", "NO")) |>
  mutate(
    tema = TAVOLE_EHIS[foglio],
    indicatore = case_when(
      modalita == "Moderata" ~ paste0("moderate_difficolta_", tema),
      modalita == "NO"       ~ paste0("nessuna_grave_difficolta_", tema),
      TRUE                   ~ paste0("gravi_difficolta_", tema)
    ),
    classe_eta = recode(etichetta, "75 e più" = "75+", "Totale" = "65+"),
    sesso = recode(sesso, "MASCHI" = "Maschi", "FEMMINE" = "Femmine", "MASCHI E FEMMINE" = "Totale"),
    territorio = "Italia",
    fonte = paste0("ISTAT EHIS 2019, tav. ", sub("tavola", "", foglio)),
    nota = "gravi = molta difficoltà o non in grado; % su 100 persone di 65+ comprese le non risposte"
  ) |>
  select(indicatore, classe_eta, sesso, territorio, valore, fonte, nota)

prev_ehis

# valori attesi (letti a mano dalle tavole, 2026-10-20), maschi e femmine
prev_ehis |>
  filter(sesso == "Totale", indicatore %in% c("gravi_difficolta_adl_o_iadl", "gravi_difficolta_iadl",
                                              "nessuna_grave_difficolta_adl_o_iadl")) |>
  select(indicatore, classe_eta, valore) 
# atteso: adl_o_iadl 12,2 / 43,6 / 28,2; iadl 12,1 / 42,9 / 27,7; nessuna grave 86,5 / 53,8 / 69,9

# 5. [E] ISTAT, Disabilità in cifre, GALI 2023 (xls) ----
# foglio per età assemblato nel vecchio repo (v. _metadati.md): controllo sul foglio scaricato al § 6
gali_raw <- read_excel(file_gali, sheet = "2023_eta_regione")

prev_gali <- gali_raw |>
  filter(Territorio %in% TERRITORI_GALI,
         livello_gravità_limitazioni %in% c("Limitazioni gravi", "Limitazioni non gravi")) |>
  select(territorio = Territorio, livello = livello_gravità_limitazioni,
         `65-74` = `65-74 anni`, `75+` = `75 anni e più`) |>
  pivot_longer(c(`65-74`, `75+`), names_to = "classe_eta", values_to = "valore") |>
  mutate(indicatore = if_else(livello == "Limitazioni gravi", "gali_grave", "gali_non_grave"),
         sesso = "Totale",
         fonte = "ISTAT Disabilità in cifre, tav. a.2 (2023)",
         nota = "limitazioni da almeno 6 mesi nelle attività abitualmente svolte; solo persone in famiglia") |>
  select(indicatore, classe_eta, sesso, territorio, valore, fonte, nota)

prev_gali

# 6. Unione e controlli: [R] vs [A]+[B], [D] vs [B], [E] per età vs [E] scaricato ----
prevalenze_pdf <- bind_rows(prev_oltc, prev_istat, prev_iss) |>
  mutate(fonte = as.character(fonte))

prevalenze_pdf

# il csv a mano e l'estrazione devono coincidere sui valori (stesse chiavi); le demenze
# non sono nel csv a mano (il controllo è la somma dei casi sopra); il Nord-est (p. 7) è
# solo nel csv a mano
confronto <- read_csv(file_csv_mano, show_col_types = FALSE) |>
  filter(territorio == "Italia") |>
  select(indicatore, classe_eta, sesso, territorio, valore_mano = valore) |>
  full_join(prevalenze_pdf |> filter(indicatore != "demenze") |>
              select(indicatore, classe_eta, sesso, territorio, valore_pdf = valore),
            by = c("indicatore", "classe_eta", "sesso", "territorio"))

confronto |> filter(is.na(valore_mano) | is.na(valore_pdf) | valore_mano != valore_pdf)   # atteso: 0 righe

# ADL gravi dalla tav. 3.2.1 vs report (p. 2): atteso 1 riga, Maschi 65+ 7,1 (tavola) vs 7,5 (report):
# vale la tavola, coerente con il totale 10,6
prev_ehis |>
  filter(indicatore == "gravi_difficolta_adl") |>
  inner_join(prevalenze_pdf |> select(indicatore, classe_eta, sesso, territorio, valore_pdf = valore),
             by = c("indicatore", "classe_eta", "sesso", "territorio")) |>
  filter(valore != valore_pdf)

# GALI: la media generale del foglio per età = foglio scaricato "2023" (tutte le età): atteso 0 righe
gali_scaricato <- read_excel(file_gali, sheet = "2023", skip = 3) |>
  select(territorio = REGIONI, grave_scaricato = `Limitazioni gravi`)

gali_raw |>
  filter(livello_gravità_limitazioni == "Limitazioni gravi") |>
  select(territorio = Territorio, grave_eta = `media generale`) |>
  inner_join(gali_scaricato, by = "territorio") |>
  filter(grave_eta != grave_scaricato)

# unione: ADL gravi dalla tavola per 65-74, 75+ e 65+ (anche per sesso); dal report solo 75-84 e 85+
prevalenze <- bind_rows(
  prevalenze_pdf |> filter(!(indicatore == "gravi_difficolta_adl" & classe_eta %in% c("65-74", "75+", "65+"))),
  prev_ehis,
  prev_gali
)

prevalenze

# 7. Salva ----
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)
# (fino al 2026-10-20 salvava solo prevalenze_pdf.rds / .csv)
saveRDS(prevalenze, file.path(dir_out, "prevalenze.rds"))
write_csv(prevalenze, file.path(dir_out, "prevalenze.csv"))

