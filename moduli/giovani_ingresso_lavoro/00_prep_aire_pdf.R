# ___________________________________________________________________________
# Modulo: giovani_ingresso_lavoro — 00_prep_aire_pdf.R
# Scopo:  estrarre dal Report giovani 2026 della Regione Emilia-Romagna le tabelle sugli
#         emiliano-romagnoli iscritti all'AIRE (Anagrafe degli italiani residenti all'estero),
#         in un'unica tabella lunga letta da 01_dati.R:
#         Tab. 2  Emilia-Romagna × classe d'età: iscritti 2023, 2024, 2025, % femmine e % sul totale
#                 2025, var. % 2023-2024 e 2024-2025
#         Tab. 3  province ER (+ totale regionale) × tutte le età / 19-34 anni: iscritti e iscritti
#                 ogni 1.000 abitanti 2025, differenza con il 2023
# Input:  dati/grezzi/rer_osservatorio_giovani/Report_giovani_2026.pdf
# Output: moduli/giovani_ingresso_lavoro/output/aire_pdf.rds (+ .csv)
#           colonne: tabella, territorio, classe_eta, indicatore, anno, misura, valore, fonte
#           misura: "n" | "per_1000" | "pct_femmine" | "pct_su_totale" | "var_pct_su_anno_prec" |
#                   "diff_per_1000_su_2023"
# Sezioni: 1 lettura pdf · 2 Tab. 2 · 3 Tab. 3 · 4 unione e controlli · 5 salva
# NB: stesso metodo di 00_prep_condizione_pdf.R (titolo + riga di dati per trovare la pagina,
#     blocco dal titolo alla riga della fonte, pagina stampata nella colonna fonte).
#     L'AIRE conta i cittadini italiani residenti all'estero da più di 12 mesi: chi è partito
#     dall'Emilia-Romagna, ma anche chi è nato all'estero e ha la cittadinanza italiana (per
#     discendenza) ed è iscritto a un comune della regione. Non misura le partenze dell'anno.
#     Il pdf scrive "ﬁno" con la legatura ﬁ (un solo carattere): il testo si normalizza al § 1.
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(stringr)
library(readr)
library(tidyr)
library(pdftools)

# Parametri ---------------------------------------------------------------
file_pdf <- here("dati", "grezzi", "rer_osservatorio_giovani", "Report_giovani_2026.pdf")
dir_out  <- here("moduli", "giovani_ingresso_lavoro", "output")

# anni della Tab. 2 (edizione 2026 del Report)
ANNI_TAB2 <- c(2023, 2024, 2025)
ANNO      <- 2025
REPORT    <- "RER Report giovani 2026"

# classi d'età come stampate → codici
CLASSI_AIRE <- c("fino a 18 anni" = "0-18", "19 - 34 anni" = "19-34", "35 - 49 anni" = "35-49",
                 "50 - 64 anni" = "50-64", "65 e più" = "65+", "Totale" = "totale")

# numeri italiani nel testo ("64.126" → 64126; "+10,6" → 10.6)
f_num_it <- function(x) as.numeric(str_replace(str_remove_all(x, "[.+]"), ",", "."))

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

# testo di una tabella: dal titolo alla riga della fonte ("Elaborazione"/"elaborazione ART-ER ...")
f_blocco_tabella <- function(pag, titolo) {
  testo <- testo_pdf[pag]
  inizio <- str_locate(testo, fixed(titolo))[1, "start"]
  dopo <- str_sub(testo, inizio)
  str_sub(dopo, 1, str_locate(dopo, "[Ee]laborazione")[1, "start"] - 1)
}

# etichetta della fonte: tabella, pagina stampata e pagina del pdf
f_fonte <- function(tab, pag) {
  str_glue("{REPORT}, Tab. {tab} (p. {f_pag_stampata(testo_pdf[pag])}; pdf p. {pag})")
}

# 1. Lettura pdf ----------------------------------------------------------
# legatura "ﬁ" (U+FB01) → "fi", così "ﬁno a 18 anni" si legge come "fino a 18 anni"
testo_pdf <- pdf_text(file_pdf) |>
  str_replace_all("ﬁ", "fi")
length(testo_pdf)   # atteso 68

# 2. Tab. 2 iscritti AIRE per classe d'età, Emilia-Romagna ----
# righe: "19 - 34 anni   55.349   60.546   64.126   49,8%   21,9%   9,4%   5,9%"
# (iscritti 2023, 2024, 2025; % femmine 2025; % sul totale 2025; var. % 2023-24; var. % 2024-25)
pag_t2 <- f_pag_tabella("Tabella 2. Iscritti", "19 - 34 anni\\s+[\\d.]+")
pag_t2; f_pag_stampata(testo_pdf[pag_t2])   # stampata attesa: 18
blocco_t2 <- f_blocco_tabella(pag_t2, "Tabella 2. Iscritti")
cat(blocco_t2)

