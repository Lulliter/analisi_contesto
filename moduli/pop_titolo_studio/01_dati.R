# ___________________________________________________________________________
# Modulo: pop_titolo_studio
# Fonte:  ISTAT — Censimento permanente della popolazione, categoria "Istruzione, lavoro e spostamenti
#         per studio o lavoro": residenti di 9 anni e più per grado di istruzione ed età (TV_1) e per
#         grado di istruzione e cittadinanza (TV_2), 2018→
#         Download con ingestione/11_get_istat_cens_istr.R; fonte usata solo da questo modulo,
#         quindi la pulizia sta qui (se servirà ad altri moduli si promuove a ingestione/)
# Input:  dati/grezzi/istat_cens_diplomi_profess/sdmx_istr_eta.rds, sdmx_istr_citt.rds (solo codici)
#         dati/grezzi/istat_cens_diplomi_profess/sdmx_struttura_istr_eta.json (codelist: codice → dicitura)
# Output: moduli/pop_titolo_studio/output/<oggetto>.rds (nome file = oggetto):
#         titolo_studio_eta  (territorio × sesso × classe d'età × titolo × anno: residenti, totale, %)
#         titolo_studio_citt (territorio × sesso × cittadinanza × titolo × anno: residenti, totale, %;
#                             solo 9 anni e più)
#         territori: 44 comuni PR, 9 province ER, Emilia-Romagna, Italia
# NB 2026-10-27 (dettagli in dati/grezzi/istat_cens_diplomi_profess/_metadati.md):
#   - valori = stime ISTAT arrotondate; la tavola non ha un totale: totale = somma dei 6 titoli
#     (ML e RDD sono il dettaglio di ML_RDD, solo per 9 anni e più)
#   - zeri: nel 2018-19 ISTAT li pubblica con OBS_STATUS "JTEST" ("valore errato usato per test
#     caricamento"), dal 2020 omette le celle a zero. Entrambi → 0, segnalati in nota_valore:
#     categorie rare nei comuni piccoli. Ipotesi ragionata, non confermata da ISTAT
#   - Sorbolo Mezzani (034051, dal 2019): il 2018 è la somma di Mezzani (034021) e Sorbolo (034037),
#     che poi si tolgono (serie continua, niente doppi conteggi sommando i comuni)
#   - età solo in 5 classi (9-24, 25-49, 50-64, 65 e più, 9 e più): non c'è 25-34
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(purrr)
library(tidyr)
library(stringr)
library(jsonlite)
source(here("R", "istat.R"))   # f_codelist()

# Parametri ---------------------------------------------------------------
dir_in  <- here("dati", "grezzi", "istat_cens_diplomi_profess")
dir_mod <- here("moduli", "pop_titolo_studio", "output")
if (!dir.exists(dir_mod)) dir.create(dir_mod, recursive = TRUE)

# Etichette brevi dei titoli, dal più basso al più alto (scelta di presentazione: si cambiano qui)
TITOLI <- tribble(
  ~cod_titolo, ~titolo,
  "NED",    "Nessun titolo",
  "PSE",    "Licenza elementare",
  "LSE",    "Licenza media",
  "USE_IF", "Diploma o qualifica professionale",
  "BL",     "Laurea triennale o ITS",
  "ML_RDD", "Laurea magistrale o dottorato",
  "ML",     "(di cui) laurea magistrale",
  "RDD",    "(di cui) dottorato"
)
# i 6 titoli che sommano al totale
TITOLI_TOTALE <- c("NED", "PSE", "LSE", "USE_IF", "BL", "ML_RDD")

ETA <- tribble(
  ~cod_eta,  ~eta,
  "Y9-24",   "9-24",
  "Y25-49",  "25-49",
  "Y50-64",  "50-64",
  "Y_GE65",  "65 e più",
  "Y_GE9",   "9 e più"
)

