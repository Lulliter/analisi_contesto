# ___________________________________________________________________________
# Modulo: anziani_non_autosuff
# Fonte:  ISTAT EHIS 2019 (prevalenze di gravi limitazioni, trascritte da report ISTAT e
#         Rapporto OLTC CERGAS 2026: dati/grezzi/istat_ehis_2019/); ISTAT censimento 2024
#         per età singola (dati/puliti/istat_cens/); ISTAT previsioni 2024-2050 per
#         classi quinquennali, scenario mediano (dati/puliti/istat_previsioni/)
# Input:  moduli/anziani_non_autosuff/output/prevalenze_pdf.rds (da 00_prep_prevalenze_pdf.R;
#           il csv trascritto a mano in dati/grezzi/istat_ehis_2019/ è solo il controllo)
#         dati/puliti/istat_cens/pop_confronti_eta_2024.rds   (IT / ITD5 / ITD52 × sesso × età singola)
#         dati/puliti/istat_previsioni/previs_pop_eta_province.rds (107 province × anno × classi 5 anni)
#         dati/grezzi/alzheimer_europe/alzheimer_europe_dementia_data_Italy.csv (solo confronto)
# Output: moduli/anziani_non_autosuff/output/anziani_pop_eta.rds (+ .csv)
#           1 riga = territorio × anno (2024, 2036, 2050) × classe d'età (65-74, 75-84, 85+): popolazione
#         moduli/anziani_non_autosuff/output/anziani_stima.rds (+ .csv)
#           1 riga = territorio × anno × classe d'età × indicatore: prevalenza % e n stimato
#         moduli/anziani_non_autosuff/output/anziani_stima_tot.rds (+ .csv)
#           1 riga = territorio × anno: popolazione totale, 15-64, 65+, 80+ (n e %), indice di
#           dipendenza anziani, stima non autosufficienti (larga e stretta), demenze, e % sui 65+
#         moduli/anziani_non_autosuff/output/anziani_demenze_sesso.rds (+ .csv)
#           1 riga = territorio × anno × sesso × classe quinquennale 65+: popolazione, tasso ISS, casi stimati
#         moduli/anziani_non_autosuff/output/anziani_sesso_2024.rds (+ .csv)
#           1 riga = territorio × sesso: 65+ nel 2024 e stima ADL gravi per sesso (prevalenze 65+ M/F)
# NB: il 2024 è il censimento al 31/12/2024; gli anni futuri sono previsioni al 1° gennaio
#     (base 1.1.2024): tra "2024" censuario e "2024" previsto c'è un anno di distanza (+1,3% di 65+)
# NB: metodo = quello dell'Osservatorio LTC (CERGAS Bocconi, 8° Rapporto, cap. 1):
#     prevalenza per classe d'età × popolazione della classe, prevalenza COSTANTE nel tempo
#     (ipotesi forte: ignora miglioramenti o peggioramenti della salute). Due definizioni:
#     - "non autosufficienti" (larga, = CERGAS): gravi difficoltà in almeno una ADL o IADL
#     - "con bisogno di assistenza continuativa" (stretta): gravi difficoltà in almeno una ADL
#     Prevalenze NAZIONALI applicate a tutti i territori: standardizzate per età, ER e Italia
#     coincidono (v. _metadati.md), quindi le differenze tra territori qui sono SOLO di
#     struttura per età
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)

# Parametri ---------------------------------------------------------------
ANNO_OGGI   <- 2024                # censimento (al 31/12/2024), ultimo anno reale (proxy per 2026!)
ANNI_FUTURI <- c(2036, 2050)       # orizzonti: previsioni ISTAT al 1° gennaio, base 1.1.2024
                                   # (2036 = orizzonte della pagina; 2050 = fine delle previsioni,
                                   # quando i baby boomer sono tra gli 80+)

file_prev   <- here("moduli", "anziani_non_autosuff", "output", "prevalenze_pdf.rds")
file_cens   <- here("dati", "puliti", "istat_cens", paste0("pop_confronti_eta_", ANNO_OGGI, ".rds"))
file_previs <- here("dati", "puliti", "istat_previsioni", "previs_pop_eta_province.rds")
dir_out     <- here("moduli", "anziani_non_autosuff", "output")
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)

