# Caricamento e pulizia dei dati FRAGILITÀ e non AUTOSUFFICIENZA ----
# Fonte: ISTAT EHIS (2022 ma su dati 2019)
# Dati ...

library(here)
library(fs)
library(readr)
library(dplyr)
library(readxl)
library(writexl)
library(tidyr)
library(stringr)
library(purrr)
library(janitor)


# 1. LOAD RAW DATA ----

# Spezzo in più file i dati sulle limitazioni (funzione ad hoc)

# Rompo e salvo 3.Limitazioni.xlsx [JUST ONCE]
# source("R/f_split_excel_sheets.R")
# split_excel_sheets(
#   file_in = here::here("data/data_in/istat_ehis_2019/3.Limitazioni.xlsx"),
#   prefix = "EHIS_limit_",
#   output_dir = "data/data_in/istat_ehis_2019/partials"
# )

# Lista di nomi di file parziali basati su pattern
patterns <- c("tavola3.2.3", "tavola3.2.5", "tavola3.3.4", "tavola3.3.5")
# Trova i file parziali rilevanti
list_tavole <- list.files(
  path = here("data/data_in/istat_ehis_2019/partials"),
  full.names = TRUE
) |>
  keep(~ any(str_detect(.x, fixed(patterns))))

# Crea nomi oggetti puliti
obj_names <- list_tavole |>
  basename() |>
  tools::file_path_sans_ext() |>
  str_replace_all("[^A-Za-z0-9_]", "_") # evita caratteri non validi

# Importa ogni file e assegnalo nell'env
walk2(
  list_tavole,
  obj_names,
  ~ assign(.y, read_excel(.x), envir = .GlobalEnv)
)

# Choose the relevant data and clean
ADL_reg_perc <- EHIS_limit_tavola3_2_3
ADL_tipo_anz_perc <- EHIS_limit_tavola3_2_5_segue2

IADL_reg_perc <- EHIS_limit_tavola3_3_4
IADL_tipo_perc <- EHIS_limit_tavola3_3_5_segue2

# remove all files starting with EHIS_limit_ in env
rm(list = ls(pattern = "^EHIS_limit_"))

# 2. CLEAN SELECTED DATA ----

# 2.1 Clean ADL_reg_perc ----
ADL_reg_perc_clean <- ADL_reg_perc |>
  # Remove empty rows
  remove_empty(which = "rows") |>
  # Remove header rows (first 2 rows with metadata)
  slice(-(1:2)) |>
  # Now we have row 1: TERRITORIO | Difficoltà nelle... | NA | NA | NA | Totale
  #          and row 2: NA | Nessuna | Moderata | Grave | Non indicato | NA
  # Manually set proper column names by combining the two header rows
  setNames(c("territorio", "nessuna", "moderata", "grave", "non_indicato", "totale")) |>
  # Remove the two header rows
  slice(-(1:2)) |>
  # Extract subheaders as categories
  mutate(
    tipo_territorio = case_when(
      territorio == "REGIONI" ~ "regione",
      territorio == "RIPARTIZIONI GEOGRAFICHE" ~ "ripartizione",
      TRUE ~ NA_character_
    )
  ) |>
  # Fill down the tipo_territorio category
  fill(tipo_territorio, .direction = "down") |>
  # Filter out the header rows themselves
  filter(!territorio %in% c("REGIONI", "RIPARTIZIONI GEOGRAFICHE")) |>
  # Convert all columns except territorio and tipo_territorio to numeric
  # Handle "..", "**", and "-" as NA (ISTAT missing value codes)
  mutate(across(c(nessuna, moderata, grave, non_indicato, totale), ~ {
    .x <- na_if(.x, "..")
    .x <- na_if(.x, "**")
    .x <- na_if(.x, "-")
    as.numeric(.x)
  })) |>
  # Clean territory names (remove alternative names after / and standardize)
  mutate(territorio = str_squish(str_remove(territorio, "/.*$"))) |>
  mutate(territorio = case_when(
    territorio == "Trentino - Alto Adige" ~ "Trentino Alto Adige",
    TRUE ~ territorio
  )) |>
  # Reorder columns to put tipo_territorio after territorio
  relocate(tipo_territorio, .after = territorio) |>
  # Check if totale equals row sum
  mutate(
    row_sum = rowSums(across(c(nessuna, moderata, grave, non_indicato)), na.rm = TRUE),
    sum_check = abs(totale - row_sum) < 0.1
  )

