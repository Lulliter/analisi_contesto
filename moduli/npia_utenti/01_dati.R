# ___________________________________________________________________________
# Modulo: npia_utenti
# Fonte:  AUSL di Parma, DAISMDP - Report d'attività annuali 2014-2024 (sezione NPIA),
#         trascritti a mano in dati/grezzi/ausl_npia/npia_pr_serie.csv (vedi _metadati.md)
# Input:  dati/grezzi/ausl_npia/npia_pr_serie.csv, npia_diagnosi_2024.csv, npia_sma_confronto_2024.csv, sma_diagnosi_2024.csv
#           formato lungo: anno × distretto × indicatore × valore, con fonte (edizione) e nota
# Output: moduli/npia_utenti/output/npia_distretti_rev.rds (+ .csv)
#           1 riga = anno × distretto, colonne = indicatori (accessi, in carico, nuovi, tassi, pop 0-17)
#           valori rivisti (correzioni e totali ricavati in § 2b, applicati in § 2c; colonna `revisione`
#           dice dove); i valori come stampati restano nell'oggetto npia_distretti (non salvato)
#           NA = valore non stampato nel report (mai "zero")
#         moduli/npia_utenti/output/npia_eta.rds (+ .csv)
#           1 riga = anno × classe d'età dei pazienti in carico (solo Totale Provincia), con quota %
#         moduli/npia_utenti/output/npia_prov.rds (+ .csv)
#           serie provinciali: in carico (totale, minori 0-17 = totale - 18+, nuovi), stranieri
#           (n, tutte le età, e %), femmine (%), autismo
#         moduli/npia_utenti/output/npia_diagnosi_2024.rds (+ .csv)
#           1 riga = diagnosi principale dei pazienti in carico nel 2024 (n, %, età media, % femmine, % stranieri)
#         moduli/npia_utenti/output/npia_sma_2024.rds (+ .csv)
#           confronto minori (NPIA) vs adulti (SMA) 2024: accessi, in carico, % su popolazione, femmine, stranieri, prima diagnosi
#         moduli/npia_utenti/output/sma_diagnosi_2024.csv — diagnosi primarie degli adulti in carico (solo scarico)
# NB: fonte MONO-modulo → lettura qui, non in ingestione/. Due misure diverse: "accessi"
#     (almeno una prestazione) e "in carico" (progetto terapeutico aperto). Le edizioni
#     rivedono gli anni precedenti: il csv tiene l'edizione più recente; le note restano
#     nel csv grezzo e nel _metadati.md, qui non si portano
# ___________________________________________________________________________


# BTW ---------------------------------------------------------------------
# L'AUSL di Parma ha le funzioni corrispondenti a ATS + ASST a Pavia:
#   + programmazione, committenza e controllo di qualità dei servizi (ATS)
#   + erogazione dei servizi (ASST), compreso il NPIA (Neuropsichiatria Infantile e dell'Adolescenza)
# 
# Il dip NPIA quindi eroga i servizi in oggetto e produce il report annuale DAISMP (Dipartimento di Assistenza Integrata Salute Mentale e Dipendenze Patologiche) che contiene i dati qui riportati.

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(tidyr)
library(readr)
library(janitor)

# Parametri ---------------------------------------------------------------
ANNO_ULTIMO <- 2024
file_in <- here("dati", "grezzi", "ausl_npia", "npia_pr_serie.csv")
dir_out <- here("moduli", "npia_utenti", "output")
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)

# ordine dei distretti nei grafici (Totale Provincia = somma dei distretti come stampata nel report)
LIV_DISTRETTI <- c("Parma", "Fidenza", "Sud Est", "Valli Taro e Ceno", "Totale Provincia")
LIV_ETA       <- c("0-2", "3-5", "6-10", "11-13", "14-17", "18+")

# 1. Carica input ---------------------------------------------------------
npia_grezzo_long <- read_csv(file_in, show_col_types = FALSE) |>
  mutate(distretto = factor(distretto, levels = LIV_DISTRETTI))

