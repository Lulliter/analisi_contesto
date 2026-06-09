# ---------- PULIZIA FILE EXCEL TREND DEMOGRAFICI ISTAT (2002-2024 per prov) ------------
# Plot each indicator over the years comparing the three territories in tidy_data_pr_er_it

# Packgs and functions ----
library(here)
library(fs)
library(dplyr)
library(tidyr)
library(readxl)
library(janitor)
library(skimr)
library(forcats)
library(glue)
library(stringr)
library(ggplot2)
library(ggiraph)
library(patchwork) # for combining ggplots
# p1 + p2                    # Affiancati
# p1 / p2                    # Uno sopra l'altro
# p1 | p2                    # Affiancati (equivalente a +)
# (p1 + p2) / p3             # Layout complesso
# p1 + p2 + plot_layout(ncol = 2)  # Specificare colonne

dir_rds <- here::here("data", "data_out", "istat_demo_2002_2024")
dir_plots <- here::here("data", "plots")

# Colors ----
grey_extra_sc <- "#4F4F4F"
grey_sc <- "#808080"
grey_md1 <- "#A9A9A9"
grey_md2 <- "#D3D3D3"
grey_extrlight <- "#FDFBF7"
burg_sc <- "#5C2129"
burg_md <- "#873C4A"
burg_lg <- "#B85E6A"
blu_sc <- "#033c55"
blu_md <- "#005d82"
blu_lg <- "#5582a7"
grn_sc <- "#246864"
grn_md <- "#539d90"
grn_lg <- "#8eb9b1"

# --- 📂 Load dataset 1) ----
indicatori_di_struttura <- readRDS(fs::path(
  dir_rds,
  "indicatori_di_struttura.rds"
))

tabyl(indicatori_di_struttura$indicatore)

# ---- Prepare data 1) for plotting (indicatori_di_struttura) ----
data <- indicatori_di_struttura |>
  dplyr::filter(
    territorio %in%
      c(
        "Bologna",
        "Piacenza",
        "Parma",
        "Reggio nell'Emilia",
        "Modena",
        "Ferrara",
        "Ravenna",
        "Forli'",
        "Rimini",
        "Emilia-Romagna",
        "NORD-EST",
        "ITALIA"
      )
  ) |>
  dplyr::mutate(
    highlight = territorio %in%
      c("Parma", "Emilia-Romagna", "NORD-EST", "ITALIA"),
    territorio_display = ifelse(highlight, territorio, "Altre provincie ER")
  ) |>
  #maintain
  dplyr::mutate(
    territorio_display = factor(
      territorio_display,
      levels = c("Parma", "Emilia-Romagna", "NORD-EST", "ITALIA", "Altre provincie ER")
    ),
    highlight = factor(highlight)
  )

sample_n(data, 10)

# 🟩🟪 SENZA Funzione Wrapper ------

# Arguments for plot
INDICATORE <- "Età media"
UDM <- "anni e decimi di anno"
TITLE <- glue("Trend demografici: {INDICATORE}")
SUBTIT <- glue("Indicatore espresso in: {UDM}")
CAP <- "Fonte: Istat, Demografia in cifre, Nov. 2025 | Rielaborazione: Fondazione Cariparma"

