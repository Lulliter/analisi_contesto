# istat.R ------------------------------------------------------------------
# Funzioni di INGESTIONE delle fonti ISTAT (API SDMX, shapefile, SITUAS) e
# briciole di salvataggio. Usate solo da ingestione/. Nato il 2026-09-18
# accorpando i file di R/ (originali in R/zzz_old/).
# Si carica con: source(here("R", "istat.R"))
#
# Indice (outline RStudio):
#   f_scarica_istat(), f_scarica_istat_blocchi()   dati ISTAT via API SDMX (censimento, a blocchi)
#   f_codelist()                                    una codelist SDMX-JSON di IstatData -> tibble
#   istat_shp_get()                                 legge uno shapefile ISTAT in UTF-8
#   f_scarica_situas_dati(), f_scarica_situas_metadati()   SITUAS (caratteristiche dei comuni)
#   istat_situas_sf_prep()                          shapefile regione/provincia pronti
#   istat_situas_join_comuni_sf()                   join comuni sf + SITUAS
#   write_codici_vec()                              scrive un vettore di codici in uno script R
#   salva_vardesc_rds(), save_all_dataframes()      briciole di salvataggio (ex utilities.R)


# ==== ex R/f_istat_scarica_cens.R ========================================================
# Funzioni per scaricare dati ISTAT via API SDMX ------------------------------
# Nessuna configurazione fissa qui: tutto passa come argomento.

library(httr)
library(rsdmx)
library(dplyr)

# Step 1) Funzione per scaricare dati ISTAT via SDMX-REST ----------------------
#' Scarica dati da ISTAT Esploradati via API SDMX (una singola richiesta)
#'
#' @param codici_territorio Vettore di codici territoriali (comuni, province, ecc.).
#' @param dataset_id ID del dataset ISTAT (Dataflow ID, es. "IT1,DF_...,1.0").
#' @param frequenza Frequenza temporale: "A" (annuale), "M" (mensile), "Q" (trimestrale).
#' @param anno Anno di riferimento (numero intero, es. 2023).
#' @param dimensioni_extra Stringa con le dimensioni extra nella chiave SDMX
#'   (es. "......" se non filtri altre dimensioni).
#' @param timeout_sec Timeout per la richiesta HTTP, in secondi.
#'
#' @return Un data frame con i dati scaricati.
f_scarica_istat <- function(codici_territorio,
                            dataset_id,
                            frequenza        = "A",
                            anno,
                            dimensioni_extra = "......",
                            timeout_sec      = 120) {
  
  # Codici territorio concatenati con "+"
  codici_str <- paste(codici_territorio, collapse = "+")
  
  # Periodo di filtro (qui: anno intero)
  start_date <- paste0(anno, "-01-01")
  end_date   <- paste0(anno, "-12-31")
  
  # Costruzione URL SDMX-REST
  url <- paste0(
    "https://esploradati.istat.it/SDMXWS/rest/data/",
    dataset_id, "/",         # dataflow
    frequenza, ".",          # frequenza
    codici_str, ".",         # codici territoriali
    dimensioni_extra, "/",   # altre dimensioni
    "ALL/?detail=full",
    "&startPeriod=", start_date,
    "&endPeriod=",   end_date,
    "&dimensionAtObservation=TIME_PERIOD"
  )
  
  # Stampa URL per debug/verifica
  message("URL richiesta: ", url)
  
  # Richiesta HTTP
  response <- httr::GET(
    url,
    httr::add_headers(
      Accept = "application/vnd.sdmx.structurespecificdata+xml;version=2.1"
    ),
    httr::timeout(timeout_sec)
  )
  
  # Controllo esito
  if (httr::status_code(response) != 200) {
    stop("Errore HTTP: ", httr::status_code(response),
         "\nURL: ", url,
         "\nPossibili cause: rate limit, codici errati, dataset non disponibile.")
  }
  
  # Salvataggio temporaneo e parsing SDMX
  temp_file <- tempfile(fileext = ".xml")
  base::writeBin(httr::content(response, "raw"), temp_file)
  
  sdmx_obj <- rsdmx::readSDMX(temp_file, isURL = FALSE)
  dati     <- as.data.frame(sdmx_obj, labels = TRUE)
  
  unlink(temp_file)
  
  dati
}