# controllo: nessun doppione anno × distretto × indicatore
stopifnot(!anyDuplicated(npia_grezzo_long[, c("anno", "distretto", "indicatore")]))


# ___ checks ------------------------------------------------------------------
npia_grezzo_long |> tabyl(  distretto) 
npia_grezzo_long |> tabyl(  indicatore)
npia_grezzo_long |> filter (indicatore == "accessi_stranieri_0_17") |> 
  tabyl(  distretto, anno) |> adorn_totals("row") |> adorn_totals("col") 
# Parma/Fidenza/Sud Est manca in 2016 
npia_grezzo_long |> filter (indicatore == "tasso_accesso_x1000") |> 
  tabyl(  distretto, anno) |> adorn_totals("row") |> adorn_totals("col") 
npia_grezzo_long |> filter (indicatore == "accessi_residenti_0_17") |> 
  tabyl(  distretto, anno) |> adorn_totals("row") |> adorn_totals("col") 
# Totale Provincia manca da 2014 a 2016


# 2. Flip to wide serie per distretto ----------------------------------
npia_distretti <- npia_grezzo_long |>
  filter(!grepl("^in_carico_eta_|^quota_|_femmine$|_stranieri$|_autismo$", indicatore)) |>
  select(anno, distretto, indicatore, valore) |>
  pivot_wider(names_from = indicatore, values_from = valore) |>
  # quota di minori in carico sulla popolazione 0-17 (dove c'è la popolazione)
  mutate(in_carico_x100_pop = round(in_carico / pop_residente_0_17 * 100, 1)) |>
  arrange(distretto, anno)

# 2b. Correzioni e totali calcolati (colonne _calc, accanto ai valori stampati) ------
# Il csv grezzo riporta SOLO ciò che i report stampano; le tre correzioni sotto
# sono ricavate qui, così restano visibili e riproducibili (dettagli nel _metadati.md)

# (a) 2014-2016: l'edizione 2016 non stampa la riga di totale provinciale degli accessi
#     dei residenti 0-17: totale = somma dei distretti; popolazione 0-17 di ogni
#     distretto ricavata da n / tasso * 1000, tasso provinciale sulla somma
tot_2014_16 <- npia_distretti |>
  filter(anno %in% 2014:2016, distretto != "Totale Provincia") |>
  mutate(pop_calc = accessi_residenti_0_17 / tasso_accesso_x1000 * 1000) |>
  group_by(anno) |>
  summarise(accessi_residenti_0_17_calc = sum(accessi_residenti_0_17),
            pop_residente_0_17_calc     = round(sum(pop_calc)),
            .groups = "drop") |>
  mutate(tasso_accesso_x1000_calc = round(accessi_residenti_0_17_calc / pop_residente_0_17_calc * 1000, 1),
         distretto = factor("Totale Provincia", levels = LIV_DISTRETTI))

# (b) Parma 2021: il report ripete il valore 2020 (2.396) pur dichiarando +17,9%;
#     valore per differenza = totale provincia meno gli altri tre distretti
parma_2021 <- npia_distretti |>
  filter(anno == 2021) |>
  summarise(accessi_residenti_0_17_calc =
              accessi_residenti_0_17[distretto == "Totale Provincia"] -
              sum(accessi_residenti_0_17[!distretto %in% c("Parma", "Totale Provincia")]),
            pop_residente_0_17_calc = pop_residente_0_17[distretto == "Parma"]) |>
  mutate(tasso_accesso_x1000_calc = round(accessi_residenti_0_17_calc / pop_residente_0_17_calc * 1000, 1),
         anno = 2021, distretto = factor("Parma", levels = LIV_DISTRETTI))

