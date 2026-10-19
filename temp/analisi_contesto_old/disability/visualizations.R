# Visualizzazioni GALI (Global Activity Limitation Indicator) ----
# Flexible visualization functions for disability data analysis
# All plots are designed to work with some combination of:
#   - dataset (gali_all, gali_all_w_ripart, gali_all_compare)
#   - territori (filter for specific regions/ripartizioni)
#   - classe_eta (age classes)
#   - limitazioni (limitation levels)

library(here)
library(ggplot2)
library(dplyr)
library(tidyr)
library(sf)
library(scales)
library(ggiraph)  # For interactive maps


# 1. LOAD DATASETS ----


# __ Load main datasets created by data_load.R ----
# -- Solo regioni
# gali_all <- readRDS(here(
#   "data/data_out/istat_GALI_2023/gali_all.rds"
# ))
# -- Regioni + ripartizioni (calcolate come media regioni)
gali_all_w_ripart <- readRDS(here(
  "data/data_out/istat_GALI_2023/gali_all_w_ripart.rds"
))
# -- Regioni + ripartizioni con classi d'età/limitazione accorpate
gali_all_w_ripart_clps <- readRDS(here(
  "data/data_out/istat_GALI_2023/gali_all_w_ripart_clps.rds"
))

# __ Load shapefile for maps ----
regioni_ita <- readRDS(here("data/data_out/ITA_shp/regioni_ita_full.rds"))

# Simplify geometry to reduce file size (especially for interactive maps)
regioni_ita <- sf::st_simplify(regioni_ita, preserveTopology = TRUE, dTolerance = 500)

# Fix name mismatch: shapefile has hyphen, data doesn't
regioni_ita <- regioni_ita %>%
  mutate(territorio = gsub("Trentino-Alto Adige", "Trentino Alto Adige", territorio))

# 2. THEME & COLORS ----
theme_gali <- function() {
  theme_minimal() +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11, color = "gray30"),
      axis.text = element_text(size = 10),
      axis.title = element_text(size = 11, face = "bold"),
      legend.position = "top",
      legend.title = element_text(size = 10, face = "bold"),
      panel.grid.minor = element_blank()
    )
}

# Color palettes
colori_eta_2 <- c(
  "65-74 anni" = "#4575b4",
  "75+ anni" = "#d73027"
)

# # install.packages("devtools")
# devtools::install_github("thomasp85/scico")
# library(scico)
# scico_palette_show()
# > scico(6, palette = 'cork')
# [1] "#2C194C" "#3D6B98" "#ACC0D3" "#B7CEB7" "#438041" "#0E2802"
# > scico(6, palette = 'davos')
# [1] "#00054A" "#224A8C" "#537D9B" "#849E88" "#D3DAA7" "#FEFEFE"
# scico(6, palette = 'tokio')
# [1] "#2D004B" "#5A4FA3" "#A3C0E4" "#E4D2A3" "#E48C5A" "#B30000"
#  
# scico(6, palette = 'vik')
# [1] "#081D58" "#253494" "#4D92C6" "#92C5DE" "#D1E5F0" "#F7FBFF"
# scico(6, palette = 'davos')
# [1] "#00054A" "#224A8C" "#537D9B" "#849E88" "#D3DAA7" "#FEFEFE"
# scico(6, palette = 'greyC')
# [1] "#000000" "#404040" "#7F7F7F" "#BFBFBF" "#E5E5E5" "#FFFFFF"

# Choose colors from scico palettes for ages 
 

colori_eta_5 <- c(
  "0-44 anni" = "#c7e9b4",
  "45-64 anni" = "#7fcdbb",
  "65-74 anni" =  "#41b6c4", 
  "Anziani (65+)" = "#1d91c0",  # a metà tra 65-74 e 75+
  "75+ anni" = "#225ea8",

  "Tutte le età" = "#7F7F7F" 
)

colori_limitazioni <- c(
  "Senza limitazioni" = "#1a9850",
  "Limitazioni non gravi" = "#fee08b",
  "Limitazioni gravi" = "#c93b04",
  "Limitazioni (lieve o grave)" = "#f46d43",  # Orange (between non gravi and gravi)
  "Non indicato" = "#999999"
)