# territori: codici del censimento (SDMX) e delle previsioni (province)
TERRITORI <- c(ITD52 = "Provincia di Parma", ITD5 = "Emilia-Romagna", IT = "Italia")
COD_PR    <- "034"
source(here("dati", "puliti", "istat_shp", "lista_COD_PROV_er_vec.R"))   # CODICI_PROV_ER
cod_prov_er_3 <- str_pad(CODICI_PROV_ER, 3, pad = "0")

# classi d'età delle prevalenze: 65-74, 75-84, 85+
LIV_CLASSI <- c("65-74", "75-84", "85+")
f_classe_eta <- function(eta) {
  cut(eta, breaks = c(65, 75, 85, Inf), right = FALSE, labels = LIV_CLASSI)
}

# 1. Prevalenze (estratte dai pdf in 00_prep_prevalenze_pdf.R) ---------
prevalenze <- readRDS(file_prev)

prevalenze

# le due definizioni per classe d'età (totale M+F, Italia). Per confrontare con l'originale:
# - gravi_limitazioni_funzionali: CERGAS, 8° Rapporto OLTC, Tab. 1.2 (p. 19 stampata)
# - gravi_difficolta_adl: ISTAT, "Le condizioni di salute della popolazione anziana", p. 2
prev_classi <- prevalenze |>
  filter(classe_eta %in% LIV_CLASSI, sesso == "Totale") |>
  select(indicatore, classe_eta, prevalenza = valore) |>
  mutate(classe_eta = factor(classe_eta, levels = LIV_CLASSI))

prev_classi

# controllo: 3 classi × 2 indicatori (atteso 6 righe, nessun NA)
nrow(prev_classi) == 6 && !anyNA(prev_classi$prevalenza)

# demenze: tassi per sesso × classe quinquennale (65-69 … 90+), Italia
# originale: ISS, Report Nazionale 2024 del Fondo Alzheimer e demenze, Tab. 1.1 (p. 1 del cap. 1 "Epidemiologia")
LIV_QUINQ <- c("65-69", "70-74", "75-79", "80-84", "85-89", "90+")
prev_demenze <- prevalenze |>
  filter(indicatore == "demenze") |>
  select(classe_quinq = classe_eta, sesso, tasso = valore) |>
  mutate(classe_quinq = factor(classe_quinq, levels = LIV_QUINQ))

prev_demenze   # attese 12 righe (6 classi × M/F)

# classi quinquennali da un'età: 65-69, …, 85-89, 90+
f_classe_quinq <- function(eta) {
  cut(eta, breaks = c(seq(65, 90, by = 5), Inf), right = FALSE, labels = LIV_QUINQ)
}

# 2. Popolazione 2024 per classe d'età (censimento, età singola) ----------
pop_cens <- readRDS(file_cens)

# controllo: codici territorio, sesso e cittadinanza presenti
count(pop_cens, territorio); count(pop_cens, sesso); count(pop_cens, cittadinanza)

pop_oggi <- pop_cens |>
  filter(territorio %in% names(TERRITORI), sesso == "T", cittadinanza == "TOTAL") |>
  mutate(territorio = TERRITORI[territorio],
         classe_eta = f_classe_eta(eta)) |>
  summarise(pop_totale = sum(popolazione),
            n15_64     = sum(popolazione[eta >= 15 & eta <= 64]),
            n65_piu    = sum(popolazione[eta >= 65]),
            n80_piu    = sum(popolazione[eta >= 80]),
            .by = territorio) |>
  mutate(anno = ANNO_OGGI)

# per classe (solo 65+)
pop_oggi_classi <- pop_cens |>
  filter(territorio %in% names(TERRITORI), sesso == "T", cittadinanza == "TOTAL", eta >= 65) |>
  mutate(territorio = TERRITORI[territorio],
         classe_eta = f_classe_eta(eta)) |>
  summarise(popolazione = sum(popolazione), .by = c(territorio, classe_eta)) |>
  mutate(anno = ANNO_OGGI)

