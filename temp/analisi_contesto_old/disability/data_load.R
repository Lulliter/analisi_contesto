# Caricamento e pulizia dei dati GALI (Global Activity Limitation Indicator) ----
# Fonte: ISTAT - Disabilità in Cifre, Anno 2023
# Dati su limitazioni nelle attività abituali per età e regione

library(readr)
library(dplyr)
library(readxl)
library(tidyr)
library(here)


# 1. LOAD RAW DATA ----
gali_raw <- read_excel(
  here::here("data/data_in/ISTAT_DISAB_CIFRE/GALI_2023_eta_regione.xls"),
  sheet = "2023_eta_regione"
)


# 2. CREATE MASTER DATAFRAME: gali_all ----

# This is the COMPLETE dataset with EVERYTHING from the raw data

# Ripartizione mapping (for labeling regions)
ripartizioni_map <- tribble(
  ~territorio             , ~ripartizione ,
  "Piemonte"              , "Nord-ovest"  ,
  "Valle d'Aosta"         , "Nord-ovest"  ,
  "Lombardia"             , "Nord-ovest"  ,
  "Liguria"               , "Nord-ovest"  ,
  "Trentino Alto Adige"   , "Nord-est"    , # Note: no hyphen (matches raw data)
  "Veneto"                , "Nord-est"    ,
  "Friuli-Venezia Giulia" , "Nord-est"    ,
  "Emilia-Romagna"        , "Nord-est"    ,
  "Toscana"               , "Centro"      ,
  "Umbria"                , "Centro"      ,
  "Marche"                , "Centro"      ,
  "Lazio"                 , "Centro"      ,
  "Abruzzo"               , "Sud"         ,
  "Molise"                , "Sud"         ,
  "Campania"              , "Sud"         ,
  "Puglia"                , "Sud"         ,
  "Basilicata"            , "Sud"         ,
  "Calabria"              , "Sud"         ,
  "Sicilia"               , "Isole"       ,
  "Sardegna"              , "Isole"       ,
  "Italia"                , "Italia"
)

# Create MASTER: clean and pivot raw data to long format
gali_all <- gali_raw %>%
  # Clean column names
  rename(
    territorio = Territorio,
    limitazioni = livello_gravità_limitazioni,
    eta_0_44 = `0-44 anni`,
    eta_45_64 = `45-64 anni`,
    eta_65_74 = `65-74 anni`,
    eta_75_plus = `75 anni e più`,
    media_generale = `media generale`
  ) %>%
  # Pivot age classes to long format
  pivot_longer(
    cols = c(eta_0_44, eta_45_64, eta_65_74, eta_75_plus, media_generale),
    names_to = "classe_eta",
    values_to = "percentuale"
  ) %>%
  # Clean age class labels
  mutate(
    classe_eta = recode(
      classe_eta,
      "eta_0_44" = "0-44 anni",
      "eta_45_64" = "45-64 anni",
      "eta_65_74" = "65-74 anni",
      "eta_75_plus" = "75+ anni",
      "media_generale" = "Tutte le età"
    )
  ) %>%
  # Add ripartizione label
  left_join(ripartizioni_map, by = "territorio") %>%
  # Add tipo_territorio classification
  mutate(
    tipo_territorio = case_when(
      territorio == "Italia" ~ "Nazionale",
      territorio %in%
        c("Nord-ovest", "Nord-est", "Centro", "Sud", "Isole") ~ "Ripartizione",
      TRUE ~ "Regione"
    )
  ) %>%
  # Factor levels for ordering
  mutate(
    classe_eta = factor(
      classe_eta,
      levels = c(
        "0-44 anni",
        "45-64 anni",
        "65-74 anni",
        "75+ anni",
        "Tutte le età"
      )
    ),
    limitazioni = factor(
      limitazioni,
      levels = c(
        "Senza limitazioni", # No limitations
        "Limitazioni non gravi", # Non-severe limitations
        "Limitazioni gravi", # Severe limitations (= disability)
        "Non indicato" # Not specified
      )
    ),
    tipo_territorio = factor(
      tipo_territorio,
      levels = c("Regione", "Ripartizione", "Nazionale")
    )
  ) %>%
  # Reorder columns for clarity
  select(
    territorio,
    tipo_territorio,
    ripartizione,
    limitazioni,
    classe_eta,
    percentuale
  )

# Verify master contains everything and check for NAs ----
# Run these to check the data:
# unique(gali_all$territorio)
# table(gali_all$tipo_territorio)
#
# Check for NAs (there should be NONE):
# sum(is.na(gali_all$limitazioni))  # Should be 0
# sum(is.na(gali_all$ripartizione)) # Should be 0
#
# If you see NAs in ripartizione, check which territories are missing:
# gali_all %>%
#   filter(is.na(ripartizione)) %>%
#   distinct(territorio)


