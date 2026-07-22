# ==========================================================================
# Modulo: demo_trend_previs — 02_output.R
# Scopo:  7 grafici dalle previsioni ISTAT 2024-2050 (scenario mediano):
#         p01 pop totale indicizzata (2024=100), p02 pop totale assoluta
#         (solo province ER), p03 piramide PR 2050 vs 2024,
#         p04 quota 65+ e 80+, p05a/b/c 65+/80+ in valore assoluto (un
#         grafico ciascuno per Parma, ER, Italia), p06 indice di dipendenza
#         anziani, p07 nati e morti previsti (PR/ER)
# Input:  output/previs_*.rds (da 01_dati.R)
# Output: output/pNN_<nome>.rds (ggplot; girafe() si applica in sito/) + csv
# ==========================================================================

library(here)
library(dplyr, warn.conflicts = FALSE)
library(tidyr)
library(glue)
library(ggplot2)
library(ggtext)
library(ggiraph)
library(scales)

source(here("R", "_parma_colors.R"))
source(here("R", "f_caption_fonte.R"))

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "demo_trend_previs", "output")

CAP <- f_caption_fonte(
  "Istat, Previsioni della popolazione 2024-2050, scenario mediano (demo.istat.it)"
)

# NB: qui i nomi vengono dai csv previsioni: "Parma", "Emilia-Romagna",
#     "Italia", "Forlì-Cesena" (≠ "ITALIA"/"Forli'" del modulo demo_trend_indicatori)
territori_hl <- c("Parma", "Emilia-Romagna", "Italia")

COLORI_TREND <- c(
  "Parma"              = ylw_lg,
  "Emilia-Romagna"     = grn_md,
  "Italia"             = blu_md,
  "Altre provincie ER" = grey_sc
)
COL_SESSO <- c(Maschi = sesso_m_pal, Femmine = sesso_f_pal)

# tema comune dei trend (stesse scelte di demo_trend_indicatori)
theme_trend <- theme_minimal(base_size = 15) +
  theme(
    panel.grid.major = element_line(color = "grey90", linewidth = rel(0.3)),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1, size = rel(0.85)),
    axis.text.y = element_text(size = rel(0.85)),
    plot.title = element_text(size = rel(1.3), face = "bold", margin = margin(b = 10)),
    plot.subtitle = ggtext::element_textbox_simple(
      size = rel(0.95), lineheight = 1.2, margin = margin(b = 10)
    ),
    legend.title = element_blank(),
    legend.position = "bottom"
  )

# Carica input -------------------------------------------------------------
previs_pop_totale <- readRDS(file.path(dir_mod, "previs_pop_totale.rds"))
previs_piramide   <- readRDS(file.path(dir_mod, "previs_piramide.rds"))
previs_struttura  <- readRDS(file.path(dir_mod, "previs_struttura_territori.rds"))
previs_bilancio   <- readRDS(file.path(dir_mod, "previs_bilancio_territori.rds"))

# dataset comune a p01/p02: indice 2024=100 + territorio_display/highlight
df_pop <- previs_pop_totale |>
  mutate(indice = totale / totale[anno == 2024] * 100, .by = territorio) |>
  mutate(
    highlight = territorio %in% territori_hl,
    territorio_display = factor(
      ifelse(highlight, territorio, "Altre provincie ER"),
      levels = c(territori_hl, "Altre provincie ER")
    ),
    highlight = factor(highlight)
  )

# 1. p01: pop totale indicizzata 2024 = 100 --------------------------------
p01_pop_indice <- df_pop |>
  ggplot(aes(x = anno, y = indice,
             color = territorio_display, alpha = highlight, group = territorio)) +
  geom_hline(yintercept = 100, color = "grey60", linewidth = rel(0.3), linetype = 2) +
  geom_line_interactive(
    aes(tooltip = territorio, data_id = gsub("'", "", territorio)),
    linewidth = rel(0.8)
  ) +
  geom_line_interactive(
    data = function(df) df |> filter(territorio_display != "Altre provincie ER"),
    aes(tooltip = territorio, data_id = gsub("'", "", territorio)),
    linewidth = rel(1.5)
  ) +
  geom_point_interactive(
    data = function(df) df |> filter(territorio_display != "Altre provincie ER"),
    aes(tooltip = round(indice, 1), data_id = gsub("'", "", territorio)),
    size = 1.6
  ) +
  scale_x_continuous(breaks = seq(2024, 2050, by = 2),
                     expand = expansion(mult = c(0.02, 0.02))) +
  scale_alpha_manual(values = c(0.3, 1), guide = "none") +
  scale_color_manual(values = COLORI_TREND) +
  theme_trend +
  labs(
    title = "Popolazione prevista al 2050 (2024 = 100)",
    subtitle = glue("Previsioni Istat, scenario mediano; province dell'Emilia-Romagna, ",
                    "regione e Italia. Base: popolazione al 1° gennaio 2024."),
    caption = CAP, x = "", y = ""
  )