pop_oggi_classi

# 3. Popolazione 2036 per classe d'età (previsioni, classi quinquennali) --
pop_previs <- readRDS(file_previs)

# controllo: etichette età e anni disponibili
unique(pop_previs$eta); range(pop_previs$anno)

# ER e Italia = somma delle province (il file non ha aggregati); età di inizio
# classe dai primi 2 caratteri ("65-69" → 65, "95+" → 95), come in demo_trend_previs
pop_previs_terr <- bind_rows(
  pop_previs |> filter(codice_provincia == COD_PR)           |> mutate(territorio = "Provincia di Parma"),
  pop_previs |> filter(codice_provincia %in% cod_prov_er_3)  |> mutate(territorio = "Emilia-Romagna"),
  pop_previs                                                 |> mutate(territorio = "Italia")
) |>
  filter(anno %in% ANNI_FUTURI, eta != "Tutte le età") |>
  mutate(eta_num = as.integer(substr(eta, 1, 2))) |>
  summarise(totale = sum(totale), .by = c(territorio, anno, eta_num))

pop_futuro <- pop_previs_terr |>
  summarise(pop_totale = sum(totale),
            # classi quinquennali: 15-64 = classi che iniziano da 15 a 60
            n15_64     = sum(totale[eta_num >= 15 & eta_num <= 60]),
            n65_piu    = sum(totale[eta_num >= 65]),
            n80_piu    = sum(totale[eta_num >= 80]),
            .by = c(territorio, anno))

pop_futuro_classi <- pop_previs_terr |>
  filter(eta_num >= 65) |>
  mutate(classe_eta = f_classe_eta(eta_num)) |>
  summarise(popolazione = sum(totale), .by = c(territorio, anno, classe_eta))

pop_futuro_classi

# 4. Dataset puliti: popolazione per classe e stime per classe -------------
LIV_TERRITORI <- unname(TERRITORI)

anziani_pop_eta <- bind_rows(pop_oggi_classi, pop_futuro_classi) |>
  mutate(territorio = factor(territorio, levels = LIV_TERRITORI)) |>
  select(territorio, anno, classe_eta, popolazione) |>
  arrange(territorio, anno, classe_eta)

# stima = prevalenza (costante, nazionale) × popolazione della classe
anziani_stima <- anziani_pop_eta |>
  inner_join(prev_classi, by = "classe_eta", relationship = "many-to-many") |>
  mutate(n_stimato = round(popolazione * prevalenza / 100)) |>
  arrange(territorio, anno, indicatore, classe_eta)

anziani_stima

# 4b. Demenze: stima per sesso × classe quinquennale ---------------------------
# stesso metodo (tasso ISS × popolazione), ma con sesso e classi fini perché la Tab. 1.1
# le ha; 2024 da età singola e sesso (censimento), 2036/2050 da classi quinquennali M/F
# (previsioni). I casi si sommano in anziani_stima_tot (colonne demenze, pct_demenze), § 4c
pop_sesso_oggi <- pop_cens |>
  filter(territorio %in% names(TERRITORI), sesso %in% c("M", "F"), cittadinanza == "TOTAL", eta >= 65) |>
  mutate(territorio = TERRITORI[territorio],
         sesso = if_else(sesso == "M", "Maschi", "Femmine"),
         classe_quinq = f_classe_quinq(eta)) |>
  summarise(popolazione = sum(popolazione), .by = c(territorio, sesso, classe_quinq)) |>
  mutate(anno = ANNO_OGGI)

pop_sesso_futuro <- bind_rows(
  pop_previs |> filter(codice_provincia == COD_PR)          |> mutate(territorio = "Provincia di Parma"),
  pop_previs |> filter(codice_provincia %in% cod_prov_er_3) |> mutate(territorio = "Emilia-Romagna"),
  pop_previs                                                |> mutate(territorio = "Italia")
) |>
  filter(anno %in% ANNI_FUTURI, eta != "Tutte le età") |>
  mutate(eta_num = as.integer(substr(eta, 1, 2))) |>
  filter(eta_num >= 65) |>
  mutate(classe_quinq = f_classe_quinq(eta_num)) |>
  summarise(Maschi = sum(maschi), Femmine = sum(femmine), .by = c(territorio, anno, classe_quinq)) |>
  pivot_longer(c(Maschi, Femmine), names_to = "sesso", values_to = "popolazione")

