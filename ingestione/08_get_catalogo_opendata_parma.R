# Catalogo del portale Open Data del Comune di Parma (piattaforma DKAN)
# Input:  API del portale https://opendata.comune.parma.it (package_list, package_show)
# Output: dati/grezzi/comune_pr_open/catalogo_opendata_parma.rds e .xlsx
#         (lista / fogli "dataset", "risorse", "metadati")

# Setup ----
library(tidyverse)
library(jsonlite)
library(writexl)

# Parametri ----
url_portale <- "https://opendata.comune.parma.it"
url_api <- paste0(url_portale, "/api/3/action/")
dir_raw <- here::here("dati", "grezzi", "comune_pr_open")
file_raw_rds <- file.path(dir_raw, "catalogo_opendata_parma.rds")
file_raw_xlsx <- file.path(dir_raw, "catalogo_opendata_parma.xlsx")

# Funzioni ----

# chiama un'azione dell'API e restituisce il campo "result"
f_api <- function(azione) {
  risposta <- fromJSON(paste0(url_api, azione), simplifyVector = FALSE)
  risposta$result
}

# valore testuale singolo: NA se il campo manca o è vuoto
f_testo <- function(x) {
  if (length(x) == 0) NA_character_ else as.character(x[[1]])
}

# unisce con ";" un campo da una lista di oggetti (gruppi, tag, risorse)
f_unisci <- function(lista, campo) {
  valori <- map_chr(lista, function(x) f_testo(x[[campo]]))
  paste(unique(na.omit(valori)), collapse = "; ")
}

# date DKAN tipo "Tue, 06/09/2026 - 14:42" (mese/giorno/anno) → data
f_data <- function(x) {
  as_date(parse_date_time(x, orders = c("a m d Y H M", "Ymd HMS", "Ymd HM"), quiet = TRUE))
}

# Elenco dei dataset ----
nomi_dataset <- f_api("package_list") |> unlist()
length(nomi_dataset)

# Metadati di ogni dataset ----
# in DKAN package_show restituisce una lista con un solo dataset (in CKAN un oggetto)
pacchetti <- map(nomi_dataset, function(nome) {
  Sys.sleep(0.3)
  risultato <- f_api(paste0("package_show?id=", nome))
  if (is.null(names(risultato))) risultato[[1]] else risultato
}, .progress = TRUE)

# Tabella dei dataset ----
dataset <- map(pacchetti, function(p) {
  tibble(
    nome = f_testo(p$name),
    titolo = f_testo(p$title),
    organizzazione = f_testo(p$organization$title),
    # autore e gestore: dove compilati, indicano chi produce/cura il dato
    autore = f_testo(p$author),
    gestore = f_testo(p$maintainer),
    gruppi = f_unisci(p$groups, "title"),
    tag = f_unisci(p$tags, "name"),
    n_risorse = length(p$resources),
    formati = f_unisci(p$resources, "format"),
    licenza = f_testo(p$license_title),
    creato_testo = f_testo(p$metadata_created),
    modificato_testo = f_testo(p$metadata_modified),
    descrizione = f_testo(p$notes),
    url = paste0(url_portale, "/dataset/", f_testo(p$name))
  )
}) |>
  list_rbind()

# date convertite: controllare che non ci siano NA dove il testo c'è
dataset <- dataset |>
  mutate(
    creato = f_data(creato_testo),
    modificato = f_data(modificato_testo),
    .after = licenza
  )
dataset |> filter(is.na(modificato), !is.na(modificato_testo))

# Tabella delle risorse (1 riga = 1 file) -----
risorse <- map(pacchetti, function(p) {
  map(p$resources, function(r) {
    tibble(
      dataset = f_testo(p$name),
      risorsa = f_testo(r$name),
      formato = f_testo(r$format),
      url = f_testo(r$url)
    )
  }) |>
    list_rbind()
}) |>
  list_rbind()

# Metadati del file ----
metadati <- tibble(
  voce = c("Fonte", "Estratto il", "N. dataset", "N. risorse"),
  valore = c(url_portale, as.character(Sys.Date()), nrow(dataset), nrow(risorse))
)

# Salvataggio ----
catalogo_opendata_parma <- list(dataset = dataset, risorse = risorse, metadati = metadati)
dir.create(dir_raw, showWarnings = FALSE)
saveRDS(catalogo_opendata_parma, file_raw_rds)
write_xlsx(catalogo_opendata_parma, file_raw_xlsx)
