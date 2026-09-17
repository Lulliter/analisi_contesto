# ___________________________________________________________________________
# Ingestione: ISTAT, Bes dei territori (edizione 2025) — tutti i domini
# Input:  dati/grezzi/istat_bes_territori/Bes_dei_territori_indic_per_prov_sesso_ed2025.xlsx
#         (tavola unica: dominio × indicatore × sesso × territorio; anni in colonne V2004..V2024)
# Output: dati/puliti/istat_bes/bes_territori.rds + .csv (formato lungo: 1 riga =
#         indicatore × sesso × territorio × anno; tutte le province italiane,
#         regioni, ripartizioni, Italia — così serve a più moduli)
# NB: fonte MULTI-modulo (istruzione, salute, lavoro, redditi, servizi...):
#     i moduli filtrano da qui, non rileggono l'xlsx
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(readr)
library(readxl)
library(stringr)
library(tidyr)

# Parametri ---------------------------------------------------------------
EDIZIONE <- 2025
file_bes <- here("dati", "grezzi", "istat_bes_territori",
                 "Bes_dei_territori_indic_per_prov_sesso_ed2025.xlsx")
dir_out <- here("dati", "puliti", "istat_bes")
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)

# 1. Carica input ---------------------------------------------------------
bes_grezzo <- read_excel(file_bes, col_types = "text") # tutto testo: i valori sono "12,3"
bes_grezzo

# 2. Formato lungo --------------------------------------------------------
# Il codice territorio W_GEO dice il livello (verificato sull'edizione 2025):
#   Italia "90-00-000"; ripartizioni "10-00-000a" (Nord), "20-00-000" (Centro),
#   "30-00-000a" (Mezzogiorno)...; regioni "02-09-000" (ER);
#   province "02-09-040" (Parma) → le ultime 3 cifre = codice ISTAT provincia
bes_territori <- bes_grezzo |>
  pivot_longer(starts_with("V20"), names_to = "anno", values_to = "valore") |>
  filter(!is.na(valore), valore != "") |>
  mutate(
    anno = as.integer(str_remove(anno, "^V")),
    valore = as.numeric(str_replace(valore, ",", ".")),
    livello = case_when(
      TERRITORIO == "Italia" ~ "italia",
      str_detect(W_GEO, "-00-000") ~ "ripartizione",
      str_ends(W_GEO, "-000") ~ "regione",
      .default = "provincia"
    ),
    cod_provincia = if_else(livello == "provincia", str_sub(W_GEO, -3, -1), NA_character_),
    edizione = EDIZIONE
  ) |>
  select(
    edizione, dominio = DOMINIO, cod_indicatore = CODICE, indicatore = INDICATORE,
    sesso = SESSO, cod_territorio = W_GEO, territorio = TERRITORIO, livello, cod_provincia,
    anno, valore, unita_misura = UNITA_MISURA, fonte = FONTE, nota = NOTA
  ) |>
  arrange(dominio, cod_indicatore, sesso, cod_territorio, anno)

bes_territori

# 3. Salva ----------------------------------------------------------------
saveRDS(bes_territori, file.path(dir_out, "bes_territori.rds"))
write_csv(bes_territori, file.path(dir_out, "bes_territori.csv"))

# Verifiche rapide (da eseguire a mano) ------------------------------------
bes_territori |> distinct(livello, territorio) |> count(livello) # atteso: 111 province (107 + 4 vecchie sarde con serie interrotte), 20 regioni (Trento solo come provincia), 7 ripartizioni, 1 Italia
bes_territori |> distinct(dominio, cod_indicatore, indicatore) |> count(dominio)
bes_territori |> filter(cod_indicatore == "02IST006-N22", territorio == "Parma", sesso == "Totale") # NEET: 2024 = 10,9
