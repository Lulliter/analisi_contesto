# ___________________________________________________________________________
# Modulo: scuola_disabilita
# Scopo:  % alunni con disabilità: trend per provincia ER (Parma evidenziata),
#         confronto Parma vs ER per grado di scuola nell'ultimo a.s., e numeri
#         indice alunni totali vs con disabilità (Parma e ER)
# Input:  output/disab_trend_prov_er.rds, output/disab_grado_prov_er.rds (da 01_dati.R)
# Output: output/plot_*.rds (ggplot; girafe() nella pagina di sito) + .png
#         (nome file = oggetto)
# NB: fonte USR-ER = solo scuole STATALI, infanzia inclusa
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(stringr)
library(purrr)
library(glue)
library(ggplot2)
library(ggiraph)
library(scales)
library(ggtext)

source(here("R", "_parma_colors.R"))
source(here("R", "f_caption_fonte.R"))
source(here("R", "f_theme_scuola.R"))
source(here("R", "f_lab_as.R"))

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "scuola_disabilita", "output")

CAP <- f_caption_fonte("USR Emilia-Romagna, fact sheet 'Studenti e studenti con disabilità' (scuole statali, organico di fatto)")

ANNO_PRIMO <- 2016  # primo a.s. della serie (2016/17)
ANNO_ULTIMO <- 2024 # a.s. 2024/25 (dato provvisorio)
PERIODO_AS <- glue("trend a.s. {f_lab_as(ANNO_PRIMO)}-{f_lab_as(ANNO_ULTIMO)}") # usato solo nei titoli dei grafici di trend

# 1. Carica dati pronti ----------------------------------------------------
disab_trend_prov_er <- readRDS(file.path(dir_mod, "disab_trend_prov_er.rds"))
disab_grado_prov_er <- readRDS(file.path(dir_mod, "disab_grado_prov_er.rds"))

# 2. Grafici ---------------------------------------------------------------

# Plot: trend % alunni con disabilità per provincia ER, Parma evidenziata ----
# (stessa impostazione di plot_stranieri_prov_er: Parma gialla, ER verde, altre grigie)
disab_prov_prep <- disab_trend_prov_er |>
  mutate(
    highlight = provincia %in% c("Parma", "Emilia-Romagna"),
    provincia_display = case_when(
      provincia == "Parma" ~ "Parma",
      provincia == "Emilia-Romagna" ~ "Emilia-Romagna",
      .default = "Altre province ER"
    ),
    provincia_display = factor(
      provincia_display,
      levels = c("Parma", "Emilia-Romagna", "Altre province ER")
    ),
    # etichetta a.s. calcolata QUI: negli aes() del plot salvato f_lab_as non esisterebbe al render
    etichetta_as = f_lab_as(anno_inizio)
  )

disab_prov_prep

plot_disab_trend_prov_er <- disab_prov_prep |>
  ggplot(aes(x = anno_inizio, y = quota_disab,
             color = provincia_display, alpha = highlight, group = provincia)) +
  geom_line_interactive(aes(tooltip = provincia, data_id = provincia),
                        linewidth = rel(0.8)) +
  # linee spesse e pallini solo sulle serie evidenziate (regola trend multi-territorio)
  geom_line_interactive(
    data = function(df) df |> filter(highlight),
    aes(tooltip = provincia, data_id = provincia), linewidth = rel(1.5)
  ) +
  geom_point_interactive(
    data = function(df) df |> filter(highlight),
    aes(tooltip = glue("{provincia} {etichetta_as}: {scales::percent(quota_disab, accuracy = 0.1)} ({scales::number(alunni_disab, big.mark = '.')} alunni)")),
    size = 1.8
  ) +
  scale_x_continuous(breaks = ANNO_PRIMO:ANNO_ULTIMO, labels = f_lab_as(ANNO_PRIMO:ANNO_ULTIMO)) + # etichette "2016/17" (già calcolate: vedi nota etichetta_as)
  scale_y_continuous(labels = function(x) scales::percent(x, accuracy = 1)) +
  scale_alpha_manual(values = c(0.35, 1), guide = "none") +
  scale_color_manual(values = c(
    "Parma" = ylw_lg,
    "Emilia-Romagna" = grn_md,
    "Altre province ER" = grey_sc
  )) +
  f_theme_scuola() +
  labs(
    title = str_wrap(glue("Alunni con disabilità per provincia ({PERIODO_AS})"), 55),
    subtitle = "Scuole statali, infanzia inclusa; ultimo a.s. provvisorio (organico di fatto a settembre)",
    caption = CAP,
    x = "",
    y = "In % degli alunni della provincia"
  )

plot_disab_trend_prov_er

# Plot: % alunni con disabilità per grado, Parma vs ER, ultimo a.s. ----
disab_grado_prep <- disab_grado_prov_er |>
  filter(anno_inizio == ANNO_ULTIMO, provincia %in% c("Parma", "Emilia-Romagna")) |>
  mutate(provincia = factor(provincia, levels = c("Parma", "Emilia-Romagna")))

disab_grado_prep

