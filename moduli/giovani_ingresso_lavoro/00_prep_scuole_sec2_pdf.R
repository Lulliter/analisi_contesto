# ___________________________________________________________________________
# Modulo: giovani_ingresso_lavoro — 00_prep_scuole_sec2_pdf.R
# Scopo:  estrarre dal Report giovani 2026 della Regione Emilia-Romagna la Tab. 5
#         "Popolazione studentesca nelle scuole secondarie di 2° grado in Emilia-Romagna, a.s. 2024/2025"
#         (p. 23): per tipo di scuola (licei, di cui scientifici e classici, tecnici, professionali,
#         istituti IeFP, totale) alunni, % femmine e % stranieri nel tipo di scuola, % femmine,
#         % stranieri e % studenti sul totale regionale, variazione % degli alunni su 2023/24 e 2018/19
# Input:  dati/grezzi/rer_osservatorio_giovani/Report_giovani_2026.pdf
# Output: moduli/giovani_ingresso_lavoro/output/scuole_sec2_pdf.rds (+ .csv)
#           colonne: tabella, territorio, tipo_scuola, anno_scol, misura, valore, fonte
#           misura: "n_alunni" | "pct_femmine_nel_tipo" | "pct_stranieri_nel_tipo" |
#                   "pct_femmine_sul_totale" | "pct_stranieri_sul_totale" | "pct_studenti_sul_totale" |
#                   "var_pct_su_2023_24" | "var_pct_su_2018_19"
# Sezioni: 1 lettura pdf · 2 Tab. 5 · 3 formato lungo e controlli · 4 salva
# NB: stesso metodo di 00_prep_aire_pdf.R (titolo + riga di dati per trovare la pagina, blocco dal
#     titolo alla riga della fonte, pagina stampata nella colonna fonte).
#     Fonte della tabella: elaborazione regionale su dati MIM (Portale unico dei dati della scuola),
#     solo Emilia-Romagna. Gli stessi dati MIM per singola scuola sono già in casa con il dettaglio
#     della provincia di Parma (dati/grezzi/mim_open_data, ingestione/02_prep_mim_studenti.R): la Tab. 5
#     serve come riferimento regionale e riscontro.
#     Il pdf stampa "% stranieri/e" del Totale con due decimali (14,21%) e le colonne "sul totale"
#     del Totale senza decimali (100%): la regex accetta entrambi.
#     "Istituti IeFP" = 556 alunni (-90,2% su 2018/19): sono solo i percorsi IeFP dentro le scuole
#     censite dal MIM, non tutta la IeFP regionale (che passa soprattutto dagli enti di formazione,
#     v. modulo formaz_e_rientro). Da non leggere come crollo della IeFP.
#     Il pdf scrive "scientiﬁci" con la legatura ﬁ (un solo carattere): il testo si normalizza al § 1.
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

ANNO_SCOL <- "2024/25"
REPORT    <- "RER Report giovani 2026"

# tipi di scuola come stampati (dopo la normalizzazione della legatura), nell'ordine della tabella
TIPI_SCUOLA <- c("Licei", "di cui scientifici", "di cui classici", "Tecnici", "Professionali",
                 "Istituti IeFP", "Totale")
# righe che sommano al Totale (i "di cui" sono già dentro i licei)
TIPI_TOTALE <- c("Licei", "Tecnici", "Professionali", "Istituti IeFP")

# numeri italiani nel testo ("86.363" → 86363; "-0,3" → -0.3)
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

# testo di una tabella: dal titolo alla riga della fonte ("Fonte: elaborazione su dati ...")
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
# legatura "ﬁ" (U+FB01) → "fi", così "scientiﬁci" si legge come "scientifici"
testo_pdf <- pdf_text(file_pdf) |>
  str_replace_all("ﬁ", "fi")
length(testo_pdf)   # atteso 68

# 2. Tab. 5 alunni delle secondarie di 2° grado per tipo di scuola ----
# righe: "Licei   86.363   63,8%   7,6%   56,6%   23,5%   43,6%   -0,3%   6,4%"
# (alunni; % femmine e % stranieri nel tipo di scuola; % femmine, % stranieri e % studenti sul totale;
#  var. % alunni su 2023/24 e su 2018/19)
pag_t5 <- f_pag_tabella("Tabella 5. Popolazione studentesca", "^\\s*Licei\\s+[\\d.]+")
pag_t5; f_pag_stampata(testo_pdf[pag_t5])   # stampata attesa: 23
blocco_t5 <- f_blocco_tabella(pag_t5, "Tabella 5. Popolazione studentesca")
cat(blocco_t5)

