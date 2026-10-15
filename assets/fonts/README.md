# Font del sito, tenuti in casa (2026-10-15)

Font serviti dal sito stesso invece che da Google Fonts: tutti i visitatori vedono gli stessi caratteri e nessuna richiesta esterna passa l'IP a Google. Dichiarati con `@font-face` in `assets/styles/custom.css`.

| File | Font | Dove si usa |
|---|---|---|
| `bricolage_grotesque_800.woff2` (+ `.woff`) | Bricolage Grotesque 800 (opsz 24, wdth 100) | titolo del sito nella navbar |
| `roboto_condensed_400.woff2`, `_700`, `_400_italic`, `_700_italic` (+ `.woff`) | Roboto Condensed | tabelle flextable (`R/formatting.R`) |

Fonte: repository ufficiale di Google Fonts, <https://github.com/google/fonts> (cartelle `ofl/bricolagegrotesque`, `ofl/robotocondensed`), licenza SIL Open Font License 1.1 (file `OFL_*.txt`).

Come sono stati ottenuti: dai font variabili si estraggono i pesi statici (`fontTools.varLib.instancer`) e si tengono solo i caratteri latini, compresi accentati, punteggiatura tipografica, € e frecce (`pyftsubset`), salvati in formato WOFF (`pyftsubset`) e TTF; il WOFF2 si ottiene dai TTF con `woff2_compress` (`brew install woff2`). Nel CSS il WOFF2 è la prima scelta, il WOFF la riserva. I `.ttf` servono solo per la conversione e non vanno nel sito.