# 3. CONFIGURATION / PARAMETERS ----

# Change these to customize your visualizations

# Which dataset to use?
DATA <- gali_all_w_ripart # Change to gali_all or gali_all_w_ripart as needed

CAPTION <- "Fonte: ISTAT (DisabilitàInCifre)-Multiscopo sulle famiglie: aspetti della vita quotidiana:parte generale (2022/2023)"
# Which territories? (set to NULL to use all in dataset)
TERRITORI <- c(
  "Emilia-Romagna",
  "Veneto",
  "Friuli-Venezia Giulia",
  "Trentino Alto Adige",
  "Lombardia",
  "Nord-est",
  "Nord-ovest",
  "Italia"
)

# Which age classes? (set to NULL for all)
CLASSI_ETA <- c("65-74 anni", "75+ anni") # Or c("0-44 anni", "45-64 anni", "65-74 anni", "75+ anni", "Tutte le età")

# Which limitation level?
LIMITAZIONE <- "Limitazioni gravi" # Or "Senza limitazioni", "Limitazioni non gravi", "Non indicato"

# 4. HELPER FUNCTION: PREPARE DATA ----
prepare_data <- function(
  dataset = DATA,
  territori = TERRITORI,
  classi_eta = CLASSI_ETA,
  limitazione = LIMITAZIONE
) {
  data <- dataset

  # Filter by territori (if specified)
  if (!is.null(territori)) {
    data <- data %>% filter(territorio %in% territori)
  }

  # Filter by age classes (if specified)
  if (!is.null(classi_eta)) {
    data <- data %>% filter(classe_eta %in% classi_eta)
  }

  # Filter by limitation level (if specified)
  if (!is.null(limitazione)) {
    data <- data %>% filter(limitazioni == limitazione)
  }

  return(data)
}


# 5. VISUALIZATION 1: Bar Chart Comparison ----

# Compare territories - automatically detects whether to compare by age class or limitation level

plot_bar_compare <- function(
  dataset = DATA,
  territori = TERRITORI,
  classi_eta = CLASSI_ETA,
  limitazione = LIMITAZIONE
) {
  data <- prepare_data(dataset, territori, classi_eta, limitazione)

  # Detect comparison mode: by age class or by limitation?
  n_classi <- length(unique(data$classe_eta))
  n_limit <- length(unique(data$limitazioni))

  # Decide what to compare by
  compare_by_age <- n_classi > 1

  if (compare_by_age) {
    # Comparing by age classes - show which limitation level(s)
    fill_var <- "classe_eta"
    palette <- colori_eta_5  # Use comprehensive palette (includes collapsed categories)
    fill_label <- "Classe d'età"
    limit_levels <- unique(data$limitazioni)
    if (length(limit_levels) == 1) {
      subtitle <- paste0(limit_levels, " - Confronto per classe d'età")
    } else {
      subtitle <- paste0("Limitazioni: ", paste(limit_levels, collapse = ", "), " - Confronto per classe d'età")
    }
  } else {
    # Comparing by limitation levels - show which age class(es)
    fill_var <- "limitazioni"
    palette <- colori_limitazioni
    fill_label <- "Livello limitazione"
    age_levels <- unique(data$classe_eta)
    if (length(age_levels) == 1) {
      subtitle <- paste0(age_levels, " - Confronto per livello di limitazione")
    } else {
      subtitle <- paste0("Età: ", paste(age_levels, collapse = ", "), " - Confronto per livello di limitazione")
    }
  }

  ggplot(
    data,
    aes(
      x = reorder(territorio, percentuale),
      y = percentuale,
      fill = .data[[fill_var]]
    )
  ) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_text(
      aes(label = sprintf("%.1f%%", percentuale)),
      position = position_dodge(width = 0.8),
      hjust = -0.2,      # Position to the right of bars (after coord_flip)
      size = 3.2,        # Slightly larger
      fontface = "bold"  # Bold for better readability with decimals
    ) +
    scale_fill_manual(values = palette) +
    scale_y_continuous(
      labels = label_percent(scale = 1, accuracy = 0.1),
      expand = expansion(mult = c(0, 0.15))  # More space for labels on the right
    ) +
    coord_flip() +
    labs(
      title = "Incidenza per territorio",
      subtitle = subtitle,
      x = NULL,
      y = "% popolazione",
      fill = fill_label,
      caption = CAPTION
    ) +
    theme_gali()
}