# Step 2) Funzione per scaricare dati ISTAT in blocchi -------------------------
#' Scarica dati ISTAT in blocchi, gestendo rate limit e unendo i risultati
#'
#' @param codici_territorio Vettore di codici territoriali da scaricare.
#' @param dataset_id ID del dataset ISTAT (Dataflow ID).
#' @param frequenza Frequenza temporale: "A", "M", "Q".
#' @param anno Anno di riferimento.
#' @param dimensioni_extra Stringa con le dimensioni extra nella chiave SDMX.
#' @param codici_per_blocco Numero di codici territorio per richiesta HTTP.
#' @param pausa_tra_richieste Pausa (secondi) tra richieste riuscite.
#' @param pausa_dopo_errore Pausa (secondi) dopo un errore.
#' @param timeout_sec Timeout (secondi) per singola richiesta HTTP.
#' @param stampa_piano Se TRUE, mostra un riepilogo del piano di download.
#'
#' @return Un data frame con tutti i dati scaricati (righe unite).
f_scarica_istat_blocchi <- function(codici_territorio,
                                    dataset_id,
                                    frequenza        = "A",
                                    anno,
                                    dimensioni_extra = "......",
                                    codici_per_blocco   = 10,
                                    pausa_tra_richieste = 20,
                                    pausa_dopo_errore   = 30,
                                    timeout_sec         = 120,
                                    stampa_piano        = TRUE) {
  
  # Suddivisione codici in blocchi
  blocchi <- split(
    codici_territorio,
    ceiling(seq_along(codici_territorio) / codici_per_blocco)
  )
  
  # Stima tempo grezza (10 sec “medi” per chiamata + pause)
  if (stampa_piano) {
    tempo_stimato <- (length(blocchi) - 1) * pausa_tra_richieste +
      length(blocchi) * 10
    minuti  <- floor(tempo_stimato / 60)
    secondi <- tempo_stimato %% 60
    
    message("\nPiano di download ISTAT")
    message("  - Totale codici territorio: ", length(codici_territorio))
    message("  - Codici per blocco:       ", codici_per_blocco)
    message("  - Numero di query:         ", length(blocchi))
    message("  - Tempo stimato:           ", minuti, " min ", secondi, " sec")
    message("  - Rate limit indicativo:   ~5 query/minuto\n")
  }
  
  # Loop di download
  dati_lista <- vector("list", length(blocchi))
  
  for (i in seq_along(blocchi)) {
    message(">>> Blocco ", i, "/", length(blocchi),
            " (", length(blocchi[[i]]), " codici) ...")
    
    tryCatch({
      dati_lista[[i]] <- f_scarica_istat(
        codici_territorio = blocchi[[i]],
        dataset_id        = dataset_id,
        frequenza         = frequenza,
        anno              = anno,
        dimensioni_extra  = dimensioni_extra,
        timeout_sec       = timeout_sec
      )
      
      if (i < length(blocchi)) {
        Sys.sleep(pausa_tra_richieste)
      }
      
    }, error = function(e) {
      warning("Errore nel blocco ", i, ": ", e$message)
      dati_lista[[i]] <- NULL
      
      if (i < length(blocchi)) {
        Sys.sleep(pausa_dopo_errore)
      }
    })
  }
  
  # Rimuovi blocchi NULL (falliti)
  dati_lista <- dati_lista[!vapply(dati_lista, is.null, logical(1))]
  
  if (length(dati_lista) == 0) {
    warning("Nessun blocco scaricato correttamente.")
    return(NULL)
  }
  
  dplyr::bind_rows(dati_lista)
}
# ==== ex R/f_codelist.R ========================================================
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