# ---- Make plot ----
# Plot: p01_e_m [= Età Media]  ----
p01_e_m <- data |>
  dplyr::filter(indicatore == INDICATORE) |>
  filter(territorio != "NORD-EST", territorio != "Altre provincie ER") |>
  # plot
  ggplot(aes(
    x = anno,
    y = valore,
    color = territorio_display,
    alpha = highlight,
    group = territorio
  )) +
  # (FUNZIONA CON ggiraph)
  geom_line_interactive(
    aes(
      tooltip = territorio,
      data_id = gsub("'", "", territorio)
    ),
    linewidth = rel(0.8)
  ) +
  # (FUNZIONA CON ggiraph) Linea più spessa per Parma ed Emilia-Romagna
  geom_line_interactive(
    data = \(df) df |> filter(territorio %in% c("Parma", "Emilia-Romagna")),
    aes(
      tooltip = territorio,
      data_id = gsub("'", "", territorio)
    ),
    linewidth = rel(1.5)
  ) +
  # x axis
  scale_x_continuous(
    breaks = seq(min(data$anno), max(data$anno), by = 1),
    limits = c(min(data$anno), max(data$anno)),
    expand = expansion(mult = c(0.02, 0.02)) # Riduce lo spazio ai margini
  ) +
  # ????
  scale_alpha_manual(values = c(0.3, 1), guide = "none") +
  scale_color_manual(
    values = c(
      "Parma" = burg_md,
      "Emilia-Romagna" = grn_md,
      "ITALIA" = blu_md
    )
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.major = element_line(color = "grey90", linewidth = rel(0.3)),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1, size = rel(0.85)),
    axis.text.y = element_text(size = rel(0.85)),
    axis.title = element_text(size = rel(1), face = "bold"),
    plot.title = element_text(
      size = rel(1.3),
      face = "bold",
      margin = margin(b = 10)
    ),
    strip.text = element_text(size = rel(1.1), face = "bold"),
    legend.text = element_text(size = rel(0.9)),
    legend.title = element_blank(),
    legend.position = "bottom",
    panel.spacing = unit(1, "lines")
  ) +
  labs(
    title = TITLE,
    subtitle = SUBTIT,
    caption = CAP,
    x = "",
    y = ""
  )

p01_e_m

# Save plot as .rds ----
saveRDS(object = p01_e_m, file = here::here("data", "plots", "p01_e_m.rds"))
# ggsave(
#   filename = fs::path(dir_plots, glue("p01_e_m",".png")),
#   plot = p01_e_m,
#   width = 8,
#   height = 7,
#   units = "in",
#   dpi = 300
#   )

# [POI] read back into env
# p01_e_m <-  readRDS(p01_e_m, here::here("dir_plots", "p01_e_m.rds"))

# 🟨🟩 CON Funzione Wrapper (Dataset 1) ------
# Presuppone un dataframe già pulito

# FUNZIONE che CREA + SALVARE plot con altri indicatori ---------
plot_indicatore_demografico <- function(
  indicatore,
  udm,
  dataset = NULL, # il df di partenza
  title = NULL,
  subtitle = NULL,
  caption = "Fonte: Istat, Demografia in cifre, Nov. 2025 | Rielaborazione: Fondazione Cariparma",
  save_plot = FALSE,
  file_name = NULL
) {
  # Se dataset non è fornito, usa 'data' dall'ambiente globale
  if (is.null(dataset)) {
    dataset <- data
  }

  # Genera title e subtitle se non forniti
  if (is.null(title)) {
    # Riformatta il nome dell'indicatore per il titolo (es. "quoziente_di_natalità"
    # → "Quoziente di natalità"). Non incide sul filter, che usa il valore raw.
    indicatore_pretty <- stringr::str_replace_all(indicatore, "_", " ") |>
      stringr::str_to_sentence()
    title <- glue("Trend demografici: {indicatore_pretty}")
  }
  if (is.null(subtitle)) {
    # Use str_wrap to wrap subtitle based on character count
    # Width calibrated for fig-width: 9 inches (typical Quarto HTML output)
    # ~120 chars fits comfortably within plot panel width
    subtitle <- glue("Indicatore espresso in: {udm}") |>
      stringr::str_wrap(width = 120)
  }

  # Crea il plot
  p <- dataset |>
    dplyr::filter(indicatore == !!indicatore) |>
    filter(territorio != "NORD-EST", territorio != "Altre provincie ER") |>
    # plot
    ggplot(aes(
      x = anno,
      y = valore,
      color = territorio_display,
      alpha = highlight,
      group = territorio
    )) +
    geom_line_interactive(
      aes(
        tooltip = territorio,
        data_id = gsub("'", "", territorio)
      ),
      linewidth = rel(0.8)
    ) +
    # Linea più spessa per Parma ed Emilia-Romagna
    geom_line_interactive(
      data = \(df) df |> filter(territorio %in% c("Parma", "Emilia-Romagna")),
      aes(
        tooltip = territorio,
        data_id = gsub("'", "", territorio)
      ),
      linewidth = rel(1.5)
    ) +
    # x axis
    scale_x_continuous(
      breaks = seq(min(dataset$anno), max(dataset$anno), by = 1),
      limits = c(min(dataset$anno), max(dataset$anno)),
      expand = expansion(mult = c(0.02, 0.02))
    ) +
    scale_alpha_manual(values = c(0.3, 1), guide = "none") +
    scale_color_manual(
      values = c(
        "Parma" = burg_md,
        "Emilia-Romagna" = grn_md,
        "NORD-EST" = blu_lg,
        "ITALIA" = blu_md,
        "Altre provincie ER" = "grey50"
      )
    ) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid.major = element_line(color = "grey90", linewidth = rel(0.3)),
      panel.grid.minor = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, size = rel(0.85)),
      axis.text.y = element_text(size = rel(0.85)),
      axis.title = element_text(size = rel(1), face = "bold"),
      plot.title = element_text(
        size = rel(1.3),
        face = "bold",
        margin = margin(b = 10)
      ),
      plot.subtitle = element_text(
        size = rel(0.95),
        lineheight = 1.2,
        margin = margin(b = 10)
      ),
      strip.text = element_text(size = rel(1.1), face = "bold"),
      legend.text = element_text(size = rel(0.9)),
      legend.title = element_blank(),
      legend.position = "bottom",
      panel.spacing = unit(1, "lines")
    ) +
    labs(
      title = title,
      subtitle = subtitle,
      caption = caption,
      x = "",
      y = ""
    )

  # Salva il plot se richiesto
  if (save_plot) {
    if (is.null(file_name)) {
      file_name <- glue("plot_{janitor::make_clean_names(indicatore)}.rds")
    }
    saveRDS(object = p, file = here::here("data", "plots", file_name))
    message(glue("Plot salvato in: data/plots/{file_name}"))
  }

  return(p)
}