# __ Example usage: ----
# function (dataset = DATA, territori = TERRITORI, classi_eta = CLASSI_ETA, limitazione = LIMITAZIONE)

# Exe 1) Compare specific age classes for specific limitation
plot_bar_compare(
  dataset = DATA, # gali_all_w_ripart
  territori = TERRITORI, # cross territori for comparison
  classi_eta = CLASSI_ETA, # anziani (65+ e 75+)
  limitazione = LIMITAZIONE # limitazione (solo)
)
# Exe 2) Compare all age classes for specific limitation
plot_bar_compare(
  dataset = DATA,
  territori = TERRITORI,
  limitazione = LIMITAZIONE,
  classi_eta = c(
    "0-44 anni",
    "45-64 anni",
    "65-74 anni",
    "75+ anni",
    "Tutte le età"
  )
)
# Exe 3) Compare specific age class for all limitation levels ----
p19_bar_comp_gravi <- plot_bar_compare(
  dataset = DATA,
  territori = c(
    "Emilia-Romagna", "Nord-est",  #"Lombardia",
    "Italia"
  ),
  limitazione = c("Limitazioni gravi"),
  classi_eta = c("65-74 anni", "75+ anni", "Tutte le età"))

p20_bar_comp_lievi <- plot_bar_compare(
  dataset = DATA,
  territori = c(
    "Emilia-Romagna", "Nord-est",  #"Lombardia",
    "Italia"),
  limitazione = c("Limitazioni non gravi"),
  classi_eta = c("65-74 anni", "75+ anni", "Tutte le età"))


# Example  COLLAPSED ----
# Using gali_all_w_ripart_clps to compare collapsed age classes
p21_bar_comp_clps  <- plot_bar_compare(
  dataset = gali_all_w_ripart_clps,
  territori = TERRITORI,
  classi_eta = c("Anziani (65+)", "Tutte le età"),
  limitazione = "Limitazioni (lieve o grave)"
)


# 🟩 Save for later use in dashboard ----
saveRDS(p19_bar_comp_gravi, here("data/plots/p19_bar_comp_gravi.rds"))
saveRDS(p20_bar_comp_lievi, here("data/plots/p20_bar_comp_lievi.rds"))
saveRDS(p21_bar_comp_clps, here("data/plots/p21_bar_comp_clps.rds"))


# 6. VISUALIZATION 2: Faceted Bar Chart ----
# Show each category in separate panel - detects whether to facet by age or limitation
plot_bar_facet <- function(
  dataset = DATA,
  territori = TERRITORI,
  classi_eta = CLASSI_ETA,
  limitazione = LIMITAZIONE
) {
  data <- prepare_data(dataset, territori, classi_eta, limitazione)

  # Detect comparison mode: by age class or by limitation?
  n_classi <- length(unique(data$classe_eta))
  n_limit <- length(unique(data$limitazioni))

  # Decide what to facet by
  facet_by_age <- n_classi > 1

  if (facet_by_age) {
    # Faceting by age classes - show which limitation level(s)
    facet_var <- "classe_eta"
    fill_var <- "classe_eta"
    palette <- colori_eta_5  # Use comprehensive palette (includes collapsed categories)
    limit_levels <- unique(data$limitazioni)
    if (length(limit_levels) == 1) {
      subtitle <- paste0(limit_levels, " - Per territorio e classe d'età")
    } else {
      subtitle <- paste0("Limitazioni: ", paste(limit_levels, collapse = ", "), " - Per territorio e classe d'età")
    }
  } else {
    # Faceting by limitation levels - show which age class(es)
    facet_var <- "limitazioni"
    fill_var <- "limitazioni"
    palette <- colori_limitazioni
    age_levels <- unique(data$classe_eta)
    if (length(age_levels) == 1) {
      subtitle <- paste0(age_levels, " - Per territorio e livello di limitazione")
    } else {
      subtitle <- paste0("Età: ", paste(age_levels, collapse = ", "), " - Per territorio e livello di limitazione")
    }
  }

  ggplot(
    data,
    aes(
      x = reorder(territorio, percentuale),
      y = percentuale,
      fill = .data[[fill_var]]
    )
  ) +
    geom_col(show.legend = FALSE) +
    geom_text(
      aes(label = sprintf("%.1f%%", percentuale)),
      hjust = -0.1,
      size = 3
    ) +
    scale_fill_manual(values = palette) +
    scale_y_continuous(
      labels = label_percent(scale = 1),
      limits = c(0, max(data$percentuale) * 1.15),
      expand = expansion(mult = c(0, 0))
    ) +
    coord_flip() +
    facet_wrap(
      as.formula(paste0("~", facet_var)),
      ncol = 2,
      scales = "free_x"
    ) +
    labs(
      title = "Incidenza per territorio",
      subtitle = subtitle,
      x = NULL,
      y = "% popolazione",
      caption = CAPTION
    ) +
    theme_gali() +
    theme(
      strip.text = element_text(face = "bold", size = 11),
      strip.background = element_rect(fill = "gray90", color = NA)
    )
}

