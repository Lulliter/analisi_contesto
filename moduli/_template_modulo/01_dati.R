# ------------------------------------------------------------------------
# Modulo: <nome_modulo>
# Fonte:  <es. ISTAT - Censimento permanente 2023>
# Input:  dati/grezzi/<fonte>/... oppure dati/puliti/...
# Output: moduli/<nome_modulo>/output/<oggetto>.rds
# ------------------------------------------------------------------------

library(dplyr)
library(here)

# Parametri ---------------------------------------------------------------
# ANNO <- 2024
# dir_out <- here("moduli", "<nome_modulo>", "output")

# 1. Carica input ---------------------------------------------------------
# df_grezzo <- readRDS(here("dati", "puliti", "..."))

# 2. Pulizia / trasformazioni ---------------------------------------------
# (rinominare il dataframe dopo trasformazioni non minimali)
# df_pronto <- df_grezzo |>
#   janitor::clean_names() |>
#   filter(...)

# 3. Salva nel proprio output/ --------------------------------------------
# saveRDS(df_pronto, here("moduli", "<nome_modulo>", "output", "df_pronto.rds"))
