# ------------------------------------------------------------------------
# Modulo: demo_trend_indicatori
# Scopo:  18 grafici di trend (linee interattive ggiraph) che confrontano
#         Parma vs province ER, Emilia-Romagna e Italia, 2002-2024
# Input:  output/<indicatore>.rds (da 01_dati.R)
# Output: output/pNN_<indicatore>.rds (oggetti ggplot; girafe() si applica
#         nella pagina di sito/ che li usa)
# Origine codice: dashboard/demographic_trends/visualizations.R (vecchio repo)
# ------------------------------------------------------------------------

library(dplyr)
library(stringr)
library(glue)
library(ggplot2)
library(ggtext)
library(ggiraph)
library(here)
# + ggtext (via ::) per il sottotitolo che va a capo da solo:
#   se manca: install.packages("ggtext"), poi renv::snapshot()

source(here("R", "_parma_colors.R")) # burg_*, grn_*, blu_* ecc.
source(here("R", "f_caption_fonte.R"))

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "demo_trend_indicatori", "output")

# caption su due righe: la riga "Rielaborazione" va sempre a capo
CAP <- f_caption_fonte("Istat, Demografia in cifre")

territori_er <- c(
  "Bologna", "Piacenza", "Parma", "Reggio nell'Emilia", "Modena",
  "Ferrara", "Ravenna", "Forli'", "Rimini",
  "Emilia-Romagna", "NORD-EST", "ITALIA"
)
territori_highlight <- c("Parma", "Emilia-Romagna", "NORD-EST", "ITALIA")

# Funzioni locali (uniche utilizzatrici: questo modulo — regola 6) ---------

# Carica un rds di 01_dati.R e prepara i fattori territorio/highlight
f_load_and_prepare_rds <- function(
  rds_file,
  dir_rds = dir_mod,
  territori_filtro = territori_er,
  territori_hl = territori_highlight
) {
  if (!grepl("\\.rds$", rds_file, ignore.case = TRUE)) {
    rds_file <- paste0(rds_file, ".rds")
  }
  file_path <- file.path(dir_rds, rds_file)
  if (!file.exists(file_path)) {
    stop(glue("File non trovato: {file_path} — eseguire prima 01_dati.R"))
  }
  message(glue("# --- Load dataset: {rds_file} ----"))

  readRDS(file_path) |>
    dplyr::filter(territorio %in% territori_filtro) |>
    dplyr::mutate(
      highlight = territorio %in% territori_hl,
      territorio_display = ifelse(highlight, territorio, "Altre provincie ER")
    ) |>
    dplyr::mutate(
      territorio_display = factor(
        territorio_display,
        levels = c(territori_hl, "Altre provincie ER")
      ),
      highlight = factor(highlight)
    )
}