# ==== ex R/istat_shp_get.R ========================================================
#' Legge uno shapefile ISTAT forzando l'encoding UTF-8
#'
#' Wrapper di \code{sf::st_read()} che imposta l'opzione
#' \code{ENCODING = "UTF-8"} e silenzia i messaggi.
#'
#' @param path Percorso completo al file \code{.shp}.
#'
#' @return Un oggetto \code{sf}.
#' @export
#'
#' @examples
#' \dontrun{
#' shp <- read_shp_utf8(
#'   "data/data_in/istat_shp_ITA/Com01012025/Com01012025_WGS84.shp"
#' )
#' }
read_shp_utf8 <- function(path) {
  sf::st_read(path, options = "ENCODING=UTF-8", quiet = TRUE)
}

#' Carica gli shapefile ISTAT Italia (WGS84) per un'annata
#'
#' Legge i limiti amministrativi ISTAT (Comuni, Province/Città metropolitane,
#' Regioni, Ripartizioni geografiche) al 1° gennaio dell'anno indicato,
#' a partire da una cartella base. Gestisce sia la versione generalizzata
#' (sottocartelle con suffisso \code{_g}) sia quella non generalizzata.
#'
#' @param istat_sh_path Percorso base alla cartella che contiene le
#'   sottocartelle ISTAT, ad esempio:
#'   \code{here::here("dati", "grezzi", "istat_shp")}.
#' @param anno Character o numeric. Anno di riferimento dei confini
#'   (al 1° gennaio). Default \code{"2026"}.
#' @param generalizzata Logical. Se \code{TRUE} (default) legge la versione
#'   generalizzata (confini semplificati, file leggeri: ok per mappe tematiche;
#'   NON per calcoli di superficie o spatial join di precisione).
#'
#' @return Una lista con quattro elementi:
#'   \itemize{
#'     \item \code{comuni_ita}: oggetto \code{sf} dei Comuni
#'     \item \code{province_cm_ita}: oggetto \code{sf} delle Province/Città metropolitane
#'     \item \code{regioni_ita}: oggetto \code{sf} delle Regioni
#'     \item \code{ripartizioni_ita}: oggetto \code{sf} delle Ripartizioni geografiche
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' base_path <- here::here("dati", "grezzi", "istat_shp")
#' shp_2026  <- istat_shp_get(base_path, anno = "2026", generalizzata = TRUE)
#'
#' names(shp_2026)
#' # "comuni_ita" "province_cm_ita" "regioni_ita" "ripartizioni_ita"
#' }
istat_shp_get <- function(istat_sh_path, anno = "2026", generalizzata = TRUE) {

  # Suffisso "_g" per la versione generalizzata (convenzione nomi ISTAT)
  suff <- if (generalizzata) "_g" else ""

  # Costruisce "Com01012026_g/Com01012026_g_WGS84.shp" ecc.
  f_path <- function(livello) {
    base <- paste0(livello, "0101", anno, suff)
    file.path(istat_sh_path, base, paste0(base, "_WGS84.shp"))
  }

  comuni_path <- f_path("Com")
  prov_path   <- f_path("ProvCM")
  reg_path    <- f_path("Reg")
  rip_path    <- f_path("RipGeo")

  # Errore chiaro se manca l'annata/versione richiesta
  paths <- c(comuni_path, prov_path, reg_path, rip_path)
  mancanti <- paths[!file.exists(paths)]
  if (length(mancanti) > 0) {
    stop("File shapefile non trovati:\n", paste("-", mancanti, collapse = "\n"),
         "\nControlla anno/versione o scarica l'annata (vedi _metadati.md).")
  }

  comuni_ita       <- read_shp_utf8(comuni_path)
  province_cm_ita  <- read_shp_utf8(prov_path)
  regioni_ita      <- read_shp_utf8(reg_path)
  ripartizioni_ita <- read_shp_utf8(rip_path)

  list(
    comuni_ita       = comuni_ita,
    province_cm_ita  = province_cm_ita,
    regioni_ita      = regioni_ita,
    ripartizioni_ita = ripartizioni_ita
  )
}