p01_pop_indice

# 2. p02: pop totale assoluta — SOLO province ER ----------------------------
# (ER e Italia fuori scala rispetto alle province: restano in p01 e nel csv)
p02_pop_totale <- df_pop |>
  filter(!territorio %in% c("Emilia-Romagna", "Italia")) |>
  ggplot(aes(x = anno, y = totale,
             color = territorio_display, alpha = highlight, group = territorio)) +
  geom_line_interactive(
    aes(tooltip = territorio, data_id = gsub("'", "", territorio)),
    linewidth = rel(0.8)
  ) +
  geom_line_interactive(
    data = function(df) df |> filter(territorio == "Parma"),
    aes(tooltip = territorio, data_id = gsub("'", "", territorio)),
    linewidth = rel(1.5)
  ) +
  geom_point_interactive(
    data = function(df) df |> filter(territorio == "Parma"),
    aes(tooltip = scales::number(totale, big.mark = "."), data_id = gsub("'", "", territorio)),
    size = 1.6
  ) +
  scale_x_continuous(breaks = seq(2024, 2050, by = 2),
                     expand = expansion(mult = c(0.02, 0.02))) +
  scale_y_continuous(labels = scales::label_number(big.mark = ".")) +
  scale_alpha_manual(values = c(0.3, 1), guide = "none") +
  scale_color_manual(values = COLORI_TREND) +
  theme_trend +
  labs(
    title = "Popolazione prevista al 2050 — province dell'Emilia-Romagna",
    subtitle = glue("Abitanti previsti al 1° gennaio; previsioni Istat, scenario mediano. ",
                    "Emilia-Romagna e Italia (fuori scala) nel grafico indicizzato."),
    caption = CAP, x = "", y = ""
  )
p02_pop_totale

# 3. p03: piramide provincia di Parma, 2050 (barre) vs 2024 (contorno) ------
f_quota_segno <- function(df) {
  mutate(df, quota_s = if_else(sesso_lbl == "Maschi", -quota, quota))
}

df_2050 <- previs_piramide |>
  filter(territorio == "Provincia di Parma", anno == 2050) |> f_quota_segno()
df_2024 <- previs_piramide |>
  filter(territorio == "Provincia di Parma", anno == 2024) |> f_quota_segno()

p03_piramide_pr <- ggplot(df_2050, aes(x = quota_s, y = eta)) +
  geom_col(aes(fill = sesso_lbl), width = 0.85) +
  # 2024: barre grigie semitrasparenti sovrapposte (NON il contorno grigio,
  # che in pop_piramide_eta indica un confronto territoriale, non temporale)
  geom_col(data = df_2024, fill = "grey40", alpha = 0.45, width = 0.85) +
  geom_vline(xintercept = 0, colour = "white", linewidth = 0.2) +
  # scales:: esplicito: il plot salvato come rds deve stampare anche in
  # sessioni dove scales non è caricato (es. render delle pagine di sito)
  scale_x_continuous(labels = function(x) scales::percent(abs(x), accuracy = 0.5),
                     breaks = breaks_pretty(n = 9)) +
  scale_fill_manual(values = COL_SESSO, name = NULL) +
  labs(
    title    = "Piramide dell'età prevista — Provincia di Parma (2050)",
    subtitle = "Barre colorate: 2050 · Grigio semitrasparente: 2024 — previsioni Istat, scenario mediano",
    x = "% della popolazione del territorio", y = NULL, caption = CAP
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = "top",
    plot.subtitle      = element_text(size = 10, colour = "grey30"),
    plot.caption       = element_text(hjust = 0, size = 8, colour = "grey30")
  )
p03_piramide_pr

# 4. p04: quota 65+ e 80+ — Parma/ER/Italia evidenziate, altre province ER grigie ----
df_p04 <- previs_struttura |>
  pivot_longer(c(p65_piu, p80_piu), names_to = "indicatore", values_to = "valore") |>
  mutate(
    indicatore = factor(indicatore, levels = c("p65_piu", "p80_piu"),
                        labels = c("65 anni e più", "80 anni e più")),
    highlight = territorio %in% territori_hl,
    territorio_display = factor(
      ifelse(highlight, territorio, "Altre provincie ER"),
      levels = c(territori_hl, "Altre provincie ER")
    ),
    highlight = factor(highlight)
  )