anziani_demenze_sesso <- bind_rows(pop_sesso_oggi, pop_sesso_futuro) |>
  mutate(territorio = factor(territorio, levels = LIV_TERRITORI)) |>
  inner_join(prev_demenze, by = c("classe_quinq", "sesso")) |>
  mutate(casi = round(popolazione * tasso / 100)) |>
  select(territorio, anno, sesso, classe_quinq, popolazione, tasso, casi) |>
  arrange(territorio, anno, sesso, classe_quinq)

anziani_demenze_sesso

# 4c. Totali per territorio × anno: 65+, 80+, stime (due definizioni + demenze), % sui 65+ --
anziani_stima_tot <- bind_rows(pop_oggi, pop_futuro) |>
  mutate(territorio = factor(territorio, levels = LIV_TERRITORI)) |>
  left_join(
    anziani_stima |>
      summarise(n_stimato = sum(n_stimato), .by = c(territorio, anno, indicatore)) |>
      pivot_wider(names_from = indicatore, values_from = n_stimato),
    by = c("territorio", "anno")
  ) |>
  left_join(anziani_demenze_sesso |> summarise(demenze = sum(casi), .by = c(territorio, anno)),
            by = c("territorio", "anno")) |>
  mutate(p65_piu = round(n65_piu / pop_totale * 100, 1),
         p80_piu = round(n80_piu / pop_totale * 100, 1),
         # indice di dipendenza anziani: 65+ ogni 100 persone di 15-64 (come demo_trend_previs)
         ind_dip_anziani = round(n65_piu / n15_64 * 100, 1),
         # quota di non autosufficienti sui 65+ (dipende solo dalla struttura per età)
         pct_non_autosuff   = round(gravi_limitazioni_funzionali / n65_piu * 100, 1),
         pct_assist_contin  = round(gravi_difficolta_adl / n65_piu * 100, 1),
         pct_demenze        = round(demenze / n65_piu * 100, 1)) |>
  select(territorio, anno, pop_totale, n15_64, n65_piu, p65_piu, n80_piu, p80_piu, ind_dip_anziani,
         non_autosuff = gravi_limitazioni_funzionali, pct_non_autosuff,
         assist_contin = gravi_difficolta_adl, pct_assist_contin,
         demenze, pct_demenze) |>
  arrange(territorio, anno)

anziani_stima_tot

# 4d. Confronto con Alzheimer Europe 2025 (solo nota di pagina) ----------------
# tassi più recenti, già in csv (dati/grezzi/alzheimer_europe/, report 2025): rapporto tra i
# totali Italia nel 2050, unico anno comune; non entra nelle stime
ae_italia <- read_csv(here("dati", "grezzi", "alzheimer_europe", "alzheimer_europe_dementia_data_Italy.csv"),
                      show_col_types = FALSE) |>
  filter(!Age %in% c("30-59", "60-64")) |>
  summarise(casi_ae = sum(Total), .by = Year)

ae_italia   # 65+: 2025 ~1,38 mln; 2050 ~2,18 mln

confronto_demenze_ae <- anziani_stima_tot |>
  filter(territorio == "Italia", anno == 2050) |>
  select(anno, demenze_iss = demenze) |>
  left_join(ae_italia |> filter(Year == 2050) |> select(anno = Year, casi_ae), by = "anno") |>
  mutate(rapporto_ae_iss = round(casi_ae / demenze_iss, 2))

confronto_demenze_ae   # rapporto atteso ~1,15-1,2: "con i tassi europei più recenti circa un sesto in più"