# __ Example usage: ----
# function (dataset = DATA, territori = TERRITORI, classi_eta = CLASSI_ETA,
#     limitazione = LIMITAZIONE)
# NOTE: When using multiple age classes, provide ONLY ONE limitation value
#       to avoid rendering issues. For multiple limitations, use plot_bar_compare() instead.

# Exe 1) Compare specific age classes for specific limitation
plot_bar_facet(
  dataset = DATA, # gali_all_w_ripart
  territori = TERRITORI, # cross territori for comparison
  classi_eta = CLASSI_ETA, # anziani (65+ e 75+)
  limitazione = LIMITAZIONE # limitazione (ONE value only)
)
# Exe 2) Compare all age classes for specific limitation ----
plot_bar_facet(
  dataset = DATA,
  territori = TERRITORI,
  limitazione = LIMITAZIONE,  # ONE limitation value only
  classi_eta = c(
    "0-44 anni",
    "45-64 anni",
    "65-74 anni",
    "75+ anni",
    "Tutte le età"
  )
)

# Exe 3) Compare specific age class for all limitation levels
plot_bar_facet(
  dataset = DATA,
  territori = TERRITORI,
  limitazione = c("Limitazioni gravi", "Limitazioni non gravi"),
  classi_eta = CLASSI_ETA
)

# SAVING SPECIFIC EXAMPLES ----
p22_bar_facet_all_ages <- plot_bar_facet(
  dataset = DATA,
  territori = TERRITORI,
  limitazione = "Limitazioni gravi",
  classi_eta = c(
    "0-44 anni",
    "45-64 anni",
    "65-74 anni",
    "75+ anni",
    "Tutte le età"
  )
)
p22_bar_facet_all_ages

p23_bar_facet_all_ages_lievi <- plot_bar_facet(
  dataset = DATA,
  territori = TERRITORI,
  limitazione = "Limitazioni non gravi",
  classi_eta = c(
    "0-44 anni",
    "45-64 anni",
    "65-74 anni",
    "75+ anni",
    "Tutte le età"
  )
)
p23_bar_facet_all_ages_lievi

# NOTE: For multiple limitations with multiple ages, use the collapsed DATA CATEGORIES ONLY
# or use plot_bar_compare() instead
p24_bar_facet_all_ages_clps <- plot_bar_facet(
  dataset = gali_all_w_ripart_clps,
  territori = TERRITORI,
  limitazione = "Limitazioni (lieve o grave)",  # Single collapsed category
  classi_eta = c(
    "Anziani (65+)",  # Collapsed dataset only has this age category
    "Tutte le età"
  )
)
p24_bar_facet_all_ages_clps

# 🟩 Save for later use in dashboard ----
saveRDS(p22_bar_facet_all_ages, here("data/plots/p22_bar_facet_all_ages.rds"))
saveRDS(p23_bar_facet_all_ages_lievi, here("data/plots/p23_bar_facet_all_ages_lievi.rds"))
saveRDS(p24_bar_facet_all_ages_clps, here("data/plots/p24_bar_facet_all_ages_clps.rds"))


