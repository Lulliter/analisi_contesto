# Input:  x — UNA codelist di una risposta SDMX-JSON di IstatData (un elemento di
#         `struttura$codelists`, dove struttura = fromJSON(file, simplifyVector = FALSE)$data
#         e il file è la "Query struttura" salvata, es. da ingestione/06a_get_istat_avq_ict.R)
# Output: tibble con 1 riga per codice: codelist (es. "CL_SEXISTAT1"), codice, etichetta (in italiano)
# Uso:    etichette <- struttura$codelists |> purrr::map(f_codelist) |> dplyr::bind_rows()
# È l'unico punto che "sa" com'è fatto il json ISTAT: x$id, x$codes[[i]]$id, x$codes[[i]]$names$it
f_codelist <- function(x) {
  tibble::tibble(
    codelist  = x$id,
    codice    = purrr::map_chr(x$codes, "id"),
    etichetta = purrr::map_chr(x$codes, list("names", "it"), .default = NA_character_)
  )
}