# ==============================================================================
# USO di FUNZIONE ----
# ==============================================================================
# # Plot:p01_e_m [ = Età Media] ----
# p01_e_m <- plot_indicatore_demografico(
#   indicatore = "Età Media",
#   udm = "Anni e decimi di anno.",
#   save_plot = TRUE,
#   file_name = "p01_e_m.rds"
# )
# p01_e_m

# Plot: p02_i_v [ = Indice di vecchiaia] ----
p02_i_v <- plot_indicatore_demografico(
  dataset = data,
  indicatore = "Indice di vecchiaia",
  udm = "% tra popolazione di 65+ anni e in età 0-14.",
  save_plot = TRUE,
  file_name = "p02_i_v.rds"
)
p02_i_v

# Plot: p03_i_d_s [ = Indice di dipendenza strutturale] ----
p03_i_d_s <- plot_indicatore_demografico(
  dataset = data,
  indicatore = "Indice di dipendenza strutturale",
  udm = "% tra popolazione in età non attiva (0-14 e 65+ anni) e in età attiva (15-64 anni)",
  save_plot = TRUE,
  file_name = "p03_i_d_s.rds"
)
p03_i_d_s

# Plot: p04_i_d_a  [= Indice di dipendenza anziani] ----
p04_i_d_a <- plot_indicatore_demografico(
  dataset = data,
  indicatore = "Indice di dipendenza anziani",
  udm = "% tra popolazione di 65+ e in età attiva (15-64 anni)",
  save_plot = TRUE,
  file_name = "p04_i_d_a.rds"
)
p04_i_d_a


# 🟨🟩 CON Funzione Wrapper (Dataset 2)------
# --- 📂 Load dataset 2) ----
indicatori_struttura_pop <- readRDS(fs::path(
  dir_rds,
  "indicatori_struttura_popolazione.rds"
))

