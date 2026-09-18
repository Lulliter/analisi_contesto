# build.R --------------------------------------------------------------
# Input:  moduli/<nome>/NN_*.R  (script numerati di ogni modulo)
# Output: moduli/<nome>/output/*.rds e *.csv rigenerati;
#         (opz.) cache _freeze/sito invalidata cosi' quarto ri-esegue le pagine
# Scopo:  ricostruire dati e grafici di TUTTI i moduli prima di renderizzare
#         il sito (quarto_render lo lancio a mano dopo).
# Nota:   freeze:auto ri-esegue una pagina solo se cambia il .qmd; qui a
#         cambiare sono i .rds a monte, percio' va svuotata la cache.
# Uso:    ➡️ source("build.R")   oppure  ➡️ Rscript build.R
# Prima:  se sono cambiati i dati GREZZI di una fonte multi-modulo, lanciare a
#         mano il relativo script di ingestione/ (00-05: shp/SITUAS, censimento,
#         MIM studenti, previsioni ISTAT, BES dei territori, BES nazionale) — build.R parte
#         dai dati/puliti/ e non li rigenera
# ----------------------------------------------------------------------

library(here)

# Parametri ------------------------------------------------------------
moduli_dir     <- here("moduli")
pulisci_freeze <- TRUE   # invalida _freeze/sito a fine build (vedi Nota)

# Moduli da costruire: sottocartelle di moduli/ che non iniziano per "_"
moduli <- list.dirs(moduli_dir, recursive = FALSE, full.names = FALSE)
moduli <- moduli[!startsWith(moduli, "_")]

# Costruzione ----------------------------------------------------------
# Ogni script gira in una sessione R pulita (come fa quarto al render),
# cosi' nessuna variabile passa "sporca" da uno script all'altro.
rscript <- file.path(R.home("bin"), "Rscript")
for (m in moduli) {
  script <- sort(list.files(
    file.path(moduli_dir, m),
    pattern = "^[0-9]+_.*\\.R$", full.names = TRUE
  ))
  for (s in script) {
    message("== ", m, " / ", basename(s))
    # Gli script stampano i grafici "a schermo" (controllo visivo in RStudio).
    # In Rscript non c'e' schermo e R aprirebbe Rplots.pdf, che non conosce
    # i caratteri tipografici (warning mbcsToSbcs): dirotto la stampa su png
    # temporanei (ragg, unicode ok)
    avvio <- "options(device = function(...) ragg::agg_png(tempfile(fileext = '.png'), ...))"
    esito <- system2(rscript, c("-e", shQuote(paste0(avvio, "; source('", s, "')"))))
    if (esito != 0) stop("Errore nello script: ", s)
  }
}

# Invalida la cache di Quarto ------------------------------------------
if (pulisci_freeze) {
  freeze_sito <- here("_freeze", "sito")
  if (dir.exists(freeze_sito)) unlink(freeze_sito, recursive = TRUE)
  message("Cache _freeze/sito invalidata.")
}

message("\nFatto. Ora lancia tu:  `quarto::quarto_render()` oppure Build `-> Render Website`")
