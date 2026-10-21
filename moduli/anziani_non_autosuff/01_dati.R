# ___________________________________________________________________________
# Modulo: anziani_non_autosuff
# Fonti:  prevalenze, un solo file prevalenze.rds (lettere come in 00_prep_prevalenze.R):
#         [A] CERGAS Tab. 1.2: gravi limitazioni funzionali, 3 classi → lim_funz_gravi (§ 4)
#         [B] ISTAT report p. 2: ADL gravi 75-84 e 85+ → non autosufficienti, con [D] (§ 4)
#         [C] ISS: tassi di demenza per sesso × classe quinquennale → demenze (§ 4b)
#         [D] EHIS tavole: ADL gravi 65-74 / 75+ / 65+ e per sesso (§ 4, § 5); ADL o IADL e
#             nessuna grave difficoltà, 2 classi (§ 6)
#         [E] GALI 2023, 2 classi, ER e Italia (§ 6)
#         popolazione e confronto:
#         [cens]   ISTAT censimento 2024 per età singola (§ 2)
#         [previs] ISTAT previsioni 2024-2050, per età e grandi classi (§ 3, § 4c)
#         [AE]     Alzheimer Europe, Prevalence of Dementia in Europe (pubblicato 2026, dati 2025), solo confronto con [C] (§ 4d)
# Input:  [A]-[E]  moduli/anziani_non_autosuff/output/prevalenze.rds (da 00_prep_prevalenze.R;
#           il csv trascritto a mano è solo il controllo)
#         [cens]   dati/puliti/istat_cens/pop_confronti_eta_2024.rds (IT / ITD5 / ITD52 × sesso × età singola)
#         [previs] dati/puliti/istat_previsioni/previs_pop_eta_territori.rds (province ER + ER + Italia ×
#           anno × classi 5 anni × sesso; aggregati fatti in ingestione/03)
#         [previs] dati/puliti/istat_previsioni/previs_struttura_territori.rds (stessi territori × anno:
#           totale, 15-64, 65+, 80+)
#         [AE]     dati/grezzi/alzheimer_europe/alzheimer_europe_dementia_data_Italy.csv (solo confronto)
# Output: moduli/anziani_non_autosuff/output/anziani_pop_eta.rds (+ .csv)
#           1 riga = territorio × anno (2024, 2036, 2050) × classe d'età (65-74, 75-84, 85+): popolazione
#         moduli/anziani_non_autosuff/output/anziani_stima.rds (+ .csv)
#           1 riga = territorio × anno × classe d'età × indicatore: prevalenza % e n stimato
#         moduli/anziani_non_autosuff/output/anziani_stima_tot.rds (+ .csv)
#           1 riga = territorio × anno: popolazione totale, 15-64, 65+, 80+ (n e %), indice di
#           dipendenza anziani, stime: non autosufficienti (ADL), gravi limitazioni funzionali, demenze, e % sui 65+
#         moduli/anziani_non_autosuff/output/anziani_demenze_sesso.rds (+ .csv)
#           1 riga = territorio × anno × sesso × classe quinquennale 65+: popolazione, tasso ISS, casi stimati
#         moduli/anziani_non_autosuff/output/anziani_sesso_2024.rds (+ .csv)
#           1 riga = territorio × sesso: 65+ nel 2024 e stima ADL gravi per sesso (prevalenze 65+ M/F)
#         moduli/anziani_non_autosuff/output/anziani_quadro.rds (+ .csv)
#           1 riga = territorio × anno × condizione (GALI grave, gravi difficoltà ADL o IADL, di cui
#           ADL, senza gravi difficoltà): n stimato, % sui 65+, % sui residenti
# NB: il 2024 è il censimento al 31/12/2024; gli anni futuri sono previsioni al 1° gennaio
#     (base 1.1.2024): tra "2024" censuario e "2024" previsto c'è un anno di distanza (+1,3% di 65+)
# NB: metodo = quello dell'Osservatorio LTC (CERGAS Bocconi, 8° Rapporto, cap. 1):
#     prevalenza per classe d'età × popolazione della classe, prevalenza COSTANTE nel tempo
#     (ipotesi forte: ignora miglioramenti o peggioramenti della salute). Misure (dal 2026-10-20):
#     - "non autosufficienti" = gravi difficoltà in almeno una ADL (cura della persona), 3 classi
#       d'età: è la misura principale per 2024 / 2036 / 2050 (colonna non_autosuff_adl)
#     - "gravi limitazioni funzionali" (motorie, sensoriali, cognitive) = prevalenze per età della
#       Tab. 1.2 CERGAS, che il Rapporto chiama "non autosufficienti" (ADL o IADL) ma che nel report
#       ISTAT stanno sotto un'altra colonna: tenute nei dati (lim_funz_gravi), non più nella pagina
#     - quadro (§ 6): GALI grave (prevalenze ER per Parma ed ER), gravi difficoltà ADL o IADL e
#       nessuna grave difficoltà (EHIS tav. 3.4.1), solo DUE classi d'età (65-74 / 75+): al 2050
#       sottostima la crescita, perché nella classe 75+ pesano sempre di più gli 85+
#     (fino al 2026-10-19: "non autosufficienti" = Tab. 1.2 CERGAS; "assistenza continuativa" = ADL)
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