# ==== ex R/istat_situas_get.R ========================================================
# FONTE -----
# ISTAT SITUAS - Servizi di pubblicazione dati territoriali
# https://situas.istat.it/web/#/territorio
# AMBITI GEOGRAFICI: Unità amministrative (Comuni)
# REPORT DISPONIBILI: Elenco codici e denominazioni UT (Report ID 61)
#                     Comuni Caratteristiche del territorio (Report ID 73)
#
#
#
# FUNZIONE 1) DATI-----
#' Scarica dati unità territoriali da ISTAT SITUAS
#'
#' @param id_report Numeric. Id del report (es: 61 per elenco comuni)
#' @param data Character o Date. Data di estrazione (formato "GG/MM/AAAA" o Date)
#' @param tipo Character. Tipo di endpoint: "dati", "conteggio", o "metadati"
#'
#' @return Un data frame (tibble) con i dati richiesti
#' @export
#'
#' @examples
#' # Scarica elenco comuni alla data odierna
#' comuni <- f_scarica_situas_dati()
#' 
#' # Scarica per una data specifica
#' comuni_2020 <- f_scarica_situas_dati(data = "01/01/2020")
f_scarica_situas_dati <- function(id_report, 
                           data = Sys.Date(), 
                           tipo = "dati") {
  
  # Converte la data nel formato richiesto (GG/MM/AAAA)
  if (inherits(data, "Date")) {
    data_formattata <- base::format(data, "%d/%m/%Y")
  } else {
    data_formattata <- data
  }
  
  # Costruisce l'URL base in base al tipo richiesto
  base_url <- "https://situas-servizi.istat.it/publish/"
  
  endpoint <- base::switch(tipo,
                           "dati" = "reportspooljson",
                           "conteggio" = "reportspooljsoncount",
                           "metadati" = "anagrafica_report_metadato_web",
                           base::stop("Tipo non valido. Usa 'dati', 'conteggio' o 'metadati'"))
  
  # Costruisce l'URL completo
  url <- base::paste0(base_url, endpoint, 
                      "?pfun=", id_report, 
                      "&pdata=", data_formattata)
  
  # Messaggio informativo
  base::message("Scarico dati da ISTAT SITUAS...")
  base::message("URL: ", url)
  
  # Effettua la richiesta HTTP
  risposta <- httr2::request(url) |>
    httr2::req_perform()
  
  # Estrae i dati JSON
  dati_json <- risposta |>
    httr2::resp_body_json(simplifyVector = TRUE)
  
  # Estrae il resultset (che contiene i dati veri)
  if ("resultset" %in% base::names(dati_json)) {
    risultato <- tibble::as_tibble(dati_json$resultset)
  } else {
    risultato <- tibble::as_tibble(dati_json)
  }
  
  base::message("Download completato: ", base::nrow(risultato), " righe")
  
  return(risultato)
}
# 
# FUNZIONE 2) METADATI-----
#' Scarica metadati delle colonne da ISTAT SITUAS
#'
#' @param id_report Numeric. Id del report (es: 61 per elenco comuni)
#' @param data Character o Date. Data di estrazione (formato "GG/MM/AAAA" o Date)
#'
#' @return Un tibble con i dettagli delle colonne
#' @export
#'
#' @examples
#' # Scarica metadati del report comuni
#' meta <- f_scarica_situas_metadati()

