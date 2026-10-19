# Visualizzazioni ADL/IADL (Activities of Daily Living) ----
# Visualization functions for non-autosufficienza (self-sufficiency) data
# Based on ISTAT EHIS 2019 data on difficulty in daily activities

library(here)
library(ggplot2)
library(dplyr)
library(tidyr)
library(sf)
library(scales)
library(ggiraph)
library(stringr)


# 1. LOAD DATASETS ----
# ___ Load cleaned datasets created by non_autosufficienza/data_load.R ----

# Corrisponde a EHIS_limit_tavola3_2_3 pulito e salvato
# ----- "Persone di 65+ anni con difficoltà nelle attività di **cura della persona**, regione e ripartizione geografica"
ADL_reg <- readRDS(here("data/data_out/istat_EHIS_2019/ADL_reg_perc_clean.rds"))

# Corrisponde a EHIS_limit_tavola3_3_4 pulito e salvato
# ----- "Persone di 65+ anni con difficoltà nelle **attività domestiche**, regione e ripartizione geografica
IADL_reg <- readRDS(here("data/data_out/istat_EHIS_2019/IADL_reg_perc_clean.rds"))

# Corrisponde a EHIS_limit_tavola3_2_5_segue2 pulito e salvato
# ----- "Persone di 65+ anni con difficoltà nelle attività qudi **cura della persona**, per tipo di attività
ADL_tipo <- readRDS(here("data/data_out/istat_EHIS_2019/ADL_tipo_anz_perc_clean.rds"))

# Corrisponde a EHIS_limit_tavola3_3_5_segue2 pulito e salvato
# ----- "Persone di 65+ anni con difficoltà nelle a**attività domestiche**, per tipo di attività
IADL_tipo <- readRDS(here("data/data_out/istat_EHIS_2019/IADL_tipo_perc_clean.rds"))

# ___ Load shapefile for maps (same as disability section) ----
regioni_ita <- readRDS(here("data/data_out/ITA_shp/regioni_ita_full.rds"))
# Simplify geometry for better performance
regioni_ita <- sf::st_simplify(regioni_ita, preserveTopology = TRUE, dTolerance = 500)