# 3. CREATE KEY SUBSETS ----

# STEP 1: Calculate RIPARTIZIONI (not in raw data) ----
gali_ripartizioni <- gali_all %>%
  filter(tipo_territorio == "Regione") %>%
  group_by(ripartizione, limitazioni, classe_eta) %>%
  summarise(percentuale = mean(percentuale, na.rm = TRUE), .groups = "drop") %>%
  rename(territorio = ripartizione) %>%
  mutate(
    tipo_territorio = "Ripartizione",
    ripartizione = territorio
  )

# STEP 2: Create extended dataset WITH ripartizioni ----
gali_all_w_ripart <- bind_rows(
  gali_all,
  gali_ripartizioni
)

# STEP 2.5: Create dataset WITH COLLAPSED CATEGORIES ----
# This version replaces component categories with aggregated ones for simpler analysis

# Calculate collapsed age: Anziani (65+) = average of "65-74 anni" + "75+ anni"
# For non-collapsed limitation levels
gali_anziani <- gali_all_w_ripart %>%
  filter(
    classe_eta %in% c("65-74 anni", "75+ anni"),
    !limitazioni %in% c("Limitazioni gravi", "Limitazioni non gravi")
  ) %>%
  group_by(territorio, tipo_territorio, ripartizione, limitazioni) %>%
  summarise(percentuale = mean(percentuale, na.rm = TRUE), .groups = "drop") %>%
  mutate(classe_eta = "Anziani (65+)")

# Calculate collapsed limitation: Limitazioni (qualsiasi) = average of gravi + non gravi
# For non-collapsed age classes
gali_limitazioni_any <- gali_all_w_ripart %>%
  filter(
    limitazioni %in% c("Limitazioni gravi", "Limitazioni non gravi"),
    !classe_eta %in% c("65-74 anni", "75+ anni")
  ) %>%
  group_by(territorio, tipo_territorio, ripartizione, classe_eta) %>%
  summarise(percentuale = mean(percentuale, na.rm = TRUE), .groups = "drop") %>%
  mutate(limitazioni = "Limitazioni (lieve o grave)")

