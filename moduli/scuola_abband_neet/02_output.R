# ___________________________________________________________________________
# Modulo: scuola_abband_neet
# Scopo:  giovani a rischio dispersione / NEET nella provincia di Parma:
#         NEET per provincia ER (trend BES); competenze non adeguate in III media
#         per provincia (barre, ultimo anno); ritardo scolastico per anno di corso
#         PR vs ER (l'accumulo lungo il percorso); ritardo per ordine nel tempo
#         PR vs ER; mappa comunale PR del ritardo alle medie
# Input:  output/*.rds (da 01_dati.R); dati/puliti/istat_shp/ (geometrie)
# Output: output/plot_*.rds, mappa_*.rds (ggplot; girafe() nella pagina) + .png;
#         output/*_ft.rds (flextable, riletta tal quale nella pagina)
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(stringr)
library(janitor)
library(purrr)
library(glue)
library(ggplot2)
library(ggiraph)
library(scales)
library(ggtext)
library(sf)

source(here("R", "formatting.R")) # f_ft, f_ft_titolo_note (tabelle)
source(here("R", "_parma_colors.R"))
source(here("R", "f_caption_fonte.R"))
source(here("R", "f_theme_scuola.R"))
source(here("R", "f_lab_as.R"))
source(here("R", "f_aggiungi_classe.R"))
source(here("R", "f_disegna_mappa.R"))
source(here("R", "f_salva_mappa.R"))
source(here("R", "f_pal5.R"))

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "scuola_abband_neet", "output")

CAP_BES <- f_caption_fonte("ISTAT, Bes dei territori (ed. 2025)")
CAP_NEET <- f_caption_fonte("ISTAT, Bes dei territori (ed. 2025); NEET = stima campionaria")
# Stime da indagine campionarie RCFL (Rilevazione sulle forze di lavoro)".
CAP_BES_NAZ <- "ISTAT, Bes (aggiornamento intermedio 2026); stima campionaria"
CAP_MIM <- f_caption_fonte("MIM, Portale unico dei dati della scuola (statali + paritarie, no infanzia, esclusi serali/CPIA)")

ANNO_PRIMO <- 2015   # primo a.s. serie MIM (2015/16)
ANNO_ULTIMO <- 2024  # a.s. 2024/25 (MIM) e anno 2024 (BES)
ANNO_BES_PRIMO <- 2018
ANNI_TAB_NEET <- c(2019, 2022, 2024) # colonne tabella NEET (Bes dei territori: ultimo anno 2024)
ANNI_TAB_ELET <- c(2019, 2022, 2025) # colonne tabella ELET (Bes nazionale: ultimo anno 2025)
TERRITORI_BES <- c("Emilia-Romagna", "Nord-est", "Italia") # ordine righe delle tabelle

# etichette degli ordini di scuola (nomi MIM → brevi) e dei territori
ORDINI_LBL <- c("SCUOLA PRIMARIA" = "Primaria",
                "SCUOLA SECONDARIA I GRADO" = "Secondaria I grado",
                "SCUOLA SECONDARIA II GRADO" = "Secondaria II grado")
COL_TERRITORI <- c("Parma" = ylw_lg, "Emilia-Romagna" = grn_md, "Italia" = blu_md,
                   "Altre province ER" = grey_sc)

# 1. Carica dati pronti ----------------------------------------------------
ritardo_trend_prov_er <- readRDS(file.path(dir_mod, "ritardo_trend_prov_er.rds"))
ritardo_corso_prov_er <- readRDS(file.path(dir_mod, "ritardo_corso_prov_er.rds"))
ritardo_comuni_pr <- readRDS(file.path(dir_mod, "ritardo_comuni_pr.rds"))
bes_istruzione_prov_er <- readRDS(file.path(dir_mod, "bes_istruzione_prov_er.rds"))
bes_istruzione_reg <- readRDS(file.path(dir_mod, "bes_istruzione_reg.rds"))

