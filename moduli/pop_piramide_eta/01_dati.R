# ==========================================================================
# Modulo: pop_piramide_eta — 01_dati.R
# Fonte:  ISTAT censimento permanente 2024 (singole età)
# Input:  dati/puliti/istat_cens/pop_confronti_eta_2024.rds
#         (territori di confronto: IT, ITD5 = ER, ITD52 = prov. Parma)
# Output: output/piramidi_df.rds — quote di popolazione per
#         territorio × sesso (M/F) × classe d'età quinquennale
# ==========================================================================

library(here)
library(dplyr, warn.conflicts = FALSE)

# Parametri ---------------------------------------------------------------
ANNO_CENS <- 2024
TERRITORI <- c(IT    = "Italia",
               ITD5  = "Emilia-Romagna",
               ITD52 = "Provincia di Parma")   # NUTS (ITD52 = Parma)
dir_out <- here("moduli", "pop_piramide_eta", "output")
dir.create(dir_out, showWarnings = FALSE)

# 1) Carica input -----------------------------------------------------------
pop_conf_eta <- readRDS(here("dati", "puliti", "istat_cens",
                             paste0("pop_confronti_eta_", ANNO_CENS, ".rds")))

stopifnot(all(names(TERRITORI) %in% unique(pop_conf_eta$territorio)))

# 2) Codici sesso: servono M e F (robusto: M/F oppure 1/2) --------------------
sessi_presenti <- unique(pop_conf_eta$sesso)
cod_mf <- if (all(c("M", "F") %in% sessi_presenti)) {
  c(M = "M", F = "F")
} else if (all(c("1", "2") %in% sessi_presenti)) {
  c(M = "1", F = "2")
} else {
  stop("Codici sesso M/F non riconosciuti. Presenti: ",
       paste(sessi_presenti, collapse = ", "))
}

# 3) Classi quinquennali e quote ----------------------------------------------
# quota = popolazione della cella / popolazione TOTALE del gruppo
# (territorio × cittadinanza, M+F): così sono confrontabili sia territori di
# taglia diversa, sia le piramidi italiani vs stranieri (su scale proprie)
CITTADINANZE <- c(TOTAL = "Totale", ITL = "Italiani", FRGAPO = "Stranieri")

piramidi_df <- pop_conf_eta |>
  filter(territorio %in% names(TERRITORI),
         cittadinanza %in% names(CITTADINANZE),
         sesso %in% cod_mf) |>
  mutate(
    territorio_lbl = factor(TERRITORI[territorio], levels = TERRITORI),
    cittadinanza_lbl = factor(CITTADINANZE[cittadinanza], levels = CITTADINANZE),
    sesso_lbl = factor(if_else(sesso == cod_mf[["M"]], "Maschi", "Femmine"),
                       levels = c("Maschi", "Femmine")),
    classe5 = pmin(floor(eta / 5) * 5, 100),
    classe5_lbl = factor(
      if_else(classe5 == 100, "100+", paste0(classe5, "-", classe5 + 4)),
      levels = c(paste0(seq(0, 95, 5), "-", seq(4, 99, 5)), "100+"))
  ) |>
  summarise(popolazione = sum(popolazione),
            .by = c(territorio, territorio_lbl, cittadinanza, cittadinanza_lbl,
                    sesso_lbl, classe5_lbl, anno)) |>
  mutate(quota = popolazione / sum(popolazione),
         .by = c(territorio, cittadinanza))

# CONTROLLO: le quote di ogni territorio × cittadinanza sommano a 1
chk <- piramidi_df |>
  summarise(tot = sum(quota), .by = c(territorio, cittadinanza)) |>
  filter(abs(tot - 1) > 1e-9)
stopifnot(nrow(chk) == 0)

# 4) Salva --------------------------------------------------------------------
saveRDS(piramidi_df, file.path(dir_out, "piramidi_df.rds"))
message("Salvato: output/piramidi_df.rds (",
        nrow(piramidi_df), " righe, ",
        length(unique(piramidi_df$territorio)), " territori)")