rx_t2 <- str_c("^\\s*(", str_c(names(CLASSI_AIRE), collapse = "|"), ")",
               "\\s+([\\d.]+)\\s+([\\d.]+)\\s+([\\d.]+)\\s+(\\d+,\\d)%\\s+(\\d+,\\d)%\\s+(-?\\d+,\\d)%\\s+(-?\\d+,\\d)%")
# righe catturate (attese 6: 5 classi + Totale)
righe_t2 <- str_split(blocco_t2, "\n")[[1]] |> str_subset(rx_t2)
righe_t2

t2_larga <- str_match(righe_t2, rx_t2) |>
  as.data.frame() |>
  transmute(classe_eta = CLASSI_AIRE[V2],
            n_2023 = f_num_it(V3), n_2024 = f_num_it(V4), n_2025 = f_num_it(V5),
            pct_femmine = f_num_it(V6), pct_su_totale = f_num_it(V7),
            var_2024 = f_num_it(V8), var_2025 = f_num_it(V9))
stopifnot(nrow(t2_larga) == 6)
t2_larga   # attese: 19-34 → 55.349 / 60.546 / 64.126; totale → 265.103 / 280.653 / 292.399

t2 <- bind_rows(
  # iscritti per anno
  t2_larga |>
    select(classe_eta, starts_with("n_")) |>
    pivot_longer(-classe_eta, names_to = "anno", values_to = "valore") |>
    mutate(anno = parse_number(anno), misura = "n"),
  # % femmine e % sul totale (2025)
  t2_larga |>
    select(classe_eta, pct_femmine, pct_su_totale) |>
    pivot_longer(-classe_eta, names_to = "misura", values_to = "valore") |>
    mutate(anno = ANNO),
  # var. % sull'anno precedente (anno = anno di arrivo)
  t2_larga |>
    select(classe_eta, var_2024, var_2025) |>
    pivot_longer(-classe_eta, names_to = "anno", values_to = "valore") |>
    mutate(anno = parse_number(anno), misura = "var_pct_su_anno_prec")
) |>
  mutate(tabella = "2", territorio = "Emilia-Romagna", indicatore = "iscritti_aire",
         fonte = f_fonte("2", pag_t2))

# 3. Tab. 3 iscritti AIRE per provincia, 2025 ----
# righe: "Parma   24.976   5.121   76,2   92,0   +10,9"
# (iscritti tutte le età, 19-34 anni; ogni 1.000 abitanti tutte le età, 19-34 anni; differenza con il 2023).
# L'ultima colonna ("diff. con 2023 in valore assoluto", sotto "Numero iscritti ogni 1000 abitanti") è la
# differenza degli iscritti ogni 1.000 abitanti di 19-34 anni rispetto al 2023: verificato sulla tabella
# 2023 del Report giovani 2025 (Tab. 2, p. 21: Parma 81,1 → 92,0 = +10,9; Ferrara 81,5 → 93,7 = +12,2)
pag_t3 <- f_pag_tabella("Tabella 3. Iscritti", "^\\s*Parma\\s+[\\d.]+")
pag_t3; f_pag_stampata(testo_pdf[pag_t3])   # stampata attesa: 19
blocco_t3 <- f_blocco_tabella(pag_t3, "Tabella 3. Iscritti")
cat(blocco_t3)

rx_t3 <- "^\\s*(\\S.*?)\\s{2,}([\\d.]+)\\s+([\\d.]+)\\s+(\\d+,\\d)\\s+(\\d+,\\d)\\s+([+-]\\d+,\\d)\\s*$"
# righe catturate (attese 10: 9 province + Totale)
righe_t3 <- str_split(blocco_t3, "\n")[[1]] |> str_subset(rx_t3)
righe_t3

t3_larga <- str_match(righe_t3, rx_t3) |>
  as.data.frame() |>
  transmute(territorio = if_else(V2 == "Totale", "Emilia-Romagna", V2),
            n_totale = f_num_it(V3), n_19_34 = f_num_it(V4),
            per_1000_totale = f_num_it(V5), per_1000_19_34 = f_num_it(V6),
            diff_per_1000_su_2023_19_34 = f_num_it(V7))
stopifnot(nrow(t3_larga) == 10)
t3_larga |> filter(territorio %in% c("Parma", "Emilia-Romagna"))
# attese: Parma 24.976 / 5.121 / 76,2 / 92,0 / 10,9; Emilia-Romagna 292.399 / 64.126 / 65,5 / 87,1 / 10,7