# 2. THEME & COLORS ----
theme_adl <- function() {
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

# Color palettes for difficulty levels
colori_difficolta <- c(
  "nessuna" = "#1a9850",        # Green - no difficulty
  "moderata" = "#fee08b",        # Yellow - moderate
  "grave" = "#d75c27",           # Red - severe
  "non_indicato" = "#999999"     # Gray - not indicated
  
)

colori_eta_5 <- c(
  "0-44 anni" = "#c7e9b4",
  "45-64 anni" = "#7fcdbb",
  "65-74 anni" =  "#41b6c4", 
  "Anziani (65+)" = "#1d91c0",  # a metà tra 65-74 e 75+
  "75+ anni" = "#225ea8",
  
  "Tutte le età" = "#7F7F7F" 
)

# 3. CONFIGURATION / PARAMETERS ----

# Default settings
DATA <- ADL_reg  # Change to IADL_reg, ADL_tipo, IADL_tipo as needed
CAPTION <- "Fonte: ISTAT - EHIS (European Health Interview Survey) 2022, su dati 2019"

# Key territories for comparison
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

# 4. HELPER FUNCTION: PREPARE DATA ----
# Function to filter and reshape data for plotting
prepare_data_ehis <- function(
  dataset = DATA,
  territori = NULL,
  tipo_territorio = NULL,
  difficolta = NULL
) {
  data <- dataset

  # Filter by territori
  if (!is.null(territori)) {
    data <- data %>% filter(territorio %in% territori)
  }

  # Filter by tipo_territorio (regione/ripartizione)
  if (!is.null(tipo_territorio)) {
    data <- data %>% filter(tipo_territorio %in% !!tipo_territorio)
  }

  # Pivot to long format for easier plotting
  if (!"difficolta" %in% names(data)) {
    data <- data %>%
      pivot_longer(
        cols = c(nessuna, moderata, grave, non_indicato),
        names_to = "difficolta",
        values_to = "percentuale"
      )
  }

  # Filter by difficulty level
  if (!is.null(difficolta)) {
    data <- data %>% filter(difficolta %in% !!difficolta)
  }

  # Drop totale column if exists
  if ("totale" %in% names(data)) {
    data <- data %>% select(-totale)
  }

  return(data)
}


# 5. VISUALIZATION 1: Faceted Bar Chart ----

# Compare territories with each difficulty level in separate panel
plot_bar_difficolta_facet <- function(
  dataset = DATA,
  territori = TERRITORI,
  difficolta = c("grave", "moderata", "nessuna"),  # Default: show all levels
  title= "Difficoltà nella popolazione anziana per gravità e per territorio",
  subtitle = NULL
) {
  data <- prepare_data_ehis(dataset, territori = territori, difficolta = difficolta)

  # Create subtitle if not provided
  if (is.null(subtitle)) {
    subtitle <- "Per territorio e livello di difficoltà"
  }

  # Difficulty labels for facets
  diff_labels <- c(
    "nessuna" = "Nessuna difficoltà",
    "moderata" = "Difficoltà moderata",
    "grave" = "Difficoltà grave",
    "non_indicato" = "Non indicato"
  )

  # Create labeled factor for faceting
  data <- data %>%
    mutate(difficolta_label = factor(
      difficolta,
      levels = c("nessuna", "moderata", "grave", "non_indicato"),
      labels = diff_labels[c("nessuna", "moderata", "grave", "non_indicato")]
    ))

  ggplot(
    data,
    aes(
      x = reorder(territorio, percentuale),
      y = percentuale,
      fill = difficolta
    )
  ) +
    geom_col(show.legend = FALSE) +
    geom_text(
      aes(label = sprintf("%.1f%%", percentuale)),
      hjust = -0.1,
      size = 3
    ) +
    scale_fill_manual(values = colori_difficolta) +
    scale_y_continuous(
      labels = label_percent(scale = 1),
      limits = c(0, max(data$percentuale, na.rm = TRUE) * 1.15),
      expand = expansion(mult = c(0, 0))
    ) +
    coord_flip() +
    facet_wrap(
      ~ difficolta_label,
      ncol = 2,
      scales = "free_x"
    ) +
    labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = "% popolazione 65+",
      caption = CAPTION
    ) +
    theme_adl() +
    theme(
      strip.text = element_text(face = "bold", size = 11),
      strip.background = element_rect(fill = "gray90", color = NA)
    )
}


# __ Example usage: ----
# ADL in anziani
plot_bar_difficolta_facet(
  dataset = ADL_reg,
  territori = TERRITORI,
  difficolta = c("nessuna", "moderata", "grave"),
  #title= "Difficoltà nella popolazione anziana per gravità e per territorio",
  subtitle = "ADL - Attività di cura della persona"
)

# IADL in anziani
plot_bar_difficolta_facet(
  dataset = IADL_reg,
  territori = TERRITORI,
  difficolta = c("nessuna", "moderata", "grave"),
  subtitle = "IADL - Attività domestiche"
)

# 6. VISUALIZATION 2: Regional Map ----

