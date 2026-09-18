# grafici.R ----------------------------------------------------------------
# Funzioni per costruire e salvare i grafici del sito (temi, caption, mappe,
# salvataggio, girafe). Nato il 2026-09-18 accorpando i file f_*.R di R/
# (originali in R/zzz_old/). Regola: "R/ non conosce i moduli", tutto via
# argomenti. Si carica con: source(here("R", "grafici.R")) dopo _parma_colors.R
#
# Indice (outline RStudio):
#   f_theme_sito()           tema base del sito: font, titolo, sottotitolo, caption, legenda
#   f_theme_sito_trend()     base + asse x a 45 gradi (serie storiche)
#   f_theme_sito_mappa()     base + niente assi/griglia, legenda a destra con titolo
#   f_theme_sito_piramide()  base + legenda in alto, niente griglia orizzontale
#   f_caption_fonte()        caption "Fonte: ... / Rielaborazione: ..."
#   f_lab_as()               2015 -> "2015/16"
#   f_pal5()                 palette a 5 da una sequenziale a 8
#   f_aggiungi_classe()      colonna classe_<var> a quantili o tagli fissi
#   f_disegna_mappa()        mappa comunale a classi (statica o interattiva)
#   f_salva_plot()           png (ragg) + rds (per il sito)
#   f_girafe()               widget girafe con lo stile del sito
#
# COME FUNZIONA LA DIMENSIONE DEI FONT (decisione 2026-09-18):
# ggiraph disegna l'svg largo fig-width pollici e lo riscala alla colonna
# del sito (~650 px). Con fig-width = 9 (default in _quarto.yml) la scala e'
# 1: un punto scritto qui e' un punto a schermo. fig-height cambia solo le
# proporzioni. Percio': nei moduli MAI theme_minimal()/base_size, solo questi
# temi; i rel() locali restano ammessi tra 0.85 e 1.3.

# f_theme_sito ---------------------------------------------------------------
# Tema base: tutto cio' che vale per OGNI grafico del sito. Le scelte che
# dipendono dal tipo di grafico (assi inclinati, legenda a destra, griglia)
# stanno nelle varianti sotto o nel singolo grafico.
# NB: titolo in element_text NORMALE (il textbox come titolo viene tagliato
# in cima nel device svg di ggiraph); sottotitolo in textbox (va a capo da
# solo). Chi sovrascrive il sottotitolo deve usare ancora un textbox.
f_theme_sito <- function(base_size = 15) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.grid.major = ggplot2::element_line(color = "grey90", linewidth = ggplot2::rel(0.3)),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text        = ggplot2::element_text(size = ggplot2::rel(0.85)),
      plot.title       = ggplot2::element_text(size = ggplot2::rel(1.3), face = "bold",
                                               margin = ggplot2::margin(b = 10)),
      plot.subtitle    = ggtext::element_textbox_simple(size = ggplot2::rel(0.95), lineheight = 1.2,
                                                        margin = ggplot2::margin(b = 10)),
      plot.caption     = ggplot2::element_text(hjust = 0, size = ggplot2::rel(0.7), colour = "grey30",
                                               margin = ggplot2::margin(t = 8)),
      # titolo, sottotitolo e caption allineati all'INTERA figura, non al
      # pannello: cosi' il textbox del sottotitolo usa tutta la larghezza anche
      # quando il pannello e' stretto (mappe con proporzioni fisse + legenda)
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      strip.text       = ggplot2::element_text(size = ggplot2::rel(1), face = "bold"),
      legend.title     = ggplot2::element_blank(),
      legend.text      = ggplot2::element_text(size = ggplot2::rel(0.9)),
      legend.position  = "bottom"
    )
}

# f_theme_sito_trend ---------------------------------------------------------
# Serie storiche: anni sull'asse x inclinati a 45 gradi
f_theme_sito_trend <- function(base_size = 15) {
  f_theme_sito(base_size) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}

# f_theme_sito_mappa ---------------------------------------------------------
# Mappe: niente assi ne' griglia; legenda a destra CON titolo (nelle mappe
# serve, es. "% stranieri su iscritti")
f_theme_sito_mappa <- function(base_size = 15) {
  f_theme_sito(base_size) +
    ggplot2::theme(
      axis.text       = ggplot2::element_blank(),
      axis.title      = ggplot2::element_blank(),
      axis.ticks      = ggplot2::element_blank(),
      panel.grid      = ggplot2::element_blank(),
      legend.position = "right",
      legend.title    = ggplot2::element_text(size = ggplot2::rel(0.9), face = "bold")
    )
}

