# ------------------------------------------------------------------------
# Modulo: demo_trend_indicatori — funzioni locali di import xlsx ISTAT
# Origine: ZZZ_old/R/istat_xlsx_import.R (riesumato 2026-07-18);
#          funzioni rinominate con prefisso f_ (convenzione repo).
# NB: locali al modulo (unico utilizzatore); si promuovono a R/ alla
#     seconda chiamata da uno script diverso (regola 6).
# ------------------------------------------------------------------------

# Packages ----
library(readxl)
library(tidyverse)

# 1/3) Importa fogli ISTAT (con 2 righe header) --------
#' Importa fogli ISTAT con struttura semplice (2 righe header)
#'
#' Gestisce fogli come: quoziente_di_natalità, quoziente_di_mortalità, ecc.
#' che hanno 2 righe di intestazione (riga 1 = titolo, riga 2 = anni)
#'
#' @param file_path Percorso al file Excel
#' @param sheet_name Nome del foglio da importare
#'
#' @return Tibble in formato tidy con colonne: territorio, tipo, anno, indicatore, valore
#'
#' @examples
#' dati_natalita <- f_import_istat_simple_sheet(
#'   file_path = here::here("data", "data_in", "indic_demogr_prov_trend.xlsx"),
#'   sheet_name = "quoziente_di_natalità"
#' )
#'
f_import_istat_simple_sheet <- function(file_path, sheet_name) {
  
  # Leggo il file senza header ----
  raw_data <- readxl::read_excel(
    path = file_path,
    sheet = sheet_name,
    col_names = FALSE
  )
  
  # Creo i nomi delle colonne dalla riga 2 (anni) ----
  col_names <- c(
    "territorio",
    as.character(unlist(raw_data[2, -1]))
  )
  
  # Assegno i nomi alle colonne
  names(raw_data) <- col_names
  
  # Rimuovo le intestazioni ----
  clean_data <- raw_data[-c(1:2), ]
  
  # Rimuovo righe vuote e note ----
  clean_data <- clean_data |>
    dplyr::filter(
      !is.na(territorio),
      # note a piè di foglio: "* Stima", "*Stima", "*Dato provvisorio", ecc.
      !stringr::str_starts(territorio, "\\*")
    )

  # Converto colonne numeriche ----
  clean_data <- clean_data |>
    dplyr::mutate(
      dplyr::across(
        .cols = -territorio,
        .fns = as.numeric
      )
    )
  
  # Definisco territori da classificare ----
  regioni <- c(
    "Piemonte", "Valle d'Aosta", "Lombardia", "Trentino-Alto Adige",
    "Veneto", "Friuli-Venezia Giulia", "Liguria", "Emilia-Romagna",
    "Toscana", "Umbria", "Marche", "Lazio", "Abruzzo", "Molise",
    "Campania", "Puglia", "Basilicata", "Calabria", "Sicilia", "Sardegna"
  )
  
  ripartizioni <- c(
    "RIPARTIZIONI", "NORD", "NORD-OVEST", "NORD-EST", 
    "CENTRO", "MEZZOGIORNO", "SUD", "ISOLE", "ITALIA"
  )
  
  # Aggiungo classificazione tipo territorio ----
  clean_data <- clean_data |>
    dplyr::mutate(
      tipo = dplyr::case_when(
        territorio %in% regioni ~ "regione",
        territorio %in% ripartizioni ~ "ripartizione",
        TRUE ~ "provincia"
      )
    )
  
  # Converto in formato long (tidy) ----
  tidy_data <- clean_data |>
    tidyr::pivot_longer(
      cols = -c(territorio, tipo),
      names_to = "anno",
      values_to = "valore"
    )
  
  # Pulisco anno e aggiungo indicatore ----
  tidy_data <- tidy_data |>
    dplyr::mutate(
      anno = stringr::str_remove_all(anno, "[\\*']+"),  # Rimuovo asterischi (singoli/multipli) e apostrofi
      anno = as.integer(anno),
      indicatore = sheet_name
    )
  
  # Rimuovo NA nei valori ----
  tidy_data <- tidy_data |>
    dplyr::filter(!is.na(valore))
  
  return(tidy_data)
}


# 1/3) ESEMPIO DI UTILIZZO ----

# dati_natalita <- f_import_istat_simple_sheet(
#   file_path = here::here("data", "data_in", "indic_demogr_prov_trend.xlsx"),
#   sheet_name = "quoziente_di_natalità"
# )
# 
# dati_mortalita <- f_import_istat_simple_sheet(
#   file_path = here::here("data", "data_in", "indic_demogr_prov_trend.xlsx"),
#   sheet_name = "quoziente_di_mortalità"
# )


