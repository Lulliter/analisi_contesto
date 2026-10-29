# ___________________________________________________________________________
# Modulo: giovani_ingresso_lavoro — 00_prep_condizione_pdf.R
# Scopo:  estrarre dal Report giovani 2026 della Regione Emilia-Romagna le tabelle sulla
#         condizione professionale dei giovani (elaborazioni su ISTAT, forze di lavoro, anno 2025)
#         in un'unica tabella lunga, letta da 01_dati.R:
#         Tab. 14  15-24 / 25-34 / 15-34 / 15+ × condizione: migliaia 2019, 2024, 2025 + var. %
#         Tab. 15  15-24 / 25-34 × condizione × sesso: migliaia 2025 + var. % su 2024 e su 2019
#         Tab. 16  tasso di attività       } EU 27, Italia, Nord-est, Emilia-Romagna
#         Tab. 17  tasso di occupazione    } × 15-24 / 25-34 × sesso, 2025
#         Tab. 18  tasso di disoccupazione }
#         Tab. 19  tassi di occupazione e disoccupazione 25-34 × provincia ER × sesso, 2025
# Input:  dati/grezzi/rer_osservatorio_giovani/Report_giovani_2026.pdf
# Output: moduli/giovani_ingresso_lavoro/output/condizione_pdf.rds (+ .csv)
#           colonne: tabella, territorio, classe_eta, sesso, indicatore, anno, misura, valore, fonte
#           misura: "migliaia" | "var_pct_su_2024" | "var_pct_su_2019" (riferite al 2025) | "pct" (tassi)
# Sezioni: 1 lettura pdf · 2 Tab. 14 · 3 Tab. 15 · 4 Tab. 16-18 · 5 Tab. 19 · 6 unione e controlli · 7 salva
# NB: ogni tabella si cerca dal titolo + una riga di dati (il titolo da solo compare anche
#     nell'indice in fondo al pdf) e si legge dal titolo fino alla prima riga "Fonte".
#     Ogni blocco stampa il testo come lo vede R, le righe catturate e la pagina STAMPATA
#     (quella da confrontare col pdf aperto). Se cambia l'impaginazione (nuova edizione) le
#     regex vanno riviste: i controlli del § 6 devono tornare TRUE.
#     Valori così come stampati: le var. % e i tassi sono calcolati dalla Regione su dati non
#     arrotondati, quindi ricalcolati dalle migliaia stampate differiscono di 0,1-0,2 punti.
#     Nota 13-14 del Report: le stime della rilevazione forze di lavoro non coincidono con la
#     popolazione residente (cap. 1 del Report): sono due stime diverse della stessa popolazione.
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
file_pdf <- here("dati", "grezzi", "rer_osservatorio_giovani", "Report_giovani_2026.pdf")
dir_out  <- here("moduli", "giovani_ingresso_lavoro", "output")

# anno dei dati e anni di confronto stampati nella Tab. 14 (edizione 2026 del Report)
ANNO      <- 2025
ANNI_TAB14 <- c(2019, 2024, ANNO)
REPORT    <- "RER Report giovani 2026"

# condizioni come stampate nel pdf → codici
CONDIZIONI <- c("Forza lavoro"                    = "forza_lavoro",
                "Occupati"                        = "occupati",
                "Persone in cerca di occupazione" = "in_cerca",
                "Inattivi"                        = "inattivi")

# numeri italiani nel testo ("2.144,4" → 2144.4; "-11,4" → -11.4)
f_num_it <- function(x) as.numeric(str_replace(str_remove_all(x, "\\."), ",", "."))

# numero di pagina STAMPATO: l'ultimo numero isolato nel testo della pagina (piè di pagina)
f_pag_stampata <- function(testo_pagina) {
  righe <- str_split(testo_pagina, "\n")[[1]] |> str_squish()
  righe <- righe[righe != ""]
  ult <- tail(righe, 1)
  if (length(ult) == 1 && str_detect(ult, "^\\d{1,3}$")) as.integer(ult) else NA_integer_
}

# pagina di una tabella: contiene il titolo E una riga di dati (esclude l'indice)
f_pag_tabella <- function(titolo, riga_dati) {
  which(str_detect(testo_pdf, fixed(titolo)) & str_detect(testo_pdf, regex(riga_dati, multiline = TRUE)))[1]
}