tabyl(indicatori_struttura_pop$indicatore)
# ---- Prepare data 2) for plotting (indicatori_di_struttura) ----
data2 <- indicatori_struttura_pop |>
  dplyr::filter(
    territorio %in%
      c(
        "Bologna",
        "Piacenza",
        "Parma",
        "Reggio nell'Emilia",
        "Modena",
        "Ferrara",
        "Ravenna",
        "Forli'",
        "Rimini",
        "Emilia-Romagna",
        "NORD-EST",
        "ITALIA"
      )
  ) |>
  dplyr::mutate(
    highlight = territorio %in%
      c("Parma", "Emilia-Romagna", "NORD-EST", "ITALIA"),
    territorio_display = ifelse(highlight, territorio, "Altre provincie ER")
  ) |>
  #maintain
  dplyr::mutate(
    territorio_display = factor(
      territorio_display,
      levels = c("Parma", "Emilia-Romagna", "NORD-EST", "ITALIA", "Altre provincie ER")
    ),
    highlight = factor(highlight)
  )

sample_n(data2, 10)


# 🟨🟩 CON Funzione Wrapper ------
# Arguments for next 3 plots ----
tabyl(indicatori_struttura_pop$indicatore)

CAP <- "Fonte: Istat, Demografia in cifre, Nov. 2025 | Rielaborazione: Fondazione Cariparma"
# OTUPUT_DIR_DEFAULT = "data", "plots", file_name

# Plot: p06_0_14_anni [% classe di età 0-14 anni] ----
p06_0_14_anni <- plot_indicatore_demografico(
  dataset = data2,
  indicatore = "0-14 anni",
  udm = "% della popolazione per classe di età",
  title = NULL,
  subtitle = NULL,
  caption = CAP,
  save_plot = TRUE,
  file_name = "p06_0_14_anni.rds"
)

p06_0_14_anni

# Plot: p06_15_64_anni [% classe di età 15-64 anni] ----
p06_15_64_anni <- plot_indicatore_demografico(
  dataset = data2,
  indicatore = "15-64 anni",
  udm = "% della popolazione per classe di età",
  title = NULL,
  subtitle = NULL,
  caption = CAP,
  save_plot = TRUE,
  file_name = "p06_15_64_anni.rds"
)

p06_15_64_anni

# Plot: p06_65piu_anni [% classe di età 65 anni e oltre] ----
p06_65piu_anni <- plot_indicatore_demografico(
  dataset = data2,
  indicatore = "65 anni e oltre",
  udm = "% della popolazione per classe di età",
  title = NULL,
  subtitle = NULL,
  caption = CAP,
  save_plot = TRUE,
  file_name = "p06_65piu_anni.rds"
)

p06_65piu_anni

# 🟨🟩🟧 CON FUNZIONE PREP + Funzione Wrapper (Dataset 3 ecc )------

# FUNZIONE che PREPARA DATASETS x altri indicatori (singoli) ---------
# Carica e prepara singolo RDS file per plotting ----
#' Carica e prepara un singolo RDS file con filtro territori
#'
#' @param rds_file Nome del file RDS (con o senza estensione .rds)
#' @param dir_rds Directory contenente il file RDS
#' @param territori_filtro Vettore di territori da includere nel filtro
#' @param territori_highlight Vettore di territori da evidenziare
#'
#' @return Dataframe preparato
#' @export
#'
#' @examples
#' dir_rds <- here::here("data", "data_out", "istat_demo_2002_2024")
#' crescita_naturale <- load_and_prepare_rds("crescita_naturale.rds", dir_rds)
load_and_prepare_rds <- function(
  rds_file,
  dir_rds,
  territori_filtro = c(
    "Bologna",
    "Piacenza",
    "Parma",
    "Reggio nell'Emilia",
    "Modena",
    "Ferrara",
    "Ravenna",
    "Forli'",
    "Rimini",
    "Emilia-Romagna",
    "NORD-EST",
    "ITALIA"
  ),
  territori_highlight = c("Parma", "Emilia-Romagna", "NORD-EST", "ITALIA")
) {
  # Assicurati che il file abbia estensione .rds
  if (!grepl("\\.rds$", rds_file, ignore.case = TRUE)) {
    rds_file <- paste0(rds_file, ".rds")
  }
  # Path completo al file
  file_path <- fs::path(dir_rds, rds_file)
  # Verifica esistenza file
  if (!file.exists(file_path)) {
    stop(glue::glue("File non trovato: {file_path}"))
  }
  # Nome base del file
  basename_no_ext <- gsub("\\.rds$", "", basename(rds_file), ignore.case = TRUE)
  # Carica il file RDS
  message(glue::glue("# --- Load dataset: {basename_no_ext} ----"))
  df <- readRDS(file_path)
  # Applica la trasformazione standard
  df_prepared <- df |>
    dplyr::filter(territorio %in% territori_filtro) |>
    dplyr::mutate(
      highlight = territorio %in% territori_highlight,
      territorio_display = ifelse(highlight, territorio, "Altre provincie ER")
    ) |>
    dplyr::mutate(
      territorio_display = factor(
        territorio_display,
        levels = c(territori_highlight, "Altre provincie ER")
      ),
      highlight = factor(highlight)
    )

  return(df_prepared)
}