# [A]-[E] prevalenze da 00_prep_prevalenze.R (fino al 2026-10-20: prevalenze_pdf.rds)
file_prev   <- here("moduli", "anziani_non_autosuff", "output", "prevalenze.rds")
# [cens] censimento 2024 per età singola
file_cens   <- here("dati", "puliti", "istat_cens", paste0("pop_confronti_eta_", ANNO_OGGI, ".rds"))
# [previs] previsioni per classe d'età e sesso; grandi classi per territorio
file_previs    <- here("dati", "puliti", "istat_previsioni", "previs_pop_eta_territori.rds")
file_struttura <- here("dati", "puliti", "istat_previsioni", "previs_struttura_territori.rds")
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

# 1. Prevalenze [A]-[E] (da 00_prep_prevalenze.R) ----
prevalenze <- readRDS(file_prev)

prevalenze

# le due definizioni per classe d'età (totale M+F, Italia). Per confrontare con l'originale:
# - [A] gravi_limitazioni_funzionali: CERGAS, 8° Rapporto OLTC, Tab. 1.2 (p. 19 stampata) = nel report
#   ISTAT p. 2 colonna "gravi limitazioni motorie, sensoriali e cognitive" (non ADL o IADL)
# - [B]+[D] gravi_difficolta_adl: 65-74 dalla tav. EHIS 3.2.1 [D], 75-84 e 85+ dal report ISTAT p. 2 [B]
prev_classi <- prevalenze |>
  # solo le due misure a tre classi (le tavole EHIS e GALI hanno anche 65-74: servono al § 6)
  filter(indicatore %in% c("gravi_limitazioni_funzionali", "gravi_difficolta_adl"),
         classe_eta %in% LIV_CLASSI, sesso == "Totale") |>
  select(indicatore, classe_eta, prevalenza = valore) |>
  mutate(classe_eta = factor(classe_eta, levels = LIV_CLASSI))

prev_classi

# controllo: 3 classi × 2 indicatori (atteso 6 righe, nessun NA)
nrow(prev_classi) == 6 && !anyNA(prev_classi$prevalenza)

# [C] demenze: tassi per sesso × classe quinquennale (65-69 … 90+), Italia
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

# 2. Popolazione 2024 per classe d'età [cens] ----
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

# 3. Popolazione 2036 e 2050 per classe d'età [previs] ----
pop_previs <- readRDS(file_previs)

# controllo: etichette età e anni disponibili
unique(pop_previs$eta); range(pop_previs$anno)

# ER e Italia = somma delle province, già fatta in ingestione/03; "Parma" →
# "Provincia di Parma" come nel resto del modulo
pop_previs_terr <- pop_previs |>
  filter(territorio %in% c("Parma", "Emilia-Romagna", "Italia"), anno %in% ANNI_FUTURI) |>
  mutate(territorio = if_else(territorio == "Parma", "Provincia di Parma", territorio))

# totali per territorio × anno: da previs_struttura_territori (stesso calcolo, già fatto)
pop_futuro <- readRDS(file_struttura) |>
  filter(territorio %in% c("Parma", "Emilia-Romagna", "Italia"), anno %in% ANNI_FUTURI) |>
  mutate(territorio = if_else(territorio == "Parma", "Provincia di Parma", territorio)) |>
  select(territorio, anno, pop_totale, n15_64, n65_piu, n80_piu)