p04_quota_anziani <- df_p04 |>
  ggplot(aes(x = anno, y = valore,
             color = territorio_display, alpha = highlight, group = territorio)) +
  geom_line_interactive(
    aes(tooltip = territorio, data_id = gsub("'", "", territorio)),
    linewidth = rel(0.8)
  ) +
  geom_line_interactive(
    data = function(df) df |> filter(territorio_display != "Altre provincie ER"),
    aes(tooltip = territorio, data_id = gsub("'", "", territorio)),
    linewidth = rel(1.5)
  ) +
  geom_point_interactive(
    data = function(df) df |> filter(territorio_display != "Altre provincie ER"),
    aes(tooltip = round(valore, 1), data_id = gsub("'", "", territorio)),
    size = 1.4
  ) +
  facet_wrap(vars(indicatore), scales = "free_y") +
  scale_x_continuous(breaks = seq(2024, 2050, by = 4)) +
  scale_alpha_manual(values = c(0.3, 1), guide = "none") +
  scale_color_manual(values = COLORI_TREND) +
  theme_trend +
  theme(strip.text = element_text(size = rel(1.1), face = "bold")) +
  labs(
    title = "Quota di popolazione anziana prevista (2024-2050)",
    subtitle = "% della popolazione con 65+ e 80+ anni; previsioni Istat, scenario mediano.",
    caption = CAP, x = "", y = "%"
  )
p04_quota_anziani

# 5. p05a/b/c: 65+ e 80+ in valore ASSOLUTO — un grafico per territorio ------
# (dimensiona la platea; livelli non confrontabili tra territori → un grafico
#  ciascuno per Parma / ER / Italia, con la linea nel colore territoriale;
#  pannelli 65+ | 80+ su scala propria)
df_p05 <- previs_struttura |>
  filter(territorio %in% territori_hl) |>
  pivot_longer(c(n65_piu, n80_piu), names_to = "indicatore", values_to = "valore") |>
  mutate(indicatore = factor(indicatore, levels = c("n65_piu", "n80_piu"),
                             labels = c("65 anni e più", "80 anni e più")))

f_p05_territorio <- function(terr) {
  df_t <- df_p05 |> filter(territorio == terr)
  ggplot(df_t, aes(x = anno, y = valore, group = indicatore)) +
    geom_line_interactive(
      aes(tooltip = territorio, data_id = indicatore),
      color = COLORI_TREND[[terr]], linewidth = rel(1.5)
    ) +
    geom_point_interactive(
      aes(tooltip = scales::number(valore, big.mark = "."), data_id = indicatore),
      color = COLORI_TREND[[terr]], size = 1.6
    ) +
    facet_wrap(vars(indicatore), scales = "free_y") +
    scale_x_continuous(breaks = seq(2024, 2050, by = 4)) +
    scale_y_continuous(labels = scales::label_number(big.mark = "."),
                       limits = c(0, NA)) +  # da zero: livelli, non variazioni
    theme_trend +
    theme(strip.text = element_text(size = rel(1.1), face = "bold")) +
    labs(
      title = glue("Popolazione anziana prevista — {terr} (2024-2050)"),
      subtitle = glue("Persone con 65+ e 80+ anni, valori assoluti; ",
                      "previsioni Istat, scenario mediano."),
      caption = CAP, x = "", y = ""
    )
}

p05a_anziani_parma  <- f_p05_territorio("Parma")
p05b_anziani_er     <- f_p05_territorio("Emilia-Romagna")
p05c_anziani_italia <- f_p05_territorio("Italia")

# 6. p06: indice di dipendenza anziani ---------------------------------------
# (65+ ogni 100 persone in età attiva 15-64: confrontabile col p04 storico)
df_p06 <- previs_struttura |>
  select(territorio, anno, valore = ind_dip_anziani) |>
  mutate(
    highlight = territorio %in% territori_hl,
    territorio_display = factor(
      ifelse(highlight, territorio, "Altre provincie ER"),
      levels = c(territori_hl, "Altre provincie ER")
    ),
    highlight = factor(highlight)
  )

