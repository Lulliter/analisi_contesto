# sito.R -------------------------------------------------------------------
# Funzioni usate SOLO dalle pagine .qmd del sito (bottoni di scarico dati).
# Nato il 2026-09-18 accorpando f_scarica_dati.R + f_bottoni_dati.R (originali
# in R/zzz_old/). Le pagine caricano: _parma_colors.R, grafici.R (f_girafe), sito.R
#
# Indice (outline RStudio):
#   f_scarica_dati()   due bottoni CSV + Excel da un data frame (nome <pagina>_<n>)
#   f_bottoni_dati()   idem, leggendo csv + titolo/fonte dal rds del grafico

# f_scarica_dati -------------------------------------------------------------
# Input:  df — data frame dei dati di un grafico
#         titolo, fonte — metadati del grafico: vanno nel foglio "Metadati"
#         dell'Excel; il CSV resta di SOLI dati (niente colonne ripetute)
# Output: due bottoni di download (CSV + Excel) da mettere sotto il grafico
# Nome file portabile e non sovrascrivibile: <pagina>_<progressivo>
# (es. trend_demogr_1.csv). Il contatore riparte a ogni pagina.
# CSV internazionale (virgola, punto decimale, UTF-8 con BOM): formato di
# riuso dati standard. Chi lavora in Excel usa il bottone Excel, che è
# l'unico sicuro contro l'autoformattazione di codici e classi d'età.
f_scarica_dati <- local({
  pagina_corr <- NULL
  n <- 0L
  # Licenza delle elaborazioni (grafici, tabelle, dati derivati); i dati di
  # origine restano soggetti alla licenza della fonte (vedi _metadati.md)
  licenza_txt <- "Elaborazione Osservatorio dei Dati Sociali, Fondazione Cariparma, CC BY 4.0. I dati di origine restano soggetti alla licenza della fonte citata."
  function(df, titolo = "", fonte = "") {
    pagina <- knitr::current_input()
    pagina <- if (is.null(pagina)) "tabella" else tools::file_path_sans_ext(basename(pagina))
    if (is.null(pagina_corr) || pagina != pagina_corr) {  # nuova pagina -> azzera
      pagina_corr <<- pagina
      n <<- 0L
    }
    n <<- n + 1L
    nome <- paste0(pagina, "_", n)

    csv_tmp <- file.path(tempdir(), paste0(nome, ".csv"))
    # la fonte arriva dalla caption del grafico e di solito inizia gia' con
    # "Fonte: " (vedi f_caption_fonte): tolgo il prefisso per non duplicarlo
    fonte_txt <- sub("^\\s*Fonte:\\s*", "", fonte)
    # titolo e fonte come righe di commento "#" in testa (convenzione dei
    # portali dati: in R si rileggono con read_csv(..., comment = "#"));
    # "\ufeff" e' il BOM UTF-8 e deve essere il primo carattere del file
    intestazione <- paste0("# Titolo: ", titolo, "\n# Fonte: ", fonte_txt,
                           "\n# Licenza: ", licenza_txt, "\n#\n")
    readr::write_file(paste0("\ufeff", intestazione, readr::format_csv(df)), csv_tmp)

    # Excel a 2 fogli (Dati + Metadati) scritto direttamente con writexl
    # (equivalente a download_this() con lista, ma esplicito e verificabile)
    metadati <- data.frame(
      campo  = c("Titolo", "Fonte", "Licenza"),
      valore = c(titolo, fonte_txt, licenza_txt)
    )
    xlsx_tmp <- file.path(tempdir(), paste0(nome, ".xlsx"))
    writexl::write_xlsx(list(Dati = df, Metadati = metadati), xlsx_tmp)

    htmltools::tagList(
      downloadthis::download_file(path = csv_tmp, output_name = nome,
        button_label = "CSV", button_type = "default", has_icon = TRUE,
        icon = "fa fa-file-csv"),
      downloadthis::download_file(path = xlsx_tmp, output_name = nome,
        button_label = "Excel", button_type = "default", has_icon = TRUE,
        icon = "fa fa-file-excel")
    )
  }
})

# f_bottoni_dati -------------------------------------------------------------
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
  # in plot_annotation() -> p$patches$annotation; nelle flextable nella riga
  # titolo (f_ft_titolo_note) e nella prima nota a pie' di tabella
  if (inherits(p, "flextable")) {
    titolo <- p$header$dataset[1, 1]
    fonte  <- if (nrow(p$footer$dataset) > 0) p$footer$dataset[1, 1] else ""
  } else if (inherits(p, "patchwork")) {
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