pop_futuro_classi <- pop_previs_terr |>
  filter(eta_num >= 65) |>
  mutate(classe_eta = f_classe_eta(eta_num)) |>
  summarise(popolazione = sum(totale), .by = c(territorio, anno, classe_eta))

pop_futuro_classi

# 4. Stime per classe: non autosufficienti [B]+[D], gravi limitazioni funzionali [A] ----
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

# 4b. Demenze per sesso × classe quinquennale [C] ----
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

pop_sesso_futuro <- pop_previs_terr |>
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

# 4c. Totali per territorio × anno [previs] + stime ----
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
         # quote sui 65+ (dipendono solo dalla struttura per età)
         # (2026-10-20: non autosufficienti = ADL gravi; prima erano le gravi limitazioni funzionali)
         pct_non_autosuff_adl = round(gravi_difficolta_adl / n65_piu * 100, 1),
         pct_lim_funz_gravi   = round(gravi_limitazioni_funzionali / n65_piu * 100, 1),
         pct_demenze          = round(demenze / n65_piu * 100, 1)) |>
  select(territorio, anno, pop_totale, n15_64, n65_piu, p65_piu, n80_piu, p80_piu, ind_dip_anziani,
         non_autosuff_adl = gravi_difficolta_adl, pct_non_autosuff_adl,
         lim_funz_gravi = gravi_limitazioni_funzionali, pct_lim_funz_gravi,
         demenze, pct_demenze) |>
  arrange(territorio, anno)

anziani_stima_tot

# 4d. Confronto con Alzheimer Europe [AE] vs [C] (solo nota di pagina) ----
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

# 5. Dettaglio per sesso, solo 2024: ADL [D], demenze [C] ----
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
         non_autosuff_adl = round(n65_piu * prevalenza / 100)) |>
  # demenze stimate per sesso (somma delle classi quinquennali del 2024, § 4b)
  left_join(anziani_demenze_sesso |>
              filter(anno == ANNO_OGGI) |>
              summarise(demenze = sum(casi), .by = c(territorio, sesso)),
            by = c("territorio", "sesso")) |>
  mutate(pct_demenze = round(100 * demenze / n65_piu, 1)) |>
  arrange(territorio, sesso)

anziani_sesso_2024

# 6. Quadro: disabilità [E] e gravi difficoltà nelle attività quotidiane [D] ----
# (2026-10-20, per la tabella quadro della pagina: v. claude_outputs/quadro_anziani_fragili.qmd)
# prevalenze a DUE classi (65-74 / 75+): GALI grave (ER per Parma ed ER, Italia per Italia),
# gravi difficoltà ADL o IADL e nessuna grave difficoltà ADL o IADL (EHIS tav. 3.4.1, Italia);
# la riga "di cui ADL" viene dalla stima a tre classi (§ 4, anziani_stima), come nel resto della pagina
INDICATORI_QUADRO <- c("gali_grave", "gravi_difficolta_adl_o_iadl", "gravi_difficolta_adl",
                       "nessuna_grave_difficolta_adl_o_iadl")

prev_quadro <- prevalenze |>
  filter(indicatore %in% INDICATORI_QUADRO, indicatore != "gravi_difficolta_adl",
         sesso == "Totale", classe_eta %in% c("65-74", "75+")) |>
  select(indicatore, classe_eta2 = classe_eta, territorio_prev = territorio, prevalenza = valore)

prev_quadro   # attese 8 righe: GALI × 2 territori × 2 classi + 2 indicatori EHIS × 2 classi

# popolazione a due classi; territorio delle prevalenze GALI (ER per Parma ed ER)
pop_classi2 <- anziani_pop_eta |>
  mutate(classe_eta2 = if_else(classe_eta == "65-74", "65-74", "75+"),
         territorio_gali = if_else(territorio == "Italia", "Italia", "Emilia-Romagna")) |>
  summarise(popolazione = sum(popolazione), .by = c(territorio, territorio_gali, anno, classe_eta2))

