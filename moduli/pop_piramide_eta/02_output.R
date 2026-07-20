# ==========================================================================
# Modulo: pop_piramide_eta — 02_output.R
# Scopo:  piramidi d'età (classi quinquennali) con territorio di CONFRONTO
#         in overlay (profilo scuro sopra le barre): PR vs ER, PR vs Italia,
#         ER vs Italia
# Input:  output/piramidi_df.rds                (da 01_dati.R)
#         R/_parma_colors.R                     (palette)
# Output: output/piramide_<target>_vs_<confronto>.png/.rds
# ==========================================================================

library(here)
library(dplyr, warn.conflicts = FALSE)
library(purrr)
library(ggplot2)
library(scales)
library(stringr)

source(here("R", "_parma_colors.R"))
source(here("R", "f_caption_fonte.R"))

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "pop_piramide_eta")

piramidi_df <- readRDS(file.path(dir_mod, "output", "piramidi_df.rds"))

FONTE <- f_caption_fonte("ISTAT, Censimento permanente della popolazione 2024")
COL_SESSO <- c(Maschi = sesso_m_pal, Femmine = sesso_f_pal)  # azzurro pallido / rosa (da _parma_colors.R)
FILL_PIRAMIDE <- blu_piramide   # monocroma, come le piramidi storiche di Luisa

# --- 1) Funzioni --------------------------------------------------------------
# quota con segno: maschi a sinistra (negativi), femmine a destra
f_quota_segno <- function(df) {
  mutate(df, quota_s = if_else(sesso_lbl == "Maschi", -quota, quota))
}

# piramide: barre = territorio target, contorno = territorio di confronto
# (popolazione totale: cittadinanza "Totale")
f_piramide <- function(cod_target, cod_confronto) {
  df_t <- piramidi_df |>
    filter(territorio == cod_target, cittadinanza_lbl == "Totale") |>
    f_quota_segno()
  df_c <- piramidi_df |>
    filter(territorio == cod_confronto, cittadinanza_lbl == "Totale") |>
    f_quota_segno()

  lbl_t <- as.character(unique(df_t$territorio_lbl))
  lbl_c <- as.character(unique(df_c$territorio_lbl))
  anno  <- unique(df_t$anno)

  # dati esportabili: target + confronto impilati (per il bottone di download)
  dati <- bind_rows(df_t, df_c) |>
    select(anno, territorio_lbl, cittadinanza_lbl, classe5_lbl, sesso_lbl, popolazione, quota)

  g <- ggplot(df_t, aes(x = quota_s, y = classe5_lbl)) +
    geom_col(aes(fill = sesso_lbl), width = 0.85) +
    # territorio di confronto: barre VUOTE sovrapposte (solo contorno)
    geom_col(data = df_c, fill = NA, colour = "grey35",
             linewidth = 0.35, width = 0.85) +
    geom_vline(xintercept = 0, colour = "white", linewidth = 0.2) +
    # scales:: esplicito: il plot salvato come rds deve stampare anche in
    # sessioni dove scales non è caricato (es. render delle pagine di sito)
    scale_x_continuous(labels = function(x) scales::percent(abs(x), accuracy = 0.5),
                       breaks = breaks_pretty(n = 9)) +
    scale_fill_manual(values = COL_SESSO, name = NULL) +
    labs(
      title    = paste0("Piramide dell'età — ", lbl_t, " (", anno, ")"),
      subtitle = paste0("Barre piene: ", lbl_t, " · Contorno: ", lbl_c),
      x = "% della popolazione del territorio", y = NULL, caption = FONTE
    ) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      legend.position    = "top",
      plot.subtitle      = element_text(size = 10, colour = "grey30"),
      plot.caption       = element_text(hjust = 0, size = 8, colour = "grey30")
    )
  attr(g, "dati") <- dati
  g
}

# piramidi per cittadinanza: tre pannelli affiancati (Totale | Italiani |
# Stranieri) per un territorio; ogni pannello ha quote sul PROPRIO gruppo,
# quindi si confrontano le FORME, non le taglie
f_piramide_cittadinanza <- function(cod_territorio) {
  df_t <- piramidi_df |>
    filter(territorio == cod_territorio) |>
    f_quota_segno()

  lbl_t <- as.character(unique(df_t$territorio_lbl))
  anno  <- unique(df_t$anno)

  # dati esportabili per il bottone di download
  dati <- df_t |>
    select(anno, territorio_lbl, cittadinanza_lbl, classe5_lbl, sesso_lbl, popolazione, quota)

  g <- ggplot(df_t, aes(x = quota_s, y = classe5_lbl)) +
    geom_col(aes(fill = sesso_lbl), width = 0.85) +
    geom_vline(xintercept = 0, colour = "white", linewidth = 0.2) +
    facet_wrap(vars(cittadinanza_lbl), nrow = 1) +
    scale_x_continuous(labels = function(x) scales::percent(abs(x), accuracy = 1),
                       breaks = breaks_pretty(n = 6)) +
    scale_fill_manual(values = COL_SESSO, name = NULL) +
    labs(
      title    = paste0("Piramidi dell'età per cittadinanza — ", lbl_t, " (", anno, ")"),
      subtitle = "Si confrontano le forme, non le taglie",
      x = "% della popolazione di ciascun gruppo", y = NULL, caption = FONTE
    ) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      legend.position    = "top",
      plot.subtitle      = element_text(size = 10, colour = "grey30"),
      strip.text         = element_text(face = "bold"),
      plot.caption       = element_text(hjust = 0, size = 8, colour = "grey30")
    )
  attr(g, "dati") <- dati
  g
}

# salvataggio (png + rds)
f_salva_piramide <- function(grafico, nome_file, larghezza = 7) {
  ggsave(file.path(dir_mod, "output", paste0(nome_file, ".png")),
         grafico, width = larghezza, height = 6, dpi = 300, bg = "white")
  saveRDS(grafico, file.path(dir_mod, "output", paste0(nome_file, ".rds")))
  # csv dei dati del grafico (per il bottone di download nelle pagine di sito/)
  dati <- attr(grafico, "dati")
  if (!is.null(dati)) {
    write.csv(dati, file.path(dir_mod, "output", paste0(nome_file, ".csv")),
              row.names = FALSE)
  }
  message("Salvata: ", nome_file)
}

# --- 2) Le tre piramidi (purrr) -----------------------------------------------
coppie <- tibble::tribble(
  ~cod_target, ~cod_confronto, ~nome_file,
  "ITD52",     "ITD5",         "piramide_pr_vs_er",
  "ITD52",     "IT",           "piramide_pr_vs_it",
  "ITD5",      "IT",           "piramide_er_vs_it"
)

piramidi <- coppie |>
  select(cod_target, cod_confronto) |>
  pmap(f_piramide) |>
  set_names(coppie$nome_file)

iwalk(piramidi, function(g, nm) f_salva_piramide(g, nm))

# --- 3) Piramidi per cittadinanza (Totale | Italiani | Stranieri) -------------
territori_citt <- c(piramide_pr_cittadinanza = "ITD52",
                    piramide_er_cittadinanza = "ITD5")

piramidi_citt <- map(territori_citt, f_piramide_cittadinanza)

iwalk(piramidi_citt, function(g, nm) f_salva_piramide(g, nm, larghezza = 11))
