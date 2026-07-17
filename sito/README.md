# sito/

Spazio di composizione: il sito Quarto **legge soltanto** gli output dei moduli
(`moduli/*/output/` e i relativi `blurb.md`) e li combina in pagine per tema
(`temi/`). Qui non si fa calcolo né pulizia dati.

`_quarto.yml` renderizza solo `index.qmd` (root) e `sito/**`: le voci di navbar
si aggiungono man mano che le pagine in `temi/` vengono create (punto 6 del piano).