# Geographic visualization of difficulty levels
plot_mappa_difficolta <- function(
  dataset = ADL_reg,
  difficolta = "grave",
  subtitle = NULL
) {
  # Prepare data - regions only
  data <- prepare_data_ehis(
    dataset = dataset,
    tipo_territorio = "regione",
    difficolta = difficolta
  )

  # Join with shapefile
  mappa_data <- regioni_ita %>%
    left_join(
      data %>% select(territorio, percentuale),
      by = "territorio"
    )

  # Difficulty labels
  diff_labels <- c(
    "nessuna" = "Nessuna difficoltà",
    "moderata" = "Difficoltà moderata",
    "grave" = "Difficoltà grave",
    "non_indicato" = "Non indicato"
  )

  # Create subtitle if not provided
  if (is.null(subtitle)) {
    subtitle <- "Persone di 65+ anni per regione"
  }

  # Invert color scale for "nessuna" (high % = good = blue)
  if (difficolta == "nessuna") {
    scale_colors <- scale_fill_gradient2(
      low = "#c93b04",      # red for low % (problematic)
      mid = "#ffffbf",
      high = "#4575b4",     # blue for high % (positive)
      midpoint = median(data$percentuale, na.rm = TRUE),
      labels = label_percent(scale = 1),
      name = "% su popolazione 65+"
    )
  } else {
    # Normal scale for grave/moderata (high % = bad = red)
    scale_colors <- scale_fill_gradient2(
      low = "#4575b4",
      mid = "#ffffbf",
      high = "#c93b04",
      midpoint = median(data$percentuale, na.rm = TRUE),
      labels = label_percent(scale = 1),
      name = "% su popolazione 65+"
    )
  }

  ggplot(mappa_data) +
    geom_sf(aes(fill = percentuale), color = "white", linewidth = 0.3) +
    scale_colors +
    labs(
      title = sprintf("Mappa: %s", diff_labels[difficolta]),
      subtitle = subtitle,
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
plot_mappa_difficolta(dataset = ADL_reg, difficolta = "grave", 
                     "Attività di cura della persona (ADL)")
plot_mappa_difficolta(dataset = ADL_reg, difficolta = "moderata", 
                      "Attività di cura della persona (ADL)")
plot_mappa_difficolta(dataset = ADL_reg, difficolta = "nessuna", 
                      "Attività di cura della persona (ADL)")


plot_mappa_difficolta(dataset = IADL_reg, difficolta = "grave",
                      subtitle= "Attività domestiche (IADL)")
plot_mappa_difficolta(dataset = IADL_reg, difficolta = "moderata",
                      subtitle= "Attività domestiche (IADL)")
plot_mappa_difficolta(dataset = IADL_reg, difficolta = "nessuna",
                      subtitle= "Attività domestiche (IADL)")


# 7. VISUALIZATION 3: Interactive Map ----

plot_mappa_difficolta_interactive <- function(
  dataset = ADL_reg,
  difficolta = "grave",
  subtitle = NULL
) {
  # Prepare data - regions only
  data <- prepare_data_ehis(
    dataset = dataset,
    tipo_territorio = "regione",
    difficolta = difficolta
  )

  # Join with shapefile and create tooltip
  mappa_data <- regioni_ita %>%
    left_join(
      data %>% select(territorio, percentuale),
      by = "territorio"
    ) %>%
    mutate(
      territorio_clean = gsub("'", "&apos;", territorio),
      tooltip = sprintf("%s: %.1f%%", territorio_clean, percentuale)
    )

  # Difficulty labels
  diff_labels <- c(
    "nessuna" = "Nessuna difficoltà",
    "moderata" = "Difficoltà moderata",
    "grave" = "Difficoltà grave",
    "non_indicato" = "Non indicato"
  )

  # Create subtitle if not provided
  if (is.null(subtitle)) {
    subtitle <- "Persone di 65+ anni per regione"
  }

  # Invert color scale for "nessuna" (high % = good = blue)
  if (difficolta == "nessuna") {
    scale_colors <- scale_fill_gradient2(
      low = "#d73027",      # red for low % (problematic)
      mid = "#ffffbf",
      high = "#4575b4",     # blue for high % (positive)
      midpoint = median(data$percentuale, na.rm = TRUE),
      labels = label_percent(scale = 1),
      name = "% di persone di 65+ anni"
    )
  } else {
    # Normal scale for grave/moderata (high % = bad = red)
    scale_colors <- scale_fill_gradient2(
      low = "#4575b4",
      mid = "#ffffbf",
      high = "#d73027",
      midpoint = median(data$percentuale, na.rm = TRUE),
      labels = label_percent(scale = 1),
      name = "% di persone di 65+ anni"
    )
  }

  # Create ggplot with interactive geom
  p <- ggplot(mappa_data) +
    geom_sf_interactive(
      aes(fill = percentuale, tooltip = tooltip, data_id = territorio_clean),
      color = "white",
      linewidth = 0.3
    ) +
    scale_colors +
    labs(
      title = sprintf("Mappa: %s", diff_labels[difficolta]),
      subtitle = subtitle,
      caption = CAPTION
    ) +
    theme_void() +
    theme(
      plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
      plot.subtitle = element_text(size = 11, color = "gray30", hjust = 0.5),
      legend.position = "right"
    )

  # Make it interactive
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

# __ Example usage: ----
plot_mappa_difficolta_interactive(dataset = ADL_reg, difficolta = "grave", 
                      subtitle = "Attività di cura della persona (ADL)")
plot_mappa_difficolta_interactive(dataset = ADL_reg, difficolta = "moderata", 
                      subtitle = "Attività di cura della persona (ADL)")
plot_mappa_difficolta_interactive(dataset = ADL_reg, difficolta = "nessuna", 
                      subtitle = "Attività di cura della persona (ADL)")


plot_mappa_difficolta_interactive(dataset = IADL_reg, difficolta = "grave",
                      subtitle= "Attività domestiche (IADL)")
plot_mappa_difficolta_interactive(dataset = IADL_reg, difficolta = "moderata",
                      subtitle= "Attività domestiche (IADL)")
plot_mappa_difficolta_interactive(dataset = IADL_reg, difficolta = "nessuna",
                      subtitle= "Attività domestiche (IADL)")


# 8.a VISUALIZATION 4: Activity Type Comparison by Age ----

# Compare specific activities by age class (for ADL_tipo and IADL_tipo datasets)
plot_attivita_by_age <- function(
  dataset = ADL_tipo,
  difficolta = c("grave", "moderata"),
  title = "Difficoltà per tipo di attività e classe d'età",
  subtitle = NULL
) {
  # Prepare data
  data <- dataset %>%
    # Keep only specific age classes (not "totale")
    filter(classe_eta %in% c("65-74", "75+")) %>%
    # Pivot to long format
    pivot_longer(
      cols = c(nessuna, moderata, grave, non_indicato),
      names_to = "livello_difficolta",
      values_to = "percentuale"
    ) %>%
    # Filter by difficulty level
    filter(livello_difficolta %in% difficolta)

  # Difficulty labels
  diff_labels <- c(
    "nessuna" = "Nessuna",
    "moderata" = "Moderata",
    "grave" = "Grave",
    "non_indicato" = "Non indicato"
  )

  # Create subtitle if not provided
  if (is.null(subtitle)) {
    subtitle <- "Confronto tra giovani anziani (65-74) e grandi anziani (75+)"
  }

  ggplot(
    data,
    aes(
      x = reorder(attivita, percentuale),
      y = percentuale,
      fill = livello_difficolta
    )
  ) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_text(
      aes(label = sprintf("%.1f", percentuale)),
      position = position_dodge(width = 0.8),
      hjust = -0.1,
      size = 2.5
    ) +
    scale_fill_manual(
      values = colori_difficolta,
      labels = diff_labels
    ) +
    scale_y_continuous(
      labels = label_percent(scale = 1),
      limits = c(0, max(data$percentuale, na.rm = TRUE) * 1.15),
      expand = expansion(mult = c(0, 0))
    ) +
    coord_flip() +
    facet_wrap(~ classe_eta, ncol = 2) +
    labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = "% popolazione",
      fill = "Livello difficoltà",
      caption = CAPTION
    ) +
    theme_adl() +
    theme(
      strip.text = element_text(face = "bold", size = 11),
      strip.background = element_rect(fill = "gray90", color = NA),
      legend.position = "top"
    )
}

# Example usage:
plot_attivita_by_age(
  dataset = ADL_tipo,
  difficolta = c("grave", "moderata"),
  title = "Difficoltà nelle attività di cura della persona (ADL)",
  subtitle = "Confronto tra giovani anziani (65-74) e grandi anziani (75+)"
)

plot_attivita_by_age(
  dataset = IADL_tipo,
  difficolta = c("grave", "moderata"),
  title = "Difficoltà nelle attività domestiche (IADL)",
  subtitle = "Confronto tra giovani anziani (65-74) e grandi anziani (75+)"
)


# 8.b VISUALIZATION 5: Activity Type Dumbbell Chart ----

# Emphasize the gap between age groups with connected points
plot_attivita_dumbbell <- function(
  dataset = ADL_tipo,
  difficolta = "grave",  # Single difficulty level for clarity
  title = "Difficoltà per tipo di attività: confronto per età",
  subtitle = NULL
) {
  # Prepare data for age groups
  data <- dataset %>%
    # Keep only specific age classes (not "totale")
    filter(classe_eta %in% c("65-74", "75+", "totale")) %>%
    # Pivot to long format
    pivot_longer(
      cols = c(nessuna, moderata, grave, non_indicato),
      names_to = "livello_difficolta",
      values_to = "percentuale"
    ) %>%
    # Filter by difficulty level
    filter(livello_difficolta == difficolta) %>%
    # Calculate difference between age groups for ordering
    group_by(attivita) %>%
    mutate(
      diff = percentuale[classe_eta == "75+"] - percentuale[classe_eta == "65-74"]
    ) %>%
    ungroup() %>%
    # Wrap long activity labels
    mutate(attivita_wrap = str_wrap(attivita, width = 30))

  # Separate totale for reference line
  data_totale <- data %>%
    filter(classe_eta == "totale") %>%
    mutate(gruppo = "Totale 65+")

  data_ages <- data %>%
    filter(classe_eta != "totale") %>%
    mutate(gruppo = classe_eta)

  # Difficulty labels
  diff_labels <- c(
    "nessuna" = "Nessuna difficoltà",
    "moderata" = "Difficoltà moderata",
    "grave" = "Difficoltà grave",
    "non_indicato" = "Non indicato"
  )

  # Create subtitle if not provided
  if (is.null(subtitle)) {
    subtitle <- sprintf("%s - Le linee mostrano l'aumento tra 65-74 e 75+",
                       diff_labels[difficolta])
  }

  # Combine data for unified legend
  data_combined <- bind_rows(data_ages, data_totale)

  ggplot(
    data_ages,
    aes(
      x = percentuale,
      y = reorder(attivita_wrap, diff)  # Order by size of difference, use wrapped labels
    )
  ) +
    # Line connecting the two age groups (dumbbell)
    geom_line(aes(group = attivita_wrap), color = "gray60", linewidth = 1.5) +
    # Points for all groups with unified legend
    geom_point(
      data = data_combined,
      aes(x = percentuale, y = attivita_wrap, color = gruppo, shape = gruppo),
      size = 4,
      stroke = 1.5
    ) +
    # Labels - no decimals, positioned with vertical offset to avoid overlap
    geom_text(
      data = data_ages %>% filter(classe_eta == "65-74"),
      aes(label = sprintf("%.0f%%", percentuale)),
      hjust = 0.5,
      vjust = 2.5,
      size = 3.5,
      color = "#41b6c4",
      fontface = "bold"
    ) +
    geom_text(
      data = data_ages %>% filter(classe_eta == "75+"),
      aes(label = sprintf("%.0f%%", percentuale)),
      hjust = 0.5,
      vjust = -1.5,
      size = 3.5,
      color = "#225ea8",
      fontface = "bold"
    ) +
    scale_color_manual(
      values = c("65-74" = "#41b6c4", "75+" = "#225ea8", "Totale 65+" = "gray50"),
      labels = c("65-74" = "65-74 anni", "75+" = "75+ anni", "Totale 65+" = "Totale 65+"),
      name = "Classe d'età"
    ) +
    scale_shape_manual(
      values = c("65-74" = 16, "75+" = 16, "Totale 65+" = 4),
      labels = c("65-74" = "65-74 anni", "75+" = "75+ anni", "Totale 65+" = "Totale 65+"),
      name = "Classe d'età"
    ) +
    scale_x_continuous(
      labels = label_percent(scale = 1),
      expand = expansion(mult = c(0.05, 0.15))
    ) +
    labs(
      title = title,
      subtitle = subtitle,
      x = "% popolazione",
      y = NULL,
      caption = CAPTION
    ) +
    guides(
      color = guide_legend(override.aes = list(size = 4, stroke = 1.5)),
      shape = "none"  # Hide duplicate shape legend since color already shows it
    ) +
    theme_adl() +
    theme(
      legend.position = "top",
      panel.grid.major.y = element_blank()
    )
}

# __ Example usage: ----
plot_attivita_dumbbell(
  dataset = ADL_tipo,
  difficolta = "grave",
  title = "Difficoltà gravi nelle attività di cura della persona (ADL)",
  subtitle = "Le linee mostrano l'aumento della difficoltà grave tra 65-74 e 75+"
)

plot_attivita_dumbbell(
  dataset = ADL_tipo,
  difficolta = "moderata",
  title = "Difficoltà moderate nelle attività di cura della persona (ADL)",
  subtitle = "Le linee mostrano l'aumento della difficoltà moderata tra 65-74 e 75+"
)

plot_attivita_dumbbell(
  dataset = IADL_tipo,
  difficolta = "grave",
  title = "Difficoltà gravi nelle attività domestiche (IADL)",
  subtitle = "Le linee mostrano l'aumento della difficoltà grave tra 65-74 e 75+"
)

plot_attivita_dumbbell(
  dataset = IADL_tipo,
  difficolta = "moderata",
  title = "Difficoltà moderate nelle attività domestiche (IADL)",
  subtitle = "Le linee mostrano l'aumento della difficoltà moderata tra 65-74 e 75+"
)


# SAVING SPECIFIC EXAMPLES ----

# Bar charts - faceted by difficulty level
p39_bar_adl_facet <- plot_bar_difficolta_facet(
  dataset = ADL_reg,
  territori = TERRITORI,
  difficolta = c("nessuna", "moderata", "grave"),
  subtitle = "ADL - Attività di cura della persona"
)

p40_bar_iadl_facet <- plot_bar_difficolta_facet(
  dataset = IADL_reg,
  territori = TERRITORI,
  difficolta = c("nessuna", "moderata", "grave"),
  subtitle = "IADL - Attività domestiche"
)

# Static maps - ADL
p41_map_adl_grave <- plot_mappa_difficolta(
  dataset = ADL_reg,
  difficolta = "grave",
  subtitle = "Attività di cura della persona (ADL)"
)

p42_map_adl_moderata <- plot_mappa_difficolta(
  dataset = ADL_reg,
  difficolta = "moderata",
  subtitle = "Attività di cura della persona (ADL)"
)

p43_map_adl_nessuna <- plot_mappa_difficolta(
  dataset = ADL_reg,
  difficolta = "nessuna",
  subtitle = "Attività di cura della persona (ADL)"
)

# Static maps - IADL
p44_map_iadl_grave <- plot_mappa_difficolta(
  dataset = IADL_reg,
  difficolta = "grave",
  subtitle = "Attività domestiche (IADL)"
)

p45_map_iadl_moderata <- plot_mappa_difficolta(
  dataset = IADL_reg,
  difficolta = "moderata",
  subtitle = "Attività domestiche (IADL)"
)

p46_map_iadl_nessuna <- plot_mappa_difficolta(
  dataset = IADL_reg,
  difficolta = "nessuna",
  subtitle = "Attività domestiche (IADL)"
)

# Interactive maps - ADL
p47_map_int_adl_grave <- plot_mappa_difficolta_interactive(
  dataset = ADL_reg,
  difficolta = "grave",
  subtitle = "Attività di cura della persona (ADL)"
)

p48_map_int_adl_moderata <- plot_mappa_difficolta_interactive(
  dataset = ADL_reg,
  difficolta = "moderata",
  subtitle = "Attività di cura della persona (ADL)"
)

p49_map_int_adl_nessuna <- plot_mappa_difficolta_interactive(
  dataset = ADL_reg,
  difficolta = "nessuna",
  subtitle = "Attività di cura della persona (ADL)"
)

# Interactive maps - IADL
p50_map_int_iadl_grave <- plot_mappa_difficolta_interactive(
  dataset = IADL_reg,
  difficolta = "grave",
  subtitle = "Attività domestiche (IADL)"
)

p51_map_int_iadl_moderata <- plot_mappa_difficolta_interactive(
  dataset = IADL_reg,
  difficolta = "moderata",
  subtitle = "Attività domestiche (IADL)"
)

p52_map_int_iadl_nessuna <- plot_mappa_difficolta_interactive(
  dataset = IADL_reg,
  difficolta = "nessuna",
  subtitle = "Attività domestiche (IADL)"
)

# Activity by age - faceted bar charts
p53_attiv_age_adl <- plot_attivita_by_age(
  dataset = ADL_tipo,
  difficolta = c("grave", "moderata"),
  title = "Difficoltà nelle attività di cura della persona (ADL)",
  subtitle = "Confronto tra giovani anziani (65-74) e grandi anziani (75+)"
)

p54_attiv_age_iadl <- plot_attivita_by_age(
  dataset = IADL_tipo,
  difficolta = c("grave", "moderata"),
  title = "Difficoltà nelle attività domestiche (IADL)",
  subtitle = "Confronto tra giovani anziani (65-74) e grandi anziani (75+)"
)

# Dumbbell charts for ADL and IADL comparison
p55_dumbbell_adl_grave <- plot_attivita_dumbbell(
  dataset = ADL_tipo,
  difficolta = "grave",
  title = "Difficoltà gravi nelle attività di cura della persona (ADL)",
  subtitle = "Le linee mostrano l'aumento della difficoltà grave tra 65-74 e 75+"
)

p56_dumbbell_adl_moderata <- plot_attivita_dumbbell(
  dataset = ADL_tipo,
  difficolta = "moderata",
  title = "Difficoltà moderate nelle attività di cura della persona (ADL)",
  subtitle = "Le linee mostrano l'aumento della difficoltà moderata tra 65-74 e 75+"
)

p57_dumbbell_iadl_grave <- plot_attivita_dumbbell(
  dataset = IADL_tipo,
  difficolta = "grave",
  title = "Difficoltà gravi nelle attività domestiche (IADL)",
  subtitle = "Le linee mostrano l'aumento della difficoltà grave tra 65-74 e 75+"
)

p58_dumbbell_iadl_moderata <- plot_attivita_dumbbell(
  dataset = IADL_tipo,
  difficolta = "moderata",
  title = "Difficoltà moderate nelle attività domestiche (IADL)",
  subtitle = "Le linee mostrano l'aumento della difficoltà moderata tra 65-74 e 75+"
)

# 🟩 Save for later use in dashboard ----
saveRDS(p39_bar_adl_facet, here("data/plots/p39_bar_adl_facet.rds"))
saveRDS(p40_bar_iadl_facet, here("data/plots/p40_bar_iadl_facet.rds"))

saveRDS(p41_map_adl_grave, here("data/plots/p41_map_adl_grave.rds"))
saveRDS(p42_map_adl_moderata, here("data/plots/p42_map_adl_moderata.rds"))
saveRDS(p43_map_adl_nessuna, here("data/plots/p43_map_adl_nessuna.rds"))

saveRDS(p44_map_iadl_grave, here("data/plots/p44_map_iadl_grave.rds"))
saveRDS(p45_map_iadl_moderata, here("data/plots/p45_map_iadl_moderata.rds"))
saveRDS(p46_map_iadl_nessuna, here("data/plots/p46_map_iadl_nessuna.rds"))

saveRDS(p47_map_int_adl_grave, here("data/plots/p47_map_int_adl_grave.rds"))
saveRDS(p48_map_int_adl_moderata, here("data/plots/p48_map_int_adl_moderata.rds"))
saveRDS(p49_map_int_adl_nessuna, here("data/plots/p49_map_int_adl_nessuna.rds"))

saveRDS(p50_map_int_iadl_grave, here("data/plots/p50_map_int_iadl_grave.rds"))
saveRDS(p51_map_int_iadl_moderata, here("data/plots/p51_map_int_iadl_moderata.rds"))
saveRDS(p52_map_int_iadl_nessuna, here("data/plots/p52_map_int_iadl_nessuna.rds"))

saveRDS(p53_attiv_age_adl, here("data/plots/p53_attiv_age_adl.rds"))
saveRDS(p54_attiv_age_iadl, here("data/plots/p54_attiv_age_iadl.rds"))

saveRDS(p55_dumbbell_adl_grave, here("data/plots/p55_dumbbell_adl_grave.rds"))
saveRDS(p56_dumbbell_adl_moderata, here("data/plots/p56_dumbbell_adl_moderata.rds"))
saveRDS(p57_dumbbell_iadl_grave, here("data/plots/p57_dumbbell_iadl_grave.rds"))
saveRDS(p58_dumbbell_iadl_moderata, here("data/plots/p58_dumbbell_iadl_moderata.rds"))
