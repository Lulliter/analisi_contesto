# Input:  df — data frame dei dati di un grafico
# Output: due bottoni di download (CSV + Excel) da mettere sotto il grafico
# Nome file portabile e non sovrascrivibile: <pagina>_<progressivo>
# (es. trend_demogr_1.csv). Il contatore riparte a ogni pagina.
# CSV per Excel italiano: separatore ";", virgola decimale, UTF-8 con BOM
# (write_excel_csv2) -> si apre pulito con doppio clic e con accenti giusti.
f_scarica_dati <- local({
  pagina_corr <- NULL
  n <- 0L
  function(df) {
    pagina <- knitr::current_input()
    pagina <- if (is.null(pagina)) "tabella" else tools::file_path_sans_ext(basename(pagina))
    if (is.null(pagina_corr) || pagina != pagina_corr) {  # nuova pagina -> azzera
      pagina_corr <<- pagina
      n <<- 0L
    }
    n <<- n + 1L
    nome <- paste0(pagina, "_", n)

    csv_tmp <- file.path(tempdir(), paste0(nome, ".csv"))
    readr::write_excel_csv2(df, csv_tmp)  # ";" + virgola dec. + BOM: Excel IT ok

    htmltools::tagList(
      downloadthis::download_file(path = csv_tmp, output_name = nome,
        button_label = "CSV", button_type = "default", has_icon = TRUE,
        icon = "fa fa-file-csv"),
      downloadthis::download_this(df, output_name = nome, output_extension = ".xlsx",
        button_label = "Excel", button_type = "default", has_icon = TRUE,
        icon = "fa fa-file-excel")
    )
  }
})