# (c) stranieri 2020: i conteggi di Valli Taro e Ceno (266) e Sud Est (109) sono
#     scambiati di riga nel report (tassi 256 e 46 per 1.000, fuori scala rispetto
#     a 2019 e 2021); si scambiano i conteggi e si ricalcola il tasso sulla
#     popolazione straniera 0-17 implicita nel report (n / tasso stampati)
stranieri_2020 <- npia_distretti |>
  filter(anno == 2020, distretto %in% c("Valli Taro e Ceno", "Sud Est")) |>
  mutate(pop_str_calc = accessi_stranieri_0_17 / tasso_accesso_stranieri_x1000 * 1000,
         accessi_stranieri_0_17_calc = rev(accessi_stranieri_0_17),
         tasso_accesso_stranieri_x1000_calc = round(accessi_stranieri_0_17_calc / pop_str_calc * 1000, 1)) |>
  select(anno, distretto, accessi_stranieri_0_17_calc, tasso_accesso_stranieri_x1000_calc)

# aggancio delle correzioni alla tabella per distretto: colonne _calc accanto ai valori stampati
npia_distretti_calc <- npia_distretti |>
  left_join(bind_rows(tot_2014_16, parma_2021), by = c("anno", "distretto")) |>
  left_join(stranieri_2020, by = c("anno", "distretto"))

# 2c. Tabella rivista: valore corretto dove c'è, stampato altrimenti ----------
# (i valori stampati restano in npia_distretti; `revisione` dice quali colonne sono cambiate)
npia_distretti_rev <- npia_distretti_calc |>
  mutate(revisione = case_when(
    !is.na(pop_residente_0_17_calc) & is.na(pop_residente_0_17) ~ "totale 2014-16 ricavato dai distretti",
    !is.na(accessi_residenti_0_17_calc) ~ "Parma 2021 per differenza",
    !is.na(accessi_stranieri_0_17_calc) ~ "stranieri 2020: distretti scambiati",
    TRUE ~ NA_character_),
    accessi_residenti_0_17        = coalesce(accessi_residenti_0_17_calc, accessi_residenti_0_17),
    pop_residente_0_17            = coalesce(pop_residente_0_17_calc, pop_residente_0_17),
    tasso_accesso_x1000           = coalesce(tasso_accesso_x1000_calc, tasso_accesso_x1000),
    accessi_stranieri_0_17        = coalesce(accessi_stranieri_0_17_calc, accessi_stranieri_0_17),
    tasso_accesso_stranieri_x1000 = coalesce(tasso_accesso_stranieri_x1000_calc, tasso_accesso_stranieri_x1000),
    # la quota di minori in carico si ricalcola sulla popolazione rivista
    in_carico_x100_pop            = round(in_carico / pop_residente_0_17 * 100, 1)) |>
  select(-ends_with("_calc")) |>
  arrange(distretto, anno)

npia_distretti_rev |> filter(!is.na(revisione))



# ___ checks ------------------------------------------------------------------

 # primo e ultimo anno disponibile per indicatore
npia_distretti_rev |>
  pivot_longer(-c(anno, distretto, revisione), names_to = "indicatore") |>
  filter(!is.na(value)) |>
   group_by(indicatore) |>
  summarise(da = min(anno), a = max(anno), n_righe = n()) 

 
# 3. Classi d'età dei pazienti in carico (solo Totale Provincia) ------------
npia_eta <- npia_grezzo_long |>
  filter(grepl("^in_carico_eta_", indicatore)) |>
  mutate(classe_eta = factor(sub("in_carico_eta_", "", indicatore), levels = LIV_ETA)) |>
  group_by(anno) |>
  mutate(quota = round(valore / sum(valore) * 100, 1)) |>
  ungroup() |>
  select(anno, classe_eta, n = valore, quota) |>
  arrange(anno, classe_eta)

# 4. Serie provinciali: composizione dei pazienti in carico ---------------
# in carico minori = totale meno la classe 18+ (da npia_eta; fino al 2022, poi le età mancano)
in_carico_18plus <- npia_eta |>
  filter(classe_eta == "18+") |>
  select(anno, in_carico_18plus = n)

