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
         "\nControlla anno/versione o scarica l'annata (vedi _meta.md).")
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