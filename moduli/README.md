# moduli/

Una cartella = un modulo = una unità di analisi autonoma: input → output
(grafico / tabella / blurb). Per creare un nuovo modulo copiare `_template_modulo/`.

Regole:

1. Il modulo scrive **solo** nel proprio `output/`
2. Legge solo da `dati/grezzi/` e `dati/puliti/` (mai dall'`output/` di altri moduli)
3. Nome per fonte/indicatore (es. `pop_piramide_eta`, `bes_indicatori`), non per tema:
   i temi vivono in `sito/`
4. `blurb.md` sempre aggiornato: fonte, anno dati, data ultimo aggiornamento
