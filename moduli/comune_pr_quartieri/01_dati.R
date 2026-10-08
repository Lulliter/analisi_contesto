# ___________________________________________________________________________
# Modulo: comune_pr_quartieri
# Fonte:  Comune di Parma, open data — "Immobili ACER di Parma 2022", "Quartieri
#         del Comune di Parma vigenti", "Popolazione residente al 1 gennaio 2026"
#         (anagrafe); v. dati/grezzi/comune_pr_open/_metadati.md
# Input:  dati/grezzi/comune_pr_open/ACER_immobili.geojson
#         dati/grezzi/comune_pr_open/quartieri_vigenti.geojson
#         sfondo: grafo_stradale_2025/, torrenti, ferrovie, parchi_intitolati
#         dati/grezzi/comune_pr_open/Popolazione_residente_2026.csv
#         (scaricati da ingestione/09_get_comune_pr_cartografia.R)
# Output: output/acer_immobili_sf.rds (1 riga = 1 immobile, con quartiere)
#         output/quartieri_sf.rds (13 quartieri vigenti)
#         output/acer_immobili.rds + .csv (elenco senza geometria, con lon/lat)
#         output/acer_quartieri.rds + .csv (immobili per quartiere)
#         output/strade_sf.rds, torrenti_sf.rds, ferrovie_sf.rds, parchi_sf.rds
#         (sfondo delle mappe per quartiere)
#         output/pop_quartieri.rds + .csv (indicatori per quartiere + comune)
#         output/pop_quartieri_eta.rds + .csv (classi di età per quartiere + comune)
# NB: 1 riga = 1 IMMOBILE (indirizzo + civico), NON 1 alloggio: la fonte non
#     dice quanti alloggi ha ogni edificio → tutti i conteggi sono di edifici
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(sf)
library(readr)
library(janitor)
library(stringr)

# Parametri ---------------------------------------------------------------
dir_in <- here("dati", "grezzi", "comune_pr_open")
file_acer <- file.path(dir_in, "ACER_immobili.geojson")
file_quartieri <- file.path(dir_in, "quartieri_vigenti.geojson")
file_strade <- file.path(dir_in, "grafo_stradale_2025", "Grafo_stradale_PARMA_2025_RDN2008.shp")
file_torrenti <- file.path(dir_in, "torrenti.geojson")
file_ferrovie <- file.path(dir_in, "ferrovie.geojson")
file_parchi <- file.path(dir_in, "parchi_intitolati.geojson")
file_pop <- file.path(dir_in, "Popolazione_residente_2026.csv")

# classi di età (anni compiuti): le prime 5 sono le classi scolari della Regione
BREAKS_ETA <- c(0, 3, 6, 11, 14, 19, 30, 65, 80, Inf)
LABELS_ETA <- c("0-2", "3-5", "6-10", "11-13", "14-18", "19-29", "30-64", "65-79", "80+")

# codici di CLASSIFICA delle strade minori (ipotesi: NN = locali; i codici
# non sono documentati: AA coincide con le autostrade, TT quasi con le tangenziali)
CLASSI_STRADE_LOCALI <- c("NN", "")
dir_mod <- here("moduli", "comune_pr_quartieri", "output")

# sistema di riferimento metrico per join e misure: RDN2008 / UTM 32N
# (quello degli shapefile del Comune); i geojson arrivano in WGS84 (4326)
CRS_METRICO <- 7791

dir.create(dir_mod, showWarnings = FALSE)

# Funzioni locali ----------------------------------------------------------

# nomi dei quartieri per esteso (la fonte abbrevia due nomi, in ACER e in anagrafe)
f_nome_quartiere <- function(x) {
  case_when(x == "S.Leonardo" ~ "San Leonardo",
            x == "C.S. Martino" ~ "Cortile San Martino",
            .default = x)
}