# fusione del 2019: Mezzani + Sorbolo → Sorbolo Mezzani
COD_FUSIONE   <- "034051"
COD_SOPPRESSI <- c("034021", "034037")

# 1. Carica input ---------------------------------------------------------
istr_eta_grezzo  <- readRDS(file.path(dir_in, "sdmx_istr_eta.rds"))
istr_citt_grezzo <- readRDS(file.path(dir_in, "sdmx_istr_citt.rds"))

# codelist (codice → dicitura ISTAT) dal json della struttura: istr_eta e istr_citt hanno la stessa
etichette <- fromJSON(file.path(dir_in, "sdmx_struttura_istr_eta.json"), simplifyVector = FALSE)$data$codelists |>
  map(f_codelist) |>
  bind_rows()

# una tabella di etichette per dimensione, pronta per i join
etich_territori <- etichette |>
  filter(codelist == "CL_ITTER107") |>
  select(cod_territorio = codice, territorio = etichetta)

etich_sesso <- etichette |>
  filter(codelist == "CL_SEXISTAT1") |>
  transmute(cod_sesso = codice, sesso = str_to_sentence(etichetta))

etich_citt <- etichette |>
  filter(codelist == "CL_CITTADINANZA") |>
  select(cod_citt = codice, cittadinanza = etichetta)

etich_titolo <- etichette |>
  filter(codelist == "CL_TITOLO_STUDIO") |>
  select(cod_titolo = codice, titolo_istat = etichetta)

# 2.a) istr_eta: grado di istruzione ed età -----

# codici e numeri; gli zeri segnalati JTEST (2018-19) restano 0 e si annotano
titolo_eta_codici <- istr_eta_grezzo |>
  as_tibble() |>
  transmute(
    cod_territorio = REF_AREA,
    cod_sesso      = GENDER,
    cod_eta        = AGE_NOCLASS,
    cod_titolo     = EDU_ATTAIN,
    anno           = as.integer(TIME_PERIOD),
    valore         = as.numeric(OBS_VALUE),
    nota_valore    = if_else(OBS_STATUS %in% "JTEST", "zero segnalato JTEST da ISTAT", NA_character_)
  )

# celle assenti (dal 2020 ISTAT omette gli zeri): si ricreano a 0 sulle combinazioni che esistono
# (territori di quell'anno × sesso × combinazioni età-titolo presenti nella tavola)
titolo_eta_completo <- titolo_eta_codici |>
  complete(nesting(anno, cod_territorio), cod_sesso, nesting(cod_eta, cod_titolo),
           fill = list(valore = 0, nota_valore = "cella assente, posta a 0"), explicit = FALSE)

count(titolo_eta_completo, nota_valore)   # attese: 261 JTEST (2018-19), 523 celle assenti (2020-24)

# Sorbolo Mezzani: il 2018 è la somma di Mezzani e Sorbolo
sorbolo_mezzani_eta_2018 <- titolo_eta_completo |>
  filter(cod_territorio %in% COD_SOPPRESSI) |>
  summarise(valore = sum(valore), .by = c(anno, cod_sesso, cod_eta, cod_titolo)) |>
  mutate(cod_territorio = COD_FUSIONE, nota_valore = "somma di Mezzani e Sorbolo (prima della fusione)")

# i due comuni soppressi si tolgono, Sorbolo Mezzani 2018 si aggiunge
titolo_eta_fusione <- titolo_eta_completo |>
  filter(!cod_territorio %in% COD_SOPPRESSI) |>
  bind_rows(sorbolo_mezzani_eta_2018)

# etichette e livello territoriale ("Parma" è sia comune sia provincia: alle province "(provincia)")
titolo_eta_etichette <- titolo_eta_fusione |>
  left_join(etich_territori, by = "cod_territorio") |>
  left_join(etich_sesso, by = "cod_sesso") |>
  left_join(ETA, by = "cod_eta") |>
  left_join(TITOLI, by = "cod_titolo") |>
  left_join(etich_titolo, by = "cod_titolo") |>
  mutate(
    livello = case_when(
      str_detect(cod_territorio, "^\\d{6}$")  ~ "comune",
      str_detect(cod_territorio, "^ITD5\\d$") ~ "provincia",
      cod_territorio == "ITD5"                ~ "regione",
      cod_territorio == "IT"                  ~ "Italia"
    ),
    territorio = if_else(livello == "provincia", paste(territorio, "(provincia)"), territorio)
  )

