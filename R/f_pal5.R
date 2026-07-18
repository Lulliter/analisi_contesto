# f_pal5 -------------------------------------------------------------------
# Estrae una palette a 5 colori (per classi a quintili) da una sequenziale
# a 8 di _parma_colors.R (seq_factor_*). Promossa da pop_mappe_tematiche
# il 2026-07-18 (2° utilizzatore: scuola_iscritti — regola 6).
f_pal5 <- function(seq8) seq8[c(2, 3, 5, 6, 8)]