# indicatori di composizione della popolazione (su dati raggruppati o no)
f_indicatori_pop <- function(df) {
  df |>
    summarise(
      residenti = n(),
      stranieri = sum(straniero),
      bambini_0_14 = sum(eta < 15),
      minori = sum(eta < 18),
      giovani_18_29 = sum(eta >= 18 & eta < 30),
      minori_stranieri = sum(eta < 18 & straniero),
      anziani_65 = sum(eta >= 65),
      anziani_80 = sum(eta >= 80),
      # anziani in famiglia anagrafica di 1 persona (convivenze escluse)
      anziani_soli = sum(eta >= 65 & !in_convivenza & n_comp == 1),
      anziani_in_famiglia = sum(eta >= 65 & !in_convivenza),
      famiglie = sum(intestatario),
      famiglie_1 = sum(intestatario & n_comp == 1),
      famiglie_numerose = sum(intestatario & n_comp >= 5),
      in_convivenza = sum(in_convivenza),
      .groups = "drop"
    ) |>
    mutate(
      pct_bambini_0_14 = round(bambini_0_14 / residenti * 100, 1),
      pct_minori_0_17 = round(minori / residenti * 100, 1),
      pct_giovani_18_29 = round(giovani_18_29 / residenti * 100, 1),
      pct_stranieri = round(stranieri / residenti * 100, 1),
      pct_stranieri_minori = round(minori_stranieri / minori * 100, 1),
      pct_anziani_65 = round(anziani_65 / residenti * 100, 1),
      pct_anziani_80 = round(anziani_80 / residenti * 100, 1),
      pct_anziani_soli = round(anziani_soli / anziani_in_famiglia * 100, 1),
      pct_famiglie_1 = round(famiglie_1 / famiglie * 100, 1),
      pct_famiglie_numerose = round(famiglie_numerose / famiglie * 100, 1),
      # dimensione media delle famiglie anagrafiche (residenti in famiglia / famiglie)
      comp_per_famiglia = round((residenti - in_convivenza) / famiglie, 2),
      convivenza_per_1000 = round(in_convivenza / residenti * 1000, 1)
    )
}

# 1. Carica input ---------------------------------------------------------
if (!file.exists(file_acer) || !file.exists(file_quartieri)) {
  stop("Mancano i geojson del Comune in dati/grezzi/comune_pr_open/: ",
       "scaricarli seguendo il _metadati.md della cartella e rilanciare")
}

acer_grezzo <- st_read(file_acer, quiet = TRUE)
quartieri_grezzo <- st_read(file_quartieri, quiet = TRUE)

# controlli: colonne e righe (attesi ~641 immobili PUNTI e 13 quartieri POLIGONI)
# NB: se le select qui sotto falliscono, i nomi nel geojson sono diversi dal csv
#     della stessa fonte (Comune;IDE;Indirizzo;NumCivico;Indir_est;Anno_costr;...)
names(acer_grezzo)
nrow(acer_grezzo)
table(st_geometry_type(acer_grezzo))
names(quartieri_grezzo)
nrow(quartieri_grezzo)

# 2. Quartieri ------------------------------------------------------------
quartieri_sf <- quartieri_grezzo |>
  clean_names() |>
  # NB: nel geojson i campi sono QUARTIERI/ID_QUART/CIRCO (nel csv: QUARTIERE/Circoscrizione)
  select(id_quart, circoscrizione = circo, quartiere = quartieri) |>
  st_transform(CRS_METRICO) |>
  # due nomi abbreviati nella fonte → per esteso come nella scheda del dataset
  mutate(quartiere = f_nome_quartiere(quartiere))

quartieri_sf$quartiere

# 3. Immobili ACER con il loro quartiere ----------------------------------
acer_immobili_sf <- acer_grezzo |>
  clean_names() |>
  select(ide, indirizzo = indir_est, anno_costr) |>
  mutate(anno_costr = as.integer(anno_costr)) |>
  st_transform(CRS_METRICO) |>
  # quartiere di appartenenza: il punto sta dentro il poligono
  st_join(quartieri_sf |> select(quartiere), join = st_within)

# controlli: geometrie vuote, punti fuori dai quartieri, indirizzi doppi,
# anni di costruzione mancanti o strani (es. 0)
sum(st_is_empty(acer_immobili_sf))
acer_immobili_sf |> filter(is.na(quartiere))
# NB 2026-10-07: 21 indirizzi doppi con dati identici (11 a Montanara); si
# tengono come nella fonte (possibili più unità allo stesso civico)
acer_immobili_sf |> st_drop_geometry() |> count(indirizzo) |> filter(n > 1)
summary(acer_immobili_sf$anno_costr)

# elenco senza geometria (per i bottoni di scarico), con coordinate WGS84
coord_wgs84 <- acer_immobili_sf |> st_transform(4326) |> st_coordinates()

acer_immobili <- acer_immobili_sf |>
  st_drop_geometry() |>
  mutate(lon = round(coord_wgs84[, "X"], 6),
         lat = round(coord_wgs84[, "Y"], 6))

# 4. Immobili per quartiere -----------------------------------------------
acer_quartieri <- acer_immobili |>
  count(quartiere, name = "n_immobili") |>
  # i quartieri senza immobili ACER devono comparire con 0
  right_join(quartieri_sf |> st_drop_geometry() |> select(quartiere),
             by = "quartiere") |>
  mutate(n_immobili = coalesce(n_immobili, 0L),
         pct_immobili = round(n_immobili / sum(n_immobili) * 100, 1)) |>
  arrange(desc(n_immobili))

acer_quartieri

# 5. Popolazione residente per quartiere ----------------------------------
# 1 riga = 1 residente (anagrafe al 1/1/2026)
pop_grezzo <- read_delim(file_pop, delim = ";", show_col_types = FALSE)