# testo di una tabella: dal titolo alla prima "Fonte" che segue (una pagina può avere due tabelle)
f_blocco_tabella <- function(pag, titolo) {
  testo <- testo_pdf[pag]
  inizio <- str_locate(testo, fixed(titolo))[1, "start"]
  dopo <- str_sub(testo, inizio)
  str_sub(dopo, 1, str_locate(dopo, "Fonte")[1, "start"] - 1)
}

# etichetta della fonte: tabella, pagina stampata e pagina del pdf
f_fonte <- function(tab, pag) {
  str_glue("{REPORT}, Tab. {tab} (p. {f_pag_stampata(testo_pdf[pag])}; pdf p. {pag})")
}

# 1. Lettura pdf ----------------------------------------------------------
testo_pdf <- pdf_text(file_pdf)
length(testo_pdf)   # atteso 68

# 2. Tab. 14 condizione × classe d'età, migliaia 2019-2024-2025 ----
# righe: "Forza lavoro   117,8   121,0   107,3   -11,4%   -8,9%" (3 valori + 2 var. %).
# L'etichetta della classe d'età sta su righe a sé o a sinistra della condizione: le righe
# si assegnano alle classi per POSIZIONE (4 blocchi da 4 righe: 15-24, 25-34, 15-34, 15+),
# poi la riga "di cui 15-64 anni" (inattivi 15-64). I controlli del § 6 verificano l'ordine
pag_t14 <- f_pag_tabella("Tabella 14. Giovani 15-34", "Forza lavoro\\s+\\d")
pag_t14; f_pag_stampata(testo_pdf[pag_t14])   # stampata attesa: 41
blocco_t14 <- f_blocco_tabella(pag_t14, "Tabella 14. Giovani 15-34")
cat(blocco_t14)

# gli anni nell'intestazione devono essere quelli dei Parametri
stopifnot(all(str_detect(blocco_t14, as.character(ANNI_TAB14))))

rx_t14 <- str_c("(", str_c(c(names(CONDIZIONI), "di cui 15-64 anni"), collapse = "|"), ")",
                "\\s+([\\d.]+,\\d)\\s+([\\d.]+,\\d)\\s+([\\d.]+,\\d)\\s+(-?\\d+,\\d)%\\s+(-?\\d+,\\d)%")
# righe catturate (attese 17)
righe_t14 <- str_split(blocco_t14, "\n")[[1]] |> str_subset(rx_t14)
righe_t14

t14_larga <- str_match(righe_t14, rx_t14) |>
  as.data.frame() |>
  transmute(
    classe_eta = c(rep(c("15-24", "25-34", "15-34", "15+"), each = 4), "15-64"),
    indicatore = if_else(V2 == "di cui 15-64 anni", "inattivi", CONDIZIONI[V2]),
    m1 = f_num_it(V3), m2 = f_num_it(V4), m3 = f_num_it(V5),
    var_pct_su_2024 = f_num_it(V6), var_pct_su_2019 = f_num_it(V7)
  )
stopifnot(nrow(t14_larga) == 17)
t14_larga   # attese: 15-24 forza lavoro 117,8 / 121,0 / 107,3; 15-64 inattivi 708,4 / 737,6 / 714,2

t14 <- t14_larga |>
  rename_with(function(x) as.character(ANNI_TAB14), c(m1, m2, m3)) |>
  pivot_longer(-c(classe_eta, indicatore), names_to = "colonna", values_to = "valore") |>
  # colonna: "2019" / "2024" / "2025" (migliaia) oppure "var_pct_su_2024" / "var_pct_su_2019" (riferite al 2025)
  mutate(misura = if_else(str_starts(colonna, "var"), colonna, "migliaia"),
         anno   = if_else(misura == "migliaia", parse_number(colonna), ANNO),
         tabella = "14", territorio = "Emilia-Romagna", sesso = "Totale",
         fonte = f_fonte("14", pag_t14)) |>
  select(-colonna)

