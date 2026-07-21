# Input:  nome — nome del csv (senza estensione) nell'output/ di un modulo
#         dir  — cartella output/ del modulo (R/ non conosce i moduli)
#         rds  — nome del grafico da cui leggere titolo e fonte (se diverso
#                dal csv, es. piu' grafici che condividono la stessa tabella)
# Output: i 2 bottoni CSV + Excel (via f_scarica_dati), con titolo e fonte
#         del grafico nel foglio "Metadati" dell'Excel
# NB: richiede f_scarica_dati gia' caricata (source di R/f_scarica_dati.R)
f_bottoni_dati <- function(nome, dir, rds = nome) {
  df <- read.csv(file.path(dir, paste0(nome, ".csv")), check.names = FALSE)
  p  <- readRDS(file.path(dir, paste0(rds, ".rds")))
  # titolo/fonte: nei ggplot stanno in labs() -> p$labels; nei patchwork
  # in plot_annotation() -> p$patches$annotation
  if (inherits(p, "patchwork")) {
    ann    <- p$patches$annotation
    titolo <- ann$title   %||% ""
    fonte  <- ann$caption %||% ""
  } else {
    titolo <- p$labels$title   %||% ""
    fonte  <- p$labels$caption %||% ""
  }
  f_scarica_dati(
    df,
    titolo = gsub("\n", " ", titolo),
    fonte  = gsub("\n", " ", fonte)
  )
}