# --- 📂  📂  Load datasets for indiv indic ecc ) ----
# crescita_naturale <- readRDS(fs::path(
#   dir_rds,
#   "crescita_naturale.rds"
# ))
#
# glimpse(crescita_naturale)
# crescita_naturale$indicatore
#
# # Preparazione dati per il plotting ----
# data3 <- crescita_naturale |>
#   dplyr::filter(
#     territorio %in%
#       c(
#         "Bologna",
#         "Piacenza",
#         "Parma",
#         "Reggio nell'Emilia",
#         "Modena",
#         "Ferrara",
#         "Ravenna",
#         "Forli'",
#         "Rimini",
#         "Emilia-Romagna",
#         "NORD-EST",
#         "ITALIA"
#       )
#   ) |>
#   dplyr::mutate(
#     highlight = territorio %in%
#       c("Parma", "Emilia-Romagna", "NORD-EST", "ITALIA"),
#     territorio_display = ifelse(highlight, territorio, "Altre provincie ER")
#   ) |>
#   #maintain
#   dplyr::mutate(
#     territorio_display = factor(
#       territorio_display,
#       levels = c("Parma", "Emilia-Romagna", "NORD-EST", "ITALIA", "Altre provincie ER")
#     ),
#     highlight = factor(highlight)
#   )

# list all files in dir_rds (no indicatori* )-----
fs::dir_ls(dir_rds)

# crescita_naturale.rds
# età_media_al_parto.rds
# quoziente_di_mortalità.rds
# quoziente_di_natalità.rds
# quoziente_di_nuzialità.rds
# saldo_migratorio_altro_motivo.rds
# saldo_migratorio_con_l_estero.rds
# saldo_migratorio_interno.rds
# saldo_migratorio_totale.rds
# speranza_di_vita_0.rds
# speranza_di_vita_65.rds
# tasso_di_crescita_totale.rds
# tasso_di_fecondità_totale.rds

# Prep & Plot with 2 FUNCTIONS ----
# Arguments for next n  plots ----
CAP <- "Fonte: Istat, Demografia in cifre, Nov. 2025 | Rielaborazione: Fondazione Cariparma"
# OTUPUT_DIR_DEFAULT = "data", "plots", file_name
# udm = da specificare ....

# Plot: p07_crescita_naturale -----
# Load & prep
crescita_naturale_rdx <- load_and_prepare_rds(
  rds_file = "crescita_naturale.rds",
  dir_rds = dir_rds
)
# Plot & save
p07_crescita_naturale <- plot_indicatore_demografico(
  dataset = crescita_naturale_rdx,
  indicatore = "crescita_naturale", # nome nel df
  udm = "differenza tra il tasso di natalità e il tasso di mortalità",
  title = NULL, # comune
  subtitle = NULL,
  caption = CAP, # comune
  save_plot = TRUE,
  file_name = "p07_crescita_naturale.rds"
)