# 3. Tab. 15 condizione × classe d'età × sesso, migliaia 2025 + var. % ----
# righe: "Forza lavoro   65,9   -14,0%   -2,8%   41,4   -6,7%   -17,2%"
# (maschi: 2025, var. su 2024, var. su 2019; poi femmine idem). 2 blocchi da 4: 15-24, 25-34
pag_t15 <- f_pag_tabella("Tabella 15. Giovani 15-34", "Forza lavoro\\s+\\d")
pag_t15; f_pag_stampata(testo_pdf[pag_t15])   # stampata attesa: 43
blocco_t15 <- f_blocco_tabella(pag_t15, "Tabella 15. Giovani 15-34")
cat(blocco_t15)

rx_t15 <- str_c("(", str_c(names(CONDIZIONI), collapse = "|"), ")",
                "\\s+([\\d.]+,\\d)\\s+(-?\\d+,\\d)%\\s+(-?\\d+,\\d)%",
                "\\s+([\\d.]+,\\d)\\s+(-?\\d+,\\d)%\\s+(-?\\d+,\\d)%")
# righe catturate (attese 8)
righe_t15 <- str_split(blocco_t15, "\n")[[1]] |> str_subset(rx_t15)
righe_t15

t15_larga <- str_match(righe_t15, rx_t15) |>
  as.data.frame() |>
  transmute(
    classe_eta = rep(c("15-24", "25-34"), each = 4),
    indicatore = CONDIZIONI[V2],
    Maschi_migliaia  = f_num_it(V3), Maschi_var_pct_su_2024  = f_num_it(V4), Maschi_var_pct_su_2019  = f_num_it(V5),
    Femmine_migliaia = f_num_it(V6), Femmine_var_pct_su_2024 = f_num_it(V7), Femmine_var_pct_su_2019 = f_num_it(V8)
  )
stopifnot(nrow(t15_larga) == 8)
t15_larga   # attese: 15-24 forza lavoro M 65,9 F 41,4; 25-34 inattivi M 20,7 F 53,5

t15 <- t15_larga |>
  pivot_longer(-c(classe_eta, indicatore), names_to = c("sesso", "misura"),
               names_pattern = "^(Maschi|Femmine)_(.*)$", values_to = "valore") |>
  mutate(anno = ANNO, tabella = "15", territorio = "Emilia-Romagna",
         fonte = f_fonte("15", pag_t15))

# 4. Tab. 16-18 tassi × territorio × classe d'età × sesso ----
# righe: "EU 27   43,2   38,1   40,7   90,4   80,9   85,8"
# (15-24: maschi, femmine, totale; 25-34: maschi, femmine, totale). Tab. 16 e 17 stanno sulla
# stessa pagina: il blocco di ciascuna va dal titolo alla sua "Fonte"
TAB_TASSI <- c("16" = "tasso_attivita", "17" = "tasso_occupazione", "18" = "tasso_disoccupazione")
COLONNE_TASSI <- c("15-24_Maschi", "15-24_Femmine", "15-24_Totale",
                   "25-34_Maschi", "25-34_Femmine", "25-34_Totale")
rx_tassi <- str_c("^\\s*(EU 27|Italia|Nord-est|Emilia-Romagna)", str_dup("\\s+(\\d+,\\d)", 6))

f_leggi_tassi <- function(tab) {
  titolo <- str_glue("Tabella {tab}. Tasso")
  pag <- f_pag_tabella(titolo, "^\\s*EU 27\\s+\\d")
  righe <- str_split(f_blocco_tabella(pag, titolo), "\n")[[1]] |> str_subset(rx_tassi)
  str_match(righe, rx_tassi) |>
    as.data.frame() |>
    select(territorio = V2, V3:V8) |>
    rename_with(function(x) COLONNE_TASSI, V3:V8) |>
    pivot_longer(-territorio, names_to = c("classe_eta", "sesso"), names_sep = "_", values_to = "valore") |>
    mutate(valore = f_num_it(valore), indicatore = TAB_TASSI[[tab]], anno = ANNO,
           misura = "pct", tabella = tab, fonte = f_fonte(tab, pag))
}

# per vedere una tabella come la vede R (es. la 17):
cat(f_blocco_tabella(f_pag_tabella("Tabella 17. Tasso", "^\\s*EU 27\\s+\\d"), "Tabella 17. Tasso"))