# 5. Dettaglio per sesso, solo 2024 (prevalenze ADL 65+ M/F; demenze da § 4b) --
# il rapporto donne/uomini cambia poco nel tempo (demenze Parma: 2,3 nel 2024, 2,0 nel 2050):
# basta il 2024
prev_sesso <- prevalenze |>
  filter(indicatore == "gravi_difficolta_adl", classe_eta == "65+", sesso %in% c("Maschi", "Femmine")) |>
  select(sesso, prevalenza = valore)

anziani_sesso_2024 <- pop_cens |>
  filter(territorio %in% names(TERRITORI), sesso %in% c("M", "F"), cittadinanza == "TOTAL", eta >= 65) |>
  mutate(territorio = factor(TERRITORI[territorio], levels = LIV_TERRITORI),
         sesso = if_else(sesso == "M", "Maschi", "Femmine")) |>
  summarise(n65_piu = sum(popolazione), .by = c(territorio, sesso)) |>
  left_join(prev_sesso, by = "sesso") |>
  mutate(anno = ANNO_OGGI,
         assist_contin = round(n65_piu * prevalenza / 100)) |>
  # demenze stimate per sesso (somma delle classi quinquennali del 2024, § 4b)
  left_join(anziani_demenze_sesso |>
              filter(anno == ANNO_OGGI) |>
              summarise(demenze = sum(casi), .by = c(territorio, sesso)),
            by = c("territorio", "sesso")) |>
  mutate(pct_demenze = round(100 * demenze / n65_piu, 1)) |>
  arrange(territorio, sesso)

anziani_sesso_2024

# 6. Salva nel proprio output/ --------------------------------------------
saveRDS(anziani_pop_eta,    file.path(dir_out, "anziani_pop_eta.rds"))
write_csv(anziani_pop_eta,  file.path(dir_out, "anziani_pop_eta.csv"))
saveRDS(anziani_stima,      file.path(dir_out, "anziani_stima.rds"))
write_csv(anziani_stima,    file.path(dir_out, "anziani_stima.csv"))
saveRDS(anziani_stima_tot,  file.path(dir_out, "anziani_stima_tot.rds"))
write_csv(anziani_stima_tot, file.path(dir_out, "anziani_stima_tot.csv"))
saveRDS(confronto_demenze_ae, file.path(dir_out, "confronto_demenze_ae.rds"))
saveRDS(anziani_demenze_sesso, file.path(dir_out, "anziani_demenze_sesso.rds"))
write_csv(anziani_demenze_sesso, file.path(dir_out, "anziani_demenze_sesso.csv"))
saveRDS(anziani_sesso_2024, file.path(dir_out, "anziani_sesso_2024.rds"))
write_csv(anziani_sesso_2024, file.path(dir_out, "anziani_sesso_2024.csv"))

# 7. Verifiche (da lanciare a mano, riga per riga) ------------------------
# Italia 2024: stima larga attesa vicina ai 4,03 milioni del CERGAS per il 2023
# (loro: 28,4% × 65+ al 1.1.2023; qui: 3 classi × censimento 2024, dovrebbe dare un po' di più)
anziani_stima_tot |> filter(territorio == "Italia", anno == ANNO_OGGI) |> select(n65_piu, non_autosuff, pct_non_autosuff)

# Italia 2024, demenze: attese ~1,15-1,2 milioni (ISS: 1.126.961 su popolazione 1.1.2023, Tab. 1.1)
anziani_stima_tot |> filter(territorio == "Italia") |> select(anno, n65_piu, demenze, pct_demenze)

# il totale 65+ dalle classi deve coincidere con n65_piu
anziani_pop_eta |>
  summarise(da_classi = sum(popolazione), .by = c(territorio, anno)) |>
  left_join(select(anziani_stima_tot, territorio, anno, n65_piu), by = c("territorio", "anno")) |>
  mutate(scarto = da_classi - n65_piu)

# 65+ e 80+ del 2024 vs demo_trend_previs (previsione 2024, base 1.1.2024): scarti piccoli attesi
readRDS(here("moduli", "demo_trend_previs", "output", "previs_struttura_territori.rds")) |>
  filter(anno == ANNO_OGGI, territorio %in% c("Parma", "Emilia-Romagna", "Italia")) |>
  select(territorio, anno, n65_piu, n80_piu)