# territorio "display" per colori e legenda (BES: nomi già in forma leggibile)
f_territorio_display <- function(territorio) {
  factor(case_when(
    territorio %in% c("Parma", "PARMA") ~ "Parma",
    territorio %in% c("Emilia-Romagna", "EMILIA-ROMAGNA") ~ "Emilia-Romagna",
    territorio == "Italia" ~ "Italia",
    .default = "Altre province ER"
  ), levels = names(COL_TERRITORI))
}

# 2. Grafici BES -----------------------------------------------------------

# Plot: NEET 15-29 per provincia ER, Parma evidenziata (+ ER e Italia) ----
neet_prov_prep <- bes_istruzione_prov_er |>
  filter(cod_indicatore == "02IST006-N22", sesso == "Totale", territorio != "Nord-est") |>
  mutate(quota = valore / 100,
         territorio_display = f_territorio_display(territorio),
         highlight = territorio_display != "Altre province ER")

neet_prov_prep

plot_neet_prov_er <- neet_prov_prep |>
  ggplot(aes(x = anno, y = quota, color = territorio_display, alpha = highlight, group = territorio)) +
  geom_line_interactive(aes(tooltip = territorio, data_id = territorio), linewidth = rel(0.8)) +
  geom_line_interactive(data = function(df) df |> filter(highlight),
                        aes(tooltip = territorio, data_id = territorio), linewidth = rel(1.5)) +
  geom_point_interactive(data = function(df) df |> filter(highlight),
                         aes(tooltip = glue("{territorio} {anno}: {scales::percent(quota, accuracy = 0.1)}")), size = 1.8) +
  scale_x_continuous(breaks = ANNO_BES_PRIMO:ANNO_ULTIMO) +
  scale_y_continuous(labels = function(x) scales::percent(x, accuracy = 1), limits = c(0, NA)) +
  scale_alpha_manual(values = c(0.35, 1), guide = "none") +
  scale_color_manual(values = COL_TERRITORI) +
  f_theme_scuola() +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5)) +
  labs(
    title = str_wrap(glue("Giovani che non studiano e non lavorano (NEET), {ANNO_BES_PRIMO}-{ANNO_ULTIMO}"), 55),
    subtitle = "Indicatore: % di 15-29enni che non studiano e non lavorano sulla popolazione della stessa età; province ER, regione e Italia. Stime campionarie: le differenze tra province vanno lette con cautela",
    caption = CAP_NEET, x = "", y = ""
  )

plot_neet_prov_er

# Plot: competenze non adeguate in III media per provincia, ultimo anno ----
competenze_prep <- bes_istruzione_prov_er |>
  filter(cod_indicatore %in% c("02IST011P", "02IST010P"), sesso == "Totale",
         anno == ANNO_ULTIMO, territorio != "Nord-est") |>
  mutate(materia = if_else(cod_indicatore == "02IST011P", "Italiano (alfabetica)", "Matematica (numerica)"),
         quota = valore / 100,
         territorio_display = f_territorio_display(territorio)) |>
  # ordine delle barre: media delle due materie
  mutate(ordine = mean(quota), .by = territorio) |>
  mutate(territorio = reorder(territorio, ordine))

competenze_prep

plot_competenze_prov_er <- competenze_prep |>
  ggplot(aes(x = quota, y = territorio, fill = territorio_display)) +
  geom_col_interactive(aes(tooltip = glue("{territorio}, {materia}: {scales::percent(quota, accuracy = 0.1)}"),
                           data_id = paste(territorio, materia)), width = 0.75) +
  geom_text(aes(label = scales::percent(quota, accuracy = 1)), hjust = -0.15, size = 3.5) +
  facet_wrap(~ materia) +
  scale_x_continuous(labels = function(x) scales::percent(x, accuracy = 1),
                     limits = c(0, 0.5), expand = expansion(mult = c(0, 0))) +
  scale_fill_manual(values = COL_TERRITORI) +
  f_theme_scuola() +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
        strip.text = element_text(size = rel(1), face = "bold"),
        panel.spacing.x = unit(2, "lines")) + # altrimenti "50%" e "0%" dei due pannelli si toccano
  labs(
    title = str_wrap(glue("Studenti di III media con competenze non adeguate ({ANNO_ULTIMO})"), 55),
    subtitle = "Indicatore: % di studenti di III media sotto il livello adeguato nelle prove INVALSI, per provincia; dato censuario",
    caption = CAP_BES, x = "", y = ""
  )

