# f_aggiungi_classe --------------------------------------------------------
# Aggiunge a un df (anche sf) la colonna "classe_<var>": classi a quantili
# di `var` (default quintili), con etichette "da – a" formattate da label_fun.
# NB: le classi sono calcolate sul df PASSATO — se serve coerenza tra mappe
# (es. zoom PR con classi ER) calcolarle sul df ampio e poi filtrare.
# Promossa da moduli/pop_mappe_tematiche il 2026-07-18 (2° utilizzatore:
# scuola_iscritti — regola 6).
# Argomenti opzionali:
#   breaks    = tagli FISSI al posto dei quantili (utile per conteggi, dove i
#               quintili collassano e producono classi assurde tipo "4 – 76")
#   etichette = etichette esplicite delle classi (se NULL si costruiscono
#               "da – a" con label_fun)
f_aggiungi_classe <- function(df_sf, var, label_fun, probs = seq(0, 1, 0.2),
                              breaks = NULL, etichette = NULL) {
  if (is.null(breaks)) {
    brks <- quantile(df_sf[[var]], probs = probs, na.rm = TRUE)
    # con variabili discrete alcuni quantili possono coincidere:
    # si tengono solo i break unici → possono uscire MENO classi del previsto
    brks <- unique(brks)
  } else {
    brks <- breaks
  }
  if (length(brks) < 2) {
    stop("f_aggiungi_classe: '", var, "' e' (quasi) costante, impossibile classare")
  }
  if (is.null(etichette)) {
    etichette <- paste(label_fun(head(brks, -1)), label_fun(tail(brks, -1)),
                       sep = " – ")
  }
  df_sf |>
    dplyr::mutate("classe_{var}" := cut(
      .data[[var]], breaks = brks, include.lowest = TRUE,
      labels = etichette))
}
