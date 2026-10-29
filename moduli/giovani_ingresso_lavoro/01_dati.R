# ___________________________________________________________________________
# Modulo: giovani_ingresso_lavoro
# Fonte:  Regione Emilia-Romagna, Report giovani 2026 (elaborazioni su ISTAT, forze di lavoro:
#         stime campionarie), Tab. 14-19, estratte dal pdf con 00_prep_condizione_pdf.R
# Input:  moduli/giovani_ingresso_lavoro/output/condizione_pdf.rds (valori come stampati, formato lungo)
#         moduli/giovani_ingresso_lavoro/output/aire_pdf.rds (iscritti AIRE, Tab. 2-3, da 00_prep_aire_pdf.R)
# Output: moduli/giovani_ingresso_lavoro/output/condizione_rev.rds (+ .csv)
#           colonne: territorio, classe_eta, sesso, indicatore, anno, misura, valore, revisione, fonte
#           = i valori stampati (revisione NA) + i valori ricavati qui (revisione dice come):
#           § 2 migliaia per sesso 2024 e 2019, ricostruite dalle var. % della Tab. 15
#           § 3 tassi ER 2019 e 2024 (per età e sesso), calcolati dalle migliaia
#           § 3b iscritti AIRE (Tab. 2-3), con i valori assoluti di Parma e Piacenza rimessi al loro posto
# NB: i valori ricavati poggiano su dati arrotondati (migliaia e var. % con un decimale):
#     scarti di 0,1-0,2 rispetto a quanto la Regione calcolerebbe sui dati originali
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(tidyr)
library(readr)

# Parametri ---------------------------------------------------------------
ANNO <- 2025
dir_out <- here("moduli", "giovani_ingresso_lavoro", "output")
file_in <- file.path(dir_out, "condizione_pdf.rds")
file_aire <- file.path(dir_out, "aire_pdf.rds")

# etichette dei territori come le vogliamo nei grafici (stampato → rivisto)
TERRITORI_REV <- c("EU 27" = "UE 27")

# 1. Carica input ---------------------------------------------------------
condizione_pdf <- readRDS(file_in)
count(condizione_pdf, tabella, misura)

# 2. Migliaia per sesso 2024 e 2019, ricostruite dalle var. % (Tab. 15) ----
# la Tab. 15 stampa per sesso solo il 2025 e le var. %: valore 2024 = valore 2025 / (1 + var. % su 2024 / 100),
# idem per il 2019
sesso_calc <- condizione_pdf |>
  filter(tabella == "15") |>
  select(classe_eta, sesso, indicatore, misura, valore) |>
  pivot_wider(names_from = misura, values_from = valore) |>
  mutate(migliaia_2024_calc = migliaia / (1 + var_pct_su_2024 / 100),
         migliaia_2019_calc = migliaia / (1 + var_pct_su_2019 / 100))
sesso_calc

# controllo: maschi + femmine ricostruiti = totale stampato nella Tab. 14 (scarti attesi entro ±0,2)
controllo_sesso_calc <- sesso_calc |>
  summarise(somma_2024 = sum(migliaia_2024_calc), somma_2019 = sum(migliaia_2019_calc),
            .by = c(classe_eta, indicatore)) |>
  left_join(condizione_pdf |>
              filter(tabella == "14", misura == "migliaia", anno %in% c(2019, 2024)) |>
              select(classe_eta, indicatore, anno, valore) |>
              pivot_wider(names_from = anno, names_prefix = "t14_", values_from = valore),
            by = c("classe_eta", "indicatore")) |>
  mutate(scarto_2024 = round(somma_2024 - t14_2024, 1), scarto_2019 = round(somma_2019 - t14_2019, 1))
controllo_sesso_calc
stopifnot(all(abs(controllo_sesso_calc$scarto_2024) <= 0.25), all(abs(controllo_sesso_calc$scarto_2019) <= 0.25))

# in formato lungo, come le righe stampate
sesso_calc_long <- sesso_calc |>
  select(classe_eta, sesso, indicatore, migliaia_2024_calc, migliaia_2019_calc) |>
  pivot_longer(starts_with("migliaia"), names_to = "anno", values_to = "valore") |>
  mutate(anno = parse_number(anno),
         territorio = "Emilia-Romagna", misura = "migliaia",
         revisione = "ricostruito dalla var. % stampata (Tab. 15)")

# 3. Tassi ER 2019 e 2024 calcolati dalle migliaia ----
# i tassi sono stampati solo per il 2025 (Tab. 16-18): per 2019 e 2024 si calcolano dalle migliaia
# della Tab. 14 (totale) e dal § 2 (per sesso). Popolazione = forze di lavoro + inattivi
# attività = forze di lavoro / popolazione; occupazione = occupati / popolazione;
# disoccupazione = in cerca / forze di lavoro
livelli_er <- bind_rows(
  condizione_pdf |>
    filter(tabella == "14", misura == "migliaia", classe_eta %in% c("15-24", "25-34")) |>
    select(classe_eta, sesso, indicatore, anno, valore),
  sesso_calc_long |>
    select(classe_eta, sesso, indicatore, anno, valore)
) |>
  filter(anno != ANNO)
count(livelli_er, anno, sesso)   # attese 8 righe per anno × sesso

tassi_calc <- livelli_er |>
  pivot_wider(names_from = indicatore, values_from = valore) |>
  transmute(classe_eta, sesso, anno,
            tasso_attivita       = forza_lavoro / (forza_lavoro + inattivi) * 100,
            tasso_occupazione    = occupati / (forza_lavoro + inattivi) * 100,
            tasso_disoccupazione = in_cerca / forza_lavoro * 100) |>
  pivot_longer(starts_with("tasso"), names_to = "indicatore", values_to = "valore") |>
  mutate(territorio = "Emilia-Romagna", misura = "pct",
         revisione = if_else(sesso == "Totale",
                             "calcolato dalle migliaia stampate (Tab. 14)",
                             "calcolato dalle migliaia ricostruite (§ 2)"))