# totale = somma dei 6 titoli; % sul totale
titolo_studio_eta <- titolo_eta_etichette |>
  mutate(totale = sum(valore[cod_titolo %in% TITOLI_TOTALE]),
         .by = c(anno, cod_territorio, cod_sesso, cod_eta)) |>
  mutate(
    pct    = 100 * valore / totale,
    titolo = factor(titolo, levels = TITOLI$titolo),
    eta    = factor(eta, levels = ETA$eta)
  ) |>
  select(livello, cod_territorio, territorio, sesso, eta, titolo, anno, valore, totale, pct,
         nota_valore, cod_sesso, cod_eta, cod_titolo, titolo_istat) |>
  arrange(livello, cod_territorio, sesso, eta, titolo, anno)

titolo_studio_eta

# 2.b) istr_citt: grado di istruzione e cittadinanza -----

# codici e numeri; gli zeri segnalati JTEST (2018-19) restano 0 e si annotano
titolo_citt_codici <- istr_citt_grezzo |>
  as_tibble() |>
  transmute(
    cod_territorio = REF_AREA,
    cod_sesso      = GENDER,
    cod_citt       = CITIZENSHIP,
    cod_titolo     = EDU_ATTAIN,
    anno           = as.integer(TIME_PERIOD),
    valore         = as.numeric(OBS_VALUE),
    nota_valore    = if_else(OBS_STATUS %in% "JTEST", "zero segnalato JTEST da ISTAT", NA_character_)
  )

# celle assenti: si ricreano a 0 sulle combinazioni che esistono
titolo_citt_completo <- titolo_citt_codici |>
  complete(nesting(anno, cod_territorio), cod_sesso, nesting(cod_citt, cod_titolo),
           fill = list(valore = 0, nota_valore = "cella assente, posta a 0"), explicit = FALSE)

count(titolo_citt_completo, nota_valore)   # nel json di controllo 42 zeri JTEST

# Sorbolo Mezzani: il 2018 è la somma di Mezzani e Sorbolo
sorbolo_mezzani_citt_2018 <- titolo_citt_completo |>
  filter(cod_territorio %in% COD_SOPPRESSI) |>
  summarise(valore = sum(valore), .by = c(anno, cod_sesso, cod_citt, cod_titolo)) |>
  mutate(cod_territorio = COD_FUSIONE, nota_valore = "somma di Mezzani e Sorbolo (prima della fusione)")

titolo_citt_fusione <- titolo_citt_completo |>
  filter(!cod_territorio %in% COD_SOPPRESSI) |>
  bind_rows(sorbolo_mezzani_citt_2018)

# etichette e livello territoriale
titolo_citt_etichette <- titolo_citt_fusione |>
  left_join(etich_territori, by = "cod_territorio") |>
  left_join(etich_sesso, by = "cod_sesso") |>
  left_join(etich_citt, by = "cod_citt") |>
  left_join(TITOLI, by = "cod_titolo") |>
  left_join(etich_titolo, by = "cod_titolo") |>
  mutate(
    livello = case_when(
      str_detect(cod_territorio, "^\\d{6}$")  ~ "comune",
      str_detect(cod_territorio, "^ITD5\\d$") ~ "provincia",
      cod_territorio == "ITD5"                ~ "regione",
      cod_territorio == "IT"                  ~ "Italia"
    ),
    territorio = if_else(livello == "provincia", paste(territorio, "(provincia)"), territorio)
  )

