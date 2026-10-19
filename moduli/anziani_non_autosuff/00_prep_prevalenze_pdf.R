# ___________________________________________________________________________
# Modulo: anziani_non_autosuff — 00_prep_prevalenze_pdf.R
# Scopo:  estrazione RIPRODUCIBILE delle prevalenze dai pdf (pdftools + regex). Tabelle lette:
#         [A] CERGAS 8° Rapporto OLTC, Tab. 1.2 "Over65 con limitazioni funzionali per fascia di età"
#             (stampata p. 19) e Tab. 1.1 "stima del bisogno potenziale" (stampate 18-19)
#         [B] ISTAT report anziani 2019, "I numeri chiave" (p. 2): ADL gravi; le limitazioni
#             della stessa tabella fanno da controllo incrociato con [A]
#         [C] ISS Report Nazionale 2024, Tab. 1.1 "Casi prevalenti demenza ≥65 anni" (stampata p. 1 del cap. 1)
#         Il numero di pagina del pdf dipende dalla copia (copertine, frontespizi): lo script trova la
#         pagina dal titolo + righe della tabella e stampa il numero STAMPATO in fondo alla pagina,
#         che è quello da confrontare col pdf aperto
#         Per rivedere: lanciare riga per riga; ogni blocco stampa la pagina trovata, le righe
#         catturate dalla regex e i numeri letti, da confrontare con il pdf aperto a quella pagina
# Fonte:  CERGAS Bocconi, 8° Rapporto Osservatorio Long Term Care (bib OLTC_8rapp_2026),
#         cap. 1, Tab. 1.1 e 1.2 (p. 18-19 stampate); ISTAT, "Le condizioni di salute della
#         popolazione anziana in Italia, anno 2019" (bib IstatAnziani2019), p. 2 e 7;
#         ISS, Report Nazionale 2024 del Fondo Alzheimer e demenze, Tab. 1.1 (p. 1 del cap. 1)
# Input:  dati/grezzi/cergas_oltc/oltc_8_rapporto_2026.pdf
#         dati/grezzi/iss_demenze/ReportNazionale_2024.pdf   (Tab. 1.1: demenza per sesso × età)
#         dati/grezzi/istat_ehis_2019/istat_report_anziani_2019.pdf   (da scaricare:
#           https://www.istat.it/it/files/2021/07/Report-anziani-2019.pdf)
# Output: moduli/anziani_non_autosuff/output/prevalenze_pdf.rds (+ .csv)
#           stesso formato del csv trascritto a mano (indicatore, classe_eta, sesso,
#           territorio, valore, fonte, nota): 01_dati.R legge QUESTO e usa il csv a mano
#           solo come controllo dell'estrazione
# NB: pdftools::pdf_text restituisce il testo pagina per pagina con l'impaginazione
#     conservata; le tabelle si leggono riga per riga con espressioni regolari. Se un
#     pdf cambia impaginazione (nuova edizione) le regex vanno riviste: i controlli in
#     coda devono tornare TRUE
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(stringr)
library(purrr)
library(readr)
library(tidyr)
library(pdftools)

# Parametri ---------------------------------------------------------------
dir_in  <- here("dati", "grezzi", "istat_ehis_2019")
dir_out <- here("moduli", "anziani_non_autosuff", "output")
file_oltc  <- here("dati", "grezzi", "cergas_oltc", "oltc_8_rapporto_2026.pdf")
file_istat <- file.path(dir_in, "istat_report_anziani_2019.pdf")
file_iss   <- here("dati", "grezzi", "iss_demenze", "ReportNazionale_2024.pdf")
# trascrizione a mano (riscontro dell'estrazione, NON una fonte): sta nel modulo, non in grezzi/
file_csv_mano <- here("moduli", "anziani_non_autosuff", "riscontro_prevalenze_a_mano.csv")

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

# 1. [A] CERGAS: "dati/grezzi/cergas_oltc/oltc_8_rapporto_2026.pdf"  ----
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
              nota = "ADL o IADL gravi; il Rapporto cita ISTAT (2021) = IstatAnziani2019"),
  tibble(indicatore = "gravi_limitazioni_funzionali", classe_eta = "65+", sesso = "Totale",
         territorio = "Italia", valore = max(oltc_tot),
         fonte = glue::glue("OLTC_8rapp_2026 Tab. 1.1 (p. {str_c(sapply(testo_oltc[pag_tab11], f_pag_stampata), collapse = '-')}; pdf p. {str_c(pag_tab11, collapse = '-')})"),
         nota = "definizione CERGAS di anziani non autosufficienti")
)

# 2. [B] ISTAT report: "dati/grezzi/istat_ehis_2019/istat_report_anziani_2019.pdf" ----
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

# 3. [C] ISS demenze: "dati/grezzi/iss_demenze/ReportNazionale_2024.pdf" ----- 
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

# 4. Unione e controllo contro la trascrizione a mano ----------------------
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

# 5. Salva -----------------------------------------------------------------
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)
saveRDS(prevalenze_pdf, file.path(dir_out, "prevalenze_pdf.rds"))
write_csv(prevalenze_pdf, file.path(dir_out, "prevalenze_pdf.csv"))