# Crea (e salva) il grafico di trend per un indicatore
f_plot_indicatore_demografico <- function(
  dataset,
  indicatore,
  udm,
  title = NULL,
  subtitle = NULL,
  caption = CAP,
  save_plot = FALSE,
  save_data = TRUE, # salva anche i dati del grafico come csv (stesso nome, .csv)
  file_name = NULL,
  dir_out = dir_mod
) {
  # Dati del solo indicatore richiesto (serve anche per il range anni)
  df_plot <- dataset |>
    dplyr::filter(indicatore == !!indicatore) |>
    dplyr::filter(territorio != "NORD-EST", territorio != "Altre provincie ER")

  # Range anni effettivo: flussi → ultimo anno solare (2025*),
  # stock al 1° gennaio (indici di struttura, classi di età) → 2026*
  anno_min <- min(df_plot$anno)
  anno_max <- max(df_plot$anno)

  # Titolo/sottotitolo di default a partire dal nome indicatore
  if (is.null(title)) {
    indicatore_pretty <- stringr::str_replace_all(indicatore, "_", " ") |>
      stringr::str_to_sentence()
    title <- glue("Trend demografici: {indicatore_pretty}")
  }
  title <- glue("{title} ({anno_min}-{anno_max})") # intervallo calcolato dai dati
  if (is.null(subtitle)) {
    # niente str_wrap: l'a-capo lo gestisce ggtext::element_textbox_simple nel theme
    subtitle <- glue("Indicatore espresso in: {udm}")
  }

  p <- df_plot |>
    ggplot(aes(
      x = anno, y = valore,
      color = territorio_display, alpha = highlight, group = territorio
    )) +
    geom_line_interactive(
      aes(tooltip = territorio, data_id = gsub("'", "", territorio)),
      linewidth = rel(0.8)
    ) +
    # linea più spessa per TUTTI i territori evidenziati (Parma, ER, Italia, ...)
    geom_line_interactive(
      data = function(df) df |> dplyr::filter(territorio_display != "Altre provincie ER"),
      aes(tooltip = territorio, data_id = gsub("'", "", territorio)),
      linewidth = rel(1.5)
    ) +
    # standard "linea + pallino": punti solo sulle linee evidenziate
    geom_point_interactive(
      data = function(df) df |> dplyr::filter(territorio_display != "Altre provincie ER"),
      aes(tooltip = valore, data_id = gsub("'", "", territorio)),
      size = 1.6
    ) +
    scale_x_continuous(
      breaks = seq(anno_min, anno_max, by = 1),
      limits = c(anno_min, anno_max),
      expand = expansion(mult = c(0.02, 0.02))
    ) +
    scale_alpha_manual(values = c(0.3, 1), guide = "none") +
    scale_color_manual(
      values = c(
        "Parma" = ylw_lg,          # come repo bilancio di missione
        "Emilia-Romagna" = grn_md,
        "NORD-EST" = blu_lg,
        "ITALIA" = blu_md,
        "Altre provincie ER" = grey_sc
      )
    ) +
    theme_minimal(base_size = 15) + # font grandi: girafe rimpicciolisce
    theme(
      panel.grid.major = element_line(color = "grey90", linewidth = rel(0.3)),
      panel.grid.minor = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, size = rel(0.85)),
      axis.text.y = element_text(size = rel(0.85)),
      axis.title = element_text(size = rel(1), face = "bold"),
      plot.title = element_text(size = rel(1.3), face = "bold", margin = margin(b = 10)),
      # textbox: va a capo da solo alla larghezza effettiva del grafico
      plot.subtitle = ggtext::element_textbox_simple(
        size = rel(0.95), lineheight = 1.2, margin = margin(b = 10)
      ),
      strip.text = element_text(size = rel(1.1), face = "bold"),
      legend.text = element_text(size = rel(0.9)),
      legend.title = element_blank(),
      legend.position = "bottom",
      panel.spacing = unit(1, "lines")
    ) +
    labs(title = title, subtitle = subtitle, caption = caption, x = "", y = "")

  if (save_plot) {
    if (is.null(file_name)) {
      file_name <- glue("plot_{janitor::make_clean_names(indicatore)}.rds")
    }
    saveRDS(p, file.path(dir_out, file_name))
    message(glue("Plot salvato in: {file.path(dir_out, file_name)}"))
  }

  # Dati del grafico in csv "lungo" (per tabelle/download nelle pagine di sito)
  if (save_data && !is.null(file_name)) {
    csv_name <- sub("\\.rds$", ".csv", file_name)
    df_plot |>
      dplyr::select(indicatore, territorio, anno, valore) |>
      write.csv(file.path(dir_out, csv_name), row.names = FALSE)
    message(glue("Dati salvati in: {file.path(dir_out, csv_name)}"))
  }

  p
}

# 1. Indici strutturali (dataset: indicatori_di_struttura) ----------------
data1 <- f_load_and_prepare_rds("indicatori_di_struttura")
# janitor::tabyl(data1$indicatore) # per controllare i nomi indicatore