# Calculate cross product: Anziani (65+) × Limitazioni (qualsiasi)
gali_anziani_limit_any <- gali_all_w_ripart %>%
  filter(
    classe_eta %in% c("65-74 anni", "75+ anni"),
    limitazioni %in% c("Limitazioni gravi", "Limitazioni non gravi")
  ) %>%
  group_by(territorio, tipo_territorio, ripartizione) %>%
  summarise(percentuale = mean(percentuale, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    classe_eta = "Anziani (65+)",
    limitazioni = "Limitazioni (lieve o grave)"
  )

# Create collapsed dataset: drop components, add collapsed categories
gali_all_w_ripart_clps <- gali_all_w_ripart %>%
  # Remove component age classes
  filter(!classe_eta %in% c("65-74 anni", "75+ anni")) %>%
  # Remove component limitation levels
  filter(!limitazioni %in% c("Limitazioni gravi", "Limitazioni non gravi")) %>%
  # Add all collapsed categories
  bind_rows(gali_anziani) %>%
  bind_rows(gali_limitazioni_any) %>%
  bind_rows(gali_anziani_limit_any) %>%
  # Update factor levels
  mutate(
    classe_eta = factor(
      classe_eta,
      levels = c("0-44 anni", "45-64 anni", "Anziani (65+)", "Tutte le età")
    ),
    limitazioni = factor(
      limitazioni,
      levels = c("Senza limitazioni", "Limitazioni (lieve o grave)", "Non indicato")
    )
  )

# STEP 3: Key comparison territories ----
territori_confronto <- c(
  "Emilia-Romagna",
  "Lombardia",
  "Nord-est",
  "Nord-ovest",
  "Italia"
)

# # STEP 4: Create a key comparison dataset
# gali_all_compare <- gali_all_w_ripart %>%
#   filter(territorio %in% territori_confronto)
# 

# 4. SAVE PROCESSED DATA ----
output_dir <- here::here("data/data_out/istat_GALI_2023")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Save master dataframe
saveRDS(
  gali_all,
  file.path(output_dir, "gali_all.rds")
)

# Save subsets
saveRDS(gali_all_w_ripart, file.path(output_dir, "gali_all_w_ripart.rds"))
saveRDS(gali_all_w_ripart_clps, file.path(output_dir, "gali_all_w_ripart_clps.rds"))
# saveRDS(gali_all_compare, file.path(output_dir, "gali_all_compare.rds"))


# 5. PREPARE SHAPEFILE (for maps) ----
shp_rds_path <- here::here("data/data_out/ITA_shp/regioni_ita_full.rds")

if (file.exists(shp_rds_path)) {
  regioni_ita <- readRDS(shp_rds_path)
  message("✓ Shapefile loaded from: ", shp_rds_path)
} else {
  library(sf)
  message("Preparing shapefile from scratch...")

  regioni_ita_raw <- st_read(
    here::here("data/data_in/istat_shp_ITA/Reg01012025/Reg01012025_WGS84.shp"),
    quiet = TRUE
  )

  # Ripartizioni mapping
  ripartizioni_nomi <- tribble(
    ~COD_RIP , ~ripartizione ,
           1 , "Nord-ovest"  ,
           2 , "Nord-est"    ,
           3 , "Centro"      ,
           4 , "Sud"         ,
           5 , "Isole"
  )

  # Clean and prepare
  regioni_ita <- regioni_ita_raw %>%
    mutate(
      territorio = case_when(
        DEN_REG == "Valle d'Aosta/Vallée d'Aoste" ~ "Valle d'Aosta",
        DEN_REG == "Trentino-Alto Adige/Südtirol" ~ "Trentino-Alto Adige",
        TRUE ~ DEN_REG
      )
    ) %>%
    left_join(ripartizioni_nomi, by = "COD_RIP")

  # Save
  output_dir_shp <- here::here("data/data_out/ITA_shp")
  if (!dir.exists(output_dir_shp)) {
    dir.create(output_dir_shp, recursive = TRUE)
  }
  saveRDS(regioni_ita, file = shp_rds_path)
  message("✓ Shapefile saved to: ", shp_rds_path)
}


# 6. DATA DICTIONARY (as comments for reference) ----

# MAIN DATASETS CREATED:
#
# 1. gali_all (MASTER - saved as gali_all.rds)
#    - Source: Raw ISTAT data, cleaned and pivoted to long format
#    - Contains: 20 regions + Italia = 21 territories
#    - Columns:
#      * territorio: region name or 'Italia'
#      * tipo_territorio: 'Regione' or 'Nazionale'
#      * ripartizione: macro-region (Nord-ovest, Nord-est, Centro, Sud, Isole, Italia)
#      * limitazioni: "Senza limitazioni", "Limitazioni non gravi", "Limitazioni gravi", "Non indicato"
#      * classe_eta: "0-44 anni", "45-64 anni", "65-74 anni", "75+ anni", "Tutte le età"
#      * percentuale: % of population with that limitation level
#    - Rows: 21 territories × 4 limitazioni × 5 age classes = 420 rows
#
# 2. gali_ripartizioni
#    - Source: Calculated as mean of regions within each ripartizione
#    - Contains: 5 ripartizioni (Nord-ovest, Nord-est, Centro, Sud, Isole)
#    - Same structure as gali_all
#    - Rows: 5 ripartizioni × 4 limitazioni × 5 age classes = 100 rows
#
# 3. gali_all_w_ripart (saved as gali_all_w_ripart.rds)
#    - Source: gali_all + gali_ripartizioni combined
#    - Contains: 20 regions + 5 ripartizioni + Italia = 26 territories
#    - Same structure as gali_all
#    - Rows: 26 territories × 4 limitazioni × 5 age classes = 520 rows
#
# 4. gali_all_compare (saved as gali_all_compare.rds)
#    - Source: Filtered from gali_all_w_ripart
#    - Contains: 5 key comparison territories
#      * Emilia-Romagna (region)
#      * Lombardia (region)
#      * Nord-est (ripartizione)
#      * Nord-ovest (ripartizione)
#      * Italia (national)
#    - Rows: 5 territories × 4 limitazioni × 5 age classes = 100 rows
#
# USAGE EXAMPLES:
#   # View all territories in master
#   unique(gali_all$territorio)
#
#   # Filter for Emilia-Romagna only
#   gali_all %>% filter(territorio == "Emilia-Romagna")
#
#   # Get all regions in Nord-est (from master)
#   gali_all %>% filter(ripartizione == "Nord-est")
#
#   # Use extended dataset for ripartizione comparisons
#   gali_all_w_ripart %>%
#     filter(territorio %in% c("Nord-est", "Nord-ovest", "Centro"))
#
#   # Compare disability (Limitazioni gravi) across key territories
#   gali_all_compare %>%
#     filter(limitazioni == "Limitazioni gravi", classe_eta == "75+ anni")
#
#   # Create custom subsets
#   gali_anziani <- gali_all %>%
#     filter(classe_eta %in% c("65-74 anni", "75+ anni"))