f_scarica_situas_metadati <- function(id_report, 
                                      data = Sys.Date()) {
  
  # Converte la data nel formato richiesto (GG/MM/AAAA)
  if (inherits(data, "Date")) {
    data_formattata <- base::format(data, "%d/%m/%Y")
  } else {
    data_formattata <- data
  }
  
  # Costruisce l'URL completo
  url <- base::paste0("https://situas-servizi.istat.it/publish/anagrafica_report_metadato_web",
                      "?pfun=", id_report, 
                      "&pdata=", data_formattata)
  
  # Messaggio informativo
  base::message("Scarico metadati da ISTAT SITUAS...")
  base::message("URL: ", url)
  
  # Effettua la richiesta HTTP
  risposta <- httr2::request(url) |>
    httr2::req_perform()
  
  # Estrae il testo JSON con encoding UTF-8 esplicito
  testo_json <- risposta |>
    httr2::resp_body_string(encoding = "UTF-8")
  
  # Forza UTF-8 come suggerito da ISTAT
  testo_json <- base::enc2utf8(testo_json)
  
  # Parse JSON con jsonlite
  dati_json <- jsonlite::fromJSON(
    testo_json, 
    simplifyVector = TRUE,
    simplifyDataFrame = TRUE
  )
  
  # Converte in tibble e spacchetta COL_DETAILS
  risultato <- tibble::as_tibble(dati_json) |>
    tidyr::unnest(COL_DETAILS)
  
  base::message("Download completato: ", base::nrow(risultato), " righe")
  
  return(risultato)
}
# 
# ESEMPIO  -----
# 
#ID_REPORT <- 76  # Elenco comuni
# UTILIZZO Funzione 1) -----
# Scarica elenco comuni alla data odierna
#dati_76 <- f_scarica_situas_dati(id_report = ID_REPORT)
#head(dati_76)
# 
# Scarica per una data specifica
# ut_com_dati_2020 <- f_scarica_situas_dati(data = "01/01/2020")
# head(cut_com_dati_2020)
# 
# 
# 
# UTILIZZO Funzione 2) -----
# Scarica metadati del report comuni
#meta_76 <- f_scarica_situas_metadati(id_report = ID_REPORT)
#head(meta_76)