# controlli: righe (attese 202.742), età (parte da 1), residenti in convivenza
nrow(pop_grezzo)
range(pop_grezzo$ETA)
count(pop_grezzo, Tipores)

pop_residenti <- pop_grezzo |>
  clean_names() |>
  transmute(
    quartiere = f_nome_quartiere(quartiere),
    # ETA = 2026 − anno di nascita → anni compiuti al 1/1 = ETA − 1
    # (verificato sulle classi di età della Regione, v. _metadati.md)
    eta = eta - 1L,
    classe_eta = cut(eta, breaks = BREAKS_ETA, labels = LABELS_ETA, right = FALSE),
    straniero = cittad != 100,
    in_convivenza = tipores == 2,
    # intestatario di famiglia (non di convivenza): 1 = 1 famiglia
    intestatario = relpar == 1 & tipores == 1,
    n_comp = ncomp
  )

# controllo: tutti i quartieri dell'anagrafe sono nei poligoni?
setdiff(unique(pop_residenti$quartiere), quartieri_sf$quartiere)

# indicatori per quartiere + riga del comune (per confronto)
pop_quartieri <- bind_rows(
  pop_residenti |> group_by(quartiere) |> f_indicatori_pop(),
  pop_residenti |> f_indicatori_pop() |> mutate(quartiere = "Comune di Parma")
) |>
  # immobili ACER ogni 1.000 residenti
  left_join(acer_quartieri |> select(quartiere, n_immobili), by = "quartiere") |>
  mutate(n_immobili = if_else(quartiere == "Comune di Parma",
                              sum(acer_quartieri$n_immobili), n_immobili),
         acer_per_1000 = round(n_immobili / residenti * 1000, 2))

pop_quartieri

# classi di età per quartiere (formato lungo, per mappe/grafici in serie)
pop_quartieri_eta <- bind_rows(
  pop_residenti |> count(quartiere, classe_eta),
  pop_residenti |> count(classe_eta) |> mutate(quartiere = "Comune di Parma")
) |>
  group_by(quartiere) |>
  mutate(pct = round(n / sum(n) * 100, 1)) |>
  ungroup()

# 6. Sfondo per le mappe dei quartieri ------------------------------------
# strade: tratti uniti per via (1 riga = 1 via, o 2 se ha tratti principali e
# locali), per avere il nome della via nel tooltip e meno elementi nel sito
strade_sf <- st_read(file_strade, quiet = TRUE) |>
  clean_names() |>
  mutate(principale = !(coalesce(classifica, "") %in% CLASSI_STRADE_LOCALI)) |>
  st_transform(CRS_METRICO) |>
  group_by(descvia, principale) |>
  summarise(.groups = "drop")

# controllo: quante vie principali e locali
count(st_drop_geometry(strade_sf), principale)

# torrenti e ferrovie: un solo oggetto ciascuno (servono solo da disegno)
torrenti_sf <- st_read(file_torrenti, quiet = TRUE) |>
  st_transform(CRS_METRICO) |>
  summarise()

ferrovie_sf <- st_read(file_ferrovie, quiet = TRUE) |>
  st_transform(CRS_METRICO) |>
  summarise()

# parchi: col nome (per il tooltip)
parchi_sf <- st_read(file_parchi, quiet = TRUE) |>
  clean_names() |>
  transmute(parco = str_to_title(parcounico)) |>
  st_transform(CRS_METRICO)

# 7. Salva nel proprio output/ --------------------------------------------
saveRDS(acer_immobili_sf, file.path(dir_mod, "acer_immobili_sf.rds"))
saveRDS(quartieri_sf, file.path(dir_mod, "quartieri_sf.rds"))
saveRDS(acer_immobili, file.path(dir_mod, "acer_immobili.rds"))
write_csv(acer_immobili, file.path(dir_mod, "acer_immobili.csv"))
saveRDS(acer_quartieri, file.path(dir_mod, "acer_quartieri.rds"))
write_csv(acer_quartieri, file.path(dir_mod, "acer_quartieri.csv"))
saveRDS(strade_sf, file.path(dir_mod, "strade_sf.rds"))
saveRDS(torrenti_sf, file.path(dir_mod, "torrenti_sf.rds"))
saveRDS(ferrovie_sf, file.path(dir_mod, "ferrovie_sf.rds"))
saveRDS(parchi_sf, file.path(dir_mod, "parchi_sf.rds"))
saveRDS(pop_quartieri, file.path(dir_mod, "pop_quartieri.rds"))
write_csv(pop_quartieri, file.path(dir_mod, "pop_quartieri.csv"))
saveRDS(pop_quartieri_eta, file.path(dir_mod, "pop_quartieri_eta.rds"))
write_csv(pop_quartieri_eta, file.path(dir_mod, "pop_quartieri_eta.csv"))