# 🟧🟩🟦 -----

# 2/3) Importa foglio ISTAT (con 3 righe di header) --------
#' Importa foglio ISTAT "indicatori_di_struttura"
#'
#' Gestisce il foglio speciale "indicatori_di_struttura" che ha 3 righe di header
#' con anni ripetuti ogni 4 colonne e 4 indicatori per anno
#'
#' @param file_path Percorso al file Excel
#' @param sheet_name Nome del foglio (default = "indicatori_di_struttura")
#'
#' @return Tibble in formato tidy con colonne: territorio, tipo, anno, indicatore, valore
#'
#' @examples
#' dati_struttura <- f_import_istat_complex_sheet(
#'   file_path = here::here("data", "data_in", "indic_demogr_prov_trend.xlsx")
#' )
#'
f_import_istat_complex_sheet <- function(file_path, sheet_name = "indicatori_di_struttura") {
  
  # Leggo il file senza header ----
  raw_data <- readxl::read_excel(
    path = file_path,
    sheet = sheet_name,
    col_names = FALSE
  )
  
  # Estraggo le righe di intestazione ----
  years_row <- raw_data[2, ]       # Riga 2: anni (ripetuti ogni 4 colonne)
  indicators_row <- raw_data[3, ]  # Riga 3: nomi indicatori
  
  # Riempio gli anni mancanti (forward fill) ----
  years_filled <- as.list(years_row) |>
    purrr::accumulate(function(prev, curr) {
      if (is.na(curr)) prev else curr
    })
  
  # Creo i nomi delle colonne combinando anno_indicatore ----
  col_names <- c(
    "territorio",
    purrr::map2_chr(
      years_filled[-1],
      as.list(indicators_row)[-1],
      ~ paste0(.x, "_", .y)
    )
  )
  
  # Assegno i nomi alle colonne
  names(raw_data) <- col_names
  
  # Rimuovo le intestazioni ----
  clean_data <- raw_data[-c(1:3), ]
  
  # Rimuovo righe vuote e note ----
  clean_data <- clean_data |>
    dplyr::filter(
      !is.na(territorio),
      # note a piè di foglio: "* Stima", "*Stima", "*Dato provvisorio", ecc.
      !stringr::str_starts(territorio, "\\*")
    )
  
  # Converto colonne numeriche ----
  clean_data <- clean_data |>
    dplyr::mutate(
      dplyr::across(
        .cols = -territorio,
        .fns = as.numeric
      )
    )
  
  # Definisco territori da classificare ----
  regioni <- c(
    "Piemonte", "Valle d'Aosta", "Lombardia", "Trentino-Alto Adige",
    "Veneto", "Friuli-Venezia Giulia", "Liguria", "Emilia-Romagna",
    "Toscana", "Umbria", "Marche", "Lazio", "Abruzzo", "Molise",
    "Campania", "Puglia", "Basilicata", "Calabria", "Sicilia", "Sardegna"
  )
  
  ripartizioni <- c(
    "RIPARTIZIONI", "NORD", "NORD-OVEST", "NORD-EST", 
    "CENTRO", "MEZZOGIORNO", "SUD", "ISOLE", "ITALIA"
  )
  
  # Aggiungo classificazione tipo territorio ----
  clean_data <- clean_data |>
    dplyr::mutate(
      tipo = dplyr::case_when(
        territorio %in% regioni ~ "regione",
        territorio %in% ripartizioni ~ "ripartizione",
        TRUE ~ "provincia"
      )
    )
  
  # Converto in formato long (tidy) ----
  tidy_data <- clean_data |>
    tidyr::pivot_longer(
      cols = -c(territorio, tipo),
      names_to = "anno_indicatore",
      values_to = "valore"
    )
  
  # Separo anno e indicatore ----
  tidy_data <- tidy_data |>
    tidyr::separate(
      anno_indicatore,
      into = c("anno", "indicatore"),
      sep = "_",
      extra = "merge"  # Per gestire indicatori con underscore nel nome
    )
  
  # Pulisco anno ----
  tidy_data <- tidy_data |>
    dplyr::mutate(
      anno = stringr::str_remove_all(anno, "[\\*']+"),  # Rimuovo asterischi (singoli/multipli) e apostrofi
      anno = as.integer(anno)
    )
  
  # Rimuovo NA nei valori ----
  tidy_data <- tidy_data |>
    dplyr::filter(!is.na(valore))
  
  return(tidy_data)
}


# 2/3) ESEMPIO DI UTILIZZO ----

# dati_struttura <- f_import_istat_complex_sheet(
#   file_path = here::here("data", "data_in", "indic_demogr_prov_trend.xlsx")
# )

# 🟧🟩🟦 -----

