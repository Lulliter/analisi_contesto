# f_salva_mappa ------------------------------------------------------------
# Salva una mappa (o un ggplot) in png (riuso rapido) + rds (per il sito),
# nome file = nome oggetto passato. Promossa da moduli/pop_mappe_tematiche
# il 2026-07-18 (2° utilizzatore: scuola_iscritti — regola 6).
f_salva_mappa <- function(mappa, nome_file, dir_out, width = 8, height = 6) {
  ggplot2::ggsave(file.path(dir_out, paste0(nome_file, ".png")),
                  mappa, width = width, height = height, dpi = 300, bg = "white")
  saveRDS(mappa, file.path(dir_out, paste0(nome_file, ".rds")))
  message("Salvata: ", nome_file)
}