# __ Example  COLLAPSED ----
# Using gali_all_w_ripart_clps to compare collapsed age classes
plot_bar_facet(
  dataset = gali_all_w_ripart_clps,
  territori = TERRITORI,
  classi_eta = c("Anziani (65+)", "Tutte le età"),
  limitazione = c("Limitazioni (lieve o grave)" )
)

plot_bar_facet(
  dataset = gali_all_w_ripart_clps,
  territori = TERRITORI,
  classi_eta = c("Anziani (65+)", "Tutte le età"),
  limitazione = c("Senza limitazioni")
)


# 7. VISUALIZATION 4: Heatmap ----

# Grid showing all territories × age classes

plot_heatmap <- function(
  dataset = DATA,
  territori = TERRITORI,
  classi_eta = CLASSI_ETA,
  limitazione = LIMITAZIONE
) {
  data <- prepare_data(dataset, territori, classi_eta, limitazione)

  # Exclude "Tutte le età" if present
  data <- data %>% filter(classe_eta != "Tutte le età")

  ggplot(
    data,
    aes(
      x = classe_eta,
      y = reorder(territorio, percentuale),
      fill = percentuale
    )
  ) +
    geom_tile(color = "white", linewidth = 1) +
    geom_text(
      aes(label = sprintf("%.1f", percentuale)),
      size = 4,
      fontface = "bold",
      color = "black"
    ) +
    scale_fill_gradient2(
      low = "#4575b4",
      mid = "#ffffbf",
      high = "#d73027",
      midpoint = median(data$percentuale, na.rm = TRUE),
      labels = label_percent(scale = 1),
      name = "%"
    ) +
    labs(
      title = sprintf("Heatmap: %s", limitazione),
      subtitle = "Incidenza per territorio e classe d'età",
      x = NULL,
      y = NULL,
      caption = CAPTION
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11, color = "gray30"),
      axis.text = element_text(size = 10),
      legend.position = "right",
      panel.grid = element_blank()
    )
}

# __ Example usage: ----
# function (dataset = DATA, territori = TERRITORI, classi_eta = CLASSI_ETA, limitazione = LIMITAZIONE)

# Exe 1) Compare specific age classes for specific limitation
plot_heatmap(
  dataset = DATA, # gali_all_w_ripart
  territori = TERRITORI, # cross territori for comparison
  classi_eta = CLASSI_ETA, # anziani (65+ e 75+)
  limitazione = LIMITAZIONE # limitazione (solo)
)
# Exe 2) Compare all age classes for specific limitation
plot_heatmap(
  dataset = DATA,
  territori = TERRITORI,
  limitazione = LIMITAZIONE,
  classi_eta = c(
    "0-44 anni",
    "45-64 anni",
    "65-74 anni",
    "75+ anni",
    "Tutte le età"
  )
)
# Exe 3) Compare specific age class for all limitation levels
plot_heatmap(
  dataset = DATA,
  territori = TERRITORI,
  limitazione = c("Limitazioni gravi", "Limitazioni non gravi"),
  classi_eta = CLASSI_ETA
)

# __ Example  COLLAPSED ----
# Using gali_all_w_ripart_clps to compare collapsed age classes
plot_heatmap(
  dataset = gali_all_w_ripart_clps,
  territori = TERRITORI,
  classi_eta = c("Anziani (65+)", "Tutte le età"),
  limitazione = "Limitazioni (lieve o grave)"
)

# 8. VISUALIZATION 5: Stacked Bar (All Limitation Levels) ----

# Show breakdown of all limitation levels

plot_stacked_limitazioni <- function(
  dataset = DATA,
  territori = TERRITORI,
  classi_eta = "75+ anni" # Single age class for clarity
) {
  data <- prepare_data(dataset, territori, classi_eta, limitazione = NULL)

  # Exclude "Non indicato" for clarity (optional)
  data <- data %>% filter(limitazioni != "Non indicato")

  ggplot(
    data,
    aes(
      x = reorder(territorio, percentuale),
      y = percentuale,
      fill = limitazioni
    )
  ) +
    geom_col(position = "stack") +
    scale_fill_manual(values = colori_limitazioni) +
    scale_y_continuous(labels = label_percent(scale = 1)) +
    coord_flip() +
    labs(
      title = sprintf(
        "Composizione popolazione per livello limitazione (%s)",
        classi_eta
      ),
      subtitle = "Distribuzione completa dei livelli di limitazione",
      x = NULL,
      y = "% popolazione",
      fill = "Livello limitazione",
      caption = CAPTION
    ) +
    theme_gali()
}