# ==== ex R/istat_situas_sf_prep.R ========================================================
#' Prepara e salva shapefile per una regione (e opzionalmente una provincia)
#'
#' A partire dai layer nazionali di Comuni, Province/Città metropolitane
#' e Regioni, filtra una regione tramite \code{COD_REG} e, se richiesto,
#' una provincia tramite \code{COD_PROV}. Salva gli oggetti filtrati
#' in formato \code{.rds} nella cartella di output e restituisce gli
#' stessi oggetti in una lista con nomi coerenti ai file salvati.
#'
#' Se \code{nome_reg} o \code{nome_prov} non sono forniti, vengono
#' generati automaticamente a partire dai codici ISTAT:
#' \itemize{
#'   \item regione: \code{REGxx}, es. \code{REG08} per COD_REG = "8"
#'   \item provincia: \code{PROVxx}, es. \code{PROV34} per COD_PROV = "34"
#' }
#'
#' @param comuni_ita Oggetto sf con tutti i comuni d'Italia.
#' @param province_cm_ita Oggetto sf con tutte le province/città metropolitane.
#' @param regioni_ita Oggetto sf con tutte le regioni.
#' @param cod_reg Codice ISTAT della regione (es. "8" per Emilia-Romagna).
#' @param out_dir Cartella di output per i file .rds.
#' @param nome_reg (opzionale) Sigla regione (es. "ER", "LOMB").
#'   Se NULL, viene generata come \code{REGxx}.
#' @param cod_prov (opzionale) Codice ISTAT della provincia (es. "34" per Parma).
#' @param nome_prov (opzionale) Sigla provincia (es. "PR").
#'   Se NULL e \code{cod_prov} non è NULL, viene generata come \code{PROVxx}.
#'
#' @return Lista con oggetti sf, i cui nomi coincidono con i file salvati.
#' @export
istat_situas_sf_prep <- function(comuni_ita,
                                 province_cm_ita,
                                 regioni_ita,
                                 cod_reg,
                                 out_dir,
                                 nome_reg  = NULL,
                                 cod_prov  = NULL,
                                 nome_prov = NULL) {
  
  # Normalizza codici (sempre carattere)
  cod_reg  <- as.character(cod_reg)
  cod_prov <- if (!is.null(cod_prov)) as.character(cod_prov) else NULL
  
  # Se nome_reg non è fornito, usa prefisso basato su COD_REG
  if (is.null(nome_reg)) {
    # zero-padding a 2 cifre
    cod_reg2 <- sprintf("%02s", cod_reg)
    nome_reg <- paste0("REG", cod_reg2)  # es. "REG08"
  } else {
    nome_reg <- toupper(trimws(nome_reg))
  }
  
  # Se nome_prov non è fornito ma ho cod_prov, costruisco PROVxx
  if (!is.null(cod_prov) && is.null(nome_prov)) {
    cod_prov2 <- sprintf("%02s", cod_prov)
    nome_prov <- paste0("PROV", cod_prov2)  # es. "PROV34"
  } else if (!is.null(nome_prov)) {
    nome_prov <- toupper(trimws(nome_prov))
  }
  
  # 1) Filtra regione
  comuni_reg    <- dplyr::filter(comuni_ita,      COD_REG == cod_reg)
  provincie_reg <- dplyr::filter(province_cm_ita, COD_REG == cod_reg)
  regioni_reg   <- dplyr::filter(regioni_ita,     COD_REG == cod_reg)
  
  # 2) Filtra provincia (se richiesta)
  comuni_prov    <- NULL
  provincie_prov <- NULL
  
  if (!is.null(cod_prov)) {
    comuni_prov    <- dplyr::filter(comuni_ita,      COD_PROV == cod_prov)
    provincie_prov <- dplyr::filter(province_cm_ita, COD_PROV == cod_prov)
  }
  
  # 3) Crea cartella di output se non esiste
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE)
  }
  
  # 4) Nomi coerenti per file e lista (prefisso regione)
  nm_comuni_reg    <- paste0(nome_reg, "_comuni_sf")
  nm_provincie_reg <- paste0(nome_reg, "_provincie_sf")
  nm_regioni_reg   <- paste0(nome_reg, "_regioni_sf")
  
  # Salva RDS regione
  saveRDS(comuni_reg,
          file = file.path(out_dir, paste0(nm_comuni_reg, ".rds")))
  saveRDS(provincie_reg,
          file = file.path(out_dir, paste0(nm_provincie_reg, ".rds")))
  saveRDS(regioni_reg,
          file = file.path(out_dir, paste0(nm_regioni_reg, ".rds")))
  
  # Inizializza lista risultato
  res <- list()
  res[[nm_comuni_reg]]    <- comuni_reg
  res[[nm_provincie_reg]] <- provincie_reg
  res[[nm_regioni_reg]]   <- regioni_reg
  
  # 5) Se c'è provincia specifica, aggiunge anche quella
  if (!is.null(comuni_prov) && !is.null(nome_prov)) {
    
    nm_comuni_prov    <- paste0(nome_reg, "_", nome_prov, "_comuni_sf")
    nm_provincie_prov <- paste0(nome_reg, "_", nome_prov, "_provincie_sf")
    
    saveRDS(comuni_prov,
            file = file.path(out_dir, paste0(nm_comuni_prov, ".rds")))
    saveRDS(provincie_prov,
            file = file.path(out_dir, paste0(nm_provincie_prov, ".rds")))
    
    res[[nm_comuni_prov]]    <- comuni_prov
    res[[nm_provincie_prov]] <- provincie_prov
  }
  
  res
}