t16_18 <- map(names(TAB_TASSI), f_leggi_tassi) |>
  list_rbind()
count(t16_18, tabella, fonte)   # attese 24 righe per tabella; pagine stampate 44, 44, 45
t16_18 |> filter(territorio == "Emilia-Romagna", sesso == "Totale")
# attese ER totale: attività 25,3 / 84,1; occupazione 20,9 / 79,9; disoccupazione 17,4 / 4,9

# 5. Tab. 19 tassi 25-34 × provincia × sesso ----
# righe: "Parma   84,6   68,3   77,2   3,7   7,6   5,3" (occupazione M, F, T; disoccupazione M, F, T).
# ATTENZIONE: Forlì-Cesena ha due valori stampati senza decimale ("90", "8"): la regex
# accetta numeri interi
pag_t19 <- f_pag_tabella("Tabella 19. Tasso", "^\\s*Parma\\s+\\d")
pag_t19; f_pag_stampata(testo_pdf[pag_t19])   # stampata attesa: 46
blocco_t19 <- f_blocco_tabella(pag_t19, "Tabella 19. Tasso")
cat(blocco_t19)

rx_t19 <- str_c("^\\s*(\\S.*?)\\s{2,}", str_c(rep("(\\d+(?:,\\d)?)", 6), collapse = "\\s+"), "\\s*$")
# righe catturate (attese 10: Emilia-Romagna + 9 province)
righe_t19 <- str_split(blocco_t19, "\n")[[1]] |> str_subset(rx_t19)
righe_t19

t19 <- str_match(righe_t19, rx_t19) |>
  as.data.frame() |>
  select(territorio = V2, V3:V8) |>
  rename_with(function(x) c("tasso_occupazione_Maschi", "tasso_occupazione_Femmine", "tasso_occupazione_Totale",
                            "tasso_disoccupazione_Maschi", "tasso_disoccupazione_Femmine", "tasso_disoccupazione_Totale"),
              V3:V8) |>
  pivot_longer(-territorio, names_to = c("indicatore", "sesso"),
               names_pattern = "^(.*)_(Maschi|Femmine|Totale)$", values_to = "valore") |>
  mutate(valore = f_num_it(valore), classe_eta = "25-34", anno = ANNO, misura = "pct",
         tabella = "19", fonte = f_fonte("19", pag_t19))
stopifnot(n_distinct(t19$territorio) == 10)
t19 |> filter(territorio == "Parma")
# attese Parma: occupazione 84,6 / 68,3 / 77,2; disoccupazione 3,7 / 7,6 / 5,3

# 6. Unione e controlli ----------------------------------------------------
condizione_pdf <- bind_rows(t14, t15, t16_18, t19) |>
  mutate(fonte = as.character(fonte)) |>
  select(tabella, territorio, classe_eta, sesso, indicatore, anno, misura, valore, fonte)

count(condizione_pdf, tabella)   # attese: 14 → 85; 15 → 48; 16, 17, 18 → 24; 19 → 60

# tolleranza per gli arrotondamenti (migliaia e % stampate con un decimale)
TOLL <- 0.25

# __ a) Tab. 14: var. % ricalcolate dalle migliaia vs stampate ----
# (calcolate dalla Regione su dati non arrotondati: scarti attesi fino a 0,2 punti)
controllo_var <- t14_larga |>
  rename_with(function(x) str_c("m_", ANNI_TAB14), c(m1, m2, m3)) |>
  mutate(ric_su_2024 = round((.data[[str_c("m_", ANNO)]] / m_2024 - 1) * 100, 1),
         ric_su_2019 = round((.data[[str_c("m_", ANNO)]] / m_2019 - 1) * 100, 1),
         scarto_24 = ric_su_2024 - var_pct_su_2024,
         scarto_19 = ric_su_2019 - var_pct_su_2019)
controllo_var |> select(classe_eta, indicatore, var_pct_su_2024, ric_su_2024, var_pct_su_2019, ric_su_2019)
# massimo scarto atteso 0,2 (15-34 in cerca: -1,4 stampato, -1,6 ricalcolato)
stopifnot(all(abs(controllo_var$scarto_24) <= TOLL), all(abs(controllo_var$scarto_19) <= TOLL))