tassi_calc |> filter(sesso == "Totale", classe_eta == "25-34")
# attesi 25-34 totale: occupazione 75,6 (2019) e 78,8 (2024); disoccupazione 8,7 e 6,1
# (78,8 e 6,1 sono i valori 2024 citati nel testo della versione web del Report)

# 3b. Iscritti AIRE (Tab. 2-3) --------------------------------------------
aire_pdf <- readRDS(file_aire)
count(aire_pdf, tabella, misura)

# correzione: nella Tab. 3 i valori ASSOLUTI di Parma e Piacenza sono scambiati tra le due righe
# (gli iscritti ogni 1.000 no; vedi 00_prep_aire_pdf.R § 4e): a ciascuna delle due si dà il valore
# stampato nella riga dell'altra
aire_scambio <- aire_pdf |>
  filter(tabella == "3", misura == "n", territorio %in% c("Parma", "Piacenza")) |>
  transmute(territorio = if_else(territorio == "Parma", "Piacenza", "Parma"),
            classe_eta, misura, valore_altra_riga = valore)
aire_scambio   # attese 4 righe: Parma 34.722 (tutte le età) e 7.177 (19-34); Piacenza 24.976 e 5.121

aire_long <- aire_pdf |>
  # i totali regionali della Tab. 3 sono identici alla Tab. 2 (verificato in 00_prep_aire § 4d): resta la Tab. 2
  filter(!(tabella == "3" & territorio == "Emilia-Romagna" & misura == "n")) |>
  left_join(aire_scambio, by = c("territorio", "classe_eta", "misura")) |>
  mutate(revisione = if_else(!is.na(valore_altra_riga),
                             "valore assoluto scambiato tra Parma e Piacenza (errore della Tab. 3, vedi 00_prep_aire_pdf.R)",
                             NA_character_),
         valore = coalesce(valore_altra_riga, valore),
         sesso = "Totale") |>
  select(-valore_altra_riga)

# controllo: popolazione implicita (iscritti / iscritti ogni 1.000 × 1.000) dopo la correzione
# (gli iscritti dell'Emilia-Romagna vengono dalla Tab. 2, perché quelli della Tab. 3 sono tolti sopra:
# per questo il filtro è sull'anno e non sulla tabella)
aire_long |>
  filter(anno == 2025, classe_eta == "totale", misura %in% c("n", "per_1000")) |>
  select(territorio, misura, valore) |>
  pivot_wider(names_from = misura, values_from = valore) |>
  mutate(pop_implicita = round(n / per_1000 * 1000))
# attese circa: Parma 456 mila, Piacenza 286 mila (prima della correzione erano rovesciate);
# Emilia-Romagna 4,46 milioni

# 4. Dataset rivisto ------------------------------------------------------
# righe stampate (revisione NA) + righe ricavate; valori ricavati arrotondati a un decimale,
# come quelli stampati
# la riga Emilia-Romagna della Tab. 19 è identica alla Tab. 17-18 (25-34; verificato in 00_prep § 6e):
# si tiene una volta sola, quella delle Tab. 17-18
condizione_rev <- bind_rows(
  condizione_pdf |>
    filter(!(tabella == "19" & territorio == "Emilia-Romagna")) |>
    mutate(revisione = NA_character_),
  sesso_calc_long |> mutate(tabella = "15", fonte = unique(condizione_pdf$fonte[condizione_pdf$tabella == "15"])),
  tassi_calc |> mutate(tabella = "14-15", fonte = "calcolo su RER Report giovani 2026, Tab. 14-15"),
  # iscritti AIRE (dal 2026-10-29)
  aire_long
) |>
  mutate(valore = if_else(is.na(revisione), valore, round(valore, 1)),
         territorio = recode(territorio, !!!TERRITORI_REV)) |>
  select(territorio, classe_eta, sesso, indicatore, anno, misura, valore, revisione, tabella, fonte) |>
  arrange(tabella, territorio, classe_eta, sesso, indicatore, misura, anno)

condizione_rev
count(condizione_rev, tabella, revisione)

# controllo: nessun doppione sulla chiave
stopifnot(!anyDuplicated(condizione_rev[, c("territorio", "classe_eta", "sesso", "indicatore", "anno", "misura")]))

# 5. Salva ----------------------------------------------------------------
saveRDS(condizione_rev, file.path(dir_out, "condizione_rev.rds"))
write_csv(condizione_rev, file.path(dir_out, "condizione_rev.csv"))

# Verifiche rapide (da eseguire a mano) -----------------------------------

# Parma, 25-34, 2025: occupazione M 84,6 / F 68,3 / T 77,2; disoccupazione 3,7 / 7,6 / 5,3
condizione_rev |>
  filter(territorio == "Parma") |>
  select(indicatore, sesso, valore)

# ER 25-34, maschi: occupazione 2024 (calcolata) 85,6 → 2025 (stampata) 87,8, cioè +2,3 punti
# come nel testo della versione web del Report ("+2,3 punti percentuali")
condizione_rev |>
  filter(territorio == "Emilia-Romagna", classe_eta == "25-34", sesso == "Maschi",
         indicatore == "tasso_occupazione") |>
  select(anno, valore, revisione)

# Parma, iscritti AIRE di 19-34 anni nel 2025: 7.177 (corretto; il Report stampa 5.121), 92,0 ogni 1.000
condizione_rev |>
  filter(indicatore == "iscritti_aire", territorio == "Parma") |>
  select(classe_eta, misura, valore, revisione)