plot_competenze_prov_er

# 2b. Tabelle gemelle NEET / ELET: totale in 3 anni + maschi e femmine nell'ultimo ----
# NEET (15-29 né occupati né in formazione) dal Bes dei territori, quindi con Parma;
# ELET (18-24 con al più la licenza media e fuori da ogni corso) solo regionale, dal Bes nazionale
# Input:  rds BES in forma lunga (indicatore × sesso × territorio × anno); dati_sesso =
#         da dove prendere maschi/femmine se il rds principale ha solo il Totale
#         (NEET: Bes dei territori solo Totale → M/F dal Bes nazionale, Parma resta N.D.)
# Output: flextable con header a due righe ("Totale" | "<ultimo anno> per sesso")
f_tab_bes <- function(dati, cod, territori, anni, titolo, note, dati_sesso = dati) {
  prep <- bind_rows(
    dati |> filter(cod_indicatore == cod, territorio %in% territori, sesso == "Totale", anno %in% anni),
    dati_sesso |> filter(cod_indicatore == cod, territorio %in% territori, sesso != "Totale", anno == max(anni))
  ) |>
    mutate(colonna = if_else(sesso == "Totale", as.character(anno), sesso),
           territorio = factor(territorio, levels = territori)) |>
    select(territorio, colonna, valore) |>
    tidyr::pivot_wider(names_from = colonna, values_from = valore) |>
    # ordine colonne esplicito: add_header_row unisce le celle per posizione
    select(territorio, all_of(as.character(anni)), Maschi, Femmine) |>
    arrange(territorio) |>
    mutate(territorio = as.character(territorio))
  prep |>
    f_ft() |>
    set_header_labels(territorio = "") |>
    add_header_row(values = c("", "Totale", glue("{max(anni)} per sesso")), colwidths = c(1, 3, 2)) |>
    align(align = "center", part = "header") |>
    bg(j = c("Maschi", "Femmine"), bg = seq_teal[1], part = "all") |> # blocco per sesso distinto dal trend
    f_ft_titolo_note(titolo = titolo, note = note)
}

neet_tab_ft <- f_tab_bes(
  bes_istruzione_prov_er, cod = "02IST006-N22",
  territori = c("Parma", TERRITORI_BES), anni = ANNI_TAB_NEET, dati_sesso = bes_istruzione_reg,
  titolo = "NEET: giovani di 15-29 anni che non studiano e non lavorano (%)",
  note = c("Fonte: ISTAT, Bes dei territori (ed. 2025); stima campionaria (Rilevazione sulle forze di lavoro).",
           "NEET = Not in Education, Employment or Training: né occupati né in istruzione o formazione, qualunque titolo di studio. Per sesso: dato regionale (Bes nazionale), non disponibile per Parma. Leggere il trend, non i decimali.")
)
neet_tab_ft

elet_tab_ft <- f_tab_bes(
  bes_istruzione_reg, cod = "02IST005-N22",
  territori = TERRITORI_BES, anni = ANNI_TAB_ELET,
  titolo = "ELET: giovani di 18-24 anni usciti presto da istruzione e formazione (%)",
  note = c(glue("Fonte: {CAP_BES_NAZ} (Rilevazione sulle forze di lavoro)."),
           "ELET = Early Leavers from Education and Training: al più la licenza media e fuori da ogni corso, occupati o no. Obiettivo UE 2030: sotto il 9%. Il dato non esiste a livello provinciale.")
)
elet_tab_ft

# 3. Grafici ritardo scolastico (MIM) --------------------------------------