t3 <- t3_larga |>
  pivot_longer(-territorio, names_to = c("misura", "classe_eta"),
               names_pattern = "^(n|per_1000|diff_per_1000_su_2023)_(totale|19_34)$", values_to = "valore") |>
  mutate(classe_eta = str_replace(classe_eta, "_", "-"),
         anno = ANNO, tabella = "3", indicatore = "iscritti_aire", fonte = f_fonte("3", pag_t3))

# 4. Unione e controlli ----------------------------------------------------
aire_pdf <- bind_rows(t2, t3) |>
  mutate(fonte = as.character(fonte)) |>
  select(tabella, territorio, classe_eta, indicatore, anno, misura, valore, fonte)

count(aire_pdf, tabella, misura)   # attese: Tab. 2 → n 18, pct 6+6, var 12; Tab. 3 → n 20, per_1000 20, diff 10

# __ a) Tab. 2: somma delle classi = Totale, per anno ----
controllo_t2 <- t2 |>
  filter(misura == "n") |>
  summarise(somma_classi = sum(valore[classe_eta != "totale"]), totale = valore[classe_eta == "totale"],
            .by = anno)
controllo_t2   # attese 3 righe con somma_classi == totale
stopifnot(all(controllo_t2$somma_classi == controllo_t2$totale))

# __ b) Tab. 2: var. % ricalcolate dagli iscritti vs stampate ----
controllo_var_aire <- t2_larga |>
  mutate(ric_2024 = round((n_2024 / n_2023 - 1) * 100, 1),
         ric_2025 = round((n_2025 / n_2024 - 1) * 100, 1))
controllo_var_aire |> select(classe_eta, var_2024, ric_2024, var_2025, ric_2025)   # scarti attesi entro 0,1

stopifnot(all(abs(controllo_var_aire$ric_2024 - controllo_var_aire$var_2024) <= 0.15),
          all(abs(controllo_var_aire$ric_2025 - controllo_var_aire$var_2025) <= 0.15))

# __ c) Tab. 3: somma delle province = riga Totale (Emilia-Romagna) ----
controllo_t3 <- t3_larga |>
  summarise(somma_tot = sum(n_totale[territorio != "Emilia-Romagna"]),
            somma_19_34 = sum(n_19_34[territorio != "Emilia-Romagna"]),
            er_tot = n_totale[territorio == "Emilia-Romagna"],
            er_19_34 = n_19_34[territorio == "Emilia-Romagna"])
controllo_t3   # attese uguali: 292.399 e 64.126
stopifnot(controllo_t3$somma_tot == controllo_t3$er_tot, controllo_t3$somma_19_34 == controllo_t3$er_19_34)

# __ d) Tab. 3 (totale regionale 2025) = Tab. 2 (2025) ----
controllo_t2_t3 <- c(
  tutte  = t3_larga$n_totale[t3_larga$territorio == "Emilia-Romagna"] - t2_larga$n_2025[t2_larga$classe_eta == "totale"],
  `19-34` = t3_larga$n_19_34[t3_larga$territorio == "Emilia-Romagna"] - t2_larga$n_2025[t2_larga$classe_eta == "19-34"]
)
controllo_t2_t3   # attesi 0 e 0
stopifnot(all(controllo_t2_t3 == 0))

# __ e) popolazione implicita (iscritti / iscritti ogni 1.000 × 1.000) ----
# deve somigliare ai residenti della provincia: Emilia-Romagna circa 4,46 milioni (tutte le età) e
# 736 mila (19-34); Bologna circa 1 milione, Rimini circa 340 mila
pop_implicita <- t3_larga |>
  transmute(territorio,
            pop_implicita_tot   = round(n_totale / per_1000_totale * 1000),
            pop_implicita_19_34 = round(n_19_34 / per_1000_19_34 * 1000))
pop_implicita
# ATTENZIONE (2026-10-29): per Parma esce circa 328 mila e per Piacenza circa 398 mila, cioè
# rovesciate (Parma ha circa 460 mila residenti, Piacenza circa 290 mila): nella Tab. 3 i valori
# ASSOLUTI di Parma e Piacenza sono scambiati tra le due righe, gli iscritti ogni 1.000 no.
# Riscontri: Report 2025, Tab. 2 p. 21 (dati 2023): Parma 32.159, Piacenza 23.396, quindi nel 2025
# Parma 34.722 e Piacenza 24.976 sono coerenti, il contrario no. Qui si lascia il valore STAMPATO;
# la correzione è in 01_dati.R (sezione AIRE, colonna revisione)

# 5. Salva ---------------------------------------------------------------
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)
saveRDS(aire_pdf, file.path(dir_out, "aire_pdf.rds"))
write_csv(aire_pdf, file.path(dir_out, "aire_pdf.csv"))