# 7 colonne in %, con 0, 1 o 2 decimali e segno meno per le variazioni
rx_pct <- "(-?\\d+(?:,\\d+)?)%"
rx_t5 <- str_c("^\\s*(\\S.*?)\\s{2,}([\\d.]+)\\s+", str_c(rep(rx_pct, 7), collapse = "\\s+"), "\\s*$")
# righe catturate (attese 7: 6 tipi di scuola + Totale)
righe_t5 <- str_split(blocco_t5, "\n")[[1]] |> str_subset(rx_t5)
righe_t5

t5_larga <- str_match(righe_t5, rx_t5) |>
  as.data.frame() |>
  transmute(tipo_scuola              = V2,
            n_alunni                 = f_num_it(V3),
            pct_femmine_nel_tipo     = f_num_it(V4),
            pct_stranieri_nel_tipo   = f_num_it(V5),
            pct_femmine_sul_totale   = f_num_it(V6),
            pct_stranieri_sul_totale = f_num_it(V7),
            pct_studenti_sul_totale  = f_num_it(V8),
            var_pct_su_2023_24       = f_num_it(V9),
            var_pct_su_2018_19       = f_num_it(V10))
stopifnot(nrow(t5_larga) == 7, setequal(t5_larga$tipo_scuola, TIPI_SCUOLA))
t5_larga   # attese: Licei 86.363 / 63,8 ...; Totale 197.935 / 49,2 / 14,21 / 100 / 100 / 100 / 0,7 / 6,5

# 3. Formato lungo e controlli ---------------------------------------------
scuole_sec2_pdf <- t5_larga |>
  pivot_longer(-tipo_scuola, names_to = "misura", values_to = "valore") |>
  mutate(tabella = "5", territorio = "Emilia-Romagna", anno_scol = ANNO_SCOL,
         tipo_scuola = factor(tipo_scuola, levels = TIPI_SCUOLA),
         fonte = as.character(f_fonte("5", pag_t5))) |>
  select(tabella, territorio, tipo_scuola, anno_scol, misura, valore, fonte)

count(scuole_sec2_pdf, misura)   # attese 8 misure × 7 righe

# __ a) alunni: licei + tecnici + professionali + IeFP = Totale ----
controllo_alunni <- t5_larga |>
  summarise(somma_tipi = sum(n_alunni[tipo_scuola %in% TIPI_TOTALE]),
            totale = n_alunni[tipo_scuola == "Totale"])
controllo_alunni   # attesi uguali: 197.935
stopifnot(controllo_alunni$somma_tipi == controllo_alunni$totale)

# __ b) colonne "sul totale": i quattro tipi sommano a circa 100 ----
controllo_sul_totale <- t5_larga |>
  filter(tipo_scuola %in% TIPI_TOTALE) |>
  summarise(across(ends_with("_sul_totale"), sum))
controllo_sul_totale   # attese circa 100 (arrotondamenti)
stopifnot(all(abs(unlist(controllo_sul_totale) - 100) <= 0.3))

# __ c) % studenti sul totale ricalcolata dagli alunni vs stampata ----
controllo_pct_studenti <- t5_larga |>
  mutate(ric = round(100 * n_alunni / n_alunni[tipo_scuola == "Totale"], 1)) |>
  select(tipo_scuola, pct_studenti_sul_totale, ric)
controllo_pct_studenti   # scarti attesi entro 0,1
stopifnot(all(abs(controllo_pct_studenti$ric - controllo_pct_studenti$pct_studenti_sul_totale) <= 0.15))

# __ d) coerenza tra "nel tipo" e "sul totale" (femmine e stranieri) ----
# femmine del tipo = alunni × % femmine nel tipo; diviso femmine totali deve dare % femmine sul totale
controllo_coerenza <- t5_larga |>
  mutate(
    femmine   = n_alunni * pct_femmine_nel_tipo / 100,
    stranieri = n_alunni * pct_stranieri_nel_tipo / 100,
    ric_femmine_sul_totale   = round(100 * femmine / femmine[tipo_scuola == "Totale"], 1),
    ric_stranieri_sul_totale = round(100 * stranieri / stranieri[tipo_scuola == "Totale"], 1)
  ) |>
  select(tipo_scuola, pct_femmine_sul_totale, ric_femmine_sul_totale,
         pct_stranieri_sul_totale, ric_stranieri_sul_totale)
controllo_coerenza   # scarti attesi entro qualche decimo (le % nel tipo sono arrotondate)
stopifnot(all(abs(controllo_coerenza$ric_femmine_sul_totale - controllo_coerenza$pct_femmine_sul_totale) <= 0.5),
          all(abs(controllo_coerenza$ric_stranieri_sul_totale - controllo_coerenza$pct_stranieri_sul_totale) <= 0.5))

# 4. Salva ---------------------------------------------------------------
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)
saveRDS(scuole_sec2_pdf, file.path(dir_out, "scuole_sec2_pdf.rds"))
write_csv(scuole_sec2_pdf, file.path(dir_out, "scuole_sec2_pdf.csv"))