# __ Example usage: ----
plot_stacked_limitazioni(classi_eta = "0-44 anni")
plot_stacked_limitazioni(classi_eta = "45-64 anni")
plot_stacked_limitazioni(classi_eta = "65-74 anni")
plot_stacked_limitazioni(classi_eta = "75+ anni")
plot_stacked_limitazioni(classi_eta = "Tutte le età")
 
# __ Example  COLLAPSED ----
# Using gali_all_w_ripart_clps to compare collapsed age classes
plot_stacked_limitazioni(
  dataset = gali_all_w_ripart_clps,
  territori = TERRITORI,
  classi_eta = "Anziani (65+)"
)

# 9. VISUALIZATION 6: Map (Regions only) ----

# Geographic visualization

plot_mappa <- function(
  dataset = gali_all_w_ripart,  # Default: use dataset with ripartizioni
  classe_eta = "75+ anni",
  limitazione = LIMITAZIONE
) {
  # Prepare data - filter for regions only (maps don't show ripartizioni)
  data <- dataset %>%
    filter(
      tipo_territorio == "Regione",  # Only regions for map (no Italia, no ripartizioni)
      classe_eta == !!classe_eta,
      limitazioni == !!limitazione
    )

  # Join with shapefile
  mappa_data <- regioni_ita %>%
    left_join(
      data %>% select(territorio, percentuale),
      by = "territorio"
    )

  ggplot(mappa_data) +
    geom_sf(aes(fill = percentuale), color = "white", linewidth = 0.3) +
    scale_fill_gradient2(
      low = "#4575b4",
      mid = "#ffffbf",
      high = "#d75c27",
      midpoint = median(data$percentuale, na.rm = TRUE),
      labels = label_percent(scale = 1),
      name = "%"
    ) +
    labs(
      title = sprintf("Mappa: %s", limitazione),
      subtitle = sprintf("Classe d'età: %s", classe_eta),
      caption = CAPTION
    ) +
    theme_void() +
    theme(
      plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
      plot.subtitle = element_text(size = 11, color = "gray30", hjust = 0.5),
      legend.position = "right"
    )
}


# __ Example usage: ----

# Exe 1) Limitazioni gravi for different age classes 
plot_mappa(classe_eta =  "75+ anni", limitazione = "Limitazioni gravi") 
plot_mappa(classe_eta =  "65-74 anni", limitazione = "Limitazioni gravi") 
plot_mappa(classe_eta =  "Tutte le età", limitazione = "Limitazioni gravi") 

# Exe 2) Limitazioni NON gravi for different age classes 
plot_mappa(classe_eta =  "75+ anni", limitazione = "Limitazioni non gravi") 
plot_mappa(classe_eta =  "65-74 anni", limitazione = "Limitazioni non gravi") 
plot_mappa(classe_eta =  "Tutte le età", limitazione = "Limitazioni non gravi") 

# __ Example  COLLAPSED ----
# Using gali_all_w_ripart_clps to compare collapsed age classes
plot_mappa(
  dataset = gali_all_w_ripart_clps,
  classe_eta = "Anziani (65+)",
  limitazione = "Limitazioni (lieve o grave)"
)
plot_mappa(
  dataset = gali_all_w_ripart_clps,
  classe_eta = "Tutte le età",
  limitazione = "Limitazioni (lieve o grave)"
)


# 10. VISUALIZATION 7: Interactive Map ----
# Same as plot_mappa but with hover tooltips showing percentage
# NOTE: If you get "svgd only supports one page" error when running multiple plots,
# run dev.off() to reset graphics device, or only run one plot at a time