# Plot: p01_e_m [= Età media] ----
p01_e_m <- f_plot_indicatore_demografico(
  dataset = data1,
  indicatore = "Età media",
  udm = "anni e decimi di anno",
  save_plot = TRUE,
  file_name = "p01_e_m.rds"
)

# Plot: p02_i_v [= Indice di vecchiaia] ----
p02_i_v <- f_plot_indicatore_demografico(
  dataset = data1,
  indicatore = "Indice di vecchiaia",
  udm = "% tra popolazione di 65+ anni e in età 0-14.",
  save_plot = TRUE,
  file_name = "p02_i_v.rds"
)

# Plot: p03_i_d_s [= Indice di dipendenza strutturale] ----
p03_i_d_s <- f_plot_indicatore_demografico(
  dataset = data1,
  indicatore = "Indice di dipendenza strutturale",
  udm = "% tra popolazione in età non attiva (0-14 e 65+ anni) e in età attiva (15-64 anni)",
  save_plot = TRUE,
  file_name = "p03_i_d_s.rds"
)

# Plot: p04_i_d_a [= Indice di dipendenza anziani] ----
p04_i_d_a <- f_plot_indicatore_demografico(
  dataset = data1,
  indicatore = "Indice di dipendenza anziani",
  udm = "% tra popolazione di 65+ e in età attiva (15-64 anni)",
  save_plot = TRUE,
  file_name = "p04_i_d_a.rds"
)

# 2. Classi di età (dataset: indicatori_struttura_popolazione) ------------
data2 <- f_load_and_prepare_rds("indicatori_struttura_popolazione")

# Plot: p06_0_14_anni ----
p06_0_14_anni <- f_plot_indicatore_demografico(
  dataset = data2,
  indicatore = "0-14 anni",
  udm = "% della popolazione per classe di età",
  save_plot = TRUE,
  file_name = "p06_0_14_anni.rds"
)

# Plot: p06_15_64_anni ----
p06_15_64_anni <- f_plot_indicatore_demografico(
  dataset = data2,
  indicatore = "15-64 anni",
  udm = "% della popolazione per classe di età",
  save_plot = TRUE,
  file_name = "p06_15_64_anni.rds"
)

# Plot: p06_65piu_anni ----
p06_65piu_anni <- f_plot_indicatore_demografico(
  dataset = data2,
  indicatore = "65 anni e oltre",
  udm = "% della popolazione per classe di età",
  save_plot = TRUE,
  file_name = "p06_65piu_anni.rds"
)

# 3. Indicatori singoli (un rds ciascuno, da 01_dati.R) -------------------

# Plot: p07_crescita_naturale ----
p07_crescita_naturale <- f_plot_indicatore_demografico(
  dataset = f_load_and_prepare_rds("crescita_naturale"),
  indicatore = "crescita_naturale", # nome nel df
  udm = "differenza tra il tasso di natalità e il tasso di mortalità",
  save_plot = TRUE,
  file_name = "p07_crescita_naturale.rds"
)

# Plot: p08_età_media_al_parto ----
p08_età_media_al_parto <- f_plot_indicatore_demografico(
  dataset = f_load_and_prepare_rds("età_media_al_parto"),
  indicatore = "età_media_al_parto",
  udm = "anni e decimi di anno",
  save_plot = TRUE,
  file_name = "p08_età_media_al_parto.rds"
)

# Plot: p09_quoziente_di_mortalità ----
p09_quoziente_di_mortalità <- f_plot_indicatore_demografico(
  dataset = f_load_and_prepare_rds("quoziente_di_mortalità"),
  indicatore = "quoziente_di_mortalità",
  udm = "rapporto num. decessi nell'anno e num. medio popolazione residente per 1.000",
  save_plot = TRUE,
  file_name = "p09_quoziente_di_mortalità.rds"
)

# Plot: p10_quoziente_di_natalità ----
p10_quoziente_di_natalità <- f_plot_indicatore_demografico(
  dataset = f_load_and_prepare_rds("quoziente_di_natalità"),
  indicatore = "quoziente_di_natalità",
  udm = "rapporto num. nati vivi nell'anno e num. medio popolazione residente per 1.000",
  save_plot = TRUE,
  file_name = "p10_quoziente_di_natalità.rds"
)

