# ==========================================================================
# ingestione/00_prep_shp_situas.R
# Fondamenta geografiche: confini ISTAT + caratteristiche territorio SITUAS
#
# Input:  dati/grezzi/istat_shp/   (confini 01/01/2026, versione generalizzata)
#         API SITUAS report 73     (interrogata ALLA STESSA DATA dei confini)
# Output: dati/puliti/istat_shp/   ER_*.rds, ER_PR_*.rds + vettori codici
#         dati/puliti/comuni_ita_info_redux_sf.rds   (shp + SITUAS, colonne utili)
#         dati/puliti/comuni_ita_info_sf_VARDESC.rds (dizionario variabili)
#
# Quando rieseguire: una volta l'anno (nuovi confini) → basta cambiare ANNO_SHP
# Adattato da: analysis/00_carica_shp_situas.qmd (repo pre-ristrutturazione)
# ==========================================================================

library(here)
library(sf)
library(dplyr, warn.conflicts = FALSE)
library(tibble)

source(here("R", "istat_shp_get.R"))
source(here("R", "istat_situas_get.R"))
source(here("R", "istat_situas_sf_prep.R"))
source(here("R", "istat_situas_join_comuni_sf.R"))
source(here("R", "write_codici_vec.R"))
source(here("R", "utilities.R"))

# --- Parametri ------------------------------------------------------------
ANNO_SHP   <- "2026"                       # annata confini (al 1° gennaio)
DATA_SHP   <- paste0("01/01/", ANNO_SHP)   # stessa data per SITUAS (allineamento!)
dir_grezzi <- here("dati", "grezzi", "istat_shp")
dir_shp    <- here("dati", "puliti", "istat_shp")
dir_puliti <- here("dati", "puliti")

# 1) Confini ISTAT (generalizzati) ------------------------------------------
istat_shp <- istat_shp_get(dir_grezzi, anno = ANNO_SHP, generalizzata = TRUE)

comuni_ita       <- istat_shp$comuni_ita        # 7.896 comuni al 01/01/2026
province_cm_ita  <- istat_shp$province_cm_ita
regioni_ita      <- istat_shp$regioni_ita
ripartizioni_ita <- istat_shp$ripartizioni_ita

# Allinea i layer al CRS dei comuni (di norma già uguale)
crs_target       <- st_crs(comuni_ita)
province_cm_ita  <- st_transform(province_cm_ita, crs_target)
regioni_ita      <- st_transform(regioni_ita, crs_target)

# 2) Caratteristiche comuni da SITUAS (report 73, via API) -------------------
# NB: data = DATA_SHP, NON la data odierna: nel 2026 ci sono già state fusioni
#     (Lirio→Montalto Pavese, Castegnero Nanto) e SITUAS "a oggi" darebbe
#     7.894 comuni contro i 7.896 dello shapefile al 1° gennaio.
com_caratt <- f_scarica_situas_dati(id_report = 73, data = DATA_SHP)

# --- CONTROLLO allineamento shp ↔ SITUAS sui codici comune ---
orfani_shp    <- anti_join(st_drop_geometry(comuni_ita), com_caratt, by = "PRO_COM_T")
orfani_situas <- anti_join(com_caratt, st_drop_geometry(comuni_ita), by = "PRO_COM_T")
stopifnot(nrow(orfani_shp) == 0, nrow(orfani_situas) == 0)

# 3) Estrai e salva ER / PR --------------------------------------------------
er_res <- istat_situas_sf_prep(
  comuni_ita      = comuni_ita,
  province_cm_ita = province_cm_ita,
  regioni_ita     = regioni_ita,
  cod_reg         = "8",    # Emilia-Romagna (ISTAT)
  out_dir         = dir_shp,
  cod_prov        = "34",   # Parma (ISTAT)
  nome_reg        = "ER",
  nome_prov       = "PR"
)
# salva in dati/puliti/istat_shp/: ER_comuni_sf.rds, ER_provincie_sf.rds,
# ER_regioni_sf.rds, ER_PR_comuni_sf.rds, ER_PR_provincie_sf.rds

# 4) Vettori codici ER / PR ---------------------------------------------------
write_codici_vec(
  x        = er_res$ER_provincie_sf,
  col      = "COD_PROV",
  vec_name = "CODICI_PROV_ER",
  out_path = file.path(dir_shp, "lista_COD_PROV_er_vec.R")
)

write_codici_vec(
  x        = er_res$ER_comuni_sf,
  col      = "PRO_COM_T",
  vec_name = "CODICI_COMUNI_ER",
  out_path = file.path(dir_shp, "lista_PRO_COM_T_er_vec.R")
)

write_codici_vec(
  x        = er_res$ER_PR_comuni_sf,
  col      = "PRO_COM_T",
  vec_name = "CODICI_COMUNI_ER_PR",
  out_path = file.path(dir_shp, "lista_PRO_COM_T_er_pr_vec.R")
)