# Check and report
if(any(!ADL_reg_perc_clean$sum_check, na.rm = TRUE)) {
  print(ADL_reg_perc_clean |> filter(!sum_check) |>
    select(territorio, nessuna:totale, row_sum))
}

ADL_reg_perc_clean <- ADL_reg_perc_clean |> select(-row_sum, -sum_check)

# 2.2 Clean IADL_reg_perc ----
IADL_reg_perc_clean <- IADL_reg_perc |>
  remove_empty(which = "rows") |>
  slice(-(1:2)) |>
  setNames(c("territorio", "nessuna", "moderata", "grave", "non_indicato", "totale")) |>
  slice(-(1:2)) |>
  # Extract subheaders as categories
  mutate(
    tipo_territorio = case_when(
      territorio == "REGIONI" ~ "regione",
      territorio == "RIPARTIZIONI GEOGRAFICHE" ~ "ripartizione",
      TRUE ~ NA_character_
    )
  ) |>
  fill(tipo_territorio, .direction = "down") |>
  filter(!territorio %in% c("REGIONI", "RIPARTIZIONI GEOGRAFICHE")) |>
  mutate(across(c(nessuna, moderata, grave, non_indicato, totale), ~ {
    .x <- na_if(.x, "..")
    .x <- na_if(.x, "**")
    .x <- na_if(.x, "-")
    as.numeric(.x)
  })) |>
  mutate(territorio = str_squish(str_remove(territorio, "/.*$"))) |>
  mutate(territorio = case_when(
    territorio == "Trentino - Alto Adige" ~ "Trentino Alto Adige",
    TRUE ~ territorio
  )) |>
  relocate(tipo_territorio, .after = territorio) |>
  mutate(
    row_sum = rowSums(across(c(nessuna, moderata, grave, non_indicato)), na.rm = TRUE),
    sum_check = abs(totale - row_sum) < 0.1
  )
# Check and report
if(any(!IADL_reg_perc_clean$sum_check, na.rm = TRUE)) {
  print(IADL_reg_perc_clean |> filter(!sum_check) |>
    select(territorio, tipo_territorio, nessuna:totale, row_sum))
}

IADL_reg_perc_clean <- IADL_reg_perc_clean |> select(-row_sum, -sum_check)
tabyl(IADL_reg_perc_clean, tipo_territorio)

# 2.3 Clean ADL_tipo_anz_perc ----
# Persone di 65 anni e più (MASCHI E FEMMINE) con ADL - per CLASSI DI ETÀ e tipo di attività 
ADL_tipo_anz_perc_clean <- ADL_tipo_anz_perc |>
  remove_empty(which = "rows") |>
  slice(-(1:2)) |>
  setNames(c("attivita", "nessuna", "moderata", "grave", "non_indicato", "totale")) |>
  slice(-(1:2)) |>
  # Fill down the sesso and classe_eta groupings
  mutate(
    # Identify section headers (MASCHI E FEMMINE, age classes, TOTALE)
    is_sesso = str_detect(attivita, "^MASCHI|^FEMMINE"),
    is_classe_eta = str_detect(attivita, "^[0-9]{2}"),
    is_totale_section = attivita == "TOTALE",
    # Create tracking variables
    sesso = case_when(
      str_detect(attivita, "^MASCHI E FEMMINE") ~ "totale",
      str_detect(attivita, "^MASCHI") ~ "maschi",
      str_detect(attivita, "^FEMMINE") ~ "femmine",
      TRUE ~ NA_character_
    ),
    classe_eta = case_when(
      str_detect(attivita, "^65-74") ~ "65-74",
      str_detect(attivita, "^75 ANNI") ~ "75+",
      attivita == "TOTALE" ~ "totale",
      TRUE ~ NA_character_
    )
  ) |>
  # Fill down sesso and classe_eta
  fill(sesso, .direction = "down") |>
  fill(classe_eta, .direction = "down") |>
  # Keep only actual activity rows (not headers)
  filter(!is_sesso, !is_classe_eta, !is_totale_section) |>
  select(-is_sesso, -is_classe_eta, -is_totale_section) |>
  # Convert numeric columns
  mutate(across(c(nessuna, moderata, grave, non_indicato, totale), ~ {
    .x <- na_if(.x, "..")
    .x <- na_if(.x, "**")
    .x <- na_if(.x, "-")
    as.numeric(.x)
  })) |>
  # Clean activity names
  mutate(attivita = str_squish(attivita)) |>
  # Reorder columns
  relocate(sesso, classe_eta, .after = attivita) |>
  # Check totals
  mutate(
    row_sum = rowSums(across(c(nessuna, moderata, grave, non_indicato)), na.rm = TRUE),
    sum_check = abs(totale - row_sum) < 1
  )
