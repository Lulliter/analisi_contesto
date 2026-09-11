# ------------------------------------------------------------------------
# Ingestione: ISTAT, Bes nazionale (Rapporto Bes 2024, aggiornamento intermedio 2026) — tutti i domini
# Input:  dati/grezzi/istat_bes/Bes_2024_dati_agg2026/
#           indicatori_regione_sesso.xlsx            (indicatore × sesso × regione/ripartizione/Italia)
#           indicatori_eta_sesso.xlsx                (indicatore × sesso × classe d'età, solo Italia)
#           indicatori_titolo_di_studio.xlsx         (indicatore × sesso × età × titolo, solo Italia; Foglio1)
#           indicatori_titolo_di_studio_ripartizione.xlsx (idem, per Nord/Centro/Mezzogiorno/Italia)
#         anni in colonne 2004..2026 (2026 vuota nell'aggiornamento 2026)
# Output: dati/puliti/istat_bes/bes_regioni.rds, bes_eta_sesso.rds, bes_titolo_studio.rds (+ .csv)
#         formato lungo come bes_territori: 1 riga = indicatore × dimensioni × anno
# NB: fonte MULTI-modulo, solo regionale/nazionale: la cornice per i dati provinciali del
#     Bes dei territori (04_prep_istat_bes.R). I moduli filtrano da qui, non rileggono gli xlsx
# ------------------------------------------------------------------------

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(readr)
library(readxl)
library(stringr)
library(tidyr)

# Parametri ---------------------------------------------------------------
EDIZIONE <- "agg2026"   # aggiornamento intermedio 2026 (dati fino al 2025)
dir_bes <- here("dati", "grezzi", "istat_bes", "Bes_2024_dati_agg2026")
dir_out <- here("dati", "puliti", "istat_bes")
ripartizioni <- c("Nord", "Nord-ovest", "Nord-est", "Centro", "Mezzogiorno", "Sud", "Isole")

# Funzione locale: legge un foglio e lo mette in forma lunga --------------
# (tutto testo perché i valori sono "12,3"; le colonne anno sono "2004".."2026")
f_leggi_bes_lungo <- function(file, foglio = 1) {
  read_excel(file, sheet = foglio, col_types = "text") |>
    pivot_longer(matches("^20\\d{2}$"), names_to = "anno", values_to = "valore") |>
    filter(!is.na(valore), valore != "") |>
    mutate(
      anno = as.integer(anno),
      # "(a)" = dato poco significativo (20-49 casi campionari): si tiene il numero e si segna
      poco_signif = str_detect(valore, "\\(a\\)"),
      valore = str_remove(valore, "\\s*\\(a\\)") |> str_trim(),
      # segni convenzionali ISTAT ("-", "..", "....", "*") → NA senza avviso
      valore = if_else(str_detect(valore, "^-?\\d+(,\\d+)?$"), valore, NA_character_),
      valore = as.numeric(str_replace(valore, ",", ".")),
      edizione = EDIZIONE
    ) |>
    filter(!is.na(valore)) |>
    rename(
      dominio = DOMINIO, cod_indicatore = CODICE, indicatore = INDICATORE,
      sesso = SESSO, unita_misura = UNITA_MISURA, fonte = FONTE, nota = NOTA
    )
}

# 1. Per regione e sesso --------------------------------------------------
bes_regioni <- f_leggi_bes_lungo(file.path(dir_bes, "indicatori_regione_sesso.xlsx")) |>
  mutate(
    livello = case_when(
      TERRITORIO == "Italia" ~ "italia",
      TERRITORIO %in% ripartizioni ~ "ripartizione",
      .default = "regione"   # 20 regioni + Trentino-Alto Adige spezzato nelle 2 province autonome
    )
  ) |>
  select(edizione, dominio, cod_indicatore, indicatore, sesso,
         territorio = TERRITORIO, livello, anno, valore, poco_signif, unita_misura, fonte, nota) |>
  arrange(dominio, cod_indicatore, sesso, territorio, anno)

bes_regioni

# 2. Per età e sesso (solo Italia) ----------------------------------------
bes_eta_sesso <- f_leggi_bes_lungo(file.path(dir_bes, "indicatori_eta_sesso.xlsx")) |>
  select(edizione, dominio, cod_indicatore, indicatore, sesso, eta = ETA,
         anno, valore, poco_signif, unita_misura, fonte, nota) |>
  arrange(dominio, cod_indicatore, sesso, eta, anno)

bes_eta_sesso

# 3. Per titolo di studio: Italia + ripartizioni in un'unica tabella ------
# NB: indicatori_titolo_di_studio.xlsx ha un Foglio2 senza intestazione con il solo
#     04BEC002A (disuguaglianza s80/s20 per titolo): ignorato
bes_titolo_studio <- bind_rows(
  f_leggi_bes_lungo(file.path(dir_bes, "indicatori_titolo_di_studio.xlsx"), foglio = "Foglio1") |>
    mutate(TERRITORIO = "Italia"),
  f_leggi_bes_lungo(file.path(dir_bes, "indicatori_titolo_di_studio_ripartizione.xlsx"))
) |>
  select(edizione, dominio, cod_indicatore, indicatore, territorio = TERRITORIO,
         sesso, eta = ETA, titolo_studio = TITOLO_STUDIO,
         anno, valore, poco_signif, unita_misura, fonte, nota) |>
  arrange(dominio, cod_indicatore, territorio, sesso, eta, titolo_studio, anno)

bes_titolo_studio

# 4. Salva ----------------------------------------------------------------
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)
saveRDS(bes_regioni, file.path(dir_out, "bes_regioni.rds"))
write_csv(bes_regioni, file.path(dir_out, "bes_regioni.csv"))
saveRDS(bes_eta_sesso, file.path(dir_out, "bes_eta_sesso.rds"))
write_csv(bes_eta_sesso, file.path(dir_out, "bes_eta_sesso.csv"))
saveRDS(bes_titolo_studio, file.path(dir_out, "bes_titolo_studio.rds"))
write_csv(bes_titolo_studio, file.path(dir_out, "bes_titolo_studio.csv"))

# Verifiche rapide (da eseguire a mano) ------------------------------------
bes_regioni |> distinct(livello, territorio) |> count(livello) # atteso: 22 regioni/PA, 7 ripartizioni, 1 Italia
bes_regioni |> distinct(dominio, cod_indicatore) |> count(dominio) # 12 domini, 153 indicatori
bes_regioni |> filter(cod_indicatore == "02IST005-N22", territorio == "Emilia-Romagna", sesso == "Totale") # uscita precoce: 2025 = 6,0
bes_eta_sesso |> filter(cod_indicatore == "02IST006-N22", sesso == "Totale") |> distinct(eta) # NEET: 15-19, 20-24, 25-29, Totale