# ==== ex R/istat_situas_join_comuni_sf.R ========================================================
#' Join shapefile comuni ISTAT con caratteristiche SITUAS
#'
#' Esegue il join tra lo shapefile nazionale dei comuni (\code{sf})
#' e la tabella SITUAS delle caratteristiche territoriali,
#' utilizzando il codice alfanumerico \code{PRO_COM_T}.
#'
#' Mantiene la geometria \code{sf}, pulisce i nomi delle colonne
#' (.x / .y) e costruisce una versione ridotta, con le sole colonne
#' di codici e attributi principali, più una colonna di denominazione
#' italiana \code{COMUNE_it}.
#'
#' Opzionalmente salva la versione ridotta in un file \code{.rds},
#' in una cartella di output specificata.
#'
#' @param comuni_sf Oggetto \code{sf} con tutti i comuni d'Italia,
#'   deve contenere almeno le colonne \code{PRO_COM_T},
#'   \code{Shape_Leng}, \code{Shape_Area}, \code{geometry}.
#' @param situas_df Data frame/tibble con le caratteristiche SITUAS
#'   dei comuni, che deve contenere una colonna \code{PRO_COM_T}
#'   compatibile con quella dello shapefile.
#' @param out_dir Cartella in cui salvare la versione ridotta in
#'   formato \code{.rds}. Se \code{NULL}, non viene salvato nulla.
#' @param out_basename Nome base del file .rds (senza estensione),
#'   usato solo se \code{out_dir} non è \code{NULL}.
#'   Default: \code{"comuni_ita_info_redux_sf"}.
#' @param keep_cols Vettore di nomi di colonne da mantenere nella
#'   versione ridotta. Se \code{NULL}, viene usato un set di default
#'   (codici territoriali principali, attributi SITUAS essenziali,
#'   area/perimetro, geometria).
#'
#' @return Una lista con:
#'   \itemize{
#'     \item \code{comuni_info_sf}       — join completo (sf)
#'     \item \code{comuni_info_redux_sf} — versione ridotta (sf)
#'   }
#'
#' @examples
#' \dontrun{
#' res <- istat_situas_join_comuni_sf(
#'   comuni_sf      = comuni_ita,
#'   situas_df      = com_caratt,
#'   out_dir        = here::here("data","data_out"),
#'   out_basename   = "comuni_ita_info_redux_sf"
#' )
#'
#' str(res$comuni_info_redux_sf)
#' }
#'
#' @export
istat_situas_join_comuni_sf <- function(comuni_sf,
                                        situas_df,
                                        out_dir      = NULL,
                                        out_basename = "comuni_ita_info_redux_sf",
                                        keep_cols    = NULL) {
  # 1) Join sf (comuni_sf a sinistra per mantenere la geometria)
  comuni_info_sf <- dplyr::left_join(
    comuni_sf,
    situas_df,
    by = "PRO_COM_T"
  ) |>
    dplyr::select(-dplyr::ends_with(".y")) |>
    dplyr::rename_with(
      ~ sub("\\.x$", "", .x),
      dplyr::ends_with(".x")
    ) |>
    dplyr::relocate(c("Shape_Leng", "Shape_Area"), .before = "geometry")
  
  # 2) Colonne da tenere nella versione ridotta
  if (is.null(keep_cols)) {
    keep_cols <- c(
      "COD_RIP", "COD_REG", "COD_UTS",
      "COD_PROV_STORICO", "COD_PROV", "COD_CM", "CC_UTS",
      "PRO_COM_T", "PRO_COM", "COMUNE", "COMUNE_A",
      # "SIGLA_AUTOMOBILISTICA",
      "COM_ISO", "COM_LIT", "ZONA_ALT", "ZONE_COST_2021", "DEGURBA_2021",
      "Shape_Leng", "Shape_Area", "geometry"
    )
  }
  
  # 3) Versione ridotta + COMUNE_it
  comuni_info_redux_sf <- comuni_info_sf |>
    dplyr::select(dplyr::all_of(keep_cols)) |>
    dplyr::mutate(
      COMUNE_it = stringr::str_trim(
        stringr::str_split_fixed(COMUNE, "/", 2)[, 1]
      )
    ) |>
    dplyr::relocate(COMUNE_it, .after = COMUNE)
  
  # 4) Salvataggio opzionale
  if (!is.null(out_dir)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    out_file <- file.path(out_dir, paste0(out_basename, ".rds"))
    saveRDS(comuni_info_redux_sf, file = out_file)
  }
  
  # 5) Output
  list(
    comuni_info_sf       = comuni_info_sf,
    comuni_info_redux_sf = comuni_info_redux_sf
  )
}


