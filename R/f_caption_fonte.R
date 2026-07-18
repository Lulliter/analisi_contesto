# f_caption_fonte ---------------------------------------------------------
# Caption standard dei grafici del repo: riga "Fonte: ..." (variabile) +
# riga fissa "Rielaborazione: ..." che va SEMPRE a capo (decisione 2026-07-18).
# Uso: labs(caption = f_caption_fonte("MIM, Portale unico dei dati della scuola"))
f_caption_fonte <- function(fonte) {
  paste0(
    "Fonte: ", fonte,
    "\nRielaborazione: Fondazione Cariparma - Osservatorio dei Dati Sociali"
  )
}
