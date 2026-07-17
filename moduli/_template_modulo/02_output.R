# ------------------------------------------------------------------------
# Modulo: <nome_modulo>
# Scopo:  genera grafico / tabella finali
# Input:  output/<oggetto>.rds (da 01_dati.R) + eventuali dati/puliti/... e R/...
# Output: output/*.png | *.rds (ggplot object) | *.csv
# ------------------------------------------------------------------------

library(dplyr)
library(ggplot2)
library(here)

source(here("R", "_parma_colors.R"))
# source(here("R", "f_ggplot2.R"))

# Parametri ---------------------------------------------------------------
# dir_mod <- here("moduli", "<nome_modulo>")

# NB: eventuali funzioni locali si chiamano SEMPRE f_<verbo>_... (regola 6)

# 1. Carica dati pronti ----------------------------------------------------
# df_pronto <- readRDS(here("moduli", "<nome_modulo>", "output", "df_pronto.rds"))

# 2. Grafico ---------------------------------------------------------------
# plot_x <- df_pronto |>
#   ggplot(aes(...)) +
#   geom_...()

# 3. Salva (sia png per riuso rapido, sia rds se il sito deve ricomporlo) --
# ggsave(here("moduli", "<nome_modulo>", "output", "plot_x.png"),
#        plot_x, width = 8, height = 6, dpi = 300)
# saveRDS(plot_x, here("moduli", "<nome_modulo>", "output", "plot_x.rds"))