npia_prov <- npia_grezzo_long |>
  filter(distretto == "Totale Provincia",
         indicatore %in% c("in_carico", "in_carico_nuovi", "in_carico_stranieri", "in_carico_femmine",
                           "quota_stranieri_in_carico_pct", "quota_femmine_in_carico_pct", "in_carico_autismo")) |>
  select(anno, indicatore, valore) |>
  pivot_wider(names_from = indicatore, values_from = valore) |>
  left_join(in_carico_18plus, by = "anno") |>
  # le quote: calcolate dove c'è il conteggio, altrimenti quelle lette nel report
  mutate(in_carico_0_17  = in_carico - in_carico_18plus,
         quota_stranieri = coalesce(round(in_carico_stranieri / in_carico * 100, 1), quota_stranieri_in_carico_pct),
         quota_femmine   = coalesce(round(in_carico_femmine / in_carico * 100, 1), quota_femmine_in_carico_pct),
         quota_nuovi     = round(in_carico_nuovi / in_carico * 100, 1)) |>
  select(anno, in_carico, in_carico_0_17, in_carico_nuovi, quota_nuovi,
         in_carico_stranieri, quota_stranieri, quota_femmine, in_carico_autismo) |>
  arrange(anno)

# 4b. Diagnosi principali dei pazienti in carico, fotografia 2024 ----------
# una riga = diagnosi, con n, %, età media, % femmine, % stranieri (report 2024, p. 10);
# trascrizione a mano in npia_diagnosi_2024.csv (maiuscole del report normalizzate)
npia_diagnosi_2024 <- read_csv(here("dati", "grezzi", "ausl_npia", "npia_diagnosi_2024.csv"),
                               show_col_types = FALSE) |>
  select(-fonte, -nota) |>
  # etichetta come nel testo del report ("disturbi evolutivi globali (autismo)", p. 10):
  # nella tabella del report la parentesi non c'è, nel csv grezzo nemmeno
  mutate(diagnosi_principale = if_else(diagnosi_principale == "Disturbi evolutivi globali",
                                       "Disturbi evolutivi globali (autismo)", diagnosi_principale)) |>
  arrange(desc(n))

# controllo: la somma delle diagnosi = pazienti in carico 2024 (atteso TRUE)
sum(npia_diagnosi_2024$n) == npia_prov$in_carico[npia_prov$anno == 2024]

# 4c. Confronto con la salute mentale adulti (SMA), fotografia 2024 ---------
# riferimento macro: stessi indicatori per minori (NPIA) e adulti (SMA), valori
# stampati nel report 2024 (pagine nel csv); la tabella diagnosi SMA resta solo
# come csv scaricabile (sma_diagnosi_2024.csv), non si porta in pagina
npia_sma_2024 <- read_csv(here("dati", "grezzi", "ausl_npia", "npia_sma_confronto_2024.csv"),
                          show_col_types = FALSE) |>
  select(-fonte, -nota)

sma_diagnosi_2024 <- read_csv(here("dati", "grezzi", "ausl_npia", "sma_diagnosi_2024.csv"),
                              show_col_types = FALSE) |>
  select(-fonte, -nota) |>
  arrange(desc(n))

# controllo: la somma delle diagnosi SMA = pazienti in carico SMA (atteso TRUE)
sum(sma_diagnosi_2024$n) == npia_sma_2024$sma[npia_sma_2024$indicatore == "in_carico"]

# 5. Salva nel proprio output/ --------------------------------------------
saveRDS(npia_distretti_rev, file.path(dir_out, "npia_distretti_rev.rds"))
write_csv(npia_distretti_rev, file.path(dir_out, "npia_distretti_rev.csv"))
saveRDS(npia_eta, file.path(dir_out, "npia_eta.rds"))
write_csv(npia_eta, file.path(dir_out, "npia_eta.csv"))
saveRDS(npia_prov, file.path(dir_out, "npia_prov.rds"))
write_csv(npia_prov, file.path(dir_out, "npia_prov.csv"))
saveRDS(npia_diagnosi_2024, file.path(dir_out, "npia_diagnosi_2024.rds"))
write_csv(npia_diagnosi_2024, file.path(dir_out, "npia_diagnosi_2024.csv"))
saveRDS(npia_sma_2024, file.path(dir_out, "npia_sma_2024.rds"))
write_csv(npia_sma_2024, file.path(dir_out, "npia_sma_2024.csv"))
write_csv(sma_diagnosi_2024, file.path(dir_out, "sma_diagnosi_2024.csv"))

