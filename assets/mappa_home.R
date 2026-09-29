# ___________________________________________________________________________
# Mappa "muta" per la home del sito: province ER in grigio, provincia di Parma
# evidenziata. Elemento di identità (come il logo), non un output di analisi.
# Input:  dati/puliti/istat_shp/ER_comuni_sf.rds
#         dati/puliti/istat_shp/ER_provincie_sf.rds
# Output: assets/mappa_home.png
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr, warn.conflicts = FALSE)
library(sf)
library(ggplot2)
library(ragg)
source(here("R", "_parma_colors.R"))

# Parametri ---------------------------------------------------------------
COD_PR      <- "34"
col_parma   <- burg_md         # alternative: blu_md, "#517699" (navbar)
col_er      <- grey_md2
col_bordo   <- "white"
file_out    <- here("assets", "mappa_home.png")

# Dati --------------------------------------------------------------------
er_comuni_sf    <- readRDS(here("dati", "puliti", "istat_shp", "ER_comuni_sf.rds"))
er_provincie_sf <- readRDS(here("dati", "puliti", "istat_shp", "ER_provincie_sf.rds"))

# Parma = unione dei comuni della provincia (coerente con la geometria dei comuni)
parma_sf <- er_comuni_sf |>
  filter(COD_PROV %in% c(COD_PR, as.numeric(COD_PR))) |>
  st_union() |>
  st_sf()

# Mappa -------------------------------------------------------------------
plot_mappa_home <- ggplot() +
  geom_sf(data = er_provincie_sf, fill = col_er, colour = col_bordo, linewidth = 0.6) +
  geom_sf(data = parma_sf, fill = col_parma, colour = col_bordo, linewidth = 0.6) +
  theme_void() +
  theme(plot.background = element_rect(fill = "transparent", colour = NA))

plot_mappa_home

# Salva -------------------------------------------------------------------
ggsave(file_out, plot_mappa_home, device = agg_png,
       width = 6, height = 4, units = "in", dpi = 200, bg = "transparent")