# totale = somma dei 6 titoli; % sul totale
titolo_studio_citt <- titolo_citt_etichette |>
  mutate(totale = sum(valore[cod_titolo %in% TITOLI_TOTALE]),
         .by = c(anno, cod_territorio, cod_sesso, cod_citt)) |>
  mutate(
    pct    = 100 * valore / totale,
    titolo = factor(titolo, levels = TITOLI$titolo)
  ) |>
  select(livello, cod_territorio, territorio, sesso, cittadinanza, titolo, anno, valore, totale, pct,
         nota_valore, cod_sesso, cod_citt, cod_titolo, titolo_istat) |>
  arrange(livello, cod_territorio, sesso, cittadinanza, titolo, anno)

titolo_studio_citt

# 3. Controlli ------------------------------------------------------------
# nessun codice rimasto senza etichetta, nessun valore NA
stopifnot(!anyNA(select(titolo_studio_eta, livello, territorio, sesso, eta, titolo, valore, pct)))
stopifnot(!anyNA(select(titolo_studio_citt, livello, territorio, sesso, cittadinanza, titolo, valore, pct)))

# territori: attesi 44 comuni + 9 province + regione + Italia = 55
count(titolo_studio_eta, livello, territorio) |> count(livello)

# riscontro col json scaricato a mano: comune di Parma, totale, 9 e più, 2024 → totale 184.900; nessun titolo 6.575
titolo_studio_eta |>
  filter(cod_territorio == "034027", cod_sesso == "T", cod_eta == "Y_GE9", anno == 2024) |>
  select(titolo, valore, totale, pct)

# le due tavole danno lo stesso totale per i 9 anni e più? (attese differenze 0 o piccole)
titolo_studio_eta |>
  filter(cod_eta == "Y_GE9", cod_titolo %in% TITOLI_TOTALE) |>
  select(cod_territorio, cod_sesso, anno, cod_titolo, valore_eta = valore) |>
  left_join(titolo_studio_citt |>
              filter(cod_citt == "TOTAL") |>
              select(cod_territorio, cod_sesso, anno, cod_titolo, valore_citt = valore),
            by = c("cod_territorio", "cod_sesso", "anno", "cod_titolo")) |>
  count(differenza = valore_eta - valore_citt)

# ML + RDD = ML_RDD (9 anni e più): attese differenze 0 o piccole (arrotondamenti)
titolo_studio_eta |>
  filter(cod_eta == "Y_GE9", cod_titolo %in% c("ML", "RDD", "ML_RDD")) |>
  select(cod_territorio, cod_sesso, anno, cod_titolo, valore) |>
  pivot_wider(names_from = cod_titolo, values_from = valore) |>
  count(differenza = ML + RDD - ML_RDD)

# somma dei comuni PR rispetto alla provincia di Parma (ITD52): attese differenze piccole (stime arrotondate)
titolo_studio_eta |>
  filter(cod_sesso == "T", cod_eta == "Y_GE9", cod_titolo %in% TITOLI_TOTALE,
         livello == "comune" | cod_territorio == "ITD52") |>
  mutate(gruppo = if_else(livello == "comune", "somma_comuni", "provincia")) |>
  summarise(valore = sum(valore), .by = c(gruppo, anno, titolo)) |>
  pivot_wider(names_from = gruppo, values_from = valore) |>
  mutate(diff_pct = 100 * (somma_comuni - provincia) / provincia) |>
  arrange(desc(abs(diff_pct)))

# Sorbolo Mezzani: serie continua dal 2018
titolo_studio_eta |>
  filter(cod_territorio == COD_FUSIONE, cod_sesso == "T", cod_eta == "Y_GE9", cod_titolo == "NED") |>
  select(anno, valore, nota_valore)

# 4. Salva nel proprio output/ ----------------------------------------------
saveRDS(titolo_studio_eta, file.path(dir_mod, "titolo_studio_eta.rds"))
saveRDS(titolo_studio_citt, file.path(dir_mod, "titolo_studio_citt.rds"))