# 6. Verifiche (da lanciare a mano, riga per riga) ------------------------
# copertura: quali indicatori ci sono per quali anni (1 = presente)
npia_grezzo_long |>
  filter(distretto == "Totale Provincia") |>
  distinct(anno, indicatore) |>
  arrange(anno) |>
  mutate(ok = 1) |>
  pivot_wider(names_from = anno, values_from = ok) |>
  arrange(indicatore) |>
  print(n = 30, width = 200)

# i distretti sommano al Totale Provincia? (scarto in n; tollerabile qualche unità per
# arrotondamenti e revisioni, non centinaia)
npia_distretti |>
  select(anno, distretto, accessi, accessi_residenti_0_17, in_carico, in_carico_nuovi) |>
  pivot_longer(-c(anno, distretto), names_to = "indicatore") |>
  filter(!is.na(value)) |>
  group_by(anno, indicatore) |>
  summarise(somma_distretti = sum(value[distretto != "Totale Provincia"]),
            totale = value[distretto == "Totale Provincia"][1],
            n_distretti = sum(distretto != "Totale Provincia"), .groups = "drop") |>
  mutate(scarto = somma_distretti - totale) |>
  filter(n_distretti == 4, !is.na(totale), scarto != 0) |>
  print(n = 50)

# le classi d'età sommano ai pazienti in carico dello stesso anno?
npia_eta |>
  group_by(anno) |>
  summarise(tot_eta = sum(n), .groups = "drop") |>
  left_join(select(npia_prov, anno, in_carico), by = "anno") |>
  mutate(scarto = tot_eta - in_carico) |>
  filter(scarto != 0)

# plausibilità: nuovi ≤ in carico; in carico ≤ accessi residenti 0-17 (gli accessi
# contano anche chi ha solo una consulenza, quindi devono essere di più)
npia_distretti |>
  filter(in_carico_nuovi > in_carico | in_carico > accessi_residenti_0_17) |>
  select(anno, distretto, accessi_residenti_0_17, in_carico, in_carico_nuovi)

# minori stranieri per CITTADINANZA sui minorenni della provincia (censimento ISTAT 2024, dati/puliti):
# atteso ~20%; il report 2024 (p. 10) parla di "circa il 30%" → base diversa (origine?), v. _metadati.md
readRDS(here("dati", "puliti", "istat_cens", "pop_com_er_minorenni_2024.rds")) |>
  filter(substr(PRO_COM_T, 1, 3) == "034", sesso == "T") |>
  summarise(minorenni = sum(minorenni), .by = cittadinanza) |>
  mutate(quota = round(minorenni / minorenni[cittadinanza == "TOTAL"] * 100, 1))

# tassi ricalcolati vs tassi del report (dove c'è la popolazione): scarto > 1 per 1.000 da guardare
npia_distretti |>
  filter(!is.na(pop_residente_0_17), !is.na(accessi_residenti_0_17)) |>
  mutate(tasso_ricalcolato = round(accessi_residenti_0_17 / pop_residente_0_17 * 1000, 1),
         scarto = tasso_ricalcolato - tasso_accesso_x1000) |>
  filter(abs(scarto) > 1) |>
  select(anno, distretto, tasso_accesso_x1000, tasso_ricalcolato, scarto)

# le quote stanno in un intervallo sensato?
npia_prov |>
  filter(quota_stranieri < 10 | quota_stranieri > 40 | quota_femmine < 30 | quota_femmine > 45 |
         quota_nuovi < 10 | quota_nuovi > 35)

# le righe con nota nel csv grezzo: sono i punti da ricordare nel blurb
npia_grezzo_long |>
  filter(!is.na(nota), nota != "") |>
  distinct(anno, indicatore, nota) |>
  print(n = 40, width = 200)