plot_disab_grado_pr_er <- disab_grado_prep |>
  ggplot(aes(x = grado, y = quota_disab, fill = provincia)) +
  geom_col_interactive(
    aes(tooltip = glue("{provincia}, {grado}: {scales::percent(quota_disab, accuracy = 0.1)} ({scales::number(alunni_disab, big.mark = '.')} su {scales::number(alunni, big.mark = '.')} alunni)"),
        # group = provincia: senza, data_id (testo) entra nel gruppo e inverte l'ordine delle barre
        data_id = paste(provincia, grado), group = provincia),
    position = position_dodge(width = 0.75), width = 0.7
  ) +
  # etichetta sopra ogni barra (group = provincia: serve al dodge per allinearla alla colonna)
  geom_text(aes(label = scales::percent(quota_disab, accuracy = 0.1), group = provincia),
            position = position_dodge(width = 0.75), vjust = -0.4, size = 4) +
  scale_y_continuous(labels = function(x) scales::percent(x, accuracy = 1),
                     expand = expansion(mult = c(0, 0.12))) +
  scale_fill_manual(values = c("Parma" = ylw_lg, "Emilia-Romagna" = grn_md)) +
  f_theme_scuola() +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5)) +
  labs(
    title = str_wrap(glue("Alunni con disabilità per grado di scuola (a.s. {f_lab_as(ANNO_ULTIMO)})"), 55),
    subtitle = "Parma e Emilia-Romagna; scuole statali, dato provvisorio (organico di fatto a settembre)",
    caption = CAP,
    x = "",
    y = "In % degli alunni del grado"
  )

plot_disab_grado_pr_er

# Plot: numeri indice (2016/17 = 100) alunni vs alunni con disabilità, Parma e ER ----
# la forbice: la scuola statale non cresce, gli alunni con disabilità sì
disab_indice_prep <- disab_trend_prov_er |>
  filter(provincia %in% c("Parma", "Emilia-Romagna")) |>
  arrange(provincia, anno_inizio) |>
  mutate(
    indice_alunni = 100 * alunni / alunni[anno_inizio == ANNO_PRIMO],
    indice_disab = 100 * alunni_disab / alunni_disab[anno_inizio == ANNO_PRIMO],
    .by = provincia
  ) |>
  tidyr::pivot_longer(c(indice_alunni, indice_disab),
                      names_to = "serie", values_to = "indice") |>
  mutate(
    serie = factor(serie, levels = c("indice_disab", "indice_alunni"),
                   labels = c("Alunni con disabilità", "Alunni totali")),
    provincia = factor(provincia, levels = c("Parma", "Emilia-Romagna")),
    etichetta_as = f_lab_as(anno_inizio) # vedi nota in disab_prov_prep
  )

disab_indice_prep

plot_disab_indice_pr_er <- disab_indice_prep |>
  ggplot(aes(x = anno_inizio, y = indice, color = provincia, group = provincia)) +
  geom_hline(yintercept = 100, color = "grey70", linewidth = 0.4) +
  geom_line_interactive(aes(tooltip = provincia, data_id = interaction(provincia, serie)),
                        linewidth = rel(1.2)) +
  geom_point_interactive(
    aes(tooltip = glue("{provincia} {etichetta_as}: {scales::number(indice, accuracy = 0.1, decimal.mark = ',')}")),
    size = 1.8
  ) +
  facet_wrap(~ serie) + # scala y comune: la piattezza dei totali è il messaggio
  scale_x_continuous(breaks = ANNO_PRIMO:ANNO_ULTIMO, labels = f_lab_as(ANNO_PRIMO:ANNO_ULTIMO)) + # etichette "2016/17" (già calcolate: vedi nota etichetta_as)
  scale_color_manual(values = c("Parma" = ylw_lg, "Emilia-Romagna" = grn_md)) +
  f_theme_scuola() +
  theme(strip.text = element_text(size = rel(1), face = "bold")) +
  labs(
    title = str_wrap(glue("Alunni totali e con disabilità: numeri indice ({PERIODO_AS})"), 55),
    subtitle = glue("A.s. {f_lab_as(ANNO_PRIMO)} = 100; scuole statali, infanzia inclusa; ultimo a.s. provvisorio"),
    caption = CAP,
    x = "",
    y = glue("Indice (a.s. {f_lab_as(ANNO_PRIMO)} = 100)")
  )

plot_disab_indice_pr_er

# 3. Salva (rds per il sito + png per riuso rapido; nome file = oggetto) ----
lista_plot <- list(
  plot_disab_trend_prov_er = plot_disab_trend_prov_er,
  plot_disab_grado_pr_er = plot_disab_grado_pr_er,
  plot_disab_indice_pr_er = plot_disab_indice_pr_er
)

purrr::iwalk(lista_plot, function(p, nome) {
  saveRDS(p, file.path(dir_mod, paste0(nome, ".rds")))
  ggsave(file.path(dir_mod, paste0(nome, ".png")), p, width = 9, height = 6, dpi = 300)
  message("Salvato: ", nome, " (.rds + .png)")
})