# 5) Join shp comuni + caratteristiche SITUAS (Italia intera) -----------------
# Salva la versione ridotta in dati/puliti/comuni_ita_info_redux_sf.rds
res_comuni_info <- istat_situas_join_comuni_sf(
  comuni_sf    = comuni_ita,
  situas_df    = com_caratt,
  out_dir      = dir_puliti,
  out_basename = "comuni_ita_info_redux_sf"
)

comuni_ita_info_sf       <- res_comuni_info$comuni_info_sf
comuni_ita_info_redux_sf <- res_comuni_info$comuni_info_redux_sf

# 6) Dizionario variabili (VARDESC) -------------------------------------------
# Fonte metadati: https://situas-servizi.istat.it/publish/anagrafica_report_metadato_web?pfun=73&pdata=01/01/1948
comuni_ita_info_sf_VARDESC <- tribble(
  ~COLNAME, ~LABEL, ~NOTE, ~GUIDA,
  # da situas
  "COD_RIP", "Codice Ripartizione geografica", "Note non presenti",
  "Codice Istat della ripartizione geografica secondo la suddivisione del territorio nazionale in: 1) Nord-ovest, 2) Nord-est, 3) Centro, 4) Sud e 5) Isole.",

  "COD_REG", "Codice Regione", "Valore di due caratteri alfanumerici, con validità nell'intervallo 01-20.",
  "Codice Istat della regione",
  "COD_UTS", "Codice Provincia/Uts", "Codice di tre caratteri alfanumerici con validità nell'intervallo 001-119 per le Province. Restano assegnati ai Liberi consorzi i codici delle omonime ex Province (081-089). Il codice delle Città metropolitane è ottenuto sommando '200' al codice della Provincia corrispondente. Ai soli fini statistici permangono i codici delle soppresse Province del Friuli-Venezia Giulia (L.r. 20/2016).",
  "Codice Istat della Provincia o Unità territoriale sovracomunale (Uts). Le unità territoriali sovracomunali comprendono, a fini statistici, Province, Città metropolitane, Liberi consorzi e unità non amministrative (ex Province del Friuli-Venezia Giulia).",
  "COD_PROV_STORICO", "Codice Provincia (Storico)", "Dal 1/1/2015 con l'entrata in vigore delle Città metropolitane i codici delle province corrispondenti permangono al solo scopo di costituire il codice del Comune, che non subisce variazioni. Permangono anche i codici delle soppresse Province del Friuli-Venezia Giulia (L.r. 20/2016).",
  "Codice Istat della Provincia vigente o cessata (tre caratteri alfanumerici, validi nell'intervallo 001-119).",
  "PRO_COM_T", "Codice Comune (alfanumerico)", "Note non presenti",
  "Codice Istat del Comune di sei caratteri in formato alfanumerico",
  "PRO_COM", "Codice comune (numerico)", "Note non presenti",
  "Codice Istat del Comune di sei caratteri in formato numerico",
  "COMUNE", "Comune", "Denominazione ufficiale dei comuni della Provincia di Bolzano/Bozen e di alcuni del Friuli-Venezia Giulia. Per le denominazioni bilingue si usa '/' per Bolzano/Bozen e '-' per gli altri.",
  "Denominazione del Comune in lingua italiana e straniera",
  "COMUNE_A", "Comune (dizione straniera)", "Note non presenti",
  "Denominazione del Comune in lingua diversa dall'italiano",
  "SIGLA_AUTOMOBILISTICA", "Sigla automobilistica", "Note non presenti",
  "Sigla automobilistica della provincia o, dal 2015, della città metropolitana, libero consorzio o unità non amministrativa (ex province del Friuli-Venezia Giulia). Null se non disponibile.",
  "COM_ISO", "Comune isolano", "Comuni appartenenti alle isole minori o lacuali. Sant'Antioco (SU) ha sezioni anche sull'Isola maggiore; Monte Isola (BS) è l'unico comune lacuale.",
  "1=Comune isolano; 0=Comune non isolano; null se non disponibile.",
  "COM_LIT", "Comune litoraneo", "Comune con almeno un tratto di confine bagnato dal mare. Sono esclusi i comuni lacuali.",
  "1=Comune litoraneo; 0=Comune non litoraneo; null se non disponibile.",
  "ZONA_ALT", "Zona altimetrica", "Ripartizione del territorio in zone omogenee basate su soglie altimetriche.",
  "1=Montagna interna; 2=Montagna litoranea; 3=Collina interna; 4=Collina litoranea; 5=Pianura; null se non disponibile.",
  "ZONE_COST_2011", "Zone costiere 2011", "Classificazione dei comuni secondo la vicinanza alla costa, basata su dati Istat ed Eurostat, armonizzata a livello UE (Reg. 2017/2391 e 2019/1130).",
  "1=Zone costiere (costa o ≥50% superficie entro 10 km dal mare); 0=Zone non costiere; null se non disponibile.",
  "ZONE_COST_2021", "Zone costiere 2021", "Classificazione aggiornata delle zone costiere (Eurostat e Istat).",
  "1=Zone costiere (costa o ≥50% superficie entro 10 km dal mare); 0=Zone non costiere; null se non disponibile.",
  "DEGURBA_2011", "Degurba 2011", "Classificazione armonizzata del grado di urbanizzazione (Eurostat), basata su Geostat grid 2011.",
  "1=Città o zone densamente popolate; 2=Piccole città/sobborghi; 3=Zone rurali; null se non disponibile.",
  "DEGURBA_2021", "Degurba 2021", "Classificazione armonizzata del grado di urbanizzazione (Eurostat), basata su Geostat grid 2021.",
  "1=Città o zone densamente popolate; 2=Piccole città/sobborghi; 3=Zone rurali; null se non disponibile.",
  "COD_ECO_DIV_2018", "Codice Ecoregioni-Divisioni", "Note non presenti",
  "Livello gerarchico che distingue 2 Divisioni: Temperata e Mediterranea; null se non disponibile.",
  "DEN_ECO_DIV_2018", "Ecoregioni - Divisioni", "Note non presenti",
  "Guida non presente",
  "COD_ECO_PRO_2018", "Codice Ecoregioni-Province", "Note non presenti",
  "Livello gerarchico articolato in 7 Province, rappresenta la regionalizzazione ecologica e geografica del territorio; null se non disponibile.",
  "DEN_ECO_PRO_2018", "Ecoregioni - Province", "Note non presenti",
  "Guida non presente",
  "COD_ECO_SEZ_2018", "Codice Ecoregioni-Sezioni", "Note non presenti",
  "Livello gerarchico di 11 Sezioni per rappresentare un quadro ecologico di riferimento più dettagliato; null se non disponibile.",
  "DEN_ECO_SEZ_2018", "Ecoregioni - Sezioni", "Note non presenti",
  "Guida non presente",
  "COD_ECO_SSEZ_2018", "Codice Ecoregioni-Sottosezioni", "Note non presenti",
  "Livello gerarchico con 33 Sottosezioni per descrivere con maggiore dettaglio il quadro ecologico del territorio; null se non disponibile.",
  "DEN_ECO_SSEZ_2018", "Ecoregioni - Sottosezioni", "Note non presenti",
  "Guida non presente",
  # da shapefile
  "COD_PROV", "Codice Provincia", "", "Codice Istat della Provincia o Città metropolitana di appartenenza del Comune.",
  "COD_CM", "Codice Città metropolitana", "", "Codice Istat della Città metropolitana di appartenenza del Comune. Null se non disponibile.",
  "CC_UTS", "Codice Unità territoriale sovracomunale", "", "Codice Istat dell'Unità territoriale sovracomunale (Uts) di appartenenza del Comune. Le unità territoriali sovracomunali comprendono, a fini statistici, Province, Città metropolitane, Liberi consorzi e unità non amministrative (ex Province del Friuli-Venezia Giulia).",
  "Shape_Leng", "Lunghezza forma", "", "Lunghezza del perimetro del comune in metri.",
  "Shape_Area", "Area forma", "", "Area del comune in metri quadrati. NB: shapefile GENERALIZZATO → non usare per calcoli di superficie di precisione.",
  "geometry", "Geometria", "", "Geometria del comune in formato 'sf' (Simple Features)."
)