# 3/3) Importa foglio ISTAT con speranza di vita  --------
library(readxl)
library(tidyverse)
library(here)

#' Importa il foglio ISTAT speranza_di_vita (anno × sesso × età)
#'
#' Layout del file "Indicatori_demografici.xls" (demo.istat.it, download 2026-07-18):
#' foglio unico "speranza_di_vita" con 4 righe di header:
#'   riga 1 = titolo, riga 2 = anni (celle unite ogni 6 colonne),
#'   riga 3 = sesso (Maschi / Femmine / Maschi e femmine, celle unite ogni 2),
#'   riga 4 = età di riferimento (0 / 65). Dati dalla riga 5.
#' (Il vecchio file aveva 2 fogli separati _0/_65: layout non più esistente.)
#'
#' @param file_path Percorso al file Excel
#' @param sheet_name Nome del foglio da importare (default "speranza_di_vita")
#'
#' @return Tibble tidy con colonne: territorio, tipo, anno, sesso, eta, valore
#'
#' @examples
#' dati_speranza <- f_import_istat_speranza(
#'   file_path = here::here("dati", "grezzi", "istat_trend_demog", "Indicatori_demografici.xls")
#' )
#'
f_import_istat_speranza <- function(file_path, sheet_name = "speranza_di_vita") {

  # Leggo il file senza header ----
  raw_data <- readxl::read_excel(
    path = file_path,
    sheet = sheet_name,
    col_names = FALSE
  )

  # Righe di intestazione: anni (2), sesso (3), età (4) ----
  anni_row <- raw_data[2, ]
  sesso_row <- raw_data[3, ]
  eta_row <- raw_data[4, ]

  # Riempio le celle unite (forward fill) per anni e sesso ----
  f_ffill <- function(riga) {
    as.list(riga) |>
      purrr::accumulate(function(prev, curr) {
        if (is.na(curr)) prev else curr
      })
  }
  anni_filled <- f_ffill(anni_row)
  sesso_filled <- f_ffill(sesso_row)

  # Nomi colonna: anno_sesso_eta (es. "2002_Maschi_0") ----
  # NB: sep "_" è sicuro perché sesso ed età non contengono underscore
  col_names <- c(
    "territorio",
    purrr::pmap_chr(
      list(
        anni_filled[-1],
        sesso_filled[-1],
        as.list(eta_row)[-1]
      ),
      function(a, s, e) paste0(a, "_", s, "_", as.integer(as.numeric(e)))
    )
  )

  names(raw_data) <- col_names

  # Definisco territori da classificare ----
  regioni <- c(
    "Piemonte", "Valle d'Aosta", "Lombardia", "Trentino-Alto Adige",
    "Veneto", "Friuli-Venezia Giulia", "Liguria", "Emilia-Romagna",
    "Toscana", "Umbria", "Marche", "Lazio", "Abruzzo", "Molise",
    "Campania", "Puglia", "Basilicata", "Calabria", "Sicilia", "Sardegna"
  )

  ripartizioni <- c(
    "RIPARTIZIONI", "NORD", "NORD-OVEST", "NORD-EST",
    "CENTRO", "MEZZOGIORNO", "SUD", "ISOLE", "ITALIA"
  )

  # Pulizia e trasformazione in tidy format ----
  tidy_data <- raw_data[-c(1:4), ] |>
    dplyr::filter(
      !is.na(territorio),
      # note a piè di foglio: "* Stima", "*Stima", "*Dato provvisorio", ecc.
      !stringr::str_starts(territorio, "\\*")
    ) |>
    dplyr::mutate(
      dplyr::across(.cols = -territorio, .fns = as.numeric)
    ) |>
    dplyr::mutate(
      tipo = dplyr::case_when(
        territorio %in% regioni ~ "regione",
        territorio %in% ripartizioni ~ "ripartizione",
        TRUE ~ "provincia"
      )
    ) |>
    tidyr::pivot_longer(
      cols = -c(territorio, tipo),
      names_to = "anno_sesso_eta",
      values_to = "valore"
    ) |>
    tidyr::separate(
      anno_sesso_eta,
      into = c("anno", "sesso", "eta"),
      sep = "_"
    ) |>
    dplyr::mutate(
      anno = stringr::str_remove_all(anno, "[\\*']+"), # asterischi tipo "2025*"
      anno = as.integer(anno),
      eta = as.integer(eta)
    ) |>
    dplyr::filter(!is.na(valore))

  return(tidy_data)
}


# ESEMPIO DI UTILIZZO ----

# dati_speranza <- f_import_istat_speranza(
#   file_path = here::here("data", "data_in", "indic_demogr_prov_trend.xlsx"),
#   sheet_name = "speranza_di_vita"
# )