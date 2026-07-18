# f_disegna_mappa ----------------------------------------------------------
# Mappa tematica comunale a classi: base condivisa dei moduli con mappe.
# Presuppone: colonna "classe_<var>" in df_comuni (vedi f_aggiungi_classe)
# e palette caricata (source R/_parma_colors.R) per i default dei colori.
# df_evidenzia = NULL → nessun bordo di evidenziazione.
# Promossa da moduli/pop_mappe_tematiche il 2026-07-18 (2° utilizzatore:
# scuola_iscritti — regola 6). "R/ non conosce i moduli": tutto via argomenti.
f_disegna_mappa <- function(df_comuni, df_prov, var, titolo, palette5, caption,
                            sottotitolo = NULL,
                            nome_legenda = NULL, # NULL = legenda senza titolo
                            col_tooltip = NULL,  # nome colonna col testo hover
                                                 # (NULL = mappa statica)
                            df_evidenzia = NULL,
                            col_evidenzia = burg_md,
                            col_bordi = grey_sc,
                            col_na = grey_m) {
  # strato dei comuni: interattivo (ggiraph) se c'è una colonna tooltip,
  # altrimenti statico. NB: la versione interattiva si attiva nelle pagine
  # con girafe(ggobj = ...); stampata/salvata in png resta identica
  if (is.null(col_tooltip)) {
    strato_comuni <- ggplot2::geom_sf(
      data = df_comuni,
      ggplot2::aes(fill = .data[[paste0("classe_", var)]]),
      color = col_bordi, linewidth = 0.1
    )
  } else {
    strato_comuni <- ggiraph::geom_sf_interactive(
      data = df_comuni,
      ggplot2::aes(fill = .data[[paste0("classe_", var)]],
                   tooltip = .data[[col_tooltip]],
                   data_id = .data[[col_tooltip]]),
      color = col_bordi, linewidth = 0.1
    )
  }

  p <- ggplot2::ggplot() +
    strato_comuni +
    ggplot2::geom_sf(data = df_prov, fill = NA, color = "#525252", linewidth = 0.2)

  if (!is.null(df_evidenzia)) {
    p <- p + ggplot2::geom_sf(data = df_evidenzia, fill = NA,
                              color = col_evidenzia, linewidth = 0.6)
  }

  p +
    ggplot2::scale_fill_manual(values = palette5, na.value = col_na,
                               name = nome_legenda, drop = FALSE) +
    ggplot2::labs(title = titolo, subtitle = sottotitolo, caption = caption) +
    ggplot2::theme_minimal(base_size = 14) + # font grandi: girafe rimpicciolisce
    ggplot2::theme(
      axis.text    = ggplot2::element_blank(),
      axis.title   = ggplot2::element_blank(),
      axis.ticks   = ggplot2::element_blank(),
      panel.grid   = ggplot2::element_blank(),
      plot.caption = ggplot2::element_text(hjust = 0, size = 8, colour = "grey30")
    )
}
