# sito/

Spazio di composizione: il sito Quarto **legge soltanto** gli output dei moduli
(`moduli/*/output/` e i relativi `blurb.md`) e li combina in pagine per tema
(`temi/`). Qui non si fa calcolo né pulizia dati.

`_quarto.yml` renderizza solo `index.qmd` (root) e `sito/**`: le voci di navbar
si aggiungono man mano che le pagine in `temi/` vengono create (punto 6 del piano).

Struttura di ogni pagina di `temi/` (deciso 2026-09-10; il sito è pubblico e in costruzione: deve far capire dove va il lavoro e raccogliere feedback):

- `## In sintesi`: 3-4 punti, i messaggi principali
- una sezione per domanda (quanti, chi, dove...): sotto il titolo 1-2 frasi col messaggio, non il metodo
- ogni grafico: bottoni di scarico + callout `Osservazioni` con il commento dettagliato (linguaggio riusabile in altri report) e, in coda, le note di metodo in corsivo `_NB: ..._`
- `## Possibili approfondimenti`: le domande aperte, scritte per il pubblico; fonti, file e percorsi operativi stanno in `_TODO.qmd`, non in pagina
- massima sintesi: niente ripetizioni tra sintesi, testo di sezione e osservazioni; grassetti con parsimonia; niente sottotitoli `### nome_grafico {.notitle}` (le ancore sono i label dei chunk)

## Categorie del piano strategico (YAML delle pagine)

Ogni pagina di `temi/` dichiara nello YAML, sotto `title`, le priorità (P = il perché, i bisogni) e le linee d'azione (LA = cosa si finanzia) del Piano Strategico 2024-27 a cui risponde. Le etichette vanno copiate tali e quali (sono l'unica fonte: `sito/_indice_ps.R` le confronta con le sue voci e avvisa se una non corrisponde); gli ambiti del PS non si usano (criteri di qualità, non classificano).

```yaml
categories: [P1 Disuguaglianze, P2 Persone e istituzioni, LA3 Capitale umano]
```

Etichette disponibili:

- Priorità strategiche: `P1 Disuguaglianze` · `P2 Persone e istituzioni` · `P3 Trasformazioni del territorio`
- Linea d'azione: `LA1 Welfare` · `LA2 Territorio` · `LA3 Capitale umano` · `LA4 Sostegno (r)esistente`

Dove si vedono: pillole sotto la description della pagina; pannello chiuso nel margine destro di tutte le pagine (`assets/indice_ps.html`, rigenerato da `build.R`), nascosto su telefono.