# __ b) Tab. 14: forza lavoro = occupati + in cerca; 15-34 = 15-24 + 25-34 ----
controllo_t14 <- t14 |>
  filter(misura == "migliaia", classe_eta != "15-64") |>
  select(classe_eta, indicatore, anno, valore) |>
  pivot_wider(names_from = indicatore, values_from = valore) |>
  mutate(scarto_fl = forza_lavoro - occupati - in_cerca)
controllo_t14   # scarti attesi 0 o ±0,1
stopifnot(all(abs(controllo_t14$scarto_fl) <= TOLL))

controllo_15_34 <- t14 |>
  filter(misura == "migliaia", classe_eta %in% c("15-24", "25-34", "15-34")) |>
  select(classe_eta, indicatore, anno, valore) |>
  pivot_wider(names_from = classe_eta, values_from = valore) |>
  mutate(scarto = `15-34` - `15-24` - `25-34`)
controllo_15_34   # scarti attesi 0 o ±0,1 (se no, le righe sono assegnate alla classe sbagliata)
stopifnot(all(abs(controllo_15_34$scarto) <= TOLL))

# __ c) Tab. 15: maschi + femmine = totale della Tab. 14 (2025) ----
controllo_sesso <- t15 |>
  filter(misura == "migliaia") |>
  summarise(somma_mf = sum(valore), .by = c(classe_eta, indicatore)) |>
  left_join(t14 |> filter(misura == "migliaia", anno == ANNO) |> select(classe_eta, indicatore, totale = valore),
            by = c("classe_eta", "indicatore")) |>
  mutate(scarto = somma_mf - totale)
controllo_sesso   # scarti attesi 0 o ±0,1
stopifnot(all(abs(controllo_sesso$scarto) <= TOLL))

# __ d) tassi ER ricalcolati dalle migliaia (Tab. 14-15) vs stampati (Tab. 16-18) ----
# attività = forza lavoro / popolazione; occupazione = occupati / popolazione;
# disoccupazione = in cerca / forza lavoro; popolazione = forza lavoro + inattivi
controllo_tassi <- bind_rows(
  t14 |> filter(misura == "migliaia", anno == ANNO, classe_eta %in% c("15-24", "25-34")),
  t15 |> filter(misura == "migliaia")
) |>
  select(classe_eta, sesso, indicatore, valore) |>
  pivot_wider(names_from = indicatore, values_from = valore) |>
  transmute(classe_eta, sesso,
            tasso_attivita       = forza_lavoro / (forza_lavoro + inattivi) * 100,
            tasso_occupazione    = occupati / (forza_lavoro + inattivi) * 100,
            tasso_disoccupazione = in_cerca / forza_lavoro * 100) |>
  pivot_longer(starts_with("tasso"), names_to = "indicatore", values_to = "ricalcolato") |>
  left_join(t16_18 |> filter(territorio == "Emilia-Romagna") |> select(classe_eta, sesso, indicatore, stampato = valore),
            by = c("classe_eta", "sesso", "indicatore")) |>
  mutate(ricalcolato = round(ricalcolato, 2), scarto = ricalcolato - stampato)
controllo_tassi   # 18 righe; scarti attesi entro ±0,1 (es. disocc. 15-24: 17,33 vs 17,4)
stopifnot(nrow(controllo_tassi) == 18, all(abs(controllo_tassi$scarto) <= TOLL))

# __ e) Tab. 19 riga Emilia-Romagna = Tab. 17-18 (25-34) ----
controllo_t19 <- t19 |>
  filter(territorio == "Emilia-Romagna") |>
  select(indicatore, sesso, t19 = valore) |>
  left_join(t16_18 |> filter(territorio == "Emilia-Romagna", classe_eta == "25-34") |>
              select(indicatore, sesso, t17_18 = valore),
            by = c("indicatore", "sesso"))
controllo_t19   # attese 6 righe uguali
stopifnot(all(controllo_t19$t19 == controllo_t19$t17_18))

# 7. Salva ---------------------------------------------------------------
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)
saveRDS(condizione_pdf, file.path(dir_out, "condizione_pdf.rds"))
write_csv(condizione_pdf, file.path(dir_out, "condizione_pdf.csv"))