plot_mappa_interactive <- function(
  dataset = gali_all_w_ripart,
  classe_eta = "75+ anni",
  limitazione = LIMITAZIONE
) {
  # Prepare data - filter for regions only
  data <- dataset %>%
    filter(
      tipo_territorio == "Regione",
      classe_eta == !!classe_eta,
      limitazioni == !!limitazione
    )

  # Join with shapefile and create tooltip
  mappa_data <- regioni_ita %>%
    left_join(
      data %>% select(territorio, percentuale),
      by = "territorio"
    ) %>%
    mutate(
      # Escape single quotes in region names (e.g., Valle d'Aosta)
      territorio_clean = gsub("'", "&apos;", territorio),
      tooltip = sprintf("%s: %.1f%%", territorio_clean, percentuale)
    )

  # Create ggplot with interactive geom
  p <- ggplot(mappa_data) +
    geom_sf_interactive(
      aes(fill = percentuale, tooltip = tooltip, data_id = territorio_clean),
      color = "white",
      linewidth = 0.3
    ) +
    scale_fill_gradient2(
      low = "#4575b4",
      mid = "#ffffbf",
      high = "#c94c4c",
      midpoint = median(data$percentuale, na.rm = TRUE),
      labels = label_percent(scale = 1),
      name = "%"
    ) +
    labs(
      title = sprintf("Mappa: %s", limitazione),
      subtitle = sprintf("Classe d'età: %s", classe_eta),
      caption = CAPTION
    ) +
    theme_void() +
    theme(
      plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
      plot.subtitle = element_text(size = 11, color = "gray30", hjust = 0.5),
      legend.position = "right"
    )

  # Make it interactive with ggiraph
  girafe(
    ggobj = p,
    width_svg = 9,
    height_svg = 7,
    options = list(
      opts_hover(css = "fill:orange;stroke:black;stroke-width:2;"),
      opts_tooltip(css = "background-color:white;padding:5px;border-radius:3px;box-shadow:2px 2px 5px rgba(0,0,0,0.3);")
    )
  )
}

# __ Example usage INTERACTIVE MAP: ----
# Hover over regions to see percentages

# Exe 1) Interactive map for Limitazioni gravi
plot_mappa_interactive(dataset = gali_all_w_ripart, classe_eta = "75+ anni", limitazione = "Limitazioni gravi")

#Exe 2) Interactive map with collapsed categories
plot_mappa_interactive(
 dataset = gali_all_w_ripart_clps,
 classe_eta = "Anziani (65+)",
 limitazione = "Limitazioni (lieve o grave)"
)

# SAVING SPECIFIC EXAMPLES ----
# All interactive maps for tabset
p25_map_gali_gr_0_44 <- plot_mappa_interactive(dataset = gali_all_w_ripart, classe_eta = "0-44 anni", limitazione = "Limitazioni gravi")
p26_map_gali_gr_45_64 <- plot_mappa_interactive(dataset = gali_all_w_ripart, classe_eta = "45-64 anni", limitazione = "Limitazioni gravi")
p27_map_gali_gr_65_74 <- plot_mappa_interactive(dataset = gali_all_w_ripart, classe_eta = "65-74 anni", limitazione = "Limitazioni gravi")
p28_map_gali_gr_75_plus <- plot_mappa_interactive(dataset = gali_all_w_ripart, classe_eta = "75+ anni", limitazione = "Limitazioni gravi")
p30_map_gali_gr_tutti <- plot_mappa_interactive(dataset = gali_all_w_ripart_clps, classe_eta = "Tutte le età", limitazione = "Limitazioni (lieve o grave)")


# 🟩 Save for later use in dashboard ----
saveRDS(p25_map_gali_gr_0_44, here("data/plots/p25_map_gali_gr_0_44.rds"))
saveRDS(p26_map_gali_gr_45_64, here("data/plots/p26_map_gali_gr_45_64.rds"))
saveRDS(p27_map_gali_gr_65_74, here("data/plots/p27_map_gali_gr_65_74.rds"))
saveRDS(p28_map_gali_gr_75_plus, here("data/plots/p28_map_gali_gr_75_plus.rds"))
saveRDS(p30_map_gali_gr_tutti, here("data/plots/p30_map_gali_gr_tutti.rds"))