p06_dipendenza_anziani <- df_p06 |>
  ggplot(aes(x = anno, y = valore,
             color = territorio_display, alpha = highlight, group = territorio)) +
  geom_line_interactive(
    aes(tooltip = territorio, data_id = gsub("'", "", territorio)),
    linewidth = rel(0.8)
  ) +
  geom_line_interactive(
    data = function(df) df |> filter(territorio_display != "Altre provincie ER"),
    aes(tooltip = territorio, data_id = gsub("'", "", territorio)),
    linewidth = rel(1.5)
  ) +
  geom_point_interactive(
    data = function(df) df |> filter(territorio_display != "Altre provincie ER"),
    aes(tooltip = round(valore, 1), data_id = gsub("'", "", territorio)),
    size = 1.6
  ) +
  scale_x_continuous(breaks = seq(2024, 2050, by = 2),
                     expand = expansion(mult = c(0.02, 0.02))) +
  scale_alpha_manual(values = c(0.3, 1), guide = "none") +
  scale_color_manual(values = COLORI_TREND) +
  theme_trend +
  labs(
    title = "Indice di dipendenza anziani previsto (2024-2050)",
    subtitle = glue("Persone di 65+ anni ogni 100 in età attiva (15-64); ",
                    "previsioni Istat, scenario mediano."),
    caption = CAP, x = "", y = ""
  )

# 7. p07: nati e morti previsti — Parma e ER ---------------------------------
# (somma dei soli comuni >= 5.000 ab.: vedi 01_dati.R)
df_p07 <- previs_bilancio |>
  pivot_longer(c(nati, morti), names_to = "componente", values_to = "valore") |>
  mutate(componente = factor(componente, levels = c("nati", "morti"),
                             labels = c("Nati", "Morti")))

p07_nati_morti <- df_p07 |>
  ggplot(aes(x = anno, y = valore, color = componente, group = componente)) +
  geom_line_interactive(aes(tooltip = componente, data_id = componente),
                        linewidth = rel(1.3)) +
  geom_point_interactive(
    aes(tooltip = scales::number(valore, big.mark = "."), data_id = componente),
    size = 1.4
  ) +
  facet_wrap(vars(territorio), scales = "free_y") +
  scale_x_continuous(breaks = seq(2024, 2050, by = 4)) +
  scale_y_continuous(labels = scales::label_number(big.mark = "."),
                     limits = c(0, NA)) +  # da zero: il divario si legge meglio
  scale_color_manual(values = c(Nati = grn_md, Morti = burg_md)) +
  theme_trend +
  theme(strip.text = element_text(size = rel(1.1), face = "bold")) +
  labs(
    title = "Nati e morti previsti (2024-2050)",
    subtitle = glue("Somma dei comuni con almeno 5.000 abitanti (22 in provincia ",
                    "di Parma, 195 in ER); previsioni Istat, scenario mediano."),
    caption = CAP, x = "", y = ""
  )

# 8. Salva rds + csv dei dati (per i bottoni di download in sito/) -----------
salva_plot <- list(
  p01_pop_indice = list(
    plot = p01_pop_indice,
    dati = df_pop |> select(territorio, anno, totale, indice)
  ),
  p02_pop_totale = list(
    plot = p02_pop_totale,
    dati = df_pop |> select(territorio, anno, maschi, femmine, totale)
  ),
  p03_piramide_pr = list(
    plot = p03_piramide_pr,
    dati = bind_rows(df_2024, df_2050) |>
      select(territorio, anno, eta, sesso_lbl, popolazione, quota)
  ),
  p04_quota_anziani = list(
    plot = p04_quota_anziani,
    dati = df_p04 |> select(territorio, anno, indicatore, valore)
  ),
  p05a_anziani_parma = list(
    plot = p05a_anziani_parma,
    dati = df_p05 |> filter(territorio == "Parma") |>
      select(territorio, anno, indicatore, valore)
  ),
  p05b_anziani_er = list(
    plot = p05b_anziani_er,
    dati = df_p05 |> filter(territorio == "Emilia-Romagna") |>
      select(territorio, anno, indicatore, valore)
  ),
  p05c_anziani_italia = list(
    plot = p05c_anziani_italia,
    dati = df_p05 |> filter(territorio == "Italia") |>
      select(territorio, anno, indicatore, valore)
  ),
  p06_dipendenza_anziani = list(
    plot = p06_dipendenza_anziani,
    dati = df_p06 |> select(territorio, anno, valore)
  ),
  p07_nati_morti = list(
    plot = p07_nati_morti,
    dati = df_p07 |> select(territorio, anno, componente, valore)
  )
)

purrr::iwalk(salva_plot, function(x, nome) {
  saveRDS(x$plot, file.path(dir_mod, paste0(nome, ".rds")))
  write.csv(x$dati, file.path(dir_mod, paste0(nome, ".csv")), row.names = FALSE)
})


