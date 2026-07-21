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
    # titolo e fonte come righe di commento "#" in testa (convenzione dei
    # portali dati: in R si rileggono con read_csv(..., comment = "#"));
    # "\ufeff" e' il BOM UTF-8 e deve essere il primo carattere del file
    intestazione <- paste0("# Titolo: ", titolo, "\n# Fonte: ", fonte, "\n#\n")
    readr::write_file(paste0("\ufeff", intestazione, readr::format_csv(df)), csv_tmp)

    # Excel a 2 fogli (Dati + Metadati) scritto direttamente con writexl
    # (equivalente a download_this() con lista, ma esplicito e verificabile)
    metadati <- data.frame(
      campo  = c("Titolo", "Fonte"),
      valore = c(titolo, fonte)
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