# ==== ex R/write_codici_vec.R ========================================================
#' Write Unique Codes to R Script as Character Vector
#' 
#' @param x A data frame or tibble containing the data.
#' @param col The column name (as a string) from which to extract unique codes
#' '            (e.g., "COD_COMUNE", "COD_PROV", "COD_REG").
#' @param vec_name The name of the character vector to be created in the output
#' '                 R script (e.g., "codici_comuni", "codici_province").
#' @param out_path The file path where the R script will be saved.
#' @return Invisibly returns the vector of unique codes.
#' @examples
#' \dontrun{
#' # Example data frame
#' df <- data.frame(COD_COMUNE = c("001", "002", "003", "001"))
#' # Write unique codes to R script
#' write_codici_vec(df, "COD_COMUNE", "codici_comuni", "data/codici_comuni.R")
#' }
write_codici_vec <- function(x, col, vec_name, out_path) {
  codici <- sort(unique(as.character(x[[col]])))
  
  txt <- paste0(
    vec_name, " <- c(",
    paste0('"', codici, '"', collapse = ", "),
    ")\n"
  )
  
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  writeLines(txt, con = out_path)
  cat(txt)
  
  invisible(codici)
}

# ==== ex R/utilities.R ========================================================
# Salva tabella di descrizione variabili comuni ISTAT-SITUAS ----
#' Salva tabella di descrizione variabili comuni ISTAT-SITUAS
#'
#' @param df Tibble da salvare
#' @param out_path Percorso completo dell'RDS di output
#' @return Lo stesso tibble (invisibile)
#' @export
salva_vardesc_rds <- function(df, out_path) {
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(df, out_path)
  invisible(df)
}


# Salva tutti i dataframe del Global Environment come file RDS ----
library(here)
library(purrr)
library(stringr)
#' Salva tutti i dataframe del Global Environment come file RDS
#'
#' @param output_dir Directory di output (obbligatorio)
#' @param pattern Pattern regex per filtrare i nomi dei dataframe (default: NULL = tutti)
#'
#' @return Invisibile: vettore con i nomi dei dataframe salvati
#'
#' @examples
#' save_all_dataframes(here::here("data", "data_out", "istat_demo_2002_2024"))
#' save_all_dataframes("export/dati", pattern = "^dati_")
#'
save_all_dataframes <- function(output_dir, pattern = NULL) {
  
  # Creo la directory se non esiste
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  # Ottengo tutti i dataframe dal Global Environment
  df_list <- ls(.GlobalEnv) |>
    mget(envir = .GlobalEnv, inherits = FALSE, ifnotfound = list(NULL)) |>
    purrr::keep(is.data.frame)
  # Filtro per pattern (se specificato)
  if (!is.null(pattern)) {
    df_list <- df_list[stringr::str_detect(names(df_list), pattern)]
  }
  # Controllo se ci sono dataframe
  if (length(df_list) == 0) {
    message("Nessun dataframe trovato")
    return(invisible(character(0)))
  }
  # Salvo i dataframe
  saved <- character()
  purrr::iwalk(df_list, function(df, df_name) {
    file_path <- file.path(output_dir, paste0(df_name, ".rds"))
    # Salvataggio con gestione errori & warnings (base R)
    tryCatch({
      saveRDS(df, file_path)
      message("✓ ", df_name)
      saved <<- c(saved, df_name)
    }, error = function(e) {
      message("✗ ", df_name, ": ", e$message)
    })
  })
  # Messaggio finale
  message("\nSalvati ", length(saved), " su ", length(df_list), " dataframe")
  
  invisible(saved)
}


# ESEMPIO DI UTILIZZO ----

# save_all_dataframes(here::here("data", "data_out", "istat_demo_2002_2024"))
# save_all_dataframes("export/dati", pattern = "^dati_")