# Plot: p08_età_media_al_parto -----
# Load & prep
età_media_al_parto_rdx <- load_and_prepare_rds(
  rds_file = "età_media_al_parto.rds",
  dir_rds = dir_rds
)
# Plot & save
p08_età_media_al_parto <- plot_indicatore_demografico(
  dataset = età_media_al_parto_rdx,
  indicatore = "età_media_al_parto", # nome nel df
  udm = "anni e decimi di anno",
  title = NULL, # comune
  subtitle = NULL,
  caption = CAP, # comune
  save_plot = TRUE,
  file_name = "p08_età_media_al_parto.rds"
)

# Plot: p09_quoziente_di_mortalità -----
# Load & prep
quoziente_di_mortalità_rdx <- load_and_prepare_rds(
  rds_file = "quoziente_di_mortalità.rds",
  dir_rds = dir_rds
)
# Plot & save
p09_quoziente_di_mortalità <- plot_indicatore_demografico(
  dataset = quoziente_di_mortalità_rdx,
  indicatore = "quoziente_di_mortalità", # nome nel df
  udm = "rapporto num. decessi nell'anno e num. medio popolazione residente per 1.000",
  title = NULL, # comune
  subtitle = NULL,
  caption = CAP, # comune
  save_plot = TRUE,
  file_name = "p09_quoziente_di_mortalità.rds"
)

# Plot: p10_quoziente_di_natalità -----
# Load & prep
quoziente_di_natalità_rdx <- load_and_prepare_rds(
  rds_file = "quoziente_di_natalità.rds",
  dir_rds = dir_rds
)
# Plot & save
p10_quoziente_di_natalità <- plot_indicatore_demografico(
  dataset = quoziente_di_natalità_rdx,
  indicatore = "quoziente_di_natalità", # nome nel df
  udm = "rapporto num. nati vivi nell'anno e num. medio popolazione residente per 1.000",
  title = NULL, # comune
  subtitle = NULL,
  caption = CAP, # comune
  save_plot = TRUE,
  file_name = "p10_quoziente_di_natalità.rds"
)

# Plot: p11_quoziente_di_nuzialità -----
# Load & prep
quoziente_di_nuzialità_rdx <- load_and_prepare_rds(
  rds_file = "quoziente_di_nuzialità.rds",
  dir_rds = dir_rds
)
# Plot & save
p11_quoziente_di_nuzialità <- plot_indicatore_demografico(
  dataset = quoziente_di_nuzialità_rdx,
  indicatore = "quoziente_di_nuzialità", # nome nel df
  udm = "rapporto num. matrimoni celebrati nell'anno e num. medio popolazione residente per 1.000",
  title = NULL, # comune
  subtitle = NULL,
  caption = CAP, # comune
  save_plot = TRUE,
  file_name = "p11_quoziente_di_nuzialità.rds"
)

# Plot: p12_saldo_migratorio -----
# Load & prep
saldo_migratorio_totale_rdx <- load_and_prepare_rds(
  rds_file = "saldo_migratorio_totale.rds",
  dir_rds = dir_rds
)
# Plot & save
p12_saldo_migratorio_totale <- plot_indicatore_demografico(
  dataset = saldo_migratorio_totale_rdx,
  indicatore = "saldo_migratorio_totale", # nome nel df
  udm = "differenza tra num. iscritti ed num. cancellati dai registri anagrafici per trasferimento di residenza",
  title = NULL, # comune
  subtitle = NULL,
  caption = CAP, # comune
  save_plot = TRUE,
  file_name = "p12_saldo_migratorio_totale.rds"
)

# Plot: p13_saldo_migratorio_interno -----
# Load & prep
saldo_migratorio_interno_rdx <- load_and_prepare_rds(
  rds_file = "saldo_migratorio_interno.rds",
  dir_rds = dir_rds
)
# Plot & save
p13_saldo_migratorio_interno <- plot_indicatore_demografico(
  dataset = saldo_migratorio_interno_rdx,
  indicatore = "saldo_migratorio_interno", # nome nel df
  udm = "differenza tra num. iscritti e num. cancellati per trasferimento di residenza da/verso altro Comune",
  title = NULL, # comune
  subtitle = NULL,
  caption = CAP, # comune
  save_plot = TRUE,
  file_name = "p13_saldo_migratorio_interno.rds"
)

