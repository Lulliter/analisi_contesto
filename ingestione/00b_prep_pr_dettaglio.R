# ___________________________________________________________________________
# ingestione/00b_prep_pr_dettaglio.R
# Confini comunali NON generalizzati per gli zoom sulla provincia di Parma
# (il generalizzato va bene a scala ER, ma a scala provinciale si vede troppo)
#
# Input:  dati/grezzi/istat_shp/Com01012026/Com01012026_WGS84.shp (NON generalizzato)
#         dati/puliti/istat_shp/lista_PRO_COM_T_er_pr_vec.R  (44 codici comuni PR)
# Output: dati/puliti/istat_shp/PR_comuni_dettaglio_sf.rds   (44 comuni, dettaglio)
#         dati/puliti/istat_shp/PR_comuni_web_sf.rds        (stessi comuni, geometria
#         semplificata per i widget interattivi del sito: è quella che i moduli disegnano)
#
# Quando: dopo ogni nuovo download dei confini non generalizzati (annuale)
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(sf)
library(dplyr, warn.conflicts = FALSE)
library(rmapshaper)   # ms_simplify: conserva i confini condivisi tra comuni (niente fessure)

source(here("R", "istat.R"))   # funzioni di ingestione ISTAT (v. indice in testa al file)

# Parametri ---------------------------------------------------------------
ANNO_SHP <- "2026"
file_in  <- here("dati", "grezzi", "istat_shp",
                 paste0("Com0101", ANNO_SHP),
                 paste0("Com0101", ANNO_SHP, "_WGS84.shp"))
file_out <- here("dati", "puliti", "istat_shp", "PR_comuni_dettaglio_sf.rds")
file_web <- here("dati", "puliti", "istat_shp", "PR_comuni_web_sf.rds")
# quota di vertici da tenere nella versione web (0.05 = 5%): gli SVG interattivi del sito
# portano tutti i vertici (~1 MB a mappa col dettaglio); nel png a 300 dpi la differenza
# sta sotto il pixel. Se compaiono sbavature ai confini alzare a 0.1
KEEP_WEB <- 0.05

# 1) Carica Italia intera (non generalizzata) e filtra i comuni PR -----------
source(here("dati", "puliti", "istat_shp", "lista_PRO_COM_T_er_pr_vec.R"))
# -> CODICI_COMUNI_ER_PR (44 codici)

comuni_ita_dett <- read_shp_utf8(file_in)

pr_comuni_dettaglio_sf <- comuni_ita_dett |>
  filter(PRO_COM_T %in% CODICI_COMUNI_ER_PR)

# CONTROLLO: tutti e soli i 44 comuni della provincia di Parma
stopifnot(setequal(pr_comuni_dettaglio_sf$PRO_COM_T, CODICI_COMUNI_ER_PR))

# 2) Salva --------------------------------------------------------------------
saveRDS(pr_comuni_dettaglio_sf, file_out)
message("Salvato: ", file_out, " (", nrow(pr_comuni_dettaglio_sf),
        " comuni, dettaglio non generalizzato)")

# 3) Versione web: stessi comuni, pochi vertici (2026-10-09) ------------------
# keep_shapes evita che i poligoni piccoli collassino
pr_comuni_web_sf <- ms_simplify(pr_comuni_dettaglio_sf, keep = KEEP_WEB, keep_shapes = TRUE)
saveRDS(pr_comuni_web_sf, file_web)
message("Salvato: ", file_web, " (vertici: ", sum(lengths(st_geometry(pr_comuni_dettaglio_sf) |> lapply(unlist))), " -> ",
        sum(lengths(st_geometry(pr_comuni_web_sf) |> lapply(unlist))), ")")