# Plot: ritardo per anno di corso, dalla 1ª primaria alla 5ª superiore, PR vs ER ----
ritardo_corso_prep <- ritardo_corso_prov_er |>
  filter(provincia %in% c("PARMA", "EMILIA-ROMAGNA"),
         anno_corso <= 5) |> # escluso il 6° anno degli istituti agrari (specializzazione
                             # enotecnico post-diploma: 282 alunni in Italia, over 18 per costruzione)
  mutate(territorio_display = f_territorio_display(provincia),
         ordine_lbl = factor(ORDINI_LBL[ordine_scuola], levels = ORDINI_LBL),
         classe = factor(anno_corso)) # pannelli per ordine, x = anno di corso

ritardo_corso_prep

plot_ritardo_corso_pr_er <- ritardo_corso_prep |>
  ggplot(aes(x = classe, y = quota_ritardo, color = territorio_display, group = territorio_display)) +
  geom_line_interactive(aes(tooltip = territorio_display, data_id = territorio_display), linewidth = rel(1.2)) +
  geom_point_interactive(aes(tooltip = glue("{territorio_display}, {ordine_lbl} {classe}ª: {scales::percent(quota_ritardo, accuracy = 0.1)} ({scales::number(alunni_ritardo, big.mark = '.', decimal.mark = ',')} alunni)")), size = 1.8) +
  facet_grid(~ ordine_lbl, scales = "free_x", space = "free_x",
             labeller = label_wrap_gen(14)) + # "Secondaria I grado" su 2 righe
  scale_y_continuous(labels = function(x) scales::percent(x, accuracy = 1), limits = c(0, NA)) +
  scale_color_manual(values = COL_TERRITORI) +
  f_theme_scuola() +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
        strip.text = element_text(size = rel(1), face = "bold")) +
  labs(
    title = str_wrap(glue("Alunni in ritardo scolastico per anno di corso (a.s. {f_lab_as(ANNO_ULTIMO)})"), 55),
    subtitle = "Indicatore: % di alunni con età superiore a quella regolare per la classe (ripetenze o inserimenti in classi inferiori) sugli iscritti della classe. Alle superiori dopo il 3° anno gli iscritti calano di un terzo (fine dell'obbligo a 16 anni, passaggi alla formazione professionale, abbandoni)",
    caption = CAP_MIM, x = "Anno di corso", y = ""
  )

plot_ritardo_corso_pr_er

# Plot: ritardo per ordine nel tempo, PR vs ER ----
ritardo_trend_prep <- ritardo_trend_prov_er |>
  filter(provincia %in% c("PARMA", "EMILIA-ROMAGNA")) |>
  mutate(territorio_display = f_territorio_display(provincia),
         ordine_lbl = factor(ORDINI_LBL[ordine_scuola], levels = ORDINI_LBL),
         etichetta_as = f_lab_as(anno_inizio))

ritardo_trend_prep

plot_ritardo_trend_pr_er <- ritardo_trend_prep |>
  ggplot(aes(x = anno_inizio, y = quota_ritardo, color = territorio_display, group = territorio_display)) +
  geom_line_interactive(aes(tooltip = territorio_display, data_id = paste(territorio_display, ordine_lbl)), linewidth = rel(1.2)) +
  geom_point_interactive(aes(tooltip = glue("{territorio_display} {etichetta_as}: {scales::percent(quota_ritardo, accuracy = 0.1)}")), size = 1.8) +
  facet_wrap(~ ordine_lbl) + # scala y comune: il confronto tra ordini è parte del messaggio
  scale_x_continuous(breaks = ANNO_PRIMO:ANNO_ULTIMO, labels = f_lab_as(ANNO_PRIMO:ANNO_ULTIMO)) +
  scale_y_continuous(labels = function(x) scales::percent(x, accuracy = 1), limits = c(0, NA)) +
  scale_color_manual(values = COL_TERRITORI) +
  f_theme_scuola() +
  theme(strip.text = element_text(size = rel(1), face = "bold")) +
  labs(
    title = str_wrap(glue("Alunni in ritardo scolastico per ordine di scuola (trend a.s. {f_lab_as(ANNO_PRIMO)}-{f_lab_as(ANNO_ULTIMO)})"), 55),
    subtitle = "Indicatore: % di alunni in ritardo sugli iscritti dell'ordine",
    caption = CAP_MIM, x = "", y = ""
  )