quadro_classi2 <- pop_classi2 |>
  inner_join(prev_quadro, by = "classe_eta2", relationship = "many-to-many") |>
  filter((indicatore == "gali_grave" & territorio_prev == territorio_gali) |
           (indicatore != "gali_grave" & territorio_prev == "Italia")) |>
  mutate(n_stimato = round(popolazione * prevalenza / 100))

anziani_quadro <- bind_rows(
  quadro_classi2 |> summarise(n_stimato = sum(n_stimato), .by = c(territorio, anno, indicatore)),
  anziani_stima |>
    filter(indicatore == "gravi_difficolta_adl") |>
    summarise(n_stimato = sum(n_stimato), .by = c(territorio, anno, indicatore))
) |>
  left_join(select(anziani_stima_tot, territorio, anno, pop_totale, n65_piu), by = c("territorio", "anno")) |>
  mutate(pct_65_piu    = round(n_stimato / n65_piu * 100, 1),
         pct_residenti = round(n_stimato / pop_totale * 100, 1),
         indicatore    = factor(indicatore, levels = INDICATORI_QUADRO)) |>
  select(territorio, anno, indicatore, n_stimato, n65_piu, pct_65_piu, pop_totale, pct_residenti) |>
  arrange(territorio, anno, indicatore)

anziani_quadro
# atteso Parma 2024 (calcolo di controllo fatto fuori da R il 2026-10-20): GALI ~14.650 (13,6%),
# ADL o IADL ~31.400 (29,2%), di cui ADL ~12.500 (11,6%), senza gravi difficoltà ~74.000 (68,8%)

# 7. Salva nel proprio output/ ----
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
saveRDS(anziani_quadro,     file.path(dir_out, "anziani_quadro.rds"))
write_csv(anziani_quadro,   file.path(dir_out, "anziani_quadro.csv"))

# 8. Verifiche (da lanciare a mano, riga per riga) ----
# Italia 2024: gravi limitazioni funzionali attese vicine ai 4,03 milioni del CERGAS per il 2023
# (loro: 28,4% × 65+ al 1.1.2023; qui: 3 classi × censimento 2024, dovrebbe dare un po' di più)
anziani_stima_tot |> filter(territorio == "Italia", anno == ANNO_OGGI) |> select(n65_piu, lim_funz_gravi, pct_lim_funz_gravi)

# Italia 2024, non autosufficienti (ADL): attesi ~1,6 milioni (11%); ISTAT 2019: 1,437 milioni (10,6%)
anziani_stima_tot |> filter(territorio == "Italia", anno == ANNO_OGGI) |> select(n65_piu, non_autosuff_adl, pct_non_autosuff_adl)

# quadro: le righe ADL o IADL e "senza gravi difficoltà" + ~2% di non risposte = 100% dei 65+;
# la riga ADL è sotto la riga ADL o IADL (atteso: somma tra 97 e 99, adl < adl_o_iadl)
anziani_quadro |>
  select(territorio, anno, indicatore, pct_65_piu) |>
  pivot_wider(names_from = indicatore, values_from = pct_65_piu) |>
  mutate(somma = gravi_difficolta_adl_o_iadl + nessuna_grave_difficolta_adl_o_iadl,
         adl_sotto = gravi_difficolta_adl < gravi_difficolta_adl_o_iadl)

# Italia 2024, demenze: attese ~1,15-1,2 milioni (ISS: 1.126.961 su popolazione 1.1.2023, Tab. 1.1)
anziani_stima_tot |> filter(territorio == "Italia") |> select(anno, n65_piu, demenze, pct_demenze)

# il totale 65+ dalle classi deve coincidere con n65_piu
anziani_pop_eta |>
  summarise(da_classi = sum(popolazione), .by = c(territorio, anno)) |>
  left_join(select(anziani_stima_tot, territorio, anno, n65_piu), by = c("territorio", "anno")) |>
  mutate(scarto = da_classi - n65_piu)

# 65+ e 80+ del 2024: censimento vs previsione 2024 (base 1.1.2024): scarti piccoli attesi
readRDS(file_struttura) |>
  filter(anno == ANNO_OGGI, territorio %in% c("Parma", "Emilia-Romagna", "Italia")) |>
  select(territorio, anno, n65_piu, n80_piu)