# Plot: p11_quoziente_di_nuzialità ----
p11_quoziente_di_nuzialità <- f_plot_indicatore_demografico(
  dataset = f_load_and_prepare_rds("quoziente_di_nuzialità"),
  indicatore = "quoziente_di_nuzialità",
  udm = "rapporto num. matrimoni celebrati nell'anno e num. medio popolazione residente per 1.000",
  save_plot = TRUE,
  file_name = "p11_quoziente_di_nuzialità.rds"
)

# Plot: p12_saldo_migratorio_totale ----
p12_saldo_migratorio_totale <- f_plot_indicatore_demografico(
  dataset = f_load_and_prepare_rds("saldo_migratorio_totale"),
  indicatore = "saldo_migratorio_totale",
  udm = "differenza tra num. iscritti ed num. cancellati dai registri anagrafici per trasferimento di residenza",
  save_plot = TRUE,
  file_name = "p12_saldo_migratorio_totale.rds"
)

# Plot: p13_saldo_migratorio_interno ----
p13_saldo_migratorio_interno <- f_plot_indicatore_demografico(
  dataset = f_load_and_prepare_rds("saldo_migratorio_interno"),
  indicatore = "saldo_migratorio_interno",
  udm = "differenza tra num. iscritti e num. cancellati per trasferimento di residenza da/verso altro Comune",
  save_plot = TRUE,
  file_name = "p13_saldo_migratorio_interno.rds"
)

# Plot: p14_saldo_migratorio_con_l_estero ----
p14_saldo_migratorio_con_l_estero <- f_plot_indicatore_demografico(
  dataset = f_load_and_prepare_rds("saldo_migratorio_con_l_estero"),
  indicatore = "saldo_migratorio_con_l_estero",
  udm = "rapporto tra il saldo migratorio con l'estero dell'anno e l'ammontare medio della popolazione residente per 1.000.",
  save_plot = TRUE,
  file_name = "p14_saldo_migratorio_con_l_estero.rds"
)

# Plot: p15_speranza_di_vita_0 ----
p15_speranza_di_vita_0 <- f_plot_indicatore_demografico(
  dataset = f_load_and_prepare_rds("speranza_di_vita_0"),
  indicatore = "speranza_di_vita_0",
  udm = "numero medio di anni che restano da vivere a un neonato",
  save_plot = TRUE,
  file_name = "p15_speranza_di_vita_0.rds"
)

# Plot: p16_speranza_di_vita_65 ----
p16_speranza_di_vita_65 <- f_plot_indicatore_demografico(
  dataset = f_load_and_prepare_rds("speranza_di_vita_65"),
  indicatore = "speranza_di_vita_65",
  udm = "numero medio di anni che restano da vivere a 65 anni",
  save_plot = TRUE,
  file_name = "p16_speranza_di_vita_65.rds"
)

# Plot: p17_tasso_di_crescita_totale ----
p17_tasso_di_crescita_totale <- f_plot_indicatore_demografico(
  dataset = f_load_and_prepare_rds("tasso_di_crescita_totale"),
  indicatore = "tasso_di_crescita_totale",
  udm = "somma tasso di crescita naturale + tasso migratorio totale",
  save_plot = TRUE,
  file_name = "p17_tasso_di_crescita_totale.rds"
)

# Plot: p18_tasso_di_fecondità_totale ----
p18_tasso_di_fecondità_totale <- f_plot_indicatore_demografico(
  dataset = f_load_and_prepare_rds("tasso_di_fecondità_totale"),
  indicatore = "tasso_di_fecondità_totale",
  udm = "Numero medio di figli per donna in età fertile (15-49 anni)",
  save_plot = TRUE,
  file_name = "p18_tasso_di_fecondità_totale.rds"
)