# f_theme_sito_piramide ------------------------------------------------------
# Piramidi dell'eta': legenda (sesso) in alto, niente griglia orizzontale
f_theme_sito_piramide <- function(base_size = 15) {
  f_theme_sito(base_size) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      legend.position    = "top"
    )
}

# f_caption_fonte ---------------------------------------------------------
# Caption standard dei grafici del repo: riga "Fonte: ..." (variabile) +
# riga fissa "Rielaborazione: ..." che va SEMPRE a capo (decisione 2026-07-18).
# Uso: labs(caption = f_caption_fonte("MIM, Portale unico dei dati della scuola"))
f_caption_fonte <- function(fonte) {
  paste0(
    "Fonte: ", fonte,
    "\nRielaborazione: Fondazione Cariparma - Osservatorio dei Dati Sociali"
  )
}

# f_lab_as ----------------------------------------------------------------
# Etichetta di un anno scolastico dal suo anno di inizio: 2015 -> "2015/16"
# (nata in moduli/scuola_iscritti, promossa a R/ il 2026-09-10)
f_lab_as <- function(anno) paste0(anno, "/", (anno + 1) %% 100)

# f_pal5 -------------------------------------------------------------------
# Estrae una palette a 5 colori (per classi a quintili) da una sequenziale
# a 8 di _parma_colors.R (seq_factor_*). Promossa da pop_mappe_tematiche
# il 2026-07-18 (2° utilizzatore: scuola_iscritti — regola 6).
f_pal5 <- function(seq8) seq8[c(2, 3, 5, 6, 8)]

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

# f_disegna_mappa ----------------------------------------------------------
# Mappa tematica comunale a classi: base condivisa dei moduli con mappe.
# Presuppone: colonna "classe_<var>" in df_comuni (vedi f_aggiungi_classe)
# e palette caricata (source R/_parma_colors.R) per i default dei colori.
# df_evidenzia = NULL → nessun bordo di evidenziazione.
# Promossa da moduli/pop_mappe_tematiche il 2026-07-18 (2° utilizzatore:
# scuola_iscritti — regola 6). Tema: f_theme_sito_mappa().
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
    f_theme_sito_mappa()
}

# f_salva_plot -------------------------------------------------------------
# Salva un ggplot (grafico o mappa) in png (riuso rapido, device ragg per i
# caratteri tipografici) + rds (per il sito); nome file = nome passato.
# Era f_salva_mappa (pop_mappe_tematiche, 2026-07-18).
f_salva_plot <- function(grafico, nome_file, dir_out, width = 9, height = 7) {
  ggplot2::ggsave(file.path(dir_out, paste0(nome_file, ".png")),
                  grafico, width = width, height = height, dpi = 300,
                  device = ragg::agg_png, bg = "white")
  saveRDS(grafico, file.path(dir_out, paste0(nome_file, ".rds")))
  message("Salvato: ", nome_file, " (.rds + .png)")
}

# f_girafe -----------------------------------------------------------------
# Input:  ggobj — un ggplot (con geoms _interactive di ggiraph)
# Output: widget girafe con lo stile standard del sito:
#         tooltip scuro + hover bordeaux (burg_md, evidenziazione di palette).
#         Larghezza e altezza dell'svg vengono da fig-width/fig-height del chunk
f_girafe <- function(ggobj) {
  ggiraph::girafe(
    ggobj = ggobj,
    options = list(
      ggiraph::opts_tooltip(
        css = "background-color:#333; color:white; padding:8px; border-radius:4px; font-size:12px;"
      ),
      # css differenziato per tipo di elemento: alle LINEE niente fill
      # (in SVG riempirebbe l'area sotto la curva), a punti e poligoni si'
      ggiraph::opts_hover(css = ggiraph::girafe_css(
        css   = "fill:#873C4A;stroke:#873C4A;",  # default (es. poligoni mappe)
        line  = "fill:none;stroke:#873C4A;",
        point = "fill:#873C4A;stroke:#873C4A;"
      ))
    )
  )
}