# Ordine colonne come nel file finale + fonte di ciascuna variabile
col_order <- c(
  "COD_RIP", "COD_REG", "COD_PROV", "COD_CM",
  "COD_UTS", "PRO_COM", "PRO_COM_T", "COMUNE",
  "COMUNE_A", "CC_UTS", "COD_PROV_STORICO", "SIGLA_AUTOMOBILISTICA",
  "COM_ISO", "COM_LIT", "ZONA_ALT", "ZONE_COST_2011",
  "ZONE_COST_2021", "DEGURBA_2011", "DEGURBA_2021",
  "COD_ECO_DIV_2018", "DEN_ECO_DIV_2018",
  "COD_ECO_PRO_2018", "DEN_ECO_PRO_2018",
  "COD_ECO_SEZ_2018", "DEN_ECO_SEZ_2018",
  "COD_ECO_SSEZ_2018", "DEN_ECO_SSEZ_2018",
  "Shape_Leng", "Shape_Area", "geometry"
)

comuni_ita_info_sf_VARDESC <- comuni_ita_info_sf_VARDESC |>
  mutate(
    FONTE = if_else(
      COLNAME %in% c("COD_PROV", "COD_CM", "CC_UTS",
                     "Shape_Leng", "Shape_Area", "geometry"),
      paste0("ISTAT – Limiti amministrativi al ", DATA_SHP, " (shp generalizzato WGS84)"),
      "ISTAT SITUAS – Caratteristiche del territorio, Report 73"
    )
  ) |>
  arrange(match(COLNAME, col_order))

salva_vardesc_rds(
  comuni_ita_info_sf_VARDESC,
  out_path = file.path(dir_puliti, "comuni_ita_info_sf_VARDESC.rds")
)

# --- Fine: oggetti salvati in dati/puliti/ (vedi intestazione) --------------