# Plot: p14_saldo_migratorio_con_l_estero -----
# Load & prep
saldo_migratorio_con_l_estero_rdx <- load_and_prepare_rds(
  rds_file = "saldo_migratorio_con_l_estero.rds",
  dir_rds = dir_rds
)
# Plot & save
p14_saldo_migratorio_con_l_estero <- plot_indicatore_demografico(
  dataset = saldo_migratorio_con_l_estero_rdx,
  indicatore = "saldo_migratorio_con_l_estero", # nome nel df
  udm = "rapporto tra il saldo migratorio con l’estero dell’anno e l’ammontare medio della popolazione residente per 1.000.",
  title = NULL, # comune
  subtitle = NULL,
  caption = CAP, # comune
  save_plot = TRUE,
  file_name = "p14_saldo_migratorio_con_l_estero.rds"
)

# Plot: p15_speranza_di_vita_0 -----
# Load & prep
speranza_di_vita_0_rdx <- load_and_prepare_rds(
  rds_file = "speranza_di_vita_0.rds",
  dir_rds = dir_rds
) |>
  dplyr::filter(sotto_categoria == "Maschi e femmine") # Filtra solo totale

# Plot & save
p15_speranza_di_vita_0 <- plot_indicatore_demografico(
  dataset = speranza_di_vita_0_rdx,
  indicatore = "speranza_di_vita_0", # nome nel df
  udm = "numero medio di anni che restano da vivere a un neonato",
  title = NULL, # comune
  subtitle = NULL,
  caption = CAP, # comune
  save_plot = TRUE,
  file_name = "p15_speranza_di_vita_0.rds"
)

# Plot: p16_speranza_di_vita_65 -----
# Load & prep
speranza_di_vita_65_rdx <- load_and_prepare_rds(
  rds_file = "speranza_di_vita_65.rds",
  dir_rds = dir_rds
) |>
  dplyr::filter(sotto_categoria == "Maschi e femmine") # Filtra solo totale

# Plot & save
p16_speranza_di_vita_65 <- plot_indicatore_demografico(
  dataset = speranza_di_vita_65_rdx,
  indicatore = "speranza_di_vita_65", # nome nel df
  udm = "numero medio di anni che restano da vivere a 65 anni",
  title = NULL, # comune
  subtitle = NULL,
  caption = CAP, # comune
  save_plot = TRUE,
  file_name = "p16_speranza_di_vita_65.rds"
)

# Plot: p17_tasso_di_crescita_totale -----
# Load & prep
tasso_di_crescita_totale_rdx <- load_and_prepare_rds(
  rds_file = "tasso_di_crescita_totale.rds",
  dir_rds = dir_rds
)
# Plot & save
p17_tasso_di_crescita_totale <- plot_indicatore_demografico(
  dataset = tasso_di_crescita_totale_rdx,
  indicatore = "tasso_di_crescita_totale", # nome nel df
  udm = "somma tasso di crescita naturale + tasso migratorio totale",
  title = NULL, # comune
  subtitle = NULL,
  caption = CAP, # comune
  save_plot = TRUE,
  file_name = "p17_tasso_di_crescita_totale.rds"
)

# Plot: p18_tasso_di_fecondità_totale -----
# Load & prep
tasso_di_fecondità_totale_rdx <- load_and_prepare_rds(
  rds_file = "tasso_di_fecondità_totale.rds",
  dir_rds = dir_rds
)
# Plot & save
p18_tasso_di_fecondità_totale <- plot_indicatore_demografico(
  dataset = tasso_di_fecondità_totale_rdx,
  indicatore = "tasso_di_fecondità_totale", # nome nel df
  udm = "Numero medio di figli per donna in età fertile (15-49 anni)",
  title = NULL, # comune
  subtitle = NULL,
  caption = CAP, # comune
  save_plot = TRUE,
  file_name = "p18_tasso_di_fecondità_totale.rds"
)