# Check and report
if(any(!ADL_tipo_anz_perc_clean$sum_check, na.rm = TRUE)) {
  print(ADL_tipo_anz_perc_clean |> filter(!sum_check) |>
    select(attivita, sesso, classe_eta, nessuna:totale, row_sum))
}

ADL_tipo_anz_perc_clean <- ADL_tipo_anz_perc_clean |> select(-row_sum, -sum_check)

# 2.4 Clean IADL_tipo_perc ----
# Persone di 65 anni e più (MASCHI E FEMMINE) con IADL - per CLASSI DI ETÀ e tipo di attività domestica
IADL_tipo_perc_clean <- IADL_tipo_perc |>
  remove_empty(which = "rows") |>
  slice(-(1:2)) |>
  setNames(c("attivita", "nessuna", "moderata", "grave", "non_indicato", "non_rispondenti", "totale")) |>
  slice(-(1:2)) |>
  mutate(
    is_sesso = str_detect(attivita, "^MASCHI|^FEMMINE"),
    is_classe_eta = str_detect(attivita, "^[0-9]{2}"),
    is_totale_section = attivita == "TOTALE",
    sesso = case_when(
      str_detect(attivita, "^MASCHI E FEMMINE") ~ "totale",
      str_detect(attivita, "^MASCHI") ~ "maschi",
      str_detect(attivita, "^FEMMINE") ~ "femmine",
      TRUE ~ NA_character_
    ),
    classe_eta = case_when(
      str_detect(attivita, "^65-74") ~ "65-74",
      str_detect(attivita, "^75 ANNI") ~ "75+",
      attivita == "TOTALE" ~ "totale",
      TRUE ~ NA_character_
    )
  ) |>
  fill(sesso, .direction = "down") |>
  fill(classe_eta, .direction = "down") |>
  filter(!is_sesso, !is_classe_eta, !is_totale_section) |>
  select(-is_sesso, -is_classe_eta, -is_totale_section) |>
  mutate(across(c(nessuna, moderata, grave, non_indicato, non_rispondenti, totale), ~ {
    .x <- na_if(.x, "..")
    .x <- na_if(.x, "**")
    .x <- na_if(.x, "-")
    as.numeric(.x)
  })) |>
  mutate(attivita = str_squish(attivita)) |>
  # Remove metadata rows (notes about missing data)
  filter(!str_detect(attivita, "^I dati mancanti")) |>
  relocate(sesso, classe_eta, .after = attivita) |>
  mutate(
    row_sum = rowSums(across(c(nessuna, moderata, grave, non_indicato, non_rispondenti)), na.rm = TRUE),
    sum_check = abs(totale - row_sum) < 1
  )

# Check and report
if(any(!IADL_tipo_perc_clean$sum_check, na.rm = TRUE)) {
  print(IADL_tipo_perc_clean |> filter(!sum_check) |>
    select(attivita, sesso, classe_eta, nessuna:totale, row_sum))
}

IADL_tipo_perc_clean <- IADL_tipo_perc_clean |> select(-row_sum, -sum_check)

# 3. SAVE PROCESSED DATA ----

output_dir <- here::here("data/data_out/istat_EHIS_2019")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Save cleaned datasets
saveRDS(ADL_reg_perc_clean, file.path(output_dir, "ADL_reg_perc_clean.rds"))
saveRDS(ADL_tipo_anz_perc_clean, file.path(output_dir, "ADL_tipo_anz_perc_clean.rds"))
saveRDS(IADL_reg_perc_clean, file.path(output_dir, "IADL_reg_perc_clean.rds"))
saveRDS(IADL_tipo_perc_clean, file.path(output_dir, "IADL_tipo_perc_clean.rds"))

cat("\n✓ Saved 4 cleaned datasets to:", output_dir, "\n") 