plot_ritardo_trend_pr_er

# 4. Mappa comunale PR: ritardo alle medie (ultimo a.s.) --------------------
# (le superiori stanno in 9 comuni: la mappa ha senso solo per il I grado)
file_dett <- here("dati", "puliti", "istat_shp", "PR_comuni_dettaglio_sf.rds")
if (file.exists(file_dett)) {
  pr_comuni_sf <- readRDS(file_dett) |> select(PRO_COM_T, COMUNE)
} else {
  message("Dettaglio PR non trovato (esegui ingestione/00b): uso il generalizzato")
  pr_comuni_sf <- readRDS(here("dati", "puliti", "istat_shp", "ER_comuni_sf.rds")) |>
    filter(COD_PROV %in% c("34", 34)) |> select(PRO_COM_T, COMUNE)
}
pr_bordo_sf <- pr_comuni_sf |> summarise()

lab_pct <- label_percent(accuracy = 0.1, decimal.mark = ",")

mappa_ritardo_prep <- pr_comuni_sf |>
  left_join(ritardo_comuni_pr |>
              filter(anno_inizio == ANNO_ULTIMO, ordine_scuola == "SCUOLA SECONDARIA I GRADO"),
            by = c("PRO_COM_T" = "pro_com_t")) |>
  # NA = comuni senza scuole medie (grigio in mappa)
  f_aggiungi_classe("quota_ritardo", lab_pct) |> # quintili dei comuni
  # i comuni senza medie: livello esplicito "n.d." (in legenda al posto di "NA")
  mutate(classe_quota_ritardo = forcats::fct_na_value_to_level(classe_quota_ritardo, "n.d.")) |>
  mutate(tooltip_mappa = paste0(
    str_to_title(COMUNE), ": ",
    if_else(is.na(quota_ritardo), "n.d.",
            paste0(lab_pct(quota_ritardo), " (", alunni_ritardo, " su ", alunni, ")"))
  ))

mappa_ritardo_sec1_comuni_pr <- f_disegna_mappa(
  df_comuni    = mappa_ritardo_prep,
  df_prov      = pr_bordo_sf,
  var          = "quota_ritardo",
  titolo       = str_wrap("Alunni in ritardo scolastico alle medie — provincia di Parma", 55),
  palette5     = c(f_pal5(seq_factor_red), grey_m), # 5 classi + "n.d."
  caption      = CAP_MIM,
  sottotitolo  = glue("Indicatore: % di alunni in ritardo sugli iscritti alle medie, per comune della scuola; a.s. {f_lab_as(ANNO_ULTIMO)}; classi = quintili; in grigio (n.d.) i comuni senza scuole medie"),
  nome_legenda = "% in ritardo\nsu iscritti",
  col_tooltip  = "tooltip_mappa",
  df_evidenzia = NULL
)

mappa_ritardo_sec1_comuni_pr

# 5. Salva (rds per il sito + png; nome file = oggetto) --------------------
lista_plot <- list(
  plot_neet_prov_er = plot_neet_prov_er,
  plot_competenze_prov_er = plot_competenze_prov_er,
  plot_ritardo_corso_pr_er = plot_ritardo_corso_pr_er,
  plot_ritardo_trend_pr_er = plot_ritardo_trend_pr_er
)

purrr::iwalk(lista_plot, function(p, nome) {
  saveRDS(p, file.path(dir_mod, paste0(nome, ".rds")))
  ggsave(file.path(dir_mod, paste0(nome, ".png")), p, width = 9, height = 6, dpi = 300, device = ragg::agg_png)
  message("Salvato: ", nome, " (.rds + .png)")
})

f_salva_mappa(mappa_ritardo_sec1_comuni_pr, "mappa_ritardo_sec1_comuni_pr", dir_out = dir_mod)

# tabelle: solo rds (i dati per i bottoni sono il csv dell'oggetto di 01_dati.R)
saveRDS(neet_tab_ft, file.path(dir_mod, "neet_tab_ft.rds"))
saveRDS(elet_tab_ft, file.path(dir_mod, "elet_tab_ft.rds"))
