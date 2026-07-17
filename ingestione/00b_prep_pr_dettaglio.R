# ==========================================================================
# ingestione/00b_prep_pr_dettaglio.R
# Confini comunali NON generalizzati per gli zoom sulla provincia di Parma
# (il generalizzato va bene a scala ER, ma a scala provinciale si vede troppo)
#
# Input:  dati/grezzi/istat_shp/Com01012026/Com01012026_WGS84.shp (NON generalizzato)
#         dati/puliti/istat_shp/lista_PRO_COM_T_er_pr_vec.R  (44 codici comuni PR)
# Output: dati/puliti/istat_shp/PR_comuni_dettaglio_sf.rds   (44 comuni, dettaglio)
#
# Quando: dopo ogni nuovo download dei confini non generalizzati (annuale)
# ==========================================================================

library(here)
library(sf)
library(dplyr, warn.conflicts = FALSE)

source(here("R", "istat_shp_get.R"))   # per read_shp_utf8()

# Parametri ---------------------------------------------------------------
ANNO_SHP <- "2026"
file_in  <- here("dati", "grezzi", "istat_shp",
                 paste0("Com0101", ANNO_SHP),
                 paste0("Com0101", ANNO_SHP, "_WGS84.shp"))
file_out <- here("dati", "puliti", "istat_shp", "PR_comuni_dettaglio_sf.rds")

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